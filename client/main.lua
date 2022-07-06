local HasAlreadyEnteredMarker, IsInShopMenu = false, false
local CurrentAction, CurrentActionMsg, LastZone, currentDisplayVehicle, CurrentVehicleData
CurrentActionData, Vehicles, Categories, AllCurrentVehicle, moneyCarDealer = {}, {}, {}, {}, nil

local ListIndex = 1
local list  = {_U("blue"), _U("red"), _U("brown"), _U("gold"), _U("green"), _U("tan"), _U("orange"), _U("purple"), _U("yellow"), _U("black"), _U("white")}

-- RegisterNetEvent
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	getVehicles()
end)

RegisterNetEvent('esx_vehicleshop:sendCategories')
AddEventHandler('esx_vehicleshop:sendCategories', function(categories)
	Categories = categories
end)

RegisterNetEvent('esx_vehicleshop:sendVehicles')
AddEventHandler('esx_vehicleshop:sendVehicles', function(vehicles)
	Vehicles = vehicles
end)

RegisterNetEvent('esx_vehicleshop:deleteVehicle')
AddEventHandler('esx_vehicleshop:deleteVehicle', function(vehicle)
	DeleteVehicle(vehicle)
end)	

RegisterNetEvent('esx_vehicleshop:OpenBossMenu')
AddEventHandler('esx_vehicleshop:OpenBossMenu',function()
    OpenBossMenu()
end)

RegisterNetEvent('esx_vehicleshop:openCarDealer')
AddEventHandler('esx_vehicleshop:openCarDealer',function()
    openCarDealer()
end)

-- Function
function DeleteDisplayVehicleInsideShop()
	for i = #AllCurrentVehicle, 1, -1 do
		if AllCurrentVehicle[i] and DoesEntityExist(AllCurrentVehicle[i]) then
			while DoesEntityExist(AllCurrentVehicle[i]) and not NetworkHasControlOfEntity(AllCurrentVehicle[i]) do
				Wait(100)
				NetworkRequestControlOfEntity(AllCurrentVehicle[i])
			end
			if DoesEntityExist(AllCurrentVehicle[i]) and NetworkHasControlOfEntity(AllCurrentVehicle[i]) then
				ESX.Game.DeleteVehicle(AllCurrentVehicle[i])
			end
		end
		table.remove(AllCurrentVehicle, i)
		break
	end
end

function DeleteDisplayVehicleShop()
	if currentDisplayVehicle and DoesEntityExist(currentDisplayVehicle) then
		while DoesEntityExist(currentDisplayVehicle) and not NetworkHasControlOfEntity(currentDisplayVehicle) do
			Wait(100)
			NetworkRequestControlOfEntity(currentDisplayVehicle)
		end
		if DoesEntityExist(currentDisplayVehicle) and NetworkHasControlOfEntity(currentDisplayVehicle) then
			ESX.Game.DeleteVehicle(currentDisplayVehicle)
		end
	end
end

function StartShopRestriction()
	CreateThread(function()
		while IsInShopMenu do
			Wait(0)
			DisableControlAction(0, 75,  true)
			DisableControlAction(27, 75, true)
		end
	end)
end

function getVehicles()
	ESX.TriggerServerCallback('esx_vehicleshop:getCategories', function(categories)
		Categories = categories
	end)
	ESX.TriggerServerCallback('esx_vehicleshop:getVehicles', function(vehicles)
		getVeh = vehicles
	end)
	ESX.TriggerServerCallback('esx_vehicleshop:getCommercialVehicles', function(vehicles)
		getBuyedVeh = vehicles
	end)
	ESX.TriggerServerCallback('esx_vehicleshop:getRentedVehicles', function(vehicles)
		getRentedVeh = vehicles
	end)
end

function getSoldVehicles(job)
	ESX.TriggerServerCallback('esx_vehicleshop:getSoldVehicles', function(customers)
		Clients = customers
	end)
end

function getVehicleFromModel(model)
	for i = 1, #Vehicles do
		local vehicle = Vehicles[i]
		if vehicle.model == model then
			return vehicle
		end
	end
end

function GiveBackVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent('esx_vehicleshop:giveBackVehicle', plate, vehicle)
end

