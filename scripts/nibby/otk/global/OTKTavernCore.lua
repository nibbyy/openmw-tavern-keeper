-- Global tavern orchestration: attaches local object scripts and handles tavern events.
local builder = require('scripts.nibby.otk.building.OTKBuilder')
local ledgerHandler = require('scripts.nibby.otk.building.OTKLedgerHandler')

---@class OTKTavernCellState
---@field name string|nil Current tavern cell name

---@class OTKTavernState
---@field ledger OTKLedgerState Ledger config and cached placed ledger objects
---@field cell OTKTavernCellState Current tavern cell state

---@class OTKTavernCoreState
---@field tavern OTKTavernState Tavern runtime state

---@type OTKTavernCoreState
local OTKCore = {
    tavern = {
        ledger = {
            scriptPath = 'scripts/nibby/otk/custom/OTKLedger.lua',
            closedObjectId = 'otk_ledger_closed',
            openObjectId = 'otk_ledger_open',
            records = {
                closed = nil,
                open = nil,
            },
        },
        cell = {
            name = nil,
        },
    },
}

---Passes ledger activation events to the ledger handler
---@param eventData { recordId: string, ledger: any }
---@return nil
local function swapLedger(eventData)
    ledgerHandler.swapLedger(OTKCore.tavern.ledger, eventData)
end

---Stores the current tavern cell and runs one-time tavern object setup.
---@param eventData { cellName: string }
---@return nil
local function tavernEntered(eventData)
    if type(eventData) ~= 'table' then return end
    if type(eventData.cellName) ~= 'string' or eventData.cellName == '' then return end

    local cell = builder.findCellByName(eventData.cellName)
    if not cell then return end

    local tavern = OTKCore.tavern
    local records = tavern.ledger.records
    local shouldRefreshLedgers = tavern.cell.name ~= eventData.cellName
        or not records.closed
        or not records.open

    if shouldRefreshLedgers then
        tavern.cell.name = eventData.cellName
        ledgerHandler.findLedgers(tavern.ledger, cell)
    end

    if records.closed and records.open and records.closed.enabled and records.open.enabled then
        builder.disableObject(records.open)
    end
end

return {
    eventHandlers = {
        TavernEntered = tavernEntered,
        SwapLedger = swapLedger,
    }
}