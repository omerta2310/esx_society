shared_script '@WaveShield/resource/waveshield.lua' --this line was automatically written by WaveShield

fx_version 'adamant'

game 'gta5'

description 'ESX Society'

version '1.0.4'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'locales/en.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts {
    '@es_extended/locale.lua',
    'locales/en.lua',
    'config.lua',
    'client/main.lua'
}

dependencies {
    'es_extended',
    -- 'cron',
    'esx_addonaccount'
}

ui_page 'html/ui.html'

files {
	'html/ui.html',
	'html/script.js',
	'html/progressbar.js',
	'html/css/*.css',
	'html/css/fonts/*.ttf',
	'html/images/*.png',
	'html/images/*.gif',
}

exports {
	"getAbility"
} 

server_exports {
	"getJobRank",
	"getJobExperience",
	"setJobExperience",
	"addJobExperience",
	"removeJobExperience",
	"getJobAbility"
} 
client_script "@Greek_ac/client/injections.lua"