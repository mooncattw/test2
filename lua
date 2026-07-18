local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Config
local Config = {
    GrabRadius = 20,
    StretchFOV = 120,
    StretchAspect = 0.7,
}

-- Keybinds
local Keybinds = {
    AutoSteal = Enum.KeyCode.V,
}

-- State for features
local State = {
    infJumpEnabled = false,
    shinyGraphicsEnabled = false,
    stretchEnabled = false,
    autoResetMedusaEnabled = true, -- AUTO ENABLED
    speedCheckerEnabled = true, -- AUTO ENABLED
    espEnabled = false,
    showSpeed = true,
}

-- ============================================================
-- STRETCH REZ VARIABLES
-- ============================================================
local stretchConn = nil
local fovConn = nil
local isStretched = false
local originalFOV = 70

-- ============================================================
-- INFINITE JUMP VARIABLES
-- ============================================================
local InfJumpPlatform = nil

-- ============================================================
-- SHINY GRAPHICS VARIABLES
-- ============================================================
local originalSkybox = nil
local shinyGraphicsSky = nil
local shinyGraphicsConn = nil
local shinyPlanets = {}
local shinyBloom = nil
local shinyCC = nil

-- ============================================================
-- AUTO RESET MEDUSA VARIABLES
-- ============================================================
local autoResetOnMedusaEnabled = true
local autoResetMedusaDebounce = false
local autoResetMedusaConns = {}
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"

-- ============================================================
-- SPEED CHECKER VARIABLES
-- ============================================================
local speedBB = nil
local speedCheckerEnabled = true

-- ============================================================
-- ESP VARIABLES
-- ============================================================
local espEnabled = false
local espConns = {}
local espObjects = {}
local showSpeed = true
local TRACER_COLOR = Color3.fromRGB(0, 255, 0)
local TRACER_THICKNESS = 2
local TRACER_TRANSPARENCY = 0.5

-- ============================================================
-- SAVE/LOAD
-- ============================================================
local function saveConfig()
    local data = {
        Config = Config,
        Keybinds = {},
        Features = {}
    }
    for k, v in pairs(Keybinds) do
        if v then
            data.Keybinds[k] = v.Name
        end
    end
    pcall(function()
        data.Features.AutoSteal = AutoStealBtn and AutoStealBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.Unwalk = UnwalkBtn and UnwalkBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.BatCounter = BatCounterBtn and BatCounterBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.MedusaCounter = MedusaCounterBtn and MedusaCounterBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.StretchRez = StretchBtn and StretchBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.InfJump = InfJumpBtn and InfJumpBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.ShinyGraphics = ShinyBtn and ShinyBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) or false
        data.Features.AutoResetMedusa = autoResetOnMedusaEnabled
        data.Features.SpeedChecker = speedCheckerEnabled
        data.Features.ESP = espEnabled
    end)
    pcall(function()
        writefile("VexDuels_Config.json", HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    pcall(function()
        if isfile("VexDuels_Config.json") then
            local data = HttpService:JSONDecode(readfile("VexDuels_Config.json"))
            if data.Config then
                for k, v in pairs(data.Config) do
                    Config[k] = v
                end
            end
            if data.Keybinds then
                for k, v in pairs(data.Keybinds) do
                    Keybinds[k] = Enum.KeyCode[v]
                end
            end
            if data.Features then
                autoResetOnMedusaEnabled = data.Features.AutoResetMedusa ~= nil and data.Features.AutoResetMedusa or true
                speedCheckerEnabled = data.Features.SpeedChecker ~= nil and data.Features.SpeedChecker or true
                espEnabled = data.Features.ESP or false
            end
            return data.Features
        end
    end)
    return nil
end

local savedFeatures = loadConfig()

local autoStealGui = nil
local circleParts = {}
local CIRCLE_COLOR = Color3.fromRGB(255, 0, 0)

-- Auto Steal variables
local AUTO_STEAL_PROX_RADIUS = Config.GrabRadius
local allAnimalsCache = {}
local PromptMemoryCache = {}
local InternalStealCache = {}
local IsStealing = false
local StealProgress = 0
local PartsCount = 64

-- Unwalk Variables
local unwalkEnabled = false
local unwalkSavedAnimate = nil

-- Bat Counter Variables
local batCounterEnabled = false
local batCounterDebounce = false
local Conns = {batCounter = nil, anchor = {}}

-- Medusa Counter Variables
local medusaCounterEnabled = false
local medusaDebounce = false
local medusaLastUsed = 0
local MEDUSA_COOLDOWN = 25

-- Bat types that work with counter
local BAT_COUNTER_SLAP_LIST = {
    "Bat", "Slap", "Iron Slap", "Gold Slap", "Diamond Slap", 
    "Emerald Slap", "Ruby Slap", "Dark Matter Slap", "Flame Slap", 
    "Nuclear Slap", "Galaxy Slap", "Glitched Slap"
}

local function getHRP()
    local c = player.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso"))
end

-- ============================================================
-- UNWALK FUNCTIONS
-- ============================================================
local function startUnwalk()
    local c = player.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then 
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do 
            t:Stop() 
        end 
    end
    local anim = c:FindFirstChild("Animate")
    if anim then 
        unwalkSavedAnimate = anim:Clone() 
        anim:Destroy() 
    end
end

local function stopUnwalk()
    local c = player.Character
    if c and unwalkSavedAnimate then 
        unwalkSavedAnimate:Clone().Parent = c 
        unwalkSavedAnimate = nil 
    end
end

-- ============================================================
-- BAT COUNTER FUNCTIONS
-- ============================================================
local function findBatForCounter()
    local c = player.Character
    if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    
    for _, name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    
    for _, ch in ipairs(c:GetChildren()) do 
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then 
            return ch 
        end 
    end
    if bp then 
        for _, ch in ipairs(bp:GetChildren()) do 
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then 
                return ch 
            end 
        end 
    end
    return nil
end

local function swingBatForCounter(bat, char)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char then 
        if hum2 then pcall(function() hum2:EquipTool(bat) end) end
        task.wait(0.05) 
    end
    
    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
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

local function startBatCounter()
    if Conns.batCounter then return end
    Conns.batCounter = RunService.Heartbeat:Connect(function()
        if not batCounterEnabled then return end
        if batCounterDebounce then return end
        
        local char = player.Character
        if not char then return end
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        
        local st = hum2:GetState()
        if st == Enum.HumanoidStateType.Physics or 
           st == Enum.HumanoidStateType.Ragdoll or 
           st == Enum.HumanoidStateType.FallingDown then
            
            batCounterDebounce = true
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then swingBatForCounter(bat, char) end
                task.wait(0.5)
                batCounterDebounce = false
            end)
        end
    end)
end

local function stopBatCounter()
    if Conns.batCounter then 
        Conns.batCounter:Disconnect()
        Conns.batCounter = nil 
    end
    batCounterDebounce = false
end

-- ============================================================
-- MEDUSA COUNTER FUNCTIONS
-- ============================================================
local function findMedusa()
    local c = player.Character
    if not c then return nil end
    
    for _, t in ipairs(c:GetChildren()) do 
        if t:IsA("Tool") then 
            local n = t.Name:lower()
            if n:find("medusa") or n:find("head") or n:find("stone") then 
                return t 
            end 
        end 
    end
    
    local bp = player:FindFirstChild("Backpack")
    if bp then 
        for _, t in ipairs(bp:GetChildren()) do 
            if t:IsA("Tool") then 
                local n = t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then 
                    return t 
                end 
            end 
        end 
    end
    return nil
end

local function useMedusaCounter()
    if medusaDebounce then return end
    if tick() - medusaLastUsed < MEDUSA_COOLDOWN then return end
    
    local c = player.Character
    if not c then return end
    
    medusaDebounce = true
    local med = findMedusa()
    if not med then 
        medusaDebounce = false
        return 
    end
    
    if med.Parent ~= c then 
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:EquipTool(med) end 
    end
    
    pcall(function() med:Activate() end)
    medusaLastUsed = tick()
    medusaDebounce = false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 then 
            useMedusaCounter() 
        end
    end)
