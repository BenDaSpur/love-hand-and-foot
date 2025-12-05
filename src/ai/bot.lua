-- AI Bot System
-- Implements easy, medium, and hard difficulty AI players

AIBot = {}

-- Easy Bot: Random valid moves
function AIBot.easyDecideDraw(player, gameState)
    -- Always draw from deck (simplest strategy)
    return "DRAW_DECK"
end

function AIBot.easyMeld(player, gameState)
    -- Try to create any valid meld
    local playDownReq = gameState:getPlayDownRequirement()

    -- Group cards by rank
    local cardsByRank = AIBot.groupCardsByRank(player.hand)

    -- Try to find first valid meld
    for rank, cards in pairs(cardsByRank) do
        if rank ~= "3" then -- Can't meld 3s
            local naturals = {}
            local wilds = {}

            for _, card in ipairs(cards) do
                if card.isWild then
                    table.insert(wilds, card)
                else
                    table.insert(naturals, card)
                end
            end

            -- Need at least 2 naturals
            if #naturals >= 2 then
                local meldCards = {naturals[1], naturals[2]}

                -- Add third natural or wild
                if #naturals >= 3 then
                    table.insert(meldCards, naturals[3])
                elseif #wilds >= 1 then
                    table.insert(meldCards, wilds[1])
                end

                -- Validate
                local valid = Meld.validate(meldCards, playDownReq, player.hasPlayedDown)
                if valid then
                    return meldCards
                end
            end
        end
    end

    return nil -- No valid meld found
end

function AIBot.easyDiscard(player, gameState)
    -- Priority: Red 3s > Black 3s > Random
    -- Use lume for cleaner card finding
    local redThree = lume.match(player.hand, function(c) return c.isRedThree end)
    if redThree then return redThree end

    local blackThree = lume.match(player.hand, function(c) return c.isBlackThree end)
    if blackThree then return blackThree end

    -- Random discard using lume
    return lume.randomchoice(player.hand)
end

-- Medium Bot: Basic strategy
function AIBot.mediumDecideDraw(player, gameState)
    -- Check if can unlock discard
    local canUnlock, reason = gameState:canUnlockDiscard()
    if canUnlock and #gameState.discardPile >= 4 then
        return "UNLOCK"
    end

    return "DRAW_DECK"
end

function AIBot.mediumMeld(player, gameState)
    local playDownReq = gameState:getPlayDownRequirement()
    local cardsByRank = AIBot.groupCardsByRank(player.hand)

    -- If not played down, try to meet requirement
    if not player.hasPlayedDown then
        return AIBot.tryPlayDown(player, cardsByRank, playDownReq)
    end

    -- Otherwise, prioritize completing books
    -- First, try to complete 6-card melds (one away from book)
    for _, meld in ipairs(player.melds) do
        if #meld.cards == 6 then
            local addedCards = AIBot.tryAddToMeld(player, meld, cardsByRank)
            if addedCards then
                return addedCards
            end
        end
    end

    -- Then try to add to any meld
    for _, meld in ipairs(player.melds) do
        local addedCards = AIBot.tryAddToMeld(player, meld, cardsByRank)
        if addedCards then
            return addedCards
        end
    end

    -- Finally, try to create new meld
    return AIBot.easyMeld(player, gameState)
end

function AIBot.mediumDiscard(player, gameState)
    -- Priority: Red 3s > Black 3s > Singles (cards with no matching rank) > Lowest value
    local redThree = lume.match(player.hand, function(c) return c.isRedThree end)
    if redThree then return redThree end

    local blackThree = lume.match(player.hand, function(c) return c.isBlackThree end)
    if blackThree then return blackThree end

    -- Find singles (cards where we only have 1 of that rank)
    local cardsByRank = AIBot.groupCardsByRank(player.hand)
    local singles = lume.filter(player.hand, function(card)
        return not card.isWild and cardsByRank[card.rank] and #cardsByRank[card.rank] == 1
    end)

    if #singles > 0 then
        -- Discard lowest value single
        table.sort(singles, function(a, b) return a.pointValue < b.pointValue end)
        return singles[1]
    end

    -- Discard lowest value non-wild card
    local nonWilds = lume.filter(player.hand, function(c) return not c.isWild end)
    if #nonWilds > 0 then
        table.sort(nonWilds, function(a, b) return a.pointValue < b.pointValue end)
        return nonWilds[1]
    end

    -- Fallback: discard any card
    return player.hand[1]
end

