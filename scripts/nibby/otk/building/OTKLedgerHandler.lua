local builder = require('scripts.nibby.otk.building.OTKBuilder')

---@class OTKLedgerRecords
---@field closed any|nil Cached closed ledger object
---@field open any|nil Cached open ledger object

---@class OTKLedgerState
---@field scriptPath string Custom script attached to both ledger objects
---@field closedObjectId string Record id for the closed ledger
---@field openObjectId string Record id for the open ledger
---@field records OTKLedgerRecords Cached placed ledger objects

---Finds both ledger objects in a cell and stores them for quick swaps later
---@param ledger OTKLedgerState Ledger config and cache table
---@param cell any Cell to search
---@return OTKLedgerRecords records Cached closed and open ledger objects
local function findLedgers(ledger, cell)
    local found = builder.findObjectsInCell({
        ledger.closedObjectId,
        ledger.openObjectId,
    }, cell)

    ledger.records.closed = found[ledger.closedObjectId]
    ledger.records.open = found[ledger.openObjectId]

    builder.attachScript(ledger.records.closed, ledger.scriptPath)
    builder.attachScript(ledger.records.open, ledger.scriptPath)

    return ledger.records
end

---Swaps the activated ledger by enabling its counterpart and disabling itself
---@param ledger OTKLedgerState Ledger config and cache table
---@param eventData { recordId: string, ledger: any }
---@return nil
local function swapLedger(ledger, eventData)
    if type(eventData) ~= 'table' then return end

    local recordId = eventData.recordId
    local activeLedger = eventData.ledger

    if not activeLedger then return end

    if recordId == ledger.closedObjectId then
        ledger.records.closed = activeLedger

        if not ledger.records.open and activeLedger.cell then
            findLedgers(ledger, activeLedger.cell)
        end

        if ledger.records.open then
            builder.enableObject(ledger.records.open)
            builder.disableObject(activeLedger)
        end
    elseif recordId == ledger.openObjectId then
        ledger.records.open = activeLedger

        if not ledger.records.closed and activeLedger.cell then
            findLedgers(ledger, activeLedger.cell)
        end

        if ledger.records.closed then
            builder.enableObject(ledger.records.closed)
            builder.disableObject(activeLedger)
        end
    end
end

return {
    findLedgers = findLedgers,
    swapLedger = swapLedger,
}
