-- GameState class
-- Manages the complete game state, turn flow, and game logic

GameState = {}
GameState.__index = GameState

function GameState.new(numPlayers, seed)
    local self = setmetatable({}, GameState)

    -- Random seed (use provided seed or generate one)
    self.seed = seed or os.time()
    math.randomseed(self.seed)

    -- Log the seed so users can replay
    print(string.format("Game seed: %d (use this to replay the same game)", self.seed))

    -- Game meta
    self.phase = "setup" -- "setup", "playing", "roundEnd", "gameEnd"
    self.round = 1
    self.winner = nil

    -- Turn management
    self.currentPlayerIndex = 1
    self.turnPhase = "draw" -- "draw", "meld", "discard"
    self.hasDrawnThisTurn = false

    -- Card piles
    self.deck = Deck.new(numPlayers)
    self.discardPile = {}
    self.discardPileFrozen = false

    -- Players (1 human + rest AI bots)
    self.players = {}
    self:createPlayers(numPlayers)

    -- Action log
    self.actionLog = {}
    self.maxLogEntries = 20
    self.actionLogCollapsed = false

    -- AI turn timing
    self.aiTurnTimer = 0
    self.aiTurnDelay = 0
    self.pendingAiAction = nil

    -- Win condition
    self.winningScore = 8500

    -- Keyboard navigation
    self.highlightedCardIndex = nil -- Index of card highlighted by arrow keys

    return self
end

function GameState:createPlayers(numPlayers)
    -- Create human player
    table.insert(self.players, Player.new("You", "human", 1))

    -- Create AI bots
    local botNames = {"Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"}
    for i = 2, numPlayers do
        local bot = Player.new(botNames[i - 1] or ("Bot " .. i), "bot", i)
        bot.difficulty = "medium"
        table.insert(self.players, bot)
    end
end

function GameState:getCurrentPlayer()
    return self.players[self.currentPlayerIndex]
end

function GameState:getPlayDownRequirement()
    -- Formula: 60 + ((round - 1) × 30)
    return 60 + ((self.round - 1) * 30)
end

function GameState:logAction(message)
    table.insert(self.actionLog, {
        message = message,
        timestamp = os.time()
    })

    -- Keep only last N entries
    while #self.actionLog > self.maxLogEntries do
        table.remove(self.actionLog, 1)
    end

    print("[Action] " .. message)
end

