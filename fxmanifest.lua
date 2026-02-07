fx_version 'cerulean'
game 'gta5'

lua54 'yes'
author 'sgMAGLERA'
description 'A simple blackmarket script for QBCore Framework'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}
