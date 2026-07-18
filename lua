local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")

local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")
local _enabled  = true
local _seen     = {}
local _focused  = nil

local ANTHROPIC_KEY = "sk-ant-api03-placeholder-replace-with-real-key"

local T = {
    BG     = Color3.fromRGB(8,8,12),
    Card   = Color3.fromRGB(16,16,24),
    Border = Color3.fromRGB(38,38,58),
    Accent = Color3.fromRGB(80,140,255),
    Green  = Color3.fromRGB(70,210,100),
    Red    = Color3.fromRGB(255,70,70),
    Yellow = Color3.fromRGB(255,195,50),
    White  = Color3.fromRGB(215,225,255),
    Dim    = Color3.fromRGB(65,65,95),
}
local F = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function Tw(o,i,p) TweenService:Create(o,i,p):Play() end
local function Corner(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p
end
local function Stroke(p,col,th)
    local s=Instance.new("UIStroke"); s.Color=col or T.Border
    s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end

pcall(function()
    if game.CoreGui:FindFirstChild("SDLCPaste") then game.CoreGui.SDLCPaste:Destroy() end
end)
pcall(function()
    if playerGui:FindFirstChild("SDLCPaste") then playerGui.SDLCPaste:Destroy() end
end)

local GUI = Instance.new("ScreenGui")
GUI.Name="SDLCPaste"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true
GUI.DisplayOrder=999
if not pcall(function() GUI.Parent=game.CoreGui end) then GUI.Parent=playerGui end

local WIN_W = 205

local Win = Instance.new("Frame")
Win.Name="Win"
Win.Size=UDim2.new(0,WIN_W,0,10)
Win.AutomaticSize=Enum.AutomaticSize.Y
Win.AnchorPoint=Vector2.new(1,0)
Win.Position=UDim2.new(1,-14,0,52)
Win.BackgroundColor3=T.BG
Win.BackgroundTransparency=0
Win.BorderSizePixel=0
Win.ZIndex=100
Win.ClipsDescendants=true
Win.Parent=GUI
Corner(Win,10)

local WBorder=Stroke(Win, T.Accent, 1.4)
local WBG=Instance.new("UIGradient")
WBG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(25,55,160)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,140,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(25,55,160)),
})
WBG.Rotation=0
WBG.Parent=WBorder

RunService.RenderStepped:Connect(function(dt)
    WBG.Rotation = (WBG.Rotation + dt*55) % 360
end)

local WinList=Instance.new("UIListLayout")
WinList.FillDirection=Enum.FillDirection.Vertical
WinList.Padding=UDim.new(0,0)
WinList.SortOrder=Enum.SortOrder.LayoutOrder
WinList.HorizontalAlignment=Enum.HorizontalAlignment.Center
WinList.Parent=Win

local Hdr=Instance.new("Frame")
Hdr.Size=UDim2.new(1,0,0,36)
Hdr.BackgroundColor3=Color3.fromRGB(12,12,20)
Hdr.BackgroundTransparency=0
Hdr.BorderSizePixel=0
Hdr.LayoutOrder=1
Hdr.Active=true
Hdr.ZIndex=101
Hdr.Parent=Win
Corner(Hdr,10)

local HdrBG=Instance.new("UIGradient")
HdrBG.Color=ColorSequence.new(Color3.fromRGB(14,14,22), Color3.fromRGB(10,10,18))
HdrBG.Rotation=90
HdrBG.Parent=Hdr

local HdrFill=Instance.new("Frame")
HdrFill.Size=UDim2.new(1,0,0,10)
HdrFill.Position=UDim2.new(0,0,1,-10)
HdrFill.BackgroundColor3=Color3.fromRGB(12,12,20)
HdrFill.BorderSizePixel=0
HdrFill.ZIndex=101
HdrFill.Parent=Hdr

local HdrLine=Instance.new("Frame")
HdrLine.Size=UDim2.new(1,0,0,1)
HdrLine.Position=UDim2.new(0,0,1,0)
HdrLine.BackgroundColor3=T.Accent
HdrLine.BackgroundTransparency=0.55
HdrLine.BorderSizePixel=0
HdrLine.ZIndex=102
HdrLine.Parent=Hdr

