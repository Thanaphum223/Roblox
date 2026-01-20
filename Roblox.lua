-- [[ ส่วนตรวจสอบรหัสแมพ (Place ID Check) ]] --
if game.PlaceId ~= 8391915840 then
    warn("Script stopped: This script only supports Place ID 8391915840")
    return
end
-------------------------------------------------

-- 1. ล้างระบบเก่า (Clean Re-execution)
if _G.ProScript_Connections then
    for _, conn in pairs(_G.ProScript_Connections) do
        if conn then
            conn:Disconnect()
        end
    end
end
_G.ProScript_Connections = {} 

-- 2. ประกาศ Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

-- 3. ตัวแปรผู้เล่น
local player = Players.LocalPlayer
local mouse = player:GetMouse() 
local camera = workspace.CurrentCamera

-- 4. สถานะการทำงาน (State Variables)
local flying = false
local espEnabled = false
local clickTpEnabled = false 
local autoFarmEnabled = false 
local isInvisible = false -- [สถานะล่องหน]
local menuVisible = true 
local speed = 2
local currentLang = "EN" 

-- ตัวแปรสำหรับ Stats Farm
local sellCount = 0
local farmStartTime = 0
local currentFarmState = "Idle"
local currentTween = nil

-- ตัวแปรสำหรับ Sink & Rise (ระบบใหม่)
local currentVerticalMode = "None" -- "Sink", "Rise", หรือ "None"
local sinkConnection = nil

-- [[ พิกัดสำคัญ (Coordinates) ]] --
local POINT_A_JOB   = CFrame.new(1146.80627, -245.849579, -561.207458)
local POINT_B_FILL  = CFrame.new(1147.00024, -245.849609, -568.630432)
local POINT_C_SELL  = CFrame.new(1143.9364,  -245.849579, -580.007935)
local INVIS_POS     = Vector3.new(-25.95, 84, 3537.55) -- พิกัดซ่อนตัว

-- ล้าง UI เก่าออกก่อนสร้างใหม่
if player.PlayerGui:FindFirstChild("ControlGui_Pro_V55") then
    player.PlayerGui.ControlGui_Pro_V55:Destroy()
end
if player.PlayerGui:FindFirstChild("FixedInvisGui") then
    player.PlayerGui.FixedInvisGui:Destroy()
end

-- === THEME SETTINGS ===
local Theme = {
    Background = Color3.fromRGB(5, 5, 10),
    ButtonOff = Color3.fromRGB(20, 20, 25),
    ButtonOn_Start = Color3.fromRGB(120, 0, 255),
    ButtonOn_End = Color3.fromRGB(50, 0, 150),
    ESP_Color = Color3.fromRGB(180, 100, 255),
    Text = Color3.fromRGB(240, 240, 255),
    TextDim = Color3.fromRGB(100, 100, 120),
    Stroke = Color3.fromRGB(60, 30, 90)
}

