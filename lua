-- ============================================================
-- ASTRO DUELS
-- ============================================================

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UIS             = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local Stats           = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LP              = Players.LocalPlayer

local LOGO_ID = "rbxassetid://96255128725816"
task.spawn(function() pcall(function() ContentProvider:PreloadAsync({LOGO_ID}) end) end)

local _isfile   = isfile   or (syn and syn.isfile)   or (getgenv and getgenv().isfile)   or function() return false end
local _readfile = readfile  or (syn and syn.readfile)  or (getgenv and getgenv().readfile)  or function() return nil  end
local _writefile= writefile or (syn and syn.writefile) or (getgenv and getgenv().writefile) or function() end
local getconnections = getconnections or get_signal_cons or getconnects or (syn and syn.get_signal_cons)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    normalSpeed=60, carrySpeed=30, laggerSpeed=10.1,
    speedToggled=false, laggerEnabled=false,
    infJumpEnabled=false, antiRagdollEnabled=false, fpsBoostEnabled=false,
    guiVisible=true, uiLocked=false,
    isStealing=false, stealStartTime=nil, lastStealTick=0,
    autoLeftEnabled=false, autoRightEnabled=false,
    autoLeftPhase=1, autoRightPhase=1,
    medusaLastUsed=0, medusaDebounce=false, medusaCounterEnabled=false,
    batAimbotToggled=false, autoSwingEnabled=false,
    hittingCooldown=false,
    batCounterEnabled=false, batCounterDebounce=false,
    dropEnabled=false, _tpInProgress=false,
    lastMoveDir=Vector3.new(0,0,0),
    unwalkEnabled=false, stackButtonsHidden=false,
    _prevCarry=30, _prevSpeed=false,
}

local Keys = {
    speed=Enum.KeyCode.Q, guiHide=Enum.KeyCode.LeftControl,
    autoLeft=Enum.KeyCode.L, autoRight=Enum.KeyCode.R,
    lagger=Enum.KeyCode.Unknown, tpDown=Enum.KeyCode.Unknown,
    drop=Enum.KeyCode.H, aimbot=Enum.KeyCode.Unknown,
}

local BTN_W=58; local BTN_H=48; local BTN_GAP=4; local COLS=2
local stackDefs = {
    {key="autoLeft",   label="AUTO\nLEFT"},
    {key="autoRight",  label="AUTO\nRIGHT"},
    {key="aimbot",     label="AIMBOT"},
    {key="lagger",     label="LAGGER"},
    {key="drop",       label="DROP\nBR"},
    {key="tpDown",     label="TP\nDOWN"},
    {key="carrySpeed", label="CARRY\nSPEED"},
}
local GRID_W=COLS*(BTN_W+BTN_GAP)-BTN_GAP
local GRID_H=math.ceil(#stackDefs/COLS)*(BTN_H+BTN_GAP)-BTN_GAP

local function getDefaultStackPos(i)
    local col=(i-1)%COLS
    local row2=math.floor((i-1)/COLS)
    return UDim2.new(1,-(GRID_W+12)+col*(BTN_W+BTN_GAP),0.5,-(GRID_H/2)+row2*(BTN_H+BTN_GAP))
end

local Steal = {
    AutoStealEnabled=false, StealRadius=20, StealDuration=0.25,
    Data={}, plotCache={}, plotCacheTime={}, cachedPrompts={}, promptCacheTime=0,
}

local CONFIG_FILE = "AstroDuelsConfig.json"

local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
    [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

local PLOT_CACHE_DURATION=2; local PROMPT_CACHE_REFRESH=0.15
local STEAL_COOLDOWN=0.1; local MEDUSA_COOLDOWN=25; local DROP_AUTO_OFF_DELAY=0.15

local POS={
    L1=Vector3.new(-476.48,-6.28,92.73), L2=Vector3.new(-483.12,-4.95,94.80),
    R1=Vector3.new(-476.16,-6.52,25.62), R2=Vector3.new(-483.04,-5.09,23.14),
}

local Conns={autoSteal=nil,antiRag=nil,autoLeft=nil,autoRight=nil,aimbot=nil,anchor={},progress=nil,batCounter=nil,unwalk=nil}

local h,hrp
local setAutoLeft,setAutoRight,setInfJump,setAntiRag,setFps
local setMedusaCounter,setUnwalkToggle,setAimbot,setAutoSwing
local setLagger,setDropBrainrot,setInstaGrab
local setupMedusaCounter,stopMedusaCounter,startAntiRagdoll,stopAntiRagdoll
local applyFPSBoost,startAutoSteal,stopAutoSteal
local startAutoLeft,stopAutoLeft,startAutoRight,stopAutoRight
local saveConfig,loadConfig,runDropBrainrot,stopDropBrainrot,doTpDown
local startBatAimbot,stopBatAimbot,startBatCounter,stopBatCounter,setBatCounter
local stackBtnRefs={}; local stackWrappers={}; local keybindBtnRefs={}
local normalBox,carryBox,laggerBox,uiScaleBox,stealRadBox,lockBtn
local setHideButtonsToggle; local radTB

-- ============================================================
-- COLORS — BLACK & PURPLE
-- ============================================================
local PURPLE       = Color3.fromRGB(147, 51, 234)
local PURPLE_LT    = Color3.fromRGB(192, 132, 252)
local PURPLE_DK    = Color3.fromRGB(88, 28, 135)
local PURPLE_VDK   = Color3.fromRGB(49, 10, 80)
local PURPLE_DIM   = Color3.fromRGB(75, 25, 130)
local PURPLE_BRD   = Color3.fromRGB(90, 30, 150)
local PURPLE_BG    = Color3.fromRGB(25, 10, 50)
local PURPLE_BG2   = Color3.fromRGB(20, 5, 40)
local PURPLE_MIDBG = Color3.fromRGB(35, 15, 65)
local PURPLE_GLOW  = Color3.fromRGB(180, 100, 255)
local BLK        = Color3.fromRGB(8, 8, 8)
local BLK2       = Color3.fromRGB(12, 12, 12)
local BLK3       = Color3.fromRGB(16, 16, 16)
local BLK4       = Color3.fromRGB(20, 20, 20)
local BLK5       = Color3.fromRGB(26, 26, 26)
local GRAY_D     = Color3.fromRGB(55, 55, 55)
local GRAY_M     = Color3.fromRGB(85, 85, 85)
local GRAY_L     = Color3.fromRGB(125, 125, 125)
local GRAY_XL    = Color3.fromRGB(175, 175, 175)
local WHITE      = Color3.fromRGB(225, 225, 225)
local RED_SOFT   = Color3.fromRGB(220, 60, 60)
local GREEN_SOFT = Color3.fromRGB(60, 200, 100)

local C = {
    winBg=BLK2, winBorder=PURPLE_BRD,
    topBg=BLK2, topTitle=PURPLE, topSub=GRAY_D,
    topBtn=PURPLE_DK, topBtnHov=PURPLE_LT, topDivider=PURPLE_BG,
    tabBarBg=BLK3, tabBarDiv=PURPLE_BG,
    tabIdle=GRAY_D, tabActive=PURPLE, tabActiveBg=PURPLE_BG2, tabUnderline=PURPLE,
    sectionTxt=PURPLE_DK, sectionDiv=PURPLE_BG,
    rowBg=BLK, rowBorder=Color3.fromRGB(25,25,25), rowLabel=WHITE,
    rowSub=GRAY_D, rowValue=GRAY_L, rowHov=PURPLE_BG2,
    inputBg=BLK4, inputBorder=PURPLE_BRD, inputFocus=PURPLE, inputTxt=WHITE,
    pillOff=BLK5, pillOn=PURPLE_DIM, dotOff=GRAY_D, dotOn=PURPLE_GLOW, pillBorder=PURPLE_BRD,
    modeBtnBg=BLK4, modeBtnBrd=PURPLE_BRD, modeBtnTxt=GRAY_D,
    modeBtnActBg=PURPLE_VDK, modeBtnActTx=PURPLE_GLOW,
    chipBg=BLK4, chipBorder=PURPLE_BRD, chipTxt=GRAY_D,
    btnBg=BLK5, btnBorder=PURPLE_BRD, btnTxt=GRAY_L, btnHov=PURPLE_MIDBG,
    stackBg=Color3.fromRGB(10,10,10), stackBrd=PURPLE_BRD,
    stackTxt=GRAY_D, stackActBg=PURPLE_BG2, stackActBrd=PURPLE,
    stackActTxt=PURPLE_GLOW, stackDot=PURPLE_VDK, stackDotOn=PURPLE_GLOW,
    infoBg=BLK, infoBrd=PURPLE_BRD, infoTxt=GRAY_D, infoVal=PURPLE, infoFill=PURPLE,
    accent=PURPLE, accentDim=PURPLE_DIM, lockOn=PURPLE, divider=PURPLE_BG,
}

-- ============================================================
-- CLEANUP
-- ============================================================
for _,name in pairs({"VyseSlottedGUI","VyseAsireGUI","VyseAsireHubV4","VyseAsireHubV5","VyseAsireHubV5_1","AsireHubV5_1","AsireHubV5_2","CookHubV1","SpinkHubV1","SkyHubV1","AstroDuelsV1"}) do
    pcall(function() local o=game:GetService("CoreGui"):FindFirstChild(name); if o then o:Destroy() end end)
    pcall(function() local o=LP:WaitForChild("PlayerGui"):FindFirstChild(name); if o then o:Destroy() end end)
end

-- ============================================================
-- ROOT GUI
-- ============================================================
local gui=Instance.new("ScreenGui")
gui.Name="AstroDuelsV1"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=LP:WaitForChild("PlayerGui")

local uiScaleObj=Instance.new("UIScale",gui); uiScaleObj.Scale=1.0

-- ============================================================
-- HELPERS
-- ============================================================
local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6); return c end
local function mkStroke(p,col,th)
    local s=Instance.new("UIStroke",p); s.Color=col; s.Thickness=th or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end

-- ============================================================
-- DRAG
-- ============================================================
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

local function makeStackDraggable(frame,onTap)
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil; local moved=false
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
        dragging=true; moved=false; dragStart=inp.Position; startPos=frame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState==Enum.UserInputState.End then
                if not moved and onTap then onTap() end; dragging=false; moved=false
            end
        end)
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp~=dragInput or not dragging then return end
        local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
        if math.abs(dx)>4 or math.abs(dy)>4 then moved=true end
        if moved and not State.uiLocked then
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
        end
    end)
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local WIN_W=220; local WIN_H=330; local TITLE_H=28; local TAB_H=24

