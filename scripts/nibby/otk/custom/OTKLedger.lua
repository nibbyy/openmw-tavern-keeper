local core = require('openmw.core')

-- Called when the player activates the ledger object in the tavern.
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