-- === LANGUAGE DATA ===
local Translations = {
    FLY = {EN = "FLY (R)", TH = "บิน (R)"},
    ESP = {EN = "ESP (F)", TH = "มองทะลุ (F)"},
    SINK_BTN = {EN = "SINK (J)", TH = "จมดิน (J)"},
    RISE_BTN = {EN = "RISE (K)", TH = "ลอยฟ้า (K)"},
    INVIS = {EN = "INVIS (Z)", TH = "ล่องหน (Z)"}, -- [ปุ่มใหม่]
    TP = {EN = "CLICK TP (T)", TH = "วาร์ป (T)"},
    FARM = {EN = "AUTO FARM", TH = "ออโต้ฟาร์ม"},
    RESET = {EN = "RESET CAM", TH = "รีเซ็ตกล้อง"},
    LIST = {EN = "ENTITIES LIST", TH = "รายชื่อผู้เล่น"},
    HINT = {EN = "[X] TOGGLE MENU", TH = "[X] เปิด/ปิด เมนู"},
    LANG_BTN = {EN = "LANG: EN", TH = "ภาษา: TH"},
    
    STATUS_WAIT = {EN = "Vacuum: Waiting...", TH = "Vacuum: รอคำสั่ง..."},
    STATUS_READY = {EN = "Vacuum: Ready", TH = "สถานะ: พร้อมใช้งาน"},
    AFK = {EN = "System: Anti-AFK", TH = "ระบบ: กัน AFK ทำงาน"},
    
    SINK_STATUS = {EN = "Action: Sinking...", TH = "สถานะ: กำลังจมดิน..."},
    RISE_STATUS = {EN = "Action: Rising...", TH = "สถานะ: กำลังลอยขึ้น..."},
    INVIS_STATUS = {EN = "Invis: ACTIVE", TH = "สถานะ: กำลังล่องหน (ซ่อนตัว)"},
    
    ABORT = {EN = "Aborted.", TH = "ยกเลิกคำสั่งแล้ว"},
    VISUAL_ON = {EN = "Visuals: ON", TH = "การมองเห็น: เปิด"},
    VISUAL_OFF = {EN = "Visuals: OFF", TH = "การมองเห็น: ปิด"},
    WARP_READY = {EN = "Warp: READY", TH = "วาร์ป: พร้อม (กด Ctrl+คลิก)"},
    WARP_OFF = {EN = "Warp: OFF", TH = "วาร์ป: ปิด"},
    WARPED = {EN = "Warped.", TH = "วาร์ปสำเร็จ!"},
    FLY_ON = {EN = "Flight Enabled", TH = "โหมดการบิน: เปิด"},
    CAM_RESET = {EN = "Cam Reset", TH = "รีเซ็ตกล้องเรียบร้อย"},
    
    FARM_STATE = {
        Init = {EN = "Init", TH = "เริ่มระบบ"},
        Job = {EN = "Job", TH = "รับงาน"},
        Fill = {EN = "Fill", TH = "เติมของ"},
        Sell = {EN = "Sell", TH = "ขายของ"},
        Idle = {EN = "Idle", TH = "ว่าง"}
    },
    FARM_FMT = {EN = "%s | Time: %s | Sold: %d", TH = "สถานะ: %s | เวลา: %s | ขาย: %d"}
}

-- สร้าง ScreenGui หลัก
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "ControlGui_Pro_V55"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- === UTILS & UI HELPERS ===
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner", instance)
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

local function addStroke(instance, transparency)
    local stroke = Instance.new("UIStroke", instance)
    stroke.Color = Theme.Stroke
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.5
    return stroke
end

local function addGradient(instance)
    local grad = Instance.new("UIGradient", instance)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.ButtonOn_Start),
        ColorSequenceKeypoint.new(1, Theme.ButtonOn_End)
    }
    grad.Rotation = 45
    grad.Enabled = false
    return grad
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- === UI CONSTRUCTION ===

-- 1. Hint Label
local hintLabel = Instance.new("TextLabel", sg)
hintLabel.Size = UDim2.new(0, 200, 0, 30)
hintLabel.Position = UDim2.new(0.5, -100, 0, 5)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = Translations.HINT.EN
hintLabel.TextColor3 = Theme.TextDim
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 18
hintLabel.TextTransparency = 0.5

-- 2. Menu Container
local menuContainer = Instance.new("Frame", sg)
menuContainer.Size = UDim2.new(1, 0, 1, 0)
menuContainer.BackgroundTransparency = 1
menuContainer.Name = "MenuContainer"
menuContainer.Visible = false

-- 3. Status Frame (มุมขวาล่าง)
local statusFrame = Instance.new("Frame", sg)
statusFrame.AutomaticSize = Enum.AutomaticSize.X
statusFrame.Size = UDim2.new(0, 0, 0, 40)
statusFrame.AnchorPoint = Vector2.new(1, 1)
statusFrame.Position = UDim2.new(1, -20, 1, -50)
statusFrame.BackgroundColor3 = Theme.Background
statusFrame.BackgroundTransparency = 0.1
addCorner(statusFrame, 10)
addStroke(statusFrame, 0.3)

