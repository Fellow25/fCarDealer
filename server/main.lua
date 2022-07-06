local categories, vehicles = {}, {}

TriggerEvent('esx_phone:registerNumber', 'cardealer', _U('dealer_customers'), false, false)
TriggerEvent('esx_society:registerSociety', 'cardealer', _U('car_dealer'), 'society_cardealer', 'society_cardealer', 'society_cardealer', {type = 'private'})

CreateThread(function()
	local char = Config.PlateLetters
	char = char + Config.PlateNumbers
	if Config.PlateUseSpace then char = char + 1 end

	if char > 8 then
		print(('[esx_vehicleshop] [^3WARNING^7] Plate character count reached, %s/8 characters!'):format(char))
	end
end)

function RemoveOwnedVehicle(plate)
	MySQL.update('DELETE FROM owned_vehicles WHERE plate = ?', {plate})
end

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		SQLVehiclesAndCategories()
	end
end)

function SQLVehiclesAndCategories()
	categories = MySQL.query.await('SELECT * FROM vehicle_categories')
	vehicles = MySQL.query.await('SELECT * FROM vehicles')

	GetVehiclesAndCategories(categories, vehicles)
end

function GetVehiclesAndCategories(categories, vehicles)
	for i = 1, #vehicles do
		local vehicle = vehicles[i]
		for j = 1, #categories do
			local category = categories[j]
			if category.name == vehicle.category then
				vehicle.categoryLabel = category.label
				break
			end
		end
	end

	-- send information after db has loaded, making sure everyone gets vehicle information
	TriggerClientEvent('esx_vehicleshop:sendCategories', -1, categories)
	TriggerClientEvent('esx_vehicleshop:sendVehicles', -1, vehicles)
end

function getVehicleFromModel(model)
	for i = 1, #vehicles do
		local vehicle = vehicles[i]
		if vehicle.model == model then
			return vehicle
		end
	end

	return
end

RegisterNetEvent('esx_vehicleshop:setVehicleOwnedPlayerId')
AddEventHandler('esx_vehicleshop:setVehicleOwnedPlayerId', function(playerId, vehicleProps, id, label)
	local xPlayer, xTarget = ESX.GetPlayerFromId(source), ESX.GetPlayerFromId(playerId)

	if xPlayer.job.name == 'cardealer' and xTarget then
		MySQL.scalar('SELECT id FROM cardealer_vehicles WHERE id = ?', {id},
		function(id)
			if id then
				MySQL.update('DELETE FROM cardealer_vehicles WHERE id = ?', {id},
				function(rowsChanged)
					if rowsChanged == 1 then
						MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)', {xTarget.identifier, vehicleProps.plate, json.encode(vehicleProps)},
						function(id)
							xPlayer.showNotification(_U('vehicle_set_owned', vehicleProps.plate, xTarget.getName()))
							xTarget.showNotification(_U('vehicle_belongs', vehicleProps.plate))
						end)

						MySQL.insert('INSERT INTO vehicle_sold (client, model, plate, soldby, date) VALUES (?, ?, ?, ?, ?)', {xTarget.getName(), label, vehicleProps.plate, xPlayer.getName(), os.date('%Y-%m-%d %H:%M')})
					end
				end)
			end
		end)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:getSoldVehicles', function(source, cb)
	MySQL.query('SELECT * FROM vehicle_sold, vehicles WHERE vehicle_sold.model = vehicles.model ORDER BY DATE DESC', function(result)
		cb(result)
	end)
end)

