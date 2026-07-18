_G.ScriptEnabled = true 
_G.CasingType = "Normal" 
_G.AutoWriteEnabled = false 
_G.AutoSubmitEnabled = false 

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
		if current:IsA("GuiObject") and not current.Visible then return false 
		elseif current:IsA("ScreenGui") and not current.Enabled then return false end 
		current = current.Parent 
	end 
	return true 
end 

local blacklistedWords = { "top", "sec", "min", "fps", "ping", "loading", "points", "coins", "cash", "rebirth", "slaps", "money", "speed", "level", "lvl", "score" } 

local commonWords = { 
	["the"]=true, ["and"]=true, ["for"]=true, ["you"]=true, ["your"]=true, ["now"]=true, ["new"]=true, ["use"]=true, ["get"]=true, ["out"]=true, ["all"]=true, ["are"]=true, ["can"]=true, ["with"]=true, ["from"]=true, ["this"]=true, ["that"]=true, ["here"]=true, ["more"]=true, ["info"]=true, ["redeem"]=true, ["claim"]=true, ["enter"]=true, ["reward"]=true, ["rewards"]=true, ["update"]=true, ["join"]=true, ["group"]=true, ["like"]=true, ["follow"]=true, ["sub"]=true, ["click"]=true, ["type"]=true, ["copy"]=true, ["paste"]=true, ["server"]=true, ["event"]=true, ["live"]=true, ["news"]=true, ["soon"]=true, ["available"]=true, ["expired"]=true, ["welcome"]=true, ["thanks"]=true, ["thank"]=true, ["player"]=true, ["players"]=true, ["today"]=true, ["time"]=true, ["wait"]=true, ["xp"]=true, ["money"]=true, ["sammy"]=true, ["announcement"]=true, ["announcements"]=true, ["release"]=true, ["released"]=true, ["limited"]=true, ["special"]=true, ["gift"]=true, ["pet"]=true, ["pets"]=true, ["egg"]=true, ["luck"]=true, ["boost"]=true, ["double"]=true, ["friend"]=true, ["friends"]=true, ["chat"]=true, ["online"]=true, ["offline"]=true, ["invite"]=true, ["party"]=true, ["voice"]=true, ["report"]=true, ["block"]=true, ["mute"]=true, ["store"]=true, ["shop"]=true, ["inventory"]=true, ["settings"]=true, ["leaderboard"]=true, ["lobby"]=true, ["menu"]=true, ["close"]=true, ["open"]=true, ["back"]=true, ["next"]=true, ["play"]=true, ["exit"]=true, ["loading"]=true 
} 

local function isBlacklisted(lowerText) 
	if commonWords[lowerText] then return true end 
	for _, word in ipairs(blacklistedWords) do 
		if lowerText:find(word, 1, true) then return true end 
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
	if text:match("^%d+$") then return #text >= 3 end 
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
	if setclipboard then pcall(function() setclipboard(formattedCode) end) success = true 
	elseif toclipboard then pcall(function() toclipboard(formattedCode) end) success = true 
	elseif set_clipboard then pcall(function() set_clipboard(formattedCode) end) success = true 
	elseif Clipboard and Clipboard.set then pcall(function() Clipboard.set(formattedCode) end) success = true 
	end 
	if success then 
		logStatus("Copied: " .. formattedCode) 
	else 
		logStatus("Error: No clipboard support! " .. formattedCode) 
	end 
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
	if _cachedBox and _cachedBox.Parent and isGuiVisible(_cachedBox) then return _cachedBox end 
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
	if firesignal then pcall(function() firesignal(sig) end) end 
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
	local ok, result = pcall(function() return rf:InvokeServer(formatted) end) 
	if ok then 
		logStatus("Redeemed via RF: " .. formatted) 
		return true 
	else 
		logStatus("RF invoke failed") 
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
		for i = 1, _G.SubmitAttempts do 
			local box = findCodeTextBox() 
			if not box then break end 
			pcall(function() 
				box:CaptureFocus() 
				box.Text = fullText 
				box.CursorPosition = #fullText + 1 
			end) 
			pcall(function() box:ReleaseFocus(true) end) 
			fireSubmitButton(box) 
		end 
		logStatus("Submitted " .. count .. " codes") 
		table.clear(collectedCodes) 
		table.clear(collectedSeen) 
	else 
		local ok = pcall(function() 
			textBox:CaptureFocus() 
			textBox.Text = fullText 
			textBox.CursorPosition = #fullText + 1 
		end) 
		if not ok then pcall(function() textBox.Text = fullText end) end 
		if ready then 
			logStatus("Collected " .. #collectedCodes .. " codes") 
			table.clear(collectedCodes) 
			table.clear(collectedSeen) 
		else 
			logStatus("Added: " .. formatted) 
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
		while _G.AutoWriteEnabled and #pendingQueue > 0 do 
			local b = findCodeTextBox() 
			if not (b and isGuiVisible(b)) then break end 
			local code = table.remove(pendingQueue, 1) 
			pendingSeen[code] = nil 
			writeAndSubmit(code) 
		end 
		writeBusy = false 
	end) 
