local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

pcall(function()
    if PlayerGui:FindFirstChild("MoonHub") then PlayerGui["MoonHub"]:Destroy() end
    if game.CoreGui:FindFirstChild("MoonHub") then game.CoreGui["MoonHub"]:Destroy() end
end)

-- Config
local sliderValue = 0.915
local laggerPower = 50
local speedBoostMax = 27.5
local savePath = "MoonHub_Settings.json"
local toggleStates = {}
local activeTriggers = {}
local boostConn = nil
local bindingAlign = false
local WHITE = Color3.fromRGB(255, 255, 255)
local LIGHT_BLUE = Color3.fromRGB(100, 180, 255)
local DARK_BLUE = Color3.fromRGB(8, 14, 32)
local MEDIUM_BLUE = Color3.fromRGB(15, 25, 55)
local alignKey = Enum.KeyCode.V
local bindingAlignKey = false
local stealBarFill = nil

-- Helper functions
local function getCharacter() return LocalPlayer.Character end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local char = getCharacter()
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    end
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(savePath) then
            local content = readfile(savePath)
            local decoded = HttpService:JSONDecode(content)
            if decoded.sliderValue then sliderValue = math.clamp(decoded.sliderValue, 0.01, 1.00) end
            if decoded.laggerPower then laggerPower = math.clamp(decoded.laggerPower, 0, 100) end
            if decoded.speedBoostMax then speedBoostMax = math.clamp(decoded.speedBoostMax, 16, 60) end
            if decoded.alignKey then alignKey = Enum.KeyCode[decoded.alignKey] or Enum.KeyCode.V end
            if decoded.speedBoost ~= nil then toggleStates["Speed Boost"] = decoded.speedBoost end
            if decoded.laggerOnSteal ~= nil then toggleStates["Lagger on Steal"] = decoded.laggerOnSteal end
            if decoded.giantPotion ~= nil then toggleStates["Giant Potion"] = decoded.giantPotion end
        end
    end)
end

local function saveSettings()
    pcall(function()
        if writefile then
            local data = {
                sliderValue = sliderValue,
                laggerPower = laggerPower,
                speedBoostMax = speedBoostMax,
                speedBoost = toggleStates["Speed Boost"] or false,
                laggerOnSteal = toggleStates["Lagger on Steal"] or false,
                giantPotion = toggleStates["Giant Potion"] or false,
                alignKey = alignKey.Name,
            }
            writefile(savePath, HttpService:JSONEncode(data))
        end
    end)
end

loadSettings()

local function triggerLagger()
    if not toggleStates["Lagger on Steal"] then return end
    task.spawn(function()
        local lagStrength = math.clamp(laggerPower / 40, 0.3, 3.0)
        settings().Network.IncomingReplicationLag = lagStrength
        task.wait(2)
        settings().Network.IncomingReplicationLag = 0
    end)
end

local function enableSpeedBoost()
    if boostConn then boostConn:Disconnect() end
    boostConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
            hrp.Velocity = Vector3.new(flatDir.X * speedBoostMax, hrp.Velocity.Y, flatDir.Z * speedBoostMax)
        end
    end)
end

local function disableSpeedBoost()
    if boostConn then
        boostConn:Disconnect()
        boostConn = nil
    end
end

local function EquipCarpet()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local carpet = backpack and backpack:FindFirstChild("Flying Carpet") or (char and char:FindFirstChild("Flying Carpet"))
    if carpet and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(carpet)
            task.wait(0.02)
        end
    end
end

local function EquipFlash()
    local flashTool = LocalPlayer.Backpack:FindFirstChild("Flash Teleport") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Flash Teleport"))
    if flashTool then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(flashTool)
        end
    end
end

local function ExecuteAlign()
    if bindingAlign then return end
    EquipCarpet()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local plots = workspace:FindFirstChild("Plots")
    if root and plots then
        local target = nil
        local dist = math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            if plot.Name == LocalPlayer.Name then continue end
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, pod in ipairs(podiums:GetChildren()) do
                    local base = pod:FindFirstChild("Base")
                    local spawn = base and base:FindFirstChild("Spawn")
                    if spawn then
                        local yDiff = math.abs(spawn.Position.Y - root.Position.Y)
                        if yDiff < 5 then
                            local d = (spawn.Position - root.Position).Magnitude
                            if d < dist then
                                dist = d
                                target = spawn
                            end
                        end
                    end
                end
            end
        end
        if target then
            root.CFrame = target.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.05)
            local _, currentYaw, _ = Camera.CFrame:ToOrientation()
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromOrientation(0.75, currentYaw, 0)
            task.wait(0.05)
            Camera.CameraType = Enum.CameraType.Custom
            root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
            task.wait(0.12)
            EquipFlash()
        end
    end