local mainOuter = Instance.new("Frame", gui)
mainOuter.Name="MainOuter"; mainOuter.Size=UDim2.new(0,WIN_W,0,WIN_H)
mainOuter.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
mainOuter.BackgroundColor3=BLK2; mainOuter.BackgroundTransparency=0
mainOuter.BorderSizePixel=0; mainOuter.ClipsDescendants=true
mkCorner(mainOuter,10); mkStroke(mainOuter, PURPLE_BRD, 1.5)
makeDraggable(mainOuter)

-- Glow layer
local glowFrame = Instance.new("Frame", mainOuter)
glowFrame.Size = UDim2.new(1, 4, 1, 4); glowFrame.Position = UDim2.new(0, -2, 0, -2)
glowFrame.BackgroundColor3 = PURPLE_VDK; glowFrame.BackgroundTransparency = 0.6
glowFrame.BorderSizePixel = 0; glowFrame.ZIndex = 0
mkCorner(glowFrame, 12)

-- ============================================================
-- TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame", mainOuter)
titleBar.Size=UDim2.new(1,0,0,TITLE_H); titleBar.BackgroundColor3=BLK3
titleBar.BackgroundTransparency=0; titleBar.BorderSizePixel=0; titleBar.ZIndex=5
mkCorner(titleBar,10)

local logoBg = Instance.new("ImageLabel", titleBar)
logoBg.Size=UDim2.new(0,18,0,18); logoBg.Position=UDim2.new(0,8,0.5,-9)
logoBg.BackgroundTransparency=1; logoBg.Image=LOGO_ID; logoBg.ScaleType=Enum.ScaleType.Fit; logoBg.ZIndex=6
local tint = Instance.new("ImageLabel", logoBg)
tint.Size=UDim2.new(1,0,1,0); tint.Position=UDim2.new(0,0,0,0)
tint.BackgroundTransparency=1; tint.ImageColor3=PURPLE
tint.Image="rbxassetid://4167816828"; tint.ScaleType=Enum.ScaleType.Slice
tint.SliceCenter=Rect.new(0,0,0,0); tint.ZIndex=7

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size=UDim2.new(0,90,1,0); titleLbl.Position=UDim2.new(0,30,0,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="ASTRO DUELS"
titleLbl.TextColor3=PURPLE_GLOW; titleLbl.Font=Enum.Font.GothamBlack
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.ZIndex=6

local verLbl = Instance.new("TextLabel", titleBar)
verLbl.Size=UDim2.new(0,30,1,0); verLbl.Position=UDim2.new(1,-58,0,0)
verLbl.BackgroundTransparency=1; verLbl.Text="v1.0"
verLbl.TextColor3=GRAY_D; verLbl.Font=Enum.Font.Gotham; verLbl.TextSize=8
verLbl.TextXAlignment=Enum.TextXAlignment.Right; verLbl.ZIndex=6

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size=UDim2.new(0,20,0,20); closeBtn.Position=UDim2.new(1,-26,0.5,-10)
closeBtn.BackgroundColor3=BLK5; closeBtn.BorderSizePixel=0; closeBtn.Text="×"
closeBtn.TextColor3=GRAY_M; closeBtn.Font=Enum.Font.GothamBlack; closeBtn.TextSize=14; closeBtn.ZIndex=7
mkCorner(closeBtn,5); mkStroke(closeBtn, PURPLE_BRD, 1)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(60,15,15),TextColor3=RED_SOFT}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundColor3=BLK5,TextColor3=GRAY_M}):Play() end)
closeBtn.MouseButton1Click:Connect(function() State.guiVisible=false; mainOuter.Visible=false end)

lockBtn = Instance.new("TextButton", titleBar)
lockBtn.Size=UDim2.new(0,20,0,20); lockBtn.Position=UDim2.new(1,-48,0.5,-10)
lockBtn.BackgroundColor3=BLK5; lockBtn.BorderSizePixel=0; lockBtn.Text="🔓"
lockBtn.Font=Enum.Font.GothamBold; lockBtn.TextSize=10; lockBtn.ZIndex=7
mkCorner(lockBtn,5); mkStroke(lockBtn, PURPLE_BRD, 1)
lockBtn.MouseButton1Click:Connect(function()
    State.uiLocked=not State.uiLocked; lockBtn.Text=State.uiLocked and "🔒" or "🔓"
end)

-- ============================================================
-- TAB BAR
-- ============================================================
local tabBar = Instance.new("Frame", mainOuter)
tabBar.Size=UDim2.new(1,0,0,TAB_H); tabBar.Position=UDim2.new(0,0,0,TITLE_H)
tabBar.BackgroundColor3=BLK3; tabBar.BackgroundTransparency=0; tabBar.BorderSizePixel=0; tabBar.ZIndex=5

local tabBarLL = Instance.new("UIListLayout", tabBar)
tabBarLL.FillDirection=Enum.FillDirection.Horizontal
tabBarLL.SortOrder=Enum.SortOrder.LayoutOrder; tabBarLL.Padding=UDim.new(0,0)

local tabDiv = Instance.new("Frame", mainOuter)
tabDiv.Size=UDim2.new(1,0,0,1); tabDiv.Position=UDim2.new(0,0,0,TITLE_H+TAB_H)
tabDiv.BackgroundColor3=PURPLE_BG; tabDiv.BorderSizePixel=0; tabDiv.ZIndex=5

-- ============================================================
-- CONTENT
-- ============================================================
local CONTENT_Y=TITLE_H+TAB_H+1
local contentBg = Instance.new("Frame", mainOuter)
contentBg.Size=UDim2.new(1,0,1,-CONTENT_Y); contentBg.Position=UDim2.new(0,0,0,CONTENT_Y)
contentBg.BackgroundColor3=BLK2; contentBg.BackgroundTransparency=0
contentBg.BorderSizePixel=0; contentBg.ClipsDescendants=true; contentBg.ZIndex=2

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local TABS={"Speed","Aimbot","Mech","Move","Config"}
local currentTab="Speed"; local tabBtns={}; local tabPages={}

for i,name in ipairs(TABS) do
    local btn=Instance.new("TextButton",tabBar)
    btn.Size=UDim2.new(1/#TABS,0,1,0); btn.BackgroundColor3=BLK3
    btn.BackgroundTransparency=0; btn.BorderSizePixel=0; btn.Text=name
    btn.TextColor3=(name==currentTab) and PURPLE_GLOW or GRAY_D
    btn.Font=Enum.Font.GothamBold; btn.TextSize=9; btn.ZIndex=6; btn.LayoutOrder=i
    local underline=Instance.new("Frame",btn)
    underline.Size=UDim2.new(0.6,0,0,2); underline.Position=UDim2.new(0.2,0,1,-2)
    underline.BackgroundColor3=PURPLE_GLOW; underline.BorderSizePixel=0
    underline.Visible=(name==currentTab); underline.ZIndex=7; mkCorner(underline,1)
    tabBtns[name]={btn=btn,underline=underline}
    btn.MouseEnter:Connect(function() if name~=currentTab then TweenService:Create(btn,TweenInfo.new(0.12),{TextColor3=PURPLE_LT}):Play() end end)
    btn.MouseLeave:Connect(function() if name~=currentTab then TweenService:Create(btn,TweenInfo.new(0.12),{TextColor3=GRAY_D}):Play() end end)
    btn.MouseButton1Click:Connect(function()
        currentTab=name
        for _,n in ipairs(TABS) do
            local t=tabBtns[n]; local a=(n==name)
            TweenService:Create(t.btn,TweenInfo.new(0.15),{TextColor3=a and PURPLE_GLOW or GRAY_D,BackgroundColor3=a and PURPLE_BG2 or BLK3}):Play()
            t.underline.Visible=a
            if tabPages[n] then tabPages[n].Visible=a end
        end
    end)
end

-- ============================================================
-- ROW BUILDERS
-- ============================================================
local currentPage=nil; local lo=0
local function LO() lo=lo+1; return lo end

local function makeGap(px)
    local f=Instance.new("Frame",currentPage); f.Size=UDim2.new(1,0,0,px or 2)
    f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=LO()
end

local function makeSectionHeader(label)
    local w=Instance.new("Frame",currentPage); w.Size=UDim2.new(1,0,0,16)
    w.BackgroundTransparency=1; w.BorderSizePixel=0; w.LayoutOrder=LO()
    local l=Instance.new("TextLabel",w); l.Size=UDim2.new(1,-16,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text=label and label:upper() or ""
    l.TextColor3=PURPLE_DK; l.Font=Enum.Font.GothamBold; l.TextSize=8
    l.TextXAlignment=Enum.TextXAlignment.Left
end

local function makeInputRow(label,default,onChange)
    local row=Instance.new("Frame",currentPage); row.Size=UDim2.new(1,0,0,28)
    row.BackgroundTransparency=0; row.BackgroundColor3=BLK
    row.BorderSizePixel=0; row.LayoutOrder=LO(); mkCorner(row,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-66,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=WHITE
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local bw=Instance.new("Frame",row); bw.Size=UDim2.new(0,50,0,20); bw.Position=UDim2.new(1,-58,0.5,-10)
    bw.BackgroundColor3=BLK4; bw.BorderSizePixel=0; mkCorner(bw,5)
    local bs=mkStroke(bw,PURPLE_BRD,1)
    local box=Instance.new("TextBox",bw); box.Size=UDim2.new(1,-6,1,0); box.Position=UDim2.new(0,3,0,0)
    box.BackgroundTransparency=1; box.Text=tostring(default); box.TextColor3=WHITE
    box.Font=Enum.Font.GothamBold; box.TextSize=10; box.ClearTextOnFocus=false; box.ZIndex=8
    box.TextXAlignment=Enum.TextXAlignment.Center
    box.Focused:Connect(function() TweenService:Create(bs,TweenInfo.new(0.15),{Color=PURPLE}):Play() end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=PURPLE_BRD}):Play()
        if onChange then local n=tonumber(box.Text); if n then onChange(n) else box.Text=tostring(default) end end
    end)
    return box,row
end

local function makeToggleRow(label,defaultOn,onToggle)
    local row=Instance.new("Frame",currentPage); row.Size=UDim2.new(1,0,0,28)
    row.BackgroundTransparency=0; row.BackgroundColor3=BLK
    row.BorderSizePixel=0; row.LayoutOrder=LO(); mkCorner(row,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-48,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=WHITE
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local pillBg=Instance.new("Frame",row); pillBg.Size=UDim2.new(0,32,0,16)
    pillBg.Position=UDim2.new(1,-40,0.5,-8); pillBg.BackgroundColor3=defaultOn and PURPLE_DIM or BLK5
    pillBg.BorderSizePixel=0; pillBg.ZIndex=7; mkCorner(pillBg,8); mkStroke(pillBg,PURPLE_BRD,1)
    local dot=Instance.new("Frame",pillBg); dot.Size=UDim2.new(0,10,0,10)
    dot.Position=defaultOn and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,4,0.5,-5)
    dot.BackgroundColor3=defaultOn and PURPLE_GLOW or GRAY_D
    dot.BorderSizePixel=0; dot.ZIndex=8; mkCorner(dot,5)
    local isOn=defaultOn or false
    local function setV(on)
        isOn=on
        TweenService:Create(pillBg,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundColor3=on and PURPLE_DIM or BLK5}):Play()
        TweenService:Create(dot,TweenInfo.new(0.2,Enum.EasingStyle.Back),{
            Position=on and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,4,0.5,-5),
            BackgroundColor3=on and PURPLE_GLOW or GRAY_D
        }):Play()
    end
    local function toggle() isOn=not isOn; setV(isOn); if onToggle then pcall(onToggle,isOn) end end
    local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1
    clk.Text=""; clk.ZIndex=5; clk.BorderSizePixel=0; clk.MouseButton1Click:Connect(toggle)
    return setV
