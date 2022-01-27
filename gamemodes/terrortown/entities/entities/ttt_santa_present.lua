AddCSLuaFile()
ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel("models/items/boxbuckshot.mdl") -- TODO: Replace placeholder model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- Don't collide with players so presents don't kill people
    self:SetModelScale(1)
    if SERVER then
        self:PrecacheGibs()
    end
    self:PhysWake()
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end

    local owner = self:GetOwner()
    if activator:TrackSantaGifts(owner) then
        if not GetGlobalBool("ttt_santa_random_presents", false) then
            owner:SetNWString("SantaLoadedItem", "")
            owner:SetCredits(1)
        end

        local item_id = self.item_id

        local equip_id = tonumber(item_id)
        if equip_id then
            activator:GiveEquipmentItem(equip_id)
        else
            activator:Give(item_id)
        end

        owner:PrintMessage(HUD_PRINTTALK, activator:Nick() .. " has opened your present and your ammo has been refunded.")
        owner:GetNWBool("SantaHasAmmo", true)
        self:Remove()
    else
        owner:PrintMessage(HUD_PRINTTALK, "You have already received a gift from " .. owner:Nick() .. "!")
        owner:PrintMessage(HUD_PRINTCENTER, "You have already received a gift from " .. owner:Nick() .. "!")
    end
end