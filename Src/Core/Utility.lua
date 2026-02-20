--[[
    GravityUI :: Utility
    --------------------
    Shared utility functions used across all GravityUI modules.
]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")

local Utility = {}

-- ─────────────────────────────────────────────
-- Instance Construction
-- ─────────────────────────────────────────────

--- Creates a Roblox instance, applies a property table, and optionally parents it.
--- Understands special keys:
---   "Children"  → table of child instances to parent
---   "Events"    → { EventName = callback } connections
function Utility.Make(className: string, props: { [string]: any }?, parent: Instance?): Instance
    local inst = Instance.new(className)
    if props then
        for key, value in pairs(props) do
            if key == "Children" then
                -- handled after property application
            elseif key == "Events" then
                -- handled after property application
            else
                pcall(function()
                    (inst :: any)[key] = value
                end)
            end
        end
        if props.Children then
            for _, child in ipairs(props.Children) do
                child.Parent = inst
            end
        end
        if props.Events then
            for evtName, fn in pairs(props.Events) do
                pcall(function()
                    (inst :: any)[evtName]:Connect(fn)
                end)
            end
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

--- Applies a set of properties to an existing instance.
function Utility.Apply(inst: Instance, props: { [string]: any }): Instance
    for key, value in pairs(props) do
        pcall(function()
            (inst :: any)[key] = value
        end)
    end
    return inst
end

--- Adds a UICorner to a GuiObject.
function Utility.Round(inst: GuiObject, radius: UDim?): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 6)
    corner.Parent = inst
    return corner
end

--- Adds a UIStroke to a GuiObject.
function Utility.Stroke(inst: GuiObject, color: Color3, thickness: number?, transparency: number?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = inst
    return stroke
end

--- Adds a UIPadding to a GuiObject with uniform or per-side padding.
function Utility.Pad(inst: GuiObject, all: number?, top: number?, right: number?, bottom: number?, left: number?): UIPadding
    local pad = Instance.new("UIPadding")
    if all then
        pad.PaddingTop    = UDim.new(0, all)
        pad.PaddingRight  = UDim.new(0, all)
        pad.PaddingBottom = UDim.new(0, all)
        pad.PaddingLeft   = UDim.new(0, all)
    else
        if top    then pad.PaddingTop    = UDim.new(0, top)    end
        if right  then pad.PaddingRight  = UDim.new(0, right)  end
        if bottom then pad.PaddingBottom = UDim.new(0, bottom) end
        if left   then pad.PaddingLeft   = UDim.new(0, left)   end
    end
    pad.Parent = inst
    return pad
end

--- Adds a UIListLayout to a GuiObject.
function Utility.List(inst: GuiObject, spacing: number?, dir: Enum.FillDirection?, align: Enum.HorizontalAlignment?): UIListLayout
    local layout = Instance.new("UIListLayout")
    layout.Padding         = UDim.new(0, spacing or 4)
    layout.FillDirection   = dir or Enum.FillDirection.Vertical
    layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
    layout.SortOrder       = Enum.SortOrder.LayoutOrder
    layout.Parent          = inst
    return layout
end

-- ─────────────────────────────────────────────
-- Math Helpers
-- ─────────────────────────────────────────────

function Utility.Clamp(v: number, min: number, max: number): number
    return math.max(min, math.min(max, v))
end

function Utility.Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

--- Maps a value from one range into another.
function Utility.Map(v: number, inMin: number, inMax: number, outMin: number, outMax: number): number
    if inMax == inMin then return outMin end
    return outMin + (v - inMin) / (inMax - inMin) * (outMax - outMin)
end

--- Rounds a number to a given number of decimal places.
function Utility.RoundTo(v: number, decimals: number): number
    local factor = 10 ^ decimals
    return math.round(v * factor) / factor
end

-- ─────────────────────────────────────────────
-- Table Helpers
-- ─────────────────────────────────────────────

--- Deep-merges `override` into a shallow copy of `base`. Returns the merged table.
function Utility.Merge<T>(base: T, override: { [string]: any }?): T
    local result = {}
    for k, v in pairs(base :: any) do
        result[k] = v
    end
    if override then
        for k, v in pairs(override) do
            result[k] = v
        end
    end
    return result :: T
end

function Utility.Contains<T>(arr: { T }, value: T): boolean
    for _, v in ipairs(arr) do
        if v == value then return true end
    end
    return false
end

function Utility.Filter<T>(arr: { T }, fn: (T) -> boolean): { T }
    local result = {}
    for _, v in ipairs(arr) do
        if fn(v) then
            table.insert(result, v)
        end
    end
    return result
end

-- ─────────────────────────────────────────────
-- Dragging Utility
-- ─────────────────────────────────────────────

--- Makes a GuiObject draggable by hooking onto a drag handle.
--- @param handle   GuiObject — What the user clicks on to drag.
--- @param target   GuiObject — What moves (usually the parent window).
--- @param onMove   function? — Called each frame while dragging (optional).
function Utility.MakeDraggable(handle: GuiObject, target: GuiObject, onMove: ((UDim2) -> ())?): () -> ()
    local dragging    = false
    local dragStart   = Vector2.zero
    local startPos    = UDim2.new()

    local conDown = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
        end
    end)

    local conMove = UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            target.Position = newPos
            if onMove then onMove(newPos) end
        end
    end)

    local conUp = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Return cleanup function
    return function()
        conDown:Disconnect()
        conMove:Disconnect()
        conUp:Disconnect()
    end
