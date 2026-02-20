--[[
    GravityUI :: Tooltip
    --------------------
    A hover-tooltip manager. Shows a styled tooltip label near the cursor
    whenever the user hovers over a registered UI element.

    Usage:
        local Tooltip = require(...)
        local mgr = Tooltip.new(screenGui, theme)
        mgr:Attach(myButton, "Click to confirm the action")
        mgr:Destroy()
]]

local UserInputService = game:GetService("UserInputService")
local Utility          = require(script.Parent.Utility)
local Tween            = require(script.Parent.Tween)

local PADDING     = 10   -- px offset from cursor
local SHOW_DELAY  = 0.35 -- seconds before tooltip appears
local FONT_SIZE   = 12
local CORNER_R    = UDim.new(0, 4)

local Tooltip = {}
Tooltip.__index = Tooltip

export type TooltipManager = {
    Attach:  (self: TooltipManager, element: GuiObject, text: string) -> (),
    Detach:  (self: TooltipManager, element: GuiObject) -> (),
    Destroy: (self: TooltipManager) -> (),
}

--- Creates a new TooltipManager.
--- @param container ScreenGui  — The ScreenGui that will host the tooltip frame.
--- @param theme     Theme      — GravityUI theme table.
function Tooltip.new(container: ScreenGui, theme: any): TooltipManager
    local self    = setmetatable({}, Tooltip)
    self._theme   = theme
    self._conns   = {} :: { [GuiObject]: { RBXScriptConnection } }
    self._timer   = nil :: thread?
    self._visible = false

    -- Build the tooltip frame (always on top, ZIndex high)
    local frame = Utility.Make("Frame", {
        Name                 = "GravityTooltip",
        BackgroundColor3     = theme.Surface2,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.fromOffset(0, 0),
        Position             = UDim2.fromOffset(0, 0),
        ZIndex               = 999,
        AutomaticSize        = Enum.AutomaticSize.XY,
    }, container)

    Utility.Round(frame, CORNER_R)
    Utility.Stroke(frame, theme.Border, 1, 0.4)
    Utility.Pad(frame, nil, 5, 10, 5, 10)

    local label = Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = "",
        TextColor3             = theme.TextDim,
        TextSize               = FONT_SIZE,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        AutomaticSize          = Enum.AutomaticSize.XY,
        RichText               = true,
        ZIndex                 = 999,
    }, frame)

    self._frame = frame
    self._label = label

    -- Follow cursor while visible
    self._moveCon = UserInputService.InputChanged:Connect(function(input)
        if not self._visible then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local mx = input.Position.X + PADDING
            local my = input.Position.Y + PADDING
            frame.Position = UDim2.fromOffset(mx, my)
        end
    end)

    return self :: any
end

local function setVisible(self, visible: boolean, text: string?)
    if visible and text then
        self._label.Text = text
        self._frame.BackgroundTransparency = 0
        Tween.Play(self._frame, { BackgroundTransparency = 0 }, "Hover")
        self._visible = true
    else
        Tween.Play(self._frame, { BackgroundTransparency = 1 }, "Close")
        self._visible = false
    end
end

--- Attaches a tooltip to a GuiObject. Text can include RichText tags.
function Tooltip:Attach(element: GuiObject, text: string)
    if self._conns[element] then
        self:Detach(element)
    end

    local conns = {}

    table.insert(conns, element.MouseEnter:Connect(function()
        -- Cancel any pending hide
        if self._timer then
            task.cancel(self._timer)
            self._timer = nil
        end
        -- Delay before showing
        self._timer = task.delay(SHOW_DELAY, function()
            self._timer = nil
            local mouse = UserInputService:GetMouseLocation()
            self._frame.Position = UDim2.fromOffset(mouse.X + PADDING, mouse.Y + PADDING)
            setVisible(self, true, text)
        end)
    end))

    table.insert(conns, element.MouseLeave:Connect(function()
        if self._timer then
            task.cancel(self._timer)
            self._timer = nil
        end
        setVisible(self, false)
    end))

    self._conns[element] = conns
end

--- Detaches the tooltip from a GuiObject.
function Tooltip:Detach(element: GuiObject)
    local conns = self._conns[element]
    if conns then
        for _, c in ipairs(conns) do c:Disconnect() end
        self._conns[element] = nil
    end
end

--- Destroys the tooltip manager and all connections.
function Tooltip:Destroy()
    if self._timer then task.cancel(self._timer) end
    if self._moveCon then self._moveCon:Disconnect() end
    for element in pairs(self._conns) do
        self:Detach(element)
    end
    if self._frame then self._frame:Destroy() end
end

return Tooltip
