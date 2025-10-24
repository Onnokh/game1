---@class Animator
---@field layers table Array of sheet names for multi-layer animation
---@field frames table List of frame indices to play
---@field fps number Frames per second
---@field loop boolean Whether animation loops
---@field time number Accumulated time
---@field playing boolean Is animation playing
---@field layerRotations table Per-layer rotation values (key: layer name, value: rotation in radians)
---@field layerOffsets table Per-layer position offsets (key: layer name, value: {x, y})
---@field layerPivots table Per-layer rotation pivot points (key: layer name, value: {x, y})
---@field layerScales table Per-layer scale values (key: layer name, value: {x, y})
local Animator = {}
Animator.__index = Animator

---Create a new Animator component
---@param config table Animation config table with {layers, frames, fps, loop}
---@return Component|Animator
function Animator.new(config)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Animator"), Animator)

    self.layers = config.layers or {""}
    self.frames = config.frames or {1}
    self.fps = config.fps or 6
    self.loop = config.loop ~= false
    self.time = 0
    self.playing = true
    self.layerRotations = {}
    self.layerOffsets = {}
    self.layerPivots = {}
    self.layerScales = {}

    return self
end

---Update animation timer
---@param dt number
function Animator:update(dt)
    if not self.playing or #self.frames <= 1 or self.fps <= 0 then return end
    self.time = self.time + dt
    if not self.loop then
        local total = (#self.frames) / self.fps
        if self.time > total then
            self.time = total
            self.playing = false
        end
    end
end

---Get current frame index (into iffy tileset)
---@return integer
function Animator:getCurrentFrame()
    if #self.frames == 0 then return 1 end
    local frameNumber = math.floor(self.time * self.fps)
    if self.loop then
        frameNumber = frameNumber % #self.frames
    else
        frameNumber = math.min(frameNumber, #self.frames - 1)
    end
    return self.frames[frameNumber + 1]
end

---Change the active animation
---@param config table Animation config table with {layers, frames, fps, loop}
function Animator:setAnimation(config)
    self.layers = config.layers or self.layers
    self.frames = config.frames or self.frames
    self.fps = config.fps or self.fps
    if config.loop ~= nil then self.loop = config.loop end
    self.time = 0
    self.playing = true
end

---Set rotation for a specific layer
---@param layerName string The name of the layer
---@param rotation number Rotation in radians
function Animator:setLayerRotation(layerName, rotation)
    self.layerRotations[layerName] = rotation
end

---Get rotation for a specific layer
---@param layerName string The name of the layer
---@return number Rotation in radians (0 if not set)
function Animator:getLayerRotation(layerName)
    return self.layerRotations[layerName] or 0
end

---Set pivot offset for a specific layer
---@param layerName string The name of the layer
---@param x number X offset
---@param y number Y offset
function Animator:setLayerOffset(layerName, x, y)
    self.layerOffsets[layerName] = {x = x, y = y}
end

---Get pivot offset for a specific layer
---@param layerName string The name of the layer
---@return table Offset table {x, y} (returns {x=0, y=0} if not set)
function Animator:getLayerOffset(layerName)
    return self.layerOffsets[layerName] or {x = 0, y = 0}
end

---Set rotation pivot point for a specific layer
---@param layerName string The name of the layer
---@param x number X pivot point
---@param y number Y pivot point
function Animator:setLayerPivot(layerName, x, y)
    self.layerPivots[layerName] = {x = x, y = y}
end

---Get rotation pivot point for a specific layer
---@param layerName string The name of the layer
---@return table Pivot table {x, y} (returns {x=0, y=0} if not set)
function Animator:getLayerPivot(layerName)
    return self.layerPivots[layerName] or {x = 0, y = 0}
end

---Set scale for a specific layer
---@param layerName string The name of the layer
---@param scaleX number X scale factor
---@param scaleY number|nil Y scale factor, defaults to scaleX
function Animator:setLayerScale(layerName, scaleX, scaleY)
    self.layerScales[layerName] = {x = scaleX, y = scaleY or scaleX}
end

---Get scale for a specific layer
---@param layerName string The name of the layer
---@return table Scale table {x, y} (returns {x=1, y=1} if not set)
function Animator:getLayerScale(layerName)
    return self.layerScales[layerName] or {x = 1, y = 1}
end

---Serialize the Animator component for saving
---@return table Serialized animator data
function Animator:serialize()
    return {
        layers = self.layers,
        frames = self.frames,
        fps = self.fps,
        loop = self.loop,
        time = self.time,
        playing = self.playing,
        layerRotations = self.layerRotations,
        layerOffsets = self.layerOffsets,
        layerPivots = self.layerPivots,
        layerScales = self.layerScales
    }
end

---Deserialize Animator component from saved data
---@param data table Serialized animator data
---@return Animator|Component Recreated Animator component
function Animator.deserialize(data)
    local animator = Animator.new({
        layers = data.layers,
        frames = data.frames,
        fps = data.fps,
        loop = data.loop
    })
    animator.time = data.time or 0
    animator.playing = data.playing ~= false
    animator.layerRotations = data.layerRotations or {}
    animator.layerOffsets = data.layerOffsets or {}
    animator.layerPivots = data.layerPivots or {}
    animator.layerScales = data.layerScales or {}
    return animator
end

return Animator


