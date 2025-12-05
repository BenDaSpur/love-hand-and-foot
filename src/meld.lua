-- Meld class
-- Represents a set of 3+ cards of the same rank

Meld = {}
Meld.__index = Meld

function Meld.new(cards)
    local self = setmetatable({}, Meld)

    self.cards = cards or {}
    self.rank = nil

    if #self.cards > 0 then
        -- Determine rank from first natural card
        for _, card in ipairs(self.cards) do
            if not card.isWild then
                self.rank = card.rank
                break
            end
        end
    end

    return self
end

function Meld:addCard(card)
    table.insert(self.cards, card)
    return self
end

function Meld:addCards(cards)
    for _, card in ipairs(cards) do
        table.insert(self.cards, card)
    end
    return self
end

function Meld:getNaturalCount()
    local count = 0
    for _, card in ipairs(self.cards) do
        if not card.isWild then
            count = count + 1
        end
    end
    return count
end

function Meld:getWildCount()
    local count = 0
    for _, card in ipairs(self.cards) do
        if card.isWild then
            count = count + 1
        end
    end
    return count
end

function Meld:isBook()
    return #self.cards >= 7
end

function Meld:isCleanBook()
    return self:isBook() and self:getWildCount() == 0
end

function Meld:isDirtyBook()
    return self:isBook() and self:getWildCount() > 0
end

function Meld:getBookBonus()
    if self:isCleanBook() then
        return 500
    elseif self:isDirtyBook() then
        return 300
    end
    return 0
end

function Meld:getPointValue()
    local total = 0
    for _, card in ipairs(self.cards) do
        total = total + card.pointValue
    end
    return total + self:getBookBonus()
end

function Meld:getDisplayName()
    if not self.rank then
        return "Empty Meld"
    end

    local rankName = Card.RANK_DISPLAY[self.rank] or self.rank
    local status = ""

    if self:isCleanBook() then
        status = " (Clean Book)"
    elseif self:isDirtyBook() then
        status = " (Dirty Book)"
    end

    return string.format("%ss%s [%d cards]", rankName, status, #self.cards)
end

function Meld:canAddCard(card)
    -- Can't add 3s
    if card.isThree then
        return false, "3s cannot be melded"
    end

    -- Wild cards can be added if wild count doesn't exceed naturals
    if card.isWild then
        local newWildCount = self:getWildCount() + 1
        local naturalCount = self:getNaturalCount()
        if newWildCount > naturalCount then
            return false, "Too many wild cards (wilds cannot exceed naturals)"
        end
        return true
    end

    -- Natural card must match rank
    if card.rank ~= self.rank then
        return false, string.format("Card rank %s doesn't match meld rank %s", card.rank, self.rank)
    end

    return true
end

function Meld:__tostring()
    return self:getDisplayName()
end

-- Static validation function for creating new melds
function Meld.validate(cards, playDownRequirement, hasPlayedDown)
    -- Empty selection
    if #cards == 0 then
        return false, "Select at least 3 cards"
    end

    -- Too few cards
    if #cards < 3 then
        return false, "Melds require at least 3 cards"
    end

    -- Separate naturals, wilds, and threes
    local naturals = {}
    local wilds = {}
    local threes = {}

    for _, card in ipairs(cards) do
        if card.isThree then
            table.insert(threes, card)
        elseif card.isWild then
            table.insert(wilds, card)
        else
            table.insert(naturals, card)
        end
    end

    -- Contains 3s
    if #threes > 0 then
        return false, "3s cannot be melded"
    end

    -- Not enough naturals
    if #naturals < 2 then
        return false, "Need at least 2 natural cards of same rank"
    end

    -- Check all naturals are same rank
    local firstRank = naturals[1].rank
    for _, card in ipairs(naturals) do
        if card.rank ~= firstRank then
            return false, "All natural cards must be same rank"
        end
    end

    -- Too many wilds
    if #wilds > #naturals then
        return false, string.format("Too many wild cards (%d wilds, %d naturals). Wilds cannot exceed naturals.", #wilds, #naturals)
    end

    -- Play-down requirement check
    if not hasPlayedDown and playDownRequirement then
        local totalPoints = 0
        for _, card in ipairs(cards) do
            totalPoints = totalPoints + card.pointValue
        end

        if totalPoints < playDownRequirement then
            return false, string.format("Need %d points to play down (have %d)", playDownRequirement, totalPoints)
        end
    end

    return true
end

-- Validate multiple melds together for play-down requirement
function Meld.validateMultiple(meldGroups, playDownRequirement, hasPlayedDown)
    if #meldGroups == 0 then
        return false, "No melds selected"
    end

    -- Validate each meld individually
    for i, cards in ipairs(meldGroups) do
        local valid, error = Meld.validate(cards, nil, true) -- Don't check playdown for individual melds
        if not valid then
            return false, string.format("Meld %d: %s", i, error)
        end
    end

    -- Check combined play-down requirement
    if not hasPlayedDown and playDownRequirement then
        local totalPoints = 0
        for _, cards in ipairs(meldGroups) do
            for _, card in ipairs(cards) do
                totalPoints = totalPoints + card.pointValue
            end
        end

        if totalPoints < playDownRequirement then
            return false, string.format("Need %d points to play down (have %d)", playDownRequirement, totalPoints)
        end
    end

    return true
end

return Meld
