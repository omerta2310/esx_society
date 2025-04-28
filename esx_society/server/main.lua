ESX = nil
local Jobs = {}
local RegisteredSocieties = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function GetSociety(name)
    for i=1, #RegisteredSocieties, 1 do
        if RegisteredSocieties[i].name == name then
            return RegisteredSocieties[i]
        end
    end
end

MySQL.ready(function()
	
	local result = MySQL.Sync.fetchAll('SELECT * FROM jobs', {})

	for i=1, #result, 1 do
		Jobs[result[i].name] = result[i]
		Jobs[result[i].name].grades = {}
		Jobs[result[i].name].idogboss = result[i].ogboss
		Jobs[result[i].name].idviceboss = result[i].viceboss
		refreshBosses(result[i].ogboss , result[i].viceboss,result[i].name)
	end

	local result2 = MySQL.Sync.fetchAll('SELECT * FROM job_grades', {})

	for i=1, #result2, 1 do
		Jobs[result2[i].job_name].grades[tostring(result2[i].grade)] = result2[i]
	end

end)

function refreshBosses(ogboss, viceboss, job)
	local data = {}

	if ogboss ~= "none" and ogboss ~= '' and ogboss ~= nil then
		local results = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @id',{['@id'] = ogboss})
		data.ogbossName = results[1].firstname..' '..results[1].lastname
	else
		data.ogbossName = 'none'
	end

	if viceboss ~= 'none' and viceboss ~= '' and viceboss ~= nil then
		local resultsV = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @id',{['@id'] = viceboss})
		data.vicebossName = resultsV[1].firstname..' '..resultsV[1].lastname
	else
		data.vicebossName = 'none'
	end
	Jobs[job].ogboss = data.ogbossName
	Jobs[job].viceboss = data.vicebossName
end

AddEventHandler('esx_society:registerSociety', function(name, label, account, datastore, inventory, data)
	local found = false
	
	local society = {
		name = name,
		label = label,
		account = account,
		datastore = datastore,
		inventory = inventory,
		data = data
	}

	for i=1, #RegisteredSocieties, 1 do
		if RegisteredSocieties[i].name == name then
			found, RegisteredSocieties[i] = true, society
			break
		end
	end

	if not found then
		table.insert(RegisteredSocieties, society)
	end
end)

AddEventHandler('esx_society:getSocieties', function(cb)
	cb(RegisteredSocieties)
end)

AddEventHandler('esx_society:getSociety', function(name, cb)
	cb(GetSociety(name))
end)

RegisterServerEvent('esx_society:putVehicleInGarage')
AddEventHandler('esx_society:putVehicleInGarage', function(societyName, vehicle)
	local society = GetSociety(societyName)

	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		table.insert(garage, vehicle)
		store.set('garage', garage)
	end)
end)

RegisterServerEvent('esx_society:removeVehicleFromGarage')
AddEventHandler('esx_society:removeVehicleFromGarage', function(societyName, vehicle)
	local society = GetSociety(societyName)

	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}

		for i=1, #garage, 1 do
			if garage[i].plate == vehicle.plate then
				table.remove(garage, i)
				break
			end
		end

		store.set('garage', garage)
	end)
end)

ESX.RegisterServerCallback('esx_society:getOnlinePlayers', function(source, cb)
	local xPlayers = ESX.GetPlayers()
	local players = {}

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		table.insert(players, {
			source = xPlayer.source,
			identifier = xPlayer.identifier,
			name = xPlayer.name,
			job = xPlayer.job
		})
	end

	cb(players)
end)

ESX.RegisterServerCallback('esx_society:getVehiclesInGarage', function(source, cb, societyName)
	local society = GetSociety(societyName)

	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		cb(garage)
	end)
end)

ESX.RegisterServerCallback('esx_society:getJob', function(source, cb, societyName)
    local job = json.decode(json.encode(Jobs[societyName]))
    local grades = {}

    for k,v in pairs(job.grades) do
        table.insert(grades, v)
    end

    table.sort(grades, function(a, b)
        return a.grade < b.grade
    end)

    job.grades = grades
    job.bossName = job.ogboss
    job.vicebossName = job.viceboss
	job.rank = job.rank
	job.experience = job.xp
	job.isArmoryLocked = job.armorylocked
	
	local society = GetSociety(societyName)
	print(society)
	if society then
		print(society)
		TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
			job.societyMoney = account.money
		end)
	else
		job.societyMoney = 0
	end
    cb(job)
