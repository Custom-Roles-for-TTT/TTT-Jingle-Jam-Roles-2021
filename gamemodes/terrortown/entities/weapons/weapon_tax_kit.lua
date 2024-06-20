AddCSLuaFile()

local hook = hook
local string = string

if CLIENT then
    SWEP.PrintName = "Taxidermy Kit"
    SWEP.Slot = 8
    SWEP.ViewModelFOV = 78

    SWEP.EquipMenuData = {
        type = "item_weapon",
        desc = "Revives an innocent as a traitor."
    }

    SWEP.Icon = "vgui/ttt/icon_brainwash"
end

SWEP.Base = "weapon_cr_defibbase"
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.InLoadoutFor = {ROLE_TAXIDERMIST}
SWEP.InLoadoutForDefault = {ROLE_TAXIDERMIST}
SWEP.Kind = WEAPON_ROLE

SWEP.BlockShopRandomization = true

if SERVER then
    SWEP.DeviceTimeConVar = CreateConVar("ttt_taxidermist_device_time", "5", FCVAR_NONE, "The amount of time (in seconds) the taxidermist's device takes to use", 0, 60)
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("taxidermy_help_pri", "taxidermy_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

if SERVER then
    function SWEP:OnSuccess(ply, body)
        local corpse = ents.Create("npc_kleiner")
        corpse:SetModel(ply:GetModel())

        local pos = body:GetPos()
        local ang = body:GetAngles()
        corpse:SetPos(pos)
        corpse:SetAngles(ang)
        corpse:SetNWBool("Taxidermied", true)
        corpse:AddFlags(FL_NOTARGET)
        corpse:Spawn()

        local phys = corpse:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(25)
        end

        SafeRemoveEntity(body)
    end

    function SWEP:GetProgressMessage(ply, body, bone)
        return "TAXIDERMYING " .. string.upper(ply:Nick())
    end

    function SWEP:GetAbortMessage()
        return "TAXIDERMYING ABORTED"
    end

    -- Prevent taxidermied bodies from taking damage
    hook.Add("EntityTakeDamage", "Taxidermist_EntityTakeDamage", function(ent, dmginfo)
        if IsValid(ent) and ent:GetNWBool("Taxidermied", false) then
            return true
        end
    end)
end