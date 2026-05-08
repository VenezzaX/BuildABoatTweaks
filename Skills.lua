loadstring(game:HttpGet(('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'),true))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/emotes/refs/heads/main/tuffemotes.lua'),true))()

local Players             = game:GetService("Players")
local Workspace           = game:GetService("Workspace")
local HttpService         = game:GetService("HttpService")
local RunService          = game:GetService("RunService")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting            = game:GetService("Lighting")
local CoreGui             = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local HRP       = character:WaitForChild("HumanoidRootPart")
local blockData = player:WaitForChild("Data")
local blocksFolder = Workspace:WaitForChild("Blocks")

-- ============================================================
--  THEME
-- ============================================================
local T = {
    Base        = Color3.fromRGB(10,  10,  12),
    Surface     = Color3.fromRGB(16,  16,  19),
    Elevated    = Color3.fromRGB(22,  22,  26),
    Overlay     = Color3.fromRGB(30,  30,  36),
    Border      = Color3.fromRGB(38,  38,  45),
    BorderBright= Color3.fromRGB(58,  58,  70),
    TextPrimary = Color3.fromRGB(235, 235, 240),
    TextSecond  = Color3.fromRGB(110, 110, 125),
    TextDim     = Color3.fromRGB(60,  60,  72),
    Accent      = Color3.fromRGB(255, 160,  60),
    AccentDim   = Color3.fromRGB(100,  58,  14),
    AccentText  = Color3.fromRGB(20,  14,   4),
    OK          = Color3.fromRGB(52,  168, 100),
    OKHover     = Color3.fromRGB(62,  190, 115),
    Danger      = Color3.fromRGB(210,  60,  60),
    DangerHover = Color3.fromRGB(235,  72,  72),
    Info        = Color3.fromRGB(60,  140, 210),
    Warning     = Color3.fromRGB(220, 180,  50),
}

local FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tw(obj, props, info) TweenService:Create(obj, info or FAST, props):Play() end

-- ============================================================
--  DIRECTORY + INVENTORY
-- ============================================================
local FOLDER      = "HeavenlyPrinter"
local BACKUP_FILE = FOLDER .. "/AutoRecovery.json"
local JOB_FILE    = FOLDER .. "/LastJobCache.json"
if isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end

local MASTER_BLOCKS = {
    "PlasticBlock","IceBlock","MarbleBlock","SandBlock","GoldBlock","TitaniumBlock",
    "FabricBlock","MetalBlock","BrickBlock","ConcreteBlock","RustedBlock","WoodBlock",
    "NeonBlock","GlassBlock","ObsidianBlock","CoalBlock"
}
local BlockColors = {
    IceBlock=Color3.fromRGB(150,200,255), PlasticBlock=Color3.fromRGB(200,200,200),
    MarbleBlock=Color3.fromRGB(220,220,210), SandBlock=Color3.fromRGB(230,210,150),
    GoldBlock=Color3.fromRGB(255,215,0), TitaniumBlock=Color3.fromRGB(200,200,220),
    FabricBlock=Color3.fromRGB(255,100,100), MetalBlock=Color3.fromRGB(120,120,130),
    BrickBlock=Color3.fromRGB(170,80,50), ConcreteBlock=Color3.fromRGB(140,140,140),
    RustedBlock=Color3.fromRGB(130,90,60), WoodBlock=Color3.fromRGB(130,100,60),
    ObsidianBlock=Color3.fromRGB(40,30,60), CoalBlock=Color3.fromRGB(30,30,30),
    NeonBlock=Color3.fromRGB(0,255,255), GlassBlock=Color3.fromRGB(180,220,255)
}
local AllowedBlocks = {}
for _,b in ipairs(MASTER_BLOCKS) do AllowedBlocks[b]=true end

local currentInventory = {}
local function refreshInventorySnapshot()
    currentInventory = {}
    for _,n in ipairs(MASTER_BLOCKS) do
        local v = blockData:FindFirstChild(n)
        if AllowedBlocks[n] and v and v.Value > 0 then currentInventory[n] = v.Value end
    end
end
local function scanInventory()
    local total = 0
    for _,n in ipairs(MASTER_BLOCKS) do
        local v = blockData:FindFirstChild(n)
        if AllowedBlocks[n] and v and v.Value > 0 then total += v.Value end
    end
    return total
end
local function getNextAvailableBlock()
    for _,n in ipairs(MASTER_BLOCKS) do
        if AllowedBlocks[n] and currentInventory[n] and currentInventory[n] > 0 then
            currentInventory[n] -= 1; return n
        end
    end
end

-- ============================================================
--  SHARED UTILITIES
-- ============================================================
local function mathRound(n) return math.floor(n + 0.5) end
local function posToKey(v)
    return string.format("%.1f_%.1f_%.1f",
        mathRound(v.X*10)/10, mathRound(v.Y*10)/10, mathRound(v.Z*10)/10)
end
local function getPlayerZone(p)
    if not p then return nil end
    local tc = p.TeamColor
    for _,v in pairs(Workspace:GetChildren()) do
        if v:FindFirstChild("TeamColor") and v.TeamColor.Value == tc then return v end
    end
end
local function getPlayerBase()
    for _,c in pairs(blocksFolder:GetChildren()) do
        if c.Name == player.Name then return c end
    end
end
local function getTool(name)
    if character:FindFirstChild(name) then return character[name] end
    local t = player.Backpack:FindFirstChild(name)
    if t then humanoid:EquipTool(t); task.wait() end
    return character:FindFirstChild(name)
end
local function placeBlock(name, pos, relativeTo, anchored)
    local tool = getTool("BuildingTool")
    if tool then task.spawn(function() pcall(function()
        local isA = (anchored == nil) and true or anchored
        tool.RF:InvokeServer(name,
            (blockData:FindFirstChild(name) and blockData[name].Value or 9),
            relativeTo,
            relativeTo and relativeTo.CFrame:ToObjectSpace(pos) or CFrame.new(),
            isA, pos, false)
    end) end) end
end
local function rescaleBlock(block, newSize, newCFrame)
    local tool = getTool("ScalingTool")
    if tool then task.spawn(function() pcall(function() tool.RF:InvokeServer(block, newSize, newCFrame) end) end) end
end
local function paintBlock(block, color)
    if block and block:FindFirstChild("PPart") and block.PPart.Color ~= color then
        local tool = getTool("PaintingTool")
        if tool then task.spawn(function() pcall(function() tool.RF:InvokeServer({{block, color}}) end) end) end
    end
end
local function getJoint(model)
    for _,v in pairs(model.PPart:GetChildren()) do
        if (v:IsA("Snap") or v:IsA("Weld")) and v.Part1 and v.Part1.Parent ~= model then return v.Part1 end
    end
    return getPlayerZone(player)
end
local function getNewBlockPos(hisBase, block, myBase)
    if not block or not block:FindFirstChild("PPart") then return CFrame.new() end
    if not hisBase or not myBase then return block.PPart.CFrame end
    return myBase.CFrame * hisBase.CFrame:ToObjectSpace(block.PPart.CFrame)
end

-- ============================================================
--  COPY / PASTE ENGINE
-- ============================================================
local usedList, clipboard, selectedBase, pastePercent, ignoreAnchored = {}, nil, nil, 0, true
local function copyBuild(blocks)
    local t = {}
    local myBase  = getPlayerZone(player)
    local hisBase = getPlayerZone(Players:FindFirstChild(blocks.Name))
    usedList = {}
    for _,block in ipairs(blocks:GetChildren()) do
        if block:FindFirstChild("PPart") then
            local id   = blockData:FindFirstChild(block.Name) and blockData[block.Name].Value or 9
            local used = usedList[block.Name] or 0
            if id == 0 or used >= id then continue end
            usedList[block.Name] = used + 1
            local rel = getJoint(block)
            if rel == hisBase then rel = myBase end
            table.insert(t, {
                Name        = block.Name,
                Pos         = getNewBlockPos(hisBase, block, myBase),
                Relative    = myBase,
                Transparency= block.PPart.Transparency,
                Anchored    = block.PPart.Anchored,
                Size        = block.PPart.Size,
                Color       = block.PPart.Color,
            })
        end
    end
    return t
end
local function getClosestBlock(expectedPos, list)
    local best, bestDist = nil, math.huge
    for _,b in ipairs(list) do
        if b and b:FindFirstChild("PPart") then
            local d = (b.PPart.Position - expectedPos.Position).Magnitude
            if d < bestDist then bestDist = d; best = b end
        end
    end
    return best
