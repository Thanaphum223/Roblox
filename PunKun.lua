--:PLAYER STICKER (V2 AUTO NEAREST):PlayerSticker_V2.lua
-- === PLAYER STICKER V2: AUTO NEAREST ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local targetPlr = nil
local activeMode = nil -- "Face", "Back", "Head", "Orbit"
local angle = 0
local connection = nil

-- ล้าง UI เก่า
if CoreGui:FindFirstChild("StickerUI_Pro") then CoreGui.StickerUI_Pro:Destroy() end

-- === 1. UI SETUP (TOP BAR) ===
local sg = Instance.new("ScreenGui")
sg.Name = "StickerUI_Pro"
sg.Parent = CoreGui 

local topBar = Instance.new("Frame", sg)
topBar.Size = UDim2.new(0, 650, 0, 50) -- ขยายความยาวนิดนึง
topBar.Position = UDim2.new(0.5, -325, 0, 10) 
topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
topBar.BackgroundTransparency = 0.2
local corner = Instance.new("UICorner", topBar)
corner.CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", topBar)
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.5

-- Input ชื่อ
local nameInput = Instance.new("TextBox", topBar)
nameInput.Size = UDim2.new(0, 100, 0, 30)
nameInput.Position = UDim2.new(0, 10, 0.5, -15)
nameInput.PlaceholderText = "Name / Empty"
nameInput.Text = ""
nameInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
nameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
nameInput.Font = Enum.Font.GothamBold
nameInput.TextSize = 12
local c1 = Instance.new("UICorner", nameInput)
c1.CornerRadius = UDim.new(0, 8)

-- ฟังก์ชันสร้างปุ่ม
local function createBtn(text, posX, width, color)
    local btn = Instance.new("TextButton", topBar)
    btn.Size = UDim2.new(0, width, 0, 30)
    btn.Position = UDim2.new(0, posX, 0.5, -15)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    return btn
end

-- ปุ่มต่างๆ (จัดตำแหน่งใหม่)
local btnNear = createBtn("🔍 NEAR", 115, 60, Color3.fromRGB(255, 150, 0)) -- ปุ่มหาคนใกล้ตัว
local btnFace = createBtn("👁️ FACE", 185, 80, Color3.fromRGB(60, 60, 70))
local btnBack = createBtn("🎒 BACK", 275, 80, Color3.fromRGB(60, 60, 70))
local btnHead = createBtn("👑 HEAD", 365, 80, Color3.fromRGB(60, 60, 70))
local btnOrbit = createBtn("🪐 ORBIT", 455, 80, Color3.fromRGB(60, 60, 70))
local btnStop = createBtn("❌ STOP", 545, 95, Color3.fromRGB(200, 50, 50))

local statusText = Instance.new("TextLabel", topBar)
statusText.Size = UDim2.new(1, 0, 0, 15)
statusText.Position = UDim2.new(0, 0, 1, 2)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: Idle (Click 'NEAR' or Type Name)"
statusText.TextColor3 = Color3.fromRGB(255, 255, 0)
statusText.Font = Enum.Font.GothamBold
statusText.TextSize = 12

-- === 2. SYSTEM LOGIC ===

local function notify(msg)
    statusText.Text = "Status: " .. msg
end

-- ฟังก์ชันหาคนใกล้ตัวที่สุด
local function getClosestPlayer()
    local closest = nil
    local minDist = math.huge
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = lp.Character.HumanoidRootPart.Position

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = p
            end
        end
    end
    return closest
end

-- ฟังก์ชันหาเป้าหมาย (ชื่อ หรือ ใกล้สุด)
local function findTarget()
    local text = nameInput.Text:lower()
    
    -- 1. ถ้ามีชื่อในช่อง ให้หาตามชื่อ
    if text ~= "" then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and (p.Name:lower():find(text) or p.DisplayName:lower():find(text)) then
                nameInput.Text = p.DisplayName
                return p
            end
        end
    else
        -- 2. ถ้าช่องว่าง ให้หาคนใกล้สุด
        local nearPlr = getClosestPlayer()
        if nearPlr then
            nameInput.Text = nearPlr.DisplayName
            return nearPlr
        end
    end
    return nil
end

local function stopStick()
    if connection then connection:Disconnect() connection = nil end
    activeMode = nil
    targetPlr = nil
    
    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.PlatformStand = false
        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    -- Reset สีปุ่ม
    btnFace.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    btnBack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    btnHead.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    btnOrbit.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    notify("Stopped")
end

local function startStick(mode)
    local target = findTarget() -- หาคน (ตามชื่อ หรือ ใกล้สุด)
    if not target then notify("No Target Found!") return end
    
    stopStick()
    targetPlr = target
    activeMode = mode
    notify("Sticking to: " .. target.DisplayName .. " (" .. mode .. ")")

    -- Highlight ปุ่มที่กด
    if mode == "Face" then btnFace.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end
    if mode == "Back" then btnBack.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end
    if mode == "Head" then btnHead.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end
    if mode == "Orbit" then btnOrbit.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end

    connection = RunService.Stepped:Connect(function()
        if not targetPlr or not targetPlr.Character or not targetPlr.Character:FindFirstChild("HumanoidRootPart") then
            stopStick()
            return
        end
        if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end

        local hrp = lp.Character.HumanoidRootPart
        local targetHrp = targetPlr.Character.HumanoidRootPart
        local hum = lp.Character.Humanoid

        hum.PlatformStand = true
        for _, v in pairs(lp.Character:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        hrp.Velocity = Vector3.new(0,0,0)

        -- Logic ตำแหน่ง
        if activeMode == "Face" then
            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
        
        elseif activeMode == "Back" then
            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 1.5, 2)
        
        elseif activeMode == "Head" then
            angle = angle + 0.2
            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, angle, 0)
        
        elseif activeMode == "Orbit" then
            angle = angle + 0.05
            local offsetX = math.cos(angle) * 5
            local offsetZ = math.sin(angle) * 5
            local newPos = targetHrp.Position + Vector3.new(offsetX, 0, offsetZ)
            hrp.CFrame = CFrame.new(newPos, targetHrp.Position)
        end
    end)
end

-- === 3. BUTTON EVENTS ===
-- ปุ่ม NEAR: แค่หาชื่อคนใกล้ๆ มาใส่ช่อง (ยังไม่เกาะ)
btnNear.MouseButton1Click:Connect(function()
    local near = getClosestPlayer()
    if near then
        nameInput.Text = near.DisplayName
        notify("Found Nearest: " .. near.DisplayName)
    else
        notify("No one nearby!")
    end
end)

btnFace.MouseButton1Click:Connect(function() startStick("Face") end)
btnBack.MouseButton1Click:Connect(function() startStick("Back") end)
btnHead.MouseButton1Click:Connect(function() startStick("Head") end)
btnOrbit.MouseButton1Click:Connect(function() startStick("Orbit") end)
btnStop.MouseButton1Click:Connect(stopStick)

notify("Ready! Click 'NEAR' or Select Mode")
