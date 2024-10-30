-- Function to mine a specified 3D area
function mineDimension(x, y, z)
    for level = 1, z do -- Loop through the depth (z-axis)
        for row = 1, y do -- Loop through the height (y-axis)
            for col = 1, x do -- Loop through the width (x-axis)
                if turtle.detect() then
                    turtle.dig() -- Mine the block in front of the turtle
                end

                if col < x then -- Move forward unless it's the last column
                    turtle.forward()
                end
            end

            -- Move to the next row
            if row < y then
                if level % 2 == 1 then -- If we're on an odd level
                    turtle.turnRight() -- Turn right to move to the next row
                else
                    turtle.turnLeft() -- Turn left if on an even level
                end

                turtle.forward() -- Move to the next row
                if level % 2 == 1 then
                    turtle.turnRight() -- Reorient for the next row
                else
                    turtle.turnLeft() -- Reorient for the next row
                end
            end
        end

        -- Move up to the next layer
        if level < z then
            turtle.up() -- Move up to the next layer
            -- Move back to the start position for the new layer
            if level % 2 == 0 then
                turtle.turnLeft() -- Adjust direction to go back to the start
                for i = 1, y - 1 do
                    turtle.forward()
                end
                turtle.turnLeft() -- Face the original direction
            else
                turtle.turnRight() -- Adjust direction to go back to the start
                for i = 1, y - 1 do
                    turtle.forward()
                end
                turtle.turnRight() -- Face the original direction
            end

            -- Move back to the start of the new layer
            for i = 1, x - 1 do
                turtle.forward()
            end
        end
    end
end

-- Example usage
-- Capture command-line arguments for dimensions
local args = {...}
local x = tonumber(args[1]) or 5 -- Default to 5 if not provided
local y = tonumber(args[2]) or 5 -- Default to 5 if not provided
local z = tonumber(args[3]) or 3 -- Default to 3 if not provided

-- Call the function with provided dimensions
mineDimension(x, y, z)
