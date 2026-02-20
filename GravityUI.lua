--[[
    GravityUI — Main Entry Point
    ============================
    The top-level module. Require this file to access the entire library.

    Quick Start:
    ─────────────────────────────────────────────────────────────────────────────
        local GravityUI = loadstring(game:HttpGet("...GravityUI.lua"))()

        local win = GravityUI:Window({
            Title    = "My Script",
            Subtitle = "v1.0.0",
            Theme    = GravityUI.Theme.Dark,    -- or GravityUI.Theme.Light
        })

        local tab = win:Tab("General", "⚙")
        local sec = tab:Section("Aimbot")

        sec:Toggle({ Label = "Enable", Default = false, Callback = function(v) end })
        sec:Slider({ Label = "FOV", Min = 1, Max = 360, Default = 90 })
        sec:Button({ Label = "Fire Now", Callback = function() end })

        win:Notify({ Title = "Loaded!", Body = "Script initialized.", Type = "Success" })
    ─────────────────────────────────────────────────────────────────────────────

    Architecture:
        GravityUI
        ├── Core/
        │   ├── Signal.lua     — Event system
        │   ├── Tween.lua      — Animation wrapper
        │   ├── Theme.lua      — Theme engine
        │   ├── Utility.lua    — Helpers
        │   └── Tooltip.lua    — Hover tooltips
        └── Components/
            ├── Window.lua     — Main draggable window
            ├── Tab.lua        — Tab pane
            ├── Section.lua    — Component group card
            ├── Button.lua     — Click button
            ├── Toggle.lua     — On/off toggle
            ├── Slider.lua     — Value slider
            ├── Dropdown.lua   — Select dropdown
            ├── TextInput.lua  — Text field
            ├── Keybind.lua    — Key picker
            ├── Notification.lua — Toast notifications
            └── Modal.lua      — Confirmation dialog

    Extending the library:
        To create a new component, create a new file in Components/ following
        the Component.new(parent, theme, tooltip, opts) → self pattern.
        Add a corresponding factory method to Section.lua and update this file
        if you want top-level access.
]]

local Players  = game:GetService("Players")
local CoreGui  = game:GetService("CoreGui")

-- Resolve where we are (handles both ModuleScript tree and loadstring)
local scriptRoot = script

-- Core modules
local ThemeModule = require(scriptRoot.Src.Core.Theme)
local Signal      = require(scriptRoot.Src.Core.Signal)
local Tween       = require(scriptRoot.Src.Core.Tween)
local Utility     = require(scriptRoot.Src.Core.Utility)

-- Component modules (top-level access for standalone usage)
local WindowModule       = require(scriptRoot.Src.Components.Window)
local ModalModule        = require(scriptRoot.Src.Components.Modal)
local NotificationModule = require(scriptRoot.Src.Components.Notification)

-- ─────────────────────────────────────────────
-- GravityUI Public API
-- ─────────────────────────────────────────────

local GravityUI = {}
GravityUI.__index = GravityUI

--- Built-in themes. Pass one to Window options or create your own.
GravityUI.Theme  = ThemeModule

--- Signal factory — useful for custom component event systems.
GravityUI.Signal = Signal

--- Tween utilities and presets.
GravityUI.Tween  = Tween

--- Utility functions.
GravityUI.Utility = Utility

--- Version
GravityUI.Version = "1.0.0"

-- ─────────────────────────────────────────────
-- Internal ScreenGui management
-- ─────────────────────────────────────────────

local function getOrCreateGui(name: string): ScreenGui
    -- Try to reuse existing ScreenGui
    local existing = CoreGui:FindFirstChild(name)
    if existing and existing:IsA("ScreenGui") then
        return existing
    end

    local gui = Instance.new("ScreenGui")
    gui.Name              = name
    gui.ResetOnSpawn      = false
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset    = true
    gui.DisplayOrder      = 999

    -- Protect on supported executors
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)

    if not gui.Parent then
        gui.Parent = CoreGui
    end

    return gui
end

--- Creates a new GravityUI Window.
---
--- @param opts WindowOptions — Configuration table:
---   - Title      string?   — Window title (default "GravityUI")
---   - Subtitle   string?   — Small subtitle below title
---   - Theme      table?    — GravityUI.Theme.Dark | .Light | custom
---   - Size       Vector2?  — Initial window size (default 620×460)
---   - Position   Vector2?  — Initial offset; nil = centered
---   - Resizable  boolean?  — Allow corner resize (default true)
---   - Keybind    Enum.KeyCode? — Toggle keybind (default RightControl)
---   - Footer     string?   — Footer text at bottom of content area
---   - LogoId     string?   — rbxassetid:// icon in title bar
---   - GuiName    string?   — Name of the ScreenGui (default "GravityUI")
---
--- @return Window
function GravityUI:Window(opts: {
    Title:     string?,
    Subtitle:  string?,
    Theme:     any?,
    Size:      Vector2?,
    Position:  Vector2?,
    Resizable: boolean?,
    Keybind:   Enum.KeyCode?,
    Footer:    string?,
    LogoId:    string?,
    GuiName:   string?,
}?)
    opts = opts or {}
    local guiName  = opts.GuiName or "GravityUI"
    local screenGui = getOrCreateGui(guiName)
    return WindowModule.new(screenGui, opts)
end

--- Creates a standalone Modal dialog not bound to any window.
---
--- @param opts table — { Title, Body, Confirm, Cancel, OnConfirm, OnCancel }
--- @return Modal
function GravityUI:Modal(opts: {
    Title:     string?,
    Body:      string?,
    Confirm:   string?,
    Cancel:    string?,
    OnConfirm: (() -> ())?,
    OnCancel:  (() -> ())?,
    Theme:     any?,
    GuiName:   string?,
}?)
    opts = opts or {}
    local theme     = opts.Theme or ThemeModule.Dark
    local guiName   = opts.GuiName or "GravityUI"
    local screenGui = getOrCreateGui(guiName)
    return ModalModule.new(screenGui, theme, opts)
end

--- Creates a standalone notification manager not bound to a window.
--- @param theme any?   — Theme to use (defaults to Theme.Dark)
function GravityUI:NotificationManager(theme: any?, guiName: string?)
    local t         = theme or ThemeModule.Dark
    local screenGui = getOrCreateGui(guiName or "GravityUI")
    return NotificationModule.new(screenGui, t)
end

--- Creates a custom theme by merging overrides into a base theme.
--- @param base      any?   — Base theme (Theme.Dark or Theme.Light). Defaults to Dark.
--- @param overrides table  — Partial Color3 token overrides.
function GravityUI:CustomTheme(base: any?, overrides: { [string]: Color3 }?): any
    return ThemeModule.new(base or ThemeModule.Dark, overrides)
end

return GravityUI
