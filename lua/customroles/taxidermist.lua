local ROLE = {}

ROLE.nameraw = "taxidermist"
ROLE.name = "Taxidermist"
ROLE.nameplural = "Taxidermists"
ROLE.nameext = "a Taxidermist"
ROLE.nameshort = "tax"

-- TODO
ROLE.desc = [[You are {role}!]]

ROLE.team = ROLE_TEAM_TRAITOR
-- TODO
ROLE.loadout = {}

ROLE.convars = {}

-- TODO
ROLE.translations = {
    ["english"] = {
        ["_help_pri"] = "Use {primaryfire} to ",
        ["_help_sec"] = "{secondaryfire}"
    }
}

RegisterRole(ROLE)