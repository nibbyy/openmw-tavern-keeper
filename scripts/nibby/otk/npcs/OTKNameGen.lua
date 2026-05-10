---@alias OTKNameGender 'female'|'male'

---@class OTKNameList
---@field [string] table Race name entries indexed by playable race name.

---@type OTKNameList
local nameList = {
    ['High Elf'] = {
        -- No surname
        name = {
            female = {
                'Anirne',
                'Ardarume',
                'Calmaninde',
            },
            male = {
                'Aldaril',
                'Anarenen',
                'Andil',
            },
        },
    },
    ['Argonian'] = {
        -- No surname
        name = {
            female = {
                jel = {
                    'Ahaht',
                    'Akish',
                    'Banalz',
                },
                imp = {
                    'Breech-Star',
                    'Snail-Tail',
                    'Tern-Feather',
                    'Travelling-New-Woman',
                },
            },
            male = {
                jel = {
                    'Asum',
                    'Bunish',
                    'Busheeus',
                },
                imp = {
                    'Also-He-Washes',
                    'Basks-In-The-Sun',
                    'Big Head',
                },
            },
        },
    },
    ['Wood Elf'] = {
        -- No surname
        name = {
            female = {
                'Aerin',
                'Aglaril',
                'Anrel',
            },
            male = {
                'Aengoth',
                'Agarond',
                'Allimir',
            },
        },
    },
    ['Breton'] = {
        first_name = {
            female = {
                'Abelle',
                'Aditte',
                'Ales',
            },
            male = {
                'Alodie',
                'Andre',
                'Arnand',
            },
        },
        surname = {
            'Acques',
            'Adrard',
            'Adrognese',
        },
    },
    ['Dark Elf'] = {
        -- Dark elves are either settlers (Great Houses) or Ashlanders.
        settler = {
            first_name = {
                female = {
                    'Mehra',
                    'Daynasa',
                    'Daynila',
                },
                male = {
                    'Ano',
                    'Galos',
                    'Anes',
                },
            },
            surname = {
                'Andrano',
                'Andrethi',
                'Ienith',
            },
        },
        ashlander = {
            first_name = {
                female = {
                    'Mamaea',
                    'Manirai',
                    'Manu',
                },
                male = {
                    'Mausur',
                    'Ainab',
                    'Maeonius',
                },
            },
            surname = {
                'Vabdas',
                'Almu',
                'Man-llu',
            },
        },
    },
    ['Imperial'] = {
        first_name = {
            female = {
                'Adraria',
                'Agrippina',
                'Ahetotis',
            },
            male = {
                'Aebondeius',
                'Afer',
                'Albecius',
            },
        },
        -- Imperial surnames are either unisex or use a root and gendered suffix.
        surname = {
            unisex = {
                'Albarnian',
                'Albuttian',
                'Amnis',
            },
            root = {
                'Atri',
                'Cadius',
                'Faust',
            },
        },
    },
    ['Khajiit'] = {
        -- No surname
        name = {
            female = {
                'Abanji',
                'Adanja',
                'Addhiranirr',
            },
            male = {
                'Baadargo',
                "Dro'Barri",
                "Dro'farahn",
            },
        },
    },
    ['Nord'] = {
        -- No surname
        name = {
            female = {
                'Aeta',
                'Aldi',
                'Anja',
            },
            male = {
                'Abbard',
                'Adding',
                'Aenar',
            },
        },
    },
    ['Orc'] = {
        first_name = {
            female = {
                'Agrob',
                'Badbog',
                'Bashuk',
            },
            male = {
                'Moghakh',
                'Atulg',
                'Azuk',
            },
        },
        surname = {
            'Agadbu',
            'Aglakh',
            'Agum',
        },
    },
    ['Redguard'] = {
        -- No surname
        name = {
            female = {
                'Alusannah',
                'Ancola',
                'Anora',
            },
            male = {
                'Achel',
                'Alusaron',
                'Bodean',
            },
        },
    },
}