end

local function getKeyDisplayName(kc)
    local n=kc.Name
    local gp={ButtonA="A",ButtonB="B",ButtonX="X",ButtonY="Y",ButtonL1="LB",ButtonL2="LT",
        ButtonL3="LS",ButtonR1="RB",ButtonR2="RT",ButtonR3="RS",DPadUp="D↑",DPadDown="D↓"}
    if gp[n] then return gp[n] end; return n:sub(1,5)
end

local function makeKeybindRow(label,currentKey,onChanged,keyName)
    local row=Instance.new("Frame",currentPage); row.Size=UDim2.new(1,0,0,28)
    row.BackgroundTransparency=0; row.BackgroundColor3=BLK
    row.BorderSizePixel=0; row.LayoutOrder=LO(); mkCorner(row,6)
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-58,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=WHITE
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local kbtn=Instance.new("TextButton",row); kbtn.Size=UDim2.new(0,40,0,18)
    kbtn.Position=UDim2.new(1,-48,0.5,-9); kbtn.BackgroundColor3=BLK4; kbtn.BorderSizePixel=0
    kbtn.Text=getKeyDisplayName(currentKey); kbtn.TextColor3=GRAY_L
    kbtn.Font=Enum.Font.GothamBold; kbtn.TextSize=8; kbtn.ZIndex=8
    mkCorner(kbtn,5); local ks=mkStroke(kbtn,PURPLE_BRD,1)
    local listening=false; local lconnK=nil; local lconnG=nil
    local function stopL(key)
        listening=false
        if lconnK then lconnK:Disconnect(); lconnK=nil end
        if lconnG then lconnG:Disconnect(); lconnG=nil end
        TweenService:Create(ks,TweenInfo.new(0.12),{Color=PURPLE_BRD}):Play(); kbtn.TextColor3=GRAY_L
        if key then kbtn.Text=getKeyDisplayName(key); if onChanged then onChanged(key) end
            task.spawn(function() if saveConfig then pcall(saveConfig) end end) end
    end
    kbtn.MouseButton1Click:Connect(function()
        if listening then stopL(nil); return end
        listening=true; kbtn.Text="···"; kbtn.TextColor3=WHITE
        TweenService:Create(ks,TweenInfo.new(0.12),{Color=PURPLE}):Play()
        lconnK=UIS.InputBegan:Connect(function(inp)
            if not listening then return end
            if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
            if inp.KeyCode==Enum.KeyCode.Escape then stopL(nil); return end; stopL(inp.KeyCode)
        end)
    end)
    if keyName then keybindBtnRefs[keyName]=kbtn end; return kbtn
end

local function makeActionButton(label,bgColor,hoverColor,onClick)
    local w=Instance.new("Frame",currentPage); w.Size=UDim2.new(1,0,0,24)
    w.BackgroundTransparency=1; w.BorderSizePixel=0; w.LayoutOrder=LO()
    local btn=Instance.new("TextButton",w); btn.Size=UDim2.new(1,-16,0,20)
    btn.Position=UDim2.new(0,8,0,2); btn.BackgroundColor3=bgColor; btn.BorderSizePixel=0
    btn.Text=label; btn.TextColor3=PURPLE_GLOW; btn.Font=Enum.Font.GothamBold; btn.TextSize=9; btn.ZIndex=5
    mkCorner(btn,6); mkStroke(btn,PURPLE_BRD,1)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=hoverColor}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=bgColor}):Play() end)
    btn.MouseButton1Click:Connect(onClick); return btn
end

-- ============================================================
-- BUILD PAGES
-- ============================================================
local function buildPage(tabName,buildFn)
    local page=Instance.new("ScrollingFrame",contentBg)
    page.Name=tabName; page.Visible=(tabName=="Speed")
    page.Size=UDim2.new(1,0,1,0); page.Position=UDim2.new(0,0,0,0)
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=2; page.ScrollBarImageColor3=PURPLE
    page.ScrollBarImageTransparency=0.5
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(0,0,0,0)
    local ll=Instance.new("UIListLayout",page)
    ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,0)
    tabPages[tabName]=page; currentPage=page; lo=0; buildFn(); currentPage=nil
end

-- SPEED PAGE
buildPage("Speed", function()
    makeGap(2); makeSectionHeader("Speed Settings"); makeGap(1)
    normalBox=makeInputRow("Normal Speed",State.normalSpeed,function(n) if n>0 and n<=500 then State.normalSpeed=n end end)
    carryBox=makeInputRow("Carry Speed",State.carrySpeed,function(n) if n>0 and n<=500 then State.carrySpeed=n end end)
    laggerBox=makeInputRow("Lagger Speed",State.laggerSpeed,function(n) if n>0 and n<=500 then State.laggerSpeed=n end end)
    makeGap(3)
    local modeRow=Instance.new("Frame",currentPage); modeRow.Size=UDim2.new(1,0,0,30)
    modeRow.BackgroundTransparency=1; modeRow.BorderSizePixel=0; modeRow.LayoutOrder=LO()
    local modeWrap=Instance.new("Frame",modeRow); modeWrap.Size=UDim2.new(1,-16,0,22)
    modeWrap.Position=UDim2.new(0,8,0,4); modeWrap.BackgroundColor3=BLK4; modeWrap.BorderSizePixel=0
    mkCorner(modeWrap,6); mkStroke(modeWrap,PURPLE_BRD,1)
    local modeLL=Instance.new("UIListLayout",modeWrap); modeLL.FillDirection=Enum.FillDirection.Horizontal
    modeLL.SortOrder=Enum.SortOrder.LayoutOrder; modeLL.Padding=UDim.new(0,0)
    local modeStatusRow=Instance.new("Frame",currentPage); modeStatusRow.Size=UDim2.new(1,0,0,14)
    modeStatusRow.BackgroundTransparency=1; modeStatusRow.BorderSizePixel=0; modeStatusRow.LayoutOrder=LO()
    local modeStatusLbl=Instance.new("TextLabel",modeStatusRow)
    modeStatusLbl.Size=UDim2.new(1,-16,1,0); modeStatusLbl.Position=UDim2.new(0,8,0,0)
    modeStatusLbl.BackgroundTransparency=1; modeStatusLbl.Text="Mode: Normal"
    modeStatusLbl.TextColor3=GRAY_D; modeStatusLbl.Font=Enum.Font.Gotham; modeStatusLbl.TextSize=8
    modeStatusLbl.TextXAlignment=Enum.TextXAlignment.Left
    local modeNames={"Normal","Carry","Lagger"}; local modeBtns={}
    local function setModeActive(active)
        for _,m in ipairs(modeNames) do
            local b=modeBtns[m]; if not b then continue end; local isA=(m==active)
            TweenService:Create(b,TweenInfo.new(0.15),{
                BackgroundColor3=isA and PURPLE_VDK or BLK4,
                BackgroundTransparency=isA and 0 or 1,
                TextColor3=isA and PURPLE_GLOW or GRAY_D
            }):Play()
        end
        modeStatusLbl.Text="Mode: "..active
        if active=="Normal" then State.speedToggled=false; State.laggerEnabled=false
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
            if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(false) end
        elseif active=="Carry" then State.speedToggled=true; State.laggerEnabled=false
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(true) end
            if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(false) end
        elseif active=="Lagger" then State.speedToggled=false; State.laggerEnabled=true
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
            if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(true) end
        end
    end
    for i,mname in ipairs(modeNames) do
        local b=Instance.new("TextButton",modeWrap); b.Size=UDim2.new(1/3,0,1,0)
        b.BackgroundColor3=(i==1) and PURPLE_VDK or BLK4; b.BackgroundTransparency=(i==1) and 0 or 1
        b.BorderSizePixel=0; b.Text=mname; b.TextColor3=(i==1) and PURPLE_GLOW or GRAY_D
        b.Font=Enum.Font.GothamBold; b.TextSize=9; b.ZIndex=8; b.LayoutOrder=i; mkCorner(b,5)
        b.MouseButton1Click:Connect(function() setModeActive(mname) end); modeBtns[mname]=b
    end
    makeGap(3); makeSectionHeader("Keybinds"); makeGap(1)
    makeKeybindRow("Speed Key",Keys.speed,function(k) Keys.speed=k end,"speed")
    makeKeybindRow("Lagger Key",Keys.lagger,function(k) Keys.lagger=k end,"lagger")
end)

