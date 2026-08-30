-- [[ PROJECT: VIOLENCE DISTRICT - INSTANT V9 (FIXED ITEM TRACKER + MOBILE + HEAL + SCP + CROSSHAIR) ]] --
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
local GuiService = game:GetService("GuiService")

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
    Key_SwitchAim = Enum.KeyCode.T, 
    Key_SelfHeal = Enum.KeyCode.H, 
    Key_Fullbright = Enum.KeyCode.K, 
    Key_NoFog = Enum.KeyCode.P, 
    Key_CleanVision = Enum.KeyCode.C,
    Key_SpeedHack = Enum.KeyCode.B,
    Key_Rejoin = Enum.KeyCode.L,
    Key_Help = Enum.KeyCode.Z, 
    Key_Crosshair = Enum.KeyCode.M, -- [ADDED] ปุ่มเปิด/ปิดเป้าเล็ง
    
    ESP_Enabled = false,              
    Noclip_Enabled = false,
    AutoSkill_Enabled = true,
    AutoParry_Enabled = false,
    Aimbot_Enabled = false,        
    Fullbright_Enabled = false, 
    NoFog_Enabled = false,
    CleanVision_Enabled = false,
    SpeedHack_Enabled = false,
    SelfHeal_Enabled = false,
    Crosshair_Enabled = false, -- [ADDED] สถานะเป้าเล็งเริ่มต้น
    
    Aimbot_TargetMode = "Killer", -- "Killer", "SCP", "Both"
    
    Parry_Key = "RightClick", 
    Parry_MaxRange = 15, 
    Parry_PanicRange = 6.5,   
    Parry_Cooldown = 0.05, 
    
    Aimbot_HoldKey = Enum.UserInputType.MouseButton2,
    Aimbot_FOV = 150,                
    Aimbot_Smoothness = 0.2,        
    Aimbot_Prediction = 0.13,        
    
    -- [UPDATED] เปลี่ยนสีผู้เล่น (Survivor) เป็นสีเหลือง
    SurvivorColor = Color3.fromRGB(255, 255, 0),    
    KillerColor = LocalPlayer:GetAttribute("killeraura") or Color3.fromRGB(255, 0, 0),        
    SuspectColor = Color3.fromRGB(255, 170, 0),        
    GenColor = LocalPlayer:GetAttribute("genaura") or Color3.fromRGB(0, 255, 255),
    PalletColor = Color3.fromRGB(74, 255, 181),
    WindowColor = Color3.fromRGB(100, 180, 255),
    SCPColor = Color3.fromRGB(255, 0, 0),
    
    GUI_NAME = "SkillCheckPromptGui",
    FRAME_NAME = "Check",
    NEEDLE_NAME = "Line",
    GOAL_NAME = "Goal",
}

-- [FIXED] ฐานข้อมูลไอเทมคูลดาวน์
local ITEM_COOLDOWNS = {
    ["parryingdagger"] = 60,
    ["holywater"] = 70,
    ["riotshield"] = 50,
    ["adrenalineshot"] = 60,
    ["shadowclone"] = 60,
    ["gate"] = 60,
    ["waxboundcandle"] = 30
}

local KNOWN_KILLERS = {
    ["Stalker"] = true, ["Killer"] = true, ["Slasher"] = true, ["Masked"] = true, 
    ["Abysswalker"] = true, ["Veil"] = true, ["Cure"] = true, ["scp035"] = true,
    ["Halloween_Jerma"] = true, ["Halloween_MJ"] = true, ["Christmas_ScratchFace"] = true
}

local KILLER_ITEMS = {"knife", "bat", "axe", "machete", "saw", "gun", "hammer", "sword", "katana", "pipe", "weapon"}
local SURVIVOR_ITEMS = {"medkit", "firstaid", "bandage", "flashlight", "phone", "key", "card", "soda"}
local ATTACK_KEYWORDS = {"attack", "swing", "slash", "lunge", "m1", "punch", "strike", "heavy", "light"} 

local KILLER_ANIM_IDS = {
    ["105374834496520"] = true, ["113255068724446"] = true, ["118907603246885"] = true, ["129784271201071"] = true,
    ["117042998468241"] = true, ["122812055447896"] = true, ["78935059863801"] = true,  ["74968262036854"] = true,
    ["78432063483146"] = true,  ["132817836308238"] = true, ["133963973694098"] = true, ["111920872708571"] = true,
    ["80411309607666"] = true,  ["98163597193511"] = true,  ["82666958311998"] = true,  ["110355011987939"] = true,
    ["139369275981139"] = true, ["135002183282873"] = true, ["121216847022485"] = true, ["130593238885843"] = true,
    ["117070354890871"] = true, ["106871536134254"] = true, ["138720291317243"] = true
}

