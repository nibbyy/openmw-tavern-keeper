local vfs = require('openmw.vfs')
local ui = require('openmw.ui')
local util = require('openmw.util')
local interfaces = require('openmw.interfaces')
local constants = require('scripts.omw.mwui.constants')
local self = require('openmw.self')
local async = require('openmw.async')

local MWUI = require('openmw.interfaces').MWUI
local v2 = util.vector2
local morrowindGold = util.color.rgb(0.792157, 0.647059, 0.376471)
local morrowindLight = util.color.rgb(0.87451, 0.788235, 0.623529)
local colorBlack = util.color.rgb(0, 0, 0)
local whiteTexture = constants.whiteTexture

-- Our Color Getter GMST module
local colorGetter = require('scripts.nibby.otk.menu.OTKColorGetter')

-- File path for our Page .lua files
local pageFilePath = 'scripts/nibby/otk/menu/pages/'

-- Our array of page modules
local pageList = {}

-- Values sent from OTKTavernMenu.buildMenu; declared early to be changed and checked easily
local pageListModule = nil
local userScreenSize = nil

-- Gets set by OTKTavernMenu with addOnFrameFunction func
local onFrames = {}
local function setOnFrames(data)
    onFrames = data or {}
end

local function darkenColor(color, multiplier)
    return util.color.rgb(color.r * multiplier, color.g * multiplier, color.b * multiplier)
end

-- Function to change file directory locations to module require names
local function pathToModuleName(fileName)
    return (fileName:gsub('\\', '.'):gsub('/', '.'):gsub('%.lua$', ""))
end

local function loadPageFiles()
    for fileName in vfs.pathsWithPrefix(pageFilePath) do
        if fileName:match('%.lua$') then
            require(pathToModuleName(fileName))
        end
    end
end

-- Sent from OTKTavernMenu, pageListFlex is our page list UI element
local function registerAllPages(pageListFlex, screenSize)
    pageListModule = pageListFlex
    userScreenSize = screenSize
    loadPageFiles()
end

-- Registers our pages by information from their .lua module
local function registerPage(page)
    if type(page) ~= 'table' then
        print('[OTK - ERR] OTKPageHandler.registerPage expected Page table, got: ' .. tostring(type(page)))
        return
    end

    if type(page.name) ~= 'string' or page.name == '' then
        print('[OTK - ERR] OTKPageHandler.registerPage: page.name must be a non-empty string in page: ' .. tostring(page))
        return
    end

    if type(page.text) ~= 'string' or page.text == '' then
        print('[OTK - ERR] OTKPageHandler.registerPage: page.text must be a non-empty string in page: ' .. tostring(page.name))
        return
    end

    if type(page.index) ~= 'number' or page.index == 0 then
        print('[OTK - ERR] OTKPageHandler.registerPage: page.index must be a Number above 0! Got: ' .. tostring(page.index))
        return
    end

    if pageList[page.index] == nil then
        pageList[page.index] = page
    else
        print('[OTK - ERR] OTKPageHandler.registerPage: Page: ' ..tostring(page.name) .. ' tried to claim Index that was already taken: ' ..tostring(page.index))
        return
    end
end

local function buildPageList()
    if not userScreenSize then
        print('[OTK - ERR] OTKPageHandler.buildPageList: User Screen Size never passed! Got: ' .. tostring(userScreenSize))
        return
    end

    if not pageListModule then
        print('[OTK - ERR] OTKPageHandler.buildPageList: Page List Flex module not passed! Got: ' .. tostring(pageListModule))
        return
    end

    local screenScale = math.min(userScreenSize.x / 1920, userScreenSize.y / 1080)

    -- Iterate through the page list
    for _, page in ipairs(pageList) do
        local pageWidget = ui.create {
            type = ui.TYPE.Widget,
            name = page.name..'_pagebutton_widget',
            template = MWUI.templates.borders,
            props = {
                anchor = v2(0.5, 0.5),
                size = v2(279, 64) * screenScale,
                relativePosition = v2(0.5, 0.5),
            },
            content = ui.content {},
        }

        local pageButton = ui.create {
            type = ui.TYPE.Image,
            name = page.name..'_pagebutton_image',
            --template = MWUI.templates.borders,
            props = {
                anchor = v2(0.5, 0.5),
                relativePosition = v2(0.5, 0.5),
                relativeSize = v2(1, 1),
                resource = whiteTexture,
                alpha = 0,
                color = colorBlack,
            },
            events = {},
            content = ui.content {},
        }

        if not onFrames.addOnFrameFunction then return end -- Checks to make sure we've received onFrameFunctions before creating events
        
        -- Page Button mouse events
        pageButton.layout.events = {
            focusGain = async:callback(function ()
                onFrames.addOnFrameFunction(page.name..'_focusGain', function () -- Adds an onFrameFunction to be loaded by OTKTavernMenu
                    pageButton.layout.props.alpha = 0.4
                    pageButton.layout.props.color = darkenColor(morrowindGold, 0.4)
                    pageButton:update()
                end)
            end),
            focusLoss = async:callback(function ()
                onFrames.addOnFrameFunction(page.name..'_focusLoss', function ()
                    pageButton.layout.props.alpha = 0
                    pageButton.layout.props.color = colorBlack
                    pageButton:update()
                end)
            end),
            mousePress = async:callback(function (event)
                -- Need a checker for if page is active
                if event.button == 1 then
                    onFrames.addOnFrameFunction(page.name..'_mousePress', function ()
                        pageButton.layout.props.alpha = 0.8
                        pageButton.layout.props.color = darkenColor(morrowindGold, 0.8)
                        pageButton:update()
                    end)
                end
            end),
            mouseRelease = async:callback(function (event)
                -- Need a checker for if page is active
                if event.button == 1 then
                    onFrames.addOnFrameFunction(page.name..'_mouseRelease', function ()
                        pageButton.layout.props.alpha = 0.6
                        pageButton.layout.props.color = darkenColor(morrowindGold, 0.6)
                        pageButton:update()
                    end)
                end
            end)
        }

        pageWidget.layout.content:add(pageButton)

        local pageText = ui.create {
            type = ui.TYPE.Text,
            name = page.name..'_pagebutton_text',
            props = {
                text = page.text,
                textSize = 18 * screenScale,
                textColor = colorGetter.normal,
                textShadow = true,
                textShadowColor = colorBlack,
                anchor = v2(0.5, 0.5),
                relativePosition = v2(0.5, 0.5),
            },
        }
        pageWidget.layout.content:add(pageText) -- Gets added to the Widget instead of the Image (so the Image can be dimmed appropriately)

        pageListModule.layout.content:add(pageWidget)
        pageListModule.layout.content:add{ props = { size = v2(5, 5) } } -- Adds a spacer between pages
    end
end

return {
    setOnFrames = setOnFrames,
    registerPage = registerPage,
    registerAllPages = registerAllPages,
    buildPageList = buildPageList,
}