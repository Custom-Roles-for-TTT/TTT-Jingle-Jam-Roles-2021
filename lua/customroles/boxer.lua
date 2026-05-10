local ROLE = {}

ROLE.nameraw = "boxer"
ROLE.name = "Boxer"
ROLE.nameplural = "Boxers"
ROLE.nameext = "a Boxer"
ROLE.nameshort = "box"

ROLE.desc = [[You are {role}! Use your boxing gloves
to make others drop their weapons or
knock them out.

Knock out all of the living players at
the same time to win!]]
ROLE.shortdesc = "Uses their Boxing Gloves to knock out players and make them drop their weapons. Wins by knocking out all living players at the same time."

ROLE.team = ROLE_TEAM_JESTER

ROLE.loadout = {"weapon_box_gloves"}

ROLE.startinghealth = 125
ROLE.maxhealth = 125

ROLE.convars = {
    {
        cvar = "ttt_boxer_speed_bonus",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_boxer_drop_chance",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_boxer_knockout_chance",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_boxer_knockout_duration",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_boxer_hide_when_active",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["box_gloves_help_pri"] = "Use {primaryfire} to knock weapons out of players' hands",
        ["box_gloves_help_sec"] = "Attack with {secondaryfire} to knock players out",
        ["box_revive"] = "Press '{usekey}' to revive",
        ["ev_win_boxer"] = "The {role} pummeled their way to victory",
        ["win_boxer"] = "The {role} has scored a Knock Out!"
    }
}

RegisterRole(ROLE)

