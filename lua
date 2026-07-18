repeat task.wait() until game:IsLoaded()

local Players, RunService, UIS, TS, Lighting, HS =
    game:GetService("Players"),
    game:GetService("RunService"),
    game:GetService("UserInputService"),
    game:GetService("TweenService"),
    game:GetService("Lighting"),
    game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ============ RENKLER ============
local COLORS = {
    BG = Color3.fromRGB(35, 45, 85),
    CARD = Color3.fromRGB(45, 55, 95),
    ACCENT = Color3.fromRGB(110, 160, 255),
    TEXT = Color3.new(1, 1, 1),
    TEXT_DIM = Color3.new(0.85, 0.85, 0.9),
    STROKE_START = Color3.fromRGB(80, 120, 200),
    STROKE_MID = Color3.fromRGB(130, 180, 255),
    TOGGLE_OFF = Color3.fromRGB(55, 65, 110),
    TOGGLE_ON = Color3.fromRGB(110, 160, 255),
    BUTTON = Color3.fromRGB(55, 65, 110),
    BUTTON_ACTIVE = Color3.fromRGB(120, 170, 255),
}

-- ============ AYARLAR ============
local NS, CS = 60, 30
local LAGGER_SPEED = 15
local LAGGER_CARRY_SPEED = 24.5
local speedMode, antiRagdollEnabled, infJumpEnabled = false, false, false
local laggerToggled = false
local laggerPhase = 0
local medusaCounterEnabled = false
local batCounterEnabled = false
local unwalkEnabled = false
local autoMedResetEnabled = false
local medusaDebounce, medusaLastUsed, dropActive = false, 0, false
local autoLeftEnabled, autoRightEnabled = false, false
local autoLeftSetVisual, autoRightSetVisual = nil, nil
local speedLabel = nil
local autoBatEnabled = false
local autoSwingEnabled = true
local autoBatSetVisual = nil
local setBatCounterVisual = nil
local startBatCounter, stopBatCounter = nil, nil
local antiLagEnabled = false
local removeAccessoriesEnabled = false
local antiLagDescConn = nil
local stretchRezEnabled = false
local stretchRezConn = nil
local setStretchRezVisual = nil
local unwalkSavedAnimate = nil
local _anyKeyListening = false
local autoTPEnabled = false
local autoTPHeight = 20
local autoTPConn = nil
local setAutoTPVisual = nil
local guiScale = 0.75
local mbScale = 0.85

local aimbot2Enabled = false
local aimbot2Cooldown = false
local aimbot2SetVisual = nil
local AB2_SWING_COOLDOWN = 0.08

local _aimbotConn = nil
local _aimbotTarget = nil
local _aimbotHittingCooldown = false
local AB_SWING_COOLDOWN = 0.08

local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"

local setCarrySpeedVisual = nil
local setLaggerModeVisual = nil
local setLaggerCarryVisual = nil
local setInstaGrab = nil
local setInfJumpVisual = nil
local setAntiRagVisual = nil
local setMedusaVisual = nil
local setUnwalkVisual = nil
local setAntiLagVisual = nil
local setAutoSwingVisual = nil
local setAutoMedResetVisual = nil

local KB = {
    DropBrainrot = {kb = Enum.KeyCode.X, gp = nil},
    AutoLeft = {kb = Enum.KeyCode.Z, gp = nil},
    AutoRight = {kb = Enum.KeyCode.C, gp = nil},
    AutoBat = {kb = Enum.KeyCode.E, gp = nil},
    Aimbot2 = {kb = Enum.KeyCode.V, gp = nil},
    TPFloor = {kb = Enum.KeyCode.T, gp = nil},
    GuiHide = {kb = Enum.KeyCode.LeftControl, gp = nil},
    SpeedToggle = {kb = Enum.KeyCode.Q, gp = nil},
    LaggerToggle = {kb = Enum.KeyCode.R, gp = nil},
    InstaReset = {kb = Enum.KeyCode.G, gp = nil},
}

local MOVE_KEYS = {
    [Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true
}
local lastMoveDir = Vector3.new(0,0,0)
local AP_L1, AP_L2 = Vector3.new(-476.47,-6.28,92.73), Vector3.new(-483.12,-4.95,94.81)
local AP_R1, AP_R2 = Vector3.new(-476.16,-6.52,25.62), Vector3.new(-483.06,-5.03,25.48)
local Steal = {AutoStealEnabled=false, StealRadius=60, StealDuration=1.4, Data={}}
local isStealing = false
local stealStartTime = nil
local Conns = {autoSteal=nil,antiRag=nil,batCounter=nil,anchor={},progress=nil,autoMedReset=nil}
local MEDUSA_COOLDOWN = 25
local batCounterDebounce = false
local progressRadLbl, progressFill, progressPct = nil, nil, nil
local modeValLbl = nil
local normalBox, carryBox, laggerBox, laggerCarryBox, radInput, autoTPHeightBox = nil, nil, nil, nil, nil, nil

-- ============ TEMEL FONKSİYONLAR ============
local function findBatTool()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
            return tool
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
                return tool
            end
        end
    end
    return nil
end

local function getClosestAimbotTarget()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
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
    return closest
end

local function trySwingBat()
    if _aimbotHittingCooldown then return end
    _aimbotHittingCooldown = true
    pcall(function()
        local c = LP.Character
        if not c then return end
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        local tool = findBatTool()
        if tool then
            if tool.Parent ~= c and hum2 then pcall(function() hum2:EquipTool(tool) end) end
            local remote = tool:FindFirstChildOfClass("RemoteEvent")
            if remote then pcall(function() remote:FireServer() end)
            else pcall(function() tool:Activate() end) end
        end
    end)
    task.delay(AB_SWING_COOLDOWN, function() _aimbotHittingCooldown = false end)
end

local function startEnvyBatAimbot()
    if _aimbotConn then _aimbotConn:Disconnect() end
    local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum0 then hum0.AutoRotate = false end
    _aimbotConn = RunService.RenderStepped:Connect(function()
        if not autoBatEnabled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if not char:FindFirstChildOfClass("Tool") then
            local bat = findBatTool()
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end
        local target = getClosestAimbotTarget()
        if not target then return end
        _aimbotTarget = target
        local targetVel = target.AssemblyLinearVelocity
        local myPos = root.Position
        local targetPos = target.Position
        local predictPos = targetPos + targetVel * 0.14
        predictPos = predictPos + target.CFrame.LookVector * 0.3
        local direction = predictPos - myPos
        local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
        local chaseSpeed = 58
        local desiredHeight = targetPos.Y + 3.7
        local yVel = (desiredHeight - myPos.Y) * 19.5 + targetVel.Y * 0.8
        if hum.FloorMaterial ~= Enum.Material.Air then yVel = math.max(yVel, 13) end
        yVel = math.clamp(yVel, -70, 110)
        local desiredVel = Vector3.new(flatDir.X * chaseSpeed, yVel, flatDir.Z * chaseSpeed)
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, 0.8)
        local speed3 = targetVel.Magnitude
        local predictTime = math.clamp(speed3 / 150, 0.05, 0.2)
        local predictedPos = targetPos + targetVel * predictTime
        local toPredict = predictedPos - myPos
        if toPredict.Magnitude > 0.1 then
            local goalCF = CFrame.lookAt(myPos, predictedPos)
            local curCF = root.CFrame
            local diffCF = curCF:Inverse() * goalCF
            local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
            rx = math.clamp(rx, -2.5, 2.5)
            ry = math.clamp(ry, -2.5, 2.5)
            rz = math.clamp(rz, -2.5, 2.5)
            local tiltSpeed = 42
            root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(Vector3.new(rx*tiltSpeed, ry*tiltSpeed, rz*tiltSpeed))
        end
        if autoSwingEnabled then trySwingBat() end
    end)
