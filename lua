_G.ScriptEnabled = true
_G.CasingType = "Normal"
_G.AutoWriteEnabled = true
_G.AutoSubmitEnabled = true

local activeConnections = {}
local pendingQueue = {}
local pendingSeen = {}
local writeBusy = false
local collectedCodes = {}
local collectedSeen = {}
local CODE_SEPARATOR = ""

_G.SubmitAfterCount = 2
_G.SubmitAttempts = 10

local ScreenGui = nil
local MainFrame = nil
local CollectedLabel = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function updateCollectedLabel()
    if CollectedLabel then
        CollectedLabel.Text = "Collected: " .. #collectedCodes .. "/" .. _G.SubmitAfterCount
    end
end

local function logStatus(message)
    if MainFrame and MainFrame:FindFirstChild("StatusLabel") then
        MainFrame.StatusLabel.Text = message
    end
end

local function isGuiVisible(obj)
    if not obj or not obj.Visible then return false end
    local current = obj.Parent
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

local blacklistedWords = {"top", "sec", "min", "fps", "ping", "loading", "points", "coins", "cash", "rebirth", "slaps", "money", "speed", "level", "lvl", "score"}
local commonWords = {["the"]=true,["and"]=true,["for"]=true,["you"]=true,["your"]=true,["now"]=true,["new"]=true,["use"]=true,["get"]=true,["out"]=true,["all"]=true,["are"]=true,["can"]=true,["with"]=true,["from"]=true,["this"]=true,["that"]=true,["here"]=true,["more"]=true,["info"]=true,["redeem"]=true,["claim"]=true,["enter"]=true,["reward"]=true}

local function isBlacklisted(lowerText)
    if commonWords[lowerText] then return true end
    for _, word in ipairs(blacklistedWords) do
        if lowerText:find(word, 1, true) then return true end
    end
    return false
end

local function looksLikeCode(token)
    if not token or #token < 4 or #token > 20 then return false end
    if not token:match("^%w+$") then return false end
    if isBlacklisted(token:lower()) then return false end
    local letterCount = 0
    for _ in token:gmatch("%a") do letterCount += 1 end
    if letterCount < 3 then return false end
    if token:match("^%d+[smhdSMHD]$") then return false end
    local hasDigit = token:match("%d") ~= nil
    local isAllUpper = (token == token:upper()) and token:match("%a")
    return hasDigit or isAllUpper
end

local function extractCodesFromText(text)
    local found = {}
    if not text then return found end
    local trimmed = text:match("^%s*(.-)%s*$"):gsub("<[^>]->", "")
    if looksLikeCode(trimmed) then
        table.insert(found, trimmed)
        return found
    end
    for token in text:gmatch("%w+") do
        if looksLikeCode(token) then table.insert(found, token) end
    end
    return found
end

local function copyCodeToClipboard(code)
    if setclipboard then pcall(function() setclipboard(code) end) end
    logStatus("Copied: " .. code)
end

local function formatCode(code) return code end

local _cachedBox = nil
local function _isCodeBox(obj)
    if not obj:IsA("TextBox") then return false end
    if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
    local hint = ((obj.PlaceholderText or "") .. " " .. obj.Name):lower()
    return hint:find("code") or hint:find("redeem") or hint:find("here")
end

local function findCodeTextBox()
    if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then return _cachedBox end
    _cachedBox = nil
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if _isCodeBox(obj) and isGuiVisible(obj) then
            _cachedBox = obj
            return obj
        end
    end
    return nil
end

local function fireSignal(sig)
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(sig)) do if c.Fire then c:Fire() end end
        end
    end)
    if firesignal then pcall(function() firesignal(sig) end) end
end

local _rfRemote = nil
local function redeemViaRF(code)
    local rfFolder = ReplicatedStorage:FindFirstChild("RF")
    if rfFolder then
        local rf = rfFolder:FindFirstChild("RequestRedemption")
        if rf and rf:IsA("RemoteFunction") then
            _rfRemote = rf
            pcall(function() rf:InvokeServer(formatCode(code)) end)
            return true
        end
    end
    return false
end

