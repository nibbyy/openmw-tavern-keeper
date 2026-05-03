---@alias OTKGender 'female'|'male'
---@alias OTKNpcPartType 'hair'|'head'

---@class OTKGenderPartRecords
---@field heads string[] Head BODY record ids that fit this race and gender.
---@field hairs string[] Hair BODY record ids that fit this race and gender.

---@class OTKRacePartRecords
---@field female OTKGenderPartRecords
---@field male OTKGenderPartRecords

-- Vanilla playable head/hair BODY record ids. These are not mesh paths.
---@type table<string, OTKRacePartRecords>
local NPC_PART_RECORDS = {
    argonian = {
        male = {
            heads = {
                'b_n_argonian_m_head_01',
                'b_n_argonian_m_head_02',
                'b_n_argonian_m_head_03',
            },
            hairs = {
                'b_n_argonian_m_hair01',
                'b_n_argonian_m_hair02',
                'b_n_argonian_m_hair03',
                'b_n_argonian_m_hair04',
                'b_n_argonian_m_hair05',
                'b_n_argonian_m_hair06',
            },
        },
        female = {
            heads = {
                'b_n_argonian_f_head_01',
                'b_n_argonian_f_head_02',
                'b_n_argonian_f_head_03',
            },
            hairs = {
                'b_n_argonian_f_hair01',
                'b_n_argonian_f_hair02',
                'b_n_argonian_f_hair03',
                'b_n_argonian_f_hair04',
                'b_n_argonian_f_hair05',
            },
        },
    },
    breton = {
        male = {
            heads = {
                'b_n_breton_m_head_01',
                'b_n_breton_m_head_02',
                'b_n_breton_m_head_03',
                'b_n_breton_m_head_04',
                'b_n_breton_m_head_05',
                'b_n_breton_m_head_06',
                'b_n_breton_m_head_07',
                'b_n_breton_m_head_08',
            },
            hairs = {
                'b_n_breton_m_hair_00',
                'b_n_breton_m_hair_01',
                'b_n_breton_m_hair_02',
                'b_n_breton_m_hair_03',
                'b_n_breton_m_hair_04',
                'b_n_breton_m_hair_05',
            },
        },
        female = {
            heads = {
                'b_n_breton_f_head_01',
                'b_n_breton_f_head_02',
                'b_n_breton_f_head_03',
                'b_n_breton_f_head_04',
                'b_n_breton_f_head_05',
                'b_n_breton_f_head_06',
            },
            hairs = {
                'b_n_breton_f_hair_01',
                'b_n_breton_f_hair_02',
                'b_n_breton_f_hair_03',
                'b_n_breton_f_hair_04',
                'b_n_breton_f_hair_05',
            },
        },
    },
    dark_elf = {
        male = {
            heads = {
                'b_n_dark elf_m_head_01',
                'b_n_dark elf_m_head_02',
                'b_n_dark elf_m_head_03',
                'b_n_dark elf_m_head_04',
                'b_n_dark elf_m_head_05',
                'b_n_dark elf_m_head_06',
                'b_n_dark elf_m_head_07',
                'b_n_dark elf_m_head_08',
                'b_n_dark elf_m_head_09',
                'b_n_dark elf_m_head_10',
                'b_n_dark elf_m_head_11',
                'b_n_dark elf_m_head_12',
                'b_n_dark elf_m_head_13',
                'b_n_dark elf_m_head_14',
                'b_n_dark elf_m_head_15',
                'b_n_dark elf_m_head_16',
                'b_n_dark elf_m_head_17',
            },
            hairs = {
                'b_n_dark elf_m_hair_01',
                'b_n_dark elf_m_hair_02',
                'b_n_dark elf_m_hair_03',
                'b_n_dark elf_m_hair_04',
                'b_n_dark elf_m_hair_05',
                'b_n_dark elf_m_hair_06',
                'b_n_dark elf_m_hair_07',
                'b_n_dark elf_m_hair_08',
                'b_n_dark elf_m_hair_09',
                'b_n_dark elf_m_hair_10',
                'b_n_dark elf_m_hair_11',
                'b_n_dark elf_m_hair_12',
                'b_n_dark elf_m_hair_13',
                'b_n_dark elf_m_hair_14',
                'b_n_dark elf_m_hair_15',
                'b_n_dark elf_m_hair_16',
                'b_n_dark elf_m_hair_17',
                'b_n_dark elf_m_hair_18',
                'b_n_dark elf_m_hair_19',
                'b_n_dark elf_m_hair_20',
                'b_n_dark elf_m_hair_21',
                'b_n_dark elf_m_hair_22',
                'b_n_dark elf_m_hair_23',
                'b_n_dark elf_m_hair_24',
                'b_n_dark elf_m_hair_25',
                'b_n_dark elf_m_hair_26',
            },
        },
        female = {
            heads = {
                'b_n_dark elf_f_head_01',
                'b_n_dark elf_f_head_02',
                'b_n_dark elf_f_head_03',
                'b_n_dark elf_f_head_04',
                'b_n_dark elf_f_head_05',
                'b_n_dark elf_f_head_06',
                'b_n_dark elf_f_head_07',
                'b_n_dark elf_f_head_08',
                'b_n_dark elf_f_head_09',
                'b_n_dark elf_f_head_10',
            },
            hairs = {
                'b_n_dark elf_f_hair_01',
                'b_n_dark elf_f_hair_02',
                'b_n_dark elf_f_hair_03',
                'b_n_dark elf_f_hair_04',
                'b_n_dark elf_f_hair_05',
                'b_n_dark elf_f_hair_06',
                'b_n_dark elf_f_hair_07',
                'b_n_dark elf_f_hair_08',
                'b_n_dark elf_f_hair_09',
                'b_n_dark elf_f_hair_10',
                'b_n_dark elf_f_hair_11',
                'b_n_dark elf_f_hair_12',
                'b_n_dark elf_f_hair_13',
                'b_n_dark elf_f_hair_14',
                'b_n_dark elf_f_hair_15',
                'b_n_dark elf_f_hair_16',
                'b_n_dark elf_f_hair_17',
                'b_n_dark elf_f_hair_18',
                'b_n_dark elf_f_hair_19',
                'b_n_dark elf_f_hair_20',
                'b_n_dark elf_f_hair_21',
                'b_n_dark elf_f_hair_22',
                'b_n_dark elf_f_hair_23',
                'b_n_dark elf_f_hair_24',
            },
        },
    },
    high_elf = {
        male = {
            heads = {
                'b_n_high elf_m_head_01',
                'b_n_high elf_m_head_02',
                'b_n_high elf_m_head_03',
                'b_n_high elf_m_head_04',
                'b_n_high elf_m_head_05',
                'b_n_high elf_m_head_06',
            },
            hairs = {
                'b_n_high elf_m_hair_01',
                'b_n_high elf_m_hair_02',
                'b_n_high elf_m_hair_03',
                'b_n_high elf_m_hair_04',
                'b_n_high elf_m_hair_05',
            },
        },
        female = {
            heads = {
                'b_n_high elf_f_head_01',
                'b_n_high elf_f_head_02',
                'b_n_high elf_f_head_03',
                'b_n_high elf_f_head_04',
                'b_n_high elf_f_head_05',
                'b_n_high elf_f_head_06',
            },
            hairs = {
                'b_n_high elf_f_hair_01',
                'b_n_high elf_f_hair_02',
                'b_n_high elf_f_hair_03',
                'b_n_high elf_f_hair_04',
            },
        },
    },
    imperial = {
        male = {
            heads = {
                'b_n_imperial_m_head_01',
                'b_n_imperial_m_head_02',
                'b_n_imperial_m_head_03',
                'b_n_imperial_m_head_04',
                'b_n_imperial_m_head_05',
                'b_n_imperial_m_head_06',
                'b_n_imperial_m_head_07',
            },
            hairs = {
                'b_n_imperial_m_hair_00',
                'b_n_imperial_m_hair_01',
                'b_n_imperial_m_hair_02',
                'b_n_imperial_m_hair_03',
                'b_n_imperial_m_hair_04',
                'b_n_imperial_m_hair_05',
                'b_n_imperial_m_hair_06',
                'b_n_imperial_m_hair_07',
                'b_n_imperial_m_hair_08',
                'b_n_imperial_m_hair_09',
            },
        },
        female = {
            heads = {
                'b_n_imperial_f_head_01',
                'b_n_imperial_f_head_02',
                'b_n_imperial_f_head_03',
                'b_n_imperial_f_head_04',
                'b_n_imperial_f_head_05',
                'b_n_imperial_f_head_06',
                'b_n_imperial_f_head_07',
            },
            hairs = {
                'b_n_imperial_f_hair_01',
                'b_n_imperial_f_hair_02',
                'b_n_imperial_f_hair_03',
                'b_n_imperial_f_hair_04',
                'b_n_imperial_f_hair_05',
                'b_n_imperial_f_hair_06',
                'b_n_imperial_f_hair_07',
            },
        },
    },
    khajiit = {
        male = {
            heads = {
                'b_n_khajiit_m_head_01',
                'b_n_khajiit_m_head_02',
                'b_n_khajiit_m_head_03',
                'b_n_khajiit_m_head_04',
            },
            hairs = {
                'b_n_khajiit_m_hair01',
                'b_n_khajiit_m_hair02',
                'b_n_khajiit_m_hair03',
                'b_n_khajiit_m_hair04',
                'b_n_khajiit_m_hair05',
            },
        },
        female = {
            heads = {
                'b_n_khajiit_f_head_01',
                'b_n_khajiit_f_head_02',
                'b_n_khajiit_f_head_03',
                'b_n_khajiit_f_head_04',
            },
            hairs = {
                'b_n_khajiit_f_hair01',
                'b_n_khajiit_f_hair02',
                'b_n_khajiit_f_hair03',
                'b_n_khajiit_f_hair04',
                'b_n_khajiit_f_hair05',
            },
        },
    },
    nord = {
        male = {
            heads = {
                'b_n_nord_m_head_01',
                'b_n_nord_m_head_02',
                'b_n_nord_m_head_03',
                'b_n_nord_m_head_04',
                'b_n_nord_m_head_05',
                'b_n_nord_m_head_06',
                'b_n_nord_m_head_07',
                'b_n_nord_m_head_08',
                'b_n_nord_m_head_09',
                'b_n_nord_m_head_10',
                'b_n_nord_m_head_11',
                'b_n_nord_m_head_12',
                'b_n_nord_m_head_13',
            },
            hairs = {
                'b_n_nord_m_hair00',
                'b_n_nord_m_hair01',
                'b_n_nord_m_hair02',
                'b_n_nord_m_hair03',
                'b_n_nord_m_hair04',
                'b_n_nord_m_hair05',
                'b_n_nord_m_hair06',
                'b_n_nord_m_hair07',
                'b_n_nord_m_hair08',
            },
        },
        female = {
            heads = {
                'b_n_nord_f_head_01',
                'b_n_nord_f_head_02',
                'b_n_nord_f_head_03',
                'b_n_nord_f_head_04',
                'b_n_nord_f_head_05',
                'b_n_nord_f_head_06',
                'b_n_nord_f_head_07',
                'b_n_nord_f_head_08',
                'b_n_nord_f_head_09',
                'b_n_nord_f_head_10',
                'b_n_nord_f_head_11',
                'b_n_nord_f_head_12',
                'b_n_nord_f_head_13',
            },
            hairs = {
                'b_n_nord_f_hair_01',
                'b_n_nord_f_hair_02',
                'b_n_nord_f_hair_03',
                'b_n_nord_f_hair_04',
                'b_n_nord_f_hair_05',
                'b_n_nord_f_hair_06',
            },
        },
    },
    orc = {
        male = {
            heads = {
                'b_n_orc_m_head_01',
                'b_n_orc_m_head_02',
                'b_n_orc_m_head_03',
                'b_n_orc_m_head_04',
            },
            hairs = {
                'b_n_orc_m_hair_01',
                'b_n_orc_m_hair_02',
                'b_n_orc_m_hair_03',
                'b_n_orc_m_hair_04',
                'b_n_orc_m_hair_05',
            },
        },
        female = {
            heads = {
                'b_n_orc_f_head_01',
                'b_n_orc_f_head_02',
                'b_n_orc_f_head_03',
            },
            hairs = {
                'b_n_orc_f_hair01',
                'b_n_orc_f_hair02',
                'b_n_orc_f_hair03',
                'b_n_orc_f_hair04',
                'b_n_orc_f_hair05',
            },
        },
    },
    redguard = {
        male = {
            heads = {
                'b_n_redguard_m_head_01',
                'b_n_redguard_m_head_02',
                'b_n_redguard_m_head_03',
                'b_n_redguard_m_head_04',
                'b_n_redguard_m_head_05',
                'b_n_redguard_m_head_06',
            },
            hairs = {
                'b_n_redguard_m_hair_00',
                'b_n_redguard_m_hair_01',
                'b_n_redguard_m_hair_02',
                'b_n_redguard_m_hair_03',
                'b_n_redguard_m_hair_04',
                'b_n_redguard_m_hair_05',
                'b_n_redguard_m_hair_06',
            },
        },
        female = {
            heads = {
                'b_n_redguard_f_head_01',
                'b_n_redguard_f_head_02',
                'b_n_redguard_f_head_03',
                'b_n_redguard_f_head_04',
                'b_n_redguard_f_head_05',
                'b_n_redguard_f_head_06',
            },
            hairs = {
                'b_n_redguard_f_hair_01',
                'b_n_redguard_f_hair_02',
                'b_n_redguard_f_hair_03',
                'b_n_redguard_f_hair_04',
                'b_n_redguard_f_hair_05',
            },
        },
    },
    wood_elf = {
        male = {
            heads = {
                'b_n_wood elf_m_head_01',
                'b_n_wood elf_m_head_02',
                'b_n_wood elf_m_head_03',
                'b_n_wood elf_m_head_04',
                'b_n_wood elf_m_head_05',
                'b_n_wood elf_m_head_06',
                'b_n_wood elf_m_head_07',
                'b_n_wood elf_m_head_08',
            },
            hairs = {
                'b_n_wood elf_m_hair_01',
                'b_n_wood elf_m_hair_02',
                'b_n_wood elf_m_hair_03',
                'b_n_wood elf_m_hair_04',
                'b_n_wood elf_m_hair_05',
                'b_n_wood elf_m_hair_06',
            },
        },
        female = {
            heads = {
                'b_n_wood elf_f_head_01',
                'b_n_wood elf_f_head_02',
                'b_n_wood elf_f_head_03',
                'b_n_wood elf_f_head_04',
                'b_n_wood elf_f_head_05',
                'b_n_wood elf_f_head_06',
            },
            hairs = {
                'b_n_wood elf_f_hair_01',
                'b_n_wood elf_f_hair_02',
                'b_n_wood elf_f_hair_03',
                'b_n_wood elf_f_hair_04',
                'b_n_wood elf_f_hair_05',
            },
        },
    },
}

-- Turns race names like "Dark Elf" into safe table keys like "dark_elf".
---@param value any
---@return string key
local function normalizeKey(value)
    local key = string.lower(tostring(value or '')):gsub('%s+', '_')
    return key
end

-- Picks one matching head or hair BODY record id.
---@param raceId string
---@param isMale boolean
---@param partType OTKNpcPartType
---@return string|nil recordId
local function selectNpcPart(raceId, isMale, partType)
    local raceParts = NPC_PART_RECORDS[normalizeKey(raceId)]
    local gender = isMale and 'male' or 'female'
    local bucket = raceParts and raceParts[gender][partType .. 's']

    if type(bucket) ~= 'table' or #bucket == 0 then
        print('[OTK - ERR] OTKBodyParts.selectNpcPart found no ' .. tostring(partType)
            .. ' for race=' .. tostring(raceId) .. ', gender=' .. gender)
        return nil
    end

    return bucket[math.random(1, #bucket)]
end

return {
    interfaceName = 'OTKBodyParts',
    interface = {
        version = 1,
        bodyParts = NPC_PART_RECORDS,
        selectNpcPart = selectNpcPart,
    },
}
