local System = require("src.core.System")
local Coin = require("src.entities.Coin")

---@class LootSystem : System
local LootSystem = System:extend("LootSystem", {"DropTable", "Position"})

---Create a new LootSystem
---@return LootSystem
function LootSystem.new()
    local self = System.new({"DropTable", "Position"})
    setmetatable(self, LootSystem)
    return self
end

---Update the loot system
---@param dt number Delta time
function LootSystem:update(dt)
    -- Process entities that have died and have drop tables
    for _, entity in ipairs(self.entities) do
        local health = entity:getComponent("Health")
        local dropTable = entity:getComponent("DropTable")
        local position = entity:getComponent("Position")

        -- Check if entity has died and hasn't already dropped loot
        if health and health.isDead and dropTable and position and not entity.hasDroppedLoot then
            self:dropLoot(entity, dropTable, position)
            entity.hasDroppedLoot = true -- Mark as having dropped loot
        end
    end
end

---Drop loot for a dead entity
---@param entity Entity The entity that died
---@param dropTable DropTable The drop table component
---@param position Position The position component
function LootSystem:dropLoot(entity, dropTable, position)
    local drops = dropTable:generateDrops()

    for _, drop in ipairs(drops) do
        if drop.item == "coin" and drop.amount > 0 then
            -- Drop coins with slight random offset to spread them out
            for i = 1, drop.amount do
                local offsetX = (math.random() - 0.5) * 32 -- Random offset within 32 pixels
                local offsetY = (math.random() - 0.5) * 32

                local coinX = position.x + offsetX
                local coinY = position.y + offsetY

                -- Create coin entity
                local world = entity._world
                if world then
                    Coin.create(coinX, coinY, 1, world, world.physicsWorld)
                end
            end
        end
        -- Add other item types here as needed
    end
end

return LootSystem
