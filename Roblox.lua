-- [[ ส่วนตรวจสอบรหัสแมพ (Place ID Check) ]] --
if game.PlaceId ~= 8391915840 then
    warn("Script stopped: This script only supports Place ID 8391915840")
    return
end
-------------------------------------------------

-- 1. ล้างระบบเก่า (Clean Re-execution)
if _G.ProScript_Connections then
    for _, conn in pairs(_G.ProScript_Connections) do
        if conn then conn:Disconnect() end
    end
end
_G.ProScript_Connections = {} 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse() 
local camera = workspace.CurrentCamera

-- สถานะตัวแปร
local flying = false
local espEnabled = false
local clickTpEnabled = false 
local autoFarmEnabled = false 
local menuVisible = true 
local speed = 2
local currentLang = "EN" 

-- ตัวแปรสำหรับ Stats Farm
local sellCount = 0
local farmStartTime = 0
local currentFarmState = "Idle"
local currentTween = nil

-- ตัวแปรสำหรับ Sink (ปรับปรุงใหม่)
local isSinkActive = false 
local sinkConnection = nil

-- พิกัด Auto Farm
local POINT_A_JOB   = CFrame.new(1146.80627, -245.849579, -561.207458)
local POINT_B_FILL  = CFrame.new(1147.00024, -245.849609, -568.630432)
local POINT_C_SELL  = CFrame.new(1143.9364,  -245.849579, -580.007935)

-- ล้าง UI เก่า
if player.PlayerGui:FindFirstChild("ControlGui_Pro_V55") then player.PlayerGui.ControlGui_Pro_V55:Destroy() end
if player.PlayerGui:FindFirstChild("ControlGui_Pro_V54") then player.PlayerGui.ControlGui_Pro_V54:Destroy() end

-- === THEME: VACUUM ===
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
    SINK = {EN = "ASCENSION", TH = "จมแล้วลอย"}, -- เปลี่ยนชื่อปุ่ม
    TP = {EN = "CLICK TP (T)", TH = "วาร์ป (T)"},
    FARM = {EN = "AUTO FARM", TH = "ออโต้ฟาร์ม"},
    RESET = {EN = "RESET CAM", TH = "รีเซ็ตกล้อง"},
    LIST = {EN = "ENTITIES LIST", TH = "รายชื่อผู้เล่น"},
    HINT = {EN = "[X] TOGGLE MENU", TH = "[X] เปิด/ปิด เมนู"},
    STATUS_WAIT = {EN = "Vacuum: Waiting...", TH = "Vacuum: รอคำสั่ง..."},
    STATUS_READY = {EN = "Vacuum: Ready", TH = "สถานะ: พร้อมใช้งาน"},
    LANG_BTN = {EN = "LANG: EN", TH = "ภาษา: TH"}
}

local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "ControlGui_Pro_V55"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- === INTRO (With ID Check) ===
local function playIntro()
    if player.UserId == 473092660 then return end -- Bypass ID

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

-- === UTILS ===
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
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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

-- === UI SETUP ===

-- [TOGGLE HINT]
local hintLabel = Instance.new("TextLabel", sg)
hintLabel.Size = UDim2.new(0, 200, 0, 30)
hintLabel.Position = UDim2.new(0.5, -100, 0, 5) 
hintLabel.BackgroundTransparency = 1
hintLabel.Text = Translations.HINT.EN
hintLabel.TextColor3 = Theme.TextDim
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 18
hintLabel.TextTransparency = 0.5

local menuContainer = Instance.new("Frame", sg)
menuContainer.Size = UDim2.new(1, 0, 1, 0)
menuContainer.BackgroundTransparency = 1
menuContainer.Name = "MenuContainer"
menuContainer.Visible = false

-- [STATUS PILL]
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
Instance.new("UIPadding", statusFrame).PaddingLeft = UDim.new(0, 15)
Instance.new("UIPadding", statusFrame).PaddingRight = UDim.new(0, 15)

