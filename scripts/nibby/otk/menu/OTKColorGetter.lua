-- OTKColorGetter
-- Separated out from ownylme's Nice Perk UI

local core = require('openmw.core')
local util = require('openmw.util')

local modLocale = core.l10n('nibbyotk', 'en')
local errorText = modLocale('error_text', {})

-- Get colors from GMST, with locale settings
local function getColorFromGameSettings(colorTag)
    local gameSettingValue = core.getGMST(colorTag) -- Grabs the GMST by color name

    if not gameSettingValue then
        print(errorText..' OTKColorGetter.getColorFromGameSettings: Color Tag GMST not found: ' .. tostring(colorTag))
        return
    end

    local rgbValues = {} -- 3 values for RGB
    for colorValue in string.gmatch(gameSettingValue, '(%d+)') do
        table.insert(rgbValues, tonumber(colorValue))
    end

    -- Did not find 3 values
    if #rgbValues ~= 3 then
        print(errorText..' OTKColorGetter.getColorFromGameSettings: Unexpected values from Color Tag: ' .. tostring(colorTag) .. ' provided ' .. tostring(#rgbValues) .. ' values: ' .. tostring(rgbValues))
        return util.color.rgb(0, 0, 0)
    end

    -- Turns our GMST values into lua-usable code
    return util.color.rgb(rgbValues[1] / 255, rgbValues[2] / 255, rgbValues[3] / 255)
end

local colors = {
    normal = getColorFromGameSettings(modLocale('color_normal', {})),
    normal_over = getColorFromGameSettings(modLocale('color_normal_over', {})),
    normal_pressed = getColorFromGameSettings(modLocale('color_normal_pressed', {})),
    active = getColorFromGameSettings(modLocale('color_active', {})),
    active_over = getColorFromGameSettings(modLocale('color_active_over', {})),
    active_pressed = getColorFromGameSettings(modLocale('color_active_pressed', {})),
    disabled = getColorFromGameSettings(modLocale('color_disabled', {})),
    disabled_over = getColorFromGameSettings(modLocale('color_disabled_over', {})),
    disabled_pressed = getColorFromGameSettings(modLocale('color_disabled_pressed', {})),
}

return colors