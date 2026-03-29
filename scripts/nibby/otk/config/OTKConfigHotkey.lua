local input = require('openmw.input')
local interfaces = require('openmw.interfaces')
local core = require('openmw.core')

local modLocale = core.l10n('nibbyotk', 'en')

input.registerTrigger {
    key = 'otk_openmenu',
    l10n = 'nibbyotk',
    name = '',
    description = '',
}

interfaces.Settings.registerGroup {
    key = 'Settings/OTK/Menu',
    page = 'Settings/OTK',
    l10n = 'nibbyotk',
    name = modLocale('tavern_settings_name', {}),
    description = modLocale('tavern_settings_description', {}),
    permanentStorage = true,
    order = 1,
    settings = {
        {
            key = 'OTK/Menu/Hotkey',
            renderer = 'inputBinding',
            name = modLocale('tavern_settings_hotkey', {}),
            description = modLocale('tavern_settings_hotkey_description', {}),
            default = 'OTK_OPENMENU_DEFAULT',
            argument = {
                type = 'trigger',
                key = 'otk_openmenu',
            }
        }
    }
}