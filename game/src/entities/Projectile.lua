local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PhysicsCollision = require("src.components.PhysicsCollision")
local Projectile = require("src.components.Projectile")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadow = require("src.components.GroundShadow")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Light = require("src.components.Light")

---@class ProjectileEntity
local ProjectileEntity = {}

---Create a new projectile entity
---@param x number Starting X position
---@param y number Starting Y position
---@param velocityX number X velocity direction
---@param velocityY number Y velocity direction
---@param speed number Projectile speed
---@param damage number Damage dealt
---@param owner Entity The entity that fired this projectile
---@param world World The ECS world to add the projectile to
---@param physicsWorld table|nil The physics world for collision
---@param knockback number|nil Knockback force (default: 0)
---@param lifetime number|nil Projectile lifetime in seconds (default: 3)
---@param piercing boolean|nil Whether projectile can hit multiple targets (default: false)
---@param projectileSprite string|nil Sprite/animation name for the projectile (default: "bullet")
---@return Entity The created projectile entity
function ProjectileEntity.create(x, y, velocityX, velocityY, speed, damage, owner, world, physicsWorld, knockback, lifetime, piercing, projectileSprite)
    -- Create the projectile entity
    local projectile = Entity.new()

    -- Tag for easy querying/filters
    projectile:addTag("Projectile")

    -- Create components
    local position = Position.new(x, y, DepthSorting.getLayerZ("FOREGROUND"))

    -- Create projectile component first (so we can get the angle)
    local projectileComponent = Projectile.new(
        velocityX,
        velocityY,
        speed,
        damage,
        lifetime,
        owner,
        knockback,
        piercing
    )

    -- Projectile sprite (use provided sprite name or default to "bullet")
    local spriteName = projectileSprite or "bullet"
    local spriteRenderer = SpriteRenderer.new(spriteName, 8, 8)
    -- Rotate sprite to match projectile direction
    spriteRenderer:setRotation(projectileComponent:getAngle())
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

    -- Circular physics collider for projectile collision detection (sensor)
    -- PhysicsCollision already creates sensors by default (non-blocking)
    local physicsCollision = PhysicsCollision.new(8, 8, "dynamic",0, 0, "circle")

    -- Create collider if physics world is available
    if physicsWorld then
        physicsCollision:createCollider(physicsWorld, x, y)
        -- Enable continuous collision detection for fast-moving projectiles
        if physicsCollision.collider and physicsCollision.collider.body then
            physicsCollision.collider.body:setBullet(true)
        end
        -- Set user data on the fixture so collision callbacks can identify projectiles
        if physicsCollision.collider and physicsCollision.collider.fixture then
            physicsCollision.collider.fixture:setUserData({
                kind = "projectile",
                entity = projectile
            })
        end
    end

    -- Add all components to the projectile
    projectile:addComponent("Position", position)
    projectile:addComponent("SpriteRenderer", spriteRenderer)
    projectile:addComponent("Projectile", projectileComponent)
    projectile:addComponent("PhysicsCollision", physicsCollision)
    projectile:addComponent("GroundShadow", GroundShadow.new({ alpha = .75, widthFactor = 1, heightFactor = 0.75, offsetY = 8 }))
    projectile:addComponent("Light", Light.new({ r = 100, g = 150, b = 255, a = 255, radius = 24 }))

    -- Add to world
    if world then
        world:addEntity(projectile)
    end

    return projectile
end

return ProjectileEntity

