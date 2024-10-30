-- Tetris for ComputerCraft Pocket Computer
-- Screen size: 26x20 characters
-- Piece definitions
local pieces = { -- I piece
{
    {{0, 0, 0, 0}, {1, 1, 1, 1}, {0, 0, 0, 0}, {0, 0, 0, 0}},
    color = colors.cyan
}, -- O piece
{
    {{1, 1}, {1, 1}},
    color = colors.yellow
}, -- T piece
{
    {{0, 1, 0}, {1, 1, 1}, {0, 0, 0}},
    color = colors.magenta
}, -- S piece
{
    {{0, 1, 1}, {1, 1, 0}, {0, 0, 0}},
    color = colors.lime
}, -- Z piece
{
    {{1, 1, 0}, {0, 1, 1}, {0, 0, 0}},
    color = colors.red
}, -- J piece
{
    {{1, 0, 0}, {1, 1, 1}, {0, 0, 0}},
    color = colors.blue
}, -- L piece
{
    {{0, 0, 1}, {1, 1, 1}, {0, 0, 0}},
    color = colors.orange
}}

-- Game state
local board = {}
local boardWidth = 10
local boardHeight = 18
local score = 0
local currentPiece = nil
local pieceX = 0
local pieceY = 0
local gameOver = false
local dropInterval = 0.5 -- seconds

-- Initialize board
local function initBoard()
    for y = 1, boardHeight do
        board[y] = {}
        for x = 1, boardWidth do
            board[y][x] = 0
        end
    end
end

-- Rotate piece clockwise
local function rotatePiece(piece)
    local size = #piece
    local rotated = {}
    for y = 1, size do
        rotated[y] = {}
        for x = 1, size do
            rotated[y][x] = piece[size - x + 1][y]
        end
    end
    return rotated
end

-- Check if piece can be placed at given position
local function canPlace(piece, px, py)
    for y = 1, #piece do
        for x = 1, #piece[y] do
            if piece[y][x] == 1 then
                local boardX, boardY = px + x - 1, py + y - 1
                if boardX < 1 or boardX > boardWidth or boardY < 1 or boardY > boardHeight or board[boardY][boardX] ~= 0 then
                    return false
                end
            end
        end
    end
    return true
end

-- Place piece on board
local function placePiece()
    for y = 1, #currentPiece[1] do
        for x = 1, #currentPiece[1][y] do
            if currentPiece[1][y][x] == 1 then
                board[pieceY + y - 1][pieceX + x - 1] = currentPiece.color
            end
        end
    end
end

-- Clear completed lines
local function clearLines()
    local linesCleared = 0
    local y = boardHeight
    while y > 0 do
        local complete = true
        for x = 1, boardWidth do
            if board[y][x] == 0 then
                complete = false
                break
            end
        end
        if complete then
            linesCleared = linesCleared + 1
            for moveY = y, 2, -1 do
                for x = 1, boardWidth do
                    board[moveY][x] = board[moveY - 1][x]
                end
            end
            for x = 1, boardWidth do
                board[1][x] = 0
            end
        else
            y = y - 1
        end
    end
    return linesCleared
end

-- Spawn new piece
local function spawnPiece()
    currentPiece = pieces[math.random(#pieces)]
    pieceX = math.floor((boardWidth - #currentPiece[1][1]) / 2) + 1
    pieceY = 1
    if not canPlace(currentPiece[1], pieceX, pieceY) then
        gameOver = true
    end
end

-- Draw game state
local function draw()
    term.clear()

    -- Draw board
    for y = 1, boardHeight do
        for x = 1, boardWidth do
            term.setCursorPos(x * 2 - 1, y)
            if board[y][x] ~= 0 then
                term.setBackgroundColor(board[y][x])
                term.write("  ")
                term.setBackgroundColor(colors.black)
            else
                term.write(". ")
            end
        end
    end

    -- Draw current piece
    if currentPiece then
        for y = 1, #currentPiece[1] do
            for x = 1, #currentPiece[1][y] do
                if currentPiece[1][y][x] == 1 then
                    term.setCursorPos((pieceX + x - 1) * 2 - 1, pieceY + y - 1)
                    term.setBackgroundColor(currentPiece.color)
                    term.write("  ")
                    term.setBackgroundColor(colors.black)
                end
            end
        end
    end

    -- Draw score
    term.setCursorPos(1, boardHeight + 1)
    term.setTextColor(colors.white)
    term.write("Score: " .. score)

    if gameOver then
        term.setCursorPos(1, boardHeight + 2)
        term.write("Game Over!")
    end
end

-- Handle piece dropping
local function dropLoop()
    while not gameOver do
        sleep(dropInterval)
        if canPlace(currentPiece[1], pieceX, pieceY + 1) then
            pieceY = pieceY + 1
        else
            placePiece()
            local cleared = clearLines()
            score = score + (cleared * 100)
            spawnPiece()
        end
        draw()
    end
end

-- Handle input
local function inputLoop()
    while not gameOver do
        local event, key = os.pullEvent("key")
        if key == keys.left and canPlace(currentPiece[1], pieceX - 1, pieceY) then
            pieceX = pieceX - 1
        elseif key == keys.right and canPlace(currentPiece[1], pieceX + 1, pieceY) then
            pieceX = pieceX + 1
        elseif key == keys.up then
            local rotated = rotatePiece(currentPiece[1])
            if canPlace(rotated, pieceX, pieceY) then
                currentPiece[1] = rotated
            end
        elseif key == keys.down then
            if canPlace(currentPiece[1], pieceX, pieceY + 1) then
                pieceY = pieceY + 1
            end
        end
        draw()
    end
end

-- Main game loop
local function main()
    initBoard()
    spawnPiece()
    draw()

    parallel.waitForAll(dropLoop, inputLoop)

    -- Game over screen
    term.setCursorPos(1, boardHeight + 3)
    print("Press any key to exit")
    os.pullEvent("key")
end

-- Start game
term.clear()
term.setCursorPos(1, 1)
print("Press any key to start")
os.pullEvent("key")
main()
