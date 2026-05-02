-- This file is mostly a handshake to attach Custom scripts to objects

local markup = require('openmw.markup')
local util = require('openmw.util')
local world = require('openmw.world')

local variables = require('scripts.nibby.otk.OTKVariables')

local DEGREES_TO_RADIANS = math.pi / 180

---@class OTKPlacedObjectData
---@field id string Object record id
---@field cell string Destination cell name
---@field script? string Local script path to attach
---@field posX? number
---@field posY? number
---@field posZ? number
---@field rotX? number
---@field rotY? number
---@field rotZ? number
---@field scale? number

---@type any|nil
local currentObject = nil

---@param yamlTable OTKPlacedObjectData
---@return any position util.vector3
local function getPosition(yamlTable)
    return util.vector3(
        yamlTable.posX or 0,
        yamlTable.posY or 0,
        yamlTable.posZ or 0
    )
end

---@param yamlTable OTKPlacedObjectData
---@return any rotation util.transform
local function getRotation(yamlTable)
    -- OpenMW applies combined transforms right-to-left, so this composes Z/Y/X Euler angles.
    return util.transform.rotateX((yamlTable.rotX or 0) * DEGREES_TO_RADIANS)
        * util.transform.rotateY((yamlTable.rotY or 0) * DEGREES_TO_RADIANS)
        * util.transform.rotateZ((yamlTable.rotZ or 0) * DEGREES_TO_RADIANS)
end

---@param object any OpenMW object
---@param yamlTable OTKPlacedObjectData
---@return nil
local function applyObjectTransform(object, yamlTable)
    if type(yamlTable.scale) == 'number' then
        object:setScale(yamlTable.scale)
    end

    object:teleport(yamlTable.cell, getPosition(yamlTable), { rotation = getRotation(yamlTable) })
end

---@param yamlTable OTKPlacedObjectData|table
---@return any|nil object Created OpenMW object, or nil if data is invalid
local function buildObject(yamlTable)
    if type(yamlTable) ~= 'table' then
        print('[OTK - ERR] OTKCustomAttacher.buildObject expected table, got: ' .. tostring(type(yamlTable)))
        return nil
    end

    if type(yamlTable.id) ~= 'string' or yamlTable.id == '' then
        print('[OTK - ERR] OTKCustomAttacher.buildObject missing object id')
        return nil
    end

    if type(yamlTable.cell) ~= 'string' or yamlTable.cell == '' then
        print('[OTK - ERR] OTKCustomAttacher.buildObject missing target cell for ' .. tostring(yamlTable.id))
        return nil
    end

    local object = world.createObject(yamlTable.id)
    applyObjectTransform(object, yamlTable)

    return object
end

---@param object any OpenMW object
---@param filePath string|nil Local script path
---@return boolean success
local function attachScript(object, filePath)
    if not object then
        print('[OTK - ERR] OTKCustomAttacher.attachScript missing object')
        return false
    end

    if type(filePath) ~= 'string' or filePath == '' then
        print('[OTK - ERR] OTKCustomAttacher.attachScript missing script path')
        return false
    end

    if not object:hasScript(filePath) then
        object:addScript(filePath)
    end

    return true
end

---@param filePath string
---@return table|nil yamlData Decoded YAML table, or nil on failure
local function loadYaml(filePath)
    local ok, yamlOrErr = pcall(markup.loadYaml, filePath)

    if not ok then
        print('[OTK - ERR] OTKCustomAttacher.loadYaml failed for ' .. tostring(filePath) .. ': ' .. tostring(yamlOrErr))
        return nil
    end

    return yamlOrErr
end

---@param yamlTable OTKPlacedObjectData|table
---@return any|nil object Existing matching object in the target cell
local function findObjectInCell(yamlTable)
    if type(yamlTable) ~= 'table' or type(yamlTable.cell) ~= 'string' or type(yamlTable.id) ~= 'string' then
        return nil
    end

    local ok, cellOrErr = pcall(world.getCellByName, yamlTable.cell)
    if not ok then
        print('[OTK - ERR] OTKCustomAttacher.findObjectInCell failed for cell ' .. tostring(yamlTable.cell) .. ': ' .. tostring(cellOrErr))
        return nil
    end

    local recordId = string.lower(yamlTable.id)
    for _, object in ipairs(cellOrErr:getAll()) do
        if object:isValid() and object.recordId == recordId then
            return object
        end
    end

    return nil
end

---@return nil
local function tavernEntered()
    if variables.checks.ledgerPlaced == false then
        local ledgerData = loadYaml('scripts/nibby/otk/building/objects/ledger.yaml')
        if not ledgerData then return end

        currentObject = findObjectInCell(ledgerData)
        if currentObject then
            applyObjectTransform(currentObject, ledgerData)
        else
            currentObject = buildObject(ledgerData)
        end

        if currentObject and attachScript(currentObject, ledgerData.script) then
            variables.checks.ledgerPlaced = true
            print('[OTK] Tavern ledger ready')
        end

        currentObject = nil
    end
end

return {
    eventHandlers = {
        TavernEntered = tavernEntered,
    }
}
