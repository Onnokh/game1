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
        movementCancelsCast = false,
        knockback = 1,
        recoilKnockback = 0.01,
        projectileSpeed = 350,
        projectileLifetime = 3,
        piercing = false,
        projectile = "bullet",
        glowColor = {0.4, 0.6, 1.0},
        icon = "resources/abilities/lightningbolt.png",
        sound = "lightningbolt",
        manaCost = 0
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
        movementCancelsCast = false,
        knockback = 1,
        recoilKnockback = 0.01,
        projectileSpeed = 350,
        projectileLifetime = 3,
        piercing = false,
        projectile = "bullet",
        glowColor = {1.0, 0.4, 0.2},
        icon = "resources/abilities/flameshock.png",
        sound = "flameshock",
        manaCost = 15
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

