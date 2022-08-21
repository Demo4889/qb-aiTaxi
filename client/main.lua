local QBCore = exports['qb-core']:GetCoreObject()

local config = Config
local ped = nil
local taxiBlip = false
local globalTaxi = nil
local customer = nil
local onTour = false
local driveFinish = nil


RegisterNetEvent('qb_aiTaxi:client:callTaxi', function(coords)
	if customer then
		QBCore.Functions.Notify(config.Language.taxionway, 'error', 3000)
	else
		customer = coords
		-- get best spawnpoint
		playerPed = GetPlayerPed(-1)
		myCoords = GetEntityCoords(playerPed)
		for k,v in pairs(Config.SpawnPoints) do
			heading = v.h
			v = vector3(v.x, v.y, v.z)
			spawnDistance = GetDistanceBetweenCoords(myCoords, v)
			if oldDistance then
				if spawnDistance < oldDistance then
					oldDistance = spawnDistance
					realSpawnPoint = v
				else
					oldDistance = oldDistance
				end
			else
				oldDistance = spawnDistance
				realSpawnPoint = v
			end
		end
		while not HasModelLoaded(config.TaxiDriver) do
			RequestModel(config.TaxiDriver)
			Wait(50)
		end
		while not HasModelLoaded(config.TaxiModel) do
			RequestModel(config.TaxiModel)
			Wait(50)
		end
		if ped == nil then
			ped = CreatePed(4, config.TaxiDriver, realSpawnPoint.x, realSpawnPoint.y, realSpawnPoint.z + 2, 0.0, true, true)
		end
		if DoesEntityExist(globalTaxi) then
			QBCore.Functions.DeleteVehicle(globalTaxi)
		end
		
		QBCore.Functions.SpawnVehicle(config.TaxiModel, function(veh)
			TaskWarpPedIntoVehicle(ped, veh, -1)
			SetVehicleHasBeenOwnedByPlayer(veh, true)
			taxiBlip = true
			globalTaxi = veh
			SetEntityAsMissionEntity(globalTaxi, true, true)
			DriveToCustomer(customer.x, customer.y, customer.z, false, 'start')
		end, realSpawnPoint, true)
		ESX.Game.SpawnVehicle(config.TaxiModel, realSpawnPoint, heading, function(callback_vehicle)
			TaskWarpPedIntoVehicle(ped, callback_vehicle, -1)
			SetVehicleHasBeenOwnedByPlayer(callback_vehicle, true)
			taxiBlip = true
			globalTaxi = callback_vehicle
			SetEntityAsMissionEntity(globalTaxi, true, true)
		end)
	end
end)

RegisterNetEvent('qb_aiTaxi:client:setTaxiBlip', function(coords)
	if CarBlip then
		RemoveBlip(CarBlip)
		CarBlip = nil
	elseif not onWayBack then
		CarBlip = AddBlipForCoord(coords)
		SetBlipSprite(CarBlip , 56)
		SetBlipScale(CarBlip , 0.8)
		SetBlipColour(CarBlip, 5)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString('TAXI')
		EndTextCommandSetBlipName(CarBlip)
	end
end)

RegisterNetEvent('qb_aiTaxi:client:killTaxiBlip', function()
	RemoveBlip(CarBlip)
end)

RegisterNetEvent('qb_aiTaxi:client:cancelTaxi', function(message)
	atTarget(message)
end)

CreateThread(function()
	local playerPed = GetPlayerPed(-1)
	while true do
		Wait(0)
		inCar = false
		if customer ~= nil then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle == globalTaxi then
				inCar = true
				local waypoint = GetFirstBlipInfoId(8)
				if not DoesBlipExist(waypoint) and not onTour then
					ESX.ShowHelpNotification('Wo möchten Sie hin?')
					Wait(2000)
				else
					tx, ty, tz = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, waypoint, Citizen.ResultAsVector()))
					if not onTour then
						if not targetX then
							targetX = tx
							targetY = ty
							targetZ = tz
						end
						Drive(tx, ty, tz, false, false)
						onTour = true
					end
				end
			end
		end
	end
end)