end

local function setupMedusa(char)
    for _, c in pairs(Conns.anchor) do 
        pcall(function() c:Disconnect() end) 
    end
    Conns.anchor = {}
    
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
-- STRETCH REZ FUNCTIONS
-- ============================================================
local function applyStretch(aspect, fov)
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    pcall(function()
        cam.FieldOfView = fov
        local matrix = CFrame.new(0, 0, 0, 
            1, 0, 0,
            0, aspect, 0,
            0, 0, 1
        )
        cam.CFrame = cam.CFrame * matrix
    end)
end

local function enableStretchRez()
    if isStretched then return end
    
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    isStretched = true
    originalFOV = cam.FieldOfView
    
    if stretchConn then 
        stretchConn:Disconnect() 
        stretchConn = nil 
    end
    if fovConn then 
        fovConn:Disconnect() 
        fovConn = nil 
    end
    
    local aspect = Config.StretchAspect
    
    stretchConn = RunService.RenderStepped:Connect(function()
        if not isStretched then
            if stretchConn then
                stretchConn:Disconnect()
                stretchConn = nil
            end
            return
        end
        applyStretch(aspect, Config.StretchFOV)
    end)
    
    fovConn = RunService.Heartbeat:Connect(function()
        if not isStretched then
            if fovConn then
                fovConn:Disconnect()
                fovConn = nil
            end
            return
        end
        
        local cam2 = Workspace.CurrentCamera
        if cam2 and cam2.FieldOfView ~= Config.StretchFOV then
            pcall(function()
                cam2.FieldOfView = Config.StretchFOV
            end)
        end
    end)
end

local function disableStretchRez()
    isStretched = false
    State.stretchEnabled = false
    
    if stretchConn then
        stretchConn:Disconnect()
        stretchConn = nil
    end
    
    if fovConn then
        fovConn:Disconnect()
        fovConn = nil
    end
    
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            cam.FieldOfView = 70
        end
    end)
end

-- ============================================================
-- INFINITE JUMP FUNCTIONS
-- ============================================================
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

local function enableInfJump()
    State.infJumpEnabled = true
    CreateIJP()
end

local function disableInfJump()
    State.infJumpEnabled = false
    if InfJumpPlatform then
        InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
    end
end

-- ============================================================
-- SHINY GRAPHICS FUNCTIONS
-- ============================================================
local function enableShinyGraphics()
    if shinyGraphicsSky then return end
    
    originalSkybox = Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent = nil end
    
    shinyGraphicsSky = Instance.new("Sky")
    for _, prop in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}) do
        shinyGraphicsSky[prop] = "rbxassetid://1534951537"
    end
    shinyGraphicsSky.StarCount = 10000
    shinyGraphicsSky.CelestialBodiesShown = false
    shinyGraphicsSky.Parent = Lighting
    
    shinyBloom = Instance.new("BloomEffect")
    shinyBloom.Intensity = 1.5
    shinyBloom.Size = 40
    shinyBloom.Threshold = 0.8
    shinyBloom.Parent = Lighting
    
    shinyCC = Instance.new("ColorCorrectionEffect")
    shinyCC.Saturation = 0.8
    shinyCC.Contrast = 0.3
    shinyCC.TintColor = Color3.fromRGB(200, 200, 200)
    shinyCC.Parent = Lighting
    
    Lighting.Ambient = Color3.fromRGB(100, 100, 110)
    Lighting.Brightness = 3
    Lighting.ClockTime = 0
    
    for i = 1, 2 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800 + i * 200, 800 + i * 200, 800 + i * 200)
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(160 + i * 15, 160 + i * 15, 165 + i * 15)
        p.Transparency = 0.3
        p.Position = Vector3.new(math.cos(i * 2) * (3000 + i * 500), 1500 + i * 300, math.sin(i * 2) * (3000 + i * 500))
        p.Parent = workspace
        table.insert(shinyPlanets, p)
    end
    
    shinyGraphicsConn = RunService.Heartbeat:Connect(function()
        if not State.shinyGraphicsEnabled then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(100 + math.sin(t) * 30, 100 + math.sin(t * 0.8) * 30, 110 + math.sin(t * 1.2) * 30)
        if shinyBloom then shinyBloom.Intensity = 1.2 + math.sin(t * 2) * 0.4 end
    end)
    
    State.shinyGraphicsEnabled = true
end

local function disableShinyGraphics()
    State.shinyGraphicsEnabled = false
    
    if shinyGraphicsConn then
        shinyGraphicsConn:Disconnect()
        shinyGraphicsConn = nil
    end
    if shinyGraphicsSky then
        shinyGraphicsSky:Destroy()
        shinyGraphicsSky = nil
    end
    if originalSkybox then originalSkybox.Parent = Lighting end
    if shinyBloom then
        shinyBloom:Destroy()
        shinyBloom = nil
    end
    if shinyCC then
        shinyCC:Destroy()
        shinyCC = nil
    end
    for _, obj in ipairs(shinyPlanets) do
        if obj then obj:Destroy() end
    end
    shinyPlanets = {}
    
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
end

