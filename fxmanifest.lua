fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hatcyk'
description 'Multi-Job System'
version '1.0.0'

ui_page 'web/build/index.html'

shared_scripts {
  '@ox_lib/init.lua'
}

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

dependencies {
  'I'
}