RegisterNetEvent('esx_vehicleshop:rentVehicle')
AddEventHandler('esx_vehicleshop:rentVehicle', function(id, plate, rentPrice, playerId)
	local xPlayer, xTarget = ESX.GetPlayerFromId(source), ESX.GetPlayerFromId(playerId)

	if xPlayer.job.name == 'cardealer' and xTarget then
		MySQL.single('SELECT id, vehicle, price FROM cardealer_vehicles WHERE id = ?', {id},
		function(result)
			if result then
				MySQL.update('DELETE FROM cardealer_vehicles WHERE id = ?', {result.id},
				function(rowsChanged)
					if rowsChanged == 1 then
						MySQL.insert('INSERT INTO rented_vehicles (vehicle, plate, player_name, base_price, rent_price, owner) VALUES (?, ?, ?, ?, ?, ?)', {result.vehicle, plate, xTarget.getName(), result.price, rentPrice, xTarget.identifier},
						function(id)
							xPlayer.showNotification(_U('vehicle_set_rented', plate, xTarget.getName()))
							xTarget.showNotification(_U('vehicle_belongs', plate))
						end)
						-- test
						MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)', {xTarget.identifier, plate, result.vehicle},
						function(id)
						end)
					end
				end)
			end
		end)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:getCategories', function(source, cb)
	cb(categories)
end)

ESX.RegisterServerCallback('esx_vehicleshop:getVehicles', function(source, cb)
	SQLVehiclesAndCategories()
	Wait(200)
	cb(vehicles)
end)

ESX.RegisterServerCallback('esx_vehicleshop:buyVehicle', function(source, cb, model, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	local modelPrice = getVehicleFromModel(model).price

	if modelPrice and xPlayer.getMoney() >= modelPrice then
		xPlayer.removeMoney(modelPrice)

		MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)', {xPlayer.identifier, plate, json.encode({model = joaat(model), plate = plate})
		}, function(rowsChanged)
			xPlayer.showNotification(_U('vehicle_belongs', plate))
			cb(true)
		end)
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:getCommercialVehicles', function(source, cb)
	MySQL.query('SELECT * FROM cardealer_vehicles, vehicles WHERE vehicles.model = cardealer_vehicles.vehicle', function(result)
		if result ~= nil then
			local getCommercialVehicles = {} or nil
			for i = 1, #result do
				getCommercialVehicles[#getCommercialVehicles+1]={
					model = result[i].vehicle, 
					label = result[i].name,
					price = result[i].price,
					id = result[i].id
				}
			end
			cb(getCommercialVehicles)
		end
	end)
end)

ESX.RegisterServerCallback('esx_vehicleshop:buyCarDealerVehicle', function(source, cb, model)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'cardealer' then
		local modelPrice = getVehicleFromModel(model).price

		if modelPrice then
			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_cardealer', function(account)
				if account.money >= modelPrice then
					account.removeMoney(modelPrice)

					MySQL.insert('INSERT INTO cardealer_vehicles (vehicle, price) VALUES (?, ?)', {model, modelPrice},
					function(rowsChanged)
						cb(true)
					end)
				else
					cb(false)
				end
			end)
		end
	end
end)

RegisterNetEvent('esx_vehicleshop:returnProvider')
AddEventHandler('esx_vehicleshop:returnProvider', function(vehicleModel)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'cardealer' then
		MySQL.single('SELECT id, price FROM cardealer_vehicles WHERE vehicle = ?', {vehicleModel},
		function(result)
			if result then
				local id = result.id

				MySQL.update('DELETE FROM cardealer_vehicles WHERE id = ?', {id},
				function(rowsChanged)
					if rowsChanged == 1 then
						TriggerEvent('esx_addonaccount:getSharedAccount', 'society_cardealer', function(account)
							local price = ESX.Math.Round(result.price * 0.75)

							account.addMoney(price)
							xPlayer.showNotification(_U('vehicle_sold_for', ESX.Math.GroupDigits(price)))
						end)
					end
				end)
			else
				print(('[esx_vehicleshop] [^3WARNING^7] %s attempted selling an invalid vehicle!'):format(xPlayer.identifier))
			end
		end)
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:getRentedVehicles', function(source, cb)
	MySQL.query('SELECT * FROM rented_vehicles ORDER BY player_name ASC', function(result)
		local vehicles = {}

		for i = 1, #result do
			local vehicle = result[i]
			vehicles[#vehicles + 1] = {
				name = vehicle.vehicle,
				plate = vehicle.plate,
				playerName = vehicle.player_name
			}
		end

		cb(vehicles)
	end)
end)

