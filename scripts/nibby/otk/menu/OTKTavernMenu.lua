-- OpenMW Tavern Keeper
-- Tavern UI Menu by nibby
-- Thank you to:
-- Ownlyme, Hyacinth, nox7, S3ctor

local input = require('openmw.input')
local core = require('openmw.core')
local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')
local interfaces = require('openmw.interfaces')
local self = require('openmw.self')
local markup = require('openmw.markup')
local constants = require('scripts.omw.mwui.constants')
local vfs = require('openmw.vfs')

local modLocale = core.l10n('nibbyotk', 'en')
local v2 = util.vector2
local MWUI = interfaces.MWUI

-- Require our helper scripts
local colorGetter = require('scripts.nibby.otk.menu.modules.OTKColorGetter')
local splashList = require('scripts.nibby.otk.menu.modules.OTKSubtitleSplashes')

-- UI Variable storage; these are generally called early to be checked or used by other functions
local OTKUI = {
    constants = { -- UI visual constants
        TITLE_TEXT_SIZE = 22,
        SUBTITLE_TEXT_SIZE = 18,
        PAGE_BUTTON_SIZE = 64,
        PAGE_BUTTON_TEXT_SIZE = 18,
        SUBPAGE_BUTTON_TEXT_SIZE = 14,
        SUBPAGE_CONTENT_TEXT_SIZE = 12,
        VERTICAL_SCROLLBAR_THICKNESS = 8,
        HORIZONTAL_SCROLLBAR_THICKNESS = 8,
        VERTICAL_THUMB_SIZE = v2(8, 64),
        HORIZONTAL_THUMB_SIZE = v2(64, 8),
        VERTICAL_THUMB_CAP_HEIGHT = 4,
    },
    elems = { -- Declared early for reassignment & checking
        rootWidget = nil,
        --rootContainer = nil,
        subtitleText = nil,
        currentPage = nil,
        currentSubPage = nil,
        subPageListScrollBarStackWidget = nil,
        subPageContentStackWidget = nil,
        subPageContentBaseSize = nil,
        subpageHelpButton = nil,
        tooltip = {
            hostWidget = nil,
            currentTooltip = nil,
            tooltipText = nil,
        },
    },
    pages = {
        pageFilePath = 'scripts/nibby/otk/menu/pages/',
        list = {},
        count = 0,
    },
    art = {
        morrowindGold = util.color.rgb(0.792157, 0.647059, 0.376471),
        morrowindLight = util.color.rgb(0.87451, 0.788235, 0.623529),
        colorBlack = util.color.rgb(0, 0, 0),
        whiteTexture = constants.whiteTexture,
    }
}

--[[
    #####

    HELPERS

    #####
]]--

---@type table<string, fun(dt?: number)>
local onFrameFunctions = {} -- Used for button functions to call onFrame

-- Helper function for checking if the Root element is visible
---@return boolean -- True if the menu is open
local function isRootVisible()
    if not OTKUI.elems.rootWidget then return false end
    return OTKUI.elems.rootWidget.layout.props.visible ~= false
end

-- Helper function for finding the length of the page list
---@return integer -- UI pixel size of the page list
local function getPageListSize()
    return OTKUI.constants.PAGE_BUTTON_SIZE * OTKUI.pages.count
end

-- Helper function for finding the width of one Page's subpage list.
---@param page table
---@return number
local function getSubPageListSize(page)
    if not page or type(page.subPages) ~= 'table' then return 0 end
    return (page.subPageButtonWidth or 0) * #page.subPages
end

local textureCache = {}
-- Helper function for a simple texture cache; returns a cached ui.texture
---@param path string -- Texture resource path
---@return any ui.texture -- Returned ui.texture from cache
local function getTexture(path)
    if not textureCache[path] then -- Texture isn't in cache
        textureCache[path] = ui.texture{path = path} -- Add it
    end
    return textureCache[path] -- Return the cached texture
end

-- Helper function to darken RGB colors
---@param color table -- util.color.rgb table
---@param multiplier number -- Amount to multiply the RGB by
---@return any util.color.rgb -- Returned util.color.rgb()
local function darkenColor(color, multiplier)
    return util.color.rgb(color.r * multiplier, color.g * multiplier, color.b * multiplier)
end

-- Function called to close the menu
local function closeMenu()
    if not isRootVisible() then return end

    interfaces.UI.setMode() -- Re-locks the mouse

    print('[OTK] OTKTavernMenu: Closing the Tavern Menu')
    OTKUI.elems.rootWidget.layout.props.visible = false -- Closes the menu
    OTKUI.elems.rootWidget:update()

    if OTKUI.elems.subpageHelpButton and OTKUI.elems.subpageHelpButton.layout then
        OTKUI.elems.subpageHelpButton.layout.props.visible = false
        OTKUI.elems.subpageHelpButton:update()
    end

    if OTKUI.elems.tooltip.hostWidget and OTKUI.elems.tooltip.hostWidget.layout then
        OTKUI.elems.tooltip.hostWidget.layout.props.visible = false
        OTKUI.elems.tooltip.hostWidget:update()
    end
end

-- Called by other scripts to add functions to onFrameFunctions
---@param key string -- Name for function (mostly used to remove itself)
---@param func fun(dt?: number) -- The function to run; (dt) is time taken from onFrame
local function addOnFrameFunction(key, func)
    if type(key) ~= 'string' then return end
    if type(func) ~= 'function' then return end
    onFrameFunctions[key] = func
end

-- Called per Page to register subpages
local function registerSubPage(subPage)
    if type(subPage) ~= 'table' then
        print('[OTK - ERR] OTKTavernMenu.registerSubPage expected Subpage Table, got: ' .. tostring(type(subPage)))
        return false
    end

    if type(subPage.name) ~= 'string' or subPage.name == '' then
        print('[OTK - ERR] OTKTavernMenu.registerSubPage: subPage.name must be a non-empty string, got: ' .. tostring(subPage.name))
        return false
    end

    if subPage.type == 'text' then
        if subPage.content ~= nil and type(subPage.content) ~= 'string' then
            print('[OTK - ERR] OTKTavernMenu.registerSubPage: Text Subpage content must be a string for ' .. tostring(subPage.name) .. ', got: ' .. tostring(type(subPage.content)))
            return false
        end

        if subPage.tooltip ~= nil and type(subPage.tooltip) ~= 'string' then
            print('[OTK - ERR] OTKTavernMenu.registerSubPage: Text Subpage tooltip must be a string for ' .. tostring(subPage.name) .. ', got: ' .. tostring(type(subPage.tooltip)))
            return false
        end

        return true
    end

    print('[OTK - ERR] OTKTavernMenu.registerSubPage: Unsupported Subpage type for ' .. tostring(subPage.name) .. ': ' .. tostring(subPage.type))
    return false
end

