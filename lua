_G.ScriptEnabled = true
_G.CasingType = "Normal"
_G.AutoWriteEnabled = true
_G.AutoSubmitEnabled = true

local collectedCodes = {}
local collectedSeen = {}
local CODE_SEPARATOR = ""
local pendingQueue = {}
local pendingSeen = {}
local writeBusy = false
local autoWriteConn = nil
local _cachedBox = nil
local ScreenGui = nil
local MainFrame = nil
local SubmitBox = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.SubmitAfterCount = 1
_G.SubmitAttempts = 10

-- GUI görünürlüğünü kontrol et
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

-- Blacklist ve common words
local blacklistedWords = {
    "top", "sec", "min", "fps", "ping", "loading", "points", "coins", "cash", "rebirth",
    "slaps", "money", "speed", "level", "lvl", "score"
}

local commonWords = {
    ["the"] = true, ["and"] = true, ["for"] = true, ["you"] = true, ["your"] = true,
    ["now"] = true, ["new"] = true, ["use"] = true, ["get"] = true, ["out"] = true,
    ["redeem"] = true, ["claim"] = true, ["enter"] = true, ["code"] = true
}

local function isBlacklisted(lowerText)
    if commonWords[lowerText] then return true end
    for _, word in ipairs(blacklistedWords) do
        if lowerText:find(word, 1, true) then return true end
    end
    return false
end

-- Son kelimenin tam olduğunu doğrula
local function isLoneCode(text)
    if not text then return false end
    text = text:match("^%s*(.-)%s*$")
    if text == "" or text:find("%s") then return false end
    if #text < 4 or #text > 20 then return false end
    if not text:match("^%w+$") then return false end
    if isBlacklisted(text:lower()) then return false end
    if text:match("^%d+[smhdSMHD]$") then return false end
    if text:match("^%d+$") then return #text >= 4 end

    -- Son karakterin harf/rakam olduğunu doğrula
    local lastChar = text:sub(-1)
    if not lastChar:match("%w") then return false end

    -- Minimum 3 harf gerekliliği
    local letters = 0
    for _ in text:gmatch("%a") do letters = letters + 1 end
    return letters >= 3
end

