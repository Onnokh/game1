local System = require("src.core.System")

---@class ManaRegenerationSystem : System
---System that manages mana regeneration for all entities with Mana and Modifier components
local ManaRegenerationSystem = System:extend("ManaRegenerationSystem", {"Mana", "Modifier"})

-- Track regeneration timers per entity (Entity ID -> time accumulator)
local regenTimers = {}

---Update mana regeneration for all entities with Mana and Modifier components
---@param dt number Delta time
function ManaRegenerationSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local mana = entity:getComponent("Mana")
        local modifier = entity:getComponent("Modifier")

        if mana and modifier then
            local manaRecovery = modifier:getStat("mana_recovery") or 0

            -- Only regenerate if mana_recovery stat exists and is greater than 0
            if manaRecovery > 0 then
                -- Initialize timer if needed
                if not regenTimers[entity.id] then
                    regenTimers[entity.id] = 0
                end

                -- Only regenerate if not at full mana
                if not mana:isFullMana() then
                    local regenInterval = 5.0 -- 5 seconds
                    regenTimers[entity.id] = regenTimers[entity.id] + dt

                    -- Regenerate mana every 5 seconds (amount = mana_recovery stat)
                    if regenTimers[entity.id] >= regenInterval then
                        local amountToRestore = manaRecovery
                        mana:restoreMana(amountToRestore)
                        
                        -- Reset timer, keeping any excess time
                        regenTimers[entity.id] = regenTimers[entity.id] - regenInterval
                    end
                else
                    -- Reset timer when at full mana
                    regenTimers[entity.id] = 0
                end
            end
        end
    end
end

---Remove entity from regeneration tracking
---@param entity Entity The entity to remove
function ManaRegenerationSystem:removeEntity(entity)
    System.removeEntity(self, entity)
    if entity and entity.id then
        regenTimers[entity.id] = nil
    end
end

return ManaRegenerationSystem

