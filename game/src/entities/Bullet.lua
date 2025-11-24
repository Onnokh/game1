local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PhysicsCollision = require("src.components.PhysicsCollision")
local Bullet = require("src.components.Bullet")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadow = require("src.components.GroundShadow")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Light = require("src.components.Light")

---@class BulletEntity
local BulletEntity = {}

---Create a new bullet entity
---@param x number Starting X position
---@param y number Starting Y position
---@param velocityX number X velocity direction
---@param velocityY number Y velocity direction
---@param speed number Bullet speed
---@param damage number Damage dealt
---@param owner Entity The entity that fired this bullet
---@param world World The ECS world to add the bullet to
---@param physicsWorld table|nil The physics world for collision
---@param knockback number|nil Knockback force (default: 0)
---@param lifetime number|nil Bullet lifetime in seconds (default: 3)
---@param piercing boolean|nil Whether bullet can hit multiple targets (default: false)
---@return Entity The created bullet entity
function BulletEntity.create(x, y, velocityX, velocityY, speed, damage, owner, world, physicsWorld, knockback, lifetime, piercing)
    -- Create the bullet entity
    local bullet = Entity.new()

    -- Tag for easy querying/filters
    bullet:addTag("Bullet")

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("FOREGROUND"))

    -- Create bullet component first (so we can get the angle)
    local bulletComponent = Bullet.new(
        velocityX,
        velocityY,
        speed,
        damage,
        lifetime,
        owner,
        knockback,
        piercing
    )

    -- Bullet sprite (16x16 circular sprite)
    local spriteRenderer = SpriteRenderer.new("bullet", 8, 8)
    -- Rotate sprite to match bullet direction
    spriteRenderer:setRotation(bulletComponent:getAngle())
    -- Start with small scale for animation
    spriteRenderer:setScale(0.3, 0.3)

    -- Set glow color and sprite color from ability if available
    if owner then
        local ability = owner:getComponent("Ability")
        if ability then
            local abilityData = ability:getCurrentAbility()
            if abilityData and abilityData.glowColor then
                -- Set glow color for the halo effect
                spriteRenderer:setGlowColor(abilityData.glowColor[1], abilityData.glowColor[2], abilityData.glowColor[3])
                -- Tint the sprite itself with the same color (since sprite is now white)
                spriteRenderer:setColor(abilityData.glowColor[1], abilityData.glowColor[2], abilityData.glowColor[3], 1.0)
            end
        end
    end

    -- Circular physics collider for bullet collision detection (sensor)
    -- PhysicsCollision already creates sensors by default (non-blocking)
    local physicsCollision = PhysicsCollision.new(8, 8, "dynamic",0, 0, "circle")

    -- Create collider if physics world is available
    if physicsWorld then
        physicsCollision:createCollider(physicsWorld, x, y)
        -- Enable continuous collision detection for fast-moving bullets
        if physicsCollision.collider and physicsCollision.collider.body then
            physicsCollision.collider.body:setBullet(true)
        end
        -- Set user data on the fixture so collision callbacks can identify bullets
        if physicsCollision.collider and physicsCollision.collider.fixture then
            physicsCollision.collider.fixture:setUserData({
                kind = "bullet",
                entity = bullet
            })
        end
    end

    -- Add all components to the bullet
    bullet:addComponent("Position", position)
    bullet:addComponent("SpriteRenderer", spriteRenderer)
    bullet:addComponent("Bullet", bulletComponent)
    bullet:addComponent("PhysicsCollision", physicsCollision)
    bullet:addComponent("GroundShadow", GroundShadow.new({ alpha = .75, widthFactor = 1, heightFactor = 0.75, offsetY = 8 }))
    bullet:addComponent("Light", Light.new({ r = 100, g = 150, b = 255, a = 255, radius = 24 }))

    -- Add to world
    if world then
        world:addEntity(bullet)
    end

    return bullet
end

return BulletEntity

