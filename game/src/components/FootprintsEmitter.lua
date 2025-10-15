---@class FootprintsEmitter
---Reusable emitter for spawning fading footprint ovals while moving
---@field spacing number Distance between successive prints per limb (pixels)
---@field lifetime number Lifetime of each footprint (seconds)
---@field baseAlpha number Initial alpha at spawn (0-1)
---@field limbs table Array of limb configs: { lateral:number, phase:number }
---@field maxCount number Max prints tracked per emitter hint (system enforces globally)
---@field pausedByStates table|nil Array of state names that pause emission
---@field _lastX number|nil
---@field _lastY number|nil
---@field _accumulators table Internal per-limb distance accumulators
---@field _nextSpacing table Internal per-limb next spacing target (with jitter)
local FootprintsEmitter = {}
FootprintsEmitter.__index = FootprintsEmitter

local Component = require("src.core.Component")

---Create a new FootprintsEmitter component
---@param config table|nil { spacing, lifetime, baseAlpha, limbs, maxCount, pausedByStates }
---@return Component|FootprintsEmitter
function FootprintsEmitter.new(config)
    local self = setmetatable(Component.new("FootprintsEmitter"), FootprintsEmitter)

    config = config or {}
    self.spacing = config.spacing or 12
    self.lifetime = config.lifetime or 2.5
    self.baseAlpha = config.baseAlpha or 0.45
    self.maxCount = config.maxCount or 300
    self.pausedByStates = config.pausedByStates

    -- Limbs: each limb has lateral (px) and phase [0..1)
    self.limbs = config.limbs or {
        { lateral = -3, phase = 0.0 },
        { lateral =  3, phase = 0.5 }
    }

    -- Internal state
    self._lastX, self._lastY = nil, nil
    self._accumulators = {}
    self._nextSpacing = {}
    for i, limb in ipairs(self.limbs) do
        -- Seed accumulators so initial emission is phase-shifted
        self._accumulators[i] = -(limb.phase or 0) * self.spacing
        -- Seed next spacing with slight positive jitter (at least base spacing)
        self._nextSpacing[i] = self.spacing * (1.05 + (math.random()) * 0.20)
    end

    return self
end

---Reset emitter tracking (e.g., when pausing due to dash)
function FootprintsEmitter:resetTracking(x, y)
    -- Only update last known position; keep per-limb accumulators to preserve phase
    self._lastX, self._lastY = x, y
end

return FootprintsEmitter


