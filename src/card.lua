-- Card class
-- Represents a single playing card with rank, suit, and point value

Card = {}
Card.__index = Card

-- Card ranks
Card.RANKS = {
    "joker", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"
}

-- Card suits (null for jokers)
Card.SUITS = {
    "hearts", "diamonds", "clubs", "spades"
}

-- Point values according to specification
Card.POINT_VALUES = {
    joker = 50,
    ["2"] = 20,
    ace = 20,
    king = 10,
    queen = 10,
    jack = 10,
    ["10"] = 10,
    ["9"] = 10,
    ["8"] = 10,
    ["7"] = 5,
    ["6"] = 5,
    ["5"] = 5,
    ["4"] = 5,
    ["3"] = -5  -- Black 3s default, red 3s overridden
}

-- Suit symbols (using text since Unicode may not render)
Card.SUIT_SYMBOLS = {
    hearts = "H",
    diamonds = "D",
    clubs = "C",
    spades = "S"
}

-- Rank display text
Card.RANK_DISPLAY = {
    joker = "JKR",
    ["2"] = "2",
    ["3"] = "3",
    ["4"] = "4",
    ["5"] = "5",
    ["6"] = "6",
    ["7"] = "7",
    ["8"] = "8",
    ["9"] = "9",
    ["10"] = "10",
    jack = "J",
    queen = "Q",
    king = "K",
    ace = "A"
}

function Card.new(rank, suit)
    local self = setmetatable({}, Card)

    self.rank = rank
    self.suit = suit

    -- Wild card check
    self.isWild = (rank == "joker" or rank == "2")

    -- 3s check
    self.isThree = (rank == "3")

    -- Red 3s check (hearts or diamonds)
    self.isRedThree = (rank == "3" and (suit == "hearts" or suit == "diamonds"))
    self.isBlackThree = (rank == "3" and (suit == "clubs" or suit == "spades"))

    -- Calculate point value
    self.pointValue = Card.POINT_VALUES[rank] or 0

    -- Override for red 3s
    if self.isRedThree then
        self.pointValue = -300
    end

    -- Unique ID for tracking
    self.id = string.format("%s_%s_%s", rank, suit or "none", math.random(1000000))

    -- Selection state (for UI)
    self.selected = false
    self.highlighted = false

    -- Animation properties
    self.animX = 0
    self.animY = 0
    self.animScale = 1.0
    self.animAlpha = 1.0

    return self
end

function Card:getDisplayName()
    if self.rank == "joker" then
        return "Joker"
    end
    local rankStr = Card.RANK_DISPLAY[self.rank] or self.rank
    local suitStr = Card.SUIT_SYMBOLS[self.suit] or ""
    return rankStr .. suitStr
end

function Card:getColor()
    if self.suit == "hearts" or self.suit == "diamonds" then
        return "red"
    elseif self.suit == "clubs" or self.suit == "spades" then
        return "black"
    end
    return "wild" -- For jokers
end

function Card:getSortValue()
    -- Sort order: 3s → 4-K → Aces → 2s → Jokers
    local rankOrder = {
        ["3"] = 1,
        ["4"] = 2,
        ["5"] = 3,
        ["6"] = 4,
        ["7"] = 5,
        ["8"] = 6,
        ["9"] = 7,
        ["10"] = 8,
        jack = 9,
        queen = 10,
        king = 11,
        ace = 12,
        ["2"] = 13,
        joker = 14
    }

    local suitOrder = {
        clubs = 1,
        diamonds = 2,
        hearts = 3,
        spades = 4
    }

    local rankVal = rankOrder[self.rank] or 0
    local suitVal = suitOrder[self.suit] or 0

    return rankVal * 10 + suitVal
end

function Card:clone()
    local cloned = Card.new(self.rank, self.suit)
    cloned.selected = self.selected
    cloned.highlighted = self.highlighted
    return cloned
end

function Card:__tostring()
    return self:getDisplayName()
end

-- Helper function to sort cards
function Card.sortCards(cards)
    table.sort(cards, function(a, b)
        return a:getSortValue() < b:getSortValue()
    end)
    return cards
end

return Card
