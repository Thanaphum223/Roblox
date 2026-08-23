-- ==========================================
-- TTK TESTING: ESP SYSTEM ONLY (FIXED LOAD)
-- ==========================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. ESP SYSTEM & CLEANUP
-- ==========================================
local ESP_Holder = Instance.new("Folder")
ESP_Holder.Name = "TTK_ESP_Storage"
ESP_Holder.Parent = CoreGui

local playerConnections = {}

local function cleanupPlayerConnections(player)
    if playerConnections[player] then
        for _, conn in ipairs(playerConnections[player]) do
            conn:Disconnect()
        end
        playerConnections[player] = nil
    end
end

local function getTargetPart(character)
    return character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("Head") 
        or character:FindFirstChildWhichIsA("BasePart")
end

local function createESP(player)
    if player == LocalPlayer then return end

    local function applyESP(character)
        if not character then return end

        -- รอให้ RootPart หรือ Head โหลดเสร็จจริง ๆ สูงสุด 3 วินาที (ไม่พึ่งเวลาสุ่ม)
        local targetPart = character:WaitForChild("HumanoidRootPart", 3) or getTargetPart(character)
        if not targetPart then return end

        local cleanName = player.Name .. "_ESP"
        local oldESP = ESP_Holder:FindFirstChild(cleanName)
        if oldESP then oldESP:Destroy() end
        cleanupPlayerConnections(player)

        local container = Instance.new("Folder")
        container.Name = cleanName
        container.Parent = ESP_Holder

        -- Chams / Highlight
        local highlight = Instance.new("Highlight")
        highlight.Adornee = character
        highlight.FillColor = Color3.fromRGB(255, 45, 45)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = container

        -- ป้ายชื่อบนตัวละคร
        local bg = Instance.new("BillboardGui")
        bg.Adornee = targetPart
        bg.Size = UDim2.new(0, 200, 0, 65)
        bg.StudsOffset = Vector3.new(0, 8.0, 0)
        bg.AlwaysOnTop = true
        bg.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextStrokeTransparency = 0
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.Parent = bg

        local function updateInfo()
            if not character or not character.Parent then
                container:Destroy()
                cleanupPlayerConnections(player)
                return
            end

            local inWorld = player:GetAttribute("InWorld")
            local weapon = player:GetAttribute("CurrentWeapon")
            local flash = player:GetAttribute("ThrowableAmmo_Flashbang") or 0
            local kills = player:GetAttribute("Kills") or 0
            local deaths = player:GetAttribute("Deaths") or 0
            local team = player:GetAttribute("Team")

            if weapon == "" or not weapon then weapon = "Holstered" end

            -- ตรวจสอบ: ถ้า InWorld ระบุชัดเจนว่าเป็น false ถึงจะถือว่าตาย / กำลังเกิด
            local isDead = (inWorld == false)
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                isDead = true
            end

            if isDead then
                label.TextColor3 = Color3.fromRGB(150, 150, 150)
                label.Text = string.format("[%s]\n[Dead / Spawning]", player.Name)
                highlight.Enabled = false
            else
                local myTeam = LocalPlayer:GetAttribute("Team")
                if team and myTeam and team == myTeam then
                    label.TextColor3 = Color3.fromRGB(0, 255, 120)
                    highlight.FillColor = Color3.fromRGB(0, 255, 120)
                else
                    label.TextColor3 = Color3.fromRGB(255, 60, 60)
                    highlight.FillColor = Color3.fromRGB(255, 45, 45)
                end

                highlight.Enabled = true
                label.Text = string.format("[%s]\nGun: %s | Flash: %d\nK: %d | D: %d", player.Name, tostring(weapon), flash, kills, deaths)
            end
        end

        playerConnections[player] = {
            player:GetAttributeChangedSignal("CurrentWeapon"):Connect(updateInfo),
            player:GetAttributeChangedSignal("ThrowableAmmo_Flashbang"):Connect(updateInfo),
            player:GetAttributeChangedSignal("InWorld"):Connect(updateInfo),
            player:GetAttributeChangedSignal("Kills"):Connect(updateInfo),
            player:GetAttributeChangedSignal("Deaths"):Connect(updateInfo),
            player:GetAttributeChangedSignal("Team"):Connect(updateInfo)
        }
        
        -- อัปเดตข้อมูลทันทีที่สร้างเสร็จ
        updateInfo()
    end

    if player.Character and player.Character.Parent then
        task.spawn(applyESP, player.Character)
    end
    player.CharacterAdded:Connect(applyESP)
end

-- สร้าง ESP ให้กับทุกคนที่อยู่ในเซิร์ฟเวอร์ทันทีที่รันสคริปต์
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(createESP, p)
end
Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(p)
    local esp = ESP_Holder:FindFirstChild(p.Name .. "_ESP")
    if esp then esp:Destroy() end
    cleanupPlayerConnections(p)
end)