local Logo=Instance.new("Frame")
Logo.Size=UDim2.new(0,18,0,18)
Logo.Position=UDim2.new(0,9,0.5,-9)
Logo.BackgroundColor3=T.Accent
Logo.BorderSizePixel=0
Logo.ZIndex=103
Logo.Parent=Hdr
Corner(Logo,5)
local LogoBG=Instance.new("UIGradient")
LogoBG.Color=ColorSequence.new(Color3.fromRGB(60,120,255), Color3.fromRGB(30,60,200))
LogoBG.Rotation=135
LogoBG.Parent=Logo
local LogoTxt=Instance.new("TextLabel")
LogoTxt.Size=UDim2.new(1,0,1,0)
LogoTxt.BackgroundTransparency=1
LogoTxt.Text="S"
LogoTxt.TextSize=10
LogoTxt.Font=Enum.Font.GothamBlack
LogoTxt.TextColor3=T.White
LogoTxt.TextXAlignment=Enum.TextXAlignment.Center
LogoTxt.TextYAlignment=Enum.TextYAlignment.Center
LogoTxt.ZIndex=104
LogoTxt.Parent=Logo

local TitleL=Instance.new("TextLabel")
TitleL.Size=UDim2.new(0,100,1,0)
TitleL.Position=UDim2.new(0,31,0,0)
TitleL.BackgroundTransparency=1
TitleL.RichText=true
TitleL.Text='<font color="rgb(90,150,255)">SDLC</font> <font color="rgb(170,190,255)" size="10">Paste</font>'
TitleL.TextSize=12
TitleL.Font=Enum.Font.GothamBold
TitleL.TextColor3=T.White
TitleL.TextXAlignment=Enum.TextXAlignment.Left
TitleL.TextYAlignment=Enum.TextYAlignment.Center
TitleL.ZIndex=102
TitleL.Parent=Hdr

local OnBtn=Instance.new("TextButton")
OnBtn.Size=UDim2.new(0,36,0,18)
OnBtn.AnchorPoint=Vector2.new(1,0.5)
OnBtn.Position=UDim2.new(1,-8,0.5,0)
OnBtn.BackgroundColor3=T.Green
OnBtn.BorderSizePixel=0
OnBtn.AutoButtonColor=false
OnBtn.Text="ON"
OnBtn.TextSize=9
OnBtn.Font=Enum.Font.GothamBold
OnBtn.TextColor3=Color3.fromRGB(8,8,12)
OnBtn.ZIndex=103
OnBtn.Parent=Hdr
Corner(OnBtn,5)
local OnS=Stroke(OnBtn,T.Green,1)

do
    local drag,ds,ws,mv
    Hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; mv=false; ds=inp.Position; ws=Win.Position
        end
    end)
    Hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            if not mv and d.Magnitude<5 then return end
            mv=true
            Win.Position=UDim2.new(ws.X.Scale,ws.X.Offset+d.X,ws.Y.Scale,ws.Y.Offset+d.Y)
        end
    end)
end

local Body=Instance.new("Frame")
Body.Size=UDim2.new(1,0,0,0)
Body.AutomaticSize=Enum.AutomaticSize.Y
Body.BackgroundTransparency=1
Body.BorderSizePixel=0
Body.LayoutOrder=2
Body.ZIndex=101
Body.Parent=Win

local BL=Instance.new("UIListLayout")
BL.FillDirection=Enum.FillDirection.Vertical
BL.Padding=UDim.new(0,5)
BL.HorizontalAlignment=Enum.HorizontalAlignment.Center
BL.Parent=Body

local BPad=Instance.new("UIPadding")
BPad.PaddingTop=UDim.new(0,7)
BPad.PaddingBottom=UDim.new(0,9)
BPad.PaddingLeft=UDim.new(0,8)
BPad.PaddingRight=UDim.new(0,8)
BPad.Parent=Body

