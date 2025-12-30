--:PLAYER TELEPORT (V50.9 RED ESP & AUTO SIZE):ControlGui_Pro_V50_Modern.lua
-- === V50.9: RED ESP + SMART STATUS BAR ===
-- 1. ล้างระบบเก่า
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
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local mouse = player:GetMouse() 
local camera = workspace.CurrentCamera
local flying = false
local espEnabled = false
local sinkEnabled = false
local clickTpEnabled = false 
local autoFarmEnabled = false 
local menuVisible = true 
local speed = 1

-- พิกัด Auto Farm
local POINT_A_JOB   = CFrame.new(1146.80627, -245.849579, -561.207458)
local POINT_B_FILL  = CFrame.new(1147.00024, -245.849609, -568.630432)
local POINT_C_SELL  = CFrame.new(1143.9364,  -245.849579, -580.007935)

-- ล้าง UI เก่า
if player.PlayerGui:FindFirstChild("ControlGui_Pro_V50_Slow") then player.PlayerGui.ControlGui_Pro_V50_Slow:Destroy() end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 2;})
    end)
end

-- === 2. สร้าง UI (MODERN DESIGN) ===
local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    ButtonOff = Color3.fromRGB(35, 35, 40),
    ButtonOn_Start = Color3.fromRGB(0, 170, 255),
    ButtonOn_End = Color3.fromRGB(0, 100, 255),
    ESP_Color = Color3.fromRGB(255, 0, 0), -- สีแดงสำหรับ ESP
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Stroke = Color3.fromRGB(60, 60, 70)
}

local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "ControlGui_Pro_V50_Slow"
sg.ResetOnSpawn = false

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

local menuContainer = Instance.new("Frame", sg)
menuContainer.Size = UDim2.new(1, 0, 1, 0)
menuContainer.BackgroundTransparency = 1
menuContainer.Name = "MenuContainer"

-- [STATUS PILL - AUTO SIZE]
local statusFrame = Instance.new("Frame", sg)
statusFrame.AutomaticSize = Enum.AutomaticSize.X -- ปรับขนาดแนวนอนอัตโนมัติ
statusFrame.Size = UDim2.new(0, 0, 0, 36) -- ความสูงคงที่
statusFrame.AnchorPoint = Vector2.new(1, 1) -- จุดอ้างอิงอยู่ขวาล่าง
statusFrame.Position = UDim2.new(1, -20, 1, -50) -- ตำแหน่งมุมขวาล่าง
statusFrame.BackgroundColor3 = Theme.Background
statusFrame.BackgroundTransparency = 0.1
addCorner(statusFrame, 10)
addStroke(statusFrame, 0.3)

-- เพิ่ม Padding เพื่อให้ตัวหนังสือไม่ชิดขอบ
local statusPad = Instance.new("UIPadding", statusFrame)
statusPad.PaddingLeft = UDim.new(0, 15)
statusPad.PaddingRight = UDim.new(0, 15)

local statusLabel = Instance.new("TextLabel", statusFrame)
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Theme.Text
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Center -- จัดกลางเพราะกรอบปรับตามคำแล้ว

-- [SIDE MENU - PLAYER LIST]
local sideFrame = Instance.new("Frame", menuContainer)
sideFrame.Size = UDim2.new(0, 260, 0, 350)
sideFrame.Position = UDim2.new(1, -280, 0.2, 0)
sideFrame.BackgroundColor3 = Theme.Background
sideFrame.BackgroundTransparency = 0.1
addCorner(sideFrame, 12)
addStroke(sideFrame, 0.4)

local sideTitle = Instance.new("TextLabel", sideFrame)
sideTitle.Size = UDim2.new(1, 0, 0, 40)
sideTitle.BackgroundTransparency = 1
sideTitle.Text = "PLAYER LIST"
sideTitle.TextColor3 = Theme.TextDim
sideTitle.Font = Enum.Font.GothamBold
sideTitle.TextSize = 12

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

