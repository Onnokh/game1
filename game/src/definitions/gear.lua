---@class GearDefinition
---@field id string Unique identifier for the gear
---@field name string Display name
---@field description string Gear description
---@field type string Item type ("gear")
---@field slot string Equipment slot (e.g., "boots", "ring", "helm")
---@field cost number Purchase cost in coins
---@field spriteSheet string Sprite sheet name
---@field spriteFrame number Frame index in sprite sheet

---Table of all equippable gear definitions
---@type table<string, GearDefinition>
local gear = {
    speed_boots = {
        id = "speed_boots",
        name = "Speed Boots",
        description = "Increases movement speed by 20%",
        type = "gear",
        slot = "boots",
        cost = 150,
        spriteSheet = "items",
        spriteFrame = 131  -- Row 9, Col 3
    },
    strength_ring = {
        id = "strength_ring",
        name = "Strength Ring",
        description = "Increases attack damage by 15%",
        type = "gear",
        slot = "ring",
        cost = 200,
        spriteSheet = "items",
        spriteFrame = 133  -- Row 10, Col 1
    },
    iron_helm = {
        id = "iron_helm",
        name = "Iron Helm",
        description = "Reduces incoming damage by 10%",
        type = "gear",
        slot = "helm",
        cost = 175,
        spriteSheet = "items",
        spriteFrame = 114  -- Row 10, Col 1
    },
    lucky_charm = {
        id = "lucky_charm",
        name = "Lucky Charm",
        description = "Increases coin drop rate by 25%",
        type = "gear",
        slot = "ring",
        cost = 125,
        spriteSheet = "items",
        spriteFrame = 177  -- Row 10, Col 1
    }
}

---Get a gear definition by ID
---@param id string Gear ID
---@return GearDefinition|nil
local function getGear(id)
    return gear[id]
end

---Get all gear definitions
---@return table<string, GearDefinition>
local function getAllGear()
    return gear
end

return {
    gear = gear,
    getGear = getGear,
    getAllGear = getAllGear
}

