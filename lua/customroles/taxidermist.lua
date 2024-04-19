local ROLE = {}

ROLE.nameraw = "taxidermist"
ROLE.name = "Taxidermist"
ROLE.nameplural = "Taxidermists"
ROLE.nameext = "a Taxidermist"
ROLE.nameshort = "tax"

ROLE.desc = [[You are {role}! {comrades}

You can use your taxidermy kit on a corpse to make them impossible to identify.

Press {menukey} to receive your special equipment!]]
ROLE.shortdesc = "Has a Taxidermy Kit which can be sed to make player corpses impossible to identify."

ROLE.team = ROLE_TEAM_TRAITOR
ROLE.loadout = {"weapon_tax_kit"}

ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_taxidermist_device_time",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

ROLE.translations = {
    ["english"] = {
        ["taxidermy_help_pri"] = "Use {primaryfire} to taxidermy a corpse",
        ["taxidermy_help_sec"] = "Taxidermied corpses cannot be inspected"
    }
}

RegisterRole(ROLE)

if CLIENT then
    hook.Add("TTTTutorialRoleText", "Taxidermist_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_TAXIDERMIST then
            local roleColor = ROLE_COLORS[ROLE_TRAITOR]
            return "The " .. ROLE_STRINGS[ROLE_TAXIDERMIST] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> whose goal is to use their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>taxidermy kit</span> on a corpse to make it impossible to identify."
        end
    end)
end