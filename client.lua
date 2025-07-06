local isFirstPersonForced = false
local lastCamViewMode = nil

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)

        if not Config.Enabled then
            goto continue
        end

        local playerPed = PlayerPedId()
        local playerId = PlayerId()
        local aiming = IsPlayerFreeAiming(playerId) or IsPedShooting(playerPed)
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        local vehicle = inVehicle and GetVehiclePedIsIn(playerPed, false)
        local isCar = inVehicle and not isBike and not IsThisModelAHeli(GetEntityModel(vehicle))
        local isHeli = inVehicle and IsThisModelAHeli(GetEntityModel(vehicle))

        -- Determine seat index
        local seatIndex = -2 -- default invalid
        if inVehicle then
            seatIndex = GetPedInVehicleSeat(vehicle, -1) == playerPed and -1 or -2
            for i = 0, 5 do
                if GetPedInVehicleSeat(vehicle, i) == playerPed then
                    seatIndex = i
                    break
                end
            end
        end

        local isDriver = (seatIndex == -1)

        -- Check if this seat is allowed to shoot
        local passengerSeatAllowed = true
        if not isDriver then
            passengerSeatAllowed = Config.AllowedPassengerSeatsToShoot[seatIndex] == true
        end

        local shouldForce =
            (Config.OnFoot and not inVehicle and aiming) or
            (
                (Config.InCar and isCar and aiming) or
                (Config.InHeli and isHeli and aiming)
            )
            and (isDriver or (Config.PassengerFirstPersonAllowed == true and passengerSeatAllowed))

        if shouldForce and not isFirstPersonForced then
            lastCamViewMode = inVehicle and GetFollowVehicleCamViewMode() or GetFollowPedCamViewMode()
            if inVehicle then
                SetFollowVehicleCamViewMode(4) -- First Person
            else
                SetFollowPedCamViewMode(4)
            end
            isFirstPersonForced = true
        elseif not shouldForce and isFirstPersonForced then
            if inVehicle and lastCamViewMode and lastCamViewMode ~= 4 then
                SetFollowVehicleCamViewMode(lastCamViewMode)
            elseif not inVehicle and lastCamViewMode and lastCamViewMode ~= 4 then
                SetFollowPedCamViewMode(lastCamViewMode)
            end
            isFirstPersonForced = false
            lastCamViewMode = nil
        end

        ::continue::
    end
end)

-- Disable Car Radio

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            SetUserRadioControlEnabled(false)
            if GetPlayerRadioStationName() ~= nil then
                SetVehRadioStation(GetVehiclePedIsIn(PlayerPedId()),"OFF")
            end
        end
    end
end)



