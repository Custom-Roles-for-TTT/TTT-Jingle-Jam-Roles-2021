-- Don't run this if the randomat doesn't exist, the role obviously can't work then
if not Randomat or type(Randomat.IsInnocentTeam) ~= "function" then return end
local initialID = -1
local finalID = -1
local itemTotal = 15

if not istable(DefaultEquipment[ROLE_RANDOMAN]) then
    DefaultEquipment[ROLE_RANDOMAN] = {}
end

-- Make sure none of the default equipment has the "Custom" icon on it
for _, item in ipairs(EquipmentItems[ROLE_RANDOMAN]) do
    if not table.HasValue(DefaultEquipment[ROLE_RANDOMAN], item.id) then
        table.insert(DefaultEquipment[ROLE_RANDOMAN], item.id)
    end
end

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
    table.insert(DefaultEquipment[ROLE_RANDOMAN], itemID)
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
                    ply:QueueMessage(MSG_PRINTCENTER, "That's already in effect!")

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
    local guaranteedEventCategories = {}
    local forcedEvents = {}

    -- Update the banned randomats list
    -- This hook is called repeatedly, to allow for changing the convars round-to-round
    hook.Add("TTTUpdateRoleState", "UpdateBannedRandomanEvents", function()
        local bannedEventsString = GetConVar("ttt_randoman_banned_randomats"):GetString()
        local guaranteedEventCategoriesString = GetConVar("ttt_randoman_guaranteed_categories"):GetString()
        local forcedEventsString = GetConVar("ttt_randoman_guaranteed_randomats"):GetString()

        if #bannedEventsString > 0 then
            bannedEvents = string.Explode(",", bannedEventsString)
        else
            bannedEvents = {}
        end

        if #guaranteedEventCategoriesString > 0 then
            guaranteedEventCategories = string.Explode(",", guaranteedEventCategoriesString)
        else
            guaranteedEventCategories = {}
        end

        if #forcedEventsString > 0 then
            forcedEvents = string.Explode(",", forcedEventsString)
        else
            forcedEvents = {}
        end

        -- Add the 'What did I find in my pocket?' event to the randoman's shop if the beggar and convar is enabled
        if not table.HasValue(forcedEvents, "pocket") and GetConVar("ttt_beggar_enabled"):GetBool() and GetConVar("ttt_randoman_guarantee_pockets_event"):GetBool() then
            table.insert(forcedEvents, "pocket")
        end
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

    local function GetCategory(event)
        local category = "moderateimpact"

        if istable(event.Categories) and not table.IsEmpty(event.Categories) then
            category = event.Categories[1]
        end

        return category
    end

    -- Keep track of this so the randomization only happens once per round
    local eventsRandomized = false

    local function RandomizeEvents()
        if eventsRandomized then return end
        table.Empty(chosenEvents)
        local guaranteedItemCount = 0
        local guaranteedItemTotal = #guaranteedEventCategories
        local forcedItemCount = 0
        local forcedItemTotal = #forcedEvents
        net.Start("UpdateRandomanItems")

        for _, item in ipairs(EquipmentItems[ROLE_RANDOMAN]) do
            -- Check that it is using one of the IDs used by a randoman item
            if IsRandomanItem(item.id) then
                local event
                local category

                -- First put all guaranteed events in
                if guaranteedItemCount < guaranteedItemTotal then
                    guaranteedItemCount = guaranteedItemCount + 1
                    category = guaranteedEventCategories[guaranteedItemCount]
                    local events = eventsByCategory[category]
                    table.Shuffle(events)

                    -- Find a random event in that category that is allowed to run
                    for _, categoryEvent in ipairs(events) do
                        if IsEventAllowed(categoryEvent) and Randomat:CanEventRun(categoryEvent) then
                            event = categoryEvent
                            break
                        end
                    end
                end

                -- If we haven't yet found an event, make sure we include the ones we always want to show
                if not event and forcedItemCount < forcedItemTotal then
                    forcedItemCount = forcedItemCount + 1
                    event = Randomat.Events[forcedEvents[forcedItemCount]]

                    if not IsEventAllowed(event) or not Randomat:CanEventRun(event) then
                        event = nil
                    else
                        category = GetCategory(event)
                    end
                end

                -- If no valid event has been found so far, find a completely random one
                if not event then
                    event = Randomat:GetRandomEvent(true, IsEventAllowed)
                    category = GetCategory(event)
                end

                -- Update the icon and send the displayed category to the client
                item.material = "vgui/ttt/roles/ran/items/" .. category .. ".png"
                net.WriteString(category)
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

                if (event.ExtDescription and #event.ExtDescription > 0) or (event.Description and #event.Description > 0) then
                    description = event.ExtDescription or event.Description

                    if descriptionName then
                        description = longName .. "\n\n" .. description
                    end
                end

                -- Add event's category to its description
                -- There is guaranteed to be one, as moderate impact is the fallback category for an event without one
                description = "Category: " .. Randomat:GetReadableCategory(category) .. "\n\n" .. description
                item.desc = description
                net.WriteString(description)
            end
        end

        net.Broadcast()
    end

    -- Make sure the events have been randomized since they were last used if someone is made a randoman
    hook.Add("TTTPlayerRoleChanged", "Randoman_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole == newRole then return end
        if newRole ~= ROLE_RANDOMAN then return end
        RandomizeEvents()
    end)

    -- Reset the table of randomats triggered by the randoman each round
    hook.Add("TTTPrepareRound", "UpdateRandomanItems", function()
        table.Empty(triggeredEvents)
        eventsRandomized = false
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