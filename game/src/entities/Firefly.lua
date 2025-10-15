---Firefly entity factory
---Creates a firefly entity with Position, Light, and Firefly components

local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Light = require("src.components.Light")
local Firefly = require("src.components.Firefly")
local SpriteRenderer = require("src.components.SpriteRenderer")

local FireflyFactory = {}

---Create a firefly entity at the specified position
---@param x number X position in world coordinates
---@param y number Y position in world coordinates
---@param ecsWorld World ECS world to add entity to
---@return Entity The created firefly entity
function FireflyFactory.create(x, y, ecsWorld)
    local firefly = Entity.new()

    -- Add tags for identification
    firefly:addTag("Firefly")

    -- Add position component
    firefly:addComponent("Position", Position.new(x, y))

    local seed = math.random()
    -- size between 1 and 3 pixels
    local size = 1 + seed * 2

    -- Add firefly behavior component with randomized properties
    local lifetime = 4 + seed * 2  -- 4-6 seconds
    local vy = -(5 + seed * 10)   -- -5 to -10
    local driftSpeed = 10 + seed * 10  -- 10-20 drift speed
    firefly:addComponent("Firefly", Firefly.new(0, vy, lifetime, driftSpeed))

    -- Add light component with small warm yellow color and flicker
    local lightOpts = {
        radius = size*3,  -- Small but visible radius
        r = 255,
        g = 255,
        b = 100,  -- More yellow, less green
        a = 20,  -- Start with very low opacity for fade-in effect
        offsetX = size / 2,
        offsetY = size / 2,
        enabled = true,
        flicker = true,
        flickerSpeed = 8,  -- Moderate flicker speed
        flickerRadiusAmplitude = 2,  -- Small radius variation
        flickerAlphaAmplitude = 30
    }

    firefly:addComponent("Light", Light.new(lightOpts))

    -- Add small blurry yellow base sprite (4x4 pixels)
    firefly:addComponent("SpriteRenderer", SpriteRenderer.new(nil, size, size))
    local spriteRenderer = firefly:getComponent("SpriteRenderer")
    spriteRenderer.color = {r = 1, g = 1, b = 0.4, a = 0.1}  -- Start with very low opacity for fade-in
    spriteRenderer.offsetY = 1  -- Slight offset below the light center

    -- Add to world if provided
    if ecsWorld then
        ecsWorld:addEntity(firefly)
    end

    return firefly
end

---Create multiple fireflies in a small area around a position
---@param centerX number Center X position
---@param centerY number Center Y position
---@param count number Number of fireflies to create
---@param ecsWorld World ECS world to add entities to
---@return table Array of created firefly entities
function FireflyFactory.createSwarm(centerX, centerY, count, ecsWorld)
    local fireflies = {}
    local spread = 50  -- Spread radius in pixels

    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local distance = math.random() * spread
        local x = centerX + math.cos(angle) * distance
        local y = centerY + math.sin(angle) * distance

        local firefly = FireflyFactory.create(x, y, ecsWorld)
        table.insert(fireflies, firefly)
    end

    return fireflies
end

return FireflyFactory
