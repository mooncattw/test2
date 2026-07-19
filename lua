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
local targetFovValue = 70
local decorationTransparencyAmount = 0.75
local savePath = "MoonHub_Settings.json"
local toggleStates = {}
local activeTriggers = {}
local boostConn = nil
local fovConn = nil
local bindingAlign = false
local WHITE = Color3.fromRGB(255, 255, 255)
local BLUE = Color3.fromRGB(40, 100, 220)
local DARK_BLUE = Color3.fromRGB(8, 14, 32)
local MEDIUM_BLUE = Color3.fromRGB(15, 25, 55)
local alignKey = Enum.KeyCode.V
local resetKeybind = Enum.KeyCode.Z
local rejoinKeybind = Enum.KeyCode.X
local kickKeybind = Enum.KeyCode.C
local bindingAlignKey = false
local bindingResetKey = false
local bindingRejoinKey = false
local bindingKickKey = false
local stealBarFill = nil
local isResetting = false
local decorationParts = {}
local decorationOriginal = {}
local decorationWatcher = nil
local decorationEnabled = false

-- Helper functions (from original script)
local function getDecorationParts()
    local parts = {}
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return parts end
    for _, plot in ipairs(plots:GetChildren()) do
        local decorations = plot:FindFirstChild("Decorations")
        if decorations then
            for _, part in ipairs(decorations:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(parts, part)
                end
            end
        end
    end
    return parts
end

local function enableDecorationTransparency()
    local parts = getDecorationParts()
    for _, part in ipairs(parts) do
        if not decorationOriginal[part] then
            decorationOriginal[part] = part.Transparency
        end
        part.Transparency = decorationTransparencyAmount
        table.insert(decorationParts, part)
    end
end

local function disableDecorationTransparency()
    for part, orig in pairs(decorationOriginal) do
        if part and part.Parent then
            part.Transparency = orig
        end
    end
    decorationOriginal = {}
    decorationParts = {}
end

local function startDecorationWatcher()
    if decorationWatcher then decorationWatcher:Disconnect() end
    decorationWatcher = Workspace.DescendantAdded:Connect(function(obj)
        if not decorationEnabled then return end
        if obj:IsA("BasePart") then
            local plots = Workspace:FindFirstChild("Plots")
            if plots and obj:IsDescendantOf(plots) then
                local decorations = obj:FindFirstAncestor("Decorations")
                if decorations then
                    if not decorationOriginal[obj] then
                        decorationOriginal[obj] = obj.Transparency
                    end
                    task.wait(0.05)
                    if obj and obj.Parent then
                        obj.Transparency = decorationTransparencyAmount
                    end
                end
            end
        end
    end)
end

local function stopDecorationWatcher()
    if decorationWatcher then
        decorationWatcher:Disconnect()
        decorationWatcher = nil
    end
end

local function setDecorationEnabled(state)
    decorationEnabled = state
    if state then
        enableDecorationTransparency()
        startDecorationWatcher()
    else
        stopDecorationWatcher()
        disableDecorationTransparency()
    end
end

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

local function instantReset()
    local char = getCharacter()
    if isResetting or not char then return end
    isResetting = true
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.LocalTransparencyModifier = 1
        hrp.CFrame = CFrame.new(0, 9.99999978e21, 9.99999978e21)
    end
    char:BreakJoints()
    local hum = getHumanoid()
    if hum then hum.Health = 0 end
    task.wait(0.5)
    isResetting = false
end

local function rejoin()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

local function loadSettings()
    pcall(function()
        if isfile and isfile(savePath) then
            local content = readfile(savePath)
            local decoded = HttpService:JSONDecode(content)
            if decoded.sliderValue then sliderValue = math.clamp(decoded.sliderValue, 0.01, 1.00) end
            if decoded.laggerPower then laggerPower = math.clamp(decoded.laggerPower, 0, 100) end
            if decoded.speedBoostMax then speedBoostMax = math.clamp(decoded.speedBoostMax, 16, 60) end
            if decoded.targetFovValue then targetFovValue = math.clamp(decoded.targetFovValue, 30, 120) end
            if decoded.decorationTransparencyAmount then decorationTransparencyAmount = math.clamp(decoded.decorationTransparencyAmount, 0, 1) end
            if decoded.decorationEnabled ~= nil then decorationEnabled = decoded.decorationEnabled end
            if decoded.autoPotion ~= nil then toggleStates["Auto Potion"] = decoded.autoPotion end
            if decoded.speedBoost ~= nil then toggleStates["Speed Boost"] = decoded.speedBoost end
            if decoded.laggerOnSteal ~= nil then toggleStates["Lagger on Steal"] = decoded.laggerOnSteal end
            if decoded.fovToggle ~= nil then toggleStates["FOV"] = decoded.fovToggle end
            if decoded.alignKey then alignKey = Enum.KeyCode[decoded.alignKey] or Enum.KeyCode.V end
            if decoded.resetKeybind then resetKeybind = Enum.KeyCode[decoded.resetKeybind] or Enum.KeyCode.Z end
            if decoded.rejoinKeybind then rejoinKeybind = Enum.KeyCode[decoded.rejoinKeybind] or Enum.KeyCode.X end
            if decoded.kickKeybind then kickKeybind = Enum.KeyCode[decoded.kickKeybind] or Enum.KeyCode.C end
        end
    end)
    if decorationEnabled then setDecorationEnabled(true) end
end

local function saveSettings()
    pcall(function()
        if writefile then
            local data = {
                sliderValue = sliderValue,
                laggerPower = laggerPower,
                speedBoostMax = speedBoostMax,
                targetFovValue = targetFovValue,
                decorationTransparencyAmount = decorationTransparencyAmount,
                decorationEnabled = decorationEnabled,
                autoPotion = toggleStates["Auto Potion"] or false,
                speedBoost = toggleStates["Speed Boost"] or false,
                laggerOnSteal = toggleStates["Lagger on Steal"] or false,
                fovToggle = toggleStates["FOV"] or false,
                alignKey = alignKey.Name,
                resetKeybind = resetKeybind.Name,
                rejoinKeybind = rejoinKeybind.Name,
                kickKeybind = kickKeybind.Name,
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

local function enableFovChanger()
    if fovConn then fovConn:Disconnect() end
    fovConn = RunService.RenderStepped:Connect(function()
        if toggleStates["FOV"] then
            Camera.FieldOfView = targetFovValue
        end
    end)
end

local function disableFovChanger()
    if fovConn then
        fovConn:Disconnect()
        fovConn = nil
    end
    Camera.FieldOfView = 70
end

if toggleStates["Speed Boost"] then enableSpeedBoost() end
if toggleStates["FOV"] then enableFovChanger() end

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
                if toggleStates["Auto Potion"] then
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
main.Size = UDim2.new(0, 220, 0, 320)
main.Position = UDim2.new(0.5, -110, 0.5, -160)
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
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextColor3 = WHITE
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

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 14)
subtitle.Position = UDim2.new(0, 10, 0, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "DZ Flash TP"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = WHITE
subtitle.TextTransparency = 0.3
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 9
subtitle.Parent = main

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

-- Settings Frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1, -20, 1, -60)
settingsFrame.Position = UDim2.new(0, 10, 0, 50)
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
settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 450)
settingsScroll.Parent = settingsFrame

settingsBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
end)