---@param subPages table|nil
---@param pageName string
---@return table
local function normalizeSubPages(subPages, pageName)
    local normalized = {}

    if type(subPages) ~= 'table' then
        return normalized
    end

    for i, rawSubPage in ipairs(subPages) do
        if type(rawSubPage) ~= 'table' then
            print('[OTK - ERR] OTKTavernMenu.normalizeSubPages: Subpage #' .. tostring(i) .. ' in Page ' .. tostring(pageName) .. ' must be a table, got: ' .. tostring(type(rawSubPage)))
        else
            local subPage = {
                name = rawSubPage.name,
                type = rawSubPage.type,
                content = rawSubPage.content,
                tooltip = rawSubPage.tooltip,
            }

            if registerSubPage(subPage) then
                normalized[#normalized + 1] = subPage
            end
        end
    end

    return normalized
end

---@class TavernPage
---@field name string -- Returned name string from module
---@field label string -- Returned text string from module
---@field index integer -- Returned index integer from module
---@field subPages table -- Ordered subpage records

---@class TavernSubPage
---@field name string
---@field type string
---@field content string|nil
---@field tooltip string|nil

-- Normalizes page data loaded from YAML into the same shape the UI expects
---@param fileName string
---@param page table
---@return TavernPage|nil
local function normalizePageData(fileName, page)
    if type(page) ~= 'table' then
        print('[OTK - ERR] OTKTavernMenu.normalizePageData expected Page table from YAML in ' .. tostring(fileName) .. ', got: ' .. tostring(type(page)))
        return nil
    end

    page.subPages = normalizeSubPages(page.subPages, page.name)

    return page
end

-- Registers our pages by information from YAML data
---@param page TavernPage -- Page data
local function registerPage(page)
    if type(page) ~= 'table' then
        print('[OTK - ERR] OTKTavernMenu.registerPage expected Page table, got: ' .. tostring(type(page)))
        return
    end

    if type(page.name) ~= 'string' or page.name == '' then
        print('[OTK - ERR] OTKTavernMenu.registerPage: page.name must be a non-empty string in page: ' .. tostring(page))
        return
    end

    if type(page.label) ~= 'string' or page.label == '' then
        print('[OTK - ERR] OTKTavernMenu.registerPage: page.label must be a non-empty string in page: ' .. tostring(page.name))
        return
    end

    if type(page.index) ~= 'number' or page.index == 0 then
        print('[OTK - ERR] OTKTavernMenu.registerPage: page.index must be a Number above 0! Got: ' .. tostring(page.index))
        return
    end

    if OTKUI.pages.list[page.index] == nil then
        OTKUI.pages.list[page.index] = page
        if page.index > OTKUI.pages.count then
            OTKUI.pages.count = page.index
        end
    else
        print('[OTK - ERR] OTKTavernMenu.registerPage: Page: ' ..tostring(page.name) .. ' tried to claim Page Index that was already taken: ' ..tostring(page.index))
        return
    end
end

-- Function called to load Page .yaml files
local function loadPageFiles()
    OTKUI.pages.list = {}
    OTKUI.pages.count = 0

    for fileName in vfs.pathsWithPrefix(OTKUI.pages.pageFilePath) do
        if fileName:match('%.yaml$') then
            local fileHandle, openErr = vfs.open(fileName)
            if not fileHandle then
                print('[OTK - ERR] OTKTavernMenu.loadPageFiles: Failed to open YAML ' .. fileName .. ': ' .. tostring(openErr))
            else
                local yamlData = fileHandle:read('*all')
                fileHandle:close()

                local ok, pageOrErr = pcall(markup.decodeYaml, yamlData)
                if not ok then
                    print('[OTK - ERR] OTKTavernMenu.loadPageFiles: Failed to decode YAML ' .. fileName .. ': ' .. tostring(pageOrErr))
                else
                    local page = normalizePageData(fileName, pageOrErr)
                    if page then
                        print('[OTK] Loaded page YAML: ' .. fileName .. ' | index=' .. tostring(page.index))
                        registerPage(page)
                    end
                end
            end
        end
    end

    if OTKUI.pages.count == 0 then
        print('[OTK - ERR] OTKTavernMenu.loadPageFiles: No YAML pages were registered from ' .. OTKUI.pages.pageFilePath)
    end
end

-- Helper function to determine our scroll bar thumb texture (vertical/horizontal)
---@param isHorizontal boolean
---@return any ui.texture
local function getThumbTexture(isHorizontal)
    if isHorizontal then
        return getTexture('textures/nibby/hor_bar.dds')
    else
        return getTexture('textures/menu_scroll_button_vert.dds')
    end
end

-- Helper function to add thumb caps to scroll bar thumb
---@param thumbElem any -- UI element
---@param thickness integer
---@return any, any -- topCap, bottomCap
local function addThumbCaps(thumbElem, thickness)
    local topCap = ui.create {
        type = ui.TYPE.Image,
        name = thumbElem.layout.name .. '_topCap',
        props = {
            size = v2(thickness, OTKUI.constants.VERTICAL_THUMB_CAP_HEIGHT),
            anchor = v2(0.5, 0),
            relativePosition = v2(0.5, 0),
            resource = getTexture('textures/menu_scroll_button_top.dds'),
        },
    }

    local bottomCap = ui.create {
        type = ui.TYPE.Image,
        name = thumbElem.layout.name .. '_bottomCap',
        props = {
            size = v2(thickness, OTKUI.constants.VERTICAL_THUMB_CAP_HEIGHT),
            anchor = v2(0.5, 1),
            relativePosition = v2(0.5, 1),
            resource = getTexture('textures/menu_scroll_button_bottom.dds'),
        },
    }

    thumbElem.layout.content:add(topCap)
    thumbElem.layout.content:add(bottomCap)

    return topCap, bottomCap
end

---@class ScrollBarData
---@field track any -- UI element
---@field thumb any -- UI element
---@field thumbTop any|nil -- UI element
---@field thumbBottom any|nil -- UI element
---@field hostElem any -- UI element
---@field scrollBarHost any -- UI element
---@field contentSize number
---@field thickness integer
---@field thumbLength integer
---@field reserveSpace boolean

---@type table<any, ScrollBarData>
local scrollBars = {}

-- Mouse wheel scrolling variables
local scrollableWindow = nil -- Our flex element which 'moves' when scrolled
local hostElem = nil -- Declares the 'host' element of the flex element
local scrollContentSize = nil
local addScrollBar = nil
local updateScrollBar = nil

---@class ScrollMetrics
---@field isHorizontal boolean
---@field hostSize number
---@field currentPos number
---@field contentSize number
---@field canScroll boolean
---@field minPos number
---@field scrollRange number
---@field flexPos any util.vector2

-- Function for getting our scroll metrics
---@param flexElem any -- UI element
---@param containerElem any -- UI element
---@param contentSize number
---@return ScrollMetrics|nil
local function getScrollMetrics(flexElem, containerElem, contentSize)
    if not flexElem or not flexElem.layout then
        print('[OTK - ERR] OTKTavernMenu.getScrollMetrics: flexElem is not a UI element/does not have a .layout: ' .. tostring(flexElem))
        return nil
    end
    if not containerElem or not containerElem.layout then
        print('[OTK - ERR] OTKTavernMenu.getScrollMetrics: containerElem is not a UI element/does not have a .layout: ' .. tostring(containerElem))
        return nil
    end
    if not contentSize then
        print('[OTK - ERR] OTKTavernMenu.getScrollMetrics: contentSize is incorrect/not passed, got: ' .. tostring(contentSize))
        return nil
    end

    local flexPos = flexElem.layout.props.position or v2(0, 0)
    local isHorizontal = flexElem.layout.props.horizontal == true

    local hostSize
    local currentPos

    if isHorizontal then
        hostSize = containerElem.layout.props.size.x -- Get horizontal size of the host element if the flex grows horizontally
        currentPos = flexPos.x -- Flex gets moved horizontally
    else
        hostSize = containerElem.layout.props.size.y -- If vertical, get its vertical size
        currentPos = flexPos.y -- Flex gets moved vertically
    end

    if not hostSize then
        print('[OTK - ERR] OTKTavernMenu.getScrollMetrics: Cannot find size property of containerElem: ' .. tostring(containerElem))
        return nil
    end

    local canScroll = contentSize > hostSize -- Checks whether the flex element is larger than the host element; if so, it can scroll
    local minPos = 0
    local scrollRange = 0

    if canScroll then
        -- Flex starts at 0; when content is larger than visible host, scroll into negative space
        -- Ex: host = 300, content = 900, so minPos = -600
        minPos = hostSize - contentSize

        -- Total distance the flex is allowed to travel while scrolling
        scrollRange = math.abs(minPos)
    end

    return {
        isHorizontal = isHorizontal,
        hostSize = hostSize,
        currentPos = currentPos,
        contentSize = contentSize,
        canScroll = canScroll,
        minPos = minPos,
        scrollRange = scrollRange,
        flexPos = flexPos,
    }
end

-- Helper Function to assign a UI target for mouse wheel scrolling
---@param flexElem any -- UI element
---@param containerElem any -- UI element
---@param contentSize number
local function setScrollTarget(flexElem, containerElem, contentSize)
    scrollableWindow = flexElem
    hostElem = containerElem
    scrollContentSize = contentSize
end

-- Helper Function to clear our mouse wheel targets
---@param flexElem any -- UI element
local function clearScrollTarget(flexElem)
    if scrollableWindow == flexElem then
        scrollableWindow = nil
        hostElem = nil
        scrollContentSize = nil
    end
end

---@param subPage table
local function updateSubPageButtonVisual(subPage)
    if not subPage or not subPage.buttonBackground then return end

    if OTKUI.elems.currentSubPage == subPage then
        subPage.buttonBackground.layout.props.alpha = 0.45
        subPage.buttonBackground.layout.props.color = darkenColor(OTKUI.art.morrowindGold, 0.5)
    else
        subPage.buttonBackground.layout.props.alpha = 0.2
        subPage.buttonBackground.layout.props.color = OTKUI.art.colorBlack
    end

    subPage.buttonBackground:update()
end

local updateSubPageHelpButtonVisibility

---@param hasScrollBar boolean
local function setSubPageScrollBarSpace(hasScrollBar)
    local scrollBarStack = OTKUI.elems.subPageListScrollBarStackWidget
    local contentStack = OTKUI.elems.subPageContentStackWidget
    local baseSize = OTKUI.elems.subPageContentBaseSize

    if not scrollBarStack or not scrollBarStack.layout then return end
    if not contentStack or not contentStack.layout then return end
    if not baseSize then return end

    local scrollBarHeight = hasScrollBar and OTKUI.constants.HORIZONTAL_SCROLLBAR_THICKNESS or 0

    scrollBarStack.layout.props.size = v2(scrollBarStack.layout.props.size.x, scrollBarHeight)
    contentStack.layout.props.size = v2(baseSize.x, baseSize.y - scrollBarHeight)

    scrollBarStack:update()
    contentStack:update()
end

---@param subPage table|nil
local function showSubPage(subPage)
    local previousSubPage = OTKUI.elems.currentSubPage

    if previousSubPage and previousSubPage ~= subPage and previousSubPage.contentHost then
        previousSubPage.contentHost.layout.props.visible = false
        previousSubPage.contentHost:update()
    end

    OTKUI.elems.currentSubPage = subPage

    if previousSubPage then
        updateSubPageButtonVisual(previousSubPage)
    end

    if updateSubPageHelpButtonVisibility then
        updateSubPageHelpButtonVisibility()
    end

    if not subPage or not subPage.contentHost then return end

    if OTKUI.elems.subPageContentStackWidget and OTKUI.elems.subPageContentStackWidget.layout then
        subPage.contentHost.layout.props.size = OTKUI.elems.subPageContentStackWidget.layout.props.size
    end

    subPage.contentHost.layout.props.visible = true
    subPage.contentHost:update()
    updateSubPageButtonVisual(subPage)
end

---@param page table
local function showPage(page)
    if OTKUI.elems.currentPage and OTKUI.elems.currentPage.subPageListFlex then
        OTKUI.elems.currentPage.subPageListFlex.layout.props.visible = false
        OTKUI.elems.currentPage.subPageListFlex:update()
    end

    if OTKUI.elems.currentPage and OTKUI.elems.currentPage.subPageScrollBarHost then
        OTKUI.elems.currentPage.subPageScrollBarHost.layout.props.visible = false
        OTKUI.elems.currentPage.subPageScrollBarHost:update()
    end

    if OTKUI.elems.currentPage and OTKUI.elems.currentPage.subPageListFlex then
        clearScrollTarget(OTKUI.elems.currentPage.subPageListFlex)
    end

    OTKUI.elems.currentPage = page

    setSubPageScrollBarSpace(page and page.hasSubPageScrollBar == true)

    if page and page.subPageListFlex then
        page.subPageListFlex.layout.props.visible = true
        page.subPageListFlex:update()
    end

    if page and page.subPageScrollBarHost and page.hasSubPageScrollBar then
        page.subPageScrollBarHost.layout.props.visible = true
        page.subPageScrollBarHost:update()
        updateScrollBar(page.subPageListFlex)
    end

    if page and page.subPages and page.subPages[1] then
        showSubPage(page.subPages[1])
    else
        showSubPage(nil)
    end
end

---@param subPage table
---@param contentHost any
local function buildTextSubPage(subPage, contentHost)
    local subpageHostFlex = ui.create {
        name = subPage.name..'_subPageHostFlex',
        type = ui.TYPE.Flex,
        props = {
            relativeSize = v2(1, 1),
            horizontal = false,
        },
        content = ui.content {},
    }
    contentHost.layout.content:add(subpageHostFlex)

    local subpageText = ui.create {
        name = subPage.name..'_subPageText',
        type = ui.TYPE.Text,
        props = {
            multiline = true,
            wordWrap = true,
            text = subPage.content or '',
            textSize = OTKUI.constants.SUBPAGE_CONTENT_TEXT_SIZE,
            textColor = OTKUI.art.morrowindLight,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Start,
        },
    }
    subpageHostFlex.layout.content:add(subpageText)
end

---@param page table
---@param subPage table
---@param subpageListWidget any
---@return any
local function buildSubPageButton(page, subPage, subpageListWidget)
    local subpageButton = ui.create {
        name = page.name..'_'..subPage.name..'_subPageButton',
        type = ui.TYPE.Widget,
        template = MWUI.templates.borders,
        props = {
            size = v2(subpageListWidget.layout.props.size.x / 3.5, subpageListWidget.layout.props.size.y),
        },
        content = ui.content {},
    }

    local subpageButtonBackground = ui.create {
        name = page.name..'_'..subPage.name..'_subPageButtonBackground',
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            resource = OTKUI.art.whiteTexture,
            color = OTKUI.art.colorBlack,
            alpha = 0.2,
            inheritAlpha = false,
        },
    }
    subpageButton.layout.content:add(subpageButtonBackground)
    subPage.buttonBackground = subpageButtonBackground

    local subpageButtonText = ui.create {
        name = page.name..'_'..subPage.name..'_subPageButtonText',
        type = ui.TYPE.Text,
        props = {
            text = subPage.name,
            textSize = OTKUI.constants.SUBPAGE_BUTTON_TEXT_SIZE,
            textColor = OTKUI.art.morrowindGold,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
        content = ui.content {},
    }
    subpageButton.layout.content:add(subpageButtonText)

    local clickBox = ui.create {
        name = page.name..'_'..subPage.name..'_subPageClickBox',
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            alpha = 0,
            inheritAlpha = false,
        },
        content = ui.content {},
        events = {},
    }

    clickBox.layout.events = {
        focusGain = async:callback(function ()
            onFrameFunctions[page.name..'_'..subPage.name..'_subPageFocusGain'] = function ()
                if scrollableWindow == nil and page.subPageListHostWidget then
                    setScrollTarget(page.subPageListFlex, page.subPageListHostWidget, getSubPageListSize(page))
                end
                if OTKUI.elems.currentSubPage ~= subPage then
                    subpageButtonBackground.layout.props.alpha = 0.35
                    subpageButtonBackground.layout.props.color = darkenColor(OTKUI.art.morrowindGold, 0.35)
                    subpageButtonBackground:update()
                end
            end
        end),
        focusLoss = async:callback(function ()
            onFrameFunctions[page.name..'_'..subPage.name..'_subPageFocusLoss'] = function ()
                clearScrollTarget(page.subPageListFlex)
                updateSubPageButtonVisual(subPage)
            end
        end),
        mousePress = async:callback(function (event)
            if event.button == 1 then
                onFrameFunctions[page.name..'_'..subPage.name..'_subPageMousePress'] = function ()
                    subpageButtonBackground.layout.props.alpha = 0.7
                    subpageButtonBackground.layout.props.color = darkenColor(OTKUI.art.morrowindGold, 0.7)
                    subpageButtonBackground:update()
                end
            end
        end),
        mouseRelease = async:callback(function (event)
            if event.button == 1 then
                onFrameFunctions[page.name..'_'..subPage.name..'_subPageMouseRelease'] = function ()
                    showSubPage(subPage)
                end
            end
        end),
    }
    subpageButton.layout.content:add(clickBox)

    return subpageButton
