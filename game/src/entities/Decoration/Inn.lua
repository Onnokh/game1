local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local PathfindingCollision = require("src.components.PathfindingCollision")
local GroundShadow = require("src.components.GroundShadow")
local Light = require("src.components.Light")

---@class Inn
local Inn = {}

---Create a new Inn entity (static 280x240 object)
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the inn to
---@param physicsWorld table|nil Physics world for collision
---@return Entity The created inn entity
function Inn.create(x, y, world, physicsWorld)

    local inn = Entity.new()
    local DepthSorting = require("src.utils.depthSorting")
    local position = Position.new(x, y, 0)
    local spriteRenderer = SpriteRenderer.new('inn', 280, 240)
    -- Set depth sort height to use ground contact point
    -- instead of full sprite height (240px) which includes roof
    spriteRenderer.depthSortHeight = 60

    -- Create child entities for additional colliders
    local function createColliderEntity(colliderName, width, height, offsetX, offsetY)
        local colliderEntity = Entity.new()
        local colliderPosition = Position.new(x + offsetX, y + offsetY, DepthSorting.getLayerZ("BACKGROUND"))
        local colliderComponent = PathfindingCollision.new(width, height, "static", 0, 0, "rectangle")

        colliderEntity:addComponent("Position", colliderPosition)
        colliderEntity:addComponent("PathfindingCollision", colliderComponent)
        colliderEntity:addTag("InnCollider")
        colliderEntity:addTag(colliderName)

        if physicsWorld then
            colliderComponent:createCollider(physicsWorld, x + offsetX, y + offsetY)
        end

        if world then
            world:addEntity(colliderEntity)
        end

        return colliderEntity
    end

    -- Main body collider (base of building)
    local mainCollider = PathfindingCollision.new(252, 140, "static", 12, 24, "rectangle")

    -- Front porch/steps (if building has a front entrance area)
    local frontPorchEntity = createColliderEntity("FrontPorch", 124, 50, 12, 164)


    -- Create physics collider for main body if physics world is available
    if physicsWorld then
        mainCollider:createCollider(physicsWorld, x, y)
    end

    inn:addComponent("Position", position)
    inn:addComponent("SpriteRenderer", spriteRenderer)
    inn:addComponent("PathfindingCollision", mainCollider)
    inn:addComponent("GroundShadow", GroundShadow.new())

    -- Tag for easy querying
    inn:addTag("Inn")

    if world then
        world:addEntity(inn)
    end

    return inn
end

return Inn

