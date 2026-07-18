-- Hanami Bypass GUI
-- Recreated from HTML design

repeat task.wait() until game:IsLoaded()

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LP             = Players.LocalPlayer

local PINK        = Color3.fromRGB(255, 77, 166)
local PINK_GLOW   = Color3.fromRGB(255, 128, 192)
local PINK_DIM    = Color3.fromRGB(194, 24, 91)
local BG          = Color3.fromRGB(0, 0, 0)
local PANEL       = Color3.fromRGB(10, 10, 10)
local BORDER      = Color3.fromRGB(26, 26, 26)

-- ===================== AIMBOT LOGIC =====================
local RunService = game:GetService("RunService")
local h, hrp = nil, nil

local function updateChar()
    local char = LP.Character
    if not char then h = nil; hrp = nil; return end
    h   = char:FindFirstChildOfClass("Humanoid")
    hrp = char:FindFirstChild("HumanoidRootPart")
end
updateChar()
LP.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    h   = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
end)

local function getClosestPlayer()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then cd = d; cp = p end
            end
        end
    end
    return cp, cd
end

local function tryHitBat()
    local char = LP.Character
    if not char then return end
    local bat = char:FindFirstChild("Bat") or (LP:FindFirstChild("Backpack") and LP.Backpack:FindFirstChild("Bat"))
    if not bat then return end
    if bat.Parent ~= char then
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then pcall(function() hum2:EquipTool(bat) end) end
    end
    pcall(function() bat:Activate() end)
    local remote = bat:FindFirstChildWhichIsA("RemoteEvent")
    if remote then pcall(function() remote:FireServer() end) end
end

local aimbotConn = nil

local function startAimbot()
    if aimbotConn then return end
    aimbotConn = RunService.Heartbeat:Connect(function()
        if not (h and hrp) then updateChar(); return end
        local target, dist = getClosestPlayer()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local fp  = tr.Position + tr.CFrame.LookVector * 1.5
                local dir = (fp - hrp.Position).Unit
                hrp.Velocity = Vector3.new(dir.X * 56.5, dir.Y * 56.5, dir.Z * 56.5)
                if dist <= 5 then tryHitBat() end
            end
        end
    end)
end

local function stopAimbot()
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    if hrp then hrp.Velocity = Vector3.zero end
end
-- ===================== END AIMBOT =====================


local gui = Instance.new("ScreenGui")
gui.Name = "HanamiBypass"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(gui) end
    gui.Parent = game:GetService("CoreGui")
end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end
local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or BORDER
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

-- ===================== MAIN PANEL =====================
local panel = Instance.new("Frame", gui)
panel.Name = "Panel"
panel.Size = UDim2.new(0, 280, 0, 0)
panel.Position = UDim2.new(0.5, -140, 0.5, -80)
panel.BackgroundColor3 = PANEL
panel.BorderSizePixel = 0
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.Active = true
mkCorner(panel, 20)
mkStroke(panel, PINK_DIM, 1)

-- Pink glow outer stroke
local glowStroke = Instance.new("UIStroke", panel)
glowStroke.Color = PINK
glowStroke.Thickness = 0
glowStroke.Transparency = 0.85

-- ===================== HEADER =====================
local header = Instance.new("Frame", panel)
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
header.BorderSizePixel = 0
mkCorner(header, 20)

-- Bottom corners square so it blends into body
local headerFix = Instance.new("Frame", header)
headerFix.Size = UDim2.new(1, 0, 0.5, 0)
headerFix.Position = UDim2.new(0, 0, 0.5, 0)
headerFix.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
headerFix.BorderSizePixel = 0

-- Pink gradient tint in header
local hGrad = Instance.new("UIGradient", header)
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 8, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 8)),
})
hGrad.Rotation = 135

-- Header bottom line
local hLine = Instance.new("Frame", header)
hLine.Size = UDim2.new(1, 0, 0, 1)
hLine.Position = UDim2.new(0, 0, 1, -1)
hLine.BackgroundColor3 = PINK
hLine.BackgroundTransparency = 0.4
hLine.BorderSizePixel = 0
local hLineGrad = Instance.new("UIGradient", hLine)
hLineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
})

-- Title
local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -20, 1, 0)
titleLbl.Position = UDim2.new(0, 16, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "HANAMI BYPASS"
titleLbl.TextColor3 = PINK
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- ===================== BODY =====================
local body = Instance.new("Frame", panel)
body.Name = "Body"
body.Size = UDim2.new(1, 0, 0, 0)
body.Position = UDim2.new(0, 0, 0, 46)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.AutomaticSize = Enum.AutomaticSize.Y

local bodyLL = Instance.new("UIListLayout", body)
bodyLL.SortOrder = Enum.SortOrder.LayoutOrder
bodyLL.Padding = UDim.new(0, 6)

local bodyPad = Instance.new("UIPadding", body)
bodyPad.PaddingLeft = UDim.new(0, 14)
bodyPad.PaddingRight = UDim.new(0, 14)
bodyPad.PaddingTop = UDim.new(0, 14)
bodyPad.PaddingBottom = UDim.new(0, 14)

-- ===================== TOGGLE ROW =====================
local bypassOn = false

local function makePill()
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 44, 0, 24)
    pill.BackgroundColor3 = Color3.fromRGB(30, 10, 20)
    pill.BorderSizePixel = 0
    mkCorner(pill, 12)
    local pillStroke = mkStroke(pill, Color3.fromRGB(194, 24, 91), 1)

    local dot = Instance.new("Frame", pill)
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = PINK_DIM
    dot.BorderSizePixel = 0
    mkCorner(dot, 8)

    local function setOn(on)
        TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = on and PINK or PINK_DIM,
        }):Play()
        TweenService:Create(pill, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Color3.fromRGB(50, 10, 30) or Color3.fromRGB(30, 10, 20),
        }):Play()
        TweenService:Create(pillStroke, TweenInfo.new(0.2), {
            Color = on and PINK or PINK_DIM,
        }):Play()
    end

    return pill, dot, setOn
