local types = require('openmw.types')
local markup = require('openmw.markup')
local interfaces = require('openmw.interfaces')

---@class OTKBodyPartsInterface
---@field version integer
---@field bodyParts table
---@field registerNpcPart fun(raceId: string, genderOrIsMale: string|boolean|nil, partType: string, recordId: string): boolean
---@field selectNpcPart fun(raceId: string, genderOrIsMale: string|boolean|nil, partType: string): string|nil

---@class OTKNpcRecordData
---@field race string
---@field isMale boolean
---@field hair string
---@field head string
---@field class string
---@field isEssential boolean
---@field isRespawning boolean
---@field baseDisposition integer
---@field bloodType integer
---@field baseGold integer

---@param filePath string
---@return table|nil yamlData Decoded YAML table, or nil on failure
local function loadYaml(filePath)
    local ok, yamlOrErr = pcall(markup.loadYaml, filePath)

    if not ok then
        print('[OTK - ERR] OTKNPCSpawner.loadYaml failed for ' .. tostring(filePath) .. ': ' .. tostring(yamlOrErr))
        return nil
    end

    return yamlOrErr
end

---@return string|nil raceId
local function selectRace()
    local races = loadYaml('scripts/nibby/otk/npcs/resources/races.yaml')

    if type(races) ~= 'table' or #races == 0 then
        print('[OTK - ERR] OTKNPCSpawner.selectRace found no races to choose from')
        return nil
    end

    return races[math.random(1, #races)]
end

---@return string|nil classId
local function selectClass()
    local classes = loadYaml('scripts/nibby/otk/npcs/resources/classes.yaml')

    if type(classes) ~= 'table' or #classes == 0 then
        print('[OTK -ERR] OTKNPCSpawner.selectClass found no classes to choose from')
        return nil
    end

    return classes[math.random(1, #classes)]
end

---@return boolean isMale
local function selectIsMale()
    return math.random(1, 2) == 1
end

---@return any|nil npcRecordDraft OpenMW NPC record draft, or nil if required data is missing
local function buildNPC()
    print('Building an NPC...')
    local race = selectRace()
    local isMale = selectIsMale()
    local gender = isMale and 'male' or 'female'
    local class = selectClass()
    local bodyParts = interfaces.OTKBodyParts

    if not race then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC cannot create NPC draft without a race')
        return nil
    end

    if not class then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC cannot create NPC draft without a class')
        return nil
    end

    if not bodyParts then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC could not find OTKBodyParts interface')
        return nil
    end

    if type(bodyParts.selectNpcPart) ~= 'function' then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC OTKBodyParts interface is missing selectNpcPart')
        return nil
    end

    ---@cast bodyParts OTKBodyPartsInterface
    local hair = bodyParts.selectNpcPart(race, isMale, 'hair')
    local head = bodyParts.selectNpcPart(race, isMale, 'head')

    print("Race selected: " .. tostring(race))
    print("Gender selected: " .. gender)
    print("Class selected: " .. tostring(class))
    print("Hair selected: " .. tostring(hair))
    print("Head selected: " .. tostring(head))

    if not hair then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC found no hair for race=' .. tostring(race) .. ', gender=' .. gender)
        return nil
    end

    if not head then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC found no head for race=' .. tostring(race) .. ', gender=' .. gender)
        return nil
    end

    ---@type OTKNpcRecordData
    local npcRecordData = {
        race = race,
        isMale = isMale,
        hair = hair,
        head = head,
        class = class,
        isEssential = false,
        isRespawning = false,
        baseDisposition = 30,
        bloodType = 0,
        baseGold = 30,

        -- Continue building the NpcRecord draft here:
        -- id, name, class, model, stats, disposition, gold, services, etc.
    }

    local ok, npcRecordDraftOrErr = pcall(types.NPC.createRecordDraft, npcRecordData)

    if not ok then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC failed to create NPC record draft: ' .. tostring(npcRecordDraftOrErr))
        return nil
    end

    return npcRecordDraftOrErr
end

---@return nil
local function spawnNPC()
    local npcRecordDraft = buildNPC()

    if not npcRecordDraft then
        print('[OTK - ERR] OTKNPCSpawner.spawnNPC could not build NPC record draft')
        return
    end

    print('NPC record draft prepared: ' .. tostring(npcRecordDraft.id))
end

return {
    eventHandlers = {
        SpawnNPC = spawnNPC,
    },
    engineHandlers = {
    },
}
