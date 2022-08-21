Eliminate your taxi job and have NPC's run the business.

Features:
- Call a taxi from your phone
- Taxi will spawn at the nearest location to the player (set in the config)
- A Blip of the taxi will be displayed on your minimap
- Once the taxi arrives, you set your waypoint on the map
- Once you reach your destination, the taxi will drive away and despawn.

Config Options:
- Taxi Driver Model
- Taxi Vehicle Model
- Taxi Enter Key
- Taxi Price for Ride
- Taxi Speed
- Taxi Drive Mode (https://gtaforums.com/topic/822314-guide-driving-styles/)
- Various locations to spawn Taxi at
- Set your own local language

Update your qb_phone to call an AI Taxi:
**qb_phone/**
*server.lua*

find:
```
RegisterServerEvent('esx_addons_gcphone:startCall')
AddEventHandler('esx_addons_gcphone:startCall', function (number, message, coords)
  local source = source
  if PhoneNumbers[number] ~= nil then
    getPhoneNumber(source, function (phone) 
      notifyAlertSMS(number, {
        message = message,
        coords = coords,
        numero = phone,
      }, PhoneNumbers[number].sources)
    end)
  else
    print('Appels sur un service non enregistre => numero : ' .. number)
  end
end)
```
 **and replace it with:**

```
RegisterServerEvent('esx_addons_gcphone:startCall')
AddEventHandler('esx_addons_gcphone:startCall', function (number, message, coords)
  local source = source

  if PhoneNumbers[number] ~= nil then
	if number == 'taxi' then
		if message == 'cancel' then
			TriggerClientEvent('esx_aiTaxi:cancelTaxi', source, true)
		else
			TriggerClientEvent('esx_aiTaxi:callTaxi', source, coords)
		end
	else
		getPhoneNumber(source, function (phone) 
		  notifyAlertSMS(number, {
			message = message,
			coords = coords,
			numero = phone,
		  }, PhoneNumbers[number].sources)
		end)
	end
  else
    print('Appels sur un service non enregistre => numero : ' .. number)
  end
end)
```

Add this to the *config.json* of gcphone
these are the last lines in area of "serviceCall"

```
    },
    {
      "display": "Taxi",
      "backgroundColor": "yellow",
      "subMenu": [
	  {
			"title": "Taxi bestellen",
			"eventName": "esx_addons_gcphone:call",
			"type": {
				"number": "taxi",
				"message": "i need a ride"
			}
		},
        {
          "title": "Taxi abbestellen",
          "eventName": "esx_addons_gcphone:call",
          "type": {
				"number": "taxi",
				"message": "cancel"
			}
        }
      ]
    }
  ],

  "defaultContacts": [{
```

Known Bugs:
- sometimes if the taxidriver hits another car he will stop driving and you have to cancel the order.
- sometime the drivingmode is a little bit weird. if someone gets a better one feel free to share
