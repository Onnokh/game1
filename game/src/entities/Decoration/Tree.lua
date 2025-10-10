local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")

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
    local spriteRenderer = SpriteRenderer.new('tree', 48, 80)
    local pathfindingCollision = PathfindingCollision.new(12, 12, "static", 18, 68, "circle")

    tree:addComponent("Position", position)
    tree:addComponent("SpriteRenderer", spriteRenderer)
    tree:addComponent("PathfindingCollision", pathfindingCollision)
    tree:addComponent("GroundShadow", GroundShadow.new({ alpha = .5, widthFactor = 1, heightFactor = 1, offsetY = -4 }))

    -- Tag for easy querying
    tree:addTag("Tree")

    if world then
        world:addEntity(tree)
    end

    return tree
end

return Tree