end
local function pasteBuild(t, folder, offsetCF)
    pastePercent = 0
    local tCount, lastAdded = #t, tick()
    local conn = folder.ChildAdded:Connect(function() lastAdded = tick() end)
    for i,v in ipairs(t) do
        placeBlock(v.Name, v.Pos * offsetCF, v.Relative, ignoreAnchored and true or v.Anchored)
        pastePercent = math.floor((i / tCount) * 50)
        if i % 20 == 0 then task.wait(0.05) end
    end
    repeat task.wait(0.1) until tick() - lastAdded > 5
    local baseList = folder:GetChildren()
    for i,v in ipairs(t) do
        local b = getClosestBlock(v.Pos * offsetCF, baseList)
        if b then rescaleBlock(b, v.Size, v.Pos * offsetCF); paintBlock(b, v.Color) end
        pastePercent = 50 + math.floor((i / tCount) * 50)
        if i % 20 == 0 then task.wait(0.05) end
    end
    conn:Disconnect(); pastePercent = 0
end

-- ============================================================
--  AUTO PILOT
-- ============================================================
local autofarm, stageIndex, tweening, AUTOFARM_SPEED, ignoreChest = false, 1, false, 20, false
local autoPilotEnabled, autoPilotConnection, apBV, apBG = false, nil, nil, nil
local AP_SPEED, AP_ALTITUDE, AP_WAYPOINT_RADIUS, AP_ARRIVAL_RADIUS, AP_ALT_STRENGTH = 120, 80, 60, 100, 4
local straightAPEnabled, straightAPConnection, straightAPBV, straightAPBG, straightAPPart = false, nil, nil, nil, nil
local STRAIGHT_AP_SPEED = 70

local function getCar() return humanoid.SeatPart and humanoid.SeatPart.Parent or nil end
local function buildWaypoints()
    local ns = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
    if not ns then return nil end
    local wps = {}
    for i = 1, 10 do
        local stage = ns:FindFirstChild("CaveStage"..i)
        local dp = stage and stage:FindFirstChild("DarknessPart")
        if dp then table.insert(wps, Vector3.new(dp.Position.X, AP_ALTITUDE, dp.Position.Z)) end
    end
    local es = ns:FindFirstChild("TheEnd")
    local ch = es and es:FindFirstChild("GoldenChest")
    if ch then table.insert(wps, ch:GetPivot().Position + Vector3.new(0, 10, -10)) end
    return #wps > 0 and wps or nil
end
local function attachWaypointPhysics(part)
    if part:FindFirstChild("AP_BV") then part.AP_BV:Destroy() end
    if part:FindFirstChild("AP_BG") then part.AP_BG:Destroy() end
    apBV = Instance.new("BodyVelocity"); apBV.Name="AP_BV"; apBV.MaxForce=Vector3.new(9e9,9e9,9e9); apBV.Velocity=Vector3.zero; apBV.Parent=part
    apBG = Instance.new("BodyGyro"); apBG.Name="AP_BG"; apBG.MaxTorque=Vector3.new(9e9,9e9,9e9); apBG.P=3000; apBG.D=300; apBG.CFrame=part.CFrame; apBG.Parent=part
end
local function stopAutoPilot()
    autoPilotEnabled = false
    if autoPilotConnection then autoPilotConnection:Disconnect(); autoPilotConnection = nil end
    if apBV then apBV:Destroy(); apBV = nil end
    if apBG then apBG:Destroy(); apBG = nil end
