-- [[ ส่วนตรวจสอบรหัสแมพ ]] --
local Supported_IDs = {
    [8391915840] = true, -- Map เก่า
    [8125861255] = true,  -- Map ใหม่
    [99002761413888] = true, -- Map Unnamed
}

-- [[ 1. SYSTEM CLEANUP (ล้างระบบเก่าแบบเกลี้ยงเกลา) ]] --
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if _G.ProScript_Connections then
    for _, conn in pairs(_G.ProScript_Connections) do
        if conn then conn:Disconnect() end
    end
end
_G.ProScript_Connections = {}

for _, gui in pairs(player.PlayerGui:GetChildren()) do
    if gui.Name:match("ControlGui_Pro") then gui:Destroy() end
end

---------------------------------------------------------------------------------
-- 2. SERVICES & CONSTANTS
---------------------------------------------------------------------------------
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Camera = workspace.CurrentCamera
local Mouse = player:GetMouse()

-- [[ MAP CONFIGURATION ]] --
local MapSettings = {
    [8391915840] = {
        InvisPos = Vector3.new(-25.95, 84, 3537.55),
        Locations = {
            Job  = CFrame.new(1146.80627, -245.849579, -561.207458),
            Fill = CFrame.new(1147.00024, -245.849609, -568.630432),
            Sell = CFrame.new(1143.9364,  -245.849579, -580.007935)
        }
    },
    [8125861255] = {
        InvisPos = Vector3.new(0, 500, 0),
        Locations = { Job=CFrame.new(0,5,0), Fill=CFrame.new(0,5,0), Sell=CFrame.new(0,5,0) }
    },
    [99002761413888] = {
        InvisPos = Vector3.new(0, 500, 0),
        Locations = { Job=CFrame.new(0,5,0), Fill=CFrame.new(0,5,0), Sell=CFrame.new(0,5,0) }
    }
}
local CurrentMapData = MapSettings[game.PlaceId] or MapSettings[8391915840]

-- [[ CONFIGURATION ]] --
local CONFIG = {
    Speed = 3, -- ปรับความเร็วการวาร์ปตรงนี้ (ยิ่งเยอะยิ่งไว)
    CurrentLang = "EN",
    MenuVisible = false,
    InvisPos = CurrentMapData.InvisPos,
    Locations = CurrentMapData.Locations,
    -- พิกัดส้มตำ (จากรูปภาพ)
    SomtumLocs = {
        Step1_Papaya = CFrame.new(-507.922882, -93.6820526, 348.588898),
        Step2_Plate  = CFrame.new(-501.166077, -93.6820526, 360.164429),
        Step3_Slided = CFrame.new(-504.504791, -93.6820526, 364.180908),
        Step4_Somtum = CFrame.new(-513.166077, -93.6822281, 352.119293),
        Step5_Sell   = CFrame.new(-517.698914, -93.682045, 357.998199)
    },
    ItemNames = {
        -- ของไอติม
        Stage1 = {"Cone", "Empty Cone", "Waffle Cone"},
        Stage2 = {"Icecream", "Ice Cream", "Chocolate Icecream", "Vanilla Icecream"},
        -- ของส้มตำ
        Somtum = {"Papaya", "Plate", "Slided Papaya", "Somtum"}
    }
}

local THEME = {
    Background = Color3.fromRGB(5, 5, 10),
    ButtonOff = Color3.fromRGB(20, 20, 25),
    ButtonOn_Start = Color3.fromRGB(120, 0, 255),
    ButtonOn_End = Color3.fromRGB(50, 0, 150),
    ESP_Color = Color3.fromRGB(180, 100, 255),
    Text = Color3.fromRGB(240, 240, 255),
    TextDim = Color3.fromRGB(100, 100, 120),
    Stroke = Color3.fromRGB(60, 30, 90)
}

local TRANSLATIONS = {
    FLY = {EN = "FLY (R)", TH = "บิน (R)"},
    ESP = {EN = "ESP (F)", TH = "มองทะลุ (F)"},
    SINK_BTN = {EN = "SINK (J)", TH = "จมดิน (J)"},
    RISE_BTN = {EN = "RISE (K)", TH = "ลอยฟ้า (K)"},
    INVIS = {EN = "INVIS (Z)", TH = "ล่องหน (Z)"},
    TP = {EN = "CLICK TP (T)", TH = "วาร์ป (T)"},
    FARM = {EN = "AUTO FARM", TH = "ออโต้ฟาร์ม"},
    REJOIN = {EN = "REJOIN", TH = "เข้าเกมใหม่"},
    RESET = {EN = "RESET CAM (C)", TH = "รีเซ็ตกล้อง (C)"}, 
    LIST = {EN = "Player LIST", TH = "รายชื่อผู้เล่น"},
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
    REJOINING = {EN = "Rejoining Server...", TH = "กำลังเข้าเซิร์ฟเวอร์ใหม่..."},
    FARM_FMT = {EN = "Status: %s | Loop: %d", TH = "สถานะ: %s | รอบที่: %d"}
}