function ResellVehiclePlayers()
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
	local name = GetEntityArchetypeName(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent('esx_vehicleshop:resellVehicle', name, vehicle, plate)
end

function refreshCarDealerMoney()
    if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
        ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
            updateCarDealerMoney(money)
        end, ESX.PlayerData.job.name)
    end
end

function updateCarDealerMoney(money)
    moneyCarDealer = ESX.Math.GroupDigits(money)
end

local listEmployee = {}
function getEmployee(jobname)
  ESX.TriggerServerCallback('getEmployee', function(data)
    listEmployee = data
 end, jobname)
end

-- IPL
if Config.IPL then
	CreateThread(function()
		RequestIpl('shr_int')

		local interiorID = 7170
		PinInteriorInMemory(interiorID)
		ActivateInteriorEntitySet(interiorID, 'csr_beforeMission')
		RefreshInterior(interiorID)
	end)
end

-- Blip
CreateThread(function()
	local blip = AddBlipForCoord(Config.Blip.Coords)

	SetBlipSprite (blip, Config.Blip.Sprite)
	SetBlipDisplay(blip, Config.Blip.Display)
	SetBlipScale  (blip, Config.Blip.Scale)
	SetBlipColour (blip, Config.Blip.Colour)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(_U('dealership'))
	EndTextCommandSetBlipName(blip)
end)

-- Create menu
Menu = {}
Menu.Toggle = false
function Menu:Create(menu)
	if menu == 'menuCarDealer' then
		getVehicles()
		Menu.Toggle = true
		_menuCarDealer = RageUI.CreateMenu(_U('car_dealer'), _U('menu'))
		_menuCatVeh = RageUI.CreateSubMenu(_menuCarDealer, _U('car_dealer'), _U('menu'))
		_menuVeh = RageUI.CreateSubMenu(_menuCatVeh, _U('car_dealer'), _U('menu'))
		_menuBuy = RageUI.CreateSubMenu(_menuVeh, _U('car_dealer'), _U('menu'))
		_menuPopVeh = RageUI.CreateSubMenu(_menuCarDealer, _U('car_dealer'), _U('menu'))
		_menuReturnVeh = RageUI.CreateSubMenu(_menuCarDealer, _U('car_dealer'), _U('menu'))
		_menuRentedVeh = RageUI.CreateSubMenu(_menuCarDealer, _U('car_dealer'), _U('menu'))
		_menuCarDealer:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuCatVeh:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuVeh:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuBuy:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuPopVeh:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuReturnVeh:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuRentedVeh:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuCarDealer:DisplayGlare(false)
		_menuCatVeh:DisplayGlare(false)
		_menuVeh:DisplayGlare(false)
		_menuBuy:DisplayGlare(false)
		_menuPopVeh:DisplayGlare(false)
		_menuReturnVeh:DisplayGlare(false)
		_menuRentedVeh:DisplayGlare(false)
		_menuCarDealer.Closed = function()
			Menu.Toggle = false
			DeleteDisplayVehicleShop()
		end
	elseif menu == 'menuBoss' then
		getSoldVehicles()
		Menu.Boss = true
		_menuCarDealerBoss = RageUI.CreateMenu(_U('car_dealer'), _U('menu'))
		_menuListEmployee = RageUI.CreateSubMenu(_menuCarDealerBoss, _U('car_dealer'), _U('menu'))
		_menuManageEmployee = RageUI.CreateSubMenu(_menuCarDealerBoss, _U('car_dealer'), _U('menu'))
		_menuSoldVeh = RageUI.CreateSubMenu(_menuCarDealerBoss, _U('car_dealer'), _U('menu'))
		_menuCarDealerBoss:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuListEmployee:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuManageEmployee:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuSoldVeh:SetRectangleBanner(Config.ColorMenu.Red, Config.ColorMenu.Green, Config.ColorMenu.Blue, Config.ColorMenu.Alpha)
		_menuCarDealerBoss:DisplayGlare(false)
		_menuListEmployee:DisplayGlare(false)
		_menuManageEmployee:DisplayGlare(false)
		_menuSoldVeh:DisplayGlare(false)
		_menuCarDealerBoss.Closed = function()
			Menu.Boss = false
		end
	end
