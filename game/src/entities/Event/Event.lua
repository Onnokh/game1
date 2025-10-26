local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local Animator = require("src.components.Animator")
local Event = require("src.components.Event")
local Upgrade = require("src.components.Upgrade")
local TriggerZone = require("src.components.TriggerZone")
local Interactable = require("src.components.Interactable")
local MinimapIcon = require("src.components.MinimapIcon")
local sprites = require("src.utils.sprites")
local EventAnimations = require("src.utils.EventAnimations")

---@class EventEntity
local EventEntity = {}

---Create a new Event entity
---@param x number X position (top-left in world units)
---@param y number Y position (top-left in world units)
---@param world World ECS world to add the event to
---@param physicsWorld table|nil Physics world for collision
---@param eventType string The type of event (e.g., "Upgrade")
---@return Entity The created event entity
function EventEntity.create(x, y, world, physicsWorld, eventType)
    local event = Entity.new()
    ---@class EventEntity : Entity
    local eventEntity = event

    local DepthSorting = require("src.utils.depthSorting")
    local position = Position.new(x, y, DepthSorting.getLayerZ("BACKGROUND"))
    local spriteRenderer = SpriteRenderer.new(nil, 128, 128)
    -- Override depth sorting height to make event render behind other entities
    spriteRenderer.depthSortHeight = 16 -- Use small height for depth sorting

    -- Animation configurations (multi-layer: event area + gem)
    local spawnAnimation = EventAnimations.get("spawn")
    local animator = Animator.new(spawnAnimation)

    -- Position the gem layer centered on the event area (gem is 32x32, event area is 128x128)
    -- Center offset: (128-32)/2 = 48px from top-left
    animator:setLayerOffset('event-gem', 48, 48)

    -- Event component
    local eventComponent = Event.new(eventType, world)

    -- Upgrade component for upgrade selection
    local eventId = string.format("event_%d", event.id)
    local upgradeComponent = Upgrade.new(world, eventId)

    -- TriggerZone for detecting player proximity (circular, 120px radius, centered on sprite)
    local triggerZone = TriggerZone.new(120, 120, 4, 4,
        function(entity, trigger)
            -- onEnter: Check if it's the player
            if entity:hasTag("Player") then
                local currentState = eventComponent:getState()
                if currentState == "idle" then
                    eventComponent:setState("activating")
                    animator:setAnimation(EventAnimations.get("activating"))
                elseif currentState == "deactivating" then
                    -- Player re-entered while deactivating, switch back to activating
                    eventComponent:setState("activating")
                    animator:setAnimation(EventAnimations.get("activating"))
                end
            end
        end,
        function(entity, trigger)
            -- onExit: Check if it's the player
            if entity:hasTag("Player") then
                local currentState = eventComponent:getState()
                if currentState == "active" then
                    eventComponent:setState("deactivating")
                    animator:setAnimation(EventAnimations.get("deactivating"))
                elseif currentState == "activating" then
                    -- Player left while activating, switch to deactivating
                    eventComponent:setState("deactivating")
                    animator:setAnimation(EventAnimations.get("deactivating"))
                end
            end
        end,
        nil, -- data
        "circle" -- shapeType
    )

    -- Interactable component for E key interaction
    local interactable = Interactable.new(
        48, -- interaction range
        function(player, eventEntity)
            -- Allow interaction if event is activating or active
            local currentState = eventComponent:getState()
            if currentState == "activating" or currentState == "active" then
                -- Open upgrade UI for this event
                local EventBus = require("src.utils.EventBus")
                EventBus.emit("openEventUpgrade", { event = eventEntity })
            end
        end,
        "Press E to interact"
    )

    -- Create trigger zone collider if physics world is available
    if physicsWorld then
        triggerZone:createCollider(physicsWorld, x, y)
        triggerZone:setEntity(event)
    end

    event:addComponent("Position", position)
    event:addComponent("SpriteRenderer", spriteRenderer)
    event:addComponent("Animator", animator)
    event:addComponent("Event", eventComponent)
    event:addComponent("Upgrade", upgradeComponent)
    event:addComponent("TriggerZone", triggerZone)
    event:addComponent("Interactable", interactable)

    -- Add minimap icon with the upgrade icon
    event:addComponent("MinimapIcon", MinimapIcon.new("upgrade", {r = 255, g = 255, b = 255}, 5, sprites.getImage("minimapUpgrade")))

    -- Tag for easy querying
    event:addTag("Event")

    if world then
        world:addEntity(event)
    end

    return event
end

return EventEntity