---------------------------------------------------------------------------------
-- 3. STATE MANAGEMENT
---------------------------------------------------------------------------------
local State = {
    Flying = false,
    ESP = false,
    ClickTP = false,
    AutoFarm = false,
    Invisible = false,
    VerticalMode = "None",
    FarmInfo = { Count = 0, StartTime = 0, CurrentState = "Idle", Tween = nil },
    Connections = {},
    OldSpeed = nil -- [[ เพิ่มตัวแปรเก็บค่าความเร็วเดิม ]]
}

---------------------------------------------------------------------------------
-- 4. UTILITY FUNCTIONS
---------------------------------------------------------------------------------
local Utils = {}

function Utils.getChar()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        return char, char.HumanoidRootPart, char.Humanoid
    end
    return nil, nil, nil
end

function Utils.addCorner(instance, radius)
    local corner = Instance.new("UICorner", instance)
    corner.CornerRadius = UDim.new(0, radius)
    return corner
end

function Utils.addStroke(instance, transparency)
    local stroke = Instance.new("UIStroke", instance)
    stroke.Color = THEME.Stroke
    stroke.Thickness = 1
    stroke.Transparency = transparency or 0.5
    return stroke
end

function Utils.addGradient(instance)
    local grad = Instance.new("UIGradient", instance)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, THEME.ButtonOn_Start),
        ColorSequenceKeypoint.new(1, THEME.ButtonOn_End)
    }
    grad.Rotation = 45
    grad.Enabled = false
    return grad
end

function Utils.makeDraggable(frame)
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

function Utils.noclip(char)
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") and v.CanCollide == true then
            v.CanCollide = false
        end
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
    
    if hrp:FindFirstChild("Elite_Movement") then hrp.Elite_Movement:Destroy() end
    if hrp:FindFirstChild("SinkLift") then hrp.SinkLift:Destroy() end
    if hrp:FindFirstChild("SinkGyro") then hrp.SinkGyro:Destroy() end
    if hrp:FindFirstChild("FarmGyro") then hrp.FarmGyro:Destroy() end
    
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("BasePart") then v.CanCollide = true end
    end
end

function Utils.formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function Utils.hasItem(possibleNames)
    local char = player.Character
    local backpack = player.Backpack
    if not char or not backpack then return false end
    
    for _, name in pairs(possibleNames) do
        if backpack:FindFirstChild(name) or char:FindFirstChild(name) then return true end
    end
    return false
end

---------------------------------------------------------------------------------
-- 5. UI CONSTRUCTION
---------------------------------------------------------------------------------
local GUI = {}
GUI.Screen = Instance.new("ScreenGui", player.PlayerGui)
GUI.Screen.Name = "ControlGui_Pro_V63_Full" 
GUI.Screen.ResetOnSpawn = false
GUI.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

function GUI.createBtn(parent, textKey, sizeScale)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(sizeScale, -8, 0, 45)
    container.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = TRANSLATIONS[textKey][CONFIG.CurrentLang]
    btn.BackgroundColor3 = THEME.ButtonOff
    btn.TextColor3 = THEME.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    Utils.addCorner(btn, 10)
    
    local grad = Utils.addGradient(btn)
    return {Button = btn, Gradient = grad, Key = textKey}
end

GUI.Hint = Instance.new("TextLabel", GUI.Screen)
GUI.Hint.Size = UDim2.new(0, 200, 0, 30)
GUI.Hint.Position = UDim2.new(0.5, -100, 0, 5)
GUI.Hint.BackgroundTransparency = 1
GUI.Hint.TextColor3 = THEME.TextDim
GUI.Hint.Font = Enum.Font.GothamBold
GUI.Hint.TextSize = 18
GUI.Hint.TextTransparency = 0.5
GUI.Hint.Text = TRANSLATIONS.HINT.EN

GUI.MenuContainer = Instance.new("Frame", GUI.Screen)
GUI.MenuContainer.Size = UDim2.new(1, 0, 1, 0)
GUI.MenuContainer.BackgroundTransparency = 1
GUI.MenuContainer.Visible = false

