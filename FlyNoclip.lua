-- [[ PROJECT: VACUUM - LITE EDITION (FLY, NOCLIP, AUTO-CLICK, ANTI-AFK) ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ฟังก์ชันหา UI ที่ปลอดภัย (Stealth)
local function GetHiddenUI()
    local target
    pcall(function() target = gethui and gethui() end)
    if target then return target end
    pcall(function() target = game:GetService("CoreGui") end)
    if target then return target end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local HiddenUI = GetHiddenUI()

-- เคลียร์ของเก่าทิ้ง
if _G.VacuumLite_Connections then
    for _, conn in pairs(_G.VacuumLite_Connections) do
        if conn then conn:Disconnect() end
    end
end
_G.VacuumLite_Connections = {}

for _, gui in pairs(HiddenUI:GetChildren()) do
    if gui.Name == "VacuumLite_UI" then gui:Destroy() end
end

-- ตั้งค่าเริ่มต้น
local State = { Flying = false, Noclip = false, AutoClick = false, CachedParts = {} }
local CONFIG = { Speed = 3, ClickX = 943, ClickY = 902 }
local THEME = {
    Background = Color3.fromRGB(15, 15, 20),
    ButtonOff = Color3.fromRGB(30, 30, 35),
    ButtonHover = Color3.fromRGB(45, 45, 55),
    ButtonOn_Start = Color3.fromRGB(120, 0, 255),
    ButtonOn_End = Color3.fromRGB(50, 0, 150),
    Text = Color3.fromRGB(240, 240, 255)
}

-- ระบบจัดการตัวละคร (Utils)
local Utils = {}
function Utils.getChar()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        return char, char.HumanoidRootPart, char.Humanoid
    end
    return nil, nil, nil
end

function Utils.updateCharCache(char)
    State.CachedParts = {}
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            table.insert(State.CachedParts, {Part = v, OrigCollide = v.CanCollide})
        end
    end
end

function Utils.noclip()
    for i = 1, #State.CachedParts do
        local data = State.CachedParts[i]
        if data.Part and data.Part.Parent then data.Part.CanCollide = false end
    end
end

function Utils.restorePhysics()
    local char, hrp, hum = Utils.getChar()
    if not char then return end
    
    hum.PlatformStand = false
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    hrp.Velocity = Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.Anchored = false
    
    local lv = hrp:FindFirstChild("Elite_Movement")
    if lv then lv:Destroy() end
    local att = hrp:FindFirstChild("ActionAtt")
    if att then att:Destroy() end
    
    for i = 1, #State.CachedParts do
        local data = State.CachedParts[i]
        if data.Part and data.Part.Parent then data.Part.CanCollide = data.OrigCollide end
    end
end

-- สร้าง UI ขนาดเล็ก (Lite UI)
local Screen = Instance.new("ScreenGui", HiddenUI)
Screen.Name = "VacuumLite_UI"
Screen.ResetOnSpawn = false

local MainBar = Instance.new("Frame", Screen)
MainBar.Size = UDim2.new(0, 380, 0, 55) -- ปรับความกว้างจาก 280 เป็น 380 เพื่อเพิ่มปุ่ม
MainBar.Position = UDim2.new(0.5, -190, 0.88, 0)
MainBar.BackgroundColor3 = THEME.Background
MainBar.BackgroundTransparency = 0.1
local corner = Instance.new("UICorner", MainBar); corner.CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", MainBar); stroke.Color = Color3.fromRGB(80, 40, 120); stroke.Thickness = 1.5

-- ทำให้ UI ลากได้
local dragging, dragInput, dragStart, startPos
MainBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainBar.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainBar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local layout = Instance.new("UIListLayout", MainBar)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)

-- ฟังก์ชันสร้างปุ่ม
local function createBtn(text, width)
    local btn = Instance.new("TextButton", MainBar)
    btn.Size = UDim2.new(0, width, 0, 38)
    btn.Text = text
    btn.BackgroundColor3 = THEME.ButtonOff
    btn.TextColor3 = THEME.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 8)
    
    local grad = Instance.new("UIGradient", btn)
    grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, THEME.ButtonOn_Start), ColorSequenceKeypoint.new(1, THEME.ButtonOn_End)}
    grad.Rotation = 45
    grad.Enabled = false

    btn.MouseEnter:Connect(function() if not grad.Enabled then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.ButtonHover}):Play() end end)
    btn.MouseLeave:Connect(function() if not grad.Enabled then TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.ButtonOff}):Play() end end)

    return btn, grad
end

local flyBtn, flyGrad = createBtn("🕊️ บิน (R)", 85)
local noclipBtn, noclipGrad = createBtn("🚪 ทะลุ (N)", 85)
local autoClickBtn, autoClickGrad = createBtn("🖱️ ออโต้คลิก (C)", 105)

