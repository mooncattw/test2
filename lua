local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons) or function() return {} end

local _isfile = isfile or (syn and syn.isfile) or function() return false end
local _readfile = readfile or (syn and syn.readfile) or function() return nil end
local _writefile = writefile or (syn and syn.writefile) or function() end

-- AUTO-SAVE
local function autoSave()
    pcall(saveConfig)
    pcall(savePresetsFile)
    pcall(saveMobileButtonPositions)
    pcall(saveMenuPosition)
    pcall(saveStealBarPosition)
    pcall(saveMenuVisibility)
end

-- STATE
local State = {
    normalSpeed = 60, carrySpeed = 30, laggerSpeed = 10.1, laggerCarrySpeed = 5,
    speedToggled = false, laggerEnabled = false,
    infJumpEnabled = false, antiRagdollEnabled = false, fpsBoostEnabled = false,
    jumpMode = "Tap",
    enemySpeedMeterEnabled = true,
    lockButtonsEnabled = false,
    guiVisible = true, uiLocked = false,
    isStealing = false, stealStartTime = nil, lastStealTick = 0,
    autoLeftEnabled = false, autoRightEnabled = false,
    autoLeftPhase = 1, autoRightPhase = 1,
    dropEnabled = false, _tpInProgress = false,
    lastMoveDir = Vector3.new(0,0,0),
    unwalkEnabled = false,
    _prevCarry = 30, _prevSpeed = false,
    batAimbotToggled = false, autoSwingEnabled = false,
    batAimbotSpeed = 58, batAimbotLaggerSpeed = 10,
    _prevBatSpeed = 58,
    lockInEnabled = false, batCounterEnabled = false,
    medusaCounterEnabled = false, medusaLastUsed = 0, medusaDebounce = false,
    tracersEnabled = false,
    splashEnabled = true,
    apFastSpeed = 58.7, apCarrySpeed = 29.2,
    detectedSpawn = nil, routeRunning = false, currentRouteId = 0,
    mobileBtnVisible = {
        CarryMode = true, AutoLeft = true, AutoRight = true,
        LaggerMode = true, BatAimbot = true,
        Drop = true, TpDown = true, InstantReset = true
    },
    _jumpHeld = false,
    _jumpHoldConn = nil,
    fovEnabled = false,
    fovValue = 70,
    stretchRezEnabled = false,
    instantResetEnabled = true,
    instantResetKey = Enum.KeyCode.T,
    instantResetOnMedusa = false,
    _medusaResetCooldown = false,
    _lastResetTime = 0,
    autoSpeedEnabled = false,
    currentSkyTheme = "Off",
}

local MEDUSA_COOLDOWN = 25

local Keys = {
    speed = Enum.KeyCode.Q, guiHide = Enum.KeyCode.LeftControl,
    autoLeft = Enum.KeyCode.L, autoRight = Enum.KeyCode.R,
    lagger = Enum.KeyCode.Unknown, tpDown = Enum.KeyCode.Unknown,
    drop = Enum.KeyCode.H, aimbot = Enum.KeyCode.E,
    instantReset = Enum.KeyCode.T,
}

-- STEAL CONFIG
local Steal = {
    AutoStealEnabled = false, StealRadius = 20, StealDuration = 0.25,
    Data = {}, plotCache = {}, plotCacheTime = {}, cachedPrompts = {}, promptCacheTime = 0,
}
local PLOT_CACHE_DURATION = 2
local PROMPT_CACHE_REFRESH = 0.15
local STEAL_COOLDOWN = 0.1

-- BAT AIMBOT CONFIG (FACING AWAY)
local AUTO_BAT_SPEED = 58
local AUTO_BAT_DIST = 2.5
local AUTO_BAT_TURN_SPEED = 285
local AUTO_BAT_MAX_TURN_RATE = 28
local AUTO_BAT_VERT_BASE = 52
local AUTO_BAT_VERT_SCALE = 4.0
local AUTO_BAT_VERT_MAX = 180
local STOP_RADIUS = 1.2
local MOVING_THRESHOLD = 1.0
local FRONT_OFFSET = 8.0
local VERTICAL_OFFSET_UP = 5.0
local VERTICAL_OFFSET_DOWN = -3.0

local PLOT3_POS = Vector3.new(-476.75, 10.46, 7.11)
local PLOT7_POS = Vector3.new(-476.75, 10.46, 114.11)

-- SKY THEME SYSTEM
local CANDY_SKY_TAG = "redccSkyTheme"
local candyOriginalLighting = nil

local CANDY_SKY_PRESETS = {
    ["Off"] = {kind = "off"},
    ["Night"] = {clock = 22, brightness = 2, ambient = {110,100,130}, outAmb = {120,110,140}},
    ["Aurora"] = {clock = 14, brightness = 3, ambient = {150,120,150}, outAmb = {160,130,160}},
    ["Sunset"] = {clock = 17.2, brightness = 2.5, ambient = {170,120,100}, outAmb = {180,130,110}},
    ["Galaxy"] = {clock = 0, brightness = 1.5, ambient = {70,60,100}, outAmb = {80,70,110}},
    ["Cyber"] = {clock = 21, brightness = 2.2, ambient = {90,130,170}, outAmb = {100,140,180}},
    ["Sakura"] = {clock = 11, brightness = 3.5, ambient = {170,150,160}, outAmb = {180,160,170}},
    ["Pink Night"] = {clock = 23, brightness = 2.2, ambient = {120,60,110}, outAmb = {140,70,120}},
    ["Blood Moon"] = {clock = 22.5, brightness = 1.6, ambient = {130,40,40}, outAmb = {150,50,50}},
    ["Emerald Dawn"] = {clock = 6.5, brightness = 2.8, ambient = {130,170,140}, outAmb = {140,180,150}},
    ["Volcanic"] = {clock = 19, brightness = 2, ambient = {180,80,40}, outAmb = {200,90,50}},
    ["Arctic"] = {clock = 9, brightness = 3.2, ambient = {200,220,235}, outAmb = {210,230,245}},
    ["Midnight Ocean"] = {clock = 1.5, brightness = 1.7, ambient = {60,90,130}, outAmb = {70,100,140}},
    ["Vaporwave"] = {clock = 19.5, brightness = 2.4, ambient = {180,120,200}, outAmb = {190,130,210}},
    ["Toxic"] = {clock = 13, brightness = 2.5, ambient = {140,180,80}, outAmb = {150,190,90}},
    ["Solar Eclipse"] = {clock = 12, brightness = 0.9, ambient = {50,40,60}, outAmb = {60,50,70}},
    ["Hellscape"] = {clock = 18, brightness = 1.8, ambient = {200,60,30}, outAmb = {220,70,40}},
    ["Heaven"] = {clock = 12, brightness = 4, ambient = {240,235,210}, outAmb = {250,245,220}},
    ["Storm"] = {clock = 15, brightness = 1.4, ambient = {90,90,110}, outAmb = {100,100,120}},
    ["Sunrise"] = {clock = 6.2, brightness = 2.8, ambient = {220,180,130}, outAmb = {230,190,140}},
    ["Deep Space"] = {clock = 0, brightness = 1, ambient = {30,25,50}, outAmb = {40,35,60}},
    ["Lavender Dream"] = {clock = 18.5, brightness = 2.6, ambient = {180,160,220}, outAmb = {190,170,230}},
    ["Inferno"] = {clock = 17.5, brightness = 2.2, ambient = {220,100,40}, outAmb = {235,110,50}},
    ["Mint Sky"] = {clock = 10, brightness = 3.2, ambient = {180,230,210}, outAmb = {190,240,220}},
}
local CandySkyOrder = {
    {"Off","Off"},{"Night","Night"},{"Aurora","Aurora"},{"Sunset","Sunset"},
    {"Galaxy","Galaxy"},{"Cyber","Cyber"},{"Sakura","Sakura"},{"Pink Night","Pink Night"},
    {"Blood Moon","Blood Moon"},{"Emerald Dawn","Emerald Dawn"},{"Volcanic","Volcanic"},
    {"Arctic","Arctic"},{"Midnight Ocean","Midnight Ocean"},{"Vaporwave","Vaporwave"},
    {"Toxic","Toxic"},{"Solar Eclipse","Solar Eclipse"},{"Hellscape","Hellscape"},
    {"Heaven","Heaven"},{"Storm","Storm"},{"Sunrise","Sunrise"},{"Deep Space","Deep Space"},
    {"Lavender Dream","Lavender Dream"},{"Inferno","Inferno"},{"Mint Sky","Mint Sky"}
}

local function candySaveOriginalLighting()
    if candyOriginalLighting then return end
    candyOriginalLighting = {
        ClockTime = Lighting.ClockTime,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
    }
end

local function candyClearSky()
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:GetAttribute(CANDY_SKY_TAG) then
            pcall(function() child:Destroy() end)
        end
    end
end

local function candyColor(rgb) return Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end

local function CandyApplyCustomSky(mode)
    candySaveOriginalLighting()
    candyClearSky()
    local preset = CANDY_SKY_PRESETS[mode]
    if not preset or preset.kind == "off" then
        if candyOriginalLighting then
            for k, v in pairs(candyOriginalLighting) do
                pcall(function() Lighting[k] = v end)
            end
        end
        State.currentSkyTheme = "Off"
        return
    end
    Lighting.ClockTime = preset.clock or 14
    Lighting.Brightness = preset.brightness or 2
    if preset.outAmb then Lighting.OutdoorAmbient = candyColor(preset.outAmb) end
    if preset.ambient then Lighting.Ambient = candyColor(preset.ambient) end
    State.currentSkyTheme = mode
end

-- PRESET & FILE MANAGEMENT
local Presets = {}
local PRESET_FILE = "redccPresets.json"
local LAST_PRESET_FILE = "redccLastPreset.json"
local CONFIG_FILE = "redccConfig.json"
local MOBILE_BTN_POS_FILE = "redccMobilePos.json"
local MENU_POS_FILE = "redccMenuPos.json"
local STEALBAR_POS_FILE = "redccStealBarPos.json"
local MENU_VIS_FILE = "redccMenuVis.json"

local function buildPresetSnapshot()
    return {
        normalSpeed=State.normalSpeed, carrySpeed=State.carrySpeed,
        laggerSpeed=State.laggerSpeed, laggerCarrySpeed=State.laggerCarrySpeed,
        stealRadius=Steal.StealRadius, stealDuration=Steal.StealDuration,
        infJump=State.infJumpEnabled, antiRagdoll=State.antiRagdollEnabled,
        fpsBoost=State.fpsBoostEnabled, autoSteal=Steal.AutoStealEnabled,
        fovEnabled=State.fovEnabled, fovValue=State.fovValue,
        stretchRezEnabled=State.stretchRezEnabled,
        medusaCounterEnabled=State.medusaCounterEnabled,
        jumpMode=State.jumpMode,
        batAimbotSpeed=State.batAimbotSpeed, batAimbotLaggerSpeed=State.batAimbotLaggerSpeed,
        enemySpeedMeterEnabled=State.enemySpeedMeterEnabled,
        lockButtonsEnabled=State.lockButtonsEnabled,
        tracersEnabled=State.tracersEnabled, splashEnabled=State.splashEnabled,
        lockInEnabled=State.lockInEnabled, batCounterEnabled=State.batCounterEnabled,
        mobileBtnVisible=State.mobileBtnVisible,
        instantResetEnabled=State.instantResetEnabled,
        instantResetOnMedusa=State.instantResetOnMedusa,
        instantResetKey=State.instantResetKey.Name,
        autoSpeedEnabled=State.autoSpeedEnabled,
        speedToggled=State.speedToggled,
        laggerEnabled=State.laggerEnabled,
        autoLeftEnabled=State.autoLeftEnabled,
        autoRightEnabled=State.autoRightEnabled,
        batAimbotToggled=State.batAimbotToggled,
        currentSkyTheme=State.currentSkyTheme,
    }
end

local function savePresetsFile()
    local ok,enc=pcall(function() return HttpService:JSONEncode(Presets) end)
    if ok then pcall(function() _writefile(PRESET_FILE,enc) end) end
end
local function loadPresetsFile()
    local has=false; pcall(function() has=_isfile(PRESET_FILE) end); if not has then return end
    local raw; pcall(function() raw=_readfile(PRESET_FILE) end); if not raw then return end
    local ok,dec=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and dec then Presets=dec end
end
local function saveLastPresetName(name)
    local ok,enc=pcall(function() return HttpService:JSONEncode({lastPreset=name}) end)
    if ok then pcall(function() _writefile(LAST_PRESET_FILE,enc) end) end
end

local function saveMobileButtonPositions()
    local positions={}
    for _,ref in ipairs(mobileBtnRefs) do
        if ref.frame then
            local pos=ref.frame.Position
            positions[ref.key]={X=pos.X.Scale, Xoff=pos.X.Offset, Y=pos.Y.Scale, Yoff=pos.Y.Offset}
        end
    end
    local ok,enc=pcall(function() return HttpService:JSONEncode(positions) end)
    if ok then pcall(function() _writefile(MOBILE_BTN_POS_FILE,enc) end) end
end
local function loadMobileButtonPositions()
    local has=false; pcall(function() has=_isfile(MOBILE_BTN_POS_FILE) end); if not has then return end
    local raw; pcall(function() raw=_readfile(MOBILE_BTN_POS_FILE) end); if not raw then return end
    local ok,positions=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and positions then
        for _,ref in ipairs(mobileBtnRefs) do
            local pos=positions[ref.key]
            if pos then ref.frame.Position=UDim2.new(pos.X,pos.Xoff,pos.Y,pos.Yoff) end
        end
    end
end

local function saveMenuPosition()
    local mainOuter=gui:FindFirstChild("MainOuter")
    if mainOuter then
        local p=mainOuter.Position
        local data={X=p.X.Scale, Xoff=p.X.Offset, Y=p.Y.Scale, Yoff=p.Y.Offset}
        local ok,enc=pcall(function() return HttpService:JSONEncode(data) end)
        if ok then pcall(function() _writefile(MENU_POS_FILE,enc) end) end
    end
end
local function loadMenuPosition()
    local has=false; pcall(function() has=_isfile(MENU_POS_FILE) end); if not has then return end
    local raw; pcall(function() raw=_readfile(MENU_POS_FILE) end); if not raw then return end
    local ok,pos=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and pos then
        local mainOuter=gui:FindFirstChild("MainOuter")
        if mainOuter then mainOuter.Position=UDim2.new(pos.X,pos.Xoff,pos.Y,pos.Yoff) end
    end
end

local function saveStealBarPosition()
    local sb=gui:FindFirstChild("ToggleGUIButton")
    if sb then
        local p=sb.Position
        local data={X=p.X.Scale, Xoff=p.X.Offset, Y=p.Y.Scale, Yoff=p.Y.Offset}
        local ok,enc=pcall(function() return HttpService:JSONEncode(data) end)
        if ok then pcall(function() _writefile(STEALBAR_POS_FILE,enc) end) end
    end
end
local function loadStealBarPosition()
    local has=false; pcall(function() has=_isfile(STEALBAR_POS_FILE) end); if not has then return end
    local raw; pcall(function() raw=_readfile(STEALBAR_POS_FILE) end); if not raw then return end
    local ok,pos=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and pos then
        local sb=gui:FindFirstChild("ToggleGUIButton")
        if sb then sb.Position=UDim2.new(pos.X,pos.Xoff,pos.Y,pos.Yoff) end
    end
end

local function saveMenuVisibility()
    local mainOuter=gui:FindFirstChild("MainOuter")
    if mainOuter then
        local data={visible=mainOuter.Visible}
        local ok,enc=pcall(function() return HttpService:JSONEncode(data) end)
        if ok then pcall(function() _writefile(MENU_VIS_FILE,enc) end) end
    end
end
local function loadMenuVisibility()
    local has=false; pcall(function() has=_isfile(MENU_VIS_FILE) end); if not has then return end
    local raw; pcall(function() raw=_readfile(MENU_VIS_FILE) end); if not raw then return end
    local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and data then
        local mainOuter=gui:FindFirstChild("MainOuter")
        if mainOuter then mainOuter.Visible=data.visible end
    end
end

local POS = {
    L1=Vector3.new(-476.48,-6.28,92.73), L2=Vector3.new(-483.12,-4.95,94.80),
    R1=Vector3.new(-476.16,-6.52,25.62), R2=Vector3.new(-483.04,-5.09,23.14),
}

local Conns = {autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,anchor={},unwalk=nil,aimbot=nil,batCounter=nil,lockIn=nil,apBlock=nil,fov=nil,stretchRez=nil}

