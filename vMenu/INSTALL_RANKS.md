# vMenu (vMenu-ox) — with Discord Staff Rank Tags
### Coastal Bay Roleplay — drag & drop build

This is a **complete, ready-to-run vMenu resource**. The DLLs are already compiled with the
rank-tag feature built in. Nothing to build, nothing to compile, no Visual Studio.

---

## 1. Install

Drop this `vMenu` folder into your resources path, exactly where your old one was:

```
/resources/[cbrp-scripts]/[Menus]/vMenu/
```

Replace your existing `vMenu` folder. (Back up your old `config/permissions.cfg` first if you
customised it — see step 3.)

## 2. server.cfg load order

`Badger_Discord_API` and `DiscordAcePerms` **must start before vMenu**:

```cfg
ensure ox_lib
ensure Badger_Discord_API
ensure DiscordAcePerms
ensure vMenu
```

## 3. Merge your permissions

This build ships the stock `config/permissions.cfg` **plus** a new block at the bottom titled
`OVERHEAD NAME RANK TAGS -- Coastal Bay Roleplay (STAFF)`.

- If you **customised** your old `permissions.cfg`: keep your old file, and copy just that final
  block (from `##### OVERHEAD NAME RANK TAGS #####` to the end) onto the bottom of it.
- If you used the **stock** file: you're already done.

Make sure it's loaded in `server.cfg`:
```cfg
exec @vMenu/config/permissions.cfg
```

## 4. Restart

```
restart vMenu
```

In game: **M → Misc Settings → Show Player Names**. Staff now show as `[SR ADMIN] Name [7]` in
their rank colour. Everyone else shows the normal `Name [12]`.

---

## What's in here

| Path | |
|---|---|
| `config/config_ranks.lua` | **Your rank list.** 38 staff ranks, filled in from your DiscordAcePerms config |
| `config/permissions.cfg` | Stock file + the staff self-ace block at the bottom |
| `server/discordRanks.lua` | Resolves ranks (aces + Badger Discord roles), caches, refreshes |
| `client/discordRanks.lua` | Feeds the rank table to the C# side |
| `vMenuClient.net.dll` | Rebuilt — contains the overhead-name changes |
| `vMenuServer.net.dll` | Rebuilt (code unchanged) |

> **Note on DLL size:** `vMenuClient.net.dll` is ~1.3 MB here vs ~1.9 MB in older builds. Nothing is
> missing — it was compiled with a newer Roslyn that writes a more compact embedded PDB. Every
> original class and method is present, verified by metadata diff (0 missing, 34 added — all the
> new rank code).

## How ranks are matched

Every rank is checked **two ways** — either one hits and the tag shows:

```lua
{ label = "ADMIN", priority = 710, colour = 1,
  ace  = "group.admin",              -- your DiscordAcePerms principal
  role = "1529201923914203157" },    -- the raw Discord role ID from your roleList
```

So it keeps working if DiscordAcePerms is slow to sync, or if Badger is down. Highest `priority`
wins when someone holds several roles — a `group.admin` who is also `group.staffTeam` shows
`[ADMIN]`, not `[STAFF]`.

### Rank ladder

| Tier | Tags (high → low) | Colour |
|---|---|---|
| Ownership | `OWNER` `CO-OWNER` `GM` | purple |
| Management | `SR MGMT` `MGMT` `JR MGMT` `TRIAL MGMT` `COMM MGR` `MGMT TEAM` `SECURITY` `MGMT ASST` | purple / grey |
| Development | `DEV DIR` `ASST DEV DIR` `DEV MGR` `DEV` | blue |
| Coordination | `STAFF MGMT` `STAFF COORD` `DEPT OVERSEER` `DEPT MGMT` `DEPT COORD` `GANG MGMT` `GANG COORD` `BIZ MGMT` `BIZ COORD` `CIV MGMT` `CIV COORD` | orange |
| Head Admin | `SR HEAD ADMIN` `HEAD ADMIN` `JR HEAD ADMIN` | red |
| Admin | `SR ADMIN` `ADMIN` | red |
| Moderation | `HEAD MOD` `SR MOD` `MOD` `TRIAL MOD` | yellow |
| Staff tiers | `HIGH STAFF` `SR STAFF` `STAFF` | light blue |

**Not tagged** (plain `Name [id]`): communityMember, certifiedCivilian, all LEO/fire/department
groups, State Patrol, FIB, IAA, and every donator / perk pack role.

Want a department tag? Add a line to `Ranks` in `config/config_ranks.lua`:
```lua
{ label = "LSPD", priority = 500, colour = 3, ace = "group.lspd", role = "1529202005526974536" },
```

## Options — `config/config_ranks.lua`

```lua
Enabled         = true,      -- false = vanilla names
TagFormat       = "[%s] %s", -- 1st %s = rank, 2nd %s = name
ShowServerId    = true,      -- false = drop the " [12]"
ShowUnranked    = false,     -- true = everyone else gets "[CIVILIAN]"
RefreshInterval = 600,       -- seconds; matches your DiscordAcePerms Refresh_Throttle
```

Colours are GTA HUD indexes: `6` purple, `1` red, `5` yellow, `3`/`27` blue, `7` orange, `8` grey,
`46` light blue, `0` white.

## Commands

```
vmenu_refreshranks       # re-check everyone (console, or staff in-game)
vmenu_refreshranks 12    # re-check one player
vmenu_ranks              # print the rank cache (console only)
```

Granted to `group.owner`, `group.coowner`, `group.headAdmin`, `group.seniorHeadAdmin`.

## Exports

```lua
-- server
exports.vMenu:getPlayerRank(src)      --> { label = "ADMIN", colour = 1, priority = 710 } | nil
exports.vMenu:refreshPlayerRank(src)

-- client
exports.vMenu:getRankLabel(serverId)
exports.vMenu:getRankColour(serverId)
exports.vMenu:getRankTag(serverId, name)
```

## Troubleshooting

| Problem | Fix |
|---|---|
| No tags at all | Turn on *Show Player Names* in Misc Settings. Check `RankConfig.Enabled = true`. |
| Aces work, Discord roles don't | `ensure Badger_Discord_API` **before** vMenu; bot token + guild ID set in its config; player must have Discord linked in their FiveM client. |
| Discord roles work, aces don't | The self-ace block at the bottom of `permissions.cfg` is missing — see step 3. |
| Wrong rank shows | Higher `priority` wins. Adjust in `config/config_ranks.lua`. |
| Rank changed but tag didn't | Run `vmenu_refreshranks`, lower `RefreshInterval`, or call `exports.vMenu:refreshPlayerRank(src)`. |
| Everyone shows `[CIVILIAN]` | `ShowUnranked` is `true`. Set it to `false`. |

Run `vmenu_ranks` in the server console to see exactly what the server resolved for each player —
fastest way to tell a Discord problem from an ace problem.

---

## Note on your DiscordAcePerms config

Your `roleList` had this entry:

```lua
{1529201850056839318, "[group.management](http://group.management)"},
```

The group name got saved with markdown link syntax around it. I used the clean `group.management`
here — but fix it in your actual DiscordAcePerms config too, otherwise that role grants a broken
principal name and the ace half of the check won't fire for it. (The Discord role ID half still works.)
