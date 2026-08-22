-- [[ PROJECT: VIOLENCE DISTRICT - INSTANT V8.9 (GOD MODE PARRY + ITEM TRACKER + CLEAN VISION) ]] --
if _G.ViolenceDistrict_Loaded then
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "System", Text = "Script is already loaded!", Duration = 3 }) end)
    return
end
_G.ViolenceDistrict_Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local SETTINGS = {
    Key_ESP = Enum.KeyCode.E,
    Key_Noclip = Enum.KeyCode.R,
    Key_AutoSkill = Enum.KeyCode.G, 
    Key_AutoParry = Enum.KeyCode.V, 
    Key_Aimbot = Enum.KeyCode.X,
    Key_Fullbright = Enum.KeyCode.K, 
    Key_NoFog = Enum.KeyCode.P, 
    Key_CleanVision = Enum.KeyCode.C,
    Key_SpeedHack = Enum.KeyCode.B,
    Key_Rejoin = Enum.KeyCode.L,
    Key_Help = Enum.KeyCode.Z, 
    
    ESP_Enabled = false,              
    Noclip_Enabled = false,
    AutoSkill_Enabled = true,
    AutoParry_Enabled = false,
    Aimbot_Enabled = false,        
    Fullbright_Enabled = false, 
    NoFog_Enabled = false,
    CleanVision_Enabled = false,
    SpeedHack_Enabled = false,
    
    Parry_Key = "RightClick", 
    Parry_MaxRange = 12, 
    Parry_PanicRange = 6.5,   
    Parry_Cooldown = 0.05, 
    
    Aimbot_HoldKey = Enum.UserInputType.MouseButton2,
    Aimbot_FOV = 150,                
    Aimbot_Smoothness = 0.2,        
    Aimbot_Prediction = 0.13,        
    
    SurvivorColor = LocalPlayer:GetAttribute("survaura") or Color3.fromRGB(0, 255, 100),    
    KillerColor = LocalPlayer:GetAttribute("killeraura") or Color3.fromRGB(255, 0, 0),        
    SuspectColor = Color3.fromRGB(255, 170, 0),        
    GenColor = LocalPlayer:GetAttribute("genaura") or Color3.fromRGB(0, 255, 255),
    PalletColor = Color3.fromRGB(74, 255, 181),
    WindowColor = Color3.fromRGB(100, 180, 255),
    
    GUI_NAME = "SkillCheckPromptGui",
    FRAME_NAME = "Check",
    NEEDLE_NAME = "Line",
    GOAL_NAME = "Goal",
}

local ITEM_COOLDOWNS = {
    ["Parrying Dagger"] = 60,
    ["Holy Water"] = 70,
    ["Riot Shield"] = 50,
    ["Adrenaline Shot"] = 60,
    ["Shadow Clone"] = 60,
    ["Gate"] = 60,
    ["WaxBound Candle"] = 30
}

local KNOWN_KILLERS = {
    ["Stalker"] = true, ["Killer"] = true, ["Slasher"] = true, ["Masked"] = true, 
    ["Abysswalker"] = true, ["Veil"] = true, ["Cure"] = true, ["scp035"] = true,
    ["Halloween_Jerma"] = true, ["Halloween_MJ"] = true, ["Christmas_ScratchFace"] = true
}

local KILLER_ITEMS = {"knife", "bat", "axe", "machete", "saw", "gun", "hammer", "sword", "katana", "pipe", "weapon"}
local SURVIVOR_ITEMS = {"medkit", "firstaid", "bandage", "flashlight", "phone", "key", "card", "soda"}
local ATTACK_KEYWORDS = {"attack", "swing", "slash", "lunge", "m1", "punch", "strike", "heavy", "light"} 
local ATTACK_IDS = { "111920872708571", "78935059863801", "139369275981139", "78432063483146", "132817836308238", "133963973694098", "74968262036854" }

if _G.ProScript_Connections then
    for _, conn in pairs(_G.ProScript_Connections) do if conn then pcall(function() conn:Disconnect() end) end end
end
_G.ProScript_Connections = {} 