end

-- Open menu
function openCarDealer()
	local isboss
    Menu:Create("menuCarDealer")
    RageUI.Visible(_menuCarDealer, true)
    CreateThread(function()
		while Menu.Toggle do
			Wait(2.0)
			if Menu.Toggle then
				RageUI.IsVisible(_menuCarDealer, function()
					RageUI.Button(_U('buy_vehicle'), nil, {RightLabel = "»"}, true, {}, _menuCatVeh)
					if Config.changePrice then
						if ESX.PlayerData.job.grade_name == 'boss' then isboss = true else isboss = false end
						RageUI.Button(_U('change_vehicle'), nil, {RightLabel = "»"}, isboss, {
							onSelected = function()
								local price = KeyboardInput(_U('change_price'), "", 100)
								local model = KeyboardInput(_('change_model'), "", 100)
								TriggerServerEvent('esx_vehicleshop:changePrice', price, model)
								Wait(50)
								getVehicles()
							end
						})
					end
					RageUI.Button(_U('pop_vehicle'), nil, {RightLabel = "»"}, true, {}, _menuPopVeh)
					RageUI.Button(_U('depop_vehicle'), nil, {RightLabel = "»"}, true, {
						onSelected = function()
							if AllCurrentVehicle then
								DeleteDisplayVehicleInsideShop()
							else
								ESX.ShowNotification(_U('no_current_vehicle'))
							end
						end
					})
					RageUI.Button(_U('return_provider'), nil, {RightLabel = "»"}, true, {}, _menuReturnVeh)
					if Config.RentCar then
						RageUI.Button(_U('get_rented_vehicles'), nil, {RightLabel = "»"}, true, {
							onSelected = function()
								getVehicles()
							end
						}, _menuRentedVeh)
					end
					RageUI.Button(_U('set_vehicle_owner_sell'), nil, {RightLabel = "»"}, true, {
						onSelected = function()
							local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer ~= -1 and closestDistance < 3 then
								if CurrentVehicleData then
										local newPlate = GeneratePlate()
										local vehicleProps = ESX.Game.GetVehicleProperties(CurrentVehicleData[1])
										vehicleProps.plate = newPlate
										SetVehicleNumberPlateText(CurrentVehicleData[1], newPlate)
										TriggerServerEvent('esx_vehicleshop:setVehicleOwnedPlayerId', GetPlayerServerId(closestPlayer), vehicleProps, CurrentVehicleData[2], GetEntityArchetypeName(CurrentVehicleData[1]))
										CurrentVehicleData = nil					
								else
									exports["esx_notify"]:Notify("info", 3000, _U('no_current_vehicle'))
								end
							else
								exports["esx_notify"]:Notify("info", 3000, _U('no_players'))
							end
						end
					})
					if Config.RentCar then
						RageUI.Button(_U('set_vehicle_owner_rent'), nil, {RightLabel = "»"}, true, {
							onSelected = function()
								local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
								if closestPlayer ~= -1 and closestDistance < 3 then
									if CurrentVehicleData then
										local amount = KeyboardInput(_U('amount'), "", 100)
										local newPlate = Config.PlateRentedCar .. ' ' .. string.upper(ESX.GetRandomString(3))
										SetVehicleNumberPlateText(CurrentVehicleData[1], newPlate)
										TriggerServerEvent('esx_vehicleshop:rentVehicle', CurrentVehicleData[2], newPlate, amount, GetPlayerServerId(closestPlayer))
										CurrentVehicleData = nil
									else
										exports["esx_notify"]:Notify("info", 3000, _U('no_current_vehicle'))
									end
								else
									exports["esx_notify"]:Notify("info", 3000, _U('no_players'))
								end
							end
						})
					end
					RageUI.Button(_U('create_bill'), nil, {RightLabel = "»"}, true, {
						onSelected = function() 
							local player, distance = ESX.Game.GetClosestPlayer()
							if player ~= -1 and distance <= 3.0 then
								local raison = ""
								local montant = 0
								AddTextEntry("FMMC_MPM_NA", "Objet de la facture")
								DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "Donnez le motif de la facture :", "", "", "", "", 30)
								while (UpdateOnscreenKeyboard() == 0) do
									DisableAllControlActions(0)
									Wait(0)
								end
								if (GetOnscreenKeyboardResult()) then
									local result = GetOnscreenKeyboardResult()
									if result then
										raison = result
										result = nil
										AddTextEntry("FMMC_MPM_NA", "Montant de la facture")
										DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "Indiquez le montant de la facture :", "", "", "", "", 30)
										while (UpdateOnscreenKeyboard() == 0) do
											DisableAllControlActions(0)
											Wait(0)
										end
										if (GetOnscreenKeyboardResult()) then
											result = GetOnscreenKeyboardResult()
											if result then
												montant = result
												result = nil
												TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_cardealer', _U('car_dealer'), montant)
											end
										end
									end
								end
							else
								exports["esx_notify"]:Notify("info", 3000, _U('no_players'))
							end
						end
					})
					RageUI.Button(_U('stock'), nil, {RightLabel = "»"}, true, {
						onSelected = function()
							exports.ox_inventory:openInventory('stash', 'society_cardealer')
							RageUI.CloseAll()
						end
					})
				end)
				RageUI.IsVisible(_menuCatVeh, function()
					for i=1, #Categories, 1 do
						local category = Categories[i]
						RageUI.Button(_U('category')..category.label, nil, {RightLabel = "»"}, true, {
							onSelected = function()
								categorylabel = category.label
								categoryname = category.name
								ESX.TriggerServerCallback('esx_vehicleshop:getVehicles', function(vehicles)
									Vehicles = vehicles
								end)
							end
						}, _menuVeh)
					end
				end)
				RageUI.IsVisible(_menuVeh, function()
					for i=1, #getVeh, 1 do
						if getVeh[i].category == categoryname then
							RageUI.Button(getVeh[i].name, nil, {RightLabel = getVeh[i].price.._U('money')}, true, {
								onSelected = function()
									price = getVeh[i].price
									model = getVeh[i].model
									DeleteDisplayVehicleShop()
				
									ESX.Game.SpawnVehicle(getVeh[i].model, Config.Zone.ShopOutside.Pos, Config.Zone.ShopOutside.Heading, function(vehicle)
										TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
										currentDisplayVehicle = vehicle
										FreezeEntityPosition(playerPed, false)
										SetEntityVisible(playerPed, true)
									end)
								end
							}, _menuBuy)
						end
					end
				end)
				RageUI.IsVisible(_menuBuy, function()

					RageUI.Button(_U('yes'), nil, {RightLabel = "»"}, true, {
						onSelected = function()
							ESX.TriggerServerCallback('esx_vehicleshop:buyCarDealerVehicle', function(success)
								if success then
									DeleteDisplayVehicleShop()
									exports["esx_notify"]:Notify("info", 3000, _U('vehicle_purchased'))
									Wait(100)
									getVehicles()
								else
									DeleteDisplayVehicleShop()
									exports["esx_notify"]:Notify("info", 3000, _U('broke_company'))
								end
							end, model)
						end
					})

					RageUI.Button(_U('no'), nil, {RightLabel = "»"}, true, {
						onSelected = function()
							DeleteDisplayVehicleShop()
							RageUI.GoBack()
						end
					})
				end)
				RageUI.IsVisible(_menuPopVeh, function()

					for k,v in ipairs(getBuyedVeh) do
						RageUI.List(v.label, list, ListIndex, nil, {}, true, {
							onSelected = function()
								if ListIndex == 1 then
									selectedColorR = 0
                    				selectedColorG = 0
                    				selectedColorB = 255
								elseif ListIndex == 2 then
									selectedColorR = 255
                    				selectedColorG = 0
                    				selectedColorB = 0
								elseif ListIndex == 3 then
									selectedColorR = 165
                    				selectedColorG = 42
                    				selectedColorB = 42
								elseif ListIndex == 4 then
									selectedColorR = 255
                    				selectedColorG = 215
                    				selectedColorB = 0
								elseif ListIndex == 5 then
									selectedColorR = 50
                    				selectedColorG = 205
                    				selectedColorB = 50
								elseif ListIndex == 6 then
									selectedColorR = 210
                    				selectedColorG = 180
                    				selectedColorB = 140
								elseif ListIndex == 7 then
									selectedColorR = 255
                    				selectedColorG = 69
                    				selectedColorB = 0
								elseif ListIndex == 8 then
									selectedColorR = 128
                    				selectedColorG = 0
                    				selectedColorB = 128
								elseif ListIndex == 9 then
									selectedColorR = 255
                    				selectedColorG = 255
                    				selectedColorB = 0
								elseif ListIndex == 10 then
									selectedColorR = 0
                    				selectedColorG = 0
                    				selectedColorB = 0
								elseif ListIndex == 11 then
									selectedColorR = 255
                    				selectedColorG = 255
                    				selectedColorB = 255
								end
								ESX.Game.SpawnVehicle(v.model, Config.Zone.ShopInside.Pos, Config.Zone.ShopInside.Heading, function(vehicle)
									AllCurrentVehicle[#AllCurrentVehicle+1] = vehicle
									CurrentVehicleData = {vehicle, v.id}
									SetVehicleCustomPrimaryColour(vehicle, selectedColorR, selectedColorG, selectedColorB)
								end)
							end,
							onListChange = function(Index)
								ListIndex = Index
							end
						})
					end
				end)
				RageUI.IsVisible(_menuReturnVeh, function()
					for k,v in ipairs(getBuyedVeh) do
						local returnPrice = ESX.Math.Round(v.price * 0.75)
						RageUI.Button(v.label, nil, {RightLabel = returnPrice..'€'}, true, {
							onSelected = function()
								TriggerServerEvent('esx_vehicleshop:returnProvider', v.model, returnPrice)
								DeleteDisplayVehicleInsideShop()
								Wait(100)
								getVehicles()
							end
						})
					end
				end)
				RageUI.IsVisible(_menuRentedVeh, function()
					for k,v in ipairs(getRentedVeh) do
						print(getRentedVeh)
						RageUI.Button(_U('vehicle')..v.name, _U('owner')..v.playerName, {RightLabel = _U('plate')..v.plate}, true, {})
					end
				end)
			else
				RageUI.Visible(_menuCarDealer, false)
				RageUI.Visible(_menuCatVeh, false)
				RageUI.Visible(_menuVeh, false)
				RageUI.Visible(_menuBuy, false)
				RageUI.Visible(_menuPopVeh, false)
				RageUI.Visible(_menuReturnVeh, false)
				RageUI.Visible(_menuRentedVeh, false)
				if not RageUI.Visible(_menuCarDealer) and not RageUI.Visible(_menuCatVeh) and not RageUI.Visible(_menuVeh) and not RageUI.Visible(_menuBuy) and not RageUI.Visible(_menuPopVeh) and not RageUI.Visible(_menuReturnVeh) and not RageUI.Visible(_menuRentedVeh) then
					_menuCarDealer = RMenu:DeleteType('_menuCarDealer', true)
				end
				Menu.Toggle = false
				return false
			end
		end
	end)