local statusLabel = Instance.new("TextLabel", statusFrame)
statusLabel.AutomaticSize = Enum.AutomaticSize.X
statusLabel.Size = UDim2.new(0, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = Translations.STATUS_WAIT.EN
statusLabel.TextColor3 = Theme.Text
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 16

local pad = Instance.new("UIPadding", statusFrame)
pad.PaddingLeft = UDim.new(0, 15)
pad.PaddingRight = UDim.new(0, 15)

-- 4. Player List (Side Menu)
local sideFrame = Instance.new("Frame", menuContainer)
sideFrame.Size = UDim2.new(0, 260, 0, 350)
sideFrame.Position = UDim2.new(1, -280, 0.2, 0)
sideFrame.BackgroundColor3 = Theme.Background
sideFrame.BackgroundTransparency = 0.1
addCorner(sideFrame, 12)
addStroke(sideFrame, 0.4)
makeDraggable(sideFrame)

local sideTitle = Instance.new("TextLabel", sideFrame)
sideTitle.Size = UDim2.new(1, 0, 0, 40)
sideTitle.BackgroundTransparency = 1
sideTitle.Text = Translations.LIST.EN
sideTitle.TextColor3 = Theme.TextDim
sideTitle.Font = Enum.Font.GothamBold
sideTitle.TextSize = 14

local scrollFrame = Instance.new("ScrollingFrame", sideFrame)
scrollFrame.Size = UDim2.new(1, -10, 1, -50)
scrollFrame.Position = UDim2.new(0, 5, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 2
scrollFrame.ScrollBarImageColor3 = Theme.ButtonOn_Start

local layout = Instance.new("UIListLayout", scrollFrame)
layout.SortOrder = Enum.SortOrder.Name
layout.Padding = UDim.new(0, 6)

-- 5. Main Control Bar (Bottom)
local mainBar = Instance.new("Frame", menuContainer)
mainBar.Size = UDim2.new(0, 1100, 0, 65)
mainBar.Position = UDim2.new(0.5, -550, 0.85, 0)
mainBar.BackgroundColor3 = Theme.Background
mainBar.BackgroundTransparency = 0.1
addCorner(mainBar, 16)
addStroke(mainBar, 0.3)
makeDraggable(mainBar)

local barLayout = Instance.new("UIListLayout", mainBar)
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barLayout.Padding = UDim.new(0, 4)

-- Helper Function สร้างปุ่ม
local function createStyledBtn(parent, text, sizeScale)
    local btnContainer = Instance.new("Frame", parent)
    btnContainer.Size = UDim2.new(sizeScale, -8, 0, 45)
    btnContainer.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", btnContainer)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = Theme.ButtonOff
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    addCorner(btn, 10)
    
    local grad = addGradient(btn)
    return btn, grad
end

-- สร้างปุ่มต่างๆ ลงใน Main Bar
local flyBtn, flyGrad = createStyledBtn(mainBar, Translations.FLY.EN, 0.09)
local espBtn, espGrad = createStyledBtn(mainBar, Translations.ESP.EN, 0.09)
local sinkBtn, sinkGrad = createStyledBtn(mainBar, Translations.SINK_BTN.EN, 0.09)
local riseBtn, riseGrad = createStyledBtn(mainBar, Translations.RISE_BTN.EN, 0.09)
local invisBtn, invisGrad = createStyledBtn(mainBar, Translations.INVIS.EN, 0.10) -- [ปุ่มใหม่ Invis]
local clickTpBtn, clickTpGrad = createStyledBtn(mainBar, Translations.TP.EN, 0.11)
local farmBtn, farmGrad = createStyledBtn(mainBar, Translations.FARM.EN, 0.11)
local stopSpecBtn, stopGrad = createStyledBtn(mainBar, Translations.RESET.EN, 0.10)

-- ช่องใส่ความเร็ว (Speed Input)
local speedContainer = Instance.new("Frame", mainBar)
speedContainer.Size = UDim2.new(0.08, -5, 0, 45)
speedContainer.BackgroundTransparency = 1
addCorner(speedContainer, 10)

local speedInput = Instance.new("TextBox", speedContainer)
speedInput.Size = UDim2.new(1, 0, 1, 0)
speedInput.Text = tostring(speed)
speedInput.BackgroundColor3 = Theme.ButtonOff
speedInput.TextColor3 = Theme.ButtonOn_Start
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 16
speedInput.PlaceholderText = "SPD"
addCorner(speedInput, 10)
addStroke(speedInput, 0.6)

local langBtn, langGrad = createStyledBtn(mainBar, Translations.LANG_BTN.EN, 0.08)


-- === CORE FUNCTIONS ===

local function setStatus(text)
    statusLabel.Text = text
end

local function toggleBtnVisual(btn, gradient, isOn)
    if isOn then
        gradient.Enabled = true
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ButtonOn_End}):Play()
    else
        gradient.Enabled = false
        btn.TextColor3 = Theme.Text
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ButtonOff}):Play()
    end
