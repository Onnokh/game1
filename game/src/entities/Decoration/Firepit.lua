local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Firepit
local Firepit = {}

---Create a new Firepit entity (static 112x48 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the firepit to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created firepit entity
function Firepit.create(x, y, world, physicsWorld)

    local firepit = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('firepit', 112, 48)
    local pathfindingCollision = PathfindingCollision.new(80, 30, "static", 16, 18, "rectangle")

    firepit:addComponent("Position", position)
    firepit:addComponent("SpriteRenderer", spriteRenderer)
    firepit:addComponent("PathfindingCollision", pathfindingCollision)
    -- firepit:addComponent("GroundShadow", GroundShadow.new())
    -- firepit:addComponent("Light", Light.new({
    --   { r = 240, g = 100, b = 20, radius = 10, offsetX = 56, offsetY = 24, flicker = true }
    -- }))

    -- Tag for easy querying
    firepit:addTag("Firepit")

    if world then
        world:addEntity(firepit)
    end

    return firepit
end

return Firepit