end

-- ─────────────────────────────────────────────
-- Mouse Position Helper
-- ─────────────────────────────────────────────

--- Returns current mouse position as Vector2.
function Utility.MousePosition(): Vector2
    return UserInputService:GetMouseLocation()
end

-- ─────────────────────────────────────────────
-- Text Size
-- ─────────────────────────────────────────────

--- Returns the bounds of a text string for a given font and size.
function Utility.GetTextSize(text: string, size: number, font: Font | Enum.Font, maxWidth: number?): Vector2
    local fontFace = typeof(font) == "EnumItem"
        and Font.fromEnum(font :: Enum.Font)
        or font :: Font
    return TextService:GetTextSize(
        text, size, fontFace :: any,
        Vector2.new(maxWidth or math.huge, math.huge)
    )
end

-- ─────────────────────────────────────────────
-- Cleanup / Connection Tracking
-- ─────────────────────────────────────────────

--- Creates a Janitor-like cleanup list.
--- Usage:
---   local clean = Utility.Cleaner()
---   clean:Add(instance)
---   clean:Add(connection)
---   clean:Add(function() end)
---   clean:Clean()  -- destroys / disconnects everything
function Utility.Cleaner()
    local items = {}
    local cleaner = {}

    function cleaner:Add(item: Instance | RBXScriptConnection | () -> ()): any
        table.insert(items, item)
        return item
    end

    function cleaner:Clean()
        for _, item in ipairs(items) do
            if typeof(item) == "Instance" then
                item:Destroy()
            elseif typeof(item) == "RBXScriptConnection" then
                item:Disconnect()
            elseif typeof(item) == "function" then
                item()
            end
        end
        items = {}
    end

    return cleaner
end

-- ─────────────────────────────────────────────
-- Keycode Display
-- ─────────────────────────────────────────────

local KEY_NAMES: { [Enum.KeyCode]: string } = {
    [Enum.KeyCode.LeftControl]  = "LCtrl",
    [Enum.KeyCode.RightControl] = "RCtrl",
    [Enum.KeyCode.LeftShift]    = "LShift",
    [Enum.KeyCode.RightShift]   = "RShift",
    [Enum.KeyCode.LeftAlt]      = "LAlt",
    [Enum.KeyCode.RightAlt]     = "RAlt",
    [Enum.KeyCode.Return]       = "Enter",
    [Enum.KeyCode.BackSpace]    = "Backspace",
    [Enum.KeyCode.Tab]          = "Tab",
    [Enum.KeyCode.CapsLock]     = "Caps",
    [Enum.KeyCode.Escape]       = "Esc",
    [Enum.KeyCode.Space]        = "Space",
    [Enum.KeyCode.Delete]       = "Del",
    [Enum.KeyCode.Insert]       = "Ins",
    [Enum.KeyCode.Home]         = "Home",
    [Enum.KeyCode.End]          = "End",
    [Enum.KeyCode.PageUp]       = "PgUp",
    [Enum.KeyCode.PageDown]     = "PgDn",
    [Enum.KeyCode.Up]           = "↑",
    [Enum.KeyCode.Down]         = "↓",
    [Enum.KeyCode.Left]         = "←",
    [Enum.KeyCode.Right]        = "→",
}

--- Returns a human-readable name for a KeyCode.
function Utility.KeyName(key: Enum.KeyCode): string
    return KEY_NAMES[key] or tostring(key):gsub("Enum.KeyCode.", "")
end

return Utility
