# Hand & Foot Card Game

A Balatro-style implementation of the Hand & Foot card game built with LÖVE2D.

## Installation

1. Install LÖVE2D from https://love2d.org/
2. Clone or download this repository

## Running the Game

### macOS/Linux
```bash
cd love-hand-and-foot
love .
```

### Windows
Drag the project folder onto `love.exe` or run:
```
love.exe "path\to\love-hand-and-foot"
```

### Alternative (macOS)
```bash
open -a love .
```

## How to Play

### Game Objective
- Reach **8500 points** across multiple rounds
- Each round: form melds, complete books, and go out first

### Key Concepts
- **Hand**: 11 cards played first
- **Foot**: 11 cards face-down, played after hand is empty
- **Meld**: 3+ cards of same rank
- **Clean Book**: 7+ cards with NO wild cards (500 bonus points)
- **Dirty Book**: 7+ cards WITH wild cards (300 bonus points)
- **Wild Cards**: Jokers and 2s
- **Going Out**: Empty both hand and foot with required books

### Controls

**Keyboard Navigation:**
- `LEFT/RIGHT ARROW` - Navigate through cards in hand
- `SPACE` - Select/deselect highlighted card

**Draw Phase:**
- `D` or `SPACE` - Draw 2 cards from deck
- `U` - Unlock discard pile (if eligible)

**Meld Phase:**
- `Click cards` or `SPACE` (with arrows) - Select/deselect cards
- `M` - Create new meld with selected cards
- `A` - Add selected cards to existing meld
- `C` - Clear selection
- `D` - Skip to discard phase

**Discard Phase:**
- `LEFT/RIGHT ARROW` - Navigate through cards
- `SPACE` - Select card to discard
- `D` - Discard selected card

**General:**
- `ESC` - Quit game

### Play-Down Requirements

| Round | Minimum Points Required |
|-------|------------------------|
| 1     | 60                     |
| 2     | 90                     |
| 3     | 120                    |
| 4     | 150                    |
| 5+    | +30 per round          |

### Card Point Values

- Joker: 50 points (wild)
- 2: 20 points (wild)
- Ace: 20 points
- K, Q, J, 10, 9, 8: 10 points
- 7, 6, 5, 4: 5 points
- Red 3: -300 points (penalty if held)
- Black 3: -5 points (penalty if held)

### Going Out Requirements

To go out, you must have:
1. ✅ Picked up your foot
2. ✅ Emptied your foot
3. ✅ At least 1 clean book (7+ cards, no wilds)
4. ✅ At least 1 dirty book (7+ cards, with wilds)

## Game Features

- **Modern Synthwave UI** with refined neon effects and professional dark theme
- **AI Opponents** with medium difficulty (3 bots by default)
- **Complete Rule Implementation** based on official Hand & Foot rules
- **Action Log** showing recent game events (collapsible)
- **Visual Feedback** for selected cards, melds, and books
- **Hot Reload** for development (automatically reloads code changes)
- **Random Seed System** for reproducible games
- **Smooth Animations** with fade-in effects for drawn cards
- **Arrow Key Navigation** with visual highlights

## Random Seed System

Each game generates a unique random seed that controls all randomness (deck shuffling, AI decisions). The seed is displayed in the game info panel and printed to the console.

**To replay a specific game:**
1. Note the seed number from the game info panel or console
2. Edit `main.lua` and set `Config.seed = [your_seed_number]`
3. Restart the game

Example:
```lua
Config = {
    seed = 1733363842  -- Use this exact seed to replay
}
```

## Project Structure

```
love-hand-and-foot/
├── main.lua                    # Entry point
├── conf.lua                    # LÖVE config
├── CLAUDE.md                   # Development guide
├── src/
│   ├── card.lua               # Card class
│   ├── deck.lua               # Deck management
│   ├── meld.lua               # Meld validation
│   ├── player.lua             # Player class
│   ├── gamestate.lua          # Game logic & flow
│   ├── ui/
│   │   ├── theme.lua          # Synthwave theme
│   │   └── renderer.lua       # UI rendering
│   └── ai/
│       └── bot.lua            # AI bot strategies
├── lib/
│   ├── flux.lua               # Tweening/animation
│   ├── lume.lua               # Utility functions
│   └── hotswap.lua            # Hot reload system
└── README.md
```

## Technical Details

- **Game Engine**: LÖVE2D 11.x+
- **Language**: Lua
- **Resolution**: 1280x720 (resizable, min 800x600)
- **Players**: 1 human + 3 AI bots (default)

## Credits

Built following the complete Hand & Foot specification with a Balatro-inspired aesthetic.

Developed with Claude Code.
