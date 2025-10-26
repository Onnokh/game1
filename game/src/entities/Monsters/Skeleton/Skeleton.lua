local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
local MonsterFactory = require("src.entities.Monsters.core.MonsterFactory")
local SkeletonChasing = require("src.entities.Monsters.Skeleton.states.Chasing")
local SkeletonAttacking = require("src.entities.Monsters.Skeleton.states.Attacking")

---@class Skeleton
local Skeleton = {}

---Create a new skeleton enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the skeleton to
---@param physicsWorld table|nil The physics world for collision
---@param isElite boolean|nil Whether this skeleton should be an elite variant
---@return Entity The created skeleton entity
function Skeleton.create(x, y, world, physicsWorld, isElite)
    return MonsterFactory.create({
        x = x,
        y = y,
        world = world,
        physicsWorld = physicsWorld,
        config = SkeletonConfig,
        tag = "Skeleton",
        isElite = isElite or false,

        -- Use custom states for ranged behavior
        customStates = {
            chasing = SkeletonChasing.new(),
            attacking = SkeletonAttacking.new()
        }
    })
end

return Skeleton