if _G.ProScript_Connections then
    for _, conn in pairs(_G.ProScript_Connections) do if conn then pcall(function() conn:Disconnect() end) end end
end
_G.ProScript_Connections = {} 

local fbConnections = {} 
local fogConnections = {} 
local originalCollision = {}
local cachedNoclipParts = {}
local ActiveCooldowns = {}
local VaultTracks = {}

local origLighting = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows,
    ClockTime = Lighting.ClockTime, AtmDensity = nil
}

local function SendNotify(titleText, descText) pcall(function() StarterGui:SetCore("SendNotification", { Title = titleText, Text = descText, Duration = 2 }) end) end

-- [ADDED] SELF HEAL SYSTEM
local SelfHealData = { HealAmount = 10, Progress = 0 }
local SelfHealLabel = nil

local function SetupSelfHealUI()
    local oldGui = PlayerGui:FindFirstChild("VD_SelfHealGui")
    if oldGui then oldGui:Destroy() end
    if not SETTINGS.SelfHeal_Enabled then return end

    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name = "VD_SelfHealGui"
    sg.ResetOnSpawn = false
    
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 200, 0, 35)
    frame.Position = UDim2.new(0.5, -100, 0.9, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1,0)
    
    SelfHealLabel = Instance.new("TextLabel", frame)
    SelfHealLabel.Size = UDim2.new(1,0,1,0)
    SelfHealLabel.BackgroundTransparency = 1
    SelfHealLabel.TextColor3 = Color3.fromRGB(0,255,0)
    SelfHealLabel.Font = Enum.Font.GothamBold
    SelfHealLabel.TextSize = 14
    SelfHealLabel.Text = "💚 Self Heal: Ready"
end

local function ProcessSelfHeal()
    if not SETTINGS.SelfHeal_Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    local healNeeded = hum.MaxHealth - hum.Health
    if healNeeded > 0 then
        SelfHealData.Progress = math.min(100, (healNeeded / hum.MaxHealth) * 100)
        hum.Health = hum.Health + math.min(SelfHealData.HealAmount, healNeeded)
        if SelfHealLabel then SelfHealLabel.Text = string.format("💚 Healing: %.0f%%", SelfHealData.Progress) end
    else
        if SelfHealLabel then SelfHealLabel.Text = "✅ Full Health" end
    end
end

-- [UPGRADED] TRACKER GUI
local function GetTrackerContainer()
    local gui = PlayerGui:FindFirstChild("VD_ItemTracker")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "VD_ItemTracker"
        gui.ResetOnSpawn = false
        gui.Parent = PlayerGui

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(0, 200, 0, 400)
        container.Position = UDim2.new(0, 20, 0.5, -200)
        container.BackgroundTransparency = 1
        container.Parent = gui

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10)
        layout.Parent = container
    end
    return gui.Container
end

local function CreateCooldownBar(itemName, duration)
    if ActiveCooldowns[itemName] then return end
    ActiveCooldowns[itemName] = true

    local container = GetTrackerContainer()

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = container
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

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

