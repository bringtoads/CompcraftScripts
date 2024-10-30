-- t3
local function getTurtleName()
    -- Make sure to use HTTP if you can't use HTTPS
    -- local response, err = http.get("https://turtleserver-production.up.railway.app/api/Turtle/GetTurtleName")
    -- local response, err = http.get("https://localhost:7221/api/Turtle/GetTurtleName")
    local response, err = http.get("http://localhost:5041/api/Turtle/GetTurtleName")
    if not response then
        print("Error connecting to the server: " .. err)
        return
    end

    -- Read the response
    local data = response.readAll()
    response.close()
    print(data)
    -- Deserialize the JSON response (assuming the server returns JSON)
    -- local turtleData = textutils.unserializeJSON(data)

    if data then
        print(data)
        -- Set the turtle label with the received name
        os.setComputerLabel(data)
        print("Turtle name set to: " .. data)
    else
        print("Failed to retrieve turtle name")
    end
end

-- Call the function to get the turtle name
getTurtleName()

