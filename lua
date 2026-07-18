_G.ScriptEnabled = true
_G.CasingType = "Normal"
_G.AutoWriteEnabled = true
_G.AutoSubmitEnabled = true
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
_G.SubmitAfterCount = 1
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
    ["redeem"]=true, ["claim"]=true,
    ["enter"]=true, ["reward"]=true, ["rewards"]=true, ["update"]=true, ["join"]=true,
    ["group"]=true, ["like"]=true, ["follow"]=true, ["sub"]=true, ["click"]=true,
    ["type"]=true, ["copy"]=true, ["paste"]=true, ["server"]=true, ["event"]=true,
    ["live"]=true, ["news"]=true, ["soon"]=true, ["available"]=true, ["expired"]=true,
    ["welcome"]=true, ["thanks"]=true, ["thank"]=true, ["player"]=true, ["players"]=true,
    ["today"]=true, ["time"]=true, ["wait"]=true, ["xp"]=true, ["money"]=true,
    ["sammy"]=true, ["announcement"]=true, ["announcements"]=true, ["release"]=true,
    ["released"]=true, ["limited"]=true, ["special"]=true, ["gift"]=true, ["pet"]=true,
    ["pets"]=true, ["egg"]=true, ["luck"]=true, ["boost"]=true, ["double"]=true,
    ["friend"]=true, ["friends"]=true, ["chat"]=true, ["online"]=true, ["offline"]=true,
    ["invite"]=true, ["party"]=true, ["voice"]=true, ["report"]=true, ["block"]=true,
    ["mute"]=true, ["store"]=true, ["shop"]=true, ["inventory"]=true, ["settings"]=true,
    ["leaderboard"]=true, ["lobby"]=true, ["menu"]=true, ["close"]=true, ["open"]=true,
    ["back"]=true, ["next"]=true, ["play"]=true, ["exit"]=true, ["loading"]=true,
    ["negozio"]=true, ["rinascita"]=true, ["indice"]=true, ["duelli"]=true,
    ["scambio"]=true, ["codici"]=true, ["incremento"]=true, ["amico"]=true,
    ["drop"]=true, ["present"]=true,
    ["win"]=true, ["wins"]=true, ["winner"]=true, ["winners"]=true, ["winning"]=true,
    ["winter"]=true, ["victory"]=true, ["lose"]=true, ["loss"]=true, ["losses"]=true,
    ["defeat"]=true, ["daily"]=true, ["spin"]=true, ["wheel"]=true, ["prize"]=true,
    ["bonus"]=true, ["streak"]=true, ["rank"]=true, ["wave"]=true, ["round"]=true,
    ["score"]=true, ["match"]=true, ["versus"]=true, ["battle"]=true, ["quest"]=true
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

local function isLoneCode(text)
    if not text then return false end
    text = text:match("^%s*(.-)%s*$")
    if text == "" or text:find("%s") then return false end
    if #text < 3 or #text > 20 then return false end
    if not text:match("^%w+$") then return false end
    if isBlacklisted(text:lower()) then return false end
    if text:match("^%d+[smhdSMHD]$") then return false end
    if text:match("^%d+$") then
        return #text >= 3
    end
    local letters = 0
    for _ in text:gmatch("%a") do letters = letters + 1 end
    return letters >= 2
end

local function extractCodesFromText(text)
    local found = {}
    if not text then return found end
    local trimmed = text:match("^%s*(.-)%s*$")
    trimmed = trimmed:gsub("<[^>]->", "")
    if isLoneCode(trimmed) then
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
    elseif toclipboard then
        pcall(function() toclipboard(formattedCode) end)
        success = true
    elseif set_clipboard then
        pcall(function() set_clipboard(formattedCode) end)
        success = true
    elseif Clipboard and Clipboard.set then
        pcall(function() Clipboard.set(formattedCode) end)
        success = true
    end
    if success then
        logStatus("Copied: " .. formattedCode)
    else
        logStatus("Error: No clipboard support! " .. formattedCode)
    end
    return success
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
            if isSubmitButton(obj) then
                target = obj
                break
            end
        end
        container = container.Parent
        levels = levels + 1
    end
    if not target then return false end
    fireSignal(target.MouseButton1Click)
    fireSignal(target.Activated)
    return true
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
    local ok, result = pcall(function()
        return rf:InvokeServer(formatted)
    end)
    if ok then
        logStatus("Redeemed via RF: " .. formatted .. (result ~= nil and (" → " .. tostring(result)) or ""))
        return true
    else
        logStatus("RF invoke failed: " .. tostring(result))
        return false
    end
