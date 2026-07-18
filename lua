_G.ScriptEnabled = true
_G.CasingType = "Normal"
_G.AutoWriteEnabled = true
_G.AutoSubmitEnabled = true
_G.SubmitAfterCount = 1

local enteredCodes = {}
local activeConnections = {}
local latestCode = nil
local pendingQueue = {}
local pendingSeen = {}
local writeBusy = false
local collectedCodes = {}
local collectedSeen = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = nil
local MainFrame = nil

local function logStatus(message)
    if MainFrame and MainFrame:FindFirstChild("StatusLabel") then
        MainFrame.StatusLabel.Text = "Status: " .. message
    end
end

-- ==================== CODE DETECTION & PROCESSING ====================

local blacklistedWords = {"top", "sec", "min", "fps", "ping", "loading", "points", "coins", "cash", "rebirth", "slaps", "money", "speed", "level", "lvl", "score"}
local commonWords = {["the"]=true, ["and"]=true, ["for"]=true, ["you"]=true, ["your"]=true, ["now"]=true, ["new"]=true, ["use"]=true, ["get"]=true, ["out"]=true, ["all"]=true, ["are"]=true, ["can"]=true, ["with"]=true, ["from"]=true, ["this"]=true, ["that"]=true, ["here"]=true, ["more"]=true, ["info"]=true, ["redeem"]=true, ["claim"]=true, ["enter"]=true, ["reward"]=true, ["sammy"]=true}

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
    text = text:gsub("<[^>]->", ""):match("^%s*(.-)%s*$")
    for token in text:gmatch("%w+") do
        if looksLikeCode(token) then
            table.insert(found, token)
        end
    end
    return found
end

local function formatCode(code)
    return code -- Normal casing (istediğin gibi değiştirebilirsin)
end

-- ==================== REMOTE & WRITING ====================

local _rfRemote = nil
local function getRedemptionRF()
    if _rfRemote and _rfRemote.Parent then return _rfRemote end
    local rfFolder = ReplicatedStorage:FindFirstChild("RF")
    if rfFolder then
        for _, v in ipairs(rfFolder:GetChildren()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                _rfRemote = v
                return v
            end
        end
    end
    if getinstances then
        for _, v in ipairs(getinstances()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                _rfRemote = v
                return v
            end
        end
    end
    return nil
end

local function redeemViaRF(code)
    local rf = getRedemptionRF()
    if not rf then return false end
    local ok = pcall(function()
        rf:InvokeServer(formatCode(code))
    end)
    return ok
end

local _cachedBox = nil
local function findCodeTextBox()
    if _cachedBox and _cachedBox.Parent and _cachedBox.Visible then return _cachedBox end
    _cachedBox = nil
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextBox") then
            local hint = (obj.PlaceholderText or "" .. obj.Name):lower()
            if hint:find("code") or hint:find("redeem") or hint:find("here") then
                if obj.Visible then
                    _cachedBox = obj
                    return obj
                end
            end
        end
    end
    return nil
end

local function writeAndSubmit(code)
    if redeemViaRF(code) then return true end

    local textBox = findCodeTextBox()
    if not textBox then return false end

    local formatted = formatCode(code)
    if not collectedSeen[formatted] then
        collectedSeen[formatted] = true
        table.insert(collectedCodes, formatted)
    end

    local fullText = table.concat(collectedCodes, "")
    local ready = #collectedCodes >= _G.SubmitAfterCount

    if ready and _G.AutoSubmitEnabled then
        for i = 1, 8 do
            local box = findCodeTextBox()
            if box then
                pcall(function()
                    box:CaptureFocus()
                    box.Text = fullText
                    box:ReleaseFocus(true)
                end)
            end
        end
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
    if writeBusy or not _G.ScriptEnabled or #pendingQueue == 0 then return end
    writeBusy = true
    task.spawn(function()
        while _G.ScriptEnabled and #pendingQueue > 0 do
            local box = findCodeTextBox()
            if not box then break end
            local code = table.remove(pendingQueue, 1)
            pendingSeen[code] = nil
            writeAndSubmit(code)
            task.wait()
        end
        writeBusy = false
    end)
end

-- ==================== NOTIFICATION HOOK ====================

local function resolveRemote()
    local Net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Net")
    if not Net then return nil end
    for _, v in ipairs(Net:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:match("^RE/%x+$") then
            return v
        end
    end
    return nil
end

local function startMonitoring()
    local NC = resolveRemote()
    if not NC then
        logStatus("PhiNotify remote not found")
        return
    end

    local conn = NC.OnClientEvent:Connect(function(...)
        if not _G.ScriptEnabled then return end
        for _, v in ipairs({...}) do
            if type(v) == "string" then
                for _, code in ipairs(extractCodesFromText(v)) do
                    table.insert(pendingQueue, code)
                    latestCode = code
                    triggerWrite()
                    logStatus("Code detected: " .. code)
                end
            end
        end
    end)
    table.insert(activeConnections, conn)
    logStatus("Hooked successfully - Listening")
end

-- ==================== MOON HUB STYLE GUI ====================

local function createGUI()
    local old = CoreGui:FindFirstChild("MoonHubCodeCopier") or LocalPlayer.PlayerGui:FindFirstChild("MoonHubCodeCopier")
    if old then old:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MoonHubCodeCopier"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 240, 0, 130)
    MainFrame.Position = UDim2.new(0.5, -120, 0.5, -65)
    MainFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
    MainFrame.BackgroundTransparency = 0.25
    MainFrame.ClipsDescendants = true
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = MainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(70, 160, 255)
    stroke.Parent = MainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Moon Hub"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MainFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -20, 0, 16)
    subtitle.Position = UDim2.new(0, 10, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Code Copier"
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 12
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 255)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = MainFrame

    -- Start Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 100, 0, 35)
    toggleBtn.Position = UDim2.new(0.5, -50, 0, 58)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    toggleBtn.Text = "START"
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.Parent = MainFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = toggleBtn

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 1, -28)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = MainFrame

    -- Submit After
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0, 80, 0, 20)
    countLabel.Position = UDim2.new(0, 10, 0, 105)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Submit after:"
    countLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = MainFrame

    local countBox = Instance.new("TextBox")
    countBox.Size = UDim2.new(0, 40, 0, 22)
    countBox.Position = UDim2.new(0, 95, 0, 104)
    countBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    countBox.Text = "1"
    countBox.TextColor3 = Color3.new(1,1,1)
    countBox.Font = Enum.Font.GothamBold
    countBox.TextSize = 13
    countBox.Parent = MainFrame

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = countBox

    -- Dragging
    local dragging, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Toggle Logic
    local function updateToggle()
        if _G.ScriptEnabled then
            toggleBtn.Text = "STOP"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            logStatus("Running")
        else
            toggleBtn.Text = "START"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 150, 80)
            logStatus("Stopped")
        end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        _G.ScriptEnabled = not _G.ScriptEnabled
        updateToggle()
    end)

    countBox.FocusLost:Connect(function()
        local num = tonumber(countBox.Text) or 1
        if num < 1 then num = 1 end
        _G.SubmitAfterCount = num
        countBox.Text = tostring(num)
    end)

    updateToggle()
end

-- ==================== INIT ====================

local function cleanup()
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(activeConnections)
end

local function init()
    cleanup()
    createGUI()
    startMonitoring()
    logStatus("Initialized - Press START")
end

init()
