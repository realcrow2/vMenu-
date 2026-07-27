--[[
    vMenu-ox :: Discord / Ace Rank Tags -- CLIENT
    ---------------------------------------------
    Receives the rank table from the server and hands it to the C# side, which
    prefixes the overhead player names when "Show Player Names" is enabled.

    Exports (for your other scripts):
        exports.vMenu:getRankLabel(serverId)   -> "ADMIN" | nil
        exports.vMenu:getRankColour(serverId)  -> HUD colour index (number)
        exports.vMenu:getRankTag(serverId, name) -> "[ADMIN] Gravxd"
]]

local ranks = {}   -- ["<serverId>"] = { label = "ADMIN", colour = 1, priority = 80 }

local function conf()
    return RankConfig or {}
end

--- Push the whole table to the C# client script.
local function sendToCSharp()
    TriggerEvent("vMenu:Ranks:ClientSync", json.encode({
        enabled      = conf().Enabled ~= false,
        format       = conf().TagFormat or "[%s] %s",
        showServerId = conf().ShowServerId ~= false,
        ranks        = ranks,
    }))
end

RegisterNetEvent("vMenu:Ranks:Sync", function(data)
    ranks = data or {}
    sendToCSharp()
end)

RegisterNetEvent("vMenu:Ranks:Update", function(serverId, rank)
    ranks[tostring(serverId)] = rank
    sendToCSharp()
end)

--- Ask the server for the table.
local function request()
    if conf().Enabled == false then return end
    TriggerServerEvent("vMenu:Ranks:Request")
end

AddEventHandler("onClientResourceStart", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    SetTimeout(1500, request)
end)

AddEventHandler("playerSpawned", function()
    SetTimeout(1000, request)
end)

-- When the player toggles overhead names on, make sure we have fresh data.
AddEventHandler("vMenu:Integrations:Action", function(action, data)
    if action == "playernames" and data and data.enabled then
        request()
    end
end)

-- The C# side asks for the data on its first tick too (in case load order differs).
RegisterNetEvent("vMenu:Ranks:ClientRequest", function()
    sendToCSharp()
    request()
end)

-----------------------------------------------------------------------------
-- Exports
-----------------------------------------------------------------------------

exports("getRankLabel", function(serverId)
    local r = ranks[tostring(serverId)]
    return r and r.label or nil
end)

exports("getRankColour", function(serverId)
    local r = ranks[tostring(serverId)]
    return r and r.colour or 0
end)

exports("getRankTag", function(serverId, name)
    local r = ranks[tostring(serverId)]
    if not r or not r.label then return name end
    return string.format(conf().TagFormat or "[%s] %s", r.label, name)
end)