end

local function stopEnvyBatAimbot()
    if _aimbotConn then _aimbotConn:Disconnect(); _aimbotConn = nil end
    _aimbotTarget = nil; _aimbotHittingCooldown = false
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    local hum2 = c and c:FindFirstChildOfClass("Humanoid")
    if hum2 then hum2.AutoRotate = true end
end

local _ab2Conn = nil
local _ab2HitCooldown = false

local function ab2GetBat()
    local char = LP.Character; if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local bp2 = LP:FindFirstChild("Backpack")
    if bp2 then
        tool = bp2:FindFirstChild("Bat")
        if tool then tool.Parent = char; return tool end
    end
    local SlapList = {"Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
    for _, name in ipairs(SlapList) do
        local t = char:FindFirstChild(name); if t then return t end
        if bp2 then t = bp2:FindFirstChild(name); if t then t.Parent = char; return t end end
    end
    return nil
end

local function ab2GetClosest()
    local char = LP.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (root.Position - tr.Position).Magnitude
                if d < cd then cd = d; cp = p end
            end
        end
    end
    return cp
end

local function ab2TryHit()
    if _ab2HitCooldown then return end
    _ab2HitCooldown = true
    pcall(function()
        local bat = ab2GetBat()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(AB2_SWING_COOLDOWN, function() _ab2HitCooldown = false end)
end

local function startAimbot2()
    if _ab2Conn then _ab2Conn:Disconnect() end
    local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum0 then hum0.AutoRotate = false end
    _ab2Conn = RunService.Heartbeat:Connect(function()
        if not aimbot2Enabled then return end
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local target = ab2GetClosest()
        if not target or not target.Character then return end
        local tr = target.Character:FindFirstChild("HumanoidRootPart"); if not tr then return end
        if sethiddenproperty then pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tr) end) end
        local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
        if (root.Position - targetPos).Magnitude > 8 then root.CFrame = CFrame.new(targetPos) end
        local cam = workspace.CurrentCamera
        cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
        ab2TryHit()
    end)
end

local function stopAimbot2()
    if _ab2Conn then _ab2Conn:Disconnect(); _ab2Conn = nil end
    _ab2HitCooldown = false
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
    local hum2 = c and c:FindFirstChildOfClass("Humanoid")
    if hum2 then hum2.AutoRotate = true end
end

local function cursedInstaReset()
    if not cursedResetRemote then
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then
                cursedResetRemote = desc; break
            end
        end
    end
    if not cursedResetRemote then return end

    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
        return
    end

    local resetDetected = false
    local conns = {}
    if humanoid then
        table.insert(conns, humanoid.Died:Connect(function() resetDetected = true end))
        table.insert(conns, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health <= 0 then resetDetected = true end
        end))
    end
    if character then
        table.insert(conns, character.AncestryChanged:Connect(function(_, parent)
            if not parent then resetDetected = true end
        end))
    end

    task.spawn(function()
        for _ = 1, 50 do
            if resetDetected then break end
            pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LP, "balloon") end)
            task.wait()
        end
        for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
    end)
end

-- ============ BLACKLIST KONTROL ============
task.spawn(function()
    local BLACKLIST_URL = "https://pastebin.com/2zLUXv2K"
    pcall(function() HS.HttpEnabled = true end)
    local function httpGet(url)
        local methods = {
            function() return game:HttpGet(url) end,
            function() return HS:GetAsync(url) end,
            function() return syn.request({Url=url,Method="GET"}).Body end,
            function() return http_request({Url=url,Method="GET"}).Body end,
            function() return request({Url=url,Method="GET"}).Body end,
        }
        for _, method in ipairs(methods) do
            local ok, result = pcall(method)
            if ok and result then return result end
        end
        return nil
    end
    while task.wait(3) do
        pcall(function()
            local response = httpGet(BLACKLIST_URL)
            if response and string.find(response, tostring(LP.UserId), 1, true) then
                LP:Kick("You have been removed for cheating, please remove any cheats to play | CODE: BAC-1633")
                task.wait(999999)
            end
        end)
    end
end)

-- ============ YARDIMCI FONKSİYONLAR ============
local function getActiveMoveSpeed()
    return laggerToggled and (laggerPhase==2 and LAGGER_CARRY_SPEED or LAGGER_SPEED) or (speedMode and CS or NS)
end

local function getAutoPathSpeed()
    return laggerToggled and LAGGER_SPEED or NS
end

local function isRagdollState(hum)
    if not hum then return true end
    local st = hum:GetState()
    return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

local function isMyPlotByName(plotName)
    local plots = workspace:FindFirstChild("Plots"); if not plots then return false end
    local plot = plots:FindFirstChild(plotName); if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then local yb = sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled==true end end
    return false
end