end)

ESX.RegisterServerCallback('esx_society:getMyJobs', function (source,cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll("SELECT * FROM jobs WHERE ogboss = @ogboss", {
		['@ogboss'] = xPlayer.identifier
	}, function (result)
		if #result > 0 then
			local jobs_owned = {}
			for k,v in pairs(result) do
				table.insert(jobs_owned, {
					boss = v.ogboss,
					label = v.label,
					name = v.name
				})
			end
			cb(jobs_owned)
		else
			cb(false)
		end
	end)
end)

RegisterNetEvent("esx:changeJob")
AddEventHandler("esx:changeJob", function (job)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)

	if xPlayer.job.name ~= job then
		if xPlayer.job2.name == job then
			local job1 = xPlayer.job2.name
			local job1g = xPlayer.job2.grade
			
			local job2 = xPlayer.job.name
			local job2g = xPlayer.job.grade

			xPlayer.setJob(job1, job1g)
			xPlayer.setJob2(job2, job2g)
		else
			local bossgrade = MySQL.Sync.fetchScalar("SELECT grade FROM job_grades WHERE name = @name AND job_name = @job", {['@name'] = "boss", ['@job'] = job})
			xPlayer.setJob(job, tonumber(bossgrade))
		end
	else
		xPlayer.showNotification("You already have this job")
	end
end)

ESX.RegisterServerCallback('esx_society:rankUp',function(source, cb, society)
	local job = json.decode(json.encode(Jobs[society]))
	if job.rank < Config.MaxRank then
		if job.xp >= Config.ExperiencePerRank then
			Jobs[society].rank = job.rank + 1
			Jobs[society].xp = job.xp - Config.ExperiencePerRank
			job.xp = Jobs[society].xp
			job.rank = Jobs[society].rank
			MySQL.Async.fetchAll('UPDATE `jobs` SET `xp` = @xp, `rank` = @rank WHERE `name` = @name',
			    {
				    ['@name'] = job.name,
				    ['@rank'] = job.rank,
				    ['@xp'] = job.xp
			    },
			    function ()
			end)
			--TriggerClientEvent('esx:showNotification', source, 'Μόλις Αναβάθμησες Το Επίπεδό Σας!')
		else
			TriggerClientEvent('esx:showNotification', source, 'Δεν έχεις ακρετό xp')
		end
	end
	cb(job.rank,job.xp)
end)

RegisterServerEvent('esx_society:setMeeting')
AddEventHandler('esx_society:setMeeting', function (coords)
	local _source = source
	local job = ESX.GetPlayerFromId(_source).job.name
	TriggerClientEvent('esx_society:setMeeting', -1, job, coords)
end)

RegisterServerEvent('esx_society:endMeeting')
AddEventHandler('esx_society:endMeeting', function (coords)
	local _source = source
	local job = ESX.GetPlayerFromId(_source).job.name
	TriggerClientEvent('esx_society:endMeeting', -1, job)
end)

RegisterServerEvent('esx_society:changeJobBoss')
AddEventHandler('esx_society:changeJobBoss', function(target)
	local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
	local kPlayer = ESX.GetPlayerFromId(target)
	local give_job_label = xPlayer.getJob().label
	local give_job = xPlayer.getJob().name
	local give_job_gtade = xPlayer.getJob().grade
    if xPlayer.getJob().grade_name == "boss" then
        if xPlayer and kPlayer then	
            xPlayer.setJob('unemployed', 0)
            xPlayer.showNotification("YOU ARE NO MORE THE BOSS"..give_job_label)
        
		    kPlayer.showNotification("YOU ARE NOW THE BOSS OF "..give_job_label)
		    kPlayer.setJob(give_job, give_job_gtade)
	    else
		    xPlayer.showNotification("Player is not online")		
        end
    else
	    xPlayer.showNotification("YOU ARE NOT THE BOSS")		
    end	
end)