end

local function moveStatusUI(toCenter)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local targetPos = toCenter and UDim2.new(0.5, 0, 0.35, 0) or UDim2.new(1, -20, 1, -50)
    local targetAnchor = toCenter and Vector2.new(0.5, 0.5) or Vector2.new(1, 1)
    statusFrame.AnchorPoint = targetAnchor
    TweenService:Create(statusFrame, tweenInfo, {Position = targetPos}):Play()
end

local function restorePhysics()
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if root then
            root.Velocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
            if root:FindFirstChild("Elite_Movement") then root.Elite_Movement:Destroy() end
            if root:FindFirstChild("SinkLift") then root.SinkLift:Destroy() end
            if root:FindFirstChild("SinkGyro") then root.SinkGyro:Destroy() end
            root.Anchored = false 
        end
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
end

local function performNoclip(char)
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") and v.CanCollide == true then
            v.CanCollide = false
        end
    end
end

-- [[ Helper: Set Transparency (เฉพาะตัวละคร ไม่รวมเก้าอี้) ]] --
local function setCharacterTransparency(transparency)
    if player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                -- เช็คว่าเป็นพาร์ทของตัวเราจริงๆ ไม่ใช่เก้าอี้
                if v.Name ~= "HumanoidRootPart" then
                    v.Transparency = transparency
                end
            end
        end
    end
end