local function resetProgressBar()
    if progressPct then progressPct.Text = "0%" end
    if progressFill then progressFill.Size = UDim2.new(0,0,1,0) end
end

local function findNearestPrompt()
    local char = LP.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local nearest, dist = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do
            local base = pod:FindFirstChild("Base")
            local sp = base and base:FindFirstChild("Spawn")
            if sp then
                local d = (sp.Position-root.Position).Magnitude
                if d <= Steal.StealRadius and d < dist then
                    local att = sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _, prompt in ipairs(att:GetChildren()) do
                            if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Steal") then
                                nearest, dist = prompt, d
                            end
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
    if not Steal.Data[prompt] then
        Steal.Data[prompt] = {hold={},trigger={},ready=true}
        if getconnections then
            for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
            for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
        end
    end
    local data = Steal.Data[prompt]
    if not data.ready then return end
    data.ready = false; isStealing = true; stealStartTime = tick()
    if Conns.progress then Conns.progress:Disconnect() end
    Conns.progress = RunService.Heartbeat:Connect(function()
        if not isStealing then Conns.progress:Disconnect(); Conns.progress=nil; return end
        local prog = math.clamp((tick()-stealStartTime)/Steal.StealDuration,0,1)
        if progressFill then progressFill.Size=UDim2.new(prog,0,1,0) end
        if progressPct then progressPct.Text=math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        for _,fn in ipairs(data.hold) do task.spawn(fn) end
        task.wait(Steal.StealDuration)
        for _,fn in ipairs(data.trigger) do task.spawn(fn) end
        if Conns.progress then Conns.progress:Disconnect(); Conns.progress=nil end
        resetProgressBar(); data.ready=true; isStealing=false
    end)
end

local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal = RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        local p = findNearestPrompt(); if p then executeSteal(p) end
    end)
end

local function stopAutoSteal()
    if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal=nil end
    if Conns.progress then Conns.progress:Disconnect(); Conns.progress=nil end
    isStealing=false; resetProgressBar()
end

local function startAutoMedReset()
    if Conns.autoMedReset then return end
    Conns.autoMedReset = RunService.Heartbeat:Connect(function()
        if not autoMedResetEnabled then return end
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            local hasMedusa = false
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Anchored and part.Transparency == 1 then hasMedusa = true; break end
            end
            if hasMedusa then task.spawn(cursedInstaReset) end
        end
    end)
end

local function stopAutoMedReset()
    if Conns.autoMedReset then Conns.autoMedReset:Disconnect(); Conns.autoMedReset=nil end
end

RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            for _,part in ipairs(p.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char=LP.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0); return end
    if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled and not aimbot2Enabled then
        local md=hum.MoveDirection; local spd=getActiveMoveSpeed()
        if md.Magnitude>0 then lastMoveDir=md; hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
            local anyHeld=false
            for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
            if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
        end
    end
    if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)

local alConn,arConn=nil,nil; local alPhase,arPhase=1,1

local function stopAutoLeft()
    if alConn then alConn:Disconnect(); alConn=nil end; alPhase=1
    local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
    if autoLeftSetVisual then autoLeftSetVisual(false) end
end

local function stopAutoRight()
    if arConn then arConn:Disconnect(); arConn=nil end; arPhase=1
    local char=LP.Character; if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
    if autoRightSetVisual then autoRightSetVisual(false) end
end

local function startAutoLeft()
    if alConn then alConn:Disconnect() end; alPhase=1
    alConn=RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local char=LP.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero,false); return end
        local spd=getAutoPathSpeed()
        if alPhase==1 then
            local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                alPhase=2; local d=AP_L2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd); return
            end
            local d=AP_L1-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif alPhase==2 then
            local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
                autoLeftEnabled=false; if alConn then alConn:Disconnect(); alConn=nil end
                alPhase=1; if autoLeftSetVisual then autoLeftSetVisual(false) end; return
            end
            local d=AP_L2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function startAutoRight()
    if arConn then arConn:Disconnect() end; arPhase=1
    arConn=RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local char=LP.Character; if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero,false); return end
        local spd=getAutoPathSpeed()
        if arPhase==1 then
            local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                arPhase=2; local d=AP_R2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd); return
            end
            local d=AP_R1-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif arPhase==2 then
            local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
            if (tgt-hrp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
                autoRightEnabled=false; if arConn then arConn:Disconnect(); arConn=nil end
                arPhase=1; if autoRightSetVisual then autoRightSetVisual(false) end; return
            end
            local d=AP_R2-hrp.Position; local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false); hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end

local function setupSpeedIndicator(char)
    local head=char:WaitForChild("Head",5); if not head then return end
    local bb=Instance.new("BillboardGui",head)
    bb.Size=UDim2.new(0,160,0,60); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
    speedLabel=Instance.new("TextLabel",bb)
    speedLabel.Size=UDim2.new(1,0,0,20); speedLabel.BackgroundTransparency=1
    speedLabel.Text="Speed: 0"; speedLabel.TextColor3=COLORS.TEXT
    speedLabel.Font=Enum.Font.Gotham; speedLabel.TextScaled=true
    speedLabel.TextStrokeTransparency=0; speedLabel.TextStrokeColor3=Color3.new(0,0,0)
end

local function startAntiRagdoll()
    if Conns.antiRag then return end
    Conns.antiRag=RunService.Heartbeat:Connect(function()
        local char=LP.Character; if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); local root=char:FindFirstChild("HumanoidRootPart")
        if hum then
            local st=hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject=hum
                pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule"); if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
                if root then root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero end
            end
        end
        for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
    end)
end

local function stopAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end
end

local holdJumpPressed = false; local holdJumpActive = false
local function applyInfJumpBoost(boost)
    if not infJumpEnabled then return end
    local char=LP.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart")
    if root then root.Velocity=Vector3.new(root.Velocity.X,boost,root.Velocity.Z) end
end
UIS.JumpRequest:Connect(function() applyInfJumpBoost(50) end)
UIS.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
        holdJumpPressed=true
        task.delay(0.12,function() if holdJumpPressed then holdJumpActive=true; applyInfJumpBoost(50) end end)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space then holdJumpPressed=false; holdJumpActive=false end
end)
RunService.Heartbeat:Connect(function() if holdJumpActive then applyInfJumpBoost(50) end end)

