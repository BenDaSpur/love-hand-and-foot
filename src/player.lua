-- Player class
-- Represents a player (human or AI) with hand, foot, and melds

Player = {}
Player.__index = Player

function Player.new(name, playerType, id)
    local self = setmetatable({}, Player)

    self.id = id or math.random(1000000)
    self.name = name
    self.type = playerType or "human" -- "human" or "bot"
    self.difficulty = "medium" -- For bots: "easy", "medium", "hard"

    -- Card collections
    self.hand = {}
    self.foot = {}
    self.melds = {}

    -- State flags
    self.hasPlayedDown = false
    self.hasPickedUpFoot = false

    -- Score tracking
    self.score = 0
    self.roundScores = {}

    -- UI helpers
    self.newlyDrawnCardIndices = {}

    return self
end

function Player:addToHand(card)
    table.insert(self.hand, card)
    Card.sortCards(self.hand)
end

function Player:addCardsToHand(cards)
    for _, card in ipairs(cards) do
        table.insert(self.hand, card)
    end
    Card.sortCards(self.hand)
end

function Player:removeFromHand(card)
    for i, c in ipairs(self.hand) do
        if c.id == card.id then
            table.remove(self.hand, i)
            return true
        end
    end
    return false
end

function Player:removeCardsFromHand(cards)
    for _, card in ipairs(cards) do
        self:removeFromHand(card)
    end
end

function Player:findMeldByRank(rank)
    for i, meld in ipairs(self.melds) do
        if meld.rank == rank then
            return i, meld
        end
    end
    return nil, nil
end

function Player:createMeld(cards)
    local meld = Meld.new(cards)
    table.insert(self.melds, meld)
    self:removeCardsFromHand(cards)
    return meld
end

function Player:addToMeld(meldIndex, cards)
    if meldIndex < 1 or meldIndex > #self.melds then
        return false, "Invalid meld index"
    end

    local meld = self.melds[meldIndex]

    -- Validate each card can be added
    for _, card in ipairs(cards) do
        local canAdd, error = meld:canAddCard(card)
        if not canAdd then
            return false, error
        end
    end

    -- Add cards
    meld:addCards(cards)
    self:removeCardsFromHand(cards)

    return true
end

function Player:pickUpFoot()
    if self.hasPickedUpFoot then
        return false
    end

    -- Move foot to hand
    for _, card in ipairs(self.foot) do
        table.insert(self.hand, card)
    end
    self.foot = {}

    Card.sortCards(self.hand)

    self.hasPickedUpFoot = true
    return true
end

function Player:canGoOut()
    -- Must have picked up and emptied foot
    if not self.hasPickedUpFoot then
        return false, "Must pick up foot first"
    end

    if #self.foot > 0 then
        return false, "Must empty foot"
    end

    -- Count books
    local cleanBooks = 0
    local dirtyBooks = 0

    for _, meld in ipairs(self.melds) do
        if meld:isCleanBook() then
            cleanBooks = cleanBooks + 1
        elseif meld:isDirtyBook() then
            dirtyBooks = dirtyBooks + 1
        end
    end

    -- Must have both types of books
    if cleanBooks < 1 then
        return false, "Need at least 1 Clean Book (7+ cards with NO wilds)"
    end

    if dirtyBooks < 1 then
        return false, "Need at least 1 Dirty Book (7+ cards WITH wilds)"
    end

    return true
end

function Player:calculateRoundScore(wentOut)
    local score = 0

    -- 1. Meld points (positive)
    for _, meld in ipairs(self.melds) do
        score = score + meld:getPointValue()
    end

    -- 2. Unplayed card penalties (negative)
    -- All cards in hand AND foot count as negative
    local unplayedCards = {}
    for _, card in ipairs(self.hand) do
        table.insert(unplayedCards, card)
    end
    for _, card in ipairs(self.foot) do
        table.insert(unplayedCards, card)
    end

    for _, card in ipairs(unplayedCards) do
        score = score - math.abs(card.pointValue)
    end

    -- 3. Going out bonus
    if wentOut then
        score = score + 100
    end

    return score
end

function Player:recordRoundScore(round, roundScore, wentOut)
    table.insert(self.roundScores, {
        round = round,
        score = roundScore,
        wentOut = wentOut
    })
end

function Player:reset()
    self.hand = {}
    self.foot = {}
    self.melds = {}
    self.hasPlayedDown = false
    self.hasPickedUpFoot = false
    self.newlyDrawnCardIndices = {}
end

function Player:getSelectedCards()
    local selected = {}
    for _, card in ipairs(self.hand) do
        if card.selected then
            table.insert(selected, card)
        end
    end
    return selected
end

function Player:clearSelection()
    for _, card in ipairs(self.hand) do
        card.selected = false
    end
end

function Player:toggleCardSelection(cardIndex)
    if cardIndex > 0 and cardIndex <= #self.hand then
        local card = self.hand[cardIndex]
        card.selected = not card.selected
    end
end

function Player:countBooksOfType()
    local cleanBooks = 0
    local dirtyBooks = 0

    for _, meld in ipairs(self.melds) do
        if meld:isCleanBook() then
            cleanBooks = cleanBooks + 1
        elseif meld:isDirtyBook() then
            dirtyBooks = dirtyBooks + 1
        end
    end

    return cleanBooks, dirtyBooks
end

function Player:__tostring()
    return string.format("%s (%s) - Score: %d", self.name, self.type, self.score)
end

function Player:countRankTotal(rank)
    -- Count cards of a specific rank in hand + melds
    local count = 0

    -- Count in hand
    for _, card in ipairs(self.hand) do
        if card.rank == rank then
            count = count + 1
        end
    end

    -- Count in melds
    for _, meld in ipairs(self.melds) do
        if meld.rank == rank then
            count = count + #meld.cards
        end
    end

    return count
end

return Player
