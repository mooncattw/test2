-- ============================================================
-- FIVE DUELS V3 - TARGET HUB STYLE (with Always-On Speed Display)
-- With Instant Toggle: TP BAT, BAT V2, AIMBOT
-- With Original Auto Steal Bar (STEAL 0% | Ping: --ms)
-- Added: BAT V2 (Sakura Anti Bypass style)
-- Added: AIMBOT SPEED SETTING & FOLLOW DISTANCE
-- Fixed: Auto Left/Right (no overlap, priority last press)
-- Added: Insta Reset Button (from Tokinu) - RENAMED TO RESET
-- Fixed: FPS Boost, button size 60x59, white text
-- Fixed: All bugs and errors
-- Fixed: Aimbot integrated from Cyber Hub v1.0
-- Added: Keybind for Lagger Carry
-- MODIFIED: Visual style to match TARGET HUB (grey/white/dark) -> NOW BLUE THEME
-- MODIFIED: Added rotating neon border effect (buildNeonBorder)
-- MODIFIED: Fonts changed to "Bangers" for headers/tabs
-- NEW: Other Players Speed is ALWAYS ON (no toggle needed)
-- NEW: ESP persists after opponent respawn (fixed CharacterAdded)
-- REMOVED: Button press animation (no movement when clicked)
-- REMOVED: Clean Effects button
-- FIXED: Auto steal properly saves state when toggled off/on
-- FIXED: Save config now correctly saves autoStealEnabled when OFF
-- FIXED: Auto Steal uses original working version (not Ace Duels)
-- ADDED: Ping display on steal bar (Cyber Hub style)
-- MODIFIED: Steal bar size slightly reduced (270 width)
-- ADDED: Aimbot Follow Distance in GUI
-- FIXED: BAT V2 toggle state persistence
-- CHANGED: BAT V2 speed to 59
-- ============================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local request = http_request or request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
if not request then return end

local LP = Players.LocalPlayer
if not LP then LP = Players.PlayerAdded:Wait() end

if _G.GreenDuelsV2_Running then return end
_G.GreenDuelsV2_Running = true

local UIS = UserInputService

local _isfile = isfile or (syn and syn.isfile) or (getgenv and getgenv().isfile) or function() return false end
local _readfile = readfile or (syn and syn.readfile) or (getgenv and getgenv().readfile) or function() return nil end
local _writefile = writefile or (syn and syn.writefile) or (getgenv and getgenv().writefile) or function() end
local _delfile = delfile or (syn and syn.delfile) or (getgenv and getgenv().delfile) or function() end
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

local _request = request or http_request or (syn and syn.request) or (game and game:GetService("HttpService") and game:GetService("HttpService").RequestAsync) or nil

if not fireproximityprompt then
    fireproximityprompt = (getgenv and getgenv().fireproximityprompt)
        or (genv and genv().fireproximityprompt)
        or function(prompt)
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
        end
end

repeat task.wait() until game:IsLoaded()

-- ============================================================
-- AUTO STEAL (ORIGINAL WORKING VERSION)
-- ============================================================
local Steal = {
    AutoStealEnabled = true,
    StealRadius = 55,
    StealDuration = 0.25,
    Data = {}
}

local isStealing = false
local stealStartTime = nil
local stealProgressConn = nil
local progressFill = nil
local percentLabel = nil

local function getHRP_Steal()
    local char = LP.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    end
    return nil
end

local function isMyPlot(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function findNearestPrompt()
    local hrp = getHRP_Steal()
    if not hrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local bestPrompt, bestDist = nil, math.huge
    local radius = Steal.StealRadius
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") and not isMyPlot(plot.Name) then
            local pods = plot:FindFirstChild("AnimalPodiums")
            if pods then
                for _, pod in ipairs(pods:GetChildren()) do
                    local base = pod:FindFirstChild("Base")
                    if base then
                        local spawn = base:FindFirstChild("Spawn")
                        if spawn then
                            local dist = (spawn.Position - hrp.Position).Magnitude
                            if dist <= radius and dist < bestDist then
                                local att = spawn:FindFirstChild("PromptAttachment")
                                if att then
                                    for _, prompt in ipairs(att:GetChildren()) do
                                        if prompt:IsA("ProximityPrompt") and prompt.ActionText and prompt.ActionText:find("Steal") then
                                            bestPrompt, bestDist = prompt, dist
                                        end
                                    end
                                end
                                if not bestPrompt then
                                    for _, prompt in ipairs(spawn:GetDescendants()) do
                                        if prompt:IsA("ProximityPrompt") and prompt.ActionText and prompt.ActionText:find("Steal") then
                                            bestPrompt, bestDist = prompt, dist
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPrompt
end

local stealDataCache = {}

local function executeSteal(prompt)
    if isStealing then return end
    if not stealDataCache[prompt] then
        local data = {hold = {}, trigger = {}, ready = true}
        if getconnections then
            local holds = getconnections(prompt.PromptButtonHoldBegan)
            for _, conn in ipairs(holds) do
                if conn.Function then table.insert(data.hold, conn.Function) end
            end
            local triggers = getconnections(prompt.Triggered)
            for _, conn in ipairs(triggers) do
                if conn.Function then table.insert(data.trigger, conn.Function) end
            end
        end
        stealDataCache[prompt] = data
    end
    local data = stealDataCache[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true
    local startTime = tick()
    local duration = Steal.StealDuration
    
    if stealProgressConn then stealProgressConn:Disconnect() end
    stealProgressConn = RunService.Heartbeat:Connect(function()
        if not isStealing then
            if stealProgressConn then stealProgressConn:Disconnect(); stealProgressConn = nil end
            return
        end
        local elapsed = tick() - startTime
        local p = math.clamp(elapsed / duration, 0, 1)
        if progressFill then
            progressFill.Size = UDim2.new(p, 0, 1, 0)
        end
        if percentLabel then
            percentLabel.Text = math.floor(p * 100) .. "%"
        end
    end)
    
    task.spawn(function()
        for _, fn in ipairs(data.hold) do task.spawn(fn) end
        local elapsed = 0
        while elapsed < duration do
            elapsed = elapsed + task.wait()
        end
        if progressFill then
            progressFill.Size = UDim2.new(1, 0, 1, 0)
        end
        if percentLabel then
            percentLabel.Text = "100%"
        end
        for _, fn in ipairs(data.trigger) do task.spawn(fn) end
        task.wait(0.05)
        if progressFill then
            progressFill.Size = UDim2.new(0, 0, 1, 0)
        end
        if percentLabel then
            percentLabel.Text = "0%"
        end
        if stealProgressConn then stealProgressConn:Disconnect(); stealProgressConn = nil end
        data.ready = true
        isStealing = false
    end)
end

local autoStealConn = nil

local function startAutoSteal()
    if autoStealConn then return end
    autoStealConn = RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        local success, prompt = pcall(findNearestPrompt)
        if success and prompt then pcall(executeSteal, prompt) end
    end)
    if toggleSetters and toggleSetters["autoSteal"] then
        toggleSetters["autoSteal"](true)
    end
end

local function stopAutoSteal()
    if autoStealConn then 
        autoStealConn:Disconnect() 
        autoStealConn = nil 
    end
    if stealProgressConn then 
        stealProgressConn:Disconnect() 
        stealProgressConn = nil 
    end
    isStealing = false
    stealDataCache = {}
    if progressFill then
        progressFill.Size = UDim2.new(0, 0, 1, 0)
    end
    if percentLabel then
        percentLabel.Text = "0%"
    end
    if toggleSetters and toggleSetters["autoSteal"] then
        toggleSetters["autoSteal"](false)
    end
end

local function toggleAutoSteal()
    Steal.AutoStealEnabled = not Steal.AutoStealEnabled
    if Steal.AutoStealEnabled then
        startAutoSteal()
    else
        stopAutoSteal()
    end
    requestSave()
end

_G.AutoSteal = Steal

-- ============================================================
-- INSTA RESET (from Cyber Hub v1.0 - Tokinu style)
-- ============================================================
local resetRemote = nil
local RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"

pcall(function()
    if hookfunction and newcclosure then
        local oldFire
        oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not resetRemote and typeof(self) == "Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3) == "RE/" then 
                resetRemote = self 
            end
            return oldFire(self, ...)
        end))
    end
end)

task.spawn(function()
    task.wait(2)
    if resetRemote then return end
    for _, desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then 
            resetRemote = desc
            break 
        end
    end
end)

local function doInstantReset()
    if not resetRemote then
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then 
                resetRemote = desc
                break 
            end
        end
    end
    
    if not resetRemote then 
        local character = LP.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            else
                character:BreakJoints()
            end
        end
        return 
    end
    
    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if humanoid and humanoid.Health <= 0 then 
        pcall(function() 
            resetRemote:FireServer(RESET_GUID, LP, "balloon") 
        end)
        return 
    end
    
    local savedTools = {}
    local bp = LP:FindFirstChild("Backpack")
    
    if character then
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:UnequipTools() end) end
        for _, t in ipairs(character:GetChildren()) do
            if t:IsA("Tool") then 
                table.insert(savedTools, t)
                t.Parent = nil
            end
        end
    end
    
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then 
                table.insert(savedTools, t)
                t.Parent = nil
            end
        end
    end
    
    LP.Character = nil
    
    local resetDetected = false
    local conns = {}
    
    if humanoid then
        table.insert(conns, humanoid.Died:Connect(function() 
            resetDetected = true 
        end))
        table.insert(conns, humanoid:GetPropertyChangedSignal("Health"):Connect(function() 
            if humanoid.Health <= 0 then 
                resetDetected = true 
            end 
        end))
    end
    
    if character then 
        table.insert(conns, character.AncestryChanged:Connect(function(_, parent) 
            if not parent then 
                resetDetected = true 
            end 
        end)) 
    end
    
    task.spawn(function()
        for _ = 1, 50 do
            if resetDetected then break end
            pcall(function() 
                resetRemote:FireServer(RESET_GUID, LP, "balloon") 
            end)
            task.wait()
        end
        for _, conn in ipairs(conns) do 
            pcall(function() 
                conn:Disconnect() 
            end) 
        end
    end)
    
    local conn
    conn = LP.CharacterAdded:Connect(function()
        if conn then 
            conn:Disconnect() 
        end
        task.spawn(function()
            local newBp = LP:WaitForChild("Backpack", 3)
            if newBp then
                for _, t in ipairs(savedTools) do 
                    if t then t.Parent = newBp end 
                end
            end
            savedTools = {}
        end)
    end)
    
    task.delay(4, function()
        if conn then
            conn:Disconnect()
            conn = nil
        end
        local curBp = LP:FindFirstChild("Backpack")
        if curBp and #savedTools > 0 then
            for _, t in ipairs(savedTools) do 
                if t then t.Parent = curBp end 
            end
            savedTools = {}
        end
    end)
end

-- ============================================================
-- CONFIG VERSION & EARLY LOAD
-- ============================================================
local CONFIG_VERSION = 3
local CONFIG_FILE = "GreenDuelsConfig.json"
local CONFIG_BACKUP = "GreenDuelsConfig.bak"

local earlyConfig = nil
local function loadEarlyConfig()
    if not _isfile(CONFIG_FILE) then return nil end
    local raw = _readfile(CONFIG_FILE)
    if not raw then return nil end
    local ok, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and cfg and cfg.version == CONFIG_VERSION then return cfg end
    return nil end
earlyConfig = loadEarlyConfig()
local introShouldPlay = (earlyConfig == nil or earlyConfig.introEnabled ~= false)