-- Sadece son kelimeyi al
local function extractCodesFromText(text)
    local found = {}
    if not text or text == "" then return found end

    local trimmed = text:match("^%s*(.-)%s*$")
    trimmed = trimmed:gsub("<[^>]->", "")

    if trimmed == "" then return found end

    -- Metni kelimelere ayır
    local words = {}
    for word in trimmed:gmatch("%S+") do
        table.insert(words, word)
    end

    -- Sadece son kelimeyi kontrol et
    if #words > 0 then
        local lastWord = words[#words]
        if isLoneCode(lastWord) then
            table.insert(found, lastWord)
        end
    end

    return found
end

-- Clipboard fonksiyonları
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
    elseif toclipboard then
        pcall(function() toclipboard(formattedCode) end)
        success = true
    elseif Clipboard and Clipboard.set then
        pcall(function() Clipboard.set(formattedCode) end)
        success = true
    end
    return success
end

local function formatCode(code)
    if _G.CasingType == "Upper" then return string.upper(code) end
    if _G.CasingType == "Lower" then return string.lower(code) end
    return code
end

-- TextBox bulma
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

-- Signal fonksiyonları
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

-- Submit butonu kontrolü
local function isSubmitButton(obj)
    if not (obj:IsA("TextButton") or obj:IsA("ImageButton")) then return false end
    if ScreenGui and obj:IsDescendantOf(ScreenGui) then return false end
    if not isGuiVisible(obj) then return false end
    local hint = (((obj:IsA("TextButton") and obj.Text) or "") .. " " .. obj.Name):lower()
    return hint:find("redeem") ~= nil or hint:find("submit") ~= nil
end

local function fireSubmitButton(nearObj)
    local target = nil
    local container = nearObj and nearObj.Parent or nil
    local levels = 0
    while container and not target and levels < 5 do
        for _, obj in ipairs(container:GetDescendants()) do
            if isSubmitButton(obj) then target = obj break end
        end
        container = container.Parent
        levels = levels + 1
    end
    if not target then return false end
    fireSignal(target.MouseButton1Click)
    fireSignal(target.Activated)
    return true
end

-- RemoteFunction ile redeem
local _rfRemote = nil
local function getRedemptionRF()
    if _rfRemote and _rfRemote.Parent then return _rfRemote end
    _rfRemote = nil
    local rfFolder = ReplicatedStorage:FindFirstChild("RF")
    if rfFolder then
        for _, v in ipairs(rfFolder:GetChildren()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                _rfRemote = v
                return _rfRemote
            end
        end
    end
    if getinstances then
        for _, v in ipairs(getinstances()) do
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
    local ok = pcall(function() return rf:InvokeServer(formatted) end)
    return ok
end

-- Ana writeAndSubmit fonksiyonu (TAM VE EKSİKSİZ YAZMA GARANTİSİ)
local function writeAndSubmit(code)
    if redeemViaRF(code) then return true end

    local textBox = findCodeTextBox()
    if not textBox then return false end

    local formatted = formatCode(code)

    -- TextBox'a odaklan
    pcall(function()
        textBox.ClearTextOnFocus = false
        textBox:CaptureFocus()
    end)

    -- Metni temizle ve yeni kodu yaz
    pcall(function()
        textBox.Text = formatted
        textBox.CursorPosition = #formatted + 1
    end)

    -- Son kelimenin tam olarak yazıldığını doğrulamak için bekle
    task.wait(1.0)

    -- TextBox'taki metni tekrar kontrol et
    local currentText = textBox.Text
    if currentText ~= formatted then
        -- Metin eşleşmiyorsa, iptal et
        return false
    end

    -- Kelime tamamen yazıldı, devam et
    if not collectedSeen[formatted] then
        collectedSeen[formatted] = true
        table.insert(collectedCodes, formatted)
    end

    -- Submit işlemi
    local target = math.max(1, tonumber(_G.SubmitAfterCount) or 1)
    local ready = #collectedCodes >= target

    if ready and _G.AutoSubmitEnabled then
        local fullText = table.concat(collectedCodes, CODE_SEPARATOR)
        for i = 1, _G.SubmitAttempts do
            local box = findCodeTextBox()
            if not box then break end
            pcall(function()
                box:CaptureFocus()
                box.Text = fullText
                box.CursorPosition = #fullText + 1
            end)
            pcall(function() box.Text = fullText end)
            pcall(function() box:ReleaseFocus(true) end)
            fireSubmitButton(box)
        end
        table.clear(collectedCodes)
        table.clear(collectedSeen)
    end

    return true
end

-- Metin işleme fonksiyonu (Sadece son kelimeyi işler)
local function processText(text)
    if not text or text == "" then return end

    -- Metni kelimelere ayır
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    -- Sadece son kelimeyi kontrol et
    if #words > 0 then
        local lastWord = words[#words]
        if isLoneCode(lastWord) then
            copyCodeToClipboard(lastWord)
            if not pendingSeen[lastWord] then
                pendingSeen[lastWord] = true
                table.insert(pendingQueue, lastWord)
            end
        end
    end
end

-- Trigger fonksiyonu
local function triggerWrite()
    if writeBusy or not _G.AutoWriteEnabled or #pendingQueue == 0 then return end
    local focused = UserInputService:GetFocusedTextBox()
    if focused and ScreenGui and focused:IsDescendantOf(ScreenGui) then return end
    local box = findCodeTextBox()
    if not (box and isGuiVisible(box)) then return end

    writeBusy = true
    task.spawn(function()
        local ok, err = pcall(function()
            while _G.AutoWriteEnabled and #pendingQueue > 0 do
                local b = findCodeTextBox()
                if not (b and isGuiVisible(b)) then break end
                local code = table.remove(pendingQueue, 1)
                pendingSeen[code] = nil
                writeAndSubmit(code)
            end
        end)
        writeBusy = false
        if not ok then warn("[CodeSniper] triggerWrite error: " .. tostring(err)) end
    end)
end

-- Bağlantıları başlat
local activeConnections = {}

local function startAutoWriteLoop()
    if autoWriteConn then return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
    local boxConn = playerGui and playerGui.DescendantAdded:Connect(function(obj)
        if _isCodeBox(obj) and isGuiVisible(obj) then
            _cachedBox = obj
            triggerWrite()
        end
    end)
    local boxRemConn = playerGui and playerGui.DescendantRemoving:Connect(function(obj)
        if obj == _cachedBox then _cachedBox = nil end
    end)
    autoWriteConn = {
        Disconnect = function()
            if boxConn then boxConn:Disconnect() end
            if boxRemConn then boxRemConn:Disconnect() end
        end
    }
    table.insert(activeConnections, autoWriteConn)
end

-- UI ve diğer fonksiyonlar (Aynı kalabilir)
local function createAnimatedStroke(parent, thickness, speed)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = Color3.new(1, 1, 1)
    s.Parent = parent
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 50, 150)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 180, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 50, 150))
    })
    g.Rotation = 0
    g.Parent = s
    task.spawn(function()
        local spd = speed or 1.2
        while parent.Parent do
            g.Rotation = (g.Rotation + spd) % 360
            task.wait()
        end
    end)
    return s, g
