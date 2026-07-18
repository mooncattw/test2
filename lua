_G.ScriptEnabled = true
_G.CasingType = "Normal"
_G.AutoWriteEnabled = true
_G.AutoSubmitEnabled = true
_G.SubmitAfterCount = 1

local pendingQueue = {}
local pendingSeen = {}
local collectedCodes = {}
local collectedSeen = {}
local writeBusy = false
local activeConnections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local ScreenGui, MainFrame

local function logStatus(message)
    if MainFrame and MainFrame:FindFirstChild("StatusLabel") then
        MainFrame.StatusLabel.Text = "Status: " .. message
    end
    print("[MoonHub Code Copier] " .. message)
end

-- ==================== CODE DETECTION ====================

local function looksLikeCode(token)
    if not token or #token < 4 or #token > 25 then return false end
    if not token:match("^[%w_]+$") then return false end
    
    local lower = token:lower()
    local badWords = {"top","sec","min","fps","ping","loading","points","coins","cash","rebirth","slaps","money","level","lvl","score","the","and","for","you","redeem","claim","enter"}
    for _, w in ipairs(badWords) do
        if lower:find(w) then return false end
    end

    local letters = 0
    for _ in token:gmatch("%a") do letters += 1 end
    return letters >= 2
end

local function extractCodes(text)
    local codes = {}
    if not text then return codes end
    text = text:gsub("<[^>]+>", ""):gsub("[%c%p]", " ")
    
    for token in text:gmatch("[%w_]+") do
        if looksLikeCode(token) then
            table.insert(codes, token)
        end
    end
    return codes
end

-- ==================== REDEEM FUNCTIONS ====================

local function findCodeTextBox()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextBox") and gui.Visible then
            local name = (gui.Name .. " " .. (gui.PlaceholderText or "")):lower()
            if name:find("code") or name:find("redeem") or name:find("enter") then
                return gui
            end
        end
    end
    return nil
end

local function redeemCode(code)
    -- Direct Remote
    local rf = ReplicatedStorage:FindFirstChild("RF", true)
    if rf then
        local remote = rf:FindFirstChild("RequestRedemption") or rf:FindFirstChildWhichIsA("RemoteFunction")
        if remote then
            pcall(function()
                remote:InvokeServer(code)
            end)
            logStatus("Redeemed via Remote: " .. code)
            return true
        end
    end

    -- TextBox Method
    local box = findCodeTextBox()
    if box then
        pcall(function()
            box:CaptureFocus()
            box.Text = code
            box:ReleaseFocus(true)
        end)
        
        -- Auto Submit
        if _G.AutoSubmitEnabled then
            task.wait(0.3)
            for _, btn in ipairs(box.Parent:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    local txt = (btn.Text or btn.Name):lower()
                    if txt:find("redeem") or txt:find("submit") or txt:find("enter") then
                        firesignal(btn.MouseButton1Click)
                        logStatus("Submitted: " .. code)
                        return true
                    end
                end
            end
        end
        logStatus("Written: " .. code)
        return true
    end
    return false
end

-- ==================== GUI (Moon Hub Style) ====================

local function createGUI()
    if ScreenGui then ScreenGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MoonHubCodeCopier"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 160)
    MainFrame.Position = UDim2.new(0.5, -125, 0.4, -80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", MainFrame)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 160, 255)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Moon Hub"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 20
    title.TextColor3 = Color3.new(1,1,1)
    title.Parent = MainFrame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -20, 0, 18)
    sub.Position = UDim2.new(0, 10, 0, 35)
    sub.BackgroundTransparency = 1
    sub.Text = "Code Copier"
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(150, 200, 255)
    sub.Parent = MainFrame

    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 140, 0, 40)
    toggleBtn.Position = UDim2.new(0.5, -70, 0, 65)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    toggleBtn.Text = "START"
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 16
    toggleBtn.Parent = MainFrame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

    -- Submit After
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0, 100, 0, 25)
    countLabel.Position = UDim2.new(0, 15, 0, 118)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Submit after:"
    countLabel.TextColor3 = Color3.fromRGB(200,200,200)
    countLabel.TextSize = 13
    countLabel.Font = Enum.Font.Gotham
    countLabel.Parent = MainFrame

    local countBox = Instance.new("TextBox")
    countBox.Size = UDim2.new(0, 45, 0, 25)
    countBox.Position = UDim2.new(0, 115, 0, 118)
    countBox.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
    countBox.Text = "1"
    countBox.TextColor3 = Color3.new(1,1,1)
    countBox.Font = Enum.Font.GothamBold
    countBox.TextSize = 14
    countBox.Parent = MainFrame
    Instance.new("UICorner", countBox).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel")
    status.Name = "StatusLabel"
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 1, -28)
    status.BackgroundTransparency = 1
    status.Text = "Status: Stopped"
    status.TextColor3 = Color3.fromRGB(160, 160, 160)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.Parent = MainFrame

    -- Dragging
    local dragging = false
    MainFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local startPos = MainFrame.Position
            local startMouse = inp.Position
            local conn
            conn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    local delta = input.Position - startMouse
                    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    -- Toggle
    toggleBtn.MouseButton1Click:Connect(function()
        _G.ScriptEnabled = not _G.ScriptEnabled
        if _G.ScriptEnabled then
            toggleBtn.Text = "STOP"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            logStatus("Running...")
        else
            toggleBtn.Text = "START"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            logStatus("Stopped")
        end
    end)

    countBox.FocusLost:Connect(function()
        _G.SubmitAfterCount = math.max(1, tonumber(countBox.Text) or 1)
        countBox.Text = _G.SubmitAfterCount
    end)
end

-- ==================== MAIN LOGIC ====================

local function processCode(code)
    if pendingSeen[code] then return end
    pendingSeen[code] = true
    table.insert(pendingQueue, code)

    if not writeBusy then
        writeBusy = true
        task.spawn(function()
            while #pendingQueue > 0 and _G.ScriptEnabled do
                local c = table.remove(pendingQueue, 1)
                redeemCode(c)
                task.wait(0.4)
            end
            writeBusy = false
        end)
    end
end

local function startHook()
    local net = ReplicatedStorage:FindFirstChild("Packages", true)
    if net then
        for _, v in ipairs(net:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local conn = v.OnClientEvent:Connect(function(...)
                    if not _G.ScriptEnabled then return end
                    for _, arg in ipairs({...}) do
                        if type(arg) == "string" then
                            for _, code in ipairs(extractCodes(arg)) do
                                processCode(code)
                            end
                        end
                    end
                end)
                table.insert(activeConnections, conn)
            end
        end
    end
    logStatus("Hook Active")
end

local function init()
    for _, c in ipairs(activeConnections) do pcall(function() c:Disconnect() end) end
    table.clear(activeConnections)
    
    createGUI()
    startHook()
    logStatus("Ready - Press START")
end

init()