-- Toggle Function
local function makeToggle(labelText, yPos, defaultState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.85, 0, 0, 22)
    container.Position = UDim2.new(0.075, 0, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = settingsScroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = WHITE
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 36, 0, 18)
    btn.Position = UDim2.new(1, -40, 0.5, -9)
    btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Thickness = 1.2
    toggleStroke.Color = BLUE
    toggleStroke.Transparency = 0.5
    toggleStroke.Parent = btn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = WHITE
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = defaultState or false
    if state then
        btn.BackgroundColor3 = BLUE
        knob.Position = UDim2.new(1, -14, 0.5, -6)
        knob.BackgroundColor3 = WHITE
        toggleStroke.Transparency = 0
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        local t = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        if state then
            TweenService:Create(btn, t, {BackgroundColor3 = BLUE}):Play()
            TweenService:Create(knob, t, {Position = UDim2.new(1, -14, 0.5, -6)}):Play()
            TweenService:Create(toggleStroke, t, {Transparency = 0}):Play()
        else
            TweenService:Create(btn, t, {BackgroundColor3 = Color3.fromRGB(35, 40, 55)}):Play()
            TweenService:Create(knob, t, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
            TweenService:Create(toggleStroke, t, {Transparency = 0.5}):Play()
        end
        if callback then callback(state) end
        saveSettings()
    end)

    return function(newState)
        state = newState
        if state then
            btn.BackgroundColor3 = BLUE
            knob.Position = UDim2.new(1, -14, 0.5, -6)
            toggleStroke.Transparency = 0
        else
            btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            knob.Position = UDim2.new(0, 2, 0.5, -6)
            toggleStroke.Transparency = 0.5
        end
    end
