local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Inn
local Inn = {}

---Create a new Inn entity (static 280x240 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the inn to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created inn entity
function Inn.create(x, y, world, physicsWorld)

    local inn = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('inn', 280, 240)
    local pathfindingCollision = PathfindingCollision.new(160, 160, "static", 60, 120, "circle")

    inn:addComponent("Position", position)
    inn:addComponent("SpriteRenderer", spriteRenderer)
    inn:addComponent("PathfindingCollision", pathfindingCollision)
    inn:addComponent("GroundShadow", GroundShadow.new())

    -- Tag for easy querying
    inn:addTag("Inn")

    if world then
        world:addEntity(inn)
    end

    return inn
end

return Inn