-- [SIDE MENU]
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

-- [BOTTOM BAR]
local mainBar = Instance.new("Frame", menuContainer)
mainBar.Size = UDim2.new(0, 900, 0, 65) 
mainBar.Position = UDim2.new(0.5, -450, 0.85, 0) 
mainBar.BackgroundColor3 = Theme.Background
mainBar.BackgroundTransparency = 0.1
addCorner(mainBar, 16)
addStroke(mainBar, 0.3)
makeDraggable(mainBar)

local function createStyledBtn(parent, text, sizeScale)
    local btnContainer = Instance.new("Frame", parent)
    btnContainer.Size = UDim2.new(sizeScale, -10, 0, 45)
    btnContainer.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", btnContainer)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = Theme.ButtonOff
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.AutoButtonColor = false
    addCorner(btn, 10)
    local grad = addGradient(btn)
    return btn, grad
end

local barLayout = Instance.new("UIListLayout", mainBar)
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barLayout.Padding = UDim.new(0, 8)

-- ปุ่ม
local flyBtn, flyGrad = createStyledBtn(mainBar, Translations.FLY.EN, 0.11)
local espBtn, espGrad = createStyledBtn(mainBar, Translations.ESP.EN, 0.11)
local sinkBtn, sinkGrad = createStyledBtn(mainBar, Translations.SINK.EN, 0.11)
local clickTpBtn, clickTpGrad = createStyledBtn(mainBar, Translations.TP.EN, 0.14)
local farmBtn, farmGrad = createStyledBtn(mainBar, Translations.FARM.EN, 0.14)
local stopSpecBtn, stopGrad = createStyledBtn(mainBar, Translations.RESET.EN, 0.11)

-- SPEED INPUT
local speedContainer = Instance.new("Frame", mainBar)
speedContainer.Size = UDim2.new(0.1, -5, 0, 45)
speedContainer.BackgroundTransparency = 1
addCorner(speedContainer, 10)

local speedInput = Instance.new("TextBox", speedContainer)
speedInput.Size = UDim2.new(1, 0, 1, 0)
speedInput.Text = tostring(speed)
speedInput.BackgroundColor3 = Theme.ButtonOff
speedInput.TextColor3 = Theme.ButtonOn_Start
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 18
speedInput.PlaceholderText = "SPD"
addCorner(speedInput, 10)
addStroke(speedInput, 0.6)

-- LANGUAGE BUTTON
local langBtn, langGrad = createStyledBtn(mainBar, Translations.LANG_BTN.EN, 0.1)

-- === FUNCTIONS ===
local function updateTexts()
    flyBtn.Text = Translations.FLY[currentLang]
    espBtn.Text = Translations.ESP[currentLang]
    sinkBtn.Text = Translations.SINK[currentLang]
    clickTpBtn.Text = Translations.TP[currentLang]
    farmBtn.Text = Translations.FARM[currentLang]
    stopSpecBtn.Text = Translations.RESET[currentLang]
    sideTitle.Text = Translations.LIST[currentLang]
    hintLabel.Text = Translations.HINT[currentLang]
    langBtn.Text = Translations.LANG_BTN[currentLang]
    
    if statusLabel.Text == Translations.STATUS_READY.EN or statusLabel.Text == Translations.STATUS_READY.TH then
         statusLabel.Text = Translations.STATUS_READY[currentLang]
    end
end

langBtn.MouseButton1Click:Connect(function()
    currentLang = (currentLang == "EN") and "TH" or "EN"
    updateTexts()
end)

local function setStatus(text) statusLabel.Text = text end

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
            if root:FindFirstChild("SinkLift") then root.SinkLift:Destroy() end -- เคลียร์ตัวลอย
            if root:FindFirstChild("SinkGyro") then root.SinkGyro:Destroy() end -- เคลียร์ตัวหมุน
            root.Anchored = false 
        end
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- HELPER: Noclip
local function performNoclip(char)
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") and v.CanCollide == true then 
            v.CanCollide = false 
        end
    end