local h, hrp
local normalBox, carryBox, laggerBox, laggerCarryBox, uiScaleBox, stealRadBox
local presetListFrame = nil
local presetNameBox   = nil
local mobileBtnRefs   = {}
local speedModeBtns   = {}

local _autoBatTarget     = nil
local _autoBatLastScan   = 0
local _autoBatEquipped   = false
local _batCounterDebounce= false
local _stealFillRef      = nil
local _lockInOriginalAnims=nil
local _dropActive        = false

-- ============================================================
-- WAVE DROP & TP DOWN
-- ============================================================
local function performDrop()
    if _dropActive then return end
    _dropActive = true
    local char = LP.Character
    if not char then _dropActive = false; return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then _dropActive = false; return end
    local DROP_ASCEND_DURATION = 0.2
    local DROP_ASCEND_SPEED    = 150
    local t0 = tick()
    local dc
    dc = RunService.Heartbeat:Connect(function()
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not r then dc:Disconnect(); _dropActive = false; return end
        if tick() - t0 >= DROP_ASCEND_DURATION then
            dc:Disconnect()
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {LP.Character}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local rr = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), rp)
            if rr then
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                local off = (hum and hum.HipHeight or 2) + (r.Size.Y / 2)
                r.CFrame = CFrame.new(r.Position.X, rr.Position.Y + off, r.Position.Z)
                r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            _dropActive = false
            return
        end
        r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, DROP_ASCEND_SPEED, r.AssemblyLinearVelocity.Z)
    end)
end

local function waveTpDown()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local rr = workspace:Raycast(root.Position, Vector3.new(0, -2000, 0), rp)
    if rr then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local off = (hum and hum.HipHeight or 2) + (root.Size.Y / 2)
        root.CFrame = CFrame.new(root.Position.X, rr.Position.Y + off, root.Position.Z)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

-- ============================================================
-- INSTANT RESET (Cursed Hub style)
-- ============================================================
local function instantReset()
    local char = LP.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
        rootPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end
    local carpet = char:FindFirstChild("Flying Carpet")
    if carpet then carpet:Destroy() end
    if humanoid then
        humanoid.Health = 0
        humanoid:BreakJoints()
    end
    local respawnConn
    respawnConn = LP.CharacterAdded:Connect(function(newChar)
        respawnConn:Disconnect()
        task.wait(0.15)
        local newHumanoid = newChar:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if newHumanoid then
            cam.CameraSubject = newHumanoid
            cam.CameraType = Enum.CameraType.Custom
        end
        local animate = newChar:FindFirstChild("Animate")
        if animate and animate:IsA("LocalScript") then
            animate.Disabled = true
            task.wait(0.05)
            animate.Disabled = false
        end
    end)
end

local function checkMedusaForInstantReset()
    if not State.instantResetEnabled or not State.instantResetOnMedusa then return end
    if State._medusaResetCooldown then return end
    if tick() - State._lastResetTime < 3 then return end
    local char = LP.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Anchored and part.Transparency == 1 then
            State._medusaResetCooldown = true
            State._lastResetTime = tick()
            instantReset()
            task.wait(2)
            State._medusaResetCooldown = false
            break
        end
    end
end

-- ============================================================
-- MEDUSA COUNTER
-- ============================================================
local function findMedusa()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local tn = tool.Name:lower()
            if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = tool.Name:lower()
                if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end
            end
        end
    end
    return nil
end

local function useMedusaCounter()
    if State.medusaDebounce then return end
    if tick() - State.medusaLastUsed < MEDUSA_COOLDOWN then return end
    local char = LP.Character
    if not char then return end
    State.medusaDebounce = true
    local med = findMedusa()
    if not med then State.medusaDebounce = false; return end
    if med.Parent ~= char then
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:EquipTool(med) end
    end
    pcall(function() med:Activate() end)
    State.medusaLastUsed = tick()
    State.medusaDebounce = false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 then
            useMedusaCounter()
            checkMedusaForInstantReset()
        end
    end)
end

local function setupMedusaCounter(char)
    stopMedusaCounter()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(Conns.anchor, onAnchorChanged(part))
        end
    end
    table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(Conns.anchor, onAnchorChanged(part))
        end
    end))
end

local function stopMedusaCounter()
    for _, c in pairs(Conns.anchor) do
        pcall(function() c:Disconnect() end)
    end
    Conns.anchor = {}
end

-- ============================================================
-- STRETCH REZ / FOV
-- ============================================================
local function startStretchRez()
    if Conns.stretchRez then Conns.stretchRez:Disconnect(); Conns.stretchRez = nil end
    Conns.stretchRez = RunService.RenderStepped:Connect(function()
        if not State.stretchRezEnabled then return end
        local cam = workspace.CurrentCamera
        if cam then
            cam.CFrame = cam.CFrame * CFrame.new(0,0,0,1,0,0,0,0.7,0,0,0,1)
        end
    end)
end

local function stopStretchRez()
    if Conns.stretchRez then Conns.stretchRez:Disconnect(); Conns.stretchRez = nil end
end

local _defFov = 70
local function startFov()
    if Conns.fov then return end
    _defFov = workspace.CurrentCamera.FieldOfView
    Conns.fov = RunService.RenderStepped:Connect(function()
        if State.fovEnabled then
            workspace.CurrentCamera.FieldOfView = State.fovValue
        end
    end)
end

local function stopFov()
    if Conns.fov then Conns.fov:Disconnect(); Conns.fov = nil end
    workspace.CurrentCamera.FieldOfView = _defFov
end

-- ============================================================
-- COUNTDOWN BILLBOARD
-- ============================================================
local countdownBB = nil
local countdownLabel = nil
local function createCountdownBillboard()
    if countdownBB then return end
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    countdownBB = Instance.new("BillboardGui", head)
    countdownBB.Name = "BatCountdownBB"
    countdownBB.Size = UDim2.new(0,80,0,30)
    countdownBB.StudsOffset = Vector3.new(0,3.2,0)
    countdownBB.AlwaysOnTop = true
    countdownBB.Enabled = false
    countdownLabel = Instance.new("TextLabel", countdownBB)
    countdownLabel.Size = UDim2.new(1,0,1,0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = ""
    countdownLabel.Font = Enum.Font.GothamBlack
    countdownLabel.TextSize = 24
    countdownLabel.TextStrokeTransparency = 0
    countdownLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
end

local function showBatCountdown()
    createCountdownBillboard()
    if not countdownBB or not countdownLabel then return end
    countdownBB.Enabled = true
    local steps = {
        {text="3", color=Color3.fromRGB(255,50,50), wait=1},
        {text="2", color=Color3.fromRGB(255,200,30), wait=1},
        {text="1", color=Color3.fromRGB(80,255,100), wait=1},
        {text="STEAL!", color=Color3.fromRGB(255,255,255), wait=0.6}
    }
    task.spawn(function()
        for _, step in ipairs(steps) do
            if countdownLabel then
                countdownLabel.Text = step.text
                countdownLabel.TextColor3 = step.color
            end
            task.wait(step.wait)
        end
        if countdownBB then countdownBB.Enabled = false end
        if countdownLabel then countdownLabel.Text = "" end
    end)
end

LP.CharacterAdded:Connect(function()
    countdownBB = nil
    countdownLabel = nil
    task.wait(0.5)
    createCountdownBillboard()
end)

-- ============================================================
-- TRACERS (RED)
-- ============================================================
local tracerLines = {}
local function clearTracers()
    for _, line in pairs(tracerLines) do
        pcall(function() line:Remove() end)
    end
    tracerLines = {}
end

local function updateTracers()
    if not State.tracersEnabled then
        clearTracers()
        return
    end
    local camera = workspace.CurrentCamera
    local char = LP.Character
    local myHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not myHRP or not camera then
        clearTracers()
        return
    end
    local validKeys = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                validKeys[tostring(plr.UserId)] = {plr = plr, hrp = tHRP}
            end
        end
    end
    for key, line in pairs(tracerLines) do
        if not validKeys[key] then
            pcall(function() line:Remove() end)
            tracerLines[key] = nil
        end
    end
    local screenSize = camera.ViewportSize
    local fromX = screenSize.X / 2
    local fromY = screenSize.Y
    for key, data in pairs(validKeys) do
        local tPos, onScreen = camera:WorldToViewportPoint(data.hrp.Position)
        if onScreen then
            local line = tracerLines[key]
            if not line and Drawing then
                line = Drawing.new("Line")
                line.Thickness = 2
                line.Color = Color3.fromRGB(255,0,0)
                line.Transparency = 0.7
                line.Visible = true
                tracerLines[key] = line
            end
            if line then
                line.From = Vector2.new(fromX, fromY)
                line.To = Vector2.new(tPos.X, tPos.Y)
                line.Visible = true
            end
        else
            local line = tracerLines[key]
            if line then line.Visible = false end
        end
    end
end

-- ============================================================
-- ENEMY SPEED METER (RED TEXT)
-- ============================================================
local enemySpeedLabels = {}
local function setupEnemySpeedMeter(player)
    if player == LP then return end
    local function onChar(char)
        task.spawn(function()
            local head = char:WaitForChild("Head", 5)
            if not head then return end
            local oldBB = head:FindFirstChild("EnemySpeedBB")
            if oldBB then oldBB:Destroy() end
            local bb = Instance.new("BillboardGui", head)
            bb.Name = "EnemySpeedBB"
            bb.Size = UDim2.new(0,100,0,20)
            bb.StudsOffset = Vector3.new(0,3.2,0)
            bb.AlwaysOnTop = true
            bb.Enabled = State.enemySpeedMeterEnabled
            local lbl = Instance.new("TextLabel", bb)
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "0"
            lbl.TextColor3 = Color3.fromRGB(255,51,51)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextScaled = true
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
            enemySpeedLabels[player] = {lbl = lbl, char = char, lastPos = nil, lastTick = nil, billboard = bb}
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

local function updateAllSpeedMetersVisibility()
    for _, data in pairs(enemySpeedLabels) do
        if data.billboard then
            data.billboard.Enabled = State.enemySpeedMeterEnabled
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not State.enemySpeedMeterEnabled then return end
    for player, data in pairs(enemySpeedLabels) do
        pcall(function()
            if not data.char or not data.char.Parent then return end
            local hrp2 = data.char:FindFirstChild("HumanoidRootPart")
            if not hrp2 then return end
            local now = tick()
            if data.lastPos and data.lastTick then
                local dt = now - data.lastTick
                if dt > 0 then
                    local spd = (hrp2.Position - data.lastPos).Magnitude / dt
                    data.lbl.Text = tostring(math.floor(spd + 0.5))
                end
            end
            data.lastPos = hrp2.Position
            data.lastTick = now
        end)
    end
end)

-- ============================================================
-- SPLASH TEXT
-- ============================================================
local splashFrame = nil
local function showSplashText()
    if not State.splashEnabled then return end
    if splashFrame then pcall(function() splashFrame:Destroy() end); splashFrame = nil end
    local guiRoot = LP:FindFirstChild("PlayerGui")
    if not guiRoot then return end
    local sg = Instance.new("ScreenGui", guiRoot)
    sg.Name = "CrazedSplashGui"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 200
    sg.IgnoreGuiInset = true
    splashFrame = sg
    local textLabel = Instance.new("TextLabel", sg)
    textLabel.Size = UDim2.new(0,750,0,150)
    textLabel.Position = UDim2.new(0.5,-375,0.5,-75)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.fromRGB(255,255,255)
    textLabel.Font = Enum.Font.GothamBlack
    textLabel.TextSize = 56
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.ZIndex = 101
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = Color3.fromRGB(30,30,30)
    local fullText = "red.cc"
    local charIndex = 0
    task.spawn(function()
        local typeInterval = 4 / #fullText
        while charIndex < #fullText do
            charIndex = charIndex + 1
            if textLabel and textLabel.Parent then
                textLabel.Text = string.sub(fullText, 1, charIndex)
            end
            task.wait(typeInterval)
        end
        task.wait(1)
        local fadeDuration = 1
        local fadeStart = tick()
        while tick() - fadeStart < fadeDuration do
            if textLabel and textLabel.Parent then
                local alpha = 1 - ((tick() - fadeStart) / fadeDuration)
                textLabel.TextTransparency = 1 - alpha
                textLabel.TextStrokeTransparency = 0.3 + (0.7 * (1 - alpha))
            end
            task.wait(0.03)
        end
        if sg and sg.Parent then pcall(function() sg:Destroy() end) end
        splashFrame = nil
    end)
end

-- ============================================================
-- COLORS (RED THEME)
-- ============================================================
local RED_MAIN = Color3.fromRGB(255, 51, 51)
local RED_DARK = Color3.fromRGB(200, 30, 30)
local RED_DIM = Color3.fromRGB(180, 40, 40)
local BG_DARK = Color3.fromRGB(8, 8, 10)

local C = {
    winBg = BG_DARK, winBorder = RED_MAIN, topBg = Color3.fromRGB(12,12,16),
    topTitle = RED_MAIN, tabBarBg = Color3.fromRGB(8,8,12), tabIdle = RED_DIM,
    tabActive = RED_MAIN, tabActiveBg = Color3.fromRGB(50,10,10),
    rowBg = Color3.fromRGB(10,10,14), rowLabel = RED_MAIN, rowSub = RED_DIM,
    inputBg = Color3.fromRGB(10,10,14), inputTxt = RED_MAIN,
    pillOff = Color3.fromRGB(25,25,35), pillOn = Color3.fromRGB(80,20,20),
    dotOff = Color3.fromRGB(100,100,120), dotOn = RED_MAIN,
    modeBtnBg = Color3.fromRGB(16,16,22), modeBtnTxt = RED_DIM,
    modeBtnActBg = Color3.fromRGB(60,20,20), modeBtnActTx = RED_MAIN,
    chipBg = Color3.fromRGB(10,10,14), chipTxt = RED_DIM,
    btnBg = Color3.fromRGB(12,12,16), btnTxt = RED_MAIN, btnHov = Color3.fromRGB(30,10,10),
    accent = RED_MAIN,
    presetBg = Color3.fromRGB(10,10,14), presetLoad = Color3.fromRGB(40,20,20), presetDel = Color3.fromRGB(25,10,10),
    floatBtnBg = BG_DARK, floatBtnBrd = RED_MAIN, floatBtnTxt = RED_MAIN,
    floatBtnOn = Color3.fromRGB(35,10,10), floatBtnOnBrd = RED_MAIN,
    dotGreenOn = RED_MAIN, dotGreenOff = RED_DIM,
    stealTrackBg = Color3.fromRGB(18,18,25), stealFill = RED_MAIN,
    gearColor = RED_MAIN, inputFocus = RED_MAIN,
}

-- ============================================================
-- CLEANUP OLD GUIs
-- ============================================================
for _, name in pairs({"VyseSlottedGUI","VyseAsireGUI","VyseAsireHubV5",
    "VyseAsireHubV5_1","AsireHubV5_1","AsireHubV5_2","OpiumGGV5_2","WrathDuels","SixHub",
    "AstraHub","AstraDuels","HonorDuels","SinDuels","GhoulDuels","CrazedDuels","FAMILYDUELSPC", "redcc"}) do
    pcall(function()
        local o = CoreGui:FindFirstChild(name)
        if o then o:Destroy() end
    end)
    pcall(function()
        local o = LP:WaitForChild("PlayerGui"):FindFirstChild(name)
        if o then o:Destroy() end
    end)
end

-- ============================================================
-- ROOT GUI (solid black background)
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "redcc"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP:WaitForChild("PlayerGui")
local uiScaleObj = Instance.new("UIScale", gui)
uiScaleObj.Scale = 1.0

local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    frame.InputBegan:Connect(function(inp)
        if State.lockButtonsEnabled then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local dx = inp.Position.X - dragStart.X
            local dy = inp.Position.Y - dragStart.Y
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
            autoSave()
        end
    end)
end

-- ============================================================
-- MENU BUTTON (STEAL BAR + DRAGGABLE)
-- ============================================================
local MENU_BTN_W = 210
local MENU_BTN_H = 56
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Name = "ToggleGUIButton"
toggleBtn.Size = UDim2.new(0, MENU_BTN_W, 0, MENU_BTN_H)
toggleBtn.Position = UDim2.new(0.5, -MENU_BTN_W/2, 0, 70)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = ""
toggleBtn.ZIndex = 20
mkCorner(toggleBtn, 10)
makeDraggable(toggleBtn)

local menuTitleLbl = Instance.new("TextLabel", toggleBtn)
menuTitleLbl.Size = UDim2.new(1, 0, 0, 16)
menuTitleLbl.Position = UDim2.new(0, 0, 0, 5)
menuTitleLbl.BackgroundTransparency = 1
menuTitleLbl.Text = "red.cc"
menuTitleLbl.TextColor3 = RED_MAIN
menuTitleLbl.Font = Enum.Font.GothamBold
menuTitleLbl.TextSize = 14
menuTitleLbl.TextYAlignment = Enum.TextYAlignment.Center
menuTitleLbl.ZIndex = 21

-- + button for ping
local statsToggleBtn = Instance.new("TextButton", toggleBtn)
statsToggleBtn.Size = UDim2.new(0,22,0,22); statsToggleBtn.Position = UDim2.new(1,-26,0,4)
statsToggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,20); statsToggleBtn.BorderSizePixel = 0
statsToggleBtn.Text = "+"; statsToggleBtn.TextColor3 = RED_MAIN
statsToggleBtn.Font = Enum.Font.GothamBlack; statsToggleBtn.TextSize = 14; statsToggleBtn.ZIndex = 25
mkCorner(statsToggleBtn, 5); mkStroke(statsToggleBtn, RED_DIM, 1)
local statsPanel = Instance.new("Frame", toggleBtn)
statsPanel.Size = UDim2.new(1,0,0,16); statsPanel.Position = UDim2.new(0,0,0,18)
statsPanel.BackgroundTransparency = 1; statsPanel.BorderSizePixel = 0; statsPanel.ZIndex = 22; statsPanel.Visible = false
local pingLbl = Instance.new("TextLabel", statsPanel)
pingLbl.Size = UDim2.new(1,-16,1,0); pingLbl.Position = UDim2.new(0,8,0,0)
pingLbl.BackgroundTransparency = 1; pingLbl.Text = "PING: --ms"
pingLbl.TextColor3 = RED_MAIN; pingLbl.Font = Enum.Font.GothamBold; pingLbl.TextSize = 10
pingLbl.TextXAlignment = Enum.TextXAlignment.Left; pingLbl.ZIndex = 23
local statsOpen = false
statsToggleBtn.MouseButton1Click:Connect(function()
    statsOpen = not statsOpen; statsPanel.Visible = statsOpen
    statsToggleBtn.Text = statsOpen and "-" or "+"
end)
RunService.Heartbeat:Connect(function()
    if not statsOpen then return end
    pcall(function()
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()+0.5)
        pingLbl.Text = "PING: "..ping.."ms"
    end)
