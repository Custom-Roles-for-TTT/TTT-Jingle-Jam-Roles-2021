AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
    self:SetModel("models/props/cs_office/cardboard_box01.mdl") -- TODO: Replace placeholder model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- Don't collide with players so presents don't kill people
    self:SetModelScale(1)
    self:PhysWake()
    self.nextUse = CurTime()
end

if SERVER then
    function ENT:Use(activator)
        if CurTime() > self.nextUse then
            if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end
            self.nextUse = CurTime() + 0.5

            local owner = self:GetOwner()
            if activator:CheckSantaGift(owner) then
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
                owner:SetNWBool("SantaHasAmmo", true)
                self:Remove()
            end
        end
    end
end