-- AIMBOT PAGE
buildPage("Aimbot", function()
    makeGap(2); makeSectionHeader("Bat Aimbot"); makeGap(1)
    setAutoSwing=makeToggleRow("Auto Swing",false,function(on) State.autoSwingEnabled=on end)
    setBatCounter=makeToggleRow("Bat Counter",false,function(on)
        State.batCounterEnabled=on; if on then startBatCounter() else stopBatCounter() end
    end)
    makeGap(3); makeSectionHeader("Keybinds"); makeGap(1)
    makeKeybindRow("Aimbot Key",Keys.aimbot,function(k) Keys.aimbot=k end,"aimbot")
end)

-- MECH PAGE
buildPage("Mech", function()
    makeGap(2); makeSectionHeader("Stealing"); makeGap(1)
    setInstaGrab=makeToggleRow("Insta Grab",false,function(on)
        Steal.AutoStealEnabled=on
        if on then if not pcall(startAutoSteal) then Steal.AutoStealEnabled=false; setInstaGrab(false) end else stopAutoSteal() end
    end)
    stealRadBox=makeInputRow("Steal Radius",Steal.StealRadius,function(n)
        if n>=5 and n<=300 then Steal.StealRadius=math.floor(n); Steal.cachedPrompts={}; Steal.promptCacheTime=0
            if radTB and not radTB:IsFocused() then radTB.Text=tostring(Steal.StealRadius) end end
    end)
    makeInputRow("Steal Duration",Steal.StealDuration,function(n) if n>=0.05 and n<=2 then Steal.StealDuration=n end end)
    makeGap(3); makeSectionHeader("Combat / Defense"); makeGap(1)
    setInfJump=makeToggleRow("Infinite Jump",false,function(on) State.infJumpEnabled=on end)
    setAntiRag=makeToggleRow("Anti Ragdoll",false,function(on)
        State.antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end
    end)
    setFps=makeToggleRow("FPS Boost",false,function(on) State.fpsBoostEnabled=on; if on then pcall(applyFPSBoost) end end)
    setMedusaCounter=makeToggleRow("Medusa Counter",false,function(on)
        State.medusaCounterEnabled=on; if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
    end)
    setUnwalkToggle=makeToggleRow("Unwalk",false,function(on)
        State.unwalkEnabled=on; if on then startUnwalk() else stopUnwalk() end
    end)
end)

-- MOVE PAGE
buildPage("Move", function()
    makeGap(2); makeSectionHeader("Auto Movement"); makeGap(1)
    makeKeybindRow("Auto Left",Keys.autoLeft,function(k) Keys.autoLeft=k end,"autoLeft")
    makeKeybindRow("Auto Right",Keys.autoRight,function(k) Keys.autoRight=k end,"autoRight")
    makeGap(3); makeSectionHeader("Other Keys"); makeGap(1)
    makeKeybindRow("Drop Key",Keys.drop,function(k) Keys.drop=k end,"drop")
    makeKeybindRow("TP Down Key",Keys.tpDown,function(k) Keys.tpDown=k end,"tpDown")
end)

-- CONFIG PAGE
local function applyStackButtonsVisible(v) State.stackButtonsHidden=not v; for _,w in pairs(stackWrappers) do w.Visible=v end end

buildPage("Config", function()
    makeGap(2); makeSectionHeader("Actions"); makeGap(1)
    local saveCfgBtn=makeActionButton("💾  Save Config",BLK5,PURPLE_MIDBG,function()
        local ok=pcall(saveConfig)
        saveCfgBtn.Text=ok and "Saved!" or "Failed!"
        saveCfgBtn.TextColor3=ok and GREEN_SOFT or RED_SOFT
        task.delay(1,function() if saveCfgBtn and saveCfgBtn.Parent then saveCfgBtn.Text="💾  Save Config"; saveCfgBtn.TextColor3=PURPLE_GLOW end end)
    end)
    makeGap(1)
    local resetBtn=makeActionButton("↺  Reset Buttons",BLK5,PURPLE_MIDBG,function()
        for i,def in ipairs(stackDefs) do local w=stackWrappers[def.key]
            if w then TweenService:Create(w,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=getDefaultStackPos(i)}):Play() end
        end
        resetBtn.Text="✓  Done!"; resetBtn.TextColor3=GREEN_SOFT
        task.delay(1,function() if resetBtn and resetBtn.Parent then resetBtn.Text="↺  Reset Buttons"; resetBtn.TextColor3=PURPLE_GLOW end end)
    end)
    makeGap(3); makeSectionHeader("Interface"); makeGap(1)
    makeKeybindRow("Hide GUI",Keys.guiHide,function(k) Keys.guiHide=k end,"guiHide")
    uiScaleBox=makeInputRow("UI Scale",1.0,function(n) if n>=0.5 and n<=2.0 then if uiScaleObj then uiScaleObj.Scale=n end end end)
    setHideButtonsToggle=makeToggleRow("Hide Buttons",false,function(on) applyStackButtonsVisible(not on) end)
    makeGap(5)
    local fw=Instance.new("Frame",currentPage); fw.Size=UDim2.new(1,0,0,14)
    fw.BackgroundTransparency=1; fw.BorderSizePixel=0; fw.LayoutOrder=LO()
    local fl=Instance.new("TextLabel",fw); fl.Size=UDim2.new(1,0,1,0)
    fl.BackgroundTransparency=1; fl.Text="ASTRO DUELS  ·  v1.0"
    fl.TextColor3=PURPLE_VDK; fl.Font=Enum.Font.Gotham; fl.TextSize=7; fl.TextXAlignment=Enum.TextXAlignment.Center
end)

for _,n in ipairs(TABS) do
    local t=tabBtns[n]; local a=(n=="Speed")
    t.btn.TextColor3=a and PURPLE_GLOW or GRAY_D; t.btn.BackgroundColor3=a and PURPLE_BG2 or BLK3
    t.underline.Visible=a; if tabPages[n] then tabPages[n].Visible=a end
end

-- ============================================================
-- VBTN
-- ============================================================
local vBtnFrame=Instance.new("Frame",gui)
vBtnFrame.Name="AstroVBtn"; vBtnFrame.Size=UDim2.new(0,36,0,36)
vBtnFrame.Position=UDim2.new(1,-48,0,12)
vBtnFrame.BackgroundColor3=PURPLE_BG2; vBtnFrame.BorderSizePixel=0
vBtnFrame.Active=true; vBtnFrame.ZIndex=20; mkCorner(vBtnFrame,10); mkStroke(vBtnFrame,PURPLE,1.5)
local vGlow=Instance.new("UIStroke",vBtnFrame); vGlow.Thickness=3; vGlow.Color=PURPLE_VDK; vGlow.Transparency=0.4
local vBtnImg=Instance.new("ImageLabel",vBtnFrame)
vBtnImg.Size=UDim2.new(1,-10,1,-10); vBtnImg.Position=UDim2.new(0,5,0,5)
vBtnImg.BackgroundTransparency=1; vBtnImg.Image=LOGO_ID; vBtnImg.ScaleType=Enum.ScaleType.Fit; vBtnImg.ZIndex=21
vBtnImg.ImageColor3=PURPLE_GLOW
local vDragging,vDragInput,vDragStart,vStartPos=false,nil,nil,nil; local vMoved=false
vBtnFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
    vDragging=true; vMoved=false; vDragStart=inp.Position; vStartPos=vBtnFrame.Position
    inp.Changed:Connect(function()
        if inp.UserInputState==Enum.UserInputState.End then
            if not vMoved then State.guiVisible=not State.guiVisible; mainOuter.Visible=State.guiVisible end
            vDragging=false; vMoved=false
        end
    end)
end)
vBtnFrame.InputChanged:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then vDragInput=inp end
end)
UIS.InputChanged:Connect(function(inp)
    if inp~=vDragInput or not vDragging then return end
    local dx=inp.Position.X-vDragStart.X; local dy=inp.Position.Y-vDragStart.Y
    if math.abs(dx)>4 or math.abs(dy)>4 then vMoved=true end
    if vMoved then vBtnFrame.Position=UDim2.new(vStartPos.X.Scale,vStartPos.X.Offset+dx,vStartPos.Y.Scale,vStartPos.Y.Offset+dy) end
end)

