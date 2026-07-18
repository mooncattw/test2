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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function logStatus(message)
    if MainFrame and MainFrame:FindFirstChild("StatusLabel") then
        MainFrame.StatusLabel.Text = "Status: " .. message
    end
end

local function isGuiVisible(obj)
    if not obj or not obj.Visible then return false end
    local current = obj.Parent
    while current do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        elseif current:IsA("ScreenGui") and not current.Enabled then
            return false
        end
        current = current.Parent
    end
    return true
end

local blacklistedWords = {
    "top", "sec", "min", "fps", "ping", "loading",
    "points", "coins", "cash", "rebirth", "slaps", "money",
    "speed", "level", "lvl", "score"
}

local commonWords = {
    ["the"]=true, ["and"]=true, ["for"]=true, ["you"]=true, ["your"]=true,
    ["now"]=true, ["new"]=true, ["use"]=true, ["get"]=true, ["out"]=true,
    ["all"]=true, ["are"]=true, ["can"]=true, ["with"]=true, ["from"]=true,
    ["this"]=true, ["that"]=true, ["here"]=true, ["more"]=true, ["info"]=true,
    ["redeem"]=true, ["claim"]=true, ["enter"]=true, ["reward"]=true
}

local function isBlacklisted(lowerText)
    if commonWords[lowerText] then return true end
    for _, word in ipairs(blacklistedWords) do
        if lowerText:find(word, 1, true) then
            return true
        end
    end
    return false
end

local function looksLikeCode(token)
    if not token then return false end
    if #token < 4 or #token > 20 then return false end
    if not token:match("^%w+$") then return false end
    if isBlacklisted(token:lower()) then return false end
    local letterCount = 0
    for _ in token:gmatch("%a") do letterCount = letterCount + 1 end
    if letterCount < 3 then return false end
    if token:match("^%d+[smhdSMHD]$") then return false end
    local hasDigit = token:match("%d") ~= nil
    local isAllUpper = (token == token:upper()) and (token:match("%a") ~= nil)
    if not (hasDigit or isAllUpper) then return false end
    return true
end

local function extractCodesFromText(text)
    local found = {}
    if not text then return found end
    local trimmed = text:match("^%s*(.-)%s*$")
    trimmed = trimmed:gsub("<[^>]->", "")
    if looksLikeCode(trimmed) then
        table.insert(found, trimmed)
        return found
    end
    for token in text:gmatch("%w+") do
        if looksLikeCode(token) then
            table.insert(found, token)
        end
    end
    return found
end

local function copyCodeToClipboard(code)
    local success = false
    if setclipboard then
        pcall(function() setclipboard(code) end)
        success = true
    end
    if success then
        logStatus("Copied: " .. code)
    end
end

local function formatCode(code)
    return code
end

local _cachedBox = nil
local function _isCodeBox(obj)
    if not obj:IsA("TextBox") then return false end
    if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
    local hint = ((obj.PlaceholderText or "") .. " " .. obj.Name):lower()
    return hint:find("code") or hint:find("redeem") or hint:find("here")
end

local function findCodeTextBox()
    if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then
        return _cachedBox
    end
    _cachedBox = nil
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if _isCodeBox(obj) then
            if isGuiVisible(obj) then
                _cachedBox = obj
                return obj
            end
        end
    end
    return nil
end

local function fireSignal(sig)
    if not sig then return end
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(sig)) do
                if c.Fire then c:Fire() end
            end
        end
    end)
    if firesignal then
        pcall(function() firesignal(sig) end)
    end
end

local _rfRemote = nil
local function getRedemptionRF()
    if _rfRemote and _rfRemote.Parent then return _rfRemote end
    _rfRemote = nil
    local rfFolder = ReplicatedStorage:FindFirstChild("RF")
    if rfFolder then
        local rf = rfFolder:FindFirstChild("RequestRedemption")
        if rf and rf:IsA("RemoteFunction") then
            _rfRemote = rf
            return _rfRemote
        end
    end
    if rfFolder then
        for _, v in ipairs(rfFolder:GetChildren()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                _rfRemote = v
                return _rfRemote
            end
        end
    end
    return _rfRemote
end

local function redeemViaRF(code)
    local rf = getRedemptionRF()
    if not rf then return false end
    local ok = pcall(function()
        rf:InvokeServer(formatCode(code))
    end)
    return ok
end

local function writeAndSubmit(code)
    if redeemViaRF(code) then return true end
    local textBox = findCodeTextBox()
    if not textBox then
        logStatus("Waiting for code box...")
        return false
    end
    local formatted = formatCode(code)
    if not collectedSeen[formatted] then
        collectedSeen[formatted] = true
        table.insert(collectedCodes, formatted)
    end
    local fullText = table.concat(collectedCodes, CODE_SEPARATOR)
    local ready = #collectedCodes >= _G.SubmitAfterCount

    if ready and _G.AutoSubmitEnabled then
        local ok = pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
            textBox:ReleaseFocus(true)
        end)
        if not ok then pcall(function() textBox.Text = fullText end) end
        fireSignal(textBox.FocusLost)
        logStatus("Submitted " .. #collectedCodes .. " codes")
        table.clear(collectedCodes)
        table.clear(collectedSeen)
    else
        local ok = pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
        end)
        if not ok then pcall(function() textBox.Text = fullText end) end
        logStatus("Added: " .. formatted .. " (" .. #collectedCodes .. "/" .. _G.SubmitAfterCount .. ")")
    end
    return true
end

local function triggerWrite()
    if writeBusy or not _G.AutoWriteEnabled or #pendingQueue == 0 then return end
    writeBusy = true
    task.spawn(function()
        while _G.AutoWriteEnabled and #pendingQueue > 0 do
            local box = findCodeTextBox()
            if not (box and isGuiVisible(box)) then break end
            local code = table.remove(pendingQueue, 1)
            pendingSeen[code] = nil
            writeAndSubmit(code)
            task.wait(0.08)
        end
        writeBusy = false
    end)
end

local function startAutoWriteLoop()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
    local boxConn = playerGui.DescendantAdded:Connect(function(obj)
        if _isCodeBox(obj) and isGuiVisible(obj) then
            _cachedBox = obj
            triggerWrite()
        end
    end)
    table.insert(activeConnections, boxConn)
end

local function extractStrings(val, out)
    out = out or {}
    if type(val) == "string" then
        table.insert(out, val)
    elseif type(val) == "table" then
        for _, v in pairs(val) do
            extractStrings(v, out)
        end
    end
    return out
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
    local Net
    local deadline = tick() + 30
    while not Net and tick() < deadline do
        pcall(function()
            local Pkgs = ReplicatedStorage:FindFirstChild("Packages")
            if Pkgs then Net = Pkgs:FindFirstChild("Net") end
        end)
        if not Net then task.wait(0.5) end
    end
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
        if not NC then
            logStatus("Remote not found")
            return
        end
        local conn = NC.OnClientEvent:Connect(function(...)
            if not _G.ScriptEnabled then return end
            local strings = {}
            for _, v in ipairs({...}) do
                extractStrings(v, strings)
            end
            for _, s in ipairs(strings) do
                processText(s)
            end
        end)
        table.insert(activeConnections, conn)
        logStatus("Monitoring Active")
    end)
