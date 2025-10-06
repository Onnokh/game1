---@class DropTable
---@field drops table Array of drop entries with item, min, max, and chance
local DropTable = {}
DropTable.__index = DropTable

---Create a new DropTable component
---@param drops table|nil Array of drop entries, each with {item, min, max, chance}
---@return Component|DropTable
function DropTable.new(drops)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("DropTable"), DropTable)

    -- Default drops if none provided
    self.drops = drops or {}

    return self
end

---Add a drop entry to the drop table
---@param item string The item type to drop
---@param minAmount number Minimum amount to drop
---@param maxAmount number Maximum amount to drop
---@param chance number Drop chance (0-1, where 1 = 100%)
function DropTable:addDrop(item, minAmount, maxAmount, chance)
    table.insert(self.drops, {
        item = item,
        min = minAmount,
        max = maxAmount,
        chance = chance
    })
end

---Generate loot drops based on the drop table
---@return table Array of drop results with {item, amount}
function DropTable:generateDrops()
    local results = {}

    for _, drop in ipairs(self.drops) do
        -- Check if this drop should occur based on chance
        if math.random() <= drop.chance then
            -- Generate random amount between min and max
            local amount = math.random(drop.min, drop.max)
            if amount > 0 then
                table.insert(results, {
                    item = drop.item,
                    amount = amount
                })
            end
        end
    end

    return results
end

---Clear all drops from the drop table
function DropTable:clearDrops()
    self.drops = {}
end

---Get the number of drop entries
---@return number Number of drop entries
function DropTable:getDropCount()
    return #self.drops
end

---Get a specific drop entry by index
---@param index number Index of the drop entry
---@return table|nil The drop entry or nil if index is invalid
function DropTable:getDrop(index)
    return self.drops[index]
end

return DropTable
