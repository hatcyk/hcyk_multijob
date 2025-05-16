// Supported languages for UI and notifications
export type LangCode = 'cs' | 'pl' | 'en' | 'de';

export const LANGUAGES = ['cs', 'pl', 'en', 'de'] as const;

export const DEFAULT_LANG: LangCode = 'en';

export const translations: Record<LangCode, Record<string, string>> = {
  cs: {
    jobs_title: 'Moje Práce',
    job_count: '{count}/3',
    no_jobs: 'Žádné práce k dispozici',
    loading: 'Načítání prací...',
    switch: 'Přepnout',
    remove: 'Odebrat',
    notification_job_removed: 'Práce {label} odebrána',
    notification_job_switched: 'Přepnuto na {label}',
    notification_error: 'Chyba připojení k serveru',
    notification_fetch_error: 'Chyba při načítání prací',
  },
  pl: {
    jobs_title: 'Moje Prace',
    job_count: '{count}/3',
    no_jobs: 'Brak dostępnych prac',
    loading: 'Ładowanie prac...',
    switch: 'Przełącz',
    remove: 'Usuń',
    notification_job_removed: 'Praca {label} usunięta',
    notification_job_switched: 'Przełączono na {label}',
    notification_error: 'Błąd połączenia z serwerem',
    notification_fetch_error: 'Błąd podczas ładowania prac',
  },
  en: {
    jobs_title: 'My Jobs',
    job_count: '{count}/3',
    no_jobs: 'No jobs available',
    loading: 'Loading jobs...',
    switch: 'Switch',
    remove: 'Remove',
    notification_job_removed: 'Job {label} removed',
    notification_job_switched: 'Switched to {label}',
    notification_error: 'Server connection error',
    notification_fetch_error: 'Error fetching jobs',
  },
  de: {
    jobs_title: 'Meine Jobs',
    job_count: '{count}/3',
    no_jobs: 'Keine Jobs verfügbar',
    loading: 'Jobs werden geladen...',
    switch: 'Wechseln',
    remove: 'Entfernen',
    notification_job_removed: 'Job {label} entfernt',
    notification_job_switched: 'Zu {label} gewechselt',
    notification_error: 'Serververbindungsfehler',
    notification_fetch_error: 'Fehler beim Laden der Jobs',
  },
};

// Helper to get translation
export function t(lang: LangCode, key: string, vars?: Record<string, string|number>) {
  let str = translations[lang][key] || translations[DEFAULT_LANG][key] || key;
  if (vars) {
    Object.entries(vars).forEach(([k, v]) => {
      str = str.replace(`{${k}}`, String(v));
    });
  }
  return str;
}