-- === LOGIC: INVISIBILITY (FIXED & TESTED VERSION) ===
-- Logic นี้มาจากที่คุณทดสอบแล้วว่าผ่าน: ไม่ย่อเก้าอี้ + ลบ Decal + Loop Destroy --
local function toggleInvisibility()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    isInvisible = not isInvisible
    
    -- อัปเดตสถานะปุ่ม
    toggleBtnVisual(invisBtn, invisGrad, isInvisible)

    if isInvisible then
        -- [[ เปิดใช้งาน ]]
        local hrp = player.Character.HumanoidRootPart
        local savedCFrame = hrp.CFrame
        
        -- 1. วาร์ปหนี
        player.Character:MoveTo(INVIS_POS)
        task.wait(0.15)
        
        -- 2. สร้างเก้าอี้ (ชื่อ Invis_Seat_Fixed)
        local seat = Instance.new("Seat")
        seat.Name = "Invis_Seat_Fixed"
        seat.Anchored = false
        seat.CanCollide = false
        -- *สำคัญ* ซ่อนทันที
        seat.Transparency = 1 
        seat.Position = INVIS_POS
        seat.Parent = workspace
        
        -- *สำคัญ* ลบ Decal (รูปหน้าเก้าอี้)
        for _, child in pairs(seat:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child:Destroy()
            end
        end
        
        -- 3. เชื่อมตัว (Weld)
        local weld = Instance.new("Weld")
        weld.Part0 = seat
        weld.Part1 = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
        weld.Parent = seat
        
        task.wait()
        
        -- 4. วาร์ปกลับ
        seat.CFrame = savedCFrame
        
        -- ปรับตัวจาง
        setCharacterTransparency(0.5)
        setStatus(Translations.INVIS_STATUS[currentLang])
    else
        -- [[ ปิดใช้งาน ]]
        -- ล้างบางเก้าอี้ที่มีชื่อเดียวกันทั้งหมด
        for _, v in pairs(workspace:GetChildren()) do
            if v.Name == "Invis_Seat_Fixed" then
                v:Destroy()
            end
        end
        
        -- คืนค่าความชัดของตัวละคร
        setCharacterTransparency(0)
        
        -- แก้บั๊กตัวแข็ง
        if player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.PlatformStand = false
        end
        
        -- รีเซ็ตสถานะข้อความ ถ้าไม่ได้ทำอย่างอื่นอยู่
        if not flying and currentVerticalMode == "None" then
            setStatus(Translations.STATUS_READY[currentLang])
        end
    end
end

-- === SINK & RISE LOGIC ===
local function stopVerticalMovement()
    currentVerticalMode = "None"
    toggleBtnVisual(sinkBtn, sinkGrad, false)
    toggleBtnVisual(riseBtn, riseGrad, false)
    if sinkConnection then
        sinkConnection:Disconnect()
        sinkConnection = nil
    end
    restorePhysics()
    setStatus(Translations.STATUS_READY[currentLang])
end

local function startVerticalMovement(mode)
    if currentVerticalMode == mode then
        stopVerticalMovement()
        return
    end

    stopVerticalMovement()
    currentVerticalMode = mode
    
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    if mode == "Sink" then
        toggleBtnVisual(sinkBtn, sinkGrad, true)
        setStatus(Translations.SINK_STATUS[currentLang])
    else
        toggleBtnVisual(riseBtn, riseGrad, true)
        setStatus(Translations.RISE_STATUS[currentLang])
    end

    hum.PlatformStand = true
    performNoclip(char)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "SinkLift"
    bv.Velocity = Vector3.new(0, (mode == "Sink" and -6 or 6), 0)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "SinkGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = root.CFrame
    bg.Parent = root

    sinkConnection = RunService.Stepped:Connect(function()
        if currentVerticalMode ~= "None" and char then
            performNoclip(char)
        else
            if sinkConnection then
                sinkConnection:Disconnect()
                sinkConnection = nil
            end
        end
    end)
    table.insert(_G.ProScript_Connections, sinkConnection)
end

-- === UPDATE TEXTS FUNCTION ===
local function updateTexts()
    flyBtn.Text = Translations.FLY[currentLang]
    espBtn.Text = Translations.ESP[currentLang]
    sinkBtn.Text = Translations.SINK_BTN[currentLang]
    riseBtn.Text = Translations.RISE_BTN[currentLang]
    invisBtn.Text = Translations.INVIS[currentLang]
    clickTpBtn.Text = Translations.TP[currentLang]
    farmBtn.Text = Translations.FARM[currentLang]
    stopSpecBtn.Text = Translations.RESET[currentLang]
    sideTitle.Text = Translations.LIST[currentLang]
    hintLabel.Text = Translations.HINT[currentLang]
    langBtn.Text = Translations.LANG_BTN[currentLang]
    
    if autoFarmEnabled then
    elseif currentVerticalMode == "Sink" then
        setStatus(Translations.SINK_STATUS[currentLang])
    elseif currentVerticalMode == "Rise" then
        setStatus(Translations.RISE_STATUS[currentLang])
    elseif isInvisible then
        setStatus(Translations.INVIS_STATUS[currentLang])
    elseif flying then
        setStatus(Translations.FLY_ON[currentLang])
    elseif clickTpEnabled then
        setStatus(Translations.WARP_READY[currentLang])
    elseif espEnabled then
        setStatus(Translations.VISUAL_ON[currentLang])
    else
        setStatus(Translations.STATUS_READY[currentLang])
    end
end

-- === EVENT CONNECTIONS ===

langBtn.MouseButton1Click:Connect(function()
    currentLang = (currentLang == "EN") and "TH" or "EN"
    updateTexts()
end)

sinkBtn.MouseButton1Click:Connect(function() startVerticalMovement("Sink") end)
riseBtn.MouseButton1Click:Connect(function() startVerticalMovement("Rise") end)

-- เชื่อมปุ่ม Invis เข้ากับฟังก์ชันใหม่
invisBtn.MouseButton1Click:Connect(toggleInvisibility)

-- Auto Farm Logic (Expanded)
local function addStabilizer(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and not hrp:FindFirstChild("FarmGyro") then
        local bg = Instance.new("BodyGyro")
        bg.Name = "FarmGyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
    end
end

local function removeStabilizer(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("FarmGyro") then
        hrp.FarmGyro:Destroy()
    end
end

local function smartMove(targetCFrame)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    addStabilizer(char)
    local dist = (root.Position - targetCFrame.Position).Magnitude
    local tweenTime = dist / 120 
    if tweenTime < 0.2 then tweenTime = 0.2 end
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetCFrame.Position)})
    currentTween = tween
    tween:Play()
    tween.Completed:Wait()
    currentTween = nil
    root.Velocity = Vector3.zero
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
end

