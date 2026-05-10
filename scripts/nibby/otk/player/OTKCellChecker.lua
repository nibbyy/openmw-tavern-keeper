local self = require('openmw.self')
local core = require('openmw.core')

---Notifies the global tavern script when the player is inside the tavern cell.
---@return nil
local function checkCurrentCell()
    local cell = self.cell
    if not cell then return end

    if cell.name == 'Your Tavern' then
        -- Events can only carry plain values, so send the name instead of the cell object
        core.sendGlobalEvent('TavernEntered', { cellName = cell.name })
    end
end

return {
    engineHandlers = {
        onTeleported = checkCurrentCell,
    }
}
