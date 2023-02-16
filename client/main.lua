local QBCore = exports['qb-core']:GetCoreObject()

local config = Config
local ped = nil
local taxiBlip = false
local globalTaxi = nil
local customer = false
local onTour = false

local function DrawText3D(x, y, z, text)
    -- Use local function instead
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function DrawText2D(x, y, width, height, scale, r, g, b, a, text)
    -- Use local function instead
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x - width / 2, y - height / 2 + 0.005)
end

RegisterNetEvent('qb_aiTaxi:client:callTaxi', function()
	if customer then
		QBCore.Functions.Notify(config.Language.taxionway, 'error', 3000)
	else
		local playerPed = GetPlayerPed(-1)
		local myCoords = GetEntityCoords(playerPed)
		for k,v in pairs(Config.SpawnPoints) do
			v = vector4(v.x, v.y, v.z, v.h)
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
			customer = true
			SetEntityAsMissionEntity(globalTaxi, true, true)
			DriveToCustomer(ped, myCoords.x, myCoords.y, myCoords.z, 'start', false)
		end, realSpawnPoint, true)
	end
end)

RegisterNetEvent('qb_aiTaxi:client:setTaxiBlip', function(coords)
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
		if customer and globaltaxi ~= nil then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle == globalTaxi then
				inCar = true
				local waypoint = GetFirstBlipInfoId(8)
				if not DoesBlipExist(waypoint) and not onTour then
					DrawText2D(0.9, 0.9, 1.0, 1.0, 1.0, 255, 255, 255, 255, "Where do you want to go?")
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
		if customer then
			myCoords = GetEntityCoords(playerPed)
			taxiCoords = GetEntityCoords(globalTaxi)
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if vehicle == globalTaxi then
				route = CalculateTravelDistanceBetweenPoints(myCoords.x, myCoords.y, myCoords.z, taxiCoords.x, taxiCoords.y, taxiCoords.z)
				--check distance between me and the destination
				if GetDistanceBetweenCoords(myCoords, targetX, targetY, targetZ) < 20 then
					atTarget()
				end
			end
			--check if taxi is next to me 
			if customer then
				local distanceMeTaxi = GetDistanceBetweenCoords(myCoords.x, myCoords.y, myCoords.z, taxiCoords.x, taxiCoords.y, taxiCoords.z, true)
				if distanceMeTaxi <= 40 then
					if not parkingDone then
						local pHead = GetEntityHeading(PlayerPedId())
						Parking(myCoords.x, myCoords.y, myCoords.z, pHead)
					end

					if GetDistanceBetweenCoords(myCoords.x, myCoords.y, myCoords.z, taxiCoords.x, taxiCoords.y, taxiCoords.z, true) <= 3 then
						taxiArrived = true
						QBCore.Functions.Notify(config.Language.taxiarrived, 'success', 3000)
						print(GetVehicleDoorLockStatus(globalTaxi), NetworkGetNetworkIdFromEntity(globalTaxi))
						SetVehicleDoorsLocked(globalTaxi, 1)
						TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(globalTaxi), 1)
						return
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
		if customer then
			if taxiArrived and not inCar and not onWayBack then
				pCoords = GetEntityCoords(ped)
				DrawText3D(pCoords.x, pCoords.y, pCoords.z + 0.8, "Hop in")
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

function Parking(x, y, z, heading)
	TaskVehiclePark(ped, globalTaxi, x + 1.0, y + 1.0, z, heading, 1, 20.0, true)
	parkingDone = true
end

function DriveToCustomer(ped, x, y , z, status, delete)
	if status == 'start' then
		Wait(math.random(1000, 3000))
		QBCore.Functions.Notify(config.Language.enroute, 'success', 3000)
	elseif status == 'end' then
		QBCore.Functions.Notify(config.Language.thankyou, 'success', 3000)
	end

	TaskVehicleDriveToCoordLongrange(ped, globalTaxi, x, y, z, config.Speed, config.DriveMode, config.StopDistance)

	if delete then
		Wait(15000)
		DeletePed(ped)
		QBCore.Functions.DeleteVehicle(globalTaxi)
	end
end