---Table of all ability definitions
---@type table<string, AbilityData>
local abilities = {
    lightningbolt = {
        id = "lightningbolt",
        name = "Lightning Bolt",
        description = "A powerful ranged attack that deals 16 damage.",
        type = "ranged",
        damage = 16,
        range = 300,
        cooldown = 0,
        castTime = 1.5,
        mana = 0,
        movementCancelsCast = false,
        knockback = 1,
        projectile = {
            type = "moving",
            sprite = "lightningbolt-projectile",
            speed = 350,
            lifetime_seconds = 3,
            scale = 1
        },
        piercing = false,
        icon = "resources/classes/shaman/abilities/lightning-bolt/lightningbolt.png",
        sound = "lightningbolt",
        -- Example onCast hook: Apply a buff to the player when casting
        -- This demonstrates how to use hooks to modify the caster
        -- onCast = function(caster, abilityData)
        --     local modifier = caster:getComponent("Modifier")
        --     if modifier then
        --         -- Example: Increase movement speed by 20% for 5 seconds
        --         -- Note: In a real implementation, you'd want to remove this after the duration
        --         modifier:apply(caster, "Movement.maxSpeed", "multiply", 1.2, "lightningbolt_buff")
        --         print("[Lightning Bolt] Applied speed buff to caster")
        --     end
        -- end,
    },
    flameshock = {
        id = "flameshock",
        name = "Flame Shock",
        description = "A fiery ranged attack that deals 24 damage.",
        type = "ranged",
        damage = 24,
        range = 300,
        cooldown = 1,
        castTime = 0,
        mana = 15,
        movementCancelsCast = false,
        knockback = 1,
        projectile = {
            type = "instant",
            sprite = "flameshock-projectile",
        },
        piercing = false,
        icon = "resources/classes/shaman/abilities/flame-shock/flameshock.png",
        sound = "flameshock",
        -- Example onHit hook: Set all hit targets ablaze
        -- This demonstrates how to use hooks to modify hit targets
        -- onHit = function(target, caster, abilityData)
        --     -- Example: Apply a damage-over-time effect or status
        --     -- In a real implementation, you might add a component or tag to track the "ablaze" status
        --     local modifier = target:getComponent("Modifier")
        --     if modifier then
        --         -- Example: Reduce target's movement speed by 30% for 3 seconds (simulating being on fire)
        --         modifier:apply(target, "Movement.maxSpeed", "multiply", 0.7, "flameshock_ablaze")
        --         print(string.format("[Flame Shock] Set target %d ablaze", target.id))
        --     end
        -- end,
    }
}

---Get an ability definition by ID
---@param id string Ability ID
---@return AbilityData|nil
local function getAbility(id)
    return abilities[id]
end

---Get all ability definitions (returns reference to immutable definitions)
---@return table<string, AbilityData>
local function getAllAbilities()
    return abilities
end

return {
    abilities = abilities,
    getAbility = getAbility,
    getAllAbilities = getAllAbilities
}