function GameState:startRound()
    self.phase = "playing"
    self.turnPhase = "draw"
    self.currentPlayerIndex = 1
    self.hasDrawnThisTurn = false
    self.discardPileFrozen = false
    self.discardPile = {}

    -- Reset all players
    for _, player in ipairs(self.players) do
        player:reset()
    end

    -- Rebuild and shuffle deck
    self.deck = Deck.new(#self.players)

    -- Deal cards
    self:dealCards()

    -- Place first card on discard pile
    local firstDiscard = self.deck:drawCard()
    if firstDiscard then
        table.insert(self.discardPile, firstDiscard)
        if firstDiscard.isWild then
            self.discardPileFrozen = true
            self:logAction("Discard pile starts frozen (wild card on top)")
        end
    end

    self:logAction(string.format("Round %d started! Play-down requirement: %d points",
        self.round, self:getPlayDownRequirement()))
end

function GameState:dealCards()
    for _, player in ipairs(self.players) do
        -- Deal 11 cards to hand
        local handCards = self.deck:drawCards(11)
        player:addCardsToHand(handCards)

        -- Deal 11 cards to foot
        player.foot = self.deck:drawCards(11)
    end
end

function GameState:nextTurn()
    -- Move to next player
    self.currentPlayerIndex = self.currentPlayerIndex + 1
    if self.currentPlayerIndex > #self.players then
        self.currentPlayerIndex = 1
    end

    -- Reset turn state
    self.turnPhase = "draw"
    self.hasDrawnThisTurn = false

    -- Clear newly drawn card highlights from previous turn
    for _, player in ipairs(self.players) do
        player.newlyDrawnCardIndices = {}
    end

    local currentPlayer = self:getCurrentPlayer()
    self:logAction(string.format("%s's turn", currentPlayer.name))

    -- If AI player, schedule their turn
    if currentPlayer.type == "bot" then
        self:scheduleAiAction("draw", 0.5)
    end
end

function GameState:drawFromDeck()
    local player = self:getCurrentPlayer()

    -- Check if deck has enough cards
    if self.deck:size() < 2 then
        -- Attempt emergency reshuffle
        if not self.deck:emergencyReshuffle(self.discardPile) then
            self:logAction("Emergency round end: Insufficient cards")
            self:endRound(nil)
            return false
        end
        self:logAction("Deck reshuffled from discard pile")
    end

    -- Draw 2 cards
    local cards = self.deck:drawCards(2)
    player:addCardsToHand(cards)

    self.hasDrawnThisTurn = true
    self.turnPhase = "meld"

    -- Highlight newly drawn cards with subtle fade-in animation
    player.newlyDrawnCardIndices = {}
    for i = #player.hand - #cards + 1, #player.hand do
        table.insert(player.newlyDrawnCardIndices, i)
        if player.hand[i] then
            local card = player.hand[i]
            card.highlighted = true

            -- Subtle fade-in animation
            card.animAlpha = 0
            card.animScale = 0.8
            flux.to(card, 0.3, { animAlpha = 1.0, animScale = 1.0 }):ease("quartout")
        end
    end

    self:logAction(string.format("%s drew 2 cards from deck", player.name))

    return true
end

function GameState:canUnlockDiscard()
    local player = self:getCurrentPlayer()

    -- Must have played down already
    if not player.hasPlayedDown then
        return false, "Must play down first"
    end

    -- Discard pile must not be empty
    if #self.discardPile == 0 then
        return false, "Discard pile is empty"
    end

    local topCard = self.discardPile[#self.discardPile]

    -- Top card must not be wild
    if topCard.isWild then
        return false, "Top card is wild"
    end

    -- Top card must not be a 3
    if topCard.isThree then
        return false, "Cannot unlock with 3 on top"
    end

    -- Count matching natural cards in hand
    local matchingNaturals = {}
    for _, card in ipairs(player.hand) do
        if card.rank == topCard.rank and not card.isWild then
            table.insert(matchingNaturals, card)
        end
    end

    -- Must have 2+ matching naturals
    if #matchingNaturals < 2 then
        return false, "Need 2+ matching natural cards"
    end

    return true
end

function GameState:unlockDiscard()
    local player = self:getCurrentPlayer()
    local topCard = self.discardPile[#self.discardPile]

    -- Find 2 matching natural cards
    local matchingCards = {}
    for _, card in ipairs(player.hand) do
        if card.rank == topCard.rank and not card.isWild and #matchingCards < 2 then
            table.insert(matchingCards, card)
        end
    end

    -- Remove top discard
    local topDiscard = table.remove(self.discardPile)

    -- Create or add to meld
    local meldCards = {matchingCards[1], matchingCards[2], topDiscard}
    local existingMeldIndex, existingMeld = player:findMeldByRank(topCard.rank)

    if existingMeld then
        player:addToMeld(existingMeldIndex, meldCards)
        self:logAction(string.format("%s unlocked discard and added to %s meld",
            player.name, topCard.rank))
    else
        player:createMeld(meldCards)
        self:logAction(string.format("%s unlocked discard and created %s meld",
            player.name, topCard.rank))
    end

    -- Take up to 5 additional cards from discard pile ONLY
    local additionalCards = {}
    for i = 1, 5 do
        if #self.discardPile > 0 then
            table.insert(additionalCards, table.remove(self.discardPile))
        else
            break
        end
    end

    if #additionalCards > 0 then
        player:addCardsToHand(additionalCards)
        self:logAction(string.format("%s took %d additional cards from discard",
            player.name, #additionalCards))
    end

    -- Unfreeze discard pile and mark as played down
    self.discardPileFrozen = false
    player.hasPlayedDown = true

    self.hasDrawnThisTurn = true
    self.turnPhase = "meld"

    return true
end

function GameState:discard(card)
    local player = self:getCurrentPlayer()

    -- Remove card from hand
    player:removeFromHand(card)

    -- Add to discard pile
    table.insert(self.discardPile, card)

    -- Freeze if wild card
    if card.isWild then
        self.discardPileFrozen = true
        self:logAction(string.format("%s discarded %s (pile frozen)",
            player.name, card:getDisplayName()))
    else
        self.discardPileFrozen = false
        self:logAction(string.format("%s discarded %s",
            player.name, card:getDisplayName()))
    end

    -- Check for foot pickup
    if #player.hand == 0 and not player.hasPickedUpFoot then
        player:pickUpFoot()
        self:logAction(string.format("%s picked up foot!", player.name))
    end

    -- Check if player can go out
    if #player.hand == 0 and #player.foot == 0 then
        local canGoOut, reason = player:canGoOut()
        if canGoOut then
            self:endRound(player)
            return
        end
    end

    -- End turn
    self:nextTurn()
end

function GameState:endRound(playerWhoWentOut)
    self.phase = "roundEnd"

    if playerWhoWentOut then
        self:logAction(string.format("%s went out! Round %d ended.",
            playerWhoWentOut.name, self.round))
    else
        self:logAction(string.format("Round %d ended.", self.round))
    end

    -- Calculate scores for all players
    for _, player in ipairs(self.players) do
        local wentOut = (player == playerWhoWentOut)
        local roundScore = player:calculateRoundScore(wentOut)
        player.score = player.score + roundScore
        player:recordRoundScore(self.round, roundScore, wentOut)

        self:logAction(string.format("%s scored %d points (total: %d)",
            player.name, roundScore, player.score))
    end

    -- Check for game end
    local highestScore = 0
    for _, player in ipairs(self.players) do
        if player.score > highestScore then
            highestScore = player.score
            self.winner = player
        end
    end

    if highestScore >= self.winningScore then
        self.phase = "gameEnd"
        self:logAction(string.format("Game Over! %s wins with %d points!",
            self.winner.name, self.winner.score))
    else
        -- Continue to next round
        self.round = self.round + 1
        -- Will need manual restart or auto-continue
    end
end

function GameState:scheduleAiAction(actionType, delay)
    -- Use flux for cleaner timer management
    local currentPlayer = self:getCurrentPlayer()
    flux.to({}, delay, {}):oncomplete(function()
        if self.phase == "playing" and currentPlayer.type == "bot" then
            self:executeAiAction(currentPlayer, actionType)
        end
    end)
end

function GameState:update()
    -- Flux timers are updated in main.lua love.update()
end

function GameState:executeAiAction(player, actionType)
    if actionType == "draw" then
        -- AI decides whether to draw from deck or unlock discard
        local decision = AIBot.makeDecision(player, self, "draw")

        if decision == "UNLOCK" then
            local canUnlock = self:canUnlockDiscard()
            if canUnlock then
                self:unlockDiscard()
            else
                self:drawFromDeck()
            end
        else
            self:drawFromDeck()
        end

        self:scheduleAiAction("meld", 0.8)

    elseif actionType == "meld" then
        -- AI tries to create melds or add to existing melds
        local meldCards = AIBot.makeDecision(player, self, "meld")

        if meldCards and #meldCards >= 3 then
            -- Check if this is a new meld or addition to existing
            local firstNonWild = nil
            for _, card in ipairs(meldCards) do
                if not card.isWild then
                    firstNonWild = card
                    break
                end
            end

            if firstNonWild then
                local meldIndex, existingMeld = player:findMeldByRank(firstNonWild.rank)

                if existingMeld then
                    -- Add to existing meld
                    player:addToMeld(meldIndex, meldCards)
                    self:logAction(string.format("%s added %d cards to %s meld",
                        player.name, #meldCards, firstNonWild.rank))
                else
                    -- Create new meld
                    player:createMeld(meldCards)
                    player.hasPlayedDown = true
                    self:logAction(string.format("%s created %s meld (%d cards)",
                        player.name, firstNonWild.rank, #meldCards))
                end

                -- Check for foot pickup
                if #player.hand == 0 and not player.hasPickedUpFoot then
                    player:pickUpFoot()
                    self:logAction(string.format("%s picked up foot!", player.name))
                end
            end
        end

        self:scheduleAiAction("discard", 0.6)

    elseif actionType == "discard" then
        -- AI chooses card to discard
        if #player.hand > 0 then
            local cardToDiscard = AIBot.makeDecision(player, self, "discard")

            if cardToDiscard then
                self:discard(cardToDiscard)
            else
                -- Fallback: discard first card
                self:discard(player.hand[1])
            end
        else
            -- No cards to discard, skip turn
            self:nextTurn()
        end
    end
end

function GameState:handleMousePressed(x, y, button)
    if self.phase == "roundEnd" then
        -- Click to continue to next round
        if button == 1 then
            self.phase = "setup"
            self:startRound()
        end
        return
    end

    if self.phase ~= "playing" then
        return
    end

    -- Check for action log toggle click (always available)
    local logW = UI.Theme.layout.logWidth
    local logH = self.actionLogCollapsed and 40 or UI.Theme.layout.logHeight
    local logX = Config.windowWidth - logW - 20
    local logY = Config.windowHeight - logH - 20

    -- Check if click is on the log header (toggle area)
    if x >= logX and x <= logX + logW and y >= logY and y <= logY + 30 then
        self.actionLogCollapsed = not self.actionLogCollapsed
        return
    end

    local currentPlayer = self:getCurrentPlayer()
    if currentPlayer.type ~= "human" then
        return
    end

    -- Handle card selection in hand
    local cardClicked = self:getCardAtPosition(x, y, currentPlayer)
    if cardClicked then
        cardClicked.selected = not cardClicked.selected
        return
    end
end

function GameState:getCardAtPosition(x, y, player)
    -- Calculate hand area
    local handX = 30
    local handY = 520
    local spacing = UI.Theme.card.spacing

    -- Adjust spacing if cards overflow
    local totalCardWidth = #player.hand * UI.Theme.card.width
    if totalCardWidth + (#player.hand - 1) * spacing > Config.windowWidth - 60 then
        spacing = (Config.windowWidth - 60 - totalCardWidth) / (#player.hand - 1)
        spacing = math.max(5, spacing)
    end

    local cardX = handX + 10

    for i, card in ipairs(player.hand) do
        local offsetY = card.selected and UI.Theme.card.selectedOffset or 0
        local cardY = handY + offsetY

        -- Check if click is within card bounds
        if x >= cardX and x <= cardX + UI.Theme.card.width and
           y >= cardY and y <= cardY + UI.Theme.card.height then
            return card
        end

        cardX = cardX + UI.Theme.card.width + spacing
    end

    return nil
end

function GameState:handleMouseReleased(x, y, button)
    -- Reserved for future drag-and-drop
end

function GameState:handleKeyPressed(key)
    if self.phase == "roundEnd" then
        if key == "space" or key == "return" then
            self.phase = "setup"
            self:startRound()
        end
        return
    end

    if self.phase ~= "playing" then
        return
    end

    local currentPlayer = self:getCurrentPlayer()
    if currentPlayer.type ~= "human" then
        return
    end

    -- Arrow key navigation (works in all phases)
    if key == "left" then
        if #currentPlayer.hand > 0 then
            if self.highlightedCardIndex == nil then
                self.highlightedCardIndex = 1
            else
                self.highlightedCardIndex = math.max(1, self.highlightedCardIndex - 1)
            end
        end
        return
    elseif key == "right" then
        if #currentPlayer.hand > 0 then
            if self.highlightedCardIndex == nil then
                self.highlightedCardIndex = 1
            else
                self.highlightedCardIndex = math.min(#currentPlayer.hand, self.highlightedCardIndex + 1)
            end
        end
        return
    elseif key == "space" and self.highlightedCardIndex then
        -- Toggle selection on highlighted card (works in meld and discard phases)
        if (self.turnPhase == "meld" or self.turnPhase == "discard") and self.highlightedCardIndex <= #currentPlayer.hand then
            currentPlayer:toggleCardSelection(self.highlightedCardIndex)
            return
        end
    end

    -- Draw phase shortcuts
    if self.turnPhase == "draw" then
        if key == "d" or key == "space" then
            self:drawFromDeck()
            return  -- Exit to prevent same key from being processed in next phase
        elseif key == "u" then
            local canUnlock = self:canUnlockDiscard()
            if canUnlock then
                self:unlockDiscard()
                return  -- Exit after phase change
            else
                self:logAction("Cannot unlock discard pile")
            end
        end
        return  -- Exit draw phase key handling
    end

    -- Meld phase shortcuts
    if self.turnPhase == "meld" then
        if key == "m" then
            -- Try to create meld with selected cards
            local selectedCards = currentPlayer:getSelectedCards()
            if #selectedCards >= 3 then
                local playDownReq = self:getPlayDownRequirement()
                local valid, error = Meld.validate(selectedCards, playDownReq, currentPlayer.hasPlayedDown)

                if valid then
                    currentPlayer:createMeld(selectedCards)
                    currentPlayer.hasPlayedDown = true
                    self:logAction(string.format("Created meld with %d cards", #selectedCards))

                    -- Check for foot pickup
                    if #currentPlayer.hand == 0 and not currentPlayer.hasPickedUpFoot then
                        currentPlayer:pickUpFoot()
                        self:logAction("Picked up foot!")
                    end
                else
                    self:logAction(string.format("Invalid meld: %s", error))
                end
            else
                self:logAction("Select at least 3 cards to create a meld")
            end
        elseif key == "a" then
            -- Try to add selected cards to existing meld
            local selectedCards = currentPlayer:getSelectedCards()
            if #selectedCards > 0 then
                -- Find which meld these cards belong to
                local firstNonWild = nil
                for _, card in ipairs(selectedCards) do
                    if not card.isWild then
                        firstNonWild = card
                        break
                    end
                end

                if firstNonWild then
                    local meldIndex, meld = currentPlayer:findMeldByRank(firstNonWild.rank)
                    if meld then
                        local success, error = currentPlayer:addToMeld(meldIndex, selectedCards)
                        if success then
                            self:logAction(string.format("Added %d cards to %s meld", #selectedCards, firstNonWild.rank))

                            -- Check for foot pickup
                            if #currentPlayer.hand == 0 and not currentPlayer.hasPickedUpFoot then
                                currentPlayer:pickUpFoot()
                                self:logAction("Picked up foot!")
                            end
                        else
                            self:logAction(string.format("Cannot add to meld: %s", error))
                        end
                    else
                        self:logAction(string.format("No existing meld for %s", firstNonWild.rank))
                    end
                end
            else
                self:logAction("Select cards to add to a meld")
            end
        elseif key == "c" then
            -- Clear selection
            currentPlayer:clearSelection()
            self:logAction("Selection cleared")
        elseif key == "d" or key == "return" or key == "tab" then
            -- Move to discard phase
            self.turnPhase = "discard"
            currentPlayer:clearSelection()
            self.highlightedCardIndex = nil  -- Clear arrow key highlight
            self:logAction("Discard phase - select a card to discard")
            return  -- Exit to prevent same key from being processed in next phase
        end
        return  -- Exit meld phase key handling
    end

    -- Discard phase
    if self.turnPhase == "discard" then
        -- ENTER toggles selection on highlighted card (SPACE is handled globally above)
        if key == "return" and self.highlightedCardIndex then
            currentPlayer:toggleCardSelection(self.highlightedCardIndex)
        -- D key discards the selected card
        elseif key == "d" then
            local selectedCards = currentPlayer:getSelectedCards()
            if #selectedCards == 1 then
                self:discard(selectedCards[1])
                self.highlightedCardIndex = nil  -- Clear highlight after discard
            elseif #selectedCards > 1 then
                self:logAction("Select exactly 1 card to discard (you have " .. #selectedCards .. " selected)")
            else
                self:logAction("Select a card to discard first")
            end
        end
    end
end

return GameState
