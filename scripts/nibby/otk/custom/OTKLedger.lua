local core = require('openmw.core')

---@param actor any Actor that activated the ledger
---@return nil
local function onActivated(actor)
    print('Ledger Activated!')
    core.sendGlobalEvent('SpawnNPC')
end

return {
    engineHandlers = {
        onActivated = onActivated,
    },
}
