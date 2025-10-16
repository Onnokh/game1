---@class UpgradeDefinition
---@field id string Unique identifier for the upgrade
---@field name string Display name
---@field description string Upgrade description
---@field targetPath string Path to stat (e.g., "Movement.maxSpeed")
---@field modifierType string "multiply" or "add"
---@field modifierValue number Value to apply per rank
---@field maxRank number Maximum number of times this can be upgraded
---@field spriteSheet string Sprite sheet name
---@field spriteFrame number Frame index in sprite sheet

---Table of all upgrade definitions
---@type table<string, UpgradeDefinition>
local upgrades = {
    movement_speed = {
        id = "movement_speed",
        name = "Movement Speed",
        description = "+20% movement speed",
        targetPath = "Movement.maxSpeed",
        modifierType = "multiply",
        modifierValue = 1.2, -- 20% increase
        maxRank = 5,
        spriteSheet = "items",
        spriteFrame = 147  -- Speed potion sprite
    },

    max_health = {
        id = "max_health",
        name = "Max Health",
        description = "+15 max health",
        targetPath = "Health.max",
        modifierType = "add",
        modifierValue = 15, -- 15 increase
        maxRank = 5,
        spriteSheet = "items",
        spriteFrame = 145  -- Health potion sprite
    },

    ranged_damage = {
        id = "ranged_damage",
        name = "Ranged Damage",
        description = "+5 ranged damage",
        targetPath = "Weapon.inventory.ranged.damage",
        modifierType = "add",
        modifierValue = 5, -- 5 increase
        maxRank = 5,
        spriteSheet = "items",
        spriteFrame = 148  -- Rage potion sprite
    },

    melee_damage = {
        id = "melee_damage",
        name = "Melee Damage",
        description = "+25% melee damage",
        targetPath = "Weapon.inventory.melee.damage",
        modifierType = "multiply",
        modifierValue = 1.25, -- 25% increase
        maxRank = 5,
        spriteSheet = "items",
        spriteFrame = 148  -- Rage potion sprite (reusing)
    },

    dash_charges = {
        id = "dash_charges",
        name = "Dash Charges",
        description = "+1 dash charge",
        targetPath = "DashCharges.maxCharges",
        modifierType = "add",
        modifierValue = 1, -- Add 1 charge
        maxRank = 2, -- Can upgrade twice (1 -> 2 -> 3)
        spriteSheet = "items",
        spriteFrame = 147  -- Speed potion sprite (reusing)
    }
}

---Get an upgrade definition by ID
---@param id string Upgrade ID
---@return UpgradeDefinition|nil
local function getUpgrade(id)
    return upgrades[id]
end

---Get all upgrade definitions
---@return table<string, UpgradeDefinition>
local function getAllUpgrades()
    return upgrades
end

return {
    upgrades = upgrades,
    getUpgrade = getUpgrade,
    getAllUpgrades = getAllUpgrades
}

