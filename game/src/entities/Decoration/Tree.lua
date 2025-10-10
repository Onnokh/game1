local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Tree
local Tree = {}

---Create a new Tree entity (static 48x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the tree to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created tree entity
function Tree.create(x, y, world, physicsWorld)

    local tree = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('tree', 48, 96)
    local pathfindingCollision = PathfindingCollision.new(12, 12, "static", 18, 84, "circle")

    tree:addComponent("Position", position)
    tree:addComponent("SpriteRenderer", spriteRenderer)
    tree:addComponent("PathfindingCollision", pathfindingCollision)
    tree:addComponent("GroundShadow", GroundShadow.new({ alpha = .5, widthFactor = 1.3, heightFactor = .5, offsetY = 0 }))

    tree:addComponent("Light", Light.new({
      { r = 100, g = 150, b = 255, radius = 15, offsetX = 32, offsetY = 20, flicker = true },
      { r = 100, g = 150, b = 255, radius = 15, offsetX = 15, offsetY = 30, flicker = true },
      { r = 100, g = 150, b = 255, radius = 15, offsetX = 32, offsetY = 54, flicker = true }
  }))

    -- Tag for easy querying
    tree:addTag("Tree")

    if world then
        world:addEntity(tree)
    end

    return tree
end

return Tree
