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
