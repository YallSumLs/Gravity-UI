--[[
    GravityUI :: Theme
    ------------------
    The theme engine for GravityUI. Provides two built-in themes (Dark and Light)
    and a factory for creating custom themes via overrides.

    Theme tokens available to every component:
        Background  — Main window / outermost background
        Surface     — Cards, sections, component backgrounds
        Surface2    — Slightly lighter layer (input fields, hover states)
        Border      — Subtle outline around surfaces
        Accent      — Primary accent (buttons, filled toggles, sliders)
        AccentDim   — Dimmed/secondary accent (hover fallback, keybind indicator)
        AccentGlow  — Semi-transparent glow color for hover effects
        Text        — Primary text
        TextDim     — Secondary / placeholder text
        Success     — Green feedback color
        Warning     — Amber feedback color
        Error       — Red feedback color
        Shadow      — Drop-shadow color (used with UIGradient / ImageLabel blur)
        Titlebar    — Title bar background (slightly different from Background)
        Sidebar     — Sidebar panel background
        TabActive   — Active tab indicator/background
        TabInactive — Inactive tab text color
]]

local C3 = Color3.fromRGB

export type Theme = {
    Background:  Color3,
    Surface:     Color3,
    Surface2:    Color3,
    Border:      Color3,
    Accent:      Color3,
    AccentDim:   Color3,
    AccentGlow:  Color3,
    Text:        Color3,
    TextDim:     Color3,
    Success:     Color3,
    Warning:     Color3,
    Error:       Color3,
    Shadow:      Color3,
    Titlebar:    Color3,
    Sidebar:     Color3,
    TabActive:   Color3,
    TabInactive: Color3,
    -- Derived helpers
    IsLight: boolean,
}

local Theme = {}

--- Dark theme — Deep space blacks with violet accent.
Theme.Dark = {
    Background  = C3(8,   8,  14),
    Surface     = C3(14,  14, 22),
    Surface2    = C3(20,  20, 32),
    Border      = C3(38,  36, 60),
    Accent      = C3(120, 86, 255),
    AccentDim   = C3(72,  50, 160),
    AccentGlow  = C3(120, 86, 255),   -- used at low alpha
    Text        = C3(238, 236, 255),
    TextDim     = C3(110, 105, 150),
    Success     = C3(72,  210, 130),
    Warning     = C3(255, 182,  70),
    Error       = C3(255,  75,  85),
    Shadow      = C3(0,    0,   0),
    Titlebar    = C3(10,  10,  18),
    Sidebar     = C3(11,  11,  17),
    TabActive   = C3(120, 86, 255),
    TabInactive = C3(90,  86, 120),
    IsLight     = false,
} :: Theme

--- Light theme — Soft lavender whites with deeper violet accent.
Theme.Light = {
    Background  = C3(240, 239, 250),
    Surface     = C3(255, 255, 255),
    Surface2    = C3(232, 230, 245),
    Border      = C3(200, 198, 225),
    Accent      = C3(100, 68, 220),
    AccentDim   = C3(150, 128, 240),
    AccentGlow  = C3(100, 68, 220),
    Text        = C3(16,  14,  40),
    TextDim     = C3(110, 104, 155),
    Success     = C3(34,  160,  90),
    Warning     = C3(200, 130,  20),
    Error       = C3(210,  45,  55),
    Shadow      = C3(180, 175, 210),
    Titlebar    = C3(230, 228, 248),
    Sidebar     = C3(235, 233, 250),
    TabActive   = C3(100, 68, 220),
    TabInactive = C3(130, 122, 175),
    IsLight     = true,
} :: Theme

--- Creates a custom theme by deep-merging overrides into the Dark base.
--- @param base      Theme  — Base theme to start from (Theme.Dark or Theme.Light).
--- @param overrides table  — Partial table of Color3 token overrides.
function Theme.new(base: Theme?, overrides: { [string]: Color3 }?): Theme
    local result = {}
    local src = base or Theme.Dark
    for k, v in pairs(src) do
        result[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            result[k] = v
        end
    end
    return result :: Theme
end

--- Returns a lighter version of a Color3 (HSV brightness boost).
function Theme.Lighten(color: Color3, amount: number): Color3
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.min(1, v + amount))
end

--- Returns a darker version of a Color3 (HSV brightness reduction).
function Theme.Darken(color: Color3, amount: number): Color3
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.max(0, v - amount))
end

--- Returns a Color3 with adjusted alpha as a Color3 (for UIStroke, ImageLabel tinting etc).
--- Note: Roblox uses BackgroundTransparency separately; this just scales the color toward black.
function Theme.Alpha(color: Color3, alpha: number): Color3
    return Color3.new(
        color.R * alpha,
        color.G * alpha,
        color.B * alpha
    )
end

return Theme
