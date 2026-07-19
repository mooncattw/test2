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
    if PlayerGui:FindFirstChild("DZ FLASH TP") then
        PlayerGui["DZ FLASH TP"]:Destroy()
    end
    if game.CoreGui:FindFirstChild("DZ FLASH TP") then
        game.CoreGui["DZ FLASH TP"]:Destroy()
    end
end)

-- Config
local sliderValue = 0.915
local laggerPower = 50
local speedBoostMax = 27.5
local targetFovValue = 70
local decorationTransparencyAmount = 0.75
local savePath = "NovaWave_Settings.json"
local toggleStates = {}
local activeTriggers = {}
local boostConn = nil
local fovConn = nil
local bindingAlign = false
local bindingAlignDown = false
local WHITE = Color3.fromRGB(255, 255, 255)
local GRAY = Color3.fromRGB(200, 200, 200)
local DARK_GRAY = Color3.fromRGB(30, 30, 30)
local LIGHT_BLUE = Color3.fromRGB(100, 180, 255)
local alignKey = Enum.KeyCode.V
local alignDownKey = Enum.KeyCode.B
local resetKeybind = Enum.KeyCode.Z
local rejoinKeybind = Enum.KeyCode.X
local kickKeybind = Enum.KeyCode.C
local bindingAlignKey = false
local bindingAlignDownKey = false
local bindingResetKey = false
local bindingRejoinKey = false
local bindingKickKey = false
local stealBarFill = nil
local isResetting = false
local decorationParts = {}
local decorationOriginal = {}
local decorationWatcher = nil
local decorationEnabled = false

-- Helper Functions
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

local function getCharacter()
    return LocalPlayer.Character
end

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
            if decoded.alignDownKey then alignDownKey = Enum.KeyCode[decoded.alignDownKey] or Enum.KeyCode.B end
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
                alignDownKey = alignDownKey.Name,
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

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if toggleStates["Speed Boost"] then enableSpeedBoost() end
    if toggleStates["FOV"] then enableFovChanger() end
end)

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

local function ExecuteAlignDown()
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
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromOrientation(-0.45, currentYaw, 0)
            task.wait(0.05)
            Camera.CameraType = Enum.CameraType.Custom
            root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
            task.wait(0.12)
            EquipFlash()
        end
    end
end

-- NEW GUI (Moon Hub Style)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DZ FLASH TP"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Watermark (FPS/Ping)
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
TitleLabel.Text = "DZ FLASH TP"
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

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 260)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.10
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local g = Instance.new("UIGradient")
g.Rotation = 45
g.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
})
g.Parent = MainFrame
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 4.5
mainStroke.Color = WHITE
mainStroke.Transparency = 0.08
mainStroke.Parent = MainFrame
local mainGrad = Instance.new("UIGradient", mainStroke)
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, WHITE),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
})
task.spawn(function()
    while mainStroke.Parent do
        TweenService:Create(mainGrad, TweenInfo.new(2.2, Enum.EasingStyle.Linear), {Rotation = mainGrad.Rotation + 360}):Play()
        task.wait(2.2)
    end
end)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, -14, 0, 34)
TitleBar.Position = UDim2.new(0, 7, 0, 7)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
TitleBar.BackgroundTransparency = 0.10
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 9)

local LogoDot = Instance.new("Frame")
LogoDot.Size = UDim2.new(0, 18, 0, 18)
LogoDot.Position = UDim2.new(0, 7, 0.5, -9)
LogoDot.BackgroundColor3 = WHITE
LogoDot.Parent = TitleBar
Instance.new("UICorner", LogoDot).CornerRadius = UDim.new(1, 0)
local logoStroke = Instance.new("UIStroke")
logoStroke.Thickness = 1.5
logoStroke.Color = GRAY
logoStroke.Transparency = 0.3
logoStroke.Parent = LogoDot

local LogoN = Instance.new("TextLabel")
LogoN.Size = UDim2.new(1, 0, 1, 0)
LogoN.BackgroundTransparency = 1
LogoN.Text = "D"
LogoN.TextColor3 = Color3.new(0, 0, 0)
LogoN.Font = Enum.Font.GothamBlack
LogoN.TextSize = 11
LogoN.Parent = LogoDot

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -65, 1, 0)
TitleLbl.Position = UDim2.new(0, 32, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "DZ FLASH TP"
TitleLbl.TextColor3 = WHITE
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 12
TitleLbl.Parent = TitleBar

-- Settings Frame
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(0, 175, 0, 250)
SettingsFrame.Position = UDim2.new(1, 15, 0, 0)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SettingsFrame.BackgroundTransparency = 0.10
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = MainFrame
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 14)

