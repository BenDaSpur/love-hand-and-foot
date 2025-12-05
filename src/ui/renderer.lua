-- UI Renderer
-- Handles all visual rendering for the game

UI = UI or {}
UI.Renderer = {}

local theme = nil
local currentTime = 0

function UI.Renderer.init()
    theme = UI.Theme
    theme.init()
end

function UI.Renderer.drawGame(gameState)
    if not theme then
        UI.Renderer.init()
    end

    currentTime = love.timer.getTime()

    -- Draw background
    UI.Renderer.drawBackground()

    if gameState.phase == "setup" then
        UI.Renderer.drawSetupScreen()
    elseif gameState.phase == "playing" then
        UI.Renderer.drawPlayingScreen(gameState)
    elseif gameState.phase == "roundEnd" then
        UI.Renderer.drawRoundEndScreen(gameState)
    elseif gameState.phase == "gameEnd" then
        UI.Renderer.drawGameEndScreen(gameState)
    end

    -- Always draw action log
    UI.Renderer.drawActionLog(gameState)
end

function UI.Renderer.drawBackground()
    -- Draw clean dark gradient background
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", 0, 0, Config.windowWidth, Config.windowHeight)

    -- Subtle horizon gradient (much softer)
    for i = 0, 80 do
        local y = Config.windowHeight * 0.5 + i
        local alpha = (80 - i) / 80 * 0.15
        love.graphics.setColor(theme.colors.horizonGlow[1], theme.colors.horizonGlow[2],
                              theme.colors.horizonGlow[3], alpha)
        love.graphics.line(0, y, Config.windowWidth, y)
    end

    -- Minimal perspective grid (very subtle)
    love.graphics.setColor(theme.colors.gridColor)
    love.graphics.setLineWidth(1)

    local gridSpacing = 50
    local horizonY = Config.windowHeight * 0.5
    local vanishingX = Config.windowWidth / 2

    -- Horizontal lines (fewer, more subtle)
    for i = 0, 5 do
        local y = horizonY + (Config.windowHeight - horizonY) * (i / 5)
        love.graphics.line(0, y, Config.windowWidth, y)
    end

    -- Vertical perspective lines (fewer lines)
    for i = -4, 4 do
        local x = vanishingX + i * gridSpacing
        love.graphics.line(x, horizonY, vanishingX + i * gridSpacing * 3.5, Config.windowHeight)
    end

    love.graphics.setLineWidth(1)

    -- Very subtle scanline effect
    love.graphics.setColor(0, 0, 0, 0.05)
    for y = 0, Config.windowHeight, 6 do
        love.graphics.line(0, y, Config.windowWidth, y)
    end

    -- Refined minimal border (single line, subtle)
    love.graphics.setColor(theme.colors.neonCyan[1], theme.colors.neonCyan[2],
                          theme.colors.neonCyan[3], 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 4, 4, Config.windowWidth - 8, Config.windowHeight - 8)
    love.graphics.setLineWidth(1)
end

function UI.Renderer.drawSetupScreen()
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.setFont(theme.fonts.title)
    love.graphics.printf("Hand & Foot", 0, Config.windowHeight / 2 - 50, Config.windowWidth, "center")

    love.graphics.setFont(theme.fonts.medium)
    love.graphics.printf("Loading...", 0, Config.windowHeight / 2 + 20, Config.windowWidth, "center")
end

