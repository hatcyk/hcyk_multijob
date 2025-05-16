local Config = require 'config'
local Lang, _L = table.unpack(require 'lang')

--- A simple wrapper around SendNUIMessage that you can use to
--- dispatch actions to the React frame.
---
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action
function SendReactMessage(action, data)
  SendNUIMessage({
    action = action,
    data = data
  })
end

local currentResourceName = GetCurrentResourceName()

--- A simple debug print function that is dependent on Config.DebugMode
--- will output a nice prettfied message if debugMode is on
local debugPrint
if Config.DebugMode then
  debugPrint = function(...)
    local args = { ... }
    local appendStr = ''
    for _, v in ipairs(args) do
      appendStr = appendStr .. ' ' .. tostring(v)
    end
    local msgTemplate = '^3[%s]^0%s'
    local finalMsg = msgTemplate:format(currentResourceName, appendStr)
    print(finalMsg)
  end
else
  debugPrint = function() end
end

-- Make debugPrint available globally
_G.debugPrint = debugPrint
