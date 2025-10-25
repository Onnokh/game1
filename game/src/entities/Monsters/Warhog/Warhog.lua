local WarhogConfig = require("src.entities.Monsters.Warhog.WarhogConfig")
local MonsterFactory = require("src.entities.Monsters.core.MonsterFactory")

---@class Warhog
local Warhog = {}

---Create a new warhog enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the warhog to
---@param physicsWorld table|nil The physics world for collision
---@param isElite boolean|nil Whether this warhog should be an elite variant
---@return Entity The created warhog entity
function Warhog.create(x, y, world, physicsWorld, isElite)
    local entity = MonsterFactory.create({
        x = x,
        y = y,
        world = world,
        physicsWorld = physicsWorld,
        config = WarhogConfig,
        tag = "Warhog",
        isElite = isElite or false,
        physicsOffsetX = WarhogConfig.SPRITE_WIDTH / 2 - WarhogConfig.DRAW_WIDTH / 2 - 2,
        physicsOffsetY = WarhogConfig.SPRITE_HEIGHT / 2 - WarhogConfig.DRAW_HEIGHT / 2 + 8
    })
    return entity
end

return Warhog