RegisterNetEvent('esx_vehicleshop:giveBackVehicle')
AddEventHandler('esx_vehicleshop:giveBackVehicle', function(plate, entity)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	MySQL.single('SELECT vehicle, base_price FROM rented_vehicles WHERE plate = ?', {plate},
	function(result)
		if result then
			local vehicle = result.vehicle
			local basePrice = result.base_price
			MySQL.update('DELETE FROM rented_vehicles WHERE plate = ?', {plate})
			MySQL.update('DELETE FROM owned_vehicles WHERE plate = ?', {plate})
			MySQL.insert('INSERT INTO cardealer_vehicles (vehicle, price) VALUES (?, ?)', {vehicle, basePrice})
			RemoveOwnedVehicle(plate)
			TriggerClientEvent('esx_vehicleshop:deleteVehicle', src, entity)
		else
			xPlayer.showNotification(_U('not_rental'))
		end
	end)
end)

RegisterNetEvent('esx_vehicleshop:resellVehicle')
AddEventHandler('esx_vehicleshop:resellVehicle', function(model, entity, plate)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local result = MySQL.query.await('SELECT model, price FROM vehicles WHERE model = ?', {model})
	local checkrent = string.find(plate, Config.PlateRentedCar)
	if result and not checkrent then
		local vehicle = result[1].model
		local price = ESX.Math.Round(result[1].price / 100 * Config.ResellPercentage)
		local result2 = MySQL.single.await('SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ?', {xPlayer.identifier, plate})
		if result2 then
			MySQL.update('DELETE FROM owned_vehicles WHERE plate = ?', {plate})
			TriggerClientEvent('esx_vehicleshop:deleteVehicle', src, entity)
			xPlayer.showNotification(_U('vehicle_sold_for', price))
			xPlayer.addMoney(price)
		else
			print(checkrent)
			xPlayer.showNotification(_U('not_yours'))
		end
	else
		xPlayer.showNotification(_U('not_sell_rental'))
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:isPlateTaken', function(source, cb, plate)
	MySQL.scalar('SELECT plate FROM owned_vehicles WHERE plate = ?', {plate},
	function(result)
		cb(result ~= nil)
	end)
end)

ESX.RegisterServerCallback('esx_vehicleshop:retrieveJobVehicles', function(source, cb, type)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT * FROM owned_vehicles WHERE owner = ? AND type = ? AND job = ?', {xPlayer.identifier, type, xPlayer.job.name},
	function(result)
		cb(result)
	end)
end)

