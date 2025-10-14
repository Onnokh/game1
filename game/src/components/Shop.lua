---@class Shop
---@field inventory table Array of item IDs for sale (max 3 items)
---@field maxItems number Maximum number of items (default 3)
local Shop = {}
Shop.__index = Shop

---Create a new Shop component
---@param inventory table|nil Optional custom inventory (array of item IDs as strings)
---@return Component|Shop
function Shop.new(inventory)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Shop"), Shop)

    self.maxItems = 3

    -- Use custom inventory or generate random items (2 items + 1 gear)
    if inventory then
        self.inventory = inventory
    else
        self.inventory = self:generateRandomInventory()
    end

    return self
end

---Generate a random inventory with 2 items and 1 gear piece
---@return table Array of 3 random item IDs
function Shop:generateRandomInventory()
    local itemsModule = require("src.definitions.items")
    local gearModule = require("src.definitions.gear")

    -- Get all available items and gear
    local allItems = {}
    local allGear = {}

    for id, _ in pairs(itemsModule.items) do
        table.insert(allItems, id)
    end

    for id, _ in pairs(gearModule.gear) do
        table.insert(allGear, id)
    end

    -- Randomly select 2 items
    local selectedItems = {}
    if #allItems >= 2 then
        -- Shuffle and pick first 2
        local itemsCopy = {}
        for _, id in ipairs(allItems) do
            table.insert(itemsCopy, id)
        end

        -- Fisher-Yates shuffle
        for i = #itemsCopy, 2, -1 do
            local j = math.random(i)
            itemsCopy[i], itemsCopy[j] = itemsCopy[j], itemsCopy[i]
        end

        selectedItems[1] = itemsCopy[1]
        selectedItems[2] = itemsCopy[2]
    end

    -- Randomly select 1 gear
    local selectedGear = nil
    if #allGear >= 1 then
        selectedGear = allGear[math.random(#allGear)]
    end

    -- Combine into inventory (2 items + 1 gear)
    local inventory = {
        selectedItems[1] or "health_potion",
        selectedItems[2] or "speed_potion",
        selectedGear or "speed_boots"
    }

    print(string.format("[Shop] Generated inventory: %s, %s, %s",
        inventory[1], inventory[2], inventory[3]))

    return inventory
end

---Get item definition from definitions (items.lua or gear.lua)
---@param itemId string The item ID
---@return table|nil Item definition with name, cost, description, etc.
function Shop:getItemDefinition(itemId)
    if not itemId then
        return nil
    end

    local itemsModule = require("src.definitions.items")
    local gearModule = require("src.definitions.gear")

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

---Add an item to the shop's inventory
---@param itemId string Item ID to add
---@return boolean True if item was added successfully
function Shop:addItem(itemId)
    if #self.inventory >= self.maxItems then
        print("[Shop] Cannot add item: inventory is full")
        return false
    end

    if not itemId then
        print("[Shop] Cannot add item: missing item ID")
        return false
    end

    -- Verify item exists in definitions
    local itemDef = self:getItemDefinition(itemId)
    if not itemDef then
        print("[Shop] Cannot add item: item ID not found in definitions: " .. itemId)
        return false
    end

    table.insert(self.inventory, itemId)
    return true
end

---Remove an item from the shop's inventory by index
---@param index number Index of the item to remove (1-based)
---@return string|nil The removed item ID, or nil if index is invalid
function Shop:removeItem(index)
    if index < 1 or index > #self.inventory then
        print("[Shop] Cannot remove item: invalid index")
        return nil
    end

    return table.remove(self.inventory, index)
end

---Get the shop's inventory (array of item IDs)
---@return table Array of item IDs
function Shop:getInventory()
    return self.inventory
end

---Check if the shop has an item with the given ID
---@param itemId string Item ID to search for
---@return boolean True if item exists
---@return number|nil Index of the item if found
function Shop:hasItem(itemId)
    for i, id in ipairs(self.inventory) do
        if id == itemId then
            return true, i
        end
    end
    return false, nil
end

---Get an item by index (returns the full definition, not just ID)
---@param index number Index of the item (1-based)
---@return table|nil The item definition, or nil if index is invalid
function Shop:getItem(index)
    if index < 1 or index > self.maxItems then
        return nil
    end

    local itemId = self.inventory[index]
    if not itemId then
        return nil
    end

    return self:getItemDefinition(itemId)
end

---Get the number of items in the shop
---@return number Number of items
function Shop:getItemCount()
    return #self.inventory
end

---Check if the shop is full
---@return boolean True if inventory is full
function Shop:isFull()
    return #self.inventory >= self.maxItems
end

---Clear all items from the shop
function Shop:clearInventory()
    self.inventory = {}
end

---Purchase an item from the shop by index
---@param index number Index of the item to purchase (1-based)
---@return table|nil The purchased item definition, or nil if purchase failed
function Shop:purchaseItem(index)
    if index < 1 or index > self.maxItems then
        print("[Shop] Cannot purchase: invalid index")
        return nil
    end

    local itemId = self.inventory[index]
    if not itemId then
        print("[Shop] Cannot purchase: item already sold")
        return nil
    end

    -- Get item definition before removing
    local itemDef = self:getItemDefinition(itemId)
    if not itemDef then
        print("[Shop] Cannot purchase: item definition not found for " .. itemId)
        return nil
    end

    -- Remove item from inventory (set to nil to keep positions)
    self.inventory[index] = nil

    print(string.format("[Shop] Purchased '%s' for %d coins", itemDef.name, itemDef.cost))

    return itemDef
end

---Serialize the Shop component for saving
---@return table Serialized shop data
function Shop:serialize()
    return {
        inventory = self.inventory,
        maxItems = self.maxItems
    }
end

---Deserialize Shop component from saved data
---@param data table Serialized shop data
---@return Shop Recreated Shop component
function Shop.deserialize(data)
    -- Pass saved inventory to constructor to prevent regeneration
    local shop = Shop.new(data.inventory)
    shop.maxItems = data.maxItems or 3
    return shop
end

return Shop

