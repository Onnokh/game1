local System = require("src.core.System")
local PlayerStats = require("src.definitions.playerStats")

---@class PlayerStatsSystem : System
---System that applies player stats from PlayerStats definition to actual components
---Handles level scaling and coordinates with Modifier component for upgrades
local PlayerStatsSystem = System:extend("PlayerStatsSystem", {"PlayerLevel", "Modifier"})

---Update and apply stats to all entities with PlayerLevel and Modifier components
---@param dt number Delta time
function PlayerStatsSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local playerLevel = entity:getComponent("PlayerLevel")
        local modifier = entity:getComponent("Modifier")

        if playerLevel and modifier then
            self:applyStats(entity, playerLevel, modifier)
        end
    end
end

---Apply stats from PlayerStats definition to entity components
---@param entity Entity The entity to apply stats to
---@param playerLevel PlayerLevel The player level component
---@param modifier Modifier The modifier component
function PlayerStatsSystem:applyStats(entity, playerLevel, modifier)
    local level = playerLevel:getLevel()

    -- Apply stats that go directly into Modifier.stats
    local manaRecovery = PlayerStats.getStatAtLevel("mana_recovery", level)
    if manaRecovery then
        modifier:setStat("mana_recovery", manaRecovery)
    end

    -- Apply stats to components that can be modified by upgrades
    -- Use modifier system's baseValues tracking

    -- Health
    local health = entity:getComponent("Health")
    if health then
        local maxHealth = PlayerStats.getStatAtLevel("max_health", level)
        if maxHealth then
            local targetPath = "Health.max"
            if modifier.baseValues[targetPath] == nil then
                -- First time: store current value as base, then set new base
                modifier.baseValues[targetPath] = maxHealth
                health:setMaxHealth(maxHealth)
            elseif modifier.baseValues[targetPath] ~= maxHealth then
                -- Level changed: update base value and recalculate
                modifier.baseValues[targetPath] = maxHealth
                modifier:_updateStat(entity, targetPath)
            end
        end
    end

    -- Mana
    local mana = entity:getComponent("Mana")
    if mana then
        local maxMana = PlayerStats.getStatAtLevel("max_mana", level)
        if maxMana then
            local targetPath = "Mana.max"
            if modifier.baseValues[targetPath] == nil then
                modifier.baseValues[targetPath] = maxMana
                mana:setMaxMana(maxMana)
            elseif modifier.baseValues[targetPath] ~= maxMana then
                modifier.baseValues[targetPath] = maxMana
                modifier:_updateStat(entity, targetPath)
            end
        end
    end

    -- Movement Speed
    local movement = entity:getComponent("Movement")
    if movement then
        local speed = PlayerStats.getStatAtLevel("movement_speed", level)
        if speed then
            local targetPath = "Movement.maxSpeed"
            if modifier.baseValues[targetPath] == nil then
                modifier.baseValues[targetPath] = speed
                movement.maxSpeed = speed
            elseif modifier.baseValues[targetPath] ~= speed then
                modifier.baseValues[targetPath] = speed
                modifier:_updateStat(entity, targetPath)
            end
        end
    end

    -- Dash Charges
    local dashCharges = entity:getComponent("DashCharges")
    if dashCharges then
        local maxCharges = PlayerStats.getStatAtLevel("dash_max_charges", level)
        if maxCharges then
            dashCharges:setMaxCharges(maxCharges)
        end

        local regenTime = PlayerStats.getStatAtLevel("dash_charge_regen_time", level)
        if regenTime then
            -- Ensure minimum value (can't go below 0.1)
            regenTime = math.max(0.1, regenTime)
            dashCharges:setChargeRegenTime(regenTime)
        end
    end
end

return PlayerStatsSystem