RegisterServerEvent('esx_society:changeJobViceboss')
AddEventHandler('esx_society:changeJobViceboss', function(target)
	local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
	local kPlayer = ESX.GetPlayerFromId(target)
	local give_job_label = xPlayer.getJob().label
	local give_job = xPlayer.getJob().name
	local give_job_gtade = xPlayer.getJob().grade
    if xPlayer.getJob().grade_name == "viceboss" then
        if xPlayer and kPlayer then	
            xPlayer.setJob('unemployed', 0)
            xPlayer.showNotification("YOU ARE NO MORE THE VICEBOSS"..give_job_label)
        
		    kPlayer.showNotification("YOU ARE NOW THE VICEBOSS OF "..give_job_label)
		    kPlayer.setJob(give_job, give_job_gtade)
	    else
		    xPlayer.showNotification("Player is not online")		
        end
    else
	    xPlayer.showNotification("YOU ARE NOT THE BOSS")		
    end	
end)

RegisterServerEvent('esx_society:depositMoney')
AddEventHandler('esx_society:depositMoney', function(societyName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local society = GetSociety(societyName)
    amount = ESX.Math.Round(tonumber(amount))
   
    Citizen.Wait(10)
    if xPlayer.job.name == society.name then
        if amount > 0 and xPlayer.getMoney() >= amount then
            TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                xPlayer.removeMoney(amount)
                xPlayer.showNotification(_U('have_deposited', ESX.Math.GroupDigits(amount)))
                account.addMoney(amount)
                logs_send(societyName,1,xPlayer.getName(),"money",amount,os.time())
            end)
        else
            xPlayer.showNotification(_U('invalid_amount'))
        end
    else
        print(('esx_society: %s attempted to call depositMoney!'):format(xPlayer.identifier))
    end
end)

