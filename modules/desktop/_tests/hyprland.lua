-- Exercise the generated configuration without a compositor or plugin binaries.
local settings = {}
local function merge(target, values)
  for key, value in pairs(values) do
    if type(value) == "table" and type(target[key]) == "table" then
      merge(target[key], value)
    else
      target[key] = value
    end
  end
end

local function noop() end
local dispatch = setmetatable({}, {
  __index = function()
    return setmetatable({}, { __index = function() return noop end, __call = noop })
  end,
})

hl = {
  plugin = { load = noop },
  config = function(values) merge(settings, values) end,
  env = noop,
  monitor = noop,
  curve = noop,
  animation = noop,
  bind = noop,
  on = noop,
  window_rule = noop,
  dsp = dispatch,
}
package.preload["hyprsplit-config"] = function() return {} end

dofile(arg[1])
assert(settings.decoration.inactive_opacity == 1, "shared defaults overwrote laptop opacity")
assert(settings.decoration.blur.enabled == false, "shared defaults overwrote laptop blur")
assert(settings.general.gaps_in == 6, "host overrides discarded shared settings")
