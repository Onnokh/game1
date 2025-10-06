---@class Interactable
---@field interactionRange number Range within which the player can interact
---@field onInteract function Callback function called when interaction occurs
---@field interactionText string|nil Optional text to display when player is in range
---@field canInteract function|nil Optional function to check if interaction is allowed
local Interactable = {}
Interactable.__index = Interactable

---Create a new Interactable component
---@param interactionRange number Range within which the player can interact (default: 32)
---@param onInteract function Callback function called when interaction occurs
---@param interactionText string|nil Optional text to display when player is in range
---@param canInteract function|nil Optional function to check if interaction is allowed
---@return Component|Interactable
function Interactable.new(interactionRange, onInteract, interactionText, canInteract)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Interactable"), Interactable)

    self.interactionRange = interactionRange or 32
    self.onInteract = onInteract or function() end
    self.interactionText = interactionText
    self.canInteract = canInteract

    return self
end

---Check if the entity can be interacted with
---@param playerEntity Entity The player entity attempting interaction
---@return boolean True if interaction is allowed
function Interactable:canPlayerInteract(playerEntity)
    if not playerEntity then
        return false
    end

    -- Check custom interaction condition if provided
    if self.canInteract and not self.canInteract(playerEntity) then
        return false
    end

    return true
end

---Execute the interaction
---@param playerEntity Entity The player entity performing the interaction
---@param interactableEntity Entity The entity being interacted with
function Interactable:interact(playerEntity, interactableEntity)
    if self:canPlayerInteract(playerEntity) then
        self.onInteract(playerEntity, interactableEntity)
    end
end

---Get the interaction text to display
---@return string|nil The interaction text or nil
function Interactable:getInteractionText()
    return self.interactionText
end

---Set the interaction callback
---@param callback function The new interaction callback
function Interactable:setInteractionCallback(callback)
    self.onInteract = callback or function() end
end

---Set the interaction text
---@param text string|nil The new interaction text
function Interactable:setInteractionText(text)
    self.interactionText = text
end

---Set the interaction range
---@param range number The new interaction range
function Interactable:setInteractionRange(range)
    self.interactionRange = range or 32
end

---Set the can interact condition
---@param condition function|nil The new condition function
function Interactable:setCanInteractCondition(condition)
    self.canInteract = condition
end

return Interactable