end 

local function startAutoWriteLoop() 
	if autoWriteConn then return end 
	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10) 
	local boxConn = playerGui.DescendantAdded:Connect(function(obj) 
		if _isCodeBox(obj) and isGuiVisible(obj) then 
			_cachedBox = obj 
			triggerWrite() 
		end 
	end) 
	local boxRemConn = playerGui.DescendantRemoving:Connect(function(obj) 
		if obj == _cachedBox then _cachedBox = nil end 
	end) 
	autoWriteConn = { 
		Disconnect = function() 
			if boxConn then boxConn:Disconnect() end 
			if boxRemConn then boxRemConn:Disconnect() end 
		end 
	} 
	table.insert(activeConnections, autoWriteConn) 
end 

local function extractStrings(val, out) 
	out = out or {} 
	if type(val) == "string" then 
		table.insert(out, val) 
	elseif type(val) == "table" then 
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
			logStatus("PhiNotify remote not found") 
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
		logStatus("Hooked successfully!") 
	end) 
end 

local function cleanupMonitoring() 
	for _, conn in pairs(activeConnections) do 
		if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end 
	end 
	table.clear(activeConnections) 
	table.clear(pendingQueue) 
	table.clear(pendingSeen) 
	table.clear(collectedCodes) 
	table.clear(collectedSeen) 
	writeBusy = false 
end 

