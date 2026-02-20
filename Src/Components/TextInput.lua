--[[
    GravityUI :: TextInput
    ----------------------
    A styled text input field with focus-glow, placeholder, numeric mode, and callbacks.

    Usage (via Section):
        local inp = sec:Input({
            Label       = "Player Name",
            Placeholder = "Enter name...",
            Default     = "",
            Numeric     = false,
            Callback    = function(text) print("Final:", text) end,
            Changed     = function(text) print("Live:", text) end,
            Disabled    = false,
            Tooltip     = "Enter a Roblox username",
        })
        inp:Set("Roblox")
        print(inp:Get())
]]

local Utility = require(script.Parent.Parent.Core.Utility)
local Tween   = require(script.Parent.Parent.Core.Tween)

local COMP_H = 54
local BOX_H  = 36

local TextInput = {}
TextInput.__index = TextInput

function TextInput.new(parent: Frame, theme: any, tooltip: any?, opts: any)
    opts = opts or {}
    local self       = setmetatable({}, TextInput)
    self._theme      = theme
    self._disabled   = opts.Disabled or false
    self._numeric    = opts.Numeric  or false
    self._value      = opts.Default  or ""
    self._callbacks  = {
        Callback = opts.Callback or function() end,
        Changed  = opts.Changed  or function() end,
    }

    -- Row root
    local root = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, COMP_H),
        ZIndex                 = 13,
    }, parent)
    self._root = root

    -- Label above field
    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Label or "Input",
        TextColor3             = self._disabled and theme.TextDim or theme.Text,
        TextSize               = 11,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, 0, 0, 16),
        Position               = UDim2.fromOffset(0, 2),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 14,
    }, root)

    -- Input container
    local container = Utility.Make("Frame", {
        BackgroundColor3 = theme.Surface2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, BOX_H),
        Position         = UDim2.fromOffset(0, 18),
        ZIndex           = 14,
    }, root)
    Utility.Round(container, UDim.new(0, 6))
    local stroke = Utility.Stroke(container, theme.Border, 1, 0.3)
    self._stroke = stroke

    -- Actual TextBox
    local box = Utility.Make("TextBox", {
        BackgroundTransparency = 1,
        Text                   = self._value,
        PlaceholderText        = opts.Placeholder or "",
        PlaceholderColor3      = theme.TextDim,
        TextColor3             = theme.Text,
        TextSize               = 13,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, -12, 1, 0),
        Position               = UDim2.fromOffset(10, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ClearTextOnFocus       = opts.ClearTextOnFocus ~= false,
        ZIndex                 = 15,
        TextEditable           = not self._disabled,
    }, container)

    self._box = box

    -- Focus glow animation
    box.Focused:Connect(function()
        Tween.Play(stroke, { Color = theme.Accent, Transparency = 0 }, "Hover")
        Tween.Play(container, { BackgroundColor3 = theme.Surface }, "Hover")
    end)

    box.FocusLost:Connect(function(enter)
        Tween.Play(stroke, { Color = theme.Border, Transparency = 0.3 }, "Hover")
        Tween.Play(container, { BackgroundColor3 = theme.Surface2 }, "Hover")

        local text = box.Text
        if self._numeric then
            local n = tonumber(text)
            if n then
                text = tostring(n)
            else
                text = self._value  -- revert if not numeric
                box.Text = text
            end
        end

        self._value = text
        task.spawn(self._callbacks.Callback, text)
    end)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        local text = box.Text
        if self._numeric then
            -- Strip non-numeric characters live
            local cleaned = text:gsub("[^%d%.%-]", "")
            if cleaned ~= text then
                box.Text = cleaned
                return
            end
        end
        self._value = text
        task.spawn(self._callbacks.Changed, text)
    end)

    -- Hover
    container.MouseEnter:Connect(function()
        if box:IsFocused() then return end
        Tween.Play(stroke, { Transparency = 0.1 }, "Hover")
    end)
    container.MouseLeave:Connect(function()
        if box:IsFocused() then return end
        Tween.Play(stroke, { Transparency = 0.3 }, "Hover")
    end)

    -- Tooltip
    if opts.Tooltip and tooltip then
        tooltip:Attach(root, opts.Tooltip)
    end

    return self
end

--- Sets the input text programmatically.
function TextInput:Set(text: string)
    self._value = text
    self._box.Text = text
end

--- Returns the current input text.
function TextInput:Get(): string
    return self._value
end

--- Clears the input.
function TextInput:Clear()
    self:Set("")
end

function TextInput:Destroy()
    self._root:Destroy()
end

return TextInput
