local WarhogConfig = require("src.entities.Monsters.Warhog.WarhogConfig")
local MonsterFactory = require("src.entities.Monsters.core.MonsterFactory")

---@class Warhog
local Warhog = {}

---Create a new warhog enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the warhog to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created warhog entity
function Warhog.create(x, y, world, physicsWorld)
    local entity = MonsterFactory.create({
        x = x,
        y = y,
        world = world,
        physicsWorld = physicsWorld,
        config = WarhogConfig,
        tag = "Warhog",
        physicsOffsetX = WarhogConfig.SPRITE_WIDTH / 2 - WarhogConfig.DRAW_WIDTH / 2 - 2,
        physicsOffsetY = WarhogConfig.SPRITE_HEIGHT / 2 - WarhogConfig.DRAW_HEIGHT / 2 + 8
    })
    -- Attach footprints emitter (4-limb)
    local FootprintsEmitter = require("src.components.FootprintsEmitter")
    entity:addComponent("FootprintsEmitter", FootprintsEmitter.new({
        spacing = 12,
        lifetime = 2.5,
        baseAlpha = 0.45,
        limbs = {
            { lateral = -4, phase = 0.00 }, -- front-left
            { lateral =  4, phase = 0.50 }, -- front-right
            { lateral = -4, phase = 0.25 }, -- back-left
            { lateral =  4, phase = 0.75 }  -- back-right
        },
        maxCount = 400
    }))
    return entity
end

return Warhog