local function createUI() 
	local oldGui = game:GetService("CoreGui"):FindFirstChild("BrainrotRedeemerGui") or LocalPlayer.PlayerGui:FindFirstChild("BrainrotRedeemerGui") 
	if oldGui then oldGui:Destroy() end 

	ScreenGui = Instance.new("ScreenGui") 
	ScreenGui.Name = "BrainrotRedeemerGui" 
	ScreenGui.ResetOnSpawn = false 
	local successParent = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end) 
	if not successParent then 
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
	end 

	MainFrame = Instance.new("Frame") 
	MainFrame.Name = "MainFrame" 
	MainFrame.Size = UDim2.new(0, 330, 0, 290) 
	MainFrame.Position = UDim2.new(0.5, -165, 0.4, -145) 
	MainFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 18) 
	MainFrame.BorderSizePixel = 0 
	MainFrame.Active = true 
	MainFrame.Draggable = true 
	MainFrame.ClipsDescendants = true 
	MainFrame.Parent = ScreenGui 

	local mainCorner = Instance.new("UICorner") 
	mainCorner.CornerRadius = UDim.new(0, 12) 
	mainCorner.Parent = MainFrame 

	local mainStroke = Instance.new("UIStroke") 
	mainStroke.Color = Color3.fromRGB(150, 60, 255) 
	mainStroke.Thickness = 2 
	mainStroke.Parent = MainFrame 

	local header = Instance.new("TextLabel") 
	header.Size = UDim2.new(1, -120, 0, 40) 
	header.Position = UDim2.new(0, 20, 0, 0) 
	header.BackgroundTransparency = 1 
	header.Text = "Gamma Hub - Code Copier" 
	header.TextColor3 = Color3.fromRGB(240, 240, 255) 
	header.TextSize = 16 
	header.Font = Enum.Font.GothamBold 
	header.TextXAlignment = Enum.TextXAlignment.Left 
	header.Parent = MainFrame 

	-- Start Stop Buttons
	local ToggleLabel = Instance.new("TextLabel") 
	ToggleLabel.Size = UDim2.new(0, 150, 0, 30) 
	ToggleLabel.Position = UDim2.new(0, 15, 0, 50) 
	ToggleLabel.BackgroundTransparency = 1 
	ToggleLabel.Text = "Monitoring Active:" 
	ToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 210) 
	ToggleLabel.TextSize = 13 
	ToggleLabel.Font = Enum.Font.GothamSemibold 
	ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left 
	ToggleLabel.Parent = MainFrame 

	local StartButton = Instance.new("TextButton") 
	StartButton.Size = UDim2.new(0, 60, 0, 30) 
	StartButton.Position = UDim2.new(1, -130, 0, 50) 
	StartButton.Text = "Start" 
	StartButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
	StartButton.TextColor3 = Color3.fromRGB(255,255,255) 
	StartButton.Parent = MainFrame 

	local StopButton = Instance.new("TextButton") 
	StopButton.Size = UDim2.new(0, 60, 0, 30) 
	StopButton.Position = UDim2.new(1, -65, 0, 50) 
	StopButton.Text = "Stop" 
	StopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60) 
	StopButton.TextColor3 = Color3.fromRGB(255,255,255) 
	StopButton.Parent = MainFrame 

	StartButton.MouseButton1Click:Connect(function() 
		_G.ScriptEnabled = true 
		logStatus("Detection started.") 
	end) 

	StopButton.MouseButton1Click:Connect(function() 
		_G.ScriptEnabled = false 
		logStatus("Detection stopped.") 
	end) 

	-- Auto-Write
	local awLabel = Instance.new("TextLabel") 
	awLabel.Size = UDim2.new(0, 200, 0, 30) 
	awLabel.Position = UDim2.new(0, 15, 0, 90) 
	awLabel.BackgroundTransparency = 1 
	awLabel.Text = "Auto-Write:" 
	awLabel.TextColor3 = Color3.fromRGB(200, 200, 210) 
	awLabel.TextSize = 13 
	awLabel.Font = Enum.Font.GothamSemibold 
	awLabel.TextXAlignment = Enum.TextXAlignment.Left 
	awLabel.Parent = MainFrame 

	local awButton = Instance.new("TextButton") 
	awButton.Size = UDim2.new(0, 80, 0, 28) 
	awButton.Position = UDim2.new(1, -95, 0, 91) 
	awButton.Text = "OFF" 
	awButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60) 
	awButton.TextColor3 = Color3.fromRGB(255,255,255) 
	awButton.Parent = MainFrame 

	awButton.MouseButton1Click:Connect(function() 
		_G.AutoWriteEnabled = not _G.AutoWriteEnabled 
		awButton.Text = _G.AutoWriteEnabled and "ON" or "OFF" 
		awButton.BackgroundColor3 = _G.AutoWriteEnabled and Color3.fromRGB(46,204,113) or Color3.fromRGB(231,76,60) 
		logStatus(_G.AutoWriteEnabled and "Auto-Write Enabled" or "Auto-Write Disabled") 
	end) 

	-- Status
	local StatusLabel = Instance.new("TextLabel") 
	StatusLabel.Name = "StatusLabel" 
	StatusLabel.Size = UDim2.new(1, -30, 0, 40) 
	StatusLabel.Position = UDim2.new(0, 15, 0, 240) 
	StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25) 
	StatusLabel.Text = "Status: Ready - Normal Mode" 
	StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 185) 
	StatusLabel.TextSize = 12 
	StatusLabel.Font = Enum.Font.Gotham 
	StatusLabel.Parent = MainFrame 

	local sCorner = Instance.new("UICorner") sCorner.Parent = StatusLabel 
end 

local function init() 
	pcall(cleanupMonitoring) 
	createUI() 
	startMonitoring() 
	startAutoWriteLoop() 
	logStatus("Script loaded successfully! (Normal mode locked)")
end 

init()