GUI.StatusFrame = Instance.new("Frame", GUI.Screen)
GUI.StatusFrame.AutomaticSize = Enum.AutomaticSize.X
GUI.StatusFrame.Size = UDim2.new(0, 0, 0, 40)
GUI.StatusFrame.AnchorPoint = Vector2.new(1, 1)
GUI.StatusFrame.Position = UDim2.new(1, -20, 1, -50)
GUI.StatusFrame.BackgroundColor3 = THEME.Background
GUI.StatusFrame.BackgroundTransparency = 0.1
Utils.addCorner(GUI.StatusFrame, 10)
Utils.addStroke(GUI.StatusFrame, 0.3)
local statusPad = Instance.new("UIPadding", GUI.StatusFrame)
statusPad.PaddingLeft = UDim.new(0, 15)
statusPad.PaddingRight = UDim.new(0, 15)

GUI.StatusLabel = Instance.new("TextLabel", GUI.StatusFrame)
GUI.StatusLabel.AutomaticSize = Enum.AutomaticSize.X
GUI.StatusLabel.Size = UDim2.new(0, 0, 1, 0)
GUI.StatusLabel.BackgroundTransparency = 1
GUI.StatusLabel.TextColor3 = THEME.Text
GUI.StatusLabel.Font = Enum.Font.GothamMedium
GUI.StatusLabel.TextSize = 16
GUI.StatusLabel.Text = TRANSLATIONS.STATUS_WAIT.EN

GUI.MainBar = Instance.new("Frame", GUI.MenuContainer)
GUI.MainBar.Size = UDim2.new(0, 1150, 0, 65) 
GUI.MainBar.Position = UDim2.new(0.5, -575, 0.85, 0)
GUI.MainBar.BackgroundColor3 = THEME.Background
GUI.MainBar.BackgroundTransparency = 0.1
Utils.addCorner(GUI.MainBar, 16)
Utils.addStroke(GUI.MainBar, 0.3)
Utils.makeDraggable(GUI.MainBar)
local barLayout = Instance.new("UIListLayout", GUI.MainBar)
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
barLayout.Padding = UDim.new(0, 4)

GUI.Buttons = {}
GUI.Buttons.Fly = GUI.createBtn(GUI.MainBar, "FLY", 0.09)
GUI.Buttons.ESP = GUI.createBtn(GUI.MainBar, "ESP", 0.09)
GUI.Buttons.Sink = GUI.createBtn(GUI.MainBar, "SINK_BTN", 0.09)
GUI.Buttons.Rise = GUI.createBtn(GUI.MainBar, "RISE_BTN", 0.09)
GUI.Buttons.Invis = GUI.createBtn(GUI.MainBar, "INVIS", 0.10)
GUI.Buttons.TP = GUI.createBtn(GUI.MainBar, "TP", 0.10)
GUI.Buttons.Farm = GUI.createBtn(GUI.MainBar, "FARM", 0.10)
GUI.Buttons.Rejoin = GUI.createBtn(GUI.MainBar, "REJOIN", 0.09)

local speedContainer = Instance.new("Frame", GUI.MainBar)
speedContainer.Size = UDim2.new(0.07, -5, 0, 45)
speedContainer.BackgroundTransparency = 1
Utils.addCorner(speedContainer, 10)
local speedInput = Instance.new("TextBox", speedContainer)
speedInput.Size = UDim2.new(1, 0, 1, 0)
speedInput.Text = tostring(CONFIG.Speed)
speedInput.BackgroundColor3 = THEME.ButtonOff
speedInput.TextColor3 = THEME.ButtonOn_Start
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 16
speedInput.PlaceholderText = "SPD"
Utils.addCorner(speedInput, 10)
Utils.addStroke(speedInput, 0.6)
GUI.Buttons.Lang = GUI.createBtn(GUI.MainBar, "LANG_BTN", 0.08)

GUI.SideFrame = Instance.new("Frame", GUI.MenuContainer)
GUI.SideFrame.Size = UDim2.new(0, 260, 0, 350)
GUI.SideFrame.Position = UDim2.new(1, -280, 0.2, 0)
GUI.SideFrame.BackgroundColor3 = THEME.Background
GUI.SideFrame.BackgroundTransparency = 0.1
Utils.addCorner(GUI.SideFrame, 12)
Utils.addStroke(GUI.SideFrame, 0.4)
Utils.makeDraggable(GUI.SideFrame)

local sideTitle = Instance.new("TextLabel", GUI.SideFrame)
sideTitle.Size = UDim2.new(1, 0, 0, 40)
sideTitle.BackgroundTransparency = 1
sideTitle.Text = TRANSLATIONS.LIST.EN
sideTitle.TextColor3 = THEME.TextDim
sideTitle.Font = Enum.Font.GothamBold
sideTitle.TextSize = 14

local scrollFrame = Instance.new("ScrollingFrame", GUI.SideFrame)
scrollFrame.Size = UDim2.new(1, -10, 1, -95)
scrollFrame.Position = UDim2.new(0, 5, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 2
scrollFrame.ScrollBarImageColor3 = THEME.ButtonOn_Start
local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 6)