-- [ADDED] ระบบเปลี่ยนแอนิเมชันข้ามสิ่งกีดขวางให้ไวขึ้น
local function HookVault(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local animator = hum:WaitForChild("Animator", 5)
    if not animator then return end
    
    table.insert(_G.ProScript_Connections, animator.AnimationPlayed:Connect(function(track)
        if not track.Animation or not track.Animation.AnimationId then return end
        local id = track.Animation.AnimationId:match("%d+")
        if id == "83873880822918" then
            if VaultTracks[track] then return end
            VaultTracks[track] = true
            track:Stop()
            local newAnim = Instance.new("Animation")
            newAnim.AnimationId = "rbxassetid://136962284480779"
            local newTrack = animator:LoadAnimation(newAnim)
            newTrack.Priority = Enum.AnimationPriority.Action
            newTrack:Play()
            newTrack:AdjustSpeed(1.3)
            newTrack.Stopped:Connect(function() VaultTracks[track] = nil end)
        end
    end))
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

local AntiFall = { IsBoosted = false, BoostTimer = 0 }
local lastHealTime = 0
local function ConstantLogicLoop()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local myRole = GetPlayerRole(LocalPlayer)

        if SETTINGS.SpeedHack_Enabled and not AntiFall.IsBoosted then
            if hum.WalkSpeed < 24 then hum.WalkSpeed = 24 end
        end

        local velocity = hrp.AssemblyLinearVelocity
        if velocity.Y < -40 and not AntiFall.IsBoosted and myRole ~= "Killer" then
            AntiFall.IsBoosted = true
            AntiFall.BoostTimer = os.clock()
            hum.WalkSpeed = 24
        elseif AntiFall.IsBoosted then
            if os.clock() - AntiFall.BoostTimer >= 4 then
                AntiFall.IsBoosted = false
                if not SETTINGS.SpeedHack_Enabled then hum.WalkSpeed = 16 end
            else
                if hum.WalkSpeed < 24 then hum.WalkSpeed = 24 end
            end
        end

        if SETTINGS.SelfHeal_Enabled then
            local now = os.clock()
            if now - lastHealTime >= 1 then
                lastHealTime = now
                ProcessSelfHeal()
            end
        end
    end)
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
                    local isDown = hp <= 0 or hp < 2 or char:GetAttribute("Downed") == true or char:GetAttribute("IsDown") == true or char:GetAttribute("Knocked") == true
                    if isDown then hpText = hpText .. " [🔻DOWN]" end
                end
                
                local color = (role == "Killer" and SETTINGS.KillerColor) or (role == "Suspect" and SETTINGS.SuspectColor) or SETTINGS.SurvivorColor
                local prefix = (role == "Killer" and "[KILLER] ") or (role == "Suspect" and "[?] ") or "[+] "
                CreatePlayerESP(char.HumanoidRootPart, prefix .. p.Name .. hpText .. string.format("\n[%d m]", math.floor(dist)), color)
            end)
        end
    end
end

local function GetGenProgress(model)
    local pct = tonumber(model:GetAttribute("RepairProgress")) or tonumber(model:GetAttribute("Progress")) or 0
    if pct > 0 and pct <= 1.001 then pct = pct * 100 end
    return math.floor(math.clamp(pct, 0, 100))
end

local cachedWorldObjects = {}
local cachedSCP = {}
local function AddWorldObject(v)
    if v:IsA("Model") and not v:IsA("Character") then
        local name = v.Name:lower()
        if name:match("generator") or name:match("cipher") or name:match("repair") or name == "palletwrong" or name == "pallet" or name == "window" then
            table.insert(cachedWorldObjects, v)
        end
        if name:match("scp") then
            table.insert(cachedSCP, v)
        end
    end
end

coroutine.wrap(function()
    local descendants = Workspace:GetDescendants()
    for i, v in ipairs(descendants) do AddWorldObject(v); if i % 1000 == 0 then task.wait() end end
end)()
table.insert(_G.ProScript_Connections, Workspace.DescendantAdded:Connect(AddWorldObject))

local function UpdateWorldESP()
    local activeObjects = {}
    local activeSCP = {}
    
    local myPos = Vector3.zero
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end

    for _, scp in ipairs(cachedSCP) do 
        if scp and scp:IsDescendantOf(Workspace) then 
            table.insert(activeSCP, scp) 
            local targetPart = scp.PrimaryPart or scp:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local dist = (myPos ~= Vector3.zero) and (myPos - targetPart.Position).Magnitude or 0
                local hi = scp:FindFirstChild("SCPESP_Highlight") or Instance.new("Highlight", scp)
                hi.Name, hi.FillColor, hi.OutlineColor, hi.FillTransparency, hi.OutlineTransparency = "SCPESP_Highlight", SETTINGS.SCPColor, SETTINGS.SCPColor, 0.8, 0.2
                hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                
                local bg = targetPart:FindFirstChild("SCPESP_Tag") or Instance.new("BillboardGui", targetPart)
                bg.Name, bg.Size, bg.AlwaysOnTop, bg.StudsOffset = "SCPESP_Tag", UDim2.new(0, 100, 0, 30), true, Vector3.new(0, 3, 0)
                local tl = bg:FindFirstChild("Label") or Instance.new("TextLabel", bg)
                tl.Name, tl.BackgroundTransparency, tl.Size, tl.Font, tl.TextSize, tl.Text, tl.TextColor3, tl.TextStrokeTransparency, tl.TextStrokeColor3 = "Label", 1, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 12, string.format("[SCP] [%dm]", math.floor(dist)), SETTINGS.SCPColor, 0, Color3.new(0,0,0)
            end
        end 
    end
    cachedSCP = activeSCP

    for _, v in ipairs(cachedWorldObjects) do
        if v and v:IsDescendantOf(Workspace) then
            table.insert(activeObjects, v) 
            local name = v.Name:lower()
            if name:match("generator") or name:match("cipher") or name:match("repair") then
                local percent = GetGenProgress(v)
                if percent >= 99 then
                    local hi = v:FindFirstChild("GenESP_Highlight") if hi then hi:Destroy() end
                    local tag = v:FindFirstChild("GenESP_Tag", true) if tag then tag:Destroy() end
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

