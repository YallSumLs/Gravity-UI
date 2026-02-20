--[[
    GravityUI :: Modal
    ------------------
    A confirmation dialog modal with a dimmed backdrop overlay.
    Supports custom title, body text, and confirm/cancel button labels.

    Usage (via GravityUI or Window):
        local modal = Modal.new(screenGui, theme, {
            Title   = "Confirm Action",
            Body    = "Are you sure you want to reset all settings?",
            Confirm = "Reset",
            Cancel  = "Keep",
            OnConfirm = function() resetSettings() end,
            OnCancel  = function() end,
        })
        modal:Show()
]]

local Utility = require(script.Parent.Parent.Core.Utility)
local Tween   = require(script.Parent.Parent.Core.Tween)

local MODAL_W = 340
local MODAL_H = 170

local Modal = {}
Modal.__index = Modal

function Modal.new(screenGui: ScreenGui, theme: any, opts: {
    Title:     string?,
    Body:      string?,
    Confirm:   string?,
    Cancel:    string?,
    OnConfirm: (() -> ())?,
    OnCancel:  (() -> ())?,
})
    opts = opts or {}
    local self        = setmetatable({}, Modal)
    self._theme       = theme
    self._onConfirm   = opts.OnConfirm or function() end
    self._onCancel    = opts.OnCancel  or function() end
    self._visible     = false

    -- Dim overlay
    local overlay = Utility.Make("Frame", {
        BackgroundColor3     = theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Size                 = UDim2.new(1, 0, 1, 0),
        ZIndex               = 50,
        Visible              = false,
    }, screenGui)
    self._overlay = overlay

    -- Click-outside to cancel
    local overlayBtn = Utility.Make("TextButton", {
        BackgroundTransparency = 1,
        Text                   = "",
        Size                   = UDim2.new(1, 0, 1, 0),
        AutoButtonColor        = false,
        ZIndex                 = 50,
    }, overlay)
    overlayBtn.MouseButton1Click:Connect(function()
        self:Close()
        task.spawn(self._onCancel)
    end)

    -- Card
    local card = Utility.Make("Frame", {
        BackgroundColor3   = theme.Surface,
        BorderSizePixel    = 0,
        Size               = UDim2.fromOffset(MODAL_W, MODAL_H),
        Position           = UDim2.new(0.5, -MODAL_W // 2, 0.5, -MODAL_H // 2),
        ZIndex             = 55,
    }, overlay)
    Utility.Round(card, UDim.new(0, 10))
    Utility.Stroke(card, theme.Border, 1, 0.2)

    -- Title bar
    local titleBar = Utility.Make("Frame", {
        BackgroundColor3 = theme.Titlebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 44),
        ZIndex           = 56,
    }, card)
    Utility.Make("Frame", {   -- flat-bottom mask
        BackgroundColor3 = theme.Titlebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        ZIndex           = 56,
    }, titleBar)
    Utility.Round(titleBar, UDim.new(0, 10))

    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text         = opts.Title or "Confirm",
        TextColor3   = theme.Text,
        TextSize     = 14,
        FontFace     = Font.fromEnum(Enum.Font.GothamBold),
        Size         = UDim2.new(1, -16, 1, 0),
        Position     = UDim2.fromOffset(16, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex       = 57,
    }, titleBar)

    -- Body text
    Utility.Make("TextLabel", {
        BackgroundTransparency = 1,
        Text         = opts.Body or "",
        TextColor3   = theme.TextDim,
        TextSize     = 12,
        FontFace     = Font.fromEnum(Enum.Font.Gotham),
        Size         = UDim2.new(1, -32, 0, 50),
        Position     = UDim2.fromOffset(16, 50),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped  = true,
        RichText     = true,
        ZIndex       = 56,
    }, card)

    -- Button row
    local btnRow = Utility.Make("Frame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -32, 0, 36),
        Position               = UDim2.new(0, 16, 1, -50),
        ZIndex                 = 56,
    }, card)
    Utility.List(btnRow, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    -- Cancel button
    local cancelBtn = Utility.Make("TextButton", {
        BackgroundColor3     = theme.Surface2,
        Text                 = opts.Cancel or "Cancel",
        TextColor3           = theme.TextDim,
        TextSize             = 12,
        FontFace             = Font.fromEnum(Enum.Font.GothamMedium),
        Size                 = UDim2.fromOffset(100, 32),
        AutoButtonColor      = false,
        ZIndex               = 57,
        LayoutOrder          = 1,
    }, btnRow)
    Utility.Round(cancelBtn, UDim.new(0, 6))
    Utility.Stroke(cancelBtn, theme.Border, 1, 0.3)

    -- Confirm button
    local confirmBtn = Utility.Make("TextButton", {
        BackgroundColor3 = theme.Accent,
        Text             = opts.Confirm or "Confirm",
        TextColor3       = theme.Text,
        TextSize         = 12,
        FontFace         = Font.fromEnum(Enum.Font.GothamBold),
        Size             = UDim2.fromOffset(110, 32),
        AutoButtonColor  = false,
        ZIndex           = 57,
        LayoutOrder      = 2,
    }, btnRow)
    Utility.Round(confirmBtn, UDim.new(0, 6))

    -- Button hover/press animations
    for _, btn in ipairs({ cancelBtn, confirmBtn }) do
        local isCancelBtn = (btn == cancelBtn)
        btn.MouseEnter:Connect(function()
            Tween.Play(btn, {
                BackgroundColor3 = isCancelBtn and theme.Surface or theme.AccentDim,
            }, "Hover")
        end)
        btn.MouseLeave:Connect(function()
            Tween.Play(btn, {
                BackgroundColor3 = isCancelBtn and theme.Surface2 or theme.Accent,
            }, "Hover")
        end)
        btn.MouseButton1Down:Connect(function()
            Tween.Play(btn, { Size = UDim2.fromOffset(isCancelBtn and 96 or 106, 29) }, "Press")
        end)
        btn.MouseButton1Up:Connect(function()
            Tween.Play(btn, { Size = UDim2.fromOffset(isCancelBtn and 100 or 110, 32) }, "Press")
        end)
    end

    cancelBtn.MouseButton1Click:Connect(function()
        self:Close()
        task.spawn(self._onCancel)
    end)
    confirmBtn.MouseButton1Click:Connect(function()
        self:Close()
        task.spawn(self._onConfirm)
    end)

    self._card = card

    return self
end

--- Shows the modal with an animated scale+fade entrance.
function Modal:Show()
    if self._visible then return end
    self._visible = true
    self._overlay.Visible = true
    self._card.Size = UDim2.fromOffset(MODAL_W * 0.92, MODAL_H * 0.92)
    Tween.Play(self._overlay, { BackgroundTransparency = 0.55 }, "Fade")
    Tween.Play(self._card,    { Size = UDim2.fromOffset(MODAL_W, MODAL_H) }, "Modal")
end

--- Closes the modal with a fade-out animation.
function Modal:Close()
    if not self._visible then return end
    self._visible = false
    Tween.Play(self._overlay, { BackgroundTransparency = 1 }, "Fade")
    task.delay(0.25, function()
        self._overlay.Visible = false
    end)
end

--- Destroys the modal.
function Modal:Destroy()
    self._overlay:Destroy()
end

return Modal