local function writeAndSubmit(code)
    if redeemViaRF(code) then return true end
    local textBox = findCodeTextBox()
    if not textBox then return false end

    local formatted = formatCode(code)
    if not collectedSeen[formatted] then
        collectedSeen[formatted] = true
        table.insert(collectedCodes, formatted)
        updateCollectedLabel()
    end

    local fullText = table.concat(collectedCodes, CODE_SEPARATOR)
    local ready = #collectedCodes >= _G.SubmitAfterCount

    if ready and _G.AutoSubmitEnabled then
        pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
            textBox:ReleaseFocus(true)
        end)
        fireSignal(textBox.FocusLost)
        logStatus("Submitted!")
        table.clear(collectedCodes)
        table.clear(collectedSeen)
        updateCollectedLabel()
    else
        pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
        end)
    end
    return true
end

local function triggerWrite()
    if writeBusy or #pendingQueue == 0 then return end
    writeBusy = true
    task.spawn(function()
        while #pendingQueue > 0 and _G.ScriptEnabled do
            local box = findCodeTextBox()
            if not box then break end
            local code = table.remove(pendingQueue, 1)
            pendingSeen[code] = nil
            writeAndSubmit(code)
            task.wait(0.1)
        end
        writeBusy = false
    end)
end

local function processText(text)
    if not text or text == "" then return end
    local codes = extractCodesFromText(text)
    for _, code in ipairs(codes) do
        copyCodeToClipboard(code)
        if not pendingSeen[code] then
            pendingSeen[code] = true
            table.insert(pendingQueue, code)
            triggerWrite()
        end
    end
end

local function resolveRemote()
    if _G.PhiNotifyRemote then return _G.PhiNotifyRemote end
    local Net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net")
    if not Net then return nil end
    for _, d in ipairs(Net:GetDescendants()) do
        if d:IsA("RemoteEvent") and d.Name:match("^RE/%x+$") then
            _G.PhiNotifyRemote = d
            return d
        end
    end
    return nil
end

local function startMonitoring()
    task.spawn(function()
        local NC = resolveRemote()
        if not NC then return end
        local conn = NC.OnClientEvent:Connect(function(...)
            if not _G.ScriptEnabled then return end
            local strings = {}
            for _, v in ipairs({...}) do extractStrings(v, strings) end
            for _, s in ipairs(strings) do processText(s) end
        end)
        table.insert(activeConnections, conn)
    end)
end

local function extractStrings(val, out)
    out = out or {}
    if type(val) == "string" then table.insert(out, val)
    elseif type(val) == "table" then
        for _, v in pairs(val) do extractStrings(v, out) end
    end
    return out
end

local function cleanupMonitoring()
    for _, conn in pairs(activeConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(activeConnections)
    table.clear(pendingQueue)
    table.clear(pendingSeen)
    table.clear(collectedCodes)
    table.clear(collectedSeen)
    writeBusy = false
end

-- ==================== GUI (Küçük + Mavi Tema) ====================
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("MoonHubCodeRedeemer") then CoreGui.MoonHubCodeRedeemer:Destroy() end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonHubCodeRedeemer"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke", parent)
    s.Thickness = thickness or 2
    local g = Instance.new("UIGradient", s)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 140, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
    }
    task.spawn(function()
        while parent.Parent do
            g.Rotation = (g.Rotation + (speed or 1.1)) % 360
            task.wait()
        end
    end)
end

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 235, 0, 155)
MainFrame.Position = UDim2.new(0.5, -117.5, 0.5, -77.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 40)
MainFrame.BackgroundTransparency = 0.2
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local corner = Instance.new("UICorner", MainFrame)
corner.CornerRadius = UDim.new(0, 10)
createAnimatedStroke(MainFrame, 2.2, 0.85)

-- Draggable
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local title = Instance.new("TextLabel", MainFrame)
title.Size = UDim2.new(1, -20, 0, 24)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 17
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left

local titleGrad = Instance.new("UIGradient", title)
titleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 160, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255))}

-- Toggle
local toggleRow = Instance.new("Frame", MainFrame)
toggleRow.Size = UDim2.new(1, -20, 0, 42)
toggleRow.Position = UDim2.new(0, 10, 0, 38)
toggleRow.BackgroundColor3 = Color3.fromRGB(20, 30, 60)
Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1.5, 1)