RegisterServerEvent('esx_society:washMoney')
AddEventHandler('esx_society:washMoney', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local account = xPlayer.getAccount('black_money')
	amount = ESX.Math.Round(tonumber(amount))

	if xPlayer.job.name == society then
		if amount and amount > 0 and account.money >= amount then
			xPlayer.removeAccountMoney('black_money', amount)

			MySQL.Async.execute('INSERT INTO society_moneywash (identifier, society, amount) VALUES (@identifier, @society, @amount)', {
				['@identifier'] = xPlayer.identifier,
				['@society'] = society,
				['@amount'] = amount
			}, function(rowsChanged)
				xPlayer.showNotification(_U('you_have', ESX.Math.GroupDigits(amount)))
			end)
		else
			xPlayer.showNotification(_U('invalid_amount'))
		end
	else
		print(('esx_society: %s attempted to call washMoney!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_society:withdrawMoney')
AddEventHandler('esx_society:withdrawMoney', function(societyName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local society = GetSociety(societyName)
    amount = ESX.Math.Round(tonumber(amount))

    
    if xPlayer.job.name == society.name then
         TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
            if amount > 0 and account.money >= amount then
                account.removeMoney(amount)
                xPlayer.addMoney(amount)
                xPlayer.showNotification(_U('have_withdrawn', ESX.Math.GroupDigits(amount)))
                logs_send(societyName,0,xPlayer.getName(),"money",amount,os.time())
            else
                xPlayer.showNotification(_U('invalid_amount'))
            end
        end)
    else
        print(('esx_society: %s attempted to call withdrawMoney!'):format(xPlayer.identifier))
    end
end)

ESX.RegisterServerCallback('esx_society:setJob', function(source, cb, identifier, job, grade, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local isBoss = xPlayer.job.grade_name == 'boss'

	if isBoss then
		local xTarget = ESX.GetPlayerFromIdentifier(identifier)

		if xTarget then
			xTarget.setJob(job, grade)

			if type == 'hire' then
				TriggerClientEvent('esx:showNotification', xTarget.source, _U('you_have_been_hired', job))
			elseif type == 'promote' then
				TriggerClientEvent('esx:showNotification', xTarget.source, _U('you_have_been_promoted'))
			elseif type == 'fire' then
				TriggerClientEvent('esx:showNotification', xTarget.source, _U('you_have_been_fired', xTarget.getJob().label))
			end

			cb()
		else
			MySQL.Async.execute('UPDATE users SET job = @job, job_grade = @job_grade WHERE identifier = @identifier', {
				['@job']        = job,
				['@job_grade']  = grade,
				['@identifier'] = identifier
			}, function(rowsChanged)
				cb()
			end)
		end
	else
		--print(('esx_society: %s attempted to setJob'):format(xPlayer.identifier))
		cb()
	end
end)

ESX.RegisterServerCallback('esx_society:setJob2', function(source, cb, identifier, job2, grade2, type)

	local xPlayer = ESX.GetPlayerFromIdentifier(identifier)

	if xPlayer ~= nil then
		xPlayer.setJob2(job2, grade2)
		
		if type == 'hire' then
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_have_been_hired', job2))
		elseif type == 'promote' then
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_have_been_promoted'))
		elseif type == 'fire' then
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_have_been_fired', xPlayer.getJob2().label))
		end
	end

	MySQL.Async.execute(
		'UPDATE users SET job2 = @job2, job2_grade = @job2_grade WHERE identifier = @identifier',
		{
			['@job2']        = job2,
			['@job2_grade']  = grade2,
			['@identifier'] = identifier
		},
		function(rowsChanged)
			cb()
		end
	)

end)

ESX.RegisterServerCallback('esx_society:setJobSalary', function(source, cb, job, grade, salary)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == job and xPlayer.job.grade_name == 'boss' then
		if salary <= Config.MaxSalary then
			MySQL.Async.execute('UPDATE job_grades SET salary = @salary WHERE job_name = @job_name AND grade = @grade', {
				['@salary']   = salary,
				['@job_name'] = job,
				['@grade']    = grade
			}, function(rowsChanged)
				Jobs[job].grades[tostring(grade)].salary = salary
				local xPlayers = ESX.GetPlayers()

				for i=1, #xPlayers, 1 do
					local xTarget = ESX.GetPlayerFromId(xPlayers[i])

					if xTarget.job.name == job and xTarget.job.grade == grade then
						xTarget.setJob(job, grade)
					end
				end

				cb()
			end)
		else
			print(('esx_society: %s attempted to setJobSalary over config limit!'):format(xPlayer.identifier))
			cb()
		end
	else
		print(('esx_society: %s attempted to setJobSalary'):format(xPlayer.identifier))
		cb()
	end
end)


RegisterServerEvent('esx_society:changeWarehouseStatus')
AddEventHandler('esx_society:changeWarehouseStatus', function (status)
	local xPlayer = ESX.GetPlayerFromId(source)
	print(xPlayer.job.name)
	print(status)
	MySQL.Async.execute("UPDATE jobs SET armorylocked = @armorylocked WHERE name = @name",{
		['@name'] = xPlayer.job.name,
		['@armorylocked'] = status
	})
end)

RegisterServerEvent('esx_society:inviteToJob')
AddEventHandler('esx_society:inviteToJob', function(jobName, target)
    TriggerClientEvent('esx_society:inviteTarget', target, jobName)
end)

ESX.RegisterServerCallback('esx_society:getBattlepassLevels', function(source, cb, playerId)
    local levels = {}

    for _, data in ipairs(playerId) do
        local identifier = data.player

        MySQL.Async.fetchAll('SELECT * FROM battlepass WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            if result and #result > 0 then
                data.level = result[1].level
            else
                data.level = 0
            end

            table.insert(levels, data)
        end)
    end

    while #levels < #playerId do
        Wait(100)
    end

    cb(levels)
end)

RegisterServerEvent('esx_society:acceptInvite')
AddEventHandler('esx_society:acceptInvite', function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)  -- Fix the typo here
    local jobName = xPlayer.getJob().name

    if xPlayer and tPlayer then
        tPlayer.setJob(jobName, 0)
        tPlayer.showNotification('You have accepted the invite and were assigned to the job: ' .. jobName)
    else
        print('Error: xPlayer not found for player ' ..source)
    end
end)


ESX.RegisterServerCallback('esx_society:getEmployees2', function(source, cb)
	local employees = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = xPlayer.job.name
	local xPlayers = ESX.GetPlayers()

	for k, v in pairs(xPlayers) do
		local secondjob = xPlayer.getJob().name
		local xPlayer = ESX.GetPlayerFromId(v)

		local name = GetPlayerName(xPlayer.source)
		if Config.EnableESXIdentity then
			name = xPlayer.get('firstName') .. ' ' .. xPlayer.get('lastName')
		end

		if xPlayer.getJob2().name == society then
			table.insert(employees, {
				name = name,
				id = xPlayer.identifier,
				identifier = xPlayer.source,
				isConnected = true,
				job = {
					name = society,
					label = xPlayer.getJob2().label,
					grade = xPlayer.getJob2().grade,
					grade_name = xPlayer.getJob2().grade_name,
					grade_label = xPlayer.getJob2().grade_label,
					isConnected = true
				}
			})
		elseif secondjob == society then
			table.insert(employees, {
				name = name,
				id = xPlayer.identifier,
				identifier = xPlayer.source,
				isConnected = true,
				job = {
					name = society,
					label = xPlayer.getJob2().label,
					grade = xPlayer.getJob2().grade,
					grade_name = xPlayer.getJob2().grade_name,
					grade_label = xPlayer.getJob2().grade_label,
					isConnected = false
				}
			})
		end
	end

	local query = "SELECT identifier, job_grade2 FROM `users` WHERE `job`=@job ORDER BY job_grade DESC"

	if Config.EnableESXIdentity then
		query = "SELECT identifier, job_grade2, firstname, lastname FROM `users` WHERE `job`=@job ORDER BY job_grade DESC"
	end

	MySQL.Async.fetchAll(query, {
		['@job2'] = society
	}, function(result)
		for k, row in pairs(result) do
			local alreadyInTable = false -- Initialize alreadyInTable as false
			local identifier = row.identifier

			for k, v in pairs(employees) do
				if v.identifier == identifier then
					alreadyInTable = true
					break -- Exit the loop if alreadyInTable is true
				end
			end

			if not alreadyInTable then
				local name = "Name not found."

				if Config.EnableESXIdentity then
					name = row.firstname .. ' ' .. row.lastname
				end

				table.insert(employees2, {
					name = name,
					identifier = identifier,
					job = {
						name = society,
						label = Jobs[society].label,
						grade = row.job_grade,
						grade_name = Jobs[society].grades[tostring(row.job_grade)].name,
						grade_label = Jobs[society].grades[tostring(row.job_grade)].label
					}
				})
			end
		end

		cb(employees)
	end)
end)

	ESX.RegisterServerCallback('esx_society:getEmployees', function(source, cb)
		local employees = {}
		local xPlayer = ESX.GetPlayerFromId(source)
		local society = xPlayer.job.name
		local xPlayers = ESX.GetPlayers()
	
		for k, v in pairs(xPlayers) do
			local secondjob = xPlayer.getJob().name
			local xPlayer = ESX.GetPlayerFromId(v)
	
			local name = GetPlayerName(xPlayer.source)
			if Config.EnableESXIdentity then
				name = xPlayer.get('firstName') .. ' ' .. xPlayer.get('lastName')
			end
	
			if xPlayer.getJob().name == society then
				table.insert(employees, {
					name = name,
					id = xPlayer.identifier,
					identifier = xPlayer.source,
					isConnected = true,
					job = {
						name = society,
						label = xPlayer.getJob().label,
						grade = xPlayer.getJob().grade,
						grade_name = xPlayer.getJob().grade_name,
						grade_label = xPlayer.getJob().grade_label,
						isConnected = true
					}
				})
			elseif secondjob == society then
				table.insert(employees, {
					name = name,
					id = xPlayer.identifier,
					identifier = xPlayer.source,
					isConnected = true,
					job = {
						name = society,
						label = xPlayer.getJob().label,
						grade = xPlayer.getJob().grade,
						grade_name = xPlayer.getJob().grade_name,
						grade_label = xPlayer.getJob().grade_label,
						isConnected = false
					}
				})
			end
		end
	
		local query = "SELECT identifier, job_grade FROM `users` WHERE `job`=@job ORDER BY job_grade DESC"
	
		if Config.EnableESXIdentity then
			query = "SELECT identifier, job_grade, firstname, lastname FROM `users` WHERE `job`=@job ORDER BY job_grade DESC"
		end
	
		MySQL.Async.fetchAll(query, {
			['@job'] = society
		}, function(result)
			for k, row in pairs(result) do
				local alreadyInTable = false -- Initialize alreadyInTable as false
				local identifier = row.identifier
	
				for k, v in pairs(employees) do
					if v.identifier == identifier then
						alreadyInTable = true
						break -- Exit the loop if alreadyInTable is true
					end
				end
	
				if not alreadyInTable then
					local name = "Name not found."
	
					if Config.EnableESXIdentity then
						name = row.firstname .. ' ' .. row.lastname
					end
	
					table.insert(employees, {
						name = name,
						identifier = identifier,
						job = {
							name = society,
							label = Jobs[society].label,
							grade = row.job_grade,
							grade_name = Jobs[society].grades[tostring(row.job_grade)].name,
							grade_label = Jobs[society].grades[tostring(row.job_grade)].label
						}
					})
				end
			end
	
			cb(employees)
		end)
	end)
	
	
RegisterServerEvent('esx_society:giveReward')
AddEventHandler('esx_society:giveReward', function(job, identifier, amount)
	local society = GetSociety(job)
    local price = amount
	local job = job
    local xPlayer = ESX.GetPlayerFromId(identifier)
	
	TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
		
		if account.money >= price then
		  account.money = account.money - price
	      xPlayer.addAccountMoney('bank', amount)
	   end
		
	end)	


end)

RegisterServerEvent('esx_society:giveMassReward')
AddEventHandler('esx_society:giveMassReward', function(job, amount)
	local society = GetSociety(job)
    local price = amount
	local job = job
    local xPlayers = ESX.GetPlayers()


	TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
		
    
		for i=1, #xPlayers, 1 do
			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
			if xPlayer.getJob().name == job then
              if account.money >= price then
				account.money = account.money - price
				xPlayer.addAccountMoney('bank', price)
			  end
			end	
		end

	end)	


end)