end)
local stealTrack = Instance.new("Frame", toggleBtn)
stealTrack.Size = UDim2.new(0.97, 0, 0, 16)
stealTrack.Position = UDim2.new(0.015, 0, 0, 35)
stealTrack.BackgroundColor3 = C.stealTrackBg
stealTrack.BorderSizePixel = 0
stealTrack.ZIndex = 21
mkCorner(stealTrack, 6)

local stealFill = Instance.new("Frame", stealTrack)
stealFill.Size = UDim2.new(0, 0, 1, 0)
stealFill.BackgroundColor3 = C.stealFill
stealFill.BorderSizePixel = 0
stealFill.ZIndex = 22
mkCorner(stealFill, 6)
_stealFillRef = stealFill

local _menuTween = nil
local _menuOrigPos = nil
toggleBtn.MouseButton1Click:Connect(function()
    local mainOuter = gui:FindFirstChild("MainOuter")
    if not mainOuter then return end
    if _menuTween then _menuTween:Cancel() end
    if not _menuOrigPos then _menuOrigPos = mainOuter.Position end
    if not mainOuter.Visible then
        mainOuter.Visible = true
        mainOuter.Position = UDim2.new(_menuOrigPos.X.Scale, _menuOrigPos.X.Offset, _menuOrigPos.Y.Scale, _menuOrigPos.Y.Offset - 20)
        _menuTween = TweenService:Create(mainOuter, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = _menuOrigPos})
        _menuTween:Play()
        autoSave()
    else
        local slideOut = UDim2.new(_menuOrigPos.X.Scale, _menuOrigPos.X.Offset, _menuOrigPos.Y.Scale, _menuOrigPos.Y.Offset - 20)
        _menuTween = TweenService:Create(mainOuter, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = slideOut})
        _menuTween:Play()
        _menuTween.Completed:Connect(function()
            mainOuter.Visible = false
            mainOuter.Position = _menuOrigPos
            autoSave()
        end)
    end
end)

-- ============================================================
-- MAIN WINDOW (solid black background)
-- ============================================================
local WIN_W = 440
local WIN_H = 540
local TITLE_H = 48
local mainOuter = Instance.new("Frame", gui)
mainOuter.Name = "MainOuter"
mainOuter.Size = UDim2.new(0, WIN_W, 0, WIN_H)
mainOuter.Position = UDim2.new(0, 20, 0, 80)
mainOuter.BackgroundColor3 = BG_DARK
mainOuter.BorderSizePixel = 0
mainOuter.ClipsDescendants = true
mainOuter.Visible = true
mkCorner(mainOuter, 14)

local titleBar = Instance.new("Frame", mainOuter)
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.topBg
titleBar.BackgroundTransparency = 0
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 5
mkCorner(titleBar, 14)
makeDraggable(mainOuter)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1, 0, 1, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "red.cc"
titleLbl.TextColor3 = RED_MAIN
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Center
titleLbl.TextYAlignment = Enum.TextYAlignment.Center
titleLbl.ZIndex = 6

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundTransparency = 1
closeBtn.BorderSizePixel = 0
closeBtn.Text = "-"
closeBtn.TextColor3 = RED_MAIN
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 24
closeBtn.ZIndex = 7
closeBtn.MouseButton1Click:Connect(function()
    mainOuter.Visible = false
    autoSave()
end)

-- TAB BAR
local TAB_W = 128
local TABS = {"Speed","Configs","Keybinds","Visual","Settings","Buttons"}
local currentTab = "Speed"
local tabBtns = {}
local tabPages = {}

local contentContainer = Instance.new("Frame", mainOuter)
contentContainer.Size = UDim2.new(1, 0, 1, -TITLE_H)
contentContainer.Position = UDim2.new(0, 0, 0, TITLE_H)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ZIndex = 2

local tabImg = Instance.new("ImageLabel", contentContainer)
tabImg.Size = UDim2.new(0, TAB_W, 1, 0); tabImg.Position = UDim2.new(0,0,0,0)
tabImg.BackgroundTransparency = 1; tabImg.Image = "rbxassetid://75924440436306"
tabImg.ScaleType = Enum.ScaleType.Crop; tabImg.ZIndex = 1; mkCorner(tabImg, 12)
local tabBar = Instance.new("Frame", contentContainer)
tabBar.Size = UDim2.new(0, TAB_W, 1, 0)
tabBar.BackgroundColor3 = C.tabBarBg
tabBar.BackgroundTransparency = 0.45
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 5
mkCorner(tabBar, 12)

local tabList = Instance.new("UIListLayout", tabBar)
tabList.FillDirection = Enum.FillDirection.Vertical
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 10)
tabList.VerticalAlignment = Enum.VerticalAlignment.Top
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingTop = UDim.new(0, 18)
tabPad.PaddingBottom = UDim.new(0, 12)
tabPad.PaddingLeft = UDim.new(0, 8)
tabPad.PaddingRight = UDim.new(0, 8)

local contentArea = Instance.new("Frame", contentContainer)
contentArea.Size = UDim2.new(1, -TAB_W, 1, 0)
contentArea.Position = UDim2.new(0, TAB_W, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true

for i, name in ipairs(TABS) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = (name == currentTab) and C.tabActiveBg or Color3.fromRGB(0,0,0)
    btn.BackgroundTransparency = (name == currentTab) and 0 or 1
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = (name == currentTab) and C.tabActive or C.tabIdle
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.ZIndex = 6
    btn.LayoutOrder = i
    mkCorner(btn, 10)
    tabBtns[name] = btn
    btn.MouseButton1Click:Connect(function()
        currentTab = name
        for _, n in ipairs(TABS) do
            local b = tabBtns[n]
            local active = (n == name)
            TweenService:Create(b, TweenInfo.new(0.12), {
                TextColor3 = active and C.tabActive or C.tabIdle,
                BackgroundColor3 = active and C.tabActiveBg or Color3.fromRGB(0,0,0),
                BackgroundTransparency = active and 0 or 1
            }):Play()
            if tabPages[n] then
                tabPages[n].Visible = active
            end
        end
    end)
end

-- PAGE BUILDER HELPERS
local currentPage = nil
local lo = 0
local function LO()
    lo = lo + 1
    return lo
end
local function makeGap(px)
    local f = Instance.new("Frame", currentPage)
    f.Size = UDim2.new(1, 0, 0, px or 6)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.LayoutOrder = LO()
end
local function makeSectionHeader(label)
    local wrap = Instance.new("Frame", currentPage)
    wrap.Size = UDim2.new(1, 0, 0, 28)
    wrap.BackgroundTransparency = 1
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = LO()
    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label and label:upper() or ""
    lbl.TextColor3 = C.accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeInputRow(label, default, onChange, boxOffset, transparentBg)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.rowLabel
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local boxWrap = Instance.new("Frame", row)
    boxWrap.Size = UDim2.new(0, 68, 0, 32)
    boxWrap.Position = UDim2.new(1, -(boxOffset or 82), 0.5, -16)
    if transparentBg then
        boxWrap.BackgroundTransparency = 1
    else
        boxWrap.BackgroundColor3 = C.inputBg
        boxWrap.BackgroundTransparency = 0
    end
    boxWrap.BorderSizePixel = 0
    mkCorner(boxWrap, 8)
    local box = Instance.new("TextBox", boxWrap)
    box.Size = UDim2.new(1, -8, 1, 0)
    box.Position = UDim2.new(0, 4, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = tostring(default)
    box.TextColor3 = C.inputTxt
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.ZIndex = 8
    box.TextXAlignment = Enum.TextXAlignment.Center
    if onChange then
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then
                onChange(n)
            else
                box.Text = tostring(default)
            end
            autoSave()
        end)
    end
    return box, row
end

local toggleStateSetters = {}

local function makeToggleRow(label, defaultOn, onToggle, rowHeight)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, rowHeight or 44)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.rowLabel
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local pillBg = Instance.new("Frame", row)
    pillBg.Size = UDim2.new(0, 44, 0, 22)
    pillBg.Position = UDim2.new(1, -58, 0.5, -11)
    pillBg.BackgroundColor3 = defaultOn and C.pillOn or C.pillOff
    pillBg.BorderSizePixel = 0
    pillBg.ZIndex = 7
    mkCorner(pillBg, 11)
    local dot = Instance.new("Frame", pillBg)
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = defaultOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = defaultOn and C.dotOn or C.dotOff
    dot.BorderSizePixel = 0
    dot.ZIndex = 8
    mkCorner(dot, 8)
    local isOn = defaultOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pillBg, TweenInfo.new(0.18), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = on and C.dotOn or C.dotOff
        }):Play()
        autoSave()
    end
    local function toggle()
        isOn = not isOn
        setV(isOn)
        if onToggle then
            pcall(onToggle, isOn)
        end
        autoSave()
    end
    local clk = Instance.new("TextButton", row)
    clk.Size = UDim2.new(1, -58, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 5
    clk.BorderSizePixel = 0
    clk.MouseButton1Click:Connect(toggle)
    local pClk = Instance.new("TextButton", pillBg)
    pClk.Size = UDim2.new(1, 0, 1, 0)
    pClk.BackgroundTransparency = 1
    pClk.Text = ""
    pClk.ZIndex = 9
    pClk.BorderSizePixel = 0
    pClk.MouseButton1Click:Connect(toggle)
    table.insert(toggleStateSetters, setV)
    return setV
end

local function makeFovSliderRow(defaultVal, onChange)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0, 60, 0, 14)
    lbl.Position = UDim2.new(0, 14, 0, 11)
    lbl.BackgroundTransparency = 1
    lbl.Text = "FOV:"
    lbl.TextColor3 = C.rowSub
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0, 30, 0, 14)
    valLbl.Position = UDim2.new(1, -44, 0, 11)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(math.floor(defaultVal))
    valLbl.TextColor3 = C.accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 10
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    local trackBg = Instance.new("Frame", row)
    trackBg.Size = UDim2.new(1, -110, 0, 6)
    trackBg.Position = UDim2.new(0, 52, 0.5, -3)
    trackBg.BackgroundColor3 = Color3.fromRGB(30,30,40)
    trackBg.BorderSizePixel = 0
    mkCorner(trackBg, 3)
    local fill = Instance.new("Frame", trackBg)
    fill.Size = UDim2.new((defaultVal - 70) / 50, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    mkCorner(fill, 3)
    local handle = Instance.new("Frame", trackBg)
    handle.Size = UDim2.new(0, 12, 0, 12)
    handle.Position = UDim2.new((defaultVal - 70) / 50, -6, 0.5, -6)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    handle.BorderSizePixel = 0
    handle.ZIndex = 3
    mkCorner(handle, 6)
    local dragging = false
    local btn = Instance.new("TextButton", trackBg)
    btn.Size = UDim2.new(1, 0, 1, 24)
    btn.Position = UDim2.new(0, 0, 0, -12)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 4
    local function updateSlider(absX)
        local abs = trackBg.AbsolutePosition
        local sz = trackBg.AbsoluteSize
        local pct = math.clamp((absX - abs.X) / sz.X, 0, 1)
        local val = math.floor(70 + pct * 50)
        State.fovValue = val
        fill.Size = UDim2.new(pct, 0, 1, 0)
        handle.Position = UDim2.new(pct, -6, 0.5, -6)
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
        autoSave()
    end
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(inp.Position.X)
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            updateSlider(inp.Position.X)
        end
    end)
    local function setSliderValue(val)
        val = math.clamp(math.floor(val), 70, 120)
        local pct = (val - 70) / 50
        State.fovValue = val
        fill.Size = UDim2.new(pct, 0, 1, 0)
        handle.Position = UDim2.new(pct, -6, 0.5, -6)
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
        autoSave()
    end
    return setSliderValue
end

local function makeGearToggleRow(label, defaultOn, onToggle, gearCallback)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    local gearBtn = Instance.new("TextButton", row)
    gearBtn.Size = UDim2.new(0, 22, 0, 22)
    gearBtn.Position = UDim2.new(1, -90, 0.5, -11)
    gearBtn.BackgroundTransparency = 1
    gearBtn.BorderSizePixel = 0
    gearBtn.Text = "+"
    gearBtn.TextColor3 = RED_MAIN
    gearBtn.Font = Enum.Font.GothamBlack
    gearBtn.TextSize = 18
    gearBtn.ZIndex = 9
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.rowLabel
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local pillBg = Instance.new("Frame", row)
    pillBg.Size = UDim2.new(0, 44, 0, 22)
    pillBg.Position = UDim2.new(1, -58, 0.5, -11)
    pillBg.BackgroundColor3 = defaultOn and C.pillOn or C.pillOff
    pillBg.BorderSizePixel = 0
    pillBg.ZIndex = 7
    mkCorner(pillBg, 11)
    local dot = Instance.new("Frame", pillBg)
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = defaultOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = defaultOn and C.dotOn or C.dotOff
    dot.BorderSizePixel = 0
    dot.ZIndex = 8
    mkCorner(dot, 8)
    local isOn = defaultOn or false
    local function setV(on)
        isOn = on
        TweenService:Create(pillBg, TweenInfo.new(0.18), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = on and C.dotOn or C.dotOff
        }):Play()
        autoSave()
    end
    local function toggle()
        isOn = not isOn
        setV(isOn)
        if onToggle then pcall(onToggle, isOn) end
        autoSave()
    end
    local clk = Instance.new("TextButton", row)
    clk.Size = UDim2.new(1, -58, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text = ""
    clk.ZIndex = 5
    clk.BorderSizePixel = 0
    clk.MouseButton1Click:Connect(toggle)
    local pClk = Instance.new("TextButton", pillBg)
    pClk.Size = UDim2.new(1, 0, 1, 0)
    pClk.BackgroundTransparency = 1
    pClk.Text = ""
    pClk.ZIndex = 9
    pClk.BorderSizePixel = 0
    pClk.MouseButton1Click:Connect(toggle)
    local expandFrame = Instance.new("Frame", currentPage)
    expandFrame.Size = UDim2.new(1, 0, 0, 0)
    expandFrame.BackgroundTransparency = 1
    expandFrame.BorderSizePixel = 0
    expandFrame.LayoutOrder = LO()
    expandFrame.ClipsDescendants = true
    expandFrame.Visible = false
    local expandLL = Instance.new("UIListLayout", expandFrame)
    expandLL.SortOrder = Enum.SortOrder.LayoutOrder
    expandLL.Padding = UDim.new(0, 6)
    local expanded = false
    local _expandTween = nil
    gearBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if gearCallback then gearCallback(expandFrame, expanded) end
        if expanded then
            expandFrame.Visible = true
            if _expandTween then _expandTween:Cancel() end
            local targetSize = expandFrame.Size
            expandFrame.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, 0)
            _expandTween = TweenService:Create(expandFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize})
            _expandTween:Play()
        else
            if _expandTween then _expandTween:Cancel() end
            local startSize = expandFrame.Size
            _expandTween = TweenService:Create(expandFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Size = UDim2.new(startSize.X.Scale, startSize.X.Offset, 0, 0)})
            _expandTween:Play()
            _expandTween.Completed:Connect(function()
                if not expanded then expandFrame.Visible = false end
            end)
        end
        gearBtn.TextColor3 = expanded and C.inputFocus or RED_MAIN
    end)
    table.insert(toggleStateSetters, setV)
    return setV