function UI.Renderer.drawPlayingScreen(gameState)
    local w, h = Config.windowWidth, Config.windowHeight

    -- Draw opponents area (top)
    UI.Renderer.drawOpponents(gameState, 20, 20, w - 40, 140)

    -- Draw center area (deck, discard, info)
    UI.Renderer.drawCenterArea(gameState, 20, 180, w - 40, 180)

    -- Find the human player (always show their hand/melds at bottom)
    local humanPlayer = nil
    for _, player in ipairs(gameState.players) do
        if player.type == "human" then
            humanPlayer = player
            break
        end
    end

    -- Draw human player melds (always show at bottom)
    if humanPlayer then
        UI.Renderer.drawPlayerMelds(humanPlayer, 20, 380, w - 40, 120)
    end

    -- Draw human player hand (always show at bottom, with keyboard highlight)
    if humanPlayer then
        UI.Renderer.drawPlayerHand(humanPlayer, 20, 520, w - 40, 160, gameState.highlightedCardIndex)
    end

    -- Draw controls help for human player (only show during their turn)
    local currentPlayer = gameState:getCurrentPlayer()
    if currentPlayer.type == "human" then
        love.graphics.setFont(theme.fonts.tiny)
        love.graphics.setColor(theme.colors.textSecondary)

        local helpText = ""
        if gameState.turnPhase == "draw" then
            helpText = "[D/SPACE] Draw from deck  |  [U] Unlock discard pile"
        elseif gameState.turnPhase == "meld" then
            helpText = "[LEFT/RIGHT] Navigate  |  [SPACE] Select cards  |  [M] Create meld  |  [A] Add to meld  |  [C] Clear  |  [D] Skip to discard"
        elseif gameState.turnPhase == "discard" then
            helpText = "[LEFT/RIGHT] Navigate  |  [SPACE] Select card  |  [D] Discard selected"
        end

        love.graphics.print(helpText, 20, h - 40)
    end
end