end

---@param page table
---@param subpageListWidget any
---@param subpageListHostWidget any
---@param subpageListScrollBarStackWidget any
---@param subpageContentStackWidget any
local function buildSubPages(page, subpageListWidget, subpageListHostWidget, subpageListScrollBarStackWidget, subpageContentStackWidget)
    if type(page.subPages) ~= 'table' then return end

    local buttonWidth = subpageListWidget.layout.props.size.x / 3.5
    page.subPageButtonWidth = buttonWidth
    page.subPageListHostWidget = subpageListHostWidget

    local subpageListFlex = ui.create {
        name = page.name..'_subPageListFlex',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            visible = false,
            position = v2(0, 0),
        },
        content = ui.content {},
        events = {},
    }
    page.subPageListFlex = subpageListFlex
    subpageListHostWidget.layout.content:add(subpageListFlex)

    subpageListFlex.layout.events = {
        focusGain = async:callback(function ()
            if scrollableWindow == nil then
                onFrameFunctions[page.name..'_subPageListFocusGain'] = function ()
                    setScrollTarget(subpageListFlex, subpageListHostWidget, getSubPageListSize(page))
                end
            end
        end),
        focusLoss = async:callback(function ()
            onFrameFunctions[page.name..'_subPageListFocusLoss'] = function ()
                clearScrollTarget(subpageListFlex)
            end
        end),
    }

    local subpageScrollBarHost = ui.create {
        name = page.name..'_subPageScrollBarHost',
        type = ui.TYPE.Widget,
        props = {
            visible = false,
            size = v2(0, 0),
        },
        content = ui.content {},
    }
    page.subPageScrollBarHost = subpageScrollBarHost
    subpageListScrollBarStackWidget.layout.content:add(subpageScrollBarHost)

    for i = 1, #page.subPages do
        local subPage = page.subPages[i]
        local subpageContentHost = ui.create {
            name = page.name..'_'..subPage.name..'_subPageContentHost',
            type = ui.TYPE.Widget,
            --template = MWUI.templates.borders,
            props = {
                visible = false,
                size = subpageContentStackWidget.layout.props.size,
            },
            content = ui.content {},
        }
        subPage.contentHost = subpageContentHost
        subpageContentStackWidget.layout.content:add(subpageContentHost)

        if subPage.type == 'text' then
            buildTextSubPage(subPage, subpageContentHost)
        end

        subpageListFlex.layout.content:add(buildSubPageButton(page, subPage, subpageListWidget))
    end

    page.hasSubPageScrollBar = addScrollBar(
        subpageScrollBarHost,
        subpageListFlex,
        subpageListHostWidget,
        getSubPageListSize(page),
        {
            namePrefix = page.name..'_subPageList',
            reserveSpace = false,
        }
    ) ~= nil