end

local function getKeyDisplayName(kc)
    local n = kc.Name
    local gp = {
        ButtonA = "A", ButtonB = "B", ButtonX = "X", ButtonY = "Y",
        ButtonL1 = "LB", ButtonL2 = "LT", ButtonL3 = "LS",
        ButtonR1 = "RB", ButtonR2 = "RT", ButtonR3 = "RS",
        ButtonSelect = "SEL", ButtonStart = "STA",
        DPadUp = "D↑", DPadDown = "D↓", DPadLeft = "D←", DPadRight = "D→"
    }
    if gp[n] then return gp[n] end
    return n:sub(1,5)
end

local function makeKeybindRow(label, currentKey, onChanged, boxOffset)
    local row = Instance.new("Frame", currentPage)
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = LO()
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.rowLabel
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local kbtn = Instance.new("TextButton", row)
    kbtn.Size = UDim2.new(0, 56, 0, 30)
    kbtn.Position = UDim2.new(1, -(boxOffset or 68), 0.5, -15)
    kbtn.BackgroundColor3 = C.chipBg
    kbtn.BorderSizePixel = 0
    kbtn.Text = getKeyDisplayName(currentKey)
    kbtn.TextColor3 = C.chipTxt
    kbtn.Font = Enum.Font.GothamBold
    kbtn.TextSize = 12
    kbtn.ZIndex = 8
    mkCorner(kbtn, 8)
    local listening = false
    local lconnKB, lconnGP = nil, nil
    local function stopL(key)
        listening = false
        if lconnKB then lconnKB:Disconnect(); lconnKB = nil end
        if lconnGP then lconnGP:Disconnect(); lconnGP = nil end
        if key then
            kbtn.Text = getKeyDisplayName(key)
            if onChanged then onChanged(key) end
            autoSave()
        end
    end
    kbtn.MouseButton1Click:Connect(function()
        if listening then
            stopL(nil)
            return
        end
        listening = true
        kbtn.Text = "..."
        kbtn.TextColor3 = C.inputTxt
        lconnKB = UIS.InputBegan:Connect(function(inp)
            if not listening then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if inp.KeyCode == Enum.KeyCode.Escape then
                stopL(nil)
                return
            end
            stopL(inp.KeyCode)
        end)
        lconnGP = UIS.InputBegan:Connect(function(inp)
            if not listening then return end
            if inp.UserInputType ~= Enum.UserInputType.Gamepad1 and inp.UserInputType ~= Enum.UserInputType.Gamepad2 then return end
            local kc = inp.KeyCode
            if kc == Enum.KeyCode.Unknown then return end
            stopL(kc)
        end)
    end)
    return kbtn
end

local function buildPage(tabName, buildFn)
    local page = Instance.new("ScrollingFrame", contentArea)
    page.Name = tabName
    page.Visible = (tabName == "Speed")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = RED_MAIN
    page.ScrollBarImageTransparency = 0.4
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    local ll = Instance.new("UIListLayout", page)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0, 8)
    tabPages[tabName] = page
    currentPage = page
    lo = 0
    buildFn()
    currentPage = nil
end

-- ============================================================
-- SPEED PAGE
-- ============================================================
buildPage("Speed", function()
    makeSectionHeader("NORMAL SPEEDS")
    makeGap(4)
    local speedModes = {
        {label="Normal Speed", key="normal", state=function() return not State.speedToggled and not State.laggerEnabled end,
         default=State.normalSpeed, onChange=function(n) if n>0 and n<=500 then State.normalSpeed=n end; autoSave() end},
        {label="Carry Speed", key="carry", state=function() return State.speedToggled and not State.laggerEnabled end,
         default=State.carrySpeed, onChange=function(n) if n>0 and n<=500 then State.carrySpeed=n end; autoSave() end},
    }
    speedModeBtns = {}
    for i, mode in ipairs(speedModes) do
        local row = Instance.new("Frame", currentPage)
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.LayoutOrder = LO()
        local modeBtn = Instance.new("TextButton", row)
        modeBtn.Size = UDim2.new(0, 110, 0, 42)
        modeBtn.Position = UDim2.new(0, 6, 0.5, -21)
        modeBtn.BackgroundColor3 = mode.state() and C.modeBtnActBg or Color3.fromRGB(0,0,0)
        modeBtn.BackgroundTransparency = mode.state() and 0 or 1
        modeBtn.BorderSizePixel = 0
        modeBtn.Text = mode.label
        modeBtn.TextColor3 = mode.state() and C.modeBtnActTx or C.modeBtnTxt
        modeBtn.Font = Enum.Font.GothamBold
        modeBtn.TextSize = 11
        modeBtn.ZIndex = 9
        mkCorner(modeBtn, 8)
        table.insert(speedModeBtns, {btn = modeBtn, mode = mode})
        local boxWrap = Instance.new("Frame", row)
        boxWrap.Size = UDim2.new(0, 56, 0, 30)
        boxWrap.Position = UDim2.new(1, -74, 0.5, -15)
        boxWrap.BackgroundColor3 = C.inputBg
        boxWrap.BorderSizePixel = 0
        mkCorner(boxWrap, 8)
        local box = Instance.new("TextBox", boxWrap)
        box.Size = UDim2.new(1, -8, 1, 0)
        box.Position = UDim2.new(0, 4, 0, 0)
        box.BackgroundTransparency = 1
        box.Text = tostring(mode.default)
        box.TextColor3 = C.inputTxt
        box.Font = Enum.Font.GothamBold
        box.TextSize = 13
        box.ClearTextOnFocus = false
        box.ZIndex = 8
        box.TextXAlignment = Enum.TextXAlignment.Center
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then
                mode.onChange(n)
            else
                box.Text = tostring(mode.default)
            end
            autoSave()
        end)
        if mode.key == "normal" then normalBox = box elseif mode.key == "carry" then carryBox = box end
        modeBtn.MouseButton1Click:Connect(function()
            State.speedToggled = false
            State.laggerEnabled = false
            if mode.key == "carry" then State.speedToggled = true end
            if State._prevBatSpeed then
                State.batAimbotSpeed = State._prevBatSpeed
                State._prevBatSpeed = nil
            end
            for _, sm in ipairs(speedModeBtns) do
                local active = sm.mode.state()
                TweenService:Create(sm.btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = active and C.modeBtnActBg or Color3.fromRGB(0,0,0),
                    BackgroundTransparency = active and 0 or 1,
                    TextColor3 = active and C.modeBtnActTx or C.modeBtnTxt
                }):Play()
            end
            autoSave()
        end)
    end
    makeGap(6)
    makeSectionHeader("LAGGER MODE")
    makeGap(4)
    makeToggleRow("Lagger Mode", false, function(on)
        State.laggerEnabled = on
        if on then
            State._prevBatSpeed = State.batAimbotSpeed
            State.batAimbotSpeed = State.batAimbotLaggerSpeed
        else
            if State._prevBatSpeed then
                State.batAimbotSpeed = State._prevBatSpeed
                State._prevBatSpeed = nil
            end
        end
        for _, sm in ipairs(speedModeBtns) do
            local active = sm.mode.state()
            TweenService:Create(sm.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = active and C.modeBtnActBg or Color3.fromRGB(0,0,0),
                BackgroundTransparency = active and 0 or 1,
                TextColor3 = active and C.modeBtnActTx or C.modeBtnTxt
            }):Play()
        end
        autoSave()
    end)
    laggerBox = makeInputRow("Lagger Speed Normal", State.laggerSpeed, function(n) if n>0 and n<=500 then State.laggerSpeed=n end; autoSave() end, 70)
    laggerCarryBox = makeInputRow("Lagger Speed Carry", State.laggerCarrySpeed, function(n) if n>0 and n<=500 then State.laggerCarrySpeed=n end; autoSave() end, 70)

    makeGap(6)
    makeSectionHeader("AUTO SPEED SWITCH")
    makeGap(4)
    makeToggleRow("Auto Speed Switch", false, function(on)
        State.autoSpeedEnabled = on
        autoSave()
    end)
end)

