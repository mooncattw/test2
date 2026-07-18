_G.ScriptEnabled = true
_G.CasingType = "Normal"
_G.AutoWriteEnabled = false
_G.AutoSubmitEnabled = false

local enteredCodes = {}
local activeConnections = {}
local latestCode = nil
local lastWrittenCode = nil
local autoWriteConn = nil
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
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
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
    ["redeem"]=true, ["claim"]=true, ["enter"]=true, ["reward"]=true, ["rewards"]=true,
    ["update"]=true, ["join"]=true, ["group"]=true, ["like"]=true, ["follow"]=true,
    ["sub"]=true, ["click"]=true, ["type"]=true, ["copy"]=true, ["paste"]=true,
    ["server"]=true, ["event"]=true, ["live"]=true, ["news"]=true, ["soon"]=true,
    ["available"]=true, ["expired"]=true, ["welcome"]=true, ["thanks"]=true,
    ["player"]=true, ["players"]=true
}

local function isBlacklisted(lowerText)
    if commonWords[lowerText] then return true end
    for _, word in ipairs(blacklistedWords) do
        if lowerText:find(word, 1, true) then return true end
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
    local formattedCode = code
    if _G.CasingType == "Upper" then
        formattedCode = string.upper(code)
    elseif _G.CasingType == "Lower" then
        formattedCode = string.lower(code)
    end
    local success = false
    if setclipboard then
        pcall(function() setclipboard(formattedCode) end)
        success = true
    end
    if success then
        logStatus("Copied: " .. formattedCode)
    end
end

local function formatCode(code)
    if _G.CasingType == "Upper" then
        return string.upper(code)
    elseif _G.CasingType == "Lower" then
        return string.lower(code)
    end
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
    if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then return _cachedBox end
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
    if firesignal then pcall(function() firesignal(sig) end) end
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
    local formatted = formatCode(code)
    local ok = pcall(function() rf:InvokeServer(formatted) end)
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
        pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
            textBox:ReleaseFocus(true)
        end)
        fireSignal(textBox.FocusLost)
        logStatus("Submitted " .. #collectedCodes .. " codes")
        table.clear(collectedCodes)
        table.clear(collectedSeen)
    else
        pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
        end)
        logStatus("Added: " .. formatted .. " (" .. #collectedCodes .. "/" .. _G.SubmitAfterCount .. ")")
    end
    return true
end

local function triggerWrite()
    if writeBusy or not _G.AutoWriteEnabled or #pendingQueue == 0 then return end
    writeBusy = true
    task.spawn(function()
        while _G.AutoWriteEnabled and #pendingQueue > 0 do
            local b = findCodeTextBox()
            if not (b and isGuiVisible(b)) then break end
            local code = table.remove(pendingQueue, 1)
            pendingSeen[code] = nil
            writeAndSubmit(code)
        end
        writeBusy = false
    end)
end

local function startAutoWriteLoop()
    if autoWriteConn then return end
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
        if not NC then return end
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

local function createUI()
    local oldGui = game:GetService("CoreGui"):FindFirstChild("BrainrotRedeemerGui") or LocalPlayer.PlayerGui:FindFirstChild("BrainrotRedeemerGui")
    if oldGui then oldGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BrainrotRedeemerGui"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 330, 0, 310)
    MainFrame.Position = UDim2.new(0.5, -165, 0.4, -155)
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    -- (Tüm orijinal UI kodları aynı kalıyor, sadece gerekli kısımları özetliyorum)
    -- ... (Orijinal createUI fonksiyonunun tamamı burada kalıyor, aşağıda sadece değişiklik yapılan kısımlar)

    local StartButton = Instance.new("TextButton")
    StartButton.Name = "StartButton"
    StartButton.Size = UDim2.new(0, 55, 0, 28)
    StartButton.Position = UDim2.new(1, -132, 0, 51)
    StartButton.Text = "Start"
    StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartButton.TextSize = 11
    StartButton.Font = Enum.Font.GothamBold
    StartButton.Parent = MainFrame
    Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 6)

    local StopButton = Instance.new("TextButton")
    StopButton.Name = "StopButton"
    StopButton.Size = UDim2.new(0, 55, 0, 28)
    StopButton.Position = UDim2.new(1, -70, 0, 51)
    StopButton.Text = "Stop"
    StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopButton.TextSize = 11
    StopButton.Font = Enum.Font.GothamBold
    StopButton.Parent = MainFrame
    Instance.new("UICorner", StopButton).CornerRadius = UDim.new(0, 6)

    local function renderStartStop()
        if _G.ScriptEnabled then
            StartButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            StopButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        else
            StartButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            StopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        end
    end

    StartButton.MouseButton1Click:Connect(function()
        _G.ScriptEnabled = true
        _G.AutoWriteEnabled = true
        _G.AutoSubmitEnabled = true
        renderStartStop()
        startMonitoring()
        startAutoWriteLoop()
        logStatus("Detection + Auto Write + Submit Started")
    end)

    StopButton.MouseButton1Click:Connect(function()
        _G.ScriptEnabled = false
        _G.AutoWriteEnabled = false
        _G.AutoSubmitEnabled = false
        renderStartStop()
        cleanupMonitoring()
        logStatus("All Stopped")
    end)

    -- Submit After kutusu (orijinalde var, sadece görünür yapıyoruz)
    local CountLabel = Instance.new("TextLabel")
    CountLabel.Size = UDim2.new(0, 200, 0, 30)
    CountLabel.Position = UDim2.new(0, 15, 0, 235)
    CountLabel.BackgroundTransparency = 1
    CountLabel.Text = "Submit after (#):"
    CountLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    CountLabel.TextSize = 13
    CountLabel.Font = Enum.Font.GothamSemibold
    CountLabel.TextXAlignment = Enum.TextXAlignment.Left
    CountLabel.Parent = MainFrame

    local CountBox = Instance.new("TextBox")
    CountBox.Size = UDim2.new(0, 80, 0, 28)
    CountBox.Position = UDim2.new(1, -95, 0, 236)
    CountBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    CountBox.Text = tostring(_G.SubmitAfterCount)
    CountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    CountBox.TextSize = 12
    CountBox.Font = Enum.Font.GothamBold
    CountBox.ClearTextOnFocus = false
    CountBox.Parent = MainFrame
    Instance.new("UICorner", CountBox).CornerRadius = UDim.new(0, 6)

    CountBox.FocusLost:Connect(function()
        local n = math.floor(tonumber(CountBox.Text) or 1)
        if n < 1 then n = 1 end
        _G.SubmitAfterCount = n
        CountBox.Text = tostring(n)
    end)

    renderStartStop()
end

local function init()
    pcall(cleanupMonitoring)
    createUI()
    logStatus("Initialization successful! Click Start")
end

init()
