local ui = require('openmw.ui')
local util = require('openmw.util')
local interfaces = require('openmw.interfaces')

local v2 = util.vector2
local MWUI = interfaces.MWUI

---@class OTKTooltipHandler
---@field register fun()
---@field showText fun(text: string, mousePosition: any)
---@field clear fun()
local TooltipHandler = {}

---@class OTKTooltipConfig
---@field textSize number Text size used by the tooltip body
---@field maxCharsPerLine number Rough word-wrap limit before a new line is inserted
---@field mouseOffset any Offset from the mouse position, stored as an OpenMW vector
---@field textColor any Tooltip body text color
---@field textShadowColor any Tooltip text shadow color

---@class OTKTooltipState
---@field hostWidget any|nil Floating container element that holds the tooltip
---@field tooltipText any|nil Text element inside the tooltip container
---@field rawText string|nil Last unwrapped tooltip text shown
---@field wrappedText string Last wrapped tooltip text shown
---@field visible boolean True when the tooltip is currently visible
---@field position any|nil Last tooltip position, stored as an OpenMW vector

---@class OTKTooltipUI
---@field config OTKTooltipConfig
---@field state OTKTooltipState

---@class OTKTooltipRoot
---@field tooltip OTKTooltipUI
---@type OTKTooltipRoot
local OTKUI = {
    tooltip = {
        config = {
            textSize = 14,
            maxCharsPerLine = 36,
            mouseOffset = v2(16, 16),
            textColor = util.color.rgb(0.87451, 0.788235, 0.623529),
            textShadowColor = util.color.rgb(0, 0, 0),
        },
        state = {
            hostWidget = nil,
            tooltipText = nil,
            rawText = nil,
            wrappedText = '',
            visible = false,
            position = nil,
        },
    },
}

---@type OTKTooltipUI
local tooltip = OTKUI.tooltip

-- Adds line breaks once per tooltip string so mouse movement only has to move the box
---@param text string Tooltip text to wrap
---@return string wrappedText
local function wrapTooltipText(text)
    if type(text) ~= 'string' then return '' end
    if type(tooltip.config.maxCharsPerLine) ~= 'number' or tooltip.config.maxCharsPerLine <= 0 then return text end

    ---@type string[]
    local wrappedLines = {}

    for sourceLine in (text .. '\n'):gmatch('(.-)\n') do
        local currentLine = ''

        for word in sourceLine:gmatch('%S+') do
            if currentLine == '' then
                currentLine = word
            elseif #currentLine + 1 + #word <= tooltip.config.maxCharsPerLine then
                currentLine = currentLine .. ' ' .. word
            else
                wrappedLines[#wrappedLines + 1] = currentLine
                currentLine = word
            end
        end

        wrappedLines[#wrappedLines + 1] = currentLine
    end

    return table.concat(wrappedLines, '\n')
end

---@param a any|nil First position to compare
---@param b any|nil Second position to compare
---@return boolean
local function samePosition(a, b)
    return a ~= nil and b ~= nil and a.x == b.x and a.y == b.y
end

-- Creates the shared tooltip UI. Call this after the menu/root UI is rebuilt
---@return nil
function TooltipHandler.register()
    local state = tooltip.state
    local config = tooltip.config

    state.hostWidget = ui.create {
        name = 'textTooltipWidget',
        type = ui.TYPE.Container,
        template = MWUI.templates.boxTransparent,
        layer = 'Popup',
        props = {
            position = v2(0, 0),
            visible = false,
        },
        content = ui.content {},
        events = {},
    }

    state.tooltipText = ui.create {
        name = 'textTooltipText',
        type = ui.TYPE.Text,
        props = {
            text = '',
            textColor = config.textColor,
            textShadow = true,
            textShadowColor = config.textShadowColor,
            textSize = config.textSize,
            multiline = true,
        }
    }

    state.hostWidget.layout.content:add(state.tooltipText)
    state.rawText = nil
    state.wrappedText = ''
    state.visible = false
    state.position = nil
end

-- Moves the tooltip near the mouse and updates the text only when it changes
---@param text string Tooltip text to show
---@param mousePosition any Current mouse position, stored as an OpenMW vector
---@return nil
function TooltipHandler.showText(text, mousePosition)
    local state = tooltip.state

    if not state.hostWidget or not state.tooltipText then return end
    if type(text) ~= 'string' or text == '' then
        TooltipHandler.clear()
        return
    end
    if not mousePosition then return end

    local textChanged = state.rawText ~= text

    if textChanged then
        state.rawText = text
        state.wrappedText = wrapTooltipText(text)
        state.tooltipText.layout.props.text = state.wrappedText
        state.tooltipText:update()
    end

    local nextPosition = mousePosition + tooltip.config.mouseOffset
    local shouldUpdateHost = textChanged or not state.visible or not samePosition(state.position, nextPosition)

    state.hostWidget.layout.props.position = nextPosition
    state.hostWidget.layout.props.visible = true
    state.visible = true
    state.position = nextPosition

    if shouldUpdateHost then
        state.hostWidget:update()
    end
end

-- Hides the tooltip and forgets the cached text for the next caller
---@return nil
function TooltipHandler.clear()
    local state = tooltip.state

    if not state.hostWidget or not state.tooltipText then return end
    if not state.visible and state.rawText == nil then return end

    state.rawText = nil
    state.wrappedText = ''
    state.position = nil
    state.visible = false

    state.tooltipText.layout.props.text = ''
    state.tooltipText:update()

    state.hostWidget.layout.props.position = v2(0, 0)
    state.hostWidget.layout.props.visible = false
    state.hostWidget:update()
end

---@cast TooltipHandler OTKTooltipHandler
return TooltipHandler