local gSettings = g:Clone()
gSettings.Parent = SettingsFrame
local settingsStroke = mainStroke:Clone()
settingsStroke.Parent = SettingsFrame
local settingsGrad = settingsStroke:FindFirstChildOfClass("UIGradient")
task.spawn(function()
    while settingsStroke.Parent do
        TweenService:Create(settingsGrad, TweenInfo.new(2.2, Enum.EasingStyle.Linear), {Rotation = settingsGrad.Rotation + 360}):Play()
        task.wait(2.2)
    end
end)

local SettingsTitleBar = Instance.new("Frame")
SettingsTitleBar.Size = UDim2.new(1, -14, 0, 32)
SettingsTitleBar.Position = UDim2.new(0, 7, 0, 7)
SettingsTitleBar.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
SettingsTitleBar.BackgroundTransparency = 0.10
SettingsTitleBar.Parent = SettingsFrame
Instance.new("UICorner", SettingsTitleBar).CornerRadius = UDim.new(0, 9)

local SettingsTitleLbl = Instance.new("TextLabel")
SettingsTitleLbl.Size = UDim2.new(1, 0, 1, 0)
SettingsTitleLbl.BackgroundTransparency = 1
SettingsTitleLbl.Text = "DZ Settings"
SettingsTitleLbl.TextColor3 = WHITE
SettingsTitleLbl.Font = Enum.Font.GothamBold
SettingsTitleLbl.TextSize = 11
SettingsTitleLbl.TextXAlignment = Enum.TextXAlignment.Center
SettingsTitleLbl.Parent = SettingsTitleBar

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, -6, 1, -46)
SettingsScroll.Position = UDim2.new(0, 3, 0, 42)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 4
SettingsScroll.ScrollBarImageColor3 = WHITE
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 450)
SettingsScroll.Parent = SettingsFrame

-- Plus Button
local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 20, 0, 20)
PlusBtn.Position = UDim2.new(1, -26, 0.5, -10)
PlusBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
PlusBtn.Text = "+"
PlusBtn.TextColor3 = WHITE
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 14
PlusBtn.Parent = TitleBar
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", PlusBtn).Color = WHITE

PlusBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
    PlusBtn.Text = SettingsFrame.Visible and "-" or "+"
end)

-- Helper Functions for GUI
local function roundToHalf(val)
    return math.round(val * 2) / 2
end

local function makeToggle(labelText, yPos, targetParent, isPureUi, extraAction)
    local parentFrame = targetParent or MainFrame
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 108, 0, 15)
    lbl.Position = UDim2.new(0.08, 0, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = GRAY
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.Parent = parentFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 13)
    btn.Position = UDim2.new(0.92, -30, 0, yPos + 1)
    btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Thickness = 1.2
    toggleStroke.Color = WHITE
    toggleStroke.Transparency = 0.5
    toggleStroke.Parent = btn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 9, 0, 9)
    knob.Position = UDim2.new(0, 2, 0.5, -4.5)
    knob.BackgroundColor3 = GRAY
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Thickness = 1
    knobStroke.Color = WHITE
    knobStroke.Transparency = 0.5
    knobStroke.Parent = knob

    local state = toggleStates[labelText] or false
    toggleStates[labelText] = state

    local function updateToggleVisual()
        if state then
            btn.BackgroundColor3 = LIGHT_BLUE
            knob.Position = UDim2.new(1, -11, 0.5, -4.5)
            knob.BackgroundColor3 = Color3.new(0, 0, 0)
            toggleStroke.Transparency = 0
            knobStroke.Transparency = 0.3
        else
            btn.BackgroundColor3 = WHITE
            knob.Position = UDim2.new(0, 2, 0.5, -4.5)
            knob.BackgroundColor3 = GRAY
            toggleStroke.Transparency = 0.5
            knobStroke.Transparency = 0.5
        end
    end

    updateToggleVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        toggleStates[labelText] = state
        updateToggleVisual()
        saveSettings()
        if isPureUi then
            if extraAction then extraAction(state) end
            return
        end
        if labelText == "Speed Boost" then
            if state then enableSpeedBoost() else disableSpeedBoost() end
        elseif labelText == "FOV" then
            if state then enableFovChanger() else disableFovChanger() end
        elseif labelText == "Transparency" then
            setDecorationEnabled(state)
        elseif labelText == "Auto Potion" then
            -- Handled in proximity prompt
        elseif labelText == "Lagger on Steal" then
            -- Handled in proximity prompt
        end
        if extraAction then extraAction(state) end
    end)
