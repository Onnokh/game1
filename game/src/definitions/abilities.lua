---Table of all ability definitions
---@type table<string, AbilityData>
local abilities = {
    ranged = {
        id = "ranged",
        name = "Lightning Bolt",
        type = "ranged",
        damage = 16,
        range = 300,
        cooldown = 0,
        castTime = 1.5,
        movementCancelsCast = false, -- Can cast while moving
        knockback = 1,
        recoilKnockback = 0.01,
        bulletSpeed = 350,
        bulletLifetime = 3,
        piercing = false,
        glowColor = {0.4, 0.6, 1.0}
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