end
local function startAutoPilot()
    local car  = getCar()
    local part = car and (car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart"))
    local wps  = buildWaypoints()
    if not part or not wps then autoPilotEnabled = false; return end
    attachWaypointPhysics(part); autoPilotEnabled = true
    local wpIndex = 1
    autoPilotConnection = RunService.RenderStepped:Connect(function()
        if not autoPilotEnabled then stopAutoPilot(); return end
        car  = humanoid.SeatPart and humanoid.SeatPart.Parent or nil
        part = car and (car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart"))
        if not part then stopAutoPilot(); return end
        if not apBV or not apBV.Parent then attachWaypointPhysics(part) end
        local pos       = part.Position
        local targetPos = Vector3.new(wps[wpIndex].X, AP_ALTITUDE, wps[wpIndex].Z)
        local flatDist  = Vector3.new(targetPos.X-pos.X, 0, targetPos.Z-pos.Z).Magnitude
        local isLast    = wpIndex == #wps
        if flatDist < (isLast and AP_ARRIVAL_RADIUS or AP_WAYPOINT_RADIUS) then
            if isLast then stopAutoPilot(); return end
            wpIndex += 1; targetPos = Vector3.new(wps[wpIndex].X, AP_ALTITUDE, wps[wpIndex].Z)
        end
        local dir     = targetPos - pos
        local dirNorm = dir.Magnitude > 0 and dir.Unit or Vector3.new(0,0,-1)
        local altErr  = AP_ALTITUDE - pos.Y
        apBV.Velocity = dirNorm*AP_SPEED + Vector3.new(0, math.clamp(altErr*AP_ALT_STRENGTH,-AP_SPEED*0.5,AP_SPEED*0.5), 0)
        local flat = Vector3.new(dirNorm.X, 0, dirNorm.Z)
        if flat.Magnitude > 0.01 then
            apBG.CFrame = CFrame.new(pos, pos + Vector3.new(flat.X, math.clamp(altErr*0.01,-0.3,0.3), flat.Z).Unit)
        end
    end)
end
local function stopStraightAutoPilot()
    straightAPEnabled = false
    if straightAPConnection then straightAPConnection:Disconnect(); straightAPConnection = nil end
    if straightAPBV then straightAPBV:Destroy(); straightAPBV = nil end
    if straightAPBG then straightAPBG:Destroy(); straightAPBG = nil end
    straightAPPart = nil
end
local function startStraightAutoPilot()
    if autoPilotEnabled then straightAPEnabled = false; return end
    local seat    = humanoid.SeatPart
    local vehicle = seat and seat.Parent
    local part    = vehicle and vehicle.PrimaryPart or seat
    if not part then straightAPEnabled = false; return end
    if part:FindFirstChild("StraightAP_BV") then part.StraightAP_BV:Destroy() end
    if part:FindFirstChild("StraightAP_BG") then part.StraightAP_BG:Destroy() end
    local locked = part.CFrame
    straightAPBG = Instance.new("BodyGyro"); straightAPBG.Name="StraightAP_BG"; straightAPBG.MaxTorque=Vector3.new(9e9,9e9,9e9); straightAPBG.P=3000; straightAPBG.D=250; straightAPBG.CFrame=locked; straightAPBG.Parent=part
    straightAPBV = Instance.new("BodyVelocity"); straightAPBV.Name="StraightAP_BV"; straightAPBV.MaxForce=Vector3.new(9e9,9e9,9e9); straightAPBV.Velocity=locked.LookVector*STRAIGHT_AP_SPEED; straightAPBV.Parent=part
    straightAPPart = part; straightAPEnabled = true
    straightAPConnection = RunService.Heartbeat:Connect(function()
        if not straightAPEnabled then return end
        if not straightAPPart or not straightAPPart.Parent then stopStraightAutoPilot(); return end
        if not straightAPBV or not straightAPBV.Parent then
            straightAPBV = Instance.new("BodyVelocity"); straightAPBV.Name="StraightAP_BV"
            straightAPBV.MaxForce=Vector3.new(9e9,9e9,9e9); straightAPBV.Velocity=locked.LookVector*STRAIGHT_AP_SPEED; straightAPBV.Parent=straightAPPart
        end
        if not straightAPBG or not straightAPBG.Parent then
            straightAPBG = Instance.new("BodyGyro"); straightAPBG.Name="StraightAP_BG"
            straightAPBG.MaxTorque=Vector3.new(9e9,9e9,9e9); straightAPBG.P=3000; straightAPBG.D=250; straightAPBG.CFrame=locked; straightAPBG.Parent=straightAPPart
        end
        straightAPBV.Velocity = locked.LookVector * STRAIGHT_AP_SPEED
    end)
end

-- ============================================================
--  PRINTER ENGINE
-- ============================================================
local isPrinting = false
local pendingBlocksData = nil
local missedBlocksBuffer = {}
local UpdateStatusLine, UpdateResumeTabUI  -- forward declared

local function clearPreview()
    local old = Workspace:FindFirstChild("ImagePrinterPreview")
    if old then old:Destroy() end
end
local function generatePreview(blocks)
    clearPreview()
    local f = Instance.new("Folder"); f.Name="ImagePrinterPreview"; f.Parent=Workspace
    for _,e in ipairs(blocks) do
        local p = Instance.new("Part"); p.Size=e.Size; p.CFrame=e.Pos; p.Color=e.Color
        p.Transparency=0.5; p.Anchored=true; p.CanCollide=false; p.Parent=f
    end
end
local function saveCrashBackup(rem)
    if not (writefile and HttpService) then return end
    local s = {}
    for _,b in ipairs(rem) do
        table.insert(s,{Pos={b.Pos:GetComponents()},Size={b.Size.X,b.Size.Y,b.Size.Z},Color={b.Color.R,b.Color.G,b.Color.B},BlockName=b.BlockName})
    end
    pcall(function() writefile(BACKUP_FILE, HttpService:JSONEncode(s)) end)
end
local function clearCrashBackup()
    if isfile and isfile(BACKUP_FILE) then pcall(function() delfile(BACKUP_FILE) end) end
end
local function saveJobCache(url, res, width, thick, removeBg, orient)
    if not (writefile and HttpService) then return end
    pcall(function() writefile(JOB_FILE, HttpService:JSONEncode({Url=url,Resolution=res,Width=width,Thickness=thick,RemoveBg=removeBg,Orientation=orient})) end)
end

local function executeInstaBlast(expectedBlocks, printSpeed, paintSpeed, batchSize, cooldownTime)
    isPrinting = true
    local myZone      = getPlayerZone(player)
    local myBaseFolder= getPlayerBase()
    if not myZone or not myBaseFolder then
        UpdateStatusLine("Plot not found.", T.Danger); isPrinting = false; return
    end
    UpdateStatusLine("Smart Sync — scanning plot…", T.Accent)

    -- build map of what already exists
    local initialMap = {}
    for _,child in ipairs(myBaseFolder:GetChildren()) do
        local p = child:FindFirstChild("PPart") or child
        initialMap[posToKey(myZone.CFrame:ToObjectSpace(p.CFrame).Position)] = child
    end
    local toSpawn = {}
    for _,e in ipairs(expectedBlocks) do
        if not initialMap[posToKey(myZone.CFrame:ToObjectSpace(e.Pos).Position)] then
            table.insert(toSpawn, e)
        end
    end

    -- place pass
    if #toSpawn > 0 then
        local batch = 0; local startTime = tick()
        for i,e in ipairs(toSpawn) do
            if not isPrinting then break end
            placeBlock(e.BlockName, e.Pos, myZone, true)
            batch += 1
            if i % 10 == 0 then
                local rate = i / math.max(tick()-startTime, 0.001)
                UpdateStatusLine(string.format("Placing %d / %d  ·  ETA %.0fs", i, #toSpawn, (#toSpawn-i)/rate), T.Accent)
            end
            if batch >= batchSize then
                UpdateStatusLine(string.format("Cooldown %.1fs…", cooldownTime), T.TextSecond)
                task.wait(cooldownTime); batch = 0
            end
            if i % printSpeed == 0 then task.wait() end
        end
        UpdateStatusLine("Awaiting replication…", T.TextSecond); task.wait(4)
    end

    -- paint pass
    local finalMap = {}
    for _,child in ipairs(myBaseFolder:GetChildren()) do
        local p = child:FindFirstChild("PPart") or child
        finalMap[posToKey(myZone.CFrame:ToObjectSpace(p.CFrame).Position)] = child
    end
    local paintBatch = 0; local missed = 0
    missedBlocksBuffer = {}
    local startTime = tick()
    for i,e in ipairs(expectedBlocks) do
        if not isPrinting then break end
        local target = finalMap[posToKey(myZone.CFrame:ToObjectSpace(e.Pos).Position)]
        if target then
            rescaleBlock(target, e.Size, e.Pos); paintBlock(target, e.Color); paintBatch += 1
        else
            table.insert(missedBlocksBuffer, e); missed += 1
        end
        if i % 10 == 0 then
            local rate = i / math.max(tick()-startTime, 0.001)
            UpdateStatusLine(string.format("Painting %d / %d  ·  ETA %.0fs", i, #expectedBlocks, (#expectedBlocks-i)/rate), T.Info)
        end
        if paintBatch >= batchSize then
            UpdateStatusLine(string.format("Paint cooldown %.1fs…", cooldownTime), T.TextSecond)
            task.wait(cooldownTime); paintBatch = 0
        end
        if i % paintSpeed == 0 then task.wait() end
    end

    clearPreview(); isPrinting = false
    if missed > 0 then
        saveCrashBackup(missedBlocksBuffer)
        UpdateStatusLine(string.format("%d blocks missed — see Recovery.", missed), T.Danger)
        if UpdateResumeTabUI then UpdateResumeTabUI(true, missed) end
    else
        missedBlocksBuffer = {}; clearCrashBackup()
        UpdateStatusLine("Print complete — 100% synced.", T.OK)
        if UpdateResumeTabUI then UpdateResumeTabUI(false, 0) end
    end
end

-- ============================================================
--  GUI ROOT
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HeavenlyHub_V15"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local _ok = pcall(function() ScreenGui.Parent = CoreGui end)
if not _ok then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

local WIN_W, WIN_H = 540, 600

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, WIN_W, 0, WIN_H)
MainFrame.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
MainFrame.BackgroundColor3 = T.Base
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local outerStroke = Instance.new("UIStroke", MainFrame)
outerStroke.Color = T.Border; outerStroke.Thickness = 1

local AccentLine = Instance.new("Frame", MainFrame)
AccentLine.Size = UDim2.new(1,0,0,2); AccentLine.BackgroundColor3 = T.Accent
AccentLine.BorderSizePixel = 0; AccentLine.ZIndex = 10

-- TOPBAR
local Topbar = Instance.new("Frame", MainFrame)
Topbar.Size = UDim2.new(1,0,0,46); Topbar.BackgroundTransparency = 1; Topbar.ZIndex = 5

for i, dc in ipairs({Color3.fromRGB(200,80,80), Color3.fromRGB(200,170,60), Color3.fromRGB(60,180,100)}) do
    local dot = Instance.new("Frame", Topbar)
    dot.Size = UDim2.new(0,9,0,9); dot.Position = UDim2.new(0,14+(i-1)*16,0.5,-4)
    dot.BackgroundColor3 = dc; dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
end

local TitleLbl = Instance.new("TextLabel", Topbar)
TitleLbl.Size = UDim2.new(1,-110,1,0); TitleLbl.Position = UDim2.new(0,68,0,0)
TitleLbl.BackgroundTransparency = 1; TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 13; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.TextColor3 = T.TextPrimary; TitleLbl.RichText = true
TitleLbl.Text = 'BABFT Hub  <font color="#3a3a46">//</font>  <font color="#FFA03C">xzyp | .gg/xe-no</font>  <font color="#3a3a46">v15</font>'

local function MakeWinBtn(xOff, icon, hoverClr)
    local b = Instance.new("TextButton", Topbar)
    b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = T.Elevated; b.Font = Enum.Font.GothamBold
    b.TextSize = 11; b.Text = icon; b.TextColor3 = T.TextSecond
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hoverClr,TextColor3=T.TextPrimary}) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=T.Elevated,TextColor3=T.TextSecond}) end)
    return b
end
local MinBtn   = MakeWinBtn(-35, "—", Color3.fromRGB(180,150,40))
local CloseBtn = MakeWinBtn(-66, "✕", Color3.fromRGB(190,60,60))

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    tw(MainFrame, {Size = isMinimized and UDim2.new(0,WIN_W,0,48) or UDim2.new(0,WIN_W,0,WIN_H)}, MED)
end)

-- drag
local dragging, dragStart, startPos
Topbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; startPos=MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- RightShift toggle
UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- separators + status bar
local Sep1 = Instance.new("Frame", MainFrame)
Sep1.Size=UDim2.new(1,0,0,1); Sep1.Position=UDim2.new(0,0,0,46)
Sep1.BackgroundColor3=T.Border; Sep1.BorderSizePixel=0

local StatusBar = Instance.new("Frame", MainFrame)
StatusBar.Size=UDim2.new(1,0,0,28); StatusBar.Position=UDim2.new(0,0,1,-28)
StatusBar.BackgroundColor3=T.Surface; StatusBar.BorderSizePixel=0

local StatusSepF = Instance.new("Frame", StatusBar)
StatusSepF.Size=UDim2.new(1,0,0,1); StatusSepF.BackgroundColor3=T.Border; StatusSepF.BorderSizePixel=0

local StatusDot = Instance.new("Frame", StatusBar)
StatusDot.Size=UDim2.new(0,6,0,6); StatusDot.Position=UDim2.new(0,12,0.5,-3)
StatusDot.BackgroundColor3=T.TextDim; StatusDot.BorderSizePixel=0
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1,0)

local StatusLbl = Instance.new("TextLabel", StatusBar)
StatusLbl.Size=UDim2.new(1,-30,1,0); StatusLbl.Position=UDim2.new(0,24,0,0)
StatusLbl.BackgroundTransparency=1; StatusLbl.Font=Enum.Font.Gotham
StatusLbl.TextSize=11; StatusLbl.TextColor3=T.TextSecond
StatusLbl.TextXAlignment=Enum.TextXAlignment.Left; StatusLbl.Text="Ready."

UpdateStatusLine = function(text, color)
    StatusLbl.Text = text
    local c = color or T.TextSecond
    tw(StatusLbl, {TextColor3=c}); tw(StatusDot, {BackgroundColor3=c})
