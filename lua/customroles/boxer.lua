local ROLE = {}

ROLE.nameraw = "boxer"
ROLE.name = "Boxer"
ROLE.nameplural = "Boxers"
ROLE.nameext = "a Boxer"
ROLE.nameshort = "box"

ROLE.desc = [[You are {role}!]]

ROLE.team = ROLE_TEAM_JESTER

ROLE.loadout = {"weapon_box_gloves"}

ROLE.startinghealth = 125
ROLE.maxhealth = 125

ROLE.convars = {}
table.insert(ROLE.convars, {
    cvar = "ttt_boxer_drop_chance",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 2
})
table.insert(ROLE.convars, {
    cvar = "ttt_boxer_knockout_duration",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

ROLE.translations = {
    ["english"] = {
        ["box_gloves_help_pri"] = "Use {primaryfire} to knock weapons out of players' hands",
        ["box_gloves_help_sec"] = "Attack with {secondaryfire} to knock players out",
        ["box_revive"] = "Press '{usekey}' to revive"
    }
}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    CreateConVar("ttt_boxer_drop_chance", "0.33", FCVAR_NONE, "Percent chance a punched player will drop weapon", 0.0, 1.0)
    local knockout_duration = CreateConVar("ttt_boxer_knockout_duration", "10", FCVAR_NONE, "Time punched player should be knocked down", 1, 60)

    local knockout = Sound("knockout.mp3")
    local plymeta = FindMetaTable("Player")

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
        -- Don't let the red matter bomb destroy this ragdoll
        ragdoll.WYOZIBHDontEat = true
        -- Let the user be revived by other players
        ragdoll.CanUseKey = true
        ragdoll.UseOverride = OnRagdollUsed

        ragdoll:SetPos(self:GetPos())
        local velocity = self:GetVelocity()
        ragdoll:SetAngles(self:GetAngles())
        ragdoll:SetModel(self:GetModel())
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
        local duration = knockout_duration:GetInt()
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
        self:SpectateEntity(nil)
        self:UnSpectate()
        self:SetParent()
        self:Spawn()
        self:SetPos(boxerRagdoll:GetPos())
        self:SetVelocity(boxerRagdoll:GetVelocity())
        local yaw = boxerRagdoll:GetAngles().yaw
		self:SetAngles(Angle(0, yaw, 0))
        self:SetModel(boxerRagdoll:GetModel())

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
        boxerRagdoll = nil
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
        for _, v in pairs(player.GetAll()) do
            v:SetNWBool("BoxerKnockedOut", false)
            v:SetNWInt("BoxerKnockoutEndTime", -1)
            v:SetNWEntity("BoxerRagdoll", nil)
            timer.Remove("BoxerKnockout_" .. v:SteamID64())
        end
    end)

    hook.Add("TTTSyncGlobals", "Boxer_TTTSyncGlobals", function()
        SetGlobalInt("ttt_boxer_knockout_duration", knockout_duration:GetInt())
    end)

    -- TODO: Win condition
end

if CLIENT then
    local MathCos = math.cos
    local MathSin = math.sin

    local client

    surface.CreateFont("KnockedOut", {
        font = "Trebuchet24",
        size = 22,
        weight = 600
    })

    -- TODO: Tutorial
    -- TODO: Win events

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

    -- Dizzy effect
    hook.Add("TTTPlayerAliveClientThink", "Boxer_KnockedOut_TTTPlayerAliveClientThink", function(cli, ply)
        if not client then
            client = cli
        end
        local ragdoll = ply:GetNWEntity("BoxerRagdoll", nil)
        if not IsValid(ragdoll) then return end

        if ply:GetNWBool("BoxerKnockedOut", false) then
            if not ragdoll.KnockoutEmitter then ragdoll.KnockoutEmitter = ParticleEmitter(ragdoll:GetPos()) end
            if not ragdoll.KnockoutNextPart then ragdoll.KnockoutNextPart = CurTime() end
            if not ragdoll.KnockoutDir then ragdoll.KnockoutDir = 0 end
            local pos = ragdoll:GetPos()
            if ragdoll.KnockoutNextPart < CurTime() then
                if client:GetPos():Distance(pos) <= 3000 then
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
        if not client then
            client = LocalPlayer()
        end

        if not client:GetNWBool("BoxerKnockedOut", false) then return end

        local endTime = client:GetNWInt("BoxerKnockoutEndTime", 0)
        if endTime <= 0 then return end

        local diff = endTime - CurTime()
        if diff <= 0 then return end

        local duration = GetGlobalInt("ttt_boxer_knockout_duration", 10)
        HUD:PaintBar(8, x, y, width, height, colors, 1 - (diff / duration))
        draw.SimpleText("KNOCKED OUT", "KnockedOut", ScrW() / 2, y + 1, COLOR_WHITE, TEXT_ALIGN_CENTER)
    end)

    -- Show message indicating they can be revived
    local MAX_TRACE_LENGTH = math.sqrt(3) * 2 * 16384
    hook.Add("HUDDrawTargetID", "Boxer_KnockedOut_HUDDrawTargetID", function()
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
        if (not IsValid(ent)) or ent.NoTarget then return end

        local ragdolledPly = ent:GetNWEntity("BoxerRagdolledPly", nil)
        if not IsPlayer(ragdolledPly) then return end
        if not ragdolledPly:GetNWBool("BoxerKnockedOut", false) then return end
        ent.TargetIDHint = { name = "box_revive_placeholder" }
    end)

    hook.Add("TTTTargetIDEntityHintLabel", "Boxer_KnockedOut_TTTTargetIDEntityHintLabel", function(ent, cli, text, col)
        if text == "box_revive_placeholder" then
            return LANG.GetParamTranslation("box_revive", { usekey = Key("+use", "E") } ), COLOR_WHITE
        end
    end)
end