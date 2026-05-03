-- This file is mostly a handshake to attach Custom scripts to objects

local markup = require('openmw.markup')
local util = require('openmw.util')
local world = require('openmw.world')

local variables = require('scripts.nibby.otk.OTKVariables')

local DEGREES_TO_RADIANS = math.pi / 180

-- The YAML shape used to place one object in the world.
---@class OTKPlacedObjectData
---@field id string Object record id to create or find
---@field cell string Destination cell name
---@field script? string Local script path to attach
---@field posX? number X position in the target cell
---@field posY? number Y position in the target cell
---@field posZ? number Z position in the target cell
---@field rotX? number X rotation in degrees
---@field rotY? number Y rotation in degrees
---@field rotZ? number Z rotation in degrees
---@field scale? number Optional object scale

-- Temporary holder for the ledger while this script creates or updates it.
---@type any|nil
local currentObject = nil

-- Converts the YAML position numbers into an OpenMW vector.
---@param yamlTable OTKPlacedObjectData Object placement data from YAML
---@return any position util.vector3 position for teleport/createObject
local function getPosition(yamlTable)
    return util.vector3(
        yamlTable.posX or 0,
        yamlTable.posY or 0,
        yamlTable.posZ or 0
    )
end

-- Converts YAML rotation degrees into the transform OpenMW expects.
---@param yamlTable OTKPlacedObjectData Object placement data from YAML
---@return any rotation util.transform rotation for teleport
local function getRotation(yamlTable)
    -- OpenMW applies combined transforms right-to-left, so this composes Z/Y/X Euler angles.
    return util.transform.rotateX((yamlTable.rotX or 0) * DEGREES_TO_RADIANS)
        * util.transform.rotateY((yamlTable.rotY or 0) * DEGREES_TO_RADIANS)
        * util.transform.rotateZ((yamlTable.rotZ or 0) * DEGREES_TO_RADIANS)
end

-- Moves an object to the YAML position and applies the YAML scale.
---@param object any OpenMW object to move
---@param yamlTable OTKPlacedObjectData Object placement data from YAML
---@return nil
local function applyObjectTransform(object, yamlTable)
    if type(yamlTable.scale) == 'number' then
        object:setScale(yamlTable.scale)
    end

    object:teleport(yamlTable.cell, getPosition(yamlTable), { rotation = getRotation(yamlTable) })
end

-- Creates a new object from YAML after checking that the required fields are present.
---@param yamlTable OTKPlacedObjectData|table Object placement data from YAML
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

-- Attaches a local script to an object if it is not already attached.
---@param object any OpenMW object that should receive the script
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

-- Loads a YAML file safely; bad YAML should log an error instead of stopping setup.
---@param filePath string Virtual OpenMW path to a YAML file
---@return table|nil yamlData Decoded YAML table, or nil on failure
local function loadYaml(filePath)
    local ok, yamlOrErr = pcall(markup.loadYaml, filePath)

    if not ok then
        print('[OTK - ERR] OTKCustomAttacher.loadYaml failed for ' .. tostring(filePath) .. ': ' .. tostring(yamlOrErr))
        return nil
    end

    return yamlOrErr
end

-- Looks for an already-placed copy of the object so we do not create duplicates.
---@param yamlTable OTKPlacedObjectData|table Object placement data from YAML
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

-- When the tavern is entered, make sure the ledger exists and has its script.
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
