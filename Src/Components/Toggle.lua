--[[
    GravityUI :: Toggle
    -------------------
    An animated pill-toggle with a sliding knob.

    Usage (via Section):
        local tog = sec:Toggle({
            Label    = "Aimbot",
            Default  = false,
            Callback = function(value) print("Aimbot:", value) end,
            Tooltip  = "Enables silent aim",
        })
        tog:Set(true)
        print(tog:Get())
]]

local Utility = require(script.Parent.Parent.Core.Utility)
local Tween   = require(script.Parent.Parent.Core.Tween)

local COMP_H    = 38
local PILL_W    = 44
local PILL_H    = 24
local KNOB_D    = 18  -- knob diameter
local KNOB_PAD  = 3   -- knob inset

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent: Frame, theme: any, tooltip: any?, opts: any)
    opts = opts or {}
    local self       = setmetatable({}, Toggle)
    self._theme      = theme
    self._value      = opts.Default or false
    self._disabled   = opts.Disabled or false
    self._callbacks  = {
        Changed  = opts.Changed  or function() end,
        Callback = opts.Callback or function() end,
    }

    -- Row root
    local root = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, COMP_H),
        ZIndex                 = 13,
    }, parent)
    self._root = root

    -- Left label area (clickable too)
    local labelBtn = Utility.Make("TextButton", {
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.new(1, -(PILL_W + 12), 1, 0),
        AutoButtonColor        = false,
        ZIndex                 = 13,
    }, root)

    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Label or "Toggle",
        TextColor3             = self._disabled and theme.TextDim or theme.Text,
        TextSize               = 13,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, 0, 0, 18),
        Position               = UDim2.fromOffset(0, opts.Description and 1 or 10),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 14,
    }, labelBtn)

    if opts.Description then
        Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = opts.Description,
            TextColor3             = theme.TextDim,
            TextSize               = 10,
            FontFace               = Font.fromEnum(Enum.Font.Gotham),
            Size                   = UDim2.new(1, 0, 0, 14),
            Position               = UDim2.fromOffset(0, 21),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 14,
        }, labelBtn)
    end

    -- Pill track
    local pillBg = Utility.Make("Frame", {
        BackgroundColor3     = self._value and theme.Accent or theme.Surface2,
        BorderSizePixel      = 0,
        Size                 = UDim2.fromOffset(PILL_W, PILL_H),
        Position             = UDim2.new(1, -(PILL_W + 2), 0.5, -PILL_H // 2),
        ZIndex               = 14,
    }, root)
    Utility.Round(pillBg, UDim.new(1, 0))
    if not self._value then
        Utility.Stroke(pillBg, theme.Border, 1, 0)
    end

    -- Knob
    local knobX = self._value and (PILL_W - KNOB_D - KNOB_PAD) or KNOB_PAD
    local knob = Utility.Make("Frame", {
        BackgroundColor3 = theme.Text,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(KNOB_D, KNOB_D),
        Position         = UDim2.fromOffset(knobX, KNOB_PAD),
        ZIndex           = 15,
    }, pillBg)
    Utility.Round(knob, UDim.new(1, 0))

    -- Invisible button overlay over the pill
    local pillBtn = Utility.Make("TextButton", {
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.fromOffset(PILL_W, PILL_H),
        Position               = UDim2.new(1, -(PILL_W + 2), 0.5, -PILL_H // 2),
        AutoButtonColor        = false,
        ZIndex                 = 16,
        Active                 = not self._disabled,
    }, root)

    self._pillBg  = pillBg
    self._knob    = knob
    self._pillBtn = pillBtn

    local function applyState(val: boolean, animate: boolean)
        local targetX  = val and (PILL_W - KNOB_D - KNOB_PAD) or KNOB_PAD
        local bgColor  = val and theme.Accent or theme.Surface2
        if animate then
            Tween.Play(knob,   { Position = UDim2.fromOffset(targetX, KNOB_PAD) }, "Value")
            Tween.Play(pillBg, { BackgroundColor3 = bgColor }, "Value")
        else
            knob.Position              = UDim2.fromOffset(targetX, KNOB_PAD)
            pillBg.BackgroundColor3    = bgColor
        end
    end

    local function toggle()
        if self._disabled then return end
        self._value = not self._value
        applyState(self._value, true)
        task.spawn(self._callbacks.Callback, self._value)
        task.spawn(self._callbacks.Changed,  self._value)
    end

    pillBtn.MouseButton1Click:Connect(toggle)
    labelBtn.MouseButton1Click:Connect(toggle)

    -- Hover glow
    pillBtn.MouseEnter:Connect(function()
        if not self._disabled then
            Tween.Play(pillBg, { BackgroundTransparency = 0.1 }, "Hover")
        end
    end)
    pillBtn.MouseLeave:Connect(function()
        Tween.Play(pillBg, { BackgroundTransparency = 0 }, "Hover")
    end)

    -- Tooltip
    if opts.Tooltip and tooltip then
        tooltip:Attach(root, opts.Tooltip)
    end

    applyState(self._value, false)

    return self
end

--- Sets the toggle value programmatically.
function Toggle:Set(value: boolean)
    if self._value == value then return end
    self._value = value
    local targetX = value and (PILL_W - KNOB_D - KNOB_PAD) or KNOB_PAD
    Tween.Play(self._knob,   { Position = UDim2.fromOffset(targetX, KNOB_PAD) }, "Value")
    Tween.Play(self._pillBg, { BackgroundColor3 = value and self._theme.Accent or self._theme.Surface2 }, "Value")
    task.spawn(self._callbacks.Callback, value)
    task.spawn(self._callbacks.Changed,  value)
end

--- Returns the current toggle value.
function Toggle:Get(): boolean
    return self._value
end

--- Enables or disables the toggle.
function Toggle:SetDisabled(disabled: boolean)
    self._disabled  = disabled
    self._pillBtn.Active = not disabled
end

function Toggle:Destroy()
    self._root:Destroy()
end

return Toggle
