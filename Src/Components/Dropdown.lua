--[[
    GravityUI :: Dropdown
    ---------------------
    An animated dropdown supporting single-select and multi-select modes.

    Usage (via Section):
        local dd = sec:Dropdown({
            Label    = "Team",
            Values   = { "Red", "Blue", "Green" },
            Default  = "Red",
            Multi    = false,
            Callback = function(v) print("Selected:", v) end,
        })
        dd:Set("Blue")
        print(dd:Get())
]]

local UserInputService = game:GetService("UserInputService")
local Utility          = require(script.Parent.Parent.Core.Utility)
local Tween            = require(script.Parent.Parent.Core.Tween)

local COMP_H    = 38
local HDR_H     = 36
local ITEM_H    = 32
local MAX_VIS   = 6
local ANIM_T    = 0.20

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent: Frame, theme: any, tooltip: any?, opts: any)
    opts = opts or {}
    local self       = setmetatable({}, Dropdown)
    self._theme      = theme
    self._multi      = opts.Multi or false
    self._values     = opts.Values or {}
    self._disabled   = opts.Disabled or false
    self._open       = false
    self._callbacks  = { opts.Callback or function() end }
    self._conns      = {}

    -- Normalise default selection
    if self._multi then
        self._selected = {}
        if opts.Default and type(opts.Default) == "table" then
            for _, v in ipairs(opts.Default) do self._selected[v] = true end
        end
    else
        self._selected = opts.Default or (self._values[1] or nil)
    end

    -- Outer wrapper (expands with dropdown open)
    local wrapper = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, COMP_H),
        ClipsDescendants       = false,
        ZIndex                 = 14,
    }, parent)
    self._root = wrapper

    -- Header bar (always visible)
    local header = Utility.Make("Frame", {
        BackgroundColor3 = theme.Surface2,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, HDR_H),
        ZIndex           = 14,
    }, wrapper)
    Utility.Round(header, UDim.new(0, 6))
    Utility.Stroke(header, theme.Border, 1, 0.3)

    -- Label
    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Label or "Select...",
        TextColor3             = theme.TextDim,
        TextSize               = 11,
        FontFace               = Font.fromEnum(Enum.Font.Gotham),
        Size                   = UDim2.fromOffset(120, 14),
        Position               = UDim2.fromOffset(10, 3),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 15,
    }, header)

    -- Current value display
    local currentLabel = Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = self:_displayText(),
        TextColor3             = theme.Text,
        TextSize               = 12,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, -40, 0, 16),
        Position               = UDim2.fromOffset(10, 17),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 15,
    }, header)
    self._currentLabel = currentLabel

    -- Chevron icon
    local chevron = Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = "▾",
        TextColor3             = theme.TextDim,
        TextSize               = 14,
        FontFace               = Font.fromEnum(Enum.Font.GothamBold),
        Size                   = UDim2.fromOffset(20, HDR_H),
        Position               = UDim2.new(1, -24, 0, 0),
        ZIndex                 = 15,
    }, header)
    self._chevron = chevron

    -- Click area over header
    local hdrBtn = Utility.Make("TextButton", {
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.new(1, 0, 1, 0),
        AutoButtonColor        = false,
        ZIndex                 = 16,
        Active                 = not self._disabled,
    }, header)

    -- Dropdown panel (below header, clipped)
    local panel = Utility.Make("Frame", {
        BackgroundColor3   = theme.Surface2,
        BorderSizePixel    = 0,
        Size               = UDim2.new(1, 0, 0, 0),
        Position           = UDim2.fromOffset(0, HDR_H + 3),
        ClipsDescendants   = true,
        ZIndex             = 18,
    }, wrapper)
    Utility.Round(panel, UDim.new(0, 6))
    Utility.Stroke(panel, theme.Border, 1, 0.3)

    local scrollFrame = Utility.Make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        CanvasSize             = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = theme.Border,
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        ZIndex                 = 19,
        ElasticBehavior        = Enum.ElasticBehavior.Never,
    }, panel)
    Utility.Pad(scrollFrame, 4)
    Utility.List(scrollFrame, 2, Enum.FillDirection.Vertical)

    self._panel  = panel
    self._scroll = scrollFrame
    self._items  = {}

    -- Populate items
    self:_buildItems()

    -- Open/Close logic
    local function setOpen(open: boolean)
        self._open = open
        local itemCount = math.min(#self._values, MAX_VIS)
        local targetH   = open and (itemCount * ITEM_H + itemCount * 2 + 8) or 0
        local rootH     = open and targetH + HDR_H + 3 or COMP_H

        Tween.Play(panel,   { Size = UDim2.new(1, 0, 0, targetH) }, "Open")
        wrapper.Size = UDim2.new(1, 0, 0, rootH)

        -- Rotate chevron
        local chevronRot = open and 180 or 0
        Tween.Play(chevron, { Rotation = chevronRot }, "Open")
        Tween.Play(header,  { BackgroundColor3 = open and theme.Surface or theme.Surface2 }, "Hover")
    end

    hdrBtn.MouseButton1Click:Connect(function()
        if self._disabled then return end
        setOpen(not self._open)
    end)

    hdrBtn.MouseEnter:Connect(function()
        if not self._open then
            Tween.Play(header, { BackgroundColor3 = theme.Surface }, "Hover")
        end
    end)
    hdrBtn.MouseLeave:Connect(function()
        if not self._open then
            Tween.Play(header, { BackgroundColor3 = theme.Surface2 }, "Hover")
        end
    end)

    -- Tooltip
    if opts.Tooltip and tooltip then
        tooltip:Attach(wrapper, opts.Tooltip)
    end

    return self
end

function Dropdown:_displayText(): string
    if self._multi then
        local selected = {}
        for v in pairs(self._selected) do table.insert(selected, v) end
        if #selected == 0 then return "None selected" end
        return table.concat(selected, ", ")
    else
        return self._selected and tostring(self._selected) or "None"
    end
end

function Dropdown:_buildItems()
    -- Clear existing
    for _, item in ipairs(self._items) do item:Destroy() end
    self._items = {}

    local theme = self._theme

    for i, value in ipairs(self._values) do
        local isSelected = self._multi
            and self._selected[value]
            or  (self._selected == value)

        local itemBtn = Utility.Make("TextButton", {
            BackgroundColor3     = isSelected and theme.AccentDim or theme.Surface2,
            BackgroundTransparency = isSelected and 0 or 1,
            Text                 = "",
            Size                 = UDim2.new(1, 0, 0, ITEM_H),
            AutoButtonColor      = false,
            ZIndex               = 20,
            LayoutOrder          = i,
        }, self._scroll)
        Utility.Round(itemBtn, UDim.new(0, 4))

        -- Check mark
        local check = Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = isSelected and "✓" or "",
            TextColor3             = theme.Accent,
            TextSize               = 13,
            FontFace               = Font.fromEnum(Enum.Font.GothamBold),
            Size                   = UDim2.fromOffset(20, ITEM_H),
            Position               = UDim2.fromOffset(4, 0),
            ZIndex                 = 21,
        }, itemBtn)

        Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = tostring(value),
            TextColor3             = isSelected and theme.Text or theme.TextDim,
            TextSize               = 12,
            FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
            Size                   = UDim2.new(1, -28, 1, 0),
            Position               = UDim2.fromOffset(24, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 21,
        }, itemBtn)

        itemBtn.MouseEnter:Connect(function()
            Tween.Play(itemBtn, { BackgroundTransparency = 0, BackgroundColor3 = theme.Surface }, "Hover")
        end)
        itemBtn.MouseLeave:Connect(function()
            local sel = self._multi and self._selected[value] or (self._selected == value)
            Tween.Play(itemBtn, {
                BackgroundColor3     = sel and theme.AccentDim or theme.Surface2,
                BackgroundTransparency = sel and 0 or 1,
            }, "Hover")
        end)

        itemBtn.MouseButton1Click:Connect(function()
            self:_selectItem(value)
        end)

        table.insert(self._items, itemBtn)
    end
