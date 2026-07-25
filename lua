--// Moon Hub Brainrot Auto Redeem (Final)
--// Sadece son kelimeyi redeemler, ekstra karakter eklemez.

_G.ScriptEnabled = true
_G.CasingType = "Normal"  -- "Normal", "Upper", "Lower"
_G.AutoWriteEnabled = true
_G.AutoSubmitEnabled = true
_G.SubmitAfterCount = 1
_G.SubmitAttempts = 1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--// Blacklist (Filtrelenecek kelimeler)
local blacklistedWords = {
    --İngilizce
    "top", "sec", "min", "fps", "ping", "loading", "points", "coins", "cash", "rebirth", "slaps",
    "money", "speed", "level", "lvl", "score", "the", "and", "for", "you", "your", "now", "new",
    "use", "get", "out", "all", "are", "can", "with", "from", "this", "that", "here", "more", "info",
    "redeem", "claim", "enter", "reward", "rewards", "update", "join", "group", "like", "follow",
    "sub", "click", "type", "copy", "paste", "server", "event", "live", "news", "soon", "available",
    "expired", "welcome", "thanks", "thank", "player", "players", "today", "time", "wait", "xp",
    "sammy", "announcement", "announcements", "release", "released", "limited", "special", "gift",
    "pet", "pets", "egg", "luck", "boost", "double", "friend", "friends", "chat", "online", "offline",
    "invite", "party", "voice", "report", "block", "mute", "store", "shop", "inventory", "settings",
    "leaderboard", "lobby", "menu", "close", "open", "back", "next", "play", "exit", "loading",
    --İtalyanca (Brainrot için)
    "negozio", "rinascita", "indice", "duelli", "scambio", "codici", "incremento", "amico", "drop",
    "present", "win", "wins", "winner", "winners", "winning", "winter", "victory", "lose", "loss",
    "losses", "defeat", "daily", "spin", "wheel", "prize", "bonus", "streak", "rank", "wave",
    "round", "score", "match", "versus", "battle", "quest"
}

--// Kelimenin blacklist'te olup olmadığını kontrol et
local function isBlacklisted(text)
    text = text:lower()
    for _, word in ipairs(blacklistedWords) do
        if text == word then
            return true
        end
    end
    return false
end

--// Sadece tek kelime olan kodları al
local function isValidCode(text)
    if not text then return false end
    text = text:match("^%s*(.-)%s*$") -- Trim
    if text == "" then return false end
    if text:find("%s") then return false end -- Boşluk varsa reddet
    if #text < 3 or #text > 20 then return false end -- 3-20 karakter arasında
    if not text:match("^%w+$") then return false end -- Sadece alphanumeric
    if isBlacklisted(text) then return false end
    if text:match("^%d+[smhdSMHD]$") then return false end -- 10s, 5m gibi süreleri reddet
    if text:match("^%d+$") then return #text >= 3 end -- Sadece sayılar (en az 3 basamak)
    return true
end

