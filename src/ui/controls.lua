-- Controls help overlay

UI = UI or {}
UI.Controls = {}

function UI.Controls.draw(gameState, x, y)
    local theme = UI.Theme
    if not theme then return end

    local currentPlayer = gameState:getCurrentPlayer()
    if currentPlayer.type ~= "human" then return end

    love.graphics.setFont(theme.fonts.tiny)
    love.graphics.setColor(theme.colors.textSecondary)

    local helpText = ""

    if gameState.turnPhase == "draw" then
        helpText = "[D/SPACE] Draw from deck  |  [U] Unlock discard pile"
    elseif gameState.turnPhase == "meld" then
        helpText = "[Click cards to select]  |  [M] Create meld  |  [A] Add to meld  |  [C] Clear  |  [ENTER] Skip to discard"
    elseif gameState.turnPhase == "discard" then
        helpText = "[Click card to select]  |  [SPACE/ENTER] Discard selected card"
    end

    love.graphics.print(helpText, x, y)
end

return UI.Controls
