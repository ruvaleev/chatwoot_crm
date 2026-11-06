# Журнал исполнителя

Новые записи — сверху. Шаблон:

```
## ГГГГ-ММ-ДД · Этап N · статус
Сделано: ...
Решения: ...
Отклонения от PRD: ...
Проверить человеку: ...
```

---

## 2026-11-06 · Этап M · in progress (ждём H5/H6)

**Обновление после H14**
- Evolution 2.3.7 установлен (`node_modules` 662 МБ) и запущен; миграции в БД `evolution` применены.
  Проблема: `sharp` пытался собраться из исходников под Homebrew `vips 8.18.7`; решение —
  `SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm ci`.
- `Procfile.dev` из upstream не запускает Sidekiq без `.env` (CLI `dotenv` требует файл). Не правя upstream,
  добавил свой `Procfile.crm`: тот же стек, Sidekiq через `dotenv -f .env.development.local`, плюс процесс
  Evolution. Запуск: `bin/dev` (обёртка над `foreman start -f Procfile.crm`; overmind не установлен). Первое открытие страницы в dev — 1–3 минуты, пока Vite компилирует фронтенд; человек принял это за зависание.
- `rake "crm:whatsapp:connect[number-1,Номер 1,2]"` в аккаунте «Acme Org»: создан API-inbox «Номер 1» с
  webhook'ом на `http://localhost:8080/chatwoot/webhook/number-1`, служебный админ «WhatsApp», в диалоге с
  контактом «WhatsApp» пришёл QR-код картинкой. Webhook'и Chatwoot → Evolution проходят (SSRF-фильтр не мешает).
- Память Evolution без подключённого номера: ~230 МБ footprint (`top`, из них 207 МБ сжато macOS; `ps` RSS
  показывает 26 МБ и вводит в заблуждение). Замер с подключённым номером — после H6. Для бюджета NFR6 это
  заметная доля: на сервере измерить `docker stats` и решать про лимит.

**Предыдущая запись (до H14)**

**Сделано**
- Исследование Evolution API (источники — GitHub API и исходники тега):
  - Репозиторий переехал: `EvolutionAPI/evolution-api` → `evolution-foundation/evolution-api`.
  - Стабильные релизы: последний **2.3.7** (2025-12-05). Дальше только `2.4.0-rc1/rc2` (май 2026), `main` после
    2.3.7 менялся лишь в документации, разработка идёт в `develop` (последний коммит 2026-07-14).
  - **Выбор: 2.3.7.** Это последний стабильный релиз, и на нём активно работают сейчас: в issues за октябрь–ноябрь
    2026 есть отчёты про v2.3.7, в том числе про интеграцию с Chatwoot, так что подключение к WhatsApp живое.
  - Baileys в 2.3.7 — `7.0.0-rc.9`; в `develop` — `rc13`; у самого Baileys последний `v7.0.0-rc14` (2026-07-29).
    **Риск:** WhatsApp меняет протокол, а стабильная ветка Evolution давно не обновлялась. Если 2.3.7 перестанет
    подключаться, следующий кандидат — `develop` на конкретном коммите.
  - Требования: Node 24 (по `Dockerfile`; локально стоит v24.11.1), PostgreSQL (Prisma), Redis — опционально,
    мы используем. Запуск без Docker: `npm ci && npm run db:generate && npm run db:deploy && npm run build &&
    npm run start:prod`.
  - Встроенная интеграция с Chatwoot: `POST /instance/create` с полями `chatwoot*` создаёт API-inbox в Chatwoot
    (ищется **по имени**, переименовывать нельзя) с webhook'ом обратно в Evolution. При
    `CHATWOOT_BOT_CONTACT=true` Evolution заводит служебный контакт и шлёт QR-код в диалог с ним, то есть QR
    можно сканировать прямо из Chatwoot, без SSH-туннеля (пригодится и на сервере).
  - Исходящие вызовы Evolution 2.3.7 (поиск URL по `src/`): телеметрия `log.evolution-api.com` — **включена по
    умолчанию**, у нас `TELEMETRY_ENABLED=false`; wavoip — только при заданном токене; версия WA Web —
    `web.whatsapp.com` (сам WhatsApp); логотип inbox'а по умолчанию — `evolution-api.com/files/...`, который
    скачал бы Chatwoot, поэтому передаём свой `chatwootLogo`. Sentry выключен, пока не задан `SENTRY_DSN`.
  - Известные проблемы из свежих issues: группы с интеграцией Chatwoot ломаются (`No session found`), у нас
    группы выключены (`groupsIgnore`); «instance open, но перестал получать сообщения после stream errored
    out» — это будет ловить мониторинг этапа 5; рост памяти при ~400 instance'ах (у нас единицы).
  - Память на номер — замерить после запуска.
- Важная находка в Chatwoot: webhook'и уходят через `SafeFetch` с SSRF-защитой (`lib/safe_fetch.rb`), а запросы
  на приватные адреса блокируются, если не задан `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true`. Без этого ответы
  из Chatwoot в Evolution не уходят — ни локально, ни на сервере (там Evolution во внутренней сети Kamal).
- `Custom::Whatsapp::ConnectService` + `rake crm:whatsapp:connect[instance_name,inbox_name,account_id]`, спек со
  стабами Evolution (создание, идемпотентность, существующий instance, громкая ошибка). `script/crm/test`:
  8 примеров, 0 падений, rubocop чистый.
- Подготовлено локально (вне git): исходники Evolution 2.3.7 в `~/private_projects/evolution-api`, БД и
  пользователь `evolution` в Postgres, `.env` Evolution (права 600, сгенерированные пароль и ключ), ключ и
  `SAFE_FETCH_ALLOW_PRIVATE_NETWORK` в `.env.development.local` Chatwoot.