local function forceInteract(duration)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local found = false
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {char}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    local partsInRadius = workspace:GetPartBoundsInRadius(root.Position, 35, overlapParams)
    
    for _, part in ipairs(partsInRadius) do
        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt") or part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt and prompt.Enabled then
            prompt:InputHoldBegin()
            found = true
        end
    end
    
    task.spawn(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        local elapsed = 0
        while elapsed < duration do 
            if not autoFarmEnabled then break end 
            task.wait(0.1) 
            elapsed = elapsed + 0.1 
        end
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        if found then
            for _, part in ipairs(partsInRadius) do
                local prompt = part:FindFirstChildWhichIsA("ProximityPrompt") or part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    prompt:InputHoldEnd()
                end
            end
        end
    end)
    
    local elapsed = 0
    while elapsed < duration do 
        if not autoFarmEnabled then return end 
        task.wait(0.1) 
        elapsed = elapsed + 0.1 
    end
end

local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function getFarmStateText(state)
    local trans = Translations.FARM_STATE[state]
    return trans and trans[currentLang] or state
end

local function runAutoFarm()
    farmStartTime = os.time()
    sellCount = 0
    currentFarmState = "Init"
    
    task.spawn(function()
        while autoFarmEnabled do
            local elapsed = os.time() - farmStartTime
            local timeStr = formatTime(elapsed)
            local stateText = getFarmStateText(currentFarmState)
            local fmt = Translations.FARM_FMT[currentLang]
            setStatus(string.format(fmt, stateText, timeStr, sellCount))
            task.wait(1)
        end
    end)
    
    task.spawn(function()
        while autoFarmEnabled do
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                task.wait(1)
                return
            end
            
            pcall(function()
                addStabilizer(player.Character)
                
                currentFarmState = "Job"
                smartMove(POINT_A_JOB)
                task.wait(0.5) 
                
                if not autoFarmEnabled then return end
                forceInteract(3.5)
                
                currentFarmState = "Fill"
                smartMove(POINT_B_FILL)
                task.wait(0.5) 
                
                if not autoFarmEnabled then return end
                forceInteract(3.5)
                
                currentFarmState = "Sell"
                smartMove(POINT_C_SELL)
                task.wait(0.5) 
                
                if not autoFarmEnabled then return end
                forceInteract(3.5)
                sellCount = sellCount + 1
                task.wait(0.5)
            end)
        end
        
        if currentTween then currentTween:Cancel() end
        removeStabilizer(player.Character)
        restorePhysics()
        setStatus(Translations.STATUS_READY[currentLang] .. " (Last: " .. sellCount .. ")")
        moveStatusUI(false) 
    end)
end

farmBtn.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    toggleBtnVisual(farmBtn, farmGrad, autoFarmEnabled)
    if autoFarmEnabled then
        moveStatusUI(true)
        runAutoFarm()
    else 
        if currentTween then currentTween:Cancel() end
        removeStabilizer(player.Character)
        restorePhysics()
        setStatus(Translations.ABORT[currentLang])
        moveStatusUI(false)
    end
end)

-- ESP SYSTEM
local function removeESP(char)
    if not char then return end
    if char:FindFirstChild("Elite_Highlight") then char.Elite_Highlight:Destroy() end
    if char:FindFirstChild("Elite_Tag") then char.Elite_Tag:Destroy() end
end

