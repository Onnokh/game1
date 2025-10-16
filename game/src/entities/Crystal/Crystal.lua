local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local TriggerZone = require("src.components.TriggerZone")
local Upgrade = require("src.components.Upgrade")
-- local Crystal = require("src.components.Crystal")
local GroundShadow = require("src.components.GroundShadow")
local Animator = require("src.components.Animator")
local Light = require("src.components.Light")

---@class CrystalEntity
local CrystalEntity = {}

---Create a new Crystal entity (static 64x64 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the shop to
---@param physicsWorld table|nil Physics world for collision
---@param inventory table|nil Optional custom inventory
---@param seed number|nil Optional seed for deterministic inventory generation
---@param shopId string|nil Optional shop identifier for unique seed per shop
---@return Entity The created shop entity
function CrystalEntity.create(x, y, world, physicsWorld, inventory, seed, shopId)

    local crystal = Entity.new()
    ---@class CrystalEntity : Entity
    local crystalEntity = crystal
    local DepthSorting = require("src.utils.depthSorting")
    local position = Position.new(x, y, DepthSorting.getLayerZ("FOREGROUND")) -- Top crystal in front
    local spriteRenderer = SpriteRenderer.new(nil, 112, 112)
    spriteRenderer.depthSortHeight = 48 -- Only use top 16px for depth sorting
    local animation = Animator.new({ sheet = 'crystal', frames = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, fps = 20, loop = true })

    -- local crystalComponent = Crystal.new(inventory, seed, shopId)

    -- Create child entities for additional colliders
    local function createColliderEntity(colliderName, width, height, offsetX, offsetY)
        local colliderEntity = Entity.new()
        local colliderPosition = Position.new(x + offsetX, y + offsetY, DepthSorting.getLayerZ("BACKGROUND")) -- Platform/stairs behind player
        local colliderComponent = PathfindingCollision.new(width, height, "static", 0, 0)

        colliderEntity:addComponent("Position", colliderPosition)
        colliderEntity:addComponent("PathfindingCollision", colliderComponent)
        colliderEntity:addTag("CrystalCollider")
        colliderEntity:addTag(colliderName)

        if physicsWorld then
            colliderComponent:createCollider(physicsWorld, x + offsetX, y + offsetY)
        end

        if world then
            world:addEntity(colliderEntity)
        end

        return colliderEntity
    end

    -- Create child collider entities
    local crystalCollider = PathfindingCollision.new(80, 4, "static", 16, 36) -- TopSide
    local leftSideEntity = createColliderEntity("LeftSide", 4, 44, 12, 36)
    local rightSideEntity = createColliderEntity("RightSide", 4, 44, 96, 36)
    local leftStairEntity = createColliderEntity("LeftStair", 30, 16, 12, 80)
    local rightStairEntity = createColliderEntity("RightStair", 30, 16, 70, 80)

    -- Create physics collider if physics world is available
    if physicsWorld then
        crystalCollider:createCollider(physicsWorld, x, y)
    end

    -- TriggerZone component (sensor for stairs)
    -- Stairs slow zone: Cover the step area using the new modifier system
    local TriggerEffects = require("src.utils.TriggerEffects")
    local onEnter, onExit = TriggerEffects.createEffect({
        type = "modifier",
        stat = "speed",
        mode = "multiply",
        value = 0.6,
        source = "crystal_stairs"
    })
    local stairsTrigger = TriggerZone.new(28, 24, 42, 80, onEnter, onExit,
        { speedMultiplier = 0.6, type = "stairs" }
    )

    -- Create trigger zone collider if physics world is available
    if physicsWorld then
        stairsTrigger:createCollider(physicsWorld, x, y)
        stairsTrigger:setEntity(crystal)
    end

    -- local light = Light.new({
    --     { r = 255, g = 0, b = 255, radius = 48, offsetX = 56, offsetY = 32, flicker = false, flickerRadiusAmplitude = 1.2 }
    -- })

    -- Store interaction range as entity property for UpgradeUISystem
    crystalEntity.interactionRange = 20

    -- Upgrade component for upgrade selection
    local upgradeComponent = Upgrade.new(world, "crystal_" .. tostring(crystal.id))

    crystal:addComponent("Position", position)
    crystal:addComponent("SpriteRenderer", spriteRenderer)
    crystal:addComponent("PathfindingCollision", crystalCollider)
    crystal:addComponent("TriggerZone", stairsTrigger)
    crystal:addComponent("Animator", animation)
    crystal:addComponent("Upgrade", upgradeComponent)
    -- crystal:addComponent("Light", light)

    -- Tag for easy querying
    crystal:addTag("Crystal")

    if world then
        world:addEntity(crystal)
    end

    return crystal
end

return CrystalEntity