local fbConnections = {} 
local fogConnections = {} 
local originalCollision = {}
local cachedNoclipParts = {}
local ActiveCooldowns = {}

local origLighting = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows,
    ClockTime = Lighting.ClockTime, AtmDensity = nil
}

local function SendNotify(titleText, descText) pcall(function() StarterGui:SetCore("SendNotification", { Title = titleText, Text = descText, Duration = 2 }) end) end

local function SetupTrackerGUI()
    local oldGui = PlayerGui:FindFirstChild("VD_ItemTracker")
    if oldGui then oldGui:Destroy() end

    local TrackerGui = Instance.new("ScreenGui")
    TrackerGui.Name = "VD_ItemTracker"
    TrackerGui.ResetOnSpawn = false
    TrackerGui.Parent = PlayerGui

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(0, 200, 0, 400)
    Container.Position = UDim2.new(0, 20, 0.5, -200)
    Container.BackgroundTransparency = 1
    Container.Parent = TrackerGui

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 10)
    UIListLayout.Parent = Container

    return Container
end
local TrackerContainer = SetupTrackerGUI()

local function CreateCooldownBar(itemName, duration)
    if ActiveCooldowns[itemName] then return end
    ActiveCooldowns[itemName] = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = TrackerContainer

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 4)
    uic.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    local uic2 = Instance.new("UICorner")
    uic2.CornerRadius = UDim.new(0, 4)
    uic2.Parent = bar

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = itemName .. " (" .. duration .. "s)"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = frame

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(bar, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
    tween:Play()

    task.spawn(function()
        for i = duration, 1, -1 do
            if not frame or not frame.Parent then break end
            label.Text = itemName .. " (" .. i .. "s)"
            task.wait(1)
        end
        if frame then frame:Destroy() end
        ActiveCooldowns[itemName] = nil
    end)
end

local function HookTool(tool)
    if tool:IsA("Tool") and ITEM_COOLDOWNS[tool.Name] then
        table.insert(_G.ProScript_Connections, tool.Activated:Connect(function()
            CreateCooldownBar(tool.Name, ITEM_COOLDOWNS[tool.Name])
        end))
    end
end

local function CacheNoclipParts(char)
    cachedNoclipParts = {}
    for _, v in pairs(char:GetDescendants()) do 
        if v:IsA("BasePart") then table.insert(cachedNoclipParts, v) end 
    end
end

local function SaveCollisionData(char)
    originalCollision = {}
    for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then originalCollision[v] = v.CanCollide end end
end

local function RestoreCollisionData(char)
    for part, canCollide in pairs(originalCollision) do if part and part.Parent then part.CanCollide = canCollide end end
    originalCollision = {}
end

local function ForceResetCollision(char)
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name == "HumanoidRootPart" then v.CanCollide = false
            elseif v.Name:match("Leg") or v.Name:match("Foot") then v.CanCollide = false 
            else v.CanCollide = true end
        end
    end
end

local function CleanVisuals()
    for _, v in pairs(Workspace:GetDescendants()) do 
        if v.Name:match("ESP") and (v:IsA("Highlight") or v:IsA("BillboardGui")) then v:Destroy() end 
    end
end
CleanVisuals()

local function AutoCleanVision()
    if not SETTINGS.CleanVision_Enabled then return end
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local darkness = pg:FindFirstChild("Darkness")
            if darkness and darkness.Enabled then darkness.Enabled = false end
            
            local blood = pg:FindFirstChild("Killerblood")
            if blood and blood.Enabled then blood.Enabled = false end
            
            local effects = pg:FindFirstChild("effects")
            if effects then
                local vignette = effects:FindFirstChild("vignette")
                if vignette and vignette.Visible then vignette.Visible = false end
                local pestilence = effects:FindFirstChild("pestilence")
                if pestilence and pestilence.Visible then pestilence.Visible = false end
            end
        end
        if LocalPlayer.Character then
            local cutscene = LocalPlayer.Character:FindFirstChild("cutscene")
            if cutscene and cutscene:IsA("LocalScript") and not cutscene.Disabled then cutscene.Disabled = true end
        end
    end)
end