ESX.RegisterServerCallback('esx_society:getJobLogs', function(source, cb, job_name)

	local xPlayer = ESX.GetPlayerFromId(source)
	local Elogs = nil
	local job = job_name
	MySQL.Async.fetchAll('SELECT logs FROM jobs WHERE name = @name', { ['@name'] = job}, function(result)
		
		Elogs = result[1].logs
	
    end)
	Citizen.Wait(10)
 
	logs = json.decode(Elogs)

    cb(logs)
end)

ESX.RegisterServerCallback('esx_society:getJobPrivileges', function(source, cb, job)
	local xPlayer = ESX.GetPlayerFromId(source)
	local job = job
	local privileges = {}
	local options= {}
	local final = {}
    local perms = {}

    MySQL.Async.fetchAll('SELECT perms FROM job_grades WHERE job_name = @name  ', { ['@name'] = job}, function(result)
		for k, v in pairs(result) do
			perms[k] = {}
			perms[k] = result[k].perms
		end	
    end)
	Citizen.Wait(10)
	for k, v in pairs(perms) do
		final[k] = {}
		final[k] = json.decode(perms[k])
	end	

    Citizen.Wait(10)

    cb(final)
end)

ESX.RegisterServerCallback('esx_society:setJobPrivileges', function(source, cb, job, grade ,privileges)
	local xPlayer = ESX.GetPlayerFromId(source)
    local perm = json.encode(privileges)
	local job = job
	local grade = grade
	local final = {}

	MySQL.Async.execute('UPDATE job_grades SET perms = @perms WHERE job_name = @name AND grade = @grade',
	{ 
		['@perms'] = perm,
		['@grade'] = grade,
		['@name'] = job,
	})

end)