end

function OpenBossMenu()
	Menu:Create('menuBoss')
	refreshCarDealerMoney()
	local selectedPlayer = {}
	getEmployee(ESX.PlayerData.job.name)
	RageUI.Visible(_menuCarDealerBoss, true)
	CreateThread(function()
		while Menu.Boss do
			Wait(2.0)
			if Menu.Boss then
				RageUI.IsVisible(_menuCarDealerBoss, function()

					if moneyCarDealer ~= nil then
						RageUI.Separator(moneyCarDealer.._U('money'))
                    end			
		
					RageUI.Button(_U('withdraw'), nil, {RightLabel = '»'}, true, {
						onSelected = function()
							local amount = KeyboardInput(_U('amount'), "", 100)
							TriggerServerEvent('esx_society:withdrawMoney', ESX.PlayerData.job.name, amount)
							refreshCarDealerMoney()
						end
					})

					RageUI.Button(_U('deposit'), nil, {RightLabel = '»'}, true, {
						onSelected = function()
							local amount = KeyboardInput(_U('amount'), "", 100)
							TriggerServerEvent('esx_society:depositMoney', ESX.PlayerData.job.name, amount)
							refreshCarDealerMoney()
						end
					})

					RageUI.Button(_U('management'), nil, {RightLabel = '»'}, true, {
					}, _menuListEmployee)

					RageUI.Button(_U('boss_sold'), nil, {RightLabel = "»"}, true, {}, _menuSoldVeh)
				end)

				RageUI.IsVisible(_menuListEmployee, function()
					for i,v in ipairs(listEmployee) do
						RageUI.Button(v.name, nil, {RightLabel =  v.job.grade_label}, true, {
							onSelected = function()
								selectedPlayer = v
							end
						}, _menuManageEmployee)
					end
				end)

				RageUI.IsVisible(_menuManageEmployee, function()


					RageUI.Button(_U('fire'), nil, {RightLabel = ''}, true, {
						onSelected = function()
							TriggerServerEvent('setJob', selectedPlayer.playerId, 'unemployed', 0, 'fire')
						end
					})

					RageUI.Button(_U('promote'), nil, {RightLabel = ''}, true, {
						onSelected = function()
							local newgrad = selectedPlayer.job.grade + 1
							if newgrad ~= ESX.PlayerData.job.grade then
								TriggerServerEvent('setJob', selectedPlayer.playerId, ESX.PlayerData.job.name, newgrad, 'promote')
							else
								ESX.ShowNotification(_U('promote_error'))
							end
						end
					})

					RageUI.Button(_U('demote'), nil, {RightLabel = ''}, true, {
						onSelected = function()
							local newgrad = selectedPlayer.job.grade - 1
							if newgrad ~= -1 then
								TriggerServerEvent('setJob', selectedPlayer.playerId, ESX.PlayerData.job.name, newgrad, 'demote')
							else
								ESX.ShowNotification(_U('demote_error'))
							end
						end
					})

				end)

				RageUI.IsVisible(_menuSoldVeh, function()
					for i=1, #Clients, 1 do
						RageUI.Button(Clients[i].client, _U('customer_model')..Clients[i].name.."\n".._U('customer_price')..Clients[i].price.._U('money').."\n".._U('customer_plate')..Clients[i].plate.."\n".._U('customer_soldby')..Clients[i].soldby, {RightLabel = _U('customer_date')..Clients[i].date}, true, {}, _menuCatVeh)
					end
					
				end)
			else
				RageUI.Visible(_menuCarDealerBoss, false)
				if not RageUI.Visible(_menuCarDealerBoss) and not RageUI.Visible(gestionsalaires) and not RageUI.Visible(_menuListEmployee) and not RageUI.Visible(_menuManageEmployee) and not RageUI.Visible(_menuSoldVeh) then
					_menuCarDealerBoss = RMenu:DeleteType('_menuCarDealerBoss', true)
				end
				Menu.Boss = false
				return false
			end
		end
	end)	