local resetContainer = Instance.new("Frame", GUI.SideFrame)
resetContainer.Size = UDim2.new(1, -20, 0, 40)
resetContainer.Position = UDim2.new(0, 10, 1, -50)
resetContainer.BackgroundTransparency = 1

local resetBtn = Instance.new("TextButton", resetContainer)
resetBtn.Size = UDim2.new(1, 0, 1, 0)
resetBtn.Text = TRANSLATIONS.RESET[CONFIG.CurrentLang]
resetBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
resetBtn.TextColor3 = Color3.new(1, 1, 1)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 14
resetBtn.AutoButtonColor = false
Utils.addCorner(resetBtn, 8)
Utils.addStroke(resetBtn, 0.5)

GUI.Buttons.Reset = {Button = resetBtn, Key = "RESET", Gradient = Utils.addGradient(resetBtn)}

function GUI.setStatus(text)
    GUI.StatusLabel.Text = text
end

function GUI.toggleVisual(btnStruct, isOn)
    if isOn then
        btnStruct.Gradient.Enabled = true
        btnStruct.Button.TextColor3 = Color3.new(1, 1, 1)
        TweenService:Create(btnStruct.Button, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ButtonOn_End}):Play()
    else
        btnStruct.Gradient.Enabled = false
        btnStruct.Button.TextColor3 = THEME.Text
        TweenService:Create(btnStruct.Button, TweenInfo.new(0.2), {BackgroundColor3 = THEME.ButtonOff}):Play()
    end
end

function GUI.updateTexts()
    local lang = CONFIG.CurrentLang
    local dynamicTextSize = (lang == "TH") and 15 or 11
    
    for _, item in pairs(GUI.Buttons) do
        item.Button.Text = TRANSLATIONS[item.Key][lang]
        item.Button.TextSize = dynamicTextSize
    end
    GUI.Hint.Text = TRANSLATIONS.HINT[lang]
    sideTitle.Text = TRANSLATIONS.LIST[lang]
end

function GUI.moveStatus(toCenter)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local targetPos = toCenter and UDim2.new(0.5, 0, 0.35, 0) or UDim2.new(1, -20, 1, -50)
    local targetAnchor = toCenter and Vector2.new(0.5, 0.5) or Vector2.new(1, 1)
    GUI.StatusFrame.AnchorPoint = targetAnchor
    TweenService:Create(GUI.StatusFrame, tweenInfo, {Position = targetPos}):Play()
end

---------------------------------------------------------------------------------
-- 6. CORE LOGIC & FEATURES
---------------------------------------------------------------------------------
local Features = {}

-- [[ INSTANT E ]] --
function Features.setupInstantPrompts()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            obj.HoldDuration = 0
        end
    end
    
    local conn = workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ProximityPrompt") then
            descendant.HoldDuration = 0
        end
    end)
    table.insert(_G.ProScript_Connections, conn)
end
Features.setupInstantPrompts()

-- [[ REJOIN SERVER ]] --
function Features.rejoinServer()
    GUI.setStatus(TRANSLATIONS.REJOINING[CONFIG.CurrentLang])
    if #Players:GetPlayers() <= 1 then
        Players.LocalPlayer:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
    end
end