-- ============================================================
-- AUTO RESET MEDUSA FUNCTIONS
-- ============================================================
pcall(function()
    if hookfunction and newcclosure then
        local oldFire
        oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not cursedResetRemote and typeof(self) == "Instance" and self:IsA("RemoteEvent") and self.Name:sub(1, 3) == "RE/" then
                cursedResetRemote = self
            end
            return oldFire(self, ...)
        end))
    end
end)

task.spawn(function()
    task.wait(2)
    if cursedResetRemote then return end
    for _, desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1, 3) == "RE/" then cursedResetRemote = desc; break end
    end
end)

local function cursedInstaReset()
    if not cursedResetRemote then
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("RemoteEvent") and desc.Name:sub(1, 3) == "RE/" then cursedResetRemote = desc; break end
        end
    end
    if not cursedResetRemote then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, player, "balloon") end)
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
            pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, player, "balloon") end)
            task.wait()
        end
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
    end)
end

local function onMedusaPlatformStandChanged()
    if not autoResetOnMedusaEnabled then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.PlatformStand then
        if autoResetMedusaDebounce then return end
        autoResetMedusaDebounce = true
        task.spawn(function()
            cursedInstaReset()
            task.wait(3)
            autoResetMedusaDebounce = false
        end)
    end
end

local function onAnchorChangedAutoReset(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if not autoResetOnMedusaEnabled then return end
        if part.Anchored and part.Transparency == 1 then
            if autoResetMedusaDebounce then return end
            autoResetMedusaDebounce = true
            task.spawn(function()
                cursedInstaReset()
                task.wait(3)
                autoResetMedusaDebounce = false
            end)
        end
    end)
end

local function setupAutoResetOnMedusa(char)
    for _, c in pairs(autoResetMedusaConns) do
        pcall(function() c:Disconnect() end)
    end
    autoResetMedusaConns = {}

    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        table.insert(autoResetMedusaConns, hum:GetPropertyChangedSignal("PlatformStand"):Connect(onMedusaPlatformStandChanged))
        if hum.PlatformStand then
            onMedusaPlatformStandChanged()
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(autoResetMedusaConns, onAnchorChangedAutoReset(part))
        end
    end

    table.insert(autoResetMedusaConns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(autoResetMedusaConns, onAnchorChangedAutoReset(part))
        end
    end))
end

local function stopAutoResetOnMedusa()
    for _, c in pairs(autoResetMedusaConns) do
        pcall(function() c:Disconnect() end)
    end
    autoResetMedusaConns = {}
end

-- ============================================================
-- SPEED CHECKER FUNCTIONS
-- ============================================================
local function createSpeedDisplay()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    if speedBB then speedBB:Destroy() end
    
    speedBB = Instance.new("BillboardGui")
    speedBB.Adornee = hrp
    speedBB.Size = UDim2.new(0, 120, 0, 36)
    speedBB.StudsOffset = Vector3.new(0, 4.5, 0)
    speedBB.AlwaysOnTop = true
    speedBB.Parent = hrp
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Text = "Speed: 0"
    lbl.Parent = speedBB
    
    return lbl
end

local function enableSpeedChecker()
    if speedCheckerEnabled then return end
    speedCheckerEnabled = true
    createSpeedDisplay()
    print("[Speed Checker] Enabled")
end

local function disableSpeedChecker()
    speedCheckerEnabled = false
    if speedBB then speedBB:Destroy() end
    print("[Speed Checker] Disabled")
end

-- ============================================================
-- INFINITE JUMP LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not State.infJumpEnabled then 
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
        return 
    end
    
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if not (char and root and hum) then 
        if InfJumpPlatform then
            InfJumpPlatform.Position = Vector3.new(0, -1000, 0)
        end
        return 
    end

    local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space)
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
-- SPEED CHECKER LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not speedCheckerEnabled then 
        if speedBB then speedBB:Destroy() end
        return 
    end
    
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not speedBB or not speedBB.Parent then
        createSpeedDisplay()
    end
    
    local lbl = speedBB and speedBB:FindFirstChildOfClass("TextLabel")
    if lbl then
        local v = hrp.AssemblyLinearVelocity
        local speed = math.floor(Vector3.new(v.X, 0, v.Z).Magnitude)
        lbl.Text = "Speed: " .. speed
    end
end)

-- ============================================================
-- ESP FUNCTIONS
-- ============================================================
local function getHRPESP(plr)
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumESP(plr)
    local char = plr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isTargetValid(plr)
    if plr == player then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    return true
end

local function createSpeedDisplayESP(plr, data)
    if not showSpeed or not espEnabled then return end
    if data.SpeedBB then return end
    
    local head = data.Head
    if not head then return end
    
    local speedBB = Instance.new("BillboardGui")
    speedBB.Name = "SpeedDisplay"
    speedBB.Adornee = head
    speedBB.Size = UDim2.new(0, 100, 0, 28)
    speedBB.StudsOffset = Vector3.new(0, 4.8, 0)
    speedBB.AlwaysOnTop = true
    speedBB.Parent = data.Group
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextScaled = true
    lbl.Text = "0.0"
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = speedBB
    
    data.SpeedBB = speedBB
    data.SpeedLbl = lbl
end

