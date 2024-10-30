-- Function to check and refuel if needed
local function checkFuel(blocksNeeded)
  local currentFuel = turtle.getFuelLevel()
  if currentFuel == "unlimited" then return true end

  -- Calculate fuel needed (blocks to mine + return journey)
  local fuelNeeded = blocksNeeded + 100  -- Adding buffer for return journey

  if currentFuel < fuelNeeded then
      for i = 1, 16 do
          turtle.select(i)
          if turtle.refuel(0) then
              turtle.refuel(64)
              if turtle.getFuelLevel() >= fuelNeeded then
                  return true
              end
          end
      end
      return false
  end
  return true
end

-- Function to return to starting position
local function returnToStart(length, width, height)
  -- Turn around
  turtle.turnRight()
  turtle.turnRight()

  -- Return to ground level
  for i = 1, height - 1 do
      turtle.down()
  end

  -- Return to start position
  for i = 1, length - 1 do
      turtle.forward()
  end

  -- Return to first row
  turtle.turnRight()
  for i = 1, width - 1 do
      turtle.forward()
  end

  -- Face original direction
  turtle.turnLeft()
end

-- Main mining function
function mineVolume(length, width, height)
  -- Calculate total blocks for fuel check
  local totalBlocks = length * width * height

  -- Check if we have enough fuel
  if not checkFuel(totalBlocks * 2) then  -- *2 for safety margin
      print("Not enough fuel! Need at least " .. totalBlocks * 2 .. " fuel.")
      return false
  end

  print("Starting mining operation: " .. length .. "x" .. width .. "x" .. height)

  -- For each level
  for h = 1, height do
      -- For each width row
      for w = 1, width do
          -- Mine forward for length
          for l = 1, length do
              turtle.dig()
              if l < length then
                  turtle.forward()
              end
          end

          -- If not at last width, prepare for next row
          if w < width then
              if w % 2 == 1 then
                  turtle.turnRight()
                  turtle.dig()
                  turtle.forward()
                  turtle.turnRight()
              else
                  turtle.turnLeft()
                  turtle.dig()
                  turtle.forward()
                  turtle.turnLeft()
              end
          end
      end

      -- If not at top level, move up and reset position
      if h < height then
          -- Return to start of level if at even width
          if width % 2 == 0 then
              returnToStart(length, width, 1)
          end

          -- Move up
          turtle.digUp()
          turtle.up()

          -- If at even width, need to turn around
          if width % 2 == 0 then
              turtle.turnRight()
              turtle.turnRight()
          end
      end
  end

  -- Return to starting position
  if width % 2 == 0 and height % 2 == 1 then
      -- If both width is even and height is odd, we're facing wrong way
      returnToStart(length, width, height)
  elseif width % 2 == 1 and height % 2 == 0 then
      -- If width is odd and height is even, we're facing wrong way
      returnToStart(length, width, height)
  end

  print("Mining operation completed!")
  return true
end

-- Usage examples:
-- mineVolume(3, 3, 3)   -- Creates a 3x3x3 cube
-- mineVolume(100, 2, 10) -- Creates a 100x2x10 tunnel