end

-- Marker
CreateThread(function()
	while true do
		Wait(0)
		local interval = true
		local playerCoords = GetEntityCoords(PlayerPedId())
		for k,v in pairs (Config.Zones) do
			local distance = #(playerCoords - v.Pos)
			if distance < Config.DrawDistance then interval = false
				for i = 1, #v.grade do
					if not Config.Qtarget and v.activate then
						if ESX.PlayerData.job.name == 'cardealer' and ESX.PlayerData.job.grade_name == v.grade[i] then
							DrawMarker(v.Type, v.Pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 50, false, true, 2, false, nil, nil, false)
							if distance < Config.Distance then	
								DrawMarker(v.Type, v.Pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 250, false, true, 2, false, nil, nil, false)
								DrawText3Ds(playerCoords.x,playerCoords.y+0.4,playerCoords.z+0.5, v.message, {0.35,0.35}, 4,{255, 255, 255, 255}, {0,0,0,75}, {0, 0, 0, 150})
								if IsControlJustReleased(0, 38) then
									v.func()
								end
							else
								Menu.Toggle = false
								Menu.Boss = false
							end				
						end
					end
					if v.grade[i] == 'none' and v.activate then
						DrawMarker(v.Type, v.Pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)	
						if distance < Config.Distance then
							DrawText3Ds(playerCoords.x,playerCoords.y+0.4,playerCoords.z+0.5, v.message, {0.35,0.35}, 4,{255, 255, 255, 255}, {0,0,0,75}, {0, 0, 0, 150})
							if IsControlJustReleased(0, 38) then
								v.func()
							end
						else
							Menu.Toggle = false
							Menu.Boss = false
						end
					end
				end
			end
		end
		if interval then
			Wait(500)
		end
	end
end)

