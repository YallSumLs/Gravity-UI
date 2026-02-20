--[[
    GravityUI :: Keybind
    --------------------
    A keybind picker that listens for a key press and displays the bound key.
    Supports three modes: Always, Toggle, Hold.

    Usage (via Section):
        local kb = sec:Keybind({
            Label    = "Open Menu",
            Default  = Enum.KeyCode.Insert,
            Mode     = "Toggle",   -- "Always" | "Toggle" | "Hold"
            Callback = function(active) print("Active:", active) end,
            Tooltip  = "Press to rebind",
        })
        kb:Set(Enum.KeyCode.F9)
        print(kb:Get())
]]

local UserInputService = game:GetService("UserInputService")
local Utility          = require(script.Parent.Parent.Core.Utility)
local Tween            = require(script.Parent.Parent.Core.Tween)

local COMP_H  = 38
local TAG_H   = 26

local Keybind = {}
Keybind.__index = Keybind

-- Keys that should not be bindable
local BLACKLISTED = {
    [Enum.KeyCode.Unknown]       = true,
    [Enum.KeyCode.W]             = true,
    [Enum.KeyCode.A]             = true,
    [Enum.KeyCode.S]             = true,
    [Enum.KeyCode.D]             = true,
}

function Keybind.new(parent: Frame, theme: any, tooltip: any?, opts: any)
    opts = opts or {}
    local self       = setmetatable({}, Keybind)
    self._theme      = theme
    self._key        = opts.Default or Enum.KeyCode.Unknown
    self._mode       = opts.Mode    or "Toggle"   -- Always | Toggle | Hold
    self._active     = false
    self._listening  = false
    self._callbacks  = { opts.Callback or function() end }
    self._conns      = {}

    -- Row root
    local root = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, COMP_H),
        ZIndex                 = 13,
    }, parent)
    self._root = root

    -- Label
    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text                   = opts.Label or "Keybind",
        TextColor3             = theme.Text,
        TextSize               = 13,
        FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
        Size                   = UDim2.new(1, -160, 1, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 14,
    }, root)

    -- Mode dropdown (small)
    local modeBtn = Utility.Make("TextButton", {
        BackgroundColor3     = theme.Surface2,
        BackgroundTransparency = 0,
        Text                 = self._mode,
        TextColor3           = theme.TextDim,
        TextSize             = 11,
        FontFace             = Font.fromEnum(Enum.Font.GothamMedium),
        Size                 = UDim2.fromOffset(60, TAG_H),
        Position             = UDim2.new(1, -140, 0.5, -TAG_H // 2),
        AutoButtonColor      = false,
        ZIndex               = 14,
    }, root)
    Utility.Round(modeBtn, UDim.new(0, 4))
    Utility.Stroke(modeBtn, theme.Border, 1, 0.4)

    local MODES = { "Always", "Toggle", "Hold" }
    modeBtn.MouseButton1Click:Connect(function()
        local idx = 1
        for i, m in ipairs(MODES) do
            if m == self._mode then idx = i; break end
        end
        self._mode = MODES[(idx % #MODES) + 1]
        modeBtn.Text = self._mode
        self._active = false
    end)

    -- Key tag button
    local keyTag = Utility.Make("TextButton", {
        BackgroundColor3     = theme.Surface2,
        BackgroundTransparency = 0,
        Text                 = Utility.KeyName(self._key),
        TextColor3           = theme.Accent,
        TextSize             = 12,
        FontFace             = Font.fromEnum(Enum.Font.GothamBold),
        Size                 = UDim2.fromOffset(72, TAG_H),
        Position             = UDim2.new(1, -74, 0.5, -TAG_H // 2),
        AutoButtonColor      = false,
        ZIndex               = 14,
    }, root)
    Utility.Round(keyTag, UDim.new(0, 4))
    Utility.Stroke(keyTag, theme.Accent, 1, 0.5)
    self._keyTag = keyTag

    -- Hover on key tag
    keyTag.MouseEnter:Connect(function()
        Tween.Play(keyTag, { BackgroundColor3 = theme.Surface }, "Hover")
    end)
    keyTag.MouseLeave:Connect(function()
        if not self._listening then
            Tween.Play(keyTag, { BackgroundColor3 = theme.Surface2 }, "Hover")
        end
    end)

    -- Click to begin listening
    keyTag.MouseButton1Click:Connect(function()
        if self._listening then return end
        self._listening = true
        keyTag.Text       = "..."
        keyTag.TextColor3 = theme.Warning
        Tween.Play(keyTag, { BackgroundColor3 = theme.Surface }, "Hover")
    end)

    -- Listen for key press in listening mode
    local inputConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if not self._listening then
            -- Active key handler
            if inp.KeyCode == self._key then
                if self._mode == "Always" then
                    self._active = true
                    for _, cb in ipairs(self._callbacks) do task.spawn(cb, true) end
                elseif self._mode == "Toggle" then
                    self._active = not self._active
                    for _, cb in ipairs(self._callbacks) do task.spawn(cb, self._active) end
                elseif self._mode == "Hold" then
                    self._active = true
                    for _, cb in ipairs(self._callbacks) do task.spawn(cb, true) end
                end
            end
            return
        end

        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if BLACKLISTED[inp.KeyCode] then return end

        -- Assign key
        self._listening = false
        self._key       = inp.KeyCode
        keyTag.Text       = Utility.KeyName(self._key)
        keyTag.TextColor3 = theme.Accent
        Tween.Play(keyTag, { BackgroundColor3 = theme.Surface2 }, "Hover")
    end)

    local releaseConn = UserInputService.InputEnded:Connect(function(inp)
        if self._mode == "Hold" and inp.KeyCode == self._key then
            self._active = false
            for _, cb in ipairs(self._callbacks) do task.spawn(cb, false) end
        end
    end)

    table.insert(self._conns, inputConn)
    table.insert(self._conns, releaseConn)

    -- Tooltip
    if opts.Tooltip and tooltip then
        tooltip:Attach(root, opts.Tooltip)
    end

    return self
end

--- Sets the bound key programmatically.
function Keybind:Set(key: Enum.KeyCode)
    self._key = key
    self._keyTag.Text = Utility.KeyName(key)
end

--- Returns the currently bound key.
function Keybind:Get(): Enum.KeyCode
    return self._key
end

--- Returns whether the keybind is currently "active" (for Toggle/Hold/Always).
function Keybind:IsActive(): boolean
    return self._active
end

function Keybind:Destroy()
    for _, c in ipairs(self._conns) do c:Disconnect() end
    self._root:Destroy()
end

return Keybind
