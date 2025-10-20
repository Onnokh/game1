local System = require("src.core.System")
local InventoryDisplay = require("src.ui.InventoryDisplay")
local itemsModule = require("src.definitions.items")
local gearModule = require("src.definitions.gear")

---@class InventoryDisplaySystem : System
local InventoryDisplaySystem = System:extend("InventoryDisplaySystem", {})

---Create a new InventoryDisplaySystem
---@param ecsWorld World The ECS world
---@return InventoryDisplaySystem
function InventoryDisplaySystem.new(ecsWorld)
    ---@class InventoryDisplaySystem
    local self = System.new()
    setmetatable(self, InventoryDisplaySystem)

    self.ecsWorld = ecsWorld

    -- Create the inventory display UI element anchored bottom-left
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 32
    self.inventoryDisplay = InventoryDisplay.new(margin, screenH - margin) -- 32px from bottom-left corner

    return self
end

---Get item definition by ID
---@param itemId string The item ID
---@return table|nil Item or gear definition
function InventoryDisplaySystem:getItemDefinition(itemId)
    -- Check items first
    local item = itemsModule.getItem(itemId)
    if item then
        return item
    end

    -- Check gear
    local gear = gearModule.getGear(itemId)
    if gear then
        return gear
    end

    return nil
end

---Update the inventory display system
---@param dt number Delta time
function InventoryDisplaySystem:update(dt)
    -- Get player entity
    local player = self.ecsWorld:getPlayer()
    if not player then
        self.inventoryDisplay:updateItems({})
        return
    end

    -- Get player's inventory component
    local inventory = player:getComponent("Inventory")
    if not inventory then
        self.inventoryDisplay:updateItems({})
        return
    end

    -- Get all inventory items and resolve their names
    local inventoryItems = inventory:getAll()
    local displayItems = {}

    for _, entry in ipairs(inventoryItems) do
        local itemDef = self:getItemDefinition(entry.id)
        if itemDef then
            table.insert(displayItems, {
                id = entry.id,
                name = itemDef.name,
                amount = entry.amount
            })
        else
            -- Fallback if definition not found
            table.insert(displayItems, {
                id = entry.id,
                name = entry.id, -- Use ID as name if definition not found
                amount = entry.amount
            })
        end
    end

    -- Update the display
    self.inventoryDisplay:updateItems(displayItems)
end

---Draw the inventory display
function InventoryDisplaySystem:draw()
    self.inventoryDisplay:draw()
end

return InventoryDisplaySystem

