-- Hand & Foot Card Game
-- Built with LÖVE2D in Balatro style
-- Version 1.0

-- Global configuration
Config = {
    windowWidth = 1280,
    windowHeight = 720,
    title = "Hand & Foot",
    version = "1.0.0",
    -- Optional: Set a specific seed to replay a game, or nil for random
    -- Example: seed = 1234567890
    seed = nil
}

-- Global game state
Game = nil

-- Libraries
flux = require("lib/flux")
lume = require("lib/lume")

-- Hot reload support
local hotswap = require("hotswap")

function love.load()
    -- Set window configuration
    love.window.setTitle(Config.title .. " v" .. Config.version)
    love.window.setMode(Config.windowWidth, Config.windowHeight, {
        resizable = true,
        minwidth = 800,
        minheight = 600
    })

    -- Load required modules
    require("src/card")
    require("src/deck")
    require("src/meld")
    require("src/player")
    require("src/gamestate")
    require("src/ui/theme")
    require("src/ui/renderer")
    require("src/ai/bot")

    -- Watch files for hot reload
    hotswap.watch("src/ui/theme.lua")
    hotswap.watch("src/ui/renderer.lua")
    hotswap.watch("src/gamestate.lua")
    hotswap.watch("src/ai/bot.lua")

    -- Initialize game with optional seed
    Game = GameState.new(4, Config.seed) -- 1 human + 3 AI bots
    Game:startRound()

    print("Hand & Foot game loaded successfully!")
    print("Hot reload enabled - edit and save files to see changes!")
    print("To replay this game, set Config.seed = " .. Game.seed .. " in main.lua")
end

function love.update(dt)
    hotswap.update() -- Check for file changes
    flux.update(dt) -- Update tweens and timers

    if Game then
        Game:update()
    end
end

function love.draw()
    if Game then
        UI.Renderer.drawGame(Game)
    end
end

function love.mousepressed(x, y, button)
    if Game then
        Game:handleMousePressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if Game then
        Game:handleMouseReleased(x, y, button)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if Game then
        Game:handleKeyPressed(key)
    end
end

function love.resize(w, h)
    Config.windowWidth = w
    Config.windowHeight = h
end
