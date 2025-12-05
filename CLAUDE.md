# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hand & Foot card game implemented in LÖVE2D (Lua) with a synthwave/outrun cyberpunk aesthetic. The game implements the complete Hand & Foot ruleset with 1 human player vs 3 AI bots.

## Running the Game

```bash
# From project root
love .

# The game has hot reload - edit and save watched files to see changes
```

Files watched for hot reload:
- `src/ui/theme.lua`
- `src/ui/renderer.lua`
- `src/gamestate.lua`
- `src/ai/bot.lua`

## Architecture

### Game Loop & State Management

The game uses a **state machine** pattern managed by `GameState`:

```
Phases: "setup" → "playing" → "roundEnd" → (repeat) → "gameEnd"
Turn Phases: "draw" → "meld" → "discard" → (next player)
```

**Critical**: The `GameState` class orchestrates ALL game logic. It owns:
- Turn flow (which player, which phase)
- Deck and discard pile
- All players and their hands/feet/melds
- AI turn scheduling via flux timers
- Input handling routing

### AI Turn System

AI turns use **flux callbacks** (not manual timers):

```lua
-- In GameState:scheduleAiAction()
flux.to({}, delay, {}):oncomplete(function()
    self:executeAiAction(currentPlayer, actionType)
end)
```

Sequence: `draw` (0.5s delay) → `meld` (0.8s delay) → `discard` (0.6s delay) → `nextTurn()`

**Important**: flux.update(dt) is called in main.lua's love.update() - never call it elsewhere.

### Module System

All game classes are **global singletons** loaded in main.lua:
- `Card`, `Deck`, `Meld`, `Player`, `GameState`, `AIBot`
- `UI.Theme`, `UI.Renderer`

**No `require()` needed** in individual files - modules expose themselves globally.

### Class Pattern

Lua classes use metatables:

```lua
ClassName = {}
ClassName.__index = ClassName

function ClassName.new(...)
    local self = setmetatable({}, ClassName)
    -- initialization
    return self
end

function ClassName:method()
    -- use self
end
```

## Key Game Logic

### Card System

Cards are immutable value objects with:
- `rank`: "ace", "2"-"10", "jack", "queen", "king", "joker"
- `suit`: "hearts", "diamonds", "clubs", "spades" (nil for jokers)
- `isWild`: true for jokers and 2s
- `isRedThree`/`isBlackThree`: special penalty cards
- `pointValue`: used for scoring and play-down requirements

**Wild cards**: Jokers (50pts) and 2s (20pts) can substitute for any rank BUT cannot exceed natural cards in a meld.

### Meld Validation

Critical rules in `Meld.validate()`:
1. Minimum 3 cards
2. 3s cannot be melded (discard only)
3. Wild cards ≤ natural cards
4. For play-down: sum of card values ≥ round requirement (60, 90, 120, 150, +30/round)
5. After playing down once, no minimum for future melds

### Books

- **Clean Book**: 7+ cards, NO wilds (500 bonus)
- **Dirty Book**: 7+ cards, WITH wilds (300 bonus)

Required to go out: ≥1 clean book AND ≥1 dirty book.

### AI Decision Making

AI bots (`src/ai/bot.lua`) have three difficulty levels:
- **Easy**: Random valid moves
- **Medium**: Basic strategy (prioritize completing books, discard singles)
- **Hard**: Advanced (unlock evaluation, book protection)

All use functional helpers from `lume`:
- `lume.match()` - find first matching card
- `lume.filter()` - filter card lists
- `lume.randomchoice()` - random selection
- `lume.clone()` - deep copy arrays

## Libraries Used

### flux (lib/flux.lua)
Tweening and timer library. Used for:
- AI turn delays
- Future: card animations, smooth transitions

```lua
flux.to(object, duration, { property = value }):ease("quadout"):oncomplete(callback)
```

### lume (lib/lume.lua)
Utility functions. Commonly used:
- `lume.shuffle(array)` - deck shuffling
- `lume.match(array, predicate)` - find card
- `lume.filter(array, predicate)` - filter cards
- `lume.clone(table)` - deep copy
- `lume.randomchoice(array)` - pick random

## Theme System

**Synthwave/Outrun aesthetic** defined in `src/ui/theme.lua`:

Color scheme:
- Background: Deep purple-black (#0D0026)
- Each suit has unique neon color:
  - Hearts: Hot pink/magenta (#FF0066)
  - Diamonds: Neon orange (#FF6600)
  - Clubs: Neon green (#00FF80)
  - Spades: Electric cyan (#00F0FF)
- Wilds: Neon purple (#B200FF)

Visual effects:
- Perspective grid floor
- Scanline overlay
- Neon glow on cards (multi-layer alpha blending)
- Circuit board patterns

## Rendering Architecture

`UI.Renderer` (src/ui/renderer.lua) uses immediate mode rendering:

```lua
function UI.Renderer.drawGame(gameState)
    -- Draw in order (back to front):
    1. Background (grid, horizon, scanlines)
    2. Top area (deck, discard, info)
    3. Opponent areas
    4. Player hand and melds
    5. Action log overlay
end
```

**Card rendering**: Only center suit icon (no corners), with rank in top-left/bottom-right.

## Common Patterns

### Adding a new game feature:
1. Add logic to `GameState` (owns all game state)
2. Update `executeAiAction()` if AI needs to handle it
3. Add rendering to `UI.Renderer`
4. Update controls in `GameState:handleKeyPressed()`

### Debugging AI turns:
- Check flux timers are being called (add prints in oncomplete)
- Verify `AIBot.makeDecision()` returns valid values
- Ensure `executeAiAction()` schedules next action

### Modifying visuals:
- Colors: `src/ui/theme.lua` → `UI.Theme.colors`
- Layout: `src/ui/theme.lua` → `UI.Theme.layout` / `UI.Theme.card`
- Rendering: `src/ui/renderer.lua` → specific draw functions

## Game Rules Reference

Full specification in `hand_and_foot_complete_specification.md`.

Quick reference:
- **Goal**: 8500 points to win
- **Play-down**: Round 1 = 60pts, +30pts each round
- **Going out**: Empty hand + foot with ≥1 clean book + ≥1 dirty book
- **Red 3s**: -300pts penalty (discard immediately!)
- **Deck size**: (num_players + 1) × 52-card decks + jokers

## Code Style

- Use `:` for method calls (`player:drawCard()`)
- Use `.` for static functions (`Card.new()`)
- Prefer `lume` utilities over manual loops
- Use `flux` for any timing/animation needs
- Keep classes in separate files, expose globally
- Document complex game logic with comments
