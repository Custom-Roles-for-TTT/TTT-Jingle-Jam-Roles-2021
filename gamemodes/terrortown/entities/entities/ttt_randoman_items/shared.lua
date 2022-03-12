-- Don't run this if the randomat doesn't exist, the role obviously can't work then
if not Randomat or type(Randomat.IsInnocentTeam) ~= "function" then return end
-- Remove the radar and body armour in the randoman's shop
table.Empty(EquipmentItems[ROLE_RANDOMAN])
local initialID = -1
local finalID = -1
local itemTotal = 15

-- Creating dummy passive shop items for now, on server and client.
for i = 1, itemTotal do
    local itemID = GenerateNewEquipmentID and GenerateNewEquipmentID() or 8

    -- Keeping track of what item IDs are being used as to not try to trigger a randomat when something like a radar is bought 
    if i == 1 then
        initialID = itemID
    elseif i == itemTotal then
        finalID = itemID
    end

    local randomanItem = {
        id = itemID,
        loadout = false,
        type = "item_passive",
        material = "vgui/ttt/icon_randomat",
        name = "Choose an Event!",
        desc = "Error, no randomat event assigned!\n\nBuying this will attempt to trigger 'Choose an Event!' as a fallback.",
        eventid = "choose",
        randomanItem = true
    }

    table.insert(EquipmentItems[ROLE_RANDOMAN], randomanItem)
end

local function IsRandomanItem(id)
    return id >= initialID and id <= finalID