-- [BOTTOM BAR - CONTROLS]
local mainBar = Instance.new("Frame", menuContainer)
mainBar.Size = UDim2.new(0, 800, 0, 65)
mainBar.Position = UDim2.new(0.5, -400, 0.85, 0) 
mainBar.BackgroundColor3 = Theme.Background
mainBar.BackgroundTransparency = 0.1
addCorner(mainBar, 16)
addStroke(mainBar, 0.3)

-- ฟังก์ชันสร้างปุ่ม
local function createStyledBtn(parent, text, order, sizeScale)
    local btnContainer = Instance.new("Frame", parent)
    btnContainer.Size = UDim2.new(sizeScale, -10, 0, 45)
    btnContainer.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", btnContainer)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = text
    btn.BackgroundColor3 = Theme.ButtonOff
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    addCorner(btn, 10)
    local grad = addGradient(btn)
    
    return btn, grad
end

local barLayout = Instance.new("UIListLayout", mainBar)
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barLayout.Padding = UDim.new(0, 10)

-- Create Buttons
local flyBtn, flyGrad = createStyledBtn(mainBar, "FLY (R)", 1, 0.12)
local espBtn, espGrad = createStyledBtn(mainBar, "ESP (F)", 2, 0.12)
local sinkBtn, sinkGrad = createStyledBtn(mainBar, "SINK", 3, 0.12)
local clickTpBtn, clickTpGrad = createStyledBtn(mainBar, "CLICK TP", 4, 0.15)
local farmBtn, farmGrad = createStyledBtn(mainBar, "AUTO FARM", 5, 0.15)
local stopSpecBtn, stopGrad = createStyledBtn(mainBar, "RESET CAM", 6, 0.12)

local speedContainer = Instance.new("Frame", mainBar)
speedContainer.Size = UDim2.new(0.12, -10, 0, 45)
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

-- === 3. ระบบการทำงาน ===

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

-- Fix Physics Function
local function restorePhysics()
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        if root then
            root.Velocity = Vector3.new(0,0,0)
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
        for _, v in pairs(player.Character:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- Button Logics
sinkBtn.MouseButton1Click:Connect(function()
    sinkEnabled = not sinkEnabled
    toggleBtnVisual(sinkBtn, sinkGrad, sinkEnabled)
    if sinkEnabled then
        setStatus("Sinking Active...")
    else
        setStatus("Ready")
        restorePhysics()
    end
end)

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
    tween:Play()
    tween.Completed:Wait()
    root.Velocity = Vector3.new(0,0,0)
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
        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt") or part.Parent:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt and prompt.Enabled then
            prompt:InputHoldBegin()
            found = true
        end
    end
    task.spawn(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(duration)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        if found then
            for _, part in ipairs(partsInRadius) do
                local prompt = part:FindFirstChildWhichIsA("ProximityPrompt") or part.Parent:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then prompt:InputHoldEnd() end
            end
        end
    end)
    task.wait(duration)
end

local function runAutoFarm()
    task.spawn(function()
        while autoFarmEnabled do
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            addStabilizer(player.Character)
            setStatus("Farming: Job")
            smartMove(POINT_A_JOB)
            task.wait(0.5) 
            if not autoFarmEnabled then break end
            forceInteract(3.5)
            setStatus("Farming: Fill")
            smartMove(POINT_B_FILL)
            task.wait(0.5) 
            if not autoFarmEnabled then break end
            forceInteract(3.5)
            setStatus("Farming: Sell")
            smartMove(POINT_C_SELL)
            task.wait(0.5) 
            if not autoFarmEnabled then break end
            forceInteract(3.5)
            task.wait(0.5)
        end
        removeStabilizer(player.Character)
        restorePhysics()
        setStatus("Ready")
    end)
end

farmBtn.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    toggleBtnVisual(farmBtn, farmGrad, autoFarmEnabled)
    if autoFarmEnabled then
        runAutoFarm()
    else
        removeStabilizer(player.Character)
        restorePhysics()
        setStatus("Ready")
    end
end)