local function SpeedHackLoop()
    if not SETTINGS.SpeedHack_Enabled then return end
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.WalkSpeed < 24 then hum.WalkSpeed = 24 end
        end
    end)
end

local function GetPlayerRole(plr)
    if not plr or not plr.Character then return "Unknown" end
    local success, teamName = pcall(function() return plr.Team.Name:lower() end)
    if success and teamName then
        if teamName:match("kill") or teamName:match("murder") then return "Killer" end
        if teamName:match("surviv") or teamName:match("innocent") then return "Survivor" end
    end
    local charName = plr.Character.Name
    if KNOWN_KILLERS[charName] or plr.Character:FindFirstChild("WeaponHolder") or plr.Character:FindFirstChild("Weapon") then return "Killer" end
    local function CheckItems(container)
        for _, item in pairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                for _, k in ipairs(KILLER_ITEMS) do if name:match(k) then return "Killer" end end
                for _, s in ipairs(SURVIVOR_ITEMS) do if name:match(s) then return "Survivor" end end
            end
        end
        return nil
    end
    local role = CheckItems(plr.Character)
    if not role and plr:FindFirstChild("Backpack") then role = CheckItems(plr.Backpack) end
    return role or "Suspect"
end

local function CreatePlayerESP(target, text, color)
    if not target or not target.Parent then return end
    local char = target.Parent
    local hi = char:FindFirstChild("RoleESP_Highlight") or Instance.new("Highlight", char)
    hi.Name, hi.FillColor, hi.OutlineColor, hi.FillTransparency, hi.OutlineTransparency = "RoleESP_Highlight", color, color, 1, 0
    local bg = target:FindFirstChild("RoleESP_Tag") or Instance.new("BillboardGui", target)
    bg.Name, bg.Size, bg.AlwaysOnTop, bg.StudsOffset = "RoleESP_Tag", UDim2.new(0, 200, 0, 50), true, Vector3.new(0, 3.5, 0)
    local tl = bg:FindFirstChild("Label") or Instance.new("TextLabel", bg)
    tl.Name, tl.BackgroundTransparency, tl.Size, tl.Font, tl.TextSize, tl.Text, tl.TextColor3, tl.TextStrokeTransparency, tl.TextStrokeColor3 = "Label", 1, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 13, text, color, 0, Color3.new(0,0,0)
end

local function UpdatePlayerESP()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local char = p.Character
                local humanoid = char:FindFirstChild("Humanoid")
                local role = GetPlayerRole(p)
                local dist = (myPos - char.HumanoidRootPart.Position).Magnitude
                local hpText = ""
                if humanoid and role == "Survivor" then
                    local hp = math.floor(humanoid.Health)
                    local maxHp = math.floor(humanoid.MaxHealth)
                    hpText = hp < maxHp and string.format(" [HP:%d%%]", (hp/maxHp)*100) or " [FULL]"
                end
                local color = (role == "Killer" and SETTINGS.KillerColor) or (role == "Suspect" and SETTINGS.SuspectColor) or SETTINGS.SurvivorColor
                local prefix = (role == "Killer" and "[KILLER] ") or (role == "Suspect" and "[?] ") or "[+] "
                CreatePlayerESP(char.HumanoidRootPart, prefix .. p.Name .. hpText .. string.format("\n[%d m]", math.floor(dist)), color)
            end)
        end
    end
end

local function GetGenProgress(model)
    local pct = tonumber(model:GetAttribute("RepairProgress")) or 0
    if pct > 0 and pct <= 1.001 then pct = pct * 100 end
    return math.floor(math.clamp(pct, 0, 100))
end

local cachedWorldObjects = {}
local function AddWorldObject(v)
    if v:IsA("Model") and not v:IsA("Character") then
        local name = v.Name:lower()
        if name:match("generator") or name:match("cipher") or name:match("repair") or name == "palletwrong" or name == "pallet" or name == "window" then
            table.insert(cachedWorldObjects, v)
        end
    end
end

coroutine.wrap(function()
    local descendants = Workspace:GetDescendants()
    for i, v in ipairs(descendants) do
        AddWorldObject(v)
        if i % 1000 == 0 then task.wait() end 
    end
end)()
table.insert(_G.ProScript_Connections, Workspace.DescendantAdded:Connect(AddWorldObject))

