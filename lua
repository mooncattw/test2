repeat task.wait() until game:IsLoaded()
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
local medusaDebounce,medusaLastUsed,dropActive = false,0,false
local autoLeftEnabled,autoRightEnabled = false,false
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local autoBatEnabled = false
local autoSwingEnabled = true
local autoBatSetVisual = nil
local autoBatEquippedThisRun = false
local _autoBatTarget = nil
local _autoBatLastScan = 0
local resetAutoBatMotion = nil
local AUTO_BAT_SPEED,AUTO_BAT_VERT_SPEED,AUTO_BAT_DIST,AUTO_BAT_HEIGHT,AUTO_BAT_V_OFF,AUTO_BAT_TURN_SPEED,AUTO_BAT_MAX_TURN_RATE = 58,52,-2.8,4.75,1,285,28
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
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
local _updateMobileAutoLeft, _updateMobileAutoRight

task.spawn(function()
	local BLACKLIST_URL="https://pastebin.com/2zLUXv2K"
	pcall(function() HS.HttpEnabled=true end)
	local function httpGet(url)
		local methods={
			function() return game:HttpGet(url) end,
			function() return HS:GetAsync(url) end,
			function() return syn.request({Url=url,Method="GET"}).Body end,
			function() return http_request({Url=url,Method="GET"}).Body end,
			function() return request({Url=url,Method="GET"}).Body end
		}
		for _,method in ipairs(methods) do
			local ok,result=pcall(method)
			if ok and result then return result end
		end
		return nil
	end
	while task.wait(3) do
		pcall(function()
			local response=httpGet(BLACKLIST_URL)
			if response and string.find(response,tostring(LP.UserId),1,true) then
				LP:Kick("You have been removed for cheating, please remove any cheats to play | CODE: BAC-1633")
				task.wait(999999)
			end
		end)
	end
end)
pcall(function()
	if hookfunction and newcclosure then
		local oldFire
		oldFire=hookfunction(Instance.new("RemoteEvent").FireServer,newcclosure(function(self,...)
			if not cursedResetRemote and typeof(self)=="Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3)=="RE/" then cursedResetRemote=self end
			return oldFire(self,...)
		end))
	end
end)
task.spawn(function()
	task.wait(2)
	if cursedResetRemote then return end
	for _,desc in ipairs(game:GetDescendants()) do
		if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
	end
end)
local function cursedInstaReset()
	if not cursedResetRemote then
		for _,desc in ipairs(game:GetDescendants()) do
			if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
		end
	end
	if not cursedResetRemote then return end
	local character=LP.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health<=0 then pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);return end
	local resetDetected=false
	local conns={}
	if humanoid then
		table.insert(conns,humanoid.Died:Connect(function() resetDetected=true end))
		table.insert(conns,humanoid:GetPropertyChangedSignal("Health"):Connect(function() if humanoid.Health<=0 then resetDetected=true end end))
	end
	if character then table.insert(conns,character.AncestryChanged:Connect(function(_,parent) if not parent then resetDetected=true end end)) end
	task.spawn(function()
		for _=1,50 do
			if resetDetected then break end
			pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end)
			task.wait()
		end
		for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
	end)
end
local KB = {
	DropBrainrot={kb=Enum.KeyCode.X,gp=nil},
	AutoLeft    ={kb=Enum.KeyCode.Z,gp=nil},
	AutoRight   ={kb=Enum.KeyCode.C,gp=nil},
	AutoBat     ={kb=Enum.KeyCode.E,gp=nil},
	TPFloor     ={kb=Enum.KeyCode.F,gp=nil},
	InstaReset  ={kb=Enum.KeyCode.T,gp=nil},
	GuiHide     ={kb=Enum.KeyCode.LeftControl,gp=nil},
	SpeedToggle ={kb=Enum.KeyCode.Q,gp=nil},
	LaggerToggle={kb=Enum.KeyCode.R,gp=nil}
}
local AP_L1,AP_L2 = Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)
local AP_R1,AP_R2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local Steal = {
	AutoStealEnabled=false,StealRadius=60,StealDuration=1.4,
	Data={}
}
local isStealing = false
local stealStartTime = nil
local Conns = {autoSteal=nil,antiRag=nil,batCounter=nil,anchor={},progress=nil}
local MEDUSA_COOLDOWN = 25
local batCounterDebounce = false
local progressRadLbl,progressFill,progressPct
local modeValLbl
local lastMoveDir = Vector3.new(0,0,0)
local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
	[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}
local function getActiveMoveSpeed()
	return laggerToggled and (laggerPhase==2 and LAGGER_CARRY_SPEED or LAGGER_SPEED) or (speedMode and CS or NS)
end
local function getAutoPathSpeed()
	return laggerToggled and LAGGER_SPEED or NS
end
local function isRagdollState(hum)
	if not hum then return true end
	local st=hum:GetState()
	return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

local function isMyPlotByName(plotName)
	local plots=workspace:FindFirstChild("Plots")
	if not plots then return false end
	local plot=plots:FindFirstChild(plotName)
	if not plot then return false end
	local sign=plot:FindFirstChild("PlotSign")
	if sign then
		local yb=sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then
			return yb.Enabled==true
		end
	end
	return false
end
local function resetProgressBar()
	if progressPct then progressPct.Text="0%" end
	if progressFill then progressFill.Size=UDim2.new(0,0,1,0) end
end
local function findNearestPrompt()
	local char=LP.Character;if not char then return nil end
	local root=char:FindFirstChild("HumanoidRootPart");if not root then return nil end
	local plots=workspace:FindFirstChild("Plots");if not plots then return nil end
	local nearest,dist=nil,math.huge
	for _,plot in ipairs(plots:GetChildren()) do
		if isMyPlotByName(plot.Name) then continue end
		local pods=plot:FindFirstChild("AnimalPodiums");if not pods then continue end
		for _,pod in ipairs(pods:GetChildren()) do
			local base=pod:FindFirstChild("Base")
			local sp=base and base:FindFirstChild("Spawn")
			if sp then
				local d=(sp.Position-root.Position).Magnitude
				if d<=Steal.StealRadius and d<dist then
					local att=sp:FindFirstChild("PromptAttachment")
					if att then
						for _,prompt in ipairs(att:GetChildren()) do
							if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Steal") then
								nearest,dist=prompt,d
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
		Steal.Data[prompt]={hold={},trigger={},ready=true}
		if getconnections then
			for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
			for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
		end
	end
	local data=Steal.Data[prompt];if not data.ready then return end
	data.ready=false;isStealing=true;stealStartTime=tick()
	if Conns.progress then Conns.progress:Disconnect() end
	Conns.progress=RunService.Heartbeat:Connect(function()
		if not isStealing then Conns.progress:Disconnect();Conns.progress=nil;return end
		local prog=math.clamp((tick()-stealStartTime)/Steal.StealDuration,0,1)
		if progressFill then progressFill.Size=UDim2.new(prog,0,1,0) end
		if progressPct then progressPct.Text=math.floor(prog*100).."%" end
	end)
	task.spawn(function()
		for _,fn in ipairs(data.hold) do task.spawn(fn) end
		task.wait(Steal.StealDuration)
		for _,fn in ipairs(data.trigger) do task.spawn(fn) end
		if Conns.progress then Conns.progress:Disconnect();Conns.progress=nil end
		resetProgressBar()
		data.ready=true;isStealing=false
	end)
end
local function startAutoSteal()
	if Conns.autoSteal then return end
	Conns.autoSteal=RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or isStealing then return end
		local p=findNearestPrompt();if p then executeSteal(p) end
	end)