end

local row = Instance.new("Frame", body)
row.Name = "BypassRow"
row.Size = UDim2.new(1, 0, 0, 52)
row.BackgroundColor3 = Color3.fromRGB(15, 5, 10)
row.BorderSizePixel = 0
row.LayoutOrder = 1
mkCorner(row, 14)
mkStroke(row, Color3.fromRGB(255, 77, 166, 0.12), 1)
local rowStroke = mkStroke(row, Color3.fromRGB(60, 15, 35), 1)

local rowLbl = Instance.new("TextLabel", row)
rowLbl.Size = UDim2.new(1, -70, 1, 0)
rowLbl.Position = UDim2.new(0, 16, 0, 0)
rowLbl.BackgroundTransparency = 1
rowLbl.Text = "BYPASS"
rowLbl.TextColor3 = PINK
rowLbl.Font = Enum.Font.GothamBold
rowLbl.TextSize = 13
rowLbl.TextXAlignment = Enum.TextXAlignment.Left

local pill, dot, setPillOn = makePill()
pill.Parent = row
pill.Position = UDim2.new(1, -54, 0.5, -12)

local rowBtn = Instance.new("TextButton", row)
rowBtn.Size = UDim2.new(1, 0, 1, 0)
rowBtn.BackgroundTransparency = 1
rowBtn.Text = ""
rowBtn.BorderSizePixel = 0
rowBtn.ZIndex = 5

rowBtn.MouseButton1Click:Connect(function()
    bypassOn = not bypassOn
    setPillOn(bypassOn)
    TweenService:Create(row, TweenInfo.new(0.2), {
        BackgroundColor3 = bypassOn and Color3.fromRGB(25, 5, 15) or Color3.fromRGB(15, 5, 10),
    }):Play()
    TweenService:Create(rowStroke, TweenInfo.new(0.2), {
        Color = bypassOn and Color3.fromRGB(255, 77, 166) or Color3.fromRGB(60, 15, 35),
    }):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.3), {
        TextTransparency = bypassOn and 0 or 0,
    }):Play()
    -- Pulse glow on panel when active
    TweenService:Create(glowStroke, TweenInfo.new(0.3), {
        Transparency = bypassOn and 0.6 or 0.85,
        Thickness    = bypassOn and 1.5 or 0,
    }):Play()
    -- Start or stop aimbot
    if bypassOn then startAimbot() else stopAimbot() end
end)

-- ===================== FOOTER =====================
local footer = Instance.new("Frame", body)
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 28)
footer.BackgroundTransparency = 1
footer.BorderSizePixel = 0
footer.LayoutOrder = 2

local ftLine = Instance.new("Frame", footer)
ftLine.Size = UDim2.new(1, 0, 0, 1)
ftLine.BackgroundColor3 = PINK
ftLine.BackgroundTransparency = 0.85
ftLine.BorderSizePixel = 0
local ftGrad = Instance.new("UIGradient", ftLine)
ftGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
})

local ftLeft = Instance.new("TextLabel", footer)
ftLeft.Size = UDim2.new(0.5, 0, 1, 0)
ftLeft.Position = UDim2.new(0, 0, 0, 4)
ftLeft.BackgroundTransparency = 1
ftLeft.Text = "HANAMI HUB"
ftLeft.TextColor3 = Color3.fromRGB(255, 77, 166)
ftLeft.TextTransparency = 0.75
ftLeft.Font = Enum.Font.GothamBold
ftLeft.TextSize = 7
ftLeft.TextXAlignment = Enum.TextXAlignment.Left

local ftRight = Instance.new("TextLabel", footer)
ftRight.Size = UDim2.new(0.5, 0, 1, 0)
ftRight.Position = UDim2.new(0.5, 0, 0, 4)
ftRight.BackgroundTransparency = 1
ftRight.Text = "v1.0"
ftRight.TextColor3 = Color3.fromRGB(255, 77, 166)
ftRight.TextTransparency = 0.8
ftRight.Font = Enum.Font.GothamBold
ftRight.TextSize = 7
ftRight.TextXAlignment = Enum.TextXAlignment.Right

-- ===================== DRAG =====================
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ===================== FADE IN =====================
panel.BackgroundTransparency = 1
panel.Position = UDim2.new(0.5, -140, 0.5, -90)
TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
    Position = UDim2.new(0.5, -140, 0.5, -80),
}):Play()

print("✅ Hanami Bypass loaded")