local function createESP(plr)
    if not isTargetValid(plr) then return end
    if espObjects[plr] then return end
    
    local char = plr.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not root or not head then return end
    
    local group = Instance.new("Folder")
    group.Name = "VexESP"
    group.Parent = char
    
    -- Square box (outline only)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "Box"
    box.Adornee = root
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = Color3.fromRGB(0, 255, 0)
    box.Transparency = 0.7
    box.ZIndex = 10
    box.AlwaysOnTop = true
    box.Parent = group
    
    -- Outer box for glow effect
    local boxGlow = Instance.new("BoxHandleAdornment")
    boxGlow.Name = "BoxGlow"
    boxGlow.Adornee = root
    boxGlow.Size = Vector3.new(4.4, 6.4, 2.4)
    boxGlow.Color3 = Color3.fromRGB(0, 255, 0)
    boxGlow.Transparency = 0.3
    boxGlow.ZIndex = 9
    boxGlow.AlwaysOnTop = true
    boxGlow.Parent = group
    
    -- Name tag
    local bb = Instance.new("BillboardGui")
    bb.Name = "NameTag"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 45)
    bb.StudsOffset = Vector3.new(0, 4.2, 0)
    bb.AlwaysOnTop = true
    bb.Parent = group
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = plr.DisplayName
    lbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Parent = bb
    
    -- Health bar
    local healthBB = Instance.new("BillboardGui")
    healthBB.Name = "HealthBar"
    healthBB.Adornee = head
    healthBB.Size = UDim2.new(0, 50, 0, 6)
    healthBB.StudsOffset = Vector3.new(0, 2.2, 0)
    healthBB.AlwaysOnTop = true
    healthBB.Parent = group
    
    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(1, 0, 1, 0)
    healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = healthBB
    
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    
    -- Tracer
    local tracer = Drawing.new("Line")
    tracer.Visible = true
    tracer.Color = Color3.new(0, 1, 0)
    tracer.Thickness = TRACER_THICKNESS
    tracer.Transparency = TRACER_TRANSPARENCY
    tracer.ZIndex = 5
    
    -- Store all objects
    local data = {
        Group = group,
        Box = box,
        BoxGlow = boxGlow,
        NameTag = bb,
        HealthBar = healthBB,
        HealthFill = healthFill,
        Tracer = tracer,
        Root = root,
        Head = head,
        Player = plr,
        SpeedBB = nil,
        SpeedLbl = nil
    }
    
    espObjects[plr] = data
    
    if showSpeed then
        createSpeedDisplayESP(plr, data)
    end
end

local function updateESP()
    if not espEnabled then return end
    
    local localChar = player.Character
    if not localChar then return end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    local localPos, localVisible = camera:WorldToViewportPoint(localRoot.Position)
    if not localVisible then return end
    
    for plr, data in pairs(espObjects) do
        if not isTargetValid(plr) then
            removeESP(plr)
        else
            -- Update health
            local hum = getHumESP(plr)
            if hum and data.HealthFill then
                local health = hum.Health / hum.MaxHealth
                data.HealthFill.Size = UDim2.new(health, 0, 1, 0)
                data.HealthFill.BackgroundColor3 = Color3.fromHSV(health * 0.3, 1, 0.6)
            end
            
            -- Update speed
            if showSpeed and data.SpeedLbl and data.Root then
                local v = data.Root.AssemblyLinearVelocity
                local horizontalSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
                data.SpeedLbl.Text = string.format("%.1f", horizontalSpeed)
                data.SpeedLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
            
            -- Update tracer
            local root = data.Root
            if root and data.Tracer then
                local enemyPos, enemyVisible = camera:WorldToViewportPoint(root.Position)
                if enemyVisible and localVisible then
                    data.Tracer.From = Vector2.new(localPos.X, localPos.Y)
                    data.Tracer.To = Vector2.new(enemyPos.X, enemyPos.Y)
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end
            end
        end
    end
end

local function removeESP(plr)
    local data = espObjects[plr]
    if data then
        if data.Group then
            data.Group:Destroy()
        end
        if data.Tracer then
            data.Tracer:Remove()
        end
        data.SpeedBB = nil
        data.SpeedLbl = nil
    end
    espObjects[plr] = nil
end

local function enableESP()
    espEnabled = true
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            pcall(function() createESP(plr) end)
        end
    end
    
    for _, conn in ipairs(espConns) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    espConns = {}
    
    local conn1 = Players.PlayerAdded:Connect(function(plr)
        if plr == player then return end
        plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            if espEnabled then pcall(function() createESP(plr) end) end
        end)
    end)
    table.insert(espConns, conn1)
    
    local conn2 = Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
    end)
    table.insert(espConns, conn2)
    
    local conn3 = RunService.RenderStepped:Connect(function()
        if espEnabled then
            updateESP()
        end
    end)
    table.insert(espConns, conn3)
end

local function disableESP()
    espEnabled = false
    for plr in pairs(espObjects) do
        removeESP(plr)
    end
    espObjects = {}
    for _, conn in ipairs(espConns) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    espConns = {}
end

-- ============================================================
-- GUI CREATION
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VexDuelsGUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 500)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2.5
MainStroke.Color = Color3.fromRGB(255, 0, 0)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- Animated Glow
task.spawn(function()
    while MainStroke and MainStroke.Parent do
        for i = 0, 30 do
            MainStroke.Thickness = 2.5 + (i * 0.04)
            task.wait(0.03)
        end
        for i = 0, 30 do
            MainStroke.Thickness = 3.7 - (i * 0.04)
            task.wait(0.03)
        end
    end
end)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "VEX DUELS"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Parent = TitleBar

-- FPS Counter
local FPSLbl = Instance.new("TextLabel", TitleBar)
FPSLbl.Size = UDim2.new(0, 70, 0, 16)
FPSLbl.Position = UDim2.new(0, 10, 0, 5)
FPSLbl.BackgroundTransparency = 1
FPSLbl.Text = "0 FPS"
FPSLbl.Font = Enum.Font.GothamBold
FPSLbl.TextSize = 11
FPSLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
FPSLbl.TextXAlignment = Enum.TextXAlignment.Left

local fc, lft = 0, tick()
RunService.RenderStepped:Connect(function()
    fc = fc + 1
    local ct = tick()
    if ct - lft >= 1 then
        FPSLbl.Text = fc .. " FPS"
        fc = 0
        lft = ct
    end
end)

-- Tab System
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -20, 0, 35)
TabContainer.Position = UDim2.new(0, 10, 0, 60)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local FeaturesTab = Instance.new("TextButton")
FeaturesTab.Name = "FeaturesTab"
FeaturesTab.Size = UDim2.new(0.47, 0, 1, 0)
FeaturesTab.Position = UDim2.new(0, 0, 0, 0)
FeaturesTab.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
FeaturesTab.Text = "FEATURES"
FeaturesTab.Font = Enum.Font.GothamBold
FeaturesTab.TextSize = 13
FeaturesTab.TextColor3 = Color3.fromRGB(255, 255, 255)
FeaturesTab.BorderSizePixel = 0
FeaturesTab.Parent = TabContainer

local FeaturesCorner = Instance.new("UICorner")
FeaturesCorner.CornerRadius = UDim.new(0, 8)
FeaturesCorner.Parent = FeaturesTab

