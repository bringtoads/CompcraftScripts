-- Chess Client
-- Save as 'chess_client'
local pieces = {
    ["K"] = {
        symbol = "♔",
        color = "white"
    },
    ["Q"] = {
        symbol = "♕",
        color = "white"
    },
    ["R"] = {
        symbol = "♖",
        color = "white"
    },
    ["B"] = {
        symbol = "♗",
        color = "white"
    },
    ["N"] = {
        symbol = "♘",
        color = "white"
    },
    ["P"] = {
        symbol = "♙",
        color = "white"
    },
    ["k"] = {
        symbol = "♚",
        color = "black"
    },
    ["q"] = {
        symbol = "♛",
        color = "black"
    },
    ["r"] = {
        symbol = "♜",
        color = "black"
    },
    ["b"] = {
        symbol = "♝",
        color = "black"
    },
    ["n"] = {
        symbol = "♞",
        color = "black"
    },
    ["p"] = {
        symbol = "♟",
        color = "black"
    }
}

local board = {}
local selectedPiece = nil
local myColor = nil
local currentPlayer = "white"

-- Convert screen coordinates to board coordinates
local function screenToBoard(screenX, screenY)
    local boardX = math.floor((screenX - 1) / 3) + 1
    local boardY = screenY
    if boardX >= 1 and boardX <= 8 and boardY >= 1 and boardY <= 8 then
        return boardX, boardY
    end
    return nil
end

-- Draw the board
local function drawBoard()
    term.clear()

    -- Draw column labels
    term.setCursorPos(2, 0)
    term.write(" a  b  c  d  e  f  g  h")

    for y = 1, 8 do
        -- Draw row labels
        term.setCursorPos(0, y)
        term.write(tostring(9 - y))

        for x = 1, 8 do
            local piece = board[y][x]
            term.setCursorPos((x - 1) * 3 + 2, y)

            -- Set colors for square
            if (x + y) % 2 == 0 then
                term.setBackgroundColor(colors.black)
            else
                term.setBackgroundColor(colors.gray)
            end

            -- Highlight selected piece
            if selectedPiece and selectedPiece.x == x and selectedPiece.y == y then
                term.setBackgroundColor(colors.yellow)
            end

            -- Draw piece
            if piece == "." then
                term.write(" . ")
            else
                if pieces[piece].color == "white" then
                    term.setTextColor(colors.white)
                else
                    term.setTextColor(colors.lightGray)
                end
                term.write(" " .. pieces[piece].symbol .. " ")
            end
        end
    end

    -- Reset colors
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)

    -- Draw status
    term.setCursorPos(1, 10)
    term.write(currentPlayer .. "'s turn")
    term.setCursorPos(1, 11)
    term.write("You are " .. myColor)
end

-- Connect to server
local function connectToServer()
    rednet.open("back") -- Or whichever side your modem is on

    print("Looking for chess server...")
    local server = rednet.lookup("chess", "chess_server")
    if not server then
        error("No chess server found")
    end

    rednet.send(server, {
        type = "join"
    }, "chess")
    local senderId, message = rednet.receive("chess")

    if message.type == "joined" then
        myColor = message.color
        print("Connected as " .. myColor)
        return server
    else
        error("Failed to join game")
    end
end

-- Main client loop
local function runClient()
    local server = connectToServer()

    parallel.waitForAll( -- Input handling
    function()
        while true do
            local event, button, x, y = os.pullEvent("mouse_click")
            if currentPlayer == myColor then
                local boardX, boardY = screenToBoard(x, y)
                if boardX then
                    if selectedPiece then
                        -- Send move to server
                        rednet.send(server, {
                            type = "move",
                            from = selectedPiece,
                            to = {
                                x = boardX,
                                y = boardY
                            }
                        }, "chess")
                        selectedPiece = nil
                    else
                        local piece = board[boardY][boardX]
                        if piece ~= "." and pieces[piece].color == myColor then
                            selectedPiece = {
                                x = boardX,
                                y = boardY
                            }
                        end
                    end
                    drawBoard()
                end
            end
        end
    end, -- Server message handling
    function()
        while true do
            local senderId, message = rednet.receive("chess")
            if message.type == "gameState" then
                board = message.state.board
                currentPlayer = message.state.currentPlayer
                drawBoard()
            elseif message.type == "playerLeft" then
                term.clear()
                term.setCursorPos(1, 1)
                print("Other player left the game")
                print("Press any key to exit")
                os.pullEvent("key")
                return
            end
        end
    end)
end

-- Start client
term.clear()
term.setCursorPos(1, 1)
print("Chess Client")
print("Press any key to connect")
os.pullEvent("key")
runClient()