-- [[ INVISIBILITY ]] --
function Features.toggleInvis()
    local char, hrp, _ = Utils.getChar()
    if not char then return end

    State.Invisible = not State.Invisible
    GUI.toggleVisual(GUI.Buttons.Invis, State.Invisible)

    if State.Invisible then
        local savedCF = hrp.CFrame
        char:MoveTo(CONFIG.InvisPos)
        task.wait(0.15)

        local seat = Instance.new("Seat")
        seat.Name = "Invis_Seat_Fixed"
        seat.Anchored = false
        seat.CanCollide = false
        seat.Transparency = 1
        seat.Position = CONFIG.InvisPos
        seat.Parent = workspace
        
        for _, child in pairs(seat:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then child:Destroy() end
        end

        local weld = Instance.new("Weld")
        weld.Part0 = seat
        weld.Part1 = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        weld.Parent = seat
        
        task.wait()
        seat.CFrame = savedCF
        
        for _, v in pairs(char:GetDescendants()) do
            if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0.5
            end
        end
        GUI.setStatus(TRANSLATIONS.INVIS_STATUS[CONFIG.CurrentLang])
    else
        for _, v in pairs(workspace:GetChildren()) do
            if v.Name == "Invis_Seat_Fixed" then v:Destroy() end
        end
        for _, v in pairs(char:GetDescendants()) do
            if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0
            end
        end
        Utils.restorePhysics()
        GUI.setStatus(TRANSLATIONS.STATUS_READY[CONFIG.CurrentLang])
    end
end

-- [[ SINK & RISE ]] --
function Features.setVertical(mode)
    if State.VerticalMode == mode then Features.stopVertical(); return end
    Features.stopVertical()
    State.VerticalMode = mode
    
    local char, hrp, hum = Utils.getChar()
    if not char then return end

    if mode == "Sink" then
        GUI.toggleVisual(GUI.Buttons.Sink, true)
        GUI.setStatus(TRANSLATIONS.SINK_STATUS[CONFIG.CurrentLang])
    else
        GUI.toggleVisual(GUI.Buttons.Rise, true)
        GUI.setStatus(TRANSLATIONS.RISE_STATUS[CONFIG.CurrentLang])
    end

    hum.PlatformStand = true
    Utils.noclip(char)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "SinkLift"
    bv.Velocity = Vector3.new(0, (mode == "Sink" and -6 or 6), 0)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "SinkGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
end

function Features.stopVertical()
    State.VerticalMode = "None"
    GUI.toggleVisual(GUI.Buttons.Sink, false)
    GUI.toggleVisual(GUI.Buttons.Rise, false)
    Utils.restorePhysics()
    GUI.setStatus(TRANSLATIONS.STATUS_READY[CONFIG.CurrentLang])
end

-- [[ AUTO FARM LOGIC ]] --
function Features.smartMove(targetCFrame)
    local char, hrp, hum = Utils.getChar()
    if not char then return end

    if not hrp:FindFirstChild("FarmGyro") then
        local bg = Instance.new("BodyGyro")
        bg.Name = "FarmGyro"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
    end

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    
    -- คำนวณความเร็ว (Speed Scaling)
    -- ยิ่ง CONFIG.Speed เยอะ -> speedFactor ยิ่งเยอะ -> tweenTime ยิ่งน้อย -> ยิ่งเร็ว
    local speedFactor = math.max(1, CONFIG.Speed * 150) 
    local tweenTime = dist / speedFactor
    
    -- ป้องกัน Tween Error ถ้าระยะใกล้เกินไป
    if tweenTime < 0.1 then tweenTime = 0.1 end
    
    local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    State.FarmInfo.Tween = tween
    tween:Play()
    tween.Completed:Wait()
    State.FarmInfo.Tween = nil
    
    hrp.Velocity = Vector3.zero
    if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
end

function Features.interactUntil(conditionFunc, maxTime)
    local elapsed = 0
    while elapsed < maxTime and State.AutoFarm do
        if conditionFunc() then return true end
        
        local char, hrp, _ = Utils.getChar()
        if char then
             local overlap = OverlapParams.new()
             overlap.FilterDescendantsInstances = {char}
             overlap.FilterType = Enum.RaycastFilterType.Exclude
             local parts = workspace:GetPartBoundsInRadius(hrp.Position, 25, overlap)
             for _, part in ipairs(parts) do
                 local prompt = part:FindFirstChildWhichIsA("ProximityPrompt") or (part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt"))
                 if prompt and prompt.Enabled then
                     prompt:InputHoldBegin()
                     task.spawn(function()
                         VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                         task.wait(0.05)
                         VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                         prompt:InputHoldEnd()
                     end)
                 end
             end
        end
        task.wait(0.2)
        elapsed = elapsed + 0.2
    end
    return false
end

function Features.toggleFarm()
    State.AutoFarm = not State.AutoFarm
    GUI.toggleVisual(GUI.Buttons.Farm, State.AutoFarm)
    
    if State.AutoFarm then
        -- [[ START: SPEED MODIFICATION ]] --
        State.OldSpeed = CONFIG.Speed -- จำค่าเดิม
        CONFIG.Speed = 4 -- ตั้งค่าเป็น 5
        if speedInput then speedInput.Text = tostring(CONFIG.Speed) end -- อัปเดต UI
        -- [[ END: SPEED MODIFICATION ]] --

        GUI.moveStatus(true)
        State.FarmInfo.StartTime = os.time()
        State.FarmInfo.Count = 0
        State.FarmInfo.CurrentState = "Starting..."
        
        -- Status Loop
        task.spawn(function()
            while State.AutoFarm do
                local elapsed = os.time() - State.FarmInfo.StartTime
                local info = string.format("Action: %s | Loop: %d | Time: %s", State.FarmInfo.CurrentState, State.FarmInfo.Count, Utils.formatTime(elapsed))
                GUI.setStatus(info)
                task.wait(1)
            end
        end)
        
        -- Main Logic Loop
        task.spawn(function()
            pcall(function()
                local char, hrp, _ = Utils.getChar()
                if char and hrp then
                    hrp.CFrame = CONFIG.Locations.Job
                    task.wait(0.5)
                end
            end)

            while State.AutoFarm do
                pcall(function()
                    if not Utils.getChar() then task.wait(1) return end
                    
                    ------------------------------------------------------------
                    -- PHASE 1: MAIN JOB (ICE CREAM)
                    ------------------------------------------------------------
                    
                    -- 1.1 รับโคน
                    State.FarmInfo.CurrentState = "IceCream: Get Cone"
                    Features.smartMove(CONFIG.Locations.Job)
                    task.wait(0.15)
                    Features.interactUntil(function() return Utils.hasItem(CONFIG.ItemNames.Stage1) end, 5)

                    if not State.AutoFarm then return end

                    -- 1.2 ตักไอติม
                    State.FarmInfo.CurrentState = "IceCream: Filling"
                    Features.smartMove(CONFIG.Locations.Fill)
                    task.wait(0.15)
                    Features.interactUntil(function() return Utils.hasItem(CONFIG.ItemNames.Stage2) end, 5)

                    if not State.AutoFarm then return end

                    -- 1.3 ขายไอติม
                    State.FarmInfo.CurrentState = "IceCream: Selling"
                    Features.smartMove(CONFIG.Locations.Sell)
                    task.wait(0.15)
                    -- รอจนกว่าไอติมจะหายไป (ขายเสร็จ)
                    Features.interactUntil(function() return not Utils.hasItem(CONFIG.ItemNames.Stage2) end, 10)

                    if not State.AutoFarm then return end

                    ------------------------------------------------------------
                    -- PHASE 2: SIDE JOB (SOMTUM COOLDOWN)
                    -- ทำเมื่อขายไอติมเสร็จแล้ว เพื่อรอเวลา
                    ------------------------------------------------------------
                    
                    -- 2.1 Papaya
                    State.FarmInfo.CurrentState = "Somtum: Papaya"
                    Features.smartMove(CONFIG.SomtumLocs.Step1_Papaya)
                    task.wait(0.1)
                    Features.interactUntil(function() return Utils.hasItem({"Papaya"}) end, 8)
                    
                    -- 2.2 Plate
                    State.FarmInfo.CurrentState = "Somtum: Plate"
                    Features.smartMove(CONFIG.SomtumLocs.Step2_Plate)
                    task.wait(0.1)
                    Features.interactUntil(function() return Utils.hasItem({"Plate"}) end, 8)

                    -- 2.3 Slice
                    State.FarmInfo.CurrentState = "Somtum: Slicing"
                    Features.smartMove(CONFIG.SomtumLocs.Step3_Slided)
                    task.wait(0.1)
                    Features.interactUntil(function() return Utils.hasItem({"Slided Papaya"}) end, 8)

                    -- 2.4 Cook
                    State.FarmInfo.CurrentState = "Somtum: Cooking"
                    Features.smartMove(CONFIG.SomtumLocs.Step4_Somtum)
                    task.wait(0.1)
                    Features.interactUntil(function() return Utils.hasItem({"Somtum"}) end, 8)

                    -- 2.5 Sell Somtum
                    State.FarmInfo.CurrentState = "Somtum: Selling"
                    Features.smartMove(CONFIG.SomtumLocs.Step5_Sell)
                    task.wait(0.15)
                    -- รอจนกว่าส้มตำจะหายไป (ขายเสร็จ)
                    Features.interactUntil(function() return not Utils.hasItem(CONFIG.ItemNames.Somtum) end, 10)
                    
                    State.FarmInfo.Count = State.FarmInfo.Count + 1
                    task.wait(0.5)
                end)
            end
            
            if State.FarmInfo.Tween then State.FarmInfo.Tween:Cancel() end
            Utils.restorePhysics()
            GUI.setStatus(TRANSLATIONS.ABORT[CONFIG.CurrentLang])
            GUI.moveStatus(false)
        end)
    else
        -- [[ STOP: RESTORE SPEED ]] --
        if State.OldSpeed then
            CONFIG.Speed = State.OldSpeed -- คืนค่าเดิม
            if speedInput then speedInput.Text = tostring(CONFIG.Speed) end -- อัปเดต UI กลับ
        end
        -- [[ END: RESTORE SPEED ]] --

        if State.FarmInfo.Tween then State.FarmInfo.Tween:Cancel() end
        Utils.restorePhysics()
        GUI.setStatus(TRANSLATIONS.ABORT[CONFIG.CurrentLang])
        GUI.moveStatus(false)
    end
end

-- [[ ESP ]] --
function Features.updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local char = p.Character
            if State.ESP then
                if not char:FindFirstChild("Elite_Highlight") then
                    local hi = Instance.new("Highlight", char)
                    hi.Name = "Elite_Highlight"
                    hi.FillTransparency = 0.5
                    hi.FillColor = THEME.ESP_Color
                    hi.OutlineColor = THEME.ESP_Color
                    
                    local bg = Instance.new("BillboardGui", char)
                    bg.Name = "Elite_Tag"
                    bg.Adornee = char.HumanoidRootPart
                    bg.Size = UDim2.new(0, 100, 0, 40)
                    bg.StudsOffset = Vector3.new(0, 3.5, 0)
                    bg.AlwaysOnTop = true
                    
                    local tl = Instance.new("TextLabel", bg)
                    tl.BackgroundTransparency = 1
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.Text = p.DisplayName
                    tl.TextColor3 = THEME.ESP_Color
                    tl.Font = Enum.Font.GothamBold
                    tl.TextSize = 14
                    tl.TextStrokeTransparency = 0.5
                end
            else
                if char:FindFirstChild("Elite_Highlight") then char.Elite_Highlight:Destroy() end
                if char:FindFirstChild("Elite_Tag") then char.Elite_Tag:Destroy() end
            end
        end
    end
end

function Features.toggleESP()
    State.ESP = not State.ESP
    GUI.toggleVisual(GUI.Buttons.ESP, State.ESP)
    Features.updateESP()
    GUI.setStatus(State.ESP and TRANSLATIONS.VISUAL_ON[CONFIG.CurrentLang] or TRANSLATIONS.VISUAL_OFF[CONFIG.CurrentLang])
end

-- [[ FLY ]] --
function Features.toggleFly()
    State.Flying = not State.Flying
    GUI.toggleVisual(GUI.Buttons.Fly, State.Flying)
    if State.Flying then
        GUI.setStatus(TRANSLATIONS.FLY_ON[CONFIG.CurrentLang])
    else
        Utils.restorePhysics()
        GUI.setStatus(TRANSLATIONS.STATUS_READY[CONFIG.CurrentLang])
    end
end

-- [[ CLICK TP ]] --
function Features.teleportClick()
    if State.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local char, hrp, _ = Utils.getChar()
        if Mouse.Target and char then
            local targetPos = Mouse.Hit.p + Vector3.new(0, 3.5, 0)
            hrp.CFrame = CFrame.new(targetPos)
            GUI.setStatus(TRANSLATIONS.WARPED[CONFIG.CurrentLang])
        end
    end
end

---------------------------------------------------------------------------------
-- 7. LOOPS & CONNECTS
---------------------------------------------------------------------------------

local runConn = RunService.Stepped:Connect(function()
    local char, hrp, hum = Utils.getChar()
    if not char then return end

    if State.Flying or State.Invisible or State.VerticalMode ~= "None" or State.AutoFarm then
        Utils.noclip(char)
    end

    if State.Flying then
        local bv = hrp:FindFirstChild("Elite_Movement")
        if not bv then 
            bv = Instance.new("BodyVelocity") 
            bv.Name = "Elite_Movement" 
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9) 
            bv.Parent = hrp 
        end
        local camCF = Camera.CFrame
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        bv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * (CONFIG.Speed * 50)) or Vector3.zero
        hrp.AssemblyLinearVelocity = Vector3.zero
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end
end)
table.insert(_G.ProScript_Connections, runConn)