local function startUnwalk()
    local c=LP.Character; if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim=c:FindFirstChild("Animate")
    if anim then unwalkSavedAnimate=anim:Clone(); anim:Destroy() end
end

local function stopUnwalk()
    local c=LP.Character
    if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent=c; unwalkSavedAnimate=nil end
end

local _wfConns={}
local function runDrop()
    if dropActive then return end
    if autoBatEnabled then autoBatEnabled=false; stopEnvyBatAimbot(); if autoBatSetVisual then autoBatSetVisual(false) end end
    if aimbot2Enabled then aimbot2Enabled=false; stopAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
    dropActive=true
    local colConn=RunService.Stepped:Connect(function()
        if not dropActive then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end
            end
        end
    end)
    table.insert(_wfConns,colConn)
    local flingThread=coroutine.create(function()
        while dropActive do
            RunService.Heartbeat:Wait()
            local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
            if not root then break end
            local vel=root.Velocity
            root.Velocity=vel*10000+Vector3.new(0,10000,0)
            RunService.RenderStepped:Wait()
            if root and root.Parent then root.Velocity=vel end
            RunService.Stepped:Wait()
            if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end
        end
    end)
    table.insert(_wfConns,flingThread)
    coroutine.resume(flingThread)
    task.delay(0.1,function()
        dropActive=false
        for _,c in ipairs(_wfConns) do
            if typeof(c)=="RBXScriptConnection" then c:Disconnect()
            elseif type(c)=="thread" then pcall(coroutine.close,c) end
        end
        _wfConns={}
    end)
end

local function doAutoTPDown(force)
    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
    if not force then
        if hum2.FloorMaterial~=Enum.Material.Air then return end
        if hrp.Position.Y<autoTPHeight then return end
    end
    hrp.CFrame=CFrame.new(hrp.Position.X,-7.00,hrp.Position.Z)*CFrame.Angles(0,select(2,hrp.CFrame:ToEulerAnglesYXZ()),0)
    hrp.AssemblyLinearVelocity=Vector3.zero
end

local function startAutoTP()
    if autoTPConn then task.cancel(autoTPConn); autoTPConn=nil end
    autoTPConn=task.spawn(function() while autoTPEnabled do task.wait(0.1); pcall(function() doAutoTPDown(false) end) end end)
end

local function stopAutoTP()
    autoTPEnabled=false
    if autoTPConn then task.cancel(autoTPConn); autoTPConn=nil end
end

local function runTPFloor() pcall(function() doAutoTPDown(true) end) end

local function enableStretchRez()
    stretchRezEnabled=true; workspace.CurrentCamera.FieldOfView=107
    if stretchRezConn then stretchRezConn:Disconnect() end
    stretchRezConn=RunService.RenderStepped:Connect(function()
        if not stretchRezEnabled then stretchRezConn:Disconnect(); stretchRezConn=nil; return end
        workspace.CurrentCamera.FieldOfView=107
    end)
end

local function disableStretchRez()
    stretchRezEnabled=false
    if stretchRezConn then stretchRezConn:Disconnect(); stretchRezConn=nil end
    workspace.CurrentCamera.FieldOfView=70
end

local function applyAntiLagDerender(obj)
    pcall(function()
        if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy()
        elseif obj:IsA("BasePart") then obj.Material=Enum.Material.Plastic; obj.Reflectance=0; obj.CastShadow=false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled=false
        elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
            for _,t in ipairs(obj:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
        end
    end)
end

local function enableAntiLag()
    removeAccessoriesEnabled=true; antiLagEnabled=true
    Lighting.GlobalShadows=false; Lighting.FogEnd=1e10; Lighting.Brightness=1
    Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0
    for _,e in pairs(Lighting:GetChildren()) do
        pcall(function()
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled=false end
        end)
    end
    for _,obj in ipairs(workspace:GetDescendants()) do applyAntiLagDerender(obj) end
    if antiLagDescConn then antiLagDescConn:Disconnect() end
    antiLagDescConn=workspace.DescendantAdded:Connect(function(obj) if removeAccessoriesEnabled then applyAntiLagDerender(obj) end end)
end

local function disableAntiLag()
    removeAccessoriesEnabled=false; antiLagEnabled=false
    if antiLagDescConn then antiLagDescConn:Disconnect(); antiLagDescConn=nil end
end

local function findMedusa()
    local c=LP.Character; if not c then return nil end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
    local bp=LP:FindFirstChild("Backpack")
    if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
    return nil
end

local function useMedusaCounter()
    if medusaDebounce then return end; if tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end
    local c=LP.Character; if not c then return end; medusaDebounce=true
    local med=findMedusa(); if not med then medusaDebounce=false; return end
    if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
    pcall(function() med:Activate() end); medusaLastUsed=tick(); medusaDebounce=false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function() if part.Anchored and part.Transparency==1 then useMedusaCounter() end end)
end

local function setupMedusa(char)
    for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end; Conns.anchor={}
    if not char then return end
    for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
    table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end))
end

local function stopMedusaCounter()
    for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end; Conns.anchor={}
end

local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
    local c=LP.Character; if not c then return nil end
    local bp=LP:FindFirstChildOfClass("Backpack")
    for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name)); if t then return t end
    end
    for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end

local function swingBatForCounter(bat,char)
    local hum2=char:FindFirstChildOfClass("Humanoid")
    if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end); task.wait(0.05) end end
    local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end); task.wait(0.15); pcall(function() remote:FireServer() end)
    else pcall(function() bat:Activate() end); task.wait(0.15); pcall(function() bat:Activate() end) end
end

startBatCounter=function()
    if Conns.batCounter then return end
    Conns.batCounter=RunService.Heartbeat:Connect(function()
        if not batCounterEnabled or batCounterDebounce then return end
        local char=LP.Character; if not char then return end
        local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local st=hum2:GetState()
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            batCounterDebounce=true
            task.spawn(function()
                local bat=findBatForCounter()
                if bat then swingBatForCounter(bat,char) end
                task.wait(0.5); batCounterDebounce=false
            end)
        end
    end)
end

stopBatCounter=function()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end
    batCounterDebounce=false
end

local function enableAutoBat()
    if autoLeftEnabled then autoLeftEnabled=false; stopAutoLeft() end
    if autoRightEnabled then autoRightEnabled=false; stopAutoRight() end
    if aimbot2Enabled then aimbot2Enabled=false; stopAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
    autoBatEnabled=true; startEnvyBatAimbot()