if Config.Qtarget then
	CreateThread(function()
		while true do
			Wait(0)
			local interval = true
			local playerCoords = GetEntityCoords(PlayerPedId())
			for k,v in pairs (Config.Zones) do
				local distance = #(playerCoords - v.Pos)
				if distance < Config.DrawDistance then interval = false
					for i = 1, #v.grade do
						if ESX.PlayerData.job.name == 'cardealer' and ESX.PlayerData.job.grade_name == v.grade[i] and v.activate then
							if distance < Config.Distance then
								exports.qtarget:AddTargetModel({1333557690}, {
									options = {
										{
											event = v.event,
											icon = "fas fa-box-circle-check",
											label = v.qmessage,
											num = 1
										},
									},
									distance = 2
								})
							else
								Menu.Toggle = false
								Menu.Boss = false
							end
						end
					end
				end
			end
			if interval then
				Wait(500)
			end
		end
	end)
end

-- Extras
function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

function DrawText3Ds(x,y,z,text,scale,police,color,color1,color2)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(scale[1], scale[2])
    SetTextFont(police)
    SetTextProportional(1)
    SetTextColour(color[1], color[2], color[3], color[4])
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, color1[1], color1[2], color1[3], color1[4])
    DrawRect(_x,_y+0.0300, 0.015+ factor, 0.005, color2[1], color2[2], color2[3], color2[4])
