-- Defib v2 (revision 20170303)

-- This code is copyright (c) 2016-2017 all rights reserved - "Vadim" @ jmwparq@gmail.com
-- (Re)sale of this code and/or products containing part of this code is strictly prohibited
-- Exclusive rights to usage of this product in "Trouble in Terrorist Town" are given to:
-- - The Garry's Mod community

AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local math = math
local player = player
local surface = surface
local string = string
local timer = timer

SWEP.HoldType = "pistol"
SWEP.LimitedStock = true

if CLIENT then
    SWEP.PrintName = "Taxidermy Kit"
    SWEP.Slot = 8

    SWEP.ViewModelFOV = 78
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFlip = false
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.Primary.Recoil = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Delay = 1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Recoil = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Delay = 1.25

SWEP.AllowDrop = false

-- settings
local maxdist = 64
local success = 100

local beep = Sound("buttons/button17.wav")
local hum = Sound("items/nvg_on.wav")
local zap = Sound("ambient/energy/zap7.wav")

SWEP.Kind = WEAPON_ROLE

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/v_c4.mdl"
SWEP.WorldModel = "models/weapons/w_c4.mdl"

SWEP.AutoSpawnable = false
SWEP.NoSights = true

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

if SERVER then
    CreateConVar("ttt_taxidermist_device_time", "8")
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("taxidermy_help_pri", "taxidermy_help_sec", true)
        return self.BaseClass.Initialize(self)
    end
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ChargeTime")
    self:NetworkVar("Float", 0, "Begin")
    self:NetworkVar("String", 0, "Message")

    if SERVER then
        self:SetChargeTime(GetConVar("ttt_taxidermist_device_time"):GetInt())
    end
end

function SWEP:OnDrop()
    self:Remove()
end

if SERVER then
    local function validbody(body)
        return CORPSE.GetPlayerNick(body, false) ~= false
    end

    local function bodyply(body)
        local ply = false

        if body.sid64 then
            ply = player.GetBySteamID64(body.sid64)
        elseif body.sid == "BOT" then
            ply = player.GetByUniqueID(body.uqid)
        else
            ply = player.GetBySteamID(body.sid)
        end

        if not IsValid(ply) then return false end

        return ply
    end

    function SWEP:Reset()
        self:SetState(DEFIB_IDLE)
        self:SetBegin(-1)
        self:SetMessage('')
        self.Target = nil
    end

    function SWEP:Error(msg)
        self:SetState(DEFIB_ERROR)
        self:SetBegin(CurTime())
        self:SetMessage(msg)

        self:GetOwner():EmitSound(beep, 60, 50, 1)
        self.Target = nil

        timer.Simple(3 * 0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:DoTaxidermy(body)
        local ply = bodyply(body)

        local corpse = ents.Create("npc_kleiner")
        corpse:SetModel(ply:GetModel())

        local pos = body:GetPos()
        local ang = body:GetAngles()
        corpse:SetPos(pos)
        corpse:SetAngles(ang)
        corpse:SetNWBool("Taxidermied", true)
        corpse:Spawn()

        local phys = corpse:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(25)
        end

        SafeRemoveEntity(body)
    end

    function SWEP:Taxidermy()
        sound.Play(zap, self.Target:GetPos(), 75, math.random(95, 105), 1)

        if math.random(0, 100) > success then
            local phys = self.Target:GetPhysicsObjectNum(self.Bone)

            if IsValid(phys) then
                phys:ApplyForceCenter(Vector(0, 0, 4096))
            end

            self:Error("ATTEMPT FAILED TRY AGAIN")
            return
        end
        if not IsFirstTimePredicted() then return end

        self:DoTaxidermy(self.Target)
        self:Reset()
    end

    function SWEP:Begin(body, bone)
        local ply = bodyply(body)

        if not ply then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage("TAXIDERMYING " .. string.upper(ply:Nick()))

        self:GetOwner():EmitSound(hum, 75, math.random(98, 102), 1)

        self.Target = body
        self.Bone = bone
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + self:GetChargeTime() <= CurTime() then
                self:Taxidermy()
            elseif not self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("TAXIDERMYING ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end

        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace(MASK_SHOT_HULL)
        local pos = owner:GetPos()

        if tr.HitPos:Distance(pos) > maxdist then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local ent = tr.Entity
        if IsValid(ent) then
            if ent:GetClass() == "prop_ragdoll" and validbody(ent) then
                self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                self:Begin(ent, tr.PhysicsBone)
            end
        end
    end

    -- Prevent taxidermied bodies from taking damage
    hook.Add("EntityTakeDamage", "Taxidermist_EntityTakeDamage", function(ent, dmginfo)
        if IsValid(ent) and ent:GetNWBool("Taxidermied", false) then
            return true
        end
    end)
end

if CLIENT then
    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

        local charge = self:GetChargeTime()
        local time = self:GetBegin() + charge

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w, h = 255, 20

        if state == DEFIB_BUSY then
            if time < 0 then return end

            local cc = math.min(1, 1 - ((time - CurTime()) / charge))

            surface.SetDrawColor(0, 255, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w * cc, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        elseif state == DEFIB_ERROR then
            surface.SetDrawColor(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)

            surface.DrawOutlinedRect(x - w / 2, y - h, w, h)

            surface.DrawRect(x - w / 2, y - h, w, h)

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 180)
            surface.SetTextPos((x - w / 2) + 3, y - h - 15)
            surface.DrawText(self:GetMessage())
        end
    end

    function SWEP:PrimaryAttack() return false end
end

function SWEP:DryFire() return false end