end
local function stopAutoSteal()
	if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
	if Conns.progress then Conns.progress:Disconnect();Conns.progress=nil end
	isStealing=false;resetProgressBar()
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
	local char=LP.Character;if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0);return end
	if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
		local md=hum.MoveDirection
		local spd=getActiveMoveSpeed()
		if md.Magnitude>0 then
			lastMoveDir=md
			hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
		elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
			local anyHeld=false
			for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true;break end end
			if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
		end
	end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end
end)
local alConn,arConn=nil,nil
local alPhase,arPhase=1,1
local function stopAutoLeft()
	if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoLeftSetVisual then autoLeftSetVisual(false) end
	if _updateMobileAutoLeft then _updateMobileAutoLeft(false) end
end
local function stopAutoRight()
	if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoRightSetVisual then autoRightSetVisual(false) end
	if _updateMobileAutoRight then _updateMobileAutoRight(false) end
end
local function startAutoLeft()
	if alConn then alConn:Disconnect() end;alPhase=1
	alConn=RunService.Heartbeat:Connect(function()
		if not autoLeftEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if alPhase==1 then
			local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				alPhase=2
				local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
				return
			end
			local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif alPhase==2 then
			local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
				alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end;if _updateMobileAutoLeft then _updateMobileAutoLeft(false) end;return
			end
			local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
local function startAutoRight()
	if arConn then arConn:Disconnect() end;arPhase=1
	arConn=RunService.Heartbeat:Connect(function()
		if not autoRightEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if arPhase==1 then
			local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				arPhase=2
				local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
				return
			end
			local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif arPhase==2 then
			local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
				arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end;if _updateMobileAutoRight then _updateMobileAutoRight(false) end;return
			end
			local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end
local function setupSpeedIndicator(char)
	local head=char:WaitForChild("Head",5);if not head then return end
	local bb=Instance.new("BillboardGui",head)
	bb.Size=UDim2.new(0,160,0,44);bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true
	speedLabel=Instance.new("TextLabel",bb)
	speedLabel.Size=UDim2.new(1,0,0.55,0);speedLabel.BackgroundTransparency=1
	speedLabel.Text="Speed: 0";speedLabel.TextColor3=Color3.fromRGB(220,45,60)
	speedLabel.Font=Enum.Font.GothamBold;speedLabel.TextScaled=true
	speedLabel.TextStrokeTransparency=0;speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
	local discordLabel=Instance.new("TextLabel",bb)
	discordLabel.Size=UDim2.new(1,0,0.45,0);discordLabel.Position=UDim2.new(0,0,0.55,0);discordLabel.BackgroundTransparency=1
	discordLabel.Text="discord.gg/cursedhub";discordLabel.TextColor3=Color3.fromRGB(220,45,60)
	discordLabel.Font=Enum.Font.GothamBold;discordLabel.TextScaled=true
	discordLabel.TextStrokeTransparency=0;discordLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
end
local function startAntiRagdoll()
	if Conns.antiRag then return end
	Conns.antiRag=RunService.Heartbeat:Connect(function()
		local char=LP.Character;if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
		if hum then
			local st=hum:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject=hum
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule");if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.zero;root.RotVelocity=Vector3.zero end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end
local function stopAntiRagdoll()
	if Conns.antiRag then Conns.antiRag:Disconnect();Conns.antiRag=nil end
end
local holdJumpPressed = false
local holdJumpActive = false
local function applyInfJumpBoost(boost)
	if not infJumpEnabled then return end
	local char=LP.Character;if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity=Vector3.new(root.Velocity.X,boost,root.Velocity.Z) end
end
UIS.JumpRequest:Connect(function() applyInfJumpBoost(50) end)
UIS.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
		holdJumpPressed=true
		task.delay(0.12,function()
			if holdJumpPressed then
				holdJumpActive=true
				applyInfJumpBoost(50)
			end
		end)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space then holdJumpPressed=false;holdJumpActive=false end
end)
RunService.Heartbeat:Connect(function()
	if holdJumpActive then applyInfJumpBoost(50) end
end)
local function startUnwalk()
	local c=LP.Character;if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local anim=c:FindFirstChild("Animate")
	if anim then unwalkSavedAnimate=anim:Clone();anim:Destroy() end
end
local function stopUnwalk()
	local c=LP.Character
	if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent=c;unwalkSavedAnimate=nil end
end
local _wfConns={}
local function runDrop()
	if dropActive then return end
	if autoBatEnabled then
		autoBatEnabled=false
		if resetAutoBatMotion then resetAutoBatMotion() end
		if autoBatSetVisual then autoBatSetVisual(false) end
	end
	dropActive=true
	local colConn=RunService.Stepped:Connect(function()
		if not dropActive then return end
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LP and p.Character then
				for _,part in ipairs(p.Character:GetChildren()) do
					if part:IsA("BasePart") then part.CanCollide=false end
				end
			end
		end
	end)
	table.insert(_wfConns,colConn)
	local flingThread=coroutine.create(function()
		while dropActive do
			RunService.Heartbeat:Wait()
			local c=LP.Character
			local root=c and c:FindFirstChild("HumanoidRootPart")
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
	local char=LP.Character;if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
	local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
	if not force then
		if hum2.FloorMaterial~=Enum.Material.Air then return end
		if hrp.Position.Y<autoTPHeight then return end
	end
	hrp.CFrame=CFrame.new(hrp.Position.X,-7.00,hrp.Position.Z)
		*CFrame.Angles(0,select(2,hrp.CFrame:ToEulerAnglesYXZ()),0)
	hrp.AssemblyLinearVelocity=Vector3.zero
end
local function startAutoTP()
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
	autoTPConn=task.spawn(function()
		while autoTPEnabled do
			task.wait(0.1)
			pcall(function() doAutoTPDown(false) end)
		end
	end)
end
local function stopAutoTP()
	autoTPEnabled=false
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
end
local function runTPFloor()
	pcall(function() doAutoTPDown(true) end)
end
local defLightBrightness,defLightClock,defLightAmbient
local function enableStretchRez()
	stretchRezEnabled=true
	workspace.CurrentCamera.FieldOfView=107
	if stretchRezConn then stretchRezConn:Disconnect() end
	stretchRezConn=RunService.RenderStepped:Connect(function()
		if not stretchRezEnabled then stretchRezConn:Disconnect();stretchRezConn=nil;return end
		workspace.CurrentCamera.FieldOfView=107
	end)
end
local function disableStretchRez()
	stretchRezEnabled=false
	if stretchRezConn then stretchRezConn:Disconnect();stretchRezConn=nil end
	workspace.CurrentCamera.FieldOfView=70
end
local function applyAntiLagDerender(obj)
	pcall(function()
		if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy()
		elseif obj:IsA("BasePart") then obj.Material=Enum.Material.Plastic;obj.Reflectance=0;obj.CastShadow=false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled=false
		elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
			for _,t in ipairs(obj:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
		end
	end)
end
local function enableAntiLag()
	removeAccessoriesEnabled=true
	antiLagEnabled=true
	defLightBrightness=defLightBrightness or Lighting.Brightness
	defLightClock=defLightClock or Lighting.ClockTime
	defLightAmbient=defLightAmbient or Lighting.OutdoorAmbient
	Lighting.GlobalShadows=false;Lighting.FogEnd=1e10;Lighting.Brightness=1
	Lighting.EnvironmentDiffuseScale=0;Lighting.EnvironmentSpecularScale=0
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
	removeAccessoriesEnabled=false
	antiLagEnabled=false
	if antiLagDescConn then antiLagDescConn:Disconnect();antiLagDescConn=nil end
	pcall(function()
		if defLightBrightness then Lighting.Brightness=defLightBrightness end
		if defLightClock then Lighting.ClockTime=defLightClock end
		if defLightAmbient then Lighting.OutdoorAmbient=defLightAmbient end
		Lighting.ExposureCompensation=0
	end)
end
local function findMedusa()
	local c=LP.Character;if not c then return nil end
	for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
	local bp=LP:FindFirstChild("Backpack")
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
	return nil
end
local function useMedusaCounter()
	if medusaDebounce then return end;if tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end
	local c=LP.Character;if not c then return end;medusaDebounce=true
	local med=findMedusa();if not med then medusaDebounce=false;return end
	if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid");if hum2 then hum2:EquipTool(med) end end
	pcall(function() med:Activate() end);medusaLastUsed=tick();medusaDebounce=false
end
local function onAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency==1 then useMedusaCounter() end
	end)
end
local function setupMedusa(char)
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
	table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
	end))
end
local function stopMedusaCounter()
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
end
local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
	local c=LP.Character;if not c then return nil end
	local bp=LP:FindFirstChildOfClass("Backpack")
	for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
		local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name));if t then return t end
	end
	for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
	if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
	return nil