end

-- Sliders
local function createSlider(parent, yPos, label, min, max, value, onChange)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.85, 0, 0, 40)
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
    valueText.TextColor3 = BLUE
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 8
    valueText.TextXAlignment = Enum.TextXAlignment.Center
    valueText.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
    track.Parent = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = BLUE
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.new(0, 0, 0)
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = BLUE
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

-- Main Toggle Buttons
local function createMainToggle(name, yPos, defaultState, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 28)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.BackgroundColor3 = WHITE
    btn.Text = name:upper()
    btn.TextColor3 = Color3.new(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    createAnimatedStroke(btn, 1, 1.5)

    local state = defaultState or false
    if state then
        btn.BackgroundColor3 = BLUE
        btn.TextColor3 = WHITE
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = BLUE, TextColor3 = WHITE}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = WHITE, TextColor3 = Color3.new(0, 0, 0)}):Play()
        end
        if onToggle then onToggle(state) end
        saveSettings()
    end)

    return function(newState)
        state = newState
        if state then
            btn.BackgroundColor3 = BLUE
            btn.TextColor3 = WHITE
        else
            btn.BackgroundColor3 = WHITE
            btn.TextColor3 = Color3.new(0, 0, 0)
        end
    end
end

-- Main Buttons
local flashToggle = createMainToggle("FLASH TP", 60, toggleStates["Flash TP"], function(state)
    toggleStates["Flash TP"] = state
end)

local speedToggle = createMainToggle("SPEED BOOST", 95, toggleStates["Speed Boost"], function(state)
    toggleStates["Speed Boost"] = state
    if state then enableSpeedBoost() else disableSpeedBoost() end
end)

local lagToggle = createMainToggle("LAG", 130, toggleStates["Lagger on Steal"], function(state)
    toggleStates["Lagger on Steal"] = state
end)

local alignBtn = Instance.new("TextButton")
alignBtn.Size = UDim2.new(0.85, 0, 0, 28)
alignBtn.Position = UDim2.new(0.075, 0, 0, 165)
alignBtn.BackgroundColor3 = WHITE
alignBtn.Text = "ALIGN"
alignBtn.TextColor3 = Color3.new(0, 0, 0)
alignBtn.Font = Enum.Font.GothamBold
alignBtn.TextSize = 10
alignBtn.Parent = main
Instance.new("UICorner", alignBtn).CornerRadius = UDim.new(0, 6)
createAnimatedStroke(alignBtn, 1, 1.5)
alignBtn.MouseButton1Click:Connect(ExecuteAlign)

-- Settings Toggles
makeToggle("FOV", 10, toggleStates["FOV"], function(state)
    toggleStates["FOV"] = state
    if state then enableFovChanger() else disableFovChanger() end
end)

makeToggle("Transparency", 40, decorationEnabled, function(state)
    setDecorationEnabled(state)
    decorationEnabled = state
end)

