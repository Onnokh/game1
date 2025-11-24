local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Torch
local Torch = {}

---Create a new Torch entity (static 12x26 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the tree to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created tree entity
function Torch.create(x, y, world, physicsWorld)

    local torch = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('torch', 12, 26)
    local pathfindingCollision = PathfindingCollision.new(12, 12, "static", 0, 14, "circle")

    torch:addComponent("Position", position)
    torch:addComponent("SpriteRenderer", spriteRenderer)
    torch:addComponent("PathfindingCollision", pathfindingCollision)
    torch:addComponent("GroundShadow", GroundShadow.new())
    torch:addComponent("Light", Light.new({
      { r = 240, g = 100, b = 20, radius = 6, offsetX = 6, offsetY = 4, flicker = true }
    }))

    -- Tag for easy querying
    torch:addTag("Torch")

    if world then
        world:addEntity(torch)
    end

    return torch
end

return Torch
