local Component = require("src.core.Component")

---@class Modifier : Component
---@field activeModifiers table<string, ModifierData> Keyed by source identifier
---@field baseValues table<string, number> Stored base values for each targetPath
local Modifier = {}
Modifier.__index = Modifier

---@class ModifierData
---@field targetPath string Path to stat (e.g., "Movement.maxSpeed", "Health.max")
---@field mode string "multiply" or "add"
---@field value number Modifier value

---Create a new Modifier component
---@return Component|Modifier
function Modifier.new()
    local self = setmetatable(Component.new("Modifier"), Modifier)
    self.activeModifiers = {}
    self.baseValues = {}
    return self
end

---Parse a target path into component name and stat path
---@param targetPath string Full path like "Movement.maxSpeed" or "Weapon.inventory.ranged.damage"
---@return string componentName
---@return string statPath Remaining path after component (e.g., "maxSpeed" or "inventory.ranged.damage")
function Modifier:_parsePath(targetPath)
    local componentName, statPath = targetPath:match("^([^.]+)%.(.+)$")
    if not componentName or not statPath then
        error("Invalid targetPath: " .. tostring(targetPath) .. ". Expected format: 'ComponentName.stat.path'")
    end
    return componentName, statPath
end

---Get a nested value from a table using a dot-separated path
---@param tbl table The table to traverse
---@param path string Dot-separated path (e.g., "inventory.ranged.damage")
---@return any The value at the path, or nil if not found
function Modifier:_getNestedValue(tbl, path)
    local keys = {}
    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end
    
    local current = tbl
    for _, key in ipairs(keys) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[key]
        if current == nil then
            return nil
        end
    end
    
    return current
end

---Set a nested value in a table using a dot-separated path
---@param tbl table The table to modify
---@param path string Dot-separated path (e.g., "inventory.ranged.damage")
---@param value any The value to set
function Modifier:_setNestedValue(tbl, path, value)
    local keys = {}
    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end
    
    local current = tbl
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            error("Cannot set nested value: path '" .. path .. "' is invalid at key '" .. key .. "'")
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

---Apply a modifier to a target stat path
---@param entity Entity The entity to modify
---@param targetPath string Path to stat (e.g., "Movement.maxSpeed", "Health.max")
---@param mode string Mode: "multiply" or "add"
---@param value number Value to apply
---@param source string Unique identifier for this modifier source
function Modifier:apply(entity, targetPath, mode, value, source)
    if not entity then
        error("Modifier:apply - entity is nil")
    end
    
    -- Parse path
    local componentName, statPath = self:_parsePath(targetPath)
    
    -- Get component
    local component = entity:getComponent(componentName)
    if not component then
        print(string.format("[Modifier] Warning: Component '%s' not found on entity", componentName))
        return
    end
    
    -- Store base value if this is the first modifier for this path
    if not self.baseValues[targetPath] then
        local currentValue = self:_getNestedValue(component, statPath)
        if currentValue == nil then
            print(string.format("[Modifier] Warning: Could not get value at path '%s' in component '%s'", statPath, componentName))
            return
        end
        self.baseValues[targetPath] = currentValue
        print(string.format("[Modifier] Stored base value for '%s': %s", targetPath, tostring(currentValue)))
    end
    
    -- Add or update modifier
    self.activeModifiers[source] = {
        targetPath = targetPath,
        mode = mode,
        value = value
    }
    
    print(string.format("[Modifier] Applied modifier '%s': %s %s at '%s'", source, mode, tostring(value), targetPath))
    
    -- Recalculate stat
    self:_updateStat(entity, targetPath)
end

---Remove a modifier by source
---@param entity Entity The entity to modify
---@param source string Unique identifier for the modifier source
function Modifier:remove(entity, source)
    if not self.activeModifiers[source] then
        print(string.format("[Modifier] Warning: Modifier source '%s' not found", source))
        return
    end
    
    local targetPath = self.activeModifiers[source].targetPath
    self.activeModifiers[source] = nil
    
    print(string.format("[Modifier] Removed modifier '%s' from '%s'", source, targetPath))
    
    -- Recalculate stat
    self:_updateStat(entity, targetPath)
end

---Recalculate a stat from base value + all active modifiers
---@param entity Entity The entity to update
---@param targetPath string Path to the stat to update
function Modifier:_updateStat(entity, targetPath)
    -- Get base value
    local baseValue = self.baseValues[targetPath]
    if not baseValue then
        print(string.format("[Modifier] Warning: No base value found for '%s'", targetPath))
        return
    end
    
    -- Start with base value
    local finalValue = baseValue
    
    -- Collect all modifiers for this path
    local addModifiers = 0
    local multiplyModifiers = 1.0
    
    for source, modifier in pairs(self.activeModifiers) do
        if modifier.targetPath == targetPath then
            if modifier.mode == "add" then
                addModifiers = addModifiers + modifier.value
            elseif modifier.mode == "multiply" then
                multiplyModifiers = multiplyModifiers * modifier.value
            end
        end
    end
    
    -- Apply modifiers: first add, then multiply
    finalValue = (finalValue + addModifiers) * multiplyModifiers
    
    -- Parse path and update component
    local componentName, statPath = self:_parsePath(targetPath)
    local component = entity:getComponent(componentName)
    
    if component then
        self:_setNestedValue(component, statPath, finalValue)
        print(string.format("[Modifier] Updated '%s' from %.2f to %.2f", targetPath, baseValue, finalValue))
    end
end

---Check if a modifier is active
---@param source string Unique identifier for the modifier source
---@return boolean True if the modifier is active
function Modifier:hasModifier(source)
    return self.activeModifiers[source] ~= nil
end

---Serialize the Modifier component for saving
---@return table Serialized modifier data
function Modifier:serialize()
    return {
        activeModifiers = self.activeModifiers,
        baseValues = self.baseValues
    }
end

---Deserialize Modifier component from saved data
---@param data table Serialized modifier data
---@return Modifier Recreated Modifier component
function Modifier.deserialize(data)
    local modifier = Modifier.new()
    modifier.activeModifiers = data.activeModifiers or {}
    modifier.baseValues = data.baseValues or {}
    return modifier
end

return Modifier

