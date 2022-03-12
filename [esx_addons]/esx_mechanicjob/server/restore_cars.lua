ESX                = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


-- Spawner Thread
Citizen.CreateThread(function()
	while true do
    Citizen.Wait(Config.Timer)
    TriggerEvent('esx_mechanicjob_restorecars:SpawnVehicle') -- only mechanics will see this
	end
end)


function math.randomchoice(t) --Selects a random item from a table
  local keys = {}
  for key, value in ipairs(t) do
    keys[#keys+1] = key --Store keys in another table
  end
  index = keys[math.random(1, #keys)]
  return t[index]
end


AddEventHandler('esx_mechanicjob_restorecars:SpawnVehicle', function()
	local model = math.randomchoice(Config.CarNames)
	local spawnPoint = math.randomchoice(Config.CarSpawns.SpawnPoints)

  TriggerClientEvent('esx_mechanicjob_restorecars:SpawnVehicle', -1, model, spawnPoint)
end)

RegisterServerEvent('esx_mechanicjob_restorecars:AddBlipForEntity')
AddEventHandler('esx_mechanicjob_restorecars:AddBlipForEntity', function(objNetID)
  TriggerClientEvent('esx_mechanicjob_restorecars:AddBlipForEntity', -1, objNetID)
end)
