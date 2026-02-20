--[[
    GravityUI :: Window
    -------------------
    The main container component. Creates a draggable, resizable window
    with a sidebar for tabs and a content area on the right.

    Usage:
        local win = Window.new(screenGui, {
            Title   = "My Script",
            Theme   = Theme.Dark,
            Size    = Vector2.new(620, 480),
            Keybind = Enum.KeyCode.RightControl,
        })
        local tab = win:Tab("General", "⚙")
        win:Notify({ Title = "Hello!", Body = "Welcome.", Type = "Success" })
        win:Destroy()
]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Utility      = require(script.Parent.Parent.Core.Utility)
local Tween        = require(script.Parent.Parent.Core.Tween)
local Theme        = require(script.Parent.Parent.Core.Theme)
local Tooltip      = require(script.Parent.Parent.Core.Tooltip)
local Tab          = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)

local SIDEBAR_W    = 160
local TITLEBAR_H   = 40
local MIN_W        = 520
local MIN_H        = 360

local Window = {}
Window.__index = Window

export type WindowOptions = {
    Title:        string?,
    Subtitle:     string?,
    Theme:        any?,       -- Theme table (Theme.Dark or Theme.Light or custom)
    Size:         Vector2?,
    Position:     Vector2?,   -- nil = centered
    Resizable:    boolean?,
    Keybind:      Enum.KeyCode?,
    Footer:       string?,
    LogoId:       string?,    -- rbxassetid:// string (optional icon)
}