local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local code = input.KeyCode
    if code == Enum.KeyCode.R then Features.toggleFly()
    elseif code == Enum.KeyCode.F then Features.toggleESP()
    elseif code == Enum.KeyCode.T then 
        State.ClickTP = not State.ClickTP 
        GUI.toggleVisual(GUI.Buttons.TP, State.ClickTP)
        GUI.setStatus(State.ClickTP and TRANSLATIONS.WARP_READY[CONFIG.CurrentLang] or TRANSLATIONS.WARP_OFF[CONFIG.CurrentLang])
    elseif code == Enum.KeyCode.J then Features.setVertical("Sink")
    elseif code == Enum.KeyCode.K then Features.setVertical("Rise")
    elseif code == Enum.KeyCode.Z then Features.toggleInvis()
    elseif code == Enum.KeyCode.X then
        CONFIG.MenuVisible = not CONFIG.MenuVisible
        GUI.MenuContainer.Visible = CONFIG.MenuVisible
    elseif code == Enum.KeyCode.C then
        local _, _, hum = Utils.getChar()
        if hum then Camera.CameraSubject = hum; GUI.setStatus(TRANSLATIONS.CAM_RESET[CONFIG.CurrentLang]) end
    end
end)
table.insert(_G.ProScript_Connections, inputConn)

