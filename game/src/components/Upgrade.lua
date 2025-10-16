---@class Upgrade
---@field upgrades table Array of upgrade IDs for selection (max 3 upgrades)
---@field maxUpgrades number Maximum number of upgrades (default 3)
---@field world World|nil Reference to ECS world to find player
---@field crystalId string Crystal identifier for logging
local Upgrade = {}
Upgrade.__index = Upgrade

---Create a new Upgrade component
---@param world World|nil Optional reference to ECS world for finding player
---@param crystalId string|nil Optional crystal identifier for logging
---@return Component|Upgrade
function Upgrade.new(world, crystalId)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Upgrade"), Upgrade)
    
    self.maxUpgrades = 3
    self.upgrades = {}
    self.world = world
    self.crystalId = crystalId or "unknown"
    
    -- Generate initial upgrades if world is available
    if world then
        local player = world:getPlayer()
        if player then
            self:generateRandomUpgrades(player)
        end
    end
    
    return self
end

---Generate random upgrades that the player hasn't maxed out
---@param player Entity The player entity
---@return table Array of 3 random upgrade IDs
function Upgrade:generateRandomUpgrades(player)
    local upgradesModule = require("src.definitions.upgrades")
    local tracker = player:getComponent("UpgradeTracker")
    
    if not tracker then
        print("[Upgrade] Warning: Player has no UpgradeTracker component")
        self.upgrades = {}
        return self.upgrades
    end
    
    -- Get all available upgrades that haven't reached max rank
    local availableUpgrades = {}
    for id, upgradeDef in pairs(upgradesModule.upgrades) do
        if tracker:canUpgrade(id, upgradeDef.maxRank) then
            table.insert(availableUpgrades, id)
        end
    end
    
    -- If less than 3 upgrades available, just use what we have
    if #availableUpgrades == 0 then
        print(string.format("[Upgrade] Crystal %s: No upgrades available (all maxed out)", self.crystalId))
        self.upgrades = {}
        return self.upgrades
    end
    
    -- Shuffle available upgrades
    for i = #availableUpgrades, 2, -1 do
        local j = math.random(i)
        availableUpgrades[i], availableUpgrades[j] = availableUpgrades[j], availableUpgrades[i]
    end
    
    -- Take first 3 (or less if not enough available)
    self.upgrades = {}
    for i = 1, math.min(3, #availableUpgrades) do
        self.upgrades[i] = availableUpgrades[i]
    end
    
    print(string.format("[Upgrade] Crystal %s: Generated %d upgrades: %s",
        self.crystalId, #self.upgrades, table.concat(self.upgrades, ", ")))
    
    return self.upgrades
end

---Get upgrade definition from definitions
---@param upgradeId string The upgrade ID
---@return table|nil Upgrade definition with name, description, etc.
function Upgrade:getUpgradeDefinition(upgradeId)
    if not upgradeId then
        return nil
    end
    
    local upgradesModule = require("src.definitions.upgrades")
    return upgradesModule.getUpgrade(upgradeId)
end

---Get an upgrade by index (returns the full definition, not just ID)
---@param index number Index of the upgrade (1-based)
---@return table|nil The upgrade definition, or nil if index is invalid
function Upgrade:getUpgrade(index)
    if index < 1 or index > self.maxUpgrades then
        return nil
    end
    
    local upgradeId = self.upgrades[index]
    if not upgradeId then
        return nil
    end
    
    return self:getUpgradeDefinition(upgradeId)
end

---Get the upgrade's inventory (array of upgrade IDs)
---@return table Array of upgrade IDs
function Upgrade:getUpgrades()
    return self.upgrades
end

---Select an upgrade by index
---@param index number Index of the upgrade to select (1-based)
---@param player Entity The player entity (for regenerating upgrades)
---@return table|nil The selected upgrade definition, or nil if selection failed
function Upgrade:selectUpgrade(index, player)
    if index < 1 or index > self.maxUpgrades then
        print("[Upgrade] Cannot select: invalid index")
        return nil
    end
    
    local upgradeId = self.upgrades[index]
    if not upgradeId then
        print("[Upgrade] Cannot select: upgrade already selected or doesn't exist")
        return nil
    end
    
    -- Get upgrade definition before removing
    local upgradeDef = self:getUpgradeDefinition(upgradeId)
    if not upgradeDef then
        print("[Upgrade] Cannot select: upgrade definition not found for " .. upgradeId)
        return nil
    end
    
    print(string.format("[Upgrade] Selected '%s' from crystal %s", upgradeDef.name, self.crystalId))
    
    -- Regenerate upgrades after selection
    if player then
        self:generateRandomUpgrades(player)
    end
    
    return upgradeDef
end

---Get the number of upgrades available
---@return number Number of upgrades
function Upgrade:getUpgradeCount()
    return #self.upgrades
end

---Serialize the Upgrade component for saving
---@return table Serialized upgrade data
function Upgrade:serialize()
    return {
        upgrades = self.upgrades,
        maxUpgrades = self.maxUpgrades,
        crystalId = self.crystalId
    }
end

---Deserialize Upgrade component from saved data
---@param data table Serialized upgrade data
---@return Upgrade Recreated Upgrade component
function Upgrade.deserialize(data)
    -- Note: world reference is lost on deserialize, may need to regenerate upgrades
    local upgrade = Upgrade.new(nil, data.crystalId)
    upgrade.upgrades = data.upgrades or {}
    upgrade.maxUpgrades = data.maxUpgrades or 3
    return upgrade
end

return Upgrade