end

local function createTextBox(parent, size, pos, defaultText)
    local box = Instance.new("TextBox")
    box.Size = size
    box.Position = pos
    box.BackgroundTransparency = 0.15
    box.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
    box.Text = defaultText
    box.TextColor3 = WHITE
    box.Font = Enum.Font.GothamBold
    box.TextSize = 8
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.ClearTextOnFocus = false
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
    local s = Instance.new("UIStroke", box)
    s.Color = WHITE
    s.Thickness = 1
    s.Transparency = 0.3
    box.Focused:Connect(function()
        TweenService:Create(s, TweenInfo.new(0.15), {Color = WHITE, Transparency = 0}):Play()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 30, 48)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(s, TweenInfo.new(0.15), {Color = WHITE, Transparency = 0.3}):Play()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(15, 20, 32)}):Play()
    end)
    return box
end

-- Settings Toggles
makeToggle("FOV", 4, SettingsScroll, false)
makeToggle("Transparency", 24, SettingsScroll, false)
makeToggle("Auto Potion", 44, SettingsScroll, false)
makeToggle("Speed Boost", 64, SettingsScroll, false)
makeToggle("Lagger on Steal", 84, SettingsScroll, false)

-- Main Toggles
makeToggle("FLASH TP", 40)
makeToggle("GIANT POTION", 60)
makeToggle("SPEED BOOST", 80)
makeToggle("LAG", 100)

-- Align Buttons
local AlignUpBtn = Instance.new("TextButton")
AlignUpBtn.Size = UDim2.new(0.58, 0, 0, 19)
AlignUpBtn.Position = UDim2.new(0.075, 0, 0, 120)
AlignUpBtn.BackgroundColor3 = WHITE
AlignUpBtn.Text = "ALIGN UP"
AlignUpBtn.TextColor3 = Color3.new(0, 0, 0)
AlignUpBtn.Font = Enum.Font.GothamBold
AlignUpBtn.TextSize = 9
AlignUpBtn.Parent = MainFrame
Instance.new("UICorner", AlignUpBtn).CornerRadius = UDim.new(0, 5)
AlignUpBtn.MouseButton1Click:Connect(ExecuteAlign)

local AlignKeybindBtn = Instance.new("TextButton")
AlignKeybindBtn.Size = UDim2.new(0.25, 0, 0, 19)
AlignKeybindBtn.Position = UDim2.new(0.67, 0, 0, 120)
AlignKeybindBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
AlignKeybindBtn.Text = "[" .. alignKey.Name .. "]"
AlignKeybindBtn.TextColor3 = GRAY
AlignKeybindBtn.Font = Enum.Font.GothamBold
AlignKeybindBtn.TextSize = 8
AlignKeybindBtn.Parent = MainFrame
Instance.new("UICorner", AlignKeybindBtn).CornerRadius = UDim.new(0, 5)
local keybindStroke = Instance.new("UIStroke")
keybindStroke.Thickness = 1
keybindStroke.Color = WHITE
keybindStroke.Transparency = 0.4
keybindStroke.Parent = AlignKeybindBtn

AlignKeybindBtn.MouseButton1Click:Connect(function()
    bindingAlignKey = true
    AlignKeybindBtn.Text = "..."
    AlignKeybindBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
end)

local AlignDownBtn = Instance.new("TextButton")
AlignDownBtn.Size = UDim2.new(0.58, 0, 0, 19)
AlignDownBtn.Position = UDim2.new(0.075, 0, 0, 142)
AlignDownBtn.BackgroundColor3 = WHITE
AlignDownBtn.Text = "ALIGN DOWN"
AlignDownBtn.TextColor3 = Color3.new(0, 0, 0)
AlignDownBtn.Font = Enum.Font.GothamBold
AlignDownBtn.TextSize = 9
AlignDownBtn.Parent = MainFrame
Instance.new("UICorner", AlignDownBtn).CornerRadius = UDim.new(0, 5)
AlignDownBtn.MouseButton1Click:Connect(ExecuteAlignDown)

local AlignDownKeybindBtn = Instance.new("TextButton")
AlignDownKeybindBtn.Size = UDim2.new(0.25, 0, 0, 19)
AlignDownKeybindBtn.Position = UDim2.new(0.67, 0, 0, 142)
AlignDownKeybindBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
AlignDownKeybindBtn.Text = "[" .. alignDownKey.Name .. "]"
AlignDownKeybindBtn.TextColor3 = GRAY
AlignDownKeybindBtn.Font = Enum.Font.GothamBold
AlignDownKeybindBtn.TextSize = 8
AlignDownKeybindBtn.Parent = MainFrame
Instance.new("UICorner", AlignDownKeybindBtn).CornerRadius = UDim.new(0, 5)
local keybindDownStroke = Instance.new("UIStroke")
keybindDownStroke.Thickness = 1
keybindDownStroke.Color = WHITE
keybindDownStroke.Transparency = 0.4
keybindDownStroke.Parent = AlignDownKeybindBtn

