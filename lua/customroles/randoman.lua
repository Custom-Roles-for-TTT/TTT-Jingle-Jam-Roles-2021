local ROLE = {}
ROLE.nameraw = "randoman"
ROLE.name = "Randoman"
ROLE.nameplural = "Randomen"
ROLE.nameext = "a Randoman"
ROLE.nameshort = "ran"
ROLE.desc = [[You are {role}!
You're {adetective}, but you can buy randomats instead of {detective} items!]]
ROLE.team = ROLE_TEAM_DETECTIVE
ROLE.shop = {"weapon_ttt_randomat"}
ROLE.loadout = {}
ROLE.startingcredits = 1
ROLE.selectionpredicate = function() return Randomat and type(Randomat.IsInnocentTeam) == "function" end

-- Lame is pointless to have in the shop as it itself does nothing
CreateConVar("ttt_randoman_banned_randomats", "lame", {FCVAR_NOTIFY}, "Events not allowed in the randoman's shop, separate ids with commas. You can find an ID by turning a randomat on/off in the randomat ULX menu and copying the word after 'ttt_randomat_', which appears in chat.")

local preventAutoRandomatCvar = CreateConVar("ttt_randoman_prevent_auto_randomat", 1, {FCVAR_NOTIFY}, "Prevent auto-randomat triggering if there is a randoman at the start of the round", 0, 1)

CreateConVar("ttt_randoman_guaranteed_categories", "biased_innocent,fun,moderateimpact", {FCVAR_NOTIFY}, "At least one randomat from each of these categories will always be in the randoman's shop. You can find a randomat's category by looking at an event in the randomat ULX menu.")

CreateConVar("ttt_randoman_guaranteed_randomats", "", {FCVAR_NOTIFY}, "Events that will always appear in the randoma's shop, separate ids with commas.")

local eventOnUnboughtDeathCvar = CreateConVar("ttt_randoman_event_on_unbought_death", 1, {FCVAR_NOTIFY}, "Whether a randomat should trigger if a randoman dies and never bought anything that round", 0, 1)

ROLE.convars = {
    {
        cvar = "ttt_randoman_banned_randomats",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_randoman_prevent_auto_randomat",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoman_guaranteed_categories",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_randoman_guaranteed_randomats",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_randoman_event_on_unbought_death",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

RegisterRole(ROLE)

if SERVER then
    local categories, _ = file.Find("gamemodes/terrortown/content/materials/vgui/ttt/roles/ran/items/*.png", "THIRDPARTY")
    for _, cat in ipairs(categories) do
        resource.AddSingleFile("materials/vgui/ttt/roles/ran/items/" .. cat)
    end

    -- Prevents auto-randomat triggering if there is a Randoman alive
    hook.Add("TTTRandomatShouldAuto", "StopAutoRandomatWithRandoman", function()
        if preventAutoRandomatCvar:GetBool() and player.IsRoleLiving(ROLE_RANDOMAN) then return false end
    end)

    local blockedEvents = {
        ["blackmarket"] = "removes the main feature of the role",
        ["credits"] = "makes their role overpowered",
        ["future"] = "can't consistently work with the dynamic shop events"
    }

    -- Prevents a randomat from ever triggering if there is a Randoman in the round
    hook.Add("TTTRandomatCanEventRun", "HardBanRandomanEvents", function(event)
        if not blockedEvents[event.Id] then return end

        for _, ply in ipairs(player.GetAll()) do
            if ply:IsRandoman() then
                return false, "There is " .. ROLE_STRINGS_EXT[ROLE_RANDOMAN] .. " in the round and this event " .. blockedEvents[event.Id]
            end
        end
    end)

    -- Detecting if the randoman has bought anything
    local boughtAsRandoman = {}

    hook.Add("TTTOrderedEquipment", "RandomanBoughtItem", function(ply, id, is_item, from_randomat)
        if ply:IsRandoman() and not from_randomat then
            boughtAsRandoman[ply] = true
        end
    end)

    hook.Add("TTTPrepareRound", "RandomanBoughtItemReset", function()
        table.Empty(boughtAsRandoman)
    end)

    -- Triggering a random event if the randoman dies and hasn't bought anything, and the convar is enabled
    hook.Add("PostPlayerDeath", "RandomanDeathEventTrigger", function (ply)
        if eventOnUnboughtDeathCvar:GetBool() and not boughtAsRandoman[ply] then
            Randomat:TriggerRandomEvent(ply)
            -- Just in case the randoman somehow respawns, only trigger a randomat on death once
            boughtAsRandoman[ply] = true
        end
    end)
end

if CLIENT then
    hook.Add("TTTTutorialRoleText", "RandomanTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_RANDOMAN then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local teamColor = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            local html = "The " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who is able to buy randomat events, rather than <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span> items. <br><br>The available randomat events <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>change each round</span>, and are shared between everyone who is a " .. ROLE_STRINGS[ROLE_RANDOMAN] .. ".<br><br>Some randomat events <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>cannot be bought</span>, such as ones that are supposed to start secretly."

            if preventAutoRandomatCvar:GetBool() and ConVarExists("ttt_randomat_auto") and GetConVar("ttt_randomat_auto"):GetBool() then
                html = html .. "<br><br>If a " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " spawns at the start of the round, <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>no randomat automatically triggers</span>."
            end

            html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"
            local special_detective_mode = GetGlobalInt("ttt_detective_hide_special_mode", SPECIAL_DETECTIVE_HIDE_NONE)
            if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
                html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]
                if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                    html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
                end
            end
            html = html .. ".</span>"

            return html
        end
    end)
end
