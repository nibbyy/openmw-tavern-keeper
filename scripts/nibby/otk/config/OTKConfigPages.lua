local interfaces = require('openmw.interfaces')
local core = require('openmw.core')

local modLocale = core.l10n('nibbyotk', 'en')

interfaces.Settings.registerPage {
    key = 'Settings/OTK',
    l10n = 'nibbyotk',
    name = modLocale('otk_mod_name', {}),
    description = modLocale('otk_mod_description', {}),
}