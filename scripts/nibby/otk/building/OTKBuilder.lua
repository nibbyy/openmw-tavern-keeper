local markup = require('openmw.markup')
local util = require('openmw.util')
local world = require('openmw.world')

---@class OTKObjectPosData
---@field posX number X world coordinate where the object should be placed
---@field posY number Y world coordinate where the object should be placed
---@field posZ number Z world coordinate where the object should be placed
---@field rotX number|nil Optional X-axis rotation in degrees; defaults to 0
---@field rotY number|nil Optional Y-axis rotation in degrees; defaults to 0
---@field rotZ number|nil Optional Z-axis rotation in degrees; defaults to 0
---@field scale number|nil Optional object scale; defaults to 1
---@field cell any|nil Optional destination cell object
---@field cellName string|nil Optional destination cell name; empty string means exterior worldspace

---Loads a YAML file safely so a bad resource file gives a useful log message.
---@param filePath string Virtual OpenMW path to a YAML file
---@return table|nil yamlData Decoded YAML table, or nil on failure
local function loadYaml(filePath)
    local ok, yamlOrErr = pcall(markup.loadYaml, filePath)

    if not ok then
        print('[OTK - ERR] OTKBuilder.loadYaml failed for ' .. tostring(filePath) .. ': ' .. tostring(yamlOrErr))
        return nil
    end

    return yamlOrErr
end

---Builds spawn-ready position data from a placement YAML file
---@param filePath string Virtual OpenMW path to a YAML file with placement data
---@param cell any|nil Optional destination cell object
---@return OTKObjectPosData|nil posData Position data ready for spawnObject
local function buildYamlPosData(filePath, cell)
    local source = loadYaml(filePath)

    if type(source) ~= 'table' then
        print('[OTK - ERR] OTKBuilder.buildYamlPosData could not load position data')
        return nil
    end

    if type(source.posX) ~= 'number' or type(source.posY) ~= 'number' or type(source.posZ) ~= 'number' then
        print('[OTK - ERR] OTKBuilder.buildYamlPosData needs numeric posX, posY, and posZ')
        return nil
    end

    return {
        posX = source.posX,
        posY = source.posY,
        posZ = source.posZ,
        rotX = source.rotX or 0,
        rotY = source.rotY or 0,
        rotZ = source.rotZ or 0,
        scale = source.scale or 1,
        cell = cell,
        cellName = source.cellName,
    }
end

---Finds the first matching object for each requested record id in one cell scan.
---@param recordIds string[] Record ids to find
---@param cell any Cell to search
---@return table<string, any> objectsByRecordId Matching objects keyed by record id
local function findObjectsInCell(recordIds, cell)
    if not cell then
        print('[OTK - ERR] OTKBuilder.findObjectsInCell needs a cell')
        return {}
    end

    if type(recordIds) ~= 'table' then
        print('[OTK - ERR] OTKBuilder.findObjectsInCell needs recordIds of type table')
        return {}
    end

    local wanted = {}
    local remaining = 0

    for _, recordId in ipairs(recordIds) do
        if type(recordId) == 'string' and recordId ~= '' and not wanted[recordId] then
            wanted[recordId] = true
            remaining = remaining + 1
        end
    end

    if remaining == 0 then
        print('[OTK - ERR] OTKBuilder.findObjectsInCell needs at least one non-empty record id')
        return {}
    end

    local objectsByRecordId = {}

    for _, object in ipairs(cell:getAll()) do
        local recordId = object.recordId

        if wanted[recordId] and not objectsByRecordId[recordId] then
            objectsByRecordId[recordId] = object
            remaining = remaining - 1

            if remaining == 0 then
                return objectsByRecordId
            end
        end
    end

    return objectsByRecordId
end

---Finds an active cell by its display name.
---@param cellName string Interior cell name to look for
---@return any|nil cell Matching active cell, or nil if it is not loaded
local function findCellByName(cellName)
    if type(cellName) ~= 'string' or cellName == '' then
        print('[OTK - ERR] OTKBuilder.findCellByName needs a non-empty cellName of type string')
        return nil
    end

    for _, cell in ipairs(world.cells) do
        if cell.name == cellName then
            return cell
        end
    end

    print('[OTK - ERR] OTKBuilder.findCellByName could not find active cell: ' .. tostring(cellName))
    return nil
