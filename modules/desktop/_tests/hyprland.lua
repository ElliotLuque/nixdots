-- Exercise both generated configurations and the workspace helper without a compositor.
local settings, monitors, env, curves, binds, hooks, rules = {}, {}, {}, {}, {}, {}, {}
local pluginLoaded = false
local function noop() end
local dispatch = setmetatable({}, {
  __index = function()
    return setmetatable({}, {
      __index = function() return function() return noop end end,
      __call = function() return noop end,
    })
  end,
})

hl = {
  plugin = { load = function(path)
    assert(path:match("libhypr%-dynamic%-cursors.so$"))
    pluginLoaded = true
  end },
  config = function(values)
    assert(pluginLoaded, "plugins must load before configuration")
    settings = values
  end,
  env = function(name, value) env[name] = value end,
  monitor = function(value) table.insert(monitors, value) end,
  curve = function(name, value)
    assert(value.type == "bezier" and #value.points == 2)
    curves[name] = true
  end,
  animation = function(value)
    assert(curves[value.bezier], "animation references a curve before its definition")
  end,
  bind = function(key, action, flags)
    assert(type(key) == "string" and type(action) == "function")
    assert(not binds[key], "duplicate binding: " .. key)
    binds[key] = { action = action, flags = flags or {} }
  end,
  on = function(event, callback) hooks[event] = callback end,
  window_rule = function(value) rules[value.name] = value end,
  dsp = dispatch,
  dispatch = noop,
}
package.preload["hyprsplit"] = function()
  return {
    config = function(value)
      assert(value.num_workspaces == 4 and value.persistent_workspaces)
    end,
    get_workspace_string = function(value) return value end,
    dsp = { focus = function() return noop end },
  }
end

dofile(arg[1])
assert(settings.debug.damage_tracking == nil, "keep upstream damage tracking; disabling it forces full redraws")
assert(settings.general.gaps_in == 6, "host overrides discarded shared settings")
assert(settings.general.layout == "scrolling", "migration changed the shared layout")
assert(settings.dwindle == nil, "shared configuration should not include dwindle settings")
assert(settings.input.kb_layout == "es" and settings.input.kb_options == "caps:super")
assert(settings.plugin.dynamic_cursors.tilt.limit == 8000)
assert(env.XCURSOR_THEME == "Bibata-Original-Classic")
assert(env.JDK_JAVA_OPTIONS == "-Dawt.toolkit.name=WLToolkit")
assert(binds["SUPER + Return"])
assert(binds["SUPER + mouse:272"].flags.mouse)
assert(binds.XF86AudioRaiseVolume.flags.locked and binds.XF86AudioRaiseVolume.flags.repeating)
for i = 1, 4 do
  assert(binds["SUPER + " .. i])
  binds["SUPER + SHIFT + " .. i].action()
  binds["SUPER + CTRL + " .. i].action()
end
assert(hooks["hyprland.start"] and hooks["hyprland.shutdown"], "missing session lifecycle hooks")
assert(rules["suppress-maximize"].suppress_event == "maximize")
assert(rules["kitty-opacity"].opacity == "0.85 override 0.45 override 0.85 override")

if arg[2] == "laptop" then
  assert(settings.decoration.inactive_opacity == 1, "shared defaults overwrote laptop opacity")
  assert(settings.decoration.blur.enabled == false, "shared defaults overwrote laptop blur")
  assert(settings.input.touchpad.natural_scroll)
  assert(settings.device[1].name == "type:touchpad" and settings.device[1].sensitivity == 0.5)
  assert(env.AQ_DRM_DEVICES == "/dev/dri/card0:/dev/dri/card1")
  assert(#monitors == 1 and monitors[1].output == "" and monitors[1].scale == 1)
elseif arg[2] == "pc" then
  assert(settings.decoration.inactive_opacity == 0.8 and settings.decoration.blur.enabled)
  assert(settings.cursor.default_monitor == "HDMI-A-1")
  assert(settings.input.sensitivity == -1 and settings.opengl.nvidia_anti_flicker == 0)
  assert(#monitors == 2, "default monitor leaked into desktop configuration")
  assert(monitors[1].output == "HDMI-A-2" and monitors[1].position == "0x0")
  assert(monitors[2].output == "HDMI-A-1" and monitors[2].position == "2560x0")
  assert(monitors[1].scale == 1.5 and monitors[2].mode == "3840x2160@60")
else
  error("unknown test host")
end
