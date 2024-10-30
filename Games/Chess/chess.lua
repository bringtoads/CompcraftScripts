-- Chess for ComputerCraft
-- Uses mouse input for piece selection and movement
-- Piece definitions with Unicode chess symbols
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

-- Initial board setup
local initialBoard = {{"r", "n", "b", "q", "k", "b", "n", "r"}, {"p", "p", "p", "p", "p", "p", "p", "p"},
                      {".", ".", ".", ".", ".", ".", ".", "."}, {".", ".", ".", ".", ".", ".", ".", "."},
                      {".", ".", ".", ".", ".", ".", ".", "."}, {".", ".", ".", ".", ".", ".", ".", "."},
                      {"P", "P", "P", "P", "P", "P", "P", "P"}, {"R", "N", "B", "Q", "K", "B", "N", "R"}}

local board = {}
local selectedPiece = nil
local currentPlayer = "white"
local moveHistory = {}

-- Initialize the board
local function initBoard()
    for y = 1, 8 do
        board[y] = {}
        for x = 1, 8 do
            board[y][x] = initialBoard[y][x]
        end
    end
end

-- Convert screen coordinates to board coordinates
local function screenToBoard(screenX, screenY)
    local boardX = math.floor((screenX - 1) / 3) + 1
    local boardY = screenY
    if boardX >= 1 and boardX <= 8 and boardY >= 1 and boardY <= 8 then
        return boardX, boardY
    end
    return nil
end

-- Check if a piece belongs to the current player
local function isCurrentPlayerPiece(piece)
    if piece == "." then
        return false
    end
    return (pieces[piece].color == currentPlayer)
end

-- Get all valid moves for a piece
local function getValidMoves(x, y)
    local piece = board[y][x]
    local validMoves = {}

    -- Helper function to add move if valid
    local function addMove(newX, newY)
        if newX >= 1 and newX <= 8 and newY >= 1 and newY <= 8 then
            local targetPiece = board[newY][newX]
            if targetPiece == "." or pieces[targetPiece].color ~= currentPlayer then
                table.insert(validMoves, {
                    x = newX,
                    y = newY
                })
            end
        end
    end

    -- Pawn moves
    if piece == "P" then
        -- White pawn
        if y > 1 then
            if board[y - 1][x] == "." then
                addMove(x, y - 1)
                if y == 7 and board[y - 2][x] == "." then
                    addMove(x, y - 2)
                end
            end
            -- Captures
            if x > 1 and board[y - 1][x - 1] ~= "." then
                addMove(x - 1, y - 1)
            end
            if x < 8 and board[y - 1][x + 1] ~= "." then
                addMove(x + 1, y - 1)
            end
        end
    elseif piece == "p" then
        -- Black pawn
        if y < 8 then
            if board[y + 1][x] == "." then
                addMove(x, y + 1)
                if y == 2 and board[y + 2][x] == "." then
                    addMove(x, y + 2)
                end
            end
            -- Captures
            if x > 1 and board[y + 1][x - 1] ~= "." then
                addMove(x - 1, y + 1)
            end
            if x < 8 and board[y + 1][x + 1] ~= "." then
                addMove(x + 1, y + 1)
            end
        end
    end

    -- Rook moves (and part of queen moves)
    local function addRookMoves()
        local directions = {{0, 1}, {0, -1}, {1, 0}, {-1, 0}}
        for _, dir in ipairs(directions) do
            local newX, newY = x + dir[1], y + dir[2]
            while newX >= 1 and newX <= 8 and newY >= 1 and newY <= 8 do
                local targetPiece = board[newY][newX]
                if targetPiece == "." then
                    addMove(newX, newY)
                else
                    if pieces[targetPiece].color ~= currentPlayer then
                        addMove(newX, newY)
                    end
                    break
                end
                newX = newX + dir[1]
                newY = newY + dir[2]
            end
        end
    end

    -- Bishop moves (and part of queen moves)
    local function addBishopMoves()
        local directions = {{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}
        for _, dir in ipairs(directions) do
            local newX, newY = x + dir[1], y + dir[2]
            while newX >= 1 and newX <= 8 and newY >= 1 and newY <= 8 do
                local targetPiece = board[newY][newX]
                if targetPiece == "." then
                    addMove(newX, newY)
                else
                    if pieces[targetPiece].color ~= currentPlayer then
                        addMove(newX, newY)
                    end
                    break
                end
                newX = newX + dir[1]
                newY = newY + dir[2]
            end
        end
    end

    -- Knight moves
    local function addKnightMoves()
        local moves = {{-2, -1}, {-2, 1}, {2, -1}, {2, 1}, {-1, -2}, {-1, 2}, {1, -2}, {1, 2}}
        for _, move in ipairs(moves) do
            addMove(x + move[1], y + move[2])
        end
    end

    -- King moves
    local function addKingMoves()
        for dy = -1, 1 do
            for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    addMove(x + dx, y + dy)
                end
            end
        end
    end

    -- Apply moves based on piece type
    if piece:lower() == "r" then
        addRookMoves()
    elseif piece:lower() == "b" then
        addBishopMoves()
    elseif piece:lower() == "n" then
        addKnightMoves()
    elseif piece:lower() == "q" then
        addRookMoves()
        addBishopMoves()
    elseif piece:lower() == "k" then
        addKingMoves()
    end

    return validMoves
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

            -- Highlight selected piece and valid moves
            if selectedPiece and selectedPiece.x == x and selectedPiece.y == y then
                term.setBackgroundColor(colors.yellow)
            elseif selectedPiece then
                local validMoves = getValidMoves(selectedPiece.x, selectedPiece.y)
                for _, move in ipairs(validMoves) do
                    if move.x == x and move.y == y then
                        term.setBackgroundColor(colors.green)
                    end
                end
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

    -- Draw current player
    term.setCursorPos(1, 10)
    term.write(currentPlayer .. "'s turn")
end

-- Main game loop
local function main()
    initBoard()

    while true do
        drawBoard()

        -- Get mouse input
        local event, button, x, y = os.pullEvent("mouse_click")
        local boardX, boardY = screenToBoard(x, y)

        if boardX then
            if selectedPiece then
                -- Try to move selected piece
                local validMoves = getValidMoves(selectedPiece.x, selectedPiece.y)
                local validMove = false

                for _, move in ipairs(validMoves) do
                    if move.x == boardX and move.y == boardY then
                        -- Make the move
                        board[boardY][boardX] = board[selectedPiece.y][selectedPiece.x]
                        board[selectedPiece.y][selectedPiece.x] = "."

                        -- Switch players
                        currentPlayer = currentPlayer == "white" and "black" or "white"
                        validMove = true
                        break
                    end
                end

                selectedPiece = nil

                -- If move wasn't valid, try selecting new piece
                if not validMove and isCurrentPlayerPiece(board[boardY][boardX]) then
                    selectedPiece = {
                        x = boardX,
                        y = boardY
                    }
                end
            else
                -- Try to select piece
                if isCurrentPlayerPiece(board[boardY][boardX]) then
                    selectedPiece = {
                        x = boardX,
                        y = boardY
                    }
                end
            end
        end
    end
end

-- Start game
term.clear()
term.setCursorPos(1, 1)
print("Chess - Click pieces to move")
print("Press any key to start")
os.pullEvent("key")
main()
