---@class DashCharges : Component
---Component that manages dash charges for an entity
local DashCharges = {}
DashCharges.__index = DashCharges

---Create a new DashCharges component
---@param maxCharges number Maximum number of dash charges (default 3)
---@param chargeRegenTime number Time in seconds to regenerate one charge (default 2.0)
---@return Component|DashCharges
function DashCharges.new(maxCharges, chargeRegenTime)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("DashCharges"), DashCharges)

    self.maxCharges = maxCharges or 3
    self.currentCharges = self.maxCharges
    self.chargeRegenTime = chargeRegenTime or 2.0
    self.currentRegenTimer = 0
    self.lastChargeCount = self.currentCharges -- Track previous charge count for pulse detection

    return self
end

---Check if the entity can dash
---@return boolean True if there are available charges
function DashCharges:canDash()
    return self.currentCharges > 0
end

---Consume one dash charge
function DashCharges:consumeCharge()
    if self.currentCharges > 0 then
        self.currentCharges = self.currentCharges - 1

        -- If we're currently regenerating a charge, merge that progress
        if self.currentRegenTimer > 0 and self.currentCharges < self.maxCharges then
            -- Keep the existing progress - don't reset to full timer
            -- The timer continues from where it was
        elseif self.currentCharges < self.maxCharges then
            -- Start fresh regeneration timer only if we weren't already regenerating
            self.currentRegenTimer = self.chargeRegenTime
        end
    end
end

---Update charge regeneration
---@param dt number Delta time
function DashCharges:update(dt)
    local previousCharges = self.currentCharges

    if self.currentCharges < self.maxCharges and self.currentRegenTimer > 0 then
        self.currentRegenTimer = self.currentRegenTimer - dt
        if self.currentRegenTimer <= 0 then
            self.currentCharges = self.currentCharges + 1
            self.currentRegenTimer = 0

            -- If still not at max charges, start timer for next charge
            if self.currentCharges < self.maxCharges then
                self.currentRegenTimer = self.chargeRegenTime
            end
        end
    end

    -- Emit event when a charge becomes available
    if self.currentCharges > previousCharges then
        local EventBus = require("src.utils.EventBus")
        EventBus.emit("dashChargeAvailable", {
            chargeIndex = self.currentCharges,
            totalCharges = self.maxCharges
        })
    end

    -- Update last charge count for pulse detection
    self.lastChargeCount = self.currentCharges
end

---Get the regeneration progress of the currently charging bar (0-1)
---@return number Progress from 0 (empty) to 1 (full)
function DashCharges:getChargeProgress()
    if self.currentCharges >= self.maxCharges or self.currentRegenTimer <= 0 then
        return 1.0
    end
    return 1.0 - (self.currentRegenTimer / self.chargeRegenTime)
end

---Check if a charge just became available (for pulse animation)
---@return boolean True if a charge just became available
function DashCharges:justBecameAvailable()
    return self.currentCharges > self.lastChargeCount
end

---Get the number of fully charged bars
---@return number Number of available charges
function DashCharges:getAvailableCharges()
    return self.currentCharges
end

---Get the maximum number of charges
---@return number Maximum charges
function DashCharges:getMaxCharges()
    return self.maxCharges
end

---Set maximum charges (useful for gear modifications)
---@param newMaxCharges number New maximum number of charges
function DashCharges:setMaxCharges(newMaxCharges)
    if newMaxCharges < 1 then newMaxCharges = 1 end

    local oldMax = self.maxCharges
    self.maxCharges = newMaxCharges

    -- If we reduced max charges, cap current charges
    if self.currentCharges > self.maxCharges then
        self.currentCharges = self.maxCharges
    end

    -- If we increased max charges, we don't automatically gain charges
    -- (they'll regenerate naturally)
end

---Set charge regeneration time (useful for gear modifications)
---@param newRegenTime number New regeneration time in seconds
function DashCharges:setChargeRegenTime(newRegenTime)
    if newRegenTime < 0.1 then newRegenTime = 0.1 end

    -- Scale current timer proportionally
    if self.currentRegenTimer > 0 then
        local progress = self.currentRegenTimer / self.chargeRegenTime
        self.currentRegenTimer = progress * newRegenTime
    end

    self.chargeRegenTime = newRegenTime
end

---Serialize the DashCharges component for saving
---@return table Serialized dash charges data
function DashCharges:serialize()
    return {
        maxCharges = self.maxCharges,
        currentCharges = self.currentCharges,
        chargeRegenTime = self.chargeRegenTime,
        currentRegenTimer = self.currentRegenTimer
    }
end

---Deserialize DashCharges component from saved data
---@param data table Serialized dash charges data
---@return Component|DashCharges Recreated DashCharges component
function DashCharges.deserialize(data)
    local dashCharges = DashCharges.new(data.maxCharges, data.chargeRegenTime)
    dashCharges.currentCharges = data.currentCharges or dashCharges.maxCharges
    dashCharges.currentRegenTimer = data.currentRegenTimer or 0
    return dashCharges
end

return DashCharges