ESX.RegisterServerCallback('esx_society:getSocietyMoney', function(source, cb, societyName)
	local society = GetSociety(societyName)

	if society then
		TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
			cb(account.money)
		end)
	else
		cb(0)
	end
end)

ESX.RegisterServerCallback('esx_society:hasAccess', function(source, cb, option)
	local xPlayer = ESX.GetPlayerFromId(source)
	local job = xPlayer.getJob().name
	local grade = xPlayer.getJob().grade
    local perms = {}
    local Permisons = {}
	local jobsinfo = json.decode(json.encode(Jobs[job]))
    stat = false
	if jobsinfo.idogboss == xPlayer.identifier then
		print("jobsinfo.idogboss == xPlayer.identifier")
		stat = true
		cb(stat)
	elseif option == 'original-boss' and jobsinfo.idogboss == xPlayer.identifier then
		print("option == original-boss")
		cb(stat)
	else
	MySQL.Async.fetchAll('SELECT perms FROM job_grades WHERE job_name = @name AND grade = @grade ', { ['@name'] = job,['@grade'] = grade}, function(result)
		if  result[1] ~= nil then
			local txtMy = json.decode(result[1].perms)
			perms = result[1].perms
		end
    end)
   Citizen.Wait(1500)

   Permisons = json.decode(perms)
   if Permisons[option] then
	stat = true
   end
   Citizen.Wait(10)

        cb(stat)
    end 
end)