local function GetSkillCheckMobileBtn()
    local current = PlayerGui
    for segment in string.gmatch("Survivor-mob.Controls.action.check", "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end

local function AutoSkillCheck()
    if not SETTINGS.AutoSkill_Enabled then return end
    pcall(function()
        local mainGui = PlayerGui:FindFirstChild(SETTINGS.GUI_NAME)
        local checkFrame = mainGui and mainGui:FindFirstChild(SETTINGS.FRAME_NAME, true)
        if checkFrame and checkFrame.Visible then
            local needle, goal = checkFrame:FindFirstChild(SETTINGS.NEEDLE_NAME), checkFrame:FindFirstChild(SETTINGS.GOAL_NAME)
            if needle and goal and LineInGoal(needle, goal) then
                if UserInputService.TouchEnabled then
                    local btn = GetSkillCheckMobileBtn()
                    if btn and btn:IsA("GuiObject") then
                        local p, s, i = btn.AbsolutePosition, btn.AbsoluteSize, GuiService:GetGuiInset()
                        local cx, cy = p.X + (s.X/2) + i.X, p.Y + (s.Y/2) + i.Y
                        VirtualInputManager:SendTouchEvent(8822, 0, cx, cy)
                        task.wait(0.01)
                        VirtualInputManager:SendTouchEvent(8822, 2, cx, cy)
                    end
                else
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait() 
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end
            end
        end
    end)
end

local function GetParryMobileBtn()
    local current = PlayerGui
    for segment in string.gmatch("Survivor-mob.Controls.Gui-mob", "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end

local lastParryTime = 0
local function ExecuteParry()
    local now = os.clock()
    if now - lastParryTime < SETTINGS.Parry_Cooldown then return end
    lastParryTime = now

    if UserInputService.TouchEnabled then
        local btn = GetParryMobileBtn()
        if btn and btn:IsA("GuiObject") then
            local p, s, i = btn.AbsolutePosition, btn.AbsoluteSize, GuiService:GetGuiInset()
            local cx, cy = p.X + (s.X/2) + i.X, p.Y + (s.Y/2) + i.Y
            VirtualInputManager:SendTouchEvent(8823, 0, cx, cy)
            task.wait(math.random(30, 60) / 1000)
            VirtualInputManager:SendTouchEvent(8823, 2, cx, cy)
        end
    else
        if SETTINGS.Parry_Key == "RightClick" then 
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
            task.wait(math.random(30, 60) / 1000)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)
        else 
            VirtualInputManager:SendKeyEvent(true, SETTINGS.Parry_Key, false, game)
            task.wait(math.random(30, 60) / 1000)
            VirtualInputManager:SendKeyEvent(false, SETTINGS.Parry_Key, false, game) 
        end
    end
end

local function IsFacingMe(myPos, killerRoot)
    local directionToMe = (myPos - killerRoot.Position).Unit
    local killerLook = killerRoot.CFrame.LookVector
    return directionToMe:Dot(killerLook) > 0.35 
end

local function CheckKillerAttacking(kChar)
    local animator = kChar:FindFirstChild("Animator", true) or (kChar:FindFirstChildWhichIsA("Humanoid") and kChar:FindFirstChildWhichIsA("Humanoid"):FindFirstChild("Animator"))
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Priority == Enum.AnimationPriority.Action or track.Priority == Enum.AnimationPriority.Action2 or track.Priority == Enum.AnimationPriority.Action3 then
                local name = track.Name:lower()
                local id = track.Animation and track.Animation.AnimationId and track.Animation.AnimationId:match("%d+") or ""
                for _, kw in ipairs(ATTACK_KEYWORDS) do if name:find(kw) then return true end end
                if KILLER_ANIM_IDS[id] then return true end
            end
        end
    end

    local rightArm = kChar:FindFirstChild("Right Arm") or kChar:FindFirstChild("RightHand")
    if rightArm then
        local pullSound = rightArm:FindFirstChild("Pull")
        if pullSound and pullSound:IsA("Sound") and pullSound.Playing then return true end
    end

    local weaponFolder = kChar:FindFirstChild("Weapon") or kChar:FindFirstChild("WeaponHolder")
    if weaponFolder then
        for _, v in pairs(weaponFolder:GetDescendants()) do
            if (v:IsA("Trail") or v:IsA("ParticleEmitter")) and v.Enabled then return true end
        end
    end
    return false
end

local ParryCircle = nil
local function UpdateParryVisual()
    if not SETTINGS.AutoParry_Enabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if ParryCircle then ParryCircle:Destroy() ParryCircle = nil end
        return
    end
    if not ParryCircle then
        ParryCircle = Instance.new("Part")
        ParryCircle.Shape = Enum.PartType.Cylinder
        ParryCircle.Anchored = true
        ParryCircle.CanCollide = false
        ParryCircle.Material = Enum.Material.Neon
        ParryCircle.Color = Color3.fromRGB(255, 80, 80)
        ParryCircle.Transparency = 0.8
        ParryCircle.Name = "ParryRangeCircle"
        ParryCircle.Parent = Workspace
    end
    local root = LocalPlayer.Character.HumanoidRootPart
    local size = SETTINGS.Parry_MaxRange * 2
    ParryCircle.Size = Vector3.new(0.2, size, size)
    ParryCircle.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
end

local RaycastParamsBlacklist = RaycastParams.new()
RaycastParamsBlacklist.FilterType = Enum.RaycastFilterType.Blacklist

local function IsTargetVisible(targetPart)
    RaycastParamsBlacklist.FilterDescendantsInstances = {LocalPlayer.Character}
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = Workspace:Raycast(origin, direction, RaycastParamsBlacklist)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestTarget()
    local closestTarget = nil
    local maxDist = SETTINGS.Aimbot_FOV
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    if SETTINGS.Aimbot_TargetMode == "Killer" or SETTINGS.Aimbot_TargetMode == "Both" then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and GetPlayerRole(p) == "Killer" then
                local hum = p.Character:FindFirstChild("Humanoid")
                local targetPart = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and targetPart and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < maxDist and IsTargetVisible(targetPart) then
                            closestTarget = targetPart
                            maxDist = dist
                        end
                    end
                end
            end
        end
    end

    if SETTINGS.Aimbot_TargetMode == "SCP" or SETTINGS.Aimbot_TargetMode == "Both" then
        for _, scp in ipairs(cachedSCP) do
            if scp and scp.Parent then
                local targetPart = scp.PrimaryPart or scp:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < maxDist and IsTargetVisible(targetPart) then
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
    local target = GetClosestTarget()
    if target then
        local predictedPos = target.Position + (target.AssemblyLinearVelocity * SETTINGS.Aimbot_Prediction)
        local currentCamCF = Camera.CFrame
        local goalCF = CFrame.new(currentCamCF.Position, predictedPos)
        Camera.CFrame = currentCamCF:Lerp(goalCF, SETTINGS.Aimbot_Smoothness)
    end
end

table.insert(_G.ProScript_Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local safeName = string.lower(string.gsub(tool.Name, "%s+", ""))
                local cd = ITEM_COOLDOWNS[safeName]
                if cd then
                    CreateCooldownBar(tool.Name, cd)
                end
            end
        end
    end
end))

