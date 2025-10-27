---@class PostprocessingManager
local PostprocessingManager = {}

-- List of registered effects
PostprocessingManager.effects = {}
-- Global enable/disable flag
PostprocessingManager.enabled = true

---Register a postprocessing effect
---@param name string Unique name for the effect
---@param shader love.Shader The shader to use
---@param params table Table of shader parameters {paramName = value}
---@param enabled boolean Whether this effect is enabled by default
function PostprocessingManager.addEffect(name, shader, params, enabled)
    enabled = enabled or false

    PostprocessingManager.effects[name] = {
        shader = shader,
        params = params or {},
        enabled = enabled
    }

    print(string.format("[PostprocessingManager] Added effect: %s (enabled: %s)", name, tostring(enabled)))
end

---Register a complex postprocessing effect with its own apply() method
---@param name string Unique name for the effect
---@param effectInstance table Effect instance that implements apply() method
---@param enabled boolean Whether this effect is enabled by default
function PostprocessingManager.addComplexEffect(name, effectInstance, enabled)
    enabled = enabled or false

    PostprocessingManager.effects[name] = {
        effectInstance = effectInstance,
        enabled = enabled,
        isComplex = true
    }

    print(string.format("[PostprocessingManager] Added complex effect: %s (enabled: %s)", name, tostring(enabled)))
end

---Remove a postprocessing effect
---@param name string Name of the effect to remove
function PostprocessingManager.removeEffect(name)
    PostprocessingManager.effects[name] = nil
    print(string.format("[PostprocessingManager] Removed effect: %s", name))
end

---Enable or disable a specific effect
---@param name string Name of the effect
---@param enabled boolean Whether to enable or disable
function PostprocessingManager.setEffectEnabled(name, enabled)
    if PostprocessingManager.effects[name] then
        PostprocessingManager.effects[name].enabled = enabled
    end
end

---Update a parameter for a specific effect
---@param effectName string Name of the effect
---@param paramName string Name of the parameter to update
---@param value any New value for the parameter
function PostprocessingManager.setEffectParameter(effectName, paramName, value)
    if PostprocessingManager.effects[effectName] and PostprocessingManager.effects[effectName].params then
        PostprocessingManager.effects[effectName].params[paramName] = value
    end
end

---Toggle a specific effect
---@param name string Name of the effect to toggle
function PostprocessingManager.toggleEffect(name)
    if PostprocessingManager.effects[name] then
        PostprocessingManager.effects[name].enabled = not PostprocessingManager.effects[name].enabled
        print(string.format("[PostprocessingManager] %s is now %s", name, PostprocessingManager.effects[name].enabled and "enabled" or "disabled"))
    end
end

---Apply all enabled postprocessing effects to a canvas
---@param inputCanvas love.Canvas The canvas to process
---@param outputTarget love.Canvas|nil Where to draw the result (nil = screen)
function PostprocessingManager.apply(inputCanvas, outputTarget)
    if not PostprocessingManager.enabled or not inputCanvas then
        return
    end

    -- Track if we need canvas ping-ponging for multi-pass (simple effects only)
    local currentTexture = inputCanvas
    local tempCanvas = nil
    local needsCleanup = false

    -- Separate complex effects from simple shader effects
    local complexEffects = {}
    local simpleEffects = {}

    for name, effect in pairs(PostprocessingManager.effects) do
        if effect.enabled then
            if effect.isComplex and effect.effectInstance then
                table.insert(complexEffects, effect)
            elseif effect.shader then
                table.insert(simpleEffects, effect)
            end
        end
    end

    if #complexEffects == 0 and #simpleEffects == 0 then
        return
    end

    -- Create intermediate canvas if we need to chain complex → simple
    local intermediateCanvas = nil
    if #complexEffects > 0 and #simpleEffects > 0 then
        intermediateCanvas = love.graphics.newCanvas(inputCanvas:getWidth(), inputCanvas:getHeight())
        needsCleanup = true
    end

    -- Apply complex effects to intermediate canvas or screen
    for _, effect in ipairs(complexEffects) do
        if effect.effectInstance and effect.effectInstance.apply then
            effect.effectInstance:apply(inputCanvas, intermediateCanvas)
        end
    end

    -- If we have simple effects, use intermediate canvas as input (or original if no complex effects)
    if #simpleEffects > 0 then
        -- Update currentTexture to intermediate canvas if we chained complex effects
        if intermediateCanvas then
            currentTexture = intermediateCanvas
        end

        -- For multi-pass effects, we need a temporary canvas to ping-pong
        if #simpleEffects > 1 then
            tempCanvas = love.graphics.newCanvas(inputCanvas:getWidth(), inputCanvas:getHeight())
        end

        -- Apply each enabled effect in sequence
        local pass = 0
        for _, effect in ipairs(simpleEffects) do
            pass = pass + 1
            local isLastPass = pass == #simpleEffects

            -- Determine target canvas
            local targetCanvas = isLastPass and outputTarget or tempCanvas

            -- Set shader and parameters
            love.graphics.setShader(effect.shader)

            -- Send all parameters to the shader
            if effect.params then
                for paramName, value in pairs(effect.params) do
                    if effect.shader:hasUniform(paramName) then
                        effect.shader:send(paramName, value)
                    end
                end
            end

            -- Draw source to target with shader
            if targetCanvas then
                -- Check if we would render canvas to itself
                if currentTexture ~= targetCanvas then
                    love.graphics.setCanvas(targetCanvas)
                    love.graphics.clear(0, 0, 0, 1)
                    love.graphics.draw(currentTexture, 0, 0)
                    love.graphics.setCanvas()
                    currentTexture = targetCanvas
                end
            else
                -- Drawing to screen
                love.graphics.clear(0, 0, 0, 1)
                love.graphics.draw(currentTexture, 0, 0)
            end

            love.graphics.setShader()
        end
    end

    -- Cleanup temporary canvases
    if tempCanvas and needsCleanup then
        tempCanvas:release()
    end
    if intermediateCanvas and needsCleanup then
        intermediateCanvas:release()
    end
end

return PostprocessingManager

