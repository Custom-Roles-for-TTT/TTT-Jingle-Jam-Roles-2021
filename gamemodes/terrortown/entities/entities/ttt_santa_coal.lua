AddCSLuaFile()
ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel("models/items/boxsrounds.mdl") -- TODO: Replace placeholder model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)  -- Needs to collide with players so it can kill people
    self:SetModelScale(1)
    if SERVER then
        self:PrecacheGibs()
    end
    self:PhysWake()
end

function ENT:Think()
    self.lifetime = self.lifetime or CurTime() + 30
    if CurTime() > self.lifetime then
        self:Remove()
    end
end

function ENT:PhysicsCollide(data, phys)
    local ent = data.HitEntity
    local owner = self:GetOwner()

    if not IsValid(ent) or not ent:IsPlayer() or not ent:IsActive() then return end
    if data.Speed < 300 then return end -- The coal has to be going fast enough to kill someone

    ent:TakeDamage(ent:Health(), owner, self)
    self.lifetime = CurTime + 3 -- Leave the coal around for a few more seconds then remove it
    if ent:IsTraitorTeam() or (ent:IsJesterTeam() and GetGlobalBool("ttt_santa_jesters_are_naughty", false)) or (ent:IsIndependentTeam() and GetGlobalBool("ttt_santa_independents_are_naughty", true)) then
        if not GetGlobalBool("ttt_santa_random_presents", false) then
            owner:SetCredits(1)
        end
        owner:GetNWBool("SantaHasAmmo", true)
        owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " was naughty and your ammo has been refunded.")
    else
        owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " was nice and you can no longer use the christmas cannon.")
    end
end