end

local function disableAutoBat()
    autoBatEnabled=false; stopEnvyBatAimbot()
end

local function enableAimbot2()
    if autoLeftEnabled then autoLeftEnabled=false; stopAutoLeft() end
    if autoRightEnabled then autoRightEnabled=false; stopAutoRight() end
    if autoBatEnabled then autoBatEnabled=false; stopEnvyBatAimbot(); if autoBatSetVisual then autoBatSetVisual(false) end end
    aimbot2Enabled=true; startAimbot2()
end

local function disableAimbot2()
    aimbot2Enabled=false; stopAimbot2()
end

local function queueAutoLeftStart()
    autoLeftEnabled=true
    if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
    if autoBatEnabled then disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
    if aimbot2Enabled then disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
    startAutoLeft()
end

local function queueAutoRightStart()
    autoRightEnabled=true
    if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
    if autoBatEnabled then disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
    if aimbot2Enabled then disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
    startAutoRight()
end

local function queueAutoBatStart()
    if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
    if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
    if aimbot2Enabled then disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
    enableAutoBat()
end

local function queueAimbot2Start()
    if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
    if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
    if autoBatEnabled then disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
    enableAimbot2()
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5); setupSpeedIndicator(char)
    if medusaCounterEnabled then setupMedusa(char) end
    if batCounterEnabled then startBatCounter() end
    if unwalkEnabled then task.wait(0.5); startUnwalk() end
    if autoBatEnabled then task.wait(0.2); startEnvyBatAimbot() end
    if aimbot2Enabled then task.wait(0.2); startAimbot2() end
end)
if LP.Character then setupSpeedIndicator(LP.Character) end

local function refreshSpeedModeLabel()
    if modeValLbl then modeValLbl.Text = laggerToggled and (laggerPhase==2 and "Lagger Carry" or "Lagger Normal") or (speedMode and "Carry" or "Normal") end
end

local function toggleCarryMode()
    if laggerToggled then
        laggerToggled=false; laggerPhase=0
        if setLaggerModeVisual then setLaggerModeVisual(false) end
        if setLaggerCarryVisual then setLaggerCarryVisual(false) end
        speedMode=true
    else speedMode=not speedMode end
    if setCarrySpeedVisual then setCarrySpeedVisual(speedMode) end
    refreshSpeedModeLabel()
end

local function toggleLaggerMode()
    if not laggerToggled then
        if speedMode then speedMode=false; if setCarrySpeedVisual then setCarrySpeedVisual(false) end end
        laggerToggled=true; laggerPhase=1
    elseif laggerPhase==1 then laggerPhase=2
    else laggerPhase=1 end
    if setLaggerModeVisual then setLaggerModeVisual(laggerPhase==1) end
    if setLaggerCarryVisual then setLaggerCarryVisual(laggerPhase==2) end
    refreshSpeedModeLabel()
end

local function applyGuiScale(scale)
    guiScale = math.clamp(scale, 0.3, 3.0)
end

local function applyMbScale(scale)
    mbScale = math.clamp(scale, 0.3, 3.0)
end

local _mainFrame = nil