--// Metinden son kelimeyi ayıkla
local function extractLastCodeFromText(text)
    if not text then return nil end
    text = text:gsub("<[^>]->", "") -- HTML taglerini temizle
    text = text:gsub("[^%w%s]", "") -- Özel karakterleri temizle
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    if #words == 0 then return nil end
    local lastWord = words[#words]
    if isValidCode(lastWord) then
        return lastWord
    end
    return nil
end

--// Kodu formatla (Upper/Lower/Normal)
local function formatCode(code)
    if _G.CasingType == "Upper" then
        return string.upper(code)
    elseif _G.CasingType == "Lower" then
        return string.lower(code)
    end
    return code
end

--// Code textbox'ını bul
local function findCodeTextBox()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextBox") then
            local hint = (obj.PlaceholderText or "" .. obj.Name):lower()
            if hint:find("code") or hint:find("redeem") or hint:find("here") then
                return obj
            end
        end
    end
    return nil
end

--// Submit butonunu bul ve tetikle
local function fireSubmitButton(box)
    local container = box.Parent
    for _ = 1, 3 do -- 3 seviye yukarı ara
        for _, obj in ipairs(container:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                local hint = (obj.Text or "" .. obj.Name):lower()
                if hint:find("redeem") or hint:find("submit") then
                    local event = obj.MouseButton1Click
                    if event then
                        event:Fire()
                    end
                    return true
                end
            end
        end
        container = container.Parent
        if not container then break end
    end
    return false
end

--// RemoteFunction üzerinden redeem etme
local function redeemViaRF(code)
    local rfFolder = ReplicatedStorage:FindFirstChild("RF")
    if rfFolder then
        for _, v in ipairs(rfFolder:GetChildren()) do
            if v.Name == "RequestRedemption" and v:IsA("RemoteFunction") then
                local success, err = pcall(function()
                    v:InvokeServer(formatCode(code))
                end)
                return success
            end
        end
    end
    return false
end

--// Kodu yaz ve submit et
local function writeAndSubmit(code)
    if not code then return false end
    if redeemViaRF(code) then return true end

    local textBox = findCodeTextBox()
    if not textBox then return false end

    local formattedCode = formatCode(code)
    textBox.Text = formattedCode
    textBox.CursorPosition = #formattedCode + 1

    -- Submit butonunu tetikle
    if _G.AutoSubmitEnabled then
        fireSubmitButton(textBox)
    end

    return true
end

--// Metin değişikliklerini izle (RemoteEvent üzerinden)
local function startMonitoring()
    local function processText(text)
        if not text or text == "" then return end
        local lastCode = extractLastCodeFromText(text)
        if lastCode then
            writeAndSubmit(lastCode)
        end
    end

    -- PhiNotify Remote'ini bul (Brainrot için)
    local function resolveRemote()
        local Net = ReplicatedStorage:FindFirstChild("Packages") and
                   ReplicatedStorage.Packages:FindFirstChild("Net")
        if not Net then return nil end
        for _, obj in ipairs(Net:GetDescendants()) do
            if obj:IsA("RemoteEvent") and obj.Name:match("^RE/%x+$") then
                return obj
            end
        end
        return nil
    end

    local NC = resolveRemote()
    if NC then
        NC.OnClientEvent:Connect(function(...)
            if not _G.ScriptEnabled then return end
            for _, arg in ipairs({...}) do
                if type(arg) == "string" then
                    processText(arg)
                elseif type(arg) == "table" then
                    for _, v in pairs(arg) do
                        if type(v) == "string" then
                            processText(v)
                        end
                    end
                end
            end
        end)
    end

    -- Chat mesajlarını da izle (ekstra güvenlik)
    local function onChatted(player, message)
        if player == LocalPlayer then return end
        processText(message)
    end

    -- Chat loglarını kontrol et
    local function checkChatLogs()
        local ChatService = game:GetService("Chat")
        local chatLogs = ChatService:FindFirstChild("ChatLogs")
        if chatLogs then
            for _, log in ipairs(chatLogs:GetChildren()) do
                if log:IsA("Folder") and log.Name == "PlayerChats" then
                    for _, playerChat in ipairs(log:GetChildren()) do
                        for _, message in ipairs(playerChat:GetChildren()) do
                            if message:IsA("Instance") and message:FindFirstChild("Message") then
                                processText(message.Message.Value)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Chat'i izle
    local ChatService = game:GetService("Chat")
    if ChatService.Chatted then
        ChatService.Chatted:Connect(onChatted)
    end

    -- Chat loglarını periyodik olarak kontrol et
    coroutine.wrap(function()
        while true do
            checkChatLogs()
            wait(5)
        end
    end)()
end

--// UI Oluşturma
local function createUI()
    -- Eğer zaten UI varsa sil
    local oldGui = game:GetService("CoreGui"):FindFirstChild("MoonHubRedeemerGui") or
                  LocalPlayer.PlayerGui:FindFirstChild("MoonHubRedeemerGui")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MoonHubRedeemerGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

    local MainFrame = Instance.new("Frame")
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

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 2
    mainStroke.Color = Color3.fromRGB(40, 100, 220)
    mainStroke.Parent = MainFrame

    --// Başlık
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

    --// Alt başlık
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

    --// Auto Write Toggle
    local autoWriteRow = Instance.new("Frame")
    autoWriteRow.Size = UDim2.new(1, -20, 0, 40)
    autoWriteRow.Position = UDim2.new(0, 10, 0, 45)
    autoWriteRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
    autoWriteRow.Parent = MainFrame

    local autoWriteCorner = Instance.new("UICorner")
    autoWriteCorner.CornerRadius = UDim.new(0, 8)
    autoWriteCorner.Parent = autoWriteRow

    local autoWriteStroke = Instance.new("UIStroke")
    autoWriteStroke.Thickness = 1
    autoWriteStroke.Color = Color3.fromRGB(40, 100, 220)
    autoWriteStroke.Parent = autoWriteRow

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
    awSwitchBg.BackgroundColor3 = _G.AutoWriteEnabled and Color3.fromRGB(40, 100, 220) or Color3.fromRGB(20, 35, 75)
    awSwitchBg.Parent = autoWriteRow

    local awSwitchCorner = Instance.new("UICorner")
    awSwitchCorner.CornerRadius = UDim.new(0, 9)
    awSwitchCorner.Parent = awSwitchBg

    local awSwitchKnob = Instance.new("Frame")
    awSwitchKnob.Size = UDim2.new(0, 14, 0, 14)
    awSwitchKnob.Position = _G.AutoWriteEnabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    awSwitchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    awSwitchKnob.Parent = awSwitchBg

    local awSwitchCorner2 = Instance.new("UICorner")
    awSwitchCorner2.CornerRadius = UDim.new(0, 7)
    awSwitchCorner2.Parent = awSwitchKnob

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

    --// Auto Submit Toggle
    local autoSubmitRow = Instance.new("Frame")
    autoSubmitRow.Size = UDim2.new(1, -20, 0, 40)
    autoSubmitRow.Position = UDim2.new(0, 10, 0, 90)
    autoSubmitRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
    autoSubmitRow.Parent = MainFrame

    local autoSubmitCorner = Instance.new("UICorner")
    autoSubmitCorner.CornerRadius = UDim.new(0, 8)
    autoSubmitCorner.Parent = autoSubmitRow

    local autoSubmitStroke = Instance.new("UIStroke")
    autoSubmitStroke.Thickness = 1
    autoSubmitStroke.Color = Color3.fromRGB(40, 100, 220)
    autoSubmitStroke.Parent = autoSubmitRow

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

    local asSwitchBg = Instance.new("Frame")
    asSwitchBg.Size = UDim2.new(0, 36, 0, 18)
    asSwitchBg.Position = UDim2.new(1, -46, 0.5, -9)
    asSwitchBg.BackgroundColor3 = _G.AutoSubmitEnabled and Color3.fromRGB(40, 100, 220) or Color3.fromRGB(20, 35, 75)
    asSwitchBg.Parent = autoSubmitRow

    local asSwitchCorner = Instance.new("UICorner")
    asSwitchCorner.CornerRadius = UDim.new(0, 9)
    asSwitchCorner.Parent = asSwitchBg

    local asSwitchKnob = Instance.new("Frame")
    asSwitchKnob.Size = UDim2.new(0, 14, 0, 14)
    asSwitchKnob.Position = _G.AutoSubmitEnabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    asSwitchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    asSwitchKnob.Parent = asSwitchBg

    local asSwitchCorner2 = Instance.new("UICorner")
    asSwitchCorner2.CornerRadius = UDim.new(0, 7)
    asSwitchCorner2.Parent = asSwitchKnob

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

    --// Draggable yap
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// Başlatma
local function init()
    createUI()
    startMonitoring()
end

--// Scripti başlat
init()
