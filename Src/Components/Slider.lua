--[[
    GravityUI :: Slider
    -------------------
    A draggable value slider with animated fill track and value label.

    Usage (via Section):
        local sld = sec:Slider({
            Label   = "Speed",
            Min     = 0,
            Max     = 200,
            Default = 50,
            Step    = 5,
            Suffix  = " studs/s",
            Callback = function(v) game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v end,
        })
        sld:Set(100)
        print(sld:Get())
]]

local UserInputService = game:GetService("UserInputService")
local Utility          = require(script.Parent.Parent.Core.Utility)
local Tween            = require(script.Parent.Parent.Core.Tween)

local COMP_H   = 54
local TRACK_H  = 5
local KNOB_D   = 16
local SIDE_PAD = 8

local Slider = {}
Slider.__index = Slider

function Slider.new(parent: Frame, theme: any, tooltip: any?, opts: any)
    opts = opts or {}
    local self       = setmetatable({}, Slider)
    self._theme      = theme
    self._min        = opts.Min or 0
    self._max        = opts.Max or 100
    self._step       = opts.Step or 0   -- 0 = continuous
    self._disabled   = opts.Disabled or false
    self._callbacks  = { opts.Callback or function() end }
    self._dragging   = false

    -- Snap value to step
    local function snap(v: number): number
        v = Utility.Clamp(v, self._min, self._max)
        if self._step and self._step > 0 then
            v = math.round(v / self._step) * self._step
        end
        -- Round to avoid floating point noise
        return math.round(v * 1000) / 1000
    end

    self._value = snap(opts.Default or self._min)

    -- Row root
    local root = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, COMP_H),
        ZIndex                 = 13,
    }, parent)
    self._root = root

    -- Top row: label + value display
    local topRow = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 20),
        ZIndex                 = 13,
    }, root)

    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Label or "Slider",
        TextColor3             = self._disabled and theme.TextDim or theme.Text,
        TextSize               = 13,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(0.6, 0, 1, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 14,
    }, topRow)

    local valueLabel = Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = (opts.Prefix or "") .. tostring(self._value) .. (opts.Suffix or ""),
        TextColor3             = theme.Accent,
        TextSize               = 12,
        FontFace               = Font.fromEnum(Enum.Font.GothamBold),
        Size                   = UDim2.new(0.4, 0, 1, 0),
        Position               = UDim2.new(0.6, 0, 0, 0),
        TextXAlignment         = Enum.TextXAlignment.Right,
        ZIndex                 = 14,
    }, topRow)

    -- Track area
    local trackArea = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, KNOB_D + 4),
        Position               = UDim2.fromOffset(0, 24),
        ZIndex                 = 13,
    }, root)

    -- Track background
    local trackBg = Utility.Make("Frame", {
        BackgroundColor3 = theme.Surface2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, TRACK_H),
        Position         = UDim2.new(0, 0, 0.5, -TRACK_H // 2),
        ZIndex           = 14,
    }, trackArea)
    Utility.Round(trackBg, UDim.new(1, 0))
    Utility.Stroke(trackBg, theme.Border, 1, 0.5)

    -- Filled track
    local trackFill = Utility.Make("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 0, 1, 0),
        ZIndex           = 15,
    }, trackBg)
    Utility.Round(trackFill, UDim.new(1, 0))

    -- Knob
    local knob = Utility.Make("Frame", {
        BackgroundColor3 = theme.Text,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(KNOB_D, KNOB_D),
        Position         = UDim2.fromOffset(0, (TRACK_H - KNOB_D) // 2),
        ZIndex           = 16,
    }, trackBg)
    Utility.Round(knob, UDim.new(1, 0))
    Utility.Stroke(knob, theme.Accent, 2, 0)

    -- Invisible hit area
    local hitArea = Utility.Make("TextButton", {
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.new(1, 0, 1, 0),
        Position               = UDim2.fromOffset(0, -(KNOB_D // 2 + 4)),
        AutoButtonColor        = false,
        ZIndex                 = 17,
        Active                 = not self._disabled,
    }, trackArea)

    self._valueLabel = valueLabel
    self._trackBg    = trackBg
    self._trackFill  = trackFill
    self._knob       = knob
    self._hitArea    = hitArea
    self._prefix     = opts.Prefix or ""
    self._suffix     = opts.Suffix or ""

    -- Update visual positions
    local function updateVisual(v: number)
        local pct = Utility.Map(v, self._min, self._max, 0, 1)
        local trackW = trackBg.AbsoluteSize.X
        local knobX  = pct * (trackW - KNOB_D)

        trackFill.Size     = UDim2.new(pct, 0, 1, 0)
        knob.Position      = UDim2.fromOffset(knobX, (TRACK_H - KNOB_D) // 2)
        valueLabel.Text    = self._prefix .. tostring(v) .. self._suffix
    end

    -- Drag logic
    local function valueFromMouse(): number
        local mx    = UserInputService:GetMouseLocation().X
        local absL  = trackBg.AbsolutePosition.X
        local absW  = trackBg.AbsoluteSize.X
        local pct   = Utility.Clamp((mx - absL) / absW, 0, 1)
        local raw   = Utility.Lerp(self._min, self._max, pct)
        return snap(raw)
    end

    hitArea.MouseButton1Down:Connect(function()
        if self._disabled then return end
        self._dragging = true
        local v = valueFromMouse()
        self._value = v
        updateVisual(v)
        for _, cb in ipairs(self._callbacks) do task.spawn(cb, v) end
    end)

    self._moveCon = UserInputService.InputChanged:Connect(function(inp)
        if self._dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local v = valueFromMouse()
            if v ~= self._value then
                self._value = v
                updateVisual(v)
                for _, cb in ipairs(self._callbacks) do task.spawn(cb, v) end
            end
        end
    end)

    self._upCon = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            self._dragging = false
        end
    end)

    -- Hover effects
    hitArea.MouseEnter:Connect(function()
        Tween.Play(knob, { Size = UDim2.fromOffset(KNOB_D + 2, KNOB_D + 2) }, "Hover")
    end)
    hitArea.MouseLeave:Connect(function()
        if not self._dragging then
            Tween.Play(knob, { Size = UDim2.fromOffset(KNOB_D, KNOB_D) }, "Hover")
        end
    end)

    -- Tooltip
    if opts.Tooltip and tooltip then
        tooltip:Attach(root, opts.Tooltip)
    end

    -- Initial render (deferred so AbsoluteSize is populated)
    task.defer(function()
        updateVisual(self._value)
    end)

    return self
end

--- Sets the slider value programmatically (fires callbacks).
function Slider:Set(value: number)
    local snap = function(v)
        v = Utility.Clamp(v, self._min, self._max)
        if self._step and self._step > 0 then
            v = math.round(v / self._step) * self._step
        end
        return math.round(v * 1000) / 1000
    end
    self._value = snap(value)
    local pct   = Utility.Map(self._value, self._min, self._max, 0, 1)
    local trackW = self._trackBg.AbsoluteSize.X
    Tween.Play(self._trackFill, { Size = UDim2.new(pct, 0, 1, 0) }, "Value")
    Tween.Play(self._knob,  { Position = UDim2.fromOffset(pct * (trackW - KNOB_D), (TRACK_H - KNOB_D) // 2) }, "Value")
    self._valueLabel.Text = self._prefix .. tostring(self._value) .. self._suffix
    for _, cb in ipairs(self._callbacks) do task.spawn(cb, self._value) end
end

--- Returns the current slider value.
function Slider:Get(): number
    return self._value
end

function Slider:Destroy()
    if self._moveCon then self._moveCon:Disconnect() end
    if self._upCon   then self._upCon:Disconnect()   end
    self._root:Destroy()
end

return Slider
