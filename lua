repeat task.wait() until game:IsLoaded()

local introEnabled = true

do
	local _TS = game:GetService("TweenService")
	local _SS = game:GetService("SoundService")
	local _PL = game:GetService("Players").LocalPlayer
	local _PG = _PL:WaitForChild("PlayerGui")

	local function shouldPlayIntro()
		if not introEnabled then return false end
		if isfile and isfile("reaper_config.json") then
			local ok, cfg = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile("reaper_config.json")) end)
			if ok and cfg and cfg.introEnabled ~= nil then
				return cfg.introEnabled
			end
		end
		return true
	end

	if shouldPlayIntro() then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ReaperIntro"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.DisplayOrder = 9999
		screenGui.Parent = _PG

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1,0,1,0)
		bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
		bg.BackgroundTransparency = 0.45
		bg.BorderSizePixel = 0
		bg.Parent = screenGui

		local webLabel = Instance.new("TextLabel")
		webLabel.Size = UDim2.new(0,120,0,120)
		webLabel.Position = UDim2.new(0,-20,0,-20)
		webLabel.BackgroundTransparency = 1
		webLabel.Text = "⬡"
		webLabel.TextColor3 = Color3.fromRGB(160,160,160)
		webLabel.TextScaled = true
		webLabel.TextTransparency = 1
		webLabel.Font = Enum.Font.Bangers
		webLabel.ZIndex = 2
		webLabel.Parent = bg

		local webLabel2 = Instance.new("TextLabel")
		webLabel2.Size = UDim2.new(0,80,0,80)
		webLabel2.Position = UDim2.new(1,-60,0,-10)
		webLabel2.BackgroundTransparency = 1
		webLabel2.Text = "⬡"
		webLabel2.TextColor3 = Color3.fromRGB(160,160,160)
		webLabel2.TextScaled = true
		webLabel2.TextTransparency = 1
		webLabel2.Font = Enum.Font.Bangers
		webLabel2.ZIndex = 2
		webLabel2.Parent = bg

		local container = Instance.new("Frame")
		container.Size = UDim2.new(0,500,0,180)
		container.Position = UDim2.new(0.5,-250,0.5,-90)
		container.BackgroundTransparency = 1
		container.Parent = bg

		local sp5derFrame = Instance.new("Frame")
		sp5derFrame.Size = UDim2.new(1,0,0,110)
		sp5derFrame.Position = UDim2.new(0,0,0,0)
		sp5derFrame.BackgroundTransparency = 1
		sp5derFrame.Parent = container

		local sp5derText = Instance.new("TextLabel")
		sp5derText.Size = UDim2.new(1,0,1,0)
		sp5derText.BackgroundTransparency = 1
		sp5derText.Text = "REAPER"
		sp5derText.TextColor3 = Color3.fromRGB(200,200,200)
		sp5derText.TextScaled = true
		sp5derText.Font = Enum.Font.Bangers
		sp5derText.TextStrokeTransparency = 0.4
		sp5derText.TextStrokeColor3 = Color3.fromRGB(0,0,0)
		sp5derText.TextTransparency = 1
		sp5derText.TextXAlignment = Enum.TextXAlignment.Center
		sp5derText.ZIndex = 3
		sp5derText.Parent = sp5derFrame

		local hubText = Instance.new("TextLabel")
		hubText.Size = UDim2.new(1,0,0,60)
		hubText.Position = UDim2.new(0,0,0,110)
		hubText.BackgroundTransparency = 1
		hubText.Text = "MOGS"
		hubText.TextColor3 = Color3.fromRGB(255,255,255)
		hubText.TextScaled = true
		hubText.Font = Enum.Font.Bangers
		hubText.TextStrokeTransparency = 0.4
		hubText.TextStrokeColor3 = Color3.fromRGB(0,0,0)
		hubText.TextTransparency = 1
		hubText.TextXAlignment = Enum.TextXAlignment.Center
		hubText.ZIndex = 3
		hubText.Parent = container

		local underline = Instance.new("Frame")
		underline.Size = UDim2.new(0,0,0,3)
		underline.Position = UDim2.new(0.5,0,0,168)
		underline.BackgroundColor3 = Color3.fromRGB(160,160,160)
		underline.BorderSizePixel = 0
		underline.BackgroundTransparency = 1
		underline.AnchorPoint = Vector2.new(0.5,0)
		underline.Parent = container
		local uiGrad = Instance.new("UIGradient", underline)
		uiGrad.Rotation = 15

		local madeBy = Instance.new("TextLabel")
		madeBy.Size = UDim2.new(0,200,0,20)
		madeBy.Position = UDim2.new(0.5,-100,1,-30)
		madeBy.BackgroundTransparency = 1
		madeBy.Text = "made by hz and reaper"
		madeBy.TextColor3 = Color3.fromRGB(160,160,160)
		madeBy.TextTransparency = 1
		madeBy.Font = Enum.Font.Bangers
		madeBy.TextSize = 13
		madeBy.TextXAlignment = Enum.TextXAlignment.Center
		madeBy.ZIndex = 4
		madeBy.Parent = bg

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://119414415681261"
		sound.Volume = 0.7
		sound.Looped = false
		sound.Parent = _SS

		task.wait(0.1)
		sound:Play()
		pcall(function() sound.TimePosition = 45 end)
		local tweenFast = TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local tweenMed  = TweenInfo.new(0.6,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		sp5derFrame.Position = UDim2.new(-0.6, 0, 0, 0)
		_TS:Create(sp5derText, tweenFast, {TextTransparency = 0}):Play()
		_TS:Create(sp5derFrame, tweenFast, {Position = UDim2.new(0,0,0,0)}):Play()
		task.wait(0.05)
		_TS:Create(webLabel,  TweenInfo.new(0.5), {TextTransparency = 0.3}):Play()
		_TS:Create(webLabel2, TweenInfo.new(0.5), {TextTransparency = 0.3}):Play()
		task.wait(0.45)

		hubText.Position = UDim2.new(0.6,0,0,110)
		_TS:Create(hubText, tweenMed, {TextTransparency = 0, Position = UDim2.new(0,0,0,110)}):Play()
		task.wait(0.3)
		underline.BackgroundTransparency = 0
		_TS:Create(underline, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{Size = UDim2.new(0,220,0,3)}):Play()
		_TS:Create(madeBy, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

		task.wait(3.2)

		local fadeOut = TweenInfo.new(0.9, Enum.EasingStyle.Quint)
		_TS:Create(bg,        fadeOut, {BackgroundTransparency = 1}):Play()
		_TS:Create(sp5derText,fadeOut, {TextTransparency = 1}):Play()
		_TS:Create(hubText,   fadeOut, {TextTransparency = 1}):Play()
		_TS:Create(webLabel,  fadeOut, {TextTransparency = 1}):Play()
		_TS:Create(webLabel2, fadeOut, {TextTransparency = 1}):Play()
		_TS:Create(underline, fadeOut, {BackgroundTransparency = 1}):Play()
		_TS:Create(madeBy,    fadeOut, {TextTransparency = 1}):Play()
		task.wait(1.0)
		screenGui:Destroy()
		sound:Stop()
		sound:Destroy()
	end
end

local Players,RunService,UIS,TS,Lighting,HS = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService")
local LP = Players.LocalPlayer
local NS,CS = 60,30
local LAGGER_SPEED = 15
local LAGGER_CARRY_SPEED = 24.5
local speedMode,antiRagdollEnabled,infJumpEnabled = false,false,false
local laggerToggled = false
local laggerPhase = 0
local medusaCounterEnabled = false
local batCounterEnabled = false
local unwalkEnabled = false
local autoMedResetEnabled = false
local medusaDebounce,medusaLastUsed,dropActive = false,0,false
local autoLeftEnabled,autoRightEnabled = false,false
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local autoBatEnabled = false
local autoSwingEnabled = true
local autoBatSetVisual = nil
local setBatCounterVisual = nil
local startBatCounter,stopBatCounter
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
local guiLocked = false

local guiScale = 1.0
local mbScale  = 1.0

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

local function findBatTool()
	local char = LP.Character; if not char then return nil end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
	end
	local bp = LP:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
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
		local c = LP.Character; if not c then return end
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
		local char = LP.Character; if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
		local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
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
			local curCF  = root.CFrame
			local diffCF = curCF:Inverse() * goalCF
			local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
			rx = math.clamp(rx, -2.5, 2.5); ry = math.clamp(ry, -2.5, 2.5); rz = math.clamp(rz, -2.5, 2.5)
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
		if sethiddenproperty then
			pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tr) end)
		end
		local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
		if (root.Position - targetPos).Magnitude > 8 then
			root.CFrame = CFrame.new(targetPos)
		end
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

local resetAutoBatMotion = function() stopEnvyBatAimbot() end

local function cursedInstaReset()
	if not cursedResetRemote then
		for _, desc in ipairs(game:GetDescendants()) do
			if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then
				cursedResetRemote = desc
				break
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
		for _, conn in ipairs(conns) do
			pcall(function() conn:Disconnect() end)
		end
	end)
end

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