-- ============================================================
-- INFO BAR
-- ============================================================
local infoBar=Instance.new("Frame",gui); infoBar.Size=UDim2.new(0,175,0,42)
infoBar.Position=UDim2.new(0.5,-87,1,-52); infoBar.BackgroundColor3=BLK
infoBar.BackgroundTransparency=0; infoBar.BorderSizePixel=0; infoBar.Active=true
mkCorner(infoBar,10); mkStroke(infoBar,PURPLE_BRD,1.5)
makeDraggable(infoBar)
local ibAcc=Instance.new("Frame",infoBar); ibAcc.Size=UDim2.new(0,3,0.6,0)
ibAcc.Position=UDim2.new(0,0,0.2,0); ibAcc.BackgroundColor3=PURPLE; ibAcc.BorderSizePixel=0; mkCorner(ibAcc,2)
local stealLbl=Instance.new("TextLabel",infoBar); stealLbl.Size=UDim2.new(0,75,0,10)
stealLbl.Position=UDim2.new(0,10,0,4); stealLbl.BackgroundTransparency=1; stealLbl.Text="Steal Progress"
stealLbl.TextColor3=GRAY_D; stealLbl.Font=Enum.Font.GothamBold; stealLbl.TextSize=7; stealLbl.TextXAlignment=Enum.TextXAlignment.Left
local stealPctLbl=Instance.new("TextLabel",infoBar); stealPctLbl.Size=UDim2.new(0,36,0,10)
stealPctLbl.Position=UDim2.new(1,-38,0,4); stealPctLbl.BackgroundTransparency=1; stealPctLbl.Text="0%"
stealPctLbl.TextColor3=PURPLE; stealPctLbl.Font=Enum.Font.GothamBlack; stealPctLbl.TextSize=8
stealPctLbl.TextXAlignment=Enum.TextXAlignment.Right
local pTrack=Instance.new("Frame",infoBar); pTrack.Size=UDim2.new(1,-16,0,3)
pTrack.Position=UDim2.new(0,8,0,16); pTrack.BackgroundColor3=BLK4; pTrack.BorderSizePixel=0; mkCorner(pTrack,2)
local progressFill=Instance.new("Frame",pTrack); progressFill.Size=UDim2.new(0,0,1,0)
progressFill.BackgroundColor3=PURPLE; progressFill.BorderSizePixel=0; mkCorner(progressFill,2)
local function makeStatMini(xOff,w,icon)
    local box=Instance.new("Frame",infoBar); box.Size=UDim2.new(0,w,0,10); box.Position=UDim2.new(0,xOff,0,24)
    box.BackgroundTransparency=1
    local iL=Instance.new("TextLabel",box); iL.Size=UDim2.new(0,22,1,0); iL.BackgroundTransparency=1
    iL.Text=icon; iL.TextColor3=GRAY_D; iL.Font=Enum.Font.GothamBold; iL.TextSize=7
    local vL=Instance.new("TextLabel",box); vL.Size=UDim2.new(1,-22,1,0); vL.Position=UDim2.new(0,22,0,0)
    vL.BackgroundTransparency=1; vL.Text="—"; vL.TextColor3=PURPLE; vL.Font=Enum.Font.GothamBlack
    vL.TextSize=7; vL.TextXAlignment=Enum.TextXAlignment.Left; return vL
end
local fpsVal=makeStatMini(10,44,"FPS"); local pingVal=makeStatMini(56,50,"PING")
local radWrap=Instance.new("Frame",infoBar); radWrap.Size=UDim2.new(0,56,0,10)
radWrap.Position=UDim2.new(1,-62,0,24); radWrap.BackgroundTransparency=1
local radIco=Instance.new("TextLabel",radWrap); radIco.Size=UDim2.new(0,22,1,0); radIco.BackgroundTransparency=1
radIco.Text="RAD"; radIco.TextColor3=GRAY_D; radIco.Font=Enum.Font.GothamBold; radIco.TextSize=7
radTB=Instance.new("TextBox",radWrap); radTB.Size=UDim2.new(0,32,1,0); radTB.Position=UDim2.new(0,22,0,0)
radTB.BackgroundTransparency=1; radTB.Text=tostring(Steal.StealRadius); radTB.TextColor3=PURPLE
radTB.Font=Enum.Font.GothamBlack; radTB.TextSize=7; radTB.ClearTextOnFocus=false; radTB.ZIndex=10
radTB.FocusLost:Connect(function()
    local n=tonumber(radTB.Text)
    if n and n>=5 and n<=300 then Steal.StealRadius=math.floor(n); Steal.cachedPrompts={}; Steal.promptCacheTime=0 end
    radTB.Text=tostring(Steal.StealRadius)
    if stealRadBox and not stealRadBox:IsFocused() then stealRadBox.Text=tostring(Steal.StealRadius) end
end)
do
    local lastT=tick(); local fc=0
    RunService.RenderStepped:Connect(function()
        fc=fc+1; local now=tick()
        if now-lastT>=0.5 then local fps=math.floor(fc/(now-lastT)); fc=0; lastT=now; fpsVal.Text=tostring(fps)
            fpsVal.TextColor3=fps>=55 and PURPLE_GLOW or fps>=30 and PURPLE_DK or PURPLE_VDK end
    end)
    task.spawn(function() while task.wait(1) do pcall(function()
        local ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        pingVal.Text=ping.."ms"; pingVal.TextColor3=ping<=80 and PURPLE_GLOW or ping<=150 and PURPLE_DK or PURPLE_VDK
    end) end end)
    task.spawn(function() while task.wait(0.5) do pcall(function()
        if not radTB:IsFocused() then radTB.Text=tostring(Steal.StealRadius) end
        if stealRadBox and not stealRadBox:IsFocused() then stealRadBox.Text=tostring(Steal.StealRadius) end
    end) end end)
end

-- ============================================================
-- STACK BUTTONS (Premium look)
-- ============================================================
for i,def in ipairs(stackDefs) do
    local btnFrame=Instance.new("Frame",gui); btnFrame.Name="StackBtn_"..def.key
    btnFrame.Size=UDim2.new(0,BTN_W,0,BTN_H); btnFrame.Position=getDefaultStackPos(i)
    btnFrame.BackgroundColor3=BLK; btnFrame.BorderSizePixel=0; btnFrame.Active=true; btnFrame.ZIndex=15
    mkCorner(btnFrame,10)
    local s1=mkStroke(btnFrame,PURPLE_BRD,1.5)
    local s2=Instance.new("UIStroke",btnFrame); s2.Color=PURPLE_VDK; s2.Thickness=3; s2.Transparency=0.7
    s2.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stackWrappers[def.key]=btnFrame

    local innerBg=Instance.new("Frame",btnFrame); innerBg.Name="InnerBg"
    innerBg.Size=UDim2.new(1,-4,1,-4); innerBg.Position=UDim2.new(0,2,0,2)
    innerBg.BackgroundColor3=BLK2; innerBg.BackgroundTransparency=0.3; innerBg.BorderSizePixel=0; innerBg.ZIndex=1
    mkCorner(innerBg,8)

    local nl=Instance.new("TextLabel",btnFrame); nl.Size=UDim2.new(1,-6,1,-14)
    nl.Position=UDim2.new(0,3,0,4); nl.BackgroundTransparency=1; nl.Text=def.label
    nl.TextColor3=GRAY_D; nl.Font=Enum.Font.GothamBlack; nl.TextSize=9; nl.TextWrapped=true
    nl.TextXAlignment=Enum.TextXAlignment.Center; nl.ZIndex=6

    local dot=Instance.new("Frame",btnFrame); dot.Size=UDim2.new(0,6,0,6)
    dot.Position=UDim2.new(0.5,-3,1,-10); dot.BackgroundColor3=PURPLE_VDK; dot.BorderSizePixel=0; mkCorner(dot,3)

    local btnState=false
    local function setOn(on)
        btnState=on
        TweenService:Create(btnFrame,TweenInfo.new(0.2),{BackgroundColor3=on and PURPLE_BG2 or BLK}):Play()
        TweenService:Create(s1,TweenInfo.new(0.2),{Color=on and PURPLE_GLOW or PURPLE_BRD}):Play()
        s2.Color=on and PURPLE_GLOW or PURPLE_VDK; s2.Transparency=on and 0.3 or 0.7
        TweenService:Create(nl,TweenInfo.new(0.2),{TextColor3=on and PURPLE_GLOW or GRAY_D}):Play()
        TweenService:Create(dot,TweenInfo.new(0.2),{BackgroundColor3=on and PURPLE_GLOW or PURPLE_VDK}):Play()
        if on then innerBg.BackgroundTransparency=0.6 else innerBg.BackgroundTransparency=0.3 end
    end
    stackBtnRefs[def.key]={setOn=setOn}

    btnFrame.MouseEnter:Connect(function()
        if not btnState then
            TweenService:Create(btnFrame,TweenInfo.new(0.12),{BackgroundColor3=PURPLE_BG}):Play()
            s2.Transparency=0.4; innerBg.BackgroundTransparency=0.5
        end
    end)
    btnFrame.MouseLeave:Connect(function()
        TweenService:Create(btnFrame,TweenInfo.new(0.12),{BackgroundColor3=btnState and PURPLE_BG2 or BLK}):Play()
        s2.Transparency=btnState and 0.3 or 0.7; innerBg.BackgroundTransparency=btnState and 0.6 or 0.3
    end)

    local function onTap()
        if def.key=="tpDown" then doTpDown(); return end
        if def.key=="carrySpeed" then State.speedToggled=not State.speedToggled; setOn(State.speedToggled); return end
        local ns=not btnState; setOn(ns)
        if def.key=="autoLeft" then
            State.autoLeftEnabled=ns
            if ns and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
            if ns then startAutoLeft() else stopAutoLeft() end
        elseif def.key=="autoRight" then
            State.autoRightEnabled=ns
            if ns and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
            if ns then startAutoRight() else stopAutoRight() end
        elseif def.key=="aimbot" then
            State.batAimbotToggled=ns
            if ns then
                if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
                if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
                pcall(startBatAimbot)
            else stopBatAimbot() end
        elseif def.key=="lagger" then
            State.laggerEnabled=ns
            if ns then State._prevCarry=State.carrySpeed; State._prevSpeed=State.speedToggled; State.speedToggled=false
                if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end
                if carryBox then carryBox.Text=tostring(State.laggerSpeed) end
            else State.carrySpeed=State._prevCarry or 30; State.speedToggled=State._prevSpeed or false
                if carryBox then carryBox.Text=tostring(State.carrySpeed) end
                if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
            end
        elseif def.key=="drop" then
            if ns then runDropBrainrot() else stopDropBrainrot() end
        end
    end
    makeStackDraggable(btnFrame,onTap)