local function UpdateWorldESP()
    local activeObjects = {}
    for _, v in ipairs(cachedWorldObjects) do
        if v and v.Parent then
            table.insert(activeObjects, v) 
            local name = v.Name:lower()
            
            if name:match("generator") or name:match("cipher") or name:match("repair") then
                local percent = GetGenProgress(v)
                if percent >= 99 then
                    local hi = v:FindFirstChild("GenESP_Highlight")
                    if hi then hi:Destroy() end
                    local tag = v:FindFirstChild("GenESP_Tag", true)
                    if tag then tag:Destroy() end
                else 
                    local hi = v:FindFirstChild("GenESP_Highlight") or Instance.new("Highlight", v)
                    hi.Name, hi.FillColor, hi.OutlineColor, hi.FillTransparency = "GenESP_Highlight", SETTINGS.GenColor, SETTINGS.GenColor, 0.4
                    local centerPart = v.PrimaryPart or v:FindFirstChild("HitBox") or v:FindFirstChildWhichIsA("BasePart")
                    if centerPart then
                        local bg = centerPart:FindFirstChild("GenESP_Tag") or Instance.new("BillboardGui", centerPart)
                        bg.Name, bg.Size, bg.AlwaysOnTop, bg.StudsOffset = "GenESP_Tag", UDim2.new(0, 150, 0, 40), true, Vector3.new(0, 2, 0)
                        local tl = bg:FindFirstChild("Label") or Instance.new("TextLabel", bg)
                        tl.Name, tl.BackgroundTransparency, tl.Size, tl.Font, tl.TextSize, tl.Text, tl.TextColor3, tl.TextStrokeTransparency = "Label", 1, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 16, string.format("%d%%", percent), Color3.fromHSV(math.clamp((percent/100)*0.33, 0, 0.33), 1, 1), 0
                    end
                end
                
            elseif name == "palletwrong" or name == "pallet" then
                local centerPart = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                local hi = v:FindFirstChild("ObjESP_Highlight") or Instance.new("Highlight", v)
                hi.Name, hi.FillColor, hi.OutlineColor, hi.FillTransparency, hi.OutlineTransparency = "ObjESP_Highlight", SETTINGS.PalletColor, SETTINGS.PalletColor, 0.8, 0.3
                hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                if centerPart then
                    local oldTag = centerPart:FindFirstChild("ObjESP_Tag")
                    if oldTag then oldTag:Destroy() end
                end
                
            elseif name == "window" then
                local centerPart = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                local oldHi = v:FindFirstChild("ObjESP_Highlight")
                if oldHi then oldHi:Destroy() end
                if centerPart then
                    local bg = centerPart:FindFirstChild("ObjESP_Tag") or Instance.new("BillboardGui", centerPart)
                    bg.Name, bg.Size, bg.AlwaysOnTop, bg.StudsOffset = "ObjESP_Tag", UDim2.new(0, 100, 0, 30), true, Vector3.new(0, 1.5, 0)
                    local tl = bg:FindFirstChild("Label") or Instance.new("TextLabel", bg)
                    tl.Name, tl.BackgroundTransparency, tl.Size, tl.Font, tl.TextSize, tl.Text, tl.TextColor3, tl.TextStrokeTransparency, tl.TextStrokeColor3 = "Label", 1, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 11, "[WINDOW]", SETTINGS.WindowColor, 0, Color3.new(0,0,0)
                end
            end
        end
    end
    cachedWorldObjects = activeObjects
end

local function LineInGoal(Line, Goal)
    local lr, gr = Line.Rotation % 360, Goal.Rotation % 360
    local gs, ge = (gr + 104) % 360, (gr + 114) % 360
    return gs > ge and (lr >= gs or lr <= ge) or (lr >= gs and lr <= ge)
end

