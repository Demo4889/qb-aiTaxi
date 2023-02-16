local QBCore = exports['qb-core']:GetCoreObject()
local config = Config

RegisterNetEvent('esx_aiTaxi:pay', function(price)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	xPlayer.removeMoney(price)
	TriggerClientEvent('esx:showNotification', _source, 'Das macht dann ~g~$'..price..'~s~. Vielen Dank')
end)

QBCore.Commands.Add('aitaxi', 'Call an AI Taxi', {}, false, function(source, args)
	TriggerClientEvent('qb_aiTaxi:client:callTaxi', source)
end)

QBCore.Commands.Add('cancelaitaxi', 'Cancel an AI Taxi', {}, false, function(source, args)
	TriggerClientEvent('qb_aiTaxi:client:cancelTaxi', source, config.Language.cancelTaxi)
end)