--- Creates a new GravityUI Window.
function Window.new(screenGui: ScreenGui, opts: WindowOptions)
    opts = opts or {}
    local self = setmetatable({}, Window)

    self._theme    = opts.Theme or Theme.Dark
    self._tabs     = {} :: { any }
    self._tabBtns  = {} :: { Frame }
    self._activeTab = nil
    self._visible  = true
    self._keybind  = opts.Keybind or Enum.KeyCode.RightControl
    self._cleaner  = Utility.Cleaner()
    self._notifyMgr = nil   -- set after construction

    local theme    = self._theme
    local sw = opts.Size and opts.Size.X or 620
    local sh = opts.Size and opts.Size.Y or 460

    -- ── Root Frame ───────────────────────────────────────────────────────────
    local root = Utility.Make("Frame", {
        Name                 = "GravityWindow",
        BackgroundColor3     = theme.Background,
        BorderSizePixel      = 0,
        Size                 = UDim2.fromOffset(sw, sh),
        Position             = opts.Position
            and UDim2.fromOffset(opts.Position.X, opts.Position.Y)
            or  UDim2.new(0.5, -sw // 2, 0.5, -sh // 2),
        ClipsDescendants     = false,
        ZIndex               = 10,
    }, screenGui)
    Utility.Round(root, UDim.new(0, 8))
    Utility.Stroke(root, theme.Border, 1, 0.2)

    -- Drop shadow (outer glow)
    local shadow = Utility.Make("ImageLabel", {
        Name                 = "Shadow",
        BackgroundTransparency = 1,
        Image                = "rbxassetid://6014261993",  -- 9-slice shadow
        ImageColor3          = theme.Shadow,
        ImageTransparency    = 0.5,
        ScaleType            = Enum.ScaleType.Slice,
        SliceCenter          = Rect.new(49, 49, 450, 450),
        Size                 = UDim2.new(1, 30, 1, 30),
        Position             = UDim2.fromOffset(-15, -10),
        ZIndex               = 9,
    }, root)
    shadow.Parent = root

    -- ── Title Bar ────────────────────────────────────────────────────────────
    local titlebar = Utility.Make("Frame", {
        Name             = "Titlebar",
        BackgroundColor3 = theme.Titlebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, TITLEBAR_H),
        ZIndex           = 12,
    }, root)
    Utility.Round(titlebar, UDim.new(0, 8))
    -- Flat-bottom corners mask
    Utility.Make("Frame", {
        BackgroundColor3 = theme.Titlebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 8),
        Position         = UDim2.new(0, 0, 1, -8),
        ZIndex           = 11,
    }, titlebar)

    -- Logo (optional)
    local logoX = 8
    if opts.LogoId then
        Utility.Make("ImageLabel", {
            BackgroundTransparency = 1,
            Image                  = opts.LogoId,
            Size                   = UDim2.fromOffset(22, 22),
            Position               = UDim2.fromOffset(10, 9),
            ZIndex                 = 13,
        }, titlebar)
        logoX = 38
    end

    -- Title text
    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Title or "GravityUI",
        TextColor3             = theme.Text,
        TextSize               = 14,
        FontFace               = Font.fromEnum(Enum.Font.GothamBold),
        Position               = UDim2.fromOffset(logoX, 0),
        Size                   = UDim2.new(0, 200, 1, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 13,
    }, titlebar)

    if opts.Subtitle then
        Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = opts.Subtitle,
            TextColor3             = theme.TextDim,
            TextSize               = 11,
            FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
            Position               = UDim2.fromOffset(logoX, 22),
            Size                   = UDim2.new(0, 200, 0, 14),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, titlebar)
    end

    -- Close button
    local closeBtn = Utility.Make("TextButton", {
        BackgroundColor3     = theme.Error,
        BackgroundTransparency = 0.3,
        Text                 = "✕",
        TextColor3           = theme.Text,
        TextSize             = 11,
        FontFace             = Font.fromEnum(Enum.Font.GothamBold),
        Size                 = UDim2.fromOffset(16, 16),
        Position             = UDim2.new(1, -22, 0.5, -8),
        AutoButtonColor      = false,
        ZIndex               = 14,
    }, titlebar)
    Utility.Round(closeBtn, UDim.new(1, 0))

    -- Minimize button
    local minBtn = Utility.Make("TextButton", {
        BackgroundColor3     = theme.Warning,
        BackgroundTransparency = 0.3,
        Text                 = "–",
        TextColor3           = theme.Text,
        TextSize             = 11,
        FontFace             = Font.fromEnum(Enum.Font.GothamBold),
        Size                 = UDim2.fromOffset(16, 16),
        Position             = UDim2.new(1, -42, 0.5, -8),
        AutoButtonColor      = false,
        ZIndex               = 14,
    }, titlebar)
    Utility.Round(minBtn, UDim.new(1, 0))

    -- ── Body ─────────────────────────────────────────────────────────────────
    local body = Utility.Make("Frame", {
        Name             = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(0, TITLEBAR_H),
        Size             = UDim2.new(1, 0, 1, -TITLEBAR_H),
        ZIndex           = 11,
        ClipsDescendants = true,
    }, root)

    -- Sidebar
    local sidebar = Utility.Make("ScrollingFrame", {
        Name                   = "Sidebar",
        BackgroundColor3       = theme.Sidebar,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, SIDEBAR_W, 1, 0),
        CanvasSize             = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = theme.Border,
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        ZIndex                 = 12,
        ElasticBehavior        = Enum.ElasticBehavior.Never,
    }, body)
    Utility.Make("Frame", {  -- sidebar right border
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        ZIndex           = 13,
    }, sidebar)
    Utility.Pad(sidebar, nil, 8, 0, 8, 0)
    self._sidebarLayout = Utility.List(sidebar, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

    -- Content area
    local content = Utility.Make("Frame", {
        Name             = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(SIDEBAR_W, 0),
        Size             = UDim2.new(1, -SIDEBAR_W, 1, 0),
        ClipsDescendants = true,
        ZIndex           = 11,
    }, body)

    -- Footer
    if opts.Footer then
        local footerH = 24
        local footer = Utility.Make("Frame", {
            BackgroundColor3 = theme.Titlebar,
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, footerH),
            Position         = UDim2.new(0, 0, 1, -footerH),
            ZIndex           = 12,
        }, content)
        Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = opts.Footer,
            TextColor3             = theme.TextDim,
            TextSize               = 10,
            FontFace               = Font.fromEnum(Enum.Font.Gotham),
            Size                   = UDim2.new(1, -10, 1, 0),
            Position               = UDim2.fromOffset(8, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, footer)
    end

    self._root    = root
    self._sidebar = sidebar
    self._content = content
    self._titlebar = titlebar
    self._tooltip = Tooltip.new(screenGui, theme)

    -- ── Dragging ─────────────────────────────────────────────────────────────
    local stopDrag = Utility.MakeDraggable(titlebar, root)
    self._cleaner:Add(stopDrag)

    -- ── Resize Handle ─────────────────────────────────────────────────────────
    if opts.Resizable ~= false then
        local grip = Utility.Make("TextButton", {
            BackgroundColor3     = theme.Accent,
            BackgroundTransparency = 0.8,
            Text                 = "",
            Size                 = UDim2.fromOffset(14, 14),
            Position             = UDim2.new(1, -14, 1, -14),
            AutoButtonColor      = false,
            ZIndex               = 15,
        }, root)
        Utility.Round(grip, UDim.new(0, 3))

        local resizing = false
        local startMouse = Vector2.zero
        local startSize = Vector2.zero

        self._cleaner:Add(grip.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing   = true
                startMouse = inp.Position
                startSize  = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
            end
        end))
        self._cleaner:Add(UserInputService.InputChanged:Connect(function(inp)
            if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - startMouse
                local nw = math.max(MIN_W, startSize.X + d.X)
                local nh = math.max(MIN_H, startSize.Y + d.Y)
                root.Size = UDim2.fromOffset(nw, nh)
            end
        end))
        self._cleaner:Add(UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end))
    end

    -- ── Close / Minimize ─────────────────────────────────────────────────────
    self._cleaner:Add(closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end))
    self._cleaner:Add(minBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end))

    -- Hover effects on window buttons
    for _, btn in ipairs({ closeBtn, minBtn }) do
        self._cleaner:Add(btn.MouseEnter:Connect(function()
            Tween.Play(btn, { BackgroundTransparency = 0 }, "Hover")
        end))
        self._cleaner:Add(btn.MouseLeave:Connect(function()
            Tween.Play(btn, { BackgroundTransparency = 0.3 }, "Hover")
        end))
        self._cleaner:Add(btn.MouseButton1Down:Connect(function()
            Tween.Play(btn, { Size = UDim2.fromOffset(14, 14) }, "Press")
        end))
        self._cleaner:Add(btn.MouseButton1Up:Connect(function()
            Tween.Play(btn, { Size = UDim2.fromOffset(16, 16) }, "Press")
        end))
    end

    -- ── Toggle Keybind ────────────────────────────────────────────────────────
    self._cleaner:Add(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == self._keybind then
            self:Toggle()
        end
    end))

    -- ── Notification Manager ──────────────────────────────────────────────────
    self._notifyMgr = Notification.new(screenGui, theme)

    return self
