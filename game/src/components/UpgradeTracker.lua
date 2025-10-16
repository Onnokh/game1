local Component = require("src.core.Component")

---@class UpgradeTracker : Component
---@field ranks table<string, number> Upgrade ranks keyed by upgrade ID
local UpgradeTracker = {}
UpgradeTracker.__index = UpgradeTracker

---Create a new UpgradeTracker component
---@return Component|UpgradeTracker
function UpgradeTracker.new()
    local self = setmetatable(Component.new("UpgradeTracker"), UpgradeTracker)
    self.ranks = {}
    return self
end

---Get the current rank of an upgrade
---@param upgradeId string The upgrade ID
---@return number Current rank (0 if not yet upgraded)
function UpgradeTracker:getRank(upgradeId)
    return self.ranks[upgradeId] or 0
end

---Increment the rank of an upgrade
---@param upgradeId string The upgrade ID
---@return number New rank
function UpgradeTracker:incrementRank(upgradeId)
    local currentRank = self:getRank(upgradeId)
    self.ranks[upgradeId] = currentRank + 1
    print(string.format("[UpgradeTracker] Incremented '%s' to rank %d", upgradeId, self.ranks[upgradeId]))
    return self.ranks[upgradeId]
end

---Check if an upgrade can be upgraded further
---@param upgradeId string The upgrade ID
---@param maxRank number Maximum rank for this upgrade
---@return boolean True if can upgrade (current rank < maxRank)
function UpgradeTracker:canUpgrade(upgradeId, maxRank)
    return self:getRank(upgradeId) < maxRank
end

---Set the rank directly (useful for testing or loading saved data)
---@param upgradeId string The upgrade ID
---@param rank number The rank to set
function UpgradeTracker:setRank(upgradeId, rank)
    self.ranks[upgradeId] = rank
end

---Get all upgrade ranks
---@return table<string, number> All upgrade ranks
function UpgradeTracker:getAllRanks()
    return self.ranks
end

---Serialize the UpgradeTracker component for saving
---@return table Serialized upgrade tracker data
function UpgradeTracker:serialize()
    return {
        ranks = self.ranks
    }
end

---Deserialize UpgradeTracker component from saved data
---@param data table Serialized upgrade tracker data
---@return UpgradeTracker Recreated UpgradeTracker component
function UpgradeTracker.deserialize(data)
    local tracker = UpgradeTracker.new()
    tracker.ranks = data.ranks or {}
    return tracker
end

return UpgradeTracker

