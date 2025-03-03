fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Project HCYK'
description 'Multi-Job System'
version '1.0.0'

ui_page 'web/build/index.html'

client_scripts {
    'client/*.lua',
}


server_scripts {
  '@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}

files {
  'web/build/**/*'
}