end

local function cleanupMonitoring()
    for _, conn in pairs(activeConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(activeConnections)
    table.clear(pendingQueue)
    table.clear(pendingSeen)
    table.clear(collectedCodes)
    table.clear(collectedSeen)
    writeBusy = false
end

-- ==================== MOON HUB GUI ====================
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("MoonHubCodeRedeemer") then
    CoreGui.MoonHubCodeRedeemer:Destroy()
end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonHubCodeRedeemer"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = Color3.new(1, 1, 1)
    s.Parent = parent
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 255)),
    })
    g.Parent = s
    task.spawn(function()
        while parent.Parent do
            g.Rotation = (g.Rotation + (speed or 1.2)) % 360
            task.wait()
        end
    end)
end

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 175)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -87)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
MainFrame.BackgroundTransparency = 0.25
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame
createAnimatedStroke(MainFrame, 2.5, 0.9)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 26)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Moon Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 19
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = MainFrame

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 255))
})
titleGrad.Parent = title

local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -20, 0, 48)
toggleRow.Position = UDim2.new(0, 10, 0, 42)
toggleRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
toggleRow.Parent = MainFrame
Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1.5, 1.1)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0, 140, 1, 0)
toggleLabel.Position = UDim2.new(0, 14, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Auto Redeem"
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.TextSize = 15
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

local switchBg = Instance.new("Frame")
switchBg.Size = UDim2.new(0, 46, 0, 24)
switchBg.Position = UDim2.new(1, -56, 0.5, -12)
switchBg.BackgroundTransparency = 1
switchBg.Parent = toggleRow
Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 12)
createAnimatedStroke(switchBg, 2, 1.4)

local switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 20, 0, 20)
switchKnob.Position = UDim2.new(0, 2, 0.5, -10)
switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
switchKnob.Parent = switchBg
Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 10)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.Parent = toggleRow

local countFrame = Instance.new("Frame")
countFrame.Size = UDim2.new(1, -20, 0, 38)
countFrame.Position = UDim2.new(0, 10, 0, 98)
countFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
countFrame.Parent = MainFrame
Instance.new("UICorner", countFrame)
createAnimatedStroke(countFrame, 1.2, 1)

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.55, 0, 1, 0)
countLabel.Position = UDim2.new(0, 14, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Submit After:"
countLabel.Font = Enum.Font.GothamSemibold
countLabel.TextSize = 13.5
countLabel.TextColor3 = Color3.new(1, 1, 1)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = countFrame

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(0, 65, 0, 28)
countBox.Position = UDim2.new(1, -75, 0.5, -14)
countBox.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
countBox.Text = tostring(_G.SubmitAfterCount)
countBox.TextColor3 = Color3.new(1, 1, 1)
countBox.Font = Enum.Font.GothamBold
countBox.TextSize = 14
countBox.Parent = countFrame
Instance.new("UICorner", countBox).CornerRadius = UDim.new(0, 6)

countBox.FocusLost:Connect(function()
    local n = tonumber(countBox.Text)
    if n and n >= 1 then
        _G.SubmitAfterCount = math.floor(n)
        countBox.Text = tostring(_G.SubmitAfterCount)
    else
        countBox.Text = tostring(_G.SubmitAfterCount)
    end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -20, 0, 22)
StatusLabel.Position = UDim2.new(0, 10, 0, 143)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
StatusLabel.TextSize = 12.5
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

local isToggled = false

local function setToggle(state)
    isToggled = state
    _G.ScriptEnabled = state
    _G.AutoWriteEnabled = state
    _G.AutoSubmitEnabled = state

    local goal = state and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    local color = state and Color3.fromRGB(80, 220, 100) or Color3.fromRGB(220, 70, 70)

    TweenService:Create(switchKnob, TweenInfo.new(0.25), {Position = goal}):Play()
    TweenService:Create(switchBg, TweenInfo.new(0.25), {BackgroundColor3 = color}):Play()

    if state then
        startMonitoring()
        startAutoWriteLoop()
        logStatus("Activated")
    else
        cleanupMonitoring()
        logStatus("Deactivated")
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    setToggle(not isToggled)
end)

setToggle(false)
logStatus("Ready")

print("Moon Hub Code Redeemer Loaded Successfully")
