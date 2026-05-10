local types = require('openmw.types')
local interfaces = require('openmw.interfaces')

local builder = require('scripts.nibby.otk.building.OTKBuilder')

-- Shape of the OTKBodyParts global interface this script asks for heads and hair.
---@class OTKBodyPartsInterface
---@field version integer Interface version number
---@field bodyParts table Shared registry of known body parts
---@field selectNpcPart fun(raceId: string, isMale: boolean, partType: string): string|nil Picks a matching part id

-- Shape of the OTKNameGen global interface this script asks for NPC names.
---@class OTKNameGenInterface
---@field version integer Interface version number
---@field nameList table Shared registry of known names
---@field selectName fun(race: string, isMale: boolean): string|nil Picks a matching NPC name

-- Data passed into OpenMW when creating a new NPC record draft.
---@class OTKNpcRecordData
---@field name string Generated display name for the NPC
---@field race string Race id/name for the NPC
---@field isMale boolean True for male, false for female
---@field hair string Hair record id
---@field head string Head record id
---@field class string Class id/name for the NPC
---@field isEssential boolean Whether the NPC is protected as essential
---@field isRespawning boolean Whether the NPC can respawn
---@field baseDisposition integer Starting friendliness
---@field bloodType integer OpenMW blood type value
---@field baseGold integer Starting gold

local races

local function registerRaces()
    races = nil
    races = builder.loadYaml('scripts/nibby/otk/npcs/resources/races.yaml')
end

-- Picks one random race from the race list.
---@return string|nil raceId Race name, or nil if the list could not be loaded
local function selectRace()
    if type(races) ~= 'table' or #races == 0 then
        print('[OTK - ERR] OTKNPCSpawner.selectRace found no races to choose from')
        return nil
    end

    return races[math.random(1, #races)]
end

local classes

local function registerClasses()
    classes = nil
    classes = builder.loadYaml('scripts/nibby/otk/npcs/resources/classes.yaml')
end

-- Picks one random class from the class list.
---@return string|nil classId Class name, or nil if the list could not be loaded
local function selectClass()
    if type(classes) ~= 'table' or #classes == 0 then
        print('[OTK -ERR] OTKNPCSpawner.selectClass found no classes to choose from')
        return nil
    end

    return classes[math.random(1, #classes)]
end

-- Flips a simple coin to decide the NPC's gender.
---@return boolean isMale
local function selectGender()
    return math.random(1, 2) == 1
end

-- Builds the NPC record data and asks OpenMW for a record draft.
---@return any|nil npcRecordDraft OpenMW NPC record draft, or nil if required data is missing
local function buildNPC()
    print('Building an NPC...')
    local race = selectRace()
    local isMale = selectGender()
    local gender = isMale and 'male' or 'female'
    local class = selectClass()
    local bodyParts = interfaces.OTKBodyParts
    local nameGen = interfaces.OTKNameGen

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

    if not nameGen then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC could not find OTKNameGen interface')
        return nil
    end

    if type(bodyParts.selectNpcPart) ~= 'function' then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC OTKBodyParts interface is missing selectNpcPart')
        return nil
    end

    if type(nameGen.selectName) ~= 'function' then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC OTKNameGen interface is missing selectName')
        return nil
    end

    ---@cast bodyParts OTKBodyPartsInterface
    ---@cast nameGen OTKNameGenInterface
    local hair = bodyParts.selectNpcPart(race, isMale, 'hair')
    local head = bodyParts.selectNpcPart(race, isMale, 'head')
    local name = nameGen.selectName(race, isMale)

    print("Name selected: " .. tostring(name))
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

    if not name then
        print('[OTK - ERR] OTKNPCSpawner.buildNPC found no name for race=' .. tostring(race) .. ', gender=' .. gender)
        return nil
    end

    ---@type OTKNpcRecordData
    local npcRecordData = {
        name = name,
        race = race,
        isMale = isMale,
        gender = gender,
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

-- Event entry point: build an NPC when another script sends SpawnNPC.
---@return nil
local function spawnNPC()
    local npcRecordDraft = buildNPC()

    if not npcRecordDraft then
        print('[OTK - ERR] OTKNPCSpawner.spawnNPC could not build NPC record draft')
        return
    end

    print('NPC record draft prepared: ' .. tostring(npcRecordDraft.id))
end

local function OnLoad()
    registerRaces()
    registerClasses()
end

return {
    eventHandlers = {
        SpawnNPC = spawnNPC,
    },
    engineHandlers = {
        onLoad = OnLoad,
    },
}