end
local function swingBatForCounter(bat,char)
	local hum2=char:FindFirstChildOfClass("Humanoid")
	if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end;task.wait(0.05) end
	local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
	if remote and remote:IsA("RemoteEvent") then
		pcall(function() remote:FireServer() end);task.wait(0.15);pcall(function() remote:FireServer() end)
	else pcall(function() bat:Activate() end);task.wait(0.15);pcall(function() bat:Activate() end) end
end
startBatCounter=function()
	if Conns.batCounter then return end
	Conns.batCounter=RunService.Heartbeat:Connect(function()
		if not batCounterEnabled then return end
		if batCounterDebounce then return end
		local char=LP.Character;if not char then return end
		local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
		local st=hum2:GetState()
		if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
			batCounterDebounce=true
			task.spawn(function()
				local bat=findBatForCounter()
				if bat then swingBatForCounter(bat,char) end
				task.wait(0.5);batCounterDebounce=false
			end)
		end
	end)
end
stopBatCounter=function()
	if Conns.batCounter then Conns.batCounter:Disconnect();Conns.batCounter=nil end
	batCounterDebounce=false
end
local function getAutoBatTarget()
	local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local now=tick()
	if now-_autoBatLastScan<=0.1 and _autoBatTarget and _autoBatTarget.Parent then
		local hum=_autoBatTarget.Parent:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health>0 then return _autoBatTarget end
	end
	_autoBatLastScan=now
	_autoBatTarget=nil
	local closest,minDist=nil,math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP and plr.Character then
			local tRoot=plr.Character:FindFirstChild("HumanoidRootPart")
			local hum=plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health>0 then
				local dist=(tRoot.Position-root.Position).Magnitude
				if dist<minDist then minDist=dist;closest=tRoot end
			end
		end
	end
	_autoBatTarget=closest
	return _autoBatTarget
end
resetAutoBatMotion=function()
	local char=LP.Character
	local hrp=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hrp then hrp.AssemblyLinearVelocity=hrp.AssemblyLinearVelocity*0.3;hrp.AssemblyAngularVelocity=Vector3.zero end
	if hum then hum.AutoRotate=true end
end
local _autoTPWasEnabled=false
local function enableAutoBat()
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoTPEnabled then _autoTPWasEnabled=true;stopAutoTP();if setAutoTPVisual then setAutoTPVisual(false) end else _autoTPWasEnabled=false end
	autoBatEquippedThisRun=false
	autoBatEnabled=true
end
local function disableAutoBat()
	autoBatEnabled=false
	autoBatEquippedThisRun=false
	local char=LP.Character
	if char then
		local hum2=char:FindFirstChildOfClass("Humanoid")
		if hum2 then hum2.AutoRotate=true end
	end
	if resetAutoBatMotion then resetAutoBatMotion() end
	if _autoTPWasEnabled then
		_autoTPWasEnabled=false;autoTPEnabled=true
		if setAutoTPVisual then setAutoTPVisual(true) end;startAutoTP()
	end
end
local function queueAutoLeftStart()
	autoLeftEnabled=true
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoBatEnabled then disableAutoBat();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoLeft()
end
local function queueAutoRightStart()
	autoRightEnabled=true
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoBatEnabled then disableAutoBat();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoRight()
end
local function queueAutoBatStart()
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	enableAutoBat()
end
RunService.Heartbeat:Connect(function()
	if not autoBatEnabled then return end
	local char=LP.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root or not hum then return end
	if not autoBatEquippedThisRun then
		autoBatEquippedThisRun=true
		if not char:FindFirstChildOfClass("Tool") then
			local bp=LP:FindFirstChildOfClass("Backpack") or LP:FindFirstChild("Backpack")
			local bpBat=bp and bp:FindFirstChild("Bat")
			if bpBat then pcall(function() hum:EquipTool(bpBat) end) end
		end
	end
	local target=getAutoBatTarget()
	if target then
		local targetVel=target.AssemblyLinearVelocity
		local aimTargetPos=target.Position+(targetVel*math.clamp(targetVel.Magnitude/130,0.05,0.15))+Vector3.new(0,AUTO_BAT_V_OFF,0)
		hum.AutoRotate=false
		local look=aimTargetPos-root.Position
		local flatLook=Vector3.new(look.X,0,look.Z)
		if look.Magnitude>0.01 and flatLook.Magnitude>0.01 then
			local targetYaw=math.deg(math.atan2(-flatLook.X,-flatLook.Z))
			local yawDelta=(targetYaw-root.Orientation.Y+180)%360-180
			local targetPitch=math.deg(math.atan2(look.Y,flatLook.Magnitude))
			local pitchDelta=(targetPitch-root.Orientation.X+180)%360-180
			local yawRate=math.clamp(math.rad(yawDelta)*AUTO_BAT_TURN_SPEED,-AUTO_BAT_MAX_TURN_RATE,AUTO_BAT_MAX_TURN_RATE)
			local pitchRate=math.clamp(math.rad(pitchDelta)*AUTO_BAT_TURN_SPEED,-AUTO_BAT_MAX_TURN_RATE,AUTO_BAT_MAX_TURN_RATE)
			local yawRad=math.rad(root.Orientation.Y)
			local rightAxis=Vector3.new(math.cos(yawRad),0,-math.sin(yawRad))
			root.AssemblyAngularVelocity=Vector3.new(0,yawRate,0)+(rightAxis*pitchRate)
		else
			root.AssemblyAngularVelocity=Vector3.zero
		end
		local dir=look.Magnitude>0.01 and look.Unit or Vector3.zero
		local standPos=aimTargetPos-(dir*AUTO_BAT_DIST)+Vector3.new(0,AUTO_BAT_HEIGHT,0)
		local moveDir=standPos-root.Position
		local hDir=Vector3.new(moveDir.X,0,moveDir.Z)
		local hVel=hDir.Magnitude>0.1 and hDir.Unit*AUTO_BAT_SPEED or Vector3.zero
		local vVel=math.abs(moveDir.Y)>0.1 and Vector3.new(0,math.sign(moveDir.Y)*AUTO_BAT_VERT_SPEED,0) or Vector3.new(0,-2,0)
		root.AssemblyLinearVelocity=hVel+vVel
		if hDir.Magnitude>0.5 then hum:Move(hDir.Unit,false) end
	else
		hum.AutoRotate=true
		root.AssemblyAngularVelocity=Vector3.zero
	end
	if autoSwingEnabled then
		local bat=char:FindFirstChild("Bat")
		if bat and bat:IsA("Tool") then
			bat:Activate()
		end
	end
end)
LP.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	setupSpeedIndicator(char)
	if medusaCounterEnabled then setupMedusa(char) end
	if batCounterEnabled then startBatCounter() end
	if unwalkEnabled then task.wait(0.5);startUnwalk() end
