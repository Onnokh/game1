local EventBus = {}

-- Simple publish/subscribe bus for decoupling game logic from UI
-- Usage:
-- EventBus.subscribe("entityDamaged", function(payload) ... end)
-- EventBus.emit("entityDamaged", { target = e, amount = 10 })

local subscribers = {}

function EventBus.subscribe(eventName, handler)
	subscribers[eventName] = subscribers[eventName] or {}
	table.insert(subscribers[eventName], handler)
end

function EventBus.emit(eventName, payload)
	local list = subscribers[eventName]
	if not list then return end
	for i = 1, #list do
		local ok, err = pcall(list[i], payload)
		if not ok then
			print(string.format("EventBus handler error for '%s': %s", tostring(eventName), tostring(err)))
		end
	end
end

return EventBus