local toggleLabel = Instance.new("TextLabel", toggleRow)
toggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Auto Redeem"
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.TextSize = 14.5
toggleLabel.TextColor3 = Color3.new(1,1,1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Position = UDim2.new(0, 14, 0, 0)

local switchBg = Instance.new("Frame", toggleRow)
switchBg.Size = UDim2.new(0, 44, 0, 23)
switchBg.Position = UDim2.new(1, -54, 0.5, -11.5)
switchBg.BackgroundTransparency = 1
Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 12)
createAnimatedStroke(switchBg, 2, 1.3)

local knob = Instance.new("Frame", switchBg)
knob.Size = UDim2.new(0, 19, 0, 19)
knob.Position = UDim2.new(0, 2, 0.5, -9.5)
knob.BackgroundColor3 = Color3.new(1,1,1)
Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 10)

local toggleBtn = Instance.new("TextButton", toggleRow)
toggleBtn.Size = UDim2.new(1,0,1,0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""

-- Submit After
local countFrame = Instance.new("Frame", MainFrame)
countFrame.Size = UDim2.new(1, -20, 0, 36)
countFrame.Position = UDim2.new(0, 10, 0, 85)
countFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 60)
Instance.new("UICorner", countFrame)
createAnimatedStroke(countFrame, 1.3, 1)

local countLabel = Instance.new("TextLabel", countFrame)
countLabel.Size = UDim2.new(0.5, 0, 1, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Submit After:"
countLabel.Font = Enum.Font.GothamSemibold
countLabel.TextSize = 13
countLabel.TextColor3 = Color3.new(1,1,1)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Position = UDim2.new(0, 14, 0, 0)

local countBox = Instance.new("TextBox", countFrame)
countBox.Size = UDim2.new(0, 60, 0, 26)
countBox.Position = UDim2.new(1, -70, 0.5, -13)
countBox.BackgroundColor3 = Color3.fromRGB(10, 15, 40)
countBox.Text = tostring(_G.SubmitAfterCount)
countBox.TextColor3 = Color3.new(1,1,1)
countBox.Font = Enum.Font.GothamBold
countBox.TextSize = 14
Instance.new("UICorner", countBox).CornerRadius = UDim.new(0, 6)

countBox.FocusLost:Connect(function()
    local n = tonumber(countBox.Text)
    if n and n >= 1 then
        _G.SubmitAfterCount = math.floor(n)
        countBox.Text = tostring(_G.SubmitAfterCount)
        updateCollectedLabel()
    else
        countBox.Text = tostring(_G.SubmitAfterCount)
    end
end)

-- Collected Label
CollectedLabel = Instance.new("TextLabel", MainFrame)
CollectedLabel.Name = "CollectedLabel"
CollectedLabel.Size = UDim2.new(1, -20, 0, 20)
CollectedLabel.Position = UDim2.new(0, 10, 0, 125)
CollectedLabel.BackgroundTransparency = 1
CollectedLabel.Text = "Collected: 0/" .. _G.SubmitAfterCount
CollectedLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
CollectedLabel.TextSize = 13
CollectedLabel.Font = Enum.Font.GothamSemibold
CollectedLabel.TextXAlignment = Enum.TextXAlignment.Center

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -20, 0, 18)
StatusLabel.Position = UDim2.new(0, 10, 0, 148)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(160, 180, 220)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham

local isToggled = false

local function setToggle(state)
    isToggled = state
    _G.ScriptEnabled = state
    _G.AutoWriteEnabled = state
    _G.AutoSubmitEnabled = state

    local goal = state and UDim2.new(1, -23, 0.5, -9.5) or UDim2.new(0, 2, 0.5, -9.5)
    local color = state and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(220, 70, 70)

    TweenService:Create(knob, TweenInfo.new(0.25), {Position = goal}):Play()
    TweenService:Create(switchBg, TweenInfo.new(0.25), {BackgroundColor3 = color}):Play()

    if state then
        startMonitoring()
        logStatus("Active")
    else
        cleanupMonitoring()
        logStatus("Stopped")
    end
end

toggleBtn.MouseButton1Click:Connect(function() setToggle(not isToggled) end)

setToggle(false)
logStatus("Ready")

print("Moon Hub Code Redeemer Loaded")