end

function Dropdown:_selectItem(value: any)
    if self._multi then
        self._selected[value] = not self._selected[value] or nil
    else
        self._selected = value
        -- Close after selection in single mode
        task.defer(function()
            Tween.Play(self._panel, { Size = UDim2.new(1, 0, 0, 0) }, "Close")
            Tween.Play(self._chevron, { Rotation = 0 }, "Close")
            self._open = false
            self._root.Size = UDim2.new(1, 0, 0, COMP_H)
        end)
    end

    self._currentLabel.Text = self:_displayText()
    self:_buildItems()

    for _, cb in ipairs(self._callbacks) do
        task.spawn(cb, self:Get())
    end
end

--- Sets the current selection programmatically.
function Dropdown:Set(value: any)
    if self._multi then
        if type(value) == "table" then
            self._selected = {}
            for _, v in ipairs(value) do self._selected[v] = true end
        else
            self._selected[value] = true
        end
    else
        self._selected = value
    end
    self._currentLabel.Text = self:_displayText()
    self:_buildItems()
end

--- Returns the current selection (string for single, table for multi).
function Dropdown:Get(): any
    if self._multi then
        local result = {}
        for v in pairs(self._selected) do table.insert(result, v) end
        return result
    else
        return self._selected
    end
end

--- Adds a new option to the dropdown list.
function Dropdown:AddValue(value: any)
    table.insert(self._values, value)
    self:_buildItems()
end

--- Removes an option from the dropdown list.
function Dropdown:RemoveValue(value: any)
    for i, v in ipairs(self._values) do
        if v == value then
            table.remove(self._values, i)
            break
        end
    end
    if not self._multi and self._selected == value then
        self._selected = self._values[1] or nil
    elseif self._multi then
        self._selected[value] = nil
    end
    self._currentLabel.Text = self:_displayText()
    self:_buildItems()
end

function Dropdown:Destroy()
    for _, item in ipairs(self._items) do item:Destroy() end
    self._root:Destroy()
end

return Dropdown
