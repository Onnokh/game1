local Component = require("src.core.Component")

---@class Light : Component
---@field lights table Array of light configurations
---@field isMultiLight boolean Whether this component has multiple lights
local Light = {}
Light.__index = Light

---Create a new Light component
---Supports two APIs:
---1. Single light: Light.new({ radius = 100, r = 255, ... })
---2. Multiple lights: Light.new({ { radius = 100, ... }, { radius = 50, ... } })
---@param opts table|nil Single light config or array of light configs
---@return Component|Light
function Light.new(opts)
    local self = setmetatable(Component.new("Light"), Light)

    opts = opts or {}

    -- Detect if this is an array of light configs or a single light config
    -- Array detection: if opts[1] is a table, treat as multiple lights
    local isMultiLight = type(opts[1]) == "table"
    self.isMultiLight = isMultiLight

    if isMultiLight then
        -- Multiple lights API
        self.lights = {}
        for i, lightConfig in ipairs(opts) do
            table.insert(self.lights, {
                radius = lightConfig.radius or 400,
                r = lightConfig.r or 255,
                g = lightConfig.g or 255,
                b = lightConfig.b or 255,
                a = lightConfig.a or 255,
                offsetX = lightConfig.offsetX,
                offsetY = lightConfig.offsetY,
                lightId = nil, -- Changed from lightRef to lightId for Luven
                enabled = lightConfig.enabled ~= false,
                flicker = lightConfig.flicker == true,
                flickerSpeed = lightConfig.flickerSpeed or 8,
                flickerRadiusAmplitude = lightConfig.flickerRadiusAmplitude or 10,
                flickerAlphaAmplitude = lightConfig.flickerAlphaAmplitude or 20
            })
        end
    else
        -- Single light API (backward compatible)
        self.lights = {
            {
                radius = opts.radius or 400,
                r = opts.r or 255,
                g = opts.g or 255,
                b = opts.b or 255,
                a = opts.a or 255,
                offsetX = opts.offsetX,
                offsetY = opts.offsetY,
                lightId = nil, -- Changed from lightRef to lightId for Luven
                enabled = opts.enabled ~= false,
                flicker = opts.flicker == true,
                flickerSpeed = opts.flickerSpeed or 8,
                flickerRadiusAmplitude = opts.flickerRadiusAmplitude or 10,
                flickerAlphaAmplitude = opts.flickerAlphaAmplitude or 20
            }
        }
    end

    return self
end

---Serialize the Light component for saving
---@return table Serialized light data
function Light:serialize()
    -- Deep copy lights array but exclude lightId (will be recreated by LightSystem)
    local lightsData = {}
    for i, light in ipairs(self.lights) do
        lightsData[i] = {
            radius = light.radius,
            r = light.r,
            g = light.g,
            b = light.b,
            a = light.a,
            offsetX = light.offsetX,
            offsetY = light.offsetY,
            enabled = light.enabled,
            flicker = light.flicker,
            flickerSpeed = light.flickerSpeed,
            flickerRadiusAmplitude = light.flickerRadiusAmplitude,
            flickerAlphaAmplitude = light.flickerAlphaAmplitude
            -- lightId excluded - will be recreated by LightSystem
        }
    end

    return {
        lights = lightsData,
        isMultiLight = self.isMultiLight
    }
end

---Destroy this light component and clean up any resources
function Light:destroy()
    -- Remove lights from Luven if they have lightIds
    local luven = require("lib.luven.luven")
    for _, light in ipairs(self.lights) do
        if light.lightId then
            -- Try to remove the light from Luven
            -- Since Luven doesn't have individual light removal, we'll mark it as disabled
            -- and let the LightSystem handle the cleanup
            light.enabled = false
        end
    end
end

---Deserialize Light component from saved data
---@param data table Serialized light data
---@return Light Recreated Light component
function Light.deserialize(data)
    -- Reconstruct as multi-light if needed
    if data.isMultiLight then
        return Light.new(data.lights)
    else
        -- Single light
        local lightConfig = data.lights and data.lights[1]
        return Light.new(lightConfig or {})
    end
end

return Light
