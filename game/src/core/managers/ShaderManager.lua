---@class ShaderManager
local ShaderManager = {}

-- Shader cache
local shaders = {}

-- Noise texture cache
local noiseTexture = nil

---Load a shader from files
---@param name string Name of the shader
---@param vertPath string Path to vertex shader file
---@param fragPath string Path to fragment shader file
---@return love.Shader|nil
function ShaderManager.loadShader(name, vertPath, fragPath)
    if shaders[name] then
        return shaders[name]
    end

    local vertSource = love.filesystem.read(vertPath)
    local fragSource = love.filesystem.read(fragPath)

    if not vertSource or not fragSource then
        print("ERROR: Failed to load shader files for", name)
        return nil
    end

    local shader = love.graphics.newShader(vertSource, fragSource)
    if not shader then
        print("ERROR: Failed to compile shader", name)
        return nil
    end

    shaders[name] = shader
    print("Loaded shader:", name)
    return shader
end

---Get a loaded shader
---@param name string Name of the shader
---@return love.Shader|nil
function ShaderManager.getShader(name)
    return shaders[name]
end

---Set shader uniform
---@param shader love.Shader The shader to set uniform on
---@param name string Uniform name
---@param value any Uniform value
function ShaderManager.setUniform(shader, name, value)
    if shader and shader:hasUniform(name) then
        shader:send(name, value)
    end
end

---Get the wind noise texture for foliage sway
---@return love.Image|nil
function ShaderManager.getNoiseTexture()
    return noiseTexture
end

---Load all default shaders
function ShaderManager.loadDefaultShaders()
    ShaderManager.loadShader("flash", "src/shaders/flash_shader.vert", "src/shaders/flash_shader.frag")
    ShaderManager.loadShader("damage_number", "src/shaders/damage_number_shader.vert", "src/shaders/damage_number_shader.frag")
    ShaderManager.loadShader("vignette", "src/shaders/vignette_shader.vert", "src/shaders/vignette_shader.frag")
    ShaderManager.loadShader("aim_line", "src/shaders/aim_line_shader.vert", "src/shaders/aim_line_shader.frag")
    ShaderManager.loadShader("outline", "src/shaders/outline_shader.vert", "src/shaders/outline_shader.frag")
    ShaderManager.loadShader("speed_lines", "src/shaders/speed_lines_shader.vert", "src/shaders/speed_lines_shader.frag")
    ShaderManager.loadShader("foliage_sway", "src/shaders/foliage_sway_shader.vert", "src/shaders/foliage_sway_shader.frag")
    ShaderManager.loadShader("glow", "src/shaders/glow_shader.vert", "src/shaders/glow_shader.frag")
    ShaderManager.loadShader("threshold", "src/shaders/threshold_shader.vert", "src/shaders/threshold_shader.frag")
    ShaderManager.loadShader("bloom", "src/shaders/bloom_shader.vert", "src/shaders/bloom_shader.frag")
    ShaderManager.loadShader("bloom_blur", "src/shaders/bloom_blur_shader.vert", "src/shaders/bloom_blur_shader.frag")
    ShaderManager.loadShader("color_grade", "src/shaders/color_grade_shader.vert", "src/shaders/color_grade_shader.frag")
    ShaderManager.loadShader("vignette", "src/shaders/vignette_shader.vert", "src/shaders/vignette_shader.frag")

    -- Load wind noise texture for foliage sway (clear cache to regenerate with fixed tiling)
    local NoiseGenerator = require("src.utils.noiseGenerator")
    NoiseGenerator.clearCache()
    noiseTexture = NoiseGenerator.getWindNoiseTexture()
end

return ShaderManager
