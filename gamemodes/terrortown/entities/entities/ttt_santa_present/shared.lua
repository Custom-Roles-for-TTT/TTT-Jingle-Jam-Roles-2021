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

    local santa_set_gift_owner = CreateConVar("ttt_santa_set_gift_owner", "0", FCVAR_NONE, "Whether gifts given by santa should be owned by them for the purposes of roles that react to the original weapon buyer (e.g the beggar)", 0, 1)

    local function CallShopHooks(isequip, id, ply, santa)
        hook.Call("TTTOrderedEquipment", GAMEMODE, ply, id, isequip, true)
        ply:AddBought(id)

        net.Start("TTT_BoughtItem")
        -- Not a boolean so we can't write it directly
        if isequip then
            net.WriteBit(true)
        else
            net.WriteBit(false)
        end
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

        -- Fudge the equip to trigger "on equip" effect
        if santa_set_gift_owner:GetBool() then
            hook.Call("WeaponEquip", GAMEMODE, {
                CanBuy = true,
                BoughtBy = santa,
                IsValid = function() return true end,
                Kind = WEAPON_ROLE
            }, ply)
        end
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
                        CallShopHooks(equip_id, equip_id, activator, owner)
                    end
                else
                    local has = activator:HasWeapon(item_id)
                    local can_carry = activator:CanCarryWeapon(weapons.GetStored(item_id))
                    NotifyPlayer(activator, item_id, has, can_carry)
                    if has or not can_carry then
                        activator:UndoSantaGift(owner)
                        return
                    else
                        activator:Give(item_id)
                        CallShopHooks(nil, item_id, activator, owner)
                    end
                end

                if not GetGlobalBool("ttt_santa_random_presents", false) then
                    owner:SetNWString("SantaLoadedItem", "")
                    owner:SetCredits(1)
                end

                hook.Call("TTTSantaPresentOpened", nil, owner, activator, item_id)

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
        local info = GetEquipmentItemById(id)
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