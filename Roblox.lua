--:PLAYER TELEPORT (V50.5 MEDIUM SINK):ControlGui_Pro_V50_Slow.lua
-- === V50.5: MEDIUM SINK (Fixed Speed) ===
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
if player.PlayerGui:FindFirstChild("ControlGui_Pro_V50") then player.PlayerGui.ControlGui_Pro_V50:Destroy() end
if player.PlayerGui:FindFirstChild("ControlGui_Pro_V50_Slow") then player.PlayerGui.ControlGui_Pro_V50_Slow:Destroy() end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 2;})
    end)
end

-- === 2. สร้าง UI ===
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "ControlGui_Pro_V50_Slow"
sg.ResetOnSpawn = false

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner", instance)
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

-- [สถานะเมนู] (ใช้แสดงสถานะฟาร์ม)
local statusLabel = Instance.new("TextLabel", sg)
statusLabel.Size = UDim2.new(0, 350, 0, 30)
statusLabel.Position = UDim2.new(1, -360, 1, -40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready (Press X to Hide)"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 16
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
local stroke = Instance.new("UIStroke", statusLabel)
stroke.Thickness = 2
stroke.Transparency = 0.5

local menuContainer = Instance.new("Frame", sg)
menuContainer.Size = UDim2.new(1, 0, 1, 0)
menuContainer.BackgroundTransparency = 1
menuContainer.Name = "MenuContainer"

-- [Side Menu]
local frame = Instance.new("ScrollingFrame", menuContainer)
frame.Size = UDim2.new(0, 300, 0, 350)
frame.Position = UDim2.new(1, -310, 0.20, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ScrollBarThickness = 4
addCorner(frame, 10)

local layout = Instance.new("UIListLayout", frame)
layout.SortOrder = Enum.SortOrder.Name
layout.Padding = UDim.new(0, 5)

local title = Instance.new("TextLabel", menuContainer)
title.Size = UDim2.new(0, 300, 0, 40)
title.Position = UDim2.new(1, -310, 0.20, -45)
title.Text = "⚡ PLAYER TELEPORT (V50.5)"
title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
addCorner(title, 8)

-- [Bottom Bar]
local mainBar = Instance.new("Frame", menuContainer)
mainBar.Size = UDim2.new(0, 920, 0, 70)
mainBar.Position = UDim2.new(0.5, -460, 0.78, 0) 
mainBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainBar.BackgroundTransparency = 0.1
addCorner(mainBar, 12)

local function createStyledBtn(parent, text, pos, sizeX, color)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(sizeX, -10, 0, 45)
    btn.Position = UDim2.new(pos, 5, 0.5, -22.5)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    addCorner(btn, 8)
    return btn
end

-- UI Elements
local flyLabel = Instance.new("TextLabel", mainBar)
flyLabel.Size = UDim2.new(0.10, 0, 1, 0)
flyLabel.Position = UDim2.new(0.01, 0, 0, 0)
flyLabel.Text = "FLY (R): OFF"
flyLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
flyLabel.BackgroundTransparency = 1 
flyLabel.Font = Enum.Font.GothamBold
flyLabel.TextSize = 12

local espLabel = Instance.new("TextLabel", mainBar)
espLabel.Size = UDim2.new(0.10, 0, 1, 0)
espLabel.Position = UDim2.new(0.11, 0, 0, 0) 
espLabel.Text = "ESP (F): OFF"
espLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
espLabel.BackgroundTransparency = 1 
espLabel.Font = Enum.Font.GothamBold
espLabel.TextSize = 12

local sinkBtn = createStyledBtn(mainBar, "SINK: OFF", 0.22, 0.13, Color3.fromRGB(45, 45, 45))
local clickTpBtn = createStyledBtn(mainBar, "CLICK TP (Ctrl): OFF", 0.35, 0.15, Color3.fromRGB(45, 45, 45))
local farmBtn = createStyledBtn(mainBar, "AUTO FARM: OFF", 0.51, 0.14, Color3.fromRGB(255, 170, 0)) 
farmBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
local stopSpecBtn = createStyledBtn(mainBar, "RESET CAM", 0.66, 0.11, Color3.fromRGB(180, 0, 150))

local speedInput = Instance.new("TextBox", mainBar)
speedInput.Size = UDim2.new(0.07, 0, 0, 40)
speedInput.Position = UDim2.new(0.79, 10, 0.5, -20)
speedInput.Text = tostring(speed)
speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedInput.TextColor3 = Color3.fromRGB(255, 215, 0)
speedInput.Font = Enum.Font.GothamBold
speedInput.PlaceholderText = "SPD"
speedInput.TextSize = 14
addCorner(speedInput, 8)

local speedTag = Instance.new("TextLabel", mainBar)
speedTag.Text = "SPEED"
speedTag.Size = UDim2.new(0, 50, 0, 20)
speedTag.Position = UDim2.new(0.87, 5, 0.5, -10)
speedTag.BackgroundTransparency = 1
speedTag.TextColor3 = Color3.fromRGB(150, 150, 150)
speedTag.Font = Enum.Font.GothamBold
speedTag.TextSize = 10
speedTag.TextXAlignment = Enum.TextXAlignment.Left

-- === 3. ระบบการทำงาน ===

local function setStatus(text)
    statusLabel.Text = "Status: " .. text
end

sinkBtn.MouseButton1Click:Connect(function()
    sinkEnabled = not sinkEnabled
    if sinkEnabled then
        sinkBtn.Text = "SINK: ON"
        sinkBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        setStatus("Medium Sinking Active...")
    else
        sinkBtn.Text = "SINK: OFF"
        sinkBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        setStatus("Ready")
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        end
    end
end)

-- Anti-Trip Stabilizer (กันล้ม)
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
    local uprightCFrame = CFrame.new(targetCFrame.Position)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = uprightCFrame})
    tween:Play()
    tween.Completed:Wait()
    
    root.Velocity = Vector3.new(0,0,0)
    root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
