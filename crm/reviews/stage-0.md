# Ревью этапа 0 — Гигиена форка, каркас `custom/`

Дата: 2026-11-23 · Коммит: a45189d4ae · Раунд: 1

## Вердикт: PASS

## Критерии приёмки
| AC | Результат | Как проверено | Вывод (коротко) |
|---|---|---|---|
| AC0.1 | PASS локально · CI NOT VERIFIED (H0) | `script/crm/test`; `gh run list` — `gh` не авторизован | 368 examples, 0 failures; rubocop 30 files, no offenses; правки upstream в реестре |
| AC0.2 | PASS | `RAILS_ENV=production SECRET_KEY_BASE=dummy bin/rails runner 'Rails.application.eager_load!; p ChatwootApp.extensions, …'` | `["enterprise", "custom"]`, первыми в цепочках стоят `Custom::*` |
| AC0.3 | PASS по отчёту, `.env` в репозитории нет | `ls .env` → нет; спек не перезапускал | — |

## Чек-лист
- [x] Секретов в git нет.
- [x] Правки upstream в реестре. Не хватало строки про удалённые upstream-воркфлоу — ревьюер добавил
      (после merge релиза новые воркфлоу upstream вернутся и начнут запускаться).
- [x] `enterprise/` не тронут.
- [ ] Версии образов точные — в `crm-ci.yml` `redis:alpine` и `pgvector/pgvector:pg16` (minor).

## Замечания
1. **[minor]** `crm-ci.yml`: образы без точных тегов (`redis:alpine`, `pgvector/pgvector:pg16`), Postgres 16
   в CI против 18 локально. → этап 6.1.
2. **[minor]** `script/crm/test` идёт ~2 минуты (цель этапа — меньше минуты): в него добавлены upstream-спеки
   этапа 6. На вердикт не влияет.
3. **[minor]** Правка `actionCable.js` не проверяется ни в `script/crm/test`, ни в CI (eslint, vitest). → этап 6.1.

## Ответ исполнителя
1. Исправлено (этап 6.1): `pgvector/pgvector:0.8.7-pg18` (как локально: PostgreSQL 18, pgvector 0.8.7) и
   `redis:7.4.12-alpine`; теги сверены с Docker Hub. Версию Postgres сервера сверить при выборе сервера (этап 2).
2. Не исправлено: цикл стал дольше (~2:45), потому что в него добавлены upstream-спеки контроллеров, которые мы
   расширяем (`conversations`, `accounts`, `bulk_actions` и др.); один из них уже поймал регрессию с ботом.
   Считаю это приемлемой ценой; если мешает — можно вынести upstream-спеки в отдельный флаг.
3. Исправлено: `script/crm/test` гоняет eslint и vitest по `actionCable.js` и нашему `crmActionCable.spec.js`;
   в CI добавлены pnpm и Node из `.nvmrc`.