AlignDownKeybindBtn.MouseButton1Click:Connect(function()
    bindingAlignDownKey = true
    AlignDownKeybindBtn.Text = "..."
    AlignDownKeybindBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
end)

-- Bar (sadece normal GUI'da, ALIGN altında)
local BarContainer = Instance.new("Frame")
BarContainer.Size = UDim2.new(0.85, 0, 0, 20)
BarContainer.Position = UDim2.new(0.075, 0, 0, 165)
BarContainer.BackgroundTransparency = 1
BarContainer.Parent = MainFrame

local BarTrack = Instance.new("Frame")
BarTrack.Size = UDim2.new(1, 0, 0, 6)
BarTrack.Position = UDim2.new(0, 0, 0, 0)
BarTrack.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
BarTrack.BorderSizePixel = 0
BarTrack.Parent = BarContainer
Instance.new("UICorner", BarTrack).CornerRadius = UDim.new(1, 0)

local barStroke = Instance.new("UIStroke", BarTrack)
barStroke.Color = WHITE
barStroke.Thickness = 1.0
barStroke.Transparency = 0.4

local BarInner = Instance.new("Frame", BarTrack)
BarInner.Size = UDim2.new(1, -2, 1, -2)
BarInner.Position = UDim2.new(0, 1, 0, 1)
BarInner.BackgroundColor3 = Color3.fromRGB(15, 18, 35)
BarInner.BorderSizePixel = 0
Instance.new("UICorner", BarInner).CornerRadius = UDim.new(1, 0)

stealBarFill = Instance.new("Frame", BarInner)
stealBarFill.Size = UDim2.new(0, 0, 1, 0)
stealBarFill.BackgroundColor3 = WHITE
stealBarFill.BorderSizePixel = 0
Instance.new("UICorner", stealBarFill).CornerRadius = UDim.new(1, 0)

-- Sliders
local SLIDER = WHITE
local TRACK = 4

-- Flash Start %
local flashSection = Instance.new("Frame")
flashSection.Size = UDim2.new(0.85, 0, 0, 28)
flashSection.Position = UDim2.new(0.075, 0, 0, 185)
flashSection.BackgroundTransparency = 1
flashSection.Parent = MainFrame

local flashLabel = Instance.new("TextLabel", flashSection)
flashLabel.Size = UDim2.new(1,0,0,9)
flashLabel.Text = "FLASH START %"
flashLabel.TextColor3 = GRAY
flashLabel.Font = Enum.Font.GothamBold
flashLabel.TextSize = 7
flashLabel.TextXAlignment = Enum.TextXAlignment.Center
flashLabel.BackgroundTransparency = 1

local percentLabel = Instance.new("TextLabel", flashSection)
percentLabel.Size = UDim2.new(1, 0, 0, 14)
percentLabel.Position = UDim2.new(0, 0, 0, 8)
percentLabel.Text = string.format("%.1f%%", sliderValue * 100)
percentLabel.TextColor3 = SLIDER
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = 7
percentLabel.TextXAlignment = Enum.TextXAlignment.Center
percentLabel.BackgroundTransparency = 1

local flashBox = createTextBox(flashSection, UDim2.new(0, 14, 0, 14), UDim2.new(1, -14, 0, 8), string.format("%.1f", sliderValue * 100))

local flashTrack = Instance.new("Frame", flashSection)
flashTrack.Size = UDim2.new(1,0,0,TRACK)
flashTrack.Position = UDim2.new(0,0,0,25)
flashTrack.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
Instance.new("UICorner", flashTrack).CornerRadius = UDim.new(1,0)

local flashFill = Instance.new("Frame", flashTrack)
flashFill.Size = UDim2.new(sliderValue,0,1,0)
flashFill.BackgroundColor3 = SLIDER
Instance.new("UICorner", flashFill).CornerRadius = UDim.new(1,0)

local flashKnob = Instance.new("Frame", flashTrack)
flashKnob.Size = UDim2.new(0,8,0,8)
flashKnob.Position = UDim2.new(sliderValue,-4,0.5,-4)
flashKnob.BackgroundColor3 = Color3.new(0,0,0)
Instance.new("UICorner", flashKnob).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", flashKnob).Color = SLIDER

local function updateFlash(v, skipBoxUpdate)
    local rounded = math.round(v / 0.005) * 0.005
    local rawPct = math.clamp(rounded, 0.01, 1.00)
    sliderValue = rawPct
    flashFill.Size = UDim2.new(sliderValue, 0, 1, 0)
    flashKnob.Position = UDim2.new(sliderValue, -4, 0.5, -4)
    percentLabel.Text = string.format("%.1f%%", sliderValue * 100)
    if not skipBoxUpdate then
        flashBox.Text = string.format("%.1f", sliderValue * 100)
    end
    saveSettings()
end

flashBox.FocusLost:Connect(function()
    local val = tonumber(flashBox.Text)
    if val then
        val = roundToHalf(val)
        val = math.clamp(val, 1, 100)
        updateFlash(val / 100, true)
    end
    flashBox.Text = string.format("%.1f", sliderValue * 100)
end)

local draggingFlash = false
flashTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFlash = true
        MainFrame.Draggable = false
        local rawPos = (input.Position.X - flashTrack.AbsolutePosition.X) / flashTrack.AbsoluteSize.X
        updateFlash(rawPos)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFlash and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rawPos = (input.Position.X - flashTrack.AbsolutePosition.X) / flashTrack.AbsoluteSize.X
        updateFlash(rawPos)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFlash = false
        MainFrame.Draggable = true
    end
end)

