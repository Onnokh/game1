local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Mailbox
local Mailbox = {}

---Create a new Mailbox entity (static 21x28 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the mailbox to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created mailbox entity
function Mailbox.create(x, y, world, physicsWorld)

    local mailbox = Entity.new()
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('mailbox', 21, 28)
    local pathfindingCollision = PathfindingCollision.new(10, 10, "static", 5, 18, "circle")

    mailbox:addComponent("Position", position)
    mailbox:addComponent("SpriteRenderer", spriteRenderer)
    mailbox:addComponent("PathfindingCollision", pathfindingCollision)
    mailbox:addComponent("GroundShadow", GroundShadow.new())

    -- Tag for easy querying
    mailbox:addTag("Mailbox")

    if world then
        world:addEntity(mailbox)
    end

    return mailbox
end

return Mailbox

