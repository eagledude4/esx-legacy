local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX 							= nil
CurrentAction 		= nil
CurrentActionData = nil


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)


-- Script states
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)

		local car, carDistance = ESX.Game.GetClosestVehicle()
		local carNear = carDistance > 0 and carDistance < 3.0
    local rubbish, rubbishDistance = ESX.Game.GetClosestObject(Config.Rubbish)
    local rubbishNear = rubbishDistance > 0 and rubbishDistance < 1.5

    if not IsPedOnFoot(PlayerPedId()) then return end
		if carNear then
			for k, v in pairs(Config.CarNames) do --index, value
				if GetEntityModel(car) == GetHashKey(v) then
					CurrentAction = 'car_restore' -- DO THIS ONLY IF VEHICLE IS IN LS CUSTOMS SHOP
					CurrentActionData = car
				end
			end
		elseif rubbishNear then
			CurrentAction = 'collect_scrap'
			CurrentActionData = rubbish
    else
			CurrentAction = nil
			urrentActionData = nil
		end
	end
end)

-- Script Actions from states
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if CurrentAction ~= nil then
      if CurrentAction == 'car_restore' then -- DO THIS ONLY IF VEHICLE IS IN LS CUSTOMS SHOP
	      ESX.ShowHelpNotification(_U('press_input_button_restore'))
        if IsControlJustReleased(0, Keys['E']) then -- Input pickup, E by default
					isBusy = true
					local scenario = 'PROP_HUMAN_BUM_BIN'
					TaskStartScenarioInPlace(PlayerPedId(), scenario, 0, false)
					exports.pNotify:SendNotification({text = "Restoring vehicle, please wait...", type = "error", timeout = 20000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
					Citizen.CreateThread(function()
						Citizen.Wait(20000)
						local oldVehicle = CurrentActionData
						local model = GetNewModel(GetEntityModel(oldVehicle))
						local spawnPoint = GetEntityCoords(oldVehicle)
						local heading = GetEntityHeading(oldVehicle)
						local fuelLevel = exports["LegacyFuel"]:GetFuel(oldVehicle)
						ESX.Game.DeleteVehicle(oldVehicle)
						ESX.Game.SpawnVehicle(model, spawnPoint, heading, function(newVehicle)
							exports["LegacyFuel"]:SetFuel(newVehicle, fuelLevel)
							TriggerServerEvent('esx_vehiclelock:registerVehicleOwner', newVehicle)
							ESX.ShowNotification(_U('vehicle_restored'))
						end)
						ClearPedTasksImmediately(PlayerPedId())
						isBusy = false
					end)
				end
      elseif CurrentAction == 'collect_scrap' then
				local object = CurrentActionData
				local entityCoords = GetEntityCoords(object)
				DrawText3D(entityCoords.x, entityCoords.y, entityCoords.z + 0.5, 'Scrap')
	      ESX.ShowHelpNotification(_U('press_input_button_collect_junk'))
        if IsControlJustReleased(0, 38) then -- Input pickup, E by default
					local scenario = 'PROP_HUMAN_BUM_BIN'
					TaskStartScenarioInPlace(PlayerPedId(), scenario, 0, false)
					Wait(1000)
					ClearPedTasksImmediately(PlayerPedId())
					SetEntityAsMissionEntity(object)
			    DeleteObject(object)
          TriggerServerEvent('esx_mechanicjob:takeItem')
				end
      end
		else
			Citizen.Wait(500)
		end
	end
end)

function DrawText3D(x,y,z, text) -- some useful function, use it if you want!
  SetDrawOrigin(x, y, z, 0);
	SetTextFont(0)
	SetTextProportional(0)
	SetTextScale(0.0, 0.53)
	SetTextColour(19, 232, 46, 240)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(2, 0, 0, 0, 150)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

function GetNewModel(modelHash)
	if modelHash == GetHashKey('carscrap1') then return 'burrito'
	elseif modelHash == GetHashKey('carscrap3') then return 'peyote'
	elseif modelHash == GetHashKey('carscrap4') then return 'rancherxl' end
end


RegisterNetEvent('esx_mechanicjob_restorecars:AddBlipForEntity')
AddEventHandler('esx_mechanicjob_restorecars:AddBlipForEntity', function(objNetID)
  local object = NetworkGetEntityFromNetworkId(objNetID)
  local blip = AddBlipForEntity(object)

  SetBlipSprite(blip, 225)
  SetBlipDisplay(blip, 4)
  SetBlipScale(blip, 1.0)
  SetBlipAsShortRange(blip, false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Wrecked Car")
	EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('esx_mechanicjob_restorecars:SpawnVehicle')
AddEventHandler('esx_mechanicjob_restorecars:SpawnVehicle', function(model, spawnPoint)
	if NetworkIsHost() then
		if ESX ~= nil then
			if ESX.Game.IsSpawnPointClear(spawnPoint.coords, spawnPoint.radius) then
				ESX.Game.SpawnVehicle(model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
					--print(string.format("spawned %s at %s heading %s", model, json.encode(spawnPoint.coords), spawnPoint.heading))
					exports["LegacyFuel"]:SetFuel(vehicle, 0)
					TriggerServerEvent('esx_mechanicjob_restorecars:AddBlipForEntity', NetworkGetNetworkIdFromEntity(vehicle)) -- only mechanics will see this
					--ESX.ShowAdvancedNotification(_U('informant'), _U('yayo'), _U('call', current_zone), 'CHAR_BLANK_ENTRY', 7)
				end)
			end
		end
	end
end)