end

-- ============================================================
--  TAB BAR + CONTENT AREA
-- ============================================================
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size=UDim2.new(1,-24,0,34); TabBar.Position=UDim2.new(0,12,0,53)
TabBar.BackgroundTransparency=1
local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection=Enum.FillDirection.Horizontal; TabLayout.Padding=UDim.new(0,2)
TabLayout.SortOrder=Enum.SortOrder.LayoutOrder

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Size=UDim2.new(1,-24,1,-120); ContentArea.Position=UDim2.new(0,12,0,94)
ContentArea.BackgroundTransparency=1

local tabList, pageList, activeTab = {}, {}, 0

local TAB_NAMES = {"PRINT","BUILD","AUTO","MATS","RECOVER","PLAYER"}
local function SwitchTab(index)
    activeTab = index
    for i,t in ipairs(tabList) do
        local active = (i == index)
        tw(t.Btn, {TextColor3 = active and T.TextPrimary or T.TextSecond})
        tw(t.Bg,  {BackgroundColor3 = active and T.Elevated or T.Surface})
        tw(t.Bar, {BackgroundColor3 = active and T.Accent or Color3.fromRGB(0,0,0)})
        pageList[i].Visible = active
    end
end

for i, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size=UDim2.new(1/#TAB_NAMES,-2,1,0); btn.BackgroundColor3=T.Surface
    btn.Font=Enum.Font.GothamSemibold; btn.TextSize=11; btn.Text=name
    btn.TextColor3=T.TextSecond; btn.AutoButtonColor=false; btn.LayoutOrder=i
    Instance.new("UICorner", btn).CornerRadius=UDim.new(0,5)

    local bar = Instance.new("Frame", btn)
    bar.Size=UDim2.new(0.6,0,0,2); bar.Position=UDim2.new(0.2,0,1,-2)
    bar.BackgroundColor3=Color3.fromRGB(0,0,0); bar.BorderSizePixel=0
    Instance.new("UICorner", bar).CornerRadius=UDim.new(1,0)

    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.ScrollBarThickness=3; page.ScrollBarImageColor3=T.Border; page.Visible=false
    local lay = Instance.new("UIListLayout", page)
    lay.Padding=UDim.new(0,6); lay.SortOrder=Enum.SortOrder.LayoutOrder
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+12)
    end)
    btn.MouseButton1Click:Connect(function() SwitchTab(i) end)
    btn.MouseEnter:Connect(function() if activeTab~=i then tw(btn,{BackgroundColor3=T.Overlay}) end end)
    btn.MouseLeave:Connect(function() if activeTab~=i then tw(btn,{BackgroundColor3=T.Surface}) end end)

    table.insert(tabList, {Btn=btn, Bg=btn, Bar=bar})
    table.insert(pageList, page)
end

local PagePrint, PageBuild, PageFarm, PageMats, PageResume, PagePlayer =
    pageList[1], pageList[2], pageList[3], pageList[4], pageList[5], pageList[6]

SwitchTab(1)

-- ============================================================
--  COMPONENT LIBRARY
-- ============================================================
local function Section(parent, text)
    local row = Instance.new("Frame", parent)
    row.Size=UDim2.new(1,0,0,22); row.BackgroundTransparency=1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,0,1,-6); lbl.Position=UDim2.new(0,0,0,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
    lbl.TextColor3=T.TextDim; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text:upper()
    local rule = Instance.new("Frame", row)
    rule.Size=UDim2.new(1,0,0,1); rule.Position=UDim2.new(0,0,1,-1)
    rule.BackgroundColor3=T.Border; rule.BorderSizePixel=0
end

local function Input(parent, placeholder, default)
    local wrap = Instance.new("Frame", parent)
    wrap.Size=UDim2.new(1,0,0,34); wrap.BackgroundColor3=T.Base
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,6)
    local stroke = Instance.new("UIStroke", wrap); stroke.Color=T.Border; stroke.Thickness=1
    local box = Instance.new("TextBox", wrap)
    box.Size=UDim2.new(1,0,1,0); box.BackgroundTransparency=1
    box.Font=Enum.Font.Gotham; box.TextSize=12; box.TextColor3=T.TextPrimary
    box.PlaceholderColor3=T.TextDim; box.Text=default or ""; box.PlaceholderText=placeholder or ""
    box.TextXAlignment=Enum.TextXAlignment.Left
    local pad = Instance.new("UIPadding", box)
    pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
    box.Focused:Connect(function() tw(stroke,{Color=T.Accent}) end)
    box.FocusLost:Connect(function() tw(stroke,{Color=T.Border}) end)
    return box, wrap
end

local function Btn(parent, text, base, hover, textColor)
    local b = Instance.new("TextButton", parent)
    b.Size=UDim2.new(1,0,0,36); b.BackgroundColor3=base or T.Elevated
    b.Font=Enum.Font.GothamBold; b.TextSize=12
    b.TextColor3=textColor or T.TextPrimary; b.Text=text; b.AutoButtonColor=false
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=hover or T.Overlay}) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=base or T.Elevated}) end)
    return b
end

local function Toggle(parent, label, default, callback)
    local row = Instance.new("TextButton", parent)
    row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=T.Surface
    row.AutoButtonColor=false; row.Text=""
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local stroke = Instance.new("UIStroke", row); stroke.Color=T.Border; stroke.Thickness=1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-56,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextColor3=T.TextSecond; lbl.Text=label

    local track = Instance.new("Frame", row)
    track.Size=UDim2.new(0,34,0,18); track.Position=UDim2.new(1,-46,0.5,-9)
    track.BackgroundColor3=T.Base; track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local knob = Instance.new("Frame", track)
    knob.Size=UDim2.new(0,12,0,12); knob.Position=UDim2.new(0,3,0.5,-6)
    knob.BackgroundColor3=T.TextDim; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local state = default or false
    local function refresh()
        tw(track, {BackgroundColor3 = state and T.AccentDim or T.Base})
        tw(knob,  {BackgroundColor3 = state and T.Accent or T.TextDim,
                   Position         = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)})
        tw(lbl,   {TextColor3 = state and T.TextPrimary or T.TextSecond})
        tw(stroke,{Color = state and T.AccentDim or T.Border})
    end
    refresh()
    row.MouseButton1Click:Connect(function()
        state = not state; refresh()
        if callback then callback(state) end
    end)
    return row,
        function() return state end,
        function(v) state=v; refresh(); if callback then callback(state) end end
end

-- ── SLIDER (fixed: uses absolute position correctly) ──────────
local function Slider(parent, label, minVal, maxVal, default)
    local wrap = Instance.new("Frame", parent)
    wrap.Size=UDim2.new(1,0,0,50); wrap.BackgroundColor3=T.Surface
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",wrap).Color=T.Border

    local nameLbl = Instance.new("TextLabel", wrap)
    nameLbl.Size=UDim2.new(1,-60,0,20); nameLbl.Position=UDim2.new(0,10,0,8)
    nameLbl.BackgroundTransparency=1; nameLbl.Font=Enum.Font.GothamMedium; nameLbl.TextSize=12
    nameLbl.TextColor3=T.TextPrimary; nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.Text=label

    local valLbl = Instance.new("TextLabel", wrap)
    valLbl.Size=UDim2.new(0,50,0,20); valLbl.Position=UDim2.new(1,-60,0,8)
    valLbl.BackgroundTransparency=1; valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=12
    valLbl.TextColor3=T.Accent; valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Text=tostring(default)

    local trackBg = Instance.new("Frame", wrap)
    trackBg.Size=UDim2.new(1,-20,0,6); trackBg.Position=UDim2.new(0,10,1,-18)
    trackBg.BackgroundColor3=T.Base; trackBg.BorderSizePixel=0
    Instance.new("UICorner",trackBg).CornerRadius=UDim.new(1,0)

    local fill = Instance.new("Frame", trackBg)
    fill.BackgroundColor3=T.Accent; fill.BorderSizePixel=0
    fill.Size=UDim2.new((default-minVal)/(maxVal-minVal),0,1,0)
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    -- invisible hit area over the track
    local hitArea = Instance.new("TextButton", trackBg)
    hitArea.Size=UDim2.new(1,0,1,0); hitArea.BackgroundTransparency=1
    hitArea.Text=""; hitArea.AutoButtonColor=false; hitArea.ZIndex=5

    local currentValue = default
    local isDragging   = false

    local function applyX(absX)
        local left  = trackBg.AbsolutePosition.X
        local width = trackBg.AbsoluteSize.X
        if width <= 0 then return end
        local frac = math.clamp((absX - left) / width, 0, 1)
        currentValue = math.floor(minVal + (maxVal - minVal) * frac + 0.5)
        valLbl.Text = tostring(currentValue)
        fill.Size = UDim2.new(frac, 0, 1, 0)
    end

    hitArea.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            applyX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if isDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            applyX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end)

    return {
        GetValue = function() return currentValue end,
        SetValue = function(v)
            currentValue = math.clamp(tonumber(v) or minVal, minVal, maxVal)
            valLbl.Text = tostring(currentValue)
            fill.Size = UDim2.new((currentValue-minVal)/(maxVal-minVal), 0, 1, 0)
        end,
    }
