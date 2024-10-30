-- Chess Server
-- Save as 'chess_server'
local pieces = {
    ["K"] = {
        symbol = "K",
        color = "white"
    },
    ["Q"] = {
        symbol = "Q",
        color = "white"
    },
    ["R"] = {
        symbol = "R",
        color = "white"
    },
    ["B"] = {
        symbol = "B",
        color = "white"
    },
    ["N"] = {
        symbol = "N",
        color = "white"
    },
    ["P"] = {
        symbol = "P",
        color = "white"
    },
    ["k"] = {
        symbol = "k",
        color = "black"
    },
    ["q"] = {
        symbol = "q",
        color = "black"
    },
    ["r"] = {
        symbol = "r",
        color = "black"
    },
    ["b"] = {
        symbol = "b",
        color = "black"
    },
    ["n"] = {
        symbol = "n",
        color = "black"
    },
    ["p"] = {
        symbol = "p",
        color = "black"
    }
}

local initialBoard = {{"r", "n", "b", "q", "k", "b", "n", "r"}, {"p", "p", "p", "p", "p", "p", "p", "p"},
                      {".", ".", ".", ".", ".", ".", ".", "."}, {".", ".", ".", ".", ".", ".", ".", "."},
                      {".", ".", ".", ".", ".", ".", ".", "."}, {".", ".", ".", ".", ".", ".", ".", "."},
                      {"P", "P", "P", "P", "P", "P", "P", "P"}, {"R", "N", "B", "Q", "K", "B", "N", "R"}}

local board = {}
local currentPlayer = "white"
local players = {
    white = nil,
    black = nil
}

-- Initialize board
local function initBoard()
    for y = 1, 8 do
        board[y] = {}
        for x = 1, 8 do
            board[y][x] = initialBoard[y][x]
        end
    end
end

-- Get valid moves (same as before, copying the getValidMoves function from the previous version)
local function getValidMoves(x, y)
    -- ... (copy the getValidMoves function from the previous version)
end

-- Broadcast game state to both players
local function broadcastGameState()
    local gameState = {
        board = board,
        currentPlayer = currentPlayer
    }

    if players.white then
        rednet.send(players.white, {
            type = "gameState",
            state = gameState,
            yourColor = "white"
        }, "chess")
    end

    if players.black then
        rednet.send(players.black, {
            type = "gameState",
            state = gameState,
            yourColor = "black"
        }, "chess")
    end
end

-- Main server loop
local function runServer()
    rednet.open("back") -- Or whichever side your modem is on
    rednet.host("chess", "chess_server")

    print("Chess server started")
    print("Waiting for players...")

    initBoard()

    -- Wait for players to connect
    while not players.white or not players.black do
        local senderId, message = rednet.receive("chess")
        if message.type == "join" then
            if not players.white then
                players.white = senderId
                rednet.send(senderId, {
                    type = "joined",
                    color = "white"
                }, "chess")
                print("White player joined")
            elseif not players.black then
                players.black = senderId
                rednet.send(senderId, {
                    type = "joined",
                    color = "black"
                }, "chess")
                print("Black player joined")
            end
        end
    end

    print("Game starting!")
    broadcastGameState()

    while true do
        local senderId, message = rednet.receive("chess")

        -- Handle player disconnect
        if message.type == "disconnect" then
            if senderId == players.white then
                players.white = nil
                if players.black then
                    rednet.send(players.black, {
                        type = "playerLeft"
                    }, "chess")
                end
            elseif senderId == players.black then
                players.black = nil
                if players.white then
                    rednet.send(players.white, {
                        type = "playerLeft"
                    }, "chess")
                end
            end
            print("Player disconnected")
            if not players.white and not players.black then
                print("No players left, resetting game")
                initBoard()
                currentPlayer = "white"
            end
        end

        -- Handle moves
        if message.type == "move" then
            local playerColor = senderId == players.white and "white" or "black"
            if playerColor == currentPlayer then
                local from, to = message.from, message.to
                local validMoves = getValidMoves(from.x, from.y)

                -- Check if move is valid
                local validMove = false
                for _, move in ipairs(validMoves) do
                    if move.x == to.x and move.y == to.y then
                        validMove = true
                        break
                    end
                end

                if validMove then
                    -- Make the move
                    board[to.y][to.x] = board[from.y][from.x]
                    board[from.y][from.x] = "."
                    currentPlayer = currentPlayer == "white" and "black" or "white"
                    broadcastGameState()
                end
            end
        end
    end
end

runServer()
