local Component = require("src.core.Component")
local EventBus = require("src.utils.EventBus")

---@class PlayerLevel : Component
---@field level number Current player level (starts at 1)
---@field experience number Current experience points
local PlayerLevel = {}
PlayerLevel.__index = PlayerLevel

---Create a new PlayerLevel component
---@param startingLevel number|nil Starting level (default 1)
---@param startingExperience number|nil Starting experience (default 0)
---@return Component|PlayerLevel
function PlayerLevel.new(startingLevel, startingExperience)
    local self = setmetatable(Component.new("PlayerLevel"), PlayerLevel)

    self.level = startingLevel or 1
    self.experience = startingExperience or 0

    return self
end

---Get current level
---@return number Current level
function PlayerLevel:getLevel()
    return self.level
end

---Get current experience
---@return number Current experience
function PlayerLevel:getExperience()
    return self.experience
end

---Calculate experience needed for next level
---@param level number Current level
---@return number Experience needed to reach next level
function PlayerLevel:_calculateExpToNextLevel(level)
    -- Simple linear formula: each level requires more experience
    -- Base: 100 exp for level 1->2, then +50 per level
    return 100 + ((level - 1) * 50)
end

---Add experience points and handle level ups
---@param amount number Experience to add
---@return boolean True if level up occurred, false otherwise
function PlayerLevel:addExperience(amount)
    self.experience = self.experience + amount
    
    local leveledUp = false
    
    -- Check if player should level up (may level up multiple times if enough exp)
    while true do
        local expNeeded = self:_calculateExpToNextLevel(self.level)
        
        if self.experience >= expNeeded then
            -- Level up!
            self.experience = self.experience - expNeeded
            local oldLevel = self.level
            self.level = self.level + 1
            leveledUp = true
            
            print(string.format("Level up! Now level %d (exp remaining: %d)", self.level, self.experience))
            
            -- Emit level gained event
            EventBus.emit("LevelGained", {
                newLevel = self.level,
                oldLevel = oldLevel
            })
            
            -- Continue checking if there's enough exp for another level
        else
            -- Not enough exp for next level
            break
        end
    end
    
    return leveledUp
end

---Set level directly (for testing or initial setup)
---@param newLevel number New level value
function PlayerLevel:setLevel(newLevel)
    self.level = math.max(1, newLevel)
end

---Level up manually
---@return number New level
function PlayerLevel:levelUp()
    self.level = self.level + 1
    return self.level
end

---Serialize the PlayerLevel component for saving
---@return table Serialized level data
function PlayerLevel:serialize()
    return {
        level = self.level,
        experience = self.experience
    }
end

---Deserialize PlayerLevel component from saved data
---@param data table Serialized level data
---@return PlayerLevel Recreated PlayerLevel component
function PlayerLevel.deserialize(data)
    local playerLevel = PlayerLevel.new(data.level, data.experience)
    return playerLevel
end

return PlayerLevel

