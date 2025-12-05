# Quick Start Guide

## Running the Game

```bash
cd /Users/ben/projects/love-hand-and-foot
love .
```

Or simply:
```bash
open -a love /Users/ben/projects/love-hand-and-foot
```

## Quick Controls Reference

### Your Turn - Draw Phase
- Press `D` or `SPACE` to draw 2 cards from the deck
- Press `U` to unlock the discard pile (if you've played down and have 2+ matching cards)

### Your Turn - Meld Phase
- Click on cards in your hand to select them (they'll move up)
- Press `M` to create a new meld with selected cards (needs 3+)
- Press `A` to add selected cards to an existing meld
- Press `C` to clear your selection
- Press `ENTER` to skip melding and go to discard phase

### Your Turn - Discard Phase
- Click a card to select it
- Press `SPACE` or `ENTER` to discard the selected card
- This ends your turn

## Important Rules

### First Turn
1. You must "play down" by melding cards worth the minimum points:
   - Round 1: 60 points
   - Round 2: 90 points
   - Round 3: 120 points
   - And so on... (+30 each round)

2. Once you've played down, you can make any valid melds on future turns

### Making Melds
- Need at least 3 cards of the same rank
- Must have at least 2 natural (non-wild) cards
- Wild cards (2s and Jokers) cannot exceed natural cards
- **Cannot meld 3s!** (Discard them immediately, especially red 3s = -300 points)

### Books (7+ card melds)
- **Clean Book**: 7+ cards with NO wilds = 500 bonus points
- **Dirty Book**: 7+ cards WITH wilds = 300 bonus points
- You need BOTH types to go out!

### Going Out (Winning the Round)
To end the round, you must:
1. Have picked up your foot (happens automatically when your hand empties)
2. Have emptied your foot completely
3. Have at least 1 clean book
4. Have at least 1 dirty book

Then discard your last card to go out!

## Tips for Beginners

1. **Discard 3s immediately** - Red 3s are worth -300 points if held at round end!

2. **Save wild cards** - Use them strategically to complete books

3. **Watch the play-down requirement** - The numbers show cumulative points:
   - Joker = 50
   - 2 = 20
   - Ace = 20
   - K, Q, J, 10, 9, 8 = 10 each
   - 7, 6, 5, 4 = 5 each

4. **Plan your books** - You need both clean AND dirty books to go out

5. **Unlock the discard pile** - If there are good cards in the discard pile and you can unlock it (need 2 matching naturals + already played down), you can take up to 6 cards from it!

## Common First-Turn Strategy

**Example starting hand with these cards:**
- K♥, K♠, K♦ (3 Kings = 30 points)
- A♥, A♠ (2 Aces = 40 points)
- 2♣ (1 wild = 20 points)

**Round 1 needs 60 points:**
- Meld: K♥ + K♠ + K♦ + A♥ + A♠ (50 points) ❌ Not enough!
- Better: K♥ + K♠ + K♦ (30) and A♥ + A♠ + 2♣ (60) ✅ Two melds = 60 points total!

Select all 6 cards and press `M` to create both melds at once!

## Winning the Game

First player to reach 8500 points wins!

Good luck! 🎴
