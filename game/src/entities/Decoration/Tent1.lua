local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Tent1
local Tent1 = {}

---Create a new Tent1 entity (static 88x72 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the tent to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created tent entity
function Tent1.create(x, y, world, physicsWorld)

    local tent = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('tent1', 88, 72)
    local pathfindingCollision = PathfindingCollision.new(60, 50, "static", 14, 22, "rectangle")

    tent:addComponent("Position", position)
    tent:addComponent("SpriteRenderer", spriteRenderer)
    tent:addComponent("PathfindingCollision", pathfindingCollision)
    tent:addComponent("GroundShadow", GroundShadow.new())

    -- Tag for easy querying
    tent:addTag("Tent1")

    if world then
        world:addEntity(tent)
    end

    return tent
end

return Tent1