-- Picks one string from a simple list
---@param names string[]|nil
---@param label string Human-readable source used in error logs.
---@return string|nil name
local function selectRandomName(names, label)
    if type(names) ~= 'table' or #names == 0 then
        print('[OTK - ERR] OTKNameGen.selectRandomName found no names for ' .. label)
        return nil
    end

    return names[math.random(1, #names)]
end

-- Turns the boolean used by the NPC spawner into the table key used by nameList.
---@param isMale boolean
---@return OTKNameGender gender
local function getNameGender(isMale)
    return isMale and 'male' or 'female'
end

-- High elves only use a single personal name in this table, so there is no surname step.
---@param isMale boolean
---@return string|nil name
local function highelfName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['High Elf'].name

    return selectRandomName(raceNames[gender], 'High Elf ' .. gender)
end

local function woodelfName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Wood Elf'].name

    return selectRandomName(raceNames[gender], 'Wood Elf ' .. gender)
end

local function nordName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Nord'].name

    return selectRandomName(raceNames[gender], 'Nord ' .. gender)
end

local function redguardName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Redguard'].name

    return selectRandomName(raceNames[gender], 'Redguard ' .. gender)
end

local function khajiitName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Khajiit'].name

    return selectRandomName(raceNames[gender], 'Khajiit ' .. gender)
end

---@param isMale boolean
---@return string|nil name
local function bretonName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Breton']
    local firstName = selectRandomName(raceNames.first_name[gender], 'Breton ' .. gender .. ' first name')
    local surname = selectRandomName(raceNames.surname, 'Breton surname')

    if not firstName or not surname then
        return nil
    end

    return firstName .. ' ' .. surname
end

local function orcName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Orc']
    local firstName = selectRandomName(raceNames.first_name[gender], 'Orc ' .. gender .. ' first name')
    local surname = selectRandomName(raceNames.surname, 'Orc surname')

    if not firstName or not surname then
        return nil
    end

    return firstName .. ' ' .. surname
end

---@param isMale boolean
---@return string|nil name
local function argonianName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Argonian'].name
    local nameStyle = math.random(1, 2) == 1 and 'jel' or 'imp'

    return selectRandomName(raceNames[gender][nameStyle], 'Argonian ' .. gender .. ' ' .. nameStyle)
end

---@param isMale boolean
---@return string|nil name
local function darkelfName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Dark Elf']
    local nameStyle = math.random(1, 2) == 1 and 'settler' or 'ashlander'
    local styleNames = raceNames[nameStyle]
    local firstName = selectRandomName(styleNames.first_name[gender], 'Dark Elf ' .. nameStyle .. ' ' .. gender .. ' first name')
    local surname = selectRandomName(styleNames.surname, 'Dark Elf ' .. nameStyle .. ' surname')

    if not firstName or not surname then
        return nil
    end

    return firstName .. ' ' .. surname
end

---@param isMale boolean
---@return string|nil name
local function imperialName(isMale)
    local gender = getNameGender(isMale)
    local raceNames = nameList['Imperial']
    local firstName = selectRandomName(raceNames.first_name[gender], 'Imperial ' .. gender .. ' first name')
    local surnameStyle = math.random(1, 2) == 1 and 'unisex' or 'root'
    local surname = selectRandomName(raceNames.surname[surnameStyle], 'Imperial ' .. surnameStyle .. ' surname')

    if not firstName or not surname then
        return nil
    end

    if surnameStyle == 'root' then
        surname = surname .. (isMale and 'us' or 'a')
    end

    return firstName .. ' ' .. surname
end

local function selectName(race, isMale)
    race = tostring(race)

    local selectedName = nil

    if race == 'High Elf' then
        selectedName = highelfName(isMale)
    elseif race == 'Argonian' then
        selectedName = argonianName(isMale)
    elseif race == 'Wood Elf' then
        selectedName = woodelfName(isMale)
    elseif race == 'Breton' then
        selectedName = bretonName(isMale)
    elseif race == 'Dark Elf' then
        selectedName = darkelfName(isMale)
    elseif race == 'Imperial' then
        selectedName = imperialName(isMale)
    elseif race == 'Khajiit' then
        selectedName = khajiitName(isMale)
    elseif race == 'Nord' then
        selectedName = nordName(isMale)
    elseif race == 'Orc' then
        selectedName = orcName(isMale)
    elseif race == 'Redguard' then
        selectedName = redguardName(isMale)
    else
        print('[OTK - ERR] OTKNameGen.selectName could not find race: ' .. race)
        return nil
    end

    return selectedName
end

return {
    interfaceName = 'OTKNameGen',
    interface = {
        version = 1,
        nameList = nameList,
        names = nameList,
        selectName = selectName,
    },
}
