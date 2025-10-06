local System = require("src.core.System")
local CoordinateUtils = require("src.utils.coordinates")

---@class InteractionSystem : System
---@field world World The ECS world
---@field playerEntity Entity|nil The player entity
---@field nearestInteractable Entity|nil The nearest interactable entity
---@field interactionRange number Maximum interaction range
local InteractionSystem = System:extend("InteractionSystem", {"Interactable"})

---Create a new InteractionSystem
---@return InteractionSystem|System
function InteractionSystem.new()
    ---@type InteractionSystem
    local self = System.new() -- Create base system
    setmetatable(self, InteractionSystem)
    self.requiredComponents = {"Interactable"} -- Track all entities with Interactable component
    self.playerEntity = nil
    self.nearestInteractable = nil
    self.interactionRange = 64 -- Default interaction range

    return self
end

---Find the player entity in the world
---@return Entity|nil The player entity or nil if not found
function InteractionSystem:findPlayerEntity()
    if self.world and self.world.entities then
        for _, entity in ipairs(self.world.entities) do
            if entity:hasTag("Player") then
                return entity
            end
        end
    end
    return nil
end

---Update the system
---@param dt number Delta time
function InteractionSystem:update(dt)
    -- Ensure we have a player entity
    if not self.playerEntity then
        self.playerEntity = self:findPlayerEntity()
        if not self.playerEntity then
            return
        end
    end

    -- Find nearest interactable entity
    self.nearestInteractable = self:findNearestInteractable()

    -- Check for interaction input
    local gameState = require("src.core.GameState")
    if gameState.input.interact and self.nearestInteractable then
        self:handleInteraction()
        -- Reset the input to prevent multiple triggers
        gameState.input.interact = false
    end
end

---Find the nearest interactable entity to the player
---@return Entity|nil The nearest interactable entity or nil
function InteractionSystem:findNearestInteractable()
    local playerPos = self.playerEntity:getComponent("Position")
    if not playerPos then
        return nil
    end

    local nearestEntity = nil
    local nearestDistance = math.huge

    for _, entity in ipairs(self.entities) do
        local interactable = entity:getComponent("Interactable")
        if interactable then
            local entityPos = entity:getComponent("Position")
            if entityPos then
                local distance = CoordinateUtils.calculateDistance(playerPos, entityPos)
                if distance <= interactable.interactionRange and distance < nearestDistance then
                    if interactable:canPlayerInteract(self.playerEntity) then
                        nearestEntity = entity
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    return nearestEntity
end


---Handle interaction with the nearest interactable entity
function InteractionSystem:handleInteraction()
    if not self.nearestInteractable then
        return
    end

    local interactable = self.nearestInteractable:getComponent("Interactable")
    if interactable then
        interactable:interact(self.playerEntity, self.nearestInteractable)
    end
end

---Get the nearest interactable entity
---@return Entity|nil The nearest interactable entity
function InteractionSystem:getNearestInteractable()
    return self.nearestInteractable
end

---Get interaction text for the nearest interactable
---@return string|nil The interaction text or nil
function InteractionSystem:getNearestInteractionText()
    if self.nearestInteractable then
        local interactable = self.nearestInteractable:getComponent("Interactable")
        if interactable then
            return interactable:getInteractionText()
        end
    end
    return nil
end

---Check if the player is near any interactable entity
---@return boolean True if near an interactable
function InteractionSystem:isNearInteractable()
    return self.nearestInteractable ~= nil
end

---Set the interaction range
---@param range number The new interaction range
function InteractionSystem:setInteractionRange(range)
    self.interactionRange = range or 64
end

return InteractionSystem
