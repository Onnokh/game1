local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PhysicsCollision = require("src.components.PhysicsCollision")
local Projectile = require("src.components.Projectile")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadow = require("src.components.GroundShadow")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Light = require("src.components.Light")
local Animator = require("src.components.Animator")

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
---@param abilityId string|nil The ability ID that created this projectile
---@param scale number|nil Projectile scale (default: 1)
---@return Entity The created projectile entity
function ProjectileEntity.create(x, y, velocityX, velocityY, speed, damage, owner, world, physicsWorld, knockback, lifetime, piercing, projectileSprite, abilityId, scale)
    -- Create the projectile entity
    local projectile = Entity.new()

    -- Tag for easy querying/filters
    projectile:addTag("Projectile")

    -- Create components
    -- Use GROUND layer so projectiles sort correctly with other entities based on Y position
    local position = Position.new(x, y, DepthSorting.getLayerZ("GROUND"))

    -- Create projectile component first (so we can get the angle)
    -- Use the provided scale as the base scale, defaulting to 1.0 if not provided
    local baseScale = scale or 1.0
    local projectileComponent = Projectile.new(
        velocityX,
        velocityY,
        speed,
        damage,
        lifetime,
        owner,
        knockback,
        piercing,
        abilityId,
        baseScale
    )

    -- Projectile sprite (use provided sprite name or default to "bullet")
    local spriteName = projectileSprite or "bullet"

    -- Look up sprite dimensions from iffy tilesets if available
    local spriteWidth = 8  -- Default fallback
    local spriteHeight = 8  -- Default fallback
    local iffy = require("lib.iffy")
    if iffy.tilesets[spriteName] then
        spriteWidth = iffy.tilesets[spriteName][1] or 8
        spriteHeight = iffy.tilesets[spriteName][2] or 8
    end

    local spriteRenderer = SpriteRenderer.new(spriteName, spriteWidth, spriteHeight)
    -- Rotate sprite to match projectile direction
    spriteRenderer:setRotation(projectileComponent:getAngle())
    -- Initial scale will be set by ProjectileSystem based on animation
    -- Set initial scale to match the animation start (0.1 * baseScale)
    local initialScale = 0.1 * baseScale
    spriteRenderer:setScale(initialScale, initialScale)

    -- Circular physics collider for projectile collision detection (sensor)
    -- PhysicsCollision already creates sensors by default (non-blocking)
    -- Use sprite dimensions for collider size (radius is half the average of width/height)
    local colliderRadius = math.max(spriteWidth, spriteHeight) / 2
    local physicsCollision = PhysicsCollision.new(colliderRadius, colliderRadius, "dynamic", colliderRadius /2 , colliderRadius /2, "circle")

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
    projectile:addComponent("GroundShadow", GroundShadow.new())

    -- Add Animator component if sprite has multiple frames
    if iffy.spritesheets[spriteName] and #iffy.spritesheets[spriteName] > 1 then
        local frameCount = #iffy.spritesheets[spriteName]
        local frames = {}
        for i = 1, frameCount do
            frames[i] = i
        end

        local animator = Animator.new({
            layers = {spriteName},
            frames = frames,
            fps = 12, -- 12 fps for smooth projectile animation
            loop = true
        })
        projectile:addComponent("Animator", animator)

        -- Clear sprite name from SpriteRenderer to avoid double rendering
        -- The Animator will handle rendering the sprite
        spriteRenderer.sprite = nil
    end

    -- Add to world
    if world then
        world:addEntity(projectile)
    end

    return projectile
end

return ProjectileEntity