local boxer_speed_bonus = CreateConVar("ttt_boxer_speed_bonus", "0.35", FCVAR_REPLICATED, "Percent bonus to speed while the boxer has their gloves out", 0.0, 1.0)
local boxer_drop_chance = CreateConVar("ttt_boxer_drop_chance", "0.33", FCVAR_REPLICATED, "Percent chance a punched player will drop weapon", 0.0, 1.0)
local boxer_knockout_chance = CreateConVar("ttt_boxer_knockout_chance", "0.33", FCVAR_REPLICATED, "Percent chance a punched player will get knocked out", 0.0, 1.0)
local boxer_knockout_duration = CreateConVar("ttt_boxer_knockout_duration", "10", FCVAR_REPLICATED, "Time punched player should be knocked out", 1, 60)
local boxer_hide_when_active = CreateConVar("ttt_boxer_hide_when_active", "0", FCVAR_REPLICATED, "Whether to hide the boxer once the fight has started")

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_BoxerWinPrevented")

    local knockout = Sound("knockout.mp3")
    local plymeta = FindMetaTable("Player")

    local GetAllPlayers = player.GetAll

    local function OnRagdollUsed(ragdoll, ply)
        local ragdolledPly = ragdoll:GetNWEntity("BoxerRagdolledPly", nil)
        if not IsValid(ragdolledPly) then return end

        -- Don't let players un-ragdoll themselves
        if ragdolledPly == ply then return end

        -- Only let knocked out players be revived
        if not ragdolledPly:GetNWBool("BoxerKnockedOut", false) then return end

        ragdolledPly:BoxerRevive()
    end

    -- Match dti.BOOL_FOUND in corpse_shd.lua
    local BOOL_FOUND = 0
    function plymeta:BoxerKnockout()
        local boxerRagdoll = self:GetNWEntity("BoxerRagdoll", nil)
        if IsValid(boxerRagdoll) then return end

        self:SetNWBool("BoxerKnockedOut", true)
        self:SelectWeapon("weapon_ttt_unarmed")
        self:EmitSound(knockout)

        -- Create ragdoll and lock their view
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetNWEntity("BoxerRagdolledPly", self)
        ragdoll:SetNWString("nick", self:Nick())
        ragdoll:SetDTBool(BOOL_FOUND, true)
        ragdoll.playerHealth = self:Health()
        ragdoll.playerColor = self:GetPlayerColor()
        -- Don't let the red matter bomb destroy this ragdoll
        ragdoll.WYOZIBHDontEat = true
        -- Let the user be revived by other players
        ragdoll.CanUseKey = true
        ragdoll.UseOverride = OnRagdollUsed

        local velocity = self:GetVelocity()
        ragdoll:SetPos(self:GetPos())
        ragdoll:SetModel(self:GetModel())
        ragdoll:SetSkin(self:GetSkin())
        for _, value in pairs(self:GetBodyGroups()) do
            ragdoll:SetBodygroup(value.id, self:GetBodygroup(value.id))
        end
        ragdoll:SetAngles(self:GetAngles())
        ragdoll:SetColor(self:GetColor())
        CORPSE.SetPlayerNick(ragdoll, self)
        ragdoll:Spawn()
        ragdoll:Activate()

        -- So their player ent will match up (position-wise) with where their ragdoll is.
        self:SetParent(ragdoll)
        -- Set velocity for each piece of the ragdoll
        for i = 1, ragdoll:GetPhysicsObjectCount() do
            local phys_obj = ragdoll:GetPhysicsObjectNum(i)
            if phys_obj then
                phys_obj:SetVelocity(velocity)
            end
        end

        self:SetNWEntity("BoxerRagdoll", ragdoll)
        self:Spectate(OBS_MODE_CHASE)
        self:SpectateEntity(ragdoll)

        -- The diguiser stays in their hand so hide it from view
        self:DrawViewModel(false)
        self:DrawWorldModel(false)

        -- Timer to revive
        local duration = boxer_knockout_duration:GetInt()
        self:SetNWInt("BoxerKnockoutEndTime", CurTime() + duration)
        timer.Create("BoxerKnockout_" .. self:SteamID64(), duration, 1, function()
            if not self:GetNWBool("BoxerKnockedOut", false) then return end
            self:BoxerRevive()
        end)
    end

    function plymeta:BoxerRevive()
        local boxerRagdoll = self:GetNWEntity("BoxerRagdoll", nil)
        if not IsValid(boxerRagdoll) then return end

        self:SetNWBool("BoxerKnockedOut", false)
        self:SetNWInt("BoxerKnockoutEndTime", 0)

        -- Unragdoll
        -- Set these so players don't get their role weapons given back if they've already used them
        self.Resurrecting = true
        self.DeathRoleWeapons = nil
        self:SpectateEntity(nil)
        self:UnSpectate()
        self:SetParent()
        self:Spawn()
        self:SetPos(boxerRagdoll:GetPos())
        self:SetVelocity(boxerRagdoll:GetVelocity())
        local yaw = boxerRagdoll:GetAngles().yaw
		self:SetAngles(Angle(0, yaw, 0))
        self:SetModel(boxerRagdoll:GetModel())
        self:SetPlayerColor(boxerRagdoll.playerColor)

        -- Let weapons be seen again
        self:DrawViewModel(true)
        self:DrawWorldModel(true)

        local newhealth = boxerRagdoll.playerHealth
        if newhealth <= 0 then
            newhealth = 1
        end
        self:SetHealth(newhealth)
        SetRoleMaxHealth(self)

        SafeRemoveEntity(boxerRagdoll)
        self:SetNWEntity("BoxerRagdoll", nil)
    end

    local function TransferRagdollDamage(rag, dmginfo)
        if not IsRagdoll(rag) then return end
        local ply = rag:GetNWEntity("BoxerRagdolledPly", nil)
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end

        -- Keep track of how much health they have left
        local damage = dmginfo:GetDamage()
        rag.playerHealth = rag.playerHealth - damage

        -- Kill the player if they run out of health
        if rag.playerHealth <= 0 then
            ply:BoxerRevive()

            local att = dmginfo:GetAttacker()
            local inflictor = dmginfo:GetInflictor()
            if not IsValid(inflictor) then
                inflictor = att
            end
            local dmg_type = dmginfo:GetDamageType()

            -- Use TakeDamage instead of Kill so it properly applies karma
            local dmg = DamageInfo()
            dmg:SetDamageType(dmg_type)
            dmg:SetAttacker(att)
            dmg:SetInflictor(inflictor)
            -- Use 10 so damage scaling doesn't mess with it. The worse damage factor (0.1) will still deal 1 damage after scaling a 10 down
            -- Karma ignores excess damage anyway
            dmg:SetDamage(10)
            dmg:SetDamageForce(Vector(0, 0, 1))

            ply:TakeDamageInfo(dmg)
        else
            ply:SetHealth(rag.playerHealth)
        end
    end

    hook.Add("Initialize", "Boxer_Initialize", function()
        WIN_BOXER = GenerateNewWinID(ROLE_BOXER)
    end)

    hook.Add("EntityTakeDamage", "Boxer_EntityTakeDamage", function(ent, dmginfo)
        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end

        -- Don't transfer damage from jester-like players
        if att:ShouldActLikeJester() then return end

        local ply, rag
        if IsRagdoll(ent) then
            rag = ent
            ply = ent:GetNWEntity("BoxerRagdolledPly", nil)
        elseif IsPlayer(ent) then
            ply = ent
            rag = ply:GetNWEntity("BoxerRagdoll", nil)
        end

        if not IsValid(rag) then return end
        if not IsValid(ply) or not ply:GetNWBool("BoxerKnockedOut", false) then return end
        if att == ply then return end

        -- Transfer damage from the knockout ragdoll to the real player
        TransferRagdollDamage(rag, dmginfo)
    end)

    hook.Add("TTTPrepareRound", "Boxer_PrepareRound", function()
        for _, v in pairs(GetAllPlayers()) do
            v:SetNWBool("BoxerWinPrevented", false)
            v:SetNWBool("BoxerKnockedOut", false)
            v:SetNWInt("BoxerKnockoutEndTime", -1)
            v:SetNWEntity("BoxerRagdoll", nil)
            timer.Remove("BoxerKnockout_" .. v:SteamID64())
        end
    end)

    -- Win conditions

    -- The boxer wins if they are the only ones left alive or conscious
    hook.Add("TTTCheckForWin", "Boxer_CheckForWin", function()
        local boxer_alive = false
        local other_alive = false
        local other_knockedout = true
        for _, v in ipairs(GetAllPlayers()) do
            if v:Alive() and v:IsTerror() then
                if v:IsBoxer() then
                    boxer_alive = true
                elseif not v:ShouldActLikeJester() then
                    other_alive = true
                    if not v:GetNWBool("BoxerKnockedOut", false) then
                        other_knockedout = false
                    end
                end
            end
        end

        if boxer_alive and (not other_alive or other_knockedout) then
            return WIN_BOXER
        end
    end)

    local function HandleBoxerWinBlock(win_type)
        if win_type == WIN_NONE or win_type == WIN_BOXER then return win_type end

        local boxer = player.GetLivingRole(ROLE_BOXER)
        if not IsPlayer(boxer) or boxer:IsRoleAbilityDisabled() then return win_type end

        if not boxer:GetNWBool("BoxerWinPrevented", false) then
            boxer:SetNWBool("BoxerWinPrevented", true)
            PrintMessage(HUD_PRINTTALK, "FIGHT!")
            PrintMessage(HUD_PRINTCENTER, "FIGHT!")

            net.Start("TTT_BoxerWinPrevented")
            net.WritePlayer(boxer)
            net.Broadcast()
        end
        return WIN_NONE
    end

    hook.Add("TTTWinCheckBlocks", "Boxer_TTTWinCheckBlocks", function(win_blocks)
        table.insert(win_blocks, HandleBoxerWinBlock)
    end)

    hook.Add("TTTPrintResultMessage", "Boxer_PrintResultMessage", function(type)
        if type == WIN_BOXER then
            LANG.Msg("win_boxer", { role = string.lower(ROLE_STRINGS[ROLE_BOXER]) })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_BOXER] .. " wins.\n")
            return true
        end
    end)