end

-- Hybrid Interact
local function forceInteract(duration)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    
    local found = false
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            if descendant.Parent and descendant.Parent:IsA("BasePart") then
                local dist = (descendant.Parent.Position - root.Position).Magnitude
                if dist <= 30 and descendant.Enabled then 
                    descendant:InputHoldBegin()
                    found = true
                end
            end
        end
    end

    task.spawn(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(duration)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        if found then
            for _, descendant in pairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then descendant:InputHoldEnd() end
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
            
            -- 1. รับงาน
            setStatus("Flying to JOB...")
            smartMove(POINT_A_JOB)
            task.wait(0.5) 
            if not autoFarmEnabled then break end
            
            setStatus("Interacting (JOB)...")
            forceInteract(3.5)
            
            -- 2. เติมไอติม
            setStatus("Flying to FILL...")
            smartMove(POINT_B_FILL)
            task.wait(0.5) 
            if not autoFarmEnabled then break end
            
            setStatus("Interacting (FILL)...")
            forceInteract(3.5)
            
            -- 3. ส่งงาน
            setStatus("Flying to SELL...")
            smartMove(POINT_C_SELL)
            task.wait(0.5) 
            if not autoFarmEnabled then break end
            
            setStatus("Interacting (SELL)...")
            forceInteract(3.5)
            
            task.wait(0.5)
        end
        removeStabilizer(player.Character)
        setStatus("Ready")
    end)
end

farmBtn.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        farmBtn.Text = "AUTO FARM: ON"
        farmBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        runAutoFarm()
    else
        farmBtn.Text = "AUTO FARM: OFF"
        farmBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        removeStabilizer(player.Character)
        setStatus("Ready")
    end
end)

