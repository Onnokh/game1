local CragBoarConfig = require("src.entities.Monsters.CragBoar.CragBoarConfig")
local MonsterFactory = require("src.entities.Monsters.core.MonsterFactory")

---@class CragBoar
local CragBoar = {}

---Create a new crag-boar enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the crag-boar to
---@param physicsWorld table|nil The physics world for collision
---@param isElite boolean|nil Whether this crag-boar should be an elite variant
---@return Entity The created crag-boar entity
function CragBoar.create(x, y, world, physicsWorld, isElite)
    local entity = MonsterFactory.create({
        x = x,
        y = y,
        world = world,
        physicsWorld = physicsWorld,
        config = CragBoarConfig,
        tag = "CragBoar",
        isElite = isElite or false,
        physicsOffsetX = CragBoarConfig.SPRITE_WIDTH / 2 - CragBoarConfig.DRAW_WIDTH / 2,
        physicsOffsetY = CragBoarConfig.SPRITE_HEIGHT / 2 - CragBoarConfig.DRAW_HEIGHT / 2
    })
    return entity
end

return CragBoar

