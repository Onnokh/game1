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

    -- Small sprite for bullet visualization (you can customize this)
    local spriteRenderer = SpriteRenderer.new(nil, 4, 4)
    spriteRenderer.color = {r = 1, g = 1, b = 0.2, a = 1} -- Yellow color for bullets

    -- Create bullet component
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

    -- Small physics collider for bullet collision detection (sensor)
    -- PhysicsCollision already creates sensors by default (non-blocking)
    local physicsCollision = PhysicsCollision.new(4, 4, "dynamic", 0, 0, "circle")

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
    bullet:addComponent("GroundShadow", GroundShadow.new({ alpha = .75, widthFactor = 0.8, heightFactor = 0.18, offsetY = 2 }))

    -- Add to world
    if world then
        world:addEntity(bullet)
    end

    return bullet
end

return BulletEntity