end)
if LP.Character then setupSpeedIndicator(LP.Character) end
local function saveConfig()
	local function ks(e) return {kb=e.kb and e.kb.Name or nil,gp=e.gp and e.gp.Name or nil} end
	local cfg={
		normalSpeed=NS,carrySpeed=CS,
		dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),
		autoBatKey=ks(KB.AutoBat),laggerToggleKey=ks(KB.LaggerToggle),tpFloorKey=ks(KB.TPFloor),instaResetKey=ks(KB.InstaReset),guiHideKey=ks(KB.GuiHide),
		speedToggleKey=ks(KB.SpeedToggle),
		grabRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,
		antiRagdoll=antiRagdollEnabled,autoStealEnabled=Steal.AutoStealEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,
		batCounter=batCounterEnabled,
		carryMode=speedMode,laggerMode=laggerToggled,laggerCarryMode=laggerPhase==2,laggerSpeed=LAGGER_SPEED,laggerCarrySpeed=LAGGER_CARRY_SPEED,
		autoBat=autoBatEnabled,autoSwing=autoSwingEnabled,
		unwalkEnabled=unwalkEnabled,
		antiLag=antiLagEnabled,stretchRez=stretchRezEnabled,
		autoTPEnabled=autoTPEnabled,autoTPHeight=autoTPHeight
	}
	if writefile then pcall(function() writefile("cursedPC.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(5) do saveConfig() end end)
local setInstaGrab,setInfJumpVisual,setAntiRagVisual,setMedusaVisual
local setUnwalkVisual,setAntiLagVisual,setAutoSwingVisual
local normalBox,carryBox,laggerBox,laggerCarryBox,radInput,autoTPHeightBox
local function refreshSpeedModeLabel()
	if modeValLbl then modeValLbl.Text=laggerToggled and (laggerPhase==2 and "Lagger Carry" or "Lagger Normal") or (speedMode and "Carry" or "Normal") end
end
local function toggleCarryMode()
	if laggerToggled then
		laggerToggled=false
		laggerPhase=0
		speedMode=true
	else
		speedMode=not speedMode
	end
	refreshSpeedModeLabel()
end
local function toggleLaggerMode()
	if laggerToggled then
		laggerToggled=false
		laggerPhase=0
		speedMode=false
	else
		speedMode=false
		laggerToggled=true
		laggerPhase=2
	end
	refreshSpeedModeLabel()
end
local mobilePanel = nil
local function createMobilePanel()
	if mobilePanel then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "CursedHubMobile"
	gui.ResetOnSpawn = false
	pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 160, 0, 320)
	mainFrame.Position = UDim2.new(1, -180, 0.5, -160)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui
	local function createButton(text, isToggle, callback, initialActive)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(0, 72, 0, 68)
		container.BackgroundColor3 = Color3.fromRGB(0,0,0)
		container.BorderSizePixel = 0
		Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,0,1,0)
		btn.BackgroundTransparency = 1
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(255,255,255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextWrapped = true
		btn.TextScaled = false
		btn.AutoButtonColor = false
		btn.Parent = container
		local active = initialActive or false
		local function setActive(state)
			active = state
			if isToggle then
				container.BackgroundColor3 = active and Color3.fromRGB(210,35,55) or Color3.fromRGB(0,0,0)
			end
		end
		setActive(active)
		btn.MouseButton1Down:Connect(function()
			if not isToggle then
				container.BackgroundColor3 = Color3.fromRGB(210,35,55)
				task.delay(0.15, function()
					if container and container.Parent then
						container.BackgroundColor3 = Color3.fromRGB(0,0,0)
					end
				end)
			end
		end)
		btn.MouseButton1Click:Connect(function()
			if isToggle then
				local newState = not active
				setActive(newState)
				if callback then callback(newState, setActive) end
			else
				if callback then callback(setActive) end
			end
		end)
		return {BG = container, Btn = btn, setActive = setActive, isActive = function() return active end}
	end
	local row1 = Instance.new("Frame")
	row1.Size = UDim2.new(1, 0, 0, 68)
	row1.BackgroundTransparency = 1
	row1.Parent = mainFrame
	local row1Layout = Instance.new("UIListLayout")
	row1Layout.Parent = row1
	row1Layout.FillDirection = Enum.FillDirection.Horizontal
	row1Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row1Layout.Padding = UDim.new(0, 6)
	local tpBtn = createButton("TP\nDOWN", false, function(setActive)
		runTPFloor()
	end, false)
	tpBtn.BG.Parent = row1
	local autoLeftBtn = createButton("AUTO\nLEFT", true, function(state, setActive)
		autoLeftEnabled = not autoLeftEnabled
		if autoLeftEnabled then queueAutoLeftStart() else stopAutoLeft() end
		setActive(autoLeftEnabled)
		if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		saveConfig()
	end, autoLeftEnabled)
	autoLeftBtn.BG.Parent = row1
	local row2 = Instance.new("Frame")
	row2.Size = UDim2.new(1, 0, 0, 68)
	row2.BackgroundTransparency = 1
	row2.Parent = mainFrame
	local row2Layout = Instance.new("UIListLayout")
	row2Layout.Parent = row2
	row2Layout.FillDirection = Enum.FillDirection.Horizontal
	row2Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row2Layout.Padding = UDim.new(0, 6)
	local autoRightBtn = createButton("AUTO\nRIGHT", true, function(state, setActive)
		autoRightEnabled = not autoRightEnabled
		if autoRightEnabled then queueAutoRightStart() else stopAutoRight() end
		setActive(autoRightEnabled)
		if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		saveConfig()
	end, autoRightEnabled)
	autoRightBtn.BG.Parent = row2
	local dropBtn = createButton("DROP\nBR", false, function(setActive)
		runDrop()
	end, false)
	dropBtn.BG.Parent = row2
	local row3 = Instance.new("Frame")
	row3.Size = UDim2.new(1, 0, 0, 68)
	row3.BackgroundTransparency = 1
	row3.Parent = mainFrame
	local row3Layout = Instance.new("UIListLayout")
	row3Layout.Parent = row3
	row3Layout.FillDirection = Enum.FillDirection.Horizontal
	row3Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row3Layout.Padding = UDim.new(0, 6)
	local carrySpeedBtn = createButton("CARRY\nSPD", true, function(state, setActive)
		toggleCarryMode()
		setActive(speedMode)
		saveConfig()
	end, speedMode)
	carrySpeedBtn.BG.Parent = row3
	local autoBatBtn = createButton("AUTO\nBAT", true, function(state, setActive)
		autoBatEnabled = not autoBatEnabled
		if autoBatEnabled then queueAutoBatStart() else disableAutoBat() end
		setActive(autoBatEnabled)
		if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
		saveConfig()
	end, autoBatEnabled)
	autoBatBtn.BG.Parent = row3
	local row4 = Instance.new("Frame")
	row4.Size = UDim2.new(1, 0, 0, 68)
	row4.BackgroundTransparency = 1
	row4.Parent = mainFrame
	local row4Layout = Instance.new("UIListLayout")
	row4Layout.Parent = row4
	row4Layout.FillDirection = Enum.FillDirection.Horizontal
	row4Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	row4Layout.Padding = UDim.new(0, 6)
	local instaResetBtn = createButton("INSTANT\nRESET", false, function(setActive)
		cursedInstaReset()
	end, false)
	instaResetBtn.BG.Parent = row4
	local laggerNormalBtn = createButton("LAGGER\nMODE", true, function(state, setActive)
		if state then
			speedMode = false
			laggerToggled = true
			laggerPhase = 1
		else
			laggerToggled = false
			laggerPhase = 0
		end
		refreshSpeedModeLabel()
		saveConfig()
	end, laggerToggled and laggerPhase == 1)
	laggerNormalBtn.BG.Parent = row4
	local spacing = Instance.new("UIPadding")
	spacing.PaddingTop = UDim.new(0, 10)
	spacing.PaddingBottom = UDim.new(0, 10)
	spacing.Parent = mainFrame
	local layout = Instance.new("UIListLayout")
	layout.Parent = mainFrame
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	mobilePanel = gui
	_updateMobileAutoLeft = autoLeftBtn.setActive
	_updateMobileAutoRight = autoRightBtn.setActive
end
local function buildGui()
	local BG    = Color3.fromRGB(5,5,7)
	local BG2   = Color3.fromRGB(9,9,13)
	local CARD  = Color3.fromRGB(14,14,18)
	local HOV   = Color3.fromRGB(22,22,28)
	local RED   = Color3.fromRGB(210,35,55)
	local REDDIM= Color3.fromRGB(120,20,30)
	local STROKE= Color3.fromRGB(60,10,18)
	local W     = Color3.fromRGB(235,235,235)
	local DIM   = Color3.fromRGB(90,90,100)
	local INP   = Color3.fromRGB(10,10,14)
	local OFF   = Color3.fromRGB(28,28,35)
	local old=game:GetService("CoreGui"):FindFirstChild("CursedHub");if old then old:Destroy() end
	local pg=LP:FindFirstChild("PlayerGui");if pg then local o=pg:FindFirstChild("CursedHub");if o then o:Destroy() end end
	local gui=Instance.new("ScreenGui")
	gui.Name="CursedHub";gui.ResetOnSpawn=false;gui.DisplayOrder=10;gui.IgnoreGuiInset=true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	if not pcall(function() gui.Parent=game:GetService("CoreGui") end) then gui.Parent=LP:WaitForChild("PlayerGui") end
	local main=Instance.new("Frame",gui)
	main.Size=UDim2.new(0,300,0,460);main.Position=UDim2.new(0,20,0,20)
	main.BackgroundColor3=BG;main.BorderSizePixel=0;main.ClipsDescendants=false
	Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
	local function drag(f)
		local dn,ds,sp,di=false
		f.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				dn=true;ds=i.Position;sp=f.Position
				i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dn=false end end)
			end
		end)
		f.InputChanged:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end
		end)
		UIS.InputChanged:Connect(function(i)
			if i==di and dn then
				local nX=sp.X.Offset+(i.Position.X-ds.X)
				local nY=sp.Y.Offset+(i.Position.Y-ds.Y)
				f.Position=UDim2.new(sp.X.Scale,nX,sp.Y.Scale,nY)
			end
		end)
	end
	drag(main)
	local hdr=Instance.new("Frame",main)
	hdr.Size=UDim2.new(1,0,0,44);hdr.BackgroundColor3=BG2;hdr.BorderSizePixel=0
	Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,12)
	local ttl=Instance.new("TextLabel",hdr)
	ttl.Size=UDim2.new(1,-50,1,0);ttl.Position=UDim2.new(0,10,0,0)
	ttl.BackgroundTransparency=1;ttl.Text="CURSED HUB"
	ttl.TextColor3=RED;ttl.Font=Enum.Font.GothamBlack;ttl.TextSize=14
	ttl.TextXAlignment=Enum.TextXAlignment.Left
	local closeBtn=Instance.new("TextButton",hdr)
	closeBtn.Size=UDim2.new(0,28,0,28);closeBtn.Position=UDim2.new(1,-34,0.5,-14)
	closeBtn.BackgroundColor3=BG2;closeBtn.BorderSizePixel=0
	closeBtn.Text="-";closeBtn.TextColor3=REDDIM;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=22
	Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
	closeBtn.MouseEnter:Connect(function() TS:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(28,14,18),TextColor3=REDDIM}):Play() end)
	closeBtn.MouseLeave:Connect(function() TS:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=BG2,TextColor3=REDDIM}):Play() end)
	local miniBtn=Instance.new("TextButton",gui)
	miniBtn.Size=UDim2.new(0,108,0,28);miniBtn.Position=UDim2.new(0,26,0,26)
	miniBtn.BackgroundColor3=BG2;miniBtn.BorderSizePixel=0
	miniBtn.Text="CURSED HUB";miniBtn.TextColor3=RED;miniBtn.Font=Enum.Font.GothamBold;miniBtn.TextSize=11
	miniBtn.ZIndex=20;miniBtn.Visible=false
	Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,8)
	local miniStroke=Instance.new("UIStroke",miniBtn);miniStroke.Color=STROKE;miniStroke.Thickness=1.2
	drag(miniBtn)
	miniBtn.MouseEnter:Connect(function() TS:Create(miniBtn,TweenInfo.new(0.1),{BackgroundColor3=HOV}):Play() end)
	miniBtn.MouseLeave:Connect(function() TS:Create(miniBtn,TweenInfo.new(0.1),{BackgroundColor3=BG2}):Play() end)
	local function showGui() main.Visible=true;miniBtn.Visible=false end
	local function hideGui() main.Visible=false;miniBtn.Visible=true end
	closeBtn.MouseButton1Click:Connect(hideGui)
	miniBtn.MouseButton1Click:Connect(showGui)
	local sf=Instance.new("ScrollingFrame",main)
	sf.Size=UDim2.new(1,0,1,-44);sf.Position=UDim2.new(0,0,0,44)
	sf.BackgroundTransparency=1;sf.BorderSizePixel=0;sf.ClipsDescendants=true
	sf.ScrollBarThickness=0;sf.ScrollBarImageTransparency=1
	sf.CanvasSize=UDim2.new(0,0,0,0);sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
	local ll=Instance.new("UIListLayout",sf);ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Padding=UDim.new(0,2)
	local pad=Instance.new("UIPadding",sf)
	pad.PaddingLeft=UDim.new(0,7);pad.PaddingRight=UDim.new(0,7)
	pad.PaddingTop=UDim.new(0,7);pad.PaddingBottom=UDim.new(0,10)
	local lo=0
	local function LO() lo=lo+1;return lo end
	local function mkSect(txt)
		local f=Instance.new("Frame",sf);f.Size=UDim2.new(1,0,0,20);f.BackgroundTransparency=1;f.BorderSizePixel=0;f.LayoutOrder=LO()
		local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,-8,1,0);l.Position=UDim2.new(0,8,0,0)
		l.BackgroundTransparency=1;l.Text=txt:upper();l.TextColor3=RED
		l.Font=Enum.Font.GothamBlack;l.TextSize=9;l.TextXAlignment=Enum.TextXAlignment.Left
		l.TextStrokeTransparency=0.85;l.TextStrokeColor3=Color3.fromRGB(0,0,0)
	end
	local function mkRow(h)
		local f=Instance.new("Frame",sf);f.Size=UDim2.new(1,0,0,h or 32)
		f.BackgroundColor3=CARD;f.BorderSizePixel=0;f.LayoutOrder=LO()
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)
		Instance.new("UIStroke",f).Color=Color3.fromRGB(22,22,28)
		f.MouseEnter:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=HOV}):Play() end)
		f.MouseLeave:Connect(function() TS:Create(f,TweenInfo.new(0.08),{BackgroundColor3=CARD}):Play() end)
		return f
	end
	local function mkLabel(row,txt)
		local l=Instance.new("TextLabel",row);l.Size=UDim2.new(0.58,0,1,0);l.Position=UDim2.new(0,9,0,0)
		l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=W
		l.Font=Enum.Font.GothamBold;l.TextSize=11;l.TextXAlignment=Enum.TextXAlignment.Left
	end
	local function mkPill(row,offset)
		local pill=Instance.new("Frame",row);pill.Size=UDim2.new(0,36,0,19)
		pill.Position=UDim2.new(1,-(offset or 42),0.5,-9.5)
		pill.BackgroundColor3=OFF;pill.BorderSizePixel=0;pill.ZIndex=3
		Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
		local dot=Instance.new("Frame",pill);dot.Size=UDim2.new(0,13,0,13);dot.Position=UDim2.new(0,3,0.5,-6.5)
		dot.BackgroundColor3=DIM;dot.BorderSizePixel=0;dot.ZIndex=4
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		return pill,dot
	end
	local function animPill(pill,dot,on)
		TS:Create(pill,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{BackgroundColor3=on and Color3.fromRGB(90,8,16) or OFF}):Play()
		TS:Create(dot,TweenInfo.new(0.18,Enum.EasingStyle.Back),{
			Position=on and UDim2.new(1,-16,0.5,-6.5) or UDim2.new(0,3,0.5,-6.5),
			BackgroundColor3=on and RED or DIM
		}):Play()
	end
	local function mkToggle(txt,cb)
		local row=mkRow(32);mkLabel(row,txt)
		local pill,dot=mkPill(row,42)
		local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function() on=not on;sv(on);cb(on) end)
		pill.ZIndex=3;dot.ZIndex=4
		return sv
	end
	local function mkBox(parent,default,w,xOff,cb)
		local tb=Instance.new("TextBox",parent)
		tb.Size=UDim2.new(0,w or 50,0,22);tb.Position=UDim2.new(1,-(xOff or 56),0.5,-11)
		tb.BackgroundColor3=INP;tb.BorderSizePixel=0;tb.Text=tostring(default);tb.TextColor3=W
		tb.Font=Enum.Font.GothamBold;tb.TextSize=11;tb.ClearTextOnFocus=false;tb.ZIndex=5
		Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5)
		local bs=Instance.new("UIStroke",tb);bs.Color=Color3.fromRGB(30,30,38);bs.Thickness=1
		tb.Focused:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Color=REDDIM}):Play() end)
		tb.FocusLost:Connect(function()
			TS:Create(bs,TweenInfo.new(0.12),{Color=Color3.fromRGB(30,30,38)}):Play()
			if cb then local n=tonumber(tb.Text);if n then cb(n) else tb.Text=tostring(default) end end
		end)
		return tb
	end
	local GAMEPAD_KEYS={
		[Enum.KeyCode.ButtonA]=true,[Enum.KeyCode.ButtonB]=true,[Enum.KeyCode.ButtonX]=true,[Enum.KeyCode.ButtonY]=true,
		[Enum.KeyCode.ButtonL1]=true,[Enum.KeyCode.ButtonR1]=true,[Enum.KeyCode.ButtonL2]=true,[Enum.KeyCode.ButtonR2]=true,
		[Enum.KeyCode.ButtonL3]=true,[Enum.KeyCode.ButtonR3]=true,[Enum.KeyCode.ButtonStart]=true,[Enum.KeyCode.ButtonSelect]=true,
		[Enum.KeyCode.DPadUp]=true,[Enum.KeyCode.DPadDown]=true,[Enum.KeyCode.DPadLeft]=true,[Enum.KeyCode.DPadRight]=true
	}
	local function isGamepadInput(inp) return inp and inp.UserInputType and inp.UserInputType.Name:match("^Gamepad")~=nil end
	local function isBindableInput(inp)
		if not inp or inp.KeyCode==Enum.KeyCode.Unknown then return false end
		if inp.UserInputType==Enum.UserInputType.Keyboard then return true end
		return isGamepadInput(inp) and GAMEPAD_KEYS[inp.KeyCode]==true
	end
	local function kbMatch(entry,kc) return kc and (kc==entry.kb or (entry.gp and kc==entry.gp)) end
	local function mkKB(parent,kbEntry,cb)
		local btn=Instance.new("TextButton",parent)
		btn.Size=UDim2.new(0,46,0,22);btn.Position=UDim2.new(1,-50,0.5,-11)
		btn.BackgroundColor3=INP;btn.BorderSizePixel=0
		local function getLabel() return (kbEntry.gp and kbEntry.gp.Name) or (kbEntry.kb and kbEntry.kb.Name) or "None" end
		btn.Text=getLabel();btn.TextColor3=W
		btn.Font=Enum.Font.GothamBold;btn.TextSize=9;btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
		local li=false;local lc;local pv=btn.Text;local listenStart=0
		btn.Activated:Connect(function()
			if li then li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;btn.Text=pv;btn.TextColor3=W;return end
			pv=btn.Text;li=true;_anyKeyListening=true;listenStart=tick();btn.Text="...";btn.TextColor3=W
			lc=UIS.InputBegan:Connect(function(inp)
				if not li then return end
				if inp.KeyCode==Enum.KeyCode.Escape then li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;btn.Text=pv;btn.TextColor3=W;return end
				local isGp=isGamepadInput(inp)
				if isGp and tick()-listenStart<0.15 then return end
				if not isBindableInput(inp) then return end
				btn.Text=inp.KeyCode.Name;pv=inp.KeyCode.Name;btn.TextColor3=W
				li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end
				if cb then cb(inp.KeyCode,isGp) end
			end)
		end)
		return btn
	end
	local function mkToggleKB(txt,kbEntry,onToggle,onKB)
		local row=mkRow(32);mkLabel(row,txt)
		if kbEntry then mkKB(row,kbEntry,function(k,isGp)
			if isGp then kbEntry.gp=k;kbEntry.kb=nil else kbEntry.kb=k;kbEntry.gp=nil end
			if onKB then onKB(k,isGp) end
		end) end
		local pill,dot=mkPill(row,kbEntry and 102 or 42)
		local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function() if _anyKeyListening then return end;on=not on;sv(on);if onToggle then onToggle(on) end end)
		pill.ZIndex=3;dot.ZIndex=4
		return sv
	end
	local pbFrame=Instance.new("Frame",gui)
	pbFrame.Size=UDim2.new(0,280,0,50);pbFrame.Position=UDim2.new(0.5,-140,1,-66)
	pbFrame.BackgroundColor3=BG2;pbFrame.BorderSizePixel=0;pbFrame.Active=true;pbFrame.ClipsDescendants=false
	Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(0,9)
	drag(pbFrame)
	progressPct=Instance.new("TextLabel",pbFrame)
	progressPct.Size=UDim2.new(0,44,0,16);progressPct.Position=UDim2.new(0,9,0,7)
	progressPct.BackgroundTransparency=1;progressPct.Text="0%";progressPct.TextColor3=W
	progressPct.Font=Enum.Font.GothamBold;progressPct.TextSize=11;progressPct.TextXAlignment=Enum.TextXAlignment.Left
	progressRadLbl=Instance.new("TextLabel",pbFrame)
	progressRadLbl.Size=UDim2.new(0,104,0,16);progressRadLbl.Position=UDim2.new(1,-112,0,7)
	progressRadLbl.BackgroundTransparency=1;progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius)
	progressRadLbl.TextColor3=W;progressRadLbl.Font=Enum.Font.GothamBold;progressRadLbl.TextSize=11;progressRadLbl.TextXAlignment=Enum.TextXAlignment.Right
	local pbg=Instance.new("Frame",pbFrame)
	pbg.Size=UDim2.new(1,-18,0,11);pbg.Position=UDim2.new(0,9,0,30)
	pbg.BackgroundColor3=Color3.fromRGB(15,15,17);pbg.BorderSizePixel=0
	Instance.new("UICorner",pbg).CornerRadius=UDim.new(1,0)
	progressFill=Instance.new("Frame",pbg)
	progressFill.Size=UDim2.new(0,0,1,0);progressFill.BackgroundColor3=RED;progressFill.BorderSizePixel=0
	Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)
	mkSect("Speed")
	do local row=mkRow(32);mkLabel(row,"Normal Speed");normalBox=mkBox(row,NS,50,48,function(v) if v>0 and v<=500 then NS=v end;saveConfig() end) end
	do local row=mkRow(32);mkLabel(row,"Carry Speed");carryBox=mkBox(row,CS,50,48,function(v) if v>0 and v<=500 then CS=v end;saveConfig() end) end
	do local row=mkRow(32);mkLabel(row,"Lagger Normal Speed");laggerBox=mkBox(row,LAGGER_SPEED,50,48,function(v) if v>0 and v<=500 then LAGGER_SPEED=v end;saveConfig() end) end
	do local row=mkRow(32);mkLabel(row,"Lagger Carry Speed");laggerCarryBox=mkBox(row,LAGGER_CARRY_SPEED,50,48,function(v) if v>0 and v<=500 then LAGGER_CARRY_SPEED=v end;saveConfig() end) end
	do
		local row=mkRow(32);mkLabel(row,"Mode")
		modeValLbl=Instance.new("TextLabel",row)
		modeValLbl.Size=UDim2.new(0,90,1,0);modeValLbl.Position=UDim2.new(1,-94,0,0)
		modeValLbl.BackgroundTransparency=1;modeValLbl.Text="Normal";modeValLbl.TextColor3=RED
		modeValLbl.Font=Enum.Font.GothamBlack;modeValLbl.TextSize=11;modeValLbl.TextXAlignment=Enum.TextXAlignment.Right
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function()
			if _anyKeyListening then return end
			toggleCarryMode()
			saveConfig()
		end)
	end
	mkSect("Keybinds")
	do local row=mkRow(32);mkLabel(row,"Speed Key");mkKB(row,KB.SpeedToggle,function(k,isGp) if isGp then KB.SpeedToggle.gp=k;KB.SpeedToggle.kb=nil else KB.SpeedToggle.kb=k;KB.SpeedToggle.gp=nil end;saveConfig() end) end
	do local row=mkRow(32);mkLabel(row,"Lagger Key");mkKB(row,KB.LaggerToggle,function(k,isGp) if isGp then KB.LaggerToggle.gp=k;KB.LaggerToggle.kb=nil else KB.LaggerToggle.kb=k;KB.LaggerToggle.gp=nil end;saveConfig() end) end
	mkSect("Combat")
	do
		local abRow=mkRow(32);mkLabel(abRow,"Auto Bat")
		mkKB(abRow,KB.AutoBat,function(k,isGp)
			if isGp then KB.AutoBat.gp=k;KB.AutoBat.kb=nil else KB.AutoBat.kb=k;KB.AutoBat.gp=nil end
			saveConfig()
		end)
		local abPill,abDot=mkPill(abRow,102)
		abPill.ZIndex=3;abDot.ZIndex=4
		local abOn=false
		local function svAutoBat(s) abOn=s;animPill(abPill,abDot,s) end
		autoBatSetVisual=svAutoBat
		local abClk=Instance.new("TextButton",abPill);abClk.Size=UDim2.new(1,0,1,0);abClk.BackgroundTransparency=1;abClk.Text="";abClk.ZIndex=5
		abClk.Activated:Connect(function()
			if _anyKeyListening then return end
			abOn=not abOn;svAutoBat(abOn)
			if abOn then queueAutoBatStart() else autoBatEnabled=false;disableAutoBat() end
			saveConfig()
		end)
	end
	setAutoSwingVisual=mkToggle("Auto Swing",function(on)
		autoSwingEnabled=on
		saveConfig()
	end)
	if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
	do
		setBatCounterVisual=mkToggle("Bat Counter",function(on)
			batCounterEnabled=on
			if on then startBatCounter() else stopBatCounter() end
			saveConfig()
		end)
	end
	mkSect("Steal")
	do
		local row=mkRow(32);mkLabel(row,"Radius")
		radInput=mkBox(row,Steal.StealRadius,50,56,function(v)
			if v>=0.5 and v<=300 then Steal.StealRadius=v;if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius) end end;saveConfig()
		end)
	end
	do
		local stealRow=mkRow(32);mkLabel(stealRow,"Auto Steal")
		local pill,dot=mkPill(stealRow,42)
		local on=false
		local function sv(s) on=s;animPill(pill,dot,s) end
		setInstaGrab=sv
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=5
		clk.Activated:Connect(function()
			on=not on;sv(on);Steal.AutoStealEnabled=on
			if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled=false;sv(false) end else stopAutoSteal() end
			saveConfig()
		end)
		pill.ZIndex=3;dot.ZIndex=4
	end
	mkSect("Misc")
	do
		local row=mkRow(32);mkLabel(row,"Instant Reset")
		mkKB(row,KB.InstaReset,function(k,isGp) if isGp then KB.InstaReset.gp=k;KB.InstaReset.kb=nil else KB.InstaReset.kb=k;KB.InstaReset.gp=nil end;saveConfig() end)
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function() cursedInstaReset() end)
	end
	setInfJumpVisual=mkToggle("Infinite Jump",function(on) infJumpEnabled=on end)
	setAntiRagVisual=mkToggle("Anti Ragdoll",function(on) antiRagdollEnabled=on;if on then startAntiRagdoll() else stopAntiRagdoll() end end)
	setMedusaVisual=mkToggle("Medusa Counter",function(on)
		medusaCounterEnabled=on
		if on then setupMedusa(LP.Character)
		else stopMedusaCounter() end
		saveConfig()
	end)
	setUnwalkVisual=mkToggle("Unwalk",function(on) unwalkEnabled=on;if on then startUnwalk() else stopUnwalk() end end)
	mkSect("Visual")
	setAntiLagVisual=mkToggle("Anti Lag",function(on)
		if on then enableAntiLag() else disableAntiLag() end
		saveConfig()
	end)
	setStretchRezVisual=mkToggle("Stretch Rez",function(on)
		if on then enableStretchRez() else disableStretchRez() end
		saveConfig()
	end)
	mkSect("Movement")
	do
		local sv=mkToggleKB("Auto Left",KB.AutoLeft,
			function(on)
				autoLeftEnabled=on
				if on then
					queueAutoLeftStart()
				else stopAutoLeft() end
			end,
			function(k,isGp) if isGp then KB.AutoLeft.gp=k;KB.AutoLeft.kb=nil else KB.AutoLeft.kb=k;KB.AutoLeft.gp=nil end;saveConfig() end)
		autoLeftSetVisual=sv
	end
	do
		local sv=mkToggleKB("Auto Right",KB.AutoRight,
			function(on)
				autoRightEnabled=on
				if on then
					queueAutoRightStart()
				else stopAutoRight() end
			end,
			function(k,isGp) if isGp then KB.AutoRight.gp=k;KB.AutoRight.kb=nil else KB.AutoRight.kb=k;KB.AutoRight.gp=nil end;saveConfig() end)
		autoRightSetVisual=sv
	end
	do
		local row=mkRow(32);mkLabel(row,"Drop Brainrot")
		mkKB(row,KB.DropBrainrot,function(k,isGp) if isGp then KB.DropBrainrot.gp=k;KB.DropBrainrot.kb=nil else KB.DropBrainrot.kb=k;KB.DropBrainrot.gp=nil end;saveConfig() end)
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function() runDrop() end)
	end
	do
		local row=mkRow(32);mkLabel(row,"TP Down")
		mkKB(row,KB.TPFloor,function(k,isGp) if isGp then KB.TPFloor.gp=k;KB.TPFloor.kb=nil else KB.TPFloor.kb=k;KB.TPFloor.gp=nil end;saveConfig() end)
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function() runTPFloor() end)
	end
	do
		setAutoTPVisual=mkToggle("Auto TP",function(on)
			autoTPEnabled=on
			if on then startAutoTP() else stopAutoTP() end
			saveConfig()
		end)
	end
	do
		local row=mkRow(32);mkLabel(row,"Auto TP Height")
		autoTPHeightBox=mkBox(row,autoTPHeight,50,56,function(v)
			if v>=0 and v<=500 then autoTPHeight=v else autoTPHeightBox.Text=tostring(autoTPHeight) end
			saveConfig()
		end)
	end
	mkSect("Interface")
	do local row=mkRow(32);mkLabel(row,"Hide UI");mkKB(row,KB.GuiHide,function(k,isGp) if isGp then KB.GuiHide.gp=k;KB.GuiHide.kb=nil else KB.GuiHide.kb=k;KB.GuiHide.gp=nil end;saveConfig() end) end
	UIS.InputBegan:Connect(function(input,gpe)
		if _anyKeyListening then return end
		if input.UserInputType==Enum.UserInputType.Keyboard then
			if gpe or UIS:GetFocusedTextBox() then return end
		elseif not isGamepadInput(input) then return end
		if not isBindableInput(input) then return end
		local kc=input.KeyCode
		if kbMatch(KB.LaggerToggle,kc) then
			toggleLaggerMode()
			saveConfig()
		elseif kbMatch(KB.SpeedToggle,kc) then
			toggleCarryMode()
			saveConfig()
		elseif kbMatch(KB.DropBrainrot,kc) then runDrop()
		elseif kbMatch(KB.TPFloor,kc) then runTPFloor()
		elseif kbMatch(KB.InstaReset,kc) then cursedInstaReset()
		elseif kbMatch(KB.AutoLeft,kc) then
			autoLeftEnabled=not autoLeftEnabled
			if autoLeftEnabled then
				queueAutoLeftStart()
			else stopAutoLeft() end
			if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
			if _updateMobileAutoLeft then _updateMobileAutoLeft(autoLeftEnabled) end
		elseif kbMatch(KB.AutoRight,kc) then
			autoRightEnabled=not autoRightEnabled
			if autoRightEnabled then
				queueAutoRightStart()
			else stopAutoRight() end
			if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
			if _updateMobileAutoRight then _updateMobileAutoRight(autoRightEnabled) end
		elseif kbMatch(KB.AutoBat,kc) then
			if not autoBatEnabled then
				queueAutoBatStart()
				if autoBatSetVisual then autoBatSetVisual(true) end
			else
				autoBatEnabled=false;disableAutoBat()
				if autoBatSetVisual then autoBatSetVisual(false) end
			end
		elseif kbMatch(KB.GuiHide,kc) then if main.Visible then hideGui() else showGui() end
		end
	end)