-- ESP & Player List
local function createESPItems(p, char)
    if not espEnabled then return end
    local root = char:WaitForChild("HumanoidRootPart", 1)
    if not root then return end
    if char:FindFirstChild("Elite_Highlight") then char.Elite_Highlight:Destroy() end
    if char:FindFirstChild("Elite_Tag") then char.Elite_Tag:Destroy() end
    local hi = Instance.new("Highlight", char)
    hi.Name = "Elite_Highlight"
    hi.FillTransparency = 0.5
    hi.OutlineColor = Color3.fromRGB(255, 255, 255)
    hi.FillColor = Color3.fromRGB(255, 0, 0)
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
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14
    tl.TextStrokeTransparency = 0.5
end

local function toggleESP()
    espEnabled = not espEnabled
    espLabel.Text = espEnabled and "ESP (F): ON" or "ESP (F): OFF"
    espLabel.TextColor3 = espEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 80, 80)
    for _, p in pairs(Players:GetPlayers()) do
        if espEnabled and p ~= player and p.Character then createESPItems(p, p.Character) end
        if not espEnabled and p.Character then 
            if p.Character:FindFirstChild("Elite_Highlight") then p.Character.Elite_Highlight:Destroy() end
            if p.Character:FindFirstChild("Elite_Tag") then p.Character.Elite_Tag:Destroy() end
        end
    end
end
table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) if espEnabled then createESPItems(p, c) end end) end))

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
    clickTpBtn.Text = clickTpEnabled and "CLICK TP: ON" or "CLICK TP (Ctrl): OFF"
    clickTpBtn.BackgroundColor3 = clickTpEnabled and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(45, 45, 45)
end)

-- Fly System
local function toggleFly()
    flying = not flying
    flyLabel.Text = flying and "FLY (R): ON" or "FLY (R): OFF"
    flyLabel.TextColor3 = flying and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 80, 80)
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
            player.Character.Humanoid.PlatformStand = false
            setStatus("Ready")
        end
    end
end

-- Update Loop
local runConn = RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        
        -- Fly Logic
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
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end

        -- [SLOW SINK LOGIC] FIXED SPEED
        if sinkEnabled then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, -0.15, 0) -- ปรับเป็น -0.15 ให้เร็วขึ้นหน่อย
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            hrp.Velocity = Vector3.new(0,0,0)
        end
        
        -- Auto Farm Noclip
        if autoFarmEnabled then
            for _, v in pairs(player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
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
        statusLabel.TextColor3 = menuVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
    end
end)
table.insert(_G.ProScript_Connections, inputConn)

local speedConn = speedInput:GetPropertyChangedSignal("Text"):Connect(function() speed = tonumber(speedInput.Text) or 1 end)
table.insert(_G.ProScript_Connections, speedConn)

-- Player List
local function updatePlayerList()
    for _, item in pairs(frame:GetChildren()) do if item:IsA("Frame") then item:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local pRow = Instance.new("Frame", frame)
            pRow.Size = UDim2.new(1, -10, 0, 50)
            pRow.BackgroundTransparency = 1
            local tBtn = Instance.new("TextButton", pRow)
            tBtn.Size = UDim2.new(0.7, -5, 1, 0)
            tBtn.Text = "  " .. p.DisplayName
            tBtn.TextXAlignment = Enum.TextXAlignment.Left
            tBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tBtn.Font = Enum.Font.GothamBold
            tBtn.TextSize = 16
            addCorner(tBtn, 8)
            tBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
            end)
            local sBtn = createStyledBtn(pRow, "SPEC", 0.7, 0.3, Color3.fromRGB(0, 80, 150))
            sBtn.TextSize = 12
            sBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("Humanoid") then
                    camera.CameraSubject = p.Character.Humanoid
                    setStatus("Spectating: " .. p.DisplayName)
                end
            end)
        end
    end
    frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
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

-- Auto Rejoin
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == 'ErrorPrompt' then
        TeleportService:Teleport(game.PlaceId)
    end
end)

notify("V50.5 Loaded", "Medium Sink Active!")