updateFlash(sliderValue)

-- Lag Power
local laggerSection = Instance.new("Frame")
laggerSection.Size = UDim2.new(0.85, 0, 0, 28)
laggerSection.Position = UDim2.new(0.075, 0, 0, 220)
laggerSection.BackgroundTransparency = 1
laggerSection.Parent = MainFrame

local laggerLabel = Instance.new("TextLabel", laggerSection)
laggerLabel.Size = UDim2.new(1,0,0,9)
laggerLabel.Text = "LAGGER POWER"
laggerLabel.TextColor3 = GRAY
laggerLabel.Font = Enum.Font.GothamBold
laggerLabel.TextSize = 7
laggerLabel.TextXAlignment = Enum.TextXAlignment.Center
laggerLabel.BackgroundTransparency = 1

local laggerValueLabel = Instance.new("TextLabel", laggerSection)
laggerValueLabel.Size = UDim2.new(1, 0, 0, 14)
laggerValueLabel.Position = UDim2.new(0, 0, 0, 8)
laggerValueLabel.Text = tostring(laggerPower)
laggerValueLabel.TextColor3 = SLIDER
laggerValueLabel.Font = Enum.Font.GothamBold
laggerValueLabel.TextSize = 7
laggerValueLabel.TextXAlignment = Enum.TextXAlignment.Center
laggerValueLabel.BackgroundTransparency = 1

local laggerBox = createTextBox(laggerSection, UDim2.new(0, 14, 0, 14), UDim2.new(1, -14, 0, 8), tostring(laggerPower))

local laggerTrack = Instance.new("Frame", laggerSection)
laggerTrack.Size = UDim2.new(1,0,0,TRACK)
laggerTrack.Position = UDim2.new(0,0,0,25)
laggerTrack.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
Instance.new("UICorner", laggerTrack).CornerRadius = UDim.new(1,0)

local laggerFill = Instance.new("Frame", laggerTrack)
laggerFill.Size = UDim2.new(laggerPower/100,0,1,0)
laggerFill.BackgroundColor3 = SLIDER
Instance.new("UICorner", laggerFill).CornerRadius = UDim.new(1,0)

local laggerKnob = Instance.new("Frame", laggerTrack)
laggerKnob.Size = UDim2.new(0,8,0,8)
laggerKnob.Position = UDim2.new(laggerPower/100,-4,0.5,-4)
laggerKnob.BackgroundColor3 = Color3.new(0,0,0)
Instance.new("UICorner", laggerKnob).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", laggerKnob).Color = SLIDER

local function updateLagger(v, skipBoxUpdate)
    laggerPower = math.clamp(v, 0, 100)
    laggerFill.Size = UDim2.new(laggerPower/100, 0, 1, 0)
    laggerKnob.Position = UDim2.new(laggerPower/100, -4, 0.5, -4)
    laggerValueLabel.Text = tostring(math.floor(laggerPower))
    if not skipBoxUpdate then
        laggerBox.Text = tostring(math.floor(laggerPower))
    end
    saveSettings()
end

