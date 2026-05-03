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

-- Kept as a simple accessor for any caller that already expected registerNames().
---@return OTKNameList nameData Name data indexed by race name, such as nameData['High Elf'].
local function registerNames()
    return nameList
end

local function highelfName(isMale)
    local raceNames = nameList['High Elf'].name
    local names = isMale and raceNames.male or raceNames.female
    return names[#names]
end

local function argonianName(isMale)
end

local function woodelfName(isMale)
end

local function bretonName(isMale)
end

local function darkelfName(isMale)
end

local function imperialName(isMale)
end

local function khajiitName(isMale)
end

local function nordName(isMale)
end

local function redguardName(isMale)
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
        registerNames = registerNames,
        selectName = selectName,
    },
}