end

-- Builds our page list from pageList info
---@param pageFlex any -- UI element
---@param pageListHost any -- UI element
local function buildPageList(pageFlex, pageListHost)
    if not pageFlex or not pageFlex.layout then return end
    if not pageListHost or not pageListHost.layout then return end

    local pageWidth = pageListHost.layout.props.size.x

    -- Iterate through the page list
    for i = 1, OTKUI.pages.count do
        local page = OTKUI.pages.list[i]
        if page then
            local pageWidget = ui.create {
                type = ui.TYPE.Widget,
                name = page.name..'_pageWidget',
                template = MWUI.templates.borders,
                props = {
                    anchor = v2(0.5, 0.5),
                    size = v2(pageWidth, OTKUI.constants.PAGE_BUTTON_SIZE),
                    --relativePosition = v2(0.5, 0.5),
                },
                content = ui.content {},
            }

            local pageBackground = ui.create {
                type = ui.TYPE.Image,
                name = page.name..'_pageBackground',
                inheritAlpha = false, -- So our text doesn't get alpha'd
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    relativeSize = v2(1, 1),
                    resource = OTKUI.art.whiteTexture,
                    alpha = 0.4,
                    color = OTKUI.art.colorBlack,
                },
                events = {},
                content = ui.content {},
            }

            local pageText = ui.create {
                type = ui.TYPE.Text,
                name = page.name..'_pageButton_text',
                props = {
                    text = page.label,
                    textSize = OTKUI.constants.PAGE_BUTTON_TEXT_SIZE,
                    textColor = colorGetter.normal,
                    textShadow = true,
                    textShadowColor = OTKUI.art.colorBlack,
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                }
            }

            pageWidget.layout.content:add(pageBackground)

            pageWidget.layout.content:add(pageText)

            -- Clickbox goes over top of the button
            local clickBox = ui.create {
                type = ui.TYPE.Image,
                name = page.name..'_pageButton_clickBox',
                props = {
                    relativeSize = v2(1, 1),
                    alpha = 0,
                },
                content = ui.content {},
                events = {},
            }
            
            clickBox.layout.events = {
                focusGain = async:callback(function ()
                    onFrameFunctions[page.name..'_focusGain'] = function ()
                        if scrollableWindow == nil then
                            setScrollTarget(pageFlex, pageListHost, getPageListSize())
                        end
                        pageBackground.layout.props.alpha = 0.6
                        pageBackground.layout.props.color = darkenColor(OTKUI.art.morrowindGold, 0.4)
                        pageBackground:update()
                    end
                end),
                focusLoss = async:callback(function ()
                    onFrameFunctions[page.name..'_focusLoss'] = function ()
                        if scrollableWindow ~= nil then
                            clearScrollTarget(pageFlex)
                        end
                        pageBackground.layout.props.alpha = 0.4
                        pageBackground.layout.props.color = OTKUI.art.colorBlack
                        pageBackground:update()
                    end
                end),
                mousePress = async:callback(function (event)
                    if event.button == 1 then
                        onFrameFunctions[page.name..'_mousePress'] = function ()
                            pageBackground.layout.props.alpha = 0.9
                            pageBackground.layout.props.color = darkenColor(OTKUI.art.morrowindGold, 0.9)
                            pageBackground:update()
                        end
                    end
                end),
                mouseRelease = async:callback(function (event)
                    if event.button == 1 then
                        onFrameFunctions[page.name..'_mouseRelease'] = function ()
                            pageBackground.layout.props.alpha = 0.7
                            pageBackground.layout.props.color = darkenColor(OTKUI.art.morrowindGold, 0.7)
                            pageBackground:update()
                            showPage(page)
                        end
                    end
                end)
            }
            pageWidget.layout.content:add(clickBox) -- Add our clickbox over top of other elements

            pageFlex.layout.content:add(pageWidget)
            --pageListModule.layout.content:add{ props = { size = v2(5, 5) } } -- Creates a 5 pixel spacer between pages
        end
    end
end

---@type table<any, any> -- Stores each host's original size so we don't keep shrinking it
local scrollHostSizes = {}

-- Function to reserve space inside a host element for a scrollbar.
---@param flexHost any -- UI element which contains the scrollable flex
---@param thickness integer -- Width/height of the scrollbar track
---@param isHorizontal boolean -- True if the flex scrolls horizontally
---@return boolean -- True if host size was adjusted successfully
local function reserveScrollBarSpace(flexHost, thickness, isHorizontal)
    if not flexHost or not flexHost.layout then return false end

    local hostSize = flexHost.layout.props.size
    if not hostSize then
        print('[OTK - ERR] OTKTavernMenu.reserveScrollBarSpace: flexHost has no size: ' .. tostring(flexHost))
    end

    -- Keep the original size so repeated calls do not keep subtracting thickness
    local baseSize = scrollHostSizes[flexHost] or hostSize
    scrollHostSizes[flexHost] = baseSize

    if isHorizontal then
        flexHost.layout.props.size = v2(baseSize.x, math.max(0, baseSize.y - thickness))
    else
        flexHost.layout.props.size = v2(math.max(0, baseSize.x - thickness), baseSize.y)
    end

    flexHost:update()
    return true
end

---@class ScrollBarOptions
---@field namePrefix? string
---@field reserveSpace? boolean

