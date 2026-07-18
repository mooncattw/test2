



local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local RunService         = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")

local request = http_request or request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
if not request then return end

local LP = Players.LocalPlayer
if not LP then LP = Players.PlayerAdded:Wait() end

-- Prevent multiple instances
if _G.LarpDuelsV2_Running then return end
_G.LarpDuelsV2_Running = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")

local LP = Players.LocalPlayer or Players:WaitForChild("LocalPlayer")

local _isfile = isfile or (syn and syn.isfile) or (getgenv and getgenv().isfile) or function() return false end
local _readfile = readfile or (syn and syn.readfile) or (getgenv and getgenv().readfile) or function() return nil end
local _writefile = writefile or (syn and syn.writefile) or (getgenv and getgenv().writefile) or function() end
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

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
-- CONFIG VERSION & EARLY LOAD
-- ============================================================
local CONFIG_VERSION = 2
local CONFIG_FILE = "LarpDuelsConfig.json"
local CONFIG_BACKUP = "LarpDuelsConfig.bak"

local earlyConfig = nil
local function loadEarlyConfig()
    if not _isfile(CONFIG_FILE) then return nil end
    local raw = _readfile(CONFIG_FILE)
    if not raw then return nil end
    local ok, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and cfg and cfg.version == CONFIG_VERSION then return cfg end
    return nil
end
earlyConfig = loadEarlyConfig()
local introShouldPlay = (earlyConfig == nil or earlyConfig.introEnabled ~= false)

-- Intro (skip if disabled)
if introShouldPlay then
    local _TS = TweenService
    local _PG = LP:WaitForChild("PlayerGui")
    local introGui = Instance.new("ScreenGui")
    introGui.Name = "LarpDuelsIntro"
    introGui.ResetOnSpawn = false
    introGui.IgnoreGuiInset = true
    introGui.DisplayOrder = 999
    introGui.Parent = _PG

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.new(0,0,0)
    bg.BackgroundTransparency = 0.15
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
    logo.ImageColor3 = Color3.fromRGB(80,140,255)
    logo.ImageTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = container

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,50)
    title.Position = UDim2.new(0,0,0,170)
    title.BackgroundTransparency = 1
    title.Text = "LARP DUELS"
    title.TextColor3 = Color3.fromRGB(80,140,255)
    title.TextTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.TextStrokeTransparency = 0.2
    title.TextStrokeColor3 = Color3.new(0,0,0)
    title.Parent = container

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(0.8,0,0,30)
    sub.Position = UDim2.new(0.1,0,0,230)
    sub.BackgroundTransparency = 1
    sub.Text = "LARP IN PROGRESS"
    sub.TextColor3 = Color3.fromRGB(80,140,255)
    sub.TextTransparency = 1
    sub.TextScaled = true
    sub.Font = Enum.Font.GothamBold
    sub.Parent = container

    local loadingBg = Instance.new("Frame")
    loadingBg.Size = UDim2.new(0.6,0,0,4)
    loadingBg.Position = UDim2.new(0.2,0,0,275)
    loadingBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
    loadingBg.BackgroundTransparency = 0.5
    loadingBg.BorderSizePixel = 0
    loadingBg.Parent = container
    Instance.new("UICorner", loadingBg).CornerRadius = UDim.new(0,2)

    local loadingBar = Instance.new("Frame")
    loadingBar.Size = UDim2.new(0,0,1,0)
    loadingBar.BackgroundColor3 = Color3.fromRGB(80,140,255)
    loadingBar.BackgroundTransparency = 0.3
    loadingBar.BorderSizePixel = 0
    loadingBar.Parent = loadingBg
    Instance.new("UICorner", loadingBar).CornerRadius = UDim.new(0,2)

    _TS:Create(bg, TweenInfo.new(0.7), {BackgroundTransparency = 0.15}):Play()
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
-- STATE (simplified Infinite Jump, Auto TP downward)
-- ============================================================
local State = {
    normalSpeed=60, carrySpeed=30, laggerSpeed=10.1, laggerCarrySpeed=15,
    speedToggled=false,
    laggerMode=0,
    infJumpEnabled=false, antiRagdollEnabled=false,
    guiVisible=true, uiLocked=false,
    isStealing=false, stealStartTime=nil, lastStealTick=0,
    autoLeftEnabled=false, autoRightEnabled=false,
    autoLeftPhase=1, autoRightPhase=1,
    medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
    batAimbotToggled=false, autoSwingEnabled=false, batV2Toggled=false,
    hittingCooldown=false,
    batCounterEnabled=false, batCounterDebounce=false,
    dropEnabled=false, _tpInProgress=false,
    lastMoveDir=Vector3.new(0,0,0),
    _prevCarry=30, _prevSpeed=false,
    stackButtonsHidden=false,
    countdownActive=false,
    stackButtonsLocked=false,
    nukeOpt=false,
    removeAcc=false,
    antiLagEnabled=false,
    stretchedResEnabled=false,
    stretchFOV=120,
    activeSky=nil,
    tryardAnimEnabled=false,
    introEnabled=true,
    autoTPEnabled=false,
    autoTPHeight=20,               -- height threshold (above this Y -> teleport down)
    autoTPConn=nil,
    bodyLockEnabled=false,
    bodyLockRadius=5,
    bodyLockConn=nil,
}

if earlyConfig and earlyConfig.introEnabled ~= nil then
    State.introEnabled = earlyConfig.introEnabled
end