RegisterNetEvent('esx_vehicleshop:setJobVehicleState')
AddEventHandler('esx_vehicleshop:setJobVehicleState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.update('UPDATE owned_vehicles SET `stored` = ? WHERE plate = ? AND job = ?', {state, plate, xPlayer.job.name},
	function(rowsChanged)
		if rowsChanged == 0 then
			print(('[esx_vehicleshop] [^3WARNING^7] %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)

function PayRent()
	local timeStart = os.clock()
	print('[esx_vehicleshop] [^2INFO^7] Paying rent cron job started')

	MySQL.query('SELECT rented_vehicles.owner, rented_vehicles.rent_price, rented_vehicles.plate, users.accounts FROM rented_vehicles LEFT JOIN users ON rented_vehicles.owner = users.identifier', {},
	function(rentals)
		local owners = {}
		for i = 1, #rentals do
			local rental = rentals[i]
			if not owners[rental.owner] then
				owners[rental.owner] = {rental}
			else
				owners[rental.owner][#owners[rental.owner] + 1] = rental
			end
		end

		local total = 0
		local unrentals = {}
		local users = {}
		for k, v in pairs(owners) do
			local sum = 0
			for i = 1, #v do
				sum = sum + v[i].rent_price
			end
			local xPlayer = ESX.GetPlayerFromIdentifier(k)

			if xPlayer then
				local bank = xPlayer.getAccount('bank').money

				if bank >= sum and #v > 1 then
					total = total + sum
					xPlayer.removeAccountMoney('bank', sum)
					xPlayer.showNotification(_U('paid_rental'):format(ESX.Math.GroupDigits(sum)))
				else
					for i = 1, #v do
						local rental = v[i]
						if xPlayer.getAccount('bank').money >= rental.rent_price then
							total = total + rental.rent_price
							xPlayer.removeAccountMoney('bank', rental.rent_price)
							xPlayer.showNotification(_U('paid_rental', ESX.Math.GroupDigits(rental.rent_price), rental.plate))
						else
							xPlayer.showNotification(_U('paid_rental_evicted', ESX.Math.GroupDigits(rental.rent_price), rental.plate))
							unrentals[#unrentals + 1] = {rental.owner, rental.plate}
						end
					end
				end
			else
				local accounts = json.decode(v[1].accounts)
				if accounts.bank < sum then
					sum = 0
					local limit = false
					for i = 1, #v do
						local rental = v[i]
						if not limit then
							sum = sum + rental.rent_price
							if sum > accounts.bank then
								sum = sum - rental.rent_price
								limit = true
							end
						else
							unrentals[#unrentals + 1] = {rental.owner, rental.plate}
						end
					end
				end
				if sum > 0 then
					total = total + sum
					accounts.bank = accounts.bank - sum
					users[#users + 1] = {json.encode(accounts), k}
				end
			end
		end

		if total > 0 then
			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_cardealer', function(account)
				account.addMoney(total)
			end)
		end

		if next(users) then
			MySQL.prepare.await('UPDATE users SET accounts = ? WHERE identifier = ?', users)
		end

		if next(unrentals) then
			MySQL.prepare.await('DELETE FROM rented_vehicles WHERE owner = ? AND plate = ?', unrentals)
		end

		print(('[esx_vehicleshop] [^2INFO^7] Paying rent cron job took %s seconds'):format(os.clock() - timeStart))
	end)
end

CreateThread(function()
	while true do
		Wait(3600000)
		PayRent()
	end
end)

ESX.RegisterServerCallback('esx_vehicleshop:requestPlayerCars', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)

RegisterNetEvent('esx_vehicleshop:changePrice')
AddEventHandler('esx_vehicleshop:changePrice', function(price, model)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'cardealer' and xPlayer.job.grade_name == 'boss' then
		MySQL.Async.execute('UPDATE vehicles SET price = @price WHERE model = @model', {
			['@model'] = model,
			['@price'] = price
		})
	end
end)

ESX.RegisterServerCallback('getEmployee', function(source, cb, jobname)
    local players = ESX.GetExtendedPlayers('job', jobname)
    cb(players)
end)

RegisterServerEvent('setJob')
AddEventHandler('setJob', function(target, job, grade, status)
  local xPlayer = ESX.GetPlayerFromId(source)
  local xTarget = ESX.GetPlayerFromId(target)
  xTarget.setJob(job, grade)
  if status == 'fire' then
	xPlayer.showNotification(_U('you_have_fired')..xTarget.getName())
	xTarget.showNotification(_U('you_have_been_fired'))
  elseif status == 'promote' then
	xPlayer.showNotification(_U('you_have_promoted')..xTarget.getName())
	xTarget.showNotification(_U('you_have_been_promoted'))
  elseif status == 'demote' then
	xPlayer.showNotification(_U('you_have_deomoted')..xTarget.getName())
	xTarget.showNotification(_U('you_have_been_demoted'))
  end
end)