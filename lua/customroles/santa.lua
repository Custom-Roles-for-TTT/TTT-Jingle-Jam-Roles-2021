local player = player

local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "santa"
ROLE.name = "Santa"
ROLE.nameplural = "Santas"
ROLE.nameext = "a Santa"
ROLE.nameshort = "san"

ROLE.desc = [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You can use your christmas cannon to give gifts to nice children and coal to naughty children.

Press {menukey} to receive your equipment!]]
ROLE.shortdesc = "Has a Christmas Cannon that can fire presents from their buy menu, or coal which kills anyone it touches."

ROLE.team = ROLE_TEAM_DETECTIVE
ROLE.shop = {}
ROLE.loadout = {"weapon_san_christmas_cannon"}
ROLE.startingcredits = 1
ROLE.canlootcredits = false

ROLE.convars = {
    {
        cvar = "ttt_santa_random_presents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_santa_jesters_are_naughty",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_santa_independents_are_naughty",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_santa_set_gift_owner",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["santa_help_pri"] = "Use {primaryfire} to give gifts to nice children",
        ["santa_help_sec"] = "Use {secondaryfire} to shoot coal at naughty children",
        ["santa_load_gift"] = "Open your buy menu with {menukey} to load a present!"
    }
}

RegisterRole(ROLE)

local santa_random_presents = CreateConVar("ttt_santa_random_presents", 0, FCVAR_REPLICATED)
local santa_jesters_are_naughty = CreateConVar("ttt_santa_jesters_are_naughty", 1, FCVAR_REPLICATED)
local santa_independents_are_naughty = CreateConVar("ttt_santa_independents_are_naughty", 0, FCVAR_REPLICATED)
CreateConVar("ttt_santa_shop_sync", 1, FCVAR_REPLICATED) -- This is generated automatically later but we want it on by default so we create it here first

