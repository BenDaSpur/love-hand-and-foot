# Library Usage Guide

## Flux - Tweening Library

Flux makes it easy to animate values over time. Perfect for smooth card movements and UI animations.

### Basic Usage

```lua
-- Animate a card's position
flux.to(card, 0.5, { x = 100, y = 200 }):ease("quadout")

-- Animate with a delay
flux.to(card, 0.3, { alpha = 1 }):delay(0.5)

-- Chain animations
flux.to(card, 0.2, { y = card.y - 10 })
    :oncomplete(function()
        flux.to(card, 0.2, { y = card.y + 10 })
    end)

-- Common easing functions
:ease("linear")
:ease("quadin")
:ease("quadout")
:ease("cubicin")
:ease("elasticout")
:ease("backin")
```

### Example: Card Draw Animation

```lua
-- Instead of instant card placement:
-- card.x = targetX
-- card.y = targetY

-- Use smooth animation:
flux.to(card, 0.4, {
    x = targetX,
    y = targetY
}):ease("quadout")
```

### Example: Discard Animation

```lua
-- Animate card to discard pile with callback
flux.to(card, 0.3, {
    x = discardX,
    y = discardY,
    scale = 0.8
}):ease("cubicout")
:oncomplete(function()
    -- Card arrived at discard pile
    table.insert(discardPile, card)
end)
```

## Lume - Utility Functions

Lume provides helpful utility functions for common operations.

### Useful Functions

```lua
-- Array operations
lume.shuffle(deck.cards)  -- Shuffle deck
lume.randomchoice(cards)  -- Pick random card
lume.first(cards, 5)      -- Get first 5 cards
lume.last(cards, 3)       -- Get last 3 cards

-- Filtering
local aces = lume.filter(hand, function(c) return c.rank == "A" end)
local wilds = lume.filter(hand, function(c) return c.isWild end)

-- Mapping
local values = lume.map(hand, function(c) return c.pointValue end)

-- Sum/reduce
local totalPoints = lume.reduce(hand, function(sum, card)
    return sum + card.pointValue
end, 0)

-- Table operations
lume.merge(table1, table2)  -- Combine tables
lume.clone(card)            -- Deep copy
lume.count(hand)            -- Count items

-- Functional helpers
lume.once(func)             -- Run function only once
lume.memoize(func)          -- Cache function results

-- Math helpers
lume.clamp(value, 0, 100)   -- Limit value range
lume.round(3.7)             -- Round to nearest integer
lume.distance(x1, y1, x2, y2)  -- Distance between points

-- String helpers
lume.trim("  hello  ")      -- Remove whitespace
lume.split("a,b,c", ",")    -- Split string
```

### Example: Improved AI Card Selection

```lua
-- Instead of manual loops:
-- for i, card in ipairs(player.hand) do
--     if card.rank == targetRank then
--         return card
--     end
-- end

-- Use lume:
local card = lume.match(player.hand, function(c)
    return c.rank == targetRank
end)
```

### Example: Shuffle Deck

```lua
-- Instead of custom shuffle logic:
function Deck:shuffle()
    self.cards = lume.shuffle(self.cards)
end
```

## Quick Integration Ideas

### 1. Smooth Card Draws
Replace instant card draws with animated movements from deck to hand.

### 2. Discard Pile Animations
Animate cards flying to the discard pile with a nice curve.

### 3. Meld Creation Animation
When creating a meld, animate cards smoothly arranging themselves.

### 4. Score Counter Animation
Animate score numbers counting up instead of instant changes.

### 5. AI Turn Delays
Use flux timers instead of manual timer code:
```lua
flux.to({}, 0.8, {}):oncomplete(function()
    executeAiAction()
end)
```

### 6. Card Selection Highlight
Smooth highlight/unhighlight animations on hover.

### 7. Better Utility Functions
Replace manual array operations with lume's optimized functions.