local SettingsTab = Instance.new("TextButton")
SettingsTab.Name = "SettingsTab"
SettingsTab.Size = UDim2.new(0.47, 0, 1, 0)
SettingsTab.Position = UDim2.new(0.53, 0, 0, 0)
SettingsTab.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsTab.Text = "SETTINGS"
SettingsTab.Font = Enum.Font.GothamBold
SettingsTab.TextSize = 13
SettingsTab.TextColor3 = Color3.fromRGB(150, 150, 150)
SettingsTab.BorderSizePixel = 0
SettingsTab.Parent = TabContainer

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 8)
SettingsCorner.Parent = SettingsTab

-- Content Frames (SCROLLABLE)
local FeaturesFrame = Instance.new("ScrollingFrame")
FeaturesFrame.Name = "FeaturesFrame"
FeaturesFrame.Size = UDim2.new(1, -20, 1, -110)
FeaturesFrame.Position = UDim2.new(0, 10, 0, 105)
FeaturesFrame.BackgroundTransparency = 1
FeaturesFrame.ScrollBarThickness = 6
FeaturesFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
FeaturesFrame.CanvasSize = UDim2.new(0, 0, 0, 520)
FeaturesFrame.Parent = MainFrame

local SettingsFrame = Instance.new("ScrollingFrame")
SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Size = UDim2.new(1, -20, 1, -110)
SettingsFrame.Position = UDim2.new(0, 10, 0, 105)
SettingsFrame.BackgroundTransparency = 1
SettingsFrame.ScrollBarThickness = 6
SettingsFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
SettingsFrame.CanvasSize = UDim2.new(0, 0, 0, 250)
SettingsFrame.Visible = false
SettingsFrame.Parent = MainFrame

