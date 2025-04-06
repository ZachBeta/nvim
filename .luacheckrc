-- Basic config for Neovim plugin
std = {
  globals = {
    "vim", "assert", "describe", "it", "before_each", "after_each", -- Neovim and Busted testing
    -- Standard Lua globals often flagged:
    "require", "print", "pcall", "table", "string", "ipairs", "pairs", "type", "tostring", "select", "error", "_G", "loadstring"
  },
  read_globals = {"package"}
}
ignore = {
    "142", -- Setting non-standard global variable (used for package.loaded in tests)
    "143", -- Mutating non-standard global variable (used in tests for package.loaded)
    "212", -- Unused argument
    "631"  -- Line is too long
}
exclude_files = {
    "plugin/packer_compiled.lua" -- Ignore generated packer file
}