laggerBox.FocusLost:Connect(function()
    local val = tonumber(laggerBox.Text)
    if val then
        val = roundToHalf(val)
        updateLagger(val, true)
    end
    laggerBox.Text = tostring(math.floor(laggerPower))
end)

local draggingLagger = false
laggerTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingLagger = true
        MainFrame.Draggable = false
        updateLagger((input.Position.X - laggerTrack.AbsolutePosition.X) / laggerTrack.AbsoluteSize.X * 100)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingLagger and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateLagger((input.Position.X - laggerTrack.AbsolutePosition.X) / laggerTrack.AbsoluteSize.X * 100)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingLagger = false
        MainFrame.Draggable = true
    end
end)

updateLagger(laggerPower)

-- Speed Config
local boostSection = Instance.new("Frame")
boostSection.Size = UDim2.new(0.86, 0, 0, 28)
boostSection.Position = UDim2.new(0.07, 0, 0, 255)
boostSection.BackgroundTransparency = 1
boostSection.Parent = MainFrame

local boostSliderLabel = Instance.new("TextLabel", boostSection)
boostSliderLabel.Size = UDim2.new(1,0,0,9)
boostSliderLabel.Text = "SPEED CONFIG"
boostSliderLabel.TextColor3 = GRAY
boostSliderLabel.Font = Enum.Font.GothamBold
boostSliderLabel.TextSize = 7
boostSliderLabel.TextXAlignment = Enum.TextXAlignment.Center
boostSliderLabel.BackgroundTransparency = 1

local boostValueLabel = Instance.new("TextLabel", boostSection)
boostValueLabel.Size = UDim2.new(1, 0, 0, 14)
boostValueLabel.Position = UDim2.new(0, 0, 0, 8)
boostValueLabel.Text = tostring(math.floor(speedBoostMax))
boostValueLabel.TextColor3 = SLIDER
boostValueLabel.Font = Enum.Font.GothamBold
boostValueLabel.TextSize = 7
boostValueLabel.TextXAlignment = Enum.TextXAlignment.Center
boostValueLabel.BackgroundTransparency = 1

local speedBox = createTextBox(boostSection, UDim2.new(0, 14, 0, 14), UDim2.new(1, -14, 0, 8), tostring(math.floor(speedBoostMax)))

local boostTrack = Instance.new("Frame", boostSection)
boostTrack.Size = UDim2.new(1,0,0,TRACK)
boostTrack.Position = UDim2.new(0,0,0,25)
boostTrack.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
Instance.new("UICorner", boostTrack).CornerRadius = UDim.new(1,0)

local boostFill = Instance.new("Frame", boostTrack)
boostFill.BackgroundColor3 = SLIDER
Instance.new("UICorner", boostFill).CornerRadius = UDim.new(1,0)

local boostKnob = Instance.new("Frame", boostTrack)
boostKnob.Size = UDim2.new(0,8,0,8)
boostKnob.BackgroundColor3 = Color3.new(0,0,0)
Instance.new("UICorner", boostKnob).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", boostKnob).Color = SLIDER

local function updateSpeedSlider(v, skipBoxUpdate)
    speedBoostMax = math.clamp(v, 16, 60)
    local pct = (speedBoostMax - 16) / (60 - 16)
    boostFill.Size = UDim2.new(pct, 0, 1, 0)
    boostKnob.Position = UDim2.new(pct, -4, 0.5, -4)
    boostValueLabel.Text = tostring(math.floor(speedBoostMax))
    if not skipBoxUpdate then
        speedBox.Text = tostring(math.floor(speedBoostMax))
    end
    saveSettings()
    if toggleStates["Speed Boost"] then
        enableSpeedBoost()
    end
end

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val then
        val = roundToHalf(val)
        updateSpeedSlider(val, true)
    end
    speedBox.Text = tostring(math.floor(speedBoostMax))
end)

local draggingBoost = false
boostTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBoost = true
        MainFrame.Draggable = false
        local rawPct = (input.Position.X - boostTrack.AbsolutePosition.X) / boostTrack.AbsoluteSize.X
        updateSpeedSlider(16 + (rawPct * (60 - 16)))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingBoost and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rawPct = (input.Position.X - boostTrack.AbsolutePosition.X) / boostTrack.AbsoluteSize.X
        updateSpeedSlider(16 + (rawPct * (60 - 16)))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBoost = false
        MainFrame.Draggable = true
    end
end)

updateSpeedSlider(speedBoostMax)

-- FOV Config
local fovSection = Instance.new("Frame")
fovSection.Size = UDim2.new(0.86, 0, 0, 28)
fovSection.Position = UDim2.new(0.07, 0, 0, 290)
fovSection.BackgroundTransparency = 1
fovSection.Parent = MainFrame