local function createESPItems(p, char)
    if not char then return end
    removeESP(char) 
    local root = char:WaitForChild("HumanoidRootPart", 10) 
    if not root then return end
    
    local hi = Instance.new("Highlight", char)
    hi.Name = "Elite_Highlight"
    hi.FillTransparency = 0.5
    hi.OutlineColor = Theme.ESP_Color
    hi.FillColor = Theme.ESP_Color
    
    local bg = Instance.new("BillboardGui", char)
    bg.Name = "Elite_Tag"
    bg.Adornee = root
    bg.Size = UDim2.new(0, 100, 0, 40)
    bg.StudsOffset = Vector3.new(0, 3.5, 0)
    bg.AlwaysOnTop = true
    
    local tl = Instance.new("TextLabel", bg)
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Text = p.DisplayName or p.Name
    tl.TextColor3 = Theme.ESP_Color
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14
    tl.TextStrokeTransparency = 0.5
end

local function setupPlayerESP(p)
    if p == player then return end 
    p.CharacterAdded:Connect(function(c)
        if espEnabled then createESPItems(p, c) end
    end)
    if p.Character then
        if espEnabled then createESPItems(p, p.Character) end
    end
end

local function toggleESP()
    espEnabled = not espEnabled
    toggleBtnVisual(espBtn, espGrad, espEnabled)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            if espEnabled then
                createESPItems(p, p.Character)
            else
                removeESP(p.Character)
            end
        end
    end
    setStatus(espEnabled and Translations.VISUAL_ON[currentLang] or Translations.VISUAL_OFF[currentLang])
end

espBtn.MouseButton1Click:Connect(toggleESP)
for _, p in pairs(Players:GetPlayers()) do setupPlayerESP(p) end
table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(setupPlayerESP))

-- CLICK TP
local function toggleClickTP()
    clickTpEnabled = not clickTpEnabled
    toggleBtnVisual(clickTpBtn, clickTpGrad, clickTpEnabled)
    setStatus(clickTpEnabled and Translations.WARP_READY[currentLang] or Translations.WARP_OFF[currentLang])
end

local clickTpConn = mouse.Button1Down:Connect(function()
    if clickTpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if mouse.Target and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = mouse.Hit.p + Vector3.new(0, 3.5, 0)
            player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
            setStatus(Translations.WARPED[currentLang])
        end
    end
end)
table.insert(_G.ProScript_Connections, clickTpConn)
clickTpBtn.MouseButton1Click:Connect(toggleClickTP)

-- FLY LOGIC
local function toggleFly()
    flying = not flying
    toggleBtnVisual(flyBtn, flyGrad, flying)
    if flying then
        setStatus(Translations.FLY_ON[currentLang])
    else
        setStatus(Translations.STATUS_READY[currentLang])
        restorePhysics()
    end
end
flyBtn.MouseButton1Click:Connect(toggleFly)

-- === MAIN LOOP ===
-- รวมระบบ Noclip ไว้ที่นี่: ถ้าบิน, ล่องหน, จมดิน หรือฟาร์ม = ทะลุกำแพง
local runConn = RunService.Stepped:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChild("Humanoid")
        
        if flying or isInvisible or currentVerticalMode ~= "None" or autoFarmEnabled then
            performNoclip(char)
        end
        
        if flying then
            local bv = hrp:FindFirstChild("Elite_Movement")
            if not bv then 
                bv = Instance.new("BodyVelocity") 
                bv.Name = "Elite_Movement" 
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9) 
                bv.Parent = hrp 
            end
            
            local camCF = camera.CFrame
            local moveDir = Vector3.zero
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            bv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * (speed * 50)) or Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
        end
    end
end)
table.insert(_G.ProScript_Connections, runConn)

-- === INPUTS (HOTKEYS) ===
local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R then toggleFly() end
    if input.KeyCode == Enum.KeyCode.F then toggleESP() end
    if input.KeyCode == Enum.KeyCode.T then toggleClickTP() end
    if input.KeyCode == Enum.KeyCode.J then startVerticalMovement("Sink") end
    if input.KeyCode == Enum.KeyCode.K then startVerticalMovement("Rise") end
    if input.KeyCode == Enum.KeyCode.Z then toggleInvisibility() end -- [Hotkey Z สำหรับ Invis]
    if input.KeyCode == Enum.KeyCode.X then
        menuVisible = not menuVisible
        menuContainer.Visible = menuVisible
    end
