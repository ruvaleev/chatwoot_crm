# Реестр правок upstream-файлов

Каждая правка файла, который пришёл из `chatwoot/chatwoot`, вносится сюда. При merge нового релиза
upstream пройди этот список: конфликты будут здесь, и после merge каждую правку надо проверить.

| Файл | Что изменено | Зачем | Как проверить после обновления |
|---|---|---|---|
| `AGENTS.md` (+ симлинк `CLAUDE.md`) | блок «CRM fork» в начале файла с `@crm/AGENTS.md` | агенты должны читать наши правила | блок на месте, `@crm/AGENTS.md` не удалён |
| `.gitignore` | строки в конце: `/notes*`, `/.playwright-mcp/`, `/config/crm/access.yml` | локальные заметки, артефакты Playwright, реальный список людей (репозиторий публичный) | строки на месте |
| `config/application.rb` | блок `# CRM:` после загрузки enterprise-инициализаторов: `custom/lib` и `custom/app/**` в eager load paths, `custom/app/views` в начало view paths, `require` файлов `custom/config/initializers/**`, `rake_tasks` из `custom/lib/tasks/**` | подключить `custom/` так же, как `enterprise/` | блок на месте и стоит после enterprise; `script/crm/test` зелёный; `bin/rails runner 'p AsyncDispatcher.ancestors.first(3)'` показывает `Custom::AsyncDispatcher` первым; `bundle exec rake -T crm` видит наши задачи |
| `app/controllers/api/v1/accounts/contacts/base_controller.rb` | строка `# CRM:` + `prepend_mod_with('Api::V1::Accounts::Contacts::BaseController')` в конце файла | у базового контроллера вложенных ресурсов контакта (заметки, метки, contact_inboxes, conversations, attachments) нет точки расширения, а фрилансеру нужно закрыть чужие контакты (этап 6) | строка на месте; `script/crm/test` зелёный (спек `spec/custom/requests/freelancer_isolation_spec.rb`, «nested resources») |

## Особенности upstream, которые надо помнить

- `ChatwootApp.extensions` (`lib/chatwoot_app.rb`) при наличии папки `custom/` возвращает `%w[enterprise custom]`
  независимо от `DISABLE_ENTERPRISE`. Порядок важен: модули `Custom::*` подключаются после `Enterprise::*` и стоят
  в цепочке предков первыми, поэтому `super` в них вызывает enterprise-версию.
- `Dotenv::Rails.load` в `config/application.rb` грузит `.env` во всех окружениях, включая test. Локальные
  настройки разработки держим в `.env.development.local`, иначе ломаются спеки, зависящие от `FRONTEND_URL` и т. п.
- Пути автозагрузки `custom/app/**` (как и `enterprise/app/**`) собираются глобом **при старте** приложения.
  Новая папка верхнего уровня в `custom/app/` (например, `models/`, `policies/`) подхватится только после
  перезапуска `bin/dev`; до этого получаются ошибки вида `undefined method` / `uninitialized constant`.
  Новые файлы в уже существующих папках подхватываются перезагрузкой кода как обычно.
