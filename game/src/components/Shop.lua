---@class Shop
---@field inventory table Array of items for sale (max 3 items)
---@field maxItems number Maximum number of items (default 3)
local Shop = {}
Shop.__index = Shop

---Create a new Shop component
---@param inventory table|nil Optional custom inventory (array of item tables)
---@return Component|Shop
function Shop.new(inventory)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Shop"), Shop)

    self.maxItems = 3

    -- Use custom inventory or default placeholder items
    self.inventory = inventory or {
        {
            name = "Health Potion",
            cost = 50,
            description = "Restores 50 health"
        },
        {
            name = "Speed Boost",
            cost = 75,
            description = "Increases movement speed for 30 seconds"
        },
        {
            name = "Damage Up",
            cost = 100,
            description = "Increases damage dealt by 25%"
        }
    }

    return self
end

---Add an item to the shop's inventory
---@param item table Item table with name, cost, and optional description
---@return boolean True if item was added successfully
function Shop:addItem(item)
    if #self.inventory >= self.maxItems then
        print("[Shop] Cannot add item: inventory is full")
        return false
    end

    if not item.name or not item.cost then
        print("[Shop] Cannot add item: missing name or cost")
        return false
    end

    table.insert(self.inventory, item)
    return true
end

---Remove an item from the shop's inventory by index
---@param index number Index of the item to remove (1-based)
---@return table|nil The removed item, or nil if index is invalid
function Shop:removeItem(index)
    if index < 1 or index > #self.inventory then
        print("[Shop] Cannot remove item: invalid index")
        return nil
    end

    return table.remove(self.inventory, index)
end

---Get the shop's inventory
---@return table Array of items
function Shop:getInventory()
    return self.inventory
end

---Check if the shop has an item with the given name
---@param name string Name of the item to search for
---@return boolean True if item exists
---@return number|nil Index of the item if found
function Shop:hasItem(name)
    for i, item in ipairs(self.inventory) do
        if item.name == name then
            return true, i
        end
    end
    return false, nil
end

---Get an item by index
---@param index number Index of the item (1-based)
---@return table|nil The item, or nil if index is invalid
function Shop:getItem(index)
    if index < 1 or index > #self.inventory then
        return nil
    end
    return self.inventory[index]
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
---@return table|nil The purchased item info, or nil if purchase failed
function Shop:purchaseItem(index)
    if index < 1 or index > #self.inventory then
        print("[Shop] Cannot purchase: invalid index")
        return nil
    end

    local item = self.inventory[index]
    if not item then
        print("[Shop] Cannot purchase: item already sold")
        return nil
    end

    -- Remove item from inventory (set to nil)
    self.inventory[index] = nil

    print(string.format("[Shop] Purchased '%s' for %d coins", item.name, item.cost))

    return item
end

return Shop

