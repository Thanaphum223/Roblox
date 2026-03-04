local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local Humanoid = char:WaitForChild("Humanoid")
local animator = Humanoid:WaitForChild("Animator")

-- [ ID ท่า Gojo Walk ]
local EMOTE_ID = "77984099336391" 

local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://" .. EMOTE_ID

-- โหลดท่าเต้นเตรียมไว้ในตัวละคร (แต่ยังไม่เล่น)
local emoteTrack = animator:LoadAnimation(anim)
emoteTrack.Priority = Enum.AnimationPriority.Action 

-- แจ้งเตือนว่าสคริปต์พร้อมใช้งาน
StarterGui:SetCore("SendNotification", {
    Title = "SYSTEM READY ⚙️",
    Text = "รันสคริปต์สำเร็จ! กดปุ่ม P เพื่อ เปิด/ปิด Gojo Walk",
    Duration = 5,
})

-- ระบบตรวจจับการกดปุ่มบนคีย์บอร์ด
UserInputService.InputBegan:Connect(function(input, isTyping)
    -- ถ้ากำลังพิมพ์แชทอยู่ ให้ข้ามไปเลย จะได้ไม่ลั่นตอนพิมพ์ตัว P
    if isTyping then return end 

    -- ตรวจจับว่ากดปุ่ม P หรือไม่
    if input.KeyCode == Enum.KeyCode.P then
        
        -- เช็คสถานะ: ท่าเต้นกำลังเล่นอยู่ไหม?
        if emoteTrack.IsPlaying then
            -- ถ้าเล่นอยู่ -> สั่งหยุด (ตัวละครจะกลับไปใช้ท่าเดินปกติเอง)
            emoteTrack:Stop() 
            
            StarterGui:SetCore("SendNotification", {
                Title = "REVERTED",
                Text = "ปิด Gojo Walk (กลับสู่ท่าปกติ)",
                Duration = 2,
            })
        else
            -- ถ้าไม่ได้เล่นอยู่ -> สั่งเปิดท่าเต้น
            emoteTrack:Play()
            
            StarterGui:SetCore("SendNotification", {
                Title = "DOMAIN EXPANSION 🤞",
                Text = "เปิด Gojo Walk!",
                Duration = 2,
            })
        end
        
    end
end)