-- Function called to add a scroll bar (when needed)
---@param scrollBarHost any -- UI element
---@param flexElem any -- UI element
---@param flexHost any -- UI element
---@param contentSize number
---@param options? ScrollBarOptions
---@return any|nil
addScrollBar = function (scrollBarHost, flexElem, flexHost, contentSize, options)
    if not scrollBarHost or not scrollBarHost.layout then return nil end

    local scrollMetrics = getScrollMetrics(flexElem, flexHost, contentSize) -- Get our scroll bar metrics
    if not scrollMetrics or not scrollMetrics.canScroll then return nil end -- If a scrollbar is unnecessary, we bail out early

    options = options or {}

    local thickness = scrollMetrics.isHorizontal and OTKUI.constants.HORIZONTAL_SCROLLBAR_THICKNESS or OTKUI.constants.VERTICAL_SCROLLBAR_THICKNESS -- The width (for vertical) or height (for horizontal) of the track/thumb

    local namePrefix = options.namePrefix or (flexElem.layout.name or 'scroll')
    local reserveSpace = options.reserveSpace ~= false

    -- Reserve space if a scrollbar is needed
    if reserveSpace then
        reserveScrollBarSpace(flexHost, thickness, scrollMetrics.isHorizontal)
    end

    -- Recalculate after shrinking the host, since hostSize has changed
    scrollMetrics = getScrollMetrics(flexElem, flexHost, contentSize)
    if not scrollMetrics then return nil end

    local trackSize -- The 'track' is the total size of a scrollbar
    local thumbSize
    local thumbLength

    if scrollMetrics.isHorizontal then
        trackSize = v2(scrollMetrics.hostSize, thickness)
        thumbLength = math.min(OTKUI.constants.HORIZONTAL_THUMB_SIZE.x, scrollMetrics.hostSize)
        thumbSize = v2(thumbLength, OTKUI.constants.HORIZONTAL_THUMB_SIZE.y)
    else
        trackSize = v2(thickness, scrollMetrics.hostSize)
        thumbLength = math.min(OTKUI.constants.VERTICAL_THUMB_SIZE.y, math.max(0, scrollMetrics.hostSize - (OTKUI.constants.VERTICAL_THUMB_CAP_HEIGHT * 2)))
        thumbSize = v2(thickness, thumbLength)
    end

    scrollBarHost.layout.props.size = trackSize
    scrollBarHost:update()

    local scrollBarWidget = ui.create {
        name = namePrefix..'_scrollBarWidget',
        type = ui.TYPE.Widget,
        --template = MWUI.templates.borders,
        props = {
            size = trackSize,
        },
        content = ui.content {},
    }

    local trackImage = ui.create {
        name = namePrefix..'_trackImage',
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            resource = scrollMetrics.isHorizontal and getTexture('textures/nibby/hor_track.dds') or getTexture('textures/tx_scroll_bar.dds'),
        }
    }
    scrollBarWidget.layout.content:add(trackImage)

    local scrollBarThumb = ui.create {
        name = namePrefix..'_scrollBarThumb',
        type = ui.TYPE.Image,
        props = {
            size = thumbSize,
            resource = getThumbTexture(scrollMetrics.isHorizontal),
            position = v2(0, 0),
        },
        content = ui.content {},
    }

    local thumbTop = nil
    local thumbBottom = nil

    if not scrollMetrics.isHorizontal then
        -- Adds Thumb tops and bottoms to vertical scroll bars
        -- Disabled for now because it looks ugly and is unnecessary
        --thumbTop, thumbBottom = addThumbCaps(scrollBarThumb, thickness)
    end

    scrollBarWidget.layout.content:add(scrollBarThumb)
    scrollBarHost.layout.content:add(scrollBarWidget)

    scrollBars[flexElem] = {
        track = scrollBarWidget,
        thumb = scrollBarThumb,
        thumbTop = thumbTop,
        thumbBottom = thumbBottom,
        hostElem = flexHost,
        scrollBarHost = scrollBarHost,
        contentSize = contentSize,
        thickness = thickness,
        thumbLength = thumbLength,
        reserveSpace = reserveSpace,
    }

    return scrollBarWidget
end

-- Function called to update the scroll bar of a given UI element
---@param flexElem any -- UI element
updateScrollBar = function (flexElem)
    local scrollBarData = scrollBars[flexElem]
    if not scrollBarData then return end

    local isHorizontal = flexElem.layout.props.horizontal == true
    if scrollBarData.reserveSpace then
        reserveScrollBarSpace(scrollBarData.hostElem, scrollBarData.thickness, isHorizontal)
    end

    local scrollMetrics = getScrollMetrics(flexElem, scrollBarData.hostElem, scrollBarData.contentSize)
    if not scrollMetrics or not scrollMetrics.canScroll then return end

    local trackSize
    if scrollMetrics.isHorizontal then
        trackSize = v2(scrollMetrics.hostSize, scrollBarData.thickness)
    else
        trackSize = v2(scrollBarData.thickness, scrollMetrics.hostSize)
    end

    scrollBarData.scrollBarHost.layout.props.size = trackSize
    scrollBarData.track.layout.props.size = trackSize

    -- Recalculate thumb size in case the host or content size changed
    -- Thumb gets smaller as total content gets larger
    local thumbLength = math.min(scrollBarData.thumbLength, scrollMetrics.hostSize)

    -- travelRange is how far the thumb body can move inside the track
    local travelRange = math.max(0, scrollMetrics.hostSize - thumbLength)

    local scrollFraction = 0

    if scrollMetrics.scrollRange > 0 then
        -- currentPos moves from 0 to a negative minPos as the content scrolls
        -- Negating currentPos turns it into a position progress value
        -- Dividing by scrollRange converts it into a 0.0 to 1.0 fraction (0.0 = top/start, 1.0 = bottom/end)
        scrollFraction = (-scrollMetrics.currentPos) / scrollMetrics.scrollRange
    end

    -- Convert scroll progress from 0.0-1.0 fraction into a pixel offset
    local thumbPos = math.floor(travelRange * scrollFraction)

    if scrollMetrics.isHorizontal then
        scrollBarData.thumb.layout.props.size = v2(thumbLength, OTKUI.constants.HORIZONTAL_THUMB_SIZE.y)
        scrollBarData.thumb.layout.props.position = v2(thumbPos, 0)
    else
        scrollBarData.thumb.layout.props.size = v2(scrollBarData.thickness, thumbLength)
        -- Offset the body by the top cap height so the full visual thumb, including both caps, stays inside the track
        scrollBarData.thumb.layout.props.position = v2(0, thumbPos)
    end

    scrollBarData.thumb.layout.props.resource = getThumbTexture(scrollMetrics.isHorizontal)

    if scrollBarData.thumbTop and scrollBarData.thumbBottom then
        scrollBarData.thumbTop.layout.props.visible = true -- Only add the caps if its a vertical scroll bar
        scrollBarData.thumbBottom.layout.props.visible = true

        scrollBarData.thumbTop.layout.props.size = v2(scrollBarData.thickness, OTKUI.constants.VERTICAL_THUMB_CAP_HEIGHT) -- Set their size
        scrollBarData.thumbBottom.layout.props.size = v2(scrollBarData.thickness, OTKUI.constants.VERTICAL_THUMB_CAP_HEIGHT)

        scrollBarData.thumbTop:update()
        scrollBarData.thumbBottom:update()
    end

    scrollBarData.scrollBarHost:update()
    scrollBarData.thumb:update()
    scrollBarData.track:update()
end

-- Function called for mouse wheel behavior in the page list
---@param direction number
local function scrollElem(direction)
    if not scrollableWindow or not scrollableWindow.layout then return end -- scrollableWindow can become nil between frames
    if not hostElem or not hostElem.layout then return end
    if not scrollContentSize then return end

    local scrollMetrics = getScrollMetrics(scrollableWindow, hostElem, scrollContentSize)
    if not scrollMetrics then
        print('[OTK - ERR] OTKTavernMenu.scrollElem: Failed to get scroll metrics!')
        return
    end

    if not scrollMetrics.canScroll then return end -- Not enough elements to need scrolling

    -- Clamp the attempted new position so the flex stays inside its legal range:
    -- 0                    = fully at the start/top
    -- scrollMetrics.minPos = fully at the end/bottom (usually negative)
    local newPos = math.max(scrollMetrics.minPos, math.min(0, scrollMetrics.currentPos + direction))

    if scrollMetrics.isHorizontal then
        scrollableWindow.layout.props.position = v2(newPos, scrollMetrics.flexPos.y)
    else
        scrollableWindow.layout.props.position = v2(scrollMetrics.flexPos.x, newPos)
    end

    scrollableWindow:update()
    updateScrollBar(scrollableWindow)