local speedInput = Instance.new("TextBox", MainBar)
speedInput.Size = UDim2.new(0, 45, 0, 38)
speedInput.Text = tostring(CONFIG.Speed)
speedInput.BackgroundColor3 = THEME.ButtonOff
speedInput.TextColor3 = THEME.ButtonOn_Start
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 14
local sCorner = Instance.new("UICorner", speedInput); sCorner.CornerRadius = UDim.new(0, 8)
local sStroke = Instance.new("UIStroke", speedInput); sStroke.Color = Color3.fromRGB(80, 80, 100); sStroke.Thickness = 1

table.insert(_G.VacuumLite_Connections, speedInput:GetPropertyChangedSignal("Text"):Connect(function()
    CONFIG.Speed = tonumber(speedInput.Text) or 1
end))

local function toggleVisual(btn, grad, isOn)
    if isOn then
        grad.Enabled = true
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ButtonOn_End}):Play()
    else
        grad.Enabled = false
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ButtonOff}):Play()
    end
end

-- ระบบเปิด/ปิด ฟังก์ชันต่างๆ
local function toggleFly()
    State.Flying = not State.Flying
    toggleVisual(flyBtn, flyGrad, State.Flying)
    if not State.Flying then Utils.restorePhysics() end
end

local function toggleNoclip()
    State.Noclip = not State.Noclip
    toggleVisual(noclipBtn, noclipGrad, State.Noclip)
    if not State.Noclip then Utils.restorePhysics() end
end

local function toggleAutoClick()
    State.AutoClick = not State.AutoClick
    toggleVisual(autoClickBtn, autoClickGrad, State.AutoClick)
end

flyBtn.MouseButton1Click:Connect(toggleFly)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)
autoClickBtn.MouseButton1Click:Connect(toggleAutoClick)

-- ลูปการทำงาน (Physics)
local runConn = RunService.Stepped:Connect(function()
    local char, hrp, hum = Utils.getChar()
    if not char then return end

    if State.Flying or State.Noclip then Utils.noclip() end

    if State.Flying then
        local lv = hrp:FindFirstChild("Elite_Movement")
        if not lv then 
            local att = hrp:FindFirstChild("ActionAtt") or Instance.new("Attachment", hrp)
            att.Name = "ActionAtt"
            lv = Instance.new("LinearVelocity", hrp)
            lv.Name = "Elite_Movement"
            lv.Attachment0 = att
            lv.MaxForce = math.huge
        end
        
        local camCF = Camera.CFrame; local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        lv.VectorVelocity = moveDir.Magnitude > 0 and (moveDir.Unit * (CONFIG.Speed * 50)) or Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end
end)
table.insert(_G.VacuumLite_Connections, runConn)

-- ลูปออโต้คลิก (ทำงานแยกเพื่อไม่ให้หน่วงเกม)
task.spawn(function()
    while task.wait(0.1) do -- ความเร็วในการคลิก (0.1 วินาที = 10 ครั้ง/วิ)
        if State.AutoClick then
            VirtualInputManager:SendMouseButtonEvent(CONFIG.ClickX, CONFIG.ClickY, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(CONFIG.ClickX, CONFIG.ClickY, 0, false, game, 1)
        end
    end
end)

-- ปุ่มลัด
local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R then toggleFly()
    elseif input.KeyCode == Enum.KeyCode.N then toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.C then toggleAutoClick()
    elseif input.KeyCode == Enum.KeyCode.X then Screen.Enabled = not Screen.Enabled
    end
end)
table.insert(_G.VacuumLite_Connections, inputConn)

-- ระบบกันหลุด (Anti-AFK)
local afkConn = LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print(":: Vacuum LITE - Anti-AFK Activated ::")
end)
table.insert(_G.VacuumLite_Connections, afkConn)

-- จัดการเวลาตัวละครตาย/เกิดใหม่
local function bindChar(char)
    Utils.updateCharCache(char)
    local conn = char.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then table.insert(State.CachedParts, {Part = descendant, OrigCollide = descendant.CanCollide}) end
    end)
    table.insert(_G.VacuumLite_Connections, conn)
end
if LocalPlayer.Character then bindChar(LocalPlayer.Character) end
table.insert(_G.VacuumLite_Connections, LocalPlayer.CharacterAdded:Connect(bindChar))

-- แจ้งเตือนเมื่อโหลดเสร็จ
StarterGui:SetCore("SendNotification", {
    Title = "VACUUM LITE", 
    Text = "โหลดสำเร็จ! [R] บิน, [N] ทะลุ, [C] ออโต้คลิก", 
    Duration = 5
})
