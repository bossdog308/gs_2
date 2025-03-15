fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Tha underWorld GunStore'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

ui_page 'html/index.html'


--[[    CHANGELOG

   --{{ 
        v1.0.0
            - Initial Release
        v1.0.1
            - Added Glock 27 and Glock 26
            - Added Ammo Types
            - Added Attachments
            - Added Config file
            - Added Config file for weapons, ammo, and attachments
            - Added Config file for shops
        v1.0.2
            - database support
            - added database support for purchased weapons


        need to be added/changed/updated
        --- ammo function (buy ammo, give ammo, nui menu for ammo)
        --- saveloadout
        --- serial number for weapons
        --- weapon license
        ---{{ remove weapon from database when 
              dropped/deleted/destroyed/lost/stolen by police
            }}
        --- buy again if not in weapon wheel      
        
        --.0
            --STABLE RELEASE--
                {{added
            --- ammo function (buy ammo, give ammo, nui menu for ammo)
            --- saveloadout
            --- serial number for weapons
            --- weapon license
            --- remove weapon from database when 
            --- full database support
                }}
    }}
]]    

