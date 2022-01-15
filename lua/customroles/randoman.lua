local ROLE = {}
ROLE.nameraw = "randoman"
ROLE.name = "Randoman"
ROLE.nameplural = "Randomen"
ROLE.nameext = "a Randoman"
ROLE.nameshort = "ran"
ROLE.desc = [[You are {role}!
You're {adetective}, but you can buy randomats instead of {detective} items!]]
ROLE.team = ROLE_TEAM_DETECTIVE
ROLE.shop = {}
ROLE.loadout = {}
ROLE.startingcredits = 1
ROLE.selectionpredicate = function() return file.Exists("gamemodes/terrortown/entities/weapons/weapon_ttt_randomat/shared.lua", "GAME") end

-- These randomats are banned from showing up in the randoman's shop for various reasons:
-- The credits, blind, etc. events are too advantageous to the innocents and are banned to prevent them from being picked all the time
-- lame is pointless to have in the shop as it itself does nothing
-- The choose, randomxn, etc. events trigger other events, potentially a banned one, so they themselves are banned
CreateConVar("ttt_randoman_banned_randomats", "credits,blind,speedrun,blerg,deadchat,lame,choose,randomxn,intensifies,delay,oncemore", {FCVAR_NOTIFY}, "The randomats that are not allowed to appear in the randoman's shop. Separate randomat ids with commas. You can find a randomat's ID by turning one off/on in the randomat ULX menu and coping the word between 'ttt_' and '_enabled' that appears in chat.")

CreateConVar("ttt_randoman_prevent_auto_randomat", 1, {FCVAR_NOTIFY}, "Prevent auto-randomat triggering if there is a randoman at the start of the round", 0, 1)

ROLE.convars = {
    {
        cvar = "ttt_randoman_banned_randomats",
        type = ROLE_CONVAR_TYPE_TEXT
    },
    {
        cvar = "ttt_randoman_prevent_auto_randomat",
        type = ROLE_CONVAR_TYPE_TEXT
    }
}

ROLE.translations = {}
ROLE.shoulddelayshop = false
ROLE.moverolestate = nil
RegisterRole(ROLE)

hook.Add("TTTRandomatShouldAuto", "StopAutoRandomatWithRandoman", function()
    if GetConVar("ttt_randoman_prevent_auto_randomat"):GetBool() and player.IsRoleLiving(ROLE_RANDOMAN) then return false end
end)

if CLIENT then
    hook.Add("TTTTutorialRoleText", "RandomanTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_RANDOMAN then
            local roleColor = ROLE_COLORS[ROLE_DETECTIVE]
            local teamName = ROLE_STRINGS[ROLE_DETECTIVE]
            local teamColor = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            local tutorialText = "<p>The " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. teamName .. "</span> who is able to buy randomat events, rather than <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. teamName .. "</span> items. <br><br>The available randomat events <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>change each round</span>, and are shared between everyone who is a " .. ROLE_STRINGS[ROLE_RANDOMAN] .. ".<br><br>Some randomat events <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>cannot be bought</span>, such as ones that are supposed to start secretly."

            if GetConVar("ttt_randoman_prevent_auto_randomat"):GetBool() and ConVarExists("ttt_randomat_auto") and GetConVar("ttt_randomat_auto"):GetBool() then
                tutorialText = tutorialText .. "<br><br>If a " .. ROLE_STRINGS[ROLE_RANDOMAN] .. " spawns at the start of the round, <span style='color: rgb(" .. teamColor.r .. ", " .. teamColor.g .. ", " .. teamColor.b .. ")'>no randomat automatically triggers</span>."
            end

            return tutorialText .. "</p>"
        end
    end)
end