function WashMoneyCRON(d, h, m)
	MySQL.Async.fetchAll('SELECT * FROM society_moneywash', {}, function(result)
		for i=1, #result, 1 do
			local society = GetSociety(result[i].society)
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i].identifier)

			-- add society money
			TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
				account.addMoney(result[i].amount)
			end)

			-- send notification if player is online
			if xPlayer then
				xPlayer.showNotification(_U('you_have_laundered', ESX.Math.GroupDigits(result[i].amount)))
			end

			MySQL.Async.execute('DELETE FROM society_moneywash WHERE id = @id', {
				['@id'] = result[i].id
			})
		end
	end)
end

TriggerEvent('cron:runAt', 3, 0, WashMoneyCRON)

RegisterCommand('setjobboss', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer and (xPlayer.getGroup() == 'owner' or xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'mod' or xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'developer') then
        print(ESX.DumpTable(args))

        if #args >= 2 then
            local xTarget = ESX.GetPlayerFromId(args[1])
            local job = args[2]

            if xTarget and job then
                changeBoss(args[1], job)
            else
                xPlayer.showNotification("/setjobboss ID job")
            end
        else
            xPlayer.showNotification("/setjobboss ID job")
        end
    end
end, true)

function changeBoss(target, job)
    local xTarget = ESX.GetPlayerFromId(target)
    
    if xTarget == nil then
        print("Player not found.")
        return
    end

    Jobs[job].idogboss = xTarget.identifier
    refreshBosses(xTarget.identifier, Jobs[job].viceboss, job)
    MySQL.Async.execute('UPDATE jobs SET ogboss = @ogboss WHERE name = @name',{
		['@name'] = job,
        ['@ogboss'] = xTarget.identifier
    },function(rowsChanged)
		print(string.format("%d rows updated.", rowsChanged))
    end)
end

function logs_send(job,deposite,name,item,pid,time)
    local base = 0
    local basenew = 0
    local newlogs = {}
    local Alogs = nil
    local job = job
    MySQL.Async.fetchAll('SELECT logs FROM jobs WHERE name = @name', { ['@name'] = job}, function(result)
        
        Alogs = result[1].logs
    
    end)

    Citizen.Wait(10)
    
    oldlogs = json.decode(Alogs)
    --------------------------------------------------------------------------------------------------------
    Citizen.Wait(10)
   
    base = #oldlogs
    basenew = base + 1
    Citizen.Wait(10)

    for i=1, basenew, 1 do
        if i == basenew then
        
            newlogs[i] = {}
            newlogs[i].deposit = deposite
            newlogs[i].name = name
            newlogs[i].item = item
            newlogs[i].pid  = "x"..pid
            newlogs[i].timestamp = time
        else
            newlogs[i] = {}
            newlogs[i] = oldlogs[i] 
        end        
    end

    Citizen.Wait(10)

    --------------------------------------------------------------------------------------------------------
    finallogs = json.encode(newlogs)

    Citizen.Wait(10)
    MySQL.Async.execute('UPDATE jobs SET logs = @logs WHERE name = @name',
    { 
        ['@logs'] = finallogs,
        ['@name'] = job,
    })
    
    
    
end    

RegisterCommand("leavejob", function(source, args, rawCommand)
    local playerId = source

    if IsPlayerEmployed(playerId) then
        local xPlayer = ESX.GetPlayerFromId(playerId)

        xPlayer.setJob("unemployed", 0)

        xPlayer.ShowNotification("You have resigned from your job.")
    else
        xPlayer.ShowNotification("You are not currently employed.")
    end
end, false)

function IsPlayerEmployed(playerId)
    return ESX.GetPlayerFromId(playerId).job ~= nil
end

-- mMafia
ESX.RegisterServerCallback('esx_mMafia:isCriminal', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        print('Invalid player')
        cb(false)
        return
    end

    MySQL.Async.fetchAll('SELECT type FROM jobs WHERE name = @job', {
        ['job'] = xPlayer.job.name
    }, function(datatwo)
        if datatwo and #datatwo > 0 then
            local jobType = datatwo[1].type

            if jobType == 'gang' or jobType == 'mafia' or jobType == 'cartel' or jobType == 'hooligan' then
                cb(true)
            else
                cb(false)
            end
        else
            print('Invalid job data')
            cb(false)
        end
    end)
end)
