---@class UpgradeDefinition
---@field id string Unique identifier for the upgrade
---@field name string Display name
---@field description string Upgrade description
---@field targetPath string Path to stat (e.g., "Movement.maxSpeed")
---@field modifierType string "multiply", "add", or "set"
---@field modifierValue number|boolean Value to apply per rank (number for add/multiply, boolean for set)
---@field maxRank number Maximum number of times this can be upgraded
---@field spriteSheet string Sprite sheet name
---@field spriteFrame number Frame index in sprite sheet

---Table of all upgrade definitions
---@type table<string, UpgradeDefinition>
local upgrades = {
    movement_speed = {
        id = "movement_speed",
        name = "Coffee",
        description = "+20% movement speed",
        targetPath = "Movement.maxSpeed",
        modifierType = "multiply",
        modifierValue = 1.2, -- 20% increase
        maxRank = 5,
        spriteSheet = "items",
        spriteFrame = 255  -- Speed potion sprite
    },

    max_health = {
        id = "max_health",
        name = "Apple",
        description = "+15 max health",
        targetPath = "Health.max",
        modifierType = "add",
        modifierValue = 15,
        maxRank = 5,
        spriteSheet = "items",
        spriteFrame = 225
    },
    dash_charges = {
        id = "dash_charges",
        name = "Dash",
        description = "+1 dash charge",
        targetPath = "DashCharges.maxCharges",
        modifierType = "add",
        modifierValue = 1, -- Add 1 charge
        maxRank = 2, -- Can upgrade twice (1 -> 2 -> 3)
        spriteSheet = "items",
        spriteFrame = 153
    },
    piercing = {
        id = "piercing",
        name = "Piercing Shots",
        description = "Bullets pierce through enemies",
        targetPath = "Weapon.inventory.ranged.piercing",
        modifierType = "set",
        modifierValue = true,
        maxRank = 1, -- Can only be taken once
        spriteSheet = "items",
        spriteFrame = 52
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