-- Toggle
local function createLaggerToggle(parent, name, text, yPos)
    local button = Instance.new("TextButton")
    button.Name = name.."Toggle"
    button.Size = UDim2.new(1, -10, 0, 40)
    button.Position = UDim2.new(0, 5, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    return button
end

-- Number Input
local function createNumberInput(parent, name, text, currentValue, min, max, yPos)
    local container = Instance.new("Frame")
    container.Name = name.."Container"
    container.Size = UDim2.new(1, -10, 0, 45)
    container.Position = UDim2.new(0, 5, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local numButton = Instance.new("TextButton")
    numButton.Name = name.."Button"
    numButton.Size = UDim2.new(0, 80, 0, 30)
    numButton.Position = UDim2.new(1, -85, 0.5, -15)
    numButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    numButton.Text = tostring(currentValue)
    numButton.Font = Enum.Font.GothamBold
    numButton.TextSize = 12
    numButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    numButton.BorderSizePixel = 0
    numButton.Parent = container
    
    local numCorner = Instance.new("UICorner")
    numCorner.CornerRadius = UDim.new(0, 8)
    numCorner.Parent = numButton
    
    return numButton
end

-- Features
local AutoStealBtn = createLaggerToggle(FeaturesFrame, "AutoSteal", "Auto Steal", 0)
local UnwalkBtn = createLaggerToggle(FeaturesFrame, "Unwalk", "No Walking Anim", 45)
local BatCounterBtn = createLaggerToggle(FeaturesFrame, "BatCounter", "Bat Counter", 90)
local MedusaCounterBtn = createLaggerToggle(FeaturesFrame, "MedusaCounter", "Medusa Counter", 135)
local StretchBtn = createLaggerToggle(FeaturesFrame, "Stretch", "Stretch Rez", 180)
local InfJumpBtn = createLaggerToggle(FeaturesFrame, "InfJump", "Infinite Jump", 225)
local ShinyBtn = createLaggerToggle(FeaturesFrame, "Shiny", "Shiny Graphics", 270)
local AutoResetBtn = createLaggerToggle(FeaturesFrame, "AutoReset", "Auto Reset Medusa", 315)
local ESPBtn = createLaggerToggle(FeaturesFrame, "ESP", "Player ESP", 360)

-- Restore saved feature states
task.delay(0.5, function()
    if savedFeatures then
        if savedFeatures.AutoSteal then
            updateLaggerToggle(AutoStealBtn, true)
            task.spawn(function()
                initAutoStealGUI()
                createCircle()
            end)
        end
        if savedFeatures.Unwalk then
            updateLaggerToggle(UnwalkBtn, true)
            unwalkEnabled = true
            task.spawn(function()
                task.wait(0.5)
                startUnwalk()
            end)
        end
        if savedFeatures.BatCounter then
            updateLaggerToggle(BatCounterBtn, true)
            batCounterEnabled = true
            startBatCounter()
        end
        if savedFeatures.MedusaCounter then
            updateLaggerToggle(MedusaCounterBtn, true)
            medusaCounterEnabled = true
            setupMedusa(player.Character)
        end
        if savedFeatures.StretchRez then
            updateLaggerToggle(StretchBtn, true)
            State.stretchEnabled = true
            enableStretchRez()
        end
        if savedFeatures.InfJump then
            updateLaggerToggle(InfJumpBtn, true)
            enableInfJump()
        end
        if savedFeatures.ShinyGraphics then
            updateLaggerToggle(ShinyBtn, true)
            enableShinyGraphics()
        end
        if savedFeatures.AutoResetMedusa or savedFeatures.AutoResetMedusa == nil then
            updateLaggerToggle(AutoResetBtn, true)
            autoResetOnMedusaEnabled = true
            setupAutoResetOnMedusa(player.Character)
        end
        if savedFeatures.ESP then
            updateLaggerToggle(ESPBtn, true)
            enableESP()
        end
    else
        -- Default: Auto Steal ON, Auto Reset Medusa ON, Speed Checker ON
        updateLaggerToggle(AutoStealBtn, true)
        updateLaggerToggle(AutoResetBtn, true)
        task.spawn(function()
            initAutoStealGUI()
            createCircle()
        end)
        autoResetOnMedusaEnabled = true
        setupAutoResetOnMedusa(player.Character)
        speedCheckerEnabled = true
        createSpeedDisplay()
    end
end)

-- Settings Tab
local GrabRadiusInput = createNumberInput(SettingsFrame, "GrabRadius", "Grab Radius", Config.GrabRadius, 1, 999999, 0)
local StretchFOVInput = createNumberInput(SettingsFrame, "StretchFOV", "Stretch FOV", Config.StretchFOV, 90, 120, 50)
local StretchAspectInput = createNumberInput(SettingsFrame, "StretchAspect", "Stretch Aspect", Config.StretchAspect * 100, 50, 100, 100)

-- Save Button
local SaveButton = Instance.new("TextButton")
SaveButton.Name = "SaveButton"
SaveButton.Size = UDim2.new(1, -10, 0, 40)
SaveButton.Position = UDim2.new(0, 5, 0, 200)
SaveButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SaveButton.Text = "SAVE CONFIG"
SaveButton.Font = Enum.Font.GothamBlack
SaveButton.TextSize = 14
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.BorderSizePixel = 0
SaveButton.Parent = SettingsFrame

local SaveCorner = Instance.new("UICorner")
SaveCorner.CornerRadius = UDim.new(0, 10)
SaveCorner.Parent = SaveButton

SaveButton.MouseButton1Click:Connect(function()
    saveConfig()
    SaveButton.Text = "✅ SAVED!"
    task.wait(1)
    SaveButton.Text = "SAVE CONFIG"
end)

-- Number Inputs
local numberInputs = {
    {button = GrabRadiusInput, name = "GrabRadius", min = 1, max = 999999},
    {button = StretchFOVInput, name = "StretchFOV", min = 90, max = 120},
    {button = StretchAspectInput, name = "StretchAspect", min = 50, max = 100},
}

for _, data in ipairs(numberInputs) do
    data.button.MouseButton1Click:Connect(function()
        local typing = false
        if typing then return end
        typing = true
        
        local textBox = Instance.new("TextBox")
        textBox.Size = data.button.Size
        textBox.Position = data.button.Position
        textBox.BackgroundColor3 = data.button.BackgroundColor3
        textBox.Text = tostring(Config[data.name])
        textBox.Font = data.button.Font
        textBox.TextSize = data.button.TextSize
        textBox.TextColor3 = data.button.TextColor3
        textBox.ClearTextOnFocus = false
        textBox.BorderSizePixel = 0
        textBox.Parent = data.button.Parent
        
        local textCorner = Instance.new("UICorner")
        textCorner.CornerRadius = UDim.new(0, 8)
        textCorner.Parent = textBox
        
        textBox:CaptureFocus()
        
        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local num = tonumber(textBox.Text)
                if data.name == "StretchAspect" then
                    num = num / 100
                end
                if num and num >= data.min and num <= data.max then
                    Config[data.name] = num
                    data.button.Text = tostring(Config[data.name])
                    if data.name == "StretchFOV" or data.name == "StretchAspect" then
                        if State.stretchEnabled then
                            disableStretchRez()
                            enableStretchRez()
                        end
                    end
                end
            end
            
            textBox:Destroy()
            typing = false
        end)
    end)
end

-- ============================================================
-- AUTO STEAL FUNCTIONS
-- ============================================================
local function findPrompt(a)
    local c = PromptMemoryCache[a.uid]
    if c and c.Parent then return c end
    local plot = workspace.Plots:FindFirstChild(a.plot)
    local podium = plot and plot.AnimalPodiums:FindFirstChild(a.slot)
    if not podium then return end
    local base = podium:FindFirstChild("Base")
    if not base then return end
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return end
    local attach = spawn:FindFirstChild("PromptAttachment")
    if not attach then return end
    for _,p in ipairs(attach:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            PromptMemoryCache[a.uid] = p
            return p
        end
    end
end

local function build(prompt)
    if InternalStealCache[prompt] then return end
    local d = {h = {}, t = {}, r = true}
    local success1, c1 = pcall(function() return getconnections(prompt.PromptButtonHoldBegan) end)
    if success1 and c1 then
        for _,c in ipairs(c1) do 
            if c and type(c.Function) == "function" then 
                table.insert(d.h, c.Function) 
            end 
        end
    end
    local success2, c2 = pcall(function() return getconnections(prompt.Triggered) end)
    if success2 and c2 then
        for _,c in ipairs(c2) do 
            if c and type(c.Function) == "function" then 
                table.insert(d.t, c.Function) 
            end 
        end
    end
    InternalStealCache[prompt] = d
end

local function steal(prompt)
    local d = InternalStealCache[prompt]
    if not d or not d.r then return end
    d.r = false
    IsStealing = true
    StealProgress = 0
    
    task.spawn(function()
        if #d.h > 0 or #d.t > 0 then
            for _,f in ipairs(d.h) do 
                task.spawn(function() pcall(f) end) 
            end
            local s = tick()
            while tick() - s < 1.3 do
                StealProgress = (tick() - s) / 1.3
                task.wait()
            end
            StealProgress = 1
            for _,f in ipairs(d.t) do 
                task.spawn(function() pcall(f) end) 
            end
        else
            local s = tick()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            elseif prompt then
                pcall(function()
                    prompt:InputHoldBegan()
                end)
            end
            
            while tick() - s < 1.3 do
                StealProgress = (tick() - s) / 1.3
                task.wait()
            end
            StealProgress = 1
            
            if prompt then
                pcall(function()
                    prompt:InputHoldEnded()
                end)
            end
        end
        
        task.wait(0.2)
        IsStealing = false
        StealProgress = 0
        d.r = true
    end)
end

local function createCircle()
    for _,p in ipairs(circleParts) do 
        if p then pcall(function() p:Destroy() end) end
    end
    table.clear(circleParts)
    for i = 1, PartsCount do
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = CIRCLE_COLOR
        part.Transparency = 0.35
        part.Size = Vector3.new(1, 0.2, 0.3)
        part.Parent = workspace
        table.insert(circleParts, part)
    end
end

local function initAutoStealGUI()
    if autoStealGui then 
        pcall(function() autoStealGui:Destroy() end) 
        autoStealGui = nil
    end
    
    autoStealGui = Instance.new("ScreenGui")
    autoStealGui.Name = "VexAutoSteal"
    autoStealGui.ResetOnSpawn = false
    autoStealGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    autoStealGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Name = "AutoStealFrame"
    frame.Size = UDim2.new(0, 260, 0, 26)
    frame.Position = UDim2.new(0.5, -130, 1, -120)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = autoStealGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.2
    stroke.Color = CIRCLE_COLOR
    stroke.Parent = frame
    
    local bg = Instance.new("Frame")
    bg.Name = "ProgressBarBG"
    bg.Size = UDim2.new(0.9, 0, 0, 8)
    bg.Position = UDim2.new(0.05, 0, 0.5, -4)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BorderSizePixel = 0
    bg.Parent = frame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = bg
    
    local fill = Instance.new("Frame")
    fill.Name = "ProgressBarFill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = CIRCLE_COLOR
    fill.BorderSizePixel = 0
    fill.Parent = bg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    task.spawn(function()
        while autoStealGui and autoStealGui.Parent do
            task.wait(0.03)
            
            if fill and fill.Parent then
                if IsStealing then
                    fill.Size = UDim2.new(StealProgress, 0, 1, 0)
                else
                    fill.Size = UDim2.new(math.max(0, fill.Size.X.Scale - 0.05), 0, 1, 0)
                end
            end
        end
    end)
end

-- ============================================================
-- TOGGLE LOGIC
-- ============================================================
local function updateLaggerToggle(button, active)
    local targetColor = active and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(20, 20, 20)
    TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
end

-- Auto Steal Toggle
AutoStealBtn.MouseButton1Click:Connect(function()
    local newState = AutoStealBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(AutoStealBtn, newState)
    if newState then
        task.spawn(function()
            initAutoStealGUI()
            createCircle()
        end)
    else
        if autoStealGui then
            pcall(function() autoStealGui:Destroy() end)
            autoStealGui = nil
        end
        for _,p in ipairs(circleParts) do
            if p then pcall(function() p:Destroy() end) end
        end
        table.clear(circleParts)
    end
end)

-- Unwalk Toggle
UnwalkBtn.MouseButton1Click:Connect(function()
    local newState = UnwalkBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(UnwalkBtn, newState)
    unwalkEnabled = newState
    if newState then
        startUnwalk()
    else
        stopUnwalk()
    end
end)

-- Bat Counter Toggle
BatCounterBtn.MouseButton1Click:Connect(function()
    local newState = BatCounterBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(BatCounterBtn, newState)
    batCounterEnabled = newState
    if newState then
        startBatCounter()
    else
        stopBatCounter()
    end
end)

-- Medusa Counter Toggle
MedusaCounterBtn.MouseButton1Click:Connect(function()
    local newState = MedusaCounterBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(MedusaCounterBtn, newState)
    medusaCounterEnabled = newState
    if newState then
        setupMedusa(player.Character)
    else
        stopMedusaCounter()
    end
end)

-- Stretch Rez Toggle
StretchBtn.MouseButton1Click:Connect(function()
    local newState = StretchBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(StretchBtn, newState)
    State.stretchEnabled = newState
    if newState then
        enableStretchRez()
    else
        disableStretchRez()
    end
end)

-- Infinite Jump Toggle
InfJumpBtn.MouseButton1Click:Connect(function()
    local newState = InfJumpBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(InfJumpBtn, newState)
    if newState then
        enableInfJump()
    else
        disableInfJump()
    end
end)

-- Shiny Graphics Toggle
ShinyBtn.MouseButton1Click:Connect(function()
    local newState = ShinyBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(ShinyBtn, newState)
    if newState then
        enableShinyGraphics()
    else
        disableShinyGraphics()
    end
end)

-- Auto Reset Medusa Toggle
AutoResetBtn.MouseButton1Click:Connect(function()
    local newState = AutoResetBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(AutoResetBtn, newState)
    autoResetOnMedusaEnabled = newState
    if newState then
        setupAutoResetOnMedusa(player.Character)
    else
        stopAutoResetOnMedusa()
    end
end)

-- ESP Toggle
ESPBtn.MouseButton1Click:Connect(function()
    local newState = ESPBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
    updateLaggerToggle(ESPBtn, newState)
    if newState then
        enableESP()
    else
        disableESP()
    end
end)

-- ============================================================
-- KEYBIND HANDLER
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    
    if Keybinds.AutoSteal and input.KeyCode == Keybinds.AutoSteal then
        local newState = AutoStealBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
        updateLaggerToggle(AutoStealBtn, newState)
        if newState then
            task.spawn(function()
                initAutoStealGUI()
                createCircle()
            end)
        else
            if autoStealGui then
                pcall(function() autoStealGui:Destroy() end)
                autoStealGui = nil
            end
            for _,p in ipairs(circleParts) do
                if p then pcall(function() p:Destroy() end) end
            end
            table.clear(circleParts)
        end
    end
    
    -- M key for Auto Reset Medusa toggle
    if input.KeyCode == Enum.KeyCode.M then
        local newState = AutoResetBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
        updateLaggerToggle(AutoResetBtn, newState)
        autoResetOnMedusaEnabled = newState
        if newState then
            setupAutoResetOnMedusa(player.Character)
        else
            stopAutoResetOnMedusa()
        end
        print("Auto Reset Medusa:", autoResetOnMedusaEnabled and "ON" or "OFF")
    end
    
    -- F8 key for Speed Checker toggle
    if input.KeyCode == Enum.KeyCode.F8 then
        speedCheckerEnabled = not speedCheckerEnabled
        if speedCheckerEnabled then
            createSpeedDisplay()
            print("Speed display ON")
        else
            if speedBB then speedBB:Destroy() end
            print("Speed display OFF")
        end
    end
    
    -- Stretch Rez keybinds
    if input.KeyCode == Enum.KeyCode.F1 then
        local newState = StretchBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0)
        updateLaggerToggle(StretchBtn, newState)
        State.stretchEnabled = newState
        if newState then
            enableStretchRez()
        else
            disableStretchRez()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        Config.StretchFOV = 90
        Config.StretchAspect = 0.6
        StretchFOVInput.Text = "90"
        StretchAspectInput.Text = "60"
        if State.stretchEnabled then
            disableStretchRez()
            enableStretchRez()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.F3 then
        Config.StretchFOV = 100
        Config.StretchAspect = 0.65
        StretchFOVInput.Text = "100"
        StretchAspectInput.Text = "65"
        if State.stretchEnabled then
            disableStretchRez()
            enableStretchRez()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.F4 then
        Config.StretchFOV = 120
        Config.StretchAspect = 0.7
        StretchFOVInput.Text = "120"
        StretchAspectInput.Text = "70"
        if State.stretchEnabled then
            disableStretchRez()
            enableStretchRez()
        end
    end
end)