end

local function Dropdown(parent, label, options, default, callback)
    local wrap = Instance.new("Frame", parent)
    wrap.Size=UDim2.new(1,0,0,34); wrap.BackgroundColor3=T.Base; wrap.ClipsDescendants=true
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,6)
    local stroke = Instance.new("UIStroke", wrap); stroke.Color=T.Border

    local headBtn = Instance.new("TextButton", wrap)
    headBtn.Size=UDim2.new(1,0,0,34); headBtn.BackgroundTransparency=1
    headBtn.Text=""; headBtn.AutoButtonColor=false; headBtn.ZIndex=3

    local headLbl = Instance.new("TextLabel", headBtn)
    headLbl.Size=UDim2.new(1,-36,1,0); headLbl.Position=UDim2.new(0,10,0,0)
    headLbl.BackgroundTransparency=1; headLbl.Font=Enum.Font.GothamMedium; headLbl.TextSize=12
    headLbl.TextColor3=T.TextPrimary; headLbl.TextXAlignment=Enum.TextXAlignment.Left; headLbl.Text=default

    local arrow = Instance.new("TextLabel", headBtn)
    arrow.Size=UDim2.new(0,24,1,0); arrow.Position=UDim2.new(1,-28,0,0)
    arrow.BackgroundTransparency=1; arrow.Font=Enum.Font.GothamBold
    arrow.TextSize=10; arrow.TextColor3=T.TextSecond; arrow.Text="▼"; arrow.ZIndex=3

    -- options container inside the same wrap
    local optContainer = Instance.new("Frame", wrap)
    optContainer.Size=UDim2.new(1,0,1,-34); optContainer.Position=UDim2.new(0,0,0,34)
    optContainer.BackgroundTransparency=1
    local optLayout = Instance.new("UIListLayout", optContainer)
    optLayout.SortOrder=Enum.SortOrder.LayoutOrder

    local expanded = false
    local dropH = 34 + #options*30
    headBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        arrow.Text = expanded and "▲" or "▼"
        tw(wrap, {Size=UDim2.new(1,0,0,expanded and dropH or 34)})
        tw(stroke,{Color=expanded and T.Accent or T.Border})
    end)

    local current = default
    for idx, opt in ipairs(options) do
        local ob = Instance.new("TextButton", optContainer)
        ob.Size=UDim2.new(1,0,0,30); ob.LayoutOrder=idx
        ob.BackgroundColor3=T.Overlay; ob.BackgroundTransparency=0.6
        ob.Font=Enum.Font.Gotham; ob.TextSize=12; ob.TextColor3=T.TextSecond; ob.Text=opt
        ob.AutoButtonColor=false; ob.ZIndex=3
        ob.MouseEnter:Connect(function() tw(ob,{BackgroundTransparency=0.2,TextColor3=T.Accent}) end)
        ob.MouseLeave:Connect(function() tw(ob,{BackgroundTransparency=0.6,TextColor3=T.TextSecond}) end)
        ob.MouseButton1Click:Connect(function()
            current=opt; headLbl.Text=opt; expanded=false; arrow.Text="▼"
            tw(wrap,{Size=UDim2.new(1,0,0,34)}); tw(stroke,{Color=T.Border})
            if callback then callback(opt) end
        end)
    end
    return {
        GetValue = function() return current end,
        SetValue = function(v) current=v; headLbl.Text=v end,
    }
end

-- small label helper
local function InfoLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size=UDim2.new(1,0,0,36); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.TextSecond
    lbl.TextWrapped=true; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=text
    return lbl
end