local StatusCard=Instance.new("Frame")
StatusCard.Size=UDim2.new(1,0,0,26)
StatusCard.BackgroundColor3=T.Card
StatusCard.BackgroundTransparency=0
StatusCard.BorderSizePixel=0
StatusCard.ZIndex=102
StatusCard.Parent=Body
Corner(StatusCard,7)
Stroke(StatusCard,T.Border,1)

local SDot=Instance.new("Frame")
SDot.Size=UDim2.new(0,6,0,6)
SDot.Position=UDim2.new(0,8,0.5,-3)
SDot.BackgroundColor3=T.Dim
SDot.BorderSizePixel=0
SDot.ZIndex=103
SDot.Parent=StatusCard
Corner(SDot,3)

local SLbl=Instance.new("TextLabel")
SLbl.Size=UDim2.new(1,-22,1,0)
SLbl.Position=UDim2.new(0,18,0,0)
SLbl.BackgroundTransparency=1
SLbl.Text="Click the code box first"
SLbl.TextSize=10
SLbl.Font=Enum.Font.GothamMedium
SLbl.TextColor3=T.Dim
SLbl.TextXAlignment=Enum.TextXAlignment.Left
SLbl.TextYAlignment=Enum.TextYAlignment.Center
SLbl.ZIndex=103
SLbl.Parent=StatusCard

local CodeCard=Instance.new("Frame")
CodeCard.Size=UDim2.new(1,0,0,42)
CodeCard.BackgroundColor3=T.Card
CodeCard.BackgroundTransparency=0
CodeCard.BorderSizePixel=0
CodeCard.ZIndex=102
CodeCard.Parent=Body
Corner(CodeCard,7)
local CodeStroke=Stroke(CodeCard,T.Border,1)
local CodeBG=Instance.new("UIGradient")
CodeBG.Color=ColorSequence.new(Color3.fromRGB(14,14,22),Color3.fromRGB(11,11,18))
CodeBG.Rotation=90
CodeBG.Parent=CodeCard

local CodeSmall=Instance.new("TextLabel")
CodeSmall.Size=UDim2.new(1,-10,0,12)
CodeSmall.Position=UDim2.new(0,9,0,5)
CodeSmall.BackgroundTransparency=1
CodeSmall.Text="DETECTED"
CodeSmall.TextSize=7
CodeSmall.Font=Enum.Font.GothamBold
CodeSmall.TextColor3=T.Dim
CodeSmall.TextXAlignment=Enum.TextXAlignment.Left
CodeSmall.ZIndex=103
CodeSmall.Parent=CodeCard

local CodeVal=Instance.new("TextLabel")
CodeVal.Size=UDim2.new(1,-10,0,22)
CodeVal.Position=UDim2.new(0,9,0,17)
CodeVal.BackgroundTransparency=1
CodeVal.Text="—"
CodeVal.TextSize=17
CodeVal.Font=Enum.Font.GothamBlack
CodeVal.TextColor3=T.Dim
CodeVal.TextXAlignment=Enum.TextXAlignment.Left
CodeVal.TextYAlignment=Enum.TextYAlignment.Center
CodeVal.ZIndex=103
CodeVal.Parent=CodeCard