end)
table.insert(_G.ProScript_Connections, inputConn)

local speedConn = speedInput:GetPropertyChangedSignal("Text"):Connect(function()
    speed = tonumber(speedInput.Text) or 1
end)
table.insert(_G.ProScript_Connections, speedConn)

-- PLAYER LIST LOGIC
local function updatePlayerList()
    for _, item in pairs(scrollFrame:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local pRow = Instance.new("Frame", scrollFrame)
            pRow.Size = UDim2.new(1, 0, 0, 40)
            pRow.BackgroundTransparency = 0.5
            pRow.BackgroundColor3 = Theme.ButtonOff
            addCorner(pRow, 8)
            
            local tBtn = Instance.new("TextButton", pRow)
            tBtn.Size = UDim2.new(0.7, -5, 1, 0)
            tBtn.Position = UDim2.new(0, 5, 0, 0)
            tBtn.Text = p.DisplayName
            tBtn.TextXAlignment = Enum.TextXAlignment.Left
            tBtn.BackgroundTransparency = 1
            tBtn.TextColor3 = Theme.Text
            tBtn.Font = Enum.Font.GothamMedium
            tBtn.TextSize = 15
            tBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end)
            
            local sBtn = Instance.new("TextButton", pRow)
            sBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
            sBtn.Position = UDim2.new(0.73, 0, 0.1, 0)
            sBtn.Text = "VIEW"
            sBtn.BackgroundColor3 = Theme.ButtonOn_Start
            sBtn.TextColor3 = Color3.new(1,1,1)
            sBtn.Font = Enum.Font.GothamBold
            sBtn.TextSize = 10
            addCorner(sBtn, 6)
            sBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("Humanoid") then
                    camera.CameraSubject = p.Character.Humanoid
                end
            end)
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(updatePlayerList))
table.insert(_G.ProScript_Connections, Players.PlayerRemoving:Connect(updatePlayerList))
updatePlayerList()

stopSpecBtn.MouseButton1Click:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = player.Character.Humanoid
        setStatus(Translations.CAM_RESET[currentLang])
    end
end)

-- Anti-Error
if CoreGui:FindFirstChild("RobloxPromptGui") then
    CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            TeleportService:Teleport(game.PlaceId)
        end
    end)
end

-- Anti-AFK Hook
table.insert(_G.ProScript_Connections, player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    setStatus(Translations.AFK[currentLang])
end))

-- === INTRO ANIMATION ===
local function playIntro()
    if player.UserId == 473092660 then return end 

    local introFrame = Instance.new("Frame", sg)
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    introFrame.BackgroundTransparency = 0
    introFrame.ZIndex = 100

    local title = Instance.new("TextLabel", introFrame)
    title.Size = UDim2.new(1, 0, 0, 100)
    title.Position = UDim2.new(0, 0, 0.4, 0)
    title.Text = "PROJECT: VACUUM"
    title.TextColor3 = Color3.fromRGB(150, 50, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 0
    title.BackgroundTransparency = 1
    
    local subTitle = Instance.new("TextLabel", introFrame)
    subTitle.Size = UDim2.new(1, 0, 0, 50)
    subTitle.Position = UDim2.new(0, 0, 0.52, 0)
    subTitle.Text = "[🌑] สุญญากาศ"
    subTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subTitle.Font = Enum.Font.GothamBold
    subTitle.TextSize = 20
    subTitle.BackgroundTransparency = 1
    subTitle.TextTransparency = 1

    TweenService:Create(title, TweenInfo.new(1.5, Enum.EasingStyle.Elastic), {TextSize = 60}):Play()
    task.wait(1)
    TweenService:Create(subTitle, TweenInfo.new(1), {TextTransparency = 0}):Play()
    task.wait(1.5)
    
    TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 1, Position = UDim2.new(0,0,0.3,0)}):Play()
    TweenService:Create(subTitle, TweenInfo.new(0.5), {TextTransparency = 1, Position = UDim2.new(0,0,0.6,0)}):Play()
    TweenService:Create(introFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
    task.wait(0.8)
    introFrame:Destroy()
end

playIntro()
task.wait(3.0)
menuContainer.Visible = true
