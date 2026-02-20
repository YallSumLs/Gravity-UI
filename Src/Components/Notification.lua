--[[
    GravityUI :: Notification
    -------------------------
    Toast-style notification system. Slides in from the bottom-right (or top-right),
    shows a progress bar countdown, and auto-dismisses.

    Usage (via Window):
        win:Notify({
            Title    = "Script Loaded",
            Body     = "GravityUI initialized successfully.",
            Duration = 5,    -- seconds (default 4)
            Type     = "Success",  -- "Info" | "Success" | "Warning" | "Error"
        })

    Or create standalone:
        local mgr = Notification.new(screenGui, theme)
        mgr:Send({ Title = "Hello", Body = "World", Type = "Info" })
]]

local Utility = require(script.Parent.Parent.Core.Utility)
local Tween   = require(script.Parent.Parent.Core.Tween)

local NOTIF_W   = 300
local NOTIF_H   = 72
local PADDING   = 14
local GAP       = 8
local MAX_STACK = 5

local TYPE_COLORS = {
    Info    = nil,    -- falls back to Accent
    Success = "Success",
    Warning = "Warning",
    Error   = "Error",
}

local TYPE_ICONS = {
    Info    = "ℹ",
    Success = "✓",
    Warning = "⚠",
    Error   = "✕",
}

local Notification = {}
Notification.__index = Notification

function Notification.new(screenGui: ScreenGui, theme: any)
    local self      = setmetatable({}, Notification)
    self._theme     = theme
    self._gui       = screenGui
    self._stack     = {} :: { Frame }
    self._conns     = {}
    return self
end

--- Sends a new notification.
function Notification:Send(opts: { Title: string, Body: string?, Duration: number?, Type: string? })
    opts = opts or {}
    local theme    = self._theme
    local kind     = opts.Type or "Info"
    local duration = opts.Duration or 4
    local accentKey = TYPE_COLORS[kind]
    local accent    = accentKey and (theme :: any)[accentKey] or theme.Accent
    local icon      = TYPE_ICONS[kind] or "ℹ"

    -- Trim stack
    if #self._stack >= MAX_STACK then
        local oldest = table.remove(self._stack, 1)
        if oldest and oldest.Parent then
            Tween.Play(oldest, { Position = UDim2.new(1, 20, oldest.Position.Y.Scale, oldest.Position.Y.Offset) }, "Close")
            task.delay(0.25, function() oldest:Destroy() end)
        end
    end

    -- Calculate Y position (stacking from bottom-right)
    local idx    = #self._stack
    local startY = -(NOTIF_H + PADDING) + idx * -(NOTIF_H + GAP)

    local card = Utility.Make("Frame", {
        BackgroundColor3   = theme.Surface,
        BorderSizePixel    = 0,
        Size               = UDim2.fromOffset(NOTIF_W, NOTIF_H),
        Position           = UDim2.new(1, NOTIF_W + 20, 1, startY),     -- off-screen right
        ZIndex             = 100,
    }, self._gui)
    Utility.Round(card, UDim.new(0, 8))
    Utility.Stroke(card, theme.Border, 1, 0.3)

    -- Left accent bar
    Utility.Make("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(3, NOTIF_H - 16),
        Position         = UDim2.fromOffset(10, 8),
        ZIndex           = 101,
    }, card)

    -- Icon circle
    local iconCircle = Utility.Make("Frame", {
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.8,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(28, 28),
        Position         = UDim2.fromOffset(20, (NOTIF_H - 28) // 2),
        ZIndex           = 101,
    }, card)
    Utility.Round(iconCircle, UDim.new(1, 0))

    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text         = icon,
        TextColor3   = accent,
        TextSize     = 14,
        FontFace     = Font.fromEnum(Enum.Font.GothamBold),
        Size         = UDim2.new(1, 0, 1, 0),
        ZIndex       = 102,
    }, iconCircle)

    -- Title
    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text         = opts.Title or "Notification",
        TextColor3   = theme.Text,
        TextSize     = 13,
        FontFace     = Font.fromEnum(Enum.Font.GothamBold),
        Size         = UDim2.new(1, -68, 0, 18),
        Position     = UDim2.fromOffset(58, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex       = 101,
    }, card)

    -- Body
    if opts.Body then
        Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text         = opts.Body,
            TextColor3   = theme.TextDim,
            TextSize     = 11,
            FontFace     = Font.fromEnum(Enum.Font.Gotham),
            Size         = UDim2.new(1, -68, 0, 30),
            Position     = UDim2.fromOffset(58, 30),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped  = true,
            ZIndex       = 101,
        }, card)
    end

    -- Progress bar track
    local progressBg = Utility.Make("Frame", {
        BackgroundColor3     = theme.Surface2,
        BackgroundTransparency = 0,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, -20, 0, 2),
        Position             = UDim2.new(0, 10, 1, -6),
        ZIndex               = 102,
    }, card)
    Utility.Round(progressBg, UDim.new(1, 0))

    local progressFill = Utility.Make("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 103,
    }, progressBg)
    Utility.Round(progressFill, UDim.new(1, 0))

    -- Close button (X)
    local closeBtn = Utility.Make("TextButton", {
        BackgroundTransparency = 1,
        Text         = "✕",
        TextColor3   = theme.TextDim,
        TextSize     = 10,
        FontFace     = Font.fromEnum(Enum.Font.GothamBold),
        Size         = UDim2.fromOffset(18, 18),
        Position     = UDim2.new(1, -20, 0, 4),
        AutoButtonColor = false,
        ZIndex       = 103,
    }, card)

    table.insert(self._stack, card)

    -- Slide in
    local targetX = -(NOTIF_W + PADDING)
    Tween.Play(card, { Position = UDim2.new(1, targetX, 1, startY) }, "Notify")

    -- Animate progress bar
    local progTween = Tween.Play(progressFill, { Size = UDim2.new(0, 0, 1, 0) },
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))

    local function dismiss()
        -- Remove from stack
        for i, c in ipairs(self._stack) do
            if c == card then table.remove(self._stack, i); break end
        end
        -- Reposition remaining
        for j, c in ipairs(self._stack) do
            local newY = -(NOTIF_H + PADDING) + (j - 1) * -(NOTIF_H + GAP)
            Tween.Play(c, { Position = UDim2.new(1, targetX, 1, newY) }, "Close")
        end
        -- Slide out
        Tween.Play(card, { Position = UDim2.new(1, NOTIF_W + 20, 1, startY) }, "Close")
        task.delay(0.3, function()
            if card.Parent then card:Destroy() end
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        progTween:Cancel()
        dismiss()
    end)

    -- Auto-dismiss after duration
    task.delay(duration, function()
        if card.Parent then dismiss() end
    end)
end

--- Destroys all active notifications.
function Notification:Destroy()
    for _, card in ipairs(self._stack) do
        if card.Parent then card:Destroy() end
    end
    self._stack = {}
end

return Notification