- `crm/docs/local-mvp.md`.

**Решения**
- Служебный администратор «WhatsApp» (`whatsapp-bridge@crm.invalid`): Evolution нужен токен пользователя с правами
  на создание inbox'а. Отдельный пользователь лучше, чем токен живого админа: сообщения, отправленные с самого
  телефона, будут подписаны «WhatsApp», а не именем человека.
- Настройки instance: без подписи агента, переоткрытие той же беседы, группы игнорируются, без импорта истории
  и контактов (импорт требует прямого доступа Evolution к БД Chatwoot, решать отдельно).
- `account_id` у задачи необязателен, только если аккаунт один (`Account.sole`). В локальной dev-БД их два, так
  что id надо передавать.

**Отклонения от PRD**
- PRD: «Evolution слушает только `127.0.0.1`». В 2.3.7 настройки хоста нет (`server.listen(PORT)` в
  `src/main.ts`), он слушает все интерфейсы. Локально защищает API-ключ (64 hex-символа), на сервере порт
  не публикуется. Ограничение описано в `crm/docs/local-mvp.md`.

**Блокер**
- H14: свободно 3.6 ГБ, `npm ci` Evolution (1223 пакета, среди них ffmpeg, sharp, движки Prisma, ~1 ГБ) опустит
  место ниже порога в 3 ГБ. Установку не запускал.

**Дальше (после H14)**
- `npm ci` / `db:deploy` / `build`, запуск, `rake crm:whatsapp:connect`, QR с человеком (H6), сценарии (H5),
  замер памяти, AC M.1–M.5.

---

## 2026-11-06 · Этап 0 · ready for review

**Сделано**
- Разобраны 20 падений полного локального прогона (11094 примера, 33 минуты):
  - 4 × `spec/controllers/slack_uploads_controller_spec.rb` — локальный `.env` подгружался в тестах
    (`Dotenv::Rails.load`, `config/application.rb:14`), `FRONTEND_URL` уводил редирект на другой хост. Человек
    согласовал переименование `.env` → `.env.development.local` (грузится только в development, игнорируется
    git по `*.local`). Теперь зелёные.
  - 15 × `spec/enterprise/**` (Twilio voice, audit log, conversation monitors, call transcription) — upstream
    не гоняет `spec/enterprise` в публичном CI: удалённый `run_foss_spec.yml` делал `rm -rf enterprise
    spec/enterprise` перед прогоном. Спекам нужно внутреннее окружение upstream (например, `Message#reindex`
    есть только при настроенном поиске). Наш код и enterprise мы не трогаем — эти спеки не запускаем.
  - 1 × `spec/builders/agent_builder_spec.rb` — проходит изолированно, падает только в длинном однопоточном
    прогоне из-за состояния, оставленного другим спеком. Upstream делит прогон на 16 нод и этого не видит.
    Не чиним.
- Каркас `custom/` подключён в `config/application.rb` (одна правка с `# CRM:`, внесена в реестр):
  eager load `custom/lib` и `custom/app/**`, views, initializers, rake-задачи `custom/lib/tasks`.
- `Custom::AsyncDispatcher` + пустой `Custom::CrmListener`, спек `spec/custom/dispatchers/async_dispatcher_spec.rb`.
- `script/crm/test` — быстрый цикл: rubocop наших файлов + `spec/custom` + спеки upstream из реестра. ~9 секунд.
- `.github/workflows/crm-ci.yml` — запускает `script/crm/test` на push в `main` и `feature/**`.
- PRD перестроен по решению человека: после этапа 0 идёт этап M «Локальный MVP» (WhatsApp на Mac), исследования
  этапа 0 разнесены по этапам, где они нужны. `HUMAN.md`: H5/H6 теперь блокируют этап M.

**Проверка AC**
- AC0.1: `script/crm/test` → rubocop `4 files inspected, no offenses detected`, rspec `4 examples, 0 failures`.
  В CI ещё не проверено (воркфлоу запустится после push ветки).
- AC0.2: `bin/rails runner 'Rails.application.eager_load!; p ChatwootApp.extensions, AsyncDispatcher.ancestors.first(3)'`
  в development и production (с фиктивным `SECRET_KEY_BASE`) → `["enterprise", "custom"]`,
  `[Custom::AsyncDispatcher, Enterprise::AsyncDispatcher, AsyncDispatcher]`. `rake -T crm` видит задачи из
  `custom/lib/tasks` (проверено временным файлом).
- AC0.3: `slack_uploads_controller_spec.rb` и `agent_builder_spec.rb` → `17 examples, 0 failures`.

**Решения**
- H0: `origin/main` = локальный `main` = `v4.19.1` + удаление upstream-воркфлоу. `.github/dependabot.yml` в репозитории
  нет. Upstream-воркфлоу удалены из кода, так что в Actions им запускаться не из чего.
- i18n и frontend для `custom/` пока не подключены: нет ни строк, ни компонентов (подключим вместе с первыми).
- Важная особенность: `ChatwootApp.extensions` при наличии `custom/` всегда включает `enterprise`, даже с
  `DISABLE_ENTERPRISE` (`lib/chatwoot_app.rb`). Записано в `crm/docs/core-changes.md`.

**Отклонения от PRD**
- Нет (PRD изменён по решению человека, см. «Порядок работ» в PRD).

**Проверить человеку**
- Dependabot security updates в настройках GitHub (Settings → Code security), если хочешь их выключить — это
  настройка репозитория, не файл.
- После push ветки — зелёный ли `CRM CI` в Actions.