end

local function writeAndSubmit(code)
    if redeemViaRF(code) then return true end
    local textBox = findCodeTextBox()
    if not textBox then
        logStatus("Waiting for an open code box...")
        return false
    end
    local formatted = formatCode(code)
    pcall(function() textBox.ClearTextOnFocus = false end)
    if not collectedSeen[formatted] then
        collectedSeen[formatted] = true
        table.insert(collectedCodes, formatted)
    end
    local fullText = table.concat(collectedCodes, CODE_SEPARATOR)
    local target = math.max(1, tonumber(_G.SubmitAfterCount) or 1)
    local ready = #collectedCodes >= target
    if ready and _G.AutoSubmitEnabled then
        local count = #collectedCodes
        local btn = false
        for i = 1, _G.SubmitAttempts do
            local box = findCodeTextBox()
            if not box then break end
            local ok = pcall(function()
                box:CaptureFocus()
                box.Text = fullText
                box.CursorPosition = #fullText + 1
            end)
            if not ok then
                pcall(function() box.Text = fullText end)
            end
            pcall(function() box:ReleaseFocus(true) end)
            if fireSubmitButton(box) then btn = true end
        end
        logStatus("Submitted " .. count .. " x" .. _G.SubmitAttempts .. ": " .. fullText)
        table.clear(collectedCodes)
        table.clear(collectedSeen)
    else
        local ok = pcall(function()
            textBox:CaptureFocus()
            textBox.Text = fullText
            textBox.CursorPosition = #fullText + 1
        end)
        if not ok then
            pcall(function() textBox.Text = fullText end)
        end
        if ready then
            logStatus("Collected " .. #collectedCodes .. " codes: " .. fullText)
            table.clear(collectedCodes)
            table.clear(collectedSeen)
        else
            logStatus("Added: " .. formatted .. " (" .. #collectedCodes .. "/" .. target .. ")")
        end
    end
    return true
end

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
        if not ok then warn("[GammaHub] triggerWrite error: " .. tostring(err)) end
    end)
end

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
    autoWriteConn = { Disconnect = function()
        if boxConn then boxConn:Disconnect() end
        if boxRemConn then boxRemConn:Disconnect() end
    end }
    table.insert(activeConnections, autoWriteConn)
end

local function extractStrings(val, out)
    out = out or {}
    local t = type(val)
    if t == "string" then
        table.insert(out, val)
    elseif t == "table" then
        for _, v in pairs(val) do
            extractStrings(v, out)
        end
    end
    return out
end

local function processText(text)
    if not text or text == "" then return end
    local codes = extractCodesFromText(text)
    if #codes == 0 then return end
    for _, code in ipairs(codes) do
        copyCodeToClipboard(code)
        latestCode = code
        if not pendingSeen[code] then
            pendingSeen[code] = true
            table.insert(pendingQueue, code)
            triggerWrite()
        end
        logStatus("Code detected: " .. code)
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
    local getinfo = debug and (debug.getinfo or debug.info)
    if getconnections and getinfo then
        for _, d in ipairs(Net:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                local ok, cs = pcall(getconnections, d.OnClientEvent)
                if ok and cs then
                    for _, c in ipairs(cs) do
                        local f, fn = pcall(function() return c.Function end)
                        if f and type(fn) == "function" then
                            local i, info = pcall(getinfo, fn)
                            if i and tostring((type(info) == "table" and (info.short_src or info.source)) or info or ""):find("NotificationController", 1, true) then
                                _G.PhiNotifyRemote = d
                                return d
                            end
                        end
                    end
                end
            end
        end
    end
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
        logStatus("Resolving PhiNotify remote...")
        local NC = resolveRemote()
        if not NC then
            logStatus("PhiNotify remote not found.")
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
        logStatus("Hooked " .. NC.Name .. " — Active!")
    end)
end

local function cleanupMonitoring()
    for _, conn in pairs(activeConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(activeConnections)
    table.clear(enteredCodes)
    table.clear(collectedCodes)
    table.clear(collectedSeen)
    table.clear(pendingQueue)
    table.clear(pendingSeen)
    writeBusy = false
    autoWriteConn = nil
    latestCode = nil
    lastWrittenCode = nil
end

-- ==================== MOON HUB STYLE GUI ====================
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local oldGui = CoreGui:FindFirstChild("GammaHubCodeCopier") or LocalPlayer.PlayerGui:FindFirstChild("GammaHubCodeCopier")
if oldGui then oldGui:Destroy() end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GammaHubCodeCopier"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

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
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 50, 150)),
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

MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 130)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
MainFrame.BackgroundTransparency = 0.25
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

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

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

createAnimatedStroke(MainFrame, 2, 0.8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 22)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Gamma Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 17
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = MainFrame

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 60, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 60, 255)),
})
titleGrad.Parent = title

task.spawn(function()
    while MainFrame.Parent do
        titleGrad.Rotation = (titleGrad.Rotation + 1.3) % 360
        task.wait()
    end
end)

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 16)
subtitle.Position = UDim2.new(0, 10, 0, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Code Auto Redeemer"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 12
subtitle.TextColor3 = Color3.new(1, 1, 1)
subtitle.TextTransparency = 0.4
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = MainFrame

local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -20, 0, 45)
toggleRow.Position = UDim2.new(0, 10, 0, 55)
toggleRow.BackgroundColor3 = Color3.fromRGB(15, 25, 55)
toggleRow.ZIndex = 2
toggleRow.Parent = MainFrame

Instance.new("UICorner", toggleRow)
createAnimatedStroke(toggleRow, 1, 1.2)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0, 90, 1, 0)
toggleLabel.Position = UDim2.new(0, 12, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Auto Redeem"
toggleLabel.Font = Enum.Font.GothamBlack
toggleLabel.TextSize = 14
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

local switchBg = Instance.new("Frame")
switchBg.Size = UDim2.new(0, 42, 0, 22)
switchBg.Position = UDim2.new(1, -52, 0.5, -11)
switchBg.BackgroundTransparency = 1
switchBg.ZIndex = 3
switchBg.Parent = toggleRow

Instance.new("UICorner", switchBg).CornerRadius = UDim.new(0, 11)
createAnimatedStroke(switchBg, 2, 1.5)

local switchKnob = Instance.new("Frame")
switchKnob.Size = UDim2.new(0, 18, 0, 18)
switchKnob.Position = UDim2.new(0, 2, 0.5, -9)
switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
switchKnob.ZIndex = 4
switchKnob.Parent = switchBg

Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(0, 9)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.ZIndex = 4
toggleBtn.Parent = toggleRow

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 105)
StatusLabel.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
StatusLabel.BackgroundTransparency = 0.3
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 185)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = StatusLabel

local isToggled = false

local function setToggle(newState)
    isToggled = newState
    _G.ScriptEnabled = newState
    local goal = newState and UDim2.new(1, -22, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    local color = newState and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(180, 60, 60)
    TweenService:Create(switchKnob, TweenInfo.new(0.2), {Position = goal}):Play()
    TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    
    if newState then
        logStatus("Auto Redeem Started")
        startMonitoring()
        startAutoWriteLoop()
    else
        logStatus("Auto Redeem Stopped")
        cleanupMonitoring()
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    setToggle(not isToggled)
end)

-- Initialize
setToggle(false)
logStatus("Script Loaded - Click to Start")

print("Gamma Hub Code Copier loaded successfully.")