end

-- Function used for exit button mouse logic
---@param elem any -- UI element
---@param texturePath string
---@param shouldClose boolean
local function exitButtonLogic(elem, texturePath, shouldClose)
    elem.layout.props.resource = getTexture(texturePath)
    elem:update()
    if shouldClose then
        closeMenu()
    end
end

local function registerTextTooltip()
    OTKUI.elems.tooltip.tooltipText = ui.create {
        name = 'textTooltipText',
        type = ui.TYPE.Text,
        props = {
            text = '',
            textColor = OTKUI.art.morrowindLight,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            textSize = 14,
        }
    }
    OTKUI.elems.tooltip.hostWidget.layout.content:add(OTKUI.elems.tooltip.tooltipText)
end

local function registerTooltip()
    OTKUI.elems.tooltip.hostWidget = ui.create {
        name = 'textTooltipWidget',
        type = ui.TYPE.Container,
        template = MWUI.templates.boxTransparent,
        layer = 'Popup',
        props = {
            position = v2(0, 0),
            --relativePosition = v2(0.5, 0.5),
            visible = false,
        },
        content = ui.content {},
        events = {},
    }

    registerTextTooltip()
end

local function updateTextTooltip(text, mousePosition)
    OTKUI.elems.tooltip.tooltipText.layout.props.text = text
    OTKUI.elems.tooltip.tooltipText:update()

    OTKUI.elems.tooltip.hostWidget.layout.props.position = mousePosition + v2(16, 16)
    OTKUI.elems.tooltip.hostWidget.layout.props.visible = true
    OTKUI.elems.tooltip.hostWidget:update()
end

local function clearTextTooltip()
    OTKUI.elems.tooltip.tooltipText.layout.props.text = ''
    OTKUI.elems.tooltip.tooltipText:update()

    OTKUI.elems.tooltip.hostWidget.layout.props.position = v2(0, 0)
    OTKUI.elems.tooltip.hostWidget.layout.props.visible = false
    OTKUI.elems.tooltip.hostWidget:update()
end

updateSubPageHelpButtonVisibility = function()
    local subpageHelpButton = OTKUI.elems.subpageHelpButton
    if not subpageHelpButton or not subpageHelpButton.layout then return end

    local currentSubPage = OTKUI.elems.currentSubPage
    local tooltip = currentSubPage and currentSubPage.tooltip
    local hasTooltip = type(tooltip) == 'string' and tooltip ~= ''

    OTKUI.elems.tooltip.currentTooltip = hasTooltip and tooltip or nil
    subpageHelpButton.layout.props.visible = hasTooltip
    subpageHelpButton:update()

    if not hasTooltip and OTKUI.elems.tooltip.hostWidget then
        clearTextTooltip()
    end
end

