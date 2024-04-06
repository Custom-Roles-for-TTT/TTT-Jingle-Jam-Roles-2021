local player = player

local PlayerIterator = player.Iterator

local preventAutoRandomatCvar = CreateConVar("ttt_randoman_prevent_auto_randomat", 1, FCVAR_REPLICATED, "Prevent auto-randomat triggering if there is a randoman at the start of the round", 0, 1)
local independentCvar = CreateConVar("ttt_randoman_is_independent", "0", FCVAR_REPLICATED, "Whether the randoman is an independent role (Requires map change)", 0, 1)

local ROLE = {}
ROLE.nameraw = "randoman"
ROLE.name = "Randoman"
ROLE.nameplural = "Randomen"
ROLE.nameext = "a Randoman"
ROLE.nameshort = "ran"

if independentCvar:GetBool() then
    ROLE.desc = [[You are {role}!
    Buy randomats to help you kill everyone else to win!]]
    ROLE.team = ROLE_TEAM_INDEPENDENT

    ROLE.translations = {
        ["english"] = {
            ["win_randoman"] = "The {role}'s chaos has taken over!",
            ["hilite_win_randoman"] = "THE {role} WINS"
        }
    }

    ROLE.canseejesters = true
else
    ROLE.desc = [[You are {role}!
    You're {adetective}, but you can buy randomats instead of {detective} items!]]
    ROLE.team = ROLE_TEAM_DETECTIVE
end

ROLE.shop = {"weapon_ttt_randomat"}

ROLE.loadout = {}
ROLE.startingcredits = 1
ROLE.selectionpredicate = function() return Randomat and type(Randomat.IsInnocentTeam) == "function" end

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
    },
    {
        cvar = "ttt_randoman_choose_event_on_drop",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoman_guarantee_pockets_event",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoman_choose_event_on_drop_count",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_randoman_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

RegisterRole(ROLE)

if SERVER then
    -- Lame is pointless to have in the shop as it itself does nothing
    CreateConVar("ttt_randoman_banned_randomats", "lame", FCVAR_NONE, "Events not allowed in the randoman's shop, separate ids with commas. You can find an ID by turning a randomat on/off in the randomat ULX menu and copying the word after 'ttt_randomat_', which appears in chat.")
    CreateConVar("ttt_randoman_guaranteed_categories", "biased_innocent,fun,moderateimpact", FCVAR_NONE, "At least one randomat from each of these categories will always be in the randoman's shop. You can find a randomat's category by looking at an event in the randomat ULX menu.")
    CreateConVar("ttt_randoman_guaranteed_randomats", "", FCVAR_NONE, "Events that will always appear in the randoma's shop, separate ids with commas.")
    local eventOnUnboughtDeathCvar = CreateConVar("ttt_randoman_event_on_unbought_death", 0, FCVAR_NONE, "Whether a randomat should trigger if a randoman dies and never bought anything that round", 0, 1)
    local chooseEventOnDropCvar = CreateConVar("ttt_randoman_choose_event_on_drop", 1, FCVAR_NONE, "Whether the held randomat item should always trigger \"Choose an event!\" after being bought by a randoman and dropped on the ground", 0, 1)
    local chooseEventOnDropCountCvar = CreateConVar("ttt_randoman_choose_event_on_drop_count", 5, FCVAR_NONE, "The number of events a player should be able to choose from when using a dropped randomat", 1, 10)
    CreateConVar("ttt_randoman_guarantee_pockets_event", 1, FCVAR_NONE, "Whether the \"What did I find in my pocket?\" event should always be available in the randoman's shop while the beggar role is enabled", 0, 1)

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

        for _, ply in PlayerIterator() do
            if ply:IsRandoman() then return false, "There is " .. ROLE_STRINGS_EXT[ROLE_RANDOMAN] .. " in the round and this event " .. blockedEvents[event.Id] end
        end
    end)

    local boughtAsRandoman = {}

    hook.Add("TTTOrderedEquipment", "RandomanBoughtItem", function(ply, id, is_item, from_randomat)
        if ply:IsRandoman() then
            -- Let the randoman be able to drop the randomat SWEP
            if id == "weapon_ttt_randomat" then
                local SWEP = ply:GetWeapon("weapon_ttt_randomat")

                if IsValid(SWEP) then
                    SWEP.AllowDrop = true

                    -- If the convar is enabled and the randoman drops this item, it is guaranteed to trigger "Choose an event!" on being picked up and used,
                    -- which gives the player a choice of 5 randomats to trigger.
                    -- This is so the randoman is able to give other players an interesting item, most notably for players that are the beggar role
                    if chooseEventOnDropCvar:GetBool() then
                        function SWEP:OnDrop()
                            self.EventId = "choose"
                            -- Vote, DeadCanVote, VotePredicate, ChoiceCount
                            self.EventArgs = {false, false, nil, chooseEventOnDropCountCvar:GetInt()}
                            self.EventSilent = true
                        end
                    end
                end
            end

            -- Detecting if the randoman has bought anything
            if not from_randomat then
                boughtAsRandoman[ply] = true
            end
        end
    end)

    hook.Add("TTTPrepareRound", "RandomanReset", function()
        table.Empty(boughtAsRandoman)
    end)

    -- Triggering a random event if the randoman dies and hasn't bought anything, and the convar is enabled
    hook.Add("PostPlayerDeath", "RandomanDeathEventTrigger", function(ply)
        if ply:IsRandoman() and GetRoundState() == ROUND_ACTIVE and eventOnUnboughtDeathCvar:GetBool() and not boughtAsRandoman[ply] then
            Randomat:TriggerRandomEvent(ply)
            -- Just in case the randoman somehow respawns, only trigger a randomat on death once
            boughtAsRandoman[ply] = true
        end
    end)

    hook.Add("Initialize", "RandomanIndependentGenerateWinID", function()
        WIN_RANDOMAN = GenerateNewWinID(ROLE_RANDOMAN)
    end)
    
    hook.Add("TTTCheckForWin", "RandomanIndependentWin", function()
        if not independentCvar:GetBool() then return end

        local randomanAlive = false
        local otherAlive = false

        for _, ply in PlayerIterator() do
            if ply:Alive() and ply:IsTerror() then
                if ply:IsRandoman() then
                    randomanAlive = true
                elseif not ply:ShouldActLikeJester() then
                    otherAlive = true
                end
            end
        end

        if randomanAlive and not otherAlive then
            return WIN_RANDOMAN
        elseif randomanAlive then
            return WIN_NONE
        end
    end)

    hook.Add("TTTPrintResultMessage", "RandomanIndependentWinMessage", function(type)
        if type == WIN_RANDOMAN then
            LANG.Msg("win_randoman", { role = ROLE_STRINGS[ROLE_RANDOMAN] })
            ServerLog("Result: The " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " wins.\n")
            return true
        end
    end)
end

if CLIENT then
    hook.Add("TTTSyncWinIDs", "RandomanSyncWinIDs", function()
        WIN_RANDOMAN = WINS_BY_ROLE[ROLE_RANDOMAN]
    end)

    hook.Add("TTTScoringWinTitle", "RandomanWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_RANDOMAN then
            return { txt = "hilite_win_randoman", params = { role = ROLE_STRINGS[ROLE_RANDOMAN]:upper() }, c = ROLE_COLORS[ROLE_RANDOMAN] }
        end
    end)

    hook.Add("TTTTutorialRoleText", "RandomanTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_RANDOMAN then
            local roleColor
            local teamColor

            if independentCvar:GetBool() then
                roleColor = ROLE_COLORS[ROLE_RANDOMAN]
                teamColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            else
                roleColor = ROLE_COLORS[ROLE_DETECTIVE]
                teamColor = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            end

            local html

            if independentCvar:GetBool() then
                html = "The " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent role</span> who is able to buy randomat events, rather than items."
            else
                html = "The " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>innocent team</span> who is able to buy randomat events, rather than <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span> items."
            end

            html = html .. "<br><br>The available randomat events <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>change each round</span>, and are shared between everyone who is a " .. ROLE_STRINGS[ROLE_RANDOMAN] .. ".<br><br>Some randomat events <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>cannot be bought</span>, such as ones that are supposed to start secretly."

            if GetConVar("ttt_randoman_prevent_auto_randomat"):GetBool() and GetConVar("ttt_randomat_auto"):GetBool() then
                html = html .. "<br><br>If a " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " spawns at the start of the round, <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>no randomat automatically triggers</span>."
            end
            
            if not independentCvar:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"

                local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
                if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
                    html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]

                    if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                        html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
                    end
                end

                html = html .. ".</span>"
            end

            return html
        end
    end)
end

hook.Add("TTTUpdateRoleState", "RandomanUpdateRoleState", function()
    local is_independent = independentCvar:GetBool()
    INDEPENDENT_ROLES[ROLE_RANDOMAN] = is_independent
    DETECTIVE_ROLES[ROLE_RANDOMAN] = not is_independent
end)