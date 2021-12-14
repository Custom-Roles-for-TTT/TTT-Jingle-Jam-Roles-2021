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
    SWEP.ViewModelFOV = 41
    SWEP.ViewModelFlip = false
    SWEP.DrawCrosshair = false
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "fist"

SWEP.ViewModel = Model("models/weapons/v_boxer.mdl")
SWEP.WorldModel = Model("models/weapons/w_boxer.mdl")

-- Animation timings, expressed as #frames/fps
local animationLengths = {
    [ACT_VM_DRAW] = 30/30,
    [ACT_VM_PRIMARYATTACK] = 20/30,
    [ACT_VM_SECONDARYATTACK] = 20/30,
    [ACT_VM_PULLBACK] = 90/30,
    [ACT_VM_HITCENTER] = 217/30,
    [ACT_VM_IDLE] = 16/30
}

SWEP.HitDistance = 250

SWEP.Primary.Damage         = 15
SWEP.Primary.ClipSize       = 1
SWEP.Primary.DefaultClip    = 1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = animationLengths[ACT_VM_PRIMARYATTACK]

SWEP.Secondary.Damage       = 0
SWEP.Secondary.ClipSize     = 1
SWEP.Secondary.DefaultClip  = 1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = animationLengths[ACT_VM_HITCENTER]

SWEP.Kind = WEAPON_ROLE

SWEP.AllowDrop = false
SWEP.IsSilent = false

-- Pull out faster than standard guns
SWEP.DeploySpeed = 2
local sound_single = Sound("Weapon_Crowbar.Single")
local sound_scream = Sound("scream.mp3")

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("box_gloves_help_pri", "box_gloves_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:GoIdle(anim)
    timer.Create("BoxerGlovesIdle_" .. self:EntIndex(), animationLengths[anim], 1, function()
        self:SendWeaponAnim(ACT_VM_IDLE)
    end)
end

--[[
Punch Attack
]]

function SWEP:PlayPunchAnimation(anim)
    self:SendWeaponAnim(anim)
    self:GetOwner():ViewPunch(Angle( 4, 4, 0 ))
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    self:GoIdle(anim)
end

function SWEP:PrimaryAttack()
    local anim
    if math.random(0, 1) == 1 then
        anim = ACT_VM_PRIMARYATTACK
    else
        anim = ACT_VM_SECONDARYATTACK
    end

    local delay = animationLengths[anim]
    self:SetNextSecondaryFire(CurTime() + delay)
    self:SetNextPrimaryFire(CurTime() + delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:PlayPunchAnimation(anim)

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
    end

    if not CLIENT then
        owner:SetAnimation(PLAYER_ATTACK1)

        if IsPlayer(hitEnt) then
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            dmg:SetDamageForce(owner:GetAimVector() * 5)
            dmg:SetDamagePosition(owner:GetPos())
            dmg:SetDamageType(DMG_SLASH)

            hitEnt:DispatchTraceAttack(dmg, spos + (owner:GetAimVector() * 3), sdest)
        end
    end

    if owner.LagCompensation then
        owner:LagCompensation(false)
    end
end

--[[
Flurry of punches Attack
]]

function SWEP:SecondaryAttack()
    local prepAnim = ACT_VM_PULLBACK
    local punchAnim = ACT_VM_HITCENTER
    local delay = animationLengths[punchAnim] + animationLengths[prepAnim]
    self:SetNextSecondaryFire(CurTime() + delay)
    self:SetNextPrimaryFire(CurTime() + delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Pullback animation which delays the normal punch and logic
    self:SendWeaponAnim(prepAnim)
    timer.Create("BoxerGlovesWindUp_" .. self:EntIndex(), animationLengths[prepAnim], 1, function()
        self:EmitSound(sound_scream)
        self:PlayPunchAnimation(punchAnim)

        -- TODO: World animation by doing multiple for the correct duration

        if owner.LagCompensation then -- for some reason not always true
            owner:LagCompensation(true)
        end

        -- TODO: Logic

        if owner.LagCompensation then
            owner:LagCompensation(false)
        end
    end)
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    timer.Remove("BoxerGlovesIdle_" .. self:EntIndex())
    timer.Remove("BoxerGlovesWindUp_" .. self:EntIndex())
end

function SWEP:Deploy()
    local anim = ACT_VM_DRAW
    -- Don't let the user use the dagger until the animation finishes
    self:SetNextPrimaryFire(CurTime() + animationLengths[anim])
    self:SendWeaponAnim(anim)
    self:GoIdle(anim)
end

function SWEP:Holster(weapon)
    return true
end