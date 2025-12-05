-- Synthwave/Outrun Theme
-- Neon-soaked 1980s cyberpunk aesthetic

UI = UI or {}
UI.Theme = {}

-- Color palette (Modern Synthwave - cleaner and more refined)
UI.Theme.colors = {
    -- Background colors - sophisticated dark gradients
    background = {0.08, 0.06, 0.12, 1.0},      -- Soft dark purple
    backgroundDark = {0.05, 0.04, 0.08, 1.0},  -- Deeper void
    backgroundLight = {0.12, 0.10, 0.16, 1.0}, -- Elevated surfaces

    -- Refined neon accents - less saturated, more professional
    neonCyan = {0.3, 0.85, 0.95, 1.0},         -- Softer cyan
    neonMagenta = {0.95, 0.35, 0.75, 1.0},     -- Refined magenta
    neonYellow = {0.95, 0.85, 0.35, 1.0},      -- Warmer yellow
    neonGreen = {0.35, 0.90, 0.55, 1.0},       -- Balanced green
    neonOrange = {0.95, 0.55, 0.25, 1.0},      -- Warm orange
    neonPurple = {0.65, 0.40, 0.90, 1.0},      -- Softer purple

    -- Card colors
    cardRed = {0.95, 0.35, 0.55, 1.0},         -- Refined red
    cardBlack = {0.35, 0.80, 0.90, 1.0},       -- Muted cyan
    cardWild = {0.65, 0.40, 0.90, 1.0},        -- Elegant purple
    cardBackground = {0.10, 0.08, 0.14, 1.0},  -- Clean dark base

    -- Individual suit colors (refined palette)
    suitHearts = {0.95, 0.35, 0.55, 1.0},      -- Warm pink
    suitDiamonds = {0.95, 0.55, 0.25, 1.0},    -- Rich orange
    suitClubs = {0.35, 0.90, 0.55, 1.0},       -- Fresh green
    suitSpades = {0.30, 0.85, 0.95, 1.0},      -- Cool cyan

    -- UI element colors - better readability
    textPrimary = {0.95, 0.95, 0.98, 1.0},     -- Soft white
    textSecondary = {0.70, 0.65, 0.75, 0.9},   -- Muted lavender
    textHighlight = {0.95, 0.85, 0.35, 1.0},   -- Warm accent

    -- State colors - more subtle
    selected = {0.95, 0.85, 0.35, 1.0},        -- Warm yellow
    highlighted = {0.95, 0.35, 0.75, 1.0},     -- Soft magenta
    disabled = {0.40, 0.35, 0.45, 0.6},        -- Subtle gray
    frozen = {0.30, 0.75, 0.90, 1.0},          -- Cool blue

    -- Book colors
    cleanBook = {0.35, 0.90, 0.55, 1.0},       -- Success green
    dirtyBook = {0.95, 0.65, 0.30, 1.0},       -- Warm amber

    -- Grid and effects - much more subtle
    gridColor = {0.60, 0.45, 0.70, 0.12},      -- Very faint purple grid
    horizonGlow = {0.75, 0.45, 0.65, 0.3},     -- Soft horizon glow
}

-- Font sizes
UI.Theme.fonts = {
    title = nil,
    large = nil,
    medium = nil,
    small = nil,
    tiny = nil
}

function UI.Theme.loadFonts()
    -- Use LÖVE default font with different sizes
    UI.Theme.fonts.title = love.graphics.newFont(32)
    UI.Theme.fonts.large = love.graphics.newFont(20)  -- Reduced from 24 for card ranks
    UI.Theme.fonts.medium = love.graphics.newFont(18)
    UI.Theme.fonts.small = love.graphics.newFont(14)
    UI.Theme.fonts.tiny = love.graphics.newFont(12)
end

-- Card dimensions
UI.Theme.card = {
    width = 80,
    height = 114, -- Aspect ratio ~0.7
    cornerRadius = 8, -- Softer, modern rounded corners
    spacing = 10,
    selectedOffset = -15, -- Move up when selected
    shadowOffset = 3,
    borderWidth = 2 -- Cleaner, refined border
}

-- Layout dimensions
UI.Theme.layout = {
    padding = 20,
    sectionSpacing = 30,
    buttonHeight = 40,
    buttonWidth = 150,
    logWidth = 300,
    logHeight = 200
}

-- Animation settings
UI.Theme.animation = {
    cardMoveSpeed = 800, -- pixels per second
    cardFlipSpeed = 0.3, -- seconds
    glowPulseSpeed = 2.0, -- cycles per second
    buttonHoverScale = 1.1
}

-- Helper function to draw rounded rectangle
function UI.Theme.drawRoundedRect(mode, x, y, w, h, radius)
    local segments = 16
    love.graphics.push()

    -- Draw main rectangle
    love.graphics.rectangle(mode, x + radius, y, w - 2 * radius, h)
    love.graphics.rectangle(mode, x, y + radius, w, h - 2 * radius)

    -- Draw corners
    local function drawCorner(cx, cy, startAngle)
        if mode == "fill" then
            love.graphics.arc("fill", cx, cy, radius, startAngle, startAngle + math.pi / 2, segments)
        else
            love.graphics.arc("line", cx, cy, radius, startAngle, startAngle + math.pi / 2, segments)
        end
    end

    drawCorner(x + radius, y + radius, math.pi)              -- Top-left
    drawCorner(x + w - radius, y + radius, -math.pi / 2)     -- Top-right
    drawCorner(x + w - radius, y + h - radius, 0)            -- Bottom-right
    drawCorner(x + radius, y + h - radius, math.pi / 2)      -- Bottom-left

    love.graphics.pop()
end

-- Helper function to add subtle glow effect
function UI.Theme.drawGlow(x, y, w, h, color, intensity)
    local prevColor = {love.graphics.getColor()}
    intensity = intensity or 0.5

    -- Refined multi-layer glow with better visibility for highlights
    local layers = intensity > 1.0 and 5 or 3  -- More layers for strong highlights
    local alphaMultiplier = intensity > 1.0 and 0.4 or 0.25  -- Stronger for highlights

    for i = 1, layers do
        local alpha = intensity * (layers + 1 - i) / layers * alphaMultiplier
        love.graphics.setLineWidth(i * 0.5)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        UI.Theme.drawRoundedRect("line", x - i, y - i, w + i * 2, h + i * 2, UI.Theme.card.cornerRadius)
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(prevColor)
end

-- Helper to get pulsing glow intensity
function UI.Theme.getGlowIntensity(time)
    return 0.3 + 0.2 * math.sin(time * UI.Theme.animation.glowPulseSpeed * math.pi * 2)
end

-- Initialize theme
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

return UI.Theme