-- ============================================================
-- MAIN LOOPS
-- ============================================================
task.spawn(function()
    task.wait(2)
    while task.wait(5) do
        if AutoStealBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) then
            table.clear(allAnimalsCache)
            for _,plot in ipairs(workspace.Plots:GetChildren()) do
                if plot:IsA("Model") then
                    local sign = plot:FindFirstChild("PlotSign")
                    local yourBase = sign and sign:FindFirstChild("YourBase")
                    if not (yourBase and yourBase.Enabled) then
                        local podiums = plot:FindFirstChild("AnimalPodiums")
                        if podiums then
                            for _,podium in ipairs(podiums:GetChildren()) do
                                if podium:IsA("Model") and podium:FindFirstChild("Base") then
                                    table.insert(allAnimalsCache,{
                                        plot = plot.Name,
                                        slot = podium.Name,
                                        worldPosition = podium:GetPivot().Position,
                                        uid = plot.Name.."_"..podium.Name
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if AutoStealBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0) or IsStealing then return end
    local hrp = getHRP()
    if not hrp then return end
    local best, dist = nil, math.huge
    for _,a in ipairs(allAnimalsCache) do
        local d = (hrp.Position - a.worldPosition).Magnitude
        if d < dist then dist = d best = a end
    end
    if not best or dist > AUTO_STEAL_PROX_RADIUS then return end
    local p = findPrompt(best)
    if not p then return end
    build(p)
    steal(p)
end)

