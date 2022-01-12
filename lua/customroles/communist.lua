local ROLE = {}

ROLE.nameraw = "communist"
ROLE.name = "Communist"
ROLE.nameplural = "Communists"
ROLE.nameext = "a Communist"
ROLE.nameshort = "com"

ROLE.desc = [[You are {role}!]]

ROLE.team = ROLE_TEAM_INDEPENDENT
ROLE.loadout = {"weapon_com_manifesto"}

ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_communist_convert_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE.convars, {
    cvar = "ttt_communist_convert_credits",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE.convars, {
    cvar = "ttt_communist_convert_freeze",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE.convars, {
    cvar = "ttt_communist_convert_unfreeze_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})

ROLE.translations = {
    ["english"] = {
        ["manifesto_help_pri"] = "Use {primaryfire} to convert a player to Communism",
        ["manifesto_help_sec"] = "All {nameplural} win together",
        ["ev_communismconvert"] = "{victim} has been converted and turned to Communism!",
        ["ev_win_communist"] = "The {role} have converted all remaining players",
        ["win_communist"] = "Communism has spread to all survivers",
        ["hilite_win_communist"] = "COMMUNISM WINS",
        ["hilite_lose_communist"] = "AND CAPITALISM WINS"
    }
}

RegisterRole(ROLE)

if CLIENT then
    local function RegisterEvent()
        local convert_icon = Material("icon16/user_go.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_COMMUNISTCONVERTED, {
            text = function(e)
                return PT("ev_communismconvert", {victim = e.vic})
            end,
            icon = function(e)
                return convert_icon, "Converted"
            end})
    end

    if not CRVersion("1.4.6") then
        hook.Add("Initialize", "Communist_Initialize", function()
            WIN_COMMUNIST = GenerateNewWinID(ROLE_COMMUNIST)
            EVENT_COMMUNISTCONVERTED = GenerateNewEventID(ROLE_COMMUNIST)
            RegisterEvent()
        end)
    else
        hook.Add("TTTSyncWinIDs", "Communist_TTTSyncWinIDs", function()
            WIN_COMMUNIST = WINS_BY_ROLE[ROLE_COMMUNIST]
        end)

        hook.Add("TTTSyncEventIDs", "Communist_TTTSyncEventIDs", function()
            EVENT_COMMUNISTCONVERTED = EVENTS_BY_ROLE[ROLE_COMMUNIST]
            RegisterEvent()
        end)
    end

    hook.Add("TTTTutorialRoleText", "Communist_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_COMMUNIST then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
            local html = "The " .. ROLE_STRINGS[ROLE_COMMUNIST] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to convert all living players <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>to communism</span> using the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>Communist Manifesto</span>."

            local freeze = GetGlobalBool("ttt_communist_convert_freeze", true) and "" or " NOT"
            html = html .. "<span style='display: block; margin-top: 10px;'>Players <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>will" .. freeze .. " be frozen</span> while being converted.</span>"

            local credits = GetGlobalInt("ttt_communist_convert_credits", 1)
            if credits > 0 then
                local plural = ""
                if credits > 1 then
                    plural = "s"
                end
                html = html .. "<span style='display: block; margin-top: 10px;'>When a player is converted to communism, all non-" .. ROLE_STRINGS_PLURAL[ROLE_COMMUNIST] .. " will be <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>given " .. credits .. " credit" .. plural .. "</span>.</span>"
            end

            return html
        end
    end)

    net.Receive("TTT_Communism_Converted", function(len)
        local name = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_COMMUNISTCONVERTED,
            vic = name
        })
    end)

    hook.Add("TTTEventFinishText", "Communist_EventFinishText", function(e)
        if e.win == WIN_COMMUNIST then
            return LANG.GetParamTranslation("ev_win_communist", { role = ROLE_STRINGS_PLURAL[ROLE_COMMUNIST] })
        end
    end)

    hook.Add("TTTEventFinishIconText", "Communist_EventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_COMMUNIST then
            return win_string, ROLE_STRINGS[ROLE_COMMUNIST]
        end
    end)

    hook.Add("TTTScoringWinTitle", "Communist_ScoringWinTitle", function(wintype, wintitles, title, secondaryWinRole)
        if wintype == WIN_COMMUNIST then
            return { txt = "hilite_win_communist", params = { role = ROLE_STRINGS[ROLE_COMMUNIST]:upper() }, c = ROLE_COLORS[ROLE_COMMUNIST] }
        end
    end)

    -- Show the player's starting role icon if they were converted to Communist and group them with their original team
    hook.Add("TTTScoringSummaryRender", "Communist_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if finalRole == ROLE_COMMUNIST then
            return ROLE_STRINGS_SHORT[startingRole], startingRole
        end
    end)

    -- Add the communist to the secondary "wins" list when they lose and show a different message
    hook.Add("TTTScoringSecondaryWins", "Communist_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        if wintype == WIN_COMMUNIST then return end

        -- Only show this message if there was a Communist in the round
        for _, p in ipairs(player.GetAll()) do
            if p:IsCommunist() then
                table.insert(secondary_wins, {
                    rol = ROLE_COMMUNIST,
                    txt = LANG.GetTranslation("hilite_lose_communist"),
                    col = ROLE_COLORS[ROLE_DETECTIVE]
                })
                return
            end
        end
    end)
end

if SERVER then
    AddCSLuaFile()

    hook.Add("TTTSyncGlobals", "Communist_TTTSyncGlobals", function()
        SetGlobalBool("ttt_communist_convert_freeze", GetConVar("ttt_communist_convert_freeze"):GetBool())
        SetGlobalInt("ttt_communist_convert_credits", GetConVar("ttt_communist_convert_credits"):GetInt())
    end)

    hook.Add("Initialize", "Communist_Initialize", function()
        WIN_COMMUNIST = GenerateNewWinID(ROLE_COMMUNIST)
        EVENT_COMMUNISTCONVERTED = GenerateNewEventID(ROLE_COMMUNIST)
    end)

    hook.Add("TTTCheckForWin", "Communist_CheckForWin", function()
        local communist_alive = false
        local other_alive = false
        for _, v in ipairs(player.GetAll()) do
            if v:Alive() and v:IsTerror() then
                if v:IsCommunist() then
                    communist_alive = true
                elseif not v:ShouldActLikeJester() then
                    other_alive = true
                end
            end
        end

        if communist_alive and not other_alive then
            return WIN_COMMUNIST
        elseif communist_alive then
            return WIN_NONE
        end
    end)

    hook.Add("TTTPrintResultMessage", "Communist_PrintResultMessage", function(type)
        if type == WIN_COMMUNIST then
            LANG.Msg("win_communist", { role = ROLE_STRINGS[ROLE_COMMUNIST] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_COMMUNIST] .. " wins.\n")
            return true
        end
    end)

    hook.Add("TTTPrepareRound", "Communist_RoleFeatures_PrepareRound", function()
        for _, v in pairs(player.GetAll()) do
            v:SetNWInt("CommunistFreezeCount", 0)
        end
    end)
end