-- Called to construct the menu
local function buildMenu()
    print('[OTK] OTKTavernMenu.buildMenu: Building the Tavern Menu!')
    OTKUI.elems.currentPage = nil
    OTKUI.elems.currentSubPage = nil
    OTKUI.elems.subPageListScrollBarStackWidget = nil
    OTKUI.elems.subPageContentStackWidget = nil
    OTKUI.elems.subPageContentBaseSize = nil

    -- Variables used to scale assets by screen size
    local screenSize = ui.layers[2].size
    local rootSize = v2(screenSize.x * 0.5, screenSize.y * 0.7) -- Defines our root widget size

    -- Lets us easily add spacing to elements ui.content{} for spacing
    local paddingSpacer = { props = { size = (v2(5, 5)) } }

    OTKUI.elems.rootWidget = ui.create {
        name = 'rootWidget',
        type = ui.TYPE.Widget,
        layer = 'Windows',
        --template = MWUI.templates.bordersThick,
        props = {
            visible = false,
            size = rootSize * 1.3,
            anchor = v2(0.5, 0.5),
            position = v2(screenSize.x / 2, screenSize.y / 2),
        },
        content = ui.content {},
    }

    local rootBackground = ui.create {
        name = 'rootBackground',
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            resource = getTexture('textures/nibby/scroll.dds')
        },
    }
    OTKUI.elems.rootWidget.layout.content:add(rootBackground)

    -- Root Vertical Flex, which will allow the UI to grow vertically
    local rootVerticalFlex = ui.create {
        name = 'rootVerticalFlex',
        type = ui.TYPE.Flex,
        props = {
            horizontal = false, -- Grows vertically
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = ui.content {},
    }
    OTKUI.elems.rootWidget.layout.content:add(rootVerticalFlex)

    -- Top Bar to hold our Back, Forward and Exit buttons
    local topBarWidget = ui.create {
        name = 'topBarWidget',
        type = ui.TYPE.Widget,
        --template = MWUI.templates.borders,
        props = {
            size = v2(rootSize.x, 48), -- width is rootSize, height is size of exit button asset
            anchor = v2(0.5, 0.5),
        },
        content = ui.content {},
        events = {},
    }

    -- Event for allowing the UI to be moved
    -- Thanks to nox7 and S3ctor
    --[[
    topBarWidget.layout.events = {
        mouseMove = async:callback(function (event)
            if event.button ~= 1 then return end -- Checks for left click
            local mousePos = event.position
            local newPos = mousePos + v2(rootSize.x, rootSize.y * 0.8) -- Offsets the position; a rough approximation

            onFrameFunctions[topBarWidget.layout.name..'_mouseMove'] = function ()
                OTKUI.elems.rootWidget.layout.props.position = newPos
                OTKUI.elems.rootWidget:update()
            end
        end)
    }
    ]]--

    rootVerticalFlex.layout.content:add(topBarWidget)

    -- Previous History button
    local previousButton = ui.create {
        name = 'previousButton',
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture{ path = 'textures/omw_menu_scroll_left.dds' },
            size = v2(24, 24), -- Double the size of the image
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0, 0.5),
            position = v2(16, 0), -- Nudge it over
            alpha = 0.5, -- Starts dimmed with no History to go back to

        }
    }
    topBarWidget.layout.content:add(previousButton)

    -- Forward History button
    local forwardButton = ui.create {
        name = 'forwardButton',
        type = ui.TYPE.Image,
        props = {
            resource = getTexture('textures/omw_menu_scroll_right.dds'),
            size = v2(24, 24),
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0, 0.5),
            position = v2(48, 0), -- Nudge it over by twice its size (accounts for Prev button)
            alpha = 0.5, -- Starts dimmed with no History to go forward to
        }
    }
    topBarWidget.layout.content:add(forwardButton)

    -- Exit Menu button
    local exitButton = ui.create {
        name = 'exitButton',
        type = ui.TYPE.Image,
        props = {
            resource = getTexture('textures/menu_exitgame.dds'),
            size = v2(96, 48), -- 75% of original texture size
            anchor = v2(0.5, 0.5),
            relativePosition = v2(1, 0.5),
            position = v2(-32, 4), -- Nudges it over
        },
        events = {},
    }

    -- Exit Button mouse events
    exitButton.layout.events = {
        focusGain = async:callback(function()
            onFrameFunctions['exitButtonFocusGain'] = function()
                exitButtonLogic(exitButton, 'textures/menu_exitgame_over.dds', false)
            end
        end),
        focusLoss = async:callback(function()
            onFrameFunctions['exitButtonFocusLoss'] = function()
                exitButtonLogic(exitButton, 'textures/menu_exitgame.dds', false)
            end
        end),
        mousePress = async:callback(function()
            onFrameFunctions['exitButtonMousePress'] = function()
                exitButtonLogic(exitButton, 'textures/menu_exitgame_pressed.dds', false)
            end
        end),
        mouseRelease = async:callback(function()
            onFrameFunctions['exitButtonMouseRelease'] = function()
                exitButtonLogic(exitButton, 'textures/menu_exitgame.dds', true)
            end
        end)
    }

    topBarWidget.layout.content:add(exitButton)

    rootVerticalFlex.layout.content:add(paddingSpacer)

    -- Top row for title and tavern log
    local topHorizontalFlex = ui.create {
        name = 'rootHorizontalFlex',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {},
    }
    rootVerticalFlex.layout.content:add(topHorizontalFlex)

    -- Widget to hold the Title and Subtitle
    local titleBoxWidget = ui.create {
        name = 'titleBoxWidget',
        type = ui.TYPE.Widget,
        template = MWUI.templates.borders,
        props = {
            size = v2(rootSize.x / 2, (rootSize.y / 5)), -- Width is rootSize, height is 1/3 of rootSize
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
        },
        content = ui.content {},
    }
    topHorizontalFlex.layout.content:add(titleBoxWidget) -- Gets added to left-side column

    local titleBoxBackground = ui.create {
        name = 'titleBoxBackground',
        type = ui.TYPE.Image,
        props = {
            inheritAlpha = false,
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            relativeSize = v2(1, 1),
            resource = OTKUI.art.whiteTexture,
            color = OTKUI.art.colorBlack,
            alpha = 0.4,
        },
        content = ui.content {},
    }
    titleBoxWidget.layout.content:add(titleBoxBackground)

    -- Title Text above our Page List
    local titleText = ui.create {
        type = ui.TYPE.Text,
        name = 'titleText',
        props = {
            text = modLocale('tavern_menu_title', {}),
            textSize = OTKUI.constants.TITLE_TEXT_SIZE,
            textColor = OTKUI.art.morrowindGold,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0), -- Anchors halfway across X, top of Y
            position = v2(0, ((titleBoxWidget.layout.props.size.y) / 4)) -- Brings it down 1/4 of the box's height
        }
    }
    titleBoxWidget.layout.content:add(titleText)

    -- Subtitle Text below the Title Text
    OTKUI.elems.subtitleText = ui.create {
        type = ui.TYPE.Text,
        name = 'subtitleText',
        props = {
            text = '',
            textSize = OTKUI.constants.SUBTITLE_TEXT_SIZE,
            textColor = OTKUI.art.morrowindLight,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5), -- Centers the Subtitle
            position = v2(0, ((rootSize.y / 3) / 5)) -- Brings it down 1/5 of the box's height
        }
    }
    titleBoxWidget.layout.content:add(OTKUI.elems.subtitleText)

    topHorizontalFlex.layout.content:add(paddingSpacer)

    local logWidget = ui.create {
        name = 'logWidget',
        type = ui.TYPE.Widget,
        template = MWUI.templates.borders,
        props = {
            size = v2((rootSize.x / 2), titleBoxWidget.layout.props.size.y),
        },
        content = ui.content {},
    }
    topHorizontalFlex.layout.content:add(logWidget)

    local logBackground = ui.create {
        name = 'logBackground',
        type = ui.TYPE.Image,
        props = {
            inheritAlpha = false,
            relativePosition = v2(0.5, 0.5),
            relativeSize = v2(1, 1),
            anchor = v2(0.5, 0.5),
            resource = OTKUI.art.whiteTexture,
            color = OTKUI.art.colorBlack,
            alpha = 0.6,
        },
        content = ui.content {},
    }
    logWidget.layout.content:add(logBackground)

    -- Page Description text
    local logText = ui.create {
        name = 'logText',
        type = ui.TYPE.Text,
        props = {
            --anchor = v2(0.5, 0.5),
            text = "Tavern Log Here",
            textSize = 18,
            textColor = OTKUI.art.morrowindLight,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Start,
        },
    }
    logWidget.layout.content:add(logText)

    rootVerticalFlex.layout.content:add(paddingSpacer)

    -- Horizontal flex for our page list and page content
    local pageHorizontalFlex = ui.create {
        name = 'pageHorizontalFlex',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {},
    }
    rootVerticalFlex.layout.content:add(pageHorizontalFlex)

    
    -- Page List widget which limits the size of the page list (so we have to scroll through it)
    local pageListWidget = ui.create {
        name = 'pageListWidget',
        type = ui.TYPE.Widget,
        template = MWUI.templates.borders,
        props = {
            size = v2(rootSize.x / 3, rootSize.y / 2),
        },
        content = ui.content {},
        events = {},
    }
    pageHorizontalFlex.layout.content:add(pageListWidget)

    -- Horizontal flex for our page list & scroll bar
    local pagelistHorizontalFlex = ui.create {
        name = 'pageListHorizontalFlex',
        type = ui.TYPE.Flex,
        --template = MWUI.templates.borders,
        props = {
            size = pageListWidget.layout.props.size,
            horizontal = true,
        },
        content = ui.content {},
    }
    pageListWidget.layout.content:add(pagelistHorizontalFlex)

    local pageListHostWidget = ui.create {
        name = 'pageListHostWidget',
        type = ui.TYPE.Widget,
        props = {
            size = pageListWidget.layout.props.size,
        },
        content = ui.content {},
        events = {},
    }
    
    -- Scrollbar host sits to the left of the page list host inside the horizontal flex.
    local pageListScrollBarHost = ui.create {
        name = 'pageListScrollBarHost',
        type = ui.TYPE.Widget,
        props = {
            size = v2(0, 0),
        },
        content = ui.content {},
    }
    pagelistHorizontalFlex.layout.content:add(pageListScrollBarHost)
    pagelistHorizontalFlex.layout.content:add(pageListHostWidget)

    -- Page List flex so our page list can grow
    local pageListFlex = ui.create {
        name = 'pageListFlex',
        type = ui.TYPE.Flex,
        --template = MWUI.templates.borders,
        props = {
            position = v2(0, 0), -- Must be declared to be used by scroll function
            horizontal = false,
        },
        content = ui.content {},
        events = {},
    }

    -- pageListWidget events are declared after pageListFlex so we can reference it
    pageListWidget.layout.events = {
        focusGain = async:callback(function ()
            if scrollableWindow == nil then
                onFrameFunctions['pageList_focusGain'] = function ()
                    setScrollTarget(pageListFlex, pageListHostWidget, getPageListSize())
                end
            end
        end)
    }

    -- Catches our mouse between page buttons
    pageListFlex.layout.events = {
        focusGain = async:callback(function ()
            if scrollableWindow == nil then
                onFrameFunctions['pageList_focusGain'] = function ()
                    setScrollTarget(pageListFlex, pageListHostWidget, getPageListSize())
                end
            end
        end),
    }

    pageListHostWidget.layout.content:add(pageListFlex)

    -- Load our Page modules
    loadPageFiles()

    -- Calls for our scroll bar function for the page list
    addScrollBar(
        pageListScrollBarHost,
        pageListFlex,
        pageListHostWidget,
        getPageListSize(),
        {
            namePrefix = 'pageList',
        }
    )

    buildPageList(pageListFlex, pageListHostWidget)
    updateScrollBar(pageListFlex)

    pageHorizontalFlex.layout.content:add(paddingSpacer)

    -- Holds our page content
    local pageContentHost = ui.create {
        name = 'pageContentHost',
        type = ui.TYPE.Widget,
        template = MWUI.templates.borders,
        props = {
            size = v2((rootSize.x / 1.5), (rootSize.y / 2)),
        },
        content = ui.content {},
    }
    pageHorizontalFlex.layout.content:add(pageContentHost)

    local pageContentBackground = ui.create {
        name = 'pageContentBackground',
        type = ui.TYPE.Image,
        props = {
            relativeSize = v2(1, 1),
            resource = OTKUI.art.whiteTexture,
            color = OTKUI.art.colorBlack,
            alpha = 0.4,
        },
        content = ui.content {},
    }
    pageContentHost.layout.content:add(pageContentBackground)

    local pageContentFlex = ui.create {
        name = 'pageContentFlex',
        type = ui.TYPE.Flex,
        props = {
            relativeSize = v2(1, 1),
            horizontal = false,
        },
        content = ui.content {},
    }
    pageContentHost.layout.content:add(pageContentFlex)

    local subpageListWidget = ui.create {
        name = 'subpageListWidget',
        type = ui.TYPE.Widget,
        --template = MWUI.templates.borders,
        props = {
            anchor = v2(0.5, 0.5),
            size = v2(pageContentHost.layout.props.size.x - 4, 32),
        },
        content = ui.content {},
    }
    pageContentFlex.layout.content:add(subpageListWidget)

    local subpageListHostWidget = ui.create {
        name = 'subpageListHostWidget',
        type = ui.TYPE.Widget,
        props = {
            size = subpageListWidget.layout.props.size,
        },
        content = ui.content {},
        events = {},
    }
    subpageListWidget.layout.content:add(subpageListHostWidget)

    subpageListHostWidget.layout.events = {
        focusGain = async:callback(function ()
            if scrollableWindow == nil and OTKUI.elems.currentPage and OTKUI.elems.currentPage.subPageListFlex then
                onFrameFunctions['subPageListHost_focusGain'] = function ()
                    setScrollTarget(
                        OTKUI.elems.currentPage.subPageListFlex,
                        subpageListHostWidget,
                        getSubPageListSize(OTKUI.elems.currentPage)
                    )
                end
            end
        end),
    }

    OTKUI.elems.subPageListScrollBarStackWidget = ui.create {
        name = 'subpageListScrollBarStackWidget',
        type = ui.TYPE.Widget,
        props = {
            size = v2(subpageListWidget.layout.props.size.x, 0),
        },
        content = ui.content {},
    }
    pageContentFlex.layout.content:add(OTKUI.elems.subPageListScrollBarStackWidget)

    OTKUI.elems.subPageContentBaseSize = v2(
        pageContentHost.layout.props.size.x,
        pageContentHost.layout.props.size.y - subpageListWidget.layout.props.size.y
    )

    OTKUI.elems.subPageContentStackWidget = ui.create {
        name = 'subpageContentStackWidget',
        type = ui.TYPE.Widget,
        props = {
            size = OTKUI.elems.subPageContentBaseSize,
        },
        content = ui.content {},
    }
    pageContentFlex.layout.content:add(OTKUI.elems.subPageContentStackWidget)

    for i = 1, OTKUI.pages.count do
        local page = OTKUI.pages.list[i]
        if page then
            buildSubPages(
                page,
                subpageListWidget,
                subpageListHostWidget,
                OTKUI.elems.subPageListScrollBarStackWidget,
                OTKUI.elems.subPageContentStackWidget
            )
        end
    end

    -- The bottom bar, which runs along the bottom of the window
    local bottomBarWidget = ui.create {
        name = 'bottomBarWidget',
        type = ui.TYPE.Widget,
        --template = MWUI.templates.borders,
        props = {
            size = v2(384, 32), -- width is 15% of screen size
            anchor = v2(0.5, 0.5),
        },
        content = ui.content {}
    }
    rootVerticalFlex.layout.content:add(bottomBarWidget)

    -- Version Text in bottom left corner of Bottom Bar
    local versionText = ui.create {
        type = ui.TYPE.Text,
        name = 'versionText',
        props = {
            text = modLocale('otk_mod_version', {}),
            textSize = 14,
            textColor = OTKUI.art.morrowindLight,
            textShadow = true,
            textShadowColor = OTKUI.art.colorBlack,
            anchor = v2(0, 1), -- Anchors self by top-right corner
            relativePosition = v2(0, 1), -- Anchors to bottom-left corner of title box
            position = v2(7, -4), -- Offsets it by a few pixels
        }
    }
    bottomBarWidget.layout.content:add(versionText)

    OTKUI.elems.subpageHelpButton = ui.create {
        name = 'subpageHelpButton',
        type = ui.TYPE.Image,
        layer = 'Modal',
        props = {
            resource = getTexture('textures/nibby/tx_scroll_01_outline.dds'),
            size = v2(32, 32),
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
            position = v2(rootSize.x / 2, -rootSize.y / 8),
            --position = v2(rootSize.x * 1.15, (rootSize.y / 2 + (subpageListWidget.layout.props.size.y * 0.6))),
            visible = false,
        },
        events = {},
    }
    local subpageHelpButton = OTKUI.elems.subpageHelpButton

    registerTooltip()

    subpageHelpButton.layout.events = {
        focusGain = async:callback(function ()
            onFrameFunctions['subpageHelp_focusGain'] = function ()
                subpageHelpButton.layout.props.resource = getTexture('icons/m/tx_scroll_open_01.dds')
                subpageHelpButton:update()
            end
        end),
        focusLoss = async:callback(function ()
            onFrameFunctions['subpageHelp_focusLoss'] = function ()
                subpageHelpButton.layout.props.resource = getTexture('textures/nibby/tx_scroll_01_outline.dds')
                subpageHelpButton:update()
                clearTextTooltip()
            end
        end),
        mouseMove = async:callback(function (event)
            local mousePosition = event.position
            onFrameFunctions['subpageHelp_mouseMove'] = function ()
                local currentSubPage = OTKUI.elems.currentSubPage
                local tooltip = currentSubPage and currentSubPage.tooltip
                if type(tooltip) == 'string' and tooltip ~= '' then
                    updateTextTooltip(tooltip, mousePosition)
                else
                    clearTextTooltip()
                end
            end
        end),
    }
    --pageContentHost.layout.content:add(subpageHelpButton)

    print('[OTK] OTKTavernMenu: Tavern Menu built!')