-- [ADDED] ระบบสร้าง Crosshair
local function UpdateCrosshair()
    local gui = PlayerGui:FindFirstChild("VD_Crosshair")
    
    if SETTINGS.Crosshair_Enabled then
        if not gui then
            gui = Instance.new("ScreenGui", PlayerGui)
            gui.Name = "VD_Crosshair"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            
            local center = Instance.new("Frame", gui)
            center.AnchorPoint = Vector2.new(0.5, 0.5)
            center.Position = UDim2.new(0.5, 0, 0.5, 0)
            center.Size = UDim2.new(0, 0, 0, 0)
            center.BackgroundTransparency = 1
            
            -- เส้นแนวตั้ง
            local vLine = Instance.new("Frame", center)
            vLine.Size = UDim2.new(0, 2, 0, 16)
            vLine.Position = UDim2.new(0.5, -1, 0.5, -8)
            vLine.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- สีเขียว
            vLine.BorderSizePixel = 0
            
            -- เส้นแนวนอน
            local hLine = Instance.new("Frame", center)
            hLine.Size = UDim2.new(0, 16, 0, 2)
            hLine.Position = UDim2.new(0.5, -8, 0.5, -1)
            hLine.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- สีเขียว
            hLine.BorderSizePixel = 0
        end
    else
        if gui then gui:Destroy() end
    end