local function buildGui()
    local oldCore = game:GetService("CoreGui"):FindFirstChild("MoonHub")
    if oldCore then oldCore:Destroy() end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local oldGui = pg:FindFirstChild("MoonHub")
        if oldGui then oldGui:Destroy() end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MoonHub"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10
    gui.IgnoreGuiInset = true
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    if not pcall(function() gui.Parent = game:GetService("CoreGui") end) then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end

    local function addAnimatedStroke(frame, thickness)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Thickness = thickness or 1.5
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = COLORS.STROKE_START
        stroke.Transparency = 0

        local gradient = Instance.new("UIGradient", stroke)
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, COLORS.STROKE_START),
            ColorSequenceKeypoint.new(0.5, COLORS.STROKE_MID),
            ColorSequenceKeypoint.new(1, COLORS.STROKE_START)
        })
        gradient.Rotation = 0

        task.spawn(function()
            while frame and frame.Parent do
                gradient.Rotation = (gradient.Rotation + 1.2) % 360
                task.wait()
            end
        end)
        return stroke
    end

    local bubble = Instance.new("TextButton", gui)
    bubble.Name = "MoonHubBubble"
    bubble.Size = UDim2.new(0, 100, 0, 28)
    bubble.Position = UDim2.new(0, 20, 0.5, -14)
    bubble.BackgroundColor3 = COLORS.BG
    bubble.BackgroundTransparency = 0.2
    bubble.BorderSizePixel = 0
    bubble.Text = "Moon Hub"
    bubble.TextColor3 = COLORS.TEXT
    bubble.Font = Enum.Font.GothamBold
    bubble.TextSize = 14
    bubble.ZIndex = 20
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 8)
    addAnimatedStroke(bubble, 1.5)

    local main = Instance.new("Frame", gui)
    main.Name = "Main"
    main.Size = UDim2.new(0, math.floor(280 * guiScale), 0, math.floor(460 * guiScale))
    main.Position = UDim2.new(0.5, -140, 0.5, -230)
    main.BackgroundColor3 = COLORS.BG
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    addAnimatedStroke(main, 2.8)
    _mainFrame = main

    local function dragFrame(frame)
        local dn, ds, sp = false
        frame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dn = true; ds = i.Position; sp = frame.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dn = false end end)
            end
        end)
        frame.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                di = i
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if i == di and dn then
                local delta = i.Position - ds
                frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
            end
        end)
    end
    dragFrame(main)

    local header = Instance.new("Frame", main)
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundTransparency = 1

    local ttl = Instance.new("TextLabel", header)
    ttl.Size = UDim2.new(0, 180, 1, 0)
    ttl.Position = UDim2.new(0, 12, 0, 0)
    ttl.BackgroundTransparency = 1
    ttl.Text = "Moon Hub"
    ttl.TextColor3 = COLORS.TEXT
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 17
    ttl.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.TEXT
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    addAnimatedStroke(closeBtn, 1)
    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    local content = Instance.new("ScrollingFrame", main)
    content.Name = "Content"
    content.Size = UDim2.new(1, -14, 1, -48)
    content.Position = UDim2.new(0, 7, 0, 42)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ClipsDescendants = true

    local contentList = Instance.new("UIListLayout", content)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Padding = UDim.new(0, 5)

    local contentPad = Instance.new("UIPadding", content)
    contentPad.PaddingLeft = UDim.new(0, 4)
    contentPad.PaddingRight = UDim.new(0, 4)
    contentPad.PaddingTop = UDim.new(0, 4)
    contentPad.PaddingBottom = UDim.new(0, 4)

    local lo = 0
    local function LO()
        lo = lo + 1
        return lo
    end

    local function mkRow(parent, h)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, h or 30)
        f.BackgroundColor3 = COLORS.CARD
        f.BorderSizePixel = 0
        f.LayoutOrder = LO()
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        addAnimatedStroke(f, 1)
        return f
    end

    local function mkLabel(row, txt)
        local l = Instance.new("TextLabel", row)
        l.Size = UDim2.new(0.5, 0, 1, 0)
        l.Position = UDim2.new(0, 8, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = COLORS.TEXT
        l.Font = Enum.Font.Gotham
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        return l
    end

    local function animPill(pill, dot, on)
        TS:Create(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            BackgroundColor3 = on and COLORS.TOGGLE_ON or COLORS.TOGGLE_OFF
        }):Play()
        TS:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = on and COLORS.TEXT or COLORS.TOGGLE_OFF
        }):Play()
    end

    local function mkPill(row, offset)
        local pill = Instance.new("Frame", row)
        pill.Size = UDim2.new(0, 34, 0, 16)
        pill.Position = UDim2.new(1, -(offset or 44), 0.5, -8)
        pill.BackgroundColor3 = COLORS.TOGGLE_OFF
        pill.BorderSizePixel = 0
        pill.ZIndex = 3
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, 3, 0.5, -6)
        dot.BackgroundColor3 = COLORS.TOGGLE_OFF
        dot.BorderSizePixel = 0
        dot.ZIndex = 4
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        return pill, dot
    end

    local function mkToggle(parent, txt, cb)
        local row = mkRow(parent, 30)
        mkLabel(row, txt)
        local pill, dot = mkPill(row, 44)
        local on = false
        local function sv(s)
            on = s
            animPill(pill, dot, s)
            if cb then cb(s) end
        end
        local clk = Instance.new("TextButton", pill)
        clk.Size = UDim2.new(1, 0, 1, 0)
        clk.BackgroundTransparency = 1
        clk.Text = ""
        clk.ZIndex = 5
        clk.Activated:Connect(function()
            if _anyKeyListening then return end
            on = not on
            sv(on)
        end)
        return sv
    end

    local function mkBox(parent, default, w, xOff, cb)
        local tb = Instance.new("TextBox", parent)
        tb.Size = UDim2.new(0, w or 44, 0, 20)
        tb.Position = UDim2.new(1, -(xOff or 54), 0.5, -10)
        tb.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        tb.BorderSizePixel = 0
        tb.Text = tostring(default)
        tb.TextColor3 = COLORS.TEXT
        tb.Font = Enum.Font.Gotham
        tb.TextSize = 13
        tb.ClearTextOnFocus = false
        tb.ZIndex = 5
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        local bs = Instance.new("UIStroke", tb)
        bs.Color = COLORS.TOGGLE_OFF
        bs.Thickness = 1
        tb.FocusLost:Connect(function()
            if cb then
                local n = tonumber(tb.Text)
                if n then cb(n) else tb.Text = tostring(default) end
            end
        end)
        return tb
    end

    local function mkToggleKB(parent, txt, kbEntry, onToggle, onKB)
        local row = mkRow(parent, 30)
        mkLabel(row, txt)
        if kbEntry then
            local btn = Instance.new("TextButton", row)
            btn.Size = UDim2.new(0, 46, 0, 20)
            btn.Position = UDim2.new(1, -100, 0.5, -10)
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            btn.Text = kbEntry.kb and kbEntry.kb.Name or "None"
            btn.TextColor3 = COLORS.TEXT
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        end
        local pill, dot = mkPill(row, kbEntry and 108 or 44)
        local on = false
        local function sv(s)
            on = s
            animPill(pill, dot, s)
            if onToggle then onToggle(s) end
        end
        local clk = Instance.new("TextButton", pill)
        clk.Size = UDim2.new(1, 0, 1, 0)
        clk.BackgroundTransparency = 1
        clk.Text = ""
        clk.ZIndex = 5
        clk.Activated:Connect(function()
            if _anyKeyListening then return end
            on = not on
            sv(on)
        end)
        return sv
    end

    local pbFrame = Instance.new("Frame", gui)
    pbFrame.Size = UDim2.new(0, 260, 0, 46)
    pbFrame.Position = UDim2.new(0.5, -130, 1, -60)
    pbFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    pbFrame.BorderSizePixel = 0
    Instance.new("UICorner", pbFrame).CornerRadius = UDim.new(0, 8)
    addAnimatedStroke(pbFrame, 1.5)

    progressPct = Instance.new("TextLabel", pbFrame)
    progressPct.Size = UDim2.new(0, 40, 0, 14)
    progressPct.Position = UDim2.new(0, 8, 0, 6)
    progressPct.BackgroundTransparency = 1
    progressPct.Text = "0%"
    progressPct.TextColor3 = COLORS.TEXT
    progressPct.Font = Enum.Font.Gotham
    progressPct.TextSize = 12

    progressRadLbl = Instance.new("TextLabel", pbFrame)
    progressRadLbl.Size = UDim2.new(0, 100, 0, 14)
    progressRadLbl.Position = UDim2.new(1, -108, 0, 6)
    progressRadLbl.BackgroundTransparency = 1
    progressRadLbl.Text = string.format("Radius: %.2g", Steal.StealRadius)
    progressRadLbl.TextColor3 = COLORS.TEXT
    progressRadLbl.Font = Enum.Font.Gotham
    progressRadLbl.TextSize = 12
    progressRadLbl.TextXAlignment = Enum.TextXAlignment.Right

    local pbg = Instance.new("Frame", pbFrame)
    pbg.Size = UDim2.new(1, -16, 0, 10)
    pbg.Position = UDim2.new(0, 8, 0, 28)
    pbg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Instance.new("UICorner", pbg).CornerRadius = UDim.new(1, 0)
    progressFill = Instance.new("Frame", pbg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = COLORS.ACCENT
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Normal Speed")
        normalBox = mkBox(row, NS, 44, 52, function(v) if v > 0 and v <= 500 then NS = v end end)
    end

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Carry Speed")
        carryBox = mkBox(row, CS, 44, 52, function(v) if v > 0 and v <= 500 then CS = v end end)
    end

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Lagger Normal")
        laggerBox = mkBox(row, LAGGER_SPEED, 44, 52, function(v) if v > 0 and v <= 500 then LAGGER_SPEED = v end end)
    end

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Lagger Carry")
        laggerCarryBox = mkBox(row, LAGGER_CARRY_SPEED, 44, 52, function(v) if v > 0 and v <= 500 then LAGGER_CARRY_SPEED = v end end)
    end

    do
        local sv = mkToggle(content, "Lagger Mode", function(on)
            if on then
                if speedMode then speedMode = false end
                laggerToggled = true
                laggerPhase = 1
            else
                laggerToggled = false
                laggerPhase = 0
            end
            refreshSpeedModeLabel()
        end)
        setLaggerModeVisual = sv
    end

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Mode")
        modeValLbl = Instance.new("TextLabel", row)
        modeValLbl.Size = UDim2.new(0, 100, 1, 0)
        modeValLbl.Position = UDim2.new(1, -110, 0, 0)
        modeValLbl.BackgroundTransparency = 1
        modeValLbl.Text = "Normal"
        modeValLbl.TextColor3 = COLORS.TEXT_DIM
        modeValLbl.Font = Enum.Font.Gotham
        modeValLbl.TextSize = 13
        modeValLbl.TextXAlignment = Enum.TextXAlignment.Right
        local clk = Instance.new("TextButton", row)
        clk.Size = UDim2.new(1, 0, 1, 0)
        clk.BackgroundTransparency = 1
        clk.Text = ""
        clk.Activated:Connect(toggleCarryMode)
    end

    setInfJumpVisual = mkToggle(content, "Infinite Jump", function(on) infJumpEnabled = on end)
    setUnwalkVisual = mkToggle(content, "Unwalk", function(on) unwalkEnabled = on; if on then startUnwalk() else stopUnwalk() end end)
    setAutoTPVisual = mkToggle(content, "Auto TP", function(on) autoTPEnabled = on; if on then startAutoTP() else stopAutoTP() end end)

    do
        local row = mkRow(content, 30)
        mkLabel(row, "TP Height")
        autoTPHeightBox = mkBox(row, autoTPHeight, 44, 52, function(v) if v >= 0 and v <= 500 then autoTPHeight = v end end)
    end

    do
        local row = mkRow(content, 30)
        mkLabel(row, "TP Down")
        local clk = Instance.new("TextButton", row)
        clk.Size = UDim2.new(0.5, 0, 1, 0)
        clk.BackgroundTransparency = 1
        clk.Text = "Click"
        clk.Activated:Connect(runTPFloor)
    end

    do
        local abRow = mkRow(content, 30)
        mkLabel(abRow, "Auto Bat")
        local abPill, abDot = mkPill(abRow, 108)
        local abOn = false
        local function svAutoBat(s)
            abOn = s
            animPill(abPill, abDot, s)
        end
        autoBatSetVisual = svAutoBat
        local abClk = Instance.new("TextButton", abPill)
        abClk.Size = UDim2.new(1, 0, 1, 0)
        abClk.BackgroundTransparency = 1
        abClk.Text = ""
        abClk.Activated:Connect(function()
            abOn = not abOn
            svAutoBat(abOn)
            if abOn then queueAutoBatStart() else disableAutoBat() end
        end)
    end

    do
        local ab2Row = mkRow(content, 30)
        mkLabel(ab2Row, "Aimbot 2")
        local ab2Pill, ab2Dot = mkPill(ab2Row, 108)
        local ab2On = false
        local function svAimbot2(s)
            ab2On = s
            animPill(ab2Pill, ab2Dot, s)
        end
        aimbot2SetVisual = svAimbot2
        local ab2Clk = Instance.new("TextButton", ab2Pill)
        ab2Clk.Size = UDim2.new(1, 0, 1, 0)
        ab2Clk.BackgroundTransparency = 1
        ab2Clk.Text = ""
        ab2Clk.Activated:Connect(function()
            ab2On = not ab2On
            svAimbot2(ab2On)
            if ab2On then queueAimbot2Start() else disableAimbot2() end
        end)
    end

    setAutoSwingVisual = mkToggle(content, "Auto Swing", function(on) autoSwingEnabled = on end)
    setBatCounterVisual = mkToggle(content, "Bat Counter", function(on) batCounterEnabled = on; if on then startBatCounter() else stopBatCounter() end end)

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Steal Radius")
        radInput = mkBox(row, Steal.StealRadius, 44, 56, function(v) if v >= 0.5 and v <= 300 then Steal.StealRadius = v end end)
    end

    do
        local stealRow = mkRow(content, 30)
        mkLabel(stealRow, "Auto Steal")
        local pill, dot = mkPill(stealRow, 44)
        local on = false
        local function sv(s)
            on = s
            animPill(pill, dot, s)
        end
        setInstaGrab = sv
        local clk = Instance.new("TextButton", pill)
        clk.Size = UDim2.new(1, 0, 1, 0)
        clk.BackgroundTransparency = 1
        clk.Text = ""
        clk.Activated:Connect(function()
            on = not on
            sv(on)
            Steal.AutoStealEnabled = on
            if on then startAutoSteal() else stopAutoSteal() end
        end)
    end

    do
        local row = mkRow(content, 30)
        mkLabel(row, "Drop Brainrot")
        local clk = Instance.new("TextButton", row)
        clk.Size = UDim2.new(0.5, 0, 1, 0)
        clk.BackgroundTransparency = 1
        clk.Text = "Click"
        clk.Activated:Connect(runDrop)
    end

    setAntiRagVisual = mkToggle(content, "Anti Ragdoll", function(on) antiRagdollEnabled = on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
    setMedusaVisual = mkToggle(content, "Medusa Counter", function(on) medusaCounterEnabled = on; if on then setupMedusa(LP.Character) else stopMedusaCounter() end end)
    setAntiLagVisual = mkToggle(content, "Anti Lag", function(on) if on then enableAntiLag() else disableAntiLag() end end)
    setStretchRezVisual = mkToggle(content, "Stretch Rez", function(on) if on then enableStretchRez() else disableStretchRez() end end)

    do
        local sv = mkToggleKB(content, "Auto Left", KB.AutoLeft, function(on) autoLeftEnabled = on; if on then queueAutoLeftStart() else stopAutoLeft() end end)
        autoLeftSetVisual = sv
    end

    do
        local sv = mkToggleKB(content, "Auto Right", KB.AutoRight, function(on) autoRightEnabled = on; if on then queueAutoRightStart() else stopAutoRight() end end)
        autoRightSetVisual = sv
    end

    setAutoMedResetVisual = mkToggle(content, "Auto Med Reset", function(on) autoMedResetEnabled = on; if on then startAutoMedReset() else stopAutoMedReset() end end)

    local bottomRow = mkRow(content, 45)
    bottomRow.BackgroundTransparency = 1

    local saveBtn = Instance.new("TextButton", bottomRow)
    saveBtn.Size = UDim2.new(0.48, 0, 1, 0)
    saveBtn.Position = UDim2.new(0, 0, 0, 0)
    saveBtn.BackgroundColor3 = COLORS.BUTTON_ACTIVE
    saveBtn.Text = "Save Settings"
    saveBtn.TextColor3 = Color3.new(1,1,1)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 14
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)
    addAnimatedStroke(saveBtn, 1.5)
    saveBtn.Activated:Connect(function()
        saveConfig()
    end)

    local resetBtn = Instance.new("TextButton", bottomRow)
    resetBtn.Size = UDim2.new(0.48, 0, 1, 0)
    resetBtn.Position = UDim2.new(0.52, 0, 0, 0)
    resetBtn.BackgroundColor3 = COLORS.BUTTON
    resetBtn.Text = "Reset Settings"
    resetBtn.TextColor3 = Color3.new(1,1,1)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 14
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)
    addAnimatedStroke(resetBtn, 1.5)
    resetBtn.Activated:Connect(function()
        guiScale = 0.75
        mbScale = 0.85
        if normalBox then normalBox.Text = "60" end
        if carryBox then carryBox.Text = "30" end
        if laggerBox then laggerBox.Text = "15" end
        if laggerCarryBox then laggerCarryBox.Text = "24.5" end
    end)

    bubble.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)