RunService.RenderStepped:Connect(function()
    if AutoStealBtn.BackgroundColor3 ~= Color3.fromRGB(255, 0, 0) then return end
    local hrp = getHRP()
    if not hrp then return end
    if #circleParts == 0 then createCircle() end
    AUTO_STEAL_PROX_RADIUS = Config.GrabRadius
    for i,p in ipairs(circleParts) do
        local a1 = math.rad((i - 1) / PartsCount * 360)
        local a2 = math.rad(i / PartsCount * 360)
        local p1 = Vector3.new(math.cos(a1), 0, math.sin(a1)) * AUTO_STEAL_PROX_RADIUS
        local p2 = Vector3.new(math.cos(a2), 0, math.sin(a2)) * AUTO_STEAL_PROX_RADIUS
        local c = (p1 + p2) / 2 + hrp.Position
        p.Size = Vector3.new((p2 - p1).Magnitude, 0.2, 0.3)
        p.CFrame = CFrame.new(c, c + Vector3.new(p2.X - p1.X, 0, p2.Z - p1.Z)) * CFrame.Angles(0, math.pi / 2, 0)
    end
end)

-- ============================================================
-- CHARACTER EVENTS
-- ============================================================
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if AutoStealBtn.BackgroundColor3 == Color3.fromRGB(255, 0, 0) then createCircle() end
    
    if unwalkEnabled then 
        task.wait(0.5)
        startUnwalk() 
    end
    
    if medusaCounterEnabled then 
        setupMedusa(char) 
    end
    
    if autoResetOnMedusaEnabled then
        setupAutoResetOnMedusa(char)
    end
    
    if speedCheckerEnabled then
        task.wait(0.5)
        createSpeedDisplay()
    end
end)

player.CharacterRemoving:Connect(function()
    if isStretched then
        disableStretchRez()
    end
end)

-- ============================================================
-- TAB SWITCHING
-- ============================================================
FeaturesTab.MouseButton1Click:Connect(function()
    FeaturesTab.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    FeaturesTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    SettingsTab.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    SettingsTab.TextColor3 = Color3.fromRGB(150, 150, 150)
    FeaturesFrame.Visible = true
    SettingsFrame.Visible = false
end)

SettingsTab.MouseButton1Click:Connect(function()
    SettingsTab.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    SettingsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    FeaturesTab.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    FeaturesTab.TextColor3 = Color3.fromRGB(150, 150, 150)
    FeaturesFrame.Visible = false
    SettingsFrame.Visible = true
end)

-- ============================================================
-- FLOATING OPEN/CLOSE BUTTON
-- ============================================================
local OpenCloseBtnGui = Instance.new("ScreenGui")
OpenCloseBtnGui.Name = "VexOpenClose"
OpenCloseBtnGui.ResetOnSpawn = false
OpenCloseBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OpenCloseBtnGui.Parent = player:WaitForChild("PlayerGui")

local OpenCloseBtn = Instance.new("TextButton")
OpenCloseBtn.Size = UDim2.new(0, 52, 0, 52)
OpenCloseBtn.Position = UDim2.new(0, 10, 0.5, -26)
OpenCloseBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
OpenCloseBtn.Text = "VEX"
OpenCloseBtn.TextSize = 14
OpenCloseBtn.Font = Enum.Font.GothamBlack
OpenCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenCloseBtn.BorderSizePixel = 0
OpenCloseBtn.Active = true
OpenCloseBtn.Parent = OpenCloseBtnGui

local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(0, 14)
oc.Parent = OpenCloseBtn

local OpenCloseBtnStroke = Instance.new("UIStroke")
OpenCloseBtnStroke.Thickness = 2.5
OpenCloseBtnStroke.Color = Color3.fromRGB(255, 0, 0)
OpenCloseBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
OpenCloseBtnStroke.Parent = OpenCloseBtn

-- Pulse glow
task.spawn(function()
    while OpenCloseBtn and OpenCloseBtn.Parent do
        for i=0,20 do if not OpenCloseBtn.Parent then break end OpenCloseBtnStroke.Thickness=2.5+(i*0.05); task.wait(0.04) end
        for i=0,20 do if not OpenCloseBtn.Parent then break end OpenCloseBtnStroke.Thickness=3.5-(i*0.05); task.wait(0.04) end
    end
end)

-- Draggable
do
    local dragging, dragStart, startPos = false, nil, nil
    OpenCloseBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = OpenCloseBtn.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = input.Position - dragStart
            OpenCloseBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

OpenCloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    TweenService:Create(OpenCloseBtnStroke, TweenInfo.new(0.15), {
        Color = MainFrame.Visible and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 0, 0)
    }):Play()
end)

-- ============================================================
-- INITIALIZE
-- ============================================================
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Play intro sound
task.spawn(function()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://133322995548944"
    sound.Volume = 0.5
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end)

task.spawn(function()
    for i = 0, 1, 0.05 do
        MainFrame.BackgroundTransparency = 1 - i
        task.wait(0.02)
    end
end)

task.spawn(function()
    initAutoStealGUI()
    createCircle()
end)

print("Vex Duels Loaded!")
print("Features: Auto Steal, Unwalk, Bat Counter, Medusa Counter, Stretch Rez, Infinite Jump, Shiny Graphics, Auto Reset Medusa, Speed Checker, ESP")
print("Keybinds: V=Auto Steal, M=Auto Reset Medusa, F8=Speed Checker, F1=Stretch Toggle, F2-F4=FOV Presets")
