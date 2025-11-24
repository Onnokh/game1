local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Tree2
local Tree2 = {}

---Create a new Tree entity (static 48x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the tree to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created tree entity
function Tree2.create(x, y, world, physicsWorld)

    local tree = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('tree2', 40, 160)
    local pathfindingCollision = PathfindingCollision.new(12, 12, "static", 16, 148, "circle")

    tree:addComponent("Position", position)
    tree:addComponent("SpriteRenderer", spriteRenderer)
    tree:addComponent("PathfindingCollision", pathfindingCollision)
    tree:addComponent("GroundShadow", GroundShadow.new())

    -- Tag for easy querying
    tree:addTag("Tree")
    tree:addTag("FoliageSway")

    if world then
        world:addEntity(tree)
    end

    return tree
end

return Tree2
