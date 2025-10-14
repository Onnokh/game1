---@class Inventory
---@field items table Array of inventory entries {id = string, amount = number}
local Inventory = {}
Inventory.__index = Inventory

---Create a new Inventory component
---@return Component|Inventory
function Inventory.new()
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Inventory"), Inventory)

    self.items = {} -- Array of {id = "item_id", amount = number}

    return self
end

---Add an item to the inventory (stacks if already exists)
---@param itemId string The item ID to add
---@param amount number Amount to add (default 1)
---@return boolean True if item was added successfully
function Inventory:addItem(itemId, amount)
    amount = amount or 1

    if not itemId or amount <= 0 then
        print("[Inventory] Invalid item or amount")
        return false
    end

    -- Check if item already exists in inventory
    for _, entry in ipairs(self.items) do
        if entry.id == itemId then
            entry.amount = entry.amount + amount
            print(string.format("[Inventory] Added %dx %s (now have %d)", amount, itemId, entry.amount))
            return true
        end
    end

    -- Item doesn't exist, add new entry
    table.insert(self.items, {
        id = itemId,
        amount = amount
    })
    print(string.format("[Inventory] Added %dx %s (new item)", amount, itemId))
    return true
end

---Remove an item from the inventory
---@param itemId string The item ID to remove
---@param amount number Amount to remove (default 1)
---@return boolean True if item was removed successfully
function Inventory:removeItem(itemId, amount)
    amount = amount or 1

    if not itemId or amount <= 0 then
        print("[Inventory] Invalid item or amount")
        return false
    end

    -- Find the item in inventory
    for i, entry in ipairs(self.items) do
        if entry.id == itemId then
            if entry.amount >= amount then
                entry.amount = entry.amount - amount
                print(string.format("[Inventory] Removed %dx %s (now have %d)", amount, itemId, entry.amount))

                -- Remove entry if amount reaches 0
                if entry.amount <= 0 then
                    table.remove(self.items, i)
                    print(string.format("[Inventory] %s depleted, removed from inventory", itemId))
                end
                return true
            else
                print(string.format("[Inventory] Not enough %s (have %d, need %d)", itemId, entry.amount, amount))
                return false
            end
        end
    end

    print(string.format("[Inventory] Item %s not found in inventory", itemId))
    return false
end

---Check if the inventory has an item
---@param itemId string The item ID to check
---@return boolean True if item exists in inventory
---@return number Amount of the item (0 if not found)
function Inventory:hasItem(itemId)
    for _, entry in ipairs(self.items) do
        if entry.id == itemId then
            return true, entry.amount
        end
    end
    return false, 0
end

---Get an item entry from the inventory
---@param itemId string The item ID to get
---@return table|nil The item entry {id, amount} or nil if not found
function Inventory:getItem(itemId)
    for _, entry in ipairs(self.items) do
        if entry.id == itemId then
            return entry
        end
    end
    return nil
end

---Get all items in the inventory
---@return table Array of item entries {id, amount}
function Inventory:getAll()
    return self.items
end

---Get the number of different items in the inventory
---@return number Number of unique items
function Inventory:getItemCount()
    return #self.items
end

---Clear the entire inventory
function Inventory:clear()
    self.items = {}
    print("[Inventory] Cleared all items")
end

return Inventory

