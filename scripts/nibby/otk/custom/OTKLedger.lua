local core = require('openmw.core')
local self = require('openmw.self')

---Tells the global tavern core which specific ledger instance was activated.
---@param actor any Actor that activated the ledger
---@return nil
local function onActivated(actor)
    core.sendGlobalEvent('SwapLedger', {
        recordId = self.object.recordId,
        ledger = self.object,
    })
end

return {
    engineHandlers = {
        onActivated = onActivated,
    },
}
