# Локальный MVP: WhatsApp + Chatwoot на Mac

Всё работает на Mac, без Docker. Пока Mac спит или выключен, уведомлений нет. Сообщения клиентов при этом не
теряются: они остаются на телефоне, и Evolution подтянет их после переподключения (проверяем сценарием).

## Что где

| Компонент | Где | Порт |
|---|---|---|
| Chatwoot (web + Sidekiq + Vite) | этот репозиторий, `overmind start -f Procfile.dev` | 3000 (Vite 3036) |
| Evolution API 2.3.7 | `~/private_projects/evolution-api` (исходники тега, **вне** репозитория) | 8080 |
| PostgreSQL | Homebrew. БД Chatwoot — как раньше; БД `evolution`, владелец `evolution` | 5432 |
| Redis | Homebrew. Evolution использует индекс 6 с префиксом `evolution` | 6379 |

Настройки:
- `~/private_projects/evolution-api/.env` (права 600): пароль БД, API-ключ, `TELEMETRY_ENABLED=false`,
  `CHATWOOT_ENABLED=true`, `CHATWOOT_BOT_CONTACT=true` (QR-код приходит прямо в Chatwoot).
- `.env.development.local` Chatwoot: `EVOLUTION_API_URL`, `EVOLUTION_API_KEY` (тот же ключ),
  `SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true`. Без последнего Chatwoot не отправит ответы в Evolution: его
  SSRF-защита (`lib/safe_fetch.rb`) блокирует webhook'и на `localhost` и приватные адреса.
- Файл `.env` в корне Chatwoot не создавать: dotenv грузит его и в тестах.

## Первая установка Evolution API

Нужно ~1 ГБ свободного места. Перед установкой проверить `df -h ~`.

```bash
cd ~/private_projects/evolution-api
npm ci
npm run db:generate
npm run db:deploy      # миграции в БД evolution
npm run build
```

## Запуск и остановка

```bash
# 1. Evolution API (отдельная вкладка терминала; Ctrl+C — остановить)
cd ~/private_projects/evolution-api && npm run start:prod

# 2. Chatwoot (вкладка в корне репозитория)
overmind start -f Procfile.dev
```

Проверка Evolution: `curl -s localhost:8080` возвращает JSON с версией.

## Подключить номер

1. Узнать id аккаунта: в адресе Chatwoot `http://localhost:3000/app/accounts/<id>/...`.
2. Выполнить:
   ```bash
   bundle exec rake "crm:whatsapp:connect[number-a,Номер A,<id>]"
   ```
   `number-a` — латинское имя instance в Evolution, `Номер A` — имя inbox'а в Chatwoot. **Inbox потом не
   переименовывать**: Evolution ищет его по имени. Задача идемпотентна: повторный запуск ничего не дублирует
   и выдаёт новый QR, если номер не подключён.
3. В Chatwoot: inbox «Номер A» → диалог с контактом «WhatsApp» → там QR-код (обновляется сам).
4. На телефоне с этим номером: WhatsApp → «Связанные устройства» → «Привязка устройства» → отсканировать.
   В списке устройств он будет называться «CRM».

Задача создаёт служебного администратора «WhatsApp» (`whatsapp-bridge@crm.invalid`). От его имени Evolution
ходит в API Chatwoot, и от его же имени в Chatwoot показываются сообщения, отправленные с самого телефона.
Не удалять. Вход под ним не нужен.

Настройки instance (в `custom/app/services/custom/whatsapp/connect_service.rb`):
- без подписи агента в исходящих (`chatwootSignMsg: false`): клиент видит обычное сообщение;
- одна и та же беседа переоткрывается (`chatwootReopenConversation: true`), чтобы переписка шла непрерывно;
- группы игнорируются, история и контакты с телефона не импортируются (решение об импорте — позже).

## Люди и передача клиента

1. Settings → Agents → добавить менеджера (Administrator) и фрилансера (Agent). Без SMTP пароль задаётся
   через super admin: `http://localhost:3000/super_admin` → Users.
2. Settings → Inboxes → «Номер A» → Collaborators: фрилансер (только свой inbox), менеджер.
3. Передача: менеджер в диалоге пишет приватную заметку-бриф и назначает диалог на фрилансера.

## Известные ограничения MVP

- Evolution слушает порт 8080 на всех интерфейсах (настройки хоста у него нет). В локальной сети его
  защищает только API-ключ. Не подключайся к публичному Wi-Fi с запущенным Evolution или включи firewall
  macOS. На сервере порт наружу публиковаться не будет.
- Уведомления — только встроенные в Chatwoot (браузер, звук). Telegram — этап 5.
- Номер клиента виден всем агентам. Скрытие — этап 6.