local RiddleCard=Instance.new("Frame")
RiddleCard.Size=UDim2.new(1,0,0,0)
RiddleCard.AutomaticSize=Enum.AutomaticSize.Y
RiddleCard.BackgroundColor3=Color3.fromRGB(30,22,8)
RiddleCard.BackgroundTransparency=0
RiddleCard.BorderSizePixel=0
RiddleCard.Visible=false
RiddleCard.ZIndex=102
RiddleCard.Parent=Body
Corner(RiddleCard,7)
Stroke(RiddleCard,T.Yellow,1)
local RiddlePad=Instance.new("UIPadding")
RiddlePad.PaddingTop=UDim.new(0,5); RiddlePad.PaddingBottom=UDim.new(0,6)
RiddlePad.PaddingLeft=UDim.new(0,8); RiddlePad.PaddingRight=UDim.new(0,8)
RiddlePad.Parent=RiddleCard
local RLL=Instance.new("UIListLayout")
RLL.FillDirection=Enum.FillDirection.Vertical
RLL.Padding=UDim.new(0,2)
RLL.Parent=RiddleCard
local RTag=Instance.new("TextLabel")
RTag.Size=UDim2.new(1,0,0,11)
RTag.BackgroundTransparency=1
RTag.Text="🧩 RIDDLE SOLVER"
RTag.TextSize=7; RTag.Font=Enum.Font.GothamBold
RTag.TextColor3=T.Yellow
RTag.TextXAlignment=Enum.TextXAlignment.Left
RTag.ZIndex=103; RTag.Parent=RiddleCard
local RMsg=Instance.new("TextLabel")
RMsg.Size=UDim2.new(1,0,0,14)
RMsg.BackgroundTransparency=1; RMsg.Text=""
RMsg.TextSize=10; RMsg.Font=Enum.Font.GothamMedium
RMsg.TextColor3=T.White; RMsg.TextXAlignment=Enum.TextXAlignment.Left
RMsg.TextWrapped=true; RMsg.ZIndex=103; RMsg.Parent=RiddleCard

local function setStatus(msg, col)
    col=col or T.Dim
    SLbl.Text=msg; SLbl.TextColor3=col; SDot.BackgroundColor3=col
end

local function flashCode(code, col)
    col=col or T.Accent
    CodeVal.Text=code; CodeVal.TextColor3=col
    Tw(CodeStroke, TweenInfo.new(0.1), {Color=col})
    task.delay(0.6, function()
        Tw(CodeStroke, TweenInfo.new(0.5), {Color=T.Border})
        Tw(CodeVal, TweenInfo.new(0.5), {TextColor3=col})
    end)
end

local function showRiddle(msg, col)
    RMsg.Text=msg; RMsg.TextColor3=col or T.White
    RiddleCard.Visible=true
end
local function hideRiddle()
    RiddleCard.Visible=false
end

OnBtn.MouseButton1Click:Connect(function()
    _enabled=not _enabled
    if _enabled then
        OnBtn.Text="ON"; OnBtn.BackgroundColor3=T.Green; OnS.Color=T.Green
        OnBtn.TextColor3=Color3.fromRGB(8,8,12)
        setStatus(_focused and "Ready — watching" or "Click the code box first",
            _focused and T.Green or T.Dim)
    else
        OnBtn.Text="OFF"; OnBtn.BackgroundColor3=T.Red; OnS.Color=T.Red
        OnBtn.TextColor3=T.White; setStatus("Paused",T.Dim)
    end
end)

UserInputService.TextBoxFocused:Connect(function(box)
    _focused=box
    if _enabled then setStatus("Ready — watching",T.Green) end
end)
UserInputService.TextBoxFocusReleased:Connect(function(box)
    if _focused==box then
        _focused=nil
        if _enabled then setStatus("Click the code box first",T.Dim) end
    end
end)

local function appendToBox(text)
    if not text or text=="" then return end
    if not _focused or not _focused.Parent then
        setStatus("Click the code box first!",T.Yellow)
        flashCode(text, T.Yellow)
        return
    end
    local cur=_focused.Text or ""
    if cur=="" then
        _focused.Text=text
    else
        _focused.Text=cur.." "..text
    end
    setStatus("Appended!",T.Green)
    flashCode(text,T.Green)
end

local RIDDLE_KW={
    "when was","how old","what year","what month","birthday","age of",
    "released","release date","hint","riddle","figure out","guess",
    "first letter","combine","spell","backwards","months","years",
    "old is","how many","what is","do you know","can you","which month",
    "which year","how long","since when",
}
local function isRiddle(txt)
    local l=txt:lower()
    for _,p in ipairs(RIDDLE_KW) do if l:find(p,1,true) then return true end end
    return false
end

