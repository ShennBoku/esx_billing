fx_version 'adamant'

game 'gta5'
lua54 'yes'
author 'ShennBoku#0001'
description 'ESX Advanced Billing'

shared_script {
	'@ox_lib/init.lua',
	'@es_extended/imports.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/main.lua'
}

dependency {
	'es_extended'
}