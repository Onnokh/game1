local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Barrel
local Barrel = {}

---Create a new Barrel entity (static 12x26 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the barrel to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created barrel entity
function Barrel.create(x, y, world, physicsWorld)

    local barrel = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('barrel', 16, 24)
    local pathfindingCollision = PathfindingCollision.new(14, 14, "static", 1, 12, "circle")

    barrel:addComponent("Position", position)
    barrel:addComponent("SpriteRenderer", spriteRenderer)
    barrel:addComponent("PathfindingCollision", pathfindingCollision)
    barrel:addComponent("GroundShadow", GroundShadow.new())

    -- Tag for easy querying
    barrel:addTag("Barrel")

    if world then
        world:addEntity(barrel)
    end

    return barrel
end

return Barrel