local function AutoSkillCheck()
    if not SETTINGS.AutoSkill_Enabled then return end
    pcall(function()
        local mainGui = PlayerGui:FindFirstChild(SETTINGS.GUI_NAME)
        local checkFrame = mainGui and mainGui:FindFirstChild(SETTINGS.FRAME_NAME, true)
        if checkFrame and checkFrame.Visible then
            local needle, goal = checkFrame:FindFirstChild(SETTINGS.NEEDLE_NAME), checkFrame:FindFirstChild(SETTINGS.GOAL_NAME)
            if needle and goal and LineInGoal(needle, goal) then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait() 
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end)
end

local lastParryTime = 0

-- [NEW] ส่งค่าคลิกที่สมูทขึ้นเพื่อไม่ให้ Server รีเจค
local function ExecuteParry()
    if SETTINGS.Parry_Key == "RightClick" then 
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
        task.wait(0.05) -- หน่วงนิดนึงเพื่อให้ Server จับจังหวะได้เต็ม 0.8s
        VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
    else 
        VirtualInputManager:SendKeyEvent(true, SETTINGS.Parry_Key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, SETTINGS.Parry_Key, false, game) 
    end
end

local function IsFacingMe(myPos, killerRoot)
    local directionToMe = (myPos - killerRoot.Position).Unit
    local killerLook = killerRoot.CFrame.LookVector
    return directionToMe:Dot(killerLook) > 0.35 
end

-- [NEW] ตรวจจับ 3 รูปแบบ (Animation + เสียง Pull + เอฟเฟกต์ Trail)
local function CheckKillerAttacking(kChar)
    -- 1. เช็ค Animation (วิธีเดิม)
    local animator = kChar:FindFirstChild("Animator", true) or (kChar:FindFirstChildWhichIsA("Humanoid") and kChar:FindFirstChildWhichIsA("Humanoid"):FindFirstChild("Animator"))
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action2 or track.Priority == Enum.AnimationPriority.Action3 then
                local name = track.Name:lower()
                local id = track.Animation.AnimationId
                for _, kw in ipairs(ATTACK_KEYWORDS) do if name:find(kw) then return true end end
                for _, aid in ipairs(ATTACK_IDS) do if id:find(aid) then return true end end
            end
        end
    end

    -- 2. เช็คเสียงดึงอาวุธ (Pull Sound) จากแขนขวา
    local rightArm = kChar:FindFirstChild("Right Arm") or kChar:FindFirstChild("RightHand")
    if rightArm then
        local pullSound = rightArm:FindFirstChild("Pull")
        if pullSound and pullSound:IsA("Sound") and pullSound.Playing then
            return true
        end
    end

    -- 3. เช็ค Trail ของอาวุธว่าถูกเปิดใช้งานหรือยัง
    local weaponFolder = kChar:FindFirstChild("Weapon") or kChar:FindFirstChild("WeaponHolder")
    if weaponFolder then
        for _, v in pairs(weaponFolder:GetDescendants()) do
            if (v:IsA("Trail") or v:IsA("ParticleEmitter")) and v.Enabled then
                return true
            end
        end
    end

    return false
end

local function AutoParryCheck()
    if not SETTINGS.AutoParry_Enabled or not LocalPlayer.Character then return end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local now = os.clock()
    if now - lastParryTime < SETTINGS.Parry_Cooldown then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if GetPlayerRole(p) == "Killer" then
                local kHum = p.Character:FindFirstChild("Humanoid")
                local kRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if kRoot and kHum and kHum.Health > 0 then
                    local dist = (kRoot.Position - myRoot.Position).Magnitude
                    if dist <= SETTINGS.Parry_MaxRange then
                        local isPanic = dist <= SETTINGS.Parry_PanicRange
                        if isPanic or IsFacingMe(myRoot.Position, kRoot) then
                            
                            -- เรียกใช้ฟังก์ชันตรวจสอบแบบ 3 มิติ
                            if CheckKillerAttacking(p.Character) then
                                task.spawn(ExecuteParry) 
                                lastParryTime = os.clock()
                                return 
                            end
                            
                        end
                    end
                end
            end
        end
    end
end