-- ============================================================
--  TAB 1 — PRINTER
-- ============================================================
do
    local p = PagePrint
    local UrlBox  = Input(p, "Image URL or local path…", "")
    local ResBox  = Input(p, "Custom resolution (unlock with CUSTOM)", "")
    ResBox.TextEditable=false; ResBox.TextColor3=T.TextDim

    local ResDrop = Dropdown(p,"Quality",{
        "AUTO (safe max)","16×16","32×32","64×64","128×128","256×256","512×512","1024×1024","CUSTOM"
    },"AUTO (safe max)", function(opt)
        if opt=="CUSTOM" then
            ResBox.TextEditable=true; ResBox.TextColor3=T.TextPrimary; ResBox.Text="100"
        elseif opt=="AUTO (safe max)" then
            ResBox.TextEditable=false; ResBox.TextColor3=T.TextDim; ResBox.Text="AUTO"
        else
            ResBox.TextEditable=false; ResBox.TextColor3=T.TextDim; ResBox.Text=opt:match("^(%d+)")
        end
    end)

    local OrientDrop = Dropdown(p,"Orientation",{"Upright (Billboard)","Flat (Floor)"},"Upright (Billboard)")
    local WidthBox   = Input(p, "Width in studs", "50")
    local ThickBox   = Input(p, "Thickness", "0.2")

    Section(p,"SERVER PACING")
    local PrintSpd = Slider(p,"Place per tick",  1, 5000, 15)
    local PaintSpd = Slider(p,"Paint per tick",  1, 5000, 40)
    local BatchSz  = Slider(p,"Batch size",     50,1000,300)
    local Cooldown = Slider(p,"Cooldown (s)",    0,  10,  2)

    local _,GetBg,_ = Toggle(p,"Remove image background",false)
    local PrintBtn   = Btn(p,"Execute Print Job",T.OK,T.OKHover)
    local StopBtn    = Btn(p,"Halt Execution",T.Danger,T.DangerHover)

    local function doFetch()
        local url = UrlBox.Text:gsub("^%s+",""):gsub("%s+$","")
        if url=="" then UpdateStatusLine("Missing image URL.",T.Danger); return end
        UpdateStatusLine("Calculating resolution…",T.TextPrimary)

        local selRes  = ResDrop.GetValue()
        local resNum  = 64
        local cacheRes= "64"
        local avail   = scanInventory()

        if selRes=="AUTO (safe max)" then
            for _,pw in ipairs({16,32,64,128,256,512,1024}) do
                if pw*pw <= avail then resNum=pw else break end
            end
            UpdateStatusLine(string.format("AUTO → %dx%d",resNum,resNum),T.Accent)
            cacheRes="AUTO"; task.wait(0.6)
        elseif selRes=="CUSTOM" then
            resNum=tonumber(ResBox.Text:match("%d+")) or 64; cacheRes=resNum
        else
            resNum=tonumber(selRes:match("^(%d+)")) or 64; cacheRes=resNum
        end

        local remBg  = GetBg()
        local orient = OrientDrop.GetValue()
        local wArg   = tonumber(WidthBox.Text) or 50
        local tArg   = tonumber(ThickBox.Text) or 0.2
        saveJobCache(url, cacheRes, wArg, tArg, remBg, orient)

        local myZone = getPlayerZone(player)
        if not myZone then UpdateStatusLine("No build zone found.",T.Danger); return end

        local apiUrl = string.format("http://127.0.0.1:5000/process?url=%s&size=%s&remove_bg=%s",
            HttpService:UrlEncode(url), tostring(resNum), tostring(remBg))

        local total  = scanInventory()
        local ok2, resp = pcall(function() return game:HttpGet(apiUrl) end)
        if not ok2 or not resp then UpdateStatusLine("Python server offline.",T.Danger); return end
        local jok, data = pcall(function() return HttpService:JSONDecode(resp) end)
        if not jok or not data.success then
            UpdateStatusLine("API error: "..(data and data.error or "?"),T.Danger); return
        end
        if #data.pixels > total then
            UpdateStatusLine(string.format("Not enough blocks. Need %d, have %d.",#data.pixels,total),T.Danger); return
        end

        local pixSize = wArg / data.width
        local wOff    = wArg / 2
        local hOff    = (data.height * pixSize) / 2
        local startPos
        if orient=="Flat (Floor)" then startPos=myZone.CFrame*CFrame.new(-wOff,100,-hOff)
        else startPos=myZone.CFrame*CFrame.new(-wOff,100+hOff,0) end

        refreshInventorySnapshot()
        local expectedBlocks = {}
        for _,px in ipairs(data.pixels) do
            local aName = getNextAvailableBlock(); if not aName then break end
            local bx = (px.x+(px.w-1)/2)*pixSize; local by = px.y*pixSize
            local cfOff, sz
            if orient=="Flat (Floor)" then
                cfOff=CFrame.new(bx,0,by); sz=Vector3.new(px.w*pixSize,tArg,px.h*pixSize)
            else
                cfOff=CFrame.new(bx,-by,0); sz=Vector3.new(px.w*pixSize,px.h*pixSize,tArg)
            end
            table.insert(expectedBlocks,{Pos=startPos*cfOff,Color=Color3.fromRGB(px.r,px.g,px.b),Size=sz,BlockName=aName})
        end
        generatePreview(expectedBlocks)
        pendingBlocksData = expectedBlocks
        UpdateStatusLine(string.format("Ready — %dx%d · %d blocks. Confirm to print.",data.width,data.height,#expectedBlocks),T.Accent)
        PrintBtn.Text = "Confirm & Start"
    end

    PrintBtn.MouseButton1Click:Connect(function()
        if isPrinting then return end
        if not pendingBlocksData then
            task.spawn(doFetch)
        else
            local b = pendingBlocksData; pendingBlocksData=nil; PrintBtn.Text="Execute Print Job"
            task.spawn(function() executeInstaBlast(b,PrintSpd.GetValue(),PaintSpd.GetValue(),BatchSz.GetValue(),Cooldown.GetValue()) end)
        end
    end)
    StopBtn.MouseButton1Click:Connect(function()
        if isPrinting then isPrinting=false; UpdateStatusLine("Halted.",T.Danger)
        else pendingBlocksData=nil; clearPreview(); PrintBtn.Text="Execute Print Job"; UpdateStatusLine("Cleared.",T.TextSecond) end
    end)
end

local RefreshMaterialsUI  -- forward declare

-- ============================================================
--  TAB 2 — BUILDER
-- ============================================================
do
    local p = PageBuild
    Section(p,"COPY TARGET")
    local TargBox = Input(p,"Target player name…","")
    local CopyBtn = Btn(p,"Copy Target Base",T.Accent,Color3.fromRGB(255,180,80),T.AccentText)

    Section(p,"PASTE MODIFIERS")
    local OX = Input(p,"Offset X","0")
    local OY = Input(p,"Offset Y","0")
    local OZ = Input(p,"Offset Z","0")
    Toggle(p,"Ignore anchored state",true,function(s) ignoreAnchored=s end)
    local PasteBtn = Btn(p,"Paste Base",T.OK,T.OKHover)

    Section(p,"BOAT TOOLS")
    -- Anchor / unanchor all blocks on own base
    local AnchorBtn = Btn(p,"Anchor All My Blocks",T.Elevated,T.Overlay)
    AnchorBtn.MouseButton1Click:Connect(function()
        local base = getPlayerBase()
        if not base then UpdateStatusLine("Your base not found.",T.Danger); return end
        local tool = getTool("BuildingTool")
        if not tool then UpdateStatusLine("No BuildingTool found.",T.Danger); return end
        local count = 0
        for _,block in ipairs(base:GetChildren()) do
            if block:FindFirstChild("PPart") then
                pcall(function() tool.RF:InvokeServer("anchor",block) end)
                count += 1
            end
        end
        UpdateStatusLine(string.format("Anchored %d blocks.",count),T.OK)
    end)

    local UnanchorBtn = Btn(p,"Unanchor All My Blocks",T.Elevated,T.Overlay)
    UnanchorBtn.MouseButton1Click:Connect(function()
        local base = getPlayerBase()
        if not base then UpdateStatusLine("Your base not found.",T.Danger); return end
        local tool = getTool("BuildingTool")
        if not tool then UpdateStatusLine("No BuildingTool found.",T.Danger); return end
        local count = 0
        for _,block in ipairs(base:GetChildren()) do
            if block:FindFirstChild("PPart") then
                pcall(function() tool.RF:InvokeServer("unanchor",block) end)
                count += 1
            end
        end
        UpdateStatusLine(string.format("Unanchored %d blocks.",count),T.OK)
    end)

    -- Delete all blocks on own base
    local ClearBaseBtn = Btn(p,"Clear My Entire Base",T.Danger,T.DangerHover)
    ClearBaseBtn.MouseButton1Click:Connect(function()
        local base = getPlayerBase()
        if not base then UpdateStatusLine("Your base not found.",T.Danger); return end
        local tool = getTool("BuildingTool")
        if not tool then UpdateStatusLine("No BuildingTool.",T.Danger); return end
        local blocks = base:GetChildren()
        local count  = #blocks
        for _,block in ipairs(blocks) do
            if block:FindFirstChild("PPart") then
                pcall(function() tool.RF:InvokeServer("delete",block) end)
            end
        end
        UpdateStatusLine(string.format("Cleared %d blocks from base.",count),T.Danger)
    end)

    -- Paint all blocks a single color
    Section(p,"MASS PAINT")
    local PRBox = Input(p,"R (0–255)","255")
    local PGBox = Input(p,"G (0–255)","255")
    local PBBox = Input(p,"B (0–255)","255")
    local PaintAllBtn = Btn(p,"Paint All Blocks",T.Elevated,T.Overlay)
    PaintAllBtn.MouseButton1Click:Connect(function()
        local base = getPlayerBase()
        if not base then UpdateStatusLine("Your base not found.",T.Danger); return end
        local r = math.clamp(tonumber(PRBox.Text) or 255,0,255)
        local g = math.clamp(tonumber(PGBox.Text) or 255,0,255)
        local b2= math.clamp(tonumber(PBBox.Text) or 255,0,255)
        local col = Color3.fromRGB(r,g,b2)
        local count = 0
        for _,block in ipairs(base:GetChildren()) do
            if block:FindFirstChild("PPart") then paintBlock(block,col); count+=1 end
        end
        UpdateStatusLine(string.format("Painted %d blocks.",count),T.OK)
    end)

    -- Count blocks
    local CountBtn = Btn(p,"Count My Blocks",T.Elevated,T.Overlay)
    CountBtn.MouseButton1Click:Connect(function()
        local base = getPlayerBase()
        if not base then UpdateStatusLine("Base not found.",T.Danger); return end
        local count = 0
        for _,c in ipairs(base:GetChildren()) do if c:FindFirstChild("PPart") then count+=1 end end
        UpdateStatusLine(string.format("Your base has %d blocks.",count),T.OK)
    end)

    -- Flip clipboard horizontally
    local FlipBtn = Btn(p,"Flip Clipboard (Mirror X)",T.Elevated,T.Overlay)
    FlipBtn.MouseButton1Click:Connect(function()
        if not clipboard or #clipboard == 0 then
            UpdateStatusLine("Nothing in clipboard to flip.",T.Danger); return
        end
        for _,v in ipairs(clipboard) do
            local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = v.Pos:GetComponents()
            v.Pos = CFrame.new(-x,y,z, -r00,r01,r02, -r10,r11,r12, -r20,r21,r22)
        end
        UpdateStatusLine("Clipboard flipped on X axis.",T.Accent)
    end)

    TargBox.FocusLost:Connect(function()
        local t = TargBox.Text:gsub("^%s+",""); local lt = t:lower()
        for _,pl in pairs(Players:GetPlayers()) do
            if pl.Name:lower():find(lt,1,true) or pl.DisplayName:lower():find(lt,1,true) then
                TargBox.Text=pl.Name
                UpdateStatusLine("Target: "..pl.DisplayName,T.Accent)
                selectedBase=blocksFolder:FindFirstChild(pl.Name); return
            end
        end
        UpdateStatusLine("Player not found.",T.Danger); selectedBase=nil
    end)
    CopyBtn.MouseButton1Click:Connect(function()
        if selectedBase then
            clipboard=copyBuild(selectedBase)
            UpdateStatusLine(string.format("Copied %d blocks.",#clipboard),T.Accent)
        else UpdateStatusLine("No base selected.",T.Danger) end
    end)
    PasteBtn.MouseButton1Click:Connect(function()
        if clipboard then
            task.spawn(function()
                pasteBuild(clipboard,getPlayerBase(),
                    CFrame.new(tonumber(OX.Text) or 0, tonumber(OY.Text) or 0, tonumber(OZ.Text) or 0))
            end)
        else UpdateStatusLine("Nothing in clipboard.",T.Danger) end
    end)
    task.spawn(function()
        while task.wait(0.2) do
            PasteBtn.Text = pastePercent>0 and string.format("Pasting — %d%%",pastePercent) or "Paste Base"
        end
    end)
end

-- ============================================================
--  TAB 3 — AUTOMATION
-- ============================================================
do
    local p = PageFarm
    Section(p,"STAGE FARMING")
    Toggle(p,"Auto Farm",false,function(s) autofarm=s end)

    local noclipState = false
    local noclipConn  = nil
    Toggle(p,"Noclip (phase walls)",false,function(s)
        noclipState = s
        if s then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclipState or not character then return end
                for _,pt in pairs(character:GetDescendants()) do
                    if pt:IsA("BasePart") then pt.CanCollide=false end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
            if character then
                for _,pt in pairs(character:GetDescendants()) do
                    if pt:IsA("BasePart") then pt.CanCollide=true end
                end
            end
        end
    end)

    local AFSpd = Input(p,"Auto farm speed","20")
    AFSpd.FocusLost:Connect(function()
        local v = tonumber(AFSpd.Text:gsub("^%s+",""))
        if v then AUTOFARM_SPEED=v end
    end)
    Toggle(p,"Fast reset (skip chest)",false,function(s) ignoreChest=s end)

    Section(p,"AUTO PILOT")
    Toggle(p,"Waypoint Auto Pilot (boat)",false,function(s) if s then startAutoPilot() else stopAutoPilot() end end)
    Toggle(p,"Straight Auto Pilot",false,function(s) if s then startStraightAutoPilot() else stopStraightAutoPilot() end end)

    Section(p,"CAR FLY")
    local CFSpd = Input(p,"Car fly speed","50")
    local isCarFlying,carFlyBV,carFlyConn = false,nil,nil
    Toggle(p,"Manual Car Fly (WASD)",false,function(state)
        isCarFlying=state
        local car  = getCar()
        local part = car and (car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart"))
        if state and part then
            carFlyBV = Instance.new("BodyVelocity"); carFlyBV.Name="CarFlyBV"
            carFlyBV.MaxForce=Vector3.new(9e9,9e9,9e9); carFlyBV.Parent=part
            carFlyConn = RunService.RenderStepped:Connect(function()
                if not isCarFlying or not carFlyBV or not carFlyBV.Parent then return end
                local speed = tonumber(CFSpd.Text:gsub("^%s+","")) or 50
                local cam   = Workspace.CurrentCamera
                local fd=0; local bd=0; local ld=0; local rd=0
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then fd=1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then bd=-1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then ld=-1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then rd=1 end
                local md = (cam.CFrame.LookVector*(fd+bd))+((cam.CFrame*CFrame.new(ld+rd,0,0)).Position-cam.CFrame.Position)
                carFlyBV.Velocity = md.Magnitude>0 and md.Unit*speed or Vector3.zero
                part.CFrame = CFrame.new(part.Position, part.Position+cam.CFrame.LookVector)
            end)
        else
            if carFlyBV  then carFlyBV:Destroy(); carFlyBV=nil end
            if carFlyConn then carFlyConn:Disconnect(); carFlyConn=nil end
        end
    end)

    Section(p,"WORLD")
    local FPSBtn = Btn(p,"FPS Potato Mode",T.Elevated,T.Overlay)
    FPSBtn.MouseButton1Click:Connect(function()
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                v.Material=Enum.Material.SmoothPlastic
            end
            if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
        end
        Lighting.GlobalShadows=false
        UpdateStatusLine("Potato mode on.",T.Warning)
    end)

    local TimeSlider   = Slider(p,"Time of Day (hr)",0,24,14)
    local BrightSlider = Slider(p,"Ambient Brightness",0,10,2)
    local SetEnvBtn    = Btn(p,"Apply Lighting",T.Elevated,T.Overlay)
    SetEnvBtn.MouseButton1Click:Connect(function()
        Lighting.ClockTime  = TimeSlider.GetValue()
        Lighting.Brightness = BrightSlider.GetValue()
        UpdateStatusLine(string.format("Time %02d:00 · Brightness %d",TimeSlider.GetValue(),BrightSlider.GetValue()),T.OK)
    end)
    local ResetLightBtn = Btn(p,"Reset Lighting",T.Elevated,T.Overlay)
    ResetLightBtn.MouseButton1Click:Connect(function()
        Lighting.ClockTime=14; Lighting.Brightness=2; Lighting.GlobalShadows=true
        UpdateStatusLine("Lighting reset.",T.OK)
    end)
end

-- ============================================================
--  TAB 4 — MATERIALS
-- ============================================================
function RefreshMaterialsUI()
    for _,v in pairs(PageMats:GetChildren()) do
        if v:IsA("TextButton") or v:IsA("Frame") then v:Destroy() end
    end
    for _,blockName in ipairs(MASTER_BLOCKS) do
        local amount = (blockData:FindFirstChild(blockName) and blockData[blockName].Value or 0)
        local btn,_,_ = Toggle(PageMats,"  "..blockName.."  ("..amount..")",AllowedBlocks[blockName],function(s)
            AllowedBlocks[blockName]=s
        end)
        local c   = BlockColors[blockName] or Color3.new(1,1,1)
        local dot = Instance.new("Frame",btn)
        dot.Size=UDim2.new(0,8,0,8); dot.Position=UDim2.new(0,12,0.5,-4)
        dot.BackgroundColor3=c; dot.BorderSizePixel=0
        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    end
end
RefreshMaterialsUI()

-- ============================================================
--  TAB 5 — RECOVERY
-- ============================================================
do
    local p = PageResume
    Section(p,"SMART SYNC")
    InfoLabel(p,"V15 scans your plot before every print and skips blocks that already exist. Crash mid-print? Load the last job and hit Print — it auto-resumes from where it left off.")

    Section(p,"RESUME")
    local ResumeBtn = Btn(p,"No missed blocks",T.Elevated,T.Overlay,T.TextSecond)
    UpdateResumeTabUI = function(has,count)
        if has then
            ResumeBtn.Text=string.format("Resume — %d missed",count)
            tw(ResumeBtn,{BackgroundColor3=T.Accent,TextColor3=T.AccentText})
        else
            ResumeBtn.Text="No missed blocks"
            tw(ResumeBtn,{BackgroundColor3=T.Elevated,TextColor3=T.TextSecond})
        end
    end
    ResumeBtn.MouseButton1Click:Connect(function()
        if isPrinting or #missedBlocksBuffer==0 then
            UpdateStatusLine(isPrinting and "Already printing." or "Nothing to resume.",T.TextSecond); return
        end
        task.spawn(function() executeInstaBlast(missedBlocksBuffer,15,40,300,2) end)
    end)

    Section(p,"SCHEMATICS")
    local SaveNameBox = Input(p,"Schematic name…","")
    local SaveBtn     = Btn(p,"Save Current Preview",T.Accent,Color3.fromRGB(255,180,80),T.AccentText)
    SaveBtn.MouseButton1Click:Connect(function()
        if not pendingBlocksData then UpdateStatusLine("No preview to save.",T.Danger); return end
        local name = SaveNameBox.Text:gsub("^%s+",""):gsub("%s+$","")
        if name=="" then UpdateStatusLine("Enter a name first.",T.Danger); return end
        if writefile and HttpService then
            local s={}
            for _,b in ipairs(pendingBlocksData) do
                table.insert(s,{Pos={b.Pos:GetComponents()},Size={b.Size.X,b.Size.Y,b.Size.Z},Color={b.Color.R,b.Color.G,b.Color.B},BlockName=b.BlockName})
            end
            pcall(function() writefile(FOLDER.."/"..name..".json",HttpService:JSONEncode(s)) end)
            SaveNameBox.Text=""; UpdateStatusLine("Saved: "..name,T.OK)
        end
    end)

    Section(p,"LOAD HISTORY")
    local LoadLastBtn = Btn(p,"Load Last Crashed Job",T.OK,T.OKHover)
    LoadLastBtn.MouseButton1Click:Connect(function()
        if not (isfile and isfile(JOB_FILE)) then UpdateStatusLine("No job cache found.",T.Danger); return end
        local ok2,d = pcall(function() return HttpService:JSONDecode(readfile(JOB_FILE)) end)
        if ok2 and d and d.Url then
            UpdateStatusLine("Last job loaded — go to Print tab.",T.Accent); SwitchTab(1)
        else UpdateStatusLine("Cache corrupted or empty.",T.Danger) end
    end)

    if listfiles then
        for _,path in pairs(listfiles(FOLDER)) do
            local fname = path:match("([^/\\]+)%.json$")
            if fname and fname~="LastJobCache" and fname~="AutoRecovery" then
                local lb = Btn(p,"Load: "..fname,T.Elevated,T.Overlay)
                lb.MouseButton1Click:Connect(function()
                    if not (readfile and HttpService) then return end
                    local ok2,d = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
                    if ok2 and d then
                        local r={}
                        for _,b in ipairs(d) do
                            table.insert(r,{Pos=CFrame.new(unpack(b.Pos)),Size=Vector3.new(unpack(b.Size)),Color=Color3.new(unpack(b.Color)),BlockName=b.BlockName})
                        end
                        pendingBlocksData=r; generatePreview(r)
                        UpdateStatusLine("Loaded: "..fname,T.Accent); SwitchTab(1)
                    end
                end)
            end
        end
    end
end

-- ============================================================
--  TAB 6 — PLAYER
-- ============================================================
do
    local p = PagePlayer

    Section(p,"MOVEMENT")
    local SpdSlider = Slider(p,"Walk Speed",  16, 300, 16)
    local JmpSlider = Slider(p,"Jump Power",  50, 500, 50)
    local ApplyBtn  = Btn(p,"Apply Stats",T.OK,T.OKHover)
    ApplyBtn.MouseButton1Click:Connect(function()
        if humanoid then
            humanoid.WalkSpeed = SpdSlider.GetValue()
            humanoid.JumpPower = JmpSlider.GetValue()
            UpdateStatusLine(string.format("Speed %d  ·  Jump %d",SpdSlider.GetValue(),JmpSlider.GetValue()),T.OK)
        end
    end)
    local ResetBtn = Btn(p,"Reset to Default",T.Elevated,T.Overlay)
    ResetBtn.MouseButton1Click:Connect(function()
        if humanoid then humanoid.WalkSpeed=16; humanoid.JumpPower=50 end
        SpdSlider.SetValue(16); JmpSlider.SetValue(50)
        UpdateStatusLine("Movement reset.",T.TextSecond)
    end)

    Section(p,"FLY")
    local FlySpd = Slider(p,"Fly Speed",10,500,80)
    local flyEnabled,flyBV,flyBG,flyConn = false,nil,nil,nil
    local function stopFly()
        flyEnabled=false
        if flyConn then flyConn:Disconnect(); flyConn=nil end
        if flyBV then flyBV:Destroy(); flyBV=nil end
        if flyBG then flyBG:Destroy(); flyBG=nil end
        if humanoid then humanoid.PlatformStand=false end
    end
    local function startFly()
        if not HRP then return end
        flyEnabled=true; humanoid.PlatformStand=true
        flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(9e9,9e9,9e9); flyBV.Velocity=Vector3.zero; flyBV.Parent=HRP
        flyBG=Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(9e9,9e9,9e9); flyBG.P=3000; flyBG.D=300; flyBG.CFrame=HRP.CFrame; flyBG.Parent=HRP
        flyConn=RunService.RenderStepped:Connect(function()
            if not flyEnabled or not HRP then stopFly(); return end
            local cam=Workspace.CurrentCamera; local spd=FlySpd.GetValue(); local dir=Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir+=Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then dir-=Vector3.new(0,1,0) end
            flyBV.Velocity=dir.Magnitude>0 and dir.Unit*spd or Vector3.zero
            flyBG.CFrame=cam.CFrame
        end)
    end
    Toggle(p,"Enable Fly (WASD + Space / Shift)",false,function(s) if s then startFly() else stopFly() end end)

    Section(p,"SURVIVAL")
    local ijConn = nil
    Toggle(p,"Infinite Jump",false,function(s)
        if s then
            ijConn = UserInputService.JumpRequest:Connect(function()
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if ijConn then ijConn:Disconnect(); ijConn=nil end
        end
    end)

    local invisEnabled = false
    Toggle(p,"Invisibility",false,function(s)
        invisEnabled=s
        if character then
            for _,pt in pairs(character:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name~="HumanoidRootPart" then pt.Transparency=s and 1 or 0 end
            end
        end
        UpdateStatusLine("Invisibility: "..(s and "ON" or "OFF"),s and T.Accent or T.TextSecond)
    end)

    Section(p,"TELEPORT")
    local TpBox = Input(p,"Player name…","")
    local TpBtn = Btn(p,"Teleport to Player",T.OK,T.OKHover)
    TpBtn.MouseButton1Click:Connect(function()
        local lt = TpBox.Text:gsub("^%s+",""):lower()
        for _,pl in pairs(Players:GetPlayers()) do
            if pl.Name:lower():find(lt,1,true) or pl.DisplayName:lower():find(lt,1,true) then
                if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    HRP:PivotTo(pl.Character.HumanoidRootPart.CFrame+Vector3.new(3,0,3))
                    UpdateStatusLine("Teleported to "..pl.DisplayName,T.OK); return
                end
            end
        end
        UpdateStatusLine("Player not found.",T.Danger)
    end)

    local CX = Input(p,"X","0"); local CY = Input(p,"Y","0"); local CZ = Input(p,"Z","0")
    local CordBtn = Btn(p,"Teleport to Coords",T.Elevated,T.Overlay)
    CordBtn.MouseButton1Click:Connect(function()
        local x,y,z = tonumber(CX.Text),tonumber(CY.Text),tonumber(CZ.Text)
        if x and y and z then
            HRP:PivotTo(CFrame.new(x,y,z))
            UpdateStatusLine(string.format("Teleported to (%.0f, %.0f, %.0f).",x,y,z),T.OK)
        else UpdateStatusLine("Invalid coordinates.",T.Danger) end
    end)

    Section(p,"CAMERA")
    local FovSlider  = Slider(p,"Field of View",30,120,70)
    local DistSlider = Slider(p,"Zoom Distance",2,60,12)

    local ApplyCamBtn = Btn(p,"Apply Camera Settings",T.Elevated,T.Overlay)
    ApplyCamBtn.MouseButton1Click:Connect(function()
        Workspace.CurrentCamera.FieldOfView = FovSlider.GetValue()
        player.CameraMaxZoomDistance = DistSlider.GetValue()
        player.CameraMinZoomDistance = DistSlider.GetValue()
        UpdateStatusLine(string.format("FOV %d · Zoom %d",FovSlider.GetValue(),DistSlider.GetValue()),T.OK)
    end)
    local ResetCamBtn = Btn(p,"Reset Camera",T.Elevated,T.Overlay)
    ResetCamBtn.MouseButton1Click:Connect(function()
        Workspace.CurrentCamera.FieldOfView=70
        player.CameraMaxZoomDistance=400; player.CameraMinZoomDistance=0.5
        FovSlider.SetValue(70); DistSlider.SetValue(12)
        UpdateStatusLine("Camera reset.",T.TextSecond)
    end)

    Section(p,"KEYBINDS")
    InfoLabel(p,"RightShift — toggle GUI visibility\nWASD+Space+Shift — fly controls")

    -- re-apply invis on respawn
    player.CharacterAdded:Connect(function(newChar)
        if invisEnabled then
            task.wait(1)
            for _,pt in pairs(newChar:GetDescendants()) do
                if pt:IsA("BasePart") and pt.Name~="HumanoidRootPart" then pt.Transparency=1 end
            end
        end
    end)
end

-- ============================================================
--  CHARACTER RESPAWN HANDLER
-- ============================================================
player.CharacterAdded:Connect(function(newChar)
    character  = newChar
    HRP        = newChar:WaitForChild("HumanoidRootPart")
    humanoid   = newChar:WaitForChild("Humanoid")
    stageIndex = 1
    if autoPilotEnabled   then stopAutoPilot() end
    if straightAPEnabled  then stopStraightAutoPilot() end
end)

-- ============================================================
--  AUTO FARM LOOP
-- ============================================================
task.spawn(function()
    while task.wait(100) do
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Tilde, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Tilde, false, nil)
    end
end)

task.spawn(function()
    while true do
        task.wait()
        if not autofarm or not HRP then continue end
        if stageIndex == 11 then
            if ignoreChest then
                if character and character:FindFirstChild("Humanoid") then character.Humanoid.Health=0 end
                player.CharacterAdded:Wait(); stageIndex=1; task.wait(1); continue
            end
            local endStage = Workspace:FindFirstChild("BoatStages")
                and Workspace.BoatStages:FindFirstChild("NormalStages")
                and Workspace.BoatStages.NormalStages:FindFirstChild("TheEnd")
            local chest = endStage and endStage:FindFirstChild("GoldenChest")
            if not chest then continue end
            HRP:PivotTo(chest:GetPivot()+Vector3.new(0,0,-10))
            local timer=0
            repeat task.wait(1); timer+=1
                if timer%20==0 then HRP:PivotTo(chest:GetPivot()+Vector3.new(0,0,-10)) end
            until (HRP.Position-chest:GetPivot().Position).Magnitude>500
            stageIndex=1
        else
            local ns = Workspace:FindFirstChild("BoatStages")
                and Workspace.BoatStages:FindFirstChild("NormalStages")
            if not ns then continue end
            local stage = ns:FindFirstChild("CaveStage"..stageIndex)
            local dp    = stage and stage:FindFirstChild("DarknessPart")
            if not dp then continue end
            local startCF = dp.CFrame - Vector3.new(0,0,15)
            local endCF   = dp.CFrame + Vector3.new(0,0,20)
            character:PivotTo(startCF)
            local dist = (startCF.Position-endCF.Position).Magnitude
            local twn  = TweenService:Create(HRP,TweenInfo.new(dist/AUTOFARM_SPEED,Enum.EasingStyle.Linear),{CFrame=endCF})
            tweening=true; twn:Play(); twn.Completed:Wait(); tweening=false; stageIndex+=1
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if tweening and HRP then HRP.AssemblyLinearVelocity=Vector3.zero end
end)