-- ============================================================
-- CONFIGS PAGE
-- ============================================================
buildPage("Configs", function()
    local setInstaGrab = makeToggleRow("Auto Steal", false, function(on)
        Steal.AutoStealEnabled = on
        if on then
            if not pcall(startAutoSteal) then
                Steal.AutoStealEnabled = false
                setInstaGrab(false)
            end
        else
            stopAutoSteal()
        end
        autoSave()
    end)
    stealRadBox = makeInputRow("Steal Radius", Steal.StealRadius, function(n) if n>=5 and n<=300 then Steal.StealRadius = math.floor(n); Steal.cachedPrompts = {}; Steal.promptCacheTime = 0 end; autoSave() end, 70)
    makeInputRow("Steal Duration", Steal.StealDuration, function(n) if n>=0.05 and n<=2 then Steal.StealDuration = n end; autoSave() end, 70)
    makeGearToggleRow("Infinite Jump", false, function(on)
        State.infJumpEnabled = on
        autoSave()
    end, function(expandFrame, expanded)
        if expanded then
            for _, child in ipairs(expandFrame:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
            expandFrame.Size = UDim2.new(1, 0, 0, 44)
            local jmRow = Instance.new("Frame", expandFrame)
            jmRow.Size = UDim2.new(1, -20, 0, 38)
            jmRow.BackgroundTransparency = 1
            jmRow.BorderSizePixel = 0
            jmRow.LayoutOrder = 1
            local jmLbl = Instance.new("TextLabel", jmRow)
            jmLbl.Size = UDim2.new(0, 100, 1, 0)
            jmLbl.Position = UDim2.new(0, 10, 0, 0)
            jmLbl.BackgroundTransparency = 1
            jmLbl.Text = "Jump Mode:"
            jmLbl.TextColor3 = RED_MAIN
            jmLbl.Font = Enum.Font.GothamBold
            jmLbl.TextSize = 11
            local modeBtn = Instance.new("TextButton", jmRow)
            modeBtn.Size = UDim2.new(0, 60, 0, 28)
            modeBtn.Position = UDim2.new(1, -70, 0.5, -14)
            modeBtn.BackgroundColor3 = State.jumpMode == "Tap" and C.pillOn or C.pillOff
            modeBtn.BorderSizePixel = 0
            modeBtn.Text = State.jumpMode == "Tap" and "TAP" or "HOLD"
            modeBtn.TextColor3 = RED_MAIN
            modeBtn.Font = Enum.Font.GothamBold
            modeBtn.TextSize = 11
            modeBtn.ZIndex = 10
            mkCorner(modeBtn, 6)
            modeBtn.MouseButton1Click:Connect(function()
                State.jumpMode = (State.jumpMode == "Tap") and "Hold" or "Tap"
                modeBtn.Text = State.jumpMode == "Tap" and "TAP" or "HOLD"
                modeBtn.BackgroundColor3 = State.jumpMode == "Tap" and C.pillOn or C.pillOff
                autoSave()
            end)
        else
            expandFrame.Size = UDim2.new(1, 0, 0, 0)
            for _, child in ipairs(expandFrame:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
        end
    end)
    makeToggleRow("Anti Ragdoll", false, function(on)
        State.antiRagdollEnabled = on
        if on then startAntiRagdoll() else stopAntiRagdoll() end
        autoSave()
    end)
    makeToggleRow("FPS Boost", false, function(on)
        State.fpsBoostEnabled = on
        if on then pcall(applyFPSBoost) end
        autoSave()
    end)
    makeToggleRow("Unwalk", false, function(on)
        State.unwalkEnabled = on
        autoSave()
    end)
    makeToggleRow("Medusa Counter", false, function(on)
        State.medusaCounterEnabled = on
        if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
        autoSave()
    end)
    makeGap(6)
    makeSectionHeader("INSTANT RESET")
    makeGap(4)
    local irRow = Instance.new("Frame", currentPage)
    irRow.Size = UDim2.new(1, 0, 0, 50)
    irRow.BackgroundTransparency = 1
    irRow.BorderSizePixel = 0
    irRow.LayoutOrder = LO()
    local irLbl = Instance.new("TextLabel", irRow)
    irLbl.Size = UDim2.new(0, 100, 1, 0)
    irLbl.Position = UDim2.new(0, 14, 0, 0)
    irLbl.BackgroundTransparency = 1
    irLbl.Text = "Instant Reset"
    irLbl.TextColor3 = C.rowLabel
    irLbl.Font = Enum.Font.GothamBold
    irLbl.TextSize = 13
    irLbl.TextXAlignment = Enum.TextXAlignment.Left
    local irKeybtn = Instance.new("TextButton", irRow)
    irKeybtn.Size = UDim2.new(0, 56, 0, 30)
    irKeybtn.Position = UDim2.new(1, -130, 0.5, -15)
    irKeybtn.BackgroundTransparency = 1
    irKeybtn.BorderSizePixel = 0
    irKeybtn.Text = getKeyDisplayName(State.instantResetKey)
    irKeybtn.TextColor3 = C.chipTxt
    irKeybtn.Font = Enum.Font.GothamBold
    irKeybtn.TextSize = 12
    irKeybtn.ZIndex = 8
    mkCorner(irKeybtn, 8)
    local irPillBg = Instance.new("Frame", irRow)
    irPillBg.Size = UDim2.new(0, 44, 0, 22)
    irPillBg.Position = UDim2.new(1, -58, 0.5, -11)
    irPillBg.BackgroundColor3 = State.instantResetEnabled and C.pillOn or C.pillOff
    irPillBg.BorderSizePixel = 0
    irPillBg.ZIndex = 7
    mkCorner(irPillBg, 11)
    local irDot = Instance.new("Frame", irPillBg)
    irDot.Size = UDim2.new(0, 16, 0, 16)
    irDot.Position = State.instantResetEnabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    irDot.BackgroundColor3 = State.instantResetEnabled and C.dotOn or C.dotOff
    irDot.BorderSizePixel = 0
    irDot.ZIndex = 8
    mkCorner(irDot, 8)
    local irIsOn = State.instantResetEnabled or false
    local function setIrV(on)
        irIsOn = on
        State.instantResetEnabled = on
        TweenService:Create(irPillBg, TweenInfo.new(0.18), {BackgroundColor3 = on and C.pillOn or C.pillOff}):Play()
        TweenService:Create(irDot, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = on and C.dotOn or C.dotOff
        }):Play()
        autoSave()
    end
    local function toggleIr()
        setIrV(not irIsOn)
    end
    local irClk = Instance.new("TextButton", irRow)
    irClk.Size = UDim2.new(0.45, 0, 1, 0)
    irClk.BackgroundTransparency = 1
    irClk.Text = ""
    irClk.ZIndex = 5
    irClk.BorderSizePixel = 0
    irClk.MouseButton1Click:Connect(toggleIr)
    local irPClk = Instance.new("TextButton", irPillBg)
    irPClk.Size = UDim2.new(1, 0, 1, 0)
    irPClk.BackgroundTransparency = 1
    irPClk.Text = ""
    irPClk.ZIndex = 9
    irPClk.BorderSizePixel = 0
    irPClk.MouseButton1Click:Connect(toggleIr)
    local irListening = false
    local irLconnKB, irLconnGP = nil, nil
    local function irStopL(key)
        irListening = false
        if irLconnKB then irLconnKB:Disconnect(); irLconnKB = nil end
        if irLconnGP then irLconnGP:Disconnect(); irLconnGP = nil end
        if key then
            irKeybtn.Text = getKeyDisplayName(key)
            State.instantResetKey = key
            Keys.instantReset = key
        end
        irKeybtn.TextColor3 = C.chipTxt
        autoSave()
    end
    irKeybtn.MouseButton1Click:Connect(function()
        if irListening then
            irStopL(nil)
            return
        end
        irListening = true
        irKeybtn.Text = "..."
        irKeybtn.TextColor3 = C.inputTxt
        irLconnKB = UIS.InputBegan:Connect(function(inp)
            if not irListening then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if inp.KeyCode == Enum.KeyCode.Escape then
                irStopL(nil)
                return
            end
            irStopL(inp.KeyCode)
        end)
        irLconnGP = UIS.InputBegan:Connect(function(inp)
            if not irListening then return end
            if inp.UserInputType ~= Enum.UserInputType.Gamepad1 and inp.UserInputType ~= Enum.UserInputType.Gamepad2 then return end
            local kc = inp.KeyCode
            if kc == Enum.KeyCode.Unknown then return end
            irStopL(kc)
        end)
    end)
    makeToggleRow("Instant Reset On Medusa", false, function(on)
        State.instantResetOnMedusa = on
        autoSave()
    end)
    makeGap(6)
    makeSectionHeader("BAT AIMBOT")
    makeGap(4)
    makeGearToggleRow("Bat Aimbot", false, function(on)
        State.batAimbotToggled = on
        autoSave()
    end, function(expandFrame, expanded)
        if expanded then
            for _, child in ipairs(expandFrame:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
            expandFrame.Size = UDim2.new(1, 0, 0, 94)
            local function makeSpeedRow(parent, labelText, stateKey, lo2)
                local r = Instance.new("Frame", parent)
                r.Size = UDim2.new(1, -20, 0, 40)
                r.BackgroundTransparency = 1
                r.BorderSizePixel = 0
                r.LayoutOrder = lo2
                local l = Instance.new("TextLabel", r)
                l.Size = UDim2.new(0, 120, 1, 0)
                l.Position = UDim2.new(0, 10, 0, 0)
                l.BackgroundTransparency = 1
                l.Text = labelText
                l.TextColor3 = RED_MAIN
                l.Font = Enum.Font.GothamBold
                l.TextSize = 11
                local bw = Instance.new("Frame", r)
                bw.Size = UDim2.new(0, 56, 0, 26)
                bw.Position = UDim2.new(1, -64, 0.5, -13)
                bw.BackgroundTransparency = 1
                bw.BorderSizePixel = 0
                local b = Instance.new("TextBox", bw)
                b.Size = UDim2.new(1, -6, 1, 0)
                b.Position = UDim2.new(0, 3, 0, 0)
                b.BackgroundTransparency = 1
                b.Text = tostring(State[stateKey])
                b.TextColor3 = C.inputTxt
                b.Font = Enum.Font.GothamBold
                b.TextSize = 12
                b.ClearTextOnFocus = false
                b.ZIndex = 10
                b.TextXAlignment = Enum.TextXAlignment.Center
                b.FocusLost:Connect(function()
                    local n = tonumber(b.Text)
                    if n and n > 0 and n <= 500 then
                        State[stateKey] = n
                    else
                        b.Text = tostring(State[stateKey])
                    end
                    autoSave()
                end)
            end
            makeSpeedRow(expandFrame, "Aimbot Speed", "batAimbotSpeed", 1)
            makeSpeedRow(expandFrame, "Lagger Speed", "batAimbotLaggerSpeed", 2)
        else
            expandFrame.Size = UDim2.new(1, 0, 0, 0)
            for _, child in ipairs(expandFrame:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
        end
    end)
    makeToggleRow("Bat Counter", false, function(on)
        State.batCounterEnabled = on
        if on then startBatCounter() else stopBatCounter() end
        autoSave()
    end)
    makeToggleRow("Lock In Animation", false, function(on)
        State.lockInEnabled = on
        if on then startLockIn() else stopLockIn() end
        autoSave()
    end)
end)

-- ============================================================
-- KEYBINDS PAGE
-- ============================================================
buildPage("Keybinds", function()
    makeKeybindRow("Auto Left", Keys.autoLeft, function(k) Keys.autoLeft = k end)
    makeKeybindRow("Auto Right", Keys.autoRight, function(k) Keys.autoRight = k end)
    makeKeybindRow("Drop Key", Keys.drop, function(k) Keys.drop = k end)
    makeKeybindRow("TP Down Key", Keys.tpDown, function(k) Keys.tpDown = k end)
    makeKeybindRow("Bat Aimbot Key", Keys.aimbot, function(k) Keys.aimbot = k end)
    makeKeybindRow("Speed Key", Keys.speed, function(k) Keys.speed = k end)
    makeKeybindRow("Lagger Key", Keys.lagger, function(k) Keys.lagger = k end)
    makeKeybindRow("Instant Reset", Keys.instantReset, function(k) Keys.instantReset = k; State.instantResetKey = k end)
end)

-- ============================================================
-- VISUAL PAGE (Sky Theme button moved left)
-- ============================================================
buildPage("Visual", function()
    makeToggleRow("Tracers", false, function(on)
        State.tracersEnabled = on
        if not on then clearTracers() end
        autoSave()
    end)
    makeToggleRow("Splash Text on Load", true, function(on)
        State.splashEnabled = on
        autoSave()
    end)
    makeToggleRow("Enemy Speed", State.enemySpeedMeterEnabled, function(on)
        State.enemySpeedMeterEnabled = on
        updateAllSpeedMetersVisibility()
        autoSave()
    end)
    makeGap(6)
    makeSectionHeader("Sky Theme")
    makeGap(4)
    local skyRow = Instance.new("Frame", currentPage)
    skyRow.Size = UDim2.new(1, 0, 0, 44)
    skyRow.BackgroundTransparency = 1
    skyRow.BorderSizePixel = 0
    skyRow.LayoutOrder = LO()
    local skyLbl = Instance.new("TextLabel", skyRow)
    skyLbl.Size = UDim2.new(1, -70, 1, 0)
    skyLbl.Position = UDim2.new(0, 14, 0, 0)
    skyLbl.BackgroundTransparency = 1
    skyLbl.Text = "Theme"
    skyLbl.TextColor3 = C.rowLabel
    skyLbl.Font = Enum.Font.GothamBold
    skyLbl.TextSize = 13
    skyLbl.TextXAlignment = Enum.TextXAlignment.Left
    local skyVal = Instance.new("TextLabel", skyRow)
    skyVal.Size = UDim2.new(0, 120, 0, 22)
    skyVal.Position = UDim2.new(1, -144, 0.5, -11)
    skyVal.BackgroundTransparency = 1
    skyVal.Text = State.currentSkyTheme
    skyVal.TextColor3 = C.accent
    skyVal.Font = Enum.Font.GothamBold
    skyVal.TextSize = 12
    skyVal.TextXAlignment = Enum.TextXAlignment.Right
    local skyBtn = Instance.new("TextButton", skyRow)
    skyBtn.Size = UDim2.new(0, 44, 0, 22)
    skyBtn.Position = UDim2.new(1, -90, 0.5, -11)
    skyBtn.BackgroundColor3 = C.inputBg
    skyBtn.BorderSizePixel = 0
    skyBtn.Text = "➡"
    skyBtn.TextColor3 = C.inputTxt
    skyBtn.Font = Enum.Font.GothamBold
    skyBtn.TextSize = 12
    mkCorner(skyBtn, 8)
    local skyIndex = 1
    for i, entry in ipairs(CandySkyOrder) do
        if entry[2] == State.currentSkyTheme then
            skyIndex = i
            break
        end
    end
    skyBtn.MouseButton1Click:Connect(function()
        skyIndex = skyIndex % #CandySkyOrder + 1
        local newTheme = CandySkyOrder[skyIndex][2]
        skyVal.Text = newTheme
        CandyApplyCustomSky(newTheme)
        State.currentSkyTheme = newTheme
        autoSave()
    end)
    makeGap(6)
    makeSectionHeader("Camera")
    makeGap(4)
    makeToggleRow("FOV Changer", false, function(on)
        State.fovEnabled = on
        if on then startFov() else stopFov() end
        autoSave()
    end)
    makeFovSliderRow(State.fovValue, function(val)
        State.fovValue = val
        if State.fovEnabled then workspace.CurrentCamera.FieldOfView = val end
        autoSave()
    end)
    makeGap(4)
    makeToggleRow("Stretch Rez", false, function(on)
        State.stretchRezEnabled = on
        if on then startStretchRez() else stopStretchRez() end
        autoSave()
    end)
end)

-- ============================================================
-- SETTINGS PAGE
-- ============================================================
local function applyPreset(data)
    if data.normalSpeed then State.normalSpeed = data.normalSpeed; if normalBox then normalBox.Text = tostring(data.normalSpeed) end end
    if data.carrySpeed then State.carrySpeed = data.carrySpeed; if carryBox then carryBox.Text = tostring(data.carrySpeed) end end
    if data.laggerSpeed then State.laggerSpeed = data.laggerSpeed; if laggerBox then laggerBox.Text = tostring(data.laggerSpeed) end end
    if data.laggerCarrySpeed then State.laggerCarrySpeed = data.laggerCarrySpeed; if laggerCarryBox then laggerCarryBox.Text = tostring(data.laggerCarrySpeed) end end
    if data.stealRadius then Steal.StealRadius = data.stealRadius; Steal.cachedPrompts = {}; Steal.promptCacheTime = 0; if stealRadBox and not stealRadBox:IsFocused() then stealRadBox.Text = tostring(data.stealRadius) end end
    if data.stealDuration then Steal.StealDuration = data.stealDuration end
    if data.fovEnabled ~= nil then State.fovEnabled = data.fovEnabled; if data.fovEnabled then startFov() else stopFov() end end
    if data.fovValue then State.fovValue = data.fovValue; if State.fovEnabled then workspace.CurrentCamera.FieldOfView = data.fovValue end end
    if data.stretchRezEnabled ~= nil then State.stretchRezEnabled = data.stretchRezEnabled; if data.stretchRezEnabled then startStretchRez() else stopStretchRez() end end
    if data.medusaCounterEnabled ~= nil then State.medusaCounterEnabled = data.medusaCounterEnabled; if data.medusaCounterEnabled then setupMedusaCounter(LP.Character) else stopMedusaCounter() end end
    if data.jumpMode then State.jumpMode = data.jumpMode end
    if data.batAimbotSpeed then State.batAimbotSpeed = data.batAimbotSpeed end
    if data.batAimbotLaggerSpeed then State.batAimbotLaggerSpeed = data.batAimbotLaggerSpeed end
    if data.enemySpeedMeterEnabled ~= nil then State.enemySpeedMeterEnabled = data.enemySpeedMeterEnabled; updateAllSpeedMetersVisibility() end
    if data.lockButtonsEnabled ~= nil then State.lockButtonsEnabled = data.lockButtonsEnabled end
    if data.tracersEnabled ~= nil then State.tracersEnabled = data.tracersEnabled end
    if data.splashEnabled ~= nil then State.splashEnabled = data.splashEnabled end
    if data.lockInEnabled ~= nil then State.lockInEnabled = data.lockInEnabled; if data.lockInEnabled then startLockIn() else stopLockIn() end end
    if data.batCounterEnabled ~= nil then State.batCounterEnabled = data.batCounterEnabled; if data.batCounterEnabled then startBatCounter() else stopBatCounter() end end
    if data.mobileBtnVisible then for k, v in pairs(data.mobileBtnVisible) do State.mobileBtnVisible[k] = v end end
    if data.instantResetEnabled ~= nil then State.instantResetEnabled = data.instantResetEnabled end
    if data.instantResetOnMedusa ~= nil then State.instantResetOnMedusa = data.instantResetOnMedusa end
    if data.instantResetKey and Enum.KeyCode[data.instantResetKey] then State.instantResetKey = Enum.KeyCode[data.instantResetKey]; Keys.instantReset = State.instantResetKey end
    if data.autoSpeedEnabled ~= nil then State.autoSpeedEnabled = data.autoSpeedEnabled end
    if data.speedToggled ~= nil then State.speedToggled = data.speedToggled end
    if data.laggerEnabled ~= nil then State.laggerEnabled = data.laggerEnabled end
    if data.autoLeftEnabled ~= nil then State.autoLeftEnabled = data.autoLeftEnabled end
    if data.autoRightEnabled ~= nil then State.autoRightEnabled = data.autoRightEnabled end
    if data.batAimbotToggled ~= nil then State.batAimbotToggled = data.batAimbotToggled end
    if data.currentSkyTheme then CandyApplyCustomSky(data.currentSkyTheme); State.currentSkyTheme = data.currentSkyTheme end
    autoSave()
    for _, setter in ipairs(toggleStateSetters) do
        pcall(setter, false)
    end
end

buildPage("Settings", function()
    makeKeybindRow("Hide GUI", Keys.guiHide, function(k) Keys.guiHide = k end)
    uiScaleBox = makeInputRow("UI Scale", 1.0, function(n) if n >= 0.5 and n <= 2.0 then if uiScaleObj then uiScaleObj.Scale = n end end; autoSave() end, 70)
    makeToggleRow("Lock Buttons", false, function(on)
        State.lockButtonsEnabled = on
        autoSave()
    end)
    makeGap(6)
    local nameWrap = Instance.new("Frame", currentPage)
    nameWrap.Size = UDim2.new(1, 0, 0, 58)
    nameWrap.BackgroundTransparency = 1
    nameWrap.BorderSizePixel = 0
    nameWrap.LayoutOrder = LO()
    local nameBoxWrap = Instance.new("Frame", nameWrap)
    nameBoxWrap.Size = UDim2.new(1, -28, 0, 46)
    nameBoxWrap.Position = UDim2.new(0, 14, 0, 6)
    nameBoxWrap.BackgroundColor3 = C.inputBg
    nameBoxWrap.BorderSizePixel = 0
    mkCorner(nameBoxWrap, 10)
    presetNameBox = Instance.new("TextBox", nameBoxWrap)
    presetNameBox.Size = UDim2.new(1, -12, 1, 0)
    presetNameBox.Position = UDim2.new(0, 16, 0, 0)
    presetNameBox.BackgroundTransparency = 1
    presetNameBox.PlaceholderText = "Set Preset"
    presetNameBox.PlaceholderColor3 = C.rowSub
    presetNameBox.Text = ""
    presetNameBox.TextColor3 = C.inputTxt
    presetNameBox.Font = Enum.Font.GothamBold
    presetNameBox.TextSize = 15
    presetNameBox.ClearTextOnFocus = false
    presetNameBox.ZIndex = 9
    presetNameBox.TextXAlignment = Enum.TextXAlignment.Left
    local sWrap = Instance.new("Frame", currentPage)
    sWrap.Size = UDim2.new(1, 0, 0, 56)
    sWrap.BackgroundTransparency = 1
    sWrap.BorderSizePixel = 0
    sWrap.LayoutOrder = LO()
    local savePBtn = Instance.new("TextButton", sWrap)
    savePBtn.Size = UDim2.new(1, -28, 0, 46)
    savePBtn.Position = UDim2.new(0, 14, 0, 5)
    savePBtn.BackgroundColor3 = C.btnBg
    savePBtn.BorderSizePixel = 0
    savePBtn.Text = "Save Preset"
    savePBtn.TextColor3 = C.btnTxt
    savePBtn.Font = Enum.Font.GothamBold
    savePBtn.TextSize = 15
    savePBtn.ZIndex = 9
    mkCorner(savePBtn, 10)
    savePBtn.MouseEnter:Connect(function()
        TweenService:Create(savePBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.btnHov}):Play()
    end)
    savePBtn.MouseLeave:Connect(function()
        TweenService:Create(savePBtn, TweenInfo.new(0.1), {BackgroundColor3 = C.btnBg}):Play()
    end)
    savePBtn.MouseButton1Click:Connect(function()
        local nm = presetNameBox.Text:match("^%s*(.-)%s*$")
        if nm == "" then
            savePBtn.Text = "Name required!"
            task.delay(1.5, function() if savePBtn and savePBtn.Parent then savePBtn.Text = "Save Preset" end end)
            return
        end
        local found = false
        for i, p in ipairs(Presets) do
            if p.name == nm then
                Presets[i].data = buildPresetSnapshot()
                found = true
                break
            end
        end
        if not found then
            table.insert(Presets, {name = nm, data = buildPresetSnapshot()})
        end
        savePresetsFile()
        presetNameBox.Text = ""
        savePBtn.Text = "Saved!"
        task.delay(1.5, function() if savePBtn and savePBtn.Parent then savePBtn.Text = "Save Preset" end end)
        rebuildPresetList()
    end)
    makeGap(4)
    local listWrap = Instance.new("Frame", currentPage)
    listWrap.Size = UDim2.new(1, 0, 0, 0)
    listWrap.AutomaticSize = Enum.AutomaticSize.Y
    listWrap.BackgroundTransparency = 1
    listWrap.BorderSizePixel = 0
    listWrap.LayoutOrder = LO()
    local listLL = Instance.new("UIListLayout", listWrap)
    listLL.SortOrder = Enum.SortOrder.LayoutOrder
    listLL.Padding = UDim.new(0, 6)
    local listPad = Instance.new("UIPadding", listWrap)
    listPad.PaddingLeft = UDim.new(0, 14)
    listPad.PaddingRight = UDim.new(0, 14)
    presetListFrame = listWrap
end)

-- ============================================================
-- BUTTONS PAGE
-- ============================================================
buildPage("Buttons", function()
    makeGap(6)
    local btnKeys = {"CarryMode","AutoLeft","AutoRight","LaggerMode","BatAimbot","Drop","TpDown","InstantReset"}
    local btnLabels = {"Carry Mode","Auto Left","Auto Right","Lagger Mode","Bat Aimbot","Drop","TP Down","Instant Reset"}
    for i, key in ipairs(btnKeys) do
        makeToggleRow(btnLabels[i], State.mobileBtnVisible[key] ~= false, function(on)
            State.mobileBtnVisible[key] = on
            for _, ref in ipairs(mobileBtnRefs) do
                if ref.key == key then
                    ref.frame.Visible = on
                end
            end
            autoSave()
        end)
    end
end)

-- ============================================================
-- REBUILD PRESET LIST
-- ============================================================
local function rebuildPresetList()
    if not presetListFrame then return end
    for _, child in ipairs(presetListFrame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    for i, preset in ipairs(Presets) do
        local row = Instance.new("Frame", presetListFrame)
        row.Name = "Preset_" .. i
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = C.presetBg
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        mkCorner(row, 10)
        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1, -100, 1, 0)
        nameLbl.Position = UDim2.new(0, 12, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = preset.name
        nameLbl.TextColor3 = C.rowLabel
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size = UDim2.new(0, 48, 0, 30)
        loadBtn.Position = UDim2.new(1, -102, 0.5, -15)
        loadBtn.BackgroundColor3 = C.presetLoad
        loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = RED_MAIN
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 12
        loadBtn.ZIndex = 9
        mkCorner(loadBtn, 8)
        loadBtn.MouseButton1Click:Connect(function()
            applyPreset(preset.data)
            saveLastPresetName(preset.name)
            loadBtn.Text = "OK"
            task.delay(1.2, function()
                if loadBtn and loadBtn.Parent then loadBtn.Text = "Load" end
            end)
        end)
        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0, 38, 0, 30)
        delBtn.Position = UDim2.new(1, -52, 0.5, -15)
        delBtn.BackgroundColor3 = C.presetDel
        delBtn.BorderSizePixel = 0
        delBtn.Text = "X"
        delBtn.TextColor3 = RED_MAIN
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 13
        delBtn.ZIndex = 9
        mkCorner(delBtn, 8)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(Presets, i)
            savePresetsFile()
            rebuildPresetList()
        end)
    end
end

for _, n in ipairs(TABS) do
    local active = (n == "Speed")
    if tabBtns[n] then
        tabBtns[n].TextColor3 = active and C.tabActive or C.tabIdle
        tabBtns[n].BackgroundColor3 = active and C.tabActiveBg or Color3.fromRGB(0,0,0)
        tabBtns[n].BackgroundTransparency = active and 0 or 1
    end
    if tabPages[n] then
        tabPages[n].Visible = active
    end
end

-- ============================================================
-- MOBILE BUTTONS (no white outlines)
-- ============================================================
local CIRC_SIZE = 78
local CIRC_GAP = 12
local PANEL_COLS = 2

local floatBtnDefs = {
    {key = "CarryMode", label = "CARRY\nMODE", state = function() return State.speedToggled end,
        onClick = function()
            State.speedToggled = not State.speedToggled
            State.laggerEnabled = false
            for _, ref in ipairs(mobileBtnRefs) do
                if ref.key == "CarryMode" then
                    ref.dot.BackgroundColor3 = State.speedToggled and C.dotGreenOn or C.dotGreenOff
                    ref.btn.BackgroundColor3 = State.speedToggled and Color3.fromRGB(180,20,20) or C.floatBtnBg
                    if ref.img then ref.img.ImageColor3 = State.speedToggled and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,255,255) end
                    if ref.stroke then ref.stroke.Transparency = State.speedToggled and 0 or 1 end
                    if ref.stroke then ref.stroke.Transparency = 1 end
                end
            end
            autoSave()
        end},
    {key = "AutoLeft", label = "AUTO\nLEFT", state = function() return State.autoLeftEnabled end,
        onClick = function()
            State.autoLeftEnabled = not State.autoLeftEnabled
            if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
            for _, ref in ipairs(mobileBtnRefs) do
                if ref.key == "AutoLeft" then
                    ref.dot.BackgroundColor3 = State.autoLeftEnabled and C.dotGreenOn or C.dotGreenOff
                    ref.btn.BackgroundColor3 = State.autoLeftEnabled and Color3.fromRGB(180,20,20) or C.floatBtnBg
                    if ref.img then ref.img.ImageColor3 = State.autoLeftEnabled and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,255,255) end
                    if ref.stroke then ref.stroke.Transparency = State.autoLeftEnabled and 0 or 1 end
                    if ref.stroke then ref.stroke.Transparency = 1 end
                end
            end
            autoSave()
        end},
    {key = "AutoRight", label = "AUTO\nRIGHT", state = function() return State.autoRightEnabled end,
        onClick = function()
            State.autoRightEnabled = not State.autoRightEnabled
            if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
            for _, ref in ipairs(mobileBtnRefs) do
                if ref.key == "AutoRight" then
                    ref.dot.BackgroundColor3 = State.autoRightEnabled and C.dotGreenOn or C.dotGreenOff
                    ref.btn.BackgroundColor3 = State.autoRightEnabled and Color3.fromRGB(180,20,20) or C.floatBtnBg
                    if ref.img then ref.img.ImageColor3 = State.autoRightEnabled and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,255,255) end
                    if ref.stroke then ref.stroke.Transparency = State.autoRightEnabled and 0 or 1 end
                    if ref.stroke then ref.stroke.Transparency = 1 end
                end
            end
            autoSave()
        end},
    {key = "LaggerMode", label = "LAGGER\nMODE", state = function() return State.laggerEnabled end,
        onClick = function()
            State.laggerEnabled = not State.laggerEnabled
            if State.laggerEnabled then
                State._prevBatSpeed = State.batAimbotSpeed
                State.batAimbotSpeed = State.batAimbotLaggerSpeed
            else
                if State._prevBatSpeed then
                    State.batAimbotSpeed = State._prevBatSpeed
                    State._prevBatSpeed = nil
                end
            end
            for _, ref in ipairs(mobileBtnRefs) do
                if ref.key == "LaggerMode" then
                    ref.dot.BackgroundColor3 = State.laggerEnabled and C.dotGreenOn or C.dotGreenOff
                    ref.btn.BackgroundColor3 = State.laggerEnabled and Color3.fromRGB(180,20,20) or C.floatBtnBg
                    if ref.img then ref.img.ImageColor3 = State.laggerEnabled and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,255,255) end
                    if ref.stroke then ref.stroke.Transparency = State.laggerEnabled and 0 or 1 end
                    if ref.stroke then ref.stroke.Transparency = 1 end
                end
            end
            autoSave()
        end},
    {key = "BatAimbot", label = "BAT\nAIMBOT", state = function() return State.batAimbotToggled end,
        onClick = function()
            State.batAimbotToggled = not State.batAimbotToggled
            if State.batAimbotToggled then
                pcall(startBatAimbot)
            else
                stopBatAimbot()
            end
            for _, ref in ipairs(mobileBtnRefs) do
                if ref.key == "BatAimbot" then
                    ref.dot.BackgroundColor3 = State.batAimbotToggled and C.dotGreenOn or C.dotGreenOff
                    ref.btn.BackgroundColor3 = State.batAimbotToggled and Color3.fromRGB(180,20,20) or C.floatBtnBg
                    if ref.img then ref.img.ImageColor3 = State.batAimbotToggled and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,255,255) end
                    if ref.stroke then ref.stroke.Transparency = State.batAimbotToggled and 0 or 1 end
                    if ref.stroke then ref.stroke.Transparency = 1 end
                end
            end
            autoSave()
        end},
    {key = "Drop", label = "DROP", state = function() return false end, onClick = function() performDrop() end},
    {key = "TpDown", label = "TP\nDOWN", state = function() return false end, onClick = function() waveTpDown() end},
    {key = "InstantReset", label = "INSTANT\nRESET", state = function() return false end, onClick = function() if State.instantResetEnabled then instantReset() end end},
}