end

if Config.CloseCar then
	function StartWorkaroundTask()
		if isRunningWorkaround then
			return
		end
		local timer = 0
		local playerPed = PlayerPedId()
		isRunningWorkaround = true
		while timer < 100 do
			Citizen.Wait(50)
			timer = timer + 1
			local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
			if DoesEntityExist(vehicle) then
				local lockStatus = GetVehicleDoorLockStatus(vehicle)

				if lockStatus == 4 then
					ClearPedTasks(playerPed)
				end
			end
		end
		isRunningWorkaround = false
	end

	function ToggleVehicleLock()
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local vehicle
		Citizen.CreateThread(function()
			StartWorkaroundTask()
		end)
		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords, 8.0, 0, 71)
		end
		if not DoesEntityExist(vehicle) then
			return
		end
		ESX.TriggerServerCallback('esx_vehicleshop:requestPlayerCars', function(isOwnedVehicle)
			if isOwnedVehicle then
				local lockStatus = GetVehicleDoorLockStatus(vehicle)
				if lockStatus == 1 then
					lockAnimation()
					SetVehicleLights(vehicle, 2)
					Wait(250)
					SetVehicleLights(vehicle, 0)
					Wait(250)
					PlayVehicleDoorCloseSound(vehicle, 1)
					SetVehicleDoorsLocked(vehicle, 2)
					Citizen.Wait(450)
					PlaySoundFrontend(-1, "BUTTON", "MP_PROPERTIES_ELEVATOR_DOORS", 1)
					ESX.ShowNotification(_U('car_lock'))
				elseif lockStatus == 2 then 
					SetVehicleLights(vehicle, 2)
					Wait(250)
					SetVehicleLights(vehicle, 0)
					Wait(250)
					PlayVehicleDoorOpenSound(vehicle, 0)
					SetVehicleDoorsLocked(vehicle, 1)
					Citizen.Wait(450)
					PlaySoundFrontend(-1, "BUTTON", "MP_PROPERTIES_ELEVATOR_DOORS", 1)
					ESX.ShowNotification(_U("car_unlock"))
				end
			end
		end, ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
	end

	function lockAnimation()
		local ply = PlayerPedId()
		RequestAnimDict("anim@heists@keycard@")
		while not HasAnimDictLoaded("anim@heists@keycard@") do
			Wait(50)
		end
		TaskPlayAnim(ply, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
		Wait(600)
		ClearPedTasks(ply)
	end

	Keys.Register('U', 'esx_vehicleshop', 'Close / Open door car', function()
		ToggleVehicleLock()
	end)
end