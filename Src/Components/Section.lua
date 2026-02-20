--[[
    GravityUI :: Section
    --------------------
    A visual grouping card that contains UI components.

    Usage (via Tab):
        local sec = tab:Section("Combat")
        sec:Button({ Label = "Silent Aim", Callback = function() print("!") end })
        sec:Toggle({ Label = "ESP", Default = true, Callback = function(v) end })
]]

local Utility = require(script.Parent.Parent.Core.Utility)

-- Lazily required to avoid circular deps
local Components = {} :: { [string]: any }

local function loadComponent(name: string)
    if not Components[name] then
        Components[name] = require(script.Parent[name])
    end
    return Components[name]
end

local Section = {}
Section.__index = Section

--- @param parent   Frame    — Parent frame (Tab's scroll frame)
--- @param theme    table    — GravityUI theme
--- @param tooltip  any?     — Tooltip manager
--- @param title    string?  — Optional header label
--- @param noFrame  boolean? — If true, no surface card, just stacked items
function Section.new(parent: Frame, theme: any, tooltip: any?, title: string?, noFrame: boolean?)
    local self      = setmetatable({}, Section)
    self._theme     = theme
    self._tooltip   = tooltip
    self._items     = {}
    self._order     = 0

    local wrapper = Utility.Make("Frame", {
        Name                 = "Section",
        BackgroundTransparency = noFrame and 1 or 0,
        BackgroundColor3     = noFrame and theme.Background or theme.Surface,
        BorderSizePixel      = 0,
        AutomaticSize        = Enum.AutomaticSize.Y,
        Size                 = UDim2.new(1, 0, 0, 0),
        ZIndex               = 12,
    }, parent)

    if not noFrame then
        Utility.Round(wrapper, UDim.new(0, 6))
        Utility.Stroke(wrapper, theme.Border, 1, 0.4)
    end

    Utility.Pad(wrapper, nil, noFrame and 0 or 12, noFrame and 0 or 12, noFrame and 0 or 12, noFrame and 0 or 12)

    local itemList = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1, 0, 0, 0),
        ZIndex                 = 12,
    }, wrapper)

    local startY = 0

    if title then
        -- Section header label
        local hdr = Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = title,
            TextColor3             = theme.TextDim,
            TextSize               = 11,
            FontFace               = Font.fromEnum(Enum.Font.GothamBold),
            Size                   = UDim2.new(1, 0, 0, 20),
            TextXAlignment         = Enum.TextXAlignment.Left,
            LayoutOrder            = 0,
            ZIndex                 = 13,
        }, itemList)

        -- Separator line
        Utility.Make("Frame", {
            BackgroundColor3 = theme.Border,
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, 1),
            LayoutOrder      = 1,
            ZIndex           = 13,
        }, itemList)

        startY = 28
    end

    Utility.List(itemList, 6, Enum.FillDirection.Vertical)
    self._wrapper  = wrapper
    self._itemList = itemList
    self._startOrder = title and 2 or 0

    return self
end

function Section:_nextOrder(): number
    self._order += 1
    return self._startOrder + self._order
end

-- ── Component factory helper ──────────────────────────────────────────────

local function addComp(self, componentName: string, opts: any)
    local comp = loadComponent(componentName)
    local item = comp.new(self._itemList, self._theme, self._tooltip, opts)
    if item._root then item._root.LayoutOrder = self:_nextOrder() end
    table.insert(self._items, item)
    return item
end

--- Adds a Button to the section.
--- @param opts { Label, Callback, Description, Disabled, Tooltip }
function Section:Button(opts: any): any
    return addComp(self, "Button", opts)
end

--- Adds a Toggle to the section.
--- @param opts { Label, Default, Callback, Changed, Description, Disabled, Tooltip }
function Section:Toggle(opts: any): any
    return addComp(self, "Toggle", opts)
end

--- Adds a Slider to the section.
--- @param opts { Label, Min, Max, Default, Step, Prefix, Suffix, Callback, Disabled, Tooltip }
function Section:Slider(opts: any): any
    return addComp(self, "Slider", opts)
end

--- Adds a Dropdown to the section.
--- @param opts { Label, Values, Default, Multi, Callback, Disabled, Tooltip }
function Section:Dropdown(opts: any): any
    return addComp(self, "Dropdown", opts)
end

--- Adds a TextInput to the section.
--- @param opts { Label, Placeholder, Default, Numeric, Callback, Changed, Disabled, Tooltip }
function Section:Input(opts: any): any
    return addComp(self, "TextInput", opts)
end

--- Adds a Keybind picker to the section.
--- @param opts { Label, Default, Mode, Callback, Tooltip }
function Section:Keybind(opts: any): any
    return addComp(self, "Keybind", opts)
end

--- Adds a plain text label to the section.
--- @param opts { Text, Color }
function Section:Label(opts: any): any
    opts = opts or {}
    local theme = self._theme
    local lbl = Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Text or "",
        TextColor3             = opts.Color or theme.TextDim,
        TextSize               = 12,
        FontFace               = Font.fromEnum(Enum.Font.Gotham),
        Size                   = UDim2.new(1, 0, 0, 18),
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = true,
        LayoutOrder            = self:_nextOrder(),
        ZIndex                 = 13,
    }, self._itemList)
    return lbl
end

--- Adds a horizontal divider line to the section.
function Section:Divider(): Frame
    local div = Utility.Make("Frame", {
        BackgroundColor3 = self._theme.Border,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 1),
        LayoutOrder      = self:_nextOrder(),
        ZIndex           = 13,
    }, self._itemList)
    return div
end

--- Destroys this section and all its items.
function Section:Destroy()
    for _, item in ipairs(self._items) do
        if item and item.Destroy then item:Destroy() end
    end
    self._wrapper:Destroy()
end

return Section