end

--- Creates and registers a new Tab in this window.
--- @param name  string  — Display name for the tab button.
--- @param icon  string? — Unicode icon or rbxassetid://.
function Window:Tab(name: string, icon: string?): any
    local theme = self._theme
    -- Tab button in sidebar
    local isFirst = #self._tabs == 0

    local btn = Utility.Make("TextButton", {
        BackgroundColor3     = isFirst and theme.Surface2 or theme.Sidebar,
        BackgroundTransparency = isFirst and 0 or 1,
        Text                 = "",
        Size                 = UDim2.new(1, -16, 0, 36),
        AutoButtonColor      = false,
        ZIndex               = 13,
        LayoutOrder          = #self._tabs + 1,
    }, self._sidebar)
    Utility.Round(btn, UDim.new(0, 6))

    -- Accent left-bar indicator
    local indicator = Utility.Make("Frame", {
        BackgroundColor3 = isFirst and theme.Accent or theme.Sidebar,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(3, 18),
        Position         = UDim2.fromOffset(0, 9),
        ZIndex           = 14,
    }, btn)
    Utility.Round(indicator, UDim.new(0, 2))

    -- Icon
    local textX = 14
    if icon then
        Utility.Make("TextLabel", {
            BackgroundTransparency = 1,
            Text                   = icon,
            TextColor3             = isFirst and theme.Accent or theme.TextDim,
            TextSize               = 14,
            FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
            Size                   = UDim2.fromOffset(20, 36),
            Position               = UDim2.fromOffset(10, 0),
            ZIndex                 = 14,
        }, btn)
        textX = 34
    end

    local label = Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = name,
        TextColor3             = isFirst and theme.Text or theme.TextDim,
        TextSize               = 12,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, -textX - 6, 1, 0),
        Position               = UDim2.fromOffset(textX, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 14,
    }, btn)

    -- Create the Tab object
    local tabObj = Tab.new(self._content, theme, self._tooltip)
    table.insert(self._tabs, tabObj)
    table.insert(self._tabBtns, btn)

    -- Show first tab by default
    if isFirst then
        self._activeTab = tabObj
        tabObj._frame.Visible = true
    else
        tabObj._frame.Visible = false
    end

    -- Tab click handler
    btn.MouseButton1Click:Connect(function()
        self:_selectTab(tabObj, btn, indicator, label, icon)
    end)

    btn.MouseEnter:Connect(function()
        if self._activeTab ~= tabObj then
            Tween.Play(btn,  { BackgroundTransparency = 0.6 }, "Hover")
            Tween.Play(btn,  { BackgroundColor3 = theme.Surface2 }, "Hover")
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= tabObj then
            Tween.Play(btn, { BackgroundTransparency = 1 }, "Hover")
        end
    end)

    self:_storeTabRefs(tabObj, btn, indicator, label, icon)

    return tabObj
