# Ревью этапа L — Выключить ненужное в Chatwoot

Дата: 2026-11-24 · Коммиты: c58b6d93df (L1), cac9dc0804 (L2), 6299286f99 (L3) + правка ревьюера (не закоммичена) ·
Раунд: 1

## Вердикт: PASS (после правки ревьюера; AC L.2 — на сервере, этап 2)

Сделано аккуратно: upstream почти не тронут (одна правка `vite.config.ts` в реестре), всё остальное — в `custom/`,
есть спеки. Ревьюер нашёл один **blocker**: 404-заглушку выключенных функций можно было обойти двойным слэшем
в пути. Исправил сам (маленькая правка со спеком), исполнителю — просмотреть.

## Критерии приёмки
| AC | Результат | Как проверено | Вывод (коротко) |
|---|---|---|---|
| AC L.1 | PASS | `cron_schedule_spec.rb`; исходники sidekiq-cron 2.4.0 (`ScheduleLoader`, `load_from_hash!`) и `config/initializers/sidekiq.rb` | оба загрузчика идут через `load_from_hash!(…, source: 'schedule')`, фильтр оставляет 3 задачи; в Redis лишних нет. Живой замер «час в покое» — 10 минут в PROGRESS, достаточно |
| AC L.2 | NOT VERIFIED (сервер, этап 2) | — | по коду: Hub-задача убрана, переключатели ENV записаны в этап 2 |
| AC L.3 | PASS | CI `6299286f99` и `d7b4ce8ba6` — success (GitHub API); `viteEntrypoints.spec.js`; `grep vite_javascript_tag` по views | в production собираются 4 входа. `vueapp` рендерит только `DashboardController`, а он на проде уводит в `/crm/` (`curl /app/`, `/app/login`, `/` → 302 `/crm/`). Размеры до и после — в PROGRESS (61,3 → 4,0 МБ) |
| AC L.4 | PASS после правки ревьюера | `curl --path-as-is` на запущенный production-режим (порт 3000), `log/production.log`, спек | до правки: `//installation/onboarding` → `Installation::OnboardingController`, `//platform/api/v1/users/1` → `Platform::Api::V1::UsersController`, `//hc/…` → `Public::Api::V1::PortalsController`. Замечание 1 |
| AC L.5 | PASS | `script/crm/test` → rubocop 81 файл, vitest 46, rspec 523, 0 failures; CI на ветке зелёный; реестр | правка `vite.config.ts` в реестре и с `// CRM:` |

## Чек-лист
- [x] Секретов в git нет (`git log -p v4.19.1..HEAD`, поиск token/password/secret/key — только код и фикстуры).
- [x] Реальных данных нет: телефоны и имена контактов локальной БД по истории `v4.19.1..HEAD` — 0 совпадений по
      телефонам. Имя реального фрилансера (логин и имя в `crm/PROGRESS.md` и `crm/reviews/stage-D.md`) убрано из файлов
      и из истории (замечание 4 этапа P).
- [x] Правки upstream в реестре; `enterprise/` не тронут.
- [x] Внешних сервисов не добавлено, наоборот — убраны (Hub, gravatar, Google favicons).
- [x] Спеки осмысленные, есть негативные (404 для чужого, 200 для нужного, `CRM_EXTRA_FEATURES`, неизвестное имя).

## Замечания
1. **[blocker, исправлено ревьюером]** `custom/config/initializers/crm_disabled_features.rb`: middleware сверяла
   `PATH_INFO` как есть, а роутер Rails перед поиском маршрута сжимает повторные слэши
   (`ActionDispatch::Journey::Router::Utils.normalize_path`). Любой закрытый путь открывался через `//` или `/x//y`.
   Хуже всего — экран первой установки: `db/seeds.rb` в production ставит в Redis флаг
   `CHATWOOT_INSTALLATION_ONBOARDING`. Если super admin создан из консоли (этап 2), флаг остаётся, и
   `POST //installation/onboarding` создал бы **нового super admin** любому человеку из интернета. Исправление: путь
   нормализуется так же, как в роутере. Спек «answers 404 however the path is written», без исправления падает
   (проверено). **Человеку:** перезапустить `script/crm/preview`, если он сейчас открыт через ngrok, — запущенный
   процесс работает со старым кодом.
2. **[major → в этап 2]** Вторым замком на сервере после `db:chatwoot_prepare` снять флаг onboarding
   (`Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)`) или создавать первую учётку так, чтобы
   флаг снимался; проверка — `curl` на `/installation/onboarding` и `//installation/onboarding` → 404. Добавлено
   задачей в этап 2.
3. **[minor]** `spec/custom/configs/cron_schedule_spec.rb`, второй пример: `load_from_hash!` удаляет **все** задачи с
   `source: 'schedule'`, кроме переданных, с любым `source` в options. Тесты делят Redis с development, поэтому
   каждый `script/crm/test` стирает расписание dev-Sidekiq до его перезапуска (сейчас в Redis 0 cron-задач). На прод
   не влияет. → этап L.1.
4. **[minor]** Набор `BASE` держит `chatwoot_v4` и `crm` ради старого интерфейса в dev — на проде лишнее, но безвредно.
   Не требует действий.

## Ответ исполнителя