end

-- Anti-AFK
table.insert(_G.ProScript_Connections, player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    setStatus("System: Anti-AFK")
end))

-- [[ NEW SINK & INFINITE RISE LOGIC ]]
local function toggleSinkLevitate()
    isSinkActive = not isSinkActive
    toggleBtnVisual(sinkBtn, sinkGrad, isSinkActive)

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")

    if isSinkActive then
        -- === เริ่มทำงาน (จม -> รอ -> ลอยยาวๆ) ===
        if not root then return end
        
        task.spawn(function()
            -- Step 1: จมดิน
            setStatus("Action: Sinking...")
            if hum then hum.PlatformStand = true end
            root.Anchored = true 
            performNoclip(char)

            local startCF = root.CFrame
            local downCF = startCF * CFrame.new(0, -10, 0)
            local tweenDown = TweenService:Create(root, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = downCF})
            tweenDown:Play()
            tweenDown.Completed:Wait()

            -- Step 2: หยุดรอ (ถ้ากดยกเลิกกลางคัน ให้จบเลย)
            if not isSinkActive then return end
            setStatus("Action: Holding...")
            task.wait(1.5)

            -- Step 3: ลอยขึ้นเรื่อยๆ (Infinite Rise)
            if not isSinkActive then return end
            setStatus("Action: Ascending...")
            
            root.Anchored = false -- ปลดล็อคเพื่อให้ BodyVelocity ทำงาน

            -- แรงยกตัว
            local bv = Instance.new("BodyVelocity")
            bv.Name = "SinkLift"
            bv.Velocity = Vector3.new(0, 6, 0) -- ความเร็วในการลอย (ปรับเลขนี้ได้ถ้าอยากให้เร็ว/ช้า)
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Parent = root

            -- ตัวทรงตัว (ไม่ให้หมุนติ้ว)
            local bg = Instance.new("BodyGyro")
            bg.Name = "SinkGyro"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 9e4
            bg.CFrame = root.CFrame
            bg.Parent = root

            -- ลูป Noclip ตลอดเวลาที่ลอย
            if sinkConnection then sinkConnection:Disconnect() end
            sinkConnection = RunService.Stepped:Connect(function()
                if isSinkActive and char then
                    performNoclip(char)
                else
                    if sinkConnection then sinkConnection:Disconnect() end
                end
            end)
            table.insert(_G.ProScript_Connections, sinkConnection)
        end)

    else
        -- === หยุดทำงาน (Reset) ===
        setStatus(Translations.STATUS_READY[currentLang])
        if sinkConnection then sinkConnection:Disconnect() end
        restorePhysics() -- ฟังก์ชันนี้จะลบ SinkLift และ SinkGyro ให้เอง
    end
end

sinkBtn.MouseButton1Click:Connect(toggleSinkLevitate)

-- AUTO FARM
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
    if hrp and hrp:FindFirstChild("FarmGyro") then hrp.FarmGyro:Destroy() end
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
        if prompt and prompt.Enabled then prompt:InputHoldBegin() found = true end
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
                if prompt then prompt:InputHoldEnd() end
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

local function runAutoFarm()
    farmStartTime = os.time()
    sellCount = 0
    currentFarmState = "Init"

    task.spawn(function()
        while autoFarmEnabled do
            local elapsed = os.time() - farmStartTime
            local timeStr = formatTime(elapsed)
            setStatus(string.format("%s | Time: %s | Sold: %d", currentFarmState, timeStr, sellCount))
            task.wait(1)
        end
    end)

    task.spawn(function()
        while autoFarmEnabled do
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then task.wait(1) return end
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
    if autoFarmEnabled then moveStatusUI(true) runAutoFarm() else 
        if currentTween then currentTween:Cancel() end
        removeStabilizer(player.Character)
        restorePhysics()
        setStatus("Aborted.")
        moveStatusUI(false)
    end
end)

