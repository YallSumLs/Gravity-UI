--[[
    GravityUI — Full Example Script
    ================================
    Demonstrates every component in the library with realistic configurations.

    HOW TO USE IN ROBLOX STUDIO:
    ─────────────────────────────────────────────────────────────────────────────
    1.  Place the "Gravity UI" folder into ReplicatedStorage.
    2.  Create a LocalScript inside StarterPlayerScripts.
    3.  Add this code (or require this file from the LocalScript).
    ─────────────────────────────────────────────────────────────────────────────
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GravityUI = require(ReplicatedStorage["Gravity UI"].GravityUI)

-- ═══════════════════════════════════════════════════════════════════
--  Create the main window
-- ═══════════════════════════════════════════════════════════════════

local win = GravityUI:Window({
    Title    = "GravityUI",
    Subtitle = "v1.0.0  —  Demo",
    Theme    = GravityUI.Theme.Dark,    -- try GravityUI.Theme.Light too!
    Size     = Vector2.new(640, 480),
    Keybind  = Enum.KeyCode.RightControl,
    Footer   = "GravityUI • github.com/your-username/GravityUI",
})

-- ═══════════════════════════════════════════════════════════════════
--  TAB 1 — General
-- ═══════════════════════════════════════════════════════════════════

local generalTab = win:Tab("General", "⚙")

-- ─── Section: Player ─────────────────────────────────────────────
local playerSec = generalTab:Section("Player")

playerSec:Toggle({
    Label       = "Infinite Jump",
    Description = "Jump an unlimited number of times",
    Default     = false,
    Tooltip     = "Hold Space to keep jumping",
    Callback    = function(enabled)
        -- Example: hook UserInputService for infinite jump
        print("Infinite Jump:", enabled)
    end,
})

playerSec:Slider({
    Label    = "Walk Speed",
    Min      = 8,
    Max      = 200,
    Default  = 16,
    Step     = 1,
    Suffix   = " st/s",
    Tooltip  = "Humanoid.WalkSpeed",
    Callback = function(v)
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = v
        end
    end,
})

playerSec:Slider({
    Label    = "Jump Power",
    Min      = 10,
    Max      = 300,
    Default  = 50,
    Step     = 5,
    Suffix   = " JP",
    Callback = function(v)
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.JumpPower = v
        end
    end,
})

playerSec:Button({
    Label       = "Reset Character",
    Description = "Kills and respawns your character",
    ButtonLabel = "Reset",
    Tooltip     = "Calls Humanoid:TakeDamage(math.huge)",
    Callback    = function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.Health = 0
        end
        win:Notify({
            Title    = "Character Reset",
            Body     = "Your character has been reset.",
            Type     = "Warning",
            Duration = 3,
        })
    end,
})

-- ─── Section: Appearance ────────────────────────────────────────
local appSec = generalTab:Section("Appearance")

local themeDropdown = appSec:Dropdown({
    Label    = "UI Theme",
    Values   = { "Dark", "Light" },
    Default  = "Dark",
    Tooltip  = "Switch color theme (requires re-open)",
    Callback = function(v)
        print("Theme selected:", v)
        win:Notify({
            Title    = "Theme Changed",
            Body     = "Reload the script to apply: " .. v,
            Type     = "Info",
            Duration = 4,
        })
    end,
})

appSec:Toggle({
    Label    = "Show FPS Counter",
    Default  = false,
    Callback = function(v)
        print("FPS Counter:", v)
    end,
})

-- ─── Section: Input ─────────────────────────────────────────────
local inputSec = generalTab:Section("Input Fields")

local nameInput = inputSec:Input({
    Label       = "Target Player",
    Placeholder = "Enter username...",
    Tooltip     = "Roblox username to target",
    Callback    = function(text)
        print("Targeting:", text)
    end,
    Changed = function(text)
        -- live update
    end,
})

local amountInput = inputSec:Input({
    Label       = "Amount",
    Placeholder = "Enter a number...",
    Numeric     = true,
    Default     = "100",
    Tooltip     = "Only numeric values accepted",
    Callback    = function(text)
        print("Amount:", text)
    end,
})

-- ═══════════════════════════════════════════════════════════════════
--  TAB 2 — Combat
-- ═══════════════════════════════════════════════════════════════════

local combatTab = win:Tab("Combat", "⚔")

-- ─── Section: Aimbot ────────────────────────────────────────────
local aimbotSec = combatTab:Section("Aimbot")

local aimbotToggle = aimbotSec:Toggle({
    Label    = "Enable Aimbot",
    Default  = false,
    Tooltip  = "Locks crosshair to nearest player",
    Callback = function(v)
        print("Aimbot:", v)
    end,
})

aimbotSec:Slider({
    Label    = "FOV Circle",
    Min      = 10,
    Max      = 500,
    Default  = 120,
    Step     = 5,
    Suffix   = "px",
    Callback = function(v)
        print("FOV:", v)
    end,
})

aimbotSec:Slider({
    Label    = "Smoothness",
    Min      = 1,
    Max      = 20,
    Default  = 5,
    Step     = 1,
    Tooltip  = "Higher = slower aim movement",
    Callback = function(v)
        print("Smooth:", v)
    end,
})

aimbotSec:Dropdown({
    Label    = "Target Part",
    Values   = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
    Default  = "Head",
    Callback = function(v)
        print("Target part:", v)
    end,
})

aimbotSec:Dropdown({
    Label    = "Target Teams",
    Values   = { "Everyone", "Enemies Only", "Friends Only" },
    Default  = "Enemies Only",
    Callback = function(v)
        print("Team filter:", v)
    end,
})

-- ─── Section: ESP ───────────────────────────────────────────────
local espSec = combatTab:Section("ESP")

espSec:Toggle({
    Label    = "Player ESP",
    Default  = false,
    Callback = function(v) print("ESP:", v) end,
})

espSec:Toggle({
    Label    = "Show Health Bars",
    Default  = true,
    Callback = function(v) print("Healthbar:", v) end,
})

espSec:Toggle({
    Label    = "Show Names",
    Default  = true,
    Callback = function(v) print("Names:", v) end,
})

espSec:Slider({
    Label    = "Max Distance",
    Min      = 50,
    Max      = 2000,
    Default  = 500,
    Step     = 50,
    Suffix   = " studs",
    Callback = function(v) print("ESP Distance:", v) end,
})

-- ─── Section: Multi-Select Demo ─────────────────────────────────
local multiSec = combatTab:Section("Multi-Select Demo")

multiSec:Dropdown({
    Label    = "Visible Parts",
    Values   = { "Head", "Torso", "Arms", "Legs" },
    Default  = { "Head", "Torso" },
    Multi    = true,
    Tooltip  = "Select multiple parts to highlight",
    Callback = function(selected)
        print("Parts selected:", table.concat(selected, ", "))
    end,
})

-- ═══════════════════════════════════════════════════════════════════
--  TAB 3 — Settings
-- ═══════════════════════════════════════════════════════════════════

local settingsTab = win:Tab("Settings", "⚡")

-- ─── Section: Keybinds ──────────────────────────────────────────
local keybindSec = settingsTab:Section("Keybinds")

keybindSec:Keybind({
    Label    = "Toggle Menu",
    Default  = Enum.KeyCode.RightControl,
    Mode     = "Toggle",
    Tooltip  = "Press to toggle the UI",
    Callback = function(active)
        -- The window already handles RightControl internally
        -- This demonstrates how to use the Keybind component
        print("Keybind active:", active)
    end,
})

keybindSec:Keybind({
    Label    = "Quick Attack",
    Default  = Enum.KeyCode.E,
    Mode     = "Hold",
    Tooltip  = "Hold to keep ability active",
    Callback = function(active)
        print("Quick Attack held:", active)
    end,
})

keybindSec:Keybind({
    Label    = "Teleport to Target",
    Default  = Enum.KeyCode.T,
    Mode     = "Always",
    Tooltip  = "Press once to teleport",
    Callback = function(active)
        if active then
            print("Teleporting!")
        end
    end,
})

-- ─── Section: Notifications Demo ────────────────────────────────
local notifSec = settingsTab:Section("Notification Demos")

notifSec:Button({
    Label       = "Info",
    ButtonLabel = "Send",
    Description = "Sends an Info notification",
    Callback    = function()
        win:Notify({ Title = "Info", Body = "This is an informational toast.", Type = "Info", Duration = 4 })
    end,
})

notifSec:Button({
    Label       = "Success",
    ButtonLabel = "Send",
    Description = "Sends a Success notification",
    Callback    = function()
        win:Notify({ Title = "Success", Body = "Operation completed successfully!", Type = "Success", Duration = 4 })
    end,
})

notifSec:Button({
    Label       = "Warning",
    ButtonLabel = "Send",
    Description = "Sends a Warning notification",
    Callback    = function()
        win:Notify({ Title = "Warning", Body = "Proceed with caution!", Type = "Warning", Duration = 4 })
    end,
})

notifSec:Button({
    Label       = "Error",
    ButtonLabel = "Send",
    Description = "Sends an Error notification",
    Callback    = function()
        win:Notify({ Title = "Error", Body = "Something went wrong. Please retry.", Type = "Error", Duration = 4 })
    end,
})

-- ─── Section: Modal Demo ────────────────────────────────────────
local modalSec = settingsTab:Section("Modal Dialog")

modalSec:Button({
    Label       = "Confirmation Dialog",
    ButtonLabel = "Open",
    Description = "Opens a modal with confirm/cancel",
    Callback    = function()
        local modal = GravityUI:Modal({
            Title     = "Reset Settings?",
            Body      = "This will reset all your configured values to their defaults. This action cannot be undone.",
            Confirm   = "Reset",
            Cancel    = "Keep",
            OnConfirm = function()
                win:Notify({ Title = "Reset", Body = "All settings have been reset.", Type = "Success" })
            end,
            OnCancel  = function()
                win:Notify({ Title = "Cancelled", Body = "No changes were made.", Type = "Info" })
            end,
        })
        modal:Show()
    end,
})

-- ─── Section: Custom Theme Demo ──────────────────────────────────
local themeSec = settingsTab:Section("Custom Theme Example")
themeSec:Label({ Text = "<b>Custom Theme</b> — Create a window with a red accent:" })

themeSec:Button({
    Label       = "Open Red-Accent Window",
    ButtonLabel = "Open",
    Callback    = function()
        local customTheme = GravityUI:CustomTheme(GravityUI.Theme.Dark, {
            Accent    = Color3.fromRGB(255, 60, 80),
            AccentDim = Color3.fromRGB(180, 30, 50),
        })
        local win2 = GravityUI:Window({
            Title   = "Custom Theme Demo",
            Theme   = customTheme,
            Size    = Vector2.new(500, 360),
            GuiName = "GravityUIDemo2",
        })
        local t = win2:Tab("Demo", "🔴")
        local s = t:Section("Red Accent")
        s:Toggle({ Label = "Example Toggle", Default = true })
        s:Button({ Label = "Close this window", ButtonLabel = "Close",
            Callback = function() win2:Destroy() end })
    end,
})

-- ═══════════════════════════════════════════════════════════════════
--  Startup notification
-- ═══════════════════════════════════════════════════════════════════

task.wait(0.5)
win:Notify({
    Title    = "GravityUI Loaded",
    Body     = "Welcome! Press [RCtrl] to toggle the window.",
    Type     = "Success",
    Duration = 5,
})
