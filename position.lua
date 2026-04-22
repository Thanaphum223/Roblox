local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- ถ้ากำลังพิมพ์แชท หรือกด UI อยู่ ให้ข้ามไปเลย (ป้องกันการกด P ตอนพิมพ์แชท)
    if gameProcessed then return end

    -- เช็คว่าปุ่มที่กดคือ P ใช่ไหม
    if input.KeyCode == Enum.KeyCode.P then
        local character = player.Character
        
        -- ตรวจสอบว่าตัวละครโหลดแล้ว และมีชิ้นส่วนหลัก (HumanoidRootPart)
        if character and character:FindFirstChild("HumanoidRootPart") then
            local pos = character.HumanoidRootPart.Position
            
            -- ถ้าอยากได้แบบเอาไปก็อปวางใช้ต่อได้เลย เปิดบรรทัดล่างนี้แทนครับ:
             print(string.format("Vector3.new(%f, %f, %f)", pos.X, pos.Y, pos.Z))
        end
    end
end)