makeToggle("Auto Potion", 70, toggleStates["Auto Potion"], function(state)
    toggleStates["Auto Potion"] = state
end)

-- Sliders
createSlider(settingsScroll, 100, "FLASH START %", 1, 100, sliderValue * 100, function(v)
    sliderValue = v / 100
    saveSettings()
end)

createSlider(settingsScroll, 150, "LAGGER POWER", 0, 100, laggerPower, function(v)
    laggerPower = v
    saveSettings()
end)

createSlider(settingsScroll, 200, "SPEED CONFIG", 16, 60, speedBoostMax, function(v)
    speedBoostMax = v
    saveSettings()
    if toggleStates["Speed Boost"] then
        disableSpeedBoost()
        enableSpeedBoost()
    end
end)

createSlider(settingsScroll, 250, "FOV CONFIG", 30, 120, targetFovValue, function(v)
    targetFovValue = v
    saveSettings()
end)

createSlider(settingsScroll, 300, "TRANSPARENCY %", 0, 100, decorationTransparencyAmount * 100, function(v)
    decorationTransparencyAmount = v / 100
    saveSettings()
    if decorationEnabled then
        setDecorationEnabled(false)
        task.wait(0.1)
        setDecorationEnabled(true)
    end
end)

-- Utility Buttons with Keybinds
local function createUtilityButton(text, yPos, defaultKey, callback, bindFlag)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.85, 0, 0, 22)
    container.Position = UDim2.new(0.075, 0, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = settingsScroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.6, 0, 1, 0)
    btn.Position = UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = WHITE
    btn.Text = text:upper()
    btn.TextColor3 = Color3.new(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    createAnimatedStroke(btn, 1, 1.5)

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0.35, 0, 1, 0)
    bindBtn.Position = UDim2.new(0.65, 0, 0, 0)
    bindBtn.BackgroundColor3 = MEDIUM_BLUE
    bindBtn.BackgroundTransparency = 0.3
    bindBtn.Text = "[" .. (defaultKey and defaultKey.Name or "...") .. "]"
    bindBtn.TextColor3 = WHITE
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 8
    bindBtn.Parent = container
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 4)
    createAnimatedStroke(bindBtn, 1, 1.5)

    btn.MouseButton1Click:Connect(callback)

    bindBtn.MouseButton1Click:Connect(function()
        bindFlag[1] = true
        bindBtn.Text = "[...]"
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if bindFlag[1] then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                bindFlag[1] = false
                bindBtn.Text = "[" .. input.KeyCode.Name .. "]"
                bindFlag[2] = input.KeyCode
                saveSettings()
            end
        end
    end)

    return bindBtn
end

local resetBind = {false, resetKeybind}
createUtilityButton("INSTANT RESET", 350, resetKeybind, instantReset, resetBind)

local rejoinBind = {false, rejoinKeybind}
createUtilityButton("REJOIN", 380, rejoinKeybind, rejoin, rejoinBind)

local kickBind = {false, kickKeybind}
createUtilityButton("KICK", 410, kickKeybind, function() game:Shutdown() end, kickBind)

-- Align Keybind
local alignKeyContainer = Instance.new("Frame")
alignKeyContainer.Size = UDim2.new(0.85, 0, 0, 22)
alignKeyContainer.Position = UDim2.new(0.075, 0, 0, 195)
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

-- Watermark
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Name = "TopWatermark"
WatermarkFrame.Size = UDim2.new(0, 160, 0, 30)
WatermarkFrame.Position = UDim2.new(0.5, -80, 0, 4)
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WatermarkFrame.BackgroundTransparency = 0.25
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Parent = ScreenGui
Instance.new("UICorner", WatermarkFrame).CornerRadius = UDim.new(0, 8)