local function makeMobileBtn(def, posX, posY)
    local btnFrame = Instance.new("Frame", gui)
    btnFrame.Name = "MobileBtn_" .. def.key
    btnFrame.Size = UDim2.new(0, CIRC_SIZE, 0, CIRC_SIZE)
    btnFrame.Position = UDim2.new(0, posX, 0, posY)
    btnFrame.BackgroundTransparency = 1
    btnFrame.BorderSizePixel = 0
    btnFrame.ZIndex = 15
    btnFrame.Visible = State.mobileBtnVisible[def.key] ~= false
    local btn = Instance.new("TextButton", btnFrame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = C.floatBtnBg
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.ZIndex = 16
    mkCorner(btn, CIRC_SIZE/2)
    -- Background image
    local btnImg = Instance.new("ImageLabel", btn)
    btnImg.Size = UDim2.new(1,0,1,0); btnImg.BackgroundTransparency = 1
    btnImg.Image = "rbxassetid://131575268169507"
    btnImg.ScaleType = Enum.ScaleType.Crop; btnImg.ImageTransparency = 0.3; btnImg.ZIndex = 16
    mkCorner(btnImg, CIRC_SIZE/2)
    -- Red stroke ring (shown when ON)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(255,51,51); btnStroke.Thickness = 2.5; btnStroke.Transparency = 1
    -- Shadow for thicker outline
    local shadow = Instance.new("TextLabel", btn)
    shadow.Size = UDim2.new(1,-8,1,-16); shadow.Position = UDim2.new(0,5,0,7)
    shadow.BackgroundTransparency = 1; shadow.Text = def.label
    shadow.TextColor3 = Color3.fromRGB(0,0,0); shadow.Font = Enum.Font.GothamBlack; shadow.TextSize = 13
    shadow.TextWrapped = true; shadow.TextXAlignment = Enum.TextXAlignment.Center
    shadow.TextYAlignment = Enum.TextYAlignment.Center
    shadow.TextStrokeTransparency = 0; shadow.TextStrokeColor3 = Color3.fromRGB(0,0,0); shadow.ZIndex = 17
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -8, 1, -16)
    lbl.Position = UDim2.new(0, 4, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = def.label
    lbl.TextColor3 = Color3.fromRGB(255,51,51)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 13
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.TextStrokeTransparency = 0; lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    lbl.ZIndex = 18
    local dot = Instance.new("Frame", btn)
    dot.Name = "StatusDot"
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0.5, -4, 1, -22)
    dot.BackgroundColor3 = def.state() and C.dotGreenOn or C.dotGreenOff
    dot.BorderSizePixel = 0
    dot.ZIndex = 18
    mkCorner(dot, 4)
    if def.state() then
        btn.BackgroundColor3 = Color3.fromRGB(180,20,20)
        btnImg.ImageColor3 = Color3.fromRGB(255,60,60)
        btnStroke.Transparency = 0
    end
    local clickOverlay = Instance.new("TextButton", btnFrame)
    clickOverlay.Size = UDim2.new(1, 0, 1, 0)
    clickOverlay.BackgroundTransparency = 1
    clickOverlay.Text = ""
    clickOverlay.ZIndex = 20
    clickOverlay.MouseButton1Click:Connect(function()
        def.onClick()
        autoSave()
    end)
    local _bDrag, _bDragStart, _bStartPos = false, nil, nil
    btnFrame.InputBegan:Connect(function(inp)
        if State.lockButtonsEnabled then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            _bDrag = true
            _bDragStart = inp.Position
            _bStartPos = btnFrame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    _bDrag = false
                    saveMobileButtonPositions()
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if _bDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local dx = inp.Position.X - _bDragStart.X
            local dy = inp.Position.Y - _bDragStart.Y
            btnFrame.Position = UDim2.new(_bStartPos.X.Scale, _bStartPos.X.Offset + dx, _bStartPos.Y.Scale, _bStartPos.Y.Offset + dy)
        end
    end)
    table.insert(mobileBtnRefs, {key = def.key, def = def, dot = dot, btn = btn, img = btnImg, stroke = btnStroke, frame = btnFrame})
    return btnFrame
end

do
    local hasPosFile = false
    pcall(function() hasPosFile = _isfile(MOBILE_BTN_POS_FILE) end)
    if hasPosFile then
        loadMobileButtonPositions()
    else
        local startX = math.floor(gui.AbsoluteSize.X) - PANEL_COLS * (CIRC_SIZE + CIRC_GAP) - 20
        local startY = math.floor(gui.AbsoluteSize.Y) / 2 - 130
        if startX <= 0 then startX = 700 end
        if startY <= 0 then startY = 200 end
        for i, def in ipairs(floatBtnDefs) do
            local col = ((i - 1) % PANEL_COLS)
            local row = math.floor((i - 1) / PANEL_COLS)
            local px = startX + col * (CIRC_SIZE + CIRC_GAP)
            local py = startY + row * (CIRC_SIZE + CIRC_GAP)
            makeMobileBtn(def, px, py)
        end
    end
end

-- ============================================================
-- CORE MOVEMENT FUNCTIONS
-- ============================================================
function doTpDown()
    waveTpDown()
end

local function faceSouth()
    pcall(function()
        local c = LP.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, 0)
        end
    end)
end

local function faceNorth()
    pcall(function()
        local c = LP.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(180), 0)
        end
    end)
end

function startAutoLeft()
    if Conns.autoLeft then Conns.autoLeft:Disconnect() end
    State.autoLeftPhase = 1
    Conns.autoLeft = RunService.Heartbeat:Connect(function()
        if not State.autoLeftEnabled then return end
        local c = LP.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then return end
        local spd = State.laggerEnabled and State.laggerSpeed or State.normalSpeed
        if State.autoLeftPhase == 1 then
            local tgt = Vector3.new(POS.L1.X, root.Position.Y, POS.L1.Z)
            if (tgt - root.Position).Magnitude < 1 then
                State.autoLeftPhase = 2
                local d = POS.L2 - root.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false)
                root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
                return
            end
            local d = POS.L1 - root.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        elseif State.autoLeftPhase == 2 then
            local tgt = Vector3.new(POS.L2.X, root.Position.Y, POS.L2.Z)
            if (tgt - root.Position).Magnitude < 1 then
                hum2:Move(Vector3.zero, false)
                root.AssemblyLinearVelocity = Vector3.zero
                State.autoLeftEnabled = false
                if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft = nil end
                State.autoLeftPhase = 1
                faceSouth()
                return
            end
            local d = POS.L2 - root.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        end
    end)
end

function stopAutoLeft()
    if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft = nil end
    State.autoLeftPhase = 1
    local c = LP.Character
    if c then
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:Move(Vector3.zero, false) end
    end
end

function startAutoRight()
    if Conns.autoRight then Conns.autoRight:Disconnect() end
    State.autoRightPhase = 1
    Conns.autoRight = RunService.Heartbeat:Connect(function()
        if not State.autoRightEnabled then return end
        local c = LP.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum2 then return end
        local spd = State.laggerEnabled and State.laggerSpeed or State.normalSpeed
        if State.autoRightPhase == 1 then
            local tgt = Vector3.new(POS.R1.X, root.Position.Y, POS.R1.Z)
            if (tgt - root.Position).Magnitude < 1 then
                State.autoRightPhase = 2
                local d = POS.R2 - root.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum2:Move(mv, false)
                root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
                return
            end
            local d = POS.R1 - root.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        elseif State.autoRightPhase == 2 then
            local tgt = Vector3.new(POS.R2.X, root.Position.Y, POS.R2.Z)
            if (tgt - root.Position).Magnitude < 1 then
                hum2:Move(Vector3.zero, false)
                root.AssemblyLinearVelocity = Vector3.zero
                State.autoRightEnabled = false
                if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight = nil end
                State.autoRightPhase = 1
                faceNorth()
                return
            end
            local d = POS.R2 - root.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum2:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        end
    end)
