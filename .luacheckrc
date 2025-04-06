-- Basic config for Neovim plugin
std = {
  globals = {"vim", "assert", "describe", "it", "before_each", "after_each"},
  read_globals = {"package"}
}
ignore = {"212", "631"} -- Unused argument, line is too long