local fovSliderLabel = Instance.new("TextLabel", fovSection)
fovSliderLabel.Size = UDim2.new(1,0,0,9)
fovSliderLabel.Text = "FOV CONFIG"
fovSliderLabel.TextColor3 = GRAY
fovSliderLabel.Font = Enum.Font.GothamBold
fovSliderLabel.TextSize = 7
fovSliderLabel.TextXAlignment = Enum.TextXAlignment.Center
fovSliderLabel.BackgroundTransparency = 1

local fovValueLabel = Instance.new("TextLabel", fovSection)
fovValueLabel.Size = UDim2.new(1, 0, 0, 14)
fovValueLabel.Position = UDim2.new(0, 0, 0, 8)
fovValueLabel.Text = tostring(math.floor(targetFovValue))
fovValueLabel.TextColor3 = SLIDER
fovValueLabel.Font = Enum.Font.GothamBold
fovValueLabel.TextSize = 7
fovValueLabel.TextXAlignment = Enum.TextXAlignment.Center
fovValueLabel.BackgroundTransparency = 1

local fovBox = createTextBox(fovSection, UDim2.new(0, 14, 0, 14), UDim2.new(1, -14, 0, 8), tostring(math.floor(targetFovValue)))

local fovTrack = Instance.new("Frame", fovSection)
fovTrack.Size = UDim2.new(1,0,0,TRACK)
fovTrack.Position = UDim2.new(0,0,0,25)
fovTrack.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
Instance.new("UICorner", fovTrack).CornerRadius = UDim.new(1,0)

local fovFill = Instance.new("Frame", fovTrack)
fovFill.BackgroundColor3 = SLIDER
Instance.new("UICorner", fovFill).CornerRadius = UDim.new(1,0)

local fovKnob = Instance.new("Frame", fovTrack)
fovKnob.Size = UDim2.new(0,8,0,8)
fovKnob.Position = UDim2.new(0, -4, 0.5, -4)
fovKnob.BackgroundColor3 = Color3.new(0,0,0)
Instance.new("UICorner", fovKnob).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", fovKnob).Color = SLIDER

local function updateFovSlider(v, skipBoxUpdate)
    targetFovValue = math.clamp(v, 30, 120)
    local pct = (targetFovValue - 30) / (120 - 30)
    fovFill.Size = UDim2.new(pct, 0, 1, 0)
    fovKnob.Position = UDim2.new(pct, -4, 0.5, -4)
    fovValueLabel.Text = tostring(math.floor(targetFovValue))
    if not skipBoxUpdate then
        fovBox.Text = tostring(math.floor(targetFovValue))
    end
    saveSettings()
end

fovBox.FocusLost:Connect(function()
    local val = tonumber(fovBox.Text)
    if val then
        val = roundToHalf(val)
        updateFovSlider(val, true)
    end
    fovBox.Text = tostring(math.floor(targetFovValue))
end)

local draggingFov = false
fovTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFov = true
        MainFrame.Draggable = false
        local rawPct = (input.Position.X - fovTrack.AbsolutePosition.X) / fovTrack.AbsoluteSize.X
        updateFovSlider(30 + (rawPct * (120 - 30)))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFov and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rawPct = (input.Position.X - fovTrack.AbsolutePosition.X) / fovTrack.AbsoluteSize.X
        updateFovSlider(30 + (rawPct * (120 - 30)))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFov = false
        MainFrame.Draggable = true
    end
end)

updateFovSlider(targetFovValue)

-- Transparency
local transSection = Instance.new("Frame")
transSection.Size = UDim2.new(0.86, 0, 0, 28)
transSection.Position = UDim2.new(0.07, 0, 0, 48)
transSection.BackgroundTransparency = 1
transSection.Parent = SettingsScroll

local transLabel = Instance.new("TextLabel", transSection)
transLabel.Size = UDim2.new(1,0,0,9)
transLabel.Text = "TRANSPARENCY AMOUNT"
transLabel.TextColor3 = GRAY
transLabel.Font = Enum.Font.GothamBold
transLabel.TextSize = 7
transLabel.TextXAlignment = Enum.TextXAlignment.Center
transLabel.BackgroundTransparency = 1

local transValueLabel = Instance.new("TextLabel", transSection)
transValueLabel.Size = UDim2.new(1, 0, 0, 14)
transValueLabel.Position = UDim2.new(0, 0, 0, 8)
transValueLabel.Text = string.format("%.0f%%", decorationTransparencyAmount * 100)
transValueLabel.TextColor3 = SLIDER
transValueLabel.Font = Enum.Font.GothamBold
transValueLabel.TextSize = 7
transValueLabel.TextXAlignment = Enum.TextXAlignment.Center
transValueLabel.BackgroundTransparency = 1

