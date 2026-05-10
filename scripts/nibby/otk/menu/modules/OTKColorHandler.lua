-- OTKColorHandler
-- Separated out from ownylme's Nice Perk UI

local core = require('openmw.core')
local util = require('openmw.util')
local constants = require('scripts.omw.mwui.constants')

local modLocale = core.l10n('nibbyotk', 'en')
local errorText = modLocale('error_text', {})

-- Reads one UI color from Morrowind's game settings and turns it into an OpenMW color.
---@param colorTag string GMST id for an RGB color setting
---@return any|nil color util.color.rgb value, or nil if the GMST is missing
local function getColorFromGameSettings(colorTag)
    local gameSettingValue = core.getGMST(colorTag) -- Grabs the GMST by color name

    if not gameSettingValue then
        print(errorText..' OTKColorHandler.getColorFromGameSettings: Color Tag GMST not found: ' .. tostring(colorTag))
        return
    end

    local rgbValues = {} -- 3 values for RGB
    for colorValue in string.gmatch(gameSettingValue, '(%d+)') do
        table.insert(rgbValues, tonumber(colorValue))
    end

    -- Did not find 3 values
    if #rgbValues ~= 3 then
        print(errorText..' OTKColorHandler.getColorFromGameSettings: Unexpected values from Color Tag: ' .. tostring(colorTag) .. ' provided ' .. tostring(#rgbValues) .. ' values: ' .. tostring(rgbValues))
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
    art = {
        morrowindGold = util.color.rgb(0.792157, 0.647059, 0.376471),
        morrowindLight = util.color.rgb(0.87451, 0.788235, 0.623529),
        colorBlack = util.color.rgb(0, 0, 0),
        whiteTexture = constants.whiteTexture,
    },
}

local darkenCache = {}

-- Creates a darker copy of a UI color.
---@param color table util.color.rgb table
---@param multiplier number Amount to multiply the RGB values by
---@return any color util.color.rgb value
local function createDarkenedColor(color, multiplier)
    return util.color.rgb(color.r * multiplier, color.g * multiplier, color.b * multiplier)
end

-- Returns a cached darker copy of a UI color for repeated hover/update logic.
---@param cacheKey string Stable name for the color being darkened
---@param color table|nil util.color.rgb table
---@param multiplier number Amount to multiply the RGB values by
---@return any|nil color util.color.rgb value
function colors.darkenColor(cacheKey, color, multiplier)
    if not color then return nil end

    local key = tostring(cacheKey) .. ':' .. tostring(multiplier)
    if not darkenCache[key] then
        darkenCache[key] = createDarkenedColor(color, multiplier)
    end
    return darkenCache[key]
end

return colors