end

function stopAutoRight()
    if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight = nil end
    State.autoRightPhase = 1
    local c = LP.Character
    if c then
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:Move(Vector3.zero, false) end
    end
end

function startAntiRagdoll()
    if Conns.antiRag then return end
    Conns.antiRag = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        if not char then return end
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum2 then
            local st = hum2:GetState()
            if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hum2:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum2
                pcall(function()
                    local pm = LP.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then
                        require(pm:FindFirstChild("ControlModule")):Enable()
                    end
                end)
                if root then
                    root.Velocity = Vector3.new(0,0,0)
                    root.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then
                obj.Enabled = true
            end
        end
    end)
end

function stopAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag = nil end
end

local unwalkAnimateRef = nil
local function startUnwalkFn()
    local c = LP.Character
    if not c then return end
    local hum2 = c:FindFirstChildOfClass("Humanoid")
    if hum2 then
        pcall(function()
            for _, track in ipairs(hum2:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
        end)
    end
    local anim = c:FindFirstChild("Animate")
    if anim and anim:IsA("LocalScript") then
        anim.Disabled = true
        unwalkAnimateRef = anim
    end
end

local function stopUnwalkFn()
    local c = LP.Character
    if c and unwalkAnimateRef and unwalkAnimateRef.Parent == c then
        unwalkAnimateRef.Disabled = false
    end
    unwalkAnimateRef = nil
end

local LockInAnims = {
    idle1 = "rbxassetid://133806214992291",
    idle2 = "rbxassetid://94970088341563",
    walk = "rbxassetid://707897309",
    run = "rbxassetid://707861613",
    jump = "rbxassetid://116936326516985",
    fall = "rbxassetid://116936326516985",
    climb = "rbxassetid://116936326516985",
    swim = "rbxassetid://116936326516985",
    swimidle = "rbxassetid://116936326516985"
}
local function applyLockInAnims(char)
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local function s(obj, id)
        if obj then obj.AnimationId = id end
    end
    s(animate.idle and animate.idle.Animation1, LockInAnims.idle1)
    s(animate.idle and animate.idle.Animation2, LockInAnims.idle2)
    s(animate.walk and animate.walk.WalkAnim, LockInAnims.walk)
    s(animate.run and animate.run.RunAnim, LockInAnims.run)
    s(animate.jump and animate.jump.JumpAnim, LockInAnims.jump)
    s(animate.fall and animate.fall.FallAnim, LockInAnims.fall)
    s(animate.climb and animate.climb.ClimbAnim, LockInAnims.climb)
    s(animate.swim and animate.swim.Swim, LockInAnims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, LockInAnims.swimidle)
end

local function saveOriginalAnims(char)
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local function g(obj)
        return obj and obj.AnimationId or nil
    end
    _lockInOriginalAnims = {
        idle1 = g(animate.idle and animate.idle.Animation1),
        idle2 = g(animate.idle and animate.idle.Animation2),
        walk = g(animate.walk and animate.walk.WalkAnim),
        run = g(animate.run and animate.run.RunAnim),
        jump = g(animate.jump and animate.jump.JumpAnim),
        fall = g(animate.fall and animate.fall.FallAnim),
        climb = g(animate.climb and animate.climb.ClimbAnim),
        swim = g(animate.swim and animate.swim.Swim),
        swimidle = g(animate.swimidle and animate.swimidle.SwimIdle)
    }
end

local function restoreOriginalAnims(char)
    if not _lockInOriginalAnims then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local function s(obj, id)
        if obj and id then obj.AnimationId = id end
    end
    s(animate.idle and animate.idle.Animation1, _lockInOriginalAnims.idle1)
    s(animate.idle and animate.idle.Animation2, _lockInOriginalAnims.idle2)
    s(animate.walk and animate.walk.WalkAnim, _lockInOriginalAnims.walk)
    s(animate.run and animate.run.RunAnim, _lockInOriginalAnims.run)
    s(animate.jump and animate.jump.JumpAnim, _lockInOriginalAnims.jump)
    s(animate.fall and animate.fall.FallAnim, _lockInOriginalAnims.fall)
    s(animate.climb and animate.climb.ClimbAnim, _lockInOriginalAnims.climb)
    s(animate.swim and animate.swim.Swim, _lockInOriginalAnims.swim)
    s(animate.swimidle and animate.swimidle.SwimIdle, _lockInOriginalAnims.swimidle)
    local hh = char:FindFirstChildOfClass("Humanoid")
    if hh then
        for _, t in ipairs(hh:GetPlayingAnimationTracks()) do
            t:Stop(0)
        end
    end
end

function startLockIn()
    if Conns.lockIn then Conns.lockIn:Disconnect(); Conns.lockIn = nil end
    local char = LP.Character
    if char then
        saveOriginalAnims(char)
        applyLockInAnims(char)
        local hh = char:FindFirstChildOfClass("Humanoid")
        if hh then
            for _, t in ipairs(hh:GetPlayingAnimationTracks()) do
                t:Stop(0)
            end
        end
    end
    Conns.lockIn = RunService.Heartbeat:Connect(function()
        if not State.lockInEnabled then return end
        local c = LP.Character
        if c then applyLockInAnims(c) end
    end)
end

function stopLockIn()
    if Conns.lockIn then Conns.lockIn:Disconnect(); Conns.lockIn = nil end
    local char = LP.Character
    if char then restoreOriginalAnims(char) end
end

local BAT_NAMES = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
    local c = LP.Character
    if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, name in ipairs(BAT_NAMES) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    return nil
end

local function swingBatCounter(bat, char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char and hum then
        pcall(function() hum:EquipTool(bat) end)
        task.wait(0.05)
    end
    local remote = bat:FindFirstChildOfClass("RemoteEvent")
    if remote then
        pcall(function() remote:FireServer() end)
        task.wait(0.15)
        pcall(function() remote:FireServer() end)
    else
        pcall(function() bat:Activate() end)
        task.wait(0.15)
        pcall(function() bat:Activate() end)
    end
end

function startBatCounter()
    if Conns.batCounter then return end
    Conns.batCounter = RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled or _batCounterDebounce then return end
        local c = LP.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            _batCounterDebounce = true
            showBatCountdown()
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then swingBatCounter(bat, c) end
                task.wait(0.5)
                _batCounterDebounce = false
            end)
        end
    end)
end

function stopBatCounter()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter = nil end
    _batCounterDebounce = false
end

function applyFPSBoost()
    pcall(function() setfpscap(999999999) end)
    local function pO(v)
        pcall(function()
            if v:IsA("Model") then
                v.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
                v.ModelStreamingMode = Enum.ModelStreamingMode.Nonatomic
            elseif v:IsA("MeshPart") then
                v.CastShadow = false
                v.DoubleSided = false
                v.RenderFidelity = Enum.RenderFidelity.Performance
            elseif v:IsA("BasePart") then
                v.CastShadow = false
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then
                v:Destroy()
            elseif v:IsA("Attachment") then
                v.Visible = false
            end
        end)
    end
    for _, v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        local L = game:GetService("Lighting")
        for _, v in pairs(L:GetDescendants()) do
            pcall(function()
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then
                    v:Destroy()
                end
            end)
        end
        pcall(function() sethiddenproperty(L, "Technology", Enum.Technology.Legacy) end)
        L.GlobalShadows = false
        L.FogEnd = 9e9
        L.Brightness = 0
        local ter = workspace:FindFirstChildOfClass("Terrain")
        if ter then
            pcall(function() sethiddenproperty(ter, "Decoration", false) end)
            ter.WaterReflectance = 0
            ter.WaterTransparency = 0.7
            ter.WaterWaveSize = 0
            ter.WaterWaveSpeed = 0
        end
    end)
    workspace.DescendantAdded:Connect(function(v)
        if State.fpsBoostEnabled then
            task.spawn(pO, v)
        end
    end)
end

-- ============================================================
-- BAT AIMBOT (FACES AWAY FROM ENEMY)
-- ============================================================
local function getAutoBatTarget()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local now = tick()
    if now - _autoBatLastScan <= 0.1 and _autoBatTarget and _autoBatTarget.Parent then
        local hum = _autoBatTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return _autoBatTarget end
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

function startBatAimbot()
    if Conns.aimbot then return end
    _autoBatEquipped = false
    Conns.aimbot = RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled then return end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not hum then return end
        if not _autoBatEquipped then
            _autoBatEquipped = true
            if not char:FindFirstChildOfClass("Tool") then
                local bp = LP:FindFirstChildOfClass("Backpack")
                local bpBat = bp and bp:FindFirstChild("Bat")
                if bpBat then
                    pcall(function() hum:EquipTool(bpBat) end)
                end
            end
        end
        local target = getAutoBatTarget()
        if target then
            local targetVel = target.AssemblyLinearVelocity
            local tFlatVel = Vector3.new(targetVel.X, 0, targetVel.Z)
            local isMoving = tFlatVel.Magnitude > MOVING_THRESHOLD
            local prediction = targetVel * math.clamp(targetVel.Magnitude / 130, 0.05, 0.15)
            local aimTargetPos = Vector3.new(target.Position.X + prediction.X, target.Position.Y, target.Position.Z + prediction.Z)

            -- FACING AWAY: opposite direction of flatDir
            local flatDir = Vector3.new(aimTargetPos.X - root.Position.X, 0, aimTargetPos.Z - root.Position.Z)
            if flatDir.Magnitude > 0.01 then
                local awayDir = -flatDir.Unit
                local awayYaw = math.deg(math.atan2(-awayDir.X, -awayDir.Z))
                local yawDelta = (awayYaw - root.Orientation.Y + 180) % 360 - 180
                local yawRate = math.clamp(math.rad(yawDelta) * AUTO_BAT_TURN_SPEED, -AUTO_BAT_MAX_TURN_RATE, AUTO_BAT_MAX_TURN_RATE)
                root.AssemblyAngularVelocity = Vector3.new(0, yawRate, 0)
            else
                root.AssemblyAngularVelocity = Vector3.zero
            end

            -- Vertical offset based on enemy Y velocity
            local verticalOffset = 0
            if targetVel.Y > 0.5 then
                verticalOffset = VERTICAL_OFFSET_UP
            elseif targetVel.Y < -0.5 then
                verticalOffset = VERTICAL_OFFSET_DOWN
            end

            -- Position in front of enemy (horizontally) + vertical adjustment
            local standPos
            if isMoving then
                local moveDir = tFlatVel.Unit
                standPos = Vector3.new(target.Position.X + moveDir.X * FRONT_OFFSET, target.Position.Y + verticalOffset, target.Position.Z + moveDir.Z * FRONT_OFFSET)
            else
                standPos = Vector3.new(aimTargetPos.X - flatDir.Unit.X * AUTO_BAT_DIST, target.Position.Y + verticalOffset, aimTargetPos.Z - flatDir.Unit.Z * AUTO_BAT_DIST)
            end

            local hDiff = Vector3.new(standPos.X - root.Position.X, 0, standPos.Z - root.Position.Z)
            local hDist = hDiff.Magnitude
            local yDiff = standPos.Y - root.Position.Y

            local hVel
            if hDist < STOP_RADIUS then
                hVel = Vector3.new(root.AssemblyLinearVelocity.X * 0.6, 0, root.AssemblyLinearVelocity.Z * 0.6)
            else
                local speedScale = math.clamp(hDist / (STOP_RADIUS * 3), 0.2, 1.0)
                local hDir = hDiff.Unit
                hVel = hDir * (State.batAimbotSpeed * speedScale)
            end

            local vVel
            if math.abs(yDiff) > 0.15 then
                local dynVert = math.clamp(AUTO_BAT_VERT_BASE + math.abs(yDiff) * AUTO_BAT_VERT_SCALE, AUTO_BAT_VERT_BASE, AUTO_BAT_VERT_MAX)
                vVel = Vector3.new(0, math.sign(yDiff) * dynVert, 0)
            else
                vVel = Vector3.new(0, root.AssemblyLinearVelocity.Y * 0.5, 0)
            end

            root.AssemblyLinearVelocity = hVel + vVel
            if hDiff.Magnitude > 0.5 then
                hum:Move(hDiff.Unit, false)
            end
        else
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

function stopBatAimbot()
    if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot = nil end
    _autoBatEquipped = false
    _autoBatTarget = nil
    pcall(function()
        local hrp2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            hrp2.AssemblyLinearVelocity = hrp2.AssemblyLinearVelocity * 0.3
            hrp2.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

-- ============================================================
-- STEAL FUNCTIONS
-- ============================================================
local function isMyPlotByName(pn)
    local ct = tick()
    if Steal.plotCache[pn] and (ct - (Steal.plotCacheTime[pn] or 0)) < PLOT_CACHE_DURATION then
        return Steal.plotCache[pn]
    end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        Steal.plotCache[pn] = false
        Steal.plotCacheTime[pn] = ct
        return false
    end
    local plot = plots:FindFirstChild(pn)
    if not plot then
        Steal.plotCache[pn] = false
        Steal.plotCacheTime[pn] = ct
        return false
    end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            local r = yb.Enabled == true
            Steal.plotCache[pn] = r
            Steal.plotCacheTime[pn] = ct
            return r
        end
    end
    Steal.plotCache[pn] = false
    Steal.plotCacheTime[pn] = ct
    return false
end

local function findNearestPrompt()
    local c = LP.Character
    if not c then return nil end
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local ct = tick()
    if ct - Steal.promptCacheTime < PROMPT_CACHE_REFRESH and #Steal.cachedPrompts > 0 then
        local np, nd = nil, math.huge
        for _, data in ipairs(Steal.cachedPrompts) do
            if data.spawn then
                local dist = (data.spawn.Position - root.Position).Magnitude
                if dist <= Steal.StealRadius and dist < nd then
                    np = data.prompt
                    nd = dist
                end
            end
        end
        if np then return np end
    end
    Steal.cachedPrompts = {}
    Steal.promptCacheTime = ct
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local sp = base and base:FindFirstChild("Spawn")
                if sp then
                    local att = sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _, child in ipairs(att:GetChildren()) do
                            if child:IsA("ProximityPrompt") then
                                local dist = (sp.Position - root.Position).Magnitude
                                table.insert(Steal.cachedPrompts, {prompt = child, spawn = sp})
                                if dist <= Steal.StealRadius and dist < nd then
                                    np = child
                                    nd = dist
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    return np
end

local function executeSteal(prompt)
    local ct = tick()
    if ct - State.lastStealTick < STEAL_COOLDOWN then return end
    if State.isStealing then return end
    if not Steal.Data[prompt] then
        Steal.Data[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            for _, c2 in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                if c2.Function then table.insert(Steal.Data[prompt].hold, c2.Function) end
            end
            for _, c2 in ipairs(getconnections(prompt.Triggered)) do
                if c2.Function then table.insert(Steal.Data[prompt].trigger, c2.Function) end
            end
        end)
    end
    local data = Steal.Data[prompt]
    if not data.ready then return end
    data.ready = false
    State.isStealing = true
    State.stealStartTime = ct
    State.lastStealTick = ct
    task.spawn(function()
        local startT = tick()
        local ok = false
        pcall(function()
            for _, fn in ipairs(data.hold) do task.spawn(fn) end
            while tick() - startT < Steal.StealDuration do
                local prog = math.clamp((tick() - startT) / Steal.StealDuration, 0, 1)
                if _stealFillRef then _stealFillRef.Size = UDim2.new(prog, 0, 1, 0) end
                task.wait(0.016)
            end
            if _stealFillRef then _stealFillRef.Size = UDim2.new(1, 0, 1, 0) end
            for _, fn in ipairs(data.trigger) do task.spawn(fn) end
            ok = true
        end)
        if not ok and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt); ok = true end)
        end
        if not ok then
            pcall(function() prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd() end)
        end
        if _stealFillRef then _stealFillRef.Size = UDim2.new(0, 0, 1, 0) end
        data.ready = true
        State.isStealing = false
    end)
end

function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal = RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or State.isStealing then return end
        local p = findNearestPrompt()
        if p then executeSteal(p) end
    end)
end

function stopAutoSteal()
    if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal = nil end
    State.isStealing = false
    State.lastStealTick = 0
    Steal.plotCache = {}
    Steal.plotCacheTime = {}
    Steal.cachedPrompts = {}
    if _stealFillRef then _stealFillRef.Size = UDim2.new(0, 0, 1, 0) end