local wmStroke = Instance.new("UIStroke")
wmStroke.Thickness = 2
wmStroke.Color = WHITE
wmStroke.Transparency = 0.15
wmStroke.Parent = WatermarkFrame
local wmGrad = Instance.new("UIGradient", wmStroke)
wmGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, WHITE),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
})
task.spawn(function()
    while wmStroke.Parent do
        TweenService:Create(wmGrad, TweenInfo.new(3, Enum.EasingStyle.Linear), {Rotation = wmGrad.Rotation + 360}):Play()
        task.wait(3)
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 12)
TitleLabel.Position = UDim2.new(0, 0, 0, 2)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MOON HUB"
TitleLabel.TextColor3 = WHITE
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 10
TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TitleLabel.TextStrokeTransparency = 0.4
TitleLabel.Parent = WatermarkFrame

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, 0, 0, 14)
StatsLabel.Position = UDim2.new(0, 0, 0, 13)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Font = Enum.Font.FredokaOne
StatsLabel.TextSize = 13
StatsLabel.TextColor3 = WHITE
StatsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
StatsLabel.TextStrokeTransparency = 0
StatsLabel.Text = "0 | 0"
StatsLabel.TextXAlignment = Enum.TextXAlignment.Center
StatsLabel.Parent = WatermarkFrame

RunService.Heartbeat:Connect(function()
    local success, pingValue = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    local ping = success and math.floor(pingValue) or 0
    local fps = 60
    pcall(function()
        fps = math.floor(1 / RunService.RenderStepped:Wait())
    end)
    StatsLabel.Text = ping .. " | " .. fps
end)

-- Steal Bar in Watermark
local WatermarkStealTrack = Instance.new("Frame")
WatermarkStealTrack.Size = UDim2.new(0.85, 0, 0, 6)
WatermarkStealTrack.Position = UDim2.new(0.075, 0, 0, 28)
WatermarkStealTrack.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
WatermarkStealTrack.BorderSizePixel = 0
WatermarkStealTrack.Parent = WatermarkFrame
Instance.new("UICorner", WatermarkStealTrack).CornerRadius = UDim.new(1, 0)

local wmStealStroke = Instance.new("UIStroke", WatermarkStealTrack)
wmStealStroke.Color = WHITE
wmStealStroke.Thickness = 1.0
wmStealStroke.Transparency = 0.4

local wmStealInner = Instance.new("Frame", WatermarkStealTrack)
wmStealInner.Size = UDim2.new(1, -2, 1, -2)
wmStealInner.Position = UDim2.new(0, 1, 0, 1)
wmStealInner.BackgroundColor3 = Color3.fromRGB(15, 18, 35)
wmStealInner.BorderSizePixel = 0
Instance.new("UICorner", wmStealInner).CornerRadius = UDim.new(1, 0)

stealBarFill = Instance.new("Frame", wmStealInner)
stealBarFill.Size = UDim2.new(0, 0, 1, 0)
stealBarFill.BackgroundColor3 = WHITE
stealBarFill.BorderSizePixel = 0
Instance.new("UICorner", stealBarFill).CornerRadius = UDim.new(1, 0)

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

    if resetBind[1] then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.MouseButton1 then
            resetKeybind = input.KeyCode
            resetBind[1] = false
            resetBind[2] = input.KeyCode
            saveSettings()
        end
        return
    end

    if rejoinBind[1] then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.MouseButton1 then
            rejoinKeybind = input.KeyCode
            rejoinBind[1] = false
            rejoinBind[2] = input.KeyCode
            saveSettings()
        end
        return
    end

    if kickBind[1] then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.MouseButton1 then
            kickKeybind = input.KeyCode
            kickBind[1] = false
            kickBind[2] = input.KeyCode
            saveSettings()
        end
        return
    end

    if input.KeyCode == alignKey then
        ExecuteAlign()
    elseif input.KeyCode == resetKeybind then
        instantReset()
    elseif input.KeyCode == rejoinKeybind then
        rejoin()
    elseif input.KeyCode == kickKeybind then
        game:Shutdown()
    end
end)

-- Character Added Handling
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if toggleStates["Speed Boost"] then enableSpeedBoost() end
    if toggleStates["FOV"] then enableFovChanger() end
end)
