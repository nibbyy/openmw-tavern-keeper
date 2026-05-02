---@class OTKChecks
---@field tavernEntered boolean
---@field ledgerPlaced boolean

---@class OTKVariables
---@field checks OTKChecks
---@field unlocks table<string, boolean>

---@type OTKVariables
local variables = {
    checks = {
        tavernEntered = false,
        ledgerPlaced = false,
    },
    unlocks = {},
}

return variables