--distancechecks
CreateThread(function()
	local playerPed = GetPlayerPed(-1)
	while true do
		Wait(0)
		if customer ~= nil then
			myCoords = GetEntityCoords(playerPed)
			taxiCoords = GetEntityCoords(ped)
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle == globalTaxi then
				route = CalculateTravelDistanceBetweenPoints(customer.x, customer.y, customer.z, taxiCoords.x, taxiCoords.y, taxiCoords.z)
				--check distance between me and the destination
				if GetDistanceBetweenCoords(myCoords, targetX, targetY, targetZ) < 20 then
					atTarget()
				end
			end
			--check if taxi is next to me 
			if customer ~= nil then
				local distanceMeTaxi = GetDistanceBetweenCoords(customer.x, customer.y, customer.z, taxiCoords.x, taxiCoords.y, taxiCoords.z, true)
				if distanceMeTaxi <= 40 then
					if not parkingDone then
						Parking(customer.x, customer.y, customer.z)
						QBCore.Functions.Notify(config.Language.taxiarrived, 'success', 3000)
					end
					if GetDistanceBetweenCoords(customer.x, customer.y, customer.z, taxiCoords.x, taxiCoords.y, taxiCoords.z, true) <= 3 then
						taxiArrived = true
					end
				end
			end
		end
	end
end)

--keycontrol
CreateThread(function()
	while true do
		Wait(0)
		if customer ~= nil then
			if taxiArrived and not inCar and not onWayBack then
				ESX.ShowHelpNotification('Mit ~INPUT_PICKUP~ einsteigen')
				if IsControlJustReleased(0, Config.VehicleEnterKey) and GetLastInputMethod(2) then
					TaskEnterVehicle(GetPlayerPed(-1), globalTaxi, 1000, math.random(0,2), 2.0, 1, 0)
				end
			end
		end
	end
end)

-- taxiBlip
CreateThread(function()
	while true do
		Wait(450)
		if taxiBlip then
			coords = GetEntityCoords(ped)
			TriggerEvent('qb_aiTaxi:client:setTaxiBlip', coords)
		end
	end
end)

--draw marker
CreateThread(function()
	while true do
		Wait(0)
		markerCoords = GetEntityCoords(globalTaxi)
		if ped ~= nil and not onWayBack then
			if GetDistanceBetweenCoords(markerCoords, myCoords) > 2 then
				DrawMarker(0, markerCoords.x, markerCoords.y, markerCoords.z+3, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 2.0, 244, 123, 23, 100, true, true, 2, true, false, false, false)
			end
		end
	end
end)

function atTarget(cancel)
	cancelTaxi = false
	if cancel then
		playerPed = GetPlayerPed(-1)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		if vehicle ~= globalTaxi then
			QBCore.Functions.Notify(config.Language.canceltaxi, 'success', 5000)
			cancelTaxi = true
		else
			QBCore.Functions.Notify(config.Language.cantcancel, 'error', 5000)
			return
		end
	end
	if not cancelTaxi then
		QBCore.Functions.Notify(config.Language.arriveddest, 'error', 5000)
		route2 = CalculateTravelDistanceBetweenPoints(customer.x, customer.y, customer.z, targetX, targetY, targetZ)
		price = (route2/1000) * config.Price
		TriggerServerEvent('qb_aiTaxi:client:pay', price)
		TaskLeaveVehicle(GetPlayerPed(-1), globalTaxi, 1)
		Wait(5000)
	end
	onWayBack = true
	customer = nil
	targetX = nil
	taxiBlip = nil
	RemoveBlip(CarBlip)
	parkingDone = false
	taxiArrived = false
	onTour = false
	onWayBack = false
	Drive(26.92, -1736.77, 28.3, true, 'end')
	ped = nil
	globalTaxi = nil
end

function Parking(x, y ,z)
	TaskVehiclePark(ped, globalTaxi, x, y, z, 0.0, 0, 30.0, false)
	parkingDone = true
end

function Drive(x, y , z, delete, status)
	if status == 'start' then
		Wait(math.random(1000,3000))
		QBCore.Functions.Notify(config.Language.enroute, 'success', 3000)
	elseif status == 'end' then
		QBCore.Functions.Notify(config.Language.thankyou, 'success', 3000)
	end

	TaskVehicleDriveToCoordLongrange(ped, globalTaxi, x, y, z, config.Speed, config.DriveMode, 20.0)

	if delete then
		Wait(15000)
		DeletePed(ped)
		QBCore.Functions.DeleteVehicle(globalTaxi)
	end
end