local transBox = createTextBox(transSection, UDim2.new(0, 14, 0, 14), UDim2.new(1, -14, 0, 8), string.format("%.0f", decorationTransparencyAmount * 100))

local transTrack = Instance.new("Frame", transSection)
transTrack.Size = UDim2.new(1,0,0,TRACK)
transTrack.Position = UDim2.new(0,0,0,25)
transTrack.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
Instance.new("UICorner", transTrack).CornerRadius = UDim.new(1,0)

local transFill = Instance.new("Frame", transTrack)
transFill.BackgroundColor3 = SLIDER
Instance.new("UICorner", transFill).CornerRadius = UDim.new(1,0)

local transKnob = Instance.new("Frame", transTrack)
transKnob.Size = UDim2.new(0,8,0,8)
transKnob.BackgroundColor3 = Color3.new(0,0,0)
Instance.new("UICorner", transKnob).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", transKnob).Color = SLIDER

local function updateTransparencyAmount(v, skipBoxUpdate)
    decorationTransparencyAmount = math.clamp(v, 0, 1)
    local pct = decorationTransparencyAmount
    transFill.Size = UDim2.new(pct, 0, 1, 0)
    transKnob.Position = UDim2.new(pct, -4, 0.5, -4)
    transValueLabel.Text = string.format("%.0f%%", decorationTransparencyAmount * 100)
    if not skipBoxUpdate then
        transBox.Text = string.format("%.0f", decorationTransparencyAmount * 100)
    end
    saveSettings()
    if decorationEnabled then
        setDecorationEnabled(false)
        task.wait(0.1)
        setDecorationEnabled(true)
    end
end

transBox.FocusLost:Connect(function()
    local val = tonumber(transBox.Text)
    if val then
        val = math.clamp(val, 0, 100)
        updateTransparencyAmount(val / 100, true)
    end
    transBox.Text = string.format("%.0f", decorationTransparencyAmount * 100)
end)

local draggingTrans = false
transTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingTrans = true
        MainFrame.Draggable = false
        local rawPct = (input.Position.X - transTrack.AbsolutePosition.X) / transTrack.AbsoluteSize.X
        updateTransparencyAmount(rawPct)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingTrans and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rawPct = (input.Position.X - transTrack.AbsolutePosition.X) / transTrack.AbsoluteSize.X
        updateTransparencyAmount(rawPct)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingTrans = false
        MainFrame.Draggable = true
    end
end)

updateTransparencyAmount(decorationTransparencyAmount)

-- Utility Buttons
local function makeUtilityButtonWithKeybind(text, yPos, defaultKey, callback, bindFlagSetter)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.86, 0, 0, 20)
    container.Position = UDim2.new(0.07, 0, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = SettingsScroll

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.68, 0, 1, 0)
    btn.Position = UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = WHITE
    btn.Text = text:upper()
    btn.TextColor3 = Color3.new(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(0.28, 0, 1, 0)
    bindBtn.Position = UDim2.new(0.72, 0, 0, 0)
    bindBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    bindBtn.Text = "[" .. defaultKey.Name .. "]"
    bindBtn.TextColor3 = GRAY
    bindBtn.Font = Enum.Font.GothamBold
    bindBtn.TextSize = 8
    bindBtn.Parent = container
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 5)

    local bStroke = Instance.new("UIStroke", bindBtn)
    bStroke.Thickness = 1
    bStroke.Color = WHITE
    bStroke.Transparency = 0.4

    btn.MouseButton1Click:Connect(callback)
    bindBtn.MouseButton1Click:Connect(function()
        bindFlagSetter(true)
        bindBtn.Text = "..."
        bindBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
    end)
    return bindBtn
end

local resetBindBtn = makeUtilityButtonWithKeybind("Instant Reset", 156, resetKeybind, function() instantReset() end, function(val) bindingResetKey = val end)
local rejoinBindBtn = makeUtilityButtonWithKeybind("Rejoin Server", 182, rejoinKeybind, function() rejoin() end, function(val) bindingRejoinKey = val end)
local kickBindBtn = makeUtilityButtonWithKeybind("Kick User", 208, kickKeybind, function() game:Shutdown() end, function(val) bindingKickKey = val end)

local BottomDiscord = Instance.new("TextLabel")
BottomDiscord.Size = UDim2.new
