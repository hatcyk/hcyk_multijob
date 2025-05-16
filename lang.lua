Lang = {}

Lang['en'] = {
    unknown = 'Unknown',
    no_free_slot = 'You have no free slot for another job',
    player_not_found = 'Player not found',
    job_not_saved = 'You do not have this job saved',
    job_data_not_found = 'Job data not found',
    job_removed = 'Job removed successfully',
    cannot_remove_active = 'Cannot remove active job',
    cannot_remove = 'Cannot remove this job',
    job_switched = 'Job switched successfully',
    job_slot_full = 'Player has no free slot for another job',
    employer_slot_full = 'You tried to employ a player, but they have no free slot.',
    job_changed = 'Job changed',
    no_permission = 'You do not have permission',
    notify_title = 'Job Manager',
    no_job_slot = 'You tried to add a job, but you have no slots left.',
}

Lang['cs'] = {
    unknown = 'Neznámá',
    no_free_slot = 'Nemáš volný slot pro další práci',
    player_not_found = 'Hráč nenalezen',
    job_not_saved = 'Tuto práci nemáš uloženou',
    job_data_not_found = 'Data o práci nebyla nalezena',
    job_removed = 'Práce úspěšně odebrána',
    cannot_remove_active = 'Nelze odebrat aktivní práci',
    cannot_remove = 'Tuto práci nelze odebrat',
    job_switched = 'Práce úspěšně změněna',
    job_slot_full = 'Hráč nemá volný slot pro další práci',
    employer_slot_full = 'Zkusil jsi si dát jobu, ale již nemáš slot.',
    job_changed = 'Práce změněna',
    no_permission = 'Nemáš oprávnění',
    notify_title = 'Správce prací',
    no_job_slot = 'Zkusil jsi si dát jobu, ale již nemáš slot.',
}

Lang['pl'] = {
    unknown = 'Nieznany',
    no_free_slot = 'Nie masz wolnego miejsca na kolejną pracę',
    player_not_found = 'Gracz nie znaleziony',
    job_not_saved = 'Nie masz tej pracy zapisanej',
    job_data_not_found = 'Nie znaleziono danych pracy',
    job_removed = 'Praca została usunięta',
    cannot_remove_active = 'Nie można usunąć aktywnej pracy',
    cannot_remove = 'Nie można usunąć tej pracy',
    job_switched = 'Praca została zmieniona',
    job_slot_full = 'Gracz nie ma wolnego miejsca na kolejną pracę',
    employer_slot_full = 'Próbowałeś zatrudnić gracza, ale nie ma wolnego miejsca.',
    job_changed = 'Praca zmieniona',
    no_permission = 'Nie masz uprawnień',
    notify_title = 'Menedżer Prac',
    no_job_slot = 'Próbowałeś dodać pracę, ale nie masz już wolnych slotów.',
}


Lang['de'] = {
    unknown = 'Unbekannt',
    no_free_slot = 'Du hast keinen freien Slot für einen weiteren Job',
    player_not_found = 'Spieler nicht gefunden',
    job_not_saved = 'Du hast diesen Job nicht gespeichert',
    job_data_not_found = 'Jobdaten nicht gefunden',
    job_removed = 'Job erfolgreich entfernt',
    cannot_remove_active = 'Aktiven Job kann man nicht entfernen',
    cannot_remove = 'Dieser Job kann nicht entfernt werden',
    job_switched = 'Job erfolgreich gewechselt',
    job_slot_full = 'Spieler hat keinen freien Slot für einen weiteren Job',
    employer_slot_full = 'Du hast versucht, einen Spieler einzustellen, aber er hat keinen freien Slot.',
    job_changed = 'Job gewechselt',
    no_permission = 'Keine Berechtigung',
    notify_title = 'Job-Manager',
    no_job_slot = 'Du hast versucht, einen Job hinzuzufügen, aber du hast keine freien Slots mehr.',
}

function _L(key, vars)
    local lang = Config and Config.Locale or 'en'
    local str = (Lang[lang] and Lang[lang][key]) or (Lang['en'][key]) or key
    if vars and type(vars) == 'table' then
        for k, v in pairs(vars) do
            str = str:gsub('{'..k..'}', tostring(v))
        end
    end
    return str
end

return { Lang = Lang, _L = _L }