-- ESP (RED COLOR)
local function createESPItems(p, char)
    if not espEnabled then return end
    local root = char:WaitForChild("HumanoidRootPart", 1)
    if not root then return end
    if char:FindFirstChild("Elite_Highlight") then char.Elite_Highlight:Destroy() end
    if char:FindFirstChild("Elite_Tag") then char.Elite_Tag:Destroy() end
    local hi = Instance.new("Highlight", char)
    hi.Name = "Elite_Highlight"
    hi.FillTransparency = 0.5
    hi.OutlineColor = Theme.ESP_Color -- สีแดง (กรอบ)
    hi.FillColor = Theme.ESP_Color -- สีแดง (ตัว)
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
    tl.TextColor3 = Theme.ESP_Color -- ชื่อสีแดงด้วย
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14
    tl.TextStrokeTransparency = 0.5
end

local function toggleESP()
    espEnabled = not espEnabled
    toggleBtnVisual(espBtn, espGrad, espEnabled)
    for _, p in pairs(Players:GetPlayers()) do
        if espEnabled and p ~= player and p.Character then createESPItems(p, p.Character) end
        if not espEnabled and p.Character then 
            if p.Character:FindFirstChild("Elite_Highlight") then p.Character.Elite_Highlight:Destroy() end
            if p.Character:FindFirstChild("Elite_Tag") then p.Character.Elite_Tag:Destroy() end
        end
    end
end
table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) if espEnabled then createESPItems(p, c) end end) end))

espBtn.MouseButton1Click:Connect(toggleESP)

-- Click TP
local clickTpConn = mouse.Button1Down:Connect(function()
    if clickTpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if mouse.Target and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = mouse.Hit.p + Vector3.new(0, 3, 0)
            player.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos)
            setStatus("Teleported!")
        end
    end
end)
table.insert(_G.ProScript_Connections, clickTpConn)

clickTpBtn.MouseButton1Click:Connect(function()
    clickTpEnabled = not clickTpEnabled
    toggleBtnVisual(clickTpBtn, clickTpGrad, clickTpEnabled)
end)

-- Fly System
local function toggleFly()
    flying = not flying
    toggleBtnVisual(flyBtn, flyGrad, flying)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        if flying then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "Elite_Movement"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
            player.Character.Humanoid.PlatformStand = true
            setStatus("Flying Mode")
        else
            if hrp:FindFirstChild("Elite_Movement") then hrp.Elite_Movement:Destroy() end
            setStatus("Ready")
            restorePhysics()
        end
    end
end
flyBtn.MouseButton1Click:Connect(toggleFly)

-- Update Loop
local runConn = RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local hum = player.Character:FindFirstChild("Humanoid")
        
        if flying then
            local bv = hrp:FindFirstChild("Elite_Movement")
            if bv then
                bv.Velocity = Vector3.new(0, 0, 0)
                local moveDir = Vector3.new(0,0,0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
                if moveDir.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (moveDir.Unit * speed) end
                hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            end
            if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
            for _, v in pairs(player.Character:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end

        if sinkEnabled then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, -0.15, 0)
            hrp.Velocity = Vector3.new(0,0,0)
            if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
            for _, v in pairs(player.Character:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
        
        if autoFarmEnabled then
            for _, v in pairs(player.Character:GetChildren()) do if v:IsA("BasePart") and v.CanCollide == true then v.CanCollide = false end end
        end
    end
end)
table.insert(_G.ProScript_Connections, runConn)

local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R then toggleFly() end
    if input.KeyCode == Enum.KeyCode.F then toggleESP() end
    if input.KeyCode == Enum.KeyCode.X then
        menuVisible = not menuVisible
        menuContainer.Visible = menuVisible
    end
end)
table.insert(_G.ProScript_Connections, inputConn)

local speedConn = speedInput:GetPropertyChangedSignal("Text"):Connect(function() speed = tonumber(speedInput.Text) or 1 end)
table.insert(_G.ProScript_Connections, speedConn)

-- Update Player List (Styled)
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
            tBtn.TextSize = 14
            tBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    setStatus("TP to " .. p.DisplayName)
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
                    setStatus("Watch: " .. p.DisplayName)
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
        setStatus("Camera Reset")
    end
end)

-- Auto Rejoin System
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == 'ErrorPrompt' then
        TeleportService:Teleport(game.PlaceId)
    end
end)

notify("V50.9 Updated", "Red ESP + Smart Status Bar")