end

-- Core Loops
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(AutoSkillCheck))
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(AutoAim)) 
table.insert(_G.ProScript_Connections, RunService.Heartbeat:Connect(AutoParryCheck))
table.insert(_G.ProScript_Connections, RunService.Heartbeat:Connect(UpdateParryVisual)) 
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(AutoCleanVision)) 
table.insert(_G.ProScript_Connections, RunService.RenderStepped:Connect(ConstantLogicLoop))

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

-- Keybinds
table.insert(_G.ProScript_Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == SETTINGS.Key_Help then
        pcall(function() 
            StarterGui:SetCore("SendNotification", { 
                Title = "📜 รายการปุ่มกด (Help)", 
                Text = "E = ESP | R = Noclip | C = Anti-Blind\nG = AutoSkill | V = God AutoParry\nX = Aimbot | T = Switch Aim Target\nH = Auto Heal | K = Fullbright\nP = No Fog | B = Speed Hack\nM = Crosshair | L = Rejoin", 
                Duration = 7 
            }) 
        end)
    elseif input.KeyCode == SETTINGS.Key_SwitchAim then
        if SETTINGS.Aimbot_TargetMode == "Killer" then SETTINGS.Aimbot_TargetMode = "SCP"
        elseif SETTINGS.Aimbot_TargetMode == "SCP" then SETTINGS.Aimbot_TargetMode = "Both"
        else SETTINGS.Aimbot_TargetMode = "Killer" end
        SendNotify("Aimbot Target", "Switched to: " .. SETTINGS.Aimbot_TargetMode)
    elseif input.KeyCode == SETTINGS.Key_SelfHeal then
        SETTINGS.SelfHeal_Enabled = not SETTINGS.SelfHeal_Enabled
        if SETTINGS.SelfHeal_Enabled then SetupSelfHealUI() else if SelfHealLabel and SelfHealLabel.Parent then SelfHealLabel.Parent.Parent:Destroy() end end
        SendNotify("Auto Heal", SETTINGS.SelfHeal_Enabled and "ON (Heals 10HP/s)" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_Crosshair then
        SETTINGS.Crosshair_Enabled = not SETTINGS.Crosshair_Enabled
        UpdateCrosshair()
        SendNotify("Crosshair", SETTINGS.Crosshair_Enabled and "ON" or "OFF")
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
        SendNotify("God Auto Parry", SETTINGS.AutoParry_Enabled and "ON (Visible Range)" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_Aimbot then
        SETTINGS.Aimbot_Enabled = not SETTINGS.Aimbot_Enabled
        SendNotify("Aimbot (Smart Lock)", SETTINGS.Aimbot_Enabled and "ON (Hold Right Click)" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_CleanVision then
        SETTINGS.CleanVision_Enabled = not SETTINGS.CleanVision_Enabled
        SendNotify("Clean Vision (Anti-Blind)", SETTINGS.CleanVision_Enabled and "ON" or "OFF")
    elseif input.KeyCode == SETTINGS.Key_SpeedHack then
        SETTINGS.SpeedHack_Enabled = not SETTINGS.SpeedHack_Enabled
        if not SETTINGS.SpeedHack_Enabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        SendNotify("Speed Hack", SETTINGS.SpeedHack_Enabled and "ON (WalkSpeed = 24)" or "OFF")
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

    HookVault(char)
    if SETTINGS.SelfHeal_Enabled then SetupSelfHealUI() end
end))

if LocalPlayer.Character then
    HookVault(LocalPlayer.Character)
    if SETTINGS.SelfHeal_Enabled then SetupSelfHealUI() end
end

SendNotify("V9 (CROSSHAIR + SCP + HEAL)", "Loaded! (Press Z for Keybinds)")
