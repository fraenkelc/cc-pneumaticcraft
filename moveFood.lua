--[[ Moves items to another inventory once that one is empty.

keeps picking different slots from the internal inventory.

--]]


local config =  {
  -- side the chest is at (left, right, front, back, top, bottom)
  sideChest = "front",
}

function feedLoop(config)
  while true do
    local chest = peripheral.wrap(config.sideChest)
    if table.maxn(chest.getAllStacks()) == 0 then
      print (os.day(), " " ,textutils.formatTime(os.time(), true), "   Supplying item.")
      turtle.drop(1)
      turtle.select((turtle.getSelectedSlot() % 16) + 1)    
    end

    local schedId = os.startTimer(1)
    repeat
      local event, timerId = os.pullEvent("timer")
    until timerId == schedId
  end
end

parallel.waitForAny(function() feedLoop(config) end)
