---@class ShaderManager
local ShaderManager = {}

-- Shader cache
local shaders = {}

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

---Load all default shaders
function ShaderManager.loadDefaultShaders()
    ShaderManager.loadShader("flash", "src/shaders/flash_shader.vert", "src/shaders/flash_shader.frag")
    ShaderManager.loadShader("damage_number", "src/shaders/damage_number_shader.vert", "src/shaders/damage_number_shader.frag")
    ShaderManager.loadShader("vignette", "src/shaders/vignette_shader.vert", "src/shaders/vignette_shader.frag")
    ShaderManager.loadShader("aim_line", "src/shaders/aim_line_shader.vert", "src/shaders/aim_line_shader.frag")
    ShaderManager.loadShader("outline", "src/shaders/outline_shader.vert", "src/shaders/outline_shader.frag")
end

return ShaderManager