end

-- ============================================================
-- SAVE / LOAD CONFIG
-- ============================================================
function saveConfig()
    local cfg = {
        normalSpeed = State.normalSpeed, carrySpeed = State.carrySpeed,
        laggerSpeed = State.laggerSpeed, laggerCarrySpeed = State.laggerCarrySpeed,
        stealRadius = Steal.StealRadius, stealDuration = Steal.StealDuration,
        uiScale = uiScaleObj and uiScaleObj.Scale or 1.0,
        speedKey = Keys.speed.Name, autoLeftKey = Keys.autoLeft.Name, autoRightKey = Keys.autoRight.Name,
        guiHideKey = Keys.guiHide.Name, dropKey = Keys.drop.Name, laggerKey = Keys.lagger.Name,
        tpDownKey = Keys.tpDown.Name, aimbotKey = Keys.aimbot.Name,
        infJump = State.infJumpEnabled, antiRagdoll = State.antiRagdollEnabled,
        fpsBoost = State.fpsBoostEnabled, autoStealEnabled = Steal.AutoStealEnabled,
        tracersEnabled = State.tracersEnabled, splashEnabled = State.splashEnabled, unwalkEnabled = State.unwalkEnabled,
        lockInEnabled = State.lockInEnabled, batCounterEnabled = State.batCounterEnabled,
        medusaCounterEnabled = State.medusaCounterEnabled, mobileBtnVisible = State.mobileBtnVisible,
        jumpMode = State.jumpMode, batAimbotSpeed = State.batAimbotSpeed,
        batAimbotLaggerSpeed = State.batAimbotLaggerSpeed,
        enemySpeedMeterEnabled = State.enemySpeedMeterEnabled, lockButtonsEnabled = State.lockButtonsEnabled,
        fovEnabled = State.fovEnabled, fovValue = State.fovValue, stretchRezEnabled = State.stretchRezEnabled,
        instantResetEnabled = State.instantResetEnabled, instantResetOnMedusa = State.instantResetOnMedusa,
        instantResetKey = State.instantResetKey.Name, autoSpeedEnabled = State.autoSpeedEnabled,
        speedToggled = State.speedToggled, laggerEnabled = State.laggerEnabled,
        autoLeftEnabled = State.autoLeftEnabled, autoRightEnabled = State.autoRightEnabled,
        batAimbotToggled = State.batAimbotToggled, currentSkyTheme = State.currentSkyTheme,
    }
    local ok, enc = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok then pcall(function() _writefile(CONFIG_FILE, enc) end) end
end

function loadConfig()
    local hasFile = false
    pcall(function() hasFile = _isfile(CONFIG_FILE) end)
    if not hasFile then return end
    local raw
    local ok = pcall(function() raw = _readfile(CONFIG_FILE) end)
    if not ok or not raw then return end
    local cfg
    local ok2 = pcall(function() cfg = HttpService:JSONDecode(raw) end)
    if not ok2 or not cfg then return end
    if cfg.normalSpeed then State.normalSpeed = cfg.normalSpeed; if normalBox then normalBox.Text = tostring(cfg.normalSpeed) end end
    if cfg.carrySpeed then State.carrySpeed = cfg.carrySpeed; if carryBox then carryBox.Text = tostring(cfg.carrySpeed) end end
    if cfg.laggerSpeed then State.laggerSpeed = cfg.laggerSpeed; if laggerBox then laggerBox.Text = tostring(cfg.laggerSpeed) end end
    if cfg.laggerCarrySpeed then State.laggerCarrySpeed = cfg.laggerCarrySpeed; if laggerCarryBox then laggerCarryBox.Text = tostring(cfg.laggerCarrySpeed) end end
    if cfg.stealRadius then Steal.StealRadius = cfg.stealRadius end
    if cfg.stealDuration then Steal.StealDuration = cfg.stealDuration end
    if cfg.uiScale and uiScaleObj then uiScaleObj.Scale = cfg.uiScale; if uiScaleBox then uiScaleBox.Text = tostring(cfg.uiScale) end end
    if cfg.autoStealEnabled ~= nil then Steal.AutoStealEnabled = cfg.autoStealEnabled; if cfg.autoStealEnabled then pcall(startAutoSteal) else stopAutoSteal() end end
    if cfg.infJump ~= nil then State.infJumpEnabled = cfg.infJump end
    if cfg.antiRagdoll ~= nil then State.antiRagdollEnabled = cfg.antiRagdoll; if cfg.antiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end end
    if cfg.fpsBoost ~= nil then State.fpsBoostEnabled = cfg.fpsBoost; if cfg.fpsBoost then applyFPSBoost() end end
    if cfg.lockInEnabled ~= nil then State.lockInEnabled = cfg.lockInEnabled; if cfg.lockInEnabled then startLockIn() else stopLockIn() end end
    if cfg.batCounterEnabled then State.batCounterEnabled = true; startBatCounter() end
    if cfg.medusaCounterEnabled then State.medusaCounterEnabled = true; setupMedusaCounter(LP.Character) end
    if cfg.mobileBtnVisible then for k, v in pairs(cfg.mobileBtnVisible) do State.mobileBtnVisible[k] = v end end
    if cfg.jumpMode then State.jumpMode = cfg.jumpMode end
    if cfg.batAimbotSpeed then State.batAimbotSpeed = cfg.batAimbotSpeed end
    if cfg.batAimbotLaggerSpeed then State.batAimbotLaggerSpeed = cfg.batAimbotLaggerSpeed end
    if cfg.enemySpeedMeterEnabled ~= nil then State.enemySpeedMeterEnabled = cfg.enemySpeedMeterEnabled; updateAllSpeedMetersVisibility() end
    if cfg.lockButtonsEnabled ~= nil then State.lockButtonsEnabled = cfg.lockButtonsEnabled end
    if cfg.fovEnabled ~= nil then State.fovEnabled = cfg.fovEnabled; if cfg.fovEnabled then startFov() else stopFov() end end
    if cfg.fovValue then State.fovValue = cfg.fovValue; if State.fovEnabled then workspace.CurrentCamera.FieldOfView = cfg.fovValue end end
    if cfg.stretchRezEnabled ~= nil then State.stretchRezEnabled = cfg.stretchRezEnabled; if cfg.stretchRezEnabled then startStretchRez() else stopStretchRez() end end
    if cfg.instantResetEnabled ~= nil then State.instantResetEnabled = cfg.instantResetEnabled end
    if cfg.instantResetOnMedusa ~= nil then State.instantResetOnMedusa = cfg.instantResetOnMedusa end
    if cfg.instantResetKey and Enum.KeyCode[cfg.instantResetKey] then State.instantResetKey = Enum.KeyCode[cfg.instantResetKey]; Keys.instantReset = State.instantResetKey end
    if cfg.autoSpeedEnabled ~= nil then State.autoSpeedEnabled = cfg.autoSpeedEnabled end
    if cfg.unwalkEnabled ~= nil then State.unwalkEnabled = cfg.unwalkEnabled end
    if cfg.speedToggled ~= nil then State.speedToggled = cfg.speedToggled end
    if cfg.laggerEnabled ~= nil then State.laggerEnabled = cfg.laggerEnabled end
    if cfg.autoLeftEnabled ~= nil then State.autoLeftEnabled = cfg.autoLeftEnabled end
    if cfg.autoRightEnabled ~= nil then State.autoRightEnabled = cfg.autoRightEnabled end
    if cfg.batAimbotToggled ~= nil then State.batAimbotToggled = cfg.batAimbotToggled end
    if cfg.currentSkyTheme then CandyApplyCustomSky(cfg.currentSkyTheme); State.currentSkyTheme = cfg.currentSkyTheme end
    if cfg.speedKey and Enum.KeyCode[cfg.speedKey] then Keys.speed = Enum.KeyCode[cfg.speedKey] end
    if cfg.autoLeftKey and Enum.KeyCode[cfg.autoLeftKey] then Keys.autoLeft = Enum.KeyCode[cfg.autoLeftKey] end
    if cfg.autoRightKey and Enum.KeyCode[cfg.autoRightKey] then Keys.autoRight = Enum.KeyCode[cfg.autoRightKey] end
    if cfg.guiHideKey and Enum.KeyCode[cfg.guiHideKey] then Keys.guiHide = Enum.KeyCode[cfg.guiHideKey] end
    if cfg.dropKey and Enum.KeyCode[cfg.dropKey] then Keys.drop = Enum.KeyCode[cfg.dropKey] end
    if cfg.laggerKey and Enum.KeyCode[cfg.laggerKey] then Keys.lagger = Enum.KeyCode[cfg.laggerKey] end
    if cfg.tpDownKey and Enum.KeyCode[cfg.tpDownKey] then Keys.tpDown = Enum.KeyCode[cfg.tpDownKey] end
    if cfg.aimbotKey and Enum.KeyCode[cfg.aimbotKey] then Keys.aimbot = Enum.KeyCode[cfg.aimbotKey] end
    task.defer(function()
        local vals = {
            State.laggerEnabled, State.autoSpeedEnabled, Steal.AutoStealEnabled,
            State.infJumpEnabled, State.antiRagdollEnabled, State.fpsBoostEnabled,
            State.unwalkEnabled, State.medusaCounterEnabled, State.instantResetOnMedusa,
            State.batAimbotToggled, State.batCounterEnabled, State.lockInEnabled,
            State.tracersEnabled, State.splashEnabled, State.enemySpeedMeterEnabled,
            State.fovEnabled, State.stretchRezEnabled, State.lockButtonsEnabled,
        }
        for i, setter in ipairs(toggleStateSetters) do
            if vals[i] ~= nil then pcall(setter, vals[i]) end
        end
    end)
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
local function setupChar(char)
    task.wait(0.1)
    h = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not h or not hrp then return end
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk = nil end
    unwalkAnimateRef = nil
    if State.unwalkEnabled then
        task.wait(0.3)
        startUnwalkFn()
    end
    stopAntiRagdoll()
    if State.antiRagdollEnabled then
        task.wait(0.5)
        startAntiRagdoll()
    end
    if State.medusaCounterEnabled then setupMedusaCounter(char) end
    if State.batAimbotToggled then stopBatAimbot(); task.wait(0.2); pcall(startBatAimbot) end
    if State.lockInEnabled then task.wait(0.3); startLockIn() end
    if State.batCounterEnabled then startBatCounter() end
    createCountdownBillboard()
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- ============================================================
-- RUNTIME LOOPS
-- ============================================================
RunService.Stepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            for _, part in ipairs(p.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- RAVEN'S HOLD JUMP (KEYBOARD + CONTROLLER)
local jumpKeyPressed = false

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    local isJump = (inp.KeyCode == Enum.KeyCode.Space) or (inp.KeyCode == Enum.KeyCode.ButtonA)
    if isJump then
        jumpKeyPressed = true
        State._jumpHeld = true
        
    end
end)

UIS.InputEnded:Connect(function(inp, gp)
    if gp then return end
    local isJump = (inp.KeyCode == Enum.KeyCode.Space) or (inp.KeyCode == Enum.KeyCode.ButtonA)
    if isJump then
        jumpKeyPressed = false
        State._jumpHeld = false
    end
end)

UIS.JumpRequest:Connect(function()
    if not State.infJumpEnabled then return end
    if State.jumpMode == "Tap" then
        local c = LP.Character
        if c then
            local root = c:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
            end
        end
    end
end)

if State._jumpHoldConn then State._jumpHoldConn:Disconnect() end
local _jumpHoldTimer = 0
State._jumpHoldConn = RunService.Heartbeat:Connect(function(dt)
    if not (State.jumpMode == "Hold" and State.infJumpEnabled and jumpKeyPressed) then _jumpHoldTimer=0; return end
    _jumpHoldTimer = _jumpHoldTimer + dt
    if _jumpHoldTimer < 0.1 then return end
    _jumpHoldTimer = 0
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not root then return end
    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 55, root.AssemblyLinearVelocity.Z)
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ============================================================
-- RENDER STEPPED: speed hack + auto speed switch
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not (h and hrp) then return end
    if State._tpInProgress then return end
    if not State.autoLeftEnabled and not State.autoRightEnabled and not State.batAimbotToggled and not State.routeRunning then
        local spd
        if State.autoSpeedEnabled then
            local isCarry = h.WalkSpeed < 25
            if State.laggerEnabled then
                spd = isCarry and State.laggerCarrySpeed or State.laggerSpeed
            else
                spd = isCarry and State.carrySpeed or State.normalSpeed
            end
        else
            if State.laggerEnabled then
                spd = State.laggerCarrySpeed
            else
                spd = State.speedToggled and State.carrySpeed or State.normalSpeed
            end
        end
        local md = h.MoveDirection
        if md.Magnitude > 0 then
            hrp.Velocity = Vector3.new(md.X * spd, hrp.Velocity.Y, md.Z * spd)
        end
    end
end)

RunService.Heartbeat:Connect(updateTracers)

-- ============================================================
-- INPUT
-- ============================================================
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    local isKb = inp.UserInputType == Enum.UserInputType.Keyboard
    local isGp = inp.UserInputType == Enum.UserInputType.Gamepad1 or inp.UserInputType == Enum.UserInputType.Gamepad2
    if not isKb and not isGp then return end
    local kc = inp.KeyCode
    if kc == Enum.KeyCode.Unknown then return end
    if kc == Keys.speed then
        State.speedToggled = not State.speedToggled
        State.laggerEnabled = false
        autoSave()
    elseif kc == Keys.autoLeft then
        State.autoLeftEnabled = not State.autoLeftEnabled
        if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
        autoSave()
    elseif kc == Keys.autoRight then
        State.autoRightEnabled = not State.autoRightEnabled
        if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
        autoSave()
    elseif kc == Keys.drop then
        performDrop()
    elseif kc == Keys.lagger then
        State.laggerEnabled = not State.laggerEnabled
        if State.laggerEnabled then
            State._prevBatSpeed = State.batAimbotSpeed
            State.batAimbotSpeed = State.batAimbotLaggerSpeed
        else
            if State._prevBatSpeed then
                State.batAimbotSpeed = State._prevBatSpeed
                State._prevBatSpeed = nil
            end
        end
        autoSave()
    elseif kc == Keys.tpDown then
        waveTpDown()
    elseif kc == Keys.aimbot then
        State.batAimbotToggled = not State.batAimbotToggled
        if State.batAimbotToggled then
            pcall(startBatAimbot)
        else
            stopBatAimbot()
        end
        autoSave()
    elseif kc == Keys.instantReset then
        if State.instantResetEnabled then instantReset() end
    elseif kc == Keys.guiHide then
        if isKb then
            mainOuter.Visible = not mainOuter.Visible
            autoSave()
        end
    end
end)

-- ============================================================
-- INIT
-- ============================================================
loadPresetsFile()
rebuildPresetList()
loadConfig()
loadMenuPosition()
loadStealBarPosition()
loadMenuVisibility()

task.spawn(function()
    task.wait(0.3)
    local lastPresetName
    pcall(function()
        if _isfile(LAST_PRESET_FILE) then
            local raw = _readfile(LAST_PRESET_FILE)
            if raw then
                local data = HttpService:JSONDecode(raw)
                if data then
                    lastPresetName = data.lastPreset
                end
            end
        end
    end)
    if lastPresetName and lastPresetName ~= "" then
        for _, preset in ipairs(Presets) do
            if preset.name == lastPresetName then
                applyPreset(preset.data)
                break
            end
        end
    end
end)

task.spawn(function()
    while gui and gui.Parent do
        local plot
        pcall(function()
            for plotNum, position in pairs({[3]=PLOT3_POS, [7]=PLOT7_POS}) do
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "PlotSign" and (obj.Position - position).Magnitude < 5 then
                        for _, child in ipairs(obj:GetDescendants()) do
                            if child:IsA("SurfaceGui") then
                                for _, label in ipairs(child:GetDescendants()) do
                                    if label:IsA("TextLabel") and label.Text ~= "" then
                                        if string.find(label.Text, LP.Name) or string.find(label.Text, LP.DisplayName) then
                                            plot = plotNum
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        if plot == 3 then
            State.detectedSpawn = 1
        elseif plot == 7 then
            State.detectedSpawn = 2
        end
        task.wait(2)
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then setupEnemySpeedMeter(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LP then setupEnemySpeedMeter(p) end end)

updateAllSpeedMetersVisibility()
task.spawn(showSplashText)
task.delay(1, function() pcall(saveConfig) end)

print("red.cc loaded")
