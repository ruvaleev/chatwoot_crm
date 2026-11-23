# Локальный MVP: WhatsApp + Chatwoot на Mac

Всё работает на Mac, без Docker. Пока Mac спит или выключен, уведомлений нет. Сообщения клиентов при этом не
теряются: они остаются на телефоне, и Evolution подтянет их после переподключения (проверяем сценарием).

## Что где

| Компонент | Где | Порт |
|---|---|---|
| Chatwoot (web + Sidekiq + Vite) | этот репозиторий | 3000 (Vite 3036) |
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
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm ci   # иначе sharp пытается собраться под Homebrew vips и падает
npm run db:generate
npm run db:deploy      # миграции в БД evolution
npm run build
```

## Запуск и остановка

Всё одной командой из корня репозитория (Ctrl+C — остановить всё):

```bash
bin/dev   # = foreman start -f Procfile.crm; первое открытие страницы — 1–3 минуты (Vite компилирует)
```

`Procfile.crm` — это `Procfile.dev` плюс Evolution API, а Sidekiq читает `.env.development.local`.
`Procfile.dev` из upstream без файла `.env` не запустит Sidekiq: CLI `dotenv` требует `.env`.
Путь к Evolution можно переопределить через `EVOLUTION_DIR`.

Проверка: `curl -s localhost:8080` (Evolution) возвращает JSON с версией, Chatwoot — `http://127.0.0.1:3000`.

`FRONTEND_URL` в `.env.development.local` — `http://127.0.0.1:3000`, и Chatwoot открывать по этому адресу.
С `localhost` медиа из Chatwoot (голосовые, фото, документы) молча не уходят в WhatsApp: Evolution 2.3.7 проверяет
ссылку на вложение `isURL` из class-validator, а он не принимает адрес без доменной зоны. Сессия браузера
привязана к адресу: после смены — войти заново.

## Подключить номер

1. Узнать id аккаунта: в адресе Chatwoot `http://127.0.0.1:3000/app/accounts/<id>/...`.
2. Выполнить:
   ```bash
   bundle exec rake "crm:whatsapp:connect[number-a,Номер A,<id>]"
   ```
   Первый номер уже заведён так: `crm:whatsapp:connect[number-1,Номер 1,2]` (аккаунт «Acme Org»).
   `number-a` — латинское имя instance в Evolution, `Номер A` — имя inbox'а в Chatwoot. **Inbox потом не
   переименовывать**: Evolution ищет его по имени. Задача идемпотентна: повторный запуск ничего не дублирует
   и выдаёт новый QR, если номер не подключён.
3. В Chatwoot: inbox «Номер A» → диалог с контактом «WhatsApp» → там QR-код. Он живёт ~40 секунд и
   обновляется сам. После 30 попыток (`QRCODE_LIMIT`) Evolution перестаёт его выдавать — тогда снова запустить задачу.
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
   через super admin: `http://127.0.0.1:3000/super_admin` → Users.
2. Settings → Inboxes → «Номер A» → Collaborators: фрилансер (только свой inbox), менеджер.
3. Пометить фрилансера (роль **Agent**, не Administrator). В `bin/rails console`:
   ```ruby
   user = User.find_by!(email: 'freelancer@example.com')
   AccountUser.find_by!(account_id: 2, user: user).update!(role: :agent)
   user.update!(custom_attributes: user.custom_attributes.merge('crm_freelancer' => true))
   ```
   Фрилансер видит **только диалоги, назначенные на него сейчас**, и контакты этих диалогов. Неназначенные и
   чужие диалоги своего inbox'а ему не видны. После снятия назначения доступ пропадает. Снять флаг:
   `'crm_freelancer' => false`. Позже это будет делать `crm:access:sync` (этап 4).
4. Передача: менеджер в диалоге пишет приватную заметку-бриф и назначает диалог на фрилансера.

## Известные ограничения MVP

- Evolution слушает порт 8080 на всех интерфейсах (настройки хоста у него нет). В локальной сети его
  защищает только API-ключ. Не подключайся к публичному Wi-Fi с запущенным Evolution или включи firewall
  macOS. На сервере порт наружу публиковаться не будет.
- Уведомления — только встроенные в Chatwoot (браузер, звук). Telegram — этап 5.
- Номер клиента виден всем агентам. Скрытие — этап 6.