local SAB={rm="MAY",ry="2024",rf="MAY2024",sa="24",c="MAY24"}
local function solveLocal(txt)
    local l=txt:lower()
    if (l:find("month") or l:find("when")) and (l:find("sab") or l:find("steal") or l:find("releas")) then return SAB.rm end
    if l:find("year") and (l:find("sab") or l:find("releas")) then return SAB.ry end
    if (l:find("when") or l:find("date")) and (l:find("sab") or l:find("steal") or l:find("releas")) then return SAB.rf end
    if (l:find("age") or l:find("old")) and l:find("sammy") then return SAB.sa end
    if (l:find("age") or l:find("old")) and (l:find("month") or l:find("when") or l:find("releas")) then return SAB.c end
    if l:find("may") and l:find("24") then return SAB.c end
    return nil
end

local function callAI(prompt)
    if not ANTHROPIC_KEY or ANTHROPIC_KEY=="" then return nil end
    local ok,result=pcall(function()
        local body=HttpService:JSONEncode({
            model="claude-sonnet-4-6",
            max_tokens=40,
            system="Decode Roblox promo codes for Steal a Brainrot (SAB). SAB released May 2024. Sammy is 24. Output ONLY the code uppercase no spaces nothing else.",
            messages={{role="user",content=prompt}}
        })
        local resp=HttpService:RequestAsync({
            Url="https://api.anthropic.com/v1/messages",
            Method="POST",
            Headers={
                ["Content-Type"]="application/json",
                ["x-api-key"]=ANTHROPIC_KEY,
                ["anthropic-version"]="2023-06-01",
            },
            Body=body,
        })
        if resp.StatusCode==200 then
            local data=HttpService:JSONDecode(resp.Body)
            if data and data.content and data.content[1] then return data.content[1].text end
        end
        return nil
    end)
    if ok and result then return tostring(result):match("^%s*([A-Z0-9_%-]+)%s*$") end
    return nil
end

-- YENİ GELİŞTİRİLMİŞ FİLTRE MOTORU
local CHAT_BLACKLIST = {
    "send starting in", "starting in", "font color", "size=", 
    "font face", "roblox", "creatorid", "system message", 
    "joined the game", "left the game", "setcreatorid"
}

local function cleanText(txt)
    if not txt then return "" end
    -- Tüm RichText HTML/Font taglarını temizler (<font ...>, </font>)
    return txt:gsub("<[^>]+>", "")
end

local function extractWords(txt)
    local cleanedTxt = cleanText(txt)
    local lowerTxt = cleanedTxt:lower()
    
    -- 1. Kelime bazlı genel karaliste kontrolü
    for _, badWord in ipairs(CHAT_BLACKLIST) do
        if lowerTxt:find(badWord, 1, true) then
            return nil
        end
    end
    
    local words = {}
    for w in cleanedTxt:gmatch("%S+") do
        -- Sadece harf ve sayıları tut, noktalama işaretlerini sil
        local clean = w:gsub("[^A-Za-z0-9]", "")
        local cleanLower = clean:lower()
        
        -- DİNAMİK SAYI FİLTRESİ (Gelişmiş regex kontrolü)
        -- "5k", "10k", "500k", "1m", "100k+", "25000" gibi tüm sayı varyasyonlarını tamamen bloklar
        local isNumberPattern = cleanLower:match("^%d+[km]%+?$") or cleanLower:match("^%d+$")
        
        if #clean >= 2 and not isNumberPattern then
            local isUpper = clean == clean:upper() and clean:match("[A-Z]")
            local isLower = clean == clean:lower() and clean:match("[a-z]") and #clean >= 3
            
            -- Kara listedeki tekil kelimelerle eşleşme kontrolü (Örn: "font")
            local isBlacklisted = false
            for _, badWord in ipairs(CHAT_BLACKLIST) do
                if cleanLower == badWord then isBlacklisted = true; break end
            end
            
            if (isUpper or isLower) and not isBlacklisted then
                table.insert(words, clean)
            end
        end
    end
    
    if #words > 0 then return table.concat(words, " ") end
    return nil
end