end

local function createUI()
    local oldGui = game:GetService("CoreGui"):FindFirstChild("BrainrotRedeemerGui")
        or LocalPlayer.PlayerGui:FindFirstChild("BrainrotRedeemerGui")
    if oldGui then oldGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BrainrotRedeemerGui"
    ScreenGui.ResetOnSpawn = false
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 140)
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -70)
    MainFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
    MainFrame.BackgroundTransparency = 0.25
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = MainFrame
    createAnimatedStroke(MainFrame, 2, 0.8)

    -- UI kodları (Aynı kalabilir)
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 120, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Moon Hub"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MainFrame

    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 160, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 160, 255))
    })
    titleGrad.Parent = title
    task.spawn(function()
        while MainFrame.Parent do
            titleGrad.Rotation = (titleGrad.Rotation + 1.2) % 360
            task.wait()
        end
    end)

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 120, 0, 15)
    subtitle.Position = UDim2.new(0, 10, 0, 23)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Auto Redeem Code"
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 11
    subtitle.TextColor3 = Color3.new(1, 1, 1)
    subtitle.TextTransparency = 0.3
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = MainFrame

    -- Auto Write Toggle
    local autoWriteRow = Instance.new("Frame")
    autoWriteRow.Size = UDim2.new(1, -20, 0, 40)
    autoWriteRow.Position = UDim2.new(0, 10, 0, 45)
    autoWriteRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
    autoWriteRow.Parent = MainFrame
    Instance.new("UICorner", autoWriteRow).CornerRadius = UDim.new(0, 8)
    createAnimatedStroke(autoWriteRow, 1, 1.2)

    local awLabel = Instance.new("TextLabel")
    awLabel.Size = UDim2.new(0, 80, 1, 0)
    awLabel.Position = UDim2.new(0, 10, 0, 0)
    awLabel.BackgroundTransparency = 1
    awLabel.Text = "Auto Write"
    awLabel.Font = Enum.Font.GothamBlack
    awLabel.TextSize = 13
    awLabel.TextColor3 = Color3.new(1, 1, 1)
    awLabel.TextXAlignment = Enum.TextXAlignment.Left
    awLabel.Parent = autoWriteRow

    local awSwitchBg = Instance.new("Frame")
    awSwitchBg.Size = UDim2.new(0, 36, 0, 18)
    awSwitchBg.Position = UDim2.new(1, -46, 0.5, -9)
    awSwitchBg.BackgroundTransparency = 1
    awSwitchBg.Parent = autoWriteRow
    Instance.new("UICorner", awSwitchBg).CornerRadius = UDim.new(0, 9)
    createAnimatedStroke(awSwitchBg, 2, 1.5)

    local awSwitchKnob = Instance.new("Frame")
    awSwitchKnob.Size = UDim2.new(0, 14, 0, 14)
    awSwitchKnob.Position = UDim2.new(1, -16, 0.5, -7)
    awSwitchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    awSwitchKnob.Parent = awSwitchBg
    Instance.new("UICorner", awSwitchKnob).CornerRadius = UDim.new(0, 7)

    local awToggleBtn = Instance.new("TextButton")
    awToggleBtn.Size = UDim2.new(0, 36, 0, 18)
    awToggleBtn.Position = UDim2.new(1, -46, 0.5, -9)
    awToggleBtn.BackgroundTransparency = 1
    awToggleBtn.Text = ""
    awToggleBtn.Parent = autoWriteRow
    awToggleBtn.MouseButton1Click:Connect(function()
        _G.AutoWriteEnabled = not _G.AutoWriteEnabled
        local newPos = _G.AutoWriteEnabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        local newColor = _G.AutoWriteEnabled and Color3.fromRGB(40, 100, 220) or Color3.fromRGB(20, 35, 75)
        TweenService:Create(awSwitchKnob, TweenInfo.new(0.15), {Position = newPos}):Play()
        TweenService:Create(awSwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = newColor}):Play()
    end)

    -- Auto Submit Toggle
    local autoSubmitRow = Instance.new("Frame")
    autoSubmitRow.Size = UDim2.new(1, -20, 0, 40)
    autoSubmitRow.Position = UDim2.new(0, 10, 0, 90)
    autoSubmitRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
    autoSubmitRow.Parent = MainFrame
    Instance.new("UICorner", autoSubmitRow).CornerRadius = UDim.new(0, 8)
    createAnimatedStroke(autoSubmitRow, 1, 1.2)

    local asLabel = Instance.new("TextLabel")
    asLabel.Size = UDim2.new(0, 80, 1, 0)
    asLabel.Position = UDim2.new(0, 10, 0, 0)
    asLabel.BackgroundTransparency = 1
    asLabel.Text = "Auto Submit"
    asLabel.Font = Enum.Font.GothamBlack
    asLabel.TextSize = 13
    asLabel.TextColor3 = Color3.new(1, 1, 1)
    asLabel.TextXAlignment = Enum.TextXAlignment.Left
    asLabel.Parent = autoSubmitRow

    SubmitBox = Instance.new("TextBox")
    SubmitBox.Name = "SubmitBox"
    SubmitBox.Size = UDim2.new(0, 50, 0, 22)
    SubmitBox.Position = UDim2.new(0, 95, 0.5, -11)
    SubmitBox.BackgroundColor3 = Color3.fromRGB(40, 100, 220)
    SubmitBox.Text = "1"
    SubmitBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBox.TextSize = 12
    SubmitBox.Font = Enum.Font.GothamBold
    SubmitBox.ClearTextOnFocus = false
    SubmitBox.TextEditable = true
    SubmitBox.ZIndex = 10
    SubmitBox.Parent = autoSubmitRow
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 6)
    submitCorner.Parent = SubmitBox
    createAnimatedStroke(SubmitBox, 1.5, 1.2)

    SubmitBox.Changed:Connect(function(property)
        if property == "Text" then
            local n = tonumber(SubmitBox.Text) or 1
            if n < 1 then n = 1 end
            _G.SubmitAfterCount = n
        end
    end)

    local asSwitchBg = Instance.new("Frame")
    asSwitchBg.Size = UDim2.new(0, 36, 0, 18)
    asSwitchBg.Position = UDim2.new(1, -46, 0.5, -9)
    asSwitchBg.BackgroundTransparency = 1
    asSwitchBg.Parent = autoSubmitRow
    Instance.new("UICorner", asSwitchBg).CornerRadius = UDim.new(0, 9)
    createAnimatedStroke(asSwitchBg, 2, 1.5)

    local asSwitchKnob = Instance.new("Frame")
    asSwitchKnob.Size = UDim2.new(0, 14, 0, 14)
    asSwitchKnob.Position = UDim2.new(1, -16, 0.5, -7)
    asSwitchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    asSwitchKnob.Parent = asSwitchBg
    Instance.new("UICorner", asSwitchKnob).CornerRadius = UDim.new(0, 7)

    local asToggleBtn = Instance.new("TextButton")
    asToggleBtn.Size = UDim2.new(0, 36, 0, 18)
    asToggleBtn.Position = UDim2.new(1, -46, 0.5, -9)
    asToggleBtn.BackgroundTransparency = 1
    asToggleBtn.Text = ""
    asToggleBtn.ZIndex = 9
    asToggleBtn.Parent = autoSubmitRow
    asToggleBtn.MouseButton1Click:Connect(function()
        _G.AutoSubmitEnabled = not _G.AutoSubmitEnabled
        local newPos = _G.AutoSubmitEnabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        local newColor = _G.AutoSubmitEnabled and Color3.fromRGB(40, 100, 220) or Color3.fromRGB(20, 35, 75)
        TweenService:Create(asSwitchKnob, TweenInfo.new(0.15), {Position = newPos}):Play()
        TweenService:Create(asSwitchBg, TweenInfo.new(0.15), {BackgroundColor3 = newColor}):Play()
    end)
end

-- Bağlantıları temizle
local function cleanupMonitoring()
    for _, conn in pairs(activeConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(activeConnections)
    table.clear(collectedCodes)
    table.clear(collectedSeen)
    table.clear(pendingQueue)
    table.clear(pendingSeen)
    writeBusy = false
    autoWriteConn = nil
end

-- Başlatma fonksiyonu
local function init()
    pcall(cleanupMonitoring)
    createUI()
    startAutoWriteLoop()
end

-- Başlat
init()
