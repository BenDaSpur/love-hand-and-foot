# Adding Card Suit Icons

## Quick Setup

### 1. Get Icon Images

You can either:
- **Download free card icons** from sites like:
  - https://opengameart.org/
  - https://itch.io/game-assets/free
  - https://kenney.nl/assets (search "cards")

- **Create your own** using any image editor (32x32 or 64x64 PNG with transparency)

### 2. File Structure

```
love-hand-and-foot/
├── assets/
│   └── suits/
│       ├── hearts.png
│       ├── diamonds.png
│       ├── clubs.png
│       └── spades.png
```

### 3. Code Changes

**Update `src/ui/theme.lua`** - Add to the `init()` function:

```lua
function UI.Theme.init()
    UI.Theme.loadFonts()

    -- Load suit icons
    UI.Theme.suitIcons = {
        hearts = love.graphics.newImage("assets/suits/hearts.png"),
        diamonds = love.graphics.newImage("assets/suits/diamonds.png"),
        clubs = love.graphics.newImage("assets/suits/clubs.png"),
        spades = love.graphics.newImage("assets/suits/spades.png")
    }
end
```

**Update `src/ui/renderer.lua`** - Modify the `drawCard()` function:

Replace the text drawing section with:

```lua
-- Draw rank and suit
love.graphics.setFont(theme.fonts.medium)
local rankStr = Card.RANK_DISPLAY[card.rank] or card.rank

if card.isWild then
    -- Wild card - special styling
    love.graphics.setColor(theme.colors.cardWild)
    love.graphics.printf(rankStr, x + 5, y + 10, w - 10, "center")

    -- Holographic effect
    love.graphics.setColor(theme.colors.neonCyan[1], theme.colors.neonCyan[2],
                          theme.colors.neonCyan[3], 0.3)
    for i = 1, 3 do
        love.graphics.circle("line", x + w / 2, y + h / 2, 10 + i * 5)
    end
else
    -- Draw rank
    love.graphics.setColor(borderColor)
    love.graphics.print(rankStr, x + 10, y + 10)

    -- Draw suit icon
    if card.suit and theme.suitIcons and theme.suitIcons[card.suit] then
        love.graphics.setColor(1, 1, 1, 1)  -- White (no tint)
        local icon = theme.suitIcons[card.suit]
        local iconSize = 24 * scale
        love.graphics.draw(icon, x + w - iconSize - 5, y + 5, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
    end
end
```

### 4. Alternative: Use Unicode with Custom Font

If you want to use Unicode suit symbols, you need a font that supports them:

1. Download a font like **"Noto Sans"** or **"Symbola"**
2. Place it in `assets/fonts/`
3. Load it in theme.lua:

```lua
UI.Theme.fonts.symbols = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 18)
```

4. Use the symbols font when drawing suits:
```lua
love.graphics.setFont(theme.fonts.symbols)
love.graphics.print("♥", x + w - 20, y + 5)  -- Will render correctly
```

## Recommendation

For best results with minimal effort:
1. Use **PNG icons** (more reliable, looks cleaner)
2. Keep them small (32x32 px)
3. Use transparent backgrounds
4. Color them in your image editor (red for hearts/diamonds, black for clubs/spades)

This way you get crisp, clear icons that will always render perfectly!