-- Intro (skip if disabled)
if introShouldPlay then
    local _TS = TweenService
    local _PG = LP:WaitForChild("PlayerGui")
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "MoonHubIntro"
    introGui.ResetOnSpawn = false
    introGui.IgnoreGuiInset = true
    introGui.DisplayOrder = 999
    introGui.Parent = _PG

    local introSound = Instance.new("Sound", introGui)
    introSound.SoundId = "rbxassetid://77815492250502"
    introSound.Volume = 0.5
    introSound:Play()

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.new(0,0,0)
    bg.BackgroundTransparency = 0.95
    bg.BorderSizePixel = 0
    bg.Parent = introGui

    local blur = Instance.new("BlurEffect")
    blur.Size = 12
    blur.Parent = game:GetService("Lighting")

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0,400,0,300)
    container.Position = UDim2.new(0.5,-200,0.5,-150)
    container.BackgroundTransparency = 1
    container.Parent = bg

    local LOGO_ID = "rbxassetid://16478039709"
    task.spawn(function() pcall(function() ContentProvider:PreloadAsync({LOGO_ID}) end) end)

    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0,120,0,120)
    logo.Position = UDim2.new(0.5,-60,0,30)
    logo.BackgroundTransparency = 1
    logo.Image = LOGO_ID
    logo.ImageColor3 = Color3.fromRGB(0, 100, 255)
    logo.ImageTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = container

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,50)
    title.Position = UDim2.new(0,0,0,170)
    title.BackgroundTransparency = 1
    title.Text = "MOON HUB"
    title.TextColor3 = Color3.fromRGB(0, 150, 255)
    title.TextTransparency = 1
    title.TextScaled = true
    title.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    title.TextStrokeTransparency = 0.2
    title.TextStrokeColor3 = Color3.new(0,0,0)
    title.Parent = container

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(0.8,0,0,30)
    sub.Position = UDim2.new(0.1,0,0,230)
    sub.BackgroundTransparency = 1
    sub.Text = "MOON HUB IN UR FACE 😂"
    sub.TextColor3 = Color3.fromRGB(100, 180, 255)
    sub.TextTransparency = 1
    sub.TextScaled = true
    sub.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    sub.Parent = container

    local loadingBg = Instance.new("Frame")
    loadingBg.Size = UDim2.new(0.6,0,0,4)
    loadingBg.Position = UDim2.new(0.2,0,0,275)
    loadingBg.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
    loadingBg.BackgroundTransparency = 0.5
    loadingBg.BorderSizePixel = 0
    loadingBg.Parent = container
    Instance.new("UICorner", loadingBg).CornerRadius = UDim.new(0,2)

    local loadingBar = Instance.new("Frame")
    loadingBar.Size = UDim2.new(0,0,1,0)
    loadingBar.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    loadingBar.BackgroundTransparency = 0.3
    loadingBar.BorderSizePixel = 0
    loadingBar.Parent = loadingBg
    Instance.new("UICorner", loadingBar).CornerRadius = UDim.new(0,2)

    _TS:Create(bg, TweenInfo.new(0.7), {BackgroundTransparency = 0.95}):Play()
    _TS:Create(logo, TweenInfo.new(0.7), {ImageTransparency = 0}):Play()
    _TS:Create(title, TweenInfo.new(0.7), {TextTransparency = 0}):Play()
    _TS:Create(sub, TweenInfo.new(0.7), {TextTransparency = 0.3}):Play()
    _TS:Create(loadingBar, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)}):Play()
    task.wait(2.5)
    _TS:Create(bg, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
    _TS:Create(logo, TweenInfo.new(0.8), {ImageTransparency = 1}):Play()
    _TS:Create(title, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
    _TS:Create(sub, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
    _TS:Create(loadingBg, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
    task.wait(1)
    introGui:Destroy()
    blur:Destroy()
end

-- ============================================================
-- INFINITE JUMP (platform-based version)
-- ============================================================
local InfJumpPlatform = nil

local function CreateIJP()
    if InfJumpPlatform then return end
    InfJumpPlatform = Instance.new("Part")
    InfJumpPlatform.Name = "InfJumpPlatform"
    InfJumpPlatform.Size = Vector3.new(8, 0.5, 8)
    InfJumpPlatform.Anchored = true
    InfJumpPlatform.CanCollide = true
    InfJumpPlatform.Transparency = 1
    InfJumpPlatform.Material = Enum.Material.ForceField
    InfJumpPlatform.Parent = workspace
end

CreateIJP()

-- ============================================================
-- STATE
-- ============================================================

local State = {
    normalSpeed=60, carrySpeed=30, laggerSpeed=10.1, laggerCarrySpeed=15,
    speedToggled=false,
    laggerMode=0, -- 0=none, 1=lagger speed, 2=lagger carry
    hittingCooldown=false,
    tpBatActive=false,

    infJumpEnabled=true, antiRagdollEnabled=false,
    guiVisible=true, uiLocked=false,
    autoLeftEnabled=false, autoRightEnabled=false,
    autoLeftPhase=1, autoRightPhase=1,
    medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
    batAimbotToggled=false, autoSwingEnabled=false,
    batCounterEnabled=false, batCounterDebounce=false,
    dropEnabled=false, _tpInProgress=false,
    lastMoveDir=Vector3.new(0,0,0),
    _prevCarry=30, _prevSpeed=false,
    stackButtonsHidden=false,
    countdownActive=false,
    stackButtonsLocked=false,
    stretchedResEnabled=false,
    stretchFOV=120,
    tryardAnimEnabled=false,
    introEnabled=true,
    autoTPEnabled=false,
    autoTPHeight=50,
    autoTPConn=nil,
    fpsBoostEnabled=false,

    -- ESP states
    espEnabled=false,

    -- BAT V2 STATE
    batV2Enabled=false,
    batV2Cooldown=false,
    
    -- TP BAT STATE
    tpBatActive=false,

    -- Auto Reset Medusa
    autoResetMedusaEnabled=false,
}

if earlyConfig and earlyConfig.introEnabled ~= nil then
    State.introEnabled = earlyConfig.introEnabled
end

local Keys = {
    speed=Enum.KeyCode.Q, guiHide=Enum.KeyCode.LeftControl,
    autoLeft=Enum.KeyCode.L, autoRight=Enum.KeyCode.R,
    lagger=Enum.KeyCode.Unknown,
    laggerCarry=Enum.KeyCode.Unknown,
    tpDown=Enum.KeyCode.Unknown,
    drop=Enum.KeyCode.H, aimbot=Enum.KeyCode.Unknown,
    tpBat=Enum.KeyCode.Unknown,
    reset=Enum.KeyCode.R,
    batV2=Enum.KeyCode.V,
}

-- ============================================================
-- AIMBOT CONFIG
-- ============================================================
local AimbotConfig = {
    CHASE_SPEED = 58,
    VERT_SPEED = 52,
    FOLLOW_DIST = -2,
    HEIGHT_OFFSET = 1.6,
    VERT_OFFSET = 1,
    TURN_SPEED = 285,
    MAX_TURN_RATE = 40,
    SWING_ENABLED = true,
    MIN_FOLLOW_DIST = 1,
}

local unwalkSavedAnimate = nil

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

local function getHRP()
    local char = LP.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    end
    return nil
end

local function getBat()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("bat") or name:find("slap") then
                return tool
            end
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("bat") or name:find("slap") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function tryHitBat()
    if State.hittingCooldown then return end
    State.hittingCooldown = true
    pcall(function()
        local bat = getBat()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() State.hittingCooldown = false end)
end

local function getClosestPlayerForTPBat()
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then
                    cd = d
                    cp = p
                end
            end
        end
    end
    return cp, cd
end

-- ============================================================
-- INFINITE JUMP PLATFORM LOGIC
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not State.infJumpEnabled then 
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
        return 
    end
    
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and root and hum) then 
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
        return 
    end

    local isJumping = UIS:IsKeyDown(Enum.KeyCode.Space)
        or hum:GetState() == Enum.HumanoidStateType.Jumping
        or hum.Jump

    if isJumping then
        if not InfJumpPlatform then CreateIJP() end
        InfJumpPlatform.Position = root.Position - Vector3.new(0, 3.5, 0)
        if root.Velocity.Y < 50 then
            root.Velocity = Vector3.new(root.Velocity.X, 50, root.Velocity.Z)
        end
    else
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
    end
end)

-- ============================================================
-- TRYARD ANIMATION PACK
-- ============================================================
local TryardAnims = {
    idle1 = "rbxassetid://133806214992291",
    idle2 = "rbxassetid://94970088341563",
    walk  = "rbxassetid://707897309",
    run   = "rbxassetid://707861613",
    jump  = "rbxassetid://116936326516985",
    fall  = "rbxassetid://116936326516985",
    climb = "rbxassetid://116936326516985",
    swim  = "rbxassetid://116936326516985",
    swimidle = "rbxassetid://116936326516985",
}
task.spawn(function()
    pcall(function() ContentProvider:PreloadAsync({
        TryardAnims.idle1, TryardAnims.idle2, TryardAnims.walk, TryardAnims.run,
        TryardAnims.jump, TryardAnims.fall, TryardAnims.climb, TryardAnims.swim, TryardAnims.swimidle,
    }) end)
end)
local tryardHeartbeatConn = nil
local originalTryardAnims = nil
local function isTryardPackAnim(id) for _,v in pairs(TryardAnims) do if v==id then return true end end return false end
local function saveOriginalTryardAnims(char)
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local function g(obj) return obj and obj.AnimationId or nil end
    local ids = {
        idle1 = g(animate.idle and animate.idle.Animation1),
        idle2 = g(animate.idle and animate.idle.Animation2),
        walk  = g(animate.walk and animate.walk.WalkAnim),
        run   = g(animate.run  and animate.run.RunAnim),
        jump  = g(animate.jump and animate.jump.JumpAnim),
        fall  = g(animate.fall and animate.fall.FallAnim),
        climb = g(animate.climb and animate.climb.ClimbAnim),
        swim  = g(animate.swim and animate.swim.Swim),
        swimidle = g(animate.swimidle and animate.swimidle.SwimIdle),
    }
    if not isTryardPackAnim(ids.walk) then originalTryardAnims = ids end
end
local function applyTryardAnimPack(char)
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local function s(obj,id) if obj then obj.AnimationId=id end end
    s(animate.idle and animate.idle.Animation1, TryardAnims.idle1)
    s(animate.idle and animate.idle.Animation2, TryardAnims.idle2)
    s(animate.walk and animate.walk.WalkAnim, TryardAnims.walk)
    s(animate.run  and animate.run.RunAnim,   TryardAnims.run)
    s(animate.jump and animate.jump.JumpAnim, TryardAnims.jump)
    s(animate.fall and animate.fall.FallAnim, TryardAnims.fall)
    s(animate.climb and animate.climb.ClimbAnim, TryardAnims.climb)
    s(animate.swim and animate.swim.Swim, TryardAnims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, TryardAnims.swimidle)
end
local function stopTryardAnim()
    if tryardHeartbeatConn then tryardHeartbeatConn:Disconnect(); tryardHeartbeatConn=nil end
    if originalTryardAnims and LP.Character then
        local animate = LP.Character:FindFirstChild("Animate")
        if animate then
            local function s(obj,id) if obj then obj.AnimationId=id end end
            s(animate.idle and animate.idle.Animation1, originalTryardAnims.idle1)
            s(animate.idle and animate.idle.Animation2, originalTryardAnims.idle2)
            s(animate.walk and animate.walk.WalkAnim, originalTryardAnims.walk)
            s(animate.run  and animate.run.RunAnim,   originalTryardAnims.run)
            s(animate.jump and animate.jump.JumpAnim, originalTryardAnims.jump)
            s(animate.fall and animate.fall.FallAnim, originalTryardAnims.fall)
            s(animate.climb and animate.climb.ClimbAnim, originalTryardAnims.climb)
            s(animate.swim and animate.swim.Swim, originalTryardAnims.swim)
            s(animate.swimidle and animate.swimidle.SwimIdle, originalTryardAnims.swimidle)
        end
    end
end
local function startTryardAnim()
    if tryardHeartbeatConn then tryardHeartbeatConn:Disconnect() end
    local char = LP.Character
    if char then
        saveOriginalTryardAnims(char)
        applyTryardAnimPack(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do track:Stop(0) end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
    tryardHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not State.tryardAnimEnabled then return end
        local c = LP.Character
        if c then applyTryardAnimPack(c) end
    end)
end
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if State.tryardAnimEnabled and tryardHeartbeatConn then
        saveOriginalTryardAnims(char)
        applyTryardAnimPack(char)
    end
end)

-- ============================================================
-- DEFAULT STACK BUTTON POSITIONS - FIXED SIZE 60x59
-- ============================================================
local BTN_W=60
local BTN_H=59
local BTN_GAP=6
local COLS=2

local stackDefs = {
    {key="autoLeft",   label="AUTO\nLEFT"},
    {key="autoRight",  label="AUTO\nRIGHT"},
    {key="aimbot",     label="AIMBOT"},
    {key="lagger",     label="LAGGER\nSPEED"},
    {key="laggerCarry",label="LAGGER\nCARRY"},
    {key="drop",       label="DROP"},
    {key="tpDown",     label="TP\nDOWN"},
    {key="carrySpeed", label="CARRY\nSPEED"},
    {key="tpBat",      label="TP\nBAT"},
    {key="reset",      label="RESET"},
    {key="batV2",      label="BAT\nV2"},
}

local function getDefaultStackPos(i)
    local col=(i-1)%COLS
    local row2=math.floor((i-1)/COLS)
    return UDim2.new(1,-(COLS*(BTN_W+BTN_GAP)-BTN_GAP+14)+col*(BTN_W+BTN_GAP),
                     0.5,-(math.ceil(#stackDefs/COLS)*(BTN_H+BTN_GAP)-BTN_GAP)/2+row2*(BTN_H+BTN_GAP))
end

-- ============================================================
-- PRESETS
-- ============================================================
local Presets = {}
local PRESET_FILE = "GreenDuelsPresets.json"
local LAST_PRESET_FILE = "GreenDuelsLastPreset.json"

local function buildPresetSnapshot() return {
    normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed,
    laggerSpeed=State.laggerSpeed, laggerCarrySpeed=State.laggerCarrySpeed,
    stealRadius=Steal.StealRadius, stealDuration=Steal.StealDuration,
    infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
    medusaCounter=State.medusaCounterEnabled, batCounter=State.batCounterEnabled,
    autoSteal=Steal.AutoStealEnabled,
    autoTP=State.autoTPEnabled, autoTPHeight=State.autoTPHeight,
    aimbotSpeed=AimbotConfig.CHASE_SPEED,
    aimbotFollowDist=AimbotConfig.FOLLOW_DIST,
    batV2=State.batV2Enabled,
} end
local function savePresetsFile()
    local ok,enc=pcall(function() return HttpService:JSONEncode(Presets) end)
    if ok then pcall(function() _writefile(PRESET_FILE,enc) end) end
end
local function loadPresetsFile()
    if not _isfile(PRESET_FILE) then return end
    local raw; pcall(function() raw=_readfile(PRESET_FILE) end)
    if raw then
        local ok,dec=pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and dec then Presets=dec end
    end
end
local function saveLastPresetName(name)
    local ok,enc=pcall(function() return HttpService:JSONEncode({lastPreset=name}) end)
    if ok then pcall(function() _writefile(LAST_PRESET_FILE,enc) end) end
end
local function loadLastPresetName()
    if not _isfile(LAST_PRESET_FILE) then return nil end
    local raw; pcall(function() raw=_readfile(LAST_PRESET_FILE) end)
    if raw then
        local ok,dec=pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and dec then return dec.lastPreset end
    end
    return nil
end

local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Right]=true}

-- Auto Left/Right positions
local AP_L1     = Vector3.new(-476.48, -6.28, 92.73)
local AP_L2     = Vector3.new(-483.12, -4.95, 94.80)
local AP_L_FACE = Vector3.new(-482.25, -4.96, 92.09)
local AP_R1     = Vector3.new(-476.16, -6.52, 25.62)
local AP_R2     = Vector3.new(-483.06, -5.03, 25.48)
local AP_R_FACE = Vector3.new(-482.06, -6.93, 35.47)

local alConn, arConn = nil, nil
local alPhase, arPhase = 1, 1

local Conns={autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,aimbot=nil,anchor={},progress=nil,batCounter=nil, autoTP=nil, batV2=nil, tpBat=nil}
local h,hrp
local setAutoLeft,setAutoRight,setInfJump,setAntiRag
local setMedusaCounter,setAimbot,setAutoSwing
local setLagger,setLaggerCarry,setDropBrainrot,setInstaGrab
local setNoCam
local setupMedusaCounter,stopMedusaCounter,startAntiRagdoll,stopAntiRagdoll
local startAutoLeft,stopAutoLeft,startAutoRight,stopAutoRight
local saveConfig,loadConfig,runDrop,stopDrop,runTPDown
local requestSave
local startBatAimbot,stopBatAimbot,startBatCounter,stopBatCounter,setBatCounter
local startBatV2,stopBatV2,toggleBatV2
local startTPBat,stopTPBat,toggleTPBat
local toggleAimbot
local stackBtnRefs={}; local stackWrappers={}; local keybindBtnRefs={}
local normalBox,carryBox,laggerBox,laggerCarryBox,uiScaleBox,stealRadBox,stealDurBox,autoTPHeightBox,aimbotSpeedBox,aimbotFollowDistBox
local setHideButtonsToggle, setLockButtonsToggle
local presetListFrame=nil; local presetNameBox=nil; local rebuildPresetList
local toggleSetters = {}

-- ============================================================
-- BLUE THEME COLORS (MOON HUB)
-- ============================================================
local BLUE_MAIN = Color3.fromRGB(0, 120, 255)
local BLUE_LIGHT = Color3.fromRGB(80, 180, 255)
local BLUE_DARK = Color3.fromRGB(0, 40, 80)
local BLUE_DIM = Color3.fromRGB(40, 80, 120)
local BLUE_GLOW = Color3.fromRGB(0, 150, 255)
local BLUE_ACCENT = Color3.fromRGB(0, 100, 200)

local C = {
    winBg=Color3.fromRGB(0,0,5),
    winBg2=Color3.fromRGB(0,0,5),
    winBorder=BLUE_MAIN,
    sidebarBg=Color3.fromRGB(0,0,5),
    sidebarDiv=BLUE_MAIN,
    topBg=Color3.fromRGB(0,0,5),
    topTitle=BLUE_LIGHT,
    topSub=BLUE_DIM,
    topBtn=BLUE_MAIN,
    topBtnHov=BLUE_LIGHT,
    topDivider=BLUE_MAIN,
    tabBarBg=Color3.fromRGB(0,0,5),
    tabBarDiv=BLUE_MAIN,
    tabIdle=BLUE_DIM,
    tabIdleHov=BLUE_LIGHT,
    tabActive=BLUE_LIGHT,
    tabActiveBg=Color3.fromRGB(0,0,5),
    tabUnderline=BLUE_MAIN,
    sectionTxt=BLUE_LIGHT,
    sectionDiv=BLUE_MAIN,
    rowBg=Color3.fromRGB(0,0,5),
    rowBorder=BLUE_DIM,
    rowLabel=BLUE_LIGHT,
    rowSub=BLUE_DIM,
    rowValue=BLUE_LIGHT,
    rowHov=Color3.fromRGB(0,10,20),
    inputBg=Color3.fromRGB(0,0,5),
    inputBorder=BLUE_DIM,
    inputFocus=BLUE_MAIN,
    inputTxt=BLUE_LIGHT,
    pillOff=Color3.fromRGB(0,10,20),
    pillOn=BLUE_MAIN,
    dotOff=Color3.fromRGB(0,30,60),
    dotOn=Color3.fromRGB(0,0,5),
    pillBorder=BLUE_MAIN,
    modeBtnBg=Color3.fromRGB(0,0,5),
    modeBtnBrd=BLUE_DIM,
    modeBtnTxt=BLUE_DIM,
    modeBtnActBg=BLUE_MAIN,
    modeBtnActTx=Color3.fromRGB(0,0,5),
    chipBg=Color3.fromRGB(0,0,5),
    chipBorder=BLUE_DIM,
    chipTxt=BLUE_DIM,
    btnBg=Color3.fromRGB(0,0,5),
    btnBorder=BLUE_MAIN,
    btnTxt=BLUE_LIGHT,
    btnHov=Color3.fromRGB(0,10,30),
    stackBg=Color3.fromRGB(0,0,5),
    stackBrd=BLUE_DIM,
    stackTxt=BLUE_LIGHT,
    stackActBg=BLUE_MAIN,
    stackActBrd=BLUE_LIGHT,
    stackActTxt=Color3.fromRGB(0,0,5),
    stackDot=Color3.fromRGB(0,20,40),
    stackDotOn=BLUE_MAIN,
    infoBg=Color3.fromRGB(0,0,5),
    infoBrd=BLUE_DIM,
    infoTxt=BLUE_DIM,
    infoVal=BLUE_LIGHT,
    infoFill=BLUE_MAIN,
    accent=BLUE_MAIN,
    accentDim=BLUE_DIM,
    presetBg=Color3.fromRGB(0,0,5),
    presetBrd=BLUE_DIM,
    presetLoad=BLUE_MAIN,
    presetDel=Color3.fromRGB(40,0,0),
    delBrd=Color3.fromRGB(255,0,0),
    lockOn=BLUE_MAIN,
    divider=BLUE_DIM,
}

-- NEON BORDER BUILDER
local _neonConns = {}
local function buildNeonBorder(parent, thick, speed, pulseSpeed)
    thick      = thick      or 2
    speed      = speed      or 40
    pulseSpeed = pulseSpeed or 0.8

    local stroke = Instance.new("UIStroke", parent)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode    = Enum.LineJoinMode.Round
    stroke.Thickness       = thick
    stroke.Transparency    = 0
    stroke.Color           = BLUE_MAIN

    local grad = Instance.new("UIGradient", stroke)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 40, 80)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(0, 40, 80)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 40, 80)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 40, 80)),
    })

    local t = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not parent or not parent.Parent then return end
        t = t + dt
        grad.Rotation       = (t * speed) % 360
        local p             = (math.sin(t * pulseSpeed * math.pi * 2) + 1) / 2
        stroke.Transparency = 0.25 * (1 - p)
    end)
    table.insert(_neonConns, conn)
    return stroke
end

-- Helper functions
local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6); return c end
local function mkStroke(p,col,th) local s=Instance.new("UIStroke",p); s.Color=col; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s end

-- CLEANUP
do
    local cleanupNames = {"VyseSlottedGUI","VyseAsireGUI","VyseAsireHubV4","VyseAsireHubV5","VyseAsireHubV5_1","AsireHubV5_1","AsireHubV5_2","LaitoHubV1","GreenDuelsV1","GreenDuelsV2","MoonHub"}
    for _,name in ipairs(cleanupNames) do
        pcall(function() local o=game:GetService("CoreGui"):FindFirstChild(name); if o then o:Destroy() end end)
        pcall(function() local o=LP:WaitForChild("PlayerGui"):FindFirstChild(name); if o then o:Destroy() end end)
    end
end

-- ============================================================
-- FPS BOOST
-- ============================================================
local function applyFPSBoost()
    pcall(function() 
        if setfpscap then setfpscap(999999999) end 
    end)
    
    local function optimizeObject(v)
        pcall(function()
            if v:IsA("Model") then
                pcall(function() v.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled end)
                pcall(function() v.ModelStreamingMode = Enum.ModelStreamingMode.Nonatomic end)
            elseif v:IsA("MeshPart") then
                pcall(function() v.CastShadow = false end)
                pcall(function() v.DoubleSided = false end)
                pcall(function() v.RenderFidelity = Enum.RenderFidelity.Performance end)
            elseif v:IsA("BasePart") then
                pcall(function() v.CastShadow = false end)
                pcall(function() v.Material = Enum.Material.Plastic end)
                pcall(function() v.Reflectance = 0 end)
            elseif v:IsA("Decal") or v:IsA("Texture") then
                pcall(function() v.Transparency = 1 end)
            elseif v:IsA("SpecialMesh") then
                pcall(function() v.TextureId = "" end)
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                pcall(function() v.Enabled = false end)
            elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then
                pcall(function() v:Destroy() end)
            elseif v:IsA("Attachment") then
                pcall(function() v.Visible = false end)
            end
        end)
    end
    
    for _,v in pairs(workspace:GetDescendants()) do 
        optimizeObject(v) 
    end
    
    pcall(function()
        local L = game:GetService("Lighting")
        for _,v in pairs(L:GetDescendants()) do
            pcall(function()
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or 
                   v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or 
                   v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then
                    v:Destroy()
                end
            end)
        end
        pcall(function() 
            if sethiddenproperty then
                sethiddenproperty(L, "Technology", Enum.Technology.Legacy) 
            end
        end)
        pcall(function() L.GlobalShadows = false end)
        pcall(function() L.FogEnd = 9e9 end)
        pcall(function() L.Brightness = 0 end)
        
        local ter = workspace:FindFirstChildOfClass("Terrain")
        if ter then
            pcall(function() 
                if sethiddenproperty then
                    sethiddenproperty(ter, "Decoration", false) 
                end
            end)
            pcall(function() ter.WaterReflectance = 0 end)
            pcall(function() ter.WaterTransparency = 0.7 end)
            pcall(function() ter.WaterWaveSize = 0 end)
            pcall(function() ter.WaterWaveSpeed = 0 end)
        end
    end)
    
    workspace.DescendantAdded:Connect(function(v)
        if State.fpsBoostEnabled then
            task.spawn(optimizeObject, v)
        end
    end)
end

local function disableFPSBoost()
    State.fpsBoostEnabled = false
    pcall(function()
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 10000
        Lighting.Brightness = 1
        pcall(function() 
            if sethiddenproperty then
                sethiddenproperty(Lighting, "Technology", Enum.Technology.Future) 
            end
        end)
    end)
end

-- ============================================================
-- AUTO TP DOWN
-- ============================================================
local function doAutoTPDown(force)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if not force then
        if hrp.Position.Y < State.autoTPHeight then return end
    end
    
    hrp.CFrame = CFrame.new(hrp.Position.X, -7, hrp.Position.Z) * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local function startAutoTP()
    if State.autoTPConn then task.cancel(State.autoTPConn); State.autoTPConn = nil end
    State.autoTPConn = task.spawn(function()
        while State.autoTPEnabled do
            task.wait(0.1)
            pcall(function() doAutoTPDown(false) end)
        end
    end)
end

local function stopAutoTP()
    State.autoTPEnabled = false
    if State.autoTPConn then task.cancel(State.autoTPConn); State.autoTPConn = nil end
end

runTPDown = function()
    pcall(function() doAutoTPDown(true) end)
end

-- ============================================================
-- JUMP DROP
-- ============================================================
local DROP_ASCEND_DURATION = 0.22
local DROP_ASCEND_SPEED = 160
local _dropConn = nil
local dropActive = false

local function runJumpDrop()
    if dropActive then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    dropActive = true
    if stackBtnRefs.drop then stackBtnRefs.drop.setOn(true) end
    local t0 = tick()
    if _dropConn then _dropConn:Disconnect() end
    _dropConn = RunService.Heartbeat:Connect(function()
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then
            if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
            dropActive = false
            if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
            return
        end
        if not dropActive then
            if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
            if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
            return
        end
        if tick() - t0 >= DROP_ASCEND_DURATION then
            if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
            pcall(function()
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {c}
                rp.FilterType = Enum.RaycastFilterType.Exclude
                local rr = workspace:Raycast(r.Position, Vector3.new(0, -3000, 0), rp)
                if rr then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    local off = ((hum and hum.HipHeight) or 2) + (r.Size.Y / 2)
                    r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z)
                    r.AssemblyLinearVelocity = Vector3.zero
                end
            end)
            dropActive = false
            if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
            return
        end
        local lv = r.AssemblyLinearVelocity
        r.AssemblyLinearVelocity = Vector3.new(lv.X, DROP_ASCEND_SPEED, lv.Z)
    end)
