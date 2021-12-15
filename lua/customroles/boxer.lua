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

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()

    CreateConVar("ttt_boxer_drop_chance", "0.33", FCVAR_NONE, "Percent chance a punched player will drop weapon", 0.0, 1.0)
    local knockout_duration = CreateConVar("ttt_boxer_knockout_duration", "10", FCVAR_NONE, "Time punched player should be knocked down", 1, 60)

    local plymeta = FindMetaTable("Player")
    function plymeta:BoxerKnockout()
        if IsValid(self.boxerRagdoll) then return end

        self:SetNWBool("BoxerKnockedOut", true)
        self:SelectWeapon("weapon_ttt_unarmed")

        -- TODO: Dizzy effect
        -- TODO: Knockout sound

        -- Create ragdoll and lock their view
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll.ragdolledPly = self
        ragdoll.playerHealth = self:Health()
        -- Don't let the red matter bomb destroy this ragdoll
        ragdoll.WYOZIBHDontEat = true

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

        self.boxerRagdoll = ragdoll
        self:Spectate(OBS_MODE_CHASE)
        self:SpectateEntity(ragdoll)

        -- The diguiser stays in their hand so hide it from view
        self:DrawViewModel(false)
        self:DrawWorldModel(false)

        -- Timer to revive
        timer.Create("BoxerKnockout_" .. self:SteamID64(), knockout_duration:GetInt(), 1, function()
            if not self:GetNWBool("BoxerKnockedOut", false) then return end
            self:BoxerRevive()
        end)
    end

    function plymeta:BoxerRevive()
        if not IsValid(self.boxerRagdoll) then return end

        self:SetNWBool("BoxerKnockedOut", false)

        -- Unragdoll
        self:SpectateEntity(nil)
        self:UnSpectate()
        self:SetParent()
        self:Spawn()
        self:SetPos(self.boxerRagdoll:GetPos())
        self:SetVelocity(self.boxerRagdoll:GetVelocity())
        local yaw = self.boxerRagdoll:GetAngles().yaw
		self:SetAngles(Angle(0, yaw, 0))
        self:SetModel(self.boxerRagdoll:GetModel())

        -- Let weapons be seen again
        self:DrawViewModel(true)
        self:DrawWorldModel(true)

        local newhealth = self.boxerRagdoll.playerHealth
        if newhealth <= 0 then
            newhealth = 1
        end
        self:SetHealth(newhealth)
        SetRoleMaxHealth(self)

        SafeRemoveEntity(self.boxerRagdoll)
        self.boxerRagdoll = nil
    end

    local function TransferRagdollDamage(rag, dmginfo)
        if not IsRagdoll(rag) then return end
        local ply = rag.ragdolledPly
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
            ply = ent.ragdolledPly
        elseif IsPlayer(ent) then
            ply = ent
            rag = ply.boxerRagdoll
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
            timer.Remove("BoxerKnockout_" .. v:SteamID64())
        end
    end)
end

if CLIENT then
    -- TODO: Knocked out progress bar
    -- TODO: "Press E to revive" for knocked out players
end