end

-- Function called to open the menu
local function openMenu()
    if isRootVisible() then return end

    print('[OTK] OTKTavernMenu: Opening the Tavern Menu')

    -- Assign a random subtitle text
    local randomSplash = math.random(1, #splashList)
    OTKUI.elems.subtitleText.layout.props.text = splashList[randomSplash]
    OTKUI.elems.subtitleText:update()

    interfaces.UI.setMode('Interface', { windows = {}, target = self.object }) -- Clears the UI and unlocks the mouse
    OTKUI.elems.rootWidget.layout.props.visible = true -- Displays the menu
    OTKUI.elems.rootWidget:update() -- Required any time a UI element is changed

    if updateSubPageHelpButtonVisibility then
        updateSubPageHelpButtonVisibility()
    end
end

-- Function called by Trigger keybind to open/close the menu
local function toggleMenu()
    if isRootVisible() then
        onFrameFunctions['closeMenu'] = closeMenu -- Add it to our onFrame functions to avoid Delayed Action problems
    else
        openMenu()
    end
end

-- Tavern Hotkey handler, looks for our Trigger in OTKConfigHotkey.lua
input.registerTriggerHandler('otk_openmenu', async:callback(toggleMenu)) -- Calls toggleMenu()

-- Checks for Escape key to close menu
local function onKeyPress(key)
    if isRootVisible() and key.code == input.KEY.Escape then
        onFrameFunctions['closeMenu'] = closeMenu
    end
end

-- Right Click checker to close menu
local function onMouseButtonPress(button)
    if isRootVisible() and button == 3 then -- '3' = right click
        onFrameFunctions['closeMenu'] = closeMenu
    end
end

-- onFrame is used to call Functions from buttons
local function onFrame(dt)
    if not isRootVisible() then return end

    for key, func in pairs(onFrameFunctions) do
        onFrameFunctions[key] = nil
        if func then
            func(dt)
        end
    end
end

-- Mouse wheel behavior
local function onMouseWheel(vertical, horizontal)
    if not isRootVisible() or not scrollableWindow then return end -- Only in our UI; only in a scrollable window

    local direction = vertical -- prefer vertical
    if direction == 0 then
        direction = horizontal -- fallback to horizontal (uncommon but possible)
    end

    direction = direction * 10

    onFrameFunctions['scroll_elem'] = function ()
        scrollElem(direction)
    end
end

local function onLoad()
    buildMenu()
end

local function onInit()
    buildMenu()
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onKeyPress = onKeyPress,
        onMouseButtonPress = onMouseButtonPress,
        onFrame = onFrame,
        onMouseWheel = onMouseWheel,
    },
    eventHandlers = {
        AddOnFrameFunction = addOnFrameFunction,
    },
}
