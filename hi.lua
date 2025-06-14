-- RobustUI Library v1.1 (Executor-friendly)
-- Single-script version for use in executors (Synapse, Krnl, etc.)

local RobustUI = {}
RobustUI.__index = RobustUI

-- Services
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

-- Local player & GUI root
local localPlayer = Players.LocalPlayer
assert(localPlayer, "RobustUI: LocalPlayer not found.")

-- Create or reuse ScreenGui container
local playerGui = localPlayer:WaitForChild("PlayerGui")
local rootGui    = Instance.new("ScreenGui")
rootGui.Name           = "RobustUI_ExecutorRoot"
rootGui.ResetOnSpawn   = false
rootGui.Parent         = playerGui

-- Default theme
local DefaultTheme = {
    BackgroundColor    = Color3.fromRGB(30, 30, 30),
    BorderColor        = Color3.fromRGB(70, 70, 70),
    TextColor          = Color3.fromRGB(220, 220, 220),
    HoverColor         = Color3.fromRGB(45, 45, 45),
    ClickColor         = Color3.fromRGB(70, 70, 70),
    Font               = Enum.Font.Gotham,
    TextSize           = 18,
    AnimationDuration  = 0.2,
}
local Theme = table.clone(DefaultTheme)

-- Utility: Create instance
local function CreateInstance(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    inst.Parent = parent or rootGui
    return inst
end

-- Set global theme
function RobustUI.SetTheme(newTheme)
    for k, v in pairs(newTheme) do
        Theme[k] = v
    end
end

-- ========== BUTTON ==========
function RobustUI.CreateButton(parent, options)
    options = options or {}
    local btnParent = (parent and parent:IsA("GuiObject")) and parent or rootGui

    local frame = CreateInstance("TextButton", {
        BackgroundColor3 = options.BackgroundColor    or Theme.BackgroundColor,
        BorderColor3     = options.BorderColor        or Theme.BorderColor,
        TextColor3       = options.TextColor          or Theme.TextColor,
        Font             = options.Font               or Theme.Font,
        TextSize         = options.TextSize           or Theme.TextSize,
        Text             = options.Text               or "Button",
        AutoButtonColor  = false,
        Size             = options.Size               or UDim2.new(0, 150, 0, 40),
        ClipsDescendants = true,
    }, btnParent)

    local OnClick   = Instance.new("BindableEvent")
    local OnHover   = Instance.new("BindableEvent")
    local OnUnhover = Instance.new("BindableEvent")

    local function TweenBackground(color)
        TweenService:Create(frame, TweenInfo.new(Theme.AnimationDuration), {
            BackgroundColor3 = color
        }):Play()
    end

    frame.MouseEnter:Connect(function()
        TweenBackground(options.HoverColor or Theme.HoverColor)
        OnHover:Fire()
    end)
    frame.MouseLeave:Connect(function()
        TweenBackground(options.BackgroundColor or Theme.BackgroundColor)
        OnUnhover:Fire()
    end)
    frame.MouseButton1Down:Connect(function()
        TweenBackground(options.ClickColor or Theme.ClickColor)
    end)
    frame.MouseButton1Up:Connect(function()
        TweenBackground(options.HoverColor or Theme.HoverColor)
        OnClick:Fire()
    end)

    return setmetatable({
        Instance   = frame,
        OnClick    = OnClick.Event,
        OnHover    = OnHover.Event,
        OnUnhover  = OnUnhover.Event,
        SetText    = function(self, txt) frame.Text = txt end,
        SetColors  = function(self, bg, border, text)
            frame.BackgroundColor3 = bg     or frame.BackgroundColor3
            frame.BorderColor3     = border or frame.BorderColor3
            frame.TextColor3       = text   or frame.TextColor3
        end,
        Destroy    = function(self)
            OnClick:Destroy()
            OnHover:Destroy()
            OnUnhover:Destroy()
            frame:Destroy()
        end,
    }, RobustUI)
end

-- ========== LABEL ==========
function RobustUI.CreateLabel(parent, options)
    options = options or {}
    local lbl = CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        TextColor3            = options.TextColor or Theme.TextColor,
        Font                  = options.Font      or Theme.Font,
        TextSize              = options.TextSize  or Theme.TextSize,
        Text                  = options.Text      or "",
        Size                  = options.Size      or UDim2.new(0, 200, 0, 30),
        TextWrapped           = true,
        TextXAlignment        = options.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment        = options.TextYAlignment or Enum.TextYAlignment.Center,
    })

    return setmetatable({
        Instance = lbl,
        SetText  = function(self, txt) lbl.Text = txt end,
        SetColor = function(self, col) lbl.TextColor3 = col end,
        Destroy  = function(self) lbl:Destroy() end,
    }, RobustUI)