end

---Builds a placement rotation from editor-style degree values.
---OpenMW combines transforms right-to-left, so this applies Z first, then Y, then X
---@param posData OTKObjectPosData Position data with optional rotX, rotY, and rotZ degree values
---@return any rotation Transform ready for GameObject:teleport
local function buildRotation(posData)
    return util.transform.rotateX(math.rad(posData.rotX or 0))
        * util.transform.rotateY(math.rad(posData.rotY or 0))
        * util.transform.rotateZ(math.rad(posData.rotZ or 0))
end

---Creates and places one object in the world.
---@param recordId string Record id for the object to create
---@param posData OTKObjectPosData Position data, with optional rotation/scale/cell fields
---@return any|nil object The created OpenMW object, or nil if the input is invalid
local function spawnObject(recordId, posData)
    if type(recordId) ~= 'string' or recordId == '' then
        print('[OTK - ERR] OTKBuilder.spawnObject needs a non-empty recordId of type string')
        return nil
    end

    if type(posData) ~= 'table' then
        print('[OTK - ERR] OTKBuilder.spawnObject needs posData of type table')
        return nil
    end

    if type(posData.posX) ~= 'number' or type(posData.posY) ~= 'number' or type(posData.posZ) ~= 'number' then
        print('[OTK - ERR] OTKBuilder.spawnObject needs numeric posX, posY, and posZ in posData table')
        return nil
    end

    local object = world.createObject(recordId, 1)
    local position = util.vector3(posData.posX, posData.posY, posData.posZ)
    local rotation = buildRotation(posData)
    local cellOrName = posData.cell or posData.cellName or ''

    object:setScale(posData.scale or 1)
    object:teleport(cellOrName, position, rotation)

    return object
end

---Deletes a specific placed object by its unique reference id.
---@param referenceId string The object's unique reference id, not its record id
---@return boolean deleted True if an object was found and removed
local function deleteObject(referenceId)
    if type(referenceId) ~= 'string' or referenceId == '' then
        print('[OTK - ERR] OTKBuilder.deleteObject needs a non-empty referenceId of type string')
        return false
    end

    for _, cell in ipairs(world.cells) do
        for _, object in ipairs(cell:getAll()) do
            if object.id == referenceId then
                object:remove()
                return true
            end
        end
    end

    print('[OTK - ERR] OTKBuilder.deleteObject could not find object with referenceId: ' .. tostring(referenceId))
    return false
end

---Removes a placed object directly when another script already handed it to us.
---@param object any Object to remove
---@return boolean removed True if the object existed and was removed
local function removeObject(object)
    if not object then
        print('[OTK - ERR] OTKBuilder.removeObject needs an object')
        return false
    end

    if type(object.isValid) == 'function' and not object:isValid() then
        print('[OTK - ERR] OTKBuilder.removeObject received an invalid object')
        return false
    end

    if type(object.remove) ~= 'function' then
        print('[OTK - ERR] OTKBuilder.removeObject received an object without remove()')
        return false
    end

    object:remove()
    return true
end

---Enables a placed object
---@param object any Object to enable
---@return boolean enabled True if the object was enabled
local function enableObject(object)
    if not object then return false end

    object.enabled = true
    return true
end

---Disables a placed object
---@param object any Object to disable
---@return boolean disabled True if the object was disabled
local function disableObject(object)
    if not object then return false end

    object.enabled = false
    return true
end

---Attaches a custom script to an object if it does not already have it.
---@param object any Object that should receive the custom script
---@param script string VFS path to a CUSTOM script from the omwscripts file
---@return nil
local function attachScript(object, script)
    if not object then return end
    if object:hasScript(script) == true then return end

    object:addScript(script)
end

return {
    attachScript = attachScript,
    buildYamlPosData = buildYamlPosData,
    deleteObject = deleteObject,
    disableObject = disableObject,
    enableObject = enableObject,
    findCellByName = findCellByName,
    findObjectsInCell = findObjectsInCell,
    loadYaml = loadYaml,
    removeObject = removeObject,
    spawnObject = spawnObject,
}
