AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
    self:SetModel("models/katharsmodels/present/type-2/big/present2.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:Activate()
    self.nextUse = CurTime()

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(10)
    end
end

if SERVER then
    util.AddNetworkString("TTT_SantaPresentNotify")

    local function CallShopHooks(isequip, id, ply)
        hook.Call("TTTOrderedEquipment", GAMEMODE, ply, id, isequip)
        ply:AddBought(id)

        net.Start("TTT_BoughtItem")
        net.WriteBit(isequip)
        if isequip then
            local bits = 16
            -- Only use 32 bits if the number of equipment items we have requires it
            if EQUIP_MAX >= 2^bits then
                bits = 32
            end

            net.WriteInt(id, bits)
        else
            net.WriteString(id)
        end
        net.Send(ply)
    end

    local function NotifyPlayer(ply, item, has, can_carry)
        net.Start("TTT_SantaPresentNotify")
        net.WriteString(tostring(item))
        net.WriteBool(has)
        net.WriteBool(can_carry)
        net.Send(ply)
    end

    function ENT:Use(activator)
        if CurTime() > self.nextUse then
            if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end
            self.nextUse = CurTime() + 0.5

            local owner = self:GetOwner()
            if activator:CheckSantaGift(owner) then
                local item_id = self.item_id

                local equip_id = tonumber(item_id)
                if equip_id then
                    local has = activator:HasEquipmentItem(equip_id)
                    NotifyPlayer(activator, equip_id, has, true)
                    if has then
                        activator:UndoSantaGift(owner)
                        return
                    else
                        activator:GiveEquipmentItem(equip_id)
                        CallShopHooks(equip_id, item_id, activator)
                    end
                else
                    local has = activator:HasWeapon(item_id)
                    local can_carry = activator:CanCarryWeapon(weapons.GetStored(item_id))
                    print(activator:Nick() .. " can carry " .. item_id .. "? " .. tostring(can_carry))
                    NotifyPlayer(activator, item_id, has, can_carry)
                    if has or not can_carry then
                        activator:UndoSantaGift(owner)
                        return
                    else
                        activator:Give(item_id)
                        CallShopHooks(equip_id, item_id, activator)
                    end
                end

                if not GetGlobalBool("ttt_santa_random_presents", false) then
                    owner:SetNWString("SantaLoadedItem", "")
                    owner:SetCredits(1)
                end

                owner:PrintMessage(HUD_PRINTTALK, activator:Nick() .. " has opened your present and your ammo has been refunded.")
                owner:SetNWBool("SantaHasAmmo", true)
                self:Remove()
            end
        end
    end
end

if CLIENT then
    local function GetItemName(item)
        local id = tonumber(item)
        local info = GetEquipmentItem(ROLE_SANTA, id)
        return info and LANG.TryTranslation(info.name) or item
    end

    local function GetWeaponName(item)
        for _, v in ipairs(weapons.GetList()) do
            if item == WEPS.GetClass(v) then
                return LANG.TryTranslation(v.PrintName)
            end
        end

        return item
    end

    net.Receive("TTT_SantaPresentNotify", function()
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local item = net.ReadString()
        local has = net.ReadBool()
        local can_carry = net.ReadBool()
        local name
        if tonumber(item) then
            name = GetItemName(item)
        else
            name = GetWeaponName(item)
        end

        if has then
            client:PrintMessage(HUD_PRINTTALK, "You already have '" .. name .. "'!")
        elseif not can_carry then
            client:PrintMessage(HUD_PRINTTALK, "You are already holding an item that shares a slot with '" .. name .. "'!")
        else
            client:PrintMessage(HUD_PRINTTALK, "You got '" .. name .. "' from " .. ROLE_STRINGS[ROLE_SANTA] .. "!")
        end
    end)
end