local Keys = {
    speed=Enum.KeyCode.Q, guiHide=Enum.KeyCode.LeftControl,
    autoLeft=Enum.KeyCode.L, autoRight=Enum.KeyCode.R,
    lagger=Enum.KeyCode.Unknown,
    tpDown=Enum.KeyCode.Unknown,
    drop=Enum.KeyCode.H, aimbot=Enum.KeyCode.Unknown,
}

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
-- DEFAULT STACK BUTTON POSITIONS
-- ============================================================
local BTN_W=58; local BTN_H=58; local BTN_GAP=8; local COLS=2
local stackDefs = {
    {key="autoLeft",   label="AUTO\nLEFT"},
    {key="autoRight",  label="AUTO\nRIGHT"},
    {key="aimbot",     label="AIMBOT"},
    {key="lagger",     label="LAGGER\nSPEED"},
    {key="laggerCarry",label="LAGGER\nCARRY"},
    {key="drop",       label="DROP\nBR"},
    {key="tpDown",     label="TP\nDOWN"},
    {key="carrySpeed", label="CARRY\nSPEED"},
    {key="batV2",      label="BAT\nV2"},
}
local function getDefaultStackPos(i)
    local col=(i-1)%COLS
    local row2=math.floor((i-1)/COLS)
    return UDim2.new(1,-(COLS*(BTN_W+BTN_GAP)-BTN_GAP+14)+col*(BTN_W+BTN_GAP),
                     0.5,-(math.ceil(#stackDefs/COLS)*(BTN_H+BTN_GAP)-BTN_GAP)/2+row2*(BTN_H+BTN_GAP))
end

local Steal = { AutoStealEnabled=true, StealRadius=55, StealDuration=0.25, Data={} }

-- ============================================================
-- PRESETS
-- ============================================================
local Presets = {}
local PRESET_FILE = "LarpDuelsPresets.json"
local LAST_PRESET_FILE = "LarpDuelsLastPreset.json"

local function buildPresetSnapshot() return {
    normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed,
    laggerSpeed=State.laggerSpeed, laggerCarrySpeed=State.laggerCarrySpeed,
    stealRadius=Steal.StealRadius, stealDuration=Steal.StealDuration,
    infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
    medusaCounter=State.medusaCounterEnabled, batCounter=State.batCounterEnabled,
    autoSteal=Steal.AutoStealEnabled,
    autoTP=State.autoTPEnabled, autoTPHeight=State.autoTPHeight,
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
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

-- Auto Left/Right positions (BlossomHub-style with facing vectors)
local AP_L1     = Vector3.new(-476.48, -6.28, 92.73)
local AP_L2     = Vector3.new(-483.12, -4.95, 94.80)
local AP_L_FACE = Vector3.new(-482.25, -4.96, 92.09)
local AP_R1     = Vector3.new(-476.16, -6.52, 25.62)
local AP_R2     = Vector3.new(-483.06, -5.03, 25.48)
local AP_R_FACE = Vector3.new(-482.06, -6.93, 35.47)

local alConn, arConn = nil, nil
local alPhase, arPhase = 1, 1

local Conns={autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,aimbot=nil,batV2=nil,anchor={},progress=nil,batCounter=nil, autoTP=nil}
local h,hrp
local setAutoLeft,setAutoRight,setInfJump,setAntiRag
local setMedusaCounter,setAimbot,setAutoSwing
local setLagger,setLaggerCarry,setDropBrainrot,setInstaGrab
local setNukeOpt,setRemoveAcc,setNoCam
local setupMedusaCounter,stopMedusaCounter,startAntiRagdoll,stopAntiRagdoll
local startAutoSteal,stopAutoSteal
local startAutoLeft,stopAutoLeft,startAutoRight,stopAutoRight
local saveConfig,loadConfig,runDropBrainrot,stopDropBrainrot,runTPDown
local requestSave
local startBatAimbot,stopBatAimbot,startBatCounter,stopBatCounter,setBatCounter,startBatV2,stopBatV2
local stackBtnRefs={}; local stackWrappers={}; local keybindBtnRefs={}
local normalBox,carryBox,laggerBox,laggerCarryBox,uiScaleBox,stealRadBox,stealDurBox,autoTPHeightBox,bodyLockRadBox  -- added autoTPHeightBox, bodyLockRadBox
local setHideButtonsToggle, setLockButtonsToggle
local presetListFrame=nil; local presetNameBox=nil; local rebuildPresetList
local toggleSetters = {}

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    winBg=Color3.fromRGB(0,0,8), winBg2=Color3.fromRGB(4,4,18), winBorder=Color3.fromRGB(30,100,200),
    sidebarBg=Color3.fromRGB(0,0,0), sidebarDiv=Color3.fromRGB(14,30,60),
    topBg=Color3.fromRGB(4,6,18), topTitle=Color3.fromRGB(225,235,255), topSub=Color3.fromRGB(90,130,200),
    topBtn=Color3.fromRGB(45,80,160), topBtnHov=Color3.fromRGB(60,110,210), topDivider=Color3.fromRGB(14,28,60),
    tabBarBg=Color3.fromRGB(2,4,18), tabBarDiv=Color3.fromRGB(14,28,60),
    tabIdle=Color3.fromRGB(100,140,210), tabIdleHov=Color3.fromRGB(150,190,255),
    tabActive=Color3.fromRGB(225,235,255), tabActiveBg=Color3.fromRGB(8,16,40), tabUnderline=Color3.fromRGB(50,120,240),
    sectionTxt=Color3.fromRGB(60,140,255), sectionDiv=Color3.fromRGB(14,28,60),
    rowBg=Color3.fromRGB(0,0,0), rowBorder=Color3.fromRGB(14,24,55), rowLabel=Color3.fromRGB(220,230,255),
    rowSub=Color3.fromRGB(90,120,200), rowValue=Color3.fromRGB(140,180,255), rowHov=Color3.fromRGB(8,16,40),
    inputBg=Color3.fromRGB(6,10,28), inputBorder=Color3.fromRGB(28,55,130), inputFocus=Color3.fromRGB(60,140,255),
    inputTxt=Color3.fromRGB(220,230,255),
    pillOff=Color3.fromRGB(16,28,60), pillOn=Color3.fromRGB(40,110,220), dotOff=Color3.fromRGB(55,80,160),
    dotOn=Color3.fromRGB(8,14,40), pillBorder=Color3.fromRGB(28,55,130),
    modeBtnBg=Color3.fromRGB(6,10,28), modeBtnBrd=Color3.fromRGB(24,50,120), modeBtnTxt=Color3.fromRGB(100,150,230),
    modeBtnActBg=Color3.fromRGB(40,110,220), modeBtnActTx=Color3.fromRGB(0,10,40),
    chipBg=Color3.fromRGB(6,10,28), chipBorder=Color3.fromRGB(24,50,120), chipTxt=Color3.fromRGB(110,160,240),
    btnBg=Color3.fromRGB(6,12,30), btnBorder=Color3.fromRGB(28,55,130), btnTxt=Color3.fromRGB(180,210,255),
    btnHov=Color3.fromRGB(12,24,55),
    stackBg=Color3.fromRGB(4,8,24), stackBrd=Color3.fromRGB(20,44,110), stackTxt=Color3.fromRGB(100,150,230),
    stackActBg=Color3.fromRGB(14,50,130), stackActBrd=Color3.fromRGB(50,130,240), stackActTxt=Color3.fromRGB(220,235,255),
    stackDot=Color3.fromRGB(28,55,130), stackDotOn=Color3.fromRGB(60,160,255),
    infoBg=Color3.fromRGB(4,8,24), infoBrd=Color3.fromRGB(20,44,110), infoTxt=Color3.fromRGB(90,130,220),
    infoVal=Color3.fromRGB(160,200,255), infoFill=Color3.fromRGB(50,130,240),
    accent=Color3.fromRGB(50,130,240), accentDim=Color3.fromRGB(24,50,120),
    presetBg=Color3.fromRGB(6,10,28), presetBrd=Color3.fromRGB(24,50,120), presetLoad=Color3.fromRGB(40,110,220),
    presetDel=Color3.fromRGB(80,25,25), delBrd=Color3.fromRGB(130,45,45), lockOn=Color3.fromRGB(40,110,220),
    divider=Color3.fromRGB(14,28,60),
}

-- CLEANUP
do
    local cleanupNames = {"VyseSlottedGUI","VyseAsireGUI","VyseAsireHubV4","VyseAsireHubV5","VyseAsireHubV5_1","AsireHubV5_1","AsireHubV5_2","LaitoHubV1","LarpDuelsV1"}
    for _,name in ipairs(cleanupNames) do
        pcall(function() local o=game:GetService("CoreGui"):FindFirstChild(name); if o then o:Destroy() end end)
        pcall(function() local o=LP:WaitForChild("PlayerGui"):FindFirstChild(name); if o then o:Destroy() end end)
    end
end

local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6); return c end
local function mkStroke(p,col,th) local s=Instance.new("UIStroke",p); s.Color=col; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s end

-- ============================================================
-- AUTO TP (teleports down to Y = -7 when above threshold & not grounded)
-- ============================================================
local function doAutoTPDown(force)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if not force then
        if hum.FloorMaterial ~= Enum.Material.Air then return end
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

-- Manual TP Down (keybind)
runTPDown = function()
    pcall(function() doAutoTPDown(true) end)
end

-- ============================================================
-- BODY LOCK (glues your body to the nearest player's body)
-- ============================================================
local _bodyLockTarget = nil

local function _blFindNearest()
    local myChar = LP.Character; if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return nil end
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < closestDist then closestDist = d; closest = plr end
            end
        end
    end
    return closest
end

local function startBodyLock()
    if State.bodyLockConn then State.bodyLockConn:Disconnect(); State.bodyLockConn = nil end
    _bodyLockTarget = _blFindNearest()
    State.bodyLockConn = RunService.Heartbeat:Connect(function()
        if not State.bodyLockEnabled then return end
        -- Re-acquire target if lost
        if not _bodyLockTarget or not _bodyLockTarget.Character then
            _bodyLockTarget = _blFindNearest()
            return
        end
        local myChar = LP.Character; if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        local tgtHRP = _bodyLockTarget.Character:FindFirstChild("HumanoidRootPart"); if not tgtHRP then return end
        -- Teleport our HRP to match the target's CFrame exactly (offset by radius studs behind them)
        local offset = tgtHRP.CFrame:VectorToWorldSpace(Vector3.new(0, 0, State.bodyLockRadius))
        local goalCF = CFrame.new(tgtHRP.Position + offset, tgtHRP.Position)
        myHRP.CFrame = goalCF
        myHRP.AssemblyLinearVelocity = tgtHRP.AssemblyLinearVelocity
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function stopBodyLock()
    State.bodyLockEnabled = false
    if State.bodyLockConn then State.bodyLockConn:Disconnect(); State.bodyLockConn = nil end
    _bodyLockTarget = nil
end

-- ============================================================
-- SIMPLE INFINITE JUMP (no modes, fixed boost)
-- ============================================================
local holdJumpPressed = false
local holdJumpActive = false

local function applyInfJumpBoost(boost)
    if not State.infJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Velocity = Vector3.new(root.Velocity.X, boost, root.Velocity.Z)
    end
end

UIS.JumpRequest:Connect(function()
    applyInfJumpBoost(50)
end)

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
        holdJumpPressed = true
        task.delay(0.12, function()
            if holdJumpPressed then
                holdJumpActive = true
                applyInfJumpBoost(50)
            end
        end)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
        holdJumpPressed = false
        holdJumpActive = false
    end
end)

RunService.Heartbeat:Connect(function()
    if holdJumpActive then applyInfJumpBoost(50) end
end)

-- ============================================================
-- MAIN FUNCTION
-- ============================================================

local function Main()
    if _G.LarpDuelsV2_MainExecuted then return end
    _G.LarpDuelsV2_MainExecuted = true

    local gui=Instance.new("ScreenGui")
    gui.Name="LarpDuelsV2"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
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
                inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
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

    local WIN_W = 380
    local WIN_H = 520
    local TITLE_H = 44
    local mainOuter = Instance.new("Frame", gui)
    mainOuter.Name = "MainOuter"
    mainOuter.Size = UDim2.new(0, WIN_W, 0, WIN_H)
    mainOuter.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
    mainOuter.BackgroundTransparency = 1; mainOuter.BorderSizePixel = 0; mainOuter.ClipsDescendants = true
    mkCorner(mainOuter, 24); makeDraggable(mainOuter)

    local bgImg = Instance.new("Frame", mainOuter)
    bgImg.Name = "BgFill"; bgImg.Size = UDim2.new(1,0,1,0)
    bgImg.BackgroundColor3 = Color3.fromRGB(6,10,28); bgImg.BorderSizePixel = 0; bgImg.ZIndex = 0
    mkCorner(bgImg, 24)
    local mainGrad = Instance.new("UIGradient", bgImg)
    mainGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10,14,38)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6,10,28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4,6,22))
    })
    mainGrad.Rotation = 90
    local mainStroke = Instance.new("UIStroke", mainOuter)
    mainStroke.Thickness = 1.4; mainStroke.Color = Color3.fromRGB(50,130,240); mainStroke.Transparency = 0.2
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local mainStrokeGrad = Instance.new("UIGradient", mainStroke)
    mainStrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,100,220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50,130,240)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30,100,220))
    })
    task.spawn(function() while mainOuter.Parent do mainStrokeGrad.Rotation = (mainStrokeGrad.Rotation+0.4)%360; RunService.RenderStepped:Wait() end end)

    local accentBar = Instance.new("Frame", mainOuter)
    accentBar.Size = UDim2.new(1, -60, 0, 1); accentBar.Position = UDim2.new(0,30,0,0)
    accentBar.BackgroundColor3 = Color3.fromRGB(50,130,240); accentBar.BackgroundTransparency = 0.85
    accentBar.BorderSizePixel = 0; accentBar.ZIndex = 2

    -- TITLE BAR
    local titleBar = Instance.new("Frame", mainOuter)
    titleBar.Size = UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundColor3 = C.topBg
    titleBar.BackgroundTransparency = 1; titleBar.BorderSizePixel = 0; titleBar.ZIndex = 5

    local avatarBg = Instance.new("Frame", titleBar)
    avatarBg.Size = UDim2.new(0,32,0,32); avatarBg.Position = UDim2.new(0,12,0.5,-16)
    avatarBg.BackgroundColor3 = Color3.fromRGB(8,14,10); avatarBg.BorderSizePixel = 0; avatarBg.ZIndex = 6
    mkCorner(avatarBg,16); mkStroke(avatarBg, Color3.fromRGB(50,130,240), 1.5).Transparency = 0.25
    local avatarImg = Instance.new("ImageLabel", avatarBg)
    avatarImg.Size = UDim2.new(1,-4,1,-4); avatarImg.Position = UDim2.new(0,2,0,2)
    avatarImg.BackgroundTransparency = 1; avatarImg.Image = ""; avatarImg.ScaleType = Enum.ScaleType.Crop
    avatarImg.ZIndex = 7; mkCorner(avatarImg,14)
    task.spawn(function()
        local ok,thumb = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
        if ok and thumb then avatarImg.Image = thumb end
    end)
    LP.CharacterAdded:Connect(function()
        task.spawn(function()
            local ok,thumb = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
            if ok and thumb then avatarImg.Image = thumb end
        end)
    end)

    local titleLbl = Instance.new("TextLabel", titleBar)
    titleLbl.Size = UDim2.new(0,160,0,16); titleLbl.Position = UDim2.new(0,50,0,7)
    titleLbl.BackgroundTransparency = 1; titleLbl.Text = "Larp Duels"
    titleLbl.TextColor3 = C.topTitle; titleLbl.Font = Enum.Font.GothamBlack; titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 6

    local subTitleLbl = Instance.new("TextLabel", titleBar)
    subTitleLbl.Size = UDim2.new(0,160,0,11); subTitleLbl.Position = UDim2.new(0,50,0,24)
    subTitleLbl.BackgroundTransparency = 1; subTitleLbl.Text = "powered by luck 🎭"
    subTitleLbl.TextColor3 = C.topSub; subTitleLbl.Font = Enum.Font.GothamMedium; subTitleLbl.TextSize = 10
    subTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; subTitleLbl.ZIndex = 6

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0,26,0,26); closeBtn.Position = UDim2.new(1,-36,0.5,-13)
    closeBtn.BackgroundColor3 = C.modeBtnBg; closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"; closeBtn.TextColor3 = C.topBtn; closeBtn.Font = Enum.Font.GothamBlack; closeBtn.TextSize = 18
    closeBtn.ZIndex = 7; mkCorner(closeBtn,6); mkStroke(closeBtn, C.chipBorder,1)
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.1), {TextColor3=Color3.fromRGB(220,80,80)}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.1), {TextColor3=C.topBtn}):Play() end)
    closeBtn.MouseButton1Click:Connect(function()
        State.guiVisible = false; mainOuter.Visible = false
        if _G.LarpDuelsQAHide then pcall(_G.LarpDuelsQAHide, true) end
        requestSave()
    end)

    local titleDiv = Instance.new("Frame", mainOuter)
    titleDiv.Size = UDim2.new(1,0,0,1); titleDiv.Position = UDim2.new(0,0,0,TITLE_H)
    titleDiv.BackgroundColor3 = C.topDivider; titleDiv.BorderSizePixel = 0; titleDiv.ZIndex = 5

    -- CONTENT AREA
    local CONTENT_Y = TITLE_H + 1
    local contentBg = Instance.new("Frame", mainOuter)
    contentBg.Size = UDim2.new(1,0,1,-CONTENT_Y); contentBg.Position = UDim2.new(0,0,0,CONTENT_Y)
    contentBg.BackgroundColor3 = C.winBg2; contentBg.BackgroundTransparency = 0
    contentBg.BorderSizePixel = 0; contentBg.ClipsDescendants = true; contentBg.ZIndex = 2

    local mainScroll = Instance.new("ScrollingFrame", contentBg)
    mainScroll.Name = "MainScroll"; mainScroll.Size = UDim2.new(1,0,1,0)
    mainScroll.BackgroundTransparency = 1; mainScroll.BorderSizePixel = 0
    mainScroll.ScrollBarThickness = 3; mainScroll.ScrollBarImageColor3 = C.accent
    mainScroll.ScrollBarImageTransparency = 0.4; mainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    mainScroll.CanvasSize = UDim2.new(0,0,0,0); mainScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    mainScroll.ZIndex = 3

    local mainLL = Instance.new("UIListLayout", mainScroll)
    mainLL.SortOrder = Enum.SortOrder.LayoutOrder; mainLL.Padding = UDim.new(0,4)
    mainLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local mainPad = Instance.new("UIPadding", mainScroll)
    mainPad.PaddingLeft = UDim.new(0,8); mainPad.PaddingRight = UDim.new(0,8)
    mainPad.PaddingTop = UDim.new(0,6); mainPad.PaddingBottom = UDim.new(0,12)

    local TABS = {"Speed", "Combat", "Auto Steal", "Movement", "Visual", "Settings"}
    local tabPages = {}
    local currentPage = nil
    local lo = 0
    local function LO() lo = lo+1; return lo end

    local function makeGap(px) local f=Instance.new("Frame",currentPage); f.Size=UDim2.new(1,0,0,px or 6); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=LO() end
    local function makeSectionHeader(label)
        local wrap = Instance.new("Frame", currentPage)
        wrap.Size = UDim2.new(1,0,0,30); wrap.BackgroundTransparency=1; wrap.BorderSizePixel=0; wrap.LayoutOrder=LO()
        local dot = Instance.new("Frame", wrap); dot.Size = UDim2.new(0,4,0,4); dot.Position = UDim2.new(0,14,0.5,-2)
        dot.BackgroundColor3 = C.accent; dot.BorderSizePixel=0; mkCorner(dot,2)
        local lbl = Instance.new("TextLabel", wrap); lbl.Size = UDim2.new(1,-34,1,0); lbl.Position = UDim2.new(0,24,0,0)
        lbl.BackgroundTransparency=1; lbl.Text = label and label:upper() or ""
        lbl.TextColor3 = C.sectionTxt; lbl.Font = Enum.Font.GothamBold; lbl.TextSize=10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function makeInputRow(label, default, onChange)
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1,-16,0,42); row.BackgroundColor3 = Color3.fromRGB(10,14,36)
        row.BorderSizePixel=0; row.LayoutOrder=LO(); mkCorner(row,12)
        local rowStroke = mkStroke(row, Color3.fromRGB(28,55,130),1); rowStroke.Transparency = 0.5
        row.MouseEnter:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(12,20,48)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(14,22,16)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.5}):Play()
        end)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-100,1,0); lbl.Position = UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.rowLabel
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local boxWrap = Instance.new("Frame", row)
        boxWrap.Size = UDim2.new(0,70,0,28); boxWrap.Position = UDim2.new(1,-82,0.5,-14)
        boxWrap.BackgroundColor3 = Color3.fromRGB(4,6,22); boxWrap.BorderSizePixel=0
        mkCorner(boxWrap,8); local bs = mkStroke(boxWrap, Color3.fromRGB(28,55,130),1); bs.Transparency=0.3
        local box = Instance.new("TextBox", boxWrap)
        box.Size = UDim2.new(1,-8,1,0); box.Position = UDim2.new(0,4,0,0)
        box.BackgroundTransparency=1; box.Text = tostring(default)
        box.TextColor3 = Color3.fromRGB(240,255,245); box.Font = Enum.Font.GothamBlack
        box.TextSize=13; box.ClearTextOnFocus=false; box.ZIndex=8; box.TextXAlignment=Enum.TextXAlignment.Center
        box.Focused:Connect(function() TweenService:Create(bs,TweenInfo.new(0.15),{Color=Color3.fromRGB(50,130,240),Transparency=0}):Play() end)
        box.FocusLost:Connect(function()
            TweenService:Create(bs,TweenInfo.new(0.15),{Color=Color3.fromRGB(28,55,130),Transparency=0.3}):Play()
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
        row.Size = UDim2.new(1,-16,0,42); row.BackgroundColor3 = Color3.fromRGB(10,14,36)
        row.BorderSizePixel=0; row.LayoutOrder=LO(); mkCorner(row,12)
        local rowStroke = mkStroke(row, Color3.fromRGB(28,55,130),1); rowStroke.Transparency = 0.5
        row.MouseEnter:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(12,20,48)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.2}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(14,22,16)}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.1),{Transparency=0.5}):Play()
        end)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-70,1,0); lbl.Position = UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.rowLabel
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local pillBg = Instance.new("Frame", row)
        pillBg.Size = UDim2.new(0,44,0,22); pillBg.Position = UDim2.new(1,-58,0.5,-11)
        pillBg.BackgroundColor3 = defaultOn and Color3.fromRGB(30,132,73) or Color3.fromRGB(20,24,55)
        pillBg.BorderSizePixel=0; pillBg.ZIndex=7; mkCorner(pillBg,11)
        local dot = Instance.new("Frame", pillBg)
        dot.Size = UDim2.new(0,16,0,16); dot.Position = defaultOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
        dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel=0; dot.ZIndex=8; mkCorner(dot,8)
        local isOn = defaultOn or false
        local function setV(on)
            isOn = on
            TweenService:Create(pillBg, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                BackgroundColor3 = on and Color3.fromRGB(30,132,73) or Color3.fromRGB(20,24,55)
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
                Position = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                BackgroundColor3 = Color3.fromRGB(255,255,255)
            }):Play()
        end
        local function toggle()
            isOn = not isOn; setV(isOn)
            if onToggle then pcall(onToggle, isOn) end
            requestSave()
        end
        local clk = Instance.new("TextButton", row); clk.Size = UDim2.new(1,-64,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=5; clk.BorderSizePixel=0; clk.MouseButton1Click:Connect(toggle)
        local pClk = Instance.new("TextButton", pillBg); pClk.Size = UDim2.new(1,0,1,0); pClk.BackgroundTransparency=1; pClk.Text=""; pClk.ZIndex=9; pClk.BorderSizePixel=0; pClk.MouseButton1Click:Connect(toggle)
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
        row.Size = UDim2.new(1,0,0,44); row.BackgroundTransparency=1; row.BorderSizePixel=0; row.LayoutOrder=LO()
        local div = Instance.new("Frame", row); div.Size = UDim2.new(1,-28,0,1); div.Position = UDim2.new(0,14,1,-1)
        div.BackgroundColor3 = C.rowBorder; div.BorderSizePixel=0
        local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1,-80,1,0); lbl.Position = UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.rowLabel; lbl.Font=Enum.Font.GothamBold
        lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local kbtn = Instance.new("TextButton", row); kbtn.Size = UDim2.new(0,52,0,26); kbtn.Position = UDim2.new(1,-64,0.5,-13)
        kbtn.BackgroundColor3 = C.accent; kbtn.BorderSizePixel=0; kbtn.Text = getKeyDisplayName(currentKey)
        kbtn.TextColor3 = Color3.fromRGB(0,20,8); kbtn.Font = Enum.Font.GothamBlack; kbtn.TextSize=11; kbtn.ZIndex=8
        mkCorner(kbtn,13); local ks = mkStroke(kbtn, C.accent,1)
        local listening = false; local lconnKeyboard,lconnGamepad
        local function stopL(key)
            listening = false
            if lconnKeyboard then lconnKeyboard:Disconnect(); lconnKeyboard=nil end
            if lconnGamepad then lconnGamepad:Disconnect(); lconnGamepad=nil end
            TweenService:Create(ks,TweenInfo.new(0.12),{Color=C.accent}):Play()
            TweenService:Create(kbtn,TweenInfo.new(0.12),{BackgroundColor3=C.accent}):Play()
            kbtn.TextColor3 = Color3.fromRGB(0,20,8)
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
            listening = true; kbtn.Text = "···"; kbtn.TextColor3 = Color3.fromRGB(0,30,12)
            TweenService:Create(kbtn,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(80,160,255)}):Play()
            TweenService:Create(ks,TweenInfo.new(0.12),{Color=Color3.fromRGB(80,160,255)}):Play()
            lconnKeyboard = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then stopL(nil); return end
                stopL(inp.KeyCode)
            end)
            lconnGamepad = UIS.InputBegan:Connect(function(inp)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Gamepad1 and inp.UserInputType ~= Enum.UserInputType.Gamepad2 and inp.UserInputType ~= Enum.UserInputType.Gamepad3 and inp.UserInputType ~= Enum.UserInputType.Gamepad4 then return end
                local kc = inp.KeyCode; if kc == Enum.KeyCode.Unknown then return end
                stopL(kc)
            end)
        end)
        if keyName then keybindBtnRefs[keyName] = kbtn end
        return kbtn
    end

    -- ============================================================
    -- PERFORMANCE (Anti-Lag, Stretch, Sky, etc.)
    -- ============================================================
    -- ── Blossom Anti Lag (ported) ────────────────────────────────
    local antiLagDescConn = nil
    local antiLagActive = false
    local antiLagDefBrightness, antiLagDefFog, antiLagDefDiffuse, antiLagDefSpecular

    local function _applyAntiLagObj(obj)
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic; obj.Reflectance = 0; obj.CastShadow = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
            or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
                for _,t in ipairs(obj:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
            end
        end)
    end

    local function enableAntiLag()
        antiLagActive = true
        antiLagDefBrightness = antiLagDefBrightness or Lighting.Brightness
        antiLagDefFog        = antiLagDefFog        or Lighting.FogEnd
        antiLagDefDiffuse    = antiLagDefDiffuse    or Lighting.EnvironmentDiffuseScale
        antiLagDefSpecular   = antiLagDefSpecular   or Lighting.EnvironmentSpecularScale
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        for _,e in pairs(Lighting:GetChildren()) do
            pcall(function()
                if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect")
                or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled = false end
            end)
        end
        for _,obj in ipairs(workspace:GetDescendants()) do _applyAntiLagObj(obj) end
        if antiLagDescConn then antiLagDescConn:Disconnect() end
        antiLagDescConn = workspace.DescendantAdded:Connect(function(obj)
            if antiLagActive then _applyAntiLagObj(obj) end
        end)
    end

    local function disableAntiLag()
        antiLagActive = false
        if antiLagDescConn then antiLagDescConn:Disconnect(); antiLagDescConn = nil end
        pcall(function()
            Lighting.GlobalShadows = true
            if antiLagDefBrightness then Lighting.Brightness = antiLagDefBrightness end
            if antiLagDefFog        then Lighting.FogEnd = antiLagDefFog end
            if antiLagDefDiffuse    then Lighting.EnvironmentDiffuseScale = antiLagDefDiffuse end
            if antiLagDefSpecular   then Lighting.EnvironmentSpecularScale = antiLagDefSpecular end
            for _,e in pairs(Lighting:GetChildren()) do
                pcall(function()
                    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect")
                    or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled = true end
                end)
            end
        end)
    end
    -- ── End Blossom Anti Lag ──────────────────────────────────────
    local stretchRezEnabled=false
    local stretchRezConn,stretchFovConn=nil,nil
    local function applyStretchFOV(val) local cam=Workspace.CurrentCamera; if cam then pcall(function() cam.FieldOfView=val end) end end
    local function enableStretchRez()
        stretchRezEnabled=true; local cam=Workspace.CurrentCamera; if not cam then return end
        if stretchRezConn then stretchRezConn:Disconnect() end
        if stretchFovConn then stretchFovConn:Disconnect() end
        stretchFovConn = RunService.RenderStepped:Connect(function() if stretchRezEnabled then applyStretchFOV(State.stretchFOV) end end)
        stretchRezConn = RunService.RenderStepped:Connect(function()
            if not stretchRezEnabled then stretchRezConn:Disconnect(); stretchRezConn=nil; return end
            if cam then cam.CFrame = cam.CFrame * CFrame.new(0,0,0,1,0,0,0,0.7,0,0,0,1) end
        end)
    end
    local function disableStretchRez()
        stretchRezEnabled=false
        if stretchRezConn then stretchRezConn:Disconnect(); stretchRezConn=nil end
        if stretchFovConn then stretchFovConn:Disconnect(); stretchFovConn=nil end
        pcall(function() Workspace.CurrentCamera.FieldOfView = 70 end)
    end
    local function cleanParticlesAndLights()
        local removed=0
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                pcall(function() obj:Destroy() end); removed=removed+1
            end
        end
        if _G._VezyFlashSave then _G._VezyFlashSave(true); task.delay(1.2,function() if _G._VezyFlashSave then _G._VezyFlashSave(false) end end) end
        print("[Larp Duels] Cleaned "..removed.." effects/lights")
    end
    -- Sky/Lighting restore helpers (used by applySky)
    local origLighting = {
        Ambient = Lighting.Ambient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
        FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
    local activeColorCorr = nil
    local function clearColorCorr() if activeColorCorr then pcall(function() activeColorCorr:Destroy() end); activeColorCorr=nil end end
    local function restoreLighting()
        clearColorCorr()
        pcall(function()
            Lighting.Ambient = origLighting.Ambient; Lighting.Brightness = origLighting.Brightness
            Lighting.ClockTime = origLighting.ClockTime; Lighting.FogColor = origLighting.FogColor
            Lighting.FogEnd = origLighting.FogEnd; Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.EnvironmentDiffuseScale = origLighting.EnvironmentDiffuseScale
            Lighting.EnvironmentSpecularScale = origLighting.EnvironmentSpecularScale
        end)
    end

    local function applySky(kind)
        if kind==nil or kind=="none" then restoreLighting(); return end
        clearColorCorr(); local cc=Instance.new("ColorCorrectionEffect"); cc.Parent=Lighting; activeColorCorr=cc
        if kind=="blue" then
            Lighting.Ambient=Color3.fromRGB(30,60,120); Lighting.FogColor=Color3.fromRGB(40,80,160)
            cc.TintColor=Color3.fromRGB(140,180,255); cc.Saturation=0.4; cc.Contrast=0.1
        elseif kind=="green" then
            Lighting.Ambient=Color3.fromRGB(40,100,60); Lighting.FogColor=Color3.fromRGB(50,140,80)
            cc.TintColor=Color3.fromRGB(160,255,180); cc.Saturation=0.5; cc.Contrast=0.1
        elseif kind=="night" then
            Lighting.ClockTime=0; Lighting.Brightness=0.2; Lighting.Ambient=Color3.fromRGB(20,20,35)
            cc.TintColor=Color3.fromRGB(180,180,220); cc.Saturation=-0.2; cc.Contrast=0.1
        elseif kind=="day" then
            Lighting.ClockTime=14; Lighting.Brightness=2; Lighting.Ambient=Color3.fromRGB(140,140,140)
            cc.TintColor=Color3.fromRGB(255,255,255); cc.Saturation=0.1; cc.Contrast=0
        end
    end

    -- ============================================================
    -- BUILD PAGES
    -- ============================================================
    local function buildPage(tabName, buildFn)
        local page = Instance.new("Frame", mainScroll)
        page.Name = tabName; page.Size = UDim2.new(1,0,0,0); page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1; page.BorderSizePixel = 0; page.LayoutOrder = 0
        local ll = Instance.new("UIListLayout", page); ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Padding = UDim.new(0,4); ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabPages[tabName] = page
        currentPage = page; lo = 0; buildFn(); currentPage = nil
        return page
    end

    -- Speed Page
    do
        local page = buildPage("Speed", function()
            makeGap(2); makeSectionHeader("Speed Values"); makeGap(2)
            normalBox = makeInputRow("Normal Speed", State.normalSpeed, function(n) if n>0 and n<=500 then State.normalSpeed=n end end)
            carryBox = makeInputRow("Carry Speed", State.carrySpeed, function(n) if n>0 and n<=500 then State.carrySpeed=n end end)
            laggerBox = makeInputRow("Lagger Speed", State.laggerSpeed, function(n) if n>0 and n<=500 then State.laggerSpeed=n end end)
            laggerCarryBox = makeInputRow("Lagger Carry Speed", State.laggerCarrySpeed, function(n) if n>0 and n<=500 then State.laggerCarrySpeed=n end end)
            makeGap(8); makeSectionHeader("Speed Keybinds"); makeGap(2)
            makeKeybindRow("Speed Key (toggles)", Keys.speed, function(k) Keys.speed=k end, "speed")
            makeKeybindRow("Lagger Key (toggles)", Keys.lagger, function(k) Keys.lagger=k end, "lagger")
        end)
        page.LayoutOrder = 1
    end

    -- Combat Page
    do
        local page = buildPage("Combat", function()
            makeGap(2); makeSectionHeader("Bat Aimbot"); makeGap(2)
            setAutoSwing = makeToggleRow("Auto Swing", false, function(on) State.autoSwingEnabled=on end)
            toggleSetters["autoSwing"] = setAutoSwing
            setBatCounter = makeToggleRow("Bat Counter", false, function(on) State.batCounterEnabled=on; if on then startBatCounter() else stopBatCounter() end end)
            toggleSetters["batCounter"] = setBatCounter
            setMedusaCounter = makeToggleRow("Medusa Counter", false, function(on) State.medusaCounterEnabled=on; if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end)
            toggleSetters["medusaCounter"] = setMedusaCounter
            makeKeybindRow("Aimbot Key", Keys.aimbot, function(k) Keys.aimbot=k end, "aimbot")
        end)
        page.LayoutOrder = 2
    end

    -- Auto Steal Page
    do
        local page = buildPage("Auto Steal", function()
            makeGap(2); makeSectionHeader("Insta Grab"); makeGap(2)
            setInstaGrab = makeToggleRow("Auto Steal", true, function(on) Steal.AutoStealEnabled=on; if on then startAutoSteal() else stopAutoSteal() end end)
            toggleSetters["autoSteal"] = setInstaGrab
            makeGap(6); makeSectionHeader("Steal Config"); makeGap(2)
            stealRadBox = makeInputRow("Steal Radius", Steal.StealRadius, function(n) if n then n=math.floor(n); if n>=1 and n<=500 then Steal.StealRadius=n end end end)
            local durBox,_ = makeInputRow("Steal Duration", Steal.StealDuration, function(n) if n then n=math.min(n,10); if n>=0.05 then Steal.StealDuration=n end end end)
            stealDurBox = durBox

        end)
        page.LayoutOrder = 3
    end

    -- Movement Page (simplified Infinite Jump, Auto TP)
    do
        local page = buildPage("Movement", function()
            makeGap(2); makeSectionHeader("Infinite Jump"); makeGap(2)
            setInfJump = makeToggleRow("Infinite Jump", false, function(on) State.infJumpEnabled=on end)
            toggleSetters["infJump"] = setInfJump
            -- No Jump Mode or Jump Height options anymore
            makeGap(8); makeSectionHeader("Defense"); makeGap(2)
            setAntiRag = makeToggleRow("Anti Ragdoll", false, function(on) State.antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
            toggleSetters["antiRagdoll"] = setAntiRag
            makeGap(8); makeSectionHeader("Auto Movement"); makeGap(2)
            makeKeybindRow("Auto Left", Keys.autoLeft, function(k) Keys.autoLeft=k end, "autoLeft")
            makeKeybindRow("Auto Right", Keys.autoRight, function(k) Keys.autoRight=k end, "autoRight")
            makeKeybindRow("Drop Brainrot", Keys.drop, function(k) Keys.drop=k end, "drop")
            makeKeybindRow("TP Down", Keys.tpDown, function(k) Keys.tpDown=k end, "tpDown")
            
            -- Auto TP section
            makeGap(8); makeSectionHeader("Auto TP"); makeGap(2)
            local autoTPToggle = makeToggleRow("Auto TP", State.autoTPEnabled, function(on)
                State.autoTPEnabled = on
                if on then startAutoTP() else stopAutoTP() end
                requestSave()
            end)
            toggleSetters["autoTP"] = autoTPToggle
            autoTPHeightBox = makeInputRow("Auto TP Height", State.autoTPHeight, function(n)
                if n and n >= 2 and n <= 500 then State.autoTPHeight = n end
            end)
            -- Body Lock section
            makeGap(8); makeSectionHeader("Body Lock"); makeGap(2)
            local bodyLockToggle = makeToggleRow("Body Lock (freeze nearest player)", State.bodyLockEnabled, function(on)
                State.bodyLockEnabled = on
                if on then startBodyLock() else stopBodyLock() end
                requestSave()
            end)
            toggleSetters["bodyLock"] = bodyLockToggle
            bodyLockRadBox = makeInputRow("Lock Radius (studs)", State.bodyLockRadius, function(n)
                if n and n >= 1 and n <= 100 then State.bodyLockRadius = n end
            end)
        end)
        page.LayoutOrder = 4
    end

    -- Visual Page (Anti-Lag, Ultra, FPS, Stretch, Sky, Nuke, NoCam, RemoveAcc, CustomFont, Tryard)
    local antiLagSetter, stretchSetter
    local nukeSetter, removeAccSetter, tryardSetter
    do
        local page = buildPage("Visual", function()
            makeGap(2); makeSectionHeader("Performance"); makeGap(2)
            antiLagSetter = makeToggleRow("Anti-Lag (recommended)", State.antiLagEnabled, function(on) State.antiLagEnabled=on; if on then enableAntiLag() else disableAntiLag() end end)
            toggleSetters["antiLag"] = antiLagSetter
            stretchSetter = makeToggleRow("Stretch Rez", State.stretchedResEnabled, function(on) State.stretchedResEnabled=on; if on then enableStretchRez() else disableStretchRez() end end)
            toggleSetters["stretchedRes"] = stretchSetter
            do
                local fovRow = Instance.new("Frame", currentPage); fovRow.Size = UDim2.new(1,-16,0,42); fovRow.BackgroundColor3=Color3.fromRGB(14,22,16); fovRow.BorderSizePixel=0; fovRow.LayoutOrder=LO(); mkCorner(fovRow,12)
                local fovStroke = mkStroke(fovRow, Color3.fromRGB(28,55,130),1); fovStroke.Transparency=0.5
                local fovLabel = Instance.new("TextLabel", fovRow); fovLabel.Size = UDim2.new(0.4,0,1,0); fovLabel.Position = UDim2.new(0,14,0,0); fovLabel.BackgroundTransparency=1; fovLabel.Text="Stretch FOV"; fovLabel.TextColor3=C.rowLabel; fovLabel.Font=Enum.Font.GothamBold; fovLabel.TextSize=13; fovLabel.TextXAlignment=Enum.TextXAlignment.Left
                local btnFrame = Instance.new("Frame", fovRow); btnFrame.Size = UDim2.new(0,150,0,28); btnFrame.Position = UDim2.new(1,-162,0.5,-14); btnFrame.BackgroundTransparency=1
                local function makeFOVBtn(val,x)
                    local btn = Instance.new("TextButton", btnFrame); btn.Size = UDim2.new(0,44,0,28); btn.Position = UDim2.new(0,x,0,0); btn.BackgroundColor3=C.modeBtnBg; btn.BorderSizePixel=0; btn.Text=tostring(val); btn.TextColor3=C.modeBtnTxt; btn.Font=Enum.Font.GothamBold; btn.TextSize=12; mkCorner(btn,6); mkStroke(btn, C.modeBtnBrd,1)
                    if val == State.stretchFOV then btn.BackgroundColor3=C.modeBtnActBg; btn.TextColor3=C.modeBtnActTx end
                    btn.MouseButton1Click:Connect(function()
                        State.stretchFOV=val; if State.stretchedResEnabled then applyStretchFOV(val) end
                        for _,b in pairs(btnFrame:GetChildren()) do if b:IsA("TextButton") then local v=tonumber(b.Text); if v==val then TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.modeBtnActBg,TextColor3=C.modeBtnActTx}):Play() else TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.modeBtnBg,TextColor3=C.modeBtnTxt}):Play() end end end
                        requestSave()
                    end)
                    return btn
                end
                makeFOVBtn(90,0); makeFOVBtn(120,53); makeFOVBtn(180,106)
            end
            local cleanBtnWrap = Instance.new("Frame", currentPage); cleanBtnWrap.Size = UDim2.new(1,-16,0,46); cleanBtnWrap.BackgroundTransparency=1; cleanBtnWrap.LayoutOrder=LO()
            local cleanBtn = Instance.new("TextButton", cleanBtnWrap); cleanBtn.Size = UDim2.new(1,0,0,32); cleanBtn.Position = UDim2.new(0,0,0,7); cleanBtn.BackgroundColor3=C.btnBg; cleanBtn.BorderSizePixel=0; cleanBtn.Text="🧹 Clean Particles & Lights"; cleanBtn.TextColor3=C.btnTxt; cleanBtn.Font=Enum.Font.GothamBold; cleanBtn.TextSize=12; mkCorner(cleanBtn,6); mkStroke(cleanBtn, C.btnBorder,1)
            cleanBtn.MouseEnter:Connect(function() TweenService:Create(cleanBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnHov}):Play() end)
            cleanBtn.MouseLeave:Connect(function() TweenService:Create(cleanBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnBg}):Play() end)
            cleanBtn.MouseButton1Click:Connect(cleanParticlesAndLights)

            makeGap(8); makeSectionHeader("Sky Colors"); makeGap(2)
            local function makeSkyBtn(label,kind)
                local btn = Instance.new("TextButton", currentPage); btn.Size = UDim2.new(1,-16,0,32); btn.BackgroundColor3=C.modeBtnBg; btn.BorderSizePixel=0; btn.Text=label; btn.TextColor3=C.modeBtnTxt; btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.LayoutOrder=LO(); mkCorner(btn,6); mkStroke(btn, C.modeBtnBrd,1)
                if State.activeSky == kind then btn.BackgroundColor3=C.modeBtnActBg; btn.TextColor3=C.modeBtnActTx end
                btn.MouseButton1Click:Connect(function()
                    if State.activeSky == kind then applySky(nil); State.activeSky=nil; for _,b in pairs(currentPage:GetChildren()) do if b:IsA("TextButton") and b~=cleanBtn and b~=cleanBtnWrap then TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.modeBtnBg,TextColor3=C.modeBtnTxt}):Play() end end
                    else applySky(kind); State.activeSky=kind; for _,b in pairs(currentPage:GetChildren()) do if b:IsA("TextButton") and b~=cleanBtn and b~=cleanBtnWrap then local isActive=(b.Text==label); TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=isActive and C.modeBtnActBg or C.modeBtnBg,TextColor3=isActive and C.modeBtnActTx or C.modeBtnTxt}):Play() end end end
                    requestSave()
                end)
                return btn
            end
            makeSkyBtn("Blue Sky","blue"); makeSkyBtn("Green Sky","green"); makeSkyBtn("Night Mode","night"); makeSkyBtn("Day Mode","day")
            makeGap(4)
            local resetSkyBtn = Instance.new("TextButton", currentPage); resetSkyBtn.Size = UDim2.new(1,-16,0,32); resetSkyBtn.BackgroundColor3=Color3.fromRGB(80,25,25); resetSkyBtn.BorderSizePixel=0; resetSkyBtn.Text="Restore Default Lighting"; resetSkyBtn.TextColor3=Color3.fromRGB(255,200,200); resetSkyBtn.Font=Enum.Font.GothamBold; resetSkyBtn.TextSize=11; resetSkyBtn.LayoutOrder=LO(); mkCorner(resetSkyBtn,6); mkStroke(resetSkyBtn, Color3.fromRGB(130,45,45),1)
            resetSkyBtn.MouseEnter:Connect(function() TweenService:Create(resetSkyBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(110,35,35)}):Play() end)
            resetSkyBtn.MouseLeave:Connect(function() TweenService:Create(resetSkyBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(80,25,25)}):Play() end)
            resetSkyBtn.MouseButton1Click:Connect(function()
                applySky(nil); State.activeSky=nil
                for _,b in pairs(currentPage:GetChildren()) do if b:IsA("TextButton") and b~=cleanBtn and b~=cleanBtnWrap and b~=resetSkyBtn then TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=C.modeBtnBg,TextColor3=C.modeBtnTxt}):Play() end end
                requestSave()
            end)

            makeGap(8); makeSectionHeader("Other Visuals"); makeGap(2)
            nukeSetter = makeToggleRow("Nuke Optimizer", false, function(on) State.nukeOpt=on; if on then _G._nukeStart() else _G._nukeStop() end end)
            toggleSetters["nukeOpt"] = nukeSetter
            removeAccSetter = makeToggleRow("Remove Accessories", false, function(on) State.removeAcc=on; if on then _G._removeAccStart() else _G._removeAccStop() end end)
            toggleSetters["removeAcc"] = removeAccSetter
            tryardSetter = makeToggleRow("Tryard Animation Pack", State.tryardAnimEnabled, function(on) State.tryardAnimEnabled=on; if on then startTryardAnim() else stopTryardAnim() end end)
            toggleSetters["tryardAnim"] = tryardSetter
            _G._VezyFOV = _G._VezyFOV or 70
            makeInputRow("FOV (normal)", _G._VezyFOV, function(n) if n>=70 and n<=180 then _G._VezyFOV=n; local cam=workspace.CurrentCamera; if cam and not State.stretchedResEnabled then pcall(function() cam.FieldOfView=n end) end end end)
        end)
        page.LayoutOrder = 5
    end

    -- Settings Page
    local introSetter, hideButtonsSetter, lockButtonsSetter
    do
        local page = buildPage("Settings", function()
            makeGap(2); makeSectionHeader("Interface"); makeGap(2)
            makeKeybindRow("Hide GUI", Keys.guiHide, function(k) Keys.guiHide=k end, "guiHide")
            uiScaleBox = makeInputRow("UI Scale", 1.0, function(n) if n>=0.5 and n<=2.0 then if uiScaleObj then uiScaleObj.Scale=n end end end)
            hideButtonsSetter = makeToggleRow("Hide Buttons", false, function(on) State.stackButtonsHidden=on; for _,wrapper in pairs(stackWrappers) do wrapper.Visible=not on end end)
            toggleSetters["hideButtons"] = hideButtonsSetter
            lockButtonsSetter = makeToggleRow("Lock Buttons", false, function(on) State.stackButtonsLocked=on end)
            toggleSetters["lockButtons"] = lockButtonsSetter
            introSetter = makeToggleRow("Show Intro Animation", State.introEnabled, function(on) State.introEnabled=on; requestSave() end)
            toggleSetters["introEnabled"] = introSetter
            makeGap(8); makeSectionHeader("Config"); makeGap(2)
            local saveWrap = Instance.new("Frame", currentPage); saveWrap.Size = UDim2.new(1,0,0,46); saveWrap.BackgroundTransparency=1; saveWrap.BorderSizePixel=0; saveWrap.LayoutOrder=LO()
            local saveBtn = Instance.new("TextButton", saveWrap); saveBtn.Size = UDim2.new(1,-28,0,32); saveBtn.Position = UDim2.new(0,14,0,7); saveBtn.BackgroundColor3=C.accent; saveBtn.BorderSizePixel=0; saveBtn.Text="💾  Save Config Now"; saveBtn.TextColor3=Color3.fromRGB(0,20,8); saveBtn.Font=Enum.Font.GothamBold; saveBtn.TextSize=12; saveBtn.ZIndex=5; mkCorner(saveBtn,6); mkStroke(saveBtn, C.accent,1)
            saveBtn.MouseEnter:Connect(function() TweenService:Create(saveBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(46,160,90)}):Play() end)
            saveBtn.MouseLeave:Connect(function() TweenService:Create(saveBtn,TweenInfo.new(0.1),{BackgroundColor3=C.accent}):Play() end)
            saveBtn.MouseButton1Click:Connect(function()
                local success = pcall(saveConfig)
                if success then saveBtn.Text="✓  Saved!"; saveBtn.BackgroundColor3=Color3.fromRGB(46,180,100) else saveBtn.Text="✗  Save Failed"; saveBtn.BackgroundColor3=Color3.fromRGB(180,60,60) end
                task.delay(2.5,function() if saveBtn and saveBtn.Parent then saveBtn.Text="💾  Save Config Now"; saveBtn.BackgroundColor3=C.accent end end)
            end)
            local resetWrap = Instance.new("Frame", currentPage); resetWrap.Size = UDim2.new(1,0,0,46); resetWrap.BackgroundTransparency=1; resetWrap.BorderSizePixel=0; resetWrap.LayoutOrder=LO()
            local resetAllBtn = Instance.new("TextButton", resetWrap); resetAllBtn.Size = UDim2.new(1,-28,0,32); resetAllBtn.Position = UDim2.new(0,14,0,7); resetAllBtn.BackgroundColor3=Color3.fromRGB(80,25,25); resetAllBtn.BorderSizePixel=0; resetAllBtn.Text="⚠  Reset All Settings"; resetAllBtn.TextColor3=Color3.fromRGB(255,200,200); resetAllBtn.Font=Enum.Font.GothamBold; resetAllBtn.TextSize=12; resetAllBtn.ZIndex=5; mkCorner(resetAllBtn,6); mkStroke(resetAllBtn, Color3.fromRGB(130,45,45),1)
            resetAllBtn.MouseEnter:Connect(function() TweenService:Create(resetAllBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(110,35,35)}):Play() end)
            resetAllBtn.MouseLeave:Connect(function() TweenService:Create(resetAllBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(80,25,25)}):Play() end)
            local _resetConfirmStage=0; local _resetConfirmTimer=nil
            resetAllBtn.MouseButton1Click:Connect(function()
                if _resetConfirmStage==0 then
                    _resetConfirmStage=1; resetAllBtn.Text="⚠  Click again to confirm!"; resetAllBtn.BackgroundColor3=Color3.fromRGB(160,50,50)
                    if _resetConfirmTimer then task.cancel(_resetConfirmTimer) end
                    _resetConfirmTimer = task.delay(3,function() if resetAllBtn and resetAllBtn.Parent then _resetConfirmStage=0; resetAllBtn.Text="⚠  Reset All Settings"; resetAllBtn.BackgroundColor3=Color3.fromRGB(80,25,25) end end)
                    return
                end
                _resetConfirmStage=0; if _resetConfirmTimer then task.cancel(_resetConfirmTimer); _resetConfirmTimer=nil end
                -- Full reset (includes autoTP)
                pcall(function() if State.batAimbotToggled then stopBatAimbot() end end)
                pcall(function() if State.batV2Toggled then stopBatV2() end end)
                pcall(function() if State.batCounterEnabled then stopBatCounter() end end)
                pcall(function() if State.medusaCounterEnabled then stopMedusaCounter() end end)
                pcall(function() if State.antiRagdollEnabled then stopAntiRagdoll() end end)
                pcall(function() if Steal.AutoStealEnabled then stopAutoSteal() end end)
                pcall(function() if State.autoLeftEnabled then stopAutoLeft() end end)
                pcall(function() if State.autoRightEnabled then stopAutoRight() end end)
                pcall(function() if State.antiLagEnabled then disableAntiLag() end end)
                pcall(function() if State.stretchedResEnabled then disableStretchRez() end end)
                pcall(function() if State.autoTPEnabled then stopAutoTP() end end)
                pcall(function() if _G._NukeOn and _G._nukeStop then _G._nukeStop() end end)
                                pcall(function() if _G._RemoveAccOn and _G._removeAccStop then _G._removeAccStop() end end)
                                applySky(nil)
                State.normalSpeed=60; State.carrySpeed=30; State.laggerSpeed=10.1; State.laggerCarrySpeed=15
                State.speedToggled=false; State.laggerMode=0; State.infJumpEnabled=false; State.antiRagdollEnabled=false
                State.antiLagEnabled=false; State.stretchedResEnabled=false
                State.stretchFOV=120; State.activeSky=nil; State.medusaCounterEnabled=false; State.batCounterEnabled=false
                State.batAimbotToggled=false; State.autoSwingEnabled=false; State.autoLeftEnabled=false; State.autoRightEnabled=false; State.batV2Toggled=false
                State.stackButtonsHidden=false; State.stackButtonsLocked=false; State.introEnabled=true
                State.autoTPEnabled=false; State.autoTPHeight=20
                State.bodyLockEnabled=false; State.bodyLockRadius=5; stopBodyLock()
                Steal.StealRadius=55; Steal.StealDuration=0.25; Steal.AutoStealEnabled=true
                Keys.speed=Enum.KeyCode.Q; Keys.guiHide=Enum.KeyCode.LeftControl; Keys.autoLeft=Enum.KeyCode.L; Keys.autoRight=Enum.KeyCode.R
                Keys.lagger=Enum.KeyCode.Unknown; Keys.tpDown=Enum.KeyCode.Unknown; Keys.drop=Enum.KeyCode.H; Keys.aimbot=Enum.KeyCode.Unknown
                if normalBox then normalBox.Text=tostring(State.normalSpeed) end; if carryBox then carryBox.Text=tostring(State.carrySpeed) end
                if laggerBox then laggerBox.Text=tostring(State.laggerSpeed) end; if laggerCarryBox then laggerCarryBox.Text=tostring(State.laggerCarrySpeed) end
                if stealRadBox then stealRadBox.Text=tostring(Steal.StealRadius) end; if stealDurBox then stealDurBox.Text=tostring(Steal.StealDuration) end
                if uiScaleObj then uiScaleObj.Scale=1.0 end; if uiScaleBox then uiScaleBox.Text="1" end
                if setInstaGrab then pcall(setInstaGrab,true) end; if setInfJump then pcall(setInfJump,false) end; if setAntiRag then pcall(setAntiRag,false) end
                if setMedusaCounter then pcall(setMedusaCounter,false) end; if setBatCounter then pcall(setBatCounter,false) end; if setAutoSwing then pcall(setAutoSwing,false) end
                if hideButtonsSetter then pcall(hideButtonsSetter,false) end; if lockButtonsSetter then pcall(lockButtonsSetter,false) end
                if introSetter then pcall(introSetter,true) end
                if stackBtnRefs then for key,ref in pairs(stackBtnRefs) do if ref and ref.setOn then pcall(ref.setOn,false) end end end
                if keybindBtnRefs then refreshAllKeybindButtons() end
                for i,def in ipairs(stackDefs) do local wrapper=stackWrappers[def.key]; if wrapper then TweenService:Create(wrapper,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=getDefaultStackPos(i)}):Play() end end
                resetAllBtn.Text="✓  All Settings Reset!"; resetAllBtn.BackgroundColor3=Color3.fromRGB(50,130,240)
                task.delay(2,function() if resetAllBtn and resetAllBtn.Parent then resetAllBtn.Text="⚠  Reset All Settings"; resetAllBtn.BackgroundColor3=Color3.fromRGB(80,25,25) end end)
            end)
            makeGap(8); makeSectionHeader("Layout"); makeGap(2)
            local rWrap = Instance.new("Frame", currentPage); rWrap.Size = UDim2.new(1,0,0,46); rWrap.BackgroundTransparency=1; rWrap.BorderSizePixel=0; rWrap.LayoutOrder=LO()
            local resetBtn = Instance.new("TextButton", rWrap); resetBtn.Size = UDim2.new(1,-28,0,32); resetBtn.Position = UDim2.new(0,14,0,7); resetBtn.BackgroundColor3=C.btnBg; resetBtn.BorderSizePixel=0; resetBtn.Text="↺  Reset Button Positions"; resetBtn.TextColor3=C.btnTxt; resetBtn.Font=Enum.Font.GothamBold; resetBtn.TextSize=12; resetBtn.ZIndex=5; mkCorner(resetBtn,6); mkStroke(resetBtn, C.btnBorder,1)
            resetBtn.MouseEnter:Connect(function() TweenService:Create(resetBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnHov}):Play() end)
            resetBtn.MouseLeave:Connect(function() TweenService:Create(resetBtn,TweenInfo.new(0.1),{BackgroundColor3=C.btnBg}):Play() end)
            resetBtn.MouseButton1Click:Connect(function()
                for i,def in ipairs(stackDefs) do local wrapper=stackWrappers[def.key]; if wrapper then TweenService:Create(wrapper,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=getDefaultStackPos(i)}):Play() end end
                resetBtn.Text="✓  Positions Reset!"; task.delay(1.8,function() if resetBtn and resetBtn.Parent then resetBtn.Text="↺  Reset Button Positions" end end)
            end)
            makeGap(10)
            local fw = Instance.new("Frame", currentPage); fw.Size = UDim2.new(1,0,0,22); fw.BackgroundTransparency=1; fw.BorderSizePixel=0; fw.LayoutOrder=LO()
            local fl = Instance.new("TextLabel", fw); fl.Size = UDim2.new(1,0,1,0); fl.BackgroundTransparency=1; fl.Text="Larp Duels  ·  powered by luck 🍀"; fl.TextColor3=Color3.fromRGB(50,100,65); fl.Font=Enum.Font.Gotham; fl.TextSize=10; fl.TextXAlignment=Enum.TextXAlignment.Center
            _G._VezySaveStatusLbl = fl
            _G._VezyFlashSave = function(success)
                if not _G._VezySaveStatusLbl or not _G._VezySaveStatusLbl.Parent then return end
                local lbl = _G._VezySaveStatusLbl
                if success then lbl.Text="✓  Auto-saved"; lbl.TextColor3=Color3.fromRGB(60,160,255)
                else lbl.Text="✗  Save failed"; lbl.TextColor3=Color3.fromRGB(220,80,80) end
                task.delay(1.5,function() if lbl and lbl.Parent then lbl.Text="Larp Duels  ·  powered by luck 🍀"; lbl.TextColor3=Color3.fromRGB(60,100,200) end end)
            end
        end)
        page.LayoutOrder = 6
    end

    rebuildPresetList = function()
        if not presetListFrame then return end
        for _,child in ipairs(presetListFrame:GetChildren()) do if child.Name~="EmptyLabel" and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end end
        local emptyLbl = presetListFrame:FindFirstChild("EmptyLabel")
        if emptyLbl then emptyLbl.Visible = (#Presets == 0) end
        for i,preset in ipairs(Presets) do
            local row = Instance.new("Frame", presetListFrame); row.Name="Preset_"..i; row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C.presetBg; row.BorderSizePixel=0; row.LayoutOrder=i+1; mkCorner(row,6); mkStroke(row, C.presetBrd,1)
            local nameLbl = Instance.new("TextLabel", row); nameLbl.Size=UDim2.new(1,-94,1,0); nameLbl.Position=UDim2.new(0,10,0,0); nameLbl.BackgroundTransparency=1; nameLbl.Text=preset.name; nameLbl.TextColor3=C.rowLabel; nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=12; nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd
            local loadBtn = Instance.new("TextButton", row); loadBtn.Size=UDim2.new(0,44,0,26); loadBtn.Position=UDim2.new(1,-96,0.5,-13); loadBtn.BackgroundColor3=C.presetLoad; loadBtn.BorderSizePixel=0; loadBtn.Text="Load"; loadBtn.TextColor3=Color3.fromRGB(240,255,245); loadBtn.Font=Enum.Font.GothamBold; loadBtn.TextSize=11; loadBtn.ZIndex=9; mkCorner(loadBtn,5)
            loadBtn.MouseEnter:Connect(function() TweenService:Create(loadBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,200,100)}):Play() end)
            loadBtn.MouseLeave:Connect(function() TweenService:Create(loadBtn,TweenInfo.new(0.1),{BackgroundColor3=C.presetLoad}):Play() end)
            loadBtn.MouseButton1Click:Connect(function()
                saveLastPresetName(preset.name); loadBtn.Text="✓"; task.delay(1.2,function() if loadBtn and loadBtn.Parent then loadBtn.Text="Load" end end)
            end)
            local delBtn = Instance.new("TextButton", row); delBtn.Size=UDim2.new(0,34,0,26); delBtn.Position=UDim2.new(1,-48,0.5,-13); delBtn.BackgroundColor3=C.presetDel; delBtn.BorderSizePixel=0; delBtn.Text="✕"; delBtn.TextColor3=Color3.fromRGB(200,80,80); delBtn.Font=Enum.Font.GothamBold; delBtn.TextSize=11; delBtn.ZIndex=9; mkCorner(delBtn,5)
            delBtn.MouseEnter:Connect(function() TweenService:Create(delBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(80,28,28)}):Play() end)
            delBtn.MouseLeave:Connect(function() TweenService:Create(delBtn,TweenInfo.new(0.1),{BackgroundColor3=C.presetDel}):Play() end)
            delBtn.MouseButton1Click:Connect(function()
                table.remove(Presets,i); savePresetsFile(); rebuildPresetList()
            end)
        end
    end

    -- ============================================================
    -- INFO BAR (auto-grab style draggable bar)
    -- ============================================================
    local infoBar = Instance.new("Frame", gui)
    infoBar.Name = "AutoStealBar"
    infoBar.Size = UDim2.new(0,320,0,36); infoBar.Position = UDim2.new(0.5,-160,0.88,-18)
    infoBar.AnchorPoint = Vector2.new(0.5,0.5)
    infoBar.BackgroundColor3 = Color3.fromRGB(6,8,24); infoBar.BorderSizePixel=0; infoBar.Active=true
    mkCorner(infoBar,18); mkStroke(infoBar, Color3.fromRGB(60,160,255), 2)

    -- Drag handle
    local _ibDragHandle = Instance.new("Frame", infoBar)
    _ibDragHandle.Size = UDim2.new(1,0,1,0); _ibDragHandle.BackgroundTransparency=1

    -- Progress track
    local progressBg = Instance.new("Frame", infoBar)
    progressBg.Name = "ProgressTrack"
    progressBg.Size = UDim2.new(0,140,0,24); progressBg.Position = UDim2.new(0,6,0.5,0)
    progressBg.AnchorPoint = Vector2.new(0,0.5)
    progressBg.BackgroundColor3 = Color3.fromRGB(14,20,38); progressBg.BorderSizePixel=0; progressBg.ClipsDescendants=true
    Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0.5,0)

    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0,0,1,0); progressFill.BackgroundColor3 = Color3.fromRGB(60,160,255)
    progressFill.BorderSizePixel=0; Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0.5,0)

    local stealTextLbl = Instance.new("TextLabel", progressBg)
    stealTextLbl.Size = UDim2.new(0,50,1,0); stealTextLbl.Position = UDim2.new(0,8,0,0)
    stealTextLbl.BackgroundTransparency=1; stealTextLbl.Text="STEAL"; stealTextLbl.TextColor3=Color3.fromRGB(130,200,255)
    stealTextLbl.Font = Enum.Font.GothamBlack; stealTextLbl.TextSize=11
    stealTextLbl.TextXAlignment=Enum.TextXAlignment.Left; stealTextLbl.ZIndex=5

    local stealPctLbl = Instance.new("TextLabel", progressBg)
    stealPctLbl.Size = UDim2.new(0,30,1,0); stealPctLbl.Position = UDim2.new(1,-6,0,0)
    stealPctLbl.AnchorPoint = Vector2.new(1,0)
    stealPctLbl.BackgroundTransparency=1; stealPctLbl.Text="0%"; stealPctLbl.TextColor3=Color3.fromRGB(60,160,255)
    stealPctLbl.Font = Enum.Font.GothamBlack; stealPctLbl.TextSize=11
    stealPctLbl.TextXAlignment=Enum.TextXAlignment.Right; stealPctLbl.ZIndex=5

    -- FPS label
    local fpsVal = Instance.new("TextLabel", infoBar)
    fpsVal.Size = UDim2.new(0,50,1,0); fpsVal.Position = UDim2.new(0,156,0,0)
    fpsVal.BackgroundTransparency=1; fpsVal.Text="FPS:0"; fpsVal.TextColor3=Color3.fromRGB(240,245,245)
    fpsVal.Font = Enum.Font.GothamBold; fpsVal.TextSize=11; fpsVal.TextXAlignment=Enum.TextXAlignment.Left

    -- Ping emoji + label
    local pingIcon = Instance.new("TextLabel", infoBar)
    pingIcon.Size = UDim2.new(0,14,0,14); pingIcon.Position = UDim2.new(0,216,0.5,0)
    pingIcon.AnchorPoint = Vector2.new(0,0.5)
    pingIcon.BackgroundTransparency=1; pingIcon.Text="📡"; pingIcon.TextSize=11

    local pingVal = Instance.new("TextLabel", infoBar)
    pingVal.Size = UDim2.new(0,45,1,0); pingVal.Position = UDim2.new(0,234,0,0)
    pingVal.BackgroundTransparency=1; pingVal.Text="0ms"; pingVal.TextColor3=Color3.fromRGB(240,245,245)
    pingVal.Font = Enum.Font.GothamBold; pingVal.TextSize=11; pingVal.TextXAlignment=Enum.TextXAlignment.Left

    -- Status dot
    local statusDotBg = Instance.new("Frame", infoBar)
    statusDotBg.Size = UDim2.new(0,24,0,24); statusDotBg.Position = UDim2.new(1,-6,0.5,0)
    statusDotBg.AnchorPoint = Vector2.new(1,0.5)
    statusDotBg.BackgroundColor3 = Color3.fromRGB(6,8,24); statusDotBg.BorderSizePixel=0
    mkCorner(statusDotBg,12); mkStroke(statusDotBg, Color3.fromRGB(60,160,255), 2)

    local statusDot = Instance.new("Frame", statusDotBg)
    statusDot.Size = UDim2.new(0,10,0,10); statusDot.Position = UDim2.new(0.5,0,0.5,0)
    statusDot.AnchorPoint = Vector2.new(0.5,0.5)
    statusDot.BackgroundColor3 = Color3.fromRGB(60,160,255); statusDot.BorderSizePixel=0; mkCorner(statusDot,5)

    -- Dragging logic
    local _ibDragToggle, _ibDragStart, _ibStartPos = false, nil, nil
    _ibDragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            _ibDragToggle = true; _ibDragStart = input.Position; _ibStartPos = infoBar.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then _ibDragToggle = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if _ibDragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - _ibDragStart
            infoBar.Position = UDim2.new(_ibStartPos.X.Scale, _ibStartPos.X.Offset+delta.X, _ibStartPos.Y.Scale, _ibStartPos.Y.Offset+delta.Y)
        end
    end)

    -- FPS counter
    local _frameCount, _lastTick = 0, tick()
    RunService.RenderStepped:Connect(function()
        _frameCount = _frameCount + 1
        local now = tick()
        if now - _lastTick >= 1 then
            fpsVal.Text = "FPS:" .. math.floor(_frameCount / (now - _lastTick))
            _frameCount = 0; _lastTick = now
        end
    end)

    -- Ping + status updater
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local ping = 0
                local net = Stats:FindFirstChild("Network")
                if net then
                    local sci = net:FindFirstChild("ServerStatsItem")
                    if sci then local dp = sci:FindFirstChild("Data Ping"); if dp then ping = math.floor(dp:GetValue() or 0) end end
                end
                if pingVal then pingVal.Text = ping.."ms" end
                if statusDot then statusDot.BackgroundColor3 = State.isStealing and Color3.fromRGB(80,180,255) or Color3.fromRGB(60,160,255) end
            end)
        end
    end)

    -- ============================================================
    -- STACK BUTTONS (unchanged)
    -- ============================================================
    local function updateLaggerButtons()
        if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerMode==1) end
        if stackBtnRefs.laggerCarry then stackBtnRefs.laggerCarry.setOn(State.laggerMode==2) end
    end
    local function setLaggerMode(mode)
        if mode==State.laggerMode then return end
        local oldMode = State.laggerMode
        State.laggerMode = mode
        if mode==0 then
            State.carrySpeed = State._prevCarry or 30
            State.speedToggled = State._prevSpeed or false
            if carryBox then carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed) end
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        elseif mode==1 then
            if oldMode==0 then State._prevCarry, State._prevSpeed = State.carrySpeed, State.speedToggled end
            State.speedToggled = false
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
            if carryBox then carryBox.Text = tostring(State.laggerSpeed) end
        elseif mode==2 then
            if oldMode==0 then State._prevCarry, State._prevSpeed = State.carrySpeed, State.speedToggled end
            State.speedToggled = false
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
            if carryBox then carryBox.Text = tostring(State.laggerCarrySpeed) end
        end
        updateLaggerButtons()
        requestSave()
    end
    local function toggleLaggerMode()
        if State.laggerMode==0 then setLaggerMode(1)
        elseif State.laggerMode==1 then setLaggerMode(2)
        else setLaggerMode(1) end
    end
    local function toggleSpeed()
        if State.laggerMode~=0 then setLaggerMode(0) end
        State.speedToggled = not State.speedToggled
        if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        if carryBox then carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed) end
        requestSave()
    end

    for i,def in ipairs(stackDefs) do
        -- Blossom-style: single TextButton, square, no dot, GothamBold sz11 lineheight 1.2
        local btnFrame = Instance.new("TextButton", gui)
        btnFrame.Name = "StackBtn_"..def.key
        btnFrame.Size = UDim2.new(0,BTN_W,0,BTN_H)
        btnFrame.Position = getDefaultStackPos(i)
        btnFrame.BackgroundColor3 = C.stackBg; btnFrame.BorderSizePixel=0
        btnFrame.AutoButtonColor = false
        btnFrame.Text = def.label; btnFrame.TextColor3 = C.stackTxt
        btnFrame.TextScaled = false; btnFrame.TextSize = 11
        btnFrame.Font = Enum.Font.GothamBold
        btnFrame.TextWrapped = true; btnFrame.LineHeight = 1.2
        btnFrame.ZIndex=15
        mkCorner(btnFrame,12)
        local bStroke = mkStroke(btnFrame, C.stackBrd, 1)
        stackWrappers[def.key] = btnFrame

        local btnState = false
        local function setOn(on)
            btnState = on
            TweenService:Create(btnFrame,TweenInfo.new(0.15),{BackgroundColor3=on and C.stackActBg or C.stackBg, TextColor3=on and C.stackActTxt or C.stackTxt}):Play()
            TweenService:Create(bStroke,TweenInfo.new(0.15),{Color=on and C.stackActBrd or C.stackBrd}):Play()
        end
        stackBtnRefs[def.key] = {setOn = setOn}

        local function onTap()
            if def.key == "tpDown" then
                task.spawn(function() if runTPDown then pcall(runTPDown) end; setOn(true); task.wait(0.12); setOn(false) end)
                return
            end
            if def.key == "drop" then
                task.spawn(function() pcall(runDropBrainrot) end)
                return
            end
            if def.key == "carrySpeed" then
                if State.laggerMode~=0 then return end
                State.speedToggled = not State.speedToggled
                setOn(State.speedToggled)
                if carryBox then carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed) end
                requestSave()
                return
            end
            if def.key == "lagger" then
                if State.laggerMode==1 then setLaggerMode(0) else setLaggerMode(1) end
                return
            end
            if def.key == "laggerCarry" then
                if State.laggerMode==2 then setLaggerMode(0) else setLaggerMode(2) end
                return
            end
            local ns = not btnState; setOn(ns)
            if def.key == "autoLeft" then
                State.autoLeftEnabled = ns
                if ns and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
                if ns then startAutoLeft() else stopAutoLeft() end
            elseif def.key == "autoRight" then
                State.autoRightEnabled = ns
                if ns and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
                if ns then startAutoRight() else stopAutoRight() end
            elseif def.key == "aimbot" then
                State.batAimbotToggled = ns
                if ns then
                    if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
                    if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
                    if State.batV2Toggled then State.batV2Toggled=false; stopBatV2(); if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(false) end end
                    pcall(startBatAimbot)
                else stopBatAimbot() end
            elseif def.key == "batV2" then
                State.batV2Toggled = ns
                if ns then
                    if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
                    if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
                    if State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
                    pcall(startBatV2)
                else stopBatV2() end
            end
            requestSave()
        end

        makeStackDraggable(btnFrame, onTap)
    end

    -- ============================================================
    -- AUTO LEFT / RIGHT (BlossomHub-style with facing vectors)
    -- ============================================================
    stopAutoLeft = function()
        if alConn then alConn:Disconnect(); alConn = nil end; alPhase = 1
        local char = LP.Character; if char then local hum2 = char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero, false) end end
        if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
    end
    stopAutoRight = function()
        if arConn then arConn:Disconnect(); arConn = nil end; arPhase = 1
        local char = LP.Character; if char then local hum2 = char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero, false) end end
        if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
    end

    startAutoLeft = function()
        if alConn then alConn:Disconnect() end; alPhase = 1
        alConn = RunService.Heartbeat:Connect(function()
            if not State.autoLeftEnabled then return end
            local char = LP.Character; if not char then return end
            local hrp2 = char:FindFirstChild("HumanoidRootPart")
            local hum2 = char:FindFirstChildOfClass("Humanoid")
            if not hrp2 or not hum2 then return end
            local spd = State.normalSpeed
            if alPhase == 1 then
                local tgt = Vector3.new(AP_L1.X, hrp2.Position.Y, AP_L1.Z)
                if (tgt - hrp2.Position).Magnitude < 1 then
                    alPhase = 2
                    local d = AP_L2 - hrp2.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
                    hum2:Move(mv, false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd); return
                end
                local d = AP_L1 - hrp2.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
            elseif alPhase == 2 then
                local tgt = Vector3.new(AP_L2.X, hrp2.Position.Y, AP_L2.Z)
                if (tgt - hrp2.Position).Magnitude < 1 then
                    hum2:Move(Vector3.zero, false); hrp2.AssemblyLinearVelocity = Vector3.zero
                    State.autoLeftEnabled = false; if alConn then alConn:Disconnect(); alConn = nil end
                    alPhase = 1; if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
                    -- Face the correct direction using BlossomHub facing vector
                    if (AP_L_FACE - hrp2.Position).Magnitude > 0.01 then
                        hrp2.CFrame = CFrame.new(hrp2.Position, Vector3.new(AP_L_FACE.X, hrp2.Position.Y, AP_L_FACE.Z))
                    end
                    return
                end
                local d = AP_L2 - hrp2.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
            end
        end)
    end

    startAutoRight = function()
        if arConn then arConn:Disconnect() end; arPhase = 1
        arConn = RunService.Heartbeat:Connect(function()
            if not State.autoRightEnabled then return end
            local char = LP.Character; if not char then return end
            local hrp2 = char:FindFirstChild("HumanoidRootPart")
            local hum2 = char:FindFirstChildOfClass("Humanoid")
            if not hrp2 or not hum2 then return end
            local spd = State.normalSpeed
            if arPhase == 1 then
                local tgt = Vector3.new(AP_R1.X, hrp2.Position.Y, AP_R1.Z)
                if (tgt - hrp2.Position).Magnitude < 1 then
                    arPhase = 2
                    local d = AP_R2 - hrp2.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
                    hum2:Move(mv, false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd); return
                end
                local d = AP_R1 - hrp2.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
            elseif arPhase == 2 then
                local tgt = Vector3.new(AP_R2.X, hrp2.Position.Y, AP_R2.Z)
                if (tgt - hrp2.Position).Magnitude < 1 then
                    hum2:Move(Vector3.zero, false); hrp2.AssemblyLinearVelocity = Vector3.zero
                    State.autoRightEnabled = false; if arConn then arConn:Disconnect(); arConn = nil end
                    arPhase = 1; if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
                    -- Face the correct direction using BlossomHub facing vector
                    if (AP_R_FACE - hrp2.Position).Magnitude > 0.01 then
                        hrp2.CFrame = CFrame.new(hrp2.Position, Vector3.new(AP_R_FACE.X, hrp2.Position.Y, AP_R_FACE.Z))
                    end
                    return
                end
                local d = AP_R2 - hrp2.Position; local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false); hrp2.AssemblyLinearVelocity = Vector3.new(mv.X*spd, hrp2.AssemblyLinearVelocity.Y, mv.Z*spd)
            end
        end)
    end

    -- ============================================================
    -- HELPER FUNCTIONS (TP, Drop, Aimbot, Counter, Medusa, AntiRagdoll, AutoSteal) - unchanged except countdown timer
    -- ============================================================
    local function resetProgressBar() stealPctLbl.Text="0%"; progressFill.Size=UDim2.new(0,0,1,0) end
    local DROP_ASCEND_DURATION=0.22; local DROP_ASCEND_SPEED=160; local _dropConn=nil
    runDropBrainrot = function()
        if State.dropEnabled then return end
        local char=LP.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        State.dropEnabled=true; if stackBtnRefs.drop then stackBtnRefs.drop.setOn(true) end
        local t0=tick()
        if _dropConn then _dropConn:Disconnect() end
        _dropConn=RunService.Heartbeat:Connect(function()
            local c=LP.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
            if not r then
                if _dropConn then _dropConn:Disconnect(); _dropConn=nil end
                State.dropEnabled=false; if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
                return
            end
            if not State.dropEnabled then
                if _dropConn then _dropConn:Disconnect(); _dropConn=nil end
                if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
                return
            end
            if tick()-t0 >= DROP_ASCEND_DURATION then
                if _dropConn then _dropConn:Disconnect(); _dropConn=nil end
                pcall(function()
                    local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
                    local rr=workspace:Raycast(r.Position, Vector3.new(0,-3000,0), rp)
                    if rr then
                        local hum=c:FindFirstChildOfClass("Humanoid")
                        local off = ((hum and hum.HipHeight) or 2) + (r.Size.Y/2)
                        r.CFrame = CFrame.new(r.Position.X, rr.Position.Y+off, r.Position.Z)
                        r.AssemblyLinearVelocity = Vector3.zero
                    end
                end)
                State.dropEnabled=false; if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
                return
            end
            local lv=r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.new(lv.X, DROP_ASCEND_SPEED, lv.Z)
        end)
    end
    stopDropBrainrot = function()
        State.dropEnabled=false
        if _dropConn then _dropConn:Disconnect(); _dropConn=nil end
        if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
    end

    -- BAT AIMBOT
    local _aimbotTarget=nil
    local function findBat()
        local char=LP.Character; if not char then return nil end
        for _,tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end end
        local bp=LP:FindFirstChild("Backpack"); if bp then for _,tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end end end
        return nil
    end
    local function getClosestTarget()
        local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not root then return nil end
        local closest,minDist=nil,math.huge
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP and plr.Character then
                local tRoot=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                if tRoot and hum and hum.Health>0 then
                    local dist=(tRoot.Position-root.Position).Magnitude
                    if dist<minDist then minDist=dist; closest=tRoot end
                end
            end
        end
        return closest
    end
    startBatAimbot = function()
        if Conns.aimbot then Conns.aimbot:Disconnect() end
        if State.autoLeftEnabled then State.autoLeftEnabled=false; if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end; stopAutoLeft() end
        if State.autoRightEnabled then State.autoRightEnabled=false; if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end; stopAutoRight() end
        local hum0=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum0 then hum0.AutoRotate=false end
        Conns.aimbot = RunService.RenderStepped:Connect(function()
            if not State.batAimbotToggled then return end
            local char=LP.Character; if not char then return end
            local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
            local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            if not char:FindFirstChildOfClass("Tool") then local bat=findBat(); if bat then pcall(function() hum:EquipTool(bat) end) end end
            local target=getClosestTarget(); if not target then return end
            _aimbotTarget=target
            local targetVel=target.AssemblyLinearVelocity
            local myPos=root.Position; local targetPos=target.Position
            local predictPos=targetPos+targetVel*0.14; predictPos=predictPos+target.CFrame.LookVector*0.3
            local direction=predictPos-myPos; local flatDir=Vector3.new(direction.X,0,direction.Z).Unit
            local chaseSpeed=58; local desiredHeight=targetPos.Y+3.7
            local yVel=(desiredHeight-myPos.Y)*19.5+targetVel.Y*0.8
            if hum.FloorMaterial~=Enum.Material.Air then yVel=math.max(yVel,13) end
            yVel=math.clamp(yVel,-70,110)
            local desiredVel=Vector3.new(flatDir.X*chaseSpeed,yVel,flatDir.Z*chaseSpeed)
            root.AssemblyLinearVelocity=root.AssemblyLinearVelocity:Lerp(desiredVel,0.8)
            local speed3=targetVel.Magnitude
            local predictTime=math.clamp(speed3/150,0.05,0.2)
            local predictedPos=targetPos+targetVel*predictTime
            local toPredict=predictedPos-myPos
            if toPredict.Magnitude>0.1 then
                local goalCF=CFrame.lookAt(myPos,predictedPos)
                local diffCF=root.CFrame:Inverse()*goalCF
                local rx,ry,rz=diffCF:ToEulerAnglesXYZ()
                rx=math.clamp(rx,-2.5,2.5); ry=math.clamp(ry,-2.5,2.5); rz=math.clamp(rz,-2.5,2.5)
                root.AssemblyAngularVelocity=root.CFrame:VectorToWorldSpace(Vector3.new(rx*42,ry*42,rz*42))
            end
        end)
    end
    stopBatAimbot = function()
        if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot=nil end
        _aimbotTarget=nil
        local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
        local hum2=c and c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2.AutoRotate=true end
        State.hittingCooldown=false
    end

    -- ============================================================
    -- BAT V2 (bypass aimbot logic)
    -- ============================================================
    local _v2HitCD = false
    local _v2SWING_CD = 0.35
    local _v2HIT_DIST = 8
    local _v2PrevAutoRotate = nil
    local BAT_V2_SLAP_LIST = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

    local function _v2FindBat()
        local char = LP.Character; if not char then return nil end
        for _, name in ipairs(BAT_V2_SLAP_LIST) do
            local t = char:FindFirstChild(name)
            if t and t:IsA("Tool") then return t end
        end
        local bp = LP:FindFirstChildOfClass("Backpack")
        if bp then
            for _, name in ipairs(BAT_V2_SLAP_LIST) do
                local t = bp:FindFirstChild(name)
                if t and t:IsA("Tool") then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:EquipTool(t) end) end
                    return t
                end
            end
        end
        for _, ch in ipairs(char:GetChildren()) do
            if ch:IsA("Tool") and (ch.Name:lower():find("bat") or ch.Name:lower():find("slap")) then return ch end
        end
        return nil
    end

    local function _v2TrySwing()
        if _v2HitCD then return end
        _v2HitCD = true
        pcall(function()
            local char = LP.Character; if not char then return end
            local bat = _v2FindBat()
            if bat then
                if bat.Parent ~= char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:EquipTool(bat) end) end
                end
                pcall(function() bat:Activate() end)
            end
        end)
        task.delay(_v2SWING_CD, function() _v2HitCD = false end)
    end

    local function _v2GetClosest()
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil, math.huge end
        local closest, minDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if tRoot and hum and hum.Health > 0 then
                    local dist = (tRoot.Position - root.Position).Magnitude
                    if dist < minDist then minDist = dist; closest = tRoot end
                end
            end
        end
        return closest, minDist
    end

    startBatV2 = function()
        if Conns.batV2 then Conns.batV2:Disconnect() end
        local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum0 then
            if _v2PrevAutoRotate == nil then _v2PrevAutoRotate = hum0.AutoRotate end
            hum0.AutoRotate = false
        end
        Conns.batV2 = RunService.RenderStepped:Connect(function()
            if not State.batV2Toggled then return end
            local char = LP.Character; if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            if not char:FindFirstChildOfClass("Tool") then
                local bat = _v2FindBat()
                if bat then pcall(function() hum:EquipTool(bat) end) end
            end
            local target, targetDist = _v2GetClosest()
            if not target then return end
            local myPos = root.Position
            local targetPos = target.Position
            local direction = targetPos - myPos
            local flatDir = Vector3.new(direction.X, 0, direction.Z)
            if flatDir.Magnitude > 0 then flatDir = flatDir.Unit else flatDir = Vector3.zero end
            local chaseSpeed = 58
            local desiredHeight = targetPos.Y + 3.7
            local yVel = (desiredHeight - myPos.Y) * 19.5
            if hum.FloorMaterial ~= Enum.Material.Air then yVel = math.max(yVel, 13) end
            yVel = math.clamp(yVel, -70, 110)
            local desiredVel = Vector3.new(flatDir.X * chaseSpeed, yVel, flatDir.Z * chaseSpeed)
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, 0.8)
            local toTarget = targetPos - myPos
            if toTarget.Magnitude > 0.1 then
                local goalCF = CFrame.lookAt(myPos, targetPos)
                local diffCF = root.CFrame:Inverse() * goalCF
                local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
                rx = math.clamp(rx,-2.5,2.5); ry = math.clamp(ry,-2.5,2.5); rz = math.clamp(rz,-2.5,2.5)
                root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(Vector3.new(rx*42, ry*42, rz*42))
            end
            if targetDist <= _v2HIT_DIST then _v2TrySwing() end
        end)
    end
    stopBatV2 = function()
        if Conns.batV2 then Conns.batV2:Disconnect(); Conns.batV2=nil end
        _v2HitCD = false
        local c = LP.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = (_v2PrevAutoRotate == nil) and true or _v2PrevAutoRotate
            hum.PlatformStand = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        _v2PrevAutoRotate = nil
    end

    -- BAT COUNTER
    local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
    local function findBatForCounter()
        local c=LP.Character; if not c then return nil end
        local bp=LP:FindFirstChildOfClass("Backpack")
        for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
            local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
            if t then return t end
        end
        for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
        if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
        return nil
    end
    local function swingBatForCounter(bat,char)
        local hum2=char:FindFirstChildOfClass("Humanoid")
        if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end; task.wait(0.05) end
        local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
        if remote and remote:IsA("RemoteEvent") then
            pcall(function() remote:FireServer() end); task.wait(0.15); pcall(function() remote:FireServer() end)
        else pcall(function() bat:Activate() end); task.wait(0.15); pcall(function() bat:Activate() end) end
    end
    startBatCounter = function()
        if Conns.batCounter then return end
        Conns.batCounter = RunService.Heartbeat:Connect(function()
            if not State.batCounterEnabled or State.batCounterDebounce then return end
            local char=LP.Character; if not char then return end
            local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
            local st=hum2:GetState()
            local isRagdolled = st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
            if isRagdolled then
                State.batCounterDebounce=true
                task.spawn(function()
                    local bat=findBatForCounter()
                    if bat then swingBatForCounter(bat,char) end
                    task.wait(0.5); State.batCounterDebounce=false
                end)
            end
        end)
    end
    stopBatCounter = function()
        if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end
        State.batCounterDebounce=false
    end

    -- MEDUSA
    local MEDUSA_COOLDOWN=0.5
    local function findMedusa()
        local c=LP.Character; if not c then return nil end
        for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
        local bp=LP:FindFirstChildOfClass("Backpack")
        if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
        return nil
    end
    local function useMedusaCounter()
        if State.medusaDebounce then return end; if tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
        local c=LP.Character; if not c then return end; State.medusaDebounce=true
        local med=findMedusa(); if not med then State.medusaDebounce=false; return end
        if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
        pcall(function() med:Activate() end); State.medusaLastUsed=tick(); State.medusaDebounce=false
    end
    local function onAnchorChanged(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if part.Anchored and part.Transparency==1 then useMedusaCounter() end end) end
    setupMedusaCounter = function(char)
        stopMedusaCounter(); if not char then return end
        for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
        table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end))
    end
    stopMedusaCounter = function() for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end; Conns.anchor={} end

    -- ============================================================
    -- ANTI RAGDOLL (undetected unpatched implementation)
    -- ============================================================
    local _arCached = {}

    local function _arCache()
        local char = LP.Character; if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return false end
        _arCached = { character=char, humanoid=hum, root=root }
        workspace.CurrentCamera.CameraSubject = hum
        return true
    end

    local function _arIsRagdolled()
        local hum = _arCached.humanoid; if not hum then return false end
        local st = hum:GetState()
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then return true end
        local endTime = LP:GetAttribute("RagdollEndTime")
        if endTime then
            local now = workspace:GetServerTimeNow()
            if (endTime - now) > 0 then return true end
        end
        return false
    end

    local function _arRemoveConstraints()
        if not _arCached.character then return end
        for _, v in ipairs(_arCached.character:GetDescendants()) do
            if v:IsA("BallSocketConstraint") or (v:IsA("Attachment") and v.Name:find("RagdollAttachment")) then
                pcall(function() v:Destroy() end)
            end
        end
    end

    local function _arForceExit()
        local hum = _arCached.humanoid; local root = _arCached.root
        if not hum or not root then return end
        pcall(function() LP:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
        if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(root.Orientation.Y), 0)
        local cam = workspace.CurrentCamera
        if cam.CameraSubject ~= hum then cam.CameraSubject = hum end
    end

    startAntiRagdoll = function()
        if Conns.antiRag then return end
        _arCache()
        Conns.antiRag = RunService.RenderStepped:Connect(function()
            if not _arCached.humanoid or not _arCached.humanoid.Parent then return end
            if _arIsRagdolled() then
                _arRemoveConstraints()
                _arForceExit()
            end
        end)
    end
    stopAntiRagdoll = function()
        if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag = nil end
        State.countdownActive = false
        _arCached = {}
    end

    -- Re-cache on respawn
    LP.CharacterAdded:Connect(function()
        if State.antiRagdollEnabled then
            task.wait(0.5)
            _arCache()
        end
    end)

    -- ============================================================
    -- RAGDOLL TIMER (overhead billboard, Blossom-style decimal countdown)
    -- ============================================================
    local _rtTimerActive = false

    local function getRagTimerColor(t)
        return Color3.fromRGB(80, 220, 80)
    end

    local function getRagTimerLbl()
        local char = LP.Character; if not char then return nil end
        local head = char:FindFirstChild("Head"); if not head then return nil end
        local bb = head:FindFirstChild("LarpDuelsBB"); if not bb then return nil end
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
                    lbl.TextColor3 = getRagTimerColor(t)
                end
                task.wait(0.1)
                t = math.round((t - 0.1) * 10) / 10
            end
            local lbl = getRagTimerLbl()
            if lbl then
                lbl.Text = "STEAL!"
                lbl.TextColor3 = Color3.fromRGB(80, 180, 255)
            end
            -- Wait until no longer ragdolled
            repeat task.wait(0.1) until (function()
                local c = LP.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not hum then return true end
                local st = hum:GetState()
                return st ~= Enum.HumanoidStateType.Physics
                    and st ~= Enum.HumanoidStateType.Ragdoll
                    and st ~= Enum.HumanoidStateType.FallingDown
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
            if st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown then
                startRagTimerGui()
            end
        end)
    end

    -- ============================================================
    -- AUTO-STEAL (updated logic)
    -- ============================================================
    local isStealing = false
    local StealDataCache = {}

    local function updateProgressBar(p)
        if progressFill then progressFill.Size = UDim2.new(p,0,1,0) end
        if stealPctLbl then stealPctLbl.Text = math.floor(p*100).."%" end
    end
    local function resetProgressBar() updateProgressBar(0) end

    local function getHRP()
        local c = LP.Character
        if c then return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
        return nil
    end

    local function isMyPlotByName(pn)
        local plots = workspace:FindFirstChild("Plots"); if not plots then return false end
        local plot = plots:FindFirstChild(pn); if not plot then return false end
        local sign = plot:FindFirstChild("PlotSign")
        if sign then local yb = sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled==true end end
        return false
    end

    local function findNearestPrompt()
        local hrp = getHRP(); if not hrp then return nil end
        local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
        local nearest, dist = nil, math.huge
        for _, plot in ipairs(plots:GetChildren()) do
            if isMyPlotByName(plot.Name) then continue end
            local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
            for _, pod in ipairs(pods:GetChildren()) do
                local base = pod:FindFirstChild("Base"); if not base then continue end
                local spawn = base:FindFirstChild("Spawn"); if not spawn then continue end
                local d = (spawn.Position - hrp.Position).Magnitude
                if d <= Steal.StealRadius and d < dist then
                    local att = spawn:FindFirstChild("PromptAttachment")
                    if att then
                        for _, p in ipairs(att:GetChildren()) do
                            if p:IsA("ProximityPrompt") and p.ActionText and p.ActionText:find("Steal") then
                                nearest, dist = p, d
                            end
                        end
                    end
                end
            end
        end
        return nearest
    end

    local function executeSteal(prompt)
        if isStealing then return end
        if not StealDataCache[prompt] then
            StealDataCache[prompt] = {hold={}, trigger={}, ready=true}
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealDataCache[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealDataCache[prompt].trigger, c.Function) end
                end
            end
        end
        local data = StealDataCache[prompt]
        if not data.ready then return end
        data.ready = false
        isStealing = true; State.isStealing = true
        local startTime = tick()
        task.spawn(function()
            for _, f in ipairs(data.hold) do pcall(f) end
            while tick() - startTime < Steal.StealDuration do
                local elapsed = tick() - startTime
                updateProgressBar(math.clamp(elapsed / Steal.StealDuration, 0, 1))
                task.wait()
            end
            updateProgressBar(1)
            for _, f in ipairs(data.trigger) do pcall(f) end
            task.wait(0.05)
            resetProgressBar()
            data.ready = true; isStealing = false; State.isStealing = false
        end)
    end

    local autoStealConn = nil
    startAutoSteal = function()
        if autoStealConn then return end
        autoStealConn = RunService.Heartbeat:Connect(function()
            if not Steal.AutoStealEnabled or isStealing then return end
            local ok, prompt = pcall(findNearestPrompt)
            if ok and prompt then pcall(executeSteal, prompt) end
        end)
    end
    stopAutoSteal = function()
        if autoStealConn then autoStealConn:Disconnect(); autoStealConn=nil end
        isStealing=false; State.isStealing=false; resetProgressBar(); StealDataCache={}
    end

    -- ============================================================
    -- MODULES (Nuke, No Cam, Custom Font, Remove Acc) - unchanged
    -- ============================================================
    _G._NukeOn=false; _G._NukeConns={}; _G._NukeThreads={}
    _G._nukeStart = function()
        if _G._NukeOn then return end; _G._NukeOn=true
        local Lighting=game:GetService("Lighting"); local MaterialService=game:GetService("MaterialService")
        local XMin,XMax=-560,-240
        local ClothingClasses={"Shirt","Pants","ShirtGraphic","Accessory","Hat","HairAccessory","FaceAccessory","NeckAccessory","ShoulderAccessory","FrontAccessory","BackAccessory","WaistAccessory"}
        local BASE_NAMES={"baseplate","spawnlocation","spawn location","spawn"}
        local function SafeDestroy(obj) if obj.Name=="Overhead" then return end pcall(function() obj:Destroy() end) end
        local function IsClothing(obj) for _,c in ipairs(ClothingClasses) do if obj:IsA(c) then return true end end return false end
        local function IsCharacterPart(obj) for _,plr in ipairs(Players:GetPlayers()) do if plr.Character and obj:IsDescendantOf(plr.Character) then return true end end return false end
        local function IsOutOfRange(obj) if obj:IsA("BasePart") then local x=obj.Position.X; return x<XMin or x>XMax end return false end
        local function IsBase(obj) if not obj:IsA("BasePart") then return false end local nl=obj.Name:lower(); for _,n in ipairs(BASE_NAMES) do if nl:find(n,1,true) then return true end end return false end
        local function IsInBase(obj) local p=obj.Parent; while p and p~=workspace do if IsBase(p) then return true end p=p.Parent end return false end
        local function MakeTransparent(obj) pcall(function() if IsBase(obj) and not IsCharacterPart(obj) then obj.Transparency=1; obj.CastShadow=false end end) end
        local function StripObject(obj) pcall(function() if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SpecialMesh") then SafeDestroy(obj) elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then pcall(function() obj.Enabled=false end); SafeDestroy(obj) elseif obj:IsA("SurfaceAppearance") then SafeDestroy(obj) elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic; obj.MaterialVariant=""; obj.Reflectance=0 end end) end
        local function CleanObject(obj) pcall(function() if obj:IsA("SurfaceAppearance") then SafeDestroy(obj) elseif obj:IsA("Decal") or obj:IsA("Texture") then if not (obj.Name=="face" and obj.Parent and obj.Parent.Name=="Head") then SafeDestroy(obj) end elseif obj:IsA("SpecialMesh") then obj.TextureId="" elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then SafeDestroy(obj) elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then SafeDestroy(obj) elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then SafeDestroy(obj) elseif obj:IsA("Animation") or obj:IsA("AnimationController") then SafeDestroy(obj) elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic; obj.MaterialVariant=""; obj.Reflectance=0 end end) end
        local function ApplyGreySky() pcall(function() for _,obj in ipairs(Lighting:GetChildren()) do if obj:IsA("Sky") then obj:Destroy() end end; local sky=Instance.new("Sky"); sky.SkyboxBk=""; sky.SkyboxDn=""; sky.SkyboxFt=""; sky.SkyboxLf=""; sky.SkyboxRt=""; sky.SkyboxUp=""; sky.CelestialBodiesShown=false; sky.Name="_VezyNukeSky"; sky.Parent=Lighting end) end
        local function OptimizeLighting() Lighting.GlobalShadows=false; Lighting.FogEnd=9e9; Lighting.FogStart=9e9; Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0; Lighting.Brightness=1.5; Lighting.Ambient=Color3.fromRGB(60,60,60); for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end end; ApplyGreySky() end
        local function ApplyTerrain() pcall(function() local T=workspace.Terrain; T.Decoration=false; T.WaterWaveSize=0; T.WaterWaveSpeed=0; T.WaterReflectance=0; T.WaterTransparency=1 end) end
        local function OptimizeCharacter(char) if not char then return end task.spawn(function() task.wait(0.3); if not _G._NukeOn then return end; for _,obj in ipairs(char:GetDescendants()) do if IsClothing(obj) then SafeDestroy(obj) else CleanObject(obj) end end end) end
        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; settings().Rendering.MeshPartDetailLevel=Enum.MeshPartDetailLevel.Level01 end)
        pcall(function() if setfpscap then setfpscap(999) end end)
        table.insert(_G._NukeThreads,task.spawn(function() if not game:IsLoaded() then game.Loaded:Wait() end; OptimizeLighting(); ApplyTerrain(); for _,obj in ipairs(workspace:GetDescendants()) do if not _G._NukeOn then return end; if IsBase(obj) then MakeTransparent(obj) elseif IsClothing(obj) then SafeDestroy(obj) elseif IsInBase(obj) then elseif IsCharacterPart(obj) then elseif IsOutOfRange(obj) then SafeDestroy(obj) else CleanObject(obj); StripObject(obj) end end; for _,obj in ipairs(workspace:GetDescendants()) do MakeTransparent(obj) end end))
        table.insert(_G._NukeConns,workspace.DescendantAdded:Connect(function(obj) if not _G._NukeOn then return end; task.defer(function() if not _G._NukeOn then return end; if IsBase(obj) then MakeTransparent(obj); return end; if IsClothing(obj) then SafeDestroy(obj) elseif IsInBase(obj) then elseif IsCharacterPart(obj) then elseif IsOutOfRange(obj) then SafeDestroy(obj) else CleanObject(obj); StripObject(obj) end end) end))
        table.insert(_G._NukeConns,Lighting.DescendantAdded:Connect(function(obj) if not _G._NukeOn then return end; if obj:IsA("Atmosphere") or obj:IsA("Clouds") or obj:IsA("PostEffect") then SafeDestroy(obj) end end))
        table.insert(_G._NukeConns,MaterialService.DescendantAdded:Connect(function(obj) if not _G._NukeOn then return end; SafeDestroy(obj) end))
        for _,plr in ipairs(Players:GetPlayers()) do OptimizeCharacter(plr.Character); table.insert(_G._NukeConns,plr.CharacterAdded:Connect(OptimizeCharacter)) end
        table.insert(_G._NukeConns,Players.PlayerAdded:Connect(function(plr) table.insert(_G._NukeConns,plr.CharacterAdded:Connect(OptimizeCharacter)) end))
        table.insert(_G._NukeThreads,task.spawn(function() while _G._NukeOn do task.wait(15); pcall(function() collectgarbage("collect") end) end end))
    end
    _G._nukeStop = function() _G._NukeOn=false; for _,c in ipairs(_G._NukeConns) do pcall(function() c:Disconnect() end) end; _G._NukeConns={}; _G._NukeThreads={} end

    _G._NoCamOn=false; _G._NoCamConn=nil; _G._NoCamParts={}
    _G._noCamStart = function() if _G._NoCamOn then return end; _G._NoCamOn=true; local function apply(obj) if obj:IsA("BasePart") and not obj:IsDescendantOf(LP.Character) then if _G._NoCamParts[obj]==nil then _G._NoCamParts[obj]=obj.CanCollide end end end; for _,obj in ipairs(workspace:GetDescendants()) do apply(obj) end; _G._NoCamConn = RunService.RenderStepped:Connect(function() if not _G._NoCamOn then return end; local cam=workspace.CurrentCamera; if not cam then return end; for p,_ in pairs(_G._NoCamParts) do if p and p.Parent then pcall(function() local dist=(cam.CFrame.Position-p.Position).Magnitude; if dist<8 then p.LocalTransparencyModifier=1 else p.LocalTransparencyModifier=0 end end) end end end) end
    _G._noCamStop = function() _G._NoCamOn=false; if _G._NoCamConn then _G._NoCamConn:Disconnect(); _G._NoCamConn=nil end; for p,_ in pairs(_G._NoCamParts) do pcall(function() if p and p.Parent then p.LocalTransparencyModifier=0 end end) end; _G._NoCamParts={} end

    _G._VezyFontMyfont=nil; _G._VezyFontBadfont=nil; _G._VezyFontConn=nil; _G._VezyFontEnabled=false; _G._VezyFontOriginals={}
    _G._fontDontTouch = function(this) if this:IsA("TextLabel") or this:IsA("TextButton") or this:IsA("TextBox") then if this.TextStrokeTransparency~=1 then return false end; local cur=tostring(this.FontFace); return cur==_G._VezyFontBadfont or string.find(cur,"BuilderIcons") end; return true end
    _G._fontChangeIt = function(txt) if (txt:IsA("TextLabel") or txt:IsA("TextButton") or txt:IsA("TextBox")) and not _G._fontDontTouch(txt) then if not _G._VezyFontOriginals[txt] then _G._VezyFontOriginals[txt]=txt.FontFace end; pcall(function() txt.FontFace=_G._VezyFontMyfont end) end end
    _G._fontSetup = function() if _G._VezyFontMyfont then return true end; local ok=pcall(function() local httpsvc=game:GetService("HttpService"); if isfile and writefile and getcustomasset then if not isfile("starborn.ttf") then writefile("starborn.ttf",game:HttpGet("https://granny.anondrop.net/uploads/6c2505542959f371/Starborn.ttf")) end; writefile("starborn.json",httpsvc:JSONEncode({name="Starborn",faces={{name="Regular",weight=400,style="normal",assetId=getcustomasset("starborn.ttf")}}})); _G._VezyFontMyfont=Font.new(getcustomasset("starborn.json")); _G._VezyFontBadfont=tostring(Font.new("rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json")) end end); return ok and _G._VezyFontMyfont~=nil end
    _G._customFontStart = function() if _G._VezyFontEnabled then return end; if not _G._fontSetup() then return end; _G._VezyFontEnabled=true; for _,v in pairs(game:GetDescendants()) do _G._fontChangeIt(v) end; _G._VezyFontConn=game.DescendantAdded:Connect(function(obj) if _G._VezyFontEnabled then _G._fontChangeIt(obj) end end) end
    _G._customFontStop = function() _G._VezyFontEnabled=false; if _G._VezyFontConn then _G._VezyFontConn:Disconnect(); _G._VezyFontConn=nil end; for obj,origFont in pairs(_G._VezyFontOriginals) do pcall(function() if obj and obj.Parent then obj.FontFace=origFont end end) end; _G._VezyFontOriginals={} end

    _G._RemoveAccOn=false; _G._RemoveAccConn=nil; _G._removedAccessories={}
    _G._removeAccDo = function() if not _G._RemoveAccOn then return end; local char=LP.Character; if not char then return end; for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Accessory") or obj:IsA("Hat") then if not _G._removedAccessories[obj] then _G._removedAccessories[obj]=true; pcall(function() obj:Destroy() end) end end end end
    _G._removeAccStart = function() if _G._RemoveAccOn then return end; _G._RemoveAccOn=true; _G._removeAccDo(); _G._RemoveAccConn=LP.CharacterAdded:Connect(function() task.wait(0.5); if _G._RemoveAccOn then _G._removeAccDo() end end) end
    _G._removeAccStop = function() _G._RemoveAccOn=false; if _G._RemoveAccConn then _G._RemoveAccConn:Disconnect(); _G._RemoveAccConn=nil end; _G._removedAccessories={} end

    -- ============================================================
    -- CHARACTER SETUP
    -- ============================================================
    local function setupChar(char)
        task.wait(0.1)
        h=char:WaitForChild("Humanoid",5)
        hrp=char:WaitForChild("HumanoidRootPart",5)
        if not h or not hrp then return end
        local head=char:FindFirstChild("Head")
        if head then
            local oldBB=head:FindFirstChild("LarpDuelsBB"); if oldBB then oldBB:Destroy() end
            local bb=Instance.new("BillboardGui", head); bb.Name="LarpDuelsBB"; bb.Size=UDim2.new(0,180,0,100); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
            local list=Instance.new("UIListLayout",bb); list.FillDirection=Enum.FillDirection.Vertical; list.SortOrder=Enum.SortOrder.LayoutOrder; list.VerticalAlignment=Enum.VerticalAlignment.Center; list.Padding=UDim.new(0,2)
            local speedBillLbl=Instance.new("TextLabel",bb); speedBillLbl.Name="SpeedBillLbl"; speedBillLbl.Size=UDim2.new(1,0,0,24); speedBillLbl.BackgroundTransparency=1; speedBillLbl.Text="0.0"; speedBillLbl.TextColor3=Color3.fromRGB(38,240,125); speedBillLbl.Font=Enum.Font.GothamBlack; speedBillLbl.TextScaled=true; speedBillLbl.TextStrokeTransparency=0.1; speedBillLbl.TextStrokeColor3=Color3.new(0,0,0); speedBillLbl.LayoutOrder=1
            local discordLbl=Instance.new("TextLabel",bb); discordLbl.Size=UDim2.new(1,0,0,22); discordLbl.BackgroundTransparency=1; discordLbl.Text="discord.gg/LarpDuels"; discordLbl.TextColor3=Color3.fromRGB(100,255,100); discordLbl.Font=Enum.Font.GothamBold; discordLbl.TextScaled=true; discordLbl.TextStrokeTransparency=0.1; discordLbl.TextStrokeColor3=Color3.new(0,0,0); discordLbl.LayoutOrder=2
            local ragTimerLbl=Instance.new("TextLabel",bb); ragTimerLbl.Name="RagdollTimerLbl"; ragTimerLbl.Size=UDim2.new(1,0,0,30); ragTimerLbl.BackgroundTransparency=1; ragTimerLbl.Text=""; ragTimerLbl.TextColor3=Color3.fromRGB(255,60,60); ragTimerLbl.Font=Enum.Font.GothamBlack; ragTimerLbl.TextScaled=true; ragTimerLbl.TextStrokeTransparency=0.1; ragTimerLbl.TextStrokeColor3=Color3.new(0,0,0); ragTimerLbl.LayoutOrder=3

        end
        stopAntiRagdoll()
        Steal.Data={}
        -- Reset overhead timer label and restart detection for new character
        _rtTimerActive = false
        local _rtLbl = getRagTimerLbl and getRagTimerLbl()
        if _rtLbl then _rtLbl.Text = "" end
        task.spawn(function() startRagTimerDetection(char) end)
        if State.antiRagdollEnabled then task.wait(0.5); startAntiRagdoll() end
        if State.medusaCounterEnabled then setupMedusaCounter(char) end
        if State.batAimbotToggled then stopBatAimbot(); task.wait(0.2); pcall(startBatAimbot) end
        if State.batCounterEnabled then task.wait(0.3); startBatCounter() end
        if State.tryardAnimEnabled then saveOriginalTryardAnims(char); applyTryardAnimPack(char) end
    end
    LP.CharacterAdded:Connect(setupChar)
    if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

    -- ============================================================
    -- RUNTIME LOOPS
    -- ============================================================
    RunService.Stepped:Connect(function()
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end end end
    end)

    -- Speed application
    RunService.RenderStepped:Connect(function()
        if not (h and hrp) then return end; if State._tpInProgress then return end
        if not State.batAimbotToggled and not State.autoLeftEnabled and not State.autoRightEnabled then
            local md=h.MoveDirection
            local spd
            if State.laggerMode==1 then spd=State.laggerSpeed
            elseif State.laggerMode==2 then spd=State.laggerCarrySpeed
            else spd=State.speedToggled and State.carrySpeed or State.normalSpeed end
            if md.Magnitude>0 then
                State.lastMoveDir=md
                hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
            elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
                local anyHeld=false
                for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
                if anyHeld then hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd) end
            end
        end
        pcall(function()
            local head2=LP.Character and LP.Character:FindFirstChild("Head")
            if head2 then
                local bb2=head2:FindFirstChild("LarpDuelsBB")
                local sl=bb2 and bb2:FindFirstChild("SpeedBillLbl")
                if sl then sl.Text=string.format("%.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
            end
        end)
    end)

    -- INPUT
    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        local isKb=inp.UserInputType==Enum.UserInputType.Keyboard
        local isGp=inp.UserInputType==Enum.UserInputType.Gamepad1 or inp.UserInputType==Enum.UserInputType.Gamepad2 or inp.UserInputType==Enum.UserInputType.Gamepad3 or inp.UserInputType==Enum.UserInputType.Gamepad4
        if not isKb and not isGp then return end
        local kc=inp.KeyCode; if kc==Enum.KeyCode.Unknown then return end
        if kc==Keys.speed then toggleSpeed()
        elseif kc==Keys.autoLeft then
            State.autoLeftEnabled=not State.autoLeftEnabled
            if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
            if State.autoLeftEnabled and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
            if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
            requestSave()
        elseif kc==Keys.autoRight then
            State.autoRightEnabled=not State.autoRightEnabled
            if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end
            if State.autoRightEnabled and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
            if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
            requestSave()
        elseif kc==Keys.drop then if not State.dropEnabled then runDropBrainrot() end
        elseif kc==Keys.lagger then toggleLaggerMode()
        elseif kc==Keys.tpDown then if runTPDown then task.spawn(runTPDown) end
        elseif kc==Keys.aimbot then
            State.batAimbotToggled=not State.batAimbotToggled
            if State.batAimbotToggled then
                if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
                if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
                pcall(startBatAimbot)
            else stopBatAimbot() end
            if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(State.batAimbotToggled) end
        if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(State.batV2Toggled) end
            requestSave()
        elseif kc==Keys.guiHide then
            if isKb then
                State.guiVisible=not State.guiVisible; mainOuter.Visible=State.guiVisible
                if _G.LarpDuelsQAHide then pcall(_G.LarpDuelsQAHide, not State.guiVisible) end
                requestSave()
            end
        end
    end)

    -- FOV LOCK
    _G._VezyFOV = _G._VezyFOV or 70
    _G._VezyFOVPropConn = nil
    local function _attachFOVLock(cam)
        if not cam then return end
        if _G._VezyFOVPropConn then pcall(function() _G._VezyFOVPropConn:Disconnect() end) end
        pcall(function() cam.FieldOfView = _G._VezyFOV or 70 end)
        _G._VezyFOVPropConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
            local target = _G._VezyFOV or 70
            if not State.stretchedResEnabled and cam.FieldOfView ~= target then pcall(function() cam.FieldOfView = target end) end
        end)
    end
    _attachFOVLock(workspace.CurrentCamera)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.wait(); _attachFOVLock(workspace.CurrentCamera) end)
    LP.CharacterAdded:Connect(function() task.wait(0.3); _attachFOVLock(workspace.CurrentCamera) end)
    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local target = _G._VezyFOV or 70
        if not State.stretchedResEnabled and cam.FieldOfView ~= target then pcall(function() cam.FieldOfView = target end) end
    end)

    -- ============================================================
    -- MINI CLOVER BUTTON
    -- ============================================================
    local cloverBtn = Instance.new("TextButton", gui)
    cloverBtn.Name = "LarpDuelsClover"
    cloverBtn.Size = UDim2.new(0,140,0,36)
    cloverBtn.Position = UDim2.new(0,20,0,200)
    cloverBtn.BackgroundColor3 = Color3.fromRGB(10,14,36)
    cloverBtn.BorderSizePixel = 0
    cloverBtn.Text = "🍀 LarpDuels"
    cloverBtn.TextColor3 = Color3.fromRGB(80,180,255)
    cloverBtn.Font = Enum.Font.GothamBold
    cloverBtn.TextSize = 14
    cloverBtn.ZIndex = 25
    cloverBtn.Visible = true
    mkCorner(cloverBtn,12)
    mkStroke(cloverBtn, Color3.fromRGB(30,132,73), 1.5)

    do
        local dragStart,startPos,dragging = nil,nil,false
        local saveDebounce = nil
        cloverBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = cloverBtn.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
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
        if _G.LarpDuelsQAHide then pcall(_G.LarpDuelsQAHide, not State.guiVisible) end
        requestSave()
    end)

    cloverBtn.MouseEnter:Connect(function() TweenService:Create(cloverBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(20,32,24)}):Play() end)
    cloverBtn.MouseLeave:Connect(function() TweenService:Create(cloverBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(14,24,18)}):Play() end)

    -- ============================================================
    -- SAVE / LOAD (with verification)
    -- ============================================================
    saveConfig = function()
        local success = false
        pcall(function()
            if _isfile(CONFIG_FILE) then
                local oldRaw = _readfile(CONFIG_FILE)
                if oldRaw then pcall(function() _writefile(CONFIG_BACKUP, oldRaw) end) end
            end

            local btnPositions = {}
            for key, wrapper in pairs(stackWrappers) do
                if wrapper and wrapper.Position then
                    btnPositions[key] = { X = wrapper.Position.X.Offset, Y = wrapper.Position.Y.Offset }
                end
            end
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
                tpDownKey = Keys.tpDown and Keys.tpDown.Name or "Unknown",
                aimbotKey = Keys.aimbot and Keys.aimbot.Name or "Unknown",
                infJump = State.infJumpEnabled,
                antiRagdoll = State.antiRagdollEnabled,
                medusaCounter = State.medusaCounterEnabled,
                batCounter = State.batCounterEnabled,
                autoStealEnabled = Steal.AutoStealEnabled,
                autoSwing = State.autoSwingEnabled,
                batAimbot = State.batAimbotToggled,
                batV2 = State.batV2Toggled,
                antiLagEnabled = State.antiLagEnabled,
                stretchedResEnabled = State.stretchedResEnabled,
                stretchFOV = State.stretchFOV,
                normalFOV = _G._VezyFOV or 70,
                activeSky = State.activeSky,
                nukeOptimizer = State.nukeOpt,
                removeAccessories = State.removeAcc,
                tryardAnimEnabled = State.tryardAnimEnabled,
                introEnabled = State.introEnabled,
                guiVisible = State.guiVisible,
                buttonPositions = btnPositions,
                cloverPosition = cloverPos,
                autoTPEnabled = State.autoTPEnabled,
                autoTPHeight = State.autoTPHeight,
        bodyLockRadius = State.bodyLockRadius,
            }
            local encoded = HttpService:JSONEncode(cfg)
            _writefile(CONFIG_FILE, encoded)
            local verify = _readfile(CONFIG_FILE)
            if verify == encoded then success = true end
        end)
        if not success then
            pcall(_G._VezyFlashSave, false)
        else
            pcall(_G._VezyFlashSave, true)
        end
        return success
    end

    loadConfig = function()
        if not _isfile(CONFIG_FILE) then return false end
        local raw = _readfile(CONFIG_FILE)
        if not raw then return false end
        local ok, decErr = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok or not decErr then return false end

        local function applyNumber(key, targetVar, uiBox)
            if decErr[key] then
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
        if decErr.uiScale and uiScaleObj then
            uiScaleObj.Scale = decErr.uiScale
            if uiScaleBox then uiScaleBox.Text = tostring(decErr.uiScale) end
        end
        if decErr.normalFOV then
            _G._VezyFOV = decErr.normalFOV
            pcall(function() workspace.CurrentCamera.FieldOfView = _G._VezyFOV end)
        end
        
        -- Auto TP height loading fix: update State and UI box
        if decErr.autoTPEnabled ~= nil then State.autoTPEnabled = decErr.autoTPEnabled end
        if decErr.autoTPHeight then 
            State.autoTPHeight = decErr.autoTPHeight
            if autoTPHeightBox then autoTPHeightBox.Text = tostring(State.autoTPHeight) end
        end
        if decErr.bodyLockRadius then
            State.bodyLockRadius = decErr.bodyLockRadius
            if bodyLockRadBox then bodyLockRadBox.Text = tostring(State.bodyLockRadius) end
        end

        local bools = {
            stackButtonsHidden = "stackButtonsHidden", stackButtonsLocked = "stackButtonsLocked",
            infJump = "infJumpEnabled", antiRagdoll = "antiRagdollEnabled",
            bodyLock = "bodyLockEnabled",
            medusaCounter = "medusaCounterEnabled", batCounter = "batCounterEnabled",
            autoStealEnabled = "autoStealEnabled", autoSwing = "autoSwingEnabled",
            batAimbot = "batAimbotToggled", batV2 = "batV2Toggled", antiLagEnabled = "antiLagEnabled",
            stretchedResEnabled = "stretchedResEnabled", nukeOptimizer = "nukeOpt",
            removeAccessories = "removeAcc",
            tryardAnimEnabled = "tryardAnimEnabled",
            introEnabled = "introEnabled", guiVisible = "guiVisible",
            speedToggled = "speedToggled", autoTPEnabled = "autoTPEnabled",
        }
        for cfgKey, stateKey in pairs(bools) do
            if decErr[cfgKey] ~= nil then State[stateKey] = decErr[cfgKey] end
        end
        if decErr.laggerMode ~= nil then State.laggerMode = decErr.laggerMode end
        if decErr.stretchFOV then State.stretchFOV = decErr.stretchFOV end
        if decErr.activeSky then State.activeSky = decErr.activeSky end

        local keyMap = {
            speedKey = "speed", autoLeftKey = "autoLeft", autoRightKey = "autoRight",
            guiHideKey = "guiHide", dropKey = "drop", laggerKey = "lagger",
            tpDownKey = "tpDown", aimbotKey = "aimbot"
        }
        for cfgKey, stateKey in pairs(keyMap) do
            if decErr[cfgKey] then
                local kc = Enum.KeyCode[decErr[cfgKey]]
                if kc then
                    Keys[stateKey] = kc
                    if keybindBtnRefs[stateKey] then
                        keybindBtnRefs[stateKey].Text = getKeyDisplayName(kc)
                    end
                end
            end
        end

        mainOuter.Visible = State.guiVisible
        if _G.LarpDuelsQAHide then pcall(_G.LarpDuelsQAHide, not State.guiVisible) end

        for _, wrapper in pairs(stackWrappers) do wrapper.Visible = not State.stackButtonsHidden end
        if hideButtonsSetter then hideButtonsSetter(State.stackButtonsHidden) end
        if lockButtonsSetter then lockButtonsSetter(State.stackButtonsLocked) end

        if State.laggerMode == 0 then
            if carryBox then carryBox.Text = tostring(State.speedToggled and State.carrySpeed or State.normalSpeed) end
        elseif State.laggerMode == 1 then
            if carryBox then carryBox.Text = tostring(State.laggerSpeed) end
        elseif State.laggerMode == 2 then
            if carryBox then carryBox.Text = tostring(State.laggerCarrySpeed) end
        end
        if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerMode == 1) end
        if stackBtnRefs.laggerCarry then stackBtnRefs.laggerCarry.setOn(State.laggerMode == 2) end
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(State.batAimbotToggled) end
        if stackBtnRefs.batV2 then stackBtnRefs.batV2.setOn(State.batV2Toggled) end
        if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
        if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end

        -- Apply features
        if State.antiLagEnabled then enableAntiLag() else disableAntiLag() end
        if State.stretchedResEnabled then enableStretchRez() else disableStretchRez() end
        if State.activeSky then applySky(State.activeSky) else applySky(nil) end
        if State.nukeOpt then _G._nukeStart() else _G._nukeStop() end
        if State.removeAcc then _G._removeAccStart() else _G._removeAccStop() end
        if State.tryardAnimEnabled then startTryardAnim() else stopTryardAnim() end
        if State.batAimbotToggled then startBatAimbot() else stopBatAimbot() end
        if State.batV2Toggled then startBatV2() else stopBatV2() end
        if State.batCounterEnabled then startBatCounter() else stopBatCounter() end
        if State.medusaCounterEnabled then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
        if State.antiRagdollEnabled then startAntiRagdoll() else stopAntiRagdoll() end
        if Steal.AutoStealEnabled then startAutoSteal() else stopAutoSteal() end
        if State.autoTPEnabled then startAutoTP() else stopAutoTP() end
        if State.bodyLockEnabled then startBodyLock() else stopBodyLock() end

        -- Sync toggle rows
        for key, setter in pairs(toggleSetters) do
            local stateValue = nil
            if key == "autoSteal" then stateValue = Steal.AutoStealEnabled
            elseif key == "infJump" then stateValue = State.infJumpEnabled
            elseif key == "antiRagdoll" then stateValue = State.antiRagdollEnabled
            elseif key == "medusaCounter" then stateValue = State.medusaCounterEnabled
            elseif key == "batCounter" then stateValue = State.batCounterEnabled
            elseif key == "autoSwing" then stateValue = State.autoSwingEnabled
            elseif key == "antiLag" then stateValue = State.antiLagEnabled
            elseif key == "stretchedRes" then stateValue = State.stretchedResEnabled
            elseif key == "nukeOpt" then stateValue = State.nukeOpt
            elseif key == "removeAcc" then stateValue = State.removeAcc
            elseif key == "tryardAnim" then stateValue = State.tryardAnimEnabled
            elseif key == "introEnabled" then stateValue = State.introEnabled
            elseif key == "hideButtons" then stateValue = State.stackButtonsHidden
            elseif key == "lockButtons" then stateValue = State.stackButtonsLocked
            elseif key == "autoTP" then stateValue = State.autoTPEnabled
            elseif key == "bodyLock" then stateValue = State.bodyLockEnabled
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
                end)
                break
            end
        end
    end
    loadConfig()
    Steal.AutoStealEnabled=true
    startAutoSteal()
    print("[Larp Duels] Ready. Blue UI active. Body Lock added. All systems go.")
end

-- ============================================================
-- SAFE MAIN EXECUTION
-- ============================================================
if not _G.LarpDuelsV2_MainExecuted then
    if LP and LP:FindFirstChild("PlayerGui") then
        Main()
    else
        LP = LP or Players:WaitForChild("LocalPlayer")
        LP:WaitForChild("PlayerGui")
        Main()
    end
end