end

runDrop = runJumpDrop

LP.CharacterRemoving:Connect(function()
    dropActive = false
    if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
end)

stopDrop = function()
    dropActive = false
    if _dropConn then _dropConn:Disconnect(); _dropConn = nil end
    if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
end

-- ============================================================
-- BAT V2 (Sakura Anti Bypass style) - SPEED SET TO 59
-- ============================================================
local function getHRP_V2()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getBat_V2()
    local char = LP.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        tool = bp:FindFirstChild("Bat")
        if tool then tool.Parent = char; return tool end
    end
    return nil
end

local function tryHitBat_V2()
    if State.batV2Cooldown then return end
    State.batV2Cooldown = true
    pcall(function()
        local bat = getBat_V2()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() State.batV2Cooldown = false end)
end

local function getClosestPlayer_V2()
    local hrp = getHRP_V2()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then cd = d; cp = p end
            end
        end
    end
    return cp, cd
end

startBatV2 = function()
    if Conns.batV2 then return end
    Conns.batV2 = RunService.RenderStepped:Connect(function()
        if not State.batV2Enabled then return end
        local hrp = getHRP_V2()
        if not hrp then return end
        local target, dist = getClosestPlayer_V2()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local fp = tr.Position + tr.CFrame.LookVector * 1.5
                local dir = (fp - hrp.Position).Unit
                hrp.Velocity = Vector3.new(dir.X * 59, dir.Y * 59, dir.Z * 59)
                if dist <= 2 then tryHitBat_V2() end
            end
        end
    end)
end

stopBatV2 = function()
    if Conns.batV2 then
        Conns.batV2:Disconnect()
        Conns.batV2 = nil
    end
    local hrp = getHRP_V2()
    if hrp then hrp.Velocity = Vector3.zero end
end

toggleBatV2 = function(on)
    if on == nil then
        on = not State.batV2Enabled
    end
    
    if on then
        if State.tpBatActive then
            State.tpBatActive = false
            if Conns.tpBat then
                Conns.tpBat:Disconnect()
                Conns.tpBat = nil
            end
            if stackBtnRefs.tpBat then 
                stackBtnRefs.tpBat.setOn(false) 
            end
        end
        
        if State.batAimbotToggled then
            State.batAimbotToggled = false
            if autoBatConnection then
                autoBatConnection:Disconnect()
                autoBatConnection = nil
            end
            resetAutoBatMotion()
            stopUnwalkAimbot()
            if stackBtnRefs.aimbot then 
                stackBtnRefs.aimbot.setOn(false) 
            end
        end
        
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if alConn then alConn:Disconnect(); alConn = nil end
            if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if arConn then arConn:Disconnect(); arConn = nil end
            if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
        end
    end
    
    State.batV2Enabled = on
    if on then
        startBatV2()
    else
        stopBatV2()
    end
    if stackBtnRefs.batV2 then
        stackBtnRefs.batV2.setOn(on)
    end
    if toggleSetters and toggleSetters["batV2"] then
        toggleSetters["batV2"](on)
    end
end

LP.CharacterAdded:Connect(function()
    if State.batV2Enabled then
        task.wait(0.5)
        local bat = getBat_V2()
        if bat then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(bat) end) end
        end
    end
    if State.batAimbotToggled then
        task.wait(0.3)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
        ensureBatEquipped()
    end
end)

-- ============================================================
-- INSTANT TOGGLE: TP BAT, BAT V2, AIMBOT
-- ============================================================

-- TP BAT FUNCTIONS
local function startTPBat()
    if Conns.tpBat then return end
    Conns.tpBat = RunService.Heartbeat:Connect(function()
        if not (State.tpBatActive) then return end
        local hrp = getHRP()
        if not hrp then return end
        local target = getClosestPlayerForTPBat()
        if target and target.Character then
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                pcall(function()
                    if sethiddenproperty then
                        sethiddenproperty(hrp, "PhysicsRepRootPart", tr)
                    end
                    local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
                    if (hrp.Position - targetPos).Magnitude > 8 then
                        hrp.CFrame = CFrame.new(targetPos)
                    end
                    local cam = workspace.CurrentCamera
                    cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
                    tryHitBat()
                end)
            end
        end
    end)
end

local function stopTPBat()
    if Conns.tpBat then
        Conns.tpBat:Disconnect()
        Conns.tpBat = nil
    end
end

toggleTPBat = function()
    local newState = not State.tpBatActive
    
    if newState then
        if State.batV2Enabled then
            State.batV2Enabled = false
            if Conns.batV2 then
                Conns.batV2:Disconnect()
                Conns.batV2 = nil
            end
            local hrp2 = getHRP_V2()
            if hrp2 then hrp2.Velocity = Vector3.zero end
            if stackBtnRefs.batV2 then 
                stackBtnRefs.batV2.setOn(false) 
            end
            if toggleSetters and toggleSetters["batV2"] then
                toggleSetters["batV2"](false)
            end
        end
        
        if State.batAimbotToggled then
            State.batAimbotToggled = false
            if autoBatConnection then
                autoBatConnection:Disconnect()
                autoBatConnection = nil
            end
            resetAutoBatMotion()
            stopUnwalkAimbot()
            if stackBtnRefs.aimbot then 
                stackBtnRefs.aimbot.setOn(false) 
            end
        end
        
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if alConn then alConn:Disconnect(); alConn = nil end
            if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if arConn then arConn:Disconnect(); arConn = nil end
            if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
        end
    end
    
    State.tpBatActive = newState
    if stackBtnRefs.tpBat then
        stackBtnRefs.tpBat.setOn(newState)
    end
    if newState then 
        startTPBat() 
    else 
        stopTPBat() 
    end
    requestSave()
end

-- ============================================================
-- AIMBOT
-- ============================================================

local function getChar() return LP.Character end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function resetAutoBatMotion()
    local root = getRoot()
    local hum = getHum()
    if root then
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.3
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then hum.AutoRotate = true end
end

local function startUnwalkAimbot()
    local char = getChar()
    if not char then return end
    local hum = getHum()
    if hum then
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    local animate = char:FindFirstChild("Animate")
    if animate then
        unwalkSavedAnimate = animate:Clone()
        animate:Destroy()
    end
end

local function stopUnwalkAimbot()
    local char = getChar()
    if char and unwalkSavedAnimate then
        unwalkSavedAnimate.Parent = char
        unwalkSavedAnimate = nil
    end
end

local function getAutoBatTarget()
    local root = getRoot()
    if not root then return nil end
    local now = tick()
    if now - (_autoBatLastScan or 0) <= 0.1 and _autoBatTarget and _autoBatTarget.Parent then
        local hum = _autoBatTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return _autoBatTarget
        end
    end
    _autoBatLastScan = now
    _autoBatTarget = nil
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = tRoot
                end
            end
        end
    end
    _autoBatTarget = closest
    return _autoBatTarget
end

local function findBatAimbot()
    local char = getChar()
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("bat") or name:find("slap") then
                return tool
            end
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("bat") or name:find("slap") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function ensureBatEquipped()
    local char = getChar()
    local hum = getHum()
    if not char or not hum then return end
    if not char:FindFirstChildOfClass("Tool") then
        local bat = findBatAimbot()
        if bat then
            pcall(function() hum:EquipTool(bat) end)
        end
    end
end

local _autoBatTarget = nil
local _autoBatLastScan = 0
local autoBatConnection = nil

local function startAutoBatLoop()
    if autoBatConnection then return end
    startUnwalkAimbot()
    autoBatConnection = RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled then return end
        local char = getChar()
        local hum = getHum()
        local root = getRoot()
        if not char or not hum or not root then return end
        
        ensureBatEquipped()
        
        local target = getAutoBatTarget()
        if target then
            local targetVel = target.AssemblyLinearVelocity
            local aimTargetPos = target.Position + (targetVel * math.clamp(targetVel.Magnitude / 130, 0.05, 0.15)) + Vector3.new(0, AimbotConfig.VERT_OFFSET, 0)
            hum.AutoRotate = false
            local look = aimTargetPos - root.Position
            local flatLook = Vector3.new(look.X, 0, look.Z)
            if look.Magnitude > 0.01 and flatLook.Magnitude > 0.01 then
                local targetYaw = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
                local yawDelta = (targetYaw - root.Orientation.Y + 180) % 360 - 180
                local targetPitch = math.deg(math.atan2(look.Y, flatLook.Magnitude))
                local pitchDelta = (targetPitch - root.Orientation.X + 180) % 360 - 180
                local yawRate = math.clamp(math.rad(yawDelta) * AimbotConfig.TURN_SPEED, -AimbotConfig.MAX_TURN_RATE, AimbotConfig.MAX_TURN_RATE)
                local pitchRate = math.clamp(math.rad(pitchDelta) * AimbotConfig.TURN_SPEED, -AimbotConfig.MAX_TURN_RATE, AimbotConfig.MAX_TURN_RATE)
                local yawRad = math.rad(root.Orientation.Y)
                local rightAxis = Vector3.new(math.cos(yawRad), 0, -math.sin(yawRad))
                root.AssemblyAngularVelocity = Vector3.new(0, yawRate, 0) + (rightAxis * pitchRate)
            else
                root.AssemblyAngularVelocity = Vector3.zero
            end
            
            local followDist = math.max(math.abs(AimbotConfig.FOLLOW_DIST), AimbotConfig.MIN_FOLLOW_DIST)
            local dir = look.Magnitude > 0.01 and look.Unit or Vector3.new(1,0,0)
            local standPos = aimTargetPos - (dir * followDist) + Vector3.new(0, AimbotConfig.HEIGHT_OFFSET, 0)
            local moveDir = standPos - root.Position
            local hDir = Vector3.new(moveDir.X, 0, moveDir.Z)
            local hVel = hDir.Magnitude > 0.1 and hDir.Unit * AimbotConfig.CHASE_SPEED or Vector3.zero
            local vVel = math.abs(moveDir.Y) > 0.1 and Vector3.new(0, math.sign(moveDir.Y) * AimbotConfig.VERT_SPEED, 0) or Vector3.new(0, -2, 0)
            root.AssemblyLinearVelocity = hVel + vVel
            if hDir.Magnitude > 0.5 then
                hum:Move(hDir.Unit, false)
            end
            if AimbotConfig.SWING_ENABLED and (root.Position - target.Position).Magnitude < 6 then
                local bat = findBatAimbot()
                if bat and bat:IsA("Tool") then
                    pcall(function() bat:Activate() end)
                end
            end
        else
            hum.AutoRotate = true
            root.AssemblyAngularVelocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function stopAutoBatLoop()
    if autoBatConnection then
        autoBatConnection:Disconnect()
        autoBatConnection = nil
    end
    resetAutoBatMotion()
    stopUnwalkAimbot()
end

toggleAimbot = function()
    local newState = not State.batAimbotToggled
    
    if newState then
        if State.tpBatActive then
            State.tpBatActive = false
            if Conns.tpBat then
                Conns.tpBat:Disconnect()
                Conns.tpBat = nil
            end
            if stackBtnRefs.tpBat then 
                stackBtnRefs.tpBat.setOn(false) 
            end
        end
        
        if State.batV2Enabled then
            State.batV2Enabled = false
            if Conns.batV2 then
                Conns.batV2:Disconnect()
                Conns.batV2 = nil
            end
            local hrp2 = getHRP_V2()
            if hrp2 then hrp2.Velocity = Vector3.zero end
            if stackBtnRefs.batV2 then 
                stackBtnRefs.batV2.setOn(false) 
            end
            if toggleSetters and toggleSetters["batV2"] then
                toggleSetters["batV2"](false)
            end
        end
        
        if State.autoLeftEnabled then
            State.autoLeftEnabled = false
            if alConn then alConn:Disconnect(); alConn = nil end
            if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
        end
        if State.autoRightEnabled then
            State.autoRightEnabled = false
            if arConn then arConn:Disconnect(); arConn = nil end
            if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
        end
    end
    
    State.batAimbotToggled = newState
    if newState then
        startAutoBatLoop()
    else
        stopAutoBatLoop()
    end
    if stackBtnRefs.aimbot then 
        stackBtnRefs.aimbot.setOn(newState) 
    end
    requestSave()
end

-- ============================================================
-- AUTO LEFT / RIGHT
-- ============================================================
stopAutoLeft = function()
    if alConn then 
        alConn:Disconnect() 
        alConn = nil 
    end
    alPhase = 1
    local char = LP.Character
    if char then
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then 
            hum2:Move(Vector3.zero, false) 
        end
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            hrp2.AssemblyLinearVelocity = Vector3.zero
        end
    end
    State.autoLeftEnabled = false
    if stackBtnRefs.autoLeft then 
        stackBtnRefs.autoLeft.setOn(false) 
    end
end

stopAutoRight = function()
    if arConn then 
        arConn:Disconnect() 
        arConn = nil 
    end
    arPhase = 1
    local char = LP.Character
    if char then
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then 
            hum2:Move(Vector3.zero, false) 
        end
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            hrp2.AssemblyLinearVelocity = Vector3.zero
        end
    end
    State.autoRightEnabled = false
    if stackBtnRefs.autoRight then 
        stackBtnRefs.autoRight.setOn(false) 
    end
end

startAutoLeft = function()
    if State.autoRightEnabled then
        stopAutoRight()
    end
    
    if State.tpBatActive then
        State.tpBatActive = false
        if Conns.tpBat then
            Conns.tpBat:Disconnect()
            Conns.tpBat = nil
        end
        if stackBtnRefs.tpBat then stackBtnRefs.tpBat.setOn(false) end
    end
    
    if State.batV2Enabled then
        State.batV2Enabled = false
        if Conns.batV2 then
            Conns.batV2:Disconnect()
            Conns.batV2 = nil
        end
        local hrp2 = getHRP_V2()
        if hrp2 then hrp2.Velocity = Vector3.zero end
        if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(false) end
        if toggleSetters and toggleSetters["batV2"] then
            toggleSetters["batV2"](false)
        end
    end
    
    if State.batAimbotToggled then
        State.batAimbotToggled = false
        if autoBatConnection then
            autoBatConnection:Disconnect()
            autoBatConnection = nil
        end
        resetAutoBatMotion()
        stopUnwalkAimbot()
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end
    end
    
    if alConn then 
        alConn:Disconnect() 
    end
    alPhase = 1
    State.autoLeftEnabled = true
    if stackBtnRefs.autoLeft then 
        stackBtnRefs.autoLeft.setOn(true) 
    end
    
    alConn = RunService.Heartbeat:Connect(function()
        if not State.autoLeftEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not hrp2 or not hum2 then return end
        local spd = State.normalSpeed
        if alPhase == 1 then
            local tgt = Vector3.new(AP_L1.X, hrp2.Position.Y, AP_L1.Z)
            if (tgt - hrp2.Position).Magnitude < 1 then
                alPhase = 2
                local d = AP_L2 - hrp2.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false)
                hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
                return
            end
            local d = AP_L1 - hrp2.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
        elseif alPhase == 2 then
            local tgt = Vector3.new(AP_L2.X, hrp2.Position.Y, AP_L2.Z)
            if (tgt - hrp2.Position).Magnitude < 1 then
                hum2:Move(Vector3.zero, false)
                hrp2.AssemblyLinearVelocity = Vector3.zero
                State.autoLeftEnabled = false
                if alConn then alConn:Disconnect(); alConn = nil end
                alPhase = 1
                if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
                if (AP_L_FACE - hrp2.Position).Magnitude > 0.01 then
                    hrp2.CFrame = CFrame.new(hrp2.Position, Vector3.new(AP_L_FACE.X, hrp2.Position.Y, AP_L_FACE.Z))
                end
                return
            end
            local d = AP_L2 - hrp2.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
        end
    end)
end

startAutoRight = function()
    if State.autoLeftEnabled then
        stopAutoLeft()
    end
    
    if State.tpBatActive then
        State.tpBatActive = false
        if Conns.tpBat then
            Conns.tpBat:Disconnect()
            Conns.tpBat = nil
        end
        if stackBtnRefs.tpBat then stackBtnRefs.tpBat.setOn(false) end
    end
    
    if State.batV2Enabled then
        State.batV2Enabled = false
        if Conns.batV2 then
            Conns.batV2:Disconnect()
            Conns.batV2 = nil
        end
        local hrp2 = getHRP_V2()
        if hrp2 then hrp2.Velocity = Vector3.zero end
        if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(false) end
        if toggleSetters and toggleSetters["batV2"] then
            toggleSetters["batV2"](false)
        end
    end
    
    if State.batAimbotToggled then
        State.batAimbotToggled = false
        if autoBatConnection then
            autoBatConnection:Disconnect()
            autoBatConnection = nil
        end
        resetAutoBatMotion()
        stopUnwalkAimbot()
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end
    end
    
    if arConn then 
        arConn:Disconnect() 
    end
    arPhase = 1
    State.autoRightEnabled = true
    if stackBtnRefs.autoRight then 
        stackBtnRefs.autoRight.setOn(true) 
    end
    
    arConn = RunService.Heartbeat:Connect(function()
        if not State.autoRightEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not hrp2 or not hum2 then return end
        local spd = State.normalSpeed
        if arPhase == 1 then
            local tgt = Vector3.new(AP_R1.X, hrp2.Position.Y, AP_R1.Z)
            if (tgt - hrp2.Position).Magnitude < 1 then
                arPhase = 2
                local d = AP_R2 - hrp2.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false)
                hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
                return
            end
            local d = AP_R1 - hrp2.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
        elseif arPhase == 2 then
            local tgt = Vector3.new(AP_R2.X, hrp2.Position.Y, AP_R2.Z)
            if (tgt - hrp2.Position).Magnitude < 1 then
                hum2:Move(Vector3.zero, false)
                hrp2.AssemblyLinearVelocity = Vector3.zero
                State.autoRightEnabled = false
                if arConn then arConn:Disconnect(); arConn = nil end
                arPhase = 1
                if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
                if (AP_R_FACE - hrp2.Position).Magnitude > 0.01 then
                    hrp2.CFrame = CFrame.new(hrp2.Position, Vector3.new(AP_R_FACE.X, hrp2.Position.Y, AP_R_FACE.Z))
                end
                return
            end
            local d = AP_R2 - hrp2.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
        end
    end)
end

-- ============================================================
-- LAGGER MODE FUNCTIONS
-- ============================================================
local function updateLaggerButtons()
    if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerMode==1) end
    if stackBtnRefs.laggerCarry then stackBtnRefs.laggerCarry.setOn(State.laggerMode==2) end
    if stackBtnRefs.carrySpeed then 
        if State.laggerMode ~= 0 then
            State.speedToggled = false
            stackBtnRefs.carrySpeed.setOn(false)
        else
            stackBtnRefs.carrySpeed.setOn(State.speedToggled)
        end
    end
end

