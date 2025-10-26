-- EventAnimations.lua
-- Centralized animation configuration for Event entities

local EventAnimations = {}

-- Animation configurations for Event entities
EventAnimations.configs = {
    -- Spawn animation (frames 1-3)
    spawn = {
        layers = {'event', 'event-gem'},
        frames = {1, 2, 3},
        fps = 6,
        loop = false
    },

    -- Idle animation (frame 12)
    idle = {
        layers = {'event', 'event-gem'},
        frames = {2, 3},
        fps = 6,
        loop = true
    },

    -- Activating animation (frames 12-22)
    activating = {
        layers = {'event', 'event-gem'},
        frames = {12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22},
        fps = 8,
        loop = false
    },

    -- Active animation (frames 18-22, looping)
    active = {
        layers = {'event', 'event-gem'},
        frames = {18, 19, 20, 21, 22},
        fps = 8,
        loop = true
    },

    -- Deactivating animation (frames 22-12, reverse)
    deactivating = {
        layers = {'event', 'event-gem'},
        frames = {22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12},
        fps = 8,
        loop = false
    },

    -- Destroy animation (frames 23-25)
    destroy = {
        layers = {'event', 'event-gem'},
        frames = {23, 24, 25},
        fps = 6,
        loop = false
    }
}

-- Helper function to get animation config by name
function EventAnimations.get(name)
    return EventAnimations.configs[name]
end

-- Helper function to get all animation names
function EventAnimations.getNames()
    local names = {}
    for name, _ in pairs(EventAnimations.configs) do
        table.insert(names, name)
    end
    return names
end

return EventAnimations
