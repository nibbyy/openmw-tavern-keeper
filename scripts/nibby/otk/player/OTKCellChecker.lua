local core = require('openmw.core')
local self = require('openmw.self')

local variables = require('scripts.nibby.otk.OTKVariables')

---@return nil
local function checkCell()
    local cell = self.cell.name

    if cell == "Your Tavern" then
        print("Tavern entered!")
        variables.checks.tavernEntered = true
        core.sendGlobalEvent('TavernEntered')
    else
        variables.checks.tavernEntered = false
    end
end

return {
    engineHandlers = {
        onLoad = checkCell,
        onTeleported = checkCell,
    }
}