local function setLaggerMode(mode)
    if mode == State.laggerMode then return end

    State.speedToggled = false
    if stackBtnRefs.carrySpeed then
        stackBtnRefs.carrySpeed.setOn(false)
    end

    if mode == 0 then
        if carryBox then
            carryBox.Text = tostring(State.normalSpeed)
        end
    elseif mode == 1 then
        if carryBox then
            carryBox.Text = tostring(State.laggerSpeed)
        end
    elseif mode == 2 then
        if carryBox then
            carryBox.Text = tostring(State.laggerCarrySpeed)
        end
    end

    State.laggerMode = mode
    updateLaggerButtons()
    requestSave()
end

local function toggleLaggerMode()
    if State.laggerMode == 0 then
        setLaggerMode(1)
    elseif State.laggerMode == 1 then
        setLaggerMode(0)
    else
        setLaggerMode(1)
    end
end

local function toggleLaggerCarryMode()
    if State.laggerMode == 0 then
        setLaggerMode(2)
    elseif State.laggerMode == 2 then
        setLaggerMode(0)
    else
        setLaggerMode(2)
    end
end

local function toggleSpeed()
    if State.laggerMode ~= 0 then
        setLaggerMode(0)
    end
    
    State.speedToggled = not State.speedToggled
    if stackBtnRefs.carrySpeed then
        stackBtnRefs.carrySpeed.setOn(State.speedToggled)
    end
    if carryBox then
        carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed)
    end
    requestSave()
end

-- ============================================================
-- MAIN UI BUILD
-- ============================================================