end
local _savedCfg = nil
local function loadConfigKeys()
	if not(isfile and isfile("cursedPC.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("cursedPC.json")) end)
	if not ok or not cfg then return end
	_savedCfg=cfg
	local function lk(e,d) if type(d)~="table" then return end;if d.kb and Enum.KeyCode[d.kb] then e.kb=Enum.KeyCode[d.kb] end;if d.gp and Enum.KeyCode[d.gp] then e.gp=Enum.KeyCode[d.gp] end end
	lk(KB.DropBrainrot,cfg.dropBrainrotKey);lk(KB.AutoLeft,cfg.autoLeftKey);lk(KB.AutoRight,cfg.autoRightKey)
	lk(KB.AutoBat,cfg.autoBatKey);lk(KB.LaggerToggle,cfg.laggerToggleKey)
	lk(KB.TPFloor,cfg.tpFloorKey);lk(KB.InstaReset,cfg.instaResetKey);lk(KB.GuiHide,cfg.guiHideKey);lk(KB.SpeedToggle,cfg.speedToggleKey)
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.grabRadius and type(cfg.grabRadius)=="number" then Steal.StealRadius=cfg.grabRadius else Steal.StealRadius=60 end
	if cfg.stealDuration and type(cfg.stealDuration)=="number" then Steal.StealDuration=cfg.stealDuration else Steal.StealDuration=1.4 end
	if cfg.laggerSpeed and type(cfg.laggerSpeed)=="number" then LAGGER_SPEED=cfg.laggerSpeed end
	if cfg.laggerCarrySpeed and type(cfg.laggerCarrySpeed)=="number" then LAGGER_CARRY_SPEED=cfg.laggerCarrySpeed end
	if cfg.autoTPHeight and type(cfg.autoTPHeight)=="number" then autoTPHeight=cfg.autoTPHeight end
	if cfg.autoSwing~=nil then autoSwingEnabled=cfg.autoSwing==true end
end
local function loadConfigState()
	local cfg=_savedCfg;if not cfg then return end
	if normalBox then normalBox.Text=tostring(NS) end
	if carryBox then carryBox.Text=tostring(CS) end
	if radInput then radInput.Text=tostring(Steal.StealRadius) end
	if progressRadLbl then progressRadLbl.Text=string.format("Radius: %.2g",Steal.StealRadius) end
	if laggerBox then laggerBox.Text=tostring(LAGGER_SPEED) end
	if laggerCarryBox then laggerCarryBox.Text=tostring(LAGGER_CARRY_SPEED) end
	if autoTPHeightBox then autoTPHeightBox.Text=tostring(autoTPHeight) end
	task.spawn(function()
		task.wait(0.15)
		if cfg.antiRagdoll then antiRagdollEnabled=true;if setAntiRagVisual then setAntiRagVisual(true) end;startAntiRagdoll() end
		if cfg.autoStealEnabled then Steal.AutoStealEnabled=true;if setInstaGrab then setInstaGrab(true) end;pcall(startAutoSteal) end
		if cfg.infiniteJump then infJumpEnabled=true;if setInfJumpVisual then setInfJumpVisual(true) end end
		if cfg.medusaCounter then medusaCounterEnabled=true;if setMedusaVisual then setMedusaVisual(true) end;setupMedusa(LP.Character) end
		if cfg.batCounter then batCounterEnabled=true;if setBatCounterVisual then setBatCounterVisual(true) end;startBatCounter() end
		if cfg.laggerMode then laggerToggled=true;speedMode=false;laggerPhase=cfg.laggerCarryMode and 2 or 1;refreshSpeedModeLabel()
		elseif cfg.carryMode then speedMode=false;toggleCarryMode() end
		if cfg.autoTPEnabled then autoTPEnabled=true;if setAutoTPVisual then setAutoTPVisual(true) end;startAutoTP() end
		if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
		if cfg.autoBat then autoBatEnabled=true;if autoBatSetVisual then autoBatSetVisual(true) end;queueAutoBatStart() end
		if cfg.unwalkEnabled then unwalkEnabled=true;if setUnwalkVisual then setUnwalkVisual(true) end;task.spawn(function() task.wait(0.5);startUnwalk() end) end
		if cfg.antiLag then enableAntiLag();if setAntiLagVisual then setAntiLagVisual(true) end end
		if cfg.stretchRez then enableStretchRez();if setStretchRezVisual then setStretchRezVisual(true) end end
	end)
end
loadConfigKeys()
buildGui()
loadConfigState()
createMobilePanel()