if CLIENT then
    hook.Add("TTTTutorialRoleText", "Santa_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_SANTA then
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
            local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
            local jesterColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
            local independentColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = ROLE_STRINGS[ROLE_SANTA] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

            html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have a christmas cannon.</span>"

            -- Gifts
            html = html .. "<span style='display: block; margin-top: 10px;'>"
            if santa_random_presents:GetBool() then
                html = html .. ROLE_STRINGS[ROLE_SANTA] .. " can shoot random shop items"
            else
                html = html .. "Instead of buying items for themselves, " .. ROLE_STRINGS[ROLE_SANTA].. " can buy an item from their shop and shoot it"
            end
            html = html .. " from their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>christmas cannon</span>. Each player can only open one gift.</span>"

            -- Coal
            html = html .. "<span style='display: block; margin-top: 10px;'>The <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>christmas cannon</span> can also shoot coal which will kill anyone it hits.</span>"

            -- Ammo
            html = html .. "<span style='display: block; margin-top: 10px;'>Ammo for the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>christmas cannon</span> is refunded whenever a player opens a gift OR a naughty ("
            html = html .. "<span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor</span>"
            if santa_jesters_are_naughty:GetBool() then
                html = html .. ", <span style='color: rgb(" .. jesterColor.r .. ", " .. jesterColor.g .. ", " .. jesterColor.b .. ")'>jester</span>"
            end
            if santa_independents_are_naughty:GetBool() then
                html = html .. ", <span style='color: rgb(" .. independentColor.r .. ", " .. independentColor.g .. ", " .. independentColor.b .. ")'>independent</span>"
            end
            html = html .. ") player is killed by coal."

            html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"

            local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
            if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
                html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]
                if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                    html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
                end
            end
            html = html .. ".</span>"

            return html
        end
    end)

    hook.Add("TTTHUDInfoPaint", "Santa_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
        if client:IsSanta() and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_san_christmas_cannon" then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local text
            if client:GetNWBool("SantaCannonDisabled", false) then
                text = "Christmas Cannon: DISABLED"
            elseif santa_random_presents:GetBool() then
                if client:GetNWBool("SantaHasAmmo", false) then
                    text = "Christmas Cannon: READY"
                else
                    text = "Christmas Cannon: UNLOADED"
                end
            else
                text = "Christmas Cannon: GIFT "
                if client:GetNWString("SantaLoadedItem", "") ~= "" then
                    text = text .. "READY"
                else
                    text = text .. "UNLOADED"
                end

                text = text .. " - COAL "
                if client:GetNWBool("SantaHasAmmo", false) then
                    text = text .. "READY"
                else
                    text = text .. "UNLOADED"
                end
            end
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels here are
            if active_labels then
                label_top = label_top + (20 * #active_labels)
            else
                label_top = label_top + 20
            end

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            if active_labels then
                table.insert(active_labels, "santa_role_cannon")
            end
        end
    end)
end

if SERVER then
    AddCSLuaFile()

    local plymeta = FindMetaTable("Player")

    function plymeta:CheckSantaGift(sender)
        if not IsValid(sender) then return false end

        if not self.giftsReceived then
            self.giftsReceived = {}
        end

        local sid = sender:SteamID64()
        if self.giftsReceived[sid] then
            self:PrintMessage(HUD_PRINTTALK, "You have already received a gift from " .. sender:Nick() .. "!")
            return false
        elseif sid == self:SteamID64() then
            self:PrintMessage(HUD_PRINTTALK, "You cannot open a gift from yourself!")
            return false
        else
            self.giftsReceived[sid] = true
            return true
        end
    end

    function plymeta:UndoSantaGift(sender)
        self.giftsReceived[sender:SteamID64()] = false
    end

    function plymeta:ResetSantaGifts()
        self.giftsReceived = {}
    end

    -- We don't want Santa to receive items unless random presents is turned on
    hook.Add("TTTCanOrderEquipment", "Santa_TTTCanOrderEquipment", function(ply, id, is_item)
        if ply:IsSanta() and not santa_random_presents:GetBool() then
            if ply:GetNWString("SantaLoadedItem") == "" then
                -- Technically need to check if santa is actually allowed to buy the item here before loading it but this will only matter if people specifically try to break the role with console commands
                ply:SetNWString("SantaLoadedItem", tostring(id))
                ply:SetNWBool("SantaHasAmmo", false)
                ply:SetCredits(0)
                ply:AddBought(id)
            else
                ply:PrintMessage(HUD_PRINTTALK, "You have already loaded an item into the christmas cannon!")
            end
            return false
        end
    end)

    hook.Add("TTTPrepareRound", "Santa_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v:SetNWString("SantaLoadedItem", "")
            v:SetNWBool("SantaHasAmmo", false)
            v:SetNWBool("SantaCannonDisabled", false)
            v:ResetSantaGifts()
        end
    end)

    hook.Add("TTTBeginRound", "Santa_TTTBeginRound", function()
        for _, v in PlayerIterator() do
            if v:IsActiveSanta() then
                v:SetNWBool("SantaHasAmmo", true)
            end
        end

        -- If random presents are disabled we hijack santa's credits to tie them to their ammo
        if not santa_random_presents:GetBool() then
            timer.Create("santacredits", 1, 0, function()
                for _, v in PlayerIterator() do
                    if v:IsActiveSanta() then
                        if v:GetCredits() ~= 0 and not v:GetNWBool("SantaHasAmmo", false) then
                            v:SetCredits(0)
                        elseif v:GetCredits() ~= 1 and v:GetNWBool("SantaHasAmmo", false) then
                            v:SetCredits(1)
                        end
                    end
                end
            end)
        end
    end)

    hook.Add("TTTEndRound", "Santa_TTTEndRound", function()
        if timer.Exists("santacredits") then timer.Remove("santacredits") end
    end)

    hook.Add("TTTRewardDetectiveTraitorDeath", "Santa_TTTRewardDetectiveTraitorDeath", function(ply, victim, attacker, amount)
        -- If random presents are disabled santa should not receive credits
        if not santa_random_presents:GetBool() and ply:IsActiveSanta() then
            return true
        end
    end)

    hook.Add("TTTRewardPlayerKilledAmount", "Santa_TTTRewardPlayerKilledAmount", function(victim, attacker, amount)
        -- If random presents are disabled santa should not receive credits
        if not santa_random_presents:GetBool() and attacker:IsActiveSanta() then
            return 0
        end
    end)

    hook.Add("EntityTakeDamage", "Santa_EntityTakeDamage", function(target, dmg)
        -- Don't let being hit by a present hurt you
        local attacker = dmg:GetAttacker()
        if not IsValid(attacker) then return end

        if attacker:GetClass() == "ttt_santa_present" then
            dmg:SetDamage(0)
            dmg:ScaleDamage(0)
        end
    end)

    hook.Add("TTTPlayerRoleChanged", "Santa_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if newRole == ROLE_SANTA and oldRole ~= newRole then
            ply:SetNWBool("SantaHasAmmo", true)
        end
    end)

    local blockedEvents = {
        ["blackmarket"] = "makes their cannon unusable",
        ["future"] = "can't consistently work with the dynamic shop events"
    }
    hook.Add("TTTRandomatCanEventRun", "Santa_TTTRandomatCanEventRun", function(event)
        if not blockedEvents[event.Id] then return end

        for _, ply in PlayerIterator() do
            if ply:IsSanta() then
                return false, "There is " .. ROLE_STRINGS_EXT[ROLE_SANTA] .. " in the round and this event " .. blockedEvents[event.Id]
            end
        end
    end)
end