AddCSLuaFile()

local IsValid = IsValid
local util = util

if CLIENT then
    SWEP.PrintName = "Gloves"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left click to attack"
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
    SWEP.DrawCrosshair = false
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "fist"

SWEP.ViewModel = Model("models/weapons/v_boxer.mdl")
SWEP.WorldModel = Model("models/weapons/w_boxer.mdl")

SWEP.HitDistance = 250

SWEP.Primary.Damage = 65
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.7

SWEP.Secondary.ClipSize = 5
SWEP.Secondary.DefaultClip = 5
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 2

SWEP.Kind = WEAPON_ROLE

SWEP.AllowDrop = false
SWEP.IsSilent = false

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2
local sound_single = Sound("Weapon_Crowbar.Single")

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("box_gloves_help_pri", "box_gloves_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

--[[
Claw Attack
]]

function SWEP:PlayPunchAnimation()
    local anim = "fists_right"
    local vm = self:GetOwner():GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
    self:GetOwner():ViewPunch(Angle( 4, 4, 0 ))
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:PlayPunchAnimation()

    if owner.LagCompensation then -- for some reason not always true
        owner:LagCompensation(true)
    end

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    local tr_main = util.TraceHull({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    local hitEnt = tr_main.Entity

    self:EmitSound(sound_single)

    if IsValid(hitEnt) or tr_main.HitWorld then
        self:PlayPunchAnimation()
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        if not (CLIENT and (not IsFirstTimePredicted())) then
            local edata = EffectData()
            edata:SetStart(spos)
            edata:SetOrigin(tr_main.HitPos)
            edata:SetNormal(tr_main.Normal)
            edata:SetSurfaceProp(tr_main.SurfaceProps)
            edata:SetHitBox(tr_main.HitBox)
            edata:SetEntity(hitEnt)

            if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
                util.Effect("BloodImpact", edata)
                owner:LagCompensation(false)
                owner:FireBullets({ Num = 1, Src = spos, Dir = owner:GetAimVector(), Spread = Vector(0, 0, 0), Tracer = 0, Force = 1, Damage = 0 })
            else
                util.Effect("Impact", edata)
            end
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
    end

    if not CLIENT then
        owner:SetAnimation(PLAYER_ATTACK1)
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

--[[
Secondary Attack
]]

function SWEP:SecondaryAttack()

end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    local vm = self:GetOwner():GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
end

function SWEP:Holster(weapon)
    return true
end