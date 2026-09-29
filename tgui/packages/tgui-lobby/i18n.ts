// Lobby menu localization (html-lobby-v2)
// Server-side language preference is delivered in the init payload ("language").
// English is the fallback for any missing key.

export type LobbyLanguage = 'english' | 'russian';

const en = {
  welcome: 'Welcome,',
  guest: 'Guest',

  // Info TV lines
  playersOnline: 'players online',
  playersReady: 'players ready',
  adminsReady: 'admins ready',
  startingIn: 'Starting in',
  shiftIn: 'in',
  gameEnded: 'Game ended,',
  restartSoon: 'restart soon',
  delayed: 'DELAYED',
  soon: 'SOON',

  // Stats panel
  statsTitle: 'Server',
  statsServer: 'Server',
  statsMap: 'Map',
  statsStatus: 'Status',
  statsShiftTime: 'Shift time',
  statsPlayers: 'Players',
  statsReady: 'Ready',
  statsAdmins: 'Admins',
  statusStartup: 'Starting up',
  statusPregame: 'Pre-game',
  statusSettingUp: 'Setting up',
  statusPlaying: 'Round in progress',
  statusPostgame: 'Round ended',

  // Character preview
  previewTitle: 'Character',
  rotate: 'Rotate',
  refresh: 'Refresh',

  // Settings popup
  settingsTitle: 'Lobby Settings',
  languageLabel: 'Language',
  crtLabel: 'CRT filter',
  soundsLabel: 'Interface sounds',
  closeLabel: 'Close',
  on: 'On',
  off: 'Off',

  // Tooltips
  ttReady: 'Ready up',
  ttNotReady: 'Cancel ready',
  ttJoin: 'Join the game',
  ttObserve: 'Observe the round',
  ttCharacterSetup: 'Character setup',
  ttSettings: 'Game preferences',
  ttChangelog: 'Changelog',
  ttManifest: 'Crew manifest',
  ttPoll: 'Player polls',
  ttCollapse: 'Hide menu',
  ttExpand: 'Show menu',
  ttStartNow: 'Start round now',
  ttOpenSettings: 'Lobby settings',
} as const;

export type TranslationKey = keyof typeof en;

const ru: Record<TranslationKey, string> = {
  welcome: 'Добро пожаловать,',
  guest: 'Гость',

  playersOnline: 'игроков онлайн',
  playersReady: 'готовы к старту',
  adminsReady: 'админов готово',
  startingIn: 'Старт через',
  shiftIn: 'в раунде',
  gameEnded: 'Игра завершена,',
  restartSoon: 'скоро рестарт',
  delayed: 'ЗАДЕРЖКА',
  soon: 'СКОРО',

  statsTitle: 'Сервер',
  statsServer: 'Сервер',
  statsMap: 'Карта',
  statsStatus: 'Статус',
  statsShiftTime: 'Время смены',
  statsPlayers: 'Игроки',
  statsReady: 'Готовы',
  statsAdmins: 'Админы',
  statusStartup: 'Запуск',
  statusPregame: 'До игры',
  statusSettingUp: 'Подготовка',
  statusPlaying: 'Идёт раунд',
  statusPostgame: 'Раунд завершён',

  previewTitle: 'Персонаж',
  rotate: 'Повернуть',
  refresh: 'Обновить',

  settingsTitle: 'Настройки лобби',
  languageLabel: 'Язык',
  crtLabel: 'CRT-фильтр',
  soundsLabel: 'Звуки интерфейса',
  closeLabel: 'Закрыть',
  on: 'Вкл',
  off: 'Выкл',

  ttReady: 'Готов играть',
  ttNotReady: 'Отменить готовность',
  ttJoin: 'Войти в игру',
  ttObserve: 'Наблюдать за раундом',
  ttCharacterSetup: 'Настройка персонажа',
  ttSettings: 'Игровые настройки',
  ttChangelog: 'Список изменений',
  ttManifest: 'Манифест экипажа',
  ttPoll: 'Опросы',
  ttCollapse: 'Свернуть меню',
  ttExpand: 'Развернуть меню',
  ttStartNow: 'Начать раунд сейчас',
  ttOpenSettings: 'Настройки лобби',
};

const dictionaries: Record<LobbyLanguage, Record<TranslationKey, string>> = {
  english: en,
  russian: ru,
};

export function makeT(language: LobbyLanguage) {
  const dict = dictionaries[language] ?? en;
  return (key: TranslationKey): string => dict[key] ?? en[key];
}

/** "1 player" / "5 players" / "1 игрок" / "5 игроков" */
export function playerCountLabel(
  language: LobbyLanguage,
  count: number,
): string {
  if (language === 'russian') {
    const mod10 = count % 10;
    const mod100 = count % 100;
    let form = 'игроков';
    if (mod10 === 1 && mod100 !== 11) {
      form = 'игрок';
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      form = 'игрока';
    }
    return `${count} ${form}`;
  }
  return `${count} player${count !== 1 ? 's' : ''}`;
}