local function GetClosestKiller()
    local closestTarget = nil
    local maxDist = SETTINGS.Aimbot_FOV
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if GetPlayerRole(p) == "Killer" then
                local hum = p.Character:FindFirstChild("Humanoid")
                local targetPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                if hum and targetPart and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < maxDist then
                            closestTarget = targetPart
                            maxDist = dist
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local function AutoAim()
    if not SETTINGS.Aimbot_Enabled then return end
    if not UserInputService:IsMouseButtonPressed(SETTINGS.Aimbot_HoldKey) then return end
    local target = GetClosestKiller()
    if target then
        local predictedPos = target.Position + (target.Velocity * SETTINGS.Aimbot_Prediction)
        local currentCamCF = Camera.CFrame
        local goalCF = CFrame.new(currentCamCF.Position, predictedPos)
        Camera.CFrame = currentCamCF:Lerp(goalCF, SETTINGS.Aimbot_Smoothness)
    end
end

table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(AutoSkillCheck))
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(AutoAim)) 
table.insert(_G.ProScript_Connections, RunService.Heartbeat:Connect(AutoParryCheck))
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(AutoCleanVision)) 
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(SpeedHackLoop))

table.insert(_G.ProScript_Connections, RunService.Stepped:Connect(function()
    if SETTINGS.Noclip_Enabled and LocalPlayer.Character then
        for i = 1, #cachedNoclipParts do 
            local p = cachedNoclipParts[i]
            if p and p.Parent then p.CanCollide = false end
        end
    end
end))

coroutine.wrap(function() 
    while true do 
        if SETTINGS.ESP_Enabled then pcall(UpdatePlayerESP) end 
        task.wait(0.2) 
    end 
end)()

coroutine.wrap(function() 
    while true do 
        if SETTINGS.ESP_Enabled then pcall(UpdateWorldESP) end 
        task.wait(1.5) 
    end 
end)()