end

if CLIENT then
    local MathCos = math.cos
    local MathSin = math.sin
    local StringUpper = string.upper

    local client
    local hide_when_active = false

    surface.CreateFont("KnockedOut", {
        font = "Trebuchet24",
        size = 22,
        weight = 600
    })

    hook.Add("TTTSyncWinIDs", "Boxer_TTTSyncWinIDs", function()
        WIN_BOXER = WINS_BY_ROLE[ROLE_BOXER]
    end)

    hook.Add("TTTUpdateRoleState", "Boxer_TTTUpdateRoleState", function()
        client = LocalPlayer()
        hide_when_active = boxer_hide_when_active:GetBool()
    end)

    -- Win condition and events
    hook.Add("TTTScoringWinTitle", "Boxer_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
        if wintype == WIN_BOXER then
            return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_BOXER]) }, c = ROLE_COLORS[ROLE_BOXER] }
        end
    end)

    hook.Add("TTTEventFinishText", "Boxer_TTTEventFinishText", function(e)
        if e.win == WIN_BOXER then
            return LANG.GetParamTranslation("ev_win_boxer", { role = string.lower(ROLE_STRINGS[ROLE_BOXER]) })
        end
    end)

    hook.Add("TTTEventFinishIconText", "Boxer_TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_BOXER then
            return win_string, ROLE_STRINGS[ROLE_BOXER]
        end
    end)

    -- Show the boxer to other players when they've prevented a win from occurring
    local function IsBoxerVisible(ply)
        return IsPlayer(ply) and ply:IsBoxer() and ply:GetNWBool("BoxerWinPrevented", false) and not hide_when_active
    end

    net.Receive("TTT_BoxerWinPrevented", function()
        local ent = net.ReadPlayer()
        if not IsPlayer(ent) then return end

        ent:EmitSound("fight.wav")
    end)

    -- Show the boxer icon if the player is a boxer who should be visible
    hook.Add("TTTTargetIDPlayerRoleIcon", "Boxer_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
        if IsBoxerVisible(ply) then
            return ROLE_BOXER, false, ROLE_BOXER
        end
    end)

    -- Show the boxer information and color when you look at the player
    hook.Add("TTTTargetIDPlayerRing", "Boxer_TTTTargetIDPlayerRing", function(ent, cli, ring_visible)
        if GetRoundState() < ROUND_ACTIVE then return end

        if IsBoxerVisible(ent) then
            return true, ROLE_COLORS_RADAR[ROLE_BOXER]
        end
    end)

    hook.Add("TTTTargetIDPlayerText", "Boxer_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        if GetRoundState() < ROUND_ACTIVE then return end

        if IsBoxerVisible(ent) then
            return StringUpper(ROLE_STRINGS[ROLE_BOXER]), ROLE_COLORS_RADAR[ROLE_BOXER]
        end
    end)

    -- Hide the player from radars if they shouldn't be visible
    hook.Add("TTTRadarPlayerRender", "Boxer_TTTRadarPlayerRender", function(cli, tgt, color, hidden)
        -- Don't bother running this if the boxer is never hidden
        if not hide_when_active then return end
        -- Or if something else is already hiding the radar point
        if hidden then return end
        -- Or if this radar point doesn't represent a player
        if not tgt.sid64 or #tgt.sid64 == 0 then return end

        local ply = player.GetBySteamID64(tgt.sid64)
        -- Make sure this player exists and is a boxer
        if not IsPlayer(ply) or not ply:IsBoxer() then return end

        -- If the "FIGHT" announcement has happened then hide the boxer from radar
        if ply:GetNWBool("BoxerWinPrevented", false) then
            return color, true
        end
    end)

    -- Tutorial
    hook.Add("TTTTutorialRoleText", "Boxer_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_BOXER then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
            local traitorColor = ROLE_COLORS[ROLE_TRAITOR]
            local html =  "The " .. ROLE_STRINGS[ROLE_BOXER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to knock out all of the living players."

            -- Knockout and Weapon Drop chance
            local drop_chance = boxer_drop_chance:GetFloat()
            local knockout_chance = boxer_knockout_chance:GetFloat()
            local canDrop = drop_chance > 0
            local canKnockout = knockout_chance > 0
            if canDrop or canKnockout then
                html = html .. "<span style='display: block; margin-top: 10px;'>The boxing gloves primary attack has a "

                if canDrop then
                    local chance = math.Round(drop_chance * 100)
                    html = html .. chance .. "% chance to make targeted players <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>drop their weapon</span>"
                end

                if canDrop and canKnockout then
                    html = html .. " and a "
                end

                if canKnockout then
                    local chance = math.Round(knockout_chance * 100)
                    html = html .. chance .. "% chance to <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>knock out</span> targeted players"
                end

                html = html .. ".</span>"
            end

            -- Knockout Duration
            local duration = boxer_knockout_duration:GetInt()
            html = html .. "<span style='display: block; margin-top: 10px;'>Using the secondary attack will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>knock out</span> the players that are hit for " .. duration .. " seconds.</span>"

            -- Speed Bonus
            local speed_bonus = boxer_speed_bonus:GetFloat()
            if speed_bonus > 0 then
                local bonus = math.Round(speed_bonus * 100)
                html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_BOXER] .. " will <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>move " .. bonus .. "% faster</span> while their gloves are out.</span>"
            end

            -- Announce when one team remaininkg
            html = html .. "<span style='display: block; margin-top: 10px;'>When only one other team remains, a voice will <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>announce the start of the final fight</span>, alerting the other players that the " .. ROLE_STRINGS[ROLE_BOXER] .. " is out there.</span>"

            -- Hide when one team remaining
            if boxer_hide_when_active:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>After the final fight is announced, they are <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>hidden</span> from players who could normally <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>see them through walls</span>.</span>"
            end

            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_BOXER] .. " is the only player remaining or all other players are knocked out then <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>they will win!</span></span>"

            return html
        end
    end)

    -- Dizzy effect
    local function GetHeadPos(ply, rag)
        local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
        local pos
        if bone then
            local _
            pos, _ = rag:GetBonePosition(bone)
        else
            pos = rag:GetPos()
        end

        pos.z = 15
        local plyPos = ply:GetPos()
        plyPos.z = pos.z

        -- Shift further toward the head, rather than the neck area
        local dir = (plyPos - pos):GetNormal()
        return pos + (dir * -5)
    end

    hook.Add("TTTPlayerAliveClientThink", "Boxer_KnockedOut_TTTPlayerAliveClientThink", function(cli, ply)
        local ragdoll = ply:GetNWEntity("BoxerRagdoll", nil)
        if not IsValid(ragdoll) then return end

        if ply:GetNWBool("BoxerKnockedOut", false) then
            if not ragdoll.KnockoutEmitter then ragdoll.KnockoutEmitter = ParticleEmitter(ragdoll:GetPos()) end
            if not ragdoll.KnockoutNextPart then ragdoll.KnockoutNextPart = CurTime() end
            if not ragdoll.KnockoutDir then ragdoll.KnockoutDir = 0 end
            local pos = ragdoll:GetPos()
            if ragdoll.KnockoutNextPart < CurTime() and client:GetPos():Distance(pos) <= 3000 then
                ragdoll.KnockoutEmitter:SetPos(pos)
                ragdoll.KnockoutNextPart = CurTime() + 0.02
                ragdoll.KnockoutDir = ragdoll.KnockoutDir + 0.25
                local radius = 7
                local vec = Vector(MathSin(ragdoll.KnockoutDir) * radius, MathCos(ragdoll.KnockoutDir) * radius, 10)
                local particle = ragdoll.KnockoutEmitter:Add("particle/wisp.vmt", GetHeadPos(ply, ragdoll) + vec)
                particle:SetVelocity(Vector(0, 0, 0))
                particle:SetDieTime(1)
                particle:SetStartAlpha(200)
                particle:SetEndAlpha(0)
                particle:SetStartSize(1)
                particle:SetEndSize(1)
                particle:SetRoll(0)
                particle:SetRollDelta(0)
                particle:SetColor(200, 230, 90)
            end
        elseif ragdoll.KnockoutEmitter then
            ragdoll.KnockoutEmitter:Finish()
            ragdoll.KnockoutEmitter = nil
        end
    end)

    -- Knocked out progress bar
    local margin = 10
    local width, height = 200, 25
    local x = ScrW() / 2 - width / 2
    local y = margin / 2 + height
    local colors = {
        background = Color(30, 60, 100, 222),
        fill = Color(75, 150, 255, 255)
    }
    hook.Add("HUDPaint", "Boxer_KnockedOut_HUDPaint", function()
        if not IsPlayer(client) or not client:GetNWBool("BoxerKnockedOut", false) then return end

        local endTime = client:GetNWInt("BoxerKnockoutEndTime", 0)
        if endTime <= 0 then return end

        local diff = endTime - CurTime()
        if diff <= 0 then return end

        local duration = boxer_knockout_duration:GetInt()
        CRHUD:PaintBar(8, x, y, width, height, colors, 1 - (diff / duration))
        draw.SimpleText("KNOCKED OUT", "KnockedOut", ScrW() / 2, y + 1, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end)

    -- Show message indicating they can be revived
    local MAX_TRACE_LENGTH = math.sqrt(3) * 2 * 16384
    hook.Add("HUDDrawTargetID", "Boxer_KnockedOut_HUDDrawTargetID", function()
        if not IsPlayer(client) then return end

        local startpos = client:EyePos()
        local endpos = client:GetAimVector()
        endpos:Mul(MAX_TRACE_LENGTH)
        endpos:Add(startpos)
        local trace = util.TraceLine({
            start = startpos,
            endpos = endpos,
            mask = MASK_SHOT,
            filter = client:GetObserverMode() == OBS_MODE_IN_EYE and { client, client:GetObserverTarget() } or client
        })
        local ent = trace.Entity
        if not IsValid(ent) or ent.NoTarget then return end

        local ragdolledPly = ent:GetNWEntity("BoxerRagdolledPly", nil)
        if not IsPlayer(ragdolledPly) then return end
        if not ragdolledPly:GetNWBool("BoxerKnockedOut", false) then return end
        ent.TargetIDHint = { name = "box_revive_placeholder" }
    end)

    hook.Add("TTTTargetIDEntityHintLabel", "Boxer_KnockedOut_TTTTargetIDEntityHintLabel", function(ent, cli, text, col)
        if text == "box_revive_placeholder" then
            local ply = ent:GetNWEntity("BoxerRagdolledPly", nil)
            -- Don't show this label if a knocked out player looks at themselves
            if IsPlayer(ply) and ply == cli then
                return ""
            end
            return LANG.GetParamTranslation("box_revive", { usekey = Key("+use", "E") } ), COLOR_WHITE
        end
    end)
end

-- Boxers move faster when they have their gloves out
hook.Add("TTTSpeedMultiplier", "Boxer_TTTSpeedMultiplier", function(ply, mults)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and WEPS.GetClass(wep) == "weapon_box_gloves" then
        local speed_bonus = 1 + boxer_speed_bonus:GetFloat()
        table.insert(mults, speed_bonus)
    end
end)