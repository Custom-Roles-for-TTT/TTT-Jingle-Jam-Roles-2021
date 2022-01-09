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
    cvar = "ttt_communist_device_time",
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
        ["manifesto_help_sec"] = "All {nameplural} win together"
        -- TODO: Round win events
    }
}

RegisterRole(ROLE)

if CLIENT then
    -- TODO
    hook.Add("TTTTutorialRoleText", "Communist_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_COMMUNIST then
            local roleColor = ROLE_COLORS[ROLE_TRAITOR]
            return ""
        end
    end)

    -- TODO: Round win events
    -- TODO: Round lose message
end

if SERVER then
    -- TODO: Round win logic

    hook.Add("TTTPrepareRound", "Communist_RoleFeatures_PrepareRound", function()
        for _, v in pairs(player.GetAll()) do
            v:SetNWInt("CommunistFreezeCount", 0)
        end
    end)
end