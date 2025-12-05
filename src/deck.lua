-- Deck class
-- Manages the draw pile with shuffle, draw, and reshuffle logic

Deck = {}
Deck.__index = Deck

function Deck.new(numPlayers)
    local self = setmetatable({}, Deck)

    -- Total decks = number_of_players + 1
    self.numDecks = numPlayers + 1
    self.cards = {}
    self.seed = os.time() -- For deterministic shuffle if needed

    self:buildDeck()
    self:shuffle()

    return self
end

function Deck:buildDeck()
    self.cards = {}

    -- Create standard 52-card decks + jokers
    for deckNum = 1, self.numDecks do
        -- Add 4 jokers per deck
        for i = 1, 4 do
            table.insert(self.cards, Card.new("joker", nil))
        end

        -- Add all regular cards (52 per deck)
        for _, suit in ipairs(Card.SUITS) do
            for _, rank in ipairs({"3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace", "2"}) do
                table.insert(self.cards, Card.new(rank, suit))
            end
        end
    end

    return self
end

function Deck:shuffle()
    -- Use lume's optimized shuffle (Fisher-Yates)
    self.cards = lume.shuffle(self.cards)
    return self
end

function Deck:drawCard()
    if #self.cards == 0 then
        return nil
    end

    local card = table.remove(self.cards)
    return card
end

function Deck:drawCards(count)
    local drawn = {}

    for i = 1, count do
        local card = self:drawCard()
        if card then
            table.insert(drawn, card)
        else
            break
        end
    end

    return drawn
end

function Deck:size()
    return #self.cards
end

function Deck:isEmpty()
    return #self.cards == 0
end

function Deck:addCards(cards)
    for _, card in ipairs(cards) do
        table.insert(self.cards, card)
    end
end

function Deck:peek()
    if #self.cards == 0 then
        return nil
    end
    return self.cards[#self.cards]
end

-- Emergency reshuffle: take all but top card from discard pile
function Deck:emergencyReshuffle(discardPile)
    if #discardPile <= 1 then
        return false -- Cannot reshuffle, not enough cards
    end

    -- Keep top card of discard pile
    local topCard = table.remove(discardPile)

    -- Add all other cards to deck
    self:addCards(discardPile)

    -- Clear discard pile except top card
    for i = #discardPile, 1, -1 do
        table.remove(discardPile)
    end
    table.insert(discardPile, topCard)

    -- Shuffle the deck
    self:shuffle()

    return true
end

function Deck:__tostring()
    return string.format("Deck (%d cards)", #self.cards)
end

return Deck
