--[[
    vMenu-ox :: Discord / Ace Rank Tags -- SERVER
    ---------------------------------------------
    Resolves every connected player's highest rank using:
        1. Ace permissions   (IsPlayerAceAllowed)  -> works with DiscordAcePerms / any ace setup
        2. Badger_Discord_API (raw Discord roles)  -> optional, only if the resource is running

    Sends the resolved table to all clients so overhead names can be prefixed.

    Console commands (server console / rcon only):
        vmenu_refreshranks           - re-resolve everyone
        vmenu_refreshranks <id>      - re-resolve one player
        vmenu_ranks                  - print the current rank table
]]

local ranksCache = {}     -- [serverId] = { label = "ADMIN", colour = 1, priority = 80 }
local resolving  = {}     -- [serverId] = true while a lookup is in flight

local function cfg()
    return RankConfig or {}
end

local function badgerRunning()
    local res = cfg().BadgerResource or "Badger_Discord_API"
    return GetResourceState(res) == "started"
end

--- Returns a lowercase set of the player's discord role ids AND role names.
---@param src number|string
---@return table<string, boolean>|nil
local function getDiscordRoles(src)
    if not badgerRunning() then return nil end

    local res = cfg().BadgerResource or "Badger_Discord_API"
    local ok, roles = pcall(function()
        return exports[res]:GetDiscordRoles(src)
    end)

    if not ok or type(roles) ~= "table" then
        return nil
    end

    local set = {}
    for i = 1, #roles do
        set[tostring(roles[i]):lower()] = true
    end
    return set
end

--- Resolve a role entry (name or id) against the player's role set.
local function hasRole(res, roleSet, role)
    if roleSet[tostring(role):lower()] then
        return true
    end
    -- Not an ID match: try resolving the role NAME into an ID through Badger.
    local ok, id = pcall(function()
        return exports[res]:GetRoleIdFromRoleName(tostring(role))
    end)
    if ok and id and roleSet[tostring(id):lower()] then
        return true
    end
    return false
end

--- Work out the highest priority rank for a player.
---@param src number
---@return table|nil
local function resolveRank(src)
    local conf   = cfg()
    local ranks  = conf.Ranks or {}
    local res    = conf.BadgerResource or "Badger_Discord_API"
    local best   = nil
    local roleSet -- lazily fetched, only if a rank actually uses discord roles

    for i = 1, #ranks do
        local rank = ranks[i]
        local matched = false

        -- 1) ace check
        if rank.ace and IsPlayerAceAllowed(tostring(src), rank.ace) then
            matched = true
        end

        -- 2) discord role check
        if not matched and rank.role then
            if roleSet == nil then
                roleSet = getDiscordRoles(src) or false
            end
            if roleSet then
                local wanted = type(rank.role) == "table" and rank.role or { rank.role }
                for r = 1, #wanted do
                    if hasRole(res, roleSet, wanted[r]) then
                        matched = true
                        break
                    end
                end
            end
        end

        if matched then
            local prio = rank.priority or 0
            if not best or prio > (best.priority or 0) then
                best = {
                    label    = rank.label,
                    colour   = rank.colour or 0,
                    priority = prio,
                }
            end
        end
    end

    if not best and conf.ShowUnranked then
        best = {
            label    = conf.UnrankedLabel or "CIVILIAN",
            colour   = conf.UnrankedColour or 0,
            priority = -1,
        }
    end

    return best
end

--- Push the full table to one client, or everyone when target is nil.
local function syncRanks(target)
    TriggerClientEvent("vMenu:Ranks:Sync", target or -1, ranksCache)
end

--- Resolve + cache + broadcast for a single player.
local function updatePlayer(src, silent)
    src = tonumber(src)
    if not src or resolving[src] then return end
    resolving[src] = true

    CreateThread(function()
        local rank = resolveRank(src)
        resolving[src] = nil

        if not GetPlayerName(src) then
            ranksCache[tostring(src)] = nil
            return
        end

        ranksCache[tostring(src)] = rank

        if not silent then
            TriggerClientEvent("vMenu:Ranks:Update", -1, tostring(src), rank)
        end
    end)
end

local function updateAll()
    for _, src in ipairs(GetPlayers()) do
        updatePlayer(src, true)
    end
    -- give the lookups a moment, then push the whole table out once
    SetTimeout(2500, function()
        syncRanks()
    end)
end

-----------------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------------

-- Client asks for the table (on resource start / player spawn / names toggled on).
RegisterNetEvent("vMenu:Ranks:Request", function()
    local src = source
    if ranksCache[tostring(src)] == nil then
        updatePlayer(src)
    end
    TriggerClientEvent("vMenu:Ranks:Sync", src, ranksCache)
end)

AddEventHandler("playerJoining", function()
    local src = source
    SetTimeout(1000, function() updatePlayer(src) end)
end)

AddEventHandler("playerDropped", function()
    local src = tostring(source)
    ranksCache[src] = nil
    TriggerClientEvent("vMenu:Ranks:Update", -1, src, nil)
end)

AddEventHandler("onResourceStart", function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if not cfg().Enabled then return end
    SetTimeout(2000, updateAll)
end)

-- Periodic refresh (Discord roles can change while someone is online).
CreateThread(function()
    local interval = tonumber(cfg().RefreshInterval or 0) or 0
    if not cfg().Enabled or interval <= 0 then return end
    while true do
        Wait(interval * 1000)
        updateAll()
    end
end)

-----------------------------------------------------------------------------
-- Exports & commands
-----------------------------------------------------------------------------

--- Other resources can grab a player's rank: exports.vMenu:getPlayerRank(src)
exports("getPlayerRank", function(src)
    return ranksCache[tostring(src)]
end)

--- Force a re-check from another resource (e.g. after you give someone a role).
exports("refreshPlayerRank", function(src)
    updatePlayer(src)
end)

RegisterCommand("vmenu_refreshranks", function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), "vMenu.Staff") then return end
    if args[1] then
        updatePlayer(args[1])
        print(("[vMenu] Refreshing ranks for player %s"):format(args[1]))
    else
        updateAll()
        print("[vMenu] Refreshing ranks for all players.")
    end
end, false)

RegisterCommand("vmenu_ranks", function(src)
    if src ~= 0 then return end
    print("[vMenu] Current rank cache:")
    for id, rank in pairs(ranksCache) do
        print(("  %s (%s) -> %s"):format(id, GetPlayerName(id) or "?", rank and rank.label or "none"))
    end
end, true)
