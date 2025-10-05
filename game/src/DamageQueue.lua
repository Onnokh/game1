local DamageQueue = {}

DamageQueue._queue = {}
DamageQueue._processing = false

function DamageQueue:push(target, amount, source, damageType, knockback, effects)
    table.insert(self._queue, {
        target = target,
        amount = amount or 0,
        source = source,
        damageType = damageType,
        knockback = knockback or 0,
        effects = effects or {}
    })
end

function DamageQueue:getAll()
    return self._queue
end

function DamageQueue:clear()
    for i = #self._queue, 1, -1 do
        self._queue[i] = nil
    end
end

function DamageQueue:isProcessing()
    return self._processing
end

function DamageQueue:beginProcessing()
    self._processing = true
end

function DamageQueue:endProcessing()
    self._processing = false
end

return DamageQueue


