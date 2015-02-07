--[[  Simple Pneumaticcraft pressure control script
  * configure the side. 
  * Set the generator to active on redstone high.
--]]

-- the works ...
function regulatePressure(config, status)
  while (true) do
    local generator=peripheral.wrap(config.sideGenerator)
    local pressure = generator.getPressure()
    if (pressure < config.minPressure ) then
      redstone.setOutput(config.sideGenerator, true);
    elseif (pressure >= config.maxPressure) then
      redstone.setOutput(config.sideGenerator, false);
    end

    local interval = redstone.getOutput(config.sideGenerator) and 0.5 or 2

    status.running = redstone.getOutput(config.sideGenerator)
    status.pressure = pressure

    local schedId = os.startTimer(interval)
    repeat
      local event, timerId = os.pullEvent("timer")
    until timerId == schedId
  end
end

local defConfig =  {
  -- side the generator is at (left, right, front, back, up, down)
  sideGenerator = "right",
  -- minimum pressure ([1-20])
  minPressure   = 12,
  -- maximum pressure([1-20])
  maxPressure   = 18,
}

--safety: pick the worst machine / pipe
function detectValues(config)
  for i,name in ipairs(peripheral.getNames()) do
    local side = nil
    local dangerPressure = 1000
    if ("pneumaticMachine" == peripheral.getType(name)) then
      if dangerPressure > peripheral.call(name, "getDangerPressure") then
        side = name
        dangerPressure = peripheral.call(name, "getDangerPressure")
      end
    end
    if side then
      config.sideGenerator = side
      config.minPressure = 0.7 * dangerPressure
      config.maxPressure = 0.9 * dangerPressure
    end
  end
end

function loadConfig()
  --Configuration
  local name="pc_reg.config"
  local rewrite = false
  if not fs.exists(name) then
    rewrite = true
    config = defConfig
    detectValues(config)
  else
    local h = fs.open(name, "r")
    config = textutils.unserialize(h.readAll())
    h.close()
    -- initialize config with all missing values
    for k, v in ipairs(defConfig) do
      if not config[k] then
        config[k] = v
        rewrite = true;
      end
    end
  end

  if rewrite then
    local h = fs.open(name, "w")
    h.write(textutils.serialize(config))
    h.close()
  end
  return config
end

function printStatus(wnd, config, status)
  wnd.setBackgroundColor(colors.black)
  while true do
    wnd.clear()
    wnd.setCursorPos(1,1)
    wnd.write(string.format("Pressure : %d / %d",status.pressure, config.maxPressure))
    wnd.setCursorPos(1,2)
    wnd.setTextColor(status.running and colors.green or colors.red)
    wnd.write(string.format("Active   : %s", tostring(status.running)))
    local schedId = os.startTimer(1)
    repeat
     local event, timerId = os.pullEvent("timer")
    until timerId == schedId
  end
end

local config = loadConfig()
local status = {}
local x, y = term.getSize()
local header = window.create(term.current(), 1, 1, x, 4)
header.clear()
header.setBackgroundColor(colors.lightGray)
header.setCursorPos(1,1)
header.write("PneumaticCraft Generator Regulator")
header.setCursorPos(1,2)
local body = window.create(term.current(), 1, 5, x, 4)
parallel.waitForAll(function () regulatePressure(config, status) end, function () printStatus(body, config, status) end)