local KB = {
	DropBrainrot={kb=Enum.KeyCode.X,  gp=nil},
	AutoLeft    ={kb=Enum.KeyCode.Z,  gp=nil},
	AutoRight   ={kb=Enum.KeyCode.C,  gp=nil},
	AutoBat     ={kb=Enum.KeyCode.E,  gp=nil},
	Aimbot2     ={kb=Enum.KeyCode.V,  gp=nil},
	TPFloor     ={kb=Enum.KeyCode.T,  gp=nil},
	GuiHide     ={kb=Enum.KeyCode.LeftControl, gp=nil},
	SpeedToggle ={kb=Enum.KeyCode.Q,  gp=nil},
	LaggerToggle={kb=Enum.KeyCode.R,  gp=nil},
	InstaReset  ={kb=Enum.KeyCode.G,  gp=nil},
}
local AP_L1,AP_L2 = Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)
local AP_R1,AP_R2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local Steal = {AutoStealEnabled=false, StealRadius=60, StealDuration=1.4, Data={}}
local isStealing = false
local stealStartTime = nil
local Conns = {autoSteal=nil,antiRag=nil,batCounter=nil,anchor={},progress=nil,autoMedReset=nil}
local MEDUSA_COOLDOWN = 25
local batCounterDebounce = false
local progressRadLbl,progressFill,progressPct
local modeValLbl
local lastMoveDir = Vector3.new(0,0,0)
local MOVE_KEYS = {[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
	[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

local function getActiveMoveSpeed()
	return laggerToggled and (laggerPhase==2 and LAGGER_CARRY_SPEED or LAGGER_SPEED) or (speedMode and CS or NS)
end
local function getAutoPathSpeed() return laggerToggled and LAGGER_SPEED or NS end
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
							if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Steal") then nearest,dist=prompt,d end
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
	local data = Steal.Data[prompt]; if not data.ready then return end
	data.ready=false; isStealing=true; stealStartTime=tick()
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

-- Auto Med Reset: detect Medusa state and reset
local function startAutoMedReset()
	if Conns.autoMedReset then return end
	Conns.autoMedReset = RunService.Heartbeat:Connect(function()
		if not autoMedResetEnabled then return end
		local char = LP.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		-- Check if player is in Medusa state (ragdoll/physics state)
		local st = hum:GetState()
		if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
			-- Check for Medusa tool being used on player (look for anchored parts with transparency)
			local hasMedusa = false
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Anchored and part.Transparency == 1 then
					hasMedusa = true
					break
				end
			end
			if hasMedusa then
				task.spawn(cursedInstaReset)
			end
		end
	end)
end

local function stopAutoMedReset()
	if Conns.autoMedReset then Conns.autoMedReset:Disconnect(); Conns.autoMedReset=nil end
end

RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)
RunService.RenderStepped:Connect(function()
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0); return end
	if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled and not aimbot2Enabled then
		local md=hum.MoveDirection
		local spd=getActiveMoveSpeed()
		if md.Magnitude>0 then
			lastMoveDir=md; hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
		elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
			local anyHeld=false
			for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
			if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
		end
	end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)

local alConn,arConn=nil,nil
local alPhase,arPhase=1,1
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
	speedLabel.Text="Speed: 0"; speedLabel.TextColor3=Color3.fromRGB(180,180,180)
	speedLabel.Font=Enum.Font.Bangers; speedLabel.TextScaled=true
	speedLabel.TextStrokeTransparency=0; speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
	local discordLabel=Instance.new("TextLabel",bb)
	discordLabel.Size=UDim2.new(1,0,0,20); discordLabel.Position=UDim2.new(0,0,0,20); discordLabel.BackgroundTransparency=1
	discordLabel.Text="made by hz and reaper"
	discordLabel.TextColor3=Color3.fromRGB(180,180,180)
	discordLabel.Font=Enum.Font.Bangers; discordLabel.TextScaled=true
	discordLabel.TextStrokeTransparency=0; discordLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
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

local holdJumpPressed = false
local holdJumpActive = false
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
	autoTPConn=task.spawn(function()
		while autoTPEnabled do task.wait(0.1); pcall(function() doAutoTPDown(false) end) end
	end)
end
local function stopAutoTP()
	autoTPEnabled=false
	if autoTPConn then task.cancel(autoTPConn); autoTPConn=nil end
end
local function runTPFloor() pcall(function() doAutoTPDown(true) end) end

local defLightBrightness,defLightClock,defLightAmbient
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
	defLightBrightness=defLightBrightness or Lighting.Brightness
	defLightClock=defLightClock or Lighting.ClockTime
	defLightAmbient=defLightAmbient or Lighting.OutdoorAmbient
	Lighting.GlobalShadows=false; Lighting.FogEnd=1e10; Lighting.Brightness=1
	Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0
	for _,e in pairs(Lighting:GetChildren()) do
		pcall(function()
			if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled=false end
		end)
	end
	for _,obj in ipairs(workspace:GetDescendants()) do applyAntiLagDerender(obj) end
	if antiLagDescConn then antiLagDescConn:Disconnect() end
	antiLagDescConn=workspace.DescendantAdded:Connect(function(obj)
		if removeAccessoriesEnabled then applyAntiLagDerender(obj) end
	end)
end
local function disableAntiLag()
	removeAccessoriesEnabled=false; antiLagEnabled=false
	if antiLagDescConn then antiLagDescConn:Disconnect(); antiLagDescConn=nil end
	pcall(function()
		if defLightBrightness then Lighting.Brightness=defLightBrightness end
		if defLightClock then Lighting.ClockTime=defLightClock end
		if defLightAmbient then Lighting.OutdoorAmbient=defLightAmbient end
		Lighting.ExposureCompensation=0
	end)
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
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency==1 then useMedusaCounter() end
	end)
end
local function setupMedusa(char)
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end; Conns.anchor={}
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
	table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
	end))
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
	if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end; task.wait(0.05) end
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

local setCarrySpeedVisual = nil
local setLaggerModeVisual = nil
local setLaggerCarryVisual = nil

local function refreshSpeedModeLabel()
	if modeValLbl then
		modeValLbl.Text = laggerToggled and (laggerPhase==2 and "Lagger Carry" or "Lagger Normal") or (speedMode and "Carry" or "Normal")
	end
end
local function toggleCarryMode()
	if laggerToggled then
		laggerToggled=false; laggerPhase=0
		if setLaggerModeVisual then setLaggerModeVisual(false) end
		if setLaggerCarryVisual then setLaggerCarryVisual(false) end
		speedMode=true
	else speedMode=not speedMode end
	refreshSpeedModeLabel()
end
local function toggleLaggerMode()
	if not laggerToggled then
		if speedMode then speedMode=false; if setCarrySpeedVisual then setCarrySpeedVisual(false) end end
		laggerToggled=true; laggerPhase=1
	elseif laggerPhase==1 then laggerPhase=2
	else laggerPhase=1 end
	refreshSpeedModeLabel()
end

local _mainFrame = nil
local _mbPanel = nil

local function applyGuiScale(scale)
	guiScale = math.clamp(scale, 0.3, 3.0)
	if _mainFrame then
		_mainFrame.Size = UDim2.new(0, math.floor(300*guiScale), 0, math.floor(400*guiScale))
	end
end

local function applyMbScale(scale)
	mbScale = math.clamp(scale, 0.3, 3.0)
	local MB_BTN_SIZE = math.floor(55*mbScale)
	local MB_PAD = math.floor(8*mbScale)
	local MB_COLS = 2
	local MB_ROWS = 6
	local MBTOTALW = MB_COLS*MB_BTN_SIZE + (MB_COLS+1)*MB_PAD
	local MBTOTALH = MB_ROWS*MB_BTN_SIZE + (MB_ROWS+1)*MB_PAD
	if _mbPanel then
		_mbPanel.Size = UDim2.new(0, MBTOTALW, 0, MBTOTALH)
		local col = 0
		for _, btn in ipairs(_mbPanel:GetChildren()) do
			if btn:IsA("TextButton") then
				local c = (col % MB_COLS)
				local r = math.floor(col / MB_COLS)
				local x = MB_PAD + c*(MB_BTN_SIZE+MB_PAD)
				local y = MB_PAD + r*(MB_BTN_SIZE+MB_PAD)
				btn.Size = UDim2.new(0, MB_BTN_SIZE, 0, MB_BTN_SIZE)
				btn.Position = UDim2.new(0, x, 0, y)
				col = col + 1
			end
		end
	end
end

