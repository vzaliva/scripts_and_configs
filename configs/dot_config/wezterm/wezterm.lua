local wezterm = require 'wezterm'
local config = {}

config.color_scheme = 'Solarized Dark (Gogh)'
config.color_scheme = 'Solarized Dark - Patched'
config.color_scheme = 'Solarized (dark) (terminal.sexy)'


config.default_prog = { '/usr/bin/fish', '-l' }

-- Specify the font and font size here
config.font = wezterm.font("Ubuntu Mono")
config.font_size = 16

-- Hide tab bar if only one tab is open
config.hide_tab_bar_if_only_one_tab = true

config.keys = {
    -- Copy with Ctrl-C
    {key="c", mods="CTRL", action=wezterm.action{CopyTo="Clipboard"}},

    -- Paste with Ctrl-V
    {key="v", mods="CTRL", action=wezterm.action{PasteFrom="Clipboard"}},

    -- Send ^C with Shift-Ctrl-C
    {key="c", mods="SHIFT|CTRL", action=wezterm.action{SendString="\x03"}},
}

return config