-- ESP SYSTEM (OPTIMIZED)
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
        if espEnabled then 
            createESPItems(p, c) 
        end 
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
            if espEnabled then createESPItems(p, p.Character) else removeESP(p.Character) end
        end
    end
    setStatus(espEnabled and "Visuals: ON" or "Visuals: OFF")
end
espBtn.MouseButton1Click:Connect(toggleESP)
for _, p in pairs(Players:GetPlayers()) do setupPlayerESP(p) end
table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(function(p) setupPlayerESP(p) end))

-- CLICK TP
local function toggleClickTP()
    clickTpEnabled = not clickTpEnabled
    toggleBtnVisual(clickTpBtn, clickTpGrad, clickTpEnabled)
    setStatus(clickTpEnabled and "Warp: READY" or "Warp: OFF")
end
local clickTpConn = mouse.Button1Down:Connect(function()
    if clickTpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if mouse.Target and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = mouse.Hit.p + Vector3.new(0, 3.5, 0)
            player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
            setStatus("Warped.")
        end
    end
end)
table.insert(_G.ProScript_Connections, clickTpConn)
clickTpBtn.MouseButton1Click:Connect(toggleClickTP)

-- FLY & PHYSICS LOOP (OPTIMIZED)
local function toggleFly()
    flying = not flying
    toggleBtnVisual(flyBtn, flyGrad, flying)
    if flying then setStatus("Flight Enabled") else setStatus(Translations.STATUS_READY[currentLang]) restorePhysics() end
end
flyBtn.MouseButton1Click:Connect(toggleFly)

-- MAIN LOOP (HEAVILY OPTIMIZED)
local runConn = RunService.Stepped:Connect(function()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChild("Humanoid")
        
        if flying then
            local bv = hrp:FindFirstChild("Elite_Movement")
            if not bv then 
                bv = Instance.new("BodyVelocity") 
                bv.Name = "Elite_Movement" 
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge) 
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
            performNoclip(char)
        end
        
        if autoFarmEnabled then
            performNoclip(char)
        end
    end
end)
table.insert(_G.ProScript_Connections, runConn)

-- INPUTS
local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R then toggleFly() end
    if input.KeyCode == Enum.KeyCode.F then toggleESP() end
    if input.KeyCode == Enum.KeyCode.T then toggleClickTP() end
    if input.KeyCode == Enum.KeyCode.X then menuVisible = not menuVisible menuContainer.Visible = menuVisible end
end)
table.insert(_G.ProScript_Connections, inputConn)
local speedConn = speedInput:GetPropertyChangedSignal("Text"):Connect(function() speed = tonumber(speedInput.Text) or 1 end)
table.insert(_G.ProScript_Connections, speedConn)

-- PLAYER LIST
local function updatePlayerList()
    for _, item in pairs(scrollFrame:GetChildren()) do if item:IsA("Frame") then item:Destroy() end end
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
            sBtn.MouseButton1Click:Connect(function() if p.Character and p.Character:FindFirstChild("Humanoid") then camera.CameraSubject = p.Character.Humanoid end end)
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end
table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(updatePlayerList))
table.insert(_G.ProScript_Connections, Players.PlayerRemoving:Connect(updatePlayerList))
updatePlayerList()

stopSpecBtn.MouseButton1Click:Connect(function() if player.Character and player.Character:FindFirstChild("Humanoid") then camera.CameraSubject = player.Character.Humanoid setStatus("Cam Reset") end end)

if CoreGui:FindFirstChild("RobloxPromptGui") then
    CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child) if child.Name == 'ErrorPrompt' then TeleportService:Teleport(game.PlaceId) end end)
end

-- RUN INTRO
playIntro()

-- SHOW MENU
if player.UserId == 473092660 then
    menuContainer.Visible = true
else
    task.wait(3.0)
    menuContainer.Visible = true
end