end

-- ========== INPUT FIELD ==========
function RobustUI.CreateInputField(parent, options)
    options = options or {}
    local box = CreateInstance("TextBox", {
        BackgroundColor3    = options.BackgroundColor or Theme.BackgroundColor,
        BorderColor3        = options.BorderColor     or Theme.BorderColor,
        TextColor3          = options.TextColor       or Theme.TextColor,
        Font                = options.Font            or Theme.Font,
        TextSize            = options.TextSize        or Theme.TextSize,
        PlaceholderText     = options.PlaceholderText or "",
        Text                = options.Text            or "",
        Size                = options.Size            or UDim2.new(0, 200, 0, 30),
        ClearTextOnFocus    = false,
        ClipsDescendants    = true,
    })
    local OnTextChanged = Instance.new("BindableEvent")

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if options.Validator then
            options.Validator(box.Text)
        end
        OnTextChanged:Fire(box.Text)
    end)

    box.FocusLost:Connect(function()
        OnTextChanged:Fire(box.Text)
    end)

    return setmetatable({
        Instance      = box,
        OnTextChanged = OnTextChanged.Event,
        GetText       = function() return box.Text end,
        SetText       = function(_, txt) box.Text = txt end,
        Destroy       = function()
            OnTextChanged:Destroy()
            box:Destroy()
        end,
    }, RobustUI)
end

-- ========== SCROLL FRAME ==========
function RobustUI.CreateScrollFrame(parent, options)
    options = options or {}
    local frame = CreateInstance("Frame", {
        BackgroundColor3    = options.BackgroundColor or Theme.BackgroundColor,
        BorderColor3        = options.BorderColor     or Theme.BorderColor,
        Size                = options.Size            or UDim2.new(0, 300, 0, 400),
        ClipsDescendants    = true,
    })
    local sf = CreateInstance("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 1, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ScrollBarThickness     = options.ScrollBarThickness or 8,
    }, frame)
    local layout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = options.Padding or UDim.new(0, 4),
    }, sf)

    return setmetatable({
        Frame         = frame,
        ScrollFrame   = sf,
        Layout        = layout,
        AddItem       = function(_, obj) obj.Parent = sf end,
        Clear         = function(_) sf:ClearAllChildren(); layout.Parent = sf end,
        SetCanvasSize = function(_, sz) sf.CanvasSize = sz end,
        Destroy       = function(_) frame:Destroy() end,
    }, RobustUI)
end

-- ========== IMAGE DISPLAY ==========
function RobustUI.CreateImage(parent, options)
    options = options or {}
    local img = CreateInstance("ImageLabel", {
        BackgroundColor3      = options.BackgroundColor or Theme.BackgroundColor,
        BorderColor3          = options.BorderColor     or Theme.BorderColor,
        Size                  = options.Size            or UDim2.new(0, 150, 0, 150),
        Image                 = options.Image           or "",
        ScaleType             = options.ScaleType       or Enum.ScaleType.Fit,
        BackgroundTransparency = options.BackgroundTransparency or 0,
    })

    return setmetatable({
        Instance = img,
        SetImage = function(_, id) img.Image = id end,
        SetSize  = function(_, s) img.Size = s end,
        Destroy  = function() img:Destroy() end,
    }, RobustUI)
end

-- ========== LAYOUT UTILS ==========
function RobustUI.ApplyResponsiveLayout(guiObj, opts)
    opts = opts or {}
    local minW, maxW = opts.MinWidth or 200, opts.MaxWidth or 800

    local function upd()
        local scale = math.clamp(workspace.CurrentCamera.ViewportSize.X / 1920, 0.5, 1)
        local w     = math.clamp(minW * scale, minW, maxW)
        guiObj.Size = UDim2.new(0, w, 0, guiObj.Size.Y.Offset)
    end

    upd()
    local conn = RunService.RenderStepped:Connect(function()
        if not guiObj.Parent then
            conn:Disconnect()
            return
        end
        upd()
    end)
end

return RobustUI