-- Hard Bot: Advanced strategy
function AIBot.hardDecideDraw(player, gameState)
    -- Advanced unlock evaluation
    local canUnlock, reason = gameState:canUnlockDiscard()
    if canUnlock then
        local discardValue = AIBot.estimateDiscardPileValue(gameState.discardPile)

        -- Unlock if:
        -- 1. Discard pile has 6+ cards (high value)
        -- 2. Current hand is large (25+ cards) and need to meld
        -- 3. Can complete a book with unlock
        if #gameState.discardPile >= 6 then
            return "UNLOCK"
        end

        if #player.hand >= 25 then
            return "UNLOCK"
        end

        -- Check if unlock would complete a book
        local topCard = gameState.discardPile[#gameState.discardPile]
        local meldIndex, meld = player:findMeldByRank(topCard.rank)
        if meld and #meld.cards >= 4 then
            return "UNLOCK"
        end
    end

    return "DRAW_DECK"
end

function AIBot.hardMeld(player, gameState)
    -- Use medium strategy but with additional book protection
    local playDownReq = gameState:getPlayDownRequirement()
    local cardsByRank = AIBot.groupCardsByRank(player.hand)

    if not player.hasPlayedDown then
        return AIBot.tryPlayDown(player, cardsByRank, playDownReq)
    end

    -- Prioritize completing books (6-card melds)
    for _, meld in ipairs(player.melds) do
        if #meld.cards == 6 then
            -- Protect clean books from contamination
            local isClean = (meld:getWildCount() == 0)

            if isClean then
                -- Only add natural cards
                local naturals = cardsByRank[meld.rank] or {}
                for _, card in ipairs(naturals) do
                    if not card.isWild then
                        return {card} -- Return as array for adding to meld
                    end
                end
            else
                -- Can add wilds
                local addedCards = AIBot.tryAddToMeld(player, meld, cardsByRank)
                if addedCards then
                    return addedCards
                end
            end
        end
    end

    -- Try to add to other melds
    for _, meld in ipairs(player.melds) do
        if #meld.cards < 6 then
            local addedCards = AIBot.tryAddToMeld(player, meld, cardsByRank)
            if addedCards then
                return addedCards
            end
        end
    end

    -- Create new meld
    return AIBot.easyMeld(player, gameState)
end

function AIBot.hardDiscard(player, gameState)
    return AIBot.mediumDiscard(player, gameState)
end

-- Helper functions
function AIBot.groupCardsByRank(hand)
    local groups = {}

    for _, card in ipairs(hand) do
        local rank = card.isWild and "wild" or card.rank

        if not groups[rank] then
            groups[rank] = {}
        end

        table.insert(groups[rank], card)
    end

    return groups
end

function AIBot.tryPlayDown(player, cardsByRank, playDownReq)
    -- Find combination of cards that meets play-down requirement
    local bestMeld = nil
    local bestPoints = 0

    for rank, cards in pairs(cardsByRank) do
        if rank ~= "3" then
            local naturals = {}
            local wilds = cardsByRank["wild"] or {}

            for _, card in ipairs(cards) do
                if not card.isWild then
                    table.insert(naturals, card)
                end
            end

            if #naturals >= 2 then
                -- Try different combinations
                for naturalCount = 2, math.min(#naturals, 7) do
                    local meldCards = {}

                    -- Add naturals
                    for i = 1, naturalCount do
                        table.insert(meldCards, naturals[i])
                    end

                    -- Calculate points
                    local points = 0
                    for _, card in ipairs(meldCards) do
                        points = points + card.pointValue
                    end

                    -- Try adding wilds
                    local maxWilds = math.min(#wilds, naturalCount) -- Wilds can't exceed naturals
                    for wildCount = 0, maxWilds do
                        local testMeld = lume.clone(meldCards)

                        for i = 1, wildCount do
                            table.insert(testMeld, wilds[i])
                        end

                        local testPoints = points
                        for i = 1, wildCount do
                            testPoints = testPoints + wilds[i].pointValue
                        end

                        if testPoints >= playDownReq and testPoints > bestPoints then
                            bestMeld = testMeld
                            bestPoints = testPoints
                        end
                    end
                end
            end
        end
    end

    return bestMeld
end

function AIBot.tryAddToMeld(player, meld, cardsByRank)
    local rank = meld.rank
    local cards = cardsByRank[rank] or {}

    -- Try to add natural cards first
    for _, card in ipairs(cards) do
        if not card.isWild then
            local canAdd, err = meld:canAddCard(card)
            if canAdd then
                return {card}
            end
        end
    end

    -- Try to add wild cards
    local wilds = cardsByRank["wild"] or {}
    for _, wild in ipairs(wilds) do
        local canAdd, err = meld:canAddCard(wild)
        if canAdd then
            return {wild}
        end
    end

    return nil
end

function AIBot.estimateDiscardPileValue(discardPile)
    local totalValue = 0
    for _, card in ipairs(discardPile) do
        totalValue = totalValue + card.pointValue
    end
    return totalValue
end

-- Main bot decision function
function AIBot.makeDecision(player, gameState, decisionType)
    local difficulty = player.difficulty or "medium"

    if decisionType == "draw" then
        if difficulty == "easy" then
            return AIBot.easyDecideDraw(player, gameState)
        elseif difficulty == "hard" then
            return AIBot.hardDecideDraw(player, gameState)
        else
            return AIBot.mediumDecideDraw(player, gameState)
        end
    elseif decisionType == "meld" then
        if difficulty == "easy" then
            return AIBot.easyMeld(player, gameState)
        elseif difficulty == "hard" then
            return AIBot.hardMeld(player, gameState)
        else
            return AIBot.mediumMeld(player, gameState)
        end
    elseif decisionType == "discard" then
        if difficulty == "easy" then
            return AIBot.easyDiscard(player, gameState)
        elseif difficulty == "hard" then
            return AIBot.hardDiscard(player, gameState)
        else
            return AIBot.mediumDiscard(player, gameState)
        end
    end
end

return AIBot
