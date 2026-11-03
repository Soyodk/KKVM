local ownerAccountName = "ruaan"
local grantFlag = "kkvm.ownerPerks.v1"
local startingMoney = 10000000
local startingCash = 1000000
local vehicleModels = {411, 541, 415, 585, 522, 461, 521, 468}

local function grantOwnerPerks(player, account)
    if not account or getAccountName(account) ~= ownerAccountName then
        return
    end

    local dealership = getResourceFromName("goiaba_Concessionaria")
    if dealership and getResourceState(dealership) == "running" then
        for _, model in ipairs(vehicleModels) do
            exports.goiaba_Concessionaria:addedAccountVehicle(ownerAccountName, model)
        end
        exports.goiaba_Concessionaria:removeAccountVehicle(ownerAccountName, 516)
        exports.goiaba_Concessionaria:removeAccountVehicle(ownerAccountName, 560)
    else
        outputDebugString("Owner perks skipped vehicles: dealership resource is not running", 2)
    end

    if getAccountData(account, grantFlag) then
        return
    end

    givePlayerMoney(player, startingMoney)
    setElementData(player, "Cash", (tonumber(getElementData(player, "Cash")) or 0) + startingCash)

    setAccountData(account, grantFlag, true)
    outputDebugString("Owner perks granted to " .. ownerAccountName)
end

addEventHandler("onPlayerLogin", root, function(_, account)
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "kkvm.ownerPerks.applyModels", resourceRoot, vehicleModels)
    end
    grantOwnerPerks(source, account)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        triggerClientEvent(player, "kkvm.ownerPerks.applyModels", resourceRoot, vehicleModels)
    end
end)