table.insert(_G.ProScript_Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == SETTINGS.Key_Help then
        pcall(function() 
            StarterGui:SetCore("SendNotification", { 
                Title = "📜 รายการปุ่มกด (Help)", 
                Text = "E = ESP | R = Noclip | C = Anti-Blind\nG = AutoSkill | V = God AutoParry\nX = Aimbot | K = Fullbright\nP = No Fog | B = Speed Hack\nL = Rejoin", 
                Duration = 5 
            }) 
        end)
    elseif input.KeyCode == SETTINGS.Key_ESP then
        SETTINGS.ESP_Enabled = not SETTINGS.ESP_Enabled
        if not SETTINGS.ESP_Enabled then CleanVisuals() end
        SendNotify("ESP", SETTINGS.ESP_Enabled and "ON" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_Noclip then
        SETTINGS.Noclip_Enabled = not SETTINGS.Noclip_Enabled
        if SETTINGS.Noclip_Enabled then 
            SaveCollisionData(LocalPlayer.Character)
            CacheNoclipParts(LocalPlayer.Character) 
        else 
            if next(originalCollision) then RestoreCollisionData(LocalPlayer.Character) else ForceResetCollision(LocalPlayer.Character) end 
        end
        SendNotify("Noclip", SETTINGS.Noclip_Enabled and "ON" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_AutoSkill then
        SETTINGS.AutoSkill_Enabled = not SETTINGS.AutoSkill_Enabled
        SendNotify("Auto Skill", SETTINGS.AutoSkill_Enabled and "ON" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_AutoParry then
        SETTINGS.AutoParry_Enabled = not SETTINGS.AutoParry_Enabled
        SendNotify("God Auto Parry", SETTINGS.AutoParry_Enabled and "ON" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_Aimbot then
        SETTINGS.Aimbot_Enabled = not SETTINGS.Aimbot_Enabled
        SendNotify("Aimbot (Head-Lock)", SETTINGS.Aimbot_Enabled and "ON (Hold Right Click)" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_CleanVision then
        SETTINGS.CleanVision_Enabled = not SETTINGS.CleanVision_Enabled
        SendNotify("Clean Vision (Anti-Blind)", SETTINGS.CleanVision_Enabled and "ON" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_SpeedHack then
        SETTINGS.SpeedHack_Enabled = not SETTINGS.SpeedHack_Enabled
        if not SETTINGS.SpeedHack_Enabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        SendNotify("Speed Hack (Test)", SETTINGS.SpeedHack_Enabled and "ON (WalkSpeed = 24)" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_Fullbright then
        SETTINGS.Fullbright_Enabled = not SETTINGS.Fullbright_Enabled
        if SETTINGS.Fullbright_Enabled then
            origLighting.Ambient = Lighting.Ambient
            origLighting.OutdoorAmbient = Lighting.OutdoorAmbient
            origLighting.Brightness = Lighting.Brightness
            origLighting.GlobalShadows = Lighting.GlobalShadows
            origLighting.ClockTime = Lighting.ClockTime
            
            table.insert(fbConnections, Lighting:GetPropertyChangedSignal("Ambient"):Connect(function() Lighting.Ambient = Color3.fromRGB(255, 255, 255) end))
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            
            table.insert(fbConnections, Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function() Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) end))
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            
            table.insert(fbConnections, Lighting:GetPropertyChangedSignal("Brightness"):Connect(function() Lighting.Brightness = 2 end))
            Lighting.Brightness = 2
            
            table.insert(fbConnections, Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function() Lighting.GlobalShadows = false end))
            Lighting.GlobalShadows = false
            
            table.insert(fbConnections, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function() Lighting.ClockTime = 12 end))
            Lighting.ClockTime = 12
            SendNotify("Fullbright", "ON (Locked)")
        else
            for _, conn in pairs(fbConnections) do conn:Disconnect() end
            table.clear(fbConnections)
            Lighting.Ambient = origLighting.Ambient
            Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
            Lighting.Brightness = origLighting.Brightness
            Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.ClockTime = origLighting.ClockTime
            SendNotify("Fullbright", "OFF")
        end
    elseif input.KeyCode == SETTINGS.Key_NoFog then 
        SETTINGS.NoFog_Enabled = not SETTINGS.NoFog_Enabled
        if SETTINGS.NoFog_Enabled then
            origLighting.FogEnd = Lighting.FogEnd
            origLighting.FogStart = Lighting.FogStart
            table.insert(fogConnections, Lighting:GetPropertyChangedSignal("FogStart"):Connect(function() Lighting.FogStart = 0 end))
            Lighting.FogStart = 0
            table.insert(fogConnections, Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function() Lighting.FogEnd = 999999 end))
            Lighting.FogEnd = 999999
            
            local atm = Lighting:FindFirstChildWhichIsA("Atmosphere")
            if atm then
                origLighting.AtmDensity = atm.Density
                table.insert(fogConnections, atm:GetPropertyChangedSignal("Density"):Connect(function() atm.Density = 0 end))
                atm.Density = 0
            end
            SendNotify("No Fog", "ON (Locked)")
        else
            for _, conn in pairs(fogConnections) do conn:Disconnect() end
            table.clear(fogConnections)
            Lighting.FogStart = origLighting.FogStart or 0
            Lighting.FogEnd = origLighting.FogEnd or 100000
            local atm = Lighting:FindFirstChildWhichIsA("Atmosphere")
            if atm and origLighting.AtmDensity then atm.Density = origLighting.AtmDensity end
            SendNotify("No Fog", "OFF")
        end
    elseif input.KeyCode == SETTINGS.Key_Rejoin then
        SendNotify("Rejoining", "Please wait... Teleporting back to server.")
        task.wait(0.5)
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    end
end))

table.insert(_G.ProScript_Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    
    if SETTINGS.Noclip_Enabled then
        SaveCollisionData(char)
        CacheNoclipParts(char)
    end

    table.insert(_G.ProScript_Connections, char.ChildAdded:Connect(HookTool))
    for _, child in pairs(char:GetChildren()) do HookTool(child) end
end))

if LocalPlayer.Character then
    table.insert(_G.ProScript_Connections, LocalPlayer.Character.ChildAdded:Connect(HookTool))
    for _, child in pairs(LocalPlayer.Character:GetChildren()) do HookTool(child) end
end

SendNotify("V8.9 + GOD PARRY + ITEM TRACKER", "Loaded! (Press Z for Keybinds)")
