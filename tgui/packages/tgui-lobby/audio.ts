import { storage } from 'common/storage';
import { assetMap } from './assets';

/// Whether interface sounds are allowed to play, persisted client-side
let soundsEnabled = true;

export const SOUNDS_STORAGE_KEY = 'lobby-sounds-enabled';

export function setSoundsEnabled(enabled: boolean) {
  soundsEnabled = enabled;
  storage.set(SOUNDS_STORAGE_KEY, enabled);
}

export function areSoundsEnabled() {
  return soundsEnabled;
}

export function loadSoundsEnabled(): Promise<boolean> {
  return storage.get(SOUNDS_STORAGE_KEY).then((val) => {
    soundsEnabled = val === undefined || val === null ? true : !!val;
    return soundsEnabled;
  });
}

function getAssetUrl(name: string): string | null {
  return assetMap[name] ?? null;
}

function playOneShot(name: string) {
  if (!soundsEnabled) {
    return;
  }
  const url = getAssetUrl(name);
  if (!url) return;
  const audio = new Audio(url);
  audio.volume = 0.6;
  audio.play().catch(() => {});
}

export function playSelectSound() {
  playOneShot('ui_select1.ogg');
}

export function playCollapseSound() {
  playOneShot('menu_rollup1.ogg');
}

export function playExpandSound() {
  playOneShot('menu_rolldown1.ogg');
}
