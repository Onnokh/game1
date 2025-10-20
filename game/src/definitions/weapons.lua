---Table of all weapon definitions
---@type table<string, WeaponData>
local weapons = {
    melee = {
        id = "melee",
        name = "Sword",
        type = "melee",
        damage = 12,
        range = 30,
        cooldown = 0.5,
        knockback = 6
    },
    ranged = {
        id = "ranged",
        name = "Gun",
        type = "ranged",
        damage = 8,
        range = 300,
        cooldown = 0.15,
        knockback = 1,
        recoilKnockback = 0.01,
        bulletSpeed = 350,
        bulletLifetime = 3,
        piercing = false,
        glowColor = {1.0, 0.85, 0.6}
    }
}

---Get a weapon definition by ID
---@param id string Weapon ID
---@return WeaponData|nil
local function getWeapon(id)
    return weapons[id]
end

---Get all weapon definitions (returns reference to immutable definitions)
---@return table<string, WeaponData>
local function getAllWeapons()
    return weapons
end

return {
    weapons = weapons,
    getWeapon = getWeapon,
    getAllWeapons = getAllWeapons
}

