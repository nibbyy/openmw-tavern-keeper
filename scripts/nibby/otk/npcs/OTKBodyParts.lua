local markup = require('openmw.markup')

local RACE_FILE = 'scripts/nibby/otk/npcs/resources/races.yaml'

---@alias OTKGender 'female'|'male'
---@alias OTKNpcPartType 'hair'|'head'

---@class OTKBodyPartRecord
---@field race string
---@field gender? OTKGender
---@field isMale? boolean
---@field type OTKNpcPartType|string
---@field id string

---@type OTKBodyPartRecord[]
local NPC_PART_RECORDS = {
    -- Add head and hair IDs here as you discover them.
    -- Example:
    -- { race = 'Dark Elf', isMale = true, type = 'hair', id = 'b_n_dark elf_m_hair_01' },
    -- { race = 'Dark Elf', isMale = true, type = 'head', id = 'b_n_dark elf_m_head_01' },
}

---@class OTKGenderParts
---@field hair string[]
---@field head string[]

---@class OTKRaceParts
---@field female OTKGenderParts
---@field male OTKGenderParts

---@type table<string, OTKRaceParts>
local bodyParts = {}
local isBuilt = false

---@param value any
---@return string
local function normalizeKey(value)
    return string.lower(tostring(value or '')):gsub('%s+', '_')
end

---@param raceId string
---@return OTKRaceParts
local function ensureRace(raceId)
    local raceKey = normalizeKey(raceId)

    if raceKey == '' then
        raceKey = 'unknown'
    end

    if not bodyParts[raceKey] then
        bodyParts[raceKey] = {
            female = {
                hair = {},
                head = {},
            },
            male = {
                hair = {},
                head = {},
            },
        }
    end

    return bodyParts[raceKey]
end

---@return nil
local function clearBodyParts()
    for key in pairs(bodyParts) do
        bodyParts[key] = nil
    end
end

---@param filePath string
---@return table|nil yamlData Decoded YAML table, or nil on failure
local function loadYaml(filePath)
    local ok, yamlOrErr = pcall(markup.loadYaml, filePath)

    if not ok then
        print('[OTK - ERR] OTKBodyParts.loadYaml failed for ' .. tostring(filePath) .. ': ' .. tostring(yamlOrErr))
        return nil
    end

    return yamlOrErr
end

---@param genderOrIsMale OTKGender|boolean|nil
---@return OTKGender|nil
local function normalizeGender(genderOrIsMale)
    if genderOrIsMale == 'male' or genderOrIsMale == 'female' then
        return genderOrIsMale
    end

    if genderOrIsMale ~= nil then
        return genderOrIsMale and 'male' or 'female'
    end

    return nil
end

---@param raceId string
---@param genderOrIsMale OTKGender|boolean|nil
---@param partType OTKNpcPartType|string
---@param recordId string
---@return boolean success
local function registerNpcPart(raceId, genderOrIsMale, partType, recordId)
    local gender = normalizeGender(genderOrIsMale)
    local normalizedPartType = normalizeKey(partType)

    if not gender or (normalizedPartType ~= 'hair' and normalizedPartType ~= 'head') then
        return false
    end

    if type(recordId) ~= 'string' or recordId == '' then
        return false
    end

    local raceParts = ensureRace(raceId)
    table.insert(raceParts[gender][normalizedPartType], recordId)

    return true
end

---@return nil
local function registerRaces()
    local races = loadYaml(RACE_FILE)

    if type(races) ~= 'table' or #races == 0 then
        print('[OTK - ERR] OTKBodyParts.registerRaces found no races in ' .. RACE_FILE)
        return
    end

    for _, raceId in ipairs(races) do
        ensureRace(raceId)
        print('[OTK] Race registered for NPC parts: ' .. tostring(raceId))
    end
end

---@return nil
local function registerNpcPartRecords()
    for _, record in ipairs(NPC_PART_RECORDS) do
        registerNpcPart(record.race, record.gender or record.isMale, record.type, record.id)
    end
end

---@return nil
local function buildParts()
    clearBodyParts()
    registerRaces()
    registerNpcPartRecords()
    isBuilt = true
    print('[OTK] OTKBodyParts built NPC head/hair registry')
end

---@param raceId string
---@param genderOrIsMale OTKGender|boolean|nil
---@param partType OTKNpcPartType|string
---@return string|nil recordId
local function selectNpcPart(raceId, genderOrIsMale, partType)
    if not isBuilt then
        print('[OTK - ERR] OTKBodyParts.selectNpcPart called before OTKBodyParts was initialized')
        return nil
    end

    local raceParts = bodyParts[normalizeKey(raceId)]
    local gender = normalizeGender(genderOrIsMale)
    local normalizedPartType = normalizeKey(partType)

    if not raceParts or not gender then
        return nil
    end

    local parts = raceParts[gender][normalizedPartType]

    if type(parts) ~= 'table' or #parts == 0 then
        return nil
    end

    return parts[math.random(1, #parts)]
end

---@return nil
local function OnInit()
    buildParts()
end

return {
    interfaceName = 'OTKBodyParts',
    interface = {
        version = 1,
        bodyParts = bodyParts,
        registerNpcPart = registerNpcPart,
        selectNpcPart = selectNpcPart
    },
    engineHandlers = {
        onInit = OnInit
    }
}