end

-- ============================================================
-- GAME LOGIC (unchanged functionality)
-- ============================================================
local function resetProgressBar() stealPctLbl.Text="0%"; progressFill.Size=UDim2.new(0,0,1,0) end

doTpDown=function()
    pcall(function()
        local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={c}; rp.FilterType=Enum.RaycastFilterType.Exclude
        local res=workspace:Raycast(root.Position,Vector3.new(0,-1000,0),rp)
        if res then root.CFrame=CFrame.new(res.Position+Vector3.new(0,root.Size.Y/2+0.5,0)); root.AssemblyLinearVelocity=Vector3.zero end
    end)
end

local _dropConns={}
runDropBrainrot=function()
    if State.dropEnabled then return end; State.dropEnabled=true; if stackBtnRefs.drop then stackBtnRefs.drop.setOn(true) end
    task.spawn(function()
        local colConn=RunService.Stepped:Connect(function()
            if not State.dropEnabled then return end
            for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end end end
        end)
        table.insert(_dropConns,colConn)
        task.spawn(function()
            while State.dropEnabled do RunService.Heartbeat:Wait()
                local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); if not root then continue end
                local vel=root.Velocity; root.Velocity=vel*10000+Vector3.new(0,10000,0)
                RunService.RenderStepped:Wait(); if root and root.Parent then root.Velocity=vel end
                RunService.Stepped:Wait(); if root and root.Parent then root.Velocity=vel+Vector3.new(0,0.1,0) end
            end
        end)
        task.wait(DROP_AUTO_OFF_DELAY); stopDropBrainrot()
    end)
end
stopDropBrainrot=function()
    State.dropEnabled=false
    for _,cn in ipairs(_dropConns) do pcall(function() cn:Disconnect() end) end; _dropConns={}
    if stackBtnRefs.drop then stackBtnRefs.drop.setOn(false) end
end

local VYSE_AIMBOT_SPEED=56.5; local VYSE_HIT_DIST=5; local SWING_COOLDOWN=0.08
local function findAnyTool()
    local c=LP.Character; if c then for _,v in ipairs(c:GetChildren()) do if v:IsA("Tool") then return v end end end
    local bp=LP:FindFirstChildOfClass("Backpack"); if bp then for _,v in ipairs(bp:GetChildren()) do if v:IsA("Tool") then return v end end end; return nil
end
local function getClosestPlayer()
    if not hrp then return nil,math.huge end; local cp,cd=nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.Character then
        local tr=p.Character:FindFirstChild("HumanoidRootPart"); local ph=p.Character:FindFirstChildOfClass("Humanoid")
        if tr and ph and ph.Health>0 then local d=(hrp.Position-tr.Position).Magnitude; if d<cd then cd=d; cp=p end end
    end end; return cp,cd
end
local function tryHitBat()
    if State.hittingCooldown then return end; State.hittingCooldown=true
    pcall(function()
        local c=LP.Character; if not c then return end; local hum2=c:FindFirstChildOfClass("Humanoid"); local tool=findAnyTool()
        if tool then
            if tool.Parent~=c and hum2 then pcall(function() hum2:EquipTool(tool) end) end
            local remote=tool:FindFirstChildOfClass("RemoteEvent")
            if remote then pcall(function() remote:FireServer() end) else pcall(function() tool:Activate() end) end
        end
    end)
    task.delay(SWING_COOLDOWN,function() State.hittingCooldown=false end)
end
startBatAimbot=function()
    if Conns.aimbot then return end
    Conns.aimbot=RunService.Heartbeat:Connect(function()
        if not State.batAimbotToggled then return end; local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum2=c:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local target,dist=getClosestPlayer()
        if target and target.Character then local tr=target.Character:FindFirstChild("HumanoidRootPart")
            if tr then local fp=tr.Position+tr.CFrame.LookVector*1.5; local dir=(fp-root.Position).Unit
                root.AssemblyLinearVelocity=Vector3.new(dir.X*VYSE_AIMBOT_SPEED,dir.Y*VYSE_AIMBOT_SPEED,dir.Z*VYSE_AIMBOT_SPEED)
                if dist<=VYSE_HIT_DIST and State.autoSwingEnabled then tryHitBat() end end
        else root.AssemblyLinearVelocity=Vector3.zero end
    end)
end
stopBatAimbot=function()
    if Conns.aimbot then Conns.aimbot:Disconnect(); Conns.aimbot=nil end
    local c=LP.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity=Vector3.zero end; State.hittingCooldown=false
end

local BAT_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
    local c=LP.Character; if not c then return nil end; local bp=LP:FindFirstChildOfClass("Backpack")
    for _,name in ipairs(BAT_SLAP_LIST) do local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name)); if t then return t end end
    for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end; return nil
end
local function swingBatForCounter(bat,char)
    local hum2=char:FindFirstChildOfClass("Humanoid")
    if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end; task.wait(0.05) end
    local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then pcall(function() remote:FireServer() end); task.wait(0.15); pcall(function() remote:FireServer() end)
    else pcall(function() bat:Activate() end); task.wait(0.15); pcall(function() bat:Activate() end) end
end
startBatCounter=function()
    if Conns.batCounter then return end
    Conns.batCounter=RunService.Heartbeat:Connect(function()
        if not State.batCounterEnabled or State.batCounterDebounce then return end
        local char=LP.Character; if not char then return end; local hum2=char:FindFirstChildOfClass("Humanoid"); if not hum2 then return end
        local st=hum2:GetState()
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            State.batCounterDebounce=true; task.spawn(function()
                local bat=findBatForCounter(); if bat then swingBatForCounter(bat,char) end
                task.wait(0.5); State.batCounterDebounce=false
            end)
        end
    end)
end
stopBatCounter=function() if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter=nil end; State.batCounterDebounce=false end

local function findMedusa()
    local c=LP.Character; if not c then return nil end
    for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
    local bp=LP:FindFirstChild("Backpack")
    if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower(); if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end; return nil
end
local function useMedusaCounter()
    if State.medusaDebounce or tick()-State.medusaLastUsed<MEDUSA_COOLDOWN then return end
    local c=LP.Character; if not c then return end; State.medusaDebounce=true
    local med=findMedusa(); if not med then State.medusaDebounce=false; return end
    if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
    pcall(function() med:Activate() end); State.medusaLastUsed=tick(); State.medusaDebounce=false
end
local function onAnchorChanged(part) return part:GetPropertyChangedSignal("Anchored"):Connect(function() if part.Anchored and part.Transparency==1 then useMedusaCounter() end end) end
setupMedusaCounter=function(char)
    stopMedusaCounter(); if not char then return end
    for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
    table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end))
end
stopMedusaCounter=function() for _,c2 in pairs(Conns.anchor) do pcall(function() c2:Disconnect() end) end; Conns.anchor={} end

local function faceSouth() pcall(function() local c=LP.Character; if not c then return end; local r=c:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=CFrame.new(r.Position) end end) end
local function faceNorth() pcall(function() local c=LP.Character; if not c then return end; local r=c:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=CFrame.new(r.Position)*CFrame.Angles(0,math.rad(180),0) end end) end

