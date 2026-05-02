local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

-- แจ้งเตือนตอนรันสคริปต์
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "System 🟢",
        Text = "Anti-AFK อัปเกรดโหลดสำเร็จ ปล่อยจอได้เลย!",
        Duration = 5
    })
end)

-- วิธีที่ 1: พยายามปิดระบบ Idled ทิ้งอย่างถาวร (สำหรับ Executor ที่รองรับ)
local connectionSuccess = pcall(function()
    for _, connection in pairs(getconnections(Players.LocalPlayer.Idled)) do
        connection:Disable()
    end
end)

-- วิธีที่ 2: ถ้าระบบด้านบนล้มเหลว ให้ใช้วิธีขยับเมาส์แบบเสถียรแทน
if not connectionSuccess then
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        -- จำลองการกดคลิกขวาค้างไว้และปล่อย (เสถียรกว่าตอนพับจอ)
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Anti-AFK 🛡️",
                Text = "ระบบป้องกันการโดนเตะทำงานแล้ว!",
                Duration = 3
            })
        end)
    end)
end