local function saveConfig()
	local function ks(e) return {kb=e.kb and e.kb.Name or nil,gp=e.gp and e.gp.Name or nil} end
	local cfg={
		normalSpeed=NS,carrySpeed=CS,
		dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),
		autoBatKey=ks(KB.AutoBat),aimbot2Key=ks(KB.Aimbot2),laggerToggleKey=ks(KB.LaggerToggle),tpFloorKey=ks(KB.TPFloor),
		guiHideKey=ks(KB.GuiHide),speedToggleKey=ks(KB.SpeedToggle),instaResetKey=ks(KB.InstaReset),
		grabRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,
		antiRagdoll=antiRagdollEnabled,autoStealEnabled=Steal.AutoStealEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,
		batCounter=batCounterEnabled,
		carryMode=speedMode,laggerMode=laggerToggled,laggerCarryMode=laggerPhase==2,
		laggerSpeed=LAGGER_SPEED,laggerCarrySpeed=LAGGER_CARRY_SPEED,
		autoBat=autoBatEnabled,autoSwing=autoSwingEnabled,
		aimbot2=aimbot2Enabled,
		unwalkEnabled=unwalkEnabled,
		antiLag=antiLagEnabled,stretchRez=stretchRezEnabled,
		autoTPEnabled=autoTPEnabled,autoTPHeight=autoTPHeight,
		guiLocked=guiLocked,introEnabled=introEnabled,
		guiScale=guiScale,mbScale=mbScale,
		autoMedReset=autoMedResetEnabled,
		mainPosXS=nil,mainPosXO=nil,mainPosYS=nil,mainPosYO=nil,
		bubblePosXS=nil,bubblePosXO=nil,bubblePosYS=nil,bubblePosYO=nil,
		pbPosXS=nil,pbPosXO=nil,pbPosYS=nil,pbPosYO=nil,
		mbPosXS=nil,mbPosXO=nil,mbPosYS=nil,mbPosYO=nil,
	}
	local gv = getgenv and getgenv()
	if gv then
		if gv._reaper_mainPos then cfg.mainPosXS=gv._reaper_mainPos.X.Scale;cfg.mainPosXO=gv._reaper_mainPos.X.Offset;cfg.mainPosYS=gv._reaper_mainPos.Y.Scale;cfg.mainPosYO=gv._reaper_mainPos.Y.Offset end
		if gv._reaper_bubblePos then cfg.bubblePosXS=gv._reaper_bubblePos.X.Scale;cfg.bubblePosXO=gv._reaper_bubblePos.X.Offset;cfg.bubblePosYS=gv._reaper_bubblePos.Y.Scale;cfg.bubblePosYO=gv._reaper_bubblePos.Y.Offset end
		if gv._reaper_pbPos then cfg.pbPosXS=gv._reaper_pbPos.X.Scale;cfg.pbPosXO=gv._reaper_pbPos.X.Offset;cfg.pbPosYS=gv._reaper_pbPos.Y.Scale;cfg.pbPosYO=gv._reaper_pbPos.Y.Offset end
		if gv._reaper_mbPos then cfg.mbPosXS=gv._reaper_mbPos.X.Scale;cfg.mbPosXO=gv._reaper_mbPos.X.Offset;cfg.mbPosYS=gv._reaper_mbPos.Y.Scale;cfg.mbPosYO=gv._reaper_mbPos.Y.Offset end
	end
	if writefile then pcall(function() writefile("reaper_config.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(5) do saveConfig() end end)

local setInstaGrab,setInfJumpVisual,setAntiRagVisual,setMedusaVisual
local setUnwalkVisual,setAntiLagVisual,setAutoSwingVisual,setIntroToggleVisual,setAutoMedResetVisual
local setLaggerModeTabVisual = nil
local normalBox,carryBox,laggerBox,laggerCarryBox,radInput,autoTPHeightBox

local function buildGui()
	local GREY       = Color3.fromRGB(160,160,160)
	local GREY_LIGHT = Color3.fromRGB(210,210,210)
	local GREY_DIM   = Color3.fromRGB(100,100,100)
	local BG         = Color3.fromRGB(10,10,10)
	local CARD       = Color3.fromRGB(18,18,18)
	local TEXT       = Color3.fromRGB(220,220,220)
	local BLACK      = Color3.fromRGB(5,5,5)
	local BLUE_TEXT  = Color3.fromRGB(130,160,210)
	local CORNER = UDim.new(0, 8)

	local old=game:GetService("CoreGui"):FindFirstChild("ReaperHub"); if old then old:Destroy() end
	local pg=LP:FindFirstChild("PlayerGui"); if pg then local o=pg:FindFirstChild("ReaperHub"); if o then o:Destroy() end end

	local gui=Instance.new("ScreenGui")
	gui.Name="ReaperHub"; gui.ResetOnSpawn=false; gui.DisplayOrder=10; gui.IgnoreGuiInset=true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	if not pcall(function() gui.Parent=game:GetService("CoreGui") end) then gui.Parent=LP:WaitForChild("PlayerGui") end

	local function addAnimatedStroke(frame, color, thickness)
		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = color or GREY
		stroke.Thickness = thickness or 1.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		task.spawn(function()
			while frame and frame.Parent do
				local t1 = TS:Create(stroke,TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Color=GREY_LIGHT,Thickness=(thickness or 1.5)+0.8})
				t1:Play(); t1.Completed:Wait()
				local t2 = TS:Create(stroke,TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Color=color or GREY,Thickness=thickness or 1.5})
				t2:Play(); t2.Completed:Wait()
			end
		end)
		return stroke
	end

	local savedCfgForPos = nil
	pcall(function()
		if isfile and isfile("reaper_config.json") then
			local ok, d = pcall(function() return HS:JSONDecode(readfile("reaper_config.json")) end)
			if ok then savedCfgForPos = d end
		end
	end)
	local function savedPos(xsKey,xoKey,ysKey,yoKey,fallback)
		if savedCfgForPos and savedCfgForPos[xsKey] ~= nil then
			return UDim2.new(savedCfgForPos[xsKey],savedCfgForPos[xoKey],savedCfgForPos[ysKey],savedCfgForPos[yoKey])
		end
		return fallback
	end

	local bubble=Instance.new("TextButton",gui)
	bubble.Name="ReaperBubble"
	bubble.Size=UDim2.new(0,110,0,30)
	bubble.Position=savedPos("bubblePosXS","bubblePosXO","bubblePosYS","bubblePosYO",UDim2.new(0,20,0.5,-15))
	bubble.BackgroundColor3=Color3.fromRGB(10,10,10)
	bubble.BorderSizePixel=0
	bubble.Text="reaper hub"
	bubble.TextColor3=GREY
	bubble.Font=Enum.Font.Bangers
	bubble.TextSize=13
	bubble.ZIndex=20
	Instance.new("UICorner",bubble).CornerRadius=UDim.new(0,8)
	addAnimatedStroke(bubble,GREY,1.5)
	do
		local dn,ds,sp2,di2=false
		bubble.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dn=true; ds=i.Position; sp2=bubble.Position
				i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dn=false end end)
			end
		end)
		bubble.InputChanged:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di2=i end
		end)
		UIS.InputChanged:Connect(function(i)
			if i==di2 and dn then
				local delta=i.Position-ds
				bubble.Position=UDim2.new(sp2.X.Scale,sp2.X.Offset+delta.X,sp2.Y.Scale,sp2.Y.Offset+delta.Y)
				local gv=getgenv and getgenv(); if gv then gv._reaper_bubblePos=bubble.Position end
			end
		end)
	end

	local main=Instance.new("Frame",gui)
	main.Name="Main"
	main.Size=UDim2.new(0,math.floor(300*guiScale),0,math.floor(400*guiScale))
	main.Position=savedPos("mainPosXS","mainPosXO","mainPosYS","mainPosYO",UDim2.new(0.5,-150,0.5,-200))
	main.BackgroundColor3=BG
	main.BackgroundTransparency=0.04
	main.BorderSizePixel=0
	main.ClipsDescendants=true
	Instance.new("UICorner",main).CornerRadius=UDim.new(0,8)
	addAnimatedStroke(main,GREY,2.5)
	_mainFrame = main

	local function dragFrame(frame, posKey)
		local dn,ds,sp,di=false
		frame.InputBegan:Connect(function(i)
			if guiLocked then return end
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dn=true; ds=i.Position; sp=frame.Position
				i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dn=false end end)
			end
		end)
		frame.InputChanged:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end
		end)
		UIS.InputChanged:Connect(function(i)
			if i==di and dn and not guiLocked then
				local delta=i.Position-ds
				frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y)
				local gv=getgenv and getgenv(); if gv and posKey then gv[posKey]=frame.Position end
			end
		end)
	end
	dragFrame(main,"_reaper_mainPos")
	local gv0=getgenv and getgenv()
	if gv0 then gv0._reaper_mainPos=main.Position; gv0._reaper_bubblePos=bubble.Position end

	local function showGui() main.Visible=true end
	local function hideGui() main.Visible=false end
	bubble.MouseButton1Click:Connect(function() main.Visible=not main.Visible end)

	local header=Instance.new("Frame",main)
	header.Size=UDim2.new(1,0,0,40); header.BackgroundTransparency=1

	local ttl=Instance.new("TextLabel",header)
	ttl.Size=UDim2.new(0,220,1,0); ttl.Position=UDim2.new(0,14,0,0)
	ttl.BackgroundTransparency=1; ttl.Text="reaper hub"
	ttl.TextColor3=GREY; ttl.Font=Enum.Font.Bangers
	ttl.TextSize=21; ttl.TextXAlignment=Enum.TextXAlignment.Left

	local closeBtn=Instance.new("TextButton",header)
	closeBtn.Size=UDim2.new(0,24,0,24); closeBtn.Position=UDim2.new(1,-32,0.5,-12)
	closeBtn.BackgroundColor3=Color3.fromRGB(20,20,20); closeBtn.BorderSizePixel=0
	closeBtn.Text="X"; closeBtn.TextColor3=GREY; closeBtn.Font=Enum.Font.Bangers; closeBtn.TextSize=13
	Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,8)
	addAnimatedStroke(closeBtn,GREY_DIM,1)
	closeBtn.MouseEnter:Connect(function() TS:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(60,60,60),TextColor3=GREY_LIGHT}):Play() end)
	closeBtn.MouseLeave:Connect(function() TS:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(20,20,20),TextColor3=GREY}):Play() end)
	closeBtn.MouseButton1Click:Connect(hideGui)

	local sep=Instance.new("Frame",main)
	sep.Size=UDim2.new(1,-18,0,2); sep.Position=UDim2.new(0,9,0,40)
	sep.BackgroundColor3=GREY; sep.BorderSizePixel=0
	local sepGrad=Instance.new("UIGradient",sep)
	sepGrad.Rotation=0
	sepGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(40,40,40)),ColorSequenceKeypoint.new(0.5,GREY_LIGHT),ColorSequenceKeypoint.new(1,Color3.fromRGB(40,40,40))})
	task.spawn(function()
		while sep and sep.Parent do
			local t1=TS:Create(sep,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.35})
			t1:Play(); t1.Completed:Wait()
			local t2=TS:Create(sep,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0})
			t2:Play(); t2.Completed:Wait()
		end
	end)

	local sidebar=Instance.new("Frame",main)
	sidebar.Size=UDim2.new(0,100,1,-50); sidebar.Position=UDim2.new(0,10,0,48); sidebar.BackgroundTransparency=1
	local tabList=Instance.new("UIListLayout",sidebar); tabList.SortOrder=Enum.SortOrder.LayoutOrder; tabList.Padding=UDim.new(0,8)

	local content=Instance.new("Frame",main)
	content.Name="Content"; content.Size=UDim2.new(1,-128,1,-54); content.Position=UDim2.new(0,118,0,52)
	content.BackgroundTransparency=1; content.ClipsDescendants=true

	local tabs={}
	local currentTab=nil

	local function createTabButton(name,order)
		local btn=Instance.new("TextButton",sidebar)
		btn.Size=UDim2.new(0,88,0,30); btn.BackgroundColor3=CARD; btn.BorderSizePixel=0
		btn.Text=name; btn.TextColor3=GREY; btn.Font=Enum.Font.Bangers; btn.TextSize=11; btn.LayoutOrder=order
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
		addAnimatedStroke(btn,GREY_DIM,1.2)
		return btn
	end

	local function switchTab(tabName)
		if currentTab==tabName then return end
		currentTab=tabName
		for name,btn in pairs(tabs) do
			if name==tabName then btn.BackgroundColor3=GREY; btn.TextColor3=BLACK
			else btn.BackgroundColor3=CARD; btn.TextColor3=GREY end
		end
		for _,child in ipairs(content:GetChildren()) do
			if child:IsA("Frame") or child:IsA("ScrollingFrame") then child.Visible=false end
		end
		local t=content:FindFirstChild(tabName); if t then t.Visible=true end
	end

	local function createTabFrame(name)
		local sf=Instance.new("ScrollingFrame",content); sf.Name=name; sf.Size=UDim2.new(1,0,1,0)
		sf.BackgroundTransparency=1; sf.BorderSizePixel=0; sf.ScrollBarThickness=0; sf.ScrollBarImageTransparency=1
		sf.CanvasSize=UDim2.new(0,0,0,0); sf.AutomaticCanvasSize=Enum.AutomaticSize.Y; sf.Visible=false
		local ll=Instance.new("UIListLayout",sf); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,5)
		local pad=Instance.new("UIPadding",sf)
		pad.PaddingLeft=UDim.new(0,3); pad.PaddingRight=UDim.new(0,3); pad.PaddingTop=UDim.new(0,3); pad.PaddingBottom=UDim.new(0,8)
		return sf
	end

	local combatTab=createTabFrame("Combat")
	local visualTab=createTabFrame("Visual")
	local protectTab=createTabFrame("Protect")
	local playerTab=createTabFrame("Player")
	local miscTab=createTabFrame("Misc")
	local settingsTab=createTabFrame("Settings")

	tabs["Combat"]=createTabButton("Combat",1)
	tabs["Visual"]=createTabButton("Visual",2)
	tabs["Protect"]=createTabButton("Protect",3)
	tabs["Player"]=createTabButton("Player",4)
	tabs["Misc"]=createTabButton("Misc",5)
	tabs["Settings"]=createTabButton("Settings",6)

	for name,btn in pairs(tabs) do btn.MouseButton1Click:Connect(function() switchTab(name) end) end

	local lo=0
	local function LO() lo=lo+1; return lo end

	local function mkRow(parent,h)
		local f=Instance.new("Frame",parent)
		f.Size=UDim2.new(1,0,0,h or 30); f.BackgroundColor3=CARD; f.BorderSizePixel=0; f.LayoutOrder=LO()
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
		addAnimatedStroke(f,GREY_DIM,1)
		f.MouseEnter:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play() end)
		f.MouseLeave:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=CARD}):Play() end)
		return f
	end

	local function mkLabel(row,txt)
		local l=Instance.new("TextLabel",row)
		l.Size=UDim2.new(0.5,0,1,0); l.Position=UDim2.new(0,8,0,0)
		l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=TEXT
		l.Font=Enum.Font.Bangers; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left
		return l
	end

	local function animPill(pill,dot,on)
		TS:Create(pill,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{BackgroundColor3=on and GREY_DIM or Color3.fromRGB(22,22,22)}):Play()
		TS:Create(dot,TweenInfo.new(0.18,Enum.EasingStyle.Back),{
			Position=on and UDim2.new(1,-16,0.5,-6) or UDim2.new(0,3,0.5,-6),
			BackgroundColor3=on and GREY_LIGHT or Color3.fromRGB(60,60,60),
		}):Play()
	end

	local function mkPill(row,offset)
		local pill=Instance.new("Frame",row)
		pill.Size=UDim2.new(0,36,0,18); pill.Position=UDim2.new(1,-(offset or 46),0.5,-9)
		pill.BackgroundColor3=Color3.fromRGB(22,22,22); pill.BorderSizePixel=0; pill.ZIndex=3
		Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
		local dot=Instance.new("Frame",pill)
		dot.Size=UDim2.new(0,12,0,12); dot.Position=UDim2.new(0,3,0.5,-6)
		dot.BackgroundColor3=Color3.fromRGB(60,60,60); dot.BorderSizePixel=0; dot.ZIndex=4
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		return pill,dot
	end

	local function mkToggle(parent,txt,cb)
		local row=mkRow(parent,30); mkLabel(row,txt)
		local pill,dot=mkPill(row,46); local on=false
		local function sv(s) on=s; animPill(pill,dot,s) end
		local clk=Instance.new("TextButton",pill)
		clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=5
		clk.Activated:Connect(function() on=not on; sv(on); cb(on) end)
		return sv
	end

	local function mkBox(parent,default,w,xOff,cb)
		local tb=Instance.new("TextBox",parent)
		tb.Size=UDim2.new(0,w or 44,0,20); tb.Position=UDim2.new(1,-(xOff or 56),0.5,-10)
		tb.BackgroundColor3=Color3.fromRGB(14,14,14); tb.BorderSizePixel=0
		tb.Text=tostring(default); tb.TextColor3=GREY; tb.Font=Enum.Font.Bangers; tb.TextSize=10
		tb.ClearTextOnFocus=false; tb.ZIndex=5
		Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)
		local bs=Instance.new("UIStroke",tb); bs.Color=GREY_DIM; bs.Thickness=1
		tb.Focused:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Color=GREY}):Play() end)
		tb.FocusLost:Connect(function()
			TS:Create(bs,TweenInfo.new(0.12),{Color=GREY_DIM}):Play()
			if cb then local n=tonumber(tb.Text); if n then cb(n) else tb.Text=tostring(default) end end
		end)
		return tb
	end

	local GAMEPAD_KEYS={[Enum.KeyCode.ButtonA]=true,[Enum.KeyCode.ButtonB]=true,[Enum.KeyCode.ButtonX]=true,[Enum.KeyCode.ButtonY]=true,[Enum.KeyCode.ButtonL1]=true,[Enum.KeyCode.ButtonR1]=true,[Enum.KeyCode.ButtonL2]=true,[Enum.KeyCode.ButtonR2]=true,[Enum.KeyCode.ButtonL3]=true,[Enum.KeyCode.ButtonR3]=true,[Enum.KeyCode.ButtonStart]=true,[Enum.KeyCode.ButtonSelect]=true,[Enum.KeyCode.DPadUp]=true,[Enum.KeyCode.DPadDown]=true,[Enum.KeyCode.DPadLeft]=true,[Enum.KeyCode.DPadRight]=true}
	local function isGamepadInput(inp) return inp and inp.UserInputType and inp.UserInputType.Name:match("^Gamepad")~=nil end
	local function isBindableInput(inp)
		if not inp or inp.KeyCode==Enum.KeyCode.Unknown then return false end
		if inp.UserInputType==Enum.UserInputType.Keyboard then return true end
		return isGamepadInput(inp) and GAMEPAD_KEYS[inp.KeyCode]==true
	end
	local function kbMatch(entry,kc) return kc and (kc==entry.kb or (entry.gp and kc==entry.gp)) end

	local function mkKB(parent,kbEntry,cb)
		local btn=Instance.new("TextButton",parent)
		btn.Size=UDim2.new(0,46,0,20); btn.Position=UDim2.new(1,-54,0.5,-10)
		btn.BackgroundColor3=Color3.fromRGB(14,14,14); btn.BorderSizePixel=0
		local function getLabel() return (kbEntry.gp and kbEntry.gp.Name) or (kbEntry.kb and kbEntry.kb.Name) or "None" end
		btn.Text=getLabel(); btn.TextColor3=GREY; btn.Font=Enum.Font.Bangers; btn.TextSize=10; btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
		local bs=Instance.new("UIStroke",btn); bs.Color=GREY_DIM; bs.Thickness=1
		local li=false; local lc; local pv=btn.Text; local listenStart=0
		btn.Activated:Connect(function()
			if li then li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end; btn.Text=pv; btn.TextColor3=GREY; return end
			pv=btn.Text; li=true; _anyKeyListening=true; listenStart=tick(); btn.Text="..."; btn.TextColor3=TEXT
			lc=UIS.InputBegan:Connect(function(inp)
				if not li then return end
				if inp.KeyCode==Enum.KeyCode.Escape then li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end; btn.Text=pv; btn.TextColor3=GREY; return end
				local isGp=isGamepadInput(inp)
				if isGp and tick()-listenStart<0.15 then return end
				if not isBindableInput(inp) then return end
				btn.Text=inp.KeyCode.Name; pv=inp.KeyCode.Name; btn.TextColor3=GREY
				li=false; _anyKeyListening=false; if lc then lc:Disconnect(); lc=nil end
				if cb then cb(inp.KeyCode,isGp) end
			end)
		end)
		return btn
	end

	local function mkToggleKB(parent,txt,kbEntry,onToggle,onKB)
		local row=mkRow(parent,30); mkLabel(row,txt)
		if kbEntry then
			mkKB(row,kbEntry,function(k,isGp)
				if isGp then kbEntry.gp=k; kbEntry.kb=nil else kbEntry.kb=k; kbEntry.gp=nil end
				if onKB then onKB(k,isGp) end
			end)
		end
		local pill,dot=mkPill(row,kbEntry and 110 or 46); local on=false
		local function sv(s) on=s; animPill(pill,dot,s) end
		local clk=Instance.new("TextButton",pill); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=5
		clk.Activated:Connect(function() if _anyKeyListening then return end; on=not on; sv(on); if onToggle then onToggle(on) end end)
		return sv
	end

	-- Progress bar
	local pbFrame=Instance.new("Frame",gui)
	pbFrame.Size=UDim2.new(0,260,0,46)
	pbFrame.Position=savedPos("pbPosXS","pbPosXO","pbPosYS","pbPosYO",UDim2.new(0.5,-130,1,-60))
	pbFrame.BackgroundColor3=Color3.fromRGB(12,12,12); pbFrame.BorderSizePixel=0; pbFrame.Active=true
	Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(0,8)
	addAnimatedStroke(pbFrame,GREY_DIM,1.5)
	do
		local dn,ds,sp,di=false
		pbFrame.InputBegan:Connect(function(i)
			if guiLocked then return end
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dn=true; ds=i.Position; sp=pbFrame.Position
				i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dn=false end end)
			end
		end)
		pbFrame.InputChanged:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end
		end)
		UIS.InputChanged:Connect(function(i)
			if i==di and dn and not guiLocked then
				pbFrame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+(i.Position.X-ds.X),sp.Y.Scale,sp.Y.Offset+(i.Position.Y-ds.Y))
				local gv=getgenv and getgenv(); if gv then gv._reaper_pbPos=pbFrame.Position end
			end
		end)
	end
	local gv1=getgenv and getgenv(); if gv1 then gv1._reaper_pbPos=pbFrame.Position end

	progressPct=Instance.new("TextLabel",pbFrame)
	progressPct.Size=UDim2.new(0,40,0,14); progressPct.Position=UDim2.new(0,8,0,6)
	progressPct.BackgroundTransparency=1; progressPct.Text="0%"; progressPct.TextColor3=TEXT
	progressPct.Font=Enum.Font.Bangers; progressPct.TextSize=10; progressPct.TextXAlignment=Enum.TextXAlignment.Left
	progressRadLbl=Instance.new("TextLabel",pbFrame)
	progressRadLbl.Size=UDim2.new(0,100,0,14); progressRadLbl.Position=UDim2.new(1,-108,0,6)
	progressRadLbl.BackgroundTransparency=1; progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius)
	progressRadLbl.TextColor3=TEXT; progressRadLbl.Font=Enum.Font.Bangers; progressRadLbl.TextSize=10; progressRadLbl.TextXAlignment=Enum.TextXAlignment.Right
	local pbg=Instance.new("Frame",pbFrame)
	pbg.Size=UDim2.new(1,-16,0,10); pbg.Position=UDim2.new(0,8,0,28)
	pbg.BackgroundColor3=Color3.fromRGB(8,8,8); pbg.BorderSizePixel=0
	Instance.new("UICorner",pbg).CornerRadius=UDim.new(1,0)
	progressFill=Instance.new("Frame",pbg)
	progressFill.Size=UDim2.new(0,0,1,0); progressFill.BackgroundColor3=GREY; progressFill.BorderSizePixel=0
	Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)

	-- ═══ COMBAT TAB ═══
	do
		local abRow=mkRow(combatTab,30); mkLabel(abRow,"Auto Bat")
		mkKB(abRow,KB.AutoBat,function(k,isGp)
			if isGp then KB.AutoBat.gp=k; KB.AutoBat.kb=nil else KB.AutoBat.kb=k; KB.AutoBat.gp=nil end; saveConfig()
		end)
		local abPill,abDot=mkPill(abRow,110); abPill.ZIndex=3; abDot.ZIndex=4
		local abOn=false
		local function svAutoBat(s) abOn=s; animPill(abPill,abDot,s) end
		autoBatSetVisual=svAutoBat
		local abClk=Instance.new("TextButton",abPill); abClk.Size=UDim2.new(1,0,1,0); abClk.BackgroundTransparency=1; abClk.Text=""; abClk.ZIndex=5
		abClk.Activated:Connect(function()
			if _anyKeyListening then return end
			abOn=not abOn; svAutoBat(abOn)
			if abOn then queueAutoBatStart() else disableAutoBat() end; saveConfig()
		end)
	end
	do
		local ab2Row=mkRow(combatTab,30); mkLabel(ab2Row,"Aimbot 2")
		mkKB(ab2Row,KB.Aimbot2,function(k,isGp)
			if isGp then KB.Aimbot2.gp=k; KB.Aimbot2.kb=nil else KB.Aimbot2.kb=k; KB.Aimbot2.gp=nil end; saveConfig()
		end)
		local ab2Pill,ab2Dot=mkPill(ab2Row,110); ab2Pill.ZIndex=3; ab2Dot.ZIndex=4
		local ab2On=false
		local function svAimbot2(s) ab2On=s; animPill(ab2Pill,ab2Dot,s) end
		aimbot2SetVisual=svAimbot2
		local ab2Clk=Instance.new("TextButton",ab2Pill); ab2Clk.Size=UDim2.new(1,0,1,0); ab2Clk.BackgroundTransparency=1; ab2Clk.Text=""; ab2Clk.ZIndex=5
		ab2Clk.Activated:Connect(function()
			if _anyKeyListening then return end
			ab2On=not ab2On; svAimbot2(ab2On)
			if ab2On then queueAimbot2Start() else disableAimbot2() end; saveConfig()
		end)
	end
	setAutoSwingVisual=mkToggle(combatTab,"Auto Swing",function(on) autoSwingEnabled=on; saveConfig() end)
	if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
	setBatCounterVisual=mkToggle(combatTab,"Bat Counter",function(on)
		batCounterEnabled=on; if on then startBatCounter() else stopBatCounter() end; saveConfig()
	end)
	do
		local row=mkRow(combatTab,30); mkLabel(row,"Steal Radius")
		radInput=mkBox(row,Steal.StealRadius,44,56,function(v)
			if v>=0.5 and v<=300 then Steal.StealRadius=v; if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius) end end; saveConfig()
		end)
	end
	do
		local stealRow=mkRow(combatTab,30); mkLabel(stealRow,"Auto Steal")
		local pill,dot=mkPill(stealRow,46); local on=false
		local function sv(s) on=s; animPill(pill,dot,s) end
		setInstaGrab=sv
		local clk=Instance.new("TextButton",pill); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=5
		clk.Activated:Connect(function()
			on=not on; sv(on); Steal.AutoStealEnabled=on
			if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled=false; sv(false) end else stopAutoSteal() end; saveConfig()
		end)
		pill.ZIndex=3; dot.ZIndex=4
	end
	do
		local row=mkRow(combatTab,30); mkLabel(row,"Drop Brainrot")
		mkKB(row,KB.DropBrainrot,function(k,isGp) if isGp then KB.DropBrainrot.gp=k; KB.DropBrainrot.kb=nil else KB.DropBrainrot.kb=k; KB.DropBrainrot.gp=nil end; saveConfig() end)
		local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(0.5,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=2
		clk.Activated:Connect(function() runDrop() end)
	end

	-- ═══ VISUAL TAB ═══
	setAntiLagVisual=mkToggle(visualTab,"Anti Lag",function(on) if on then enableAntiLag() else disableAntiLag() end; saveConfig() end)
	setStretchRezVisual=mkToggle(visualTab,"Stretch Rez",function(on) if on then enableStretchRez() else disableStretchRez() end; saveConfig() end)

	-- ═══ PROTECT TAB ═══
	setAntiRagVisual=mkToggle(protectTab,"Anti Ragdoll",function(on) antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
	setMedusaVisual=mkToggle(protectTab,"Medusa Counter",function(on)
		medusaCounterEnabled=on; if on then setupMedusa(LP.Character) else stopMedusaCounter() end; saveConfig()
	end)

	-- ═══ PLAYER TAB ═══
	do local row=mkRow(playerTab,30); mkLabel(row,"Normal Speed"); normalBox=mkBox(row,NS,44,52,function(v) if v>0 and v<=500 then NS=v end; saveConfig() end) end
	do local row=mkRow(playerTab,30); mkLabel(row,"Carry Speed"); carryBox=mkBox(row,CS,44,52,function(v) if v>0 and v<=500 then CS=v end; saveConfig() end) end
	do local row=mkRow(playerTab,30); mkLabel(row,"Lagger Normal"); laggerBox=mkBox(row,LAGGER_SPEED,44,52,function(v) if v>0 and v<=500 then LAGGER_SPEED=v end; saveConfig() end) end
	do local row=mkRow(playerTab,30); mkLabel(row,"Lagger Carry"); laggerCarryBox=mkBox(row,LAGGER_CARRY_SPEED,44,52,function(v) if v>0 and v<=500 then LAGGER_CARRY_SPEED=v end; saveConfig() end) end

	-- Lagger Mode toggle in Player tab
	do
		local sv = mkToggle(playerTab, "Lagger Mode", function(on)
			if on then
				if speedMode then
					speedMode = false
					if setCarrySpeedVisual then setCarrySpeedVisual(false) end
				end
				laggerToggled = true
				laggerPhase = 1
			else
				laggerToggled = false
				laggerPhase = 0
			end
			refreshSpeedModeLabel()
			saveConfig()
		end)
		setLaggerModeTabVisual = sv
		local _prevLaggerModeVisual = setLaggerModeVisual
		setLaggerModeVisual = function(s)
			if _prevLaggerModeVisual then _prevLaggerModeVisual(s) end
			if setLaggerModeTabVisual then setLaggerModeTabVisual(s) end
		end
	end

	do
		local row=mkRow(playerTab,30); mkLabel(row,"Mode")
		modeValLbl=Instance.new("TextLabel",row)
		modeValLbl.Size=UDim2.new(0,110,1,0); modeValLbl.Position=UDim2.new(1,-114,0,0)
		modeValLbl.BackgroundTransparency=1; modeValLbl.Text="Normal"; modeValLbl.TextColor3=GREY
		modeValLbl.Font=Enum.Font.Bangers; modeValLbl.TextSize=11; modeValLbl.TextXAlignment=Enum.TextXAlignment.Right
		local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=2
		clk.Activated:Connect(function() if _anyKeyListening then return end; toggleCarryMode(); saveConfig() end)
	end
	setInfJumpVisual=mkToggle(playerTab,"Infinite Jump",function(on) infJumpEnabled=on end)
	setUnwalkVisual=mkToggle(playerTab,"Unwalk",function(on) unwalkEnabled=on; if on then startUnwalk() else stopUnwalk() end end)
	setAutoTPVisual=mkToggle(playerTab,"Auto TP",function(on) autoTPEnabled=on; if on then startAutoTP() else stopAutoTP() end; saveConfig() end)
	do
		local row=mkRow(playerTab,30); mkLabel(row,"TP Height")
		autoTPHeightBox=mkBox(row,autoTPHeight,44,52,function(v)
			if v>=0 and v<=500 then autoTPHeight=v else autoTPHeightBox.Text=tostring(autoTPHeight) end; saveConfig()
		end)
	end
	do
		local row=mkRow(playerTab,30); mkLabel(row,"TP Down")
		mkKB(row,KB.TPFloor,function(k,isGp) if isGp then KB.TPFloor.gp=k; KB.TPFloor.kb=nil else KB.TPFloor.kb=k; KB.TPFloor.gp=nil end; saveConfig() end)
		local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(0.5,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=2
		clk.Activated:Connect(function() runTPFloor() end)
	end

	-- ═══ MISC TAB ═══
	do
		local sv=mkToggleKB(miscTab,"Auto Left",KB.AutoLeft,
			function(on) autoLeftEnabled=on; if on then queueAutoLeftStart() else stopAutoLeft() end end,
			function(k,isGp) if isGp then KB.AutoLeft.gp=k; KB.AutoLeft.kb=nil else KB.AutoLeft.kb=k; KB.AutoLeft.gp=nil end; saveConfig() end)
		autoLeftSetVisual=sv
	end
	do
		local sv=mkToggleKB(miscTab,"Auto Right",KB.AutoRight,
			function(on) autoRightEnabled=on; if on then queueAutoRightStart() else stopAutoRight() end end,
			function(k,isGp) if isGp then KB.AutoRight.gp=k; KB.AutoRight.kb=nil else KB.AutoRight.kb=k; KB.AutoRight.gp=nil end; saveConfig() end)
		autoRightSetVisual=sv
	end
	do local row=mkRow(miscTab,30); mkLabel(row,"Insta Reset KB"); mkKB(row,KB.InstaReset,function(k,isGp) if isGp then KB.InstaReset.gp=k; KB.InstaReset.kb=nil else KB.InstaReset.kb=k; KB.InstaReset.gp=nil end; saveConfig() end) end
	do local row=mkRow(miscTab,30); mkLabel(row,"Hide UI"); mkKB(row,KB.GuiHide,function(k,isGp) if isGp then KB.GuiHide.gp=k; KB.GuiHide.kb=nil else KB.GuiHide.kb=k; KB.GuiHide.gp=nil end; saveConfig() end) end
	do local row=mkRow(miscTab,30); mkLabel(row,"Speed Key"); mkKB(row,KB.SpeedToggle,function(k,isGp) if isGp then KB.SpeedToggle.gp=k; KB.SpeedToggle.kb=nil else KB.SpeedToggle.kb=k; KB.SpeedToggle.gp=nil end; saveConfig() end) end
	do local row=mkRow(miscTab,30); mkLabel(row,"Lagger Key"); mkKB(row,KB.LaggerToggle,function(k,isGp) if isGp then KB.LaggerToggle.gp=k; KB.LaggerToggle.kb=nil else KB.LaggerToggle.kb=k; KB.LaggerToggle.gp=nil end; saveConfig() end) end
	
	-- Auto Med Reset in Misc tab
	setAutoMedResetVisual=mkToggle(miscTab,"Auto Med Reset",function(on)
		autoMedResetEnabled=on
		if on then startAutoMedReset() else stopAutoMedReset() end
		saveConfig()
	end)

	local creditFrame=Instance.new("Frame",miscTab)
	creditFrame.Size=UDim2.new(1,0,0,25); creditFrame.BackgroundTransparency=1; creditFrame.LayoutOrder=LO()
	local creditText=Instance.new("TextLabel",creditFrame)
	creditText.Size=UDim2.new(1,0,1,0); creditText.BackgroundTransparency=1
	creditText.Text="made by hz and reaper"; creditText.TextColor3=BLUE_TEXT
	creditText.Font=Enum.Font.Bangers; creditText.TextSize=9
	creditText.TextScaled=false; creditText.TextWrapped=true; creditText.TextXAlignment=Enum.TextXAlignment.Center

	-- ═══ SETTINGS TAB ═══
	do
		local secRow=Instance.new("Frame",settingsTab)
		secRow.Size=UDim2.new(1,0,0,20); secRow.BackgroundTransparency=1; secRow.LayoutOrder=LO()
		local secLbl=Instance.new("TextLabel",secRow); secLbl.Size=UDim2.new(1,0,1,0)
		secLbl.BackgroundTransparency=1; secLbl.Text="GUI"; secLbl.TextColor3=GREY
		secLbl.Font=Enum.Font.Bangers; secLbl.TextSize=9; secLbl.TextXAlignment=Enum.TextXAlignment.Left

		do
			local row=mkRow(settingsTab,30); mkLabel(row,"Main GUI Scale")
			local box=mkBox(row,guiScale,44,52,function(v) applyGuiScale(v); saveConfig() end)
			box.Text=tostring(guiScale)
			local hint=Instance.new("TextLabel",row)
			hint.Size=UDim2.new(0,60,1,0); hint.Position=UDim2.new(1,-115,0,0)
			hint.BackgroundTransparency=1; hint.Text="(0.3–3.0)"
			hint.TextColor3=GREY_DIM; hint.Font=Enum.Font.Bangers; hint.TextSize=8
			hint.TextXAlignment=Enum.TextXAlignment.Right
		end

		do
			local row=mkRow(settingsTab,30); mkLabel(row,"Mobile Scale")
			local box=mkBox(row,mbScale,44,52,function(v) applyMbScale(v); saveConfig() end)
			box.Text=tostring(mbScale)
			local hint=Instance.new("TextLabel",row)
			hint.Size=UDim2.new(0,60,1,0); hint.Position=UDim2.new(1,-115,0,0)
			hint.BackgroundTransparency=1; hint.Text="(0.3–3.0)"
			hint.TextColor3=GREY_DIM; hint.Font=Enum.Font.Bangers; hint.TextSize=8
			hint.TextXAlignment=Enum.TextXAlignment.Right
		end

		local resetRow=mkRow(settingsTab,30); mkLabel(resetRow,"Reset Sizes")
		local resetBtn=Instance.new("TextButton",resetRow)
		resetBtn.Size=UDim2.new(0,60,0,20); resetBtn.Position=UDim2.new(1,-66,0.5,-10)
		resetBtn.BackgroundColor3=Color3.fromRGB(30,30,30); resetBtn.BorderSizePixel=0
		resetBtn.Text="RESET"; resetBtn.TextColor3=GREY; resetBtn.Font=Enum.Font.Bangers; resetBtn.TextSize=10
		Instance.new("UICorner",resetBtn).CornerRadius=UDim.new(0,8)
		addAnimatedStroke(resetBtn,GREY_DIM,1)
		resetBtn.MouseButton1Click:Connect(function() applyGuiScale(1.0); applyMbScale(1.0); saveConfig() end)

		-- Lock UI in Settings
		local lockRow=mkRow(settingsTab,30); mkLabel(lockRow,"Lock UI")
		local lockPill,lockDot=mkPill(lockRow,46); local lockOn=guiLocked
		local function updateLockVisual(s) lockOn=s; animPill(lockPill,lockDot,s) end
		updateLockVisual(guiLocked)
		local lockClk=Instance.new("TextButton",lockPill)
		lockClk.Size=UDim2.new(1,0,1,0); lockClk.BackgroundTransparency=1; lockClk.Text=""; lockClk.ZIndex=5
		lockClk.Activated:Connect(function()
			if _anyKeyListening then return end; guiLocked=not guiLocked; updateLockVisual(guiLocked); saveConfig()
		end)

		-- Intro Animation in Settings
		setIntroToggleVisual=mkToggle(settingsTab,"Intro Animation",function(on) introEnabled=on; saveConfig() end)

		local infoFrame=Instance.new("Frame",settingsTab)
		infoFrame.Size=UDim2.new(1,0,0,40); infoFrame.BackgroundTransparency=1; infoFrame.LayoutOrder=LO()
		local infoLbl=Instance.new("TextLabel",infoFrame)
		infoLbl.Size=UDim2.new(1,0,1,0); infoLbl.BackgroundTransparency=1
		infoLbl.Text="1.0 = default size\n0.5 = half size\n2.0 = double size"
		infoLbl.TextColor3=GREY_DIM; infoLbl.Font=Enum.Font.Bangers; infoLbl.TextSize=9
		infoLbl.TextXAlignment=Enum.TextXAlignment.Left; infoLbl.TextWrapped=true

		local credRow=Instance.new("Frame",settingsTab)
		credRow.Size=UDim2.new(1,0,0,25); credRow.BackgroundTransparency=1; credRow.LayoutOrder=LO()
		local credLbl=Instance.new("TextLabel",credRow)
		credLbl.Size=UDim2.new(1,0,1,0); credLbl.BackgroundTransparency=1
		credLbl.Text="made by hz and reaper"; credLbl.TextColor3=BLUE_TEXT
		credLbl.Font=Enum.Font.Bangers; credLbl.TextSize=9; credLbl.TextXAlignment=Enum.TextXAlignment.Center
	end

	-- Global keybinds
	UIS.InputBegan:Connect(function(input,gpe)
		if _anyKeyListening then return end
		if input.UserInputType==Enum.UserInputType.Keyboard then
			if gpe or UIS:GetFocusedTextBox() then return end
		elseif not isGamepadInput(input) then return end
		if not isBindableInput(input) then return end
		local kc=input.KeyCode
		if kbMatch(KB.LaggerToggle,kc) then toggleLaggerMode(); saveConfig()
		elseif kbMatch(KB.SpeedToggle,kc) then toggleCarryMode(); saveConfig()
		elseif kbMatch(KB.DropBrainrot,kc) then runDrop()
		elseif kbMatch(KB.TPFloor,kc) then runTPFloor()
		elseif kbMatch(KB.InstaReset,kc) then task.spawn(cursedInstaReset)
		elseif kbMatch(KB.AutoLeft,kc) then
			autoLeftEnabled=not autoLeftEnabled
			if autoLeftEnabled then queueAutoLeftStart() else stopAutoLeft() end
			if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		elseif kbMatch(KB.AutoRight,kc) then
			autoRightEnabled=not autoRightEnabled
			if autoRightEnabled then queueAutoRightStart() else stopAutoRight() end
			if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		elseif kbMatch(KB.AutoBat,kc) then
			if not autoBatEnabled then queueAutoBatStart(); if autoBatSetVisual then autoBatSetVisual(true) end
			else disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
		elseif kbMatch(KB.Aimbot2,kc) then
			if not aimbot2Enabled then queueAimbot2Start(); if aimbot2SetVisual then aimbot2SetVisual(true) end
			else disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
		elseif kbMatch(KB.GuiHide,kc) then if main.Visible then hideGui() else showGui() end
		end
	end)

	switchTab("Combat")

	-- ── MOBILE PANEL ──
	local MB_BTN_SIZE = math.floor(55*mbScale)
	local MB_PAD = math.floor(8*mbScale)
	local MB_COLS = 2
	local MB_ROWS = 6
	local MBTOTALW = MB_COLS*MB_BTN_SIZE + (MB_COLS+1)*MB_PAD
	local MBTOTALH = MB_ROWS*MB_BTN_SIZE + (MB_ROWS+1)*MB_PAD
	local OUTLINE_COLOR = Color3.fromRGB(160,160,160)
	local OUTLINE_HOVER = Color3.fromRGB(210,210,210)
	local MB_TEXT_CLR  = Color3.fromRGB(220,220,220)
	local MB_ACTIVE    = Color3.fromRGB(80,80,80)
	local MB_NORMAL    = Color3.fromRGB(0,0,0)
	local MB_FLASH     = Color3.fromRGB(140,140,140)

	local oldMb = game:GetService("CoreGui"):FindFirstChild("ReaperMobile")
	if oldMb then oldMb:Destroy() end
	local mbPg = LP:FindFirstChild("PlayerGui")
	if mbPg then local o = mbPg:FindFirstChild("ReaperMobile"); if o then o:Destroy() end end

	local mbGui = Instance.new("ScreenGui")
	mbGui.Name = "ReaperMobile"; mbGui.ResetOnSpawn = false; mbGui.DisplayOrder = 10; mbGui.IgnoreGuiInset = true
	if not pcall(function() mbGui.Parent = game:GetService("CoreGui") end) then
		mbGui.Parent = LP:WaitForChild("PlayerGui")
	end

	local mbPanel = Instance.new("Frame", mbGui)
	mbPanel.Name = "MobilePanel"
	mbPanel.Size = UDim2.new(0, MBTOTALW, 0, MBTOTALH)
	mbPanel.Position = savedPos("mbPosXS","mbPosXO","mbPosYS","mbPosYO", UDim2.new(1,-(MBTOTALW+15),0.5,-(MBTOTALH/2)))
	mbPanel.BackgroundTransparency = 1
	mbPanel.BorderSizePixel = 0
	mbPanel.Active = true
	mbPanel.ZIndex = 50
	_mbPanel = mbPanel

	local gv2 = getgenv and getgenv(); if gv2 then gv2._reaper_mbPos = mbPanel.Position end

	do
		local dn,ds,sp = false
		mbPanel.InputBegan:Connect(function(i)
			if guiLocked then return end
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dn=true; ds=i.Position; sp=mbPanel.Position
				i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dn=false end end)
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if dn and not guiLocked then
				if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
					local delta = i.Position - ds
					mbPanel.Position = UDim2.new(sp.X.Scale, sp.X.Offset+delta.X, sp.Y.Scale, sp.Y.Offset+delta.Y)
					local gv = getgenv and getgenv(); if gv then gv._reaper_mbPos = mbPanel.Position end
				end
			end
		end)
	end

	local function makeMobileBtn(label, row, col)
		local x = MB_PAD + (col-1)*(MB_BTN_SIZE+MB_PAD)
		local y = MB_PAD + (row-1)*(MB_BTN_SIZE+MB_PAD)
		local btn = Instance.new("TextButton", mbPanel)
		btn.Size = UDim2.new(0, MB_BTN_SIZE, 0, MB_BTN_SIZE)
		btn.Position = UDim2.new(0, x, 0, y)
		btn.BackgroundColor3 = MB_NORMAL
		btn.BorderSizePixel = 0
		btn.Text = label
		btn.TextColor3 = MB_TEXT_CLR
		btn.Font = Enum.Font.Bangers
		btn.TextSize = 11
		btn.TextWrapped = true
		btn.ZIndex = 52
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
		local outline = Instance.new("UIStroke", btn)
		outline.Color = OUTLINE_COLOR; outline.Thickness = 2; outline.Transparency = 0
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btn.MouseButton1Down:Connect(function()
			if btn.BackgroundColor3 == MB_NORMAL then
				TS:Create(btn, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(25,25,25)}):Play()
			end
		end)
		btn.MouseButton1Up:Connect(function()
			if btn.BackgroundColor3 ~= MB_ACTIVE then
				TS:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = MB_NORMAL}):Play()
			end
		end)
		btn.MouseEnter:Connect(function() TS:Create(outline, TweenInfo.new(0.1), {Color=OUTLINE_HOVER, Thickness=2.5}):Play() end)
		btn.MouseLeave:Connect(function() TS:Create(outline, TweenInfo.new(0.1), {Color=OUTLINE_COLOR, Thickness=2}):Play() end)
		return btn
	end

	local function setToggleBG(btn, active)
		TS:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = active and MB_ACTIVE or MB_NORMAL}):Play()
	end
	local function flashBG(btn)
		TS:Create(btn, TweenInfo.new(0.05), {BackgroundColor3 = MB_FLASH}):Play()
		task.delay(0.15, function() TS:Create(btn, TweenInfo.new(0.05), {BackgroundColor3 = MB_NORMAL}):Play() end)
	end

	-- Row 1: Aimbot 2 | Drop BR
	-- Row 2: Auto Left | Auto Bat
	-- Row 3: Auto Right | TP Down
	-- Row 4: Lagger Carry | Carry Spd
	-- Row 5: Lagger Mode | Insta Reset
	local aimbot2Btn     = makeMobileBtn("AIMBOT\n2",       1,1)
	local dropBtn        = makeMobileBtn("DROP\nBR",         1,2)
	local autoLeftBtn    = makeMobileBtn("AUTO\nLEFT",       2,1)
	local autoBatBtn     = makeMobileBtn("AUTO\nBAT",        2,2)
	local autoRightBtn   = makeMobileBtn("AUTO\nRIGHT",      3,1)
	local tpDownBtn      = makeMobileBtn("TP\nDOWN",         3,2)
	local laggerCarryBtn = makeMobileBtn("LAGGER\nCARRY",    4,1)
	local carrySpeedBtn  = makeMobileBtn("CARRY\nSPD",       4,2)
	local laggerModeBtn  = makeMobileBtn("LAGGER\nMODE",     5,1)
	local instaResetBtn  = makeMobileBtn("INSTA\nRESET",     5,2)

	dropBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end; flashBG(dropBtn); task.spawn(runDrop)
	end)
	tpDownBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end; flashBG(tpDownBtn); task.spawn(runTPFloor)
	end)
	instaResetBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end; flashBG(instaResetBtn); task.spawn(cursedInstaReset)
	end)

	local _origAutoLeftSetVisual = autoLeftSetVisual
	autoLeftSetVisual = function(s)
		if _origAutoLeftSetVisual then _origAutoLeftSetVisual(s) end
		setToggleBG(autoLeftBtn, s)
	end
	local _origAutoRightSetVisual = autoRightSetVisual
	autoRightSetVisual = function(s)
		if _origAutoRightSetVisual then _origAutoRightSetVisual(s) end
		setToggleBG(autoRightBtn, s)
	end
	local _origAutoBatSetVisual = autoBatSetVisual
	autoBatSetVisual = function(s)
		if _origAutoBatSetVisual then _origAutoBatSetVisual(s) end
		setToggleBG(autoBatBtn, s)
	end
	local _origAimbot2SetVisual = aimbot2SetVisual
	aimbot2SetVisual = function(s)
		if _origAimbot2SetVisual then _origAimbot2SetVisual(s) end
		setToggleBG(aimbot2Btn, s)
	end
	setCarrySpeedVisual  = function(s) setToggleBG(carrySpeedBtn, s) end
	setLaggerCarryVisual = function(s) setToggleBG(laggerCarryBtn, s) end

	local _prevLaggerModeVisual2 = setLaggerModeVisual
	setLaggerModeVisual = function(s)
		if _prevLaggerModeVisual2 then _prevLaggerModeVisual2(s) end
		setToggleBG(laggerModeBtn, s)
		if setLaggerModeTabVisual then setLaggerModeTabVisual(s) end
	end

	aimbot2Btn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
		if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
		if autoBatEnabled then disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
		aimbot2Enabled = not aimbot2Enabled
		if aimbot2SetVisual then aimbot2SetVisual(aimbot2Enabled) end
		if aimbot2Enabled then queueAimbot2Start() else disableAimbot2() end
		saveConfig()
	end)
	autoLeftBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
		if autoBatEnabled then disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
		if aimbot2Enabled then disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
		autoLeftEnabled = not autoLeftEnabled
		if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		if autoLeftEnabled then queueAutoLeftStart() else stopAutoLeft() end
		saveConfig()
	end)
	autoBatBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
		if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
		if aimbot2Enabled then disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
		autoBatEnabled = not autoBatEnabled
		if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
		if autoBatEnabled then queueAutoBatStart() else disableAutoBat() end
		saveConfig()
	end)
	autoRightBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
		if autoBatEnabled then disableAutoBat(); if autoBatSetVisual then autoBatSetVisual(false) end end
		if aimbot2Enabled then disableAimbot2(); if aimbot2SetVisual then aimbot2SetVisual(false) end end
		autoRightEnabled = not autoRightEnabled
		if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		if autoRightEnabled then queueAutoRightStart() else stopAutoRight() end
		saveConfig()
	end)
	carrySpeedBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if not speedMode then
			if laggerToggled then
				laggerToggled=false; laggerPhase=0
				if setLaggerModeVisual then setLaggerModeVisual(false) end
				if setLaggerCarryVisual then setLaggerCarryVisual(false) end
			end
			speedMode = true
		else speedMode = false end
		setToggleBG(carrySpeedBtn, speedMode)
		refreshSpeedModeLabel(); saveConfig()
	end)
	laggerCarryBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if laggerToggled and laggerPhase==2 then
			laggerToggled=false; laggerPhase=0; setToggleBG(laggerCarryBtn, false)
			if setLaggerModeVisual then setLaggerModeVisual(false) end
		else
			if speedMode then speedMode=false; setToggleBG(carrySpeedBtn, false) end
			laggerToggled=true; laggerPhase=2
			setToggleBG(laggerCarryBtn, true)
			if setLaggerModeVisual then setLaggerModeVisual(true) end
		end
		refreshSpeedModeLabel(); saveConfig()
	end)

	laggerModeBtn.MouseButton1Click:Connect(function()
		if _anyKeyListening then return end
		if laggerToggled and laggerPhase == 1 then
			laggerToggled = false; laggerPhase = 0
			setToggleBG(laggerModeBtn, false)
			if setLaggerCarryVisual then setLaggerCarryVisual(false) end
		else
			if speedMode then speedMode = false; setToggleBG(carrySpeedBtn, false) end
			if laggerPhase == 2 then setToggleBG(laggerCarryBtn, false) end
			laggerToggled = true; laggerPhase = 1
			setToggleBG(laggerModeBtn, true)
		end
		if setLaggerModeTabVisual then setLaggerModeTabVisual(laggerToggled and laggerPhase==1) end
		refreshSpeedModeLabel(); saveConfig()
	end)