end

-- Proximity Prompt Handling
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if activeTriggers[prompt] then return end
    activeTriggers[prompt] = true
    local start = os.clock()
    local fired = false
    local conn
    if stealBarFill then stealBarFill.Size = UDim2.new(0, 0, 1, 0) end
    conn = RunService.PreRender:Connect(function()
        if not prompt or not prompt.Parent then
            conn:Disconnect()
            activeTriggers[prompt] = nil
            if stealBarFill then
                TweenService:Create(stealBarFill, TweenInfo.new(0.25), {Size = UDim2.new(0, 0, 1, 0)}):Play()
            end
            return
        end
        local progress = math.clamp((os.clock() - start) / prompt.HoldDuration, 0, 1)
        if stealBarFill then
            stealBarFill.Size = UDim2.new(progress, 0, 1, 0)
        end
        if not fired and progress >= sliderValue then
            fired = true
            conn:Disconnect()
            activeTriggers[prompt] = nil
            if stealBarFill then
                stealBarFill.Size = UDim2.new(1, 0, 1, 0)
                task.delay(0.15, function()
                    if stealBarFill then
                        TweenService:Create(stealBarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            Size = UDim2.new(0, 0, 1, 0)
                        }):Play()
                    end
                end)
            end
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                if toggleStates["Lagger on Steal"] then triggerLagger() end
                tool:Activate()
                if toggleStates["Giant Potion"] then
                    task.spawn(function()
                        task.wait(0.09)
                        local potion = LocalPlayer.Backpack:FindFirstChild("Giant Potion") or (char and char:FindFirstChild("Giant Potion"))
                        if potion then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:EquipTool(potion)
                                task.wait(0.05)
                                potion:Activate()
                            end
                        end
                    end)
                end
                if toggleStates["Speed Boost"] then enableSpeedBoost() end
            end
        end
    end)
    prompt.PromptButtonHoldEnded:Connect(function()
        if not fired then
            conn:Disconnect()
            activeTriggers[prompt] = nil
            if stealBarFill then
                TweenService:Create(stealBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 1, 0)
                }):Play()
            end
        end
    end)
end)

-- GUI Creation (Moon Hub Style)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 2
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
        while parent and parent.Parent do
            g.Rotation = (g.Rotation + spd) % 360
            task.wait()
        end
    end)
    return s, g
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 200, 0, 200)
main.Position = UDim2.new(0.5, -100, 0.5, -100)
main.BackgroundColor3 = DARK_BLUE
main.BackgroundTransparency = 0.25
main.ClipsDescendants = true
main.Active = true
main.Draggable = true
main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main
createAnimatedStroke(main, 2, 0.8)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 22)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Moon Hub Flash TP"
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.TextColor3 = WHITE
title.TextXAlignment = Enum.TextXAlignment.Left
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

-- Settings Button
local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.new(0, 28, 0, 28)
settingsBtn.Position = UDim2.new(1, -34, 0, 4)
settingsBtn.BackgroundColor3 = MEDIUM_BLUE
settingsBtn.BackgroundTransparency = 0.3
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = WHITE
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextSize = 14
settingsBtn.Parent = main
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 6)
createAnimatedStroke(settingsBtn, 1, 1.5)

-- Buttons Container
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Size = UDim2.new(1, 0, 0, 120)
buttonsContainer.Position = UDim2.new(0, 0, 0, 35)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.Parent = main

-- Settings Frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1, -20, 0, 140)
settingsFrame.Position = UDim2.new(0, 10, 0, 35)
settingsFrame.BackgroundColor3 = MEDIUM_BLUE
settingsFrame.BackgroundTransparency = 0.2
settingsFrame.Visible = false
settingsFrame.Parent = main
Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 8)
createAnimatedStroke(settingsFrame, 1, 1.2)

local settingsScroll = Instance.new("ScrollingFrame")
settingsScroll.Size = UDim2.new(1, 0, 1, 0)
settingsScroll.Position = UDim2.new(0, 0, 0, 0)
settingsScroll.BackgroundTransparency = 1
settingsScroll.ScrollBarThickness = 4
settingsScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 220)
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 180)
settingsScroll.Parent = settingsFrame

settingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
    buttonsContainer.Visible = not settingsFrame.Visible
end)

-- Slider Function
local function createSlider(parent, yPos, label, min, max, value, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.85, 0, 0, 28)
    container.Position = UDim2.new(0.075, 0, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, 0, 0, 12)
    labelText.Position = UDim2.new(0, 0, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = WHITE
    labelText.Font = Enum.Font.GothamBold
    labelText.TextSize = 8
    labelText.TextXAlignment = Enum.TextXAlignment.Center
    labelText.Parent = container

    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(1, 0, 0, 12)
    valueText.Position = UDim2.new(0, 0, 0, 12)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(math.floor(value))
    valueText.TextColor3 = LIGHT_BLUE
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 8
    valueText.TextXAlignment = Enum.TextXAlignment.Center
    valueText.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 0, 24)
    track.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
    track.Parent = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = LIGHT_BLUE
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.new(0, 0, 0)
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = LIGHT_BLUE
    knobStroke.Thickness = 1
    knobStroke.Parent = knob

    local dragging = false

    local function updateSlider(v)
        value = math.clamp(v, min, max)
        local pct = (value - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -6, 0.5, -6)
        valueText.Text = tostring(math.floor(value))
        if onChange then onChange(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            main.Draggable = false
            local rawPos = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            updateSlider(min + (rawPos * (max - min)))
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local rawPos = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            updateSlider(min + (rawPos * (max - min)))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            main.Draggable = true
        end
    end)

    updateSlider(value)
end

