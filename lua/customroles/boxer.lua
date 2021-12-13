local ROLE = {}

ROLE.nameraw = "boxer"
ROLE.name = "Boxer"
ROLE.nameplural = "Boxers"
ROLE.nameext = "a Boxer"
ROLE.nameshort = "box"

ROLE.desc = [[You are {role}!]]

ROLE.team = ROLE_TEAM_JESTER

ROLE.loadout = {"weapon_box_gloves"}

ROLE.startinghealth = 125
ROLE.maxhealth = 125

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end