local BearConfig = require("src.entities.Monsters.Bear.BearConfig")
local MonsterFactory = require("src.entities.Monsters.core.MonsterFactory")

---@class Bear
local Bear = {}

---Create a new bear enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the bear to
---@param physicsWorld table|nil The physics world for collision
---@param isElite boolean|nil Whether this bear should be an elite variant
---@return Entity The created bear entity
function Bear.create(x, y, world, physicsWorld, isElite)
    local entity = MonsterFactory.create({
        x = x,
        y = y,
        world = world,
        physicsWorld = physicsWorld,
        config = BearConfig,
        tag = "Bear",
        isElite = isElite or false,
        physicsOffsetX = BearConfig.SPRITE_WIDTH / 2 - BearConfig.DRAW_WIDTH / 2,
        physicsOffsetY = BearConfig.SPRITE_HEIGHT / 2 - BearConfig.DRAW_HEIGHT / 2
    })
    return entity
end

return Bear

