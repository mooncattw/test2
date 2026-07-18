local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Draggable = true,
    TpBatKey = nil,
}

local tpBatToggled = false
local tpBatCooldown = false
local FILE_NAME = "moonhubtpbat.json"

local function saveConfig()
    local success, err = pcall(function()
        if writefile then
            local data = {
                TpBatKey = CONFIG.TpBatKey and CONFIG.TpBatKey.Name or nil
            }
            writefile(FILE_NAME, HttpService:JSONEncode(data))
        end
    end)
end

local function loadConfig()
    local success, err = pcall(function()
        if readfile and isfile and isfile(FILE_NAME) then
            local content = readfile(FILE_NAME)
            local data = HttpService:JSONDecode(content)
            if data and data.TpBatKey then
                CONFIG.TpBatKey = Enum.KeyCode[data.TpBatKey]
            end
        end
    end)
end

loadConfig()

local function getHRP()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getBat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        tool = bp:FindFirstChild("Bat")
        if tool then
            tool.Parent = char
            return tool
        end
    end
    return nil
end

local function tryHitBat()
    if tpBatCooldown then return end
    tpBatCooldown = true
    pcall(function()
        local bat = getBat()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() tpBatCooldown = false end)
end

local function getClosestPlayer()
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then cd = d; cp = p end
            end
        end
    end
    return cp, cd
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonHub_New"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = Color3.new(1, 1, 1)
    s.Parent = parent

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 50, 150)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 50, 150)),
    })
    g.Rotation = 0
    g.Parent = s

    task.spawn(function()
        local spd = speed or 1.2
        while parent.Parent do
            g.Rotation = (g.Rotation + spd) % 360
            task.wait()
        end
    end)

    return s, g
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 95)
main.Position = UDim2.new(0.5, -110, 0.5, -47)
main.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
main.BackgroundTransparency = 0.25
main.ClipsDescendants = true
main.Active = true
main.Parent = ScreenGui

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

createAnimatedStroke(main, 2, 0.8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 20)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 9
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 160, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 160, 255)),
})
titleGrad.Parent = title

task.spawn(function()
    while main.Parent do
        titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
        task.wait()
    end
end)

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 15)
subtitle.Position = UDim2.new(0, 10, 0, 23)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Tp Bat/Anti Desync"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.new(1, 1, 1)
subtitle.TextTransparency = 0.3
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 9
subtitle.Parent = main

local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -20, 0, 40)
toggleRow.Position = UDim2.new(0, 10, 0, 45)
toggleRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
toggleRow.ZIndex = 2
toggleRow.Parent = main

Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1, 1.2)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0, 60, 1, 0)
toggleLabel.Position = UDim2.new(0, 10, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "TP Bat"
toggleLabel.Font = Enum.Font.GothamBlack
toggleLabel.TextSize = 13
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.ZIndex = 3
toggleLabel.Parent = toggleRow

local switchBg = Instance.new("Frame")
switchBg.Size = UDim2.new(0, 36, 0, 18)
switchBg.Position = UDim2.new(1, -46, 0.5, -9)
switchBg.BackgroundTransparency = 1
switchBg.ZIndex = 3
switchBg.Parent = toggleRow

Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 9)
createAnimatedStroke(switchBg, 2, 1.5)

local switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 14, 0, 14)
switchKnob.Position = UDim2.new(0, 2, 0.5, -7)
switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
switchKnob.ZIndex = 4
switchKnob.Parent = switchBg

Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 7)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.ZIndex = 4
toggleBtn.Parent = toggleRow

local kbBtn = Instance.new("TextButton")
kbBtn.Size = UDim2.new(0, 55, 0, 22)
kbBtn.Position = UDim2.new(0, 65, 0.5, -11)
kbBtn.BackgroundColor3 = Color3.fromRGB(25, 45, 95)
kbBtn.BackgroundTransparency = 0.3
kbBtn.AutoButtonColor = false
kbBtn.Font = Enum.Font.GothamBlack
kbBtn.ZIndex = 5

if CONFIG.TpBatKey then
    kbBtn.Text = "[ " .. CONFIG.TpBatKey.Name .. " ]"
else
    kbBtn.Text = "[ ... ]"
end

kbBtn.TextSize = 10
kbBtn.TextColor3 = Color3.new(1, 1, 1)
kbBtn.Parent = toggleRow

Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 5)
createAnimatedStroke(kbBtn, 1, 1.5)

local function setToggle(newState)
    tpBatToggled = newState
    local goal = newState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local color = newState and Color3.fromRGB(40, 100, 220) or Color3.fromRGB(20, 35, 75)
    TweenService:Create(switchKnob, TweenInfo.new(0.15), {Position = goal}):Play()
    TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
end

toggleBtn.MouseButton1Click:Connect(function()
    setToggle(not tpBatToggled)
end)

local listeningForKey = false

kbBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    kbBtn.Text = "[ ... ]"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CONFIG.TpBatKey = input.KeyCode
            kbBtn.Text = "[ " .. input.KeyCode.Name .. " ]"
            saveConfig()
            listeningForKey = false
        end
        return
    end
    if CONFIG.TpBatKey and input.KeyCode == CONFIG.TpBatKey then
        setToggle(not tpBatToggled)
    end
end)

RunService.Heartbeat:Connect(function()
    if not tpBatToggled then return end
    local hrp = getHRP()
    if not hrp then return end

    local target = getClosestPlayer()
    if target and target.Character then
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            if sethiddenproperty then
                sethiddenproperty(hrp, "PhysicsRepRootPart", tr)
            end
            local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
            if (hrp.Position - targetPos).Magnitude > 8 then
                hrp.CFrame = CFrame.new(targetPos)
            end
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
            tryHitBat()
        end
    end
end)

setToggle(false)
