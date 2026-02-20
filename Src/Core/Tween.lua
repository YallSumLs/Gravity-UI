--[[
    GravityUI :: Tween
    ------------------
    A TweenService wrapper that provides consistent animation presets
    for all GravityUI components.

    Usage:
        Tween.Play(instance, { BackgroundColor3 = Color3.new(1,0,0) }, "Hover")
        Tween.Play(instance, { Size = UDim2.new(...) }, "Open")
]]

local TweenService = game:GetService("TweenService")

local Tween = {}

--- Preset tween infos used throughout the library.
Tween.Presets = {
    -- Fast, snappy transitions (hover, focus)
    Hover  = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Ultra-fast press feedback
    Press  = TweenInfo.new(0.08, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Opening panels, dropdowns, expanding elements
    Open   = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Closing panels, collapsing elements
    Close  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Value changes (slider, color, etc.)
    Value  = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Notification slide-in/out
    Notify = TweenInfo.new(0.30, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    -- Generic slow fade
    Fade   = TweenInfo.new(0.25, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
    -- Modal appear
    Modal  = TweenInfo.new(0.20, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

--- Plays a tween on an instance and returns the Tween object.
--- @param instance Instance — The Roblox instance to tween.
--- @param props    table    — Property => goal value pairs.
--- @param preset   string   — Key into Tween.Presets, or a TweenInfo directly.
--- @param andPlay  boolean? — If false, returns tween without playing. Default true.
function Tween.Play(
    instance: Instance,
    props: { [string]: any },
    preset: string | TweenInfo,
    andPlay: boolean?
): Tween
    local info: TweenInfo
    if typeof(preset) == "TweenInfo" then
        info = preset
    else
        info = Tween.Presets[preset] or Tween.Presets.Hover
    end
    local tween = TweenService:Create(instance, info, props)
    if andPlay ~= false then
        tween:Play()
    end
    return tween
end

--- Cancels all tweens on an instance and immediately applies property values.
function Tween.Set(instance: Instance, props: { [string]: any })
    for prop, value in pairs(props) do
        pcall(function()
            (instance :: any)[prop] = value
        end)
    end
end

--- Creates a quick fade-in: sets Transparency to 0.
function Tween.FadeIn(instance: Instance, duration: number?)
    local info = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    return Tween.Play(instance, { BackgroundTransparency = 0 }, info)
end

--- Creates a quick fade-out: sets Transparency to 1.
function Tween.FadeOut(instance: Instance, duration: number?)
    local info = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    return Tween.Play(instance, { BackgroundTransparency = 1 }, info)
end

return Tween
