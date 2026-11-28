/* Макеты, раунд 2. Один скрипт на всё: экран приложения (screen.html) и полотно со всеми экранами (index.html).
   Все тексты интерфейса — через словарь i18n.js. Данные выдуманные. */
(function () {
  'use strict';
  var root = document.documentElement;
  var store = {
    get: function (k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    set: function (k, v) { try { localStorage.setItem(k, v); } catch (e) { /* хранилище недоступно */ } }
  };
  var P = new URLSearchParams(location.search);
  var lang = P.get('lang') || store.get('mock-lang') || 'ru';
  var theme = P.get('theme') || store.get('mock-theme') || 'system';
  function applyTheme(v) { theme = v; if (v === 'system') delete root.dataset.theme; else root.dataset.theme = v; }
  applyTheme(theme);
  root.lang = lang;

  function t(k, v) {
    var d = window.I18N || {};
    var s = (d[lang] && d[lang][k]) != null ? d[lang][k] : (d.ru && d.ru[k]);
    if (s == null) { console.warn('i18n: нет ключа ' + k); return k; }
    if (v) s = s.replace(/\{(\w+)\}/g, function (m, x) { return v[x] != null ? v[x] : m; });
    return s;
  }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  var I = {
    chat: '<path d="M4 5h16v11H9l-5 4z"/>',
    phone: '<rect x="7" y="3" width="10" height="18" rx="2"/><path d="M11 18h2"/>',
    people: '<circle cx="9" cy="8" r="3.2"/><path d="M3 19c.6-3.2 3-5 6-5s5.4 1.8 6 5"/><path d="M16 5.2a3 3 0 0 1 0 5.6M18 14c1.6.6 2.7 2.4 3 5"/>',
    search: '<circle cx="11" cy="11" r="6"/><path d="M20 20l-4.5-4.5"/>',
    clip: '<path d="M20 11.5l-8.2 8.2a5 5 0 0 1-7.1-7.1l8.5-8.5a3.3 3.3 0 0 1 4.7 4.7l-8.5 8.5a1.7 1.7 0 0 1-2.4-2.4l7.8-7.8"/>',
    mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
    send: '<path d="M4 12l16-8-6 16-2.5-6.5z"/><path d="M11.5 13.5L20 4"/>',
    check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    check2: '<path d="M2.5 12.5L7 17l9.5-9.5M12 16l1 1 9.5-9.5"/>',
    clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
    alert: '<path d="M12 3.5l9.5 16.5h-19z"/><path d="M12 10v4.5M12 17.2v.3"/>',
    back: '<path d="M19 12H5M11 6l-6 6 6 6"/>',
    more: '<circle cx="12" cy="5.5" r="1.3" fill="currentColor"/><circle cx="12" cy="12" r="1.3" fill="currentColor"/><circle cx="12" cy="18.5" r="1.3" fill="currentColor"/>',
    lock: '<rect x="5" y="10.5" width="14" height="9.5" rx="2"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
    play: '<path d="M8 5.5v13l10.5-6.5z" fill="currentColor" stroke="none"/>',
    pause: '<path d="M8.5 5.5v13M15.5 5.5v13" stroke-width="3"/>',
    x: '<path d="M6 6l12 12M18 6L6 18"/>',
    copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h3"/>',
    refresh: '<path d="M20 6v5h-5"/><path d="M19.5 11A8 8 0 1 0 18 16.5"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    eyeoff: '<path d="M3 3l18 18"/><path d="M10.6 6.1A9.8 9.8 0 0 1 12 6c5 0 8.5 4.5 9.5 6a17 17 0 0 1-3 3.4M6.4 7.6C4.4 9 3 11 2.5 12c1 1.5 4.5 6 9.5 6a9 9 0 0 0 4-.9"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
    logout: '<path d="M14 4h5v16h-5"/><path d="M10 8l-4 4 4 4M6 12h10"/>',
    user: '<circle cx="12" cy="8.5" r="3.5"/><path d="M5 20c.8-3.6 3.6-5.5 7-5.5s6.2 1.9 7 5.5"/>',
    image: '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="10" r="1.8"/><path d="M21 16l-5-5-9 8"/>',
    chev: '<path d="M6 9l6 6 6-6"/>',
    right: '<path d="M9 6l6 6-6 6"/>',
    handoff: '<path d="M4 12h11M11 7l5 5-5 5"/><path d="M20 4v16"/>',
    archive: '<rect x="3" y="4" width="18" height="4" rx="1"/><path d="M5 8v11h14V8M10 12h4"/>',
    unarchive: '<rect x="3" y="4" width="18" height="4" rx="1"/><path d="M5 8v11h14V8M12 17v-5M9.5 14.5L12 12l2.5 2.5"/>',
    bell: '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>',
    pin: '<path d="M9 4h6l-1 6 3 3H7l3-3z"/><path d="M12 13v7"/>',
    pencil: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
    gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>',
    sliders: '<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>',
    trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
    globe: '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.6 3.5 5.4 3.5 8.5s-1 5.9-3.5 8.5c-2.5-2.6-3.5-5.4-3.5-8.5s1-5.9 3.5-8.5z"/>',
    moon: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
    smile: '<circle cx="12" cy="12" r="8.5"/><path d="M8.5 14.5c1.8 2 5.2 2 7 0"/><circle cx="9" cy="10" r=".8" fill="currentColor"/><circle cx="15" cy="10" r=".8" fill="currentColor"/>',
    tag: '<path d="M3.5 12.5l8-8H20v8.5l-8 8z"/><circle cx="15.5" cy="8.5" r="1.4"/>',
    flag: '<path d="M5 21V4h11l-2 4 2 4H5"/>',
    file: '<path d="M14 3H6v18h12V7z"/><path d="M14 3v4h4"/>',
    camera: '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>',
    note: '<path d="M5 4h14v11l-5 5H5z"/><path d="M14 20v-5h5M8 9h8M8 13h5"/>',
    key: '<circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M16 7l3 3"/>',
    link: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
    qr: '<rect x="4" y="4" width="6" height="6"/><rect x="14" y="4" width="6" height="6"/><rect x="4" y="14" width="6" height="6"/><path d="M14 14h2v2M18 14h2M14 18h2v2M18 18v2h2"/>',
    power: '<path d="M12 3v8"/><path d="M6.3 6.8a8 8 0 1 0 11.4 0"/>'
  };
  function ic(n, c) { return '<svg class="ico ' + (c || '') + '" aria-hidden="true"><use href="#i-' + n + '"/></svg>'; }
  var SPRITE = '<svg class="sprite" aria-hidden="true">' + Object.keys(I).map(function (k) {
    return '<symbol id="i-' + k + '" viewBox="0 0 24 24">' + I[k] + '</symbol>';
  }).join('') + '</svg>';

  /* ---------- Данные (выдуманные) ---------- */
  var NUMS = {
    anna: { label: 'Номер Анны', phone: '+1 555 0101 2201', fr: 'Анна Ветрова', short: 'Анна', on: 'on', seen: 0 },
    oleg: { label: 'Номер Олега', phone: '+1 555 0102 3302', fr: 'Олег Сурин', short: 'Олег', on: 'on', seen: 0 },
    marina: { label: 'Номер Марины', phone: '+1 555 0103 4403', fr: 'Марина Лис', short: 'Марина', on: 'on', seen: 0 }
  };
  var FREEL = [
    { id: 'anna', name: 'Анна Ветрова', login: 'anna.v', num: 'anna', clients: 6, tg: true },
    { id: 'oleg', name: 'Олег Сурин', login: 'oleg.s', num: 'oleg', clients: 4, tg: true },
    { id: 'marina', name: 'Марина Лис', login: 'marina.l', num: 'marina', clients: 3, tg: false },
    { id: 'viktor', name: 'Виктор Гаев', login: 'viktor.g', num: null, clients: 0, tg: false, off: true }
  ];
  var LABELS = ['Балабол', 'Постоянный', 'Срочно', 'Торгуется'];
  var REASONS = ['Дорого', 'Не подходят сроки', 'Передумал', 'Перестал отвечать'];
  var TPL_TEAM = [
    ['/привет', 'Здравствуйте! Спасибо, что написали. Подскажите, пожалуйста, что вас интересует?'],
    ['/цена', 'Стоимость зависит от объёма. Расскажите чуть подробнее, и я сориентирую по цене.'],
    ['/сроки', 'Обычно начинаем в течение 2–3 дней после согласования деталей.']
  ];
  var TPL_MY = {
    fl: [['/примеры', 'Сейчас пришлю несколько примеров похожих работ.'], ['/замер', 'Могу приехать на замер в будний день после 18:00.']],
    mgr: [['/уточню', 'Сейчас уточню детали и вернусь к вам с ответом.']]
  };
  var BRIEF = {
    c49: { by: 'Ирина', time: '11:05', want: 'Дизайн-проект кухни ~12 м²', budget: 'до 150 тыс.', when: 'Старт в декабре',
      imp: 'Просит примеры в светлых тонах, общаемся на «вы». Я обещала примеры — пришли их первым сообщением.' },
    d1: { by: 'Ирина', time: '11:05', want: 'Дизайн-проект кухни ~14 м², есть план и фото', budget: '200–250 тыс.', when: 'До конца месяца, спрашивал про пятницу',
      imp: 'Фото на один просмотр — посмотреть на телефоне номера.' }
  };
  var T49 = [
    { k: 'day', key: 'day.today' },
    { k: 'in', text: 'Добрый день! Мне вас посоветовали, хочу узнать про дизайн-проект кухни', time: '10:31' },
    { k: 'out', by: 'Ирина', mgr: 1, text: 'Здравствуйте! Да, конечно. Какая площадь и когда хотелось бы начать?', time: '10:33', tick: 'read' },
    { k: 'in', text: 'Около 12 м², начать хотим в декабре. Бюджет до 150', time: '10:40' },
    { k: 'in', media: 'photo', time: '10:41' },
    { k: 'in', media: 'voice', dur: '0:21', time: '10:42' },
    { k: 'in', media: 'once', time: '10:42' },
    { k: 'out', by: 'Ирина', mgr: 1, text: 'Отлично! Подберу примеры похожих кухонь и вернусь к вам.', time: '10:44', tick: 'read' },
    { k: 'note', by: 'Ирина', text: 'Тёплый клиент. Бриф закрепила сверху.', time: '11:04' },
    { k: 'sys', key: 'sys.handed', x: 'Анна Ветрова', flKey: 'sys.toyou', time: '11:05' },
    { k: 'in', text: 'Хорошо, буду ждать примеры', time: '11:12' },
    { k: 'out', by: 'Анна', text: 'Добрый день! Вот несколько примеров светлых кухонь, посмотрите:', time: '11:14', tick: 'fail', sc: 'sendfail' }
  ];
  var TD = [
    { k: 'day', key: 'day.today' },
    { k: 'sys', key: 'sys.new', x: 'Номер Анны', time: '10:24' },
    { k: 'in', text: 'Здравствуйте! Мне вас посоветовали. Нужен дизайн-проект кухни, это к вам?', time: '10:24' },
    { k: 'out', by: 'Ирина', text: 'Здравствуйте, Дмитрий! Да, к нам. Расскажите, какая площадь и что хочется получить в итоге?', time: '10:26', tick: 'read' },
    { k: 'sys', key: 'sys.st', st: 'qual', time: '10:27' },
    { k: 'in', media: 'photo', cap: 'Вот так сейчас', time: '10:31' },
    { k: 'in', media: 'doc', name: 'План_кухни.pdf', size: 'PDF · 1,2 MB', time: '10:31' },
    { k: 'in', media: 'video', dur: '0:17', time: '10:32' },
    { k: 'in', media: 'voice', dur: '0:38', time: '10:33' },
    { k: 'in', media: 'once', time: '10:33' },
    { k: 'note', by: 'Ирина', text: 'Похоже на целевого: ~14 м², план есть. Подойдёт Анне.', time: '10:35' },
    { k: 'out', by: 'Ирина', text: 'Подскажите, какой бюджет и сроки вы рассматриваете?', time: '10:36', tick: 'fail' },
    { k: 'unread' },
    { k: 'in', text: 'Есть кто-нибудь?', time: '10:51' },
    { k: 'in', text: 'Здравствуйте, а можно сделать к пятнице? Бюджет примерно 200–250 тысяч', time: '10:58' },
    { k: 'sys', key: 'sys.handed', x: 'Анна Ветрова', time: '11:05', sc: 'handed' },
    { k: 'sys', key: 'sys.st', st: 'handed', time: '11:05', sc: 'handed' }
  ];
  var FL = [
    { id: 'c49', last4: '49', st: 'handed', fresh: 1, labels: [], wait: 12, unread: 1, last: 'Хорошо, буду ждать примеры', time: '11:12', from: 'c', order: 1, msgs: T49, num: 'anna' },
    { id: 'c17', name: 'Светлана Миронова', av: 'h2', st: 'work', labels: ['Постоянный'], wait: 6, unread: 1, lastMedia: 'photo', time: '11:19', from: 'c', order: 2 },
    { id: 'c07', last4: '07', st: 'work', labels: ['Балабол'], wait: 2, unread: 2, last: 'Спасибо! А сколько по времени займёт?', time: '11:24', from: 'c', order: 3 },
    { id: 'c88', name: 'Никита Орлов', av: 'h3', st: 'deal', labels: ['Постоянный'], last: 'Отправила договор, жду подпись', time: '@y', from: 'me', tick: 'read', order: 4 },
    { id: 'c55', name: 'Георгий Б.', av: 'h4', st: 'lost', labels: [], last: 'Хорошо, если что — пишите', time: '20.11', from: 'me', tick: 'read', order: 5 },
    { id: 'c62', name: 'Тамара К.', av: 'h5', st: 'lost', labels: [], hidden: 1, last: 'Спасибо, подумаю', time: '18.11', from: 'c', order: 6 },
    { id: 'c31', last4: '31', st: 'spam', labels: [], hidden: 1, last: 'Выгодное предложение для вашего бизнеса…', time: '15.11', from: 'c', order: 7 }
  ];
  var MG = [
    { id: 'd1', name: 'Дмитрий Кравец', av: 'h1', phone: '+1 555 0158 3317', num: 'anna', st: 'qual', handler: 'me', labels: [], wait: 27, unread: 2,
      last: 'Здравствуйте, а можно сделать к пятнице? Бюджет примерно 200–250 тысяч', time: '10:58', from: 'c', order: 1, msgs: TD, other: [['oleg', '12.03', 'lost']] },
    { id: 'd2', phone: '+1 555 0147 8820', num: 'oleg', st: 'new', handler: null, labels: [], wait: 14, unread: 1, last: 'Добрый день! Сколько стоит проект для студии?', time: '11:11', from: 'c', order: 2 },
    { id: 'd3', phone: '+1 555 0163 2249', num: 'anna', st: 'handed', handler: 'Анна', labels: [], wait: 12, unread: 1, last: 'Хорошо, буду ждать примеры', time: '11:12', from: 'c', order: 3, msgs: T49, briefId: 'c49' },
    { id: 'd4', name: 'Светлана Миронова', av: 'h2', phone: '+1 555 0144 9051', num: 'anna', st: 'work', handler: 'Анна', labels: ['Постоянный'], wait: 6, unread: 1, lastMedia: 'photo', time: '11:19', from: 'c', order: 4 },
    { id: 'd5', phone: '+1 555 0171 6604', num: 'marina', st: 'new', handler: null, labels: [], wait: 3, unread: 1, lastMedia: 'voice', dur: '0:42', time: '11:22', from: 'c', order: 5 },
    { id: 'd6', name: 'Ольга Дёмина', av: 'h3', phone: '+1 555 0132 7716', num: 'marina', st: 'qual', handler: 'me', labels: [], last: 'Отправила примеры, посмотрите, пожалуйста', time: '10:20', from: 'me', by: 'Ирина', tick: 'read', order: 6 },
    { id: 'd7', name: 'Артём Лаптев', av: 'h4', phone: '+1 555 0119 4420', num: 'oleg', st: 'work', handler: 'Олег', labels: ['Балабол'], last: 'Договорились, до связи в четверг', time: '09:47', from: 'me', by: 'Олег', tick: 'read', order: 7 },
    { id: 'd8', name: 'Евгения Рощина', av: 'h5', phone: '+1 555 0127 3385', num: 'marina', st: 'deal', handler: 'Марина', labels: ['Постоянный'], last: 'Рада была помочь!', time: '@y', from: 'me', by: 'Марина', tick: 'read', order: 8 },
    { id: 'd9', phone: '+1 555 0189 0032', num: 'oleg', st: 'spam', handler: null, labels: [], hidden: 1, last: 'Выгодное предложение для вашего бизнеса…', time: '@y', from: 'c', order: 9 }
  ];
  var ST_ALL = ['new', 'qual', 'handed', 'work', 'deal', 'lost', 'spam'];
  var ST_FL = ['work', 'deal', 'lost', 'spam'];
  var ANSWERED = { c49: 'Отправила примеры, посмотрите', c17: 'Да, сделаем в этом цвете', c07: 'Около двух недель', d1: 'Да, к пятнице успеем', d2: 'Добрый день! Расскажите, какая площадь?', d3: 'Вот примеры, посмотрите', d4: 'Хорошо, учту', d5: 'Перезвоню вам после обеда' };

  /* ---------- Состояние экрана (из параметров URL) ---------- */
  var S = {
    app: P.get('app') || 'fl', side: P.get('side') || 'list', tab: P.get('tab') || 'waiting', chat: P.get('chat'),
    focus: P.get('focus') || (P.get('chat') ? 'main' : 'side'), drawer: P.get('drawer'), menu: P.get('menu'), sheet: P.get('sheet'),
    preview: P.get('preview'), select: P.get('select'), find: P.get('find'), brief: P.get('brief') === '1', mode: P.get('mode') || 'client',
    draft: P.get('draft') || '', loading: P.get('loading'), sc: (P.get('sc') || '').split(',').filter(Boolean), other: P.get('other') === '1',
    num: P.get('num') || 'oleg', qr: P.get('qr') === '1', add: P.get('add'), fr: P.get('fr') || 'anna', team: P.get('team') || 'hours',
    me: P.get('me') || 'tg', auth: P.get('auth') || 'login', tg: P.get('tg') === '1', fnum: P.get('fnum') || '', fst: P.get('fst') || '',
    rename: P.get('rename') === '1', toast: null, forgot: false, reason: 0
  };
  function has(x) { return S.sc.indexOf(x) >= 0; }
  var ME = S.app === 'mgr' ? 'Ирина' : 'Анна';
  var CH = S.app === 'mgr' ? MG : FL;

  // Сценарии меняют данные
  if (has('none')) FL.length = 0;
  if (has('answered')) CH.forEach(function (c) { if (ANSWERED[c.id]) { c.last = ANSWERED[c.id]; c.lastMedia = null; c.from = 'me'; c.by = c.handler === 'me' ? 'Ирина' : (c.handler || 'Ирина'); c.tick = 'read'; c.wait = 0; c.unread = 0; } });
  if (has('returned')) { var r62 = FL.filter(function (c) { return c.id === "c62"; })[0]; r62.hidden = 0; r62.back = 1; r62.last = 'Здравствуйте! А предложение ещё в силе?'; r62.time = "11:26"; r62.unread = 1; r62.wait = 1; r62.order = 0; }
  if (has('hiddenEmpty')) for (var i = FL.length - 1; i >= 0; i--) if (FL[i].hidden) FL.splice(i, 1);
  if (has('handed')) { MG[0].st = 'handed'; MG[0].handler = 'Анна'; MG[0].briefId = 'd1'; }
  if (has('disconnected')) { NUMS.oleg.on = 'off'; NUMS.oleg.seen = 40; }
  if (S.qr) NUMS.oleg.on = 'qr';

  function byId(id) { return CH.filter(function (c) { return c.id === id; })[0]; }
  function cname(c) { return c.name || (S.app === 'fl' ? t('client.masked', { n: c.last4 }) : c.phone); }
  function initials(c) { return c.name ? c.name.split(' ').map(function (w) { return w.charAt(0); }).join('').slice(0, 2) : ''; }
  function avHtml(c, cls) { return '<div class="av ' + (c.av || '') + ' ' + (cls || '') + '">' + (initials(c) || ic('user')) + '</div>'; }
  function tm(x) { return x === '@y' ? t('time.yesterday') : x; }
  function waiting(c) { return !c.hidden && c.from === 'c' && c.wait > 0; }
  function overdue(c) { return waiting(c) && c.wait >= 10; }
  function handlerName(c) { return c.handler === 'me' ? t('who.you') : (c.handler || t('who.nobody')); }
  function now() { var d = new Date(); return ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2); }
  function thread(c) {
    if (!c.msgs) {
      c.msgs = [{ k: 'day', key: 'day.today' }, c.from === 'c'
        ? { k: 'in', text: c.last, media: c.lastMedia, dur: c.dur, time: tm(c.time) }
        : { k: 'out', by: c.by || ME, text: c.last, time: tm(c.time), tick: c.tick }];
    }
    return c.msgs;
  }
  function brief(c) { return BRIEF[c.briefId || (S.app === 'fl' ? c.id : '')]; }

  /* ---------- Мелкие куски разметки ---------- */
  function tickHtml(k) {
    if (k === 'read') return ic('check2', 'read');
    if (k === 'deliv') return ic('check2');
    if (k === 'sent') return ic('check');
    if (k === 'pending') return ic('clock', 'xs');
    if (k === 'fail') return ic('alert', 'xs bad');
    return '';
  }
  function stHtml(s) { return '<span class="st" data-s="' + s + '">' + t('st.' + s) + '</span>'; }
  function prevHtml(c) {
    var p = '';
    if (c.from === 'me') p += tickHtml(c.tick);
    if (S.app === 'mgr' && c.from === 'me' && c.by && c.by !== ME) p += '<span>' + esc(c.by) + ':</span>';
    if (c.lastMedia === 'photo') p += ic('image', 'sm') + '<span class="t">' + t('prev.photo') + '</span>';
    else if (c.lastMedia === 'voice') p += ic('mic', 'sm') + '<span class="t">' + t('prev.voice', { x: c.dur || '0:21' }) + '</span>';
    else p += '<span class="t">' + esc(c.last) + '</span>';
    return p;
  }
  function rowHtml(c) {
    var meta = [];
    if (c.fresh && S.app === 'fl') meta.push('<span class="tag fresh">' + t('tag.fresh') + '</span>');
    if (c.back) meta.push('<span class="tag back">' + t('tag.back') + '</span>');
    if (overdue(c)) meta.push('<span class="tag wait">' + ic('clock') + t('wait.min', { n: c.wait }) + '</span>');
    if (S.app === 'mgr') meta.push('<span>' + esc(NUMS[c.num].label) + '</span>');
    meta.push(stHtml(c.st));
    if (S.app === 'mgr') meta.push('<span>' + esc(handlerName(c)) + '</span>');
    c.labels.forEach(function (l) { meta.push('<span class="tag lbl">' + esc(l) + '</span>'); });
    var timeCls = overdue(c) ? 'red' : (c.unread ? 'acc' : '');
    var search = [cname(c), c.phone || '', c.last || ''].concat(thread(c).map(function (m) { return m.text || ''; })).join(' ').toLowerCase();
    var menu = S.menu === 'row:' + c.id ? '<div class="pop" style="right:12px;top:44px">' + (c.hidden
      ? '<button data-act="unhide" data-id="' + c.id + '">' + ic('unarchive') + t('a.unhide') + '</button>'
      : '<button data-act="hide" data-id="' + c.id + '">' + ic('archive') + t('a.hide') + '</button>') +
      '<button data-act="sheet" data-v="labels" data-id="' + c.id + '">' + ic('tag') + t('a.labels') + '</button></div>' : '';
    return '<div class="crow' + (S.chat === c.id ? ' active' : '') + (S.select === c.id ? ' picked' : '') + (overdue(c) ? ' over' : '') +
      '" role="button" tabindex="0" data-act="open" data-id="' + c.id + '" data-search="' + esc(search) + '">' +
      avHtml(c) + (S.select === c.id ? '' : '') +
      '<div class="crow-b"><div class="crow-top"><span class="crow-name">' + esc(cname(c)) + '</span><span class="crow-time ' + timeCls + '">' + tm(c.time) + '</span></div>' +
      '<div class="crow-mid"><span class="crow-prev">' + prevHtml(c) + '</span>' + (c.unread ? '<span class="badge">' + c.unread + '</span>' : '') + '</div>' +
      '<div class="crow-meta">' + meta.join('') + '</div></div>' +
      '<button class="crow-menu" data-act="menu" data-v="row:' + c.id + '" aria-label="' + t('a.more') + '">' + ic('chev', 'sm') + '</button>' + menu + '</div>';
  }
  function skRows(n) {
    var w = ['w50', 'w40', 'w60', 'w30'], s = '';
    for (var i = 0; i < n; i++) s += '<div class="sk-row"><div class="sk c"></div><div class="sk-lines"><div class="sk sk-l ' + w[i % 4] + '"></div><div class="sk sk-l w80"></div><div class="sk sk-l ' + w[(i + 2) % 4] + '"></div></div></div>';
    return s;
  }
  function empty(icon, title, text, ok) {
    return '<div class="empty"><div class="e-ico' + (ok ? ' ok' : '') + '">' + ic(icon, 'lg') + '</div><h3>' + title + '</h3><p>' + text + '</p></div>';
  }
  function bar(title, backAct, extra) {
    return '<div class="bar">' + (backAct ? '<button class="ib" data-act="' + backAct + '" aria-label="' + t('a.back') + '">' + ic('back') + '</button>' : '') +
      '<h2>' + title + '</h2>' + (extra || '') + '</div>';
  }

  /* ---------- Левая колонка ---------- */
  function sideList() {
    var tabs = S.app === 'mgr' ? ['waiting', 'new', 'mine', 'all'] : ['waiting', 'all'];
    var visible = CH.filter(function (c) { return !c.hidden; });
    var inTab = function (c, tb) {
      if (tb === 'waiting') return waiting(c);
      if (tb === 'new') return !c.handler;
      if (tb === 'mine') return c.handler === 'me';
      return true;
    };
    var rows = visible.filter(function (c) { return inTab(c, S.tab) && (!S.fnum || c.num === S.fnum) && (!S.fst || c.st === S.fst); });
    rows.sort(function (a, b) { return S.tab === 'waiting' ? b.wait - a.wait : a.order - b.order; });
    var hiddenN = CH.filter(function (c) { return c.hidden; }).length;
    var head;
    if (S.select) {
      head = '<div class="bar sel"><button class="ib" data-act="unselect" aria-label="' + t('a.back') + '">' + ic('back') + '</button><b>1</b>' +
        '<button class="ib" data-act="sheet" data-v="labels" data-id="' + S.select + '" aria-label="' + t('a.labels') + '">' + ic('tag') + '</button>' +
        '<button class="ib" data-act="hide" data-id="' + S.select + '" aria-label="' + t('a.hide') + '">' + ic('archive') + '</button></div>';
    } else if (S.app === 'mgr') {
      head = '<div class="bar title"><h1>' + t('nav.chats') + '</h1>' +
        '<button class="ib" data-act="side" data-v="numbers" aria-label="' + t('nav.numbers') + '">' + ic('phone') + (has('disconnected') ? '<i class="dot"></i>' : '') + '</button>' +
        '<button class="ib" data-act="side" data-v="freelancers" aria-label="' + t('nav.freelancers') + '">' + ic('people') + '</button>' +
        '<button class="ib" data-act="menu" data-v="list" aria-label="' + t('a.more') + '">' + ic('more') + '</button>' + listMenu() + '</div>';
    } else {
      head = '<div class="bar title"><h1>' + t('nav.chats') + '</h1><button class="ib" data-act="menu" data-v="list" aria-label="' + t('a.more') + '">' + ic('more') + '</button>' + listMenu() + '</div>';
    }
    var chips = tabs.map(function (tb) {
      var n = visible.filter(function (c) { return inTab(c, tb); }).length;
      return '<button class="fchip" data-act="tab" data-v="' + tb + '" aria-pressed="' + (S.tab === tb) + '">' + t('tab.' + tb) + (tb !== 'all' && n ? ' <span class="n">' + n + '</span>' : '') + '</button>';
    }).join('');
    if (S.app === 'mgr') {
      chips += '<button class="fchip" data-act="menu" data-v="filter" aria-label="' + t('a.filter') + '">' + ic('sliders', 'sm') + '</button>';
      if (S.fnum) chips += '<button class="fchip x" data-act="fclear" data-v="fnum">' + esc(NUMS[S.fnum].label) + ' ' + ic('x', 'xs') + '</button>';
      if (S.fst) chips += '<button class="fchip x" data-act="fclear" data-v="fst">' + t('st.' + S.fst) + ' ' + ic('x', 'xs') + '</button>';
    }
    var body;
    if (S.loading === 'list' || S.loading === 'all') body = skRows(6);
    else if (!CH.length) body = empty('chat', t('empty.none'), t('empty.none.t'));
    else {
      body = (hiddenN ? '<button class="arch" data-act="side" data-v="hidden">' + ic('archive') + '<span>' + t('hidden.row') + '</span><span class="n">' + hiddenN + '</span></button>' : '') +
        (rows.length ? rows.map(rowHtml).join('') : (S.tab === 'waiting' ? empty('check', t('empty.answered'), t('empty.answered.t'), true) : empty('search', t('empty.tab'), t('empty.tab.t'))));
    }
    var filterPop = S.menu === 'filter' ? filterMenu() : '';
    return head + '<label class="search">' + ic('search') + '<input type="search" data-act="search" placeholder="' + esc(t(S.app === 'mgr' ? 'search.ph.mgr' : 'search.ph')) + '" aria-label="' + t('a.search') + '"></label>' +
      '<div class="chips" style="position:relative">' + chips + filterPop + '</div><div class="list">' + body + '</div>';
  }
  function listMenu() {
    if (S.menu !== 'list') return '';
    var b = '<button data-act="side" data-v="hidden">' + ic('archive') + t('hidden.title') + '</button>';
    if (S.app === 'mgr') {
      b += '<button data-act="side" data-v="numbers">' + ic('phone') + t('nav.numbers') + '</button>' +
        '<button data-act="side" data-v="freelancers">' + ic('people') + t('nav.freelancers') + '</button>' +
        '<button data-act="side" data-v="team">' + ic('sliders') + t('nav.team') + '</button>';
    }
    b += '<button data-act="side" data-v="settings">' + ic('gear') + t('nav.settings') + '</button>';
    return '<div class="pop tr">' + b + '</div>';
  }
  function filterMenu() {
    var o = '<div class="p-title">' + t('f.number') + '</div><button data-act="fset" data-k="fnum" data-v="" class="' + (S.fnum ? '' : 'on') + '">' + t('f.allnums') + '</button>';
    Object.keys(NUMS).forEach(function (k) { o += '<button data-act="fset" data-k="fnum" data-v="' + k + '" class="' + (S.fnum === k ? 'on' : '') + '">' + esc(NUMS[k].label) + '</button>'; });
    o += '<div class="p-title">' + t('f.status') + '</div><button data-act="fset" data-k="fst" data-v="" class="' + (S.fst ? '' : 'on') + '">' + t('f.allst') + '</button>';
    ST_ALL.forEach(function (s) { o += '<button data-act="fset" data-k="fst" data-v="' + s + '" class="' + (S.fst === s ? 'on' : '') + '">' + t('st.' + s) + '</button>'; });
    return '<div class="pop" style="left:12px;top:38px;max-height:420px;overflow:auto">' + o + '</div>';
  }
  function sideHidden() {
    var rows = CH.filter(function (c) { return c.hidden; });
    return bar(t('hidden.title'), 'side-list') + '<div class="list"><div class="list-hint">' + t('hidden.hint') + '</div>' +
      (rows.length ? rows.map(rowHtml).join('') : empty('archive', t('empty.hidden'), t('empty.hidden.t'))) + '</div>';
  }
  function profileRow() {
    var mgr = S.app === 'mgr';
    return '<div class="pf-sec" style="display:flex;gap:14px;align-items:center"><div class="av h1" style="margin:0;width:64px;height:64px;font-size:22px">' + (mgr ? 'ИБ' : 'АВ') + '</div>' +
      '<div class="grow"><b style="font-size:18px;font-weight:500">' + (mgr ? 'Ирина Белова' : 'Анна Ветрова') + '</b><div class="faint">' + t(mgr ? 'role.admin' : 'role.freelancer') + ' · ' + (mgr ? 'irina.b' : 'anna.v') + '</div></div></div>';
  }
  function setRow(icon, title, sub, act, v, cls) {
    return '<button class="pf-row ' + (cls || '') + '" data-act="' + act + '" data-v="' + (v || '') + '">' + ic(icon) + '<span class="k"><b>' + title + '</b>' + (sub ? '<small>' + sub + '</small>' : '') + '</span>' + (cls ? '' : ic('right', 'sm faint')) + '</button>';
  }
  function sideSettings() {
    var sub = S.app === 'mgr' ? 'me' : 'side';
    return bar(t('nav.settings'), 'side-list') + '<div class="pf">' + profileRow() + '<div class="pf-sec">' +
      setRow('globe', t('set.lang'), lang === 'ru' ? 'Русский' : 'English', 'sheet', 'lang') +
      setRow('moon', t('set.theme'), t('theme.' + theme), 'sheet', 'theme') +
      setRow('bell', t('set.notif'), t(S.tg ? 'tg.yes' : 'tg.no'), sub, 'tg') +
      setRow('note', t('set.tpl'), t('set.tpl.sub', { n: TPL_MY[S.app].length }), sub, 'tpl') +
      '</div><div class="pf-sec">' + setRow('logout', t('a.logout'), '', 'logout', '', 'red') + '</div></div>';
  }
  function sideNumbers() {
    var rows = '<button class="add-row" data-act="addnum"><span class="ci">' + ic('plus') + '</span>' + t('num.add') + '</button>' +
      Object.keys(NUMS).map(function (k) {
        var n = NUMS[k];
        return '<div class="crow' + (S.num === k && !S.add ? ' active' : '') + '" role="button" tabindex="0" data-act="pick" data-k="num" data-v="' + k + '"><div class="av">' + ic('phone') + '</div>' +
          '<div class="crow-b"><div class="crow-top"><span class="crow-name">' + esc(n.label) + '</span></div><div class="crow-mid"><span class="crow-prev"><span class="t">' + esc(n.phone) + '</span></span></div>' +
          '<div class="crow-meta"><span class="conn ' + n.on + '">' + t('conn.' + n.on) + '</span><span>' + t('num.of', { x: esc(n.fr) }) + '</span></div></div></div>';
      }).join('');
    return bar(t('nav.numbers'), 'side-list') + '<div class="list">' + rows + '<div class="list-hint">' + t('num.pool') + '</div></div>';
  }
  function sideFreelancers() {
    var rows = '<button class="add-row" data-act="pick" data-k="fr" data-v="add"><span class="ci">' + ic('plus') + '</span>' + t('fr.add') + '</button>' +
      FREEL.map(function (f) {
        var n = f.num ? NUMS[f.num] : null;
        return '<div class="crow' + (S.fr === f.id ? ' active' : '') + '" role="button" tabindex="0" data-act="pick" data-k="fr" data-v="' + f.id + '"><div class="av h' + (FREEL.indexOf(f) + 1) + '">' + f.name.split(' ').map(function (w) { return w[0]; }).join('') + '</div>' +
          '<div class="crow-b"><div class="crow-top"><span class="crow-name">' + esc(f.name) + '</span></div>' +
          '<div class="crow-meta">' + (f.off ? '<span class="conn no">' + t('fr.off') + '</span>' : (n ? '<span>' + esc(n.label) + '</span><span class="conn ' + n.on + '">' + t('conn.' + n.on) + '</span>' : '<span>' + t('fr.nonum') + '</span>')) +
          (f.off ? '' : '<span>' + t('fr.clients', { n: f.clients }) + '</span>') + '<span class="' + (f.tg ? 'sub-ok' : '') + '">' + t(f.tg ? 'tg.yes' : 'tg.no') + '</span></div></div></div>';
      }).join('');
    return bar(t('nav.freelancers'), 'side-list') + '<div class="list">' + rows + '</div>';
  }
  var TEAM_SECS = ['hours', 'wait', 'tglang', 'tpl', 'reasons', 'labels'];
  function sideTeam() {
    var subs = { hours: t('team.hours.sub'), wait: t('team.wait.sub', { a: 10, b: 60 }), tglang: 'Русский', tpl: t('set.tpl.sub', { n: TPL_TEAM.length }), reasons: String(REASONS.length), labels: LABELS.join(', ') };
    var icons = { hours: 'clock', wait: 'bell', tglang: 'globe', tpl: 'note', reasons: 'flag', labels: 'tag' };
    return bar(t('nav.team'), 'side-list') + '<div class="list">' + TEAM_SECS.map(function (s) {
      return '<div class="crow' + (S.team === s ? ' active' : '') + '" role="button" tabindex="0" data-act="pick" data-k="team" data-v="' + s + '"><div class="av" style="background:var(--chip);color:var(--text-2)">' + ic(icons[s]) + '</div>' +
        '<div class="crow-b"><div class="crow-top"><span class="crow-name">' + t('team.' + s) + '</span></div><div class="crow-mid"><span class="crow-prev"><span class="t">' + esc(subs[s]) + '</span></span></div></div></div>';
    }).join('') + '<div class="list-hint">' + t('team.only') + '</div></div>';
  }
  function sideHtml() {
    if (S.side === 'hidden') return sideHidden();
    if (S.side === 'settings') return sideSettings();
    if (S.side === 'tg' && S.app === 'fl') return bar(t('set.notif'), 'side-settings') + '<div class="page"><div class="page-in">' + panelTg() + '</div></div>';
    if (S.side === 'tpl' && S.app === 'fl') return bar(t('set.tpl'), 'side-settings') + '<div class="page"><div class="page-in">' + panelTpl() + '</div></div>';
    if (S.side === 'numbers') return sideNumbers();
    if (S.side === 'freelancers') return sideFreelancers();
    if (S.side === 'team') return sideTeam();
    return sideList();
  }

  /* ---------- Чат ---------- */
  function msgHtml(m, c) {
    if (m.sc && !has(m.sc)) return '';
    if (m.k === 'day') return '<div class="cchip day">' + t(m.key) + '</div>';
    if (m.k === 'unread') return '<div class="unread-sep"><span>' + t('unread.sep') + '</span></div>';
    if (m.k === 'sys') {
      var txt = m.key === 'sys.st' ? t('sys.st', { x: t('st.' + m.st) }) : t(S.app === 'fl' && m.flKey ? m.flKey : m.key, { x: m.x });
      return '<div class="cchip">' + txt + (m.time ? ' · ' + m.time : '') + '</div>';
    }
    var cls = m.k === 'in' ? 'in' : (m.k === 'note' ? 'note' : 'out');
    var fail = m.tick === 'fail';
    var head = '';
    if (m.k === 'note') head = '<div class="b-note">' + ic('lock', 'xs') + t('note.label') + ' · ' + esc(m.by === ME ? t('who.you') : m.by) + '</div>';
    else if (m.k === 'out' && m.by && m.by !== ME) head = '<div class="b-author">' + esc(m.by) + (m.mgr && S.app === 'fl' ? ' · ' + t('role.manager.l') : '') + '</div>';
    var body = '';
    if (m.media === 'photo') body = '<div class="media">' + ic('image', 'lg') + '</div>';
    else if (m.media === 'video') body = '<div class="media"><span class="play">' + ic('play') + '</span><span class="dur">' + ic('camera', 'xs') + m.dur + '</span></div>';
    else if (m.media === 'doc') body = '<div class="doc"><span class="d-ico">PDF</span><span class="grow"><b>' + esc(m.name) + '</b><small>' + esc(m.size) + '</small></span></div>';
    else if (m.media === 'voice') {
      var bars = [30, 55, 80, 45, 70, 35, 90, 55, 30, 65, 80, 40, 60, 25, 50, 70, 35, 45, 60, 30].map(function (h) { return '<i style="height:' + h + '%"></i>'; }).join('');
      body = '<div class="voice"><button class="vplay" data-act="voice" aria-label="' + t('a.play') + '"><span class="p1">' + ic('play') + '</span><span class="p2">' + ic('pause') + '</span></button><div class="grow"><div class="vwave">' + bars + '<span class="knob"></span></div><span class="vt">' + m.dur + '</span></div></div>';
    } else if (m.media === 'once') {
      var nl = NUMS[c.num || 'anna'].label;
      body = '<div class="once"><span class="o-ico">' + ic('eyeoff', 'sm') + '</span><span><b>' + t('once.title') + '</b><small>' + (S.app === 'fl' ? t('once.text.fl') : t('once.text', { x: esc(nl) })) + '</small></span></div>';
    }
    var text = m.text || m.cap ? '<span class="txt" data-raw="' + esc(m.text || m.cap) + '">' + hl(m.text || m.cap) + '</span>' : '';
    var meta = '<span class="b-meta">' + m.time + (m.k === 'out' && !fail ? tickHtml(m.tick) : '') + '</span>';
    var fr = fail ? '<div class="failrow">' + ic('alert', 'xs') + t('fail.text') + ' <button data-act="retry" data-i="' + thread(c).indexOf(m) + '">' + t('a.retry') + '</button></div>' : '';
    return '<div class="m ' + cls + (fail ? ' fail' : '') + '"><div class="b">' + head + body + text + meta + '</div>' + fr + '</div>';
  }
  function hl(s) {
    var q = (S.find || '').trim();
    var e = esc(s);
    if (!q) return e;
    var qe = esc(q).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return e.replace(new RegExp(qe, 'gi'), function (x) { return '<mark>' + x + '</mark>'; });
  }
  function chatMenu(c) {
    if (S.menu !== 'chat') return '';
    var b = '<button data-act="drawer" data-v="profile">' + ic('user') + t('a.profile') + '</button>' +
      '<button data-act="sheet" data-v="status">' + ic('flag') + t('a.status') + '</button>' +
      '<button data-act="sheet" data-v="labels">' + ic('tag') + t('a.labels') + '</button>';
    if (S.app === 'mgr') b += '<button data-act="drawer" data-v="handoff">' + ic('handoff') + t('a.handoff') + '</button>';
    b += '<button data-act="find">' + ic('search') + t('a.find') + '</button><button data-act="hide" data-id="' + c.id + '">' + ic('archive') + t('a.hide') + '</button>';
    return '<div class="pop tr">' + b + '</div>';
  }
  function composerHtml(c) {
    var off = S.app === 'fl' && has('disconnected');
    var note = S.mode === 'note';
    var hint = note ? t('cmp.note.h') : (S.app === 'mgr' ? t('cmp.as', { x: esc(NUMS[c.num].label), y: esc(NUMS[c.num].short) }) : '');
    var tpls = '';
    if (S.draft.charAt(0) === '/' && S.draft.indexOf(' ') < 0) {
      var list = TPL_TEAM.map(function (x) { return x.concat('team'); }).concat(TPL_MY[S.app].map(function (x) { return x.concat('my'); }))
        .filter(function (x) { return x[0].indexOf(S.draft) === 0; });
      if (list.length) tpls = '<div class="pop tpls"><div class="p-title">' + t('tpl.title') + '</div>' + list.map(function (x) {
        return '<button data-act="tpl" data-v="' + esc(x[1]) + '"><code>' + x[0] + '</code><span class="k">' + t('tpl.k.' + x[2]) + '</span><span class="x">' + esc(x[1]) + '</span></button>';
      }).join('') + '</div>';
    }
    var emoji = S.menu === 'emoji' ? '<div class="pop emoji">' + ['🙂', '😊', '👍', '🙏', '👌', '✅', '📅', '📎'].map(function (e) { return '<button data-act="emoji" data-v="' + e + '">' + e + '</button>'; }).join('') + '</div>' : '';
    return '<div class="cmp' + (note ? ' note' : '') + (off ? ' off' : '') + '">' + tpls + emoji +
      (off ? '<div class="cmp-off">' + ic('alert', 'xs') + t('cmp.off') + '</div>' : '') +
      '<div class="cmp-mode"><button data-act="mode" data-v="client" aria-pressed="' + !note + '">' + t('mode.client') + '</button>' +
      '<button data-act="mode" data-v="note" aria-pressed="' + note + '">' + ic('lock', 'xs') + t('mode.note') + '</button><span class="h">' + hint + '</span></div>' +
      '<div class="cmp-row"><div class="cmp-pill"><button class="ib" data-act="menu" data-v="emoji" aria-label="' + t('a.emoji') + '">' + ic('smile') + '</button>' +
      '<textarea rows="1" data-act="draft" placeholder="' + esc(t(note ? 'cmp.ph.note' : 'cmp.ph')) + '">' + esc(S.draft) + '</textarea>' +
      '<button class="ib" data-act="sheet" data-v="attach" aria-label="' + t('a.attach') + '">' + ic('clip') + '</button></div>' +
      '<button class="round' + (S.draft ? ' has' : '') + '" data-act="send" aria-label="' + t('a.send') + '"><span class="mic">' + ic('mic') + '</span><span class="s">' + ic('send') + '</span></button></div></div>';
  }
  function chatHtml() {
    var c = S.chat && byId(S.chat);
    if (S.loading === 'chat' || S.loading === 'all') {
      return '<div class="chead"><div class="chead-main"><div class="sk" style="width:40px;height:40px;border-radius:50%"></div><div class="sk-lines" style="max-width:200px"><div class="sk sk-l w60"></div><div class="sk sk-l w80"></div></div></div></div>' +
        '<div class="thread"><div class="sk" style="width:45%;height:40px"></div><div class="sk" style="width:55%;height:40px;align-self:flex-end"></div><div class="sk" style="width:35%;height:40px"></div><div class="sk" style="width:50%;height:56px;align-self:flex-end"></div></div>';
    }
    if (!c) return '<div class="placeholder"><div>' + ic('chat') + '<h2>' + t('ph.title') + '</h2><p>' + t('ph.text') + '</p></div></div>';
    var sub = S.app === 'mgr'
      ? esc(NUMS[c.num].label) + ' · <em>' + t('chat.as', { x: esc(NUMS[c.num].short) }) + '</em> · ' + t('st.' + c.st)
      : t('st.' + c.st) + (c.labels.length ? ' · ' + esc(c.labels.join(', ')) : '');
    var head = S.find != null
      ? '<div class="findbar"><button class="ib" data-act="findclose" aria-label="' + t('a.close') + '">' + ic('back') + '</button><input data-act="findq" value="' + esc(S.find) + '" placeholder="' + t('find.ph') + '"></div>'
      : '<div class="chead"><button class="ib phone-only" data-act="back" aria-label="' + t('a.back') + '">' + ic('back') + '</button>' +
        '<button class="chead-main" data-act="drawer" data-v="profile">' + avHtml(c, 'sm') + '<span class="chead-t"><b>' + esc(cname(c)) + '</b><span>' + sub + '</span></span></button>' +
        (S.app === 'mgr' && c.st !== 'handed' ? '<button class="btn pri sm desk-only" data-act="drawer" data-v="handoff">' + ic('handoff', 'sm') + t('a.handoff') + '</button>' : '') +
        '<button class="ib desk-only" data-act="find" aria-label="' + t('a.find') + '">' + ic('search') + '</button>' +
        '<button class="ib" data-act="menu" data-v="chat" aria-label="' + t('a.more') + '">' + ic('more') + '</button>' + chatMenu(c) + '</div>';
    var b = brief(c), pin = '';
    if (b) {
      pin = '<button class="pin' + (S.brief ? ' open' : '') + '" data-act="brief">' + ic('pin', 'sm') + '<span class="pin-t"><b>' + t(S.app === 'fl' ? 'brief.from' : 'brief.for', { x: esc(S.app === 'fl' ? b.by : NUMS[c.num].short) }) + ' · ' + b.time + '</b><span>' + esc(b.want) + ' · ' + esc(b.budget) + '</span></span>' + ic('chev', 'sm chev') + '</button>' +
        (S.brief ? '<div class="pin-body"><dl class="brief"><dt>' + t('brief.want') + '</dt><dd>' + esc(b.want) + '</dd><dt>' + t('brief.budget') + '</dt><dd>' + esc(b.budget) + '</dd><dt>' + t('brief.when') + '</dt><dd>' + esc(b.when) + '</dd><dt>' + t('brief.imp') + '</dt><dd>' + esc(b.imp) + '</dd></dl></div>' : '');
    }
    var notice = S.app === 'fl' && has('disconnected') ? '<div class="cnotice">' + ic('alert', 'sm') + '<span><b>' + t('fl.off.t') + '</b> ' + t('fl.off.d') + '</span></div>' : '';
    var th = '<div class="thread" id="thread">' + thread(c).map(function (m) { return msgHtml(m, c); }).join('') + '</div>';
    var cover = S.app === 'fl' && has('taken') ? '<div class="cover"><div class="cover-card"><div class="e-ico">' + ic('handoff') + '</div><h3>' + t('taken.t') + '</h3><p>' + t('taken.d') + '</p><button class="btn pri" data-act="back">' + t('a.tochats') + '</button></div></div>' : '';
    return head + notice + pin + th + composerHtml(c) + cover + previewHtml();
  }
  function previewHtml() {
    if (!S.preview) return '';
    var stage = S.preview === 'doc'
      ? '<div class="pv-doc"><div class="d-ico">PDF</div><b>Смета_кухня.pdf</b><br><small>PDF · 3 ' + t('pv.pages') + ' · 240 KB</small></div>'
      : '<div class="pv-img">' + ic('image', 'lg') + '</div>';
    var c = byId(S.chat);
    return '<div class="pv"><div class="pv-top"><button class="ib" data-act="pvclose" aria-label="' + t('a.close') + '">' + ic('x') + '</button><b>' + t('pv.title') + '</b></div>' +
      '<div class="pv-stage">' + stage + '</div><div class="pv-bottom">' +
      '<div class="pv-cap"><input id="pvcap" placeholder="' + t('pv.cap') + '"></div>' +
      '<div class="pv-row">' + (S.preview === 'photo' ? '<span class="pv-thumb"></span><button class="pv-add" aria-label="' + t('a.attach') + '">' + ic('plus') + '</button>' : '') +
      '<span class="pv-to">' + t('pv.to', { x: esc(cname(c)) }) + '</span><button class="round has" data-act="pvsend" aria-label="' + t('a.send') + '"><span class="s">' + ic('send') + '</span></button></div></div></div>';
  }

  /* ---------- Правая панель: данные клиента и передача ---------- */
  function drawerHtml() {
    var c = S.chat && byId(S.chat);
    if (!S.drawer || !c) return '';
    var x = '<button class="ib" data-act="drawerclose" aria-label="' + t('a.close') + '">' + ic('x') + '</button>';
    if (S.drawer === 'handoff') {
      var n = NUMS[c.num];
      var b = BRIEF.d1;
      return bar(t('ho.title'), null, '').replace('<div class="bar">', '<div class="bar">' + x) + '<div class="pf">' +
        '<div class="pf-sec"><h4>' + t('ho.to') + '</h4><div style="display:flex;gap:12px;align-items:center"><div class="av h1 sm">АВ<span class="tick-ok">' + ic('check', 'xs') + '</span></div><div class="grow"><b>' + esc(n.fr) + '</b><div class="faint small">' + t('ho.default', { x: esc(n.label) }) + '</div></div></div>' +
        (S.other
          ? '<div style="margin-top:12px"><select class="sel" aria-label="' + t('ho.to') + '"><option>' + esc(n.fr) + '</option><option>Олег Сурин</option><option>Марина Лис</option></select><div class="callout warn" style="margin:10px 0 0">' + ic('alert', 'sm') + '<span>' + t('ho.warn', { x: esc(n.label), y: esc(n.short) }) + '</span></div></div>'
          : '<button class="linkbtn small" style="margin-top:10px" data-act="other">' + t('ho.other') + '</button>') + '</div>' +
        '<div class="pf-sec"><h4>' + t('ho.brief') + '</h4><textarea class="ta" rows="7">' + t('brief.want') + ': ' + esc(b.want) + '\n' + t('brief.budget') + ': ' + esc(b.budget) + '\n' + t('brief.when') + ': ' + esc(b.when) + '\n' + t('brief.imp') + ': ' + esc(b.imp) + '</textarea>' +
        '<div class="hint">' + t('ho.hint') + '</div></div>' +
        '<div class="pf-sec"><button class="btn pri block" data-act="dohandoff">' + t('ho.do', { x: esc(n.short) }) + '</button></div></div>';
    }
    var mgr = S.app === 'mgr';
    var nameBlock = S.rename
      ? '<div class="pf-ren"><input class="inp" id="renin" value="' + esc(c.name || '') + '" placeholder="' + t('rename.ph') + '"><button class="btn pri sm" data-act="renok">' + t('a.save') + '</button></div>'
      : '<button class="pf-name" data-act="rename"><span>' + esc(cname(c)) + '</span>' + ic('pencil') + '</button>';
    var b2 = brief(c);
    var other = mgr && c.other ? '<div class="pf-sec"><h4>' + t('pf.other') + '</h4>' + c.other.map(function (o) {
      return '<div class="pf-row">' + ic('chat') + '<span class="k"><b>' + esc(NUMS[o[0]].label) + '</b><small>' + o[1] + '</small></span>' + stHtml(o[2]) + '</div>';
    }).join('') + '</div>' : '';
    return '<div class="bar">' + x + '<h2>' + t('pf.title') + '</h2></div><div class="pf">' +
      '<div class="pf-sec pf-top">' + avHtml(c, 'xl') + nameBlock +
      (mgr ? '<div class="pf-sub">' + esc(c.phone) + ' <button class="ib" style="width:30px;height:30px" data-act="copy" aria-label="' + t('a.copy') + '">' + ic('copy', 'xs') + '</button></div><div class="faint small">' + t('pf.via', { x: esc(NUMS[c.num].label), y: esc(NUMS[c.num].fr) }) + '</div>' : '<div class="faint small" style="margin-top:6px">' + t('pf.nophone') + '</div>') + '</div>' +
      '<div class="pf-sec">' + '<button class="pf-row" data-act="sheet" data-v="status">' + ic('flag') + '<span class="k"><b>' + t('pf.status') + '</b></span>' + stHtml(c.st) + ic('right', 'sm faint') + '</button>' +
      (mgr ? '<div class="pf-row">' + ic('user') + '<span class="k"><b>' + t('pf.handler') + '</b></span><span class="v">' + esc(handlerName(c)) + '</span></div>' : '') +
      '<button class="pf-row" data-act="sheet" data-v="labels">' + ic('tag') + '<span class="k"><b>' + t('pf.labels') + '</b>' + (c.labels.length ? '' : '<small>' + t('pf.nolabels') + '</small>') + '</span>' + ic('right', 'sm faint') + '</button>' +
      (c.labels.length ? '<div class="tags" style="padding:0 0 6px 36px">' + c.labels.map(function (l) { return '<span class="tag lbl">' + esc(l) + '</span>'; }).join('') + '</div>' : '') + '</div>' +
      '<div class="pf-sec"><h4>' + t('pf.deal') + '</h4><label class="fld"><span>' + t('deal.budget') + '</span><input class="inp" value="' + (c.id === 'd1' ? '200 000 – 250 000' : (c.id === 'c49' || c.id === 'd3' ? 'до 150 000' : '')) + '"></label>' +
      '<label class="fld"><span>' + t('deal.sum') + '</span><input class="inp" placeholder="—"></label>' +
      '<label class="fld" style="margin:0"><span>' + t('deal.reason') + '</span><input class="inp" value="' + esc(c.reason || '') + '" placeholder="' + t('deal.reason.ph') + '"></label></div>' +
      (b2 ? '<div class="pf-sec"><h4>' + t('pf.brief') + ' · ' + esc(b2.by) + ', ' + b2.time + '</h4><dl class="brief"><dt>' + t('brief.want') + '</dt><dd>' + esc(b2.want) + '</dd><dt>' + t('brief.budget') + '</dt><dd>' + esc(b2.budget) + '</dd><dt>' + t('brief.when') + '</dt><dd>' + esc(b2.when) + '</dd><dt>' + t('brief.imp') + '</dt><dd>' + esc(b2.imp) + '</dd></dl></div>' : '') +
      other +
      '<div class="pf-sec">' + (mgr && c.st !== 'handed' ? setRow('handoff', t('a.handoff'), '', 'drawer', 'handoff') : '') +
      '<button class="pf-row red" data-act="hide" data-id="' + c.id + '">' + ic('archive') + '<span class="k"><b>' + t('a.hide') + '</b><small>' + t('hide.only') + '</small></span></button></div></div>';
  }

  /* ---------- Панели настроек ---------- */
  function panelTg() {
    var sw = function (k, on) { return '<div class="pf-row"><span class="k"><b>' + t(k) + '</b><small>' + t(k + '.d') + '</small></span><label class="sw"><input type="checkbox"' + (on ? ' checked' : '') + ' aria-label="' + t(k) + '"><i></i></label></div>'; };
    var tg = S.tg
      ? '<div class="card"><h3>' + t('tg.title') + '</h3><div class="callout ok">' + ic('check', 'sm') + '<span>' + t('tg.linked', { x: '12.11' }) + '</span></div><div class="row2"><button class="btn sm">' + t('tg.test') + '</button><button class="btn sm red" data-act="tg" data-v="0">' + t('tg.unlink') + '</button></div></div>'
      : '<div class="card"><h3>' + t('tg.title') + '</h3><p>' + t('tg.lead') + '</p><ol class="steps"><li>' + t('tg.s1') + '</li><li>' + t('tg.s2') + '</li></ol><div class="code">482 913</div>' +
        '<div class="row2"><button class="btn sm" data-act="copy">' + ic('copy', 'xs') + t('a.copy') + '</button><button class="btn sm">' + ic('refresh', 'xs') + t('tg.new') + '</button><span class="faint small">' + t('tg.ttl') + '</span></div>' +
        '<div class="hint"><button class="linkbtn" data-act="tg" data-v="1">' + t('tg.demo') + '</button></div></div>';
    var list = S.app === 'mgr'
      ? sw('n.newclient', true) + sw('n.waiting', true) + sw('n.numoff', true)
      : sw('n.mymsg', true) + sw('n.handed', true) + sw('n.waiting', true) + sw('n.numoff', true);
    return tg + '<div class="card"><h3>' + t('notif.title') + '</h3><p>' + t('notif.lead') + '</p>' + list + '</div>';
  }
  function tplList(arr, edit) {
    return arr.map(function (x) {
      return '<div class="tpl"><code>' + x[0] + '</code><p>' + esc(x[1]) + '</p>' + (edit ? '<button class="ib" data-act="sheet" data-v="tpledit" aria-label="' + t('a.edit') + '">' + ic('pencil', 'sm') + '</button><button class="ib" aria-label="' + t('a.delete') + '">' + ic('trash', 'sm') + '</button>' : '') + '</div>';
    }).join('');
  }
  function panelTpl() {
    return '<div class="card"><h3>' + t('tpl.my') + '</h3><p>' + t('tpl.my.d') + '</p>' + tplList(TPL_MY[S.app], true) +
      '<button class="btn sm" style="margin-top:8px" data-act="sheet" data-v="tpledit">' + ic('plus', 'xs') + t('tpl.add') + '</button></div>' +
      '<div class="card"><h3>' + t('tpl.team') + '</h3><p>' + t('tpl.team.d') + '</p>' + tplList(TPL_TEAM, false) + '</div>';
  }
  function pageWrap(title, inner) {
    return '<div class="bar"><button class="ib phone-only" data-act="back" aria-label="' + t('a.back') + '">' + ic('back') + '</button><h2>' + title + '</h2></div><div class="page"><div class="page-in">' + inner + '</div></div>';
  }
  var QR = (function () {
    var N = 25, g = [], seed = 7, x, y;
    function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    for (y = 0; y < N; y++) { g.push([]); for (x = 0; x < N; x++) g[y].push(rnd() < .5); }
    function fi(ox, oy) {
      for (var i = -1; i < 8; i++) for (var j = -1; j < 8; j++) {
        if (ox + i < 0 || oy + j < 0 || ox + i >= N || oy + j >= N) continue;
        g[oy + j][ox + i] = i >= 0 && i <= 6 && j >= 0 && j <= 6 && (i === 0 || i === 6 || j === 0 || j === 6 || (i >= 2 && i <= 4 && j >= 2 && j <= 4));
      }
    }
    fi(0, 0); fi(N - 7, 0); fi(0, N - 7);
    var d = '';
    for (y = 0; y < N; y++) for (x = 0; x < N; x++) if (g[y][x]) d += 'M' + x + ' ' + y + 'h1v1h-1z';
    return '<svg viewBox="0 0 25 25" shape-rendering="crispEdges" role="img" aria-label="QR"><path fill="#111" d="' + d + '"/></svg>';
  })();
  function qrBlock(label, okAct) {
    return '<div class="card"><h3>' + t('qr.title', { x: esc(label) }) + '</h3><p>' + t('qr.lead') + '</p><div class="qr-wrap"><div class="qr">' + QR + '</div><ol class="steps"><li>' + t('qr.s1') + '</li><li>' + t('qr.s2') + '</li><li>' + t('qr.s3') + '</li></ol></div>' +
      '<p class="faint small" style="margin:12px 0">' + t('qr.timer', { x: '0:42' }) + '</p><div class="row2"><button class="btn pri" data-act="' + okAct + '">' + t('qr.done') + '</button><button class="btn" data-act="qrcancel">' + t('a.cancel') + '</button></div></div>';
  }
  function mainNumbers() {
    if (S.add) {
      var steps = ['name', 'qr', 'assign'];
      var sp = '<div class="stepper">' + steps.map(function (s, i) {
        var cur = steps.indexOf(S.add); return '<span class="' + (i === cur ? 'on' : (i < cur ? 'done' : '')) + '">' + (i + 1) + '. ' + t('num.step.' + s) + '</span>';
      }).join('') + '</div>';
      var body;
      if (S.add === 'name') body = '<div class="card"><label class="fld"><span>' + t('num.name') + '</span><input class="inp" value="Номер Веры" placeholder="' + t('num.name.ph') + '"></label>' +
        '<div class="callout warn">' + ic('alert', 'sm') + '<span>' + t('num.pool.warn') + '</span></div><button class="btn pri" data-act="addstep" data-v="qr">' + t('num.next') + '</button></div>';
      else if (S.add === 'qr') body = qrBlock('Номер Веры', 'addstep" data-v="assign');
      else body = '<div class="card"><div class="callout ok">' + ic('check', 'sm') + '<span>' + t('num.connected', { x: 'Номер Веры', y: '+1 555 0104 5506' }) + '</span></div>' +
        '<label class="fld"><span>' + t('num.assign') + '</span><select class="sel"><option>Вера Седова</option><option>' + t('fr.nonum.opt') + '</option></select></label><div class="hint" style="margin:-6px 0 14px">' + t('num.assign.h') + '</div>' +
        '<button class="btn pri" data-act="adddone">' + t('a.save') + '</button></div>';
      return pageWrap(t('num.add'), sp + body);
    }
    var n = NUMS[S.num];
    var inner = '';
    if (n.on === 'qr' || S.qr) inner = qrBlock(n.label, 'qrok');
    else {
      inner = '<div class="card"><div class="row2" style="justify-content:space-between"><h3 style="margin:0">' + esc(n.label) + '</h3><span class="conn ' + n.on + '">' + t('conn.' + n.on) + '</span></div>' +
        '<div class="kv"><span>' + t('num.phone') + '</span><span>' + esc(n.phone) + '</span></div>' +
        '<div class="kv"><span>' + t('num.fr') + '</span><span>' + esc(n.fr) + ' <button class="linkbtn small" data-act="sheet" data-v="numfr">' + t('num.change') + '</button></span></div>' +
        '<div class="kv"><span>' + t('num.seen') + '</span><span>' + (n.on === 'on' ? t('conn.now') : t('conn.ago', { x: n.seen })) + '</span></div>' +
        (n.on === 'off' ? '<div class="callout red" style="margin-top:10px">' + ic('alert', 'sm') + '<span>' + t('num.off.d') + '</span></div><button class="btn pri" data-act="reconnect">' + ic('qr', 'sm') + t('a.reconnect') + '</button>' : '') + '</div>' +
        '<div class="card"><button class="pf-row red" data-act="sheet" data-v="numoff">' + ic('power') + '<span class="k"><b>' + t('num.disable') + '</b><small>' + t('num.disable.d') + '</small></span></button></div>';
    }
    return pageWrap(n.label, inner);
  }
  function mainFreelancers() {
    if (S.fr === 'add') return pageWrap(t('fr.add'), '<div class="card"><label class="fld"><span>' + t('fr.name') + '</span><input class="inp" value="Вера Седова"></label>' +
      '<label class="fld"><span>' + t('fr.num') + '</span><select class="sel"><option>' + t('fr.nonum.opt') + '</option><option disabled>Номер Анны — Анна Ветрова</option><option disabled>Номер Олега — Олег Сурин</option><option disabled>Номер Марины — Марина Лис</option></select><div class="hint">' + t('fr.num.h') + '</div></label>' +
      '<button class="btn pri" data-act="pick" data-k="fr" data-v="invite">' + ic('link', 'sm') + t('fr.invite.do') + '</button></div>');
    if (S.fr === 'invite') return pageWrap(t('fr.invite.t'), '<div class="card"><div class="callout ok">' + ic('check', 'sm') + '<span>' + t('fr.invite.ok', { x: 'Вера Седова' }) + '</span></div>' +
      '<div class="kv"><span>' + t('fr.login') + '</span><span><b>vera.s</b> <span class="faint small">' + t('fr.login.auto') + '</span></span></div>' +
      '<label class="fld" style="margin-top:8px"><span>' + t('fr.link') + '</span><div class="linkbox"><input class="inp" readonly value="https://chat.example.test/i/k3v9-2xq7-77mf"><button class="btn sm" data-act="copy">' + ic('copy', 'xs') + t('a.copy') + '</button></div></label>' +
      '<div class="callout">' + ic('clock', 'sm') + '<span>' + t('fr.link.d') + '</span></div></div>');
    var f = FREEL.filter(function (x) { return x.id === S.fr; })[0];
    var n = f.num ? NUMS[f.num] : null;
    return pageWrap(f.name, '<div class="card"><div class="row2" style="justify-content:space-between"><h3 style="margin:0">' + esc(f.name) + '</h3>' + (f.off ? '<span class="conn no">' + t('fr.off') + '</span>' : '') + '</div>' +
      '<div class="kv"><span>' + t('fr.login') + '</span><span>' + f.login + '</span></div>' +
      '<div class="kv"><span>' + t('fr.num') + '</span><span>' + (n ? esc(n.label) + ' <span class="conn ' + n.on + '">' + t('conn.' + n.on) + '</span>' : t('fr.nonum')) + ' <button class="linkbtn small" data-act="sheet" data-v="frnum">' + t('num.change') + '</button></span></div>' +
      '<div class="kv"><span>' + t('fr.clients.k') + '</span><span>' + f.clients + '</span></div>' +
      '<div class="kv"><span>Telegram</span><span class="' + (f.tg ? 'sub-ok' : '') + '">' + t(f.tg ? 'tg.yes' : 'tg.no') + '</span></div></div>' +
      '<div class="card">' + setRow('key', t('fr.newlink'), t('fr.newlink.d'), 'pick', 'invite').replace('data-act="pick" data-v="invite"', 'data-act="pick" data-k="fr" data-v="invite"') +
      '<button class="pf-row red" data-act="toast" data-v="toast.disabled">' + ic('power') + '<span class="k"><b>' + t(f.off ? 'fr.enable' : 'fr.disable') + '</b><small>' + t('fr.disable.d') + '</small></span></button></div>');
  }
  function mainTeam() {
    var s = S.team, inner;
    if (s === 'hours') {
      inner = '<div class="card"><p>' + t('team.hours.d') + '</p><div class="fld"><span>' + t('team.days') + '</span><div class="days">' +
        [0, 1, 2, 3, 4, 5, 6].map(function (d) { return '<button data-act="toggle" aria-pressed="' + (d < 5) + '">' + t('day.' + d) + '</button>'; }).join('') + '</div></div>' +
        '<div class="fld"><span>' + t('team.time') + '</span><div class="row2"><input class="inp time" type="time" value="09:00" aria-label="from"> — <input class="inp time" type="time" value="20:00" aria-label="to"></div></div>' +
        '<label class="fld"><span>' + t('team.tz') + '</span><select class="sel" style="max-width:220px"><option>UTC+02:00</option><option selected>UTC+03:00</option><option>UTC+04:00</option></select></label></div>';
    } else if (s === 'wait') {
      inner = '<div class="card"><p>' + t('team.wait.d') + '</p><div class="fld"><span>' + t('team.wait.work') + '</span><div class="row2"><input class="inp num" type="number" value="10" aria-label="min"><span class="muted">' + t('unit.min') + '</span></div></div>' +
        '<div class="fld"><span>' + t('team.wait.off') + '</span><div class="row2"><input class="inp num" type="number" value="60" aria-label="min"><span class="muted">' + t('unit.min') + '</span></div></div></div>';
    } else if (s === 'tglang') {
      inner = '<div class="card"><p>' + t('team.tglang.d') + '</p><select class="sel" style="max-width:220px" aria-label="lang"><option>Русский</option><option>English</option></select></div>';
    } else if (s === 'tpl') {
      inner = '<div class="card"><p>' + t('tpl.team.d') + '</p>' + tplList(TPL_TEAM, true) + '<button class="btn sm" style="margin-top:8px" data-act="sheet" data-v="tpledit">' + ic('plus', 'xs') + t('tpl.add') + '</button></div>';
    } else {
      var arr = s === 'reasons' ? REASONS : LABELS;
      inner = '<div class="card"><p>' + t('team.' + s + '.d') + '</p><div class="tags">' + arr.map(function (r) { return '<span class="chipx">' + esc(r) + '<button data-act="rmchip" aria-label="' + t('a.delete') + '">' + ic('x', 'xs') + '</button></span>'; }).join('') +
        (s === 'reasons' ? '<span class="chipx fixed">' + t('reason.other') + '</span>' : '') + '</div><div class="row2" style="margin-top:12px"><input class="inp grow" placeholder="' + t('team.new.ph') + '"><button class="btn sm">' + t('a.add') + '</button></div></div>';
    }
    return pageWrap(t('team.' + s), inner + '<button class="btn pri">' + t('a.save') + '</button>');
  }
  function mainHtml() {
    if (S.side === 'numbers') return mainNumbers();
    if (S.side === 'freelancers') return mainFreelancers();
    if (S.side === 'team') return mainTeam();
    if (S.app === 'mgr' && S.side === 'settings') return S.me === 'tpl' ? pageWrap(t('set.tpl'), panelTpl()) : pageWrap(t('set.notif'), panelTg());
    return chatHtml();
  }

  /* ---------- Шторки ---------- */
  function sheetHtml() {
    if (!S.sheet) return '';
    var c = byId(S.sheet_id || S.chat) || CH[0];
    var title = '', body = '', foot = '', sub = '';
    if (S.sheet === 'status') {
      title = t('a.status');
      var opts = S.app === 'mgr' ? ST_ALL : ST_FL;
      if (S.app === 'fl') sub = t('sheet.st.now', { x: t('st.' + c.st) });
      body = opts.map(function (s) { return '<button class="opt' + (c.st === s ? ' on' : '') + '" data-act="setst" data-v="' + s + '"><span class="rd"></span>' + stHtml(s) + '</button>'; }).join('');
    } else if (S.sheet === 'reason') {
      title = t('reason.title');
      body = REASONS.concat([t('reason.other')]).map(function (r, i) { return '<button class="opt' + (S.reason === i ? ' on' : '') + '" data-act="reason" data-v="' + i + '"><span class="rd"></span>' + esc(r) + '</button>'; }).join('') +
        (S.reason === REASONS.length ? '<div style="padding:4px 12px 8px"><input class="inp" placeholder="' + t('reason.other.ph') + '"></div>' : '');
      foot = '<button class="btn" data-act="close">' + t('a.cancel') + '</button><button class="btn pri" data-act="reasonok">' + t('a.save') + '</button>';
    } else if (S.sheet === 'labels') {
      title = t('a.labels'); sub = t('labels.hint');
      body = LABELS.map(function (l) { var on = c.labels.indexOf(l) >= 0; return '<button class="opt' + (on ? ' on' : '') + '" data-act="label" data-v="' + esc(l) + '"><span class="cb">' + ic('check', 'xs') + '</span>' + esc(l) + '</button>'; }).join('');
      foot = '<button class="btn pri" data-act="close">' + t('a.done') + '</button>';
    } else if (S.sheet === 'attach') {
      return '<div class="sh-back" data-act="close"></div><div class="sheet"><div class="sh-grab"></div><div class="attach-grid">' +
        '<button data-act="preview" data-v="photo"><span class="ci c1">' + ic('image') + '</span>' + t('att.photo') + '</button>' +
        '<button data-act="preview" data-v="photo"><span class="ci c3">' + ic('camera') + '</span>' + t('att.camera') + '</button>' +
        '<button data-act="preview" data-v="doc"><span class="ci c2">' + ic('file') + '</span>' + t('att.doc') + '</button></div></div>';
    } else if (S.sheet === 'lang') {
      title = t('set.lang');
      body = [['ru', 'Русский'], ['en', 'English']].map(function (l) { return '<button class="opt' + (lang === l[0] ? ' on' : '') + '" data-act="lang" data-v="' + l[0] + '"><span class="rd"></span>' + l[1] + '</button>'; }).join('');
    } else if (S.sheet === 'theme') {
      title = t('set.theme');
      body = ['light', 'dark', 'system'].map(function (v) { return '<button class="opt' + (theme === v ? ' on' : '') + '" data-act="theme" data-v="' + v + '"><span class="rd"></span>' + t('theme.' + v) + '</button>'; }).join('');
    } else if (S.sheet === 'tpledit') {
      title = t('tpl.edit');
      body = '<div class="sh-body pad" style="padding:0 12px"><label class="fld"><span>' + t('tpl.cmd') + '</span><input class="inp" value="/"></label><label class="fld"><span>' + t('tpl.text') + '</span><textarea class="ta" rows="4"></textarea></label></div>';
      foot = '<button class="btn" data-act="close">' + t('a.cancel') + '</button><button class="btn pri" data-act="close">' + t('a.save') + '</button>';
    } else if (S.sheet === 'numfr' || S.sheet === 'frnum') {
      var isNum = S.sheet === 'numfr';
      title = t(isNum ? 'num.change.t' : 'fr.num.t');
      body = '<div style="padding:0 12px"><select class="sel" aria-label="' + title + '">' + (isNum ? FREEL.filter(function (f) { return !f.off; }).map(function (f) { return '<option>' + esc(f.name) + '</option>'; }).join('')
        : Object.keys(NUMS).map(function (k) { return '<option>' + esc(NUMS[k].label) + '</option>'; }).join('') + '<option>' + t('fr.nonum.opt') + '</option>') + '</select>' +
        '<div class="callout warn" style="margin-top:12px">' + ic('alert', 'sm') + '<span>' + t('num.change.warn') + '</span></div></div>';
      foot = '<button class="btn" data-act="close">' + t('a.cancel') + '</button><button class="btn pri" data-act="close">' + t('a.save') + '</button>';
    } else if (S.sheet === 'numoff') {
      title = t('num.disable.q', { x: esc(NUMS[S.num].label) });
      body = '<div style="padding:0 12px"><div class="callout red">' + ic('alert', 'sm') + '<span>' + t('num.disable.warn') + '</span></div></div>';
      foot = '<button class="btn" data-act="close">' + t('a.cancel') + '</button><button class="btn pri" style="background:var(--red);border-color:var(--red);color:#fff" data-act="numoffok">' + t('num.disable') + '</button>';
    }
    return '<div class="sh-back" data-act="close"></div><div class="sheet" role="dialog" aria-label="' + esc(title) + '"><div class="sh-grab"></div><div class="sh-head">' + title + '</div>' +
      (sub ? '<div class="sh-sub">' + sub + '</div>' : '') + '<div class="sh-body">' + body + '</div>' + (foot ? '<div class="sh-foot">' + foot + '</div>' : '') + '</div>';
  }

  /* ---------- Вход ---------- */
  function authHtml() {
    var logo = '<div class="auth-logo">' + ic('chat') + '</div>';
    var inner;
    if (S.auth === 'invite') {
      inner = logo + '<h1>' + t('auth.inv.t', { x: 'Вера' }) + '</h1><p>' + t('auth.inv.d') + '</p>' +
        '<label class="fld"><span>' + t('fr.login') + '</span><input class="inp" readonly value="vera.s"></label>' +
        '<label class="fld"><span>' + t('auth.pw') + '</span><input class="inp" type="password" value="password1"></label>' +
        '<label class="fld"><span>' + t('auth.pw2') + '</span><input class="inp" type="password" value="password1"><div class="hint">' + t('auth.pw.h') + '</div></label>' +
        '<button class="btn pri block" data-act="authgo">' + t('auth.inv.do') + '</button><div class="hint" style="margin-top:12px;text-align:center">' + t('auth.inv.exp', { x: '24.11, 12:30' }) + '</div>';
    } else if (S.auth === 'expired') {
      inner = '<div class="e-ico">' + ic('link') + '</div><h1>' + t('auth.exp.t') + '</h1><p>' + t('auth.exp.d') + '</p><button class="btn pri block" data-act="auth" data-v="login">' + t('auth.tologin') + '</button>';
    } else {
      inner = logo + '<h1>' + t('auth.login.t') + '</h1><p>' + t('auth.login.d') + '</p>' +
        (S.auth === 'loginerr' ? '<div class="callout red">' + ic('alert', 'sm') + '<span>' + t('auth.err') + '</span></div>' : '') +
        '<label class="fld"><span>' + t('fr.login') + '</span><input class="inp" value="anna.v" autocomplete="off"></label>' +
        '<label class="fld"><span>' + t('auth.pw') + '</span><input class="inp" type="password" value="12345678"></label>' +
        '<button class="btn pri block" data-act="authgo">' + t('auth.login.do') + '</button>' +
        '<div style="text-align:center;margin-top:14px"><button class="linkbtn small" data-act="forgot">' + t('auth.forgot') + '</button></div>' +
        (S.forgot ? '<div class="callout" style="margin:12px 0 0">' + ic('key', 'sm') + '<span>' + t('auth.forgot.d') + '</span></div>' : '');
    }
    return '<div class="auth"><div class="auth-card">' + inner + '</div></div>';
  }

  /* ---------- Отрисовка ---------- */
  var app;
  function render() {
    root.lang = lang;
    document.title = t('mock.title');
    if (S.app === 'auth') { app.innerHTML = authHtml(); return; }
    var banner = S.app === 'mgr' && has('disconnected') ? '<div class="banner" role="alert">' + ic('alert', 'sm') + '<span><b>' + t('banner.t', { x: 'Номер Олега' }) + '</b> ' + t('banner.d') + '</span><button class="btn" data-act="reconnect" data-num="oleg">' + t('a.reconnect') + '</button></div>' : '';
    var focus = S.drawer && S.chat ? 'drawer' : S.focus;
    app.innerHTML = banner + '<div class="wa" data-focus="' + focus + '"><aside class="side">' + sideHtml() + '</aside><section class="main">' + mainHtml() + '</section>' +
      (S.drawer && S.chat ? '<aside class="drawer">' + drawerHtml() + '</aside>' : '') + sheetHtml() +
      (S.toast ? '<div class="toast"><span>' + t(S.toast) + '</span>' + (S.toast === 'toast.hidden' ? '<button data-act="undo">' + t('a.undo') + '</button>' : '') + '</div>' : '') + '</div>';
    var th = document.getElementById('thread');
    if (th) th.scrollTop = th.scrollHeight;
  }
  var toastTimer;
  function toast(k) { S.toast = k; clearTimeout(toastTimer); toastTimer = setTimeout(function () { S.toast = null; render(); }, 3500); }
  function closeAll() { S.menu = null; S.sheet = null; S.sheet_id = null; }
  var lastHidden = null;

  function act(a, el, e) {
    var v = el.dataset.v, id = el.dataset.id;
    switch (a) {
      case 'open':
        if (suppress) { suppress = false; return; }
        if (S.select) { S.select = null; break; }
        if (e.target.closest('.crow-menu, .pop')) return;
        var c = byId(id); if (c) { c.unread = 0; }
        S.chat = id; S.focus = 'main'; S.menu = null; S.find = null; S.preview = null; S.drawer = S.drawer === 'profile' ? 'profile' : null; break;
      case 'pick': S[el.dataset.k] = v; S.focus = 'main'; S.qr = false; S.add = null; if (S.side === 'numbers') { S.qr = NUMS[v] && NUMS[v].on === 'qr'; } break;
      case 'tab': S.tab = v; break;
      case 'menu': S.menu = S.menu === v ? null : v; break;
      case 'close': closeAll(); break;
      case 'side': closeAll(); S.side = v; S.focus = 'side'; if (v === 'numbers' || v === 'freelancers' || v === 'team') S.focus = 'side';
        if (v === 'settings' && S.app === 'mgr') S.me = S.me || 'tg'; break;
      case 'side-list': S.side = 'list'; S.focus = 'side'; break;
      case 'side-settings': S.side = 'settings'; break;
      case 'me': S.me = v; S.focus = 'main'; break;
      case 'back': S.focus = 'side'; S.find = null; S.preview = null; if (S.app === 'fl' && has('taken')) { S.sc = S.sc.filter(function (x) { return x !== 'taken'; }); FL.splice(0, 1); S.chat = null; } break;
      case 'drawer': closeAll(); S.drawer = v; S.rename = false; break;
      case 'drawerclose': S.drawer = null; S.other = false; S.rename = false; break;
      case 'other': S.other = true; break;
      case 'dohandoff': var hc = byId(S.chat); hc.st = 'handed'; hc.handler = 'Анна'; hc.briefId = 'd1'; S.sc.push('handed'); S.drawer = null; toast('toast.handed'); break;
      case 'sheet': S.menu = null; S.sheet = v; S.sheet_id = id || null; if (v === 'reason') S.reason = 0; break;
      case 'setst':
        var sc = byId(S.sheet_id || S.chat);
        if (v === 'lost') { S.sheet = 'reason'; S.reason = 0; break; }
        if (v === 'handed' && S.app === 'mgr') { closeAll(); S.drawer = 'handoff'; break; }
        sc.st = v; thread(sc).push({ k: 'sys', key: 'sys.st', st: v, time: now() }); closeAll(); break;
      case 'reason': S.reason = +v; break;
      case 'reasonok':
        var rc = byId(S.sheet_id || S.chat); rc.st = 'lost'; rc.reason = S.reason < REASONS.length ? REASONS[S.reason] : t('reason.other');
        thread(rc).push({ k: 'sys', key: 'sys.st', st: 'lost', time: now() }); closeAll(); break;
      case 'label': var lc = byId(S.sheet_id || S.chat); var li = lc.labels.indexOf(v); if (li >= 0) lc.labels.splice(li, 1); else lc.labels.push(v); break;
      case 'hide': var hcx = byId(id); hcx.hidden = 1; lastHidden = hcx; closeAll(); S.select = null;
        if (S.chat === id) { S.chat = null; S.drawer = null; S.focus = 'side'; } toast('toast.hidden'); break;
      case 'unhide': byId(id).hidden = 0; closeAll(); toast('toast.unhidden'); break;
      case 'undo': if (lastHidden) lastHidden.hidden = 0; S.toast = null; break;
      case 'unselect': S.select = null; break;
      case 'find': closeAll(); S.find = ''; break;
      case 'findclose': S.find = null; break;
      case 'brief': S.brief = !S.brief; break;
      case 'mode': S.mode = v; break;
      case 'emoji': S.draft += v; S.menu = null; break;
      case 'tpl': S.draft = v; break;
      case 'send': sendText(); return;
      case 'preview': S.sheet = null; S.preview = v; break;
      case 'pvclose': S.preview = null; break;
      case 'pvsend':
        var cap = (document.getElementById('pvcap') || {}).value || '';
        var pc = byId(S.chat);
        var msg = S.preview === 'doc' ? { k: 'out', by: ME, media: 'doc', name: 'Смета_кухня.pdf', size: 'PDF · 240 KB', cap: cap, time: now(), tick: 'pending' } : { k: 'out', by: ME, media: 'photo', cap: cap, time: now(), tick: 'pending' };
        thread(pc).push(msg); S.preview = null; later(msg); break;
      case 'retry': var rm = thread(byId(S.chat))[+el.dataset.i]; rm.tick = 'pending'; delete rm.sc; later(rm); break;
      case 'voice': var vb = el.closest('.voice'); vb.classList.add('go'); vb.classList.toggle('on'); return;
      case 'rename': S.rename = true; render(); var ri = document.getElementById('renin'); if (ri) { ri.focus(); ri.select(); } return;
      case 'renok': var nc = byId(S.chat); var nv = document.getElementById('renin').value.trim(); nc.name = nv || null; S.rename = false; break;
      case 'copy': toast('toast.copied'); break;
      case 'lang': setLang(v); closeAll(); break;
      case 'theme': setTheme(v); closeAll(); break;
      case 'tg': S.tg = v === '1'; break;
      case 'logout': S.app = 'auth'; S.auth = 'login'; break;
      case 'auth': S.auth = v; break;
      case 'authgo': if (S.auth === 'login' && P.get('auth') === 'loginerr') { S.auth = 'loginerr'; break; } location.search = '?app=fl'; return;
      case 'forgot': S.forgot = true; break;
      case 'fset': S[el.dataset.k] = v; S.menu = null; break;
      case 'fclear': S[v] = ''; break;
      case 'reconnect': S.side = 'numbers'; S.num = el.dataset.num || S.num; S.qr = true; S.add = null; S.focus = 'main'; break;
      case 'qrok': NUMS[S.num].on = 'on'; NUMS[S.num].seen = 0; S.qr = false; S.sc = S.sc.filter(function (x) { return x !== 'disconnected'; }); toast('toast.connected'); break;
      case 'qrcancel': S.qr = false; if (S.add) S.add = null; if (NUMS[S.num].on === 'qr') NUMS[S.num].on = 'off'; break;
      case 'addnum': S.add = 'name'; S.focus = 'main'; break;
      case 'addstep': S.add = v; break;
      case 'adddone': NUMS.vera = { label: 'Номер Веры', phone: '+1 555 0104 5506', fr: 'Вера Седова', short: 'Вера', on: 'on', seen: 0 }; S.add = null; S.num = 'vera'; toast('toast.numadded'); break;
      case 'numoffok': NUMS[S.num].on = 'off'; NUMS[S.num].seen = 0; closeAll(); toast('toast.numoff'); break;
      case 'toggle': el.setAttribute('aria-pressed', String(el.getAttribute('aria-pressed') !== 'true')); return;
      case 'rmchip': el.closest('.chipx').remove(); return;
      case 'toast': toast(v); break;
      default: return;
    }
    render();
  }
  function later(m) { render(); setTimeout(function () { m.tick = 'sent'; render(); }, 700); setTimeout(function () { m.tick = 'deliv'; render(); }, 1600); }
  function sendText() {
    var text = S.draft.trim(); if (!text) return;
    var c = byId(S.chat);
    var m = S.mode === 'note' ? { k: 'note', by: ME, text: text, time: now() } : { k: 'out', by: ME, text: text, time: now(), tick: 'pending' };
    thread(c).push(m); S.draft = '';
    if (m.k === 'out') { c.from = 'me'; c.last = text; c.wait = 0; later(m); } else render();
    var ta = document.querySelector('.cmp textarea'); if (ta) ta.focus();
  }
  function setLang(l) { lang = l; store.set('mock-lang', l); }
  function setTheme(v) { applyTheme(v); store.set('mock-theme', v); }

  var suppress = false, pressTimer = null;
  function bootApp() {
    document.body.insertAdjacentHTML('afterbegin', SPRITE);
    app = document.getElementById('app');
    render();
    app.addEventListener('click', function (e) {
      var el = e.target.closest('[data-act]');
      if (!el) { if (S.menu) { S.menu = null; render(); } return; }
      if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') return;
      if (S.menu && !e.target.closest('.pop') && el.dataset.act !== 'menu') S.menu = null;
      act(el.dataset.act, el, e);
    });
    app.addEventListener('keydown', function (e) {
      if (e.target.matches('.cmp textarea') && e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendText(); }
      if (e.target.id === 'renin' && e.key === 'Enter') act('renok', e.target, e);
      if (e.target.matches('.crow') && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); e.target.click(); }
      if (e.key === 'Escape' && (S.menu || S.sheet)) { closeAll(); render(); }
    });
    app.addEventListener('input', function (e) {
      var a = e.target.dataset.act;
      if (a === 'draft') {
        var before = S.draft.charAt(0) === '/' && S.draft.indexOf(' ') < 0;
        S.draft = e.target.value;
        var nowTpl = S.draft.charAt(0) === '/' && S.draft.indexOf(' ') < 0;
        var rb = app.querySelector('.round'); if (rb) rb.classList.toggle('has', !!S.draft);
        e.target.style.height = 'auto'; e.target.style.height = e.target.scrollHeight + 'px';
        if (before || nowTpl) { var pos = e.target.selectionStart; render(); var ta = app.querySelector('.cmp textarea'); ta.focus(); ta.setSelectionRange(pos, pos); }
      }
      if (a === 'search') {
        var q = e.target.value.trim().toLowerCase();
        app.querySelectorAll('.side .crow').forEach(function (r) { r.hidden = q && (r.dataset.search || '').indexOf(q) < 0; });
      }
      if (a === 'findq') {
        S.find = e.target.value;
        app.querySelectorAll('#thread .txt').forEach(function (s) { s.innerHTML = hl(s.dataset.raw); });
      }
    });
    // Долгое нажатие на строку = выбор (как в мессенджере), дальше «Скрыть»
    app.addEventListener('pointerdown', function (e) {
      var r = e.target.closest('.crow[data-act="open"]'); if (!r || e.target.closest('.crow-menu')) return;
      pressTimer = setTimeout(function () { suppress = true; S.select = r.dataset.id; render(); }, 480);
    });
    ['pointerup', 'pointerleave', 'pointercancel', 'pointermove'].forEach(function (ev) {
      app.addEventListener(ev, function (e) { if (ev !== 'pointermove' || Math.abs(e.movementY) > 3) clearTimeout(pressTimer); });
    });
    app.addEventListener('contextmenu', function (e) {
      var r = e.target.closest('.crow[data-act="open"]'); if (!r) return;
      e.preventDefault(); S.menu = 'row:' + r.dataset.id; render();
    });
    window.addEventListener('message', function (e) {
      if (!e.data || !e.data.mock) return;
      lang = e.data.lang; applyTheme(e.data.theme); render();
    });
  }

  /* ---------- Полотно со всеми экранами ---------- */
  function bootCanvas() {
    document.body.insertAdjacentHTML('afterbegin', SPRITE);
    function texts() {
      root.lang = lang;
      document.title = t('cv.title');
      document.querySelectorAll('[data-i18n]').forEach(function (el) { el.textContent = t(el.dataset.i18n); });
      document.querySelectorAll('[data-lang]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.lang === lang)); });
      document.querySelectorAll('[data-theme-v]').forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.themeV === theme)); });
    }
    function push(f) { try { f.contentWindow.postMessage({ mock: 1, lang: lang, theme: theme }, '*'); } catch (e) { /* рамка ещё не загрузилась */ } }
    function fit() {
      var cv = document.querySelector('.cv'), avail = cv.clientWidth - 40;
      document.querySelectorAll('.fr').forEach(function (fr) {
        var w = +fr.dataset.w, h = +fr.dataset.h, phone = fr.classList.contains('phone');
        var s = phone ? Math.min(1, (avail - 16) / w) : Math.min(0.75, avail / w);
        var ifr = fr.querySelector('iframe');
        ifr.style.width = w + 'px'; ifr.style.height = h + 'px'; ifr.style.transform = 'scale(' + s + ')';
        fr.style.width = Math.floor(w * s) + 'px'; fr.style.height = Math.floor(h * s + (phone ? 0 : 26)) + 'px';
        fr.parentElement.style.width = Math.floor(w * s + (phone ? 16 : 0)) + 'px';
      });
    }
    document.querySelectorAll('.fr').forEach(function (fr) {
      var ifr = document.createElement('iframe');
      ifr.title = fr.dataset.title || 'screen';
      ifr.loading = 'lazy';
      ifr.src = 'screen.html?' + fr.dataset.q;
      ifr.addEventListener('load', function () { push(ifr); });
      fr.appendChild(ifr);
    });
    document.addEventListener('click', function (e) {
      var b = e.target.closest('[data-lang],[data-theme-v]'); if (!b) return;
      if (b.dataset.lang) setLang(b.dataset.lang); else setTheme(b.dataset.themeV);
      texts();
      document.querySelectorAll('.fr iframe').forEach(push);
    });
    texts(); fit();
    window.addEventListener('resize', fit);
  }

  document.addEventListener('DOMContentLoaded', function () {
    if (document.getElementById('app')) bootApp();
    else if (document.querySelector('.cv')) bootCanvas();
  });
})();
