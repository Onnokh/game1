local System = require("src.core.System")
local Coin = require("src.entities.Coin")
local EventBus = require("src.utils.EventBus")

---@class LootSystem : System
---@field physicsWorld love.World|nil
local LootSystem = System:extend("LootSystem", {"DropTable", "Position"})

---Create a new LootSystem
---@param physicsWorld love.World|nil The physics world for creating coin colliders
---@return LootSystem
function LootSystem.new(physicsWorld)
    ---@class LootSystem
    local self = System.new({"DropTable", "Position"})
    setmetatable(self, LootSystem)
    self.physicsWorld = physicsWorld

    -- Subscribe to entityDespawned events to spawn loot after death animation completes
    EventBus.subscribe("entityDropLoot", function(payload)
        self:onEntityDropLoot(payload)
    end)

    return self
end

---Handle entity despawn events (post-death, after animation)
---@param payload table Event payload containing entity
function LootSystem:onEntityDropLoot(payload)
    local entity = payload.entity
    if not entity then return end
    local dropTable = entity:getComponent("DropTable")
    local position = entity:getComponent("Position")

    if dropTable and position and not entity.hasDroppedLoot then
        self:dropLoot(entity, dropTable, position)
        entity.hasDroppedLoot = true
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
            -- Drop coins with momentum - they fly out from the dead entityaw
            for i = 1, drop.amount do
                -- Calculate random direction and distance for positioning
                local angle = math.random() * 2 * math.pi -- Random angle in radians
                local distance = math.random(0, 4) -- Distance from entity center

                -- Base spawn position: center of PathfindingCollision if available; otherwise use Position
                local baseX, baseY = position.x, position.y
                local pcol = entity:getComponent("PathfindingCollision")
                if pcol and pcol.hasCollider and pcol.getCenterPosition then
                    if pcol:hasCollider() then
                        baseX, baseY = pcol:getCenterPosition()
                    end
                end

                -- Calculate spawn position
                local coinX = baseX + math.cos(angle) * distance
                local coinY = baseY + math.sin(angle) * distance

                -- Calculate velocity to make coins fly out (with some randomness)
                local baseSpeed = math.random(5, 15) -- Base speed range (reduced from 80-150)
                local speedVariation = math.random(-10, 10) -- Add some randomness (reduced from -20, 20)
                local finalSpeed = baseSpeed + speedVariation

                local velocityX = math.cos(angle) * finalSpeed
                local velocityY = math.sin(angle) * finalSpeed

                -- Create coin entity with momentum
                local world = entity._world
                if world then
                    Coin.create(coinX, coinY, 1, world, self.physicsWorld, velocityX, velocityY)
                end
            end
        end
    end
end

return LootSystem
