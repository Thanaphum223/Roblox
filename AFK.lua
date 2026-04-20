local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

-- เมื่อเกมตรวจพบว่าเราไม่ได้ขยับตัว (Idled)
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new()) -- จำลองการคลิกเมาส์ขวา
    
    -- แจ้งเตือนเพื่อให้รู้ว่าระบบกัน AFK ทำงานแล้ว
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Anti-AFK 🛡️",
            Text = "ระบบป้องกันการโดนเตะทำงานแล้ว!",
            Duration = 3
        })
    end)
end)

-- แจ้งเตือนตอนรันสคริปต์ครั้งแรก
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "System 🟢",
        Text = "Anti-AFK Script โหลดสำเร็จ สามารถปล่อยจอได้เลย!",
        Duration = 5
    })
end)
