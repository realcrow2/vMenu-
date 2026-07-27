--[[
    vMenu-ox :: Discord / Ace Rank Tags for overhead player names
    Coastal Bay Roleplay
    -------------------------------------------------------------
    STAFF RANKS ONLY. Civilian / department / donator roles are intentionally
    NOT listed here, so those players just get the normal "Name [id]" tag.

    Every rank below is checked TWO ways, whichever hits first:
        ace  = "group.owner"          -> your DiscordAcePerms group principal
        role = "1529201837109022741"    -> the raw Discord role ID from your DiscordAcePerms roleList
    So it keeps working even if DiscordAcePerms is down/slow, as long as
    Badger_Discord_API is running (and vice versa).

    IMPORTANT: for the `ace` half to work you need the matching
    `add_ace group.x group.x allow` lines - they are already appended to
    config/permissions.cfg for you.

    Load order in server.cfg:
        ensure ox_lib
        ensure Badger_Discord_API
        ensure DiscordAcePerms
        ensure vMenu
]]

RankConfig = {
    -- Master switch. false = vanilla "Name [id]" tags.
    Enabled = true,

    -- %s (1st) = rank label, %s (2nd) = player name  ->  "[ADMIN] Gravxd"
    TagFormat = "[%s] %s",

    -- Keep vMenu's default " [serverId]" suffix on the overhead name?
    ShowServerId = true,

    -- Staff-only setup: non-staff get NO prefix.
    ShowUnranked = false,
    UnrankedLabel = "CIVILIAN",
    UnrankedColour = 0,

    -- Seconds between automatic re-checks (staff promotions apply without a reconnect).
    -- 600 matches your DiscordAcePerms Refresh_Throttle.
    RefreshInterval = 600,

    -- Name of the Badger Discord API resource.
    BadgerResource = "Badger_Discord_API",

    ----------------------------------------------------------------------
    -- STAFF RANKS (highest priority wins if someone holds several)
    ----------------------------------------------------------------------
    Ranks = {

        --==================== OWNERSHIP ====================--
        { label = "OWNER",        priority = 1000, colour = 0,  ace = "group.owner",              role = "1529201837109022741" },
        { label = "CO-OWNER",     priority = 990,  colour = 0,  ace = "group.coowner",            role = "1529201838606516316" },
        { label = "GM",           priority = 980,  colour = 0,  ace = "group.generalManager",     role = "1529201845933969561" },

        --==================== MANAGEMENT ====================--
        { label = "SR MGMT",      priority = 970,  colour = 0,  ace = "group.seniorManagement",   role = "1529201848454484011" },
        { label = "MGMT",         priority = 960,  colour = 0,  ace = "group.management",         role = "1529201850056839318" },
        { label = "JR MGMT",      priority = 950,  colour = 0,  ace = "group.juniorManagement",   role = "1529201851377909822" },
        { label = "TRIAL MGMT",   priority = 940,  colour = 0,  ace = "group.trialManagement",    role = "1529201852485468271" },
        { label = "COMM MGR",     priority = 930,  colour = 0,  ace = "group.communityManager",   role = "1529201853479387357" },

        --==================== HEAD ADMIN ====================--
        { label = "SR HEAD ADMIN",priority = 750,  colour = 0,  ace = "group.seniorHeadAdmin",  role = "1529201886543220947" },
        { label = "HEAD ADMIN",   priority = 740,  colour = 0,  ace = "group.headAdmin",        role = "1529201887528620203" },
        { label = "JR HEAD ADMIN",priority = 730,  colour = 0,  ace = "group.juniorHeadAdmin",  role = "1529201888631980163" },

        --==================== ADMINISTRATION ====================--
        { label = "SR ADMIN",     priority = 720,  colour = 0,  ace = "group.seniorAdmin",      role = "1529201914443464824" },
        { label = "ADMIN",        priority = 710,  colour = 0,  ace = "group.admin",            role = "1529201923914203157" },

        --==================== MODERATION ====================--
        { label = "HEAD MOD",     priority = 700,  colour = 0,  ace = "group.headMod",          role = "1529201924665249866" },
        { label = "SR MOD",       priority = 690,  colour = 0,  ace = "group.seniorMod",        role = "1529201927013798060" },
        { label = "MOD",          priority = 680,  colour = 0,  ace = "group.moderator",        role = "1529201928330805459" },
        { label = "TRIAL MOD",    priority = 670,  colour = 0,  ace = "group.tMod",             role = "1529201929476112454" },
    },
}

--[[
    COLOURS USED ABOVE
      6  = purple      -> ownership / management
      8  = grey        -> security team
      3  = blue        -> development leadership
      27 = blue        -> developers
      7  = orange      -> coordination / management tracks
      1  = red         -> head admin + admin
      5  = yellow      -> moderation
      46 = light blue  -> generic staff team tiers
      0  = white       -> default
    Full HUD colour list: https://docs.fivem.net/natives/?_0x613ED644

    NOT INCLUDED ON PURPOSE (not staff): communityMember, certifiedCivilian,
    whitelistedLeo, safr, lspd, bcso, sasp, sabp, departmentSupervisor, dhc,
    statePatrol/spSupervisor/spCommand, fib/fibSupervisor/fibCommand,
    iaa/iaaSupervisor/iaaCommand, and every donator/perk pack role.
    If you ever want a department tag (e.g. LSPD), just copy a line above and
    swap in the group + role ID from your DiscordAcePerms config.
]]