end

function Window:_storeTabRefs(tabObj, btn, indicator, label, icon)
    tabObj._btn       = btn
    tabObj._indicator = indicator
    tabObj._label     = label
    tabObj._icon      = icon
end

function Window:_selectTab(tabObj, btn, indicator, label, icon)
    if self._activeTab == tabObj then return end
    local theme = self._theme

    -- Deselect current
    if self._activeTab then
        local prev = self._activeTab
        Tween.Play(prev._btn,       { BackgroundColor3 = theme.Sidebar, BackgroundTransparency = 1 }, "Open")
        Tween.Play(prev._indicator, { BackgroundColor3 = theme.Sidebar }, "Open")
        Tween.Play(prev._label,     { TextColor3 = theme.TextDim }, "Open")
        task.delay(0.15, function()
            prev._frame.Visible = false
        end)
    end

    -- Select new
    self._activeTab = tabObj
    tabObj._frame.Visible = true
    tabObj._frame.GroupTransparency = 1
    Tween.Play(tabObj._frame, { GroupTransparency = 0 }, "Open")

    Tween.Play(btn,       { BackgroundColor3 = theme.Surface2, BackgroundTransparency = 0 }, "Open")
    Tween.Play(indicator, { BackgroundColor3 = theme.Accent },  "Open")
    Tween.Play(label,     { TextColor3 = theme.Text },           "Open")
end

--- Shows the window (if hidden).
function Window:Show()
    self._root.Visible = true
    self._visible = true
    Tween.Play(self._root, { GroupTransparency = 0 }, "Open")
end

--- Hides the window without destroying it.
function Window:Hide()
    Tween.Play(self._root, { GroupTransparency = 1 }, "Close")
    task.delay(0.2, function()
        if not self._visible then
            self._root.Visible = false
        end
    end)
    self._visible = false
end

--- Toggles visibility.
function Window:Toggle()
    if self._visible then self:Hide() else self:Show() end
end

--- Sends a notification toast.
--- @param opts table — { Title, Body, Duration, Type }
function Window:Notify(opts: { Title: string, Body: string?, Duration: number?, Type: string? })
    self._notifyMgr:Send(opts)
end

--- Updates the window theme at runtime.
function Window:SetTheme(newTheme: any)
    -- For simplicity, recommend recreating the window; this is a design note.
    warn("GravityUI: SetTheme after construction requires recreating the window. Pass Theme to Window.new() options.")
end

--- Destroys the window and all connections.
function Window:Destroy()
    self._cleaner:Clean()
    self._tooltip:Destroy()
    if self._notifyMgr then self._notifyMgr:Destroy() end
    for _, tab in ipairs(self._tabs) do
        if tab.Destroy then tab:Destroy() end
    end
    self._root:Destroy()
end

return Window
