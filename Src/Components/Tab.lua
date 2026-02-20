--[[
    GravityUI :: Tab
    ----------------
    A tab content pane managed by Window. Tabs hold Sections which hold components.

    Usage (via Window):
        local tab = win:Tab("Settings", "⚙")
        local section = tab:Section("Aimbot")
        section:Button({ Label = "Fire", Callback = function() end })
]]

local Utility = require(script.Parent.Parent.Core.Utility)
local Section = require(script.Parent.Section)

local Tab = {}
Tab.__index = Tab

--- Creates a new Tab pane in the given content frame.
function Tab.new(contentFrame: Frame, theme: any, tooltip: any?)
    local self   = setmetatable({}, Tab)
    self._theme  = theme
    self._tooltip = tooltip
    self._sections = {}

    -- Tab content scrolling frame
    local frame = Utility.Make("ScrollingFrame", {
        Name                 = "TabContent",
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, 0, 1, 0),
        CanvasSize           = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        ScrollBarThickness   = 3,
        ScrollBarImageColor3 = theme.Border,
        ScrollingDirection   = Enum.ScrollingDirection.Y,
        Visible              = false,
        GroupTransparency    = 1,
        ZIndex               = 11,
        ElasticBehavior      = Enum.ElasticBehavior.Never,
    }, contentFrame)

    Utility.Pad(frame, nil, 14, 14, 14, 14)
    Utility.List(frame, 10, Enum.FillDirection.Vertical)

    self._frame = frame

    return self
end

--- Creates a Section inside this Tab.
--- @param title   string?  — Optional header title for the section.
--- @param noFrame boolean? — If true, renders without a visible surface card.
function Tab:Section(title: string?, noFrame: boolean?): any
    local sec = Section.new(self._frame, self._theme, self._tooltip, title, noFrame)
    table.insert(self._sections, sec)
    return sec
end

--- Destroys the tab and all its sections.
function Tab:Destroy()
    for _, sec in ipairs(self._sections) do
        if sec.Destroy then sec:Destroy() end
    end
    self._frame:Destroy()
end

return Tab