function UI.Renderer.drawOpponents(gameState, x, y, w, h)
    love.graphics.setColor(theme.colors.backgroundDark)
    theme.drawRoundedRect("fill", x, y, w, h, 10)

    -- Section label
    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.neonYellow)
    love.graphics.print("OPPONENTS", x + 10, y + 5)

    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.setFont(theme.fonts.small)

    local opponentX = x + 20
    local botCount = 0
    for _, p in ipairs(gameState.players) do
        if p.type == "bot" then botCount = botCount + 1 end
    end
    local spacing = (w - 40) / math.max(1, botCount)

    for i, player in ipairs(gameState.players) do
        if player.type == "bot" then
            local isActive = (gameState.players[gameState.currentPlayerIndex] == player)

            -- Highlight active player
            if isActive then
                love.graphics.setColor(theme.colors.neonCyan[1], theme.colors.neonCyan[2],
                                      theme.colors.neonCyan[3], 0.3)
                theme.drawRoundedRect("fill", opponentX - 10, y + 10, 180, h - 20, 8)
            end

            love.graphics.setColor(theme.colors.textPrimary)
            love.graphics.print(player.name, opponentX, y + 20)

            love.graphics.setColor(theme.colors.textSecondary)
            love.graphics.setFont(theme.fonts.tiny)
            love.graphics.print(string.format("Score: %d", player.score), opponentX, y + 40)

            -- Draw hand as card backs
            local cardBackScale = 0.4
            local cardBackWidth = theme.card.width * cardBackScale
            for cardIdx = 1, math.min(5, #player.hand) do
                local cardX = opponentX + (cardIdx - 1) * (cardBackWidth * 0.3)
                UI.Renderer.drawCardBack(cardX, y + 58, cardBackScale)
            end
            if #player.hand > 5 then
                love.graphics.setColor(theme.colors.textSecondary)
                love.graphics.print(string.format("+%d", #player.hand - 5), opponentX + 80, y + 68)
            end

            -- Foot status
            if player.hasPickedUpFoot then
                love.graphics.setColor(theme.colors.textSecondary)
                love.graphics.print("Foot picked up", opponentX, y + 95)
            else
                love.graphics.setColor(theme.colors.textSecondary)
                love.graphics.print(string.format("Foot: %d", #player.foot), opponentX, y + 95)
            end

            -- Show books
            local cleanBooks, dirtyBooks = player:countBooksOfType()
            if cleanBooks > 0 or dirtyBooks > 0 then
                love.graphics.setColor(theme.colors.cleanBook)
                love.graphics.print(string.format("Clean: %d", cleanBooks), opponentX, y + 110)
                love.graphics.setColor(theme.colors.dirtyBook)
                love.graphics.print(string.format("Dirty: %d", dirtyBooks), opponentX + 60, y + 110)
            end

            love.graphics.setFont(theme.fonts.small)
            opponentX = opponentX + spacing
        end
    end
end

function UI.Renderer.drawCenterArea(gameState, x, y, w, h)
    local sectionWidth = w / 3

    -- Section labels
    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.neonCyan)
    love.graphics.printf("DRAW PILE", x, y + 5, sectionWidth, "center")

    love.graphics.setColor(theme.colors.neonOrange)
    love.graphics.printf("DISCARD PILE", x + sectionWidth, y + 5, sectionWidth, "center")

    love.graphics.setColor(theme.colors.neonMagenta)
    love.graphics.printf("GAME INFO", x + sectionWidth * 2, y + 5, sectionWidth, "center")

    -- Deck
    UI.Renderer.drawDeck(gameState.deck, x + 20, y + 35, sectionWidth - 40, h - 55)

    -- Discard pile
    UI.Renderer.drawDiscardPile(gameState.discardPile, gameState.discardPileFrozen,
                                x + sectionWidth + 20, y + 35, sectionWidth - 40, h - 55)

    -- Game info
    UI.Renderer.drawGameInfo(gameState, x + sectionWidth * 2 + 20, y + 35, sectionWidth - 40, h - 55)
end

function UI.Renderer.drawCardBack(x, y, scale)
    scale = scale or 1.0
    local w = theme.card.width * scale
    local h = theme.card.height * scale
    local cornerRadius = theme.card.cornerRadius * scale

    -- Draw card back (clean dark surface)
    love.graphics.setColor(theme.colors.backgroundDark)
    theme.drawRoundedRect("fill", x, y, w, h, cornerRadius)

    -- Subtle geometric pattern on card back
    love.graphics.setColor(theme.colors.neonPurple[1], theme.colors.neonPurple[2],
                          theme.colors.neonPurple[3], 0.15)

    -- Diamond pattern in center
    local centerX = x + w / 2
    local centerY = y + h / 2
    local diamondSize = 25 * scale

    love.graphics.line(centerX, centerY - diamondSize, centerX + diamondSize, centerY)
    love.graphics.line(centerX + diamondSize, centerY, centerX, centerY + diamondSize)
    love.graphics.line(centerX, centerY + diamondSize, centerX - diamondSize, centerY)
    love.graphics.line(centerX - diamondSize, centerY, centerX, centerY - diamondSize)

    -- Refined border
    love.graphics.setColor(theme.colors.neonPurple)
    love.graphics.setLineWidth(2 * scale)
    theme.drawRoundedRect("line", x, y, w, h, cornerRadius)
    love.graphics.setLineWidth(1)
end

function UI.Renderer.drawDeck(deck, x, y, w, h)
    -- Draw neon glow around deck
    theme.drawGlow(x, y, theme.card.width, theme.card.height, theme.colors.neonPurple, 0.4)

    -- Draw card back
    UI.Renderer.drawCardBack(x, y, 1.0)

    -- Deck count with glow
    love.graphics.setColor(theme.colors.neonCyan)
    love.graphics.setFont(theme.fonts.small)
    love.graphics.print(string.format("%d cards", deck:size()), x, y + theme.card.height + 10)
end

function UI.Renderer.drawDiscardPile(discardPile, frozen, x, y, w, h)
    if #discardPile == 0 then
        -- Empty discard pile
        love.graphics.setColor(theme.colors.backgroundDark[1], theme.colors.backgroundDark[2],
                              theme.colors.backgroundDark[3], 0.5)
        theme.drawRoundedRect("line", x, y, theme.card.width, theme.card.height, theme.card.cornerRadius)

        love.graphics.setColor(theme.colors.textSecondary)
        love.graphics.setFont(theme.fonts.tiny)
        love.graphics.printf("Empty", x, y + theme.card.height / 2 - 6, theme.card.width, "center")
    else
        -- Draw top card
        local topCard = discardPile[#discardPile]
        UI.Renderer.drawCard(topCard, x, y, false, false)

        -- Frozen indicator
        if frozen then
            love.graphics.setColor(theme.colors.frozen[1], theme.colors.frozen[2],
                                  theme.colors.frozen[3], 0.4)
            theme.drawRoundedRect("fill", x, y, theme.card.width, theme.card.height, theme.card.cornerRadius)

            love.graphics.setColor(theme.colors.frozen)
            love.graphics.setFont(theme.fonts.tiny)
            love.graphics.printf("FROZEN", x, y + 5, theme.card.width, "center")
        end

        -- Pile count
        love.graphics.setColor(theme.colors.textPrimary)
        love.graphics.setFont(theme.fonts.small)
        love.graphics.print(string.format("%d cards", #discardPile), x, y + theme.card.height + 10)
    end
end

function UI.Renderer.drawGameInfo(gameState, x, y, w, h)
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.setFont(theme.fonts.medium)
    love.graphics.print(string.format("Round %d", gameState.round), x, y)

    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.textSecondary)
    love.graphics.print(string.format("Play-down: %d pts", gameState:getPlayDownRequirement()), x, y + 30)

    local currentPlayer = gameState:getCurrentPlayer()
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.print(string.format("Current: %s", currentPlayer.name), x, y + 55)

    -- Turn phase indicator
    local phaseColor = theme.colors.neonCyan
    if gameState.turnPhase == "meld" then
        phaseColor = theme.colors.neonGreen
    elseif gameState.turnPhase == "discard" then
        phaseColor = theme.colors.neonOrange
    end

    love.graphics.setColor(phaseColor)
    love.graphics.print(string.format("Phase: %s", gameState.turnPhase:upper()), x, y + 80)

    -- Player score
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.print(string.format("Score: %d", currentPlayer.score), x, y + 105)

    -- Game seed (for replaying)
    love.graphics.setColor(theme.colors.textSecondary)
    love.graphics.setFont(theme.fonts.tiny)
    love.graphics.print(string.format("Seed: %d", gameState.seed), x, y + 130)
end

function UI.Renderer.drawPlayerMelds(player, x, y, w, h)
    -- Section label
    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.neonGreen)
    love.graphics.print("YOUR MELDS", x, y - 20)

    if #player.melds == 0 then
        love.graphics.setColor(theme.colors.textSecondary)
        love.graphics.setFont(theme.fonts.tiny)
        love.graphics.print("(Create melds by selecting 3+ matching cards and pressing M)", x + 10, y + 10)
        return
    end

    local meldX = x + 10
    for _, meld in ipairs(player.melds) do
        -- Draw meld label
        local labelColor = theme.colors.textPrimary
        if meld:isCleanBook() then
            labelColor = theme.colors.cleanBook
        elseif meld:isDirtyBook() then
            labelColor = theme.colors.dirtyBook
        end

        love.graphics.setColor(labelColor)
        love.graphics.setFont(theme.fonts.tiny)
        love.graphics.print(meld:getDisplayName(), meldX, y + 5)

        -- Draw cards in meld
        local cardY = y + 25
        for i, card in ipairs(meld.cards) do
            local cardX = meldX + (i - 1) * (theme.card.width * 0.3)
            UI.Renderer.drawCard(card, cardX, cardY, false, false, 0.6)
        end

        meldX = meldX + math.max(200, #meld.cards * (theme.card.width * 0.3) + 50)
    end
end

function UI.Renderer.drawPlayerHand(player, x, y, w, h, highlightedIndex)
    if #player.hand == 0 then
        love.graphics.setColor(theme.colors.textSecondary)
        love.graphics.setFont(theme.fonts.small)
        love.graphics.print("Hand empty", x + 10, y + 10)
        return
    end

    -- Calculate card spacing
    local totalCardWidth = #player.hand * theme.card.width
    local spacing = theme.card.spacing
    if totalCardWidth + (#player.hand - 1) * spacing > w then
        spacing = (w - totalCardWidth) / (#player.hand - 1)
        spacing = math.max(5, spacing)
    end

    -- Draw hand label
    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.neonCyan)
    love.graphics.print(string.format("YOUR HAND (%d cards)", #player.hand), x, y - 20)

    -- Draw cards
    local cardX = x + 10
    for i, card in ipairs(player.hand) do
        local offsetY = card.selected and theme.card.selectedOffset or 0
        local isHighlighted = (highlightedIndex == i) or card.highlighted
        UI.Renderer.drawCard(card, cardX, y + offsetY, card.selected, isHighlighted)
        cardX = cardX + theme.card.width + spacing
    end
end

function UI.Renderer.drawCard(card, x, y, selected, highlighted, scale)
    scale = scale or 1.0

    -- Apply animation properties
    local animScale = (card.animScale or 1.0) * scale
    local animAlpha = card.animAlpha or 1.0
    x = x + (card.animX or 0)
    y = y + (card.animY or 0)

    local w = theme.card.width * animScale
    local h = theme.card.height * animScale
    local cornerRadius = theme.card.cornerRadius * animScale

    -- Determine border color based on suit (wilds use suit color too)
    local borderColor = theme.colors.cardBlack
    if card.suit == "hearts" then
        borderColor = theme.colors.suitHearts
    elseif card.suit == "diamonds" then
        borderColor = theme.colors.suitDiamonds
    elseif card.suit == "clubs" then
        borderColor = theme.colors.suitClubs
    elseif card.suit == "spades" then
        borderColor = theme.colors.suitSpades
    elseif card.rank == "joker" then
        -- Jokers have no suit, use a neutral color
        borderColor = theme.colors.textPrimary
    end

    -- Save graphics state and apply alpha for animations
    love.graphics.push()
    love.graphics.setColor(1, 1, 1, animAlpha)

    -- Draw neon glow effect
    if selected and highlighted then
        -- Both selected AND highlighted - show both glows
        theme.drawGlow(x, y, w, h, theme.colors.selected, theme.getGlowIntensity(currentTime) * animAlpha)
        theme.drawGlow(x, y, w, h, theme.colors.highlighted, 1.2 * animAlpha)
    elseif selected then
        -- Just selected
        theme.drawGlow(x, y, w, h, theme.colors.selected, theme.getGlowIntensity(currentTime) * animAlpha)
    elseif highlighted then
        -- Just highlighted (arrow key navigation)
        theme.drawGlow(x, y, w, h, theme.colors.highlighted, 1.2 * animAlpha)
    else
        -- Subtle ambient glow on all cards
        theme.drawGlow(x, y, w, h, borderColor, 0.15 * animAlpha)
    end

    -- Draw card background (clean dark surface)
    love.graphics.setColor(theme.colors.cardBackground[1], theme.colors.cardBackground[2],
                          theme.colors.cardBackground[3], animAlpha)
    theme.drawRoundedRect("fill", x, y, w, h, cornerRadius)

    -- Draw refined border
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], animAlpha)
    love.graphics.setLineWidth(theme.card.borderWidth)
    theme.drawRoundedRect("line", x, y, w, h, cornerRadius)
    love.graphics.setLineWidth(1)

    -- Draw rank and suit
    love.graphics.setFont(theme.fonts.medium)
    local rankStr = Card.RANK_DISPLAY[card.rank] or card.rank

    if card.rank == "joker" then
        -- Joker - clean minimal design with just centered star/asterisk symbol
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], animAlpha)

        -- Draw simple "J" in top-left corner
        love.graphics.setFont(theme.fonts.large)
        love.graphics.print("J", x + 12, y + 10)

        -- Draw simple "J" in bottom-right corner
        love.graphics.push()
        love.graphics.translate(x + w - 12, y + h - 10)
        love.graphics.rotate(math.pi)
        love.graphics.print("J", 0, 0)
        love.graphics.pop()

        -- Draw clean centered asterisk symbol
        love.graphics.setFont(theme.fonts.title)
        love.graphics.printf("*", x + 5, y + h/2 - 20, w - 10, "center")
    else
        -- Regular cards (including 2s which have suits)
        -- Draw rank in corners with extra spacing to avoid border overlap
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], animAlpha)
        love.graphics.setFont(theme.fonts.large)
        love.graphics.print(rankStr, x + 12, y + 10)

        -- Bottom-right rank (with extra padding to avoid border overlap)
        love.graphics.push()
        love.graphics.translate(x + w - 12, y + h - 10)
        love.graphics.rotate(math.pi)
        love.graphics.print(rankStr, 0, 0)
        love.graphics.pop()

        -- Draw suit icon (center only, smaller size)
        if card.suit and theme.suitIcons and theme.suitIcons[card.suit] then
            local icon = theme.suitIcons[card.suit]

            -- Center suit icon (smaller, cleaner)
            local centerIconSize = 35 * animScale
            local centerSx = centerIconSize / icon:getWidth()
            local centerSy = centerIconSize / icon:getHeight()

            -- Main center icon (no glow for cleaner look)
            love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], animAlpha)
            love.graphics.draw(icon, x + w/2 - centerIconSize/2, y + h/2 - centerIconSize/2, 0, centerSx, centerSy)
        end
    end

    -- Restore graphics state
    love.graphics.pop()
end

function UI.Renderer.drawActionLog(gameState)
    local w = theme.layout.logWidth
    local collapsed = gameState.actionLogCollapsed
    local h = collapsed and 40 or theme.layout.logHeight
    local x = Config.windowWidth - w - 20
    local y = Config.windowHeight - h - 20

    -- Background
    love.graphics.setColor(theme.colors.backgroundDark[1], theme.colors.backgroundDark[2],
                          theme.colors.backgroundDark[3], 0.9)
    theme.drawRoundedRect("fill", x, y, w, h, 8)

    -- Border
    love.graphics.setColor(theme.colors.neonCyan)
    theme.drawRoundedRect("line", x, y, w, h, 8)

    -- Title bar (clickable)
    love.graphics.setColor(theme.colors.backgroundLight[1], theme.colors.backgroundLight[2],
                          theme.colors.backgroundLight[3], 0.5)
    theme.drawRoundedRect("fill", x, y, w, 30, 8)

    -- Title text
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.setFont(theme.fonts.small)
    love.graphics.print("Action Log", x + 10, y + 10)

    -- Collapse/expand indicator
    love.graphics.setColor(theme.colors.neonCyan)
    local arrow = collapsed and "+" or "-"
    love.graphics.print(arrow, x + w - 25, y + 10)

    -- Hover hint
    love.graphics.setFont(theme.fonts.tiny)
    love.graphics.setColor(theme.colors.textSecondary[1], theme.colors.textSecondary[2],
                          theme.colors.textSecondary[3], 0.6)
    love.graphics.print("(click to toggle)", x + 90, y + 12)

    -- Only draw log entries if not collapsed
    if not collapsed then
        love.graphics.setFont(theme.fonts.tiny)
        love.graphics.setColor(theme.colors.textSecondary)

        local logY = y + 40
        local lineHeight = 15
        local startIndex = math.max(1, #gameState.actionLog - 10)

        for i = startIndex, #gameState.actionLog do
            local entry = gameState.actionLog[i]
            love.graphics.printf(entry.message, x + 10, logY, w - 20, "left")
            logY = logY + lineHeight
        end
    end
end

function UI.Renderer.drawRoundEndScreen(gameState)
    UI.Renderer.drawPlayingScreen(gameState)

    -- Draw overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, Config.windowWidth, Config.windowHeight)

    -- Draw round end panel
    local w = 500
    local h = 400
    local x = (Config.windowWidth - w) / 2
    local y = (Config.windowHeight - h) / 2

    love.graphics.setColor(theme.colors.backgroundLight)
    theme.drawRoundedRect("fill", x, y, w, h, 10)

    love.graphics.setColor(theme.colors.neonCyan)
    theme.drawRoundedRect("line", x, y, w, h, 10)

    -- Title
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.setFont(theme.fonts.title)
    love.graphics.printf(string.format("Round %d Complete!", gameState.round), x, y + 20, w, "center")

    -- Scores
    love.graphics.setFont(theme.fonts.medium)
    local scoreY = y + 80
    for i, player in ipairs(gameState.players) do
        local lastRound = player.roundScores[#player.roundScores]
        if lastRound then
            love.graphics.setColor(theme.colors.textPrimary)
            love.graphics.print(player.name, x + 50, scoreY)
            love.graphics.printf(string.format("%+d", lastRound.score), x + 200, scoreY, 100, "right")
            love.graphics.printf(string.format("%d", player.score), x + 350, scoreY, 100, "right")
            scoreY = scoreY + 35
        end
    end

    -- Continue button
    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.textSecondary)
    love.graphics.printf("Press SPACE to continue", x, y + h - 50, w, "center")
end

function UI.Renderer.drawGameEndScreen(gameState)
    love.graphics.setColor(theme.colors.textPrimary)
    love.graphics.setFont(theme.fonts.title)
    love.graphics.printf("Game Over!", 0, Config.windowHeight / 2 - 100, Config.windowWidth, "center")

    if gameState.winner then
        love.graphics.setFont(theme.fonts.large)
        love.graphics.printf(string.format("%s wins with %d points!",
            gameState.winner.name, gameState.winner.score),
            0, Config.windowHeight / 2 - 20, Config.windowWidth, "center")
    end
end

return UI.Renderer