startAutoLeft=function()
    if Conns.autoLeft then Conns.autoLeft:Disconnect() end; State.autoLeftPhase=1
    Conns.autoLeft=RunService.Heartbeat:Connect(function()
        if not State.autoLeftEnabled then return end; local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); local hum2=c:FindFirstChildOfClass("Humanoid"); if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoLeftPhase==1 then
            local tgt=Vector3.new(POS.L1.X,root.Position.Y,POS.L1.Z)
            if (tgt-root.Position).Magnitude<1 then State.autoLeftPhase=2; local d=(POS.L2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd); return end
            local d=(POS.L1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoLeftPhase==2 then
            local tgt=Vector3.new(POS.L2.X,root.Position.Y,POS.L2.Z)
            if (tgt-root.Position).Magnitude<1 then hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.zero; State.autoLeftEnabled=false
                if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end; State.autoLeftPhase=1
                if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end; faceSouth(); return end
            local d=(POS.L2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
stopAutoLeft=function()
    if Conns.autoLeft then Conns.autoLeft:Disconnect(); Conns.autoLeft=nil end; State.autoLeftPhase=1
    local c=LP.Character; if c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero,false) end end
    if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end
end

startAutoRight=function()
    if Conns.autoRight then Conns.autoRight:Disconnect() end; State.autoRightPhase=1
    Conns.autoRight=RunService.Heartbeat:Connect(function()
        if not State.autoRightEnabled then return end; local c=LP.Character; if not c then return end
        local root=c:FindFirstChild("HumanoidRootPart"); local hum2=c:FindFirstChildOfClass("Humanoid"); if not root or not hum2 then return end
        local spd=State.normalSpeed
        if State.autoRightPhase==1 then
            local tgt=Vector3.new(POS.R1.X,root.Position.Y,POS.R1.Z)
            if (tgt-root.Position).Magnitude<1 then State.autoRightPhase=2; local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd); return end
            local d=(POS.R1-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif State.autoRightPhase==2 then
            local tgt=Vector3.new(POS.R2.X,root.Position.Y,POS.R2.Z)
            if (tgt-root.Position).Magnitude<1 then hum2:Move(Vector3.zero,false); root.AssemblyLinearVelocity=Vector3.zero; State.autoRightEnabled=false
                if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end; State.autoRightPhase=1
                if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end; faceNorth(); return end
            local d=(POS.R2-root.Position); local mv=Vector3.new(d.X,0,d.Z).Unit; hum2:Move(mv,false); root.AssemblyLinearVelocity=Vector3.new(mv.X*spd,root.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
stopAutoRight=function()
    if Conns.autoRight then Conns.autoRight:Disconnect(); Conns.autoRight=nil end; State.autoRightPhase=1
    local c=LP.Character; if c then local hum2=c:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:Move(Vector3.zero,false) end end
    if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end
end

startAntiRagdoll=function()
    if Conns.antiRag then return end
    Conns.antiRag=RunService.Heartbeat:Connect(function()
        if not State.antiRagdollEnabled then return end; local c=LP.Character; if not c then return end
        local hum2=c:FindFirstChildOfClass("Humanoid"); local root=c:FindFirstChild("HumanoidRootPart")
        if not hum2 or not root or hum2.Health<=0 then return end
        local st=hum2:GetState(); if st==Enum.HumanoidStateType.Dead then return end
        if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
            pcall(function() hum2:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            pcall(function() workspace.CurrentCamera.CameraSubject=hum2 end)
            pcall(function() local PM=LP.PlayerScripts:FindFirstChild("PlayerModule"); if PM then local CM=require(PM:FindFirstChild("ControlModule")); if CM then CM:Enable() end end end)
            root.Velocity=Vector3.new(0,0,0); root.RotVelocity=Vector3.new(0,0,0)
        end
        for _,obj in ipairs(c:GetDescendants()) do pcall(function() if obj:IsA("Motor6D") and obj.Enabled==false then obj.Enabled=true end end) end
    end)
end
stopAntiRagdoll=function() if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag=nil end end

local unwalkAnimateRef=nil
local function startUnwalk()
    local c=LP.Character; if not c then return end
    local hum2=c:FindFirstChildOfClass("Humanoid")
    if hum2 then pcall(function() for _,track in ipairs(hum2:GetPlayingAnimationTracks()) do track:Stop(0) end end) end
    local animCtrl=c:FindFirstChildOfClass("AnimationController")
    if animCtrl then pcall(function() for _,track in ipairs(animCtrl:GetPlayingAnimationTracks()) do track:Stop(0) end end) end
    local anim=c:FindFirstChild("Animate")
    if anim and anim:IsA("LocalScript") then anim.Disabled=true; unwalkAnimateRef=anim end
    if Conns.unwalk then Conns.unwalk:Disconnect() end
    Conns.unwalk=RunService.Heartbeat:Connect(function()
        if not State.unwalkEnabled then return end; local c2=LP.Character; if not c2 then return end
        local hum3=c2:FindFirstChildOfClass("Humanoid"); if hum3 then pcall(function() for _,track in ipairs(hum3:GetPlayingAnimationTracks()) do track:Stop(0) end end) end
    end)
end
local function stopUnwalk()
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end
    local c=LP.Character; if c and unwalkAnimateRef and unwalkAnimateRef.Parent==c then unwalkAnimateRef.Disabled=false end; unwalkAnimateRef=nil
end

applyFPSBoost=function()
    pcall(function() setfpscap(999999999) end)
    local function pO(v) pcall(function()
        if v:IsA("Model") then v.LevelOfDetail=Enum.ModelLevelOfDetail.Disabled; v.ModelStreamingMode=Enum.ModelStreamingMode.Nonatomic
        elseif v:IsA("MeshPart") then v.CastShadow=false; v.DoubleSided=false; v.RenderFidelity=Enum.RenderFidelity.Performance
        elseif v:IsA("BasePart") then v.CastShadow=false; v.Material=Enum.Material.Plastic; v.Reflectance=0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1
        elseif v:IsA("SpecialMesh") then v.TextureId=""
        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled=false
        elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then v:Destroy()
        elseif v:IsA("Attachment") then v.Visible=false end
    end) end
    for _,v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        local L=game:GetService("Lighting")
        for _,v in pairs(L:GetDescendants()) do pcall(function() if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end end) end
        pcall(function() sethiddenproperty(L,"Technology",Enum.Technology.Legacy) end)
        L.GlobalShadows=false; L.FogEnd=9e9; L.Brightness=0
        local ter=workspace:FindFirstChildOfClass("Terrain")
        if ter then pcall(function() sethiddenproperty(ter,"Decoration",false) end); ter.WaterReflectance=0; ter.WaterTransparency=0.7; ter.WaterWaveSize=0; ter.WaterWaveSpeed=0 end
    end)
    workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(pO,v) end end)
end

local function isMyPlotByName(pn)
    local ct=tick(); if Steal.plotCache[pn] and (ct-(Steal.plotCacheTime[pn] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[pn] end
    local plots=workspace:FindFirstChild("Plots"); if not plots then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local plot=plots:FindFirstChild(pn); if not plot then Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false end
    local sign=plot:FindFirstChild("PlotSign"); if sign then local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then local r=yb.Enabled==true; Steal.plotCache[pn]=r; Steal.plotCacheTime[pn]=ct; return r end end
    Steal.plotCache[pn]=false; Steal.plotCacheTime[pn]=ct; return false
end
local function findNearestPrompt()
    local c=LP.Character; if not c then return nil end; local root=c:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local ct=tick(); if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then
        local np,nd=nil,math.huge; for _,data in ipairs(Steal.cachedPrompts) do if data.spawn then local dist=(data.spawn.Position-root.Position).Magnitude; if dist<=Steal.StealRadius and dist<nd then np=data.prompt; nd=dist end end end; if np then return np end
    end
    Steal.cachedPrompts={}; Steal.promptCacheTime=ct; local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end; local np,nd=nil,math.huge
    for _,plot in ipairs(plots:GetChildren()) do if isMyPlotByName(plot.Name) then continue end; local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _,pod in ipairs(pods:GetChildren()) do pcall(function() local base=pod:FindFirstChild("Base"); local sp=base and base:FindFirstChild("Spawn"); if sp then
            local att=sp:FindFirstChild("PromptAttachment"); if att then for _,child in ipairs(att:GetChildren()) do if child:IsA("ProximityPrompt") then
                local dist=(sp.Position-root.Position).Magnitude; table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp}); if dist<=Steal.StealRadius and dist<nd then np=child; nd=dist end; break
            end end end
        end end) end
    end; return np
end
local function executeSteal(prompt)
    local ct=tick(); if ct-State.lastStealTick<STEAL_COOLDOWN or State.isStealing then return end
    if not Steal.Data[prompt] then Steal.Data[prompt]={hold={},trigger={},ready=true}
        pcall(function() if getconnections then for _,c2 in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c2.Function then table.insert(Steal.Data[prompt].hold,c2.Function) end end
            for _,c2 in ipairs(getconnections(prompt.Triggered)) do if c2.Function then table.insert(Steal.Data[prompt].trigger,c2.Function) end end
        else Steal.Data[prompt].useFallback=true end end)
    end
    local data=Steal.Data[prompt]; if not data.ready then return end; data.ready=false; State.isStealing=true; State.stealStartTime=ct; State.lastStealTick=ct
    if Conns.progress then Conns.progress:Disconnect() end
    Conns.progress=RunService.Heartbeat:Connect(function() if not State.isStealing then Conns.progress:Disconnect(); return end
        local prog=math.clamp((tick()-State.stealStartTime)/Steal.StealDuration,0,1); progressFill.Size=UDim2.new(prog,0,1,0); stealPctLbl.Text=math.floor(prog*100).."%" end)
    task.spawn(function()
        local ok=false; pcall(function() if not data.useFallback then for _,fn in ipairs(data.hold) do task.spawn(fn) end; task.wait(Steal.StealDuration); for _,fn in ipairs(data.trigger) do task.spawn(fn) end; ok=true end end)
        if not ok and fireproximityprompt then pcall(function() fireproximityprompt(prompt); ok=true end) end
        if not ok then pcall(function() prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd() end) end
        task.wait(Steal.StealDuration*0.3); if Conns.progress then Conns.progress:Disconnect() end; resetProgressBar(); task.wait(0.05); data.ready=true; State.isStealing=false
    end)
end
startAutoSteal=function() if Conns.autoSteal then return end
    Conns.autoSteal=RunService.Heartbeat:Connect(function() if not Steal.AutoStealEnabled or State.isStealing then return end; local p=findNearestPrompt(); if p then executeSteal(p) end end) end
stopAutoSteal=function() if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal=nil end
    State.isStealing=false; State.lastStealTick=0; Steal.plotCache={}; Steal.plotCacheTime={}; Steal.cachedPrompts={}; resetProgressBar() end

-- ============================================================
-- SAVE / LOAD CONFIG
-- ============================================================
saveConfig=function()
    local cfg={normalSpeed=State.normalSpeed,carrySpeed=State.carrySpeed,laggerSpeed=State.laggerSpeed,
        stealRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,uiScale=uiScaleObj and uiScaleObj.Scale or 1.0,
        stackButtonsHidden=State.stackButtonsHidden,speedKey=Keys.speed.Name,autoLeftKey=Keys.autoLeft.Name,
        autoRightKey=Keys.autoRight.Name,guiHideKey=Keys.guiHide.Name,dropKey=Keys.drop.Name,
        laggerKey=Keys.lagger.Name,tpDownKey=Keys.tpDown.Name,aimbotKey=Keys.aimbot.Name,
        infJump=State.infJumpEnabled,antiRagdoll=State.antiRagdollEnabled,fpsBoost=State.fpsBoostEnabled,
        medusaCounter=State.medusaCounterEnabled,batCounter=State.batCounterEnabled,autoStealEnabled=Steal.AutoStealEnabled,
        autoSwingEnabled=State.autoSwingEnabled,unwalkEnabled=State.unwalkEnabled,speedToggled=State.speedToggled,laggerEnabled=State.laggerEnabled}
    local ok,encoded=pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok then return pcall(function() _writefile(CONFIG_FILE,encoded) end) end; return false
end
loadConfig=function()
    local hasFile=false; pcall(function() hasFile=_isfile(CONFIG_FILE) end)
    if not hasFile then pcall(function() hasFile=_isfile("SpinkHubConfig.json") end) end
    if not hasFile then return end
    local raw; pcall(function() raw=_readfile(CONFIG_FILE) end)
    if not raw then pcall(function() raw=_readfile("SpinkHubConfig.json") end) end
    if not raw then return end
    local cfg; local ok2=pcall(function() cfg=HttpService:JSONDecode(raw) end)
    if not ok2 or not cfg then return end
    if cfg.normalSpeed then State.normalSpeed=cfg.normalSpeed; if normalBox then normalBox.Text=tostring(cfg.normalSpeed) end end
    if cfg.carrySpeed then State.carrySpeed=cfg.carrySpeed; if carryBox then carryBox.Text=tostring(cfg.carrySpeed) end end
    if cfg.laggerSpeed then State.laggerSpeed=cfg.laggerSpeed; if laggerBox then laggerBox.Text=tostring(cfg.laggerSpeed) end end
    if cfg.stealRadius then Steal.StealRadius=cfg.stealRadius end
    if cfg.stealDuration then Steal.StealDuration=cfg.stealDuration end
    if cfg.uiScale and uiScaleObj then uiScaleObj.Scale=cfg.uiScale; if uiScaleBox then uiScaleBox.Text=tostring(cfg.uiScale) end end
    if cfg.stackButtonsHidden then applyStackButtonsVisible(false); if setHideButtonsToggle then setHideButtonsToggle(true) end end
    local function tryKey(f,t) if cfg[f] and Enum.KeyCode[cfg[f]] then local kc=Enum.KeyCode[cfg[f]]; Keys[t]=kc; if keybindBtnRefs[t] then keybindBtnRefs[t].Text=getKeyDisplayName(kc) end end end
    tryKey("speedKey","speed"); tryKey("autoLeftKey","autoLeft"); tryKey("autoRightKey","autoRight")
    tryKey("guiHideKey","guiHide"); tryKey("dropKey","drop"); tryKey("laggerKey","lagger")
    tryKey("tpDownKey","tpDown"); tryKey("aimbotKey","aimbot")
    if cfg.autoStealEnabled then Steal.AutoStealEnabled=true; if setInstaGrab then setInstaGrab(true) end; pcall(startAutoSteal) end
    if cfg.infJump then State.infJumpEnabled=true; if setInfJump then setInfJump(true) end end
    if cfg.antiRagdoll then State.antiRagdollEnabled=true; if setAntiRag then setAntiRag(true) end; startAntiRagdoll() end
    if cfg.fpsBoost then State.fpsBoostEnabled=true; if setFps then setFps(true) end; applyFPSBoost() end
    if cfg.medusaCounter then State.medusaCounterEnabled=true; if setMedusaCounter then setMedusaCounter(true) end; setupMedusaCounter(LP.Character) end
    if cfg.batCounter then State.batCounterEnabled=true; if setBatCounter then setBatCounter(true) end; startBatCounter() end
    if cfg.autoSwingEnabled then State.autoSwingEnabled=true; if setAutoSwing then setAutoSwing(true) end end
    if cfg.unwalkEnabled then State.unwalkEnabled=true; if setUnwalkToggle then setUnwalkToggle(true) end; startUnwalk() end
    if cfg.speedToggled then State.speedToggled=true; if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(true) end end
    if cfg.laggerEnabled then State.laggerEnabled=true; if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(true) end end
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
local function setupChar(char)
    task.wait(0.1); h=char:WaitForChild("Humanoid",5); hrp=char:WaitForChild("HumanoidRootPart",5)
    if not h or not hrp then return end
    local head=char:FindFirstChild("Head")
    if head then
        local oldBB=head:FindFirstChild("AstroDuelsBB"); if oldBB then oldBB:Destroy() end
        local bb=Instance.new("BillboardGui",head); bb.Name="AstroDuelsBB"; bb.Size=UDim2.new(0,150,0,48)
        bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
        local speedBillLbl=Instance.new("TextLabel",bb); speedBillLbl.Name="SpeedBillLbl"
        speedBillLbl.Size=UDim2.new(1,0,0,22); speedBillLbl.Position=UDim2.new(0,0,0,0)
        speedBillLbl.BackgroundTransparency=1; speedBillLbl.Text="0.0"; speedBillLbl.TextColor3=PURPLE_GLOW
        speedBillLbl.Font=Enum.Font.GothamBlack; speedBillLbl.TextScaled=true
        speedBillLbl.TextStrokeTransparency=0.1; speedBillLbl.TextStrokeColor3=Color3.new(0,0,0)
        local lbl2=Instance.new("TextLabel",bb); lbl2.Size=UDim2.new(1,0,0,22); lbl2.Position=UDim2.new(0,0,0,26)
        lbl2.BackgroundTransparency=1; lbl2.Text="/astro duels"; lbl2.TextColor3=PURPLE_DK
        lbl2.Font=Enum.Font.GothamBold; lbl2.TextScaled=true
        lbl2.TextStrokeTransparency=0.1; lbl2.TextStrokeColor3=Color3.new(0,0,0)
    end
    if Conns.unwalk then Conns.unwalk:Disconnect(); Conns.unwalk=nil end; unwalkAnimateRef=nil
    if State.unwalkEnabled then task.wait(0.3); startUnwalk() end
    stopAntiRagdoll()
    if State.antiRagdollEnabled then task.wait(0.5); startAntiRagdoll() end
    if State.medusaCounterEnabled then setupMedusaCounter(char) end
    if State.batAimbotToggled then stopBatAimbot(); task.wait(0.2); pcall(startBatAimbot) end
    if State.batCounterEnabled then task.wait(0.3); startBatCounter() end
end
LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- ============================================================
-- RUNTIME
-- ============================================================
RunService.Stepped:Connect(function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then for _,part in ipairs(p.Character:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end end end
end)
UIS.JumpRequest:Connect(function()
    if not State.infJumpEnabled then return end; local c=LP.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart"); if root then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
end)
RunService.RenderStepped:Connect(function()
    if not (h and hrp) or State._tpInProgress then return end
    if not State.batAimbotToggled and not State.autoLeftEnabled and not State.autoRightEnabled then
        local md=h.MoveDirection; local spd
        if State.laggerEnabled then spd=State.laggerSpeed
        elseif State.speedToggled then spd=State.carrySpeed
        else spd=State.normalSpeed end
        if md.Magnitude>0 then State.lastMoveDir=md; hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
        elseif State.antiRagdollEnabled and State.lastMoveDir.Magnitude>0 then
            local anyHeld=false; for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true; break end end
            if anyHeld then hrp.Velocity=Vector3.new(State.lastMoveDir.X*spd,hrp.Velocity.Y,State.lastMoveDir.Z*spd) end
        end
    end
    pcall(function()
        local head2=LP.Character and LP.Character:FindFirstChild("Head")
        if head2 then local bb2=head2:FindFirstChild("AstroDuelsBB"); local sl=bb2 and bb2:FindFirstChild("SpeedBillLbl")
            if sl then sl.Text=string.format("%.1f",Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude) end end
    end)
end)

UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    local isKb=inp.UserInputType==Enum.UserInputType.Keyboard
    local isGp=inp.UserInputType==Enum.UserInputType.Gamepad1 or inp.UserInputType==Enum.UserInputType.Gamepad2 or inp.UserInputType==Enum.UserInputType.Gamepad3 or inp.UserInputType==Enum.UserInputType.Gamepad4
    if not isKb and not isGp then return end; local kc=inp.KeyCode; if kc==Enum.KeyCode.Unknown then return end
    if kc==Keys.speed then State.speedToggled=not State.speedToggled; if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
    elseif kc==Keys.autoLeft then
        State.autoLeftEnabled=not State.autoLeftEnabled; if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(State.autoLeftEnabled) end
        if State.autoLeftEnabled and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
        if State.autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
    elseif kc==Keys.autoRight then
        State.autoRightEnabled=not State.autoRightEnabled; if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(State.autoRightEnabled) end
        if State.autoRightEnabled and State.batAimbotToggled then State.batAimbotToggled=false; stopBatAimbot(); if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(false) end end
        if State.autoRightEnabled then startAutoRight() else stopAutoRight() end
    elseif kc==Keys.drop then if not State.dropEnabled then runDropBrainrot() end
    elseif kc==Keys.lagger then
        State.laggerEnabled=not State.laggerEnabled; if stackBtnRefs.lagger then stackBtnRefs.lagger.setOn(State.laggerEnabled) end
        if State.laggerEnabled then State._prevCarry=State.carrySpeed; State._prevSpeed=State.speedToggled; State.speedToggled=false
            if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(false) end; if carryBox then carryBox.Text=tostring(State.laggerSpeed) end
        else State.carrySpeed=State._prevCarry or 30; State.speedToggled=State._prevSpeed or false
            if carryBox then carryBox.Text=tostring(State.carrySpeed) end; if stackBtnRefs.carrySpeed then stackBtnRefs.carrySpeed.setOn(State.speedToggled) end
        end
    elseif kc==Keys.tpDown then doTpDown()
    elseif kc==Keys.aimbot then
        State.batAimbotToggled=not State.batAimbotToggled
        if State.batAimbotToggled then
            if State.autoLeftEnabled then State.autoLeftEnabled=false; stopAutoLeft(); if stackBtnRefs.autoLeft then stackBtnRefs.autoLeft.setOn(false) end end
            if State.autoRightEnabled then State.autoRightEnabled=false; stopAutoRight(); if stackBtnRefs.autoRight then stackBtnRefs.autoRight.setOn(false) end end
            pcall(startBatAimbot)
        else stopBatAimbot() end
        if stackBtnRefs.aimbot then stackBtnRefs.aimbot.setOn(State.batAimbotToggled) end
    elseif kc==Keys.guiHide then if isKb then State.guiVisible=not State.guiVisible; mainOuter.Visible=State.guiVisible end end
end)

loadConfig()
task.delay(1,function() pcall(saveConfig) end)
print("[Astro Duels] Loaded")