-- Main Toggle Buttons (renk değiştirmeyen - açık mavi/beyaz)
local function createMainToggle(name, yPos, defaultState, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 28)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.BackgroundColor3 = WHITE
    btn.Text = name:upper()
    btn.TextColor3 = Color3.new(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = buttonsContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    createAnimatedStroke(btn, 1, 1.5)

    local state = defaultState or false

    local function updateColor()
        if state then
            btn.BackgroundColor3 = LIGHT_BLUE
            btn.TextColor3 = WHITE
        else
            btn.BackgroundColor3 = WHITE
            btn.TextColor3 = Color3.new(0, 0, 0)
        end
    end

    updateColor()

    btn.MouseButton1Click:Connect(function()
        state = not state
        toggleStates[name] = state
        updateColor()
        if onToggle then onToggle(state) end
        saveSettings()
    end)
end

-- Main Buttons
createMainToggle("FLASH TP", 5, toggleStates["FLASH TP"])
createMainToggle("SPEED BOOST", 38, toggleStates["Speed Boost"], function(state)
    if state then enableSpeedBoost() else disableSpeedBoost() end
end)
createMainToggle("LAG", 71, toggleStates["Lagger on Steal"])
createMainToggle("GIANT POTION", 104, toggleStates["Giant Potion"])

-- ALIGN Button
local alignBtn = Instance.new("TextButton")
alignBtn.Size = UDim2.new(0.85, 0, 0, 28)
alignBtn.Position = UDim2.new(0.075, 0, 0, 137)
alignBtn.BackgroundColor3 = WHITE
alignBtn.Text = "ALIGN"
alignBtn.TextColor3 = Color3.new(0, 0, 0)
alignBtn.Font = Enum.Font.GothamBold
alignBtn.TextSize = 11
alignBtn.Parent = buttonsContainer
Instance.new("UICorner", alignBtn).CornerRadius = UDim.new(0, 6)
createAnimatedStroke(alignBtn, 1, 1.5)
alignBtn.MouseButton1Click:Connect(ExecuteAlign)

-- Bar (GUI içinde, ALIGN altında, discord üstünde)
local barContainer = Instance.new("Frame")
barContainer.Size = UDim2.new(1, -20, 0, 20)
barContainer.Position = UDim2.new(0, 10, 1, -45)
barContainer.BackgroundTransparency = 1
barContainer.Parent = main

local barFrame = Instance.new("Frame")
barFrame.Size = UDim2.new(1, 0, 0, 8)
barFrame.Position = UDim2.new(0, 0, 0, 0)
barFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
barFrame.BackgroundTransparency = 0.25
barFrame.BorderSizePixel = 0
barFrame.Parent = barContainer
Instance.new("UICorner", barFrame).CornerRadius = UDim.new(0, 8)
createAnimatedStroke(barFrame, 1.5, 0.8)

local barTrack = Instance.new("Frame")
barTrack.Size = UDim2.new(1, 0, 0, 6)
barTrack.Position = UDim2.new(0, 0, 0, 1)
barTrack.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
barTrack.BorderSizePixel = 0
barTrack.Parent = barFrame
Instance.new("UICorner", barTrack).CornerRadius = UDim.new(1, 0)

local barInner = Instance.new("Frame", barTrack)
barInner.Size = UDim2.new(1, -2, 1, -2)
barInner.Position = UDim2.new(0, 1, 0, 1)
barInner.BackgroundColor3 = Color3.fromRGB(15, 18, 35)
barInner.BorderSizePixel = 0
Instance.new("UICorner", barInner).CornerRadius = UDim.new(1, 0)

stealBarFill = Instance.new("Frame", barInner)
stealBarFill.Size = UDim2.new(0, 0, 1, 0)
stealBarFill.BackgroundColor3 = WHITE
stealBarFill.BorderSizePixel = 0
Instance.new("UICorner", stealBarFill).CornerRadius = UDim.new(1, 0)

-- Discord Label
local discordLabel = Instance.new("TextLabel")
discordLabel.Size = UDim2.new(1, 0, 0, 14)
discordLabel.Position = UDim2.new(0, 0, 1, -25)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = "discord.gg/moonhub"
discordLabel.TextColor3 = WHITE
discordLabel.Font = Enum.Font.Gotham
discordLabel.TextSize = 10
discordLabel.TextXAlignment = Enum.TextXAlignment.Center
discordLabel.Parent = main

-- Settings Sliders (sadece 3 bar)
createSlider(settingsScroll, 10, "TRIGGER START %", 1, 100, sliderValue * 100, function(v)
    sliderValue = v / 100
    saveSettings()
end)

createSlider(settingsScroll, 50, "LAG AMOUNT", 0, 100, laggerPower, function(v)
    laggerPower = v
    saveSettings()
end)

createSlider(settingsScroll, 90, "SPEED", 16, 60, speedBoostMax, function(v)
    speedBoostMax = v
    saveSettings()
    if toggleStates["Speed Boost"] then
        disableSpeedBoost()
        enableSpeedBoost()
    end
end)

-- Align Keybind Setting
local alignKeyContainer = Instance.new("Frame")
alignKeyContainer.Size = UDim2.new(0.85, 0, 0, 22)
alignKeyContainer.Position = UDim2.new(0.075, 0, 0, 140)
alignKeyContainer.BackgroundTransparency = 1
alignKeyContainer.Parent = settingsScroll

local alignKeyLabel = Instance.new("TextLabel")
alignKeyLabel.Size = UDim2.new(0.6, 0, 1, 0)
alignKeyLabel.Position = UDim2.new(0, 0, 0, 0)
alignKeyLabel.BackgroundTransparency = 1
alignKeyLabel.Text = "ALIGN KEY"
alignKeyLabel.TextColor3 = WHITE
alignKeyLabel.Font = Enum.Font.GothamBold
alignKeyLabel.TextSize = 9
alignKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
alignKeyLabel.Parent = alignKeyContainer

local alignKeyBtn = Instance.new("TextButton")
alignKeyBtn.Size = UDim2.new(0.35, 0, 1, 0)
alignKeyBtn.Position = UDim2.new(0.65, 0, 0, 0)
alignKeyBtn.BackgroundColor3 = MEDIUM_BLUE
alignKeyBtn.BackgroundTransparency = 0.3
alignKeyBtn.Text = "[" .. alignKey.Name .. "]"
alignKeyBtn.TextColor3 = WHITE
alignKeyBtn.Font = Enum.Font.GothamBold
alignKeyBtn.TextSize = 8
alignKeyBtn.Parent = alignKeyContainer
Instance.new("UICorner", alignKeyBtn).CornerRadius = UDim.new(0, 4)
createAnimatedStroke(alignKeyBtn, 1, 1.5)

alignKeyBtn.MouseButton1Click:Connect(function()
    bindingAlignKey = true
    alignKeyBtn.Text = "[...]"
end)

-- Keybind Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if bindingAlignKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.MouseButton1 then
            alignKey = input.KeyCode
            bindingAlignKey = false
            alignKeyBtn.Text = "[" .. alignKey.Name .. "]"
            saveSettings()
        end
        return
    end

    if input.KeyCode == alignKey then
        ExecuteAlign()
    end
end)

-- Character Added Handling
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if toggleStates["Speed Boost"] then enableSpeedBoost() end
end)
