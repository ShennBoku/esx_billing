Config = {}
Config.Locale = GetConvar('esx:locale', 'en')

Config.Notification = {
    res = 'DEFAULT', -- Available Support: ESX DEFAULT (DEFAULT), okokNotify (OKOK)
    data = {
        okok = {
            time = 3500,
            type = 'info',
            title = 'Notification',
        }
    }
}