// Utility to load lang.json dynamically and provide translation function

export type Langs = Record<string, Record<string, string>>;

let langs: Langs = {};
let loaded = false;

export async function loadLangs(): Promise<Langs> {
  if (loaded) return langs;
  const resp = await fetch('/lang.json');
  langs = await resp.json();
  loaded = true;
  return langs;
}

export function t(lang: string, key: string, vars?: Record<string, string|number>): string {
  if (!langs[lang] || !langs[lang][key]) return key;
  let str = langs[lang][key];
  if (vars) {
    Object.entries(vars).forEach(([k, v]) => {
      str = str.replace(new RegExp(`{${k}}`, 'g'), String(v));
    });
  }
  return str;
}

export function setLangData(data: Langs) {
  langs = data;
  loaded = true;
}