local function Main()
    if _G.GreenDuelsV2_MainExecuted then return end
    _G.GreenDuelsV2_MainExecuted = true

    local gui=Instance.new("ScreenGui")
    gui.Name="MoonHub"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
    gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=LP:WaitForChild("PlayerGui")
    local uiScaleObj=Instance.new("UIScale",gui); uiScaleObj.Scale=1.0

    local function makeDraggable(frame,handle)
        local src=handle or frame
        local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
        src.InputBegan:Connect(function(inp)
            if State.uiLocked then return end
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                dragging=true; dragStart=inp.Position; startPos=frame.Position
                inp.Changed:Connect(function() if inp.UserInputState==Enum.InputUserState.End then dragging=false end end)
            end
        end)
        src.InputChanged:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
        end)
        UIS.InputChanged:Connect(function(inp)
            if inp==dragInput and dragging and not State.uiLocked then
                local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
                frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
            end
        end)
    end

    local function makeStackDraggable(frame, onTap)
        local dragStartPos, startPos = nil, nil
        local isDragging = false
        local movedEnough = false
        local wasPressed = false
        local pressTime = 0
        local movementAllowed = not State.stackButtonsLocked
        local saveDebounce = nil

        local lockChangedConn = RunService.Heartbeat:Connect(function()
            movementAllowed = not State.stackButtonsLocked
        end)

        frame.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            wasPressed = true
            pressTime = tick()
            dragStartPos = input.Position
            startPos = frame.Position
            isDragging = true
            movedEnough = false
        end)

        frame.InputChanged:Connect(function(input)
            if not isDragging or not movementAllowed then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStartPos
                if delta.Magnitude > 8 then movedEnough = true end
                if movedEnough then
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end)

        frame.InputEnded:Connect(function(input)
            local wasPressedLocal = wasPressed
            wasPressed = false
            if not isDragging then return end
            isDragging = false

            if movedEnough then
                if saveDebounce then task.cancel(saveDebounce) end
                saveDebounce = task.delay(0.2, function()
                    pcall(requestSave)
                    saveDebounce = nil
                end)
            end

            if wasPressedLocal and not movedEnough and (tick() - pressTime) < 0.3 then
                if onTap then onTap() end
            end
        end)

        frame.AncestryChanged:Connect(function()
            if not frame.Parent then lockChangedConn:Disconnect() end
        end)
    end

    -- GUI SIZE
    local WIN_W = 260
    local WIN_H = 350
    local TITLE_H = 38
    local ROUND = 24
    
    local mainOuter = Instance.new("Frame", gui)
    mainOuter.Name = "MainOuter"
    mainOuter.Size = UDim2.new(0, WIN_W, 0, WIN_H)
    mainOuter.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
    mainOuter.BackgroundTransparency = 1
    mainOuter.BorderSizePixel = 0
    mainOuter.ClipsDescendants = true
    mkCorner(mainOuter, ROUND)
    buildNeonBorder(mainOuter, 2, 25, 0.8)
    makeDraggable(mainOuter)

    local bgImg = Instance.new("Frame", mainOuter)
    bgImg.Name = "BgFill"
    bgImg.Size = UDim2.new(1,0,1,0)
    bgImg.BackgroundColor3 = Color3.fromRGB(0,0,5)
    bgImg.BorderSizePixel = 0
    bgImg.ZIndex = 0
    mkCorner(bgImg, ROUND)

    local accentBar = Instance.new("Frame", mainOuter)
    accentBar.Size = UDim2.new(1, -60, 0, 1)
    accentBar.Position = UDim2.new(0, 30, 0, 0)
    accentBar.BackgroundColor3 = BLUE_MAIN
    accentBar.BackgroundTransparency = 0.5
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 2

    local titleBar = Instance.new("Frame", mainOuter)
    titleBar.Size = UDim2.new(1,0,0,TITLE_H)
    titleBar.BackgroundColor3 = C.topBg
    titleBar.BackgroundTransparency = 1
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 5

    -- Title (MOON HUB) - Avatar removed
    local titleLbl = Instance.new("TextLabel", titleBar)
    titleLbl.Size = UDim2.new(1, -50, 0, 18)
    titleLbl.Position = UDim2.new(0, 12, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "MOON HUB"
    titleLbl.TextColor3 = BLUE_LIGHT
    titleLbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    titleLbl.TextSize = 16
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 6

    local subTitleLbl = Instance.new("TextLabel", titleBar)
    subTitleLbl.Size = UDim2.new(1, -50, 0, 12)
    subTitleLbl.Position = UDim2.new(0, 12, 0, 24)
    subTitleLbl.BackgroundTransparency = 1
    subTitleLbl.Text = "USING MOON HUB"
    subTitleLbl.TextColor3 = BLUE_DIM
    subTitleLbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    subTitleLbl.TextSize = 10
    subTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    subTitleLbl.ZIndex = 6

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0,24,0,24)
    closeBtn.Position = UDim2.new(1,-32,0.5,-12)
    closeBtn.BackgroundColor3 = C.modeBtnBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = BLUE_MAIN
    closeBtn.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    closeBtn.TextSize = 18
    closeBtn.ZIndex = 7
    mkCorner(closeBtn,6)
    buildNeonBorder(closeBtn, 1, 30, 0.6)
    
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {TextColor3=BLUE_LIGHT}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.1), {TextColor3=BLUE_MAIN}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        State.guiVisible = false
        mainOuter.Visible = false
        if _G.GreenDuelsQAHide then pcall(_G.GreenDuelsQAHide, true) end
        requestSave()
    end)

    local titleDiv = Instance.new("Frame", mainOuter)
    titleDiv.Size = UDim2.new(1,0,0,1)
    titleDiv.Position = UDim2.new(0,0,0,TITLE_H)
    titleDiv.BackgroundColor3 = BLUE_MAIN
    titleDiv.BorderSizePixel = 0
    titleDiv.ZIndex = 5

    local CONTENT_Y = TITLE_H + 1
    local contentBg = Instance.new("Frame", mainOuter)
    contentBg.Size = UDim2.new(1,0,1,-CONTENT_Y)
    contentBg.Position = UDim2.new(0,0,0,CONTENT_Y)
    contentBg.BackgroundColor3 = C.winBg2
    contentBg.BackgroundTransparency = 0
    contentBg.BorderSizePixel = 0
    contentBg.ClipsDescendants = true
    contentBg.ZIndex = 2
    mkCorner(contentBg, ROUND - 2)

    local mainScroll = Instance.new("ScrollingFrame", contentBg)
    mainScroll.Name = "MainScroll"
    mainScroll.Size = UDim2.new(1,0,1,0)
    mainScroll.BackgroundTransparency = 1
    mainScroll.BorderSizePixel = 0
    mainScroll.ScrollBarThickness = 2
    mainScroll.ScrollBarImageColor3 = BLUE_MAIN
    mainScroll.ScrollBarImageTransparency = 0.4
    mainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    mainScroll.CanvasSize = UDim2.new(0,0,0,0)
    mainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    mainScroll.ZIndex = 3

    local mainLL = Instance.new("UIListLayout", mainScroll)
    mainLL.SortOrder = Enum.SortOrder.LayoutOrder
    mainLL.Padding = UDim.new(0,3)
    mainLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local mainPad = Instance.new("UIPadding", mainScroll)
    mainPad.PaddingLeft = UDim.new(0,6)
    mainPad.PaddingRight = UDim.new(0,6)
    mainPad.PaddingTop = UDim.new(0,4)
    mainPad.PaddingBottom = UDim.new(0,8)

    local TABS = {"Speed", "Combat", "Auto Steal", "Movement", "Visual", "Settings"}
    local tabPages = {}
    local currentPage = nil
    local lo = 0
    local function LO() lo = lo+1; return lo end

    local function makeGap(px) local f=Instance.new("Frame",currentPage); f.Size=UDim2.new(1,0,0,px or 4); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=LO() end
    local function makeSectionHeader(label)
        -- Section headers are removed as requested
    end

    local function makeInputRow(label, default, onChange)
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1,-14,0,36)
        row.BackgroundColor3 = Color3.fromRGB(0,0,5)
        row.BorderSizePixel=0
        row.LayoutOrder=LO()
        mkCorner(row,10)
        local rowStroke = mkStroke(row, BLUE_DIM,1)
        rowStroke.Transparency = 0.5
        row.MouseEnter:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,10,20)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,0,5)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.5}):Play()
        end)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-90,1,0)
        lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency=1
        lbl.Text=label
        lbl.TextColor3=BLUE_LIGHT
        lbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
        lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        local boxWrap = Instance.new("Frame", row)
        boxWrap.Size = UDim2.new(0,60,0,24)
        boxWrap.Position = UDim2.new(1,-72,0.5,-12)
        boxWrap.BackgroundColor3 = Color3.fromRGB(0,0,5)
        boxWrap.BorderSizePixel=0
        mkCorner(boxWrap,6)
        local bs = mkStroke(boxWrap, BLUE_DIM,1)
        bs.Transparency=0.3
        local box = Instance.new("TextBox", boxWrap)
        box.Size = UDim2.new(1,-6,1,0)
        box.Position = UDim2.new(0,3,0,0)
        box.BackgroundTransparency=1
        box.Text = tostring(default)
        box.TextColor3 = BLUE_LIGHT
        box.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
        box.TextSize=12
        box.ClearTextOnFocus=false
        box.ZIndex=8
        box.TextXAlignment=Enum.TextXAlignment.Center
        box.Focused:Connect(function()
            TweenService:Create(bs,TweenInfo.new(0.15),{Color=BLUE_MAIN,Transparency=0}):Play()
        end)
        box.FocusLost:Connect(function()
            TweenService:Create(bs,TweenInfo.new(0.15),{Color=BLUE_DIM,Transparency=0.3}):Play()
            if onChange then
                local n = tonumber(box.Text)
                if n then onChange(n); requestSave()
                else box.Text = tostring(default) end
            end
        end)
        return box,row
    end

    local function makeToggleRow(label, defaultOn, onToggle)
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1,-14,0,36)
        row.BackgroundColor3 = Color3.fromRGB(0,0,5)
        row.BorderSizePixel=0
        row.LayoutOrder=LO()
        mkCorner(row,10)
        local rowStroke = mkStroke(row, BLUE_DIM,1)
        rowStroke.Transparency = 0.5
        row.MouseEnter:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,10,20)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,0,5)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.5}):Play()
        end)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-60,1,0)
        lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency=1
        lbl.Text=label
        lbl.TextColor3=BLUE_LIGHT
        lbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
        lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        local pillBg = Instance.new("Frame", row)
        pillBg.Size = UDim2.new(0,38,0,18)
        pillBg.Position = UDim2.new(1,-50,0.5,-9)
        pillBg.BackgroundColor3 = defaultOn and BLUE_MAIN or Color3.fromRGB(0,10,20)
        pillBg.BorderSizePixel=0
        pillBg.ZIndex=7
        mkCorner(pillBg,9)
        local dot = Instance.new("Frame", pillBg)
        dot.Size = UDim2.new(0,13,0,13)
        dot.Position = defaultOn and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5)
        dot.BackgroundColor3 = defaultOn and Color3.fromRGB(0,0,5) or BLUE_DIM
        dot.BorderSizePixel=0
        dot.ZIndex=8
        mkCorner(dot,6.5)
        local isOn = defaultOn or false
        local function setV(on)
            isOn = on
            TweenService:Create(pillBg, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                BackgroundColor3 = on and BLUE_MAIN or Color3.fromRGB(0,10,20)
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
                Position = on and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5),
                BackgroundColor3 = on and Color3.fromRGB(0,0,5) or BLUE_DIM
            }):Play()
        end
        local function toggle()
            isOn = not isOn; setV(isOn)
            if onToggle then pcall(onToggle, isOn) end
            requestSave()
        end
        local clk = Instance.new("TextButton", row)
        clk.Size = UDim2.new(1,-56,1,0)
        clk.BackgroundTransparency=1
        clk.Text=""
        clk.ZIndex=5
        clk.BorderSizePixel=0
        clk.MouseButton1Click:Connect(toggle)
        local pClk = Instance.new("TextButton", pillBg)
        pClk.Size = UDim2.new(1,0,1,0)
        pClk.BackgroundTransparency=1
        pClk.Text=""
        pClk.ZIndex=9
        pClk.BorderSizePixel=0
        pClk.MouseButton1Click:Connect(toggle)
        return setV
    end

    local function getKeyDisplayName(kc)
        if kc == Enum.KeyCode.Unknown then return "None" end
        local n = kc.Name
        local gpNames = {ButtonA="A",ButtonB="B",ButtonX="X",ButtonY="Y",ButtonL1="LB",ButtonL2="LT",ButtonL3="LS",
            ButtonR1="RB",ButtonR2="RT",ButtonR3="RS",ButtonSelect="SEL",ButtonStart="STA",
            DPadUp="D↑",DPadDown="D↓",DPadLeft="D←",DPadRight="D→",Thumbstick1="LS",Thumbstick2="RS"}
        return gpNames[n] or n:sub(1,5)
    end

    local function refreshAllKeybindButtons()
        for keyName, btn in pairs(keybindBtnRefs) do
            if btn and Keys[keyName] then
                btn.Text = getKeyDisplayName(Keys[keyName])
            end
        end
    end

    local function makeKeybindRow(label, currentKey, onChanged, keyName)
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1,0,0,38)
        row.BackgroundTransparency=1
        row.BorderSizePixel=0
        row.LayoutOrder=LO()
        local div = Instance.new("Frame", row)
        div.Size = UDim2.new(1,-24,0,1)
        div.Position = UDim2.new(0,12,1,-1)
        div.BackgroundColor3 = BLUE_DIM
        div.BorderSizePixel=0
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-70,1,0)
        lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency=1
        lbl.Text=label
        lbl.TextColor3=BLUE_LIGHT
        lbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
        lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        local kbtn = Instance.new("TextButton", row)
        kbtn.Size = UDim2.new(0,46,0,22)
        kbtn.Position = UDim2.new(1,-58,0.5,-11)
        kbtn.BackgroundColor3 = BLUE_MAIN
        kbtn.BorderSizePixel=0
        kbtn.Text = getKeyDisplayName(currentKey)
        kbtn.TextColor3 = Color3.fromRGB(0,0,5)
        kbtn.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
        kbtn.TextSize=11
        kbtn.ZIndex=8
        mkCorner(kbtn,11)
        local ks = mkStroke(kbtn, BLUE_MAIN,1)
        local listening = false
        local lconnKeyboard,lconnGamepad
        local function stopL(key)
            listening = false
            if lconnKeyboard then lconnKeyboard:Disconnect(); lconnKeyboard=nil end
            if lconnGamepad then lconnGamepad:Disconnect(); lconnGamepad=nil end
            TweenService:Create(ks,TweenInfo.new(0.12),{Color=BLUE_MAIN}):Play()
            TweenService:Create(kbtn,TweenInfo.new(0.12),{BackgroundColor3=BLUE_MAIN}):Play()
            kbtn.TextColor3 = Color3.fromRGB(0,0,5)
            if key then
                kbtn.Text = getKeyDisplayName(key)
                if onChanged then onChanged(key) end
                pcall(requestSave)
            else
                kbtn.Text = getKeyDisplayName(Keys[keyName] or Enum.KeyCode.Unknown)
            end
        end
        kbtn.MouseButton1Click:Connect(function()
            if listening then stopL(nil); return end
            listening = true
            kbtn.Text = "···"
            kbtn.TextColor3 = Color3.fromRGB(10,10,20)
            TweenService:Create(kbtn,TweenInfo.new(0.12),{BackgroundColor3=BLUE_LIGHT}):Play()
            TweenService:Create(ks,TweenInfo.new(0.12),{Color=BLUE_LIGHT}):Play()
            lconnKeyboard = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then stopL(nil); return end
                stopL(inp.KeyCode)
            end)
            lconnGamepad = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Gamepad1 and inp.UserInputType ~= Enum.UserInputType.Gamepad2 and inp.UserInputType ~= Enum.UserInputType.Gamepad3 and inp.UserInputType ~= Enum.UserInputType.Gamepad4 then return end
                local kc = inp.KeyCode
                if kc == Enum.KeyCode.Unknown then return end
                stopL(kc)
            end)
        end)
        if keyName then keybindBtnRefs[keyName] = kbtn end
        return kbtn
    end

    -- ============================================================
    -- STEAL BAR WITH PING (BLUE THEME)
    -- ============================================================
    local stealBarFrame = Instance.new("Frame", gui)
    stealBarFrame.Name = "MoonHubStealBar"
    stealBarFrame.Size = UDim2.new(0, 250, 0, 32)
    stealBarFrame.Position = UDim2.new(0.5, -135, 0.92, 0)
    stealBarFrame.BackgroundColor3 = Color3.fromRGB(0,5,10)
    stealBarFrame.BackgroundTransparency = 0.04
    stealBarFrame.BorderSizePixel = 0
    stealBarFrame.ZIndex = 20
    stealBarFrame.ClipsDescendants = true
    stealBarFrame.Active = true
    mkCorner(stealBarFrame, 14)
    buildNeonBorder(stealBarFrame, 1.4, 30, 0.8)

    -- Progress fill
    progressFill = Instance.new("Frame", stealBarFrame)
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = BLUE_MAIN
    progressFill.BackgroundTransparency = 0.3
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 21
    mkCorner(progressFill, 14)

    -- Steal label (STEAL 0%)
    local stealLabel = Instance.new("TextLabel", stealBarFrame)
    stealLabel.Name = "StealLabel"
    stealLabel.ZIndex = 22
    stealLabel.Position = UDim2.new(0, 10, 0, 0)
    stealLabel.Size = UDim2.new(0, 75, 1, 0)
    stealLabel.BackgroundTransparency = 1
    stealLabel.Text = "STEAL 0%"
    stealLabel.TextColor3 = BLUE_LIGHT
    stealLabel.TextSize = 12
    stealLabel.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    stealLabel.TextStrokeTransparency = 0.45
    stealLabel.Parent = stealBarFrame
    percentLabel = stealLabel

    -- PING LABEL
    local pingLabel = Instance.new("TextLabel", stealBarFrame)
    pingLabel.Name = "PingLabel"
    pingLabel.ZIndex = 23
    pingLabel.Position = UDim2.new(1, -85, 0, 0)
    pingLabel.Size = UDim2.new(0, 80, 1, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: --ms"
    pingLabel.TextColor3 = BLUE_DIM
    pingLabel.TextSize = 10
    pingLabel.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    pingLabel.TextStrokeTransparency = 0.45
    pingLabel.TextXAlignment = Enum.TextXAlignment.Right
    pingLabel.Parent = stealBarFrame

    -- PING UPDATE LOOP
    task.spawn(function()
        while pingLabel and pingLabel.Parent do
            local success, ping = pcall(function()
                local network = Stats:FindFirstChild("Network")
                if network and network:FindFirstChild("ServerStatsItem") then
                    local dataPing = network.ServerStatsItem:FindFirstChild("Data Ping")
                    if dataPing then 
                        return math.floor(dataPing:GetValue())
                    end
                end
                return 0
            end)
            if success and ping then
                pingLabel.Text = "Ping: " .. tostring(ping) .. "ms"
            else
                pingLabel.Text = "Ping: --ms"
            end
            task.wait(0.5)
        end
    end)

    -- Steal bar click toggles auto steal
    local stealClickBtn = Instance.new("TextButton", stealBarFrame)
    stealClickBtn.Size = UDim2.new(1, -42, 1, 0)
    stealClickBtn.Position = UDim2.new(0, 0, 0, 0)
    stealClickBtn.BackgroundTransparency = 1
    stealClickBtn.Text = ""
    stealClickBtn.ZIndex = 24
    stealClickBtn.BorderSizePixel = 0

    stealClickBtn.MouseButton1Click:Connect(function()
        toggleAutoSteal()
    end)

    -- ============================================================
    -- STEAL BAR DRAG HANDLING
    -- ============================================================
    local dragging, dragStart, startPos = false, nil, nil
    local saveDebounce = nil

    stealBarFrame.InputBegan:Connect(function(inp)
        if State.uiLocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = stealBarFrame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.InputUserState.End then dragging = false end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if not dragging or State.uiLocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local dx = inp.Position.X - dragStart.X
            local dy = inp.Position.Y - dragStart.Y
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1000, 1000)
            local sz = stealBarFrame.AbsoluteSize
            
            local newXScalePx = startPos.X.Scale * vp.X
            local newX = math.clamp(newXScalePx + startPos.X.Offset + dx, sz.X / 2, vp.X - sz.X / 2)
            local newY = math.clamp(startPos.Y.Scale * vp.Y + startPos.Y.Offset + dy, 0, vp.Y - sz.Y)
            
            stealBarFrame.Position = UDim2.new(startPos.X.Scale, newX - newXScalePx, startPos.Y.Scale, newY - startPos.Y.Scale * vp.Y)
        end
    end)

    stealBarFrame.InputEnded:Connect(function()
        if dragging then
            dragging = false
            if saveDebounce then task.cancel(saveDebounce) end
            saveDebounce = task.delay(0.2, function()
                pcall(requestSave)
                saveDebounce = nil
            end)
        end
    end)

    -- ============================================================
    -- PERFORMANCE - STRETCH REZ
    -- ============================================================
    local STRETCH_NAME = "FadedVS_Stretch"
    local stretchRezEnabled = false

    local function enableStretchRez()
        stretchRezEnabled = true
        pcall(function() RunService:UnbindFromRenderStep(STRETCH_NAME) end)
        pcall(function()
            RunService:BindToRenderStep(STRETCH_NAME, Enum.RenderPriority.Last.Value - 1, function()
                local cam = workspace.CurrentCamera
                if cam then cam.CFrame = cam.CFrame * CFrame.new(0,0,0,1,0,0,0,0.7,0,0,0,1) end
            end)
        end)
    end

    local function disableStretchRez()
        stretchRezEnabled = false
        pcall(function() RunService:UnbindFromRenderStep(STRETCH_NAME) end)
    end

    -- ============================================================
    -- ESP + TRACERS (BLUE THEME)
    -- ============================================================
    local espEnabled = false
    local espObjects = {}
    local espConns = {}
    local camera = workspace.CurrentCamera
    local ACCENT_COLOR = BLUE_MAIN

    local function isTargetValid(plr)
        if plr == LP then return false end
        local char = plr.Character; if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return false end
        if hum.Health <= 0 then return false end
        if char:FindFirstChildOfClass("ForceField") then return false end
        return true
    end

    local function removeESP(plr)
        local data = espObjects[plr]
        if data then if data.Group then data.Group:Destroy() end; if data.Tracer then data.Tracer:Remove() end end
        espObjects[plr] = nil
    end

    local function createESP(plr)
        if not isTargetValid(plr) then return end
        if espObjects[plr] then return end
        local char = plr.Character
        local root = char:FindFirstChild("HumanoidRootPart"); local head = char:FindFirstChild("Head")
        if not root or not head then return end
        local group = Instance.new("Folder"); group.Name = "MoonESP"; group.Parent = char
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = root; box.Size = Vector3.new(4,6,2); box.Color3 = ACCENT_COLOR; box.Transparency = 0.7; box.ZIndex = 10; box.AlwaysOnTop = true; box.Parent = group
        local boxGlow = Instance.new("BoxHandleAdornment")
        boxGlow.Adornee = root; boxGlow.Size = Vector3.new(4.4,6.4,2.4); boxGlow.Color3 = ACCENT_COLOR; boxGlow.Transparency = 0.3; boxGlow.ZIndex = 9; boxGlow.AlwaysOnTop = true; boxGlow.Parent = group
        local bb = Instance.new("BillboardGui"); bb.Adornee = head; bb.Size = UDim2.new(0,200,0,45); bb.StudsOffset = Vector3.new(0,4.2,0); bb.AlwaysOnTop = true; bb.Parent = group
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.Text = plr.DisplayName; lbl.TextColor3 = ACCENT_COLOR; lbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json"); lbl.TextScaled = true; lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0); lbl.Parent = bb
        local healthBB = Instance.new("BillboardGui"); healthBB.Adornee = head; healthBB.Size = UDim2.new(0,50,0,6); healthBB.StudsOffset = Vector3.new(0,2.2,0); healthBB.AlwaysOnTop = true; healthBB.Parent = group
        local healthBg = Instance.new("Frame"); healthBg.Size = UDim2.new(1,0,1,0); healthBg.BackgroundColor3 = Color3.fromRGB(0,10,20); healthBg.BorderSizePixel = 0; healthBg.Parent = healthBB
        local healthFill = Instance.new("Frame"); healthFill.Size = UDim2.new(1,0,1,0); healthFill.BackgroundColor3 = BLUE_MAIN; healthFill.BorderSizePixel = 0; healthFill.Parent = healthBg
        local tracer = Drawing.new("Line"); tracer.Visible = true; tracer.Color = Color3.new(0, 150, 255); tracer.Thickness = 2; tracer.Transparency = 0.5; tracer.ZIndex = 5
        espObjects[plr] = {Group=group,Box=box,BoxGlow=boxGlow,NameTag=bb,HealthBar=healthBB,HealthFill=healthFill,Tracer=tracer,Root=root,Head=head,Player=plr}
    end

    local function updateESP()
        if not espEnabled then return end
        local localChar = LP.Character; if not localChar then return end
        local localRoot = localChar:FindFirstChild("HumanoidRootPart"); if not localRoot then return end
        local localPos, localVisible = camera:WorldToViewportPoint(localRoot.Position)
        for plr, data in pairs(espObjects) do
            if not isTargetValid(plr) then removeESP(plr)
            else
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and data.HealthFill then
                    local health = hum.Health / hum.MaxHealth
                    data.HealthFill.Size = UDim2.new(health, 0, 1, 0)
                    data.HealthFill.BackgroundColor3 = Color3.fromHSV(health * 0.3, 1, 0.6)
                end
                if data.Root and data.Tracer and localVisible then
                    local enemyPos, enemyVisible = camera:WorldToViewportPoint(data.Root.Position)
                    if enemyVisible then data.Tracer.From = Vector2.new(localPos.X, localPos.Y); data.Tracer.To = Vector2.new(enemyPos.X, enemyPos.Y); data.Tracer.Visible = true
                    else data.Tracer.Visible = false end
                end
            end
        end
    end

    local function enableESP()
        if espEnabled then return end
        espEnabled = true
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP then pcall(function() createESP(plr) end) end end
        for _, conn in ipairs(espConns) do if conn and conn.Connected then conn:Disconnect() end end
        espConns = {}
        table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
            if plr == LP then return end
            pcall(function() createESP(plr) end)
            plr.CharacterAdded:Connect(function()
                task.wait(0.1)
                if espEnabled then pcall(function() createESP(plr) end) end
            end)
        end))
        table.insert(espConns, Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end))
        table.insert(espConns, RunService.RenderStepped:Connect(function() if espEnabled then updateESP() end end))
        table.insert(espConns, LP.CharacterAdded:Connect(function()
            task.wait(0.3)
            if espEnabled then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP then pcall(function() createESP(plr) end) end
                end
            end
        end))
    end

    local function disableESP()
        espEnabled = false
        for plr in pairs(espObjects) do removeESP(plr) end
        espObjects = {}
        for _, conn in ipairs(espConns) do if conn and conn.Connected then conn:Disconnect() end end
        espConns = {}
    end

    -- ============================================================
    -- AUTO RESET ON MEDUSA
    -- ============================================================
    local autoResetMedusaEnabled = false
    local autoResetMedusaDebounce = false
    local autoResetMedusaConns = {}

    local function onAnchorChangedAutoReset(part)
        return part:GetPropertyChangedSignal("Anchored"):Connect(function()
            if not autoResetMedusaEnabled then return end
            if part.Anchored and part.Transparency == 1 then
                if autoResetMedusaDebounce then return end
                autoResetMedusaDebounce = true
                task.spawn(function() doInstantReset(); task.wait(3); autoResetMedusaDebounce = false end)
            end
        end)
    end

    local function setupAutoResetOnMedusa(char)
        for _, c in pairs(autoResetMedusaConns) do pcall(function() c:Disconnect() end) end
        autoResetMedusaConns = {}
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            table.insert(autoResetMedusaConns, hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
                if not autoResetMedusaEnabled then return end
                if hum.PlatformStand then
                    if autoResetMedusaDebounce then return end
                    autoResetMedusaDebounce = true
                    task.spawn(function() doInstantReset(); task.wait(3); autoResetMedusaDebounce = false end)
                end
            end))
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(autoResetMedusaConns, onAnchorChangedAutoReset(part)) end
        end
        table.insert(autoResetMedusaConns, char.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then table.insert(autoResetMedusaConns, onAnchorChangedAutoReset(part)) end
        end))
    end

    local function stopAutoResetOnMedusa()
        for _, c in pairs(autoResetMedusaConns) do pcall(function() c:Disconnect() end) end
        autoResetMedusaConns = {}
    end

    LP.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if autoResetMedusaEnabled then setupAutoResetOnMedusa(char) end
    end)

    -- ============================================================
    -- OTHER PLAYERS SPEED - ALWAYS ON (BLUE THEME)
    -- ============================================================
    local function setupOtherPlayerSpeed(player)
        if player == LP then return end
        local function onCharacterAdded(char)
            task.wait(0.2)
            local head = char:FindFirstChild("Head")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not head or not hrp then return end
            local oldBB = head:FindFirstChild("MoonHubBB_Other")
            if oldBB then oldBB:Destroy() end
            local bb = Instance.new("BillboardGui", head)
            bb.Name = "MoonHubBB_Other"
            bb.Size = UDim2.new(0, 140, 0, 20)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            local speedLbl = Instance.new("TextLabel", bb)
            speedLbl.Name = "SpeedBillLbl"
            speedLbl.Size = UDim2.new(1, 0, 1, 0)
            speedLbl.Position = UDim2.new(0, 0, 0, 0)
            speedLbl.BackgroundTransparency = 1
            speedLbl.Text = "0.0"
            speedLbl.TextColor3 = BLUE_LIGHT
            speedLbl.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
            speedLbl.TextScaled = true
            speedLbl.TextStrokeTransparency = 0
            speedLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            task.spawn(function()
                while char and char.Parent and hrp and hrp.Parent and speedLbl and speedLbl.Parent do
                    pcall(function()
                        local hspd = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
                        speedLbl.Text = string.format("%.1f", hspd)
                    end)
                    task.wait(0.1)
                end
            end)
        end
        if player.Character then task.spawn(function() onCharacterAdded(player.Character) end) end
        player.CharacterAdded:Connect(onCharacterAdded)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then task.spawn(function() setupOtherPlayerSpeed(player) end) end
    end
    Players.PlayerAdded:Connect(function(player)
        task.spawn(function() setupOtherPlayerSpeed(player) end)
    end)

    -- ============================================================
    -- BUILD PAGES
    -- ============================================================
    local function buildPage(tabName, buildFn)
        local page = Instance.new("Frame", mainScroll)
        page.Name = tabName
        page.Size = UDim2.new(1,0,0,0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.LayoutOrder = 0
        local ll = Instance.new("UIListLayout", page)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Padding = UDim.new(0,3)
        ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabPages[tabName] = page
        currentPage = page
        lo = 0
        buildFn()
        currentPage = nil
        return page
    end

    -- Speed Page
    do
        local page = buildPage("Speed", function()
            makeGap(2)
            normalBox = makeInputRow("Normal Speed", State.normalSpeed, function(n) if n>0 and n<=500 then State.normalSpeed=n end end)
            carryBox = makeInputRow("Carry Speed", State.carrySpeed, function(n) if n>0 and n<=500 then State.carrySpeed=n end end)
            laggerBox = makeInputRow("Lagger Speed", State.laggerSpeed, function(n) if n>0 and n<=500 then State.laggerSpeed=n end end)
            laggerCarryBox = makeInputRow("Lagger Carry Speed", State.laggerCarrySpeed, function(n) if n>0 and n<=500 then State.laggerCarrySpeed=n end end)
            makeGap(6)
            makeKeybindRow("Speed Key (toggles)", Keys.speed, function(k) Keys.speed=k end, "speed")
            makeKeybindRow("Lagger Speed Key", Keys.lagger, function(k) Keys.lagger=k end, "lagger")
            makeKeybindRow("Lagger Carry Key", Keys.laggerCarry, function(k) Keys.laggerCarry=k end, "laggerCarry")
        end)
        page.LayoutOrder = 1
    end

    -- Combat Page
    do
        local page = buildPage("Combat", function()
            makeGap(2)
            
            aimbotSpeedBox = makeInputRow("Aimbot Speed", AimbotConfig.CHASE_SPEED, function(n)
                if n >= 10 and n <= 300 then 
                    AimbotConfig.CHASE_SPEED = n
                    requestSave()
                end 
            end)
            
            aimbotFollowDistBox = makeInputRow("Follow Distance", AimbotConfig.FOLLOW_DIST, function(n)
                if n >= -20 and n <= 20 then 
                    AimbotConfig.FOLLOW_DIST = n
                    requestSave()
                end 
            end)
            
            setAutoSwing = makeToggleRow("Auto Swing", false, function(on) State.autoSwingEnabled=on end)
            toggleSetters["autoSwing"] = setAutoSwing
            setBatCounter = makeToggleRow("Bat Counter", false, function(on) State.batCounterEnabled=on; if on then startBatCounter() else stopBatCounter() end end)
            toggleSetters["batCounter"] = setBatCounter
            setMedusaCounter = makeToggleRow("Medusa Counter", false, function(on) State.medusaCounterEnabled=on; if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end)
            toggleSetters["medusaCounter"] = setMedusaCounter
            
            local batV2Setter = makeToggleRow("Bat V2 (Sakura)", State.batV2Enabled, function(on)
                toggleBatV2(on)
                requestSave()
            end)
            toggleSetters["batV2"] = batV2Setter
            
            makeKeybindRow("Aimbot Key", Keys.aimbot, function(k) Keys.aimbot=k end, "aimbot")
            makeKeybindRow("Bat V2 Key", Keys.batV2, function(k) Keys.batV2=k end, "batV2")

            makeGap(6)
            local autoResetMedSetter = makeToggleRow("Auto Reset Medusa", false, function(on)
                autoResetMedusaEnabled = on
                State.autoResetMedusaEnabled = on
                if on then setupAutoResetOnMedusa(LP.Character) else stopAutoResetOnMedusa() end
                requestSave()
            end)
            toggleSetters["autoResetMedusa"] = autoResetMedSetter
        end)
        page.LayoutOrder = 2
    end

    -- Auto Steal Page
    do
        local page = buildPage("Auto Steal", function()
            makeGap(2)
            local stealToggle = makeToggleRow("Auto Steal", Steal.AutoStealEnabled, function(on) 
                Steal.AutoStealEnabled = on
                if on then 
                    startAutoSteal() 
                else 
                    stopAutoSteal()
                end 
                requestSave()
            end)
            toggleSetters["autoSteal"] = stealToggle
            
            makeGap(4)
            stealRadBox = makeInputRow("Steal Radius", Steal.StealRadius, function(n) 
                if n then 
                    n = math.floor(n)
                    if n >= 1 and n <= 500 then 
                        Steal.StealRadius = n
                        requestSave()
                    end 
                end 
            end)
            local durBox,_ = makeInputRow("Steal Duration", Steal.StealDuration, function(n) 
                if n then 
                    n = math.min(n, 10)
                    if n >= 0.05 then 
                        Steal.StealDuration = n
                        requestSave()
                    end 
                end 
            end)
            stealDurBox = durBox
        end)
        page.LayoutOrder = 3
    end

    -- Movement Page
    do
        local page = buildPage("Movement", function()
            makeGap(2)
            setInfJump = makeToggleRow("Infinite Jump", true, function(on) State.infJumpEnabled=on end)
            toggleSetters["infJump"] = setInfJump
            makeGap(6)
            setAntiRag = makeToggleRow("Anti Ragdoll", false, function(on) State.antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
            toggleSetters["antiRagdoll"] = setAntiRag
            makeGap(6)
            makeKeybindRow("Auto Left", Keys.autoLeft, function(k) Keys.autoLeft=k end, "autoLeft")
            makeKeybindRow("Auto Right", Keys.autoRight, function(k) Keys.autoRight=k end, "autoRight")
            makeKeybindRow("Drop Key", Keys.drop, function(k) Keys.drop=k end, "drop")
            makeKeybindRow("TP Down", Keys.tpDown, function(k) Keys.tpDown=k end, "tpDown")
            makeKeybindRow("TP Bat", Keys.tpBat, function(k) Keys.tpBat=k end, "tpBat")
            makeKeybindRow("Reset", Keys.reset, function(k) Keys.reset=k end, "reset")
            makeGap(6)
            local autoTPToggle = makeToggleRow("Auto TP", State.autoTPEnabled, function(on)
                State.autoTPEnabled = on
                if on then startAutoTP() else stopAutoTP() end
                requestSave()
            end)
            toggleSetters["autoTP"] = autoTPToggle
            autoTPHeightBox = makeInputRow("Auto TP Height", State.autoTPHeight, function(n)
                if n and n >= 2 and n <= 500 then State.autoTPHeight = n end
            end)
        end)
        page.LayoutOrder = 4
    end

    -- Visual Page
    do
        local page = buildPage("Visual", function()
            makeGap(2)
            
            fpsBoostSetter = makeToggleRow("FPS Boost", State.fpsBoostEnabled, function(on)
                State.fpsBoostEnabled = on
                if on then 
                    pcall(applyFPSBoost) 
                else 
                    pcall(disableFPSBoost) 
                end
                requestSave()
            end)
            toggleSetters["fpsBoost"] = fpsBoostSetter
            
            local stretchSetter = makeToggleRow("Stretch Rez", State.stretchedResEnabled, function(on) 
                State.stretchedResEnabled=on
                if on then enableStretchRez() else disableStretchRez() end 
            end)
            toggleSetters["stretchedRes"] = stretchSetter

            makeGap(6)
            
            local espSetter = makeToggleRow("ESP + Tracers", State.espEnabled, function(on)
                State.espEnabled = on
                if on then enableESP() else disableESP() end
                requestSave()
            end)
            toggleSetters["esp"] = espSetter

            makeGap(6)
            
            tryardSetter = makeToggleRow("Tryard Pack", State.tryardAnimEnabled, function(on)
                State.tryardAnimEnabled=on
                if on then startTryardAnim() else stopTryardAnim() end
            end)
            toggleSetters["tryardAnim"] = tryardSetter
            
            _G._VezyFOV = _G._VezyFOV or 70
            makeInputRow("Normal FOV", _G._VezyFOV, function(n)
                if n>=70 and n<=180 then
                    _G._VezyFOV=n
                    local cam=workspace.CurrentCamera
                    if cam and not State.stretchedResEnabled then
                        pcall(function() cam.FieldOfView=n end)
                    end
                end
            end)
        end)
        page.LayoutOrder = 5
    end

    -- Settings Page
    do
        local page = buildPage("Settings", function()
            makeGap(2)
            makeKeybindRow("Hide GUI", Keys.guiHide, function(k) Keys.guiHide=k end, "guiHide")
            uiScaleBox = makeInputRow("UI Scale", 1.0, function(n) if n>=0.5 and n<=2.0 then if uiScaleObj then uiScaleObj.Scale=n end end end)
            hideButtonsSetter = makeToggleRow("Hide Buttons", false, function(on) 
                State.stackButtonsHidden=on
                State.stackButtonsHidden = on
                for _,wrapper in pairs(stackWrappers) do 
                    if wrapper then wrapper.Visible = not on end 
                end
            end)
            toggleSetters["hideButtons"] = hideButtonsSetter
            lockButtonsSetter = makeToggleRow("Lock Buttons", false, function(on) 
                State.stackButtonsLocked=on
                State.uiLocked = on
            end)
            toggleSetters["lockButtons"] = lockButtonsSetter
            introSetter = makeToggleRow("Show Intro", State.introEnabled, function(on) State.introEnabled=on; requestSave() end)
            toggleSetters["introEnabled"] = introSetter

            makeGap(6)
            
            local saveWrap = Instance.new("Frame", currentPage)
            saveWrap.Size = UDim2.new(1,0,0,40)
            saveWrap.BackgroundTransparency=1
            saveWrap.BorderSizePixel=0
            saveWrap.LayoutOrder=LO()
            local saveBtn = Instance.new("TextButton", saveWrap)
            saveBtn.Size = UDim2.new(1,-24,0,28)
            saveBtn.Position = UDim2.new(0,12,0,6)
            saveBtn.BackgroundColor3=BLUE_MAIN
            saveBtn.BorderSizePixel=0
            saveBtn.Text="💾 Save Config"
            saveBtn.TextColor3=Color3.fromRGB(0,0,5)
            saveBtn.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            saveBtn.TextSize=12
            saveBtn.ZIndex=5
            mkCorner(saveBtn,5)
            buildNeonBorder(saveBtn, 1, 30, 0.8)
            saveBtn.MouseEnter:Connect(function()
                TweenService:Create(saveBtn,TweenInfo.new(0.1),{BackgroundColor3=BLUE_LIGHT}):Play()
            end)
            saveBtn.MouseLeave:Connect(function()
                TweenService:Create(saveBtn,TweenInfo.new(0.1),{BackgroundColor3=BLUE_MAIN}):Play()
            end)
            saveBtn.MouseButton1Click:Connect(function()
                local success = pcall(saveConfig)
                if success then
                    saveBtn.Text="✓ Saved!"
                    saveBtn.BackgroundColor3=BLUE_LIGHT
                else
                    saveBtn.Text="✗ Failed"
                    saveBtn.BackgroundColor3=Color3.fromRGB(40,0,0)
                end
                task.delay(2.5,function()
                    if saveBtn and saveBtn.Parent then
                        saveBtn.Text="💾 Save Config"
                        saveBtn.BackgroundColor3=BLUE_MAIN
                    end
                end)
            end)
            
            local resetWrap = Instance.new("Frame", currentPage)
            resetWrap.Size = UDim2.new(1,0,0,40)
            resetWrap.BackgroundTransparency=1
            resetWrap.BorderSizePixel=0
            resetWrap.LayoutOrder=LO()
            local resetAllBtn = Instance.new("TextButton", resetWrap)
            resetAllBtn.Size = UDim2.new(1,-24,0,28)
            resetAllBtn.Position = UDim2.new(0,12,0,6)
            resetAllBtn.BackgroundColor3=Color3.fromRGB(40,0,0)
            resetAllBtn.BorderSizePixel=0
            resetAllBtn.Text="⚠ Reset All"
            resetAllBtn.TextColor3=BLUE_LIGHT
            resetAllBtn.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            resetAllBtn.TextSize=12
            resetAllBtn.ZIndex=5
            mkCorner(resetAllBtn,5)
            mkStroke(resetAllBtn, Color3.fromRGB(255,0,0),1)
            resetAllBtn.MouseEnter:Connect(function()
                TweenService:Create(resetAllBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(60,0,0)}):Play()
            end)
            resetAllBtn.MouseLeave:Connect(function()
                TweenService:Create(resetAllBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(40,0,0)}):Play()
            end)
            local _resetConfirmStage=0
            local _resetConfirmTimer=nil
            resetAllBtn.MouseButton1Click:Connect(function()
                if _resetConfirmStage==0 then
                    _resetConfirmStage=1
                    resetAllBtn.Text="⚠ Confirm!"
                    resetAllBtn.BackgroundColor3=Color3.fromRGB(80,0,0)
                    if _resetConfirmTimer then task.cancel(_resetConfirmTimer) end
                    _resetConfirmTimer = task.delay(3,function()
                        if resetAllBtn and resetAllBtn.Parent then
                            _resetConfirmStage=0
                            resetAllBtn.Text="⚠ Reset All"
                            resetAllBtn.BackgroundColor3=Color3.fromRGB(40,0,0)
                        end
                    end)
                    return
                end
                _resetConfirmStage=0
                if _resetConfirmTimer then task.cancel(_resetConfirmTimer); _resetConfirmTimer=nil end
                pcall(function() if State.batAimbotToggled then stopAutoBatLoop() end end)
                pcall(function() if State.batCounterEnabled then stopBatCounter() end end)
                pcall(function() if State.medusaCounterEnabled then stopMedusaCounter() end end)
                pcall(function() if State.antiRagdollEnabled then stopAntiRagdoll() end end)
                pcall(function() if Steal.AutoStealEnabled then stopAutoSteal() end end)
                pcall(function() if State.autoLeftEnabled then stopAutoLeft() end end)
                pcall(function() if State.autoRightEnabled then stopAutoRight() end end)
                pcall(function() if State.stretchedResEnabled then disableStretchRez() end end)
                pcall(function() if State.autoTPEnabled then stopAutoTP() end end)
                pcall(function() if State.fpsBoostEnabled then disableFPSBoost() end end)
                pcall(function() if State.batV2Enabled then toggleBatV2(false) end end)
                pcall(function() if State.tpBatActive then 
                    State.tpBatActive = false
                    if Conns.tpBat then
                        Conns.tpBat:Disconnect()
                        Conns.tpBat = nil
                    end
                    if stackBtnRefs.tpBat then stackBtnRefs.tpBat.setOn(false) end
                end end)
                pcall(function() if State.espEnabled then disableESP() end end)
                pcall(function() if autoResetMedusaEnabled then stopAutoResetOnMedusa(); autoResetMedusaEnabled=false end end)
                pcall(function()
                    Lighting.Ambient = Color3.fromRGB(127,127,127)
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                end)
                State.normalSpeed=60
                State.carrySpeed=30
                State.laggerSpeed=10.1
                State.laggerCarrySpeed=15
                State.speedToggled=false
                State.laggerMode=0
                State.infJumpEnabled=true
                State.antiRagdollEnabled=false
                State.stretchedResEnabled=false
                State.stretchFOV=120
                State.medusaCounterEnabled=false
                State.batCounterEnabled=false
                State.batAimbotToggled=false
                State.autoSwingEnabled=false
                State.autoLeftEnabled=false
                State.autoRightEnabled=false
                State.stackButtonsHidden=false
                State.stackButtonsLocked=false
                State.uiLocked=false
                State.introEnabled=true
                State.autoTPEnabled=false
                State.autoTPHeight=50
                State.fpsBoostEnabled=false
                State.batV2Enabled=false
                State.tpBatActive=false
                State.espEnabled=false
                State.autoResetMedusaEnabled=false
                AimbotConfig.CHASE_SPEED=58
                AimbotConfig.FOLLOW_DIST=-2
                Steal.StealRadius=55
                Steal.StealDuration=0.25
                Steal.AutoStealEnabled=true
                Keys.speed=Enum.KeyCode.Q
                Keys.guiHide=Enum.KeyCode.LeftControl
                Keys.autoLeft=Enum.KeyCode.L
                Keys.autoRight=Enum.KeyCode.R
                Keys.lagger=Enum.KeyCode.Unknown
                Keys.laggerCarry=Enum.KeyCode.Unknown
                Keys.tpDown=Enum.KeyCode.Unknown
                Keys.drop=Enum.KeyCode.H
                Keys.aimbot=Enum.KeyCode.Unknown
                Keys.tpBat=Enum.KeyCode.Unknown
                Keys.reset=Enum.KeyCode.R
                Keys.batV2=Enum.KeyCode.V
                if normalBox then normalBox.Text=tostring(State.normalSpeed) end
                if carryBox then carryBox.Text=tostring(State.carrySpeed) end
                if laggerBox then laggerBox.Text=tostring(State.laggerSpeed) end
                if laggerCarryBox then laggerCarryBox.Text=tostring(State.laggerCarrySpeed) end
                if stealRadBox then stealRadBox.Text=tostring(Steal.StealRadius) end
                if stealDurBox then stealDurBox.Text=tostring(Steal.StealDuration) end
                if uiScaleObj then uiScaleObj.Scale=1.0 end
                if uiScaleBox then uiScaleBox.Text="1" end
                if aimbotSpeedBox then aimbotSpeedBox.Text=tostring(AimbotConfig.CHASE_SPEED) end
                if aimbotFollowDistBox then aimbotFollowDistBox.Text=tostring(AimbotConfig.FOLLOW_DIST) end
                if setInfJump then pcall(setInfJump,true) end
                if setAntiRag then pcall(setAntiRag,false) end
                if setMedusaCounter then pcall(setMedusaCounter,false) end
                if setBatCounter then pcall(setBatCounter,false) end
                if setAutoSwing then pcall(setAutoSwing,false) end
                if hideButtonsSetter then pcall(hideButtonsSetter,false) end
                if lockButtonsSetter then pcall(lockButtonsSetter,false) end
                if introSetter then pcall(introSetter,true) end
                if fpsBoostSetter then pcall(fpsBoostSetter,false) end
                if autoResetMedSetter then pcall(autoResetMedSetter,false) end
                if espSetter then pcall(espSetter,false) end
                if toggleSetters["autoSteal"] then pcall(toggleSetters["autoSteal"], true) end
                if stackBtnRefs then
                    for key,ref in pairs(stackBtnRefs) do
                        if ref and ref.setOn then pcall(ref.setOn,false) end
                    end
                end
                if keybindBtnRefs then refreshAllKeybindButtons() end
                for i,def in ipairs(stackDefs) do
                    local wrapper=stackWrappers[def.key]
                    if wrapper then
                        TweenService:Create(wrapper,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=getDefaultStackPos(i)}):Play()
                    end
                end
                resetAllBtn.Text="✓ Reset!"
                resetAllBtn.BackgroundColor3=BLUE_LIGHT
                task.delay(2,function()
                    if resetAllBtn and resetAllBtn.Parent then
                        resetAllBtn.Text="⚠ Reset All"
                        resetAllBtn.BackgroundColor3=Color3.fromRGB(40,0,0)
                    end
                end)
            end)
            
            makeGap(6)
            local rWrap = Instance.new("Frame", currentPage)
            rWrap.Size = UDim2.new(1,0,0,40)
            rWrap.BackgroundTransparency=1
            rWrap.BorderSizePixel=0
            rWrap.LayoutOrder=LO()
            local resetBtn = Instance.new("TextButton", rWrap)
            resetBtn.Size = UDim2.new(1,-24,0,28)
            resetBtn.Position = UDim2.new(0,12,0,6)
            resetBtn.BackgroundColor3=C.btnBg
            resetBtn.BorderSizePixel=0
            resetBtn.Text="↺ Reset Positions"
            resetBtn.TextColor3=BLUE_LIGHT
            resetBtn.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            resetBtn.TextSize=12
            resetBtn.ZIndex=5
            mkCorner(resetBtn,5)
            mkStroke(resetBtn, BLUE_DIM,1)
            resetBtn.MouseEnter:Connect(function()
                TweenService:Create(resetBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,10,20)}):Play()
            end)
            resetBtn.MouseLeave:Connect(function()
                TweenService:Create(resetBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnBg}):Play()
            end)
            resetBtn.MouseButton1Click:Connect(function()
                for i,def in ipairs(stackDefs) do
                    local wrapper=stackWrappers[def.key]
                    if wrapper then
                        TweenService:Create(wrapper,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=getDefaultStackPos(i)}):Play()
                    end
                end
                resetBtn.Text="✓ Reset!"
                task.delay(1.8,function()
                    if resetBtn and resetBtn.Parent then resetBtn.Text="↺ Reset Positions" end
                end)
            end)
            
            makeGap(8)
            local fw = Instance.new("Frame", currentPage)
            fw.Size = UDim2.new(1,0,0,18)
            fw.BackgroundTransparency=1
            fw.BorderSizePixel=0
            fw.LayoutOrder=LO()
            local fl = Instance.new("TextLabel", fw)
            fl.Size = UDim2.new(1,0,1,0)
            fl.BackgroundTransparency=1
            fl.Text="Moon Hub  ·  🌙"
            fl.TextColor3=BLUE_DIM
            fl.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            fl.TextSize=10
            fl.TextXAlignment=Enum.TextXAlignment.Center
            _G._VezySaveStatusLbl = fl
            _G._VezyFlashSave = function(success)
                if not _G._VezySaveStatusLbl or not _G._VezySaveStatusLbl.Parent then return end
                local lbl = _G._VezySaveStatusLbl
                if success then
                    lbl.Text="✓ Auto-saved"
                    lbl.TextColor3=BLUE_LIGHT
                else
                    lbl.Text="✗ Save failed"
                    lbl.TextColor3=Color3.fromRGB(255,0,0)
                end
                task.delay(1.5,function()
                    if lbl and lbl.Parent then
                        lbl.Text="Moon Hub  ·  🌙"
                        lbl.TextColor3=BLUE_DIM
                    end
                end)
            end
        end)
        page.LayoutOrder = 6
    end

    rebuildPresetList = function()
        if not presetListFrame then return end
        for _,child in ipairs(presetListFrame:GetChildren()) do
            if child.Name~="EmptyLabel" and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
        local emptyLbl = presetListFrame:FindFirstChild("EmptyLabel")
        if emptyLbl then emptyLbl.Visible = (#Presets == 0) end
        for i,preset in ipairs(Presets) do
            local row = Instance.new("Frame", presetListFrame)
            row.Name="Preset_"..i
            row.Size=UDim2.new(1,0,0,30)
            row.BackgroundColor3=C.presetBg
            row.BorderSizePixel=0
            row.LayoutOrder=i+1
            mkCorner(row,5)
            mkStroke(row, C.presetBrd,1)
            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size=UDim2.new(1,-90,1,0)
            nameLbl.Position=UDim2.new(0,8,0,0)
            nameLbl.BackgroundTransparency=1
            nameLbl.Text=preset.name
            nameLbl.TextColor3=BLUE_LIGHT
            nameLbl.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            nameLbl.TextSize=12
            nameLbl.TextXAlignment=Enum.TextXAlignment.Left
            nameLbl.TextTruncate=Enum.TextTruncate.AtEnd
            local loadBtn = Instance.new("TextButton", row)
            loadBtn.Size=UDim2.new(0,38,0,22)
            loadBtn.Position=UDim2.new(1,-84,0.5,-11)
            loadBtn.BackgroundColor3=C.presetLoad
            loadBtn.BorderSizePixel=0
            loadBtn.Text="Load"
            loadBtn.TextColor3=Color3.fromRGB(0,0,5)
            loadBtn.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            loadBtn.TextSize=11
            loadBtn.ZIndex=9
            mkCorner(loadBtn,4)
            loadBtn.MouseEnter:Connect(function()
                TweenService:Create(loadBtn,TweenInfo.new(0.1),{BackgroundColor3=BLUE_LIGHT}):Play()
            end)
            loadBtn.MouseLeave:Connect(function()
                TweenService:Create(loadBtn,TweenInfo.new(0.1),{BackgroundColor3=C.presetLoad}):Play()
            end)
            loadBtn.MouseButton1Click:Connect(function()
                saveLastPresetName(preset.name)
                loadBtn.Text="✓"
                task.delay(1.2,function()
                    if loadBtn and loadBtn.Parent then loadBtn.Text="Load" end
                end)
            end)
            local delBtn = Instance.new("TextButton", row)
            delBtn.Size=UDim2.new(0,28,0,22)
            delBtn.Position=UDim2.new(1,-40,0.5,-11)
            delBtn.BackgroundColor3=C.presetDel
            delBtn.BorderSizePixel=0
            delBtn.Text="✕"
            delBtn.TextColor3=Color3.fromRGB(255,0,0)
            delBtn.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            delBtn.TextSize=11
            delBtn.ZIndex=9
            mkCorner(delBtn,4)
            delBtn.MouseEnter:Connect(function()
                TweenService:Create(delBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(60,0,0)}):Play()
            end)
            delBtn.MouseLeave:Connect(function()
                TweenService:Create(delBtn,TweenInfo.new(0.1),{BackgroundColor3=C.presetDel}):Play()
            end)
            delBtn.MouseButton1Click:Connect(function()
                table.remove(Presets,i)
                savePresetsFile()
                rebuildPresetList()
            end)
        end
    end

    -- ============================================================
    -- BUTTONS (BLUE THEME)
    -- ============================================================
    for i,def in ipairs(stackDefs) do
        local btnFrame = Instance.new("TextButton", gui)
        btnFrame.Name = "StackBtn_"..def.key
        btnFrame.Size = UDim2.new(0, BTN_W, 0, BTN_H)
        btnFrame.Position = getDefaultStackPos(i)
        btnFrame.BackgroundColor3 = C.stackBg
        btnFrame.BorderSizePixel = 0
        btnFrame.AutoButtonColor = false
        btnFrame.Text = def.label
        btnFrame.TextColor3 = BLUE_LIGHT
        btnFrame.TextScaled = false
        btnFrame.TextSize = 11
        btnFrame.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
        btnFrame.TextWrapped = true
        btnFrame.LineHeight = 1.2
        btnFrame.ZIndex = 15
        mkCorner(btnFrame, 12)
        local bStroke = buildNeonBorder(btnFrame, 2, 35, 0.8)
        bStroke.Color = C.stackBrd
        stackWrappers[def.key] = btnFrame

        local btnState = false
        local function setOn(on)
            btnState = on
            TweenService:Create(btnFrame, TweenInfo.new(0.08), {
                BackgroundColor3 = on and C.stackActBg or C.stackBg,
                TextColor3 = on and Color3.fromRGB(0,0,5) or BLUE_LIGHT
            }):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.08), {
                Color = on and C.stackActBrd or C.stackBrd
            }):Play()
        end
        stackBtnRefs[def.key] = {setOn = setOn}

        local function onTap()
            if def.key == "tpDown" then
                task.spawn(function()
                    if runTPDown then pcall(runTPDown) end
                    setOn(true)
                    task.wait(0.12)
                    setOn(false)
                end)
                return
            end
            if def.key == "drop" then
                task.spawn(function() pcall(runDrop) end)
                return
            end
            if def.key == "tpBat" then
                toggleTPBat()
                return
            end
            if def.key == "reset" then
                setOn(true)
                task.spawn(function()
                    doInstantReset()
                    task.wait(0.12)
                    setOn(false)
                end)
                return
            end
            if def.key == "batV2" then
                local ns = not State.batV2Enabled
                toggleBatV2(ns)
                return
            end
            if def.key == "carrySpeed" then
                toggleSpeed()
                return
            end
            if def.key == "lagger" then
                toggleLaggerMode()
                return
            end
            if def.key == "laggerCarry" then
                toggleLaggerCarryMode()
                return
            end
            if def.key == "aimbot" then
                toggleAimbot()
                return
            end
            local ns = not btnState
            setOn(ns)
            if def.key == "autoLeft" then
                State.autoLeftEnabled = ns
                if ns and State.batAimbotToggled then
                    State.batAimbotToggled = false
                    stopAutoBatLoop()
                    if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end
                end
                if ns then startAutoLeft() else stopAutoLeft() end
            elseif def.key == "autoRight" then
                State.autoRightEnabled = ns
                if ns and State.batAimbotToggled then
                    State.batAimbotToggled = false
                    stopAutoBatLoop()
                    if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end
                end
                if ns then startAutoRight() else stopAutoRight() end
            end
            requestSave()
        end

        makeStackDraggable(btnFrame, onTap)
    end

    -- ============================================================
    -- HELPER FUNCTIONS
    -- ============================================================

    local _aimbotTarget=nil
    local function findBat()
        local char=LP.Character
        if not char then return nil end
        for _,tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
                return tool
            end
        end
        local bp=LP:FindFirstChild("Backpack")
        if bp then
            for _,tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
                    return tool
                end
            end
        end
        return nil
    end

    local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
    
    local function getBatCounter()
        local char=LP.Character
        if not char then return nil end
        local bp=LP:FindFirstChildOfClass("Backpack")
        for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
            local t=char:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
            if t then return t end
        end
        for _,ch in ipairs(char:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
        if bp then
            for _,ch in ipairs(bp:GetChildren()) do
                if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
            end
        end
        return nil
    end
    local function swingBatForCounter(bat,char)
        local hum2=char:FindFirstChildOfClass("Humanoid")
        if bat.Parent~=char then
            if hum2 then pcall(function() hum2:EquipTool(bat) end) end
            task.wait(0.05)
        end
        local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
        if remote and remote:IsA("RemoteEvent") then
            pcall(function() remote:FireServer() end)
            task.wait(0.15)
            pcall(function() remote:FireServer() end)
        else
            pcall(function() bat:Activate() end)
            task.wait(0.15)
            pcall(function() bat:Activate() end)
        end
    end
    startBatCounter = function()
        if Conns.batCounter then return end
        Conns.batCounter = RunService.Heartbeat:Connect(function()
            if not State.batCounterEnabled or State.batCounterDebounce then return end
            local char=LP.Character
            if not char then return end
            local hum2=char:FindFirstChildOfClass("Humanoid")
            if not hum2 then return end
            local st=hum2:GetState()
            local isRagdolled = st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
            if isRagdolled then
                State.batCounterDebounce=true
                task.spawn(function()
                    local bat=getBatCounter()
                    if bat then swingBatForCounter(bat,char) end
                    task.wait(0.5)
                    State.batCounterDebounce=false
                end)
            end
        end)
    end
    stopBatCounter = function()
        if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end
        State.batCounterDebounce=false
    end

    local MEDUSA_COOLDOWN=0.5
    local function findMedusa()
        local c=LP.Character
        if not c then return nil end
        for _,t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n=t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then return t end
            end
        end
        local bp=LP:FindFirstChildOfClass("Backpack")
        if bp then
            for _,t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then
                    local n=t.Name:lower()
                    if n:find("medusa") or n:find("head") or n:find("stone") then return t end
                end
            end
        end
        return nil
    end
    local function useMedusaCounter()
        if State.medusaDebounce then return end
        if tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
        local c=LP.Character
        if not c then return end
        State.medusaDebounce=true
        local med=findMedusa()
        if not med then
            State.medusaDebounce=false
            return
        end
        if med.Parent~=c then
            local hum2=c:FindFirstChildOfClass("Humanoid")
            if hum2 then hum2:EquipTool(med) end
        end
        pcall(function() med:Activate() end)
        State.medusaLastUsed=tick()
        State.medusaDebounce=false
    end
    local function onAnchorChanged(part)
        return part:GetPropertyChangedSignal("Anchored"):Connect(function()
            if part.Anchored and part.Transparency==1 then useMedusaCounter() end
        end)
    end
    setupMedusaCounter = function(char)
        stopMedusaCounter()
        if not char then return end
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(Conns.anchor,onAnchorChanged(part))
            end
        end
        table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                table.insert(Conns.anchor,onAnchorChanged(part))
            end
        end))
    end
    stopMedusaCounter = function()
        for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end
        Conns.anchor={}
    end

    startAntiRagdoll = function()
        if Conns.antiRag then return end
        Conns.antiRag = RunService.Heartbeat:Connect(function()
            if not State.antiRagdollEnabled then return end
            local char = LP.Character
            if not char then return end
            local hum2 = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum2 or not root then return end
            
            local st = hum2:GetState()
            local isRag = st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
            
            local et = LP:GetAttribute("RagdollEndTime")
            if et then
                local now = workspace:GetServerTimeNow()
                if (et - now) > 0 then
                    isRag = true
                end
            end
            
            if isRag then
                for _, d in pairs(char:GetDescendants()) do
                    if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and string.find(d.Name, "RagdollAttachment")) then
                        pcall(function() d:Destroy() end)
                    end
                end
                pcall(function() LP:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
                if hum2.Health > 0 then
                    hum2:ChangeState(Enum.HumanoidStateType.Running)
                end
                root.Anchored = false
                root.AssemblyLinearVelocity = Vector3.zero
                workspace.CurrentCamera.CameraSubject = hum2
                pcall(function()
                    local pm=LP.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
            end
            
            for _,obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
            end
        end)
    end
    stopAntiRagdoll = function()
        if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag = nil end
    end

    local _rtTimerActive = false
    local function getRagTimerLbl()
        local char = LP.Character
        if not char then return nil end
        local head = char:FindFirstChild("Head")
        if not head then return nil end
        local bb = head:FindFirstChild("MoonHubBB")
        if not bb then return nil end
        return bb:FindFirstChild("RagdollTimerLbl")
    end
    local function startRagTimerGui()
        if _rtTimerActive then return end
        _rtTimerActive = true
        task.spawn(function()
            local t = 3.0
            while t >= 0.0 do
                local lbl = getRagTimerLbl()
                if lbl then
                    lbl.Text = string.format("%.1f", t)
                    lbl.TextColor3 = BLUE_LIGHT
                end
                task.wait(0.1)
                t = math.round((t - 0.1) * 10) / 10
            end
            local lbl = getRagTimerLbl()
            if lbl then
                lbl.Text = "STEAL!"
                lbl.TextColor3 = BLUE_MAIN
            end
            repeat task.wait(0.1) until (function()
                local c = LP.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not hum then return true end
                local st = hum:GetState()
                return st ~= Enum.HumanoidStateType.Physics and st ~= Enum.HumanoidStateType.Ragdoll and st ~= Enum.HumanoidStateType.FallingDown
            end)()
            local lbl2 = getRagTimerLbl()
            if lbl2 then lbl2.Text = "" end
            _rtTimerActive = false
        end)
    end
    local function startRagTimerDetection(char)
        RunService.Heartbeat:Connect(function()
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                startRagTimerGui()
            end
        end)
    end

    -- ============================================================
    -- CHARACTER SETUP (BLUE THEME)
    -- ============================================================
    local function setupChar(char)
        task.wait(0.1)
        h=char:WaitForChild("Humanoid",5)
        hrp=char:WaitForChild("HumanoidRootPart",5)
        if not h or not hrp then return end
        local head=char:FindFirstChild("Head")
        if head then
            local oldBB=head:FindFirstChild("MoonHubBB")
            if oldBB then oldBB:Destroy() end
            local bb=Instance.new("BillboardGui", head)
            bb.Name="MoonHubBB"
            bb.Size=UDim2.new(0,160,0,80)
            bb.StudsOffset=Vector3.new(0,2.5,0)
            bb.AlwaysOnTop=true
            local list=Instance.new("UIListLayout",bb)
            list.FillDirection=Enum.FillDirection.Vertical
            list.SortOrder=Enum.SortOrder.LayoutOrder
            list.VerticalAlignment=Enum.VerticalAlignment.Center
            list.Padding=UDim.new(0,2)
            local speedBillLbl=Instance.new("TextLabel",bb)
            speedBillLbl.Name="SpeedBillLbl"
            speedBillLbl.Size=UDim2.new(1,0,0,20)
            speedBillLbl.BackgroundTransparency=1
            speedBillLbl.Text="0.0"
            speedBillLbl.TextColor3=BLUE_LIGHT
            speedBillLbl.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            speedBillLbl.TextScaled=true
            speedBillLbl.TextStrokeTransparency=0.1
            speedBillLbl.TextStrokeColor3=Color3.new(0,0,0)
            speedBillLbl.LayoutOrder=1
            local discordLbl=Instance.new("TextLabel",bb)
            discordLbl.Size=UDim2.new(1,0,0,18)
            discordLbl.BackgroundTransparency=1
            discordLbl.Text="discord.gg/Gk3UcK9A2"
            discordLbl.TextColor3=BLUE_DIM
            discordLbl.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            discordLbl.TextScaled=true
            discordLbl.TextStrokeTransparency=0.1
            discordLbl.TextStrokeColor3=Color3.new(0,0,0)
            discordLbl.LayoutOrder=2
            local ragTimerLbl=Instance.new("TextLabel",bb)
            ragTimerLbl.Name="RagdollTimerLbl"
            ragTimerLbl.Size=UDim2.new(1,0,0,24)
            ragTimerLbl.BackgroundTransparency=1
            ragTimerLbl.Text=""
            ragTimerLbl.TextColor3=BLUE_LIGHT
            ragTimerLbl.FontFace=Font.new("rbxasset://fonts/families/Bangers.json")
            ragTimerLbl.TextScaled=true
            ragTimerLbl.TextStrokeTransparency=0.1
            ragTimerLbl.TextStrokeColor3=Color3.new(0,0,0)
            ragTimerLbl.LayoutOrder=3
        end
        if Conns.antiRag then stopAntiRagdoll() end
        Steal.Data={}
        _rtTimerActive = false
        local _rtLbl = getRagTimerLbl and getRagTimerLbl()
        if _rtLbl then _rtLbl.Text = "" end
        task.spawn(function() startRagTimerDetection(char) end)
        if State.antiRagdollEnabled then 
            if not Conns.antiRag then
                task.wait(0.1)
                startAntiRagdoll() 
            end 
        end
        if State.medusaCounterEnabled then setupMedusaCounter(char) end
        if State.batAimbotToggled then
            stopAutoBatLoop()
            task.wait(0.2)
            pcall(startAutoBatLoop)
        end
        if State.batCounterEnabled then
            task.wait(0.3)
            startBatCounter()
        end
        if State.batV2Enabled then
            task.wait(0.3)
            local bat = getBat_V2()
            if bat then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:EquipTool(bat) end) end
            end
        end
        if State.tryardAnimEnabled then
            saveOriginalTryardAnims(char)
            applyTryardAnimPack(char)
        end
        if State.fpsBoostEnabled then
            pcall(applyFPSBoost)
        end
        if State.espEnabled then
            enableESP()
        end
        if State.autoResetMedusaEnabled then
            setupAutoResetOnMedusa(char)
        end
        if Steal.AutoStealEnabled then
            task.wait(0.2)
            startAutoSteal()
        end
    end
    LP.CharacterAdded:Connect(setupChar)
    if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

    -- ============================================================
    -- RUNTIME LOOPS
    -- ============================================================
    RunService.Stepped:Connect(function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                for _,part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide=false end
                end
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not (h and hrp) then return end
        if State._tpInProgress then return end
        if not State.batAimbotToggled and not State.batV2Enabled and not State.autoLeftEnabled and not State.autoRightEnabled then
            local md=h.MoveDirection
            local spd
            if State.laggerMode==1 then
                spd=State.laggerSpeed
            elseif State.laggerMode==2 then
                spd=State.laggerCarrySpeed
            else
                spd=State.speedToggled and State.carrySpeed or State.normalSpeed
            end
            if md.Magnitude>0 then
                State.lastMoveDir=md
                hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
            elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
                local anyHeld=false
                for key in pairs(MOVE_KEYS) do
                    if UIS:IsKeyDown(key) then anyHeld=true; break end
                end
                if anyHeld then
                    hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd)
                end
            end
        end
        pcall(function()
            local head2=LP.Character and LP.Character:FindFirstChild("Head")
            if head2 then
                local bb2=head2:FindFirstChild("MoonHubBB")
                local sl=bb2 and bb2:FindFirstChild("SpeedBillLbl")
                if sl then
                    local currentSpeed
                    if State.laggerMode==1 then
                        currentSpeed = State.laggerSpeed
                    elseif State.laggerMode==2 then
                        currentSpeed = State.laggerCarrySpeed
                    elseif State.speedToggled then
                        currentSpeed = State.carrySpeed
                    else
                        currentSpeed = State.normalSpeed
                    end
                    sl.Text = string.format("%.1f", currentSpeed)
                end
            end
        end)
    end)

    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        local isKb=inp.UserInputType==Enum.UserInputType.Keyboard
        local isGp=inp.UserInputType==Enum.UserInputType.Gamepad1 or inp.UserInputType==Enum.UserInputType.Gamepad2 or inp.UserInputType==Enum.UserInputType.Gamepad3 or inp.UserInputType==Enum.UserInputType.Gamepad4
        if not isKb and not isGp then return end
        local kc=inp.KeyCode
        if kc==Enum.KeyCode.Unknown then return end
        if kc==Keys.speed then
            toggleSpeed()
        elseif kc==Keys.autoLeft then
            State.autoLeftEnabled=not State.autoLeftEnabled
            if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
            if State.autoLeftEnabled and State.batAimbotToggled then
                State.batAimbotToggled=false
                stopAutoBatLoop()
                if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end
            end
            if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
            requestSave()
        elseif kc==Keys.autoRight then
            State.autoRightEnabled=not State.autoRightEnabled
            if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end
            if State.autoRightEnabled and State.batAimbotToggled then
                State.batAimbotToggled=false
                stopAutoBatLoop()
                if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end
            end
            if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
            requestSave()
        elseif kc==Keys.drop then
            if not dropActive then pcall(runDrop) end
        elseif kc==Keys.lagger then
            toggleLaggerMode()
        elseif kc==Keys.laggerCarry then
            toggleLaggerCarryMode()
        elseif kc==Keys.tpDown then
            if runTPDown then task.spawn(runTPDown) end
        elseif kc==Keys.aimbot then
            toggleAimbot()
        elseif kc==Keys.batV2 then
            local ns = not State.batV2Enabled
            toggleBatV2(ns)
            requestSave()
        elseif kc==Keys.guiHide then
            if isKb then
                State.guiVisible=not State.guiVisible
                mainOuter.Visible=State.guiVisible
                if _G.GreenDuelsQAHide then pcall(_G.GreenDuelsQAHide, not State.guiVisible) end
                requestSave()
            end
        elseif kc==Keys.tpBat then
            toggleTPBat()
        elseif kc==Keys.reset then
            doInstantReset()
        end
    end)

    _G._VezyFOV = _G._VezyFOV or 70
    _G._VezyFOVPropConn = nil
    local function _attachFOVLock(cam)
        if not cam then return end
        if _G._VezyFOVPropConn then pcall(function() _G._VezyFOVPropConn:Disconnect() end) end
        pcall(function() cam.FieldOfView = _G._VezyFOV or 70 end)
        _G._VezyFOVPropConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
            local target = _G._VezyFOV or 70
            if not State.stretchedResEnabled and cam.FieldOfView ~= target then
                pcall(function() cam.FieldOfView = target end)
            end
        end)
    end
    _attachFOVLock(workspace.CurrentCamera)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait()
        _attachFOVLock(workspace.CurrentCamera)
    end)
    LP.CharacterAdded:Connect(function()
        task.wait(0.3)
        _attachFOVLock(workspace.CurrentCamera)
    end)
    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local target = _G._VezyFOV or 70
        if not State.stretchedResEnabled and cam.FieldOfView ~= target then
            pcall(function() cam.FieldOfView = target end)
        end
    end)

    -- ============================================================
    -- MINI MOON BUTTON
    -- ============================================================
    local cloverBtn = Instance.new("TextButton", gui)
    cloverBtn.Name = "MoonHubButton"
    cloverBtn.Size = UDim2.new(0,120,0,30)
    cloverBtn.Position = UDim2.new(0,16,0,160)
    cloverBtn.BackgroundColor3 = Color3.fromRGB(0,0,5)
    cloverBtn.BorderSizePixel = 0
    cloverBtn.Text = "🌙 MOON"
    cloverBtn.TextColor3 = BLUE_LIGHT
    cloverBtn.FontFace = Font.new("rbxasset://fonts/families/Bangers.json")
    cloverBtn.TextSize = 13
    cloverBtn.ZIndex = 25
    cloverBtn.Visible = true
    mkCorner(cloverBtn,10)
    buildNeonBorder(cloverBtn, 2, 35, 0.8)

    do
        local dragStart,startPos,dragging = nil,nil,false
        local saveDebounce = nil
        cloverBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = cloverBtn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.InputUserState.End then dragging = false end
                end)
            end
        end)
        cloverBtn.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                cloverBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        cloverBtn.InputEnded:Connect(function()
            if dragging then
                dragging = false
                if saveDebounce then task.cancel(saveDebounce) end
                saveDebounce = task.delay(0.2, function()
                    pcall(requestSave)
                    saveDebounce = nil
                end)
            end
        end)
    end

    cloverBtn.MouseButton1Click:Connect(function()
        State.guiVisible = not State.guiVisible
        mainOuter.Visible = State.guiVisible
        if _G.GreenDuelsQAHide then pcall(_G.GreenDuelsQAHide, not State.guiVisible) end
        requestSave()
    end)

    cloverBtn.MouseEnter:Connect(function()
        TweenService:Create(cloverBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(0,10,20)}):Play()
    end)
    cloverBtn.MouseLeave:Connect(function()
        TweenService:Create(cloverBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(0,0,5)}):Play()
    end)

    -- ============================================================
    -- SAVE / LOAD
    -- ============================================================
    saveConfig = function()
        local success = false
        pcall(function()
            if _isfile(CONFIG_FILE) then
                local oldRaw = _readfile(CONFIG_FILE)
                if oldRaw and oldRaw ~= "" then
                    pcall(function() _writefile(CONFIG_BACKUP, oldRaw) end)
                end
            end
            
            local btnPositions = {}
            for key, wrapper in pairs(stackWrappers) do
                if wrapper and wrapper.Position then
                    btnPositions[key] = { X = wrapper.Position.X.Offset, Y = wrapper.Position.Y.Offset }
                end
            end
            local stealBarPos = stealBarFrame and stealBarFrame.Position and { X = stealBarFrame.Position.X.Offset, Y = stealBarFrame.Position.Y.Offset } or nil
            local cloverPos = cloverBtn and cloverBtn.Position and { X = cloverBtn.Position.X.Offset, Y = cloverBtn.Position.Y.Offset } or nil
            local cfg = {
                version = CONFIG_VERSION,
                normalSpeed = State.normalSpeed,
                carrySpeed = State.carrySpeed,
                laggerSpeed = State.laggerSpeed,
                laggerCarrySpeed = State.laggerCarrySpeed,
                speedToggled = State.speedToggled,
                laggerMode = State.laggerMode,
                stealRadius = Steal.StealRadius,
                stealDuration = Steal.StealDuration,
                uiScale = uiScaleObj and uiScaleObj.Scale or 1.0,
                stackButtonsHidden = State.stackButtonsHidden,
                stackButtonsLocked = State.stackButtonsLocked,
                speedKey = Keys.speed and Keys.speed.Name or "Q",
                autoLeftKey = Keys.autoLeft and Keys.autoLeft.Name or "L",
                autoRightKey = Keys.autoRight and Keys.autoRight.Name or "R",
                guiHideKey = Keys.guiHide and Keys.guiHide.Name or "LeftControl",
                dropKey = Keys.drop and Keys.drop.Name or "H",
                laggerKey = Keys.lagger and Keys.lagger.Name or "Unknown",
                laggerCarryKey = Keys.laggerCarry and Keys.laggerCarry.Name or "Unknown",
                tpDownKey = Keys.tpDown and Keys.tpDown.Name or "Unknown",
                aimbotKey = Keys.aimbot and Keys.aimbot.Name or "Unknown",
                tpBatKey = Keys.tpBat and Keys.tpBat.Name or "Unknown",
                resetKey = Keys.reset and Keys.reset.Name or "R",
                batV2Key = Keys.batV2 and Keys.batV2.Name or "V",
                infJump = State.infJumpEnabled,
                antiRagdoll = State.antiRagdollEnabled,
                medusaCounter = State.medusaCounterEnabled,
                batCounter = State.batCounterEnabled,
                autoStealEnabled = Steal.AutoStealEnabled,
                autoSwing = State.autoSwingEnabled,
                batAimbot = State.batAimbotToggled,
                batV2 = State.batV2Enabled,
                stretchedResEnabled = State.stretchedResEnabled,
                normalFOV = _G._VezyFOV or 70,
                tryardAnimEnabled = State.tryardAnimEnabled,
                introEnabled = State.introEnabled,
                guiVisible = State.guiVisible,
                buttonPositions = btnPositions,
                stealBarPosition = stealBarPos,
                cloverPosition = cloverPos,
                autoTPEnabled = State.autoTPEnabled,
                autoTPHeight = State.autoTPHeight,
                fpsBoostEnabled = State.fpsBoostEnabled,
                aimbotSpeed = AimbotConfig.CHASE_SPEED,
                aimbotFollowDist = AimbotConfig.FOLLOW_DIST,
                tpBatActive = State.tpBatActive,
                espEnabled = State.espEnabled,
                autoResetMedusaEnabled = State.autoResetMedusaEnabled,
            }
            local encoded = HttpService:JSONEncode(cfg)
            _writefile(CONFIG_FILE, encoded)
            local verify = _readfile(CONFIG_FILE)
            if verify == encoded then success = true end
        end)
        if not success then
            pcall(_G._VezyFlashSave, false)
            warn("[Moon Hub] Config save FAILED!")
        else
            pcall(_G._VezyFlashSave, true)
        end
        return success
    end

    loadConfig = function()
        local raw = nil
        if _isfile(CONFIG_FILE) then
            raw = _readfile(CONFIG_FILE)
        end
        if not raw or raw == "" then
            if _isfile(CONFIG_BACKUP) then
                raw = _readfile(CONFIG_BACKUP)
                if raw and raw ~= "" then
                    print("[Moon Hub] Loaded config from backup")
                end
            end
        end
        if not raw or raw == "" then
            print("[Moon Hub] No valid config file found, using defaults")
            return false
        end
        
        local ok, decErr = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok or not decErr then
            pcall(function() _delfile(CONFIG_FILE) end)
            pcall(function() _delfile(CONFIG_BACKUP) end)
            warn("[Moon Hub] Corrupt config deleted, using defaults")
            return false
        end

        local function applyNumber(key, targetVar, uiBox)
            if decErr[key] ~= nil then
                targetVar = decErr[key]
                if uiBox and uiBox.Text then uiBox.Text = tostring(decErr[key]) end
            end
            return targetVar
        end

        State.normalSpeed = applyNumber("normalSpeed", State.normalSpeed, normalBox)
        State.carrySpeed = applyNumber("carrySpeed", State.carrySpeed, carryBox)
        State.laggerSpeed = applyNumber("laggerSpeed", State.laggerSpeed, laggerBox)
        State.laggerCarrySpeed = applyNumber("laggerCarrySpeed", State.laggerCarrySpeed, laggerCarryBox)
        Steal.StealRadius = applyNumber("stealRadius", Steal.StealRadius, stealRadBox)
        Steal.StealDuration = applyNumber("stealDuration", Steal.StealDuration, stealDurBox)
        
        if decErr.autoStealEnabled ~= nil then
            Steal.AutoStealEnabled = decErr.autoStealEnabled
            if toggleSetters["autoSteal"] then
                toggleSetters["autoSteal"](Steal.AutoStealEnabled)
            end
        end
        
        if decErr.uiScale and uiScaleObj then
            uiScaleObj.Scale = decErr.uiScale
            if uiScaleBox then uiScaleBox.Text = tostring(decErr.uiScale) end
        end
        if decErr.normalFOV then
            _G._VezyFOV = decErr.normalFOV
            pcall(function() workspace.CurrentCamera.FieldOfView = _G._VezyFOV end)
        end
        if decErr.autoTPEnabled ~= nil then State.autoTPEnabled = decErr.autoTPEnabled end
        if decErr.autoTPHeight then
            State.autoTPHeight = decErr.autoTPHeight
            if autoTPHeightBox then autoTPHeightBox.Text = tostring(State.autoTPHeight) end
        end
        if decErr.fpsBoostEnabled ~= nil then
            State.fpsBoostEnabled = decErr.fpsBoostEnabled
            if fpsBoostSetter then
                fpsBoostSetter(decErr.fpsBoostEnabled)
                if decErr.fpsBoostEnabled then
                    pcall(applyFPSBoost)
                else
                    pcall(disableFPSBoost)
                end
            end
        end
        if decErr.aimbotSpeed then
            AimbotConfig.CHASE_SPEED = decErr.aimbotSpeed
            if aimbotSpeedBox then aimbotSpeedBox.Text = tostring(decErr.aimbotSpeed) end
        end
        if decErr.aimbotFollowDist then
            AimbotConfig.FOLLOW_DIST = decErr.aimbotFollowDist
            if aimbotFollowDistBox then aimbotFollowDistBox.Text = tostring(decErr.aimbotFollowDist) end
        end
        if decErr.batV2 ~= nil then
            State.batV2Enabled = decErr.batV2
            if toggleSetters["batV2"] then toggleSetters["batV2"](decErr.batV2) end
            if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(decErr.batV2) end
        end
        if decErr.tpBatActive ~= nil then
            State.tpBatActive = decErr.tpBatActive
            if stackBtnRefs.tpBat then stackBtnRefs.tpBat.setOn(decErr.tpBatActive) end
        end
        if decErr.espEnabled ~= nil then
            State.espEnabled = decErr.espEnabled
            if toggleSetters["esp"] then toggleSetters["esp"](decErr.espEnabled) end
        end
        if decErr.autoResetMedusaEnabled ~= nil then
            State.autoResetMedusaEnabled = decErr.autoResetMedusaEnabled
            if toggleSetters["autoResetMedusa"] then toggleSetters["autoResetMedusa"](decErr.autoResetMedusaEnabled) end
        end

        local bools = {
            stackButtonsHidden="stackButtonsHidden", stackButtonsLocked="stackButtonsLocked",
            infJump="infJumpEnabled", antiRagdoll="antiRagdollEnabled",
            medusaCounter="medusaCounterEnabled", batCounter="batCounterEnabled",
            autoSwing="autoSwingEnabled",
            batAimbot="batAimbotToggled",
            stretchedResEnabled="stretchedResEnabled",
            tryardAnimEnabled="tryardAnimEnabled", introEnabled="introEnabled",
            guiVisible="guiVisible", speedToggled="speedToggled", autoTPEnabled="autoTPEnabled",
        }
        for cfgKey, stateKey in pairs(bools) do
            if decErr[cfgKey] ~= nil then State[stateKey] = decErr[cfgKey] end
        end
        if decErr.laggerMode ~= nil then State.laggerMode = decErr.laggerMode end

        local keyMap = {
            speedKey="speed", autoLeftKey="autoLeft", autoRightKey="autoRight",
            guiHideKey="guiHide", dropKey="drop", laggerKey="lagger",
            laggerCarryKey="laggerCarry",
            tpDownKey="tpDown", aimbotKey="aimbot", tpBatKey="tpBat", resetKey="reset",
            batV2Key="batV2"
        }
        for cfgKey, stateKey in pairs(keyMap) do
            if decErr[cfgKey] then
                local kc = Enum.KeyCode[decErr[cfgKey]]
                if kc then
                    Keys[stateKey] = kc
                    if keybindBtnRefs[stateKey] then keybindBtnRefs[stateKey].Text = getKeyDisplayName(kc) end
                end
            end
        end

        mainOuter.Visible = State.guiVisible
        if _G.GreenDuelsQAHide then pcall(_G.GreenDuelsQAHide, not State.guiVisible) end
        for _, wrapper in pairs(stackWrappers) do wrapper.Visible = not State.stackButtonsHidden end
        if hideButtonsSetter then hideButtonsSetter(State.stackButtonsHidden) end
        if lockButtonsSetter then lockButtonsSetter(State.stackButtonsLocked) end

        if State.laggerMode == 0 then
            if carryBox then carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed) end
        elseif State.laggerMode == 1 then
            if carryBox then carryBox.Text = tostring(State.laggerSpeed) end
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
        elseif State.laggerMode == 2 then
            if carryBox then carryBox.Text = tostring(State.laggerCarrySpeed) end
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
        end
        if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled and State.laggerMode == 0) end
        if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerMode == 1) end
        if stackBtnRefs.laggerCarry then stackBtnRefs.laggerCarry.setOn(State.laggerMode == 2) end
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(State.batAimbotToggled) end
        if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
        if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end
        if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(State.batV2Enabled) end
        if stackBtnRefs.tpBat then stackBtnRefs.tpBat.setOn(State.tpBatActive) end

        if decErr.stealBarPosition and stealBarFrame then
            stealBarFrame.Position = UDim2.new(stealBarFrame.Position.X.Scale, decErr.stealBarPosition.X, stealBarFrame.Position.Y.Scale, decErr.stealBarPosition.Y)
        end

        if Steal.AutoStealEnabled then
            startAutoSteal()
        else
            stopAutoSteal()
        end

        if State.stretchedResEnabled then enableStretchRez() else disableStretchRez() end
        if State.tryardAnimEnabled then startTryardAnim() else stopTryardAnim() end
        if State.batAimbotToggled then startAutoBatLoop() else stopAutoBatLoop() end
        if State.batCounterEnabled then startBatCounter() else stopBatCounter() end
        if State.batV2Enabled then 
            startBatV2() 
            if toggleSetters["batV2"] then toggleSetters["batV2"](true) end
        else 
            stopBatV2()
        end
        if State.tpBatActive then
            startTPBat()
        else
            stopTPBat()
        end
        if State.medusaCounterEnabled then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
        if Conns.antiRag then stopAntiRagdoll() end
        if State.antiRagdollEnabled then task.wait(0.2); startAntiRagdoll() else stopAntiRagdoll() end
        if State.autoTPEnabled then startAutoTP() else stopAutoTP() end
        if State.fpsBoostEnabled then pcall(applyFPSBoost) end
        if State.espEnabled then enableESP() else disableESP() end
        if State.autoResetMedusaEnabled then setupAutoResetOnMedusa(LP.Character) else stopAutoResetOnMedusa() end

        for key, setter in pairs(toggleSetters) do
            local stateValue = nil
            if key=="autoSteal" then stateValue=Steal.AutoStealEnabled
            elseif key=="infJump" then stateValue=State.infJumpEnabled
            elseif key=="antiRagdoll" then stateValue=State.antiRagdollEnabled
            elseif key=="medusaCounter" then stateValue=State.medusaCounterEnabled
            elseif key=="batCounter" then stateValue=State.batCounterEnabled
            elseif key=="autoSwing" then stateValue=State.autoSwingEnabled
            elseif key=="stretchedRes" then stateValue=State.stretchedResEnabled
            elseif key=="tryardAnim" then stateValue=State.tryardAnimEnabled
            elseif key=="introEnabled" then stateValue=State.introEnabled
            elseif key=="hideButtons" then stateValue=State.stackButtonsHidden
            elseif key=="lockButtons" then stateValue=State.stackButtonsLocked
            elseif key=="autoTP" then stateValue=State.autoTPEnabled
            elseif key=="fpsBoost" then stateValue=State.fpsBoostEnabled
            elseif key=="batV2" then stateValue=State.batV2Enabled
            elseif key=="esp" then stateValue=State.espEnabled
            elseif key=="autoResetMedusa" then stateValue=State.autoResetMedusaEnabled
            end
            if stateValue ~= nil then pcall(setter, stateValue) end
        end

        refreshAllKeybindButtons()

        if decErr.buttonPositions then
            for key, posData in pairs(decErr.buttonPositions) do
                local wrapper = stackWrappers[key]
                if wrapper and posData.X and posData.Y then
                    wrapper.Position = UDim2.new(wrapper.Position.X.Scale, posData.X, wrapper.Position.Y.Scale, posData.Y)
                end
            end
        end
        if decErr.cloverPosition and cloverBtn then
            cloverBtn.Position = UDim2.new(0, decErr.cloverPosition.X, 0, decErr.cloverPosition.Y)
        end

        print("[Moon Hub] Config loaded successfully")
        return true
    end

    requestSave = function()
        local ok = saveConfig()
        if ok then
            if _G._VezyFlashSave then _G._VezyFlashSave(true) end
        else
            if _G._VezyFlashSave then _G._VezyFlashSave(false) end
        end
    end

    -- ============================================================
    -- INIT
    -- ============================================================
    loadPresetsFile()
    rebuildPresetList()
    local _lastPresetName = loadLastPresetName()
    if _lastPresetName and _lastPresetName~="" then
        for _,preset in ipairs(Presets) do
            if preset.name==_lastPresetName then
                pcall(function()
                    local d=preset.data or {}
                    if d.normalSpeed then State.normalSpeed=d.normalSpeed; if normalBox then normalBox.Text=tostring(d.normalSpeed) end end
                    if d.carrySpeed then State.carrySpeed=d.carrySpeed; if carryBox then carryBox.Text=tostring(d.carrySpeed) end end
                    if d.laggerSpeed then State.laggerSpeed=d.laggerSpeed; if laggerBox then laggerBox.Text=tostring(d.laggerSpeed) end end
                    if d.laggerCarrySpeed then State.laggerCarrySpeed=d.laggerCarrySpeed; if laggerCarryBox then laggerCarryBox.Text=tostring(d.laggerCarrySpeed) end end
                    if d.stealRadius then Steal.StealRadius=d.stealRadius; if stealRadBox and not stealRadBox:IsFocused() then stealRadBox.Text=tostring(Steal.StealRadius) end end
                    if d.stealDuration then Steal.StealDuration=d.stealDuration; if stealDurBox then stealDurBox.Text=tostring(Steal.StealDuration) end end
                    if d.autoTP ~= nil then State.autoTPEnabled=d.autoTP; if toggleSetters["autoTP"] then toggleSetters["autoTP"](d.autoTP) end end
                    if d.autoTPHeight then State.autoTPHeight=d.autoTPHeight; if autoTPHeightBox then autoTPHeightBox.Text=tostring(d.autoTPHeight) end end
                    if d.fpsBoost ~= nil then State.fpsBoostEnabled=d.fpsBoost; if fpsBoostSetter then fpsBoostSetter(d.fpsBoost) end end
                    if d.aimbotSpeed then AimbotConfig.CHASE_SPEED=d.aimbotSpeed; if aimbotSpeedBox then aimbotSpeedBox.Text=tostring(d.aimbotSpeed) end end
                    if d.aimbotFollowDist then AimbotConfig.FOLLOW_DIST=d.aimbotFollowDist; if aimbotFollowDistBox then aimbotFollowDistBox.Text=tostring(d.aimbotFollowDist) end end
                    if d.batV2 ~= nil then 
                        State.batV2Enabled=d.batV2
                        if toggleSetters["batV2"] then toggleSetters["batV2"](d.batV2) end
                        if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(d.batV2) end
                    end
                    if d.esp ~= nil then State.espEnabled=d.esp; if toggleSetters["esp"] then toggleSetters["esp"](d.esp) end end
                    if d.autoResetMedusa ~= nil then State.autoResetMedusaEnabled=d.autoResetMedusa; if toggleSetters["autoResetMedusa"] then toggleSetters["autoResetMedusa"](d.autoResetMedusa) end end
                end)
                break
            end
        end
    end
    loadConfig()
    startAutoSteal()
    print("[Moon Hub] Ready. Target Hub style with original Auto Steal!")
    print("[Moon Hub] ✓ Colors changed to BLUE theme (Moon Hub)")
    print("[Moon Hub] ✓ Fonts changed to Bangers")
    print("[Moon Hub] ✓ Neon border effect added (rotating gradient)")
    print("[Moon Hub] ✓ Intro updated with Moon Hub style")
    print("[Moon Hub] ✓ ESP persists after opponent respawn")
    print("[Moon Hub] ✓ Other Players Speed is always ON")
    print("[Moon Hub] ✓ Button press animation removed")
    print("[Moon Hub] ✓ Original Auto Steal (working version)")
    print("[Moon Hub] ✓ Auto steal properly saves state")
    print("[Moon Hub] ✓ Clean Effects button removed")
    print("[Moon Hub] ✓ Ping display added to steal bar (Cyber Hub style)")
    print("[Moon Hub] ✓ Steal bar size slightly reduced (270px)")
    print("[Moon Hub] ✓ Aimbot Follow Distance added to GUI")
    print("[Moon Hub] ✓ BAT V2 speed set to 59")
    print("[Moon Hub] ✓ All headers removed as requested")
    print("[Moon Hub] ✓ Avatar removed as requested")
end

-- ============================================================
-- SAFE MAIN EXECUTION
-- ============================================================

if not _G.GreenDuelsV2_MainExecuted then
    if LP and LP:FindFirstChild("PlayerGui") then
        Main()
    else
        LP = LP or Players:WaitForChild("LocalPlayer")
        LP:WaitForChild("PlayerGui")
        Main()
    end
end