end

local _savedCfg=nil
local function loadConfigKeys()
	if not(isfile and isfile("reaper_config.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("reaper_config.json")) end)
	if not ok or not cfg then return end
	_savedCfg=cfg
	local function lk(e,d) if type(d)~="table" then return end; if d.kb and Enum.KeyCode[d.kb] then e.kb=Enum.KeyCode[d.kb] end; if d.gp and Enum.KeyCode[d.gp] then e.gp=Enum.KeyCode[d.gp] end end
	lk(KB.DropBrainrot,cfg.dropBrainrotKey); lk(KB.AutoLeft,cfg.autoLeftKey); lk(KB.AutoRight,cfg.autoRightKey)
	lk(KB.AutoBat,cfg.autoBatKey); lk(KB.LaggerToggle,cfg.laggerToggleKey)
	lk(KB.TPFloor,cfg.tpFloorKey); lk(KB.GuiHide,cfg.guiHideKey); lk(KB.SpeedToggle,cfg.speedToggleKey)
	lk(KB.InstaReset,cfg.instaResetKey)
	if cfg.aimbot2Key then lk(KB.Aimbot2,cfg.aimbot2Key) end
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.grabRadius and type(cfg.grabRadius)=="number" then Steal.StealRadius=cfg.grabRadius else Steal.StealRadius=60 end
	if cfg.stealDuration and type(cfg.stealDuration)=="number" then Steal.StealDuration=cfg.stealDuration else Steal.StealDuration=1.4 end
	if cfg.laggerSpeed and type(cfg.laggerSpeed)=="number" then LAGGER_SPEED=cfg.laggerSpeed end
	if cfg.laggerCarrySpeed and type(cfg.laggerCarrySpeed)=="number" then LAGGER_CARRY_SPEED=cfg.laggerCarrySpeed end
	if cfg.autoTPHeight and type(cfg.autoTPHeight)=="number" then autoTPHeight=cfg.autoTPHeight end
	if cfg.autoSwing~=nil then autoSwingEnabled=cfg.autoSwing==true end
	if cfg.guiLocked~=nil then guiLocked=cfg.guiLocked end
	if cfg.introEnabled~=nil then introEnabled=cfg.introEnabled end
	if cfg.guiScale and type(cfg.guiScale)=="number" then guiScale=math.clamp(cfg.guiScale,0.3,3.0) end
	if cfg.mbScale and type(cfg.mbScale)=="number" then mbScale=math.clamp(cfg.mbScale,0.3,3.0) end
	if cfg.autoMedReset~=nil then autoMedResetEnabled=cfg.autoMedReset end
end
local function loadConfigState()
	local cfg=_savedCfg; if not cfg then return end
	if normalBox then normalBox.Text=tostring(NS) end
	if carryBox then carryBox.Text=tostring(CS) end
	if radInput then radInput.Text=tostring(Steal.StealRadius) end
	if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius) end
	if laggerBox then laggerBox.Text=tostring(LAGGER_SPEED) end
	if laggerCarryBox then laggerCarryBox.Text=tostring(LAGGER_CARRY_SPEED) end
	if autoTPHeightBox then autoTPHeightBox.Text=tostring(autoTPHeight) end
	if setIntroToggleVisual then setIntroToggleVisual(introEnabled) end
	if setAutoMedResetVisual then setAutoMedResetVisual(autoMedResetEnabled) end
	task.spawn(function()
		task.wait(0.15)
		if cfg.antiRagdoll then antiRagdollEnabled=true; if setAntiRagVisual then setAntiRagVisual(true) end; startAntiRagdoll() end
		if cfg.autoStealEnabled then Steal.AutoStealEnabled=true; if setInstaGrab then setInstaGrab(true) end; pcall(startAutoSteal) end
		if cfg.infiniteJump then infJumpEnabled=true; if setInfJumpVisual then setInfJumpVisual(true) end end
		if cfg.medusaCounter then medusaCounterEnabled=true; if setMedusaVisual then setMedusaVisual(true) end; setupMedusa(LP.Character) end
		if cfg.batCounter then batCounterEnabled=true; if setBatCounterVisual then setBatCounterVisual(true) end; startBatCounter() end
		if cfg.autoMedReset then autoMedResetEnabled=true; if setAutoMedResetVisual then setAutoMedResetVisual(true) end; startAutoMedReset() end
		if cfg.laggerMode then
			speedMode=false; laggerToggled=true; laggerPhase=cfg.laggerCarryMode and 2 or 1
			if setLaggerModeVisual then setLaggerModeVisual(laggerPhase==1) end
			if setLaggerCarryVisual then setLaggerCarryVisual(laggerPhase==2) end
			refreshSpeedModeLabel()
		elseif cfg.carryMode then
			laggerToggled=false; laggerPhase=0; speedMode=true
			if setCarrySpeedVisual then setCarrySpeedVisual(true) end; refreshSpeedModeLabel()
		end
		if cfg.autoTPEnabled then autoTPEnabled=true; if setAutoTPVisual then setAutoTPVisual(true) end; startAutoTP() end
		if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
		if cfg.autoBat then autoBatEnabled=true; if autoBatSetVisual then autoBatSetVisual(true) end; queueAutoBatStart() end
		if cfg.aimbot2 then aimbot2Enabled=true; if aimbot2SetVisual then aimbot2SetVisual(true) end; queueAimbot2Start() end
		if cfg.unwalkEnabled then unwalkEnabled=true; if setUnwalkVisual then setUnwalkVisual(true) end; task.spawn(function() task.wait(0.5); startUnwalk() end) end
		if cfg.antiLag then enableAntiLag(); if setAntiLagVisual then setAntiLagVisual(true) end end
		if cfg.stretchRez then enableStretchRez(); if setStretchRezVisual then setStretchRezVisual(true) end end
	end)
end

pcall(function()
	if hookfunction and newcclosure then
		local oldFire
		oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
			if not cursedResetRemote and typeof(self) == "Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3) == "RE/" then
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
		if desc:IsA("RemoteEvent") and desc.Name:sub(1,3) == "RE/" then
			cursedResetRemote = desc
			break
		end
	end
end)

loadConfigKeys()
buildGui()
loadConfigState()

print("Reaper Hub Loaded - made by hz and reaper")
