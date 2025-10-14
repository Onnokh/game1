---@class ItemDefinition
---@field id string Unique identifier for the item
---@field name string Display name
---@field description string Item description
---@field type string Item type ("item")
---@field cost number Purchase cost in coins
---@field spriteSheet string Sprite sheet name
---@field spriteFrame number Frame index in sprite sheet

---Table of all single-use item definitions
---@type table<string, ItemDefinition>
local items = {
    health_potion = {
        id = "health_potion",
        name = "Health Potion",
        description = "Restores 50 health",
        type = "item",
        cost = 5,
        spriteSheet = "items",
        spriteFrame = 145  -- Row 10, Col 1
    },
    speed_potion = {
        id = "speed_potion",
        name = "Speed Potion",
        description = "Increases movement speed for 30 seconds",
        type = "item",
        cost = 5,
        spriteSheet = "items",
        spriteFrame = 147  -- Row 10, Col 3
    },
    rage_potion = {
        id = "rage_potion",
        name = "Rage Potion",
        description = "Increases damage dealt by 25% for 20 seconds",
        type = "item",
        cost = 5,
        spriteSheet = "items",
        spriteFrame = 148  -- Row 10, Col 4
    }
}

---Get an item definition by ID
---@param id string Item ID
---@return ItemDefinition|nil
local function getItem(id)
    return items[id]
end

---Get all item definitions
---@return table<string, ItemDefinition>
local function getAllItems()
    return items
end

return {
    items = items,
    getItem = getItem,
    getAllItems = getAllItems
}