end

local function saveConfig()
    local cfg = {
        normalSpeed = NS, carrySpeed = CS,
        laggerSpeed = LAGGER_SPEED, laggerCarrySpeed = LAGGER_CARRY_SPEED,
        grabRadius = Steal.StealRadius,
        guiScale = guiScale, mbScale = mbScale,
        autoTPHeight = autoTPHeight,
        antiRagdoll = antiRagdollEnabled,
        infiniteJump = infJumpEnabled,
        medusaCounter = medusaCounterEnabled,
        batCounter = batCounterEnabled,
        carryMode = speedMode,
        laggerMode = laggerToggled,
        laggerCarryMode = laggerPhase == 2,
        autoBat = autoBatEnabled,
        autoSwing = autoSwingEnabled,
        aimbot2 = aimbot2Enabled,
        unwalkEnabled = unwalkEnabled,
        antiLag = antiLagEnabled,
        stretchRez = stretchRezEnabled,
        autoTPEnabled = autoTPEnabled,
        autoMedReset = autoMedResetEnabled,
        autoStealEnabled = Steal.AutoStealEnabled
    }
    if writefile then
        pcall(function()
            writefile("moonhubduel.json", HS:JSONEncode(cfg))
        end)
    end
end

local function loadConfig()
    if not isfile or not isfile("moonhubduel.json") then return end
    local ok, cfg = pcall(function()
        return HS:JSONDecode(readfile("moonhubduel.json"))
    end)
    if not ok or not cfg then return end
    if cfg.normalSpeed then NS = cfg.normalSpeed end
    if cfg.carrySpeed then CS = cfg.carrySpeed end
    if cfg.laggerSpeed then LAGGER_SPEED = cfg.laggerSpeed end
    if cfg.laggerCarrySpeed then LAGGER_CARRY_SPEED = cfg.laggerCarrySpeed end
    if cfg.grabRadius then Steal.StealRadius = cfg.grabRadius end
    if cfg.guiScale then guiScale = cfg.guiScale end
    if cfg.mbScale then mbScale = cfg.mbScale end
    if cfg.autoTPHeight then autoTPHeight = cfg.autoTPHeight end
    if cfg.antiRagdoll ~= nil then antiRagdollEnabled = cfg.antiRagdoll end
    if cfg.infiniteJump ~= nil then infJumpEnabled = cfg.infiniteJump end
    if cfg.medusaCounter ~= nil then medusaCounterEnabled = cfg.medusaCounter end
    if cfg.batCounter ~= nil then batCounterEnabled = cfg.batCounter end
    if cfg.carryMode ~= nil then speedMode = cfg.carryMode end
    if cfg.laggerMode ~= nil then laggerToggled = cfg.laggerMode end
    if cfg.laggerCarryMode ~= nil then laggerPhase = cfg.laggerCarryMode and 2 or 1 end
    if cfg.autoBat ~= nil then autoBatEnabled = cfg.autoBat end
    if cfg.autoSwing ~= nil then autoSwingEnabled = cfg.autoSwing end
    if cfg.aimbot2 ~= nil then aimbot2Enabled = cfg.aimbot2 end
    if cfg.unwalkEnabled ~= nil then unwalkEnabled = cfg.unwalkEnabled end
    if cfg.antiLag ~= nil then antiLagEnabled = cfg.antiLag end
    if cfg.stretchRez ~= nil then stretchRezEnabled = cfg.stretchRez end
    if cfg.autoTPEnabled ~= nil then autoTPEnabled = cfg.autoTPEnabled end
    if cfg.autoMedReset ~= nil then autoMedResetEnabled = cfg.autoMedReset end
    if cfg.autoStealEnabled ~= nil then Steal.AutoStealEnabled = cfg.autoStealEnabled end
end

task.spawn(function()
    task.wait(3)
    loadConfig()
    buildGui()
    print("Moon Hub Loaded - made by hz and reaper")
end)