end

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("UpdateRandomanItems")
    local eventsByCategory = {}

    for _, category in ipairs(Randomat:GetAllEventCategories()) do
        eventsByCategory[category] = Randomat:GetEventsByCategory(category)
    end

    -- Prevent multiple of the same randomats from triggering
    hook.Add("TTTCanOrderEquipment", "RandomanCheckRepeatItem", function(ply, id, is_item)
        if is_item then
            id = math.floor(id)

            if IsRandomanItem(id) then
                local item = GetEquipmentItemById(id)

                if ply:IsRandoman() and Randomat:IsEventActive(item.eventid) then
                    ply:PrintMessage(HUD_PRINTCENTER, "That's already in effect!")

                    return false
                end
            end
        end
    end)

    local triggeredEvents = {}

    -- Trigger a randomat event when a randoman item is bought
    hook.Add("TTTOrderedEquipment", "RandomanItemBought", function(ply, id, is_item)
        if is_item and IsRandomanItem(id) then
            local item = GetEquipmentItemById(id)

            -- This prevents randomats like communism repeatedly triggering
            for i, triggeredEvent in ipairs(triggeredEvents) do
                if item.eventid == triggeredEvent then return end
            end

            Randomat:TriggerEvent(item.eventid, ply)
            table.insert(triggeredEvents, item.eventid)
        end
    end)

    local chosenEvents = {}
    local bannedEvents = {}

    -- Update the banned randomats list according to the convar. This hook is called repeatedly, to allow for changing the convar round-to-round
    hook.Add("TTTUpdateRoleState", "UpdateBannedRandomanEvents", function()
        bannedEvents = string.Explode(",", GetConVar("ttt_randoman_banned_randomats"):GetString())
    end)

    -- Used to filter out repeat, secret and banned randomats when randomly selecting them for the randoman's shop
    local function IsEventAllowed(event)
        for i, chosenEvent in ipairs(chosenEvents) do
            if chosenEvent == event.id then return false end
        end

        if event.StartSecret then return false end

        for i, bannedEvent in ipairs(bannedEvents) do
            if bannedEvent == event.id then return false end
        end

        return true
    end

    -- Only update the randoman's shop if there actually is one, or if a player joins since the last round started
    -- (In case a player is forcibly made a randoman, either through commands or a randomat)
    local playerJoined = false

    hook.Add("PlayerInitialSpawn", "RandomanPlayerJoinCheck", function(ply)
        playerJoined = true
    end)

    hook.Add("TTTBeginRound", "UpdateRandomanItems", function()
        if playerJoined or player.IsRoleLiving(ROLE_RANDOMAN) then
            table.Empty(chosenEvents)
            local garunteedEventCategories = string.Explode(",", GetConVar("ttt_randoman_guaranteed_randomat_categories"):GetString())
            local garunteedItemCount = #garunteedEventCategories
            local randomanItemCount = 0
            net.Start("UpdateRandomanItems")

            for _, item in ipairs(EquipmentItems[ROLE_RANDOMAN]) do
                -- Check that it is using one of the IDs used by a randoman item
                if IsRandomanItem(item.id) then
                    randomanItemCount = randomanItemCount + 1
                    local event
                    local category

                    -- First put all guaranteed events in
                    if randomanItemCount <= garunteedItemCount then
                        category = garunteedEventCategories[randomanItemCount]
                        local events = eventsByCategory[category]
                        table.Shuffle(events)

                        -- Find a random event in that category that is allowed to run
                        for _, categoryEvent in ipairs(events) do
                            if IsEventAllowed(categoryEvent) and Randomat:CanEventRun(categoryEvent, true) then
                                event = categoryEvent
                                item.material = "vgui/ttt/roles/ran/items/" .. category .. ".png"
                                net.WriteString(category)
                                break
                            end
                        end
                    end

                    -- If no events of that category are allowed to run,
                    -- or we're done with guranteed events, find a complete random one
                    if not event then
                        event = Randomat:GetRandomEvent(true, IsEventAllowed)
                        category = "moderateimpact"

                        if istable(event.Categories) and not table.IsEmpty(event.Categories) then
                            category = event.Categories[1]
                        end

                        net.WriteString(category)
                    end

                    table.insert(chosenEvents, event.id)
                    -- Update randomat ID
                    item.eventid = event.id
                    net.WriteString(event.id)
                    -- Update randomat name
                    local name = Randomat:GetEventTitle(event)
                    local longName = name
                    local descriptionName = false

                    -- Puts the name of the randomat in the description if it is too long
                    if string.len(name) > 35 then
                        name = string.Left(name, 32) .. "..."
                        descriptionName = true
                    end

                    item.name = name
                    net.WriteString(name)
                    -- Update randomat description
                    local description = "'" .. longName .. "' is triggered when you buy this."

                    if event.Description ~= nil and event.Description ~= "" then
                        description = event.Description

                        if descriptionName then
                            description = longName .. "\n\n" .. description
                        end
                    end

                    -- Add event's category to its description 
                    -- There is garunteed to be one, as moderateimpact is the fallback category for an event without one
                    description = "Category: " .. Randomat:GetReadableCategory(category) .. "\n\n" .. description
                    item.desc = description
                    net.WriteString(description)
                end
            end

            net.Broadcast()
        end

        -- Reset the table of randomats triggered by the randoman each round
        table.Empty(triggeredEvents)
        playerJoined = false
    end)

    -- Greys out randomats if an event's condition isn't met anymore, because something changed in the round, for anyone who is a randoman
    timer.Create("CheckValidRandomanEvents", 1, 0, function()
        for i, ply in ipairs(player.GetAll()) do
            if ply:IsRandoman() then
                for j, item in ipairs(EquipmentItems[ROLE_RANDOMAN]) do
                    -- Check that it is using one of the IDs used by a randoman item
                    if IsRandomanItem(item.id) and not Randomat:CanEventRun(item.eventid) then
                        ply:AddEquipmentItem(item.id)
                    end
                end
            end
        end
    end)
end

if CLIENT then
    -- Updating randoman items per-round on the client
    net.Receive("UpdateRandomanItems", function()
        for i, item in ipairs(EquipmentItems[ROLE_RANDOMAN]) do
            -- Check that it is using one of the IDs used by a randoman item
            if IsRandomanItem(item.id) then
                item.material = "vgui/ttt/roles/ran/items/" .. net.ReadString() .. ".png"
                item.eventid = net.ReadString()
                item.name = net.ReadString()
                item.desc = net.ReadString()
            end
        end
    end)
end