GUI.Buttons.Fly.Button.MouseButton1Click:Connect(Features.toggleFly)
GUI.Buttons.ESP.Button.MouseButton1Click:Connect(Features.toggleESP)
GUI.Buttons.Sink.Button.MouseButton1Click:Connect(function() Features.setVertical("Sink") end)
GUI.Buttons.Rise.Button.MouseButton1Click:Connect(function() Features.setVertical("Rise") end)
GUI.Buttons.Invis.Button.MouseButton1Click:Connect(Features.toggleInvis)
GUI.Buttons.TP.Button.MouseButton1Click:Connect(function() 
    State.ClickTP = not State.ClickTP 
    GUI.toggleVisual(GUI.Buttons.TP, State.ClickTP)
    GUI.setStatus(State.ClickTP and TRANSLATIONS.WARP_READY[CONFIG.CurrentLang] or TRANSLATIONS.WARP_OFF[CONFIG.CurrentLang])
end)
GUI.Buttons.Farm.Button.MouseButton1Click:Connect(Features.toggleFarm)
GUI.Buttons.Rejoin.Button.MouseButton1Click:Connect(Features.rejoinServer)

GUI.Buttons.Reset.Button.MouseButton1Click:Connect(function()
    local _, _, hum = Utils.getChar()
    if hum then Camera.CameraSubject = hum; GUI.setStatus(TRANSLATIONS.CAM_RESET[CONFIG.CurrentLang]) end
end)

GUI.Buttons.Lang.Button.MouseButton1Click:Connect(function()
    CONFIG.CurrentLang = (CONFIG.CurrentLang == "EN") and "TH" or "EN"
    GUI.updateTexts()
end)

table.insert(_G.ProScript_Connections, Mouse.Button1Down:Connect(Features.teleportClick))
table.insert(_G.ProScript_Connections, speedInput:GetPropertyChangedSignal("Text"):Connect(function()
    CONFIG.Speed = tonumber(speedInput.Text) or 1
end))
table.insert(_G.ProScript_Connections, player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    GUI.setStatus(TRANSLATIONS.AFK[CONFIG.CurrentLang])
end))

local function updateList()
    for _, item in pairs(scrollFrame:GetChildren()) do if item:IsA("Frame") then item:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local pRow = Instance.new("Frame", scrollFrame)
            pRow.Size = UDim2.new(1, 0, 0, 40)
            pRow.BackgroundTransparency = 0.5
            pRow.BackgroundColor3 = THEME.ButtonOff
            Utils.addCorner(pRow, 8)
            local tBtn = Instance.new("TextButton", pRow)
            tBtn.Size = UDim2.new(0.7, -5, 1, 0)
            tBtn.Position = UDim2.new(0, 5, 0, 0)
            tBtn.Text = p.DisplayName
            tBtn.TextXAlignment = Enum.TextXAlignment.Left
            tBtn.BackgroundTransparency = 1
            tBtn.TextColor3 = THEME.Text
            tBtn.Font = Enum.Font.GothamMedium
            tBtn.TextSize = 15
            tBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and player.Character then
                    player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                end
            end)
            local sBtn = Instance.new("TextButton", pRow)
            sBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
            sBtn.Position = UDim2.new(0.73, 0, 0.1, 0)
            sBtn.Text = "VIEW"
            sBtn.BackgroundColor3 = THEME.ButtonOn_Start
            sBtn.TextColor3 = Color3.new(1,1,1)
            sBtn.Font = Enum.Font.GothamBold
            sBtn.TextSize = 10
            Utils.addCorner(sBtn, 6)
            sBtn.MouseButton1Click:Connect(function()
                if p.Character and p.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = p.Character.Humanoid end
            end)
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

local function bindPlayerEvents(p)
    if p == player then return end 
    local conn = p.CharacterAdded:Connect(function(char)
        task.wait(1) 
        if State.ESP then Features.updateESP() end
    end)
    table.insert(_G.ProScript_Connections, conn)
end

for _, p in pairs(Players:GetPlayers()) do bindPlayerEvents(p) end
table.insert(_G.ProScript_Connections, Players.PlayerAdded:Connect(function(p)
    bindPlayerEvents(p)
    Features.updateESP()
    updateList()
end))
table.insert(_G.ProScript_Connections, Players.PlayerRemoving:Connect(updateList))
updateList()

local function playIntro()
    -- [[ CHECK ID: 473092660 ]] --
    if player.UserId == 473092660 then
        return -- ข้าม Intro ทันที
    end

    local introFrame = Instance.new("Frame", GUI.Screen)
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundColor3 = Color3.new(0, 0, 0)
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
task.wait(0.5)
CONFIG.MenuVisible = true
GUI.MenuContainer.Visible = true
