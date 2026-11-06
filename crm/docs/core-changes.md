# Реестр правок upstream-файлов

Каждая правка файла, который пришёл из `chatwoot/chatwoot`, вносится сюда. При merge нового релиза
upstream пройди этот список: конфликты будут здесь, и после merge каждую правку надо проверить.

| Файл | Что изменено | Зачем | Как проверить после обновления |
|---|---|---|---|
| `AGENTS.md` (+ симлинк `CLAUDE.md`) | блок «CRM fork» в начале файла с `@crm/AGENTS.md` | агенты должны читать наши правила | блок на месте, `@crm/AGENTS.md` не удалён |
| `.gitignore` | строки в конце: `/notes*`, `/.playwright-mcp/`, `/config/crm/access.yml` | локальные заметки, артефакты Playwright, реальный список людей (репозиторий публичный) | строки на месте |
| `config/application.rb` | блок `# CRM:` после загрузки enterprise-инициализаторов: `custom/lib` и `custom/app/**` в eager load paths, `custom/app/views` в начало view paths, `require` файлов `custom/config/initializers/**`, `rake_tasks` из `custom/lib/tasks/**` | подключить `custom/` так же, как `enterprise/` | блок на месте и стоит после enterprise; `script/crm/test` зелёный; `bin/rails runner 'p AsyncDispatcher.ancestors.first(3)'` показывает `Custom::AsyncDispatcher` первым; `bundle exec rake -T crm` видит наши задачи |

## Особенности upstream, которые надо помнить

- `ChatwootApp.extensions` (`lib/chatwoot_app.rb`) при наличии папки `custom/` возвращает `%w[enterprise custom]`
  независимо от `DISABLE_ENTERPRISE`. Порядок важен: модули `Custom::*` подключаются после `Enterprise::*` и стоят
  в цепочке предков первыми, поэтому `super` в них вызывает enterprise-версию.
- `Dotenv::Rails.load` в `config/application.rb` грузит `.env` во всех окружениях, включая test. Локальные
  настройки разработки держим в `.env.development.local`, иначе ломаются спеки, зависящие от `FRONTEND_URL` и т. п.