local function processGlobal(txt)
    if not _enabled then return end
    if not txt or type(txt)~="string" or #txt<2 then return end
    
    local cleaned = cleanText(txt)
    if _seen[cleaned] then return end
    _seen[cleaned]=true
    task.delay(20, function() _seen[cleaned]=nil end)

    if isRiddle(txt) then
        showRiddle("Solving...",T.Yellow)
        setStatus("Riddle detected...",T.Yellow)
        local ans=solveLocal(txt)
        if ans then
            showRiddle("Answer: "..ans,T.Green)
            setStatus("Solved: "..ans,T.Green)
            appendToBox(ans)
            task.delay(4,hideRiddle); return
        end
        showRiddle("Asking AI...",T.Yellow)
        task.spawn(function()
            local ai=callAI("Sammy said: \""..cleaned.."\". SAB=May2024,Sammy=24. Code only.")
            if ai then
                showRiddle("AI: "..ai,T.Green)
                setStatus("AI solved: "..ai,T.Green)
                appendToBox(ai)
                task.delay(4,hideRiddle)
            else
                showRiddle("Could not solve",T.Red)
                setStatus("Riddle unsolved",T.Red)
                task.delay(3,function()
                    hideRiddle()
                    setStatus(_focused and "Ready — watching" or "Click the code box first",
                        _focused and T.Green or T.Dim)
                end)
            end
        end)
        return
    end

    local words=extractWords(txt)
    if words then appendToBox(words) end
end

local _watched={}
local function watchLabel(obj)
    if _watched[obj] then return end
    _watched[obj]=true
    obj:GetPropertyChangedSignal("Text"):Connect(function()
        processGlobal(obj.Text)
    end)
end

local BAD={"backpack","inventory","chatmain","bubblechat","overhead","nametag","leaderboard","hudgui"}
local GOOD={"global","announce","notif","banner","broadcast","event","popup","sammy","alert","header","news","system","message","center"}
local function classify(obj)
    local n=(obj.Name or ""):lower()
    local pn=((obj.Parent and obj.Parent.Name) or ""):lower()
    local gpn=((obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Name) or ""):lower()
    for _,b in ipairs(BAD) do if n:find(b) or pn:find(b) then return false end end
    for _,g in ipairs(GOOD) do
        if n:find(g) or pn:find(g) or gpn:find(g) then return true end
    end
    for _, badWord in ipairs(CHAT_BLACKLIST) do
        if n:find(badWord) or pn:find(badWord) then return false end
    end
    return false
end

playerGui.DescendantAdded:Connect(function(obj)
    task.wait(0.04)
    if obj:IsA("TextLabel") then
        local txt=obj.Text or ""
        if classify(obj) or extractWords(txt) or isRiddle(txt) then
            watchLabel(obj)
            if #txt>1 then processGlobal(txt) end
        end
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            local t=obj.Text or ""
            if classify(obj) or extractWords(t) or isRiddle(t) then
                if not _watched[obj] then watchLabel(obj) end
                processGlobal(t)
            end
        end)
    end
end)

pcall(function()
    local tcs=game:GetService("TextChatService")
    if tcs and tcs.MessageReceived then
        tcs.MessageReceived:Connect(function(msg)
            if not msg then return end
            processGlobal(msg.Text or "")
        end)
    end
end)

pcall(function()
    local shared=ReplicatedStorage:WaitForChild("Shared",5)
    if not shared then return end
    local flags=shared:WaitForChild("Flags",5); if not flags then return end
    local cf=flags:WaitForChild("CodesFlags",5); if not cf then return end
    cf.ChildAdded:Connect(function(obj)
        processGlobal(obj.Name)
        if obj:IsA("StringValue") then
            processGlobal(tostring(obj.Value))
            obj:GetPropertyChangedSignal("Value"):Connect(function()
                processGlobal(tostring(obj.Value))
            end)
        end
    end)
end)

pcall(function()
    local ctrl=ReplicatedStorage:WaitForChild("Controllers",5)
    if not ctrl then return end
    local cc=ctrl:WaitForChild("CodesController",5); if not cc then return end
    cc.DescendantAdded:Connect(function(obj)
        if obj:IsA("StringValue") then processGlobal(tostring(obj.Value)) end
        processGlobal(obj.Name)
    end)
end)

setStatus("Click the code box first",T.Dim)
flashCode("—",T.Dim)
