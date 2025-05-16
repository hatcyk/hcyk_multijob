fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hatcyk'
description 'Multi-Job System'
version '1.4.0'

ui_page 'web/build/index.html'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'lang.lua'
}

client_scripts {
    'client/utils.lua',
    'client/client.lua'
}
server_scripts {
  '@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}

files {
  'web/build/**/*',
  'lang.json'
}