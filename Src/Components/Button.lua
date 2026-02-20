--[[
    GravityUI :: Button
    -------------------
    A styled, clickable button with hover / press animations.

    Usage (via Section):
        sec:Button({
            Label       = "Execute",
            Description = "Run the script",
            Callback    = function() print("clicked!") end,
            Disabled    = false,
            Tooltip     = "Executes the script",
        })
]]

local Utility = require(script.Parent.Parent.Core.Utility)
local Tween   = require(script.Parent.Parent.Core.Tween)

local COMP_H  = 38
local BTN_H   = 30

local Button = {}
Button.__index = Button

function Button.new(parent: Frame, theme: any, tooltip: any?, opts: any)
    opts = opts or {}
    local self      = setmetatable({}, Button)
    self._theme     = theme
    self._callbacks = { opts.Callback }
    self._disabled  = opts.Disabled or false

    -- Row root
    local root = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, COMP_H),
        ZIndex                 = 13,
    }, parent)
    self._root = root

    -- Left: Label + description stack
    local labelFrame = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -110, 1, 0),
        ZIndex                 = 13,
    }, root)

    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Label or "Button",
        TextColor3             = self._disabled and theme.TextDim or theme.Text,
        TextSize               = 13,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, 0, 0, 18),
        Position               = UDim2.fromOffset(0, opts.Description and 1 or 10),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 14,
    }, labelFrame)

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
        }, labelFrame)
    end

    -- Right: Button pill
    local pill = Utility.Make("TextButton", {
        BackgroundColor3     = theme.Accent,
        BackgroundTransparency = self._disabled and 0.6 or 0,
        Text                 = opts.Icon and (opts.Icon .. "  " .. (opts.ButtonLabel or "Click")) or (opts.ButtonLabel or "Click"),
        TextColor3           = theme.Text,
        TextSize             = 12,
        FontFace             = Font.fromEnum(Enum.Font.GothamBold),
        AutoButtonColor      = false,
        Size                 = UDim2.fromOffset(100, BTN_H),
        Position             = UDim2.new(1, -100, 0.5, -BTN_H // 2),
        ZIndex               = 14,
        Active               = not self._disabled,
    }, root)
    Utility.Round(pill, UDim.new(0, 6))

    -- Hover / press animations
    if not self._disabled then
        pill.MouseEnter:Connect(function()
            Tween.Play(pill, { BackgroundColor3 = Tween.Play == nil and theme.Accent or theme.AccentDim }, "Hover")
            Tween.Play(pill, { BackgroundColor3 = theme.AccentDim }, "Hover")
        end)
        pill.MouseLeave:Connect(function()
            Tween.Play(pill, { BackgroundColor3 = theme.Accent }, "Hover")
            Tween.Play(pill, { Size = UDim2.fromOffset(100, BTN_H) }, "Hover")
        end)
        pill.MouseButton1Down:Connect(function()
            Tween.Play(pill, { Size = UDim2.fromOffset(96, 27) }, "Press")
        end)
        pill.MouseButton1Up:Connect(function()
            Tween.Play(pill, { Size = UDim2.fromOffset(100, BTN_H) }, "Press")
        end)
        pill.MouseButton1Click:Connect(function()
            for _, cb in ipairs(self._callbacks) do
                if cb then task.spawn(cb) end
            end
        end)
    end

    -- Tooltip
    if opts.Tooltip and tooltip then
        tooltip:Attach(root, opts.Tooltip)
    end

    self._pill = pill

    return self
end

--- Sets/clears the disabled state at runtime.
function Button:SetDisabled(disabled: boolean)
    self._disabled = disabled
    Tween.Play(self._pill, {
        BackgroundTransparency = disabled and 0.6 or 0,
    }, "Hover")
    self._pill.Active = not disabled
end

--- Adds an additional callback to fire on click.
function Button:OnClick(fn: () -> ()): () -> ()
    table.insert(self._callbacks, fn)
    return function()
        for i, v in ipairs(self._callbacks) do
            if v == fn then table.remove(self._callbacks, i) break end
        end
    end
end

function Button:Destroy()
    self._root:Destroy()
end

return Button
