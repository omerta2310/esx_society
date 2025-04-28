Config = {}

Config.Locale = 'en'
Config.EnableESXIdentity = false

Config.MaxRank = 100
Config.ExperiencePerRank = 1000
Config.NonCriminalHireAmount = 0
Config.DeleteLogsAfterDays = 7
Config.AbilityPerRank = 0.5
Config.PercentPerAbility = 5
Config.IncreaseRankCost = 20		--DC
Config.ResetAbilitiesCost = 5		--DC
Config.MoneyAbilityInterval = 60	--minutes
Config.MoneyPerAbility = 10			--1 = 10
Config.SecondsToDeletePreviousJob = 3600*24*3 -- 3 days

Config.JobsWithAbilities = {--Only police is supported
	['police'] = true
}

Config.Privileges = {
	{name = 'deposit',			label = 'Deposit'},
	{name = 'withdraw',			label = 'Withdraw'},
	{name = 'company-workers',	label = 'Manage Workers'},
	{name = 'hire-worker',		label = 'Hire Worker'},
	{name = 'single-reward',	label = 'Single Reward'},
	{name = 'mass-reward',		label = 'Mass Reward'},
	{name = 'display-workers',	label = 'Display Members'},
	{name = 'set-meeting',		label = 'Set Meeting'},
	{name = 'warehouse-toggle',	label = 'Toggle Warehouse'},
	{name = 'company-logs',		label = 'Company Logs'},
	{name = 'abilities',		label = 'Abilities'},
}

Config.Abilities = {
	{name = 'speed',		label = 'Increase Run Speed',		icon = 'far fa-running',		color = 'green',	text = 'Increase your mafia member\'s run speed. <br/>  10% = +1% more speed.'},
	{name = 'recoil',		label = 'Reduce Recoil',			icon = 'far fa-bullseye-arrow',	color = 'green',	text = 'Decrease recoil in all guns. <br/> 10% = -1% less recoil.'},
	{name = 'health',		label = 'Health Regeneration',		icon = 'fas fa-flask-potion',	color = 'blue',		text = 'Health regeneration every 5 seconds.<br/> 10% = +1% more regeneration.'},
	{name = 'vest',			label = 'Vest Regeneration',		icon = 'far fa-vest',			color = 'blue',		text = 'Vest regeneration every 5 seconds. <br/> 10% = +1% more regeneration.'},
	{name = 'armor',		label = 'Reduce Damage Taken',		icon = 'far fa-shield-alt',		color = 'red',		text = 'Reduce damage taken from enemies. <br/> 10% = -1% damage taken.'},
	{name = 'damage',		label = 'Increased Damage',			icon = 'fas fa-fire-smoke',		color = 'green',	text = 'Increase damage making to enemies. <br/> 10% = +1% more damage.'},
	{name = 'money',		label = 'Extra Money',				icon = 'far fa-sack-dollar',	color = 'green',	text = 'Money for all police employees every 1 hour. <br/> 10% = +100$.'},
	{name = 'inventory',	label = 'Increase Inventory',		icon = 'far fa-warehouse',		color = 'green',	text = 'You can now have a bigger inventory with up to +100% more space.'},
}