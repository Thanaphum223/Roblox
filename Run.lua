local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local Animate = char:WaitForChild("Animate")
local Humanoid = char:WaitForChild("Humanoid")
local StarterGui = game:GetService("StarterGui")

-- [[ ขั้นตอนที่ 1: แจ้งเตือนให้กด EMOTE ]] --
StarterGui:SetCore("SendNotification", {
    Title = "⚠️ ACTION REQUIRED",
    Text = "(รอ 3 วินาที)",
    Duration = 3,
})

-- รอ 3 วินาที (ช่วงนี้ให้รีบกดเต้น เพื่อแก้บัคท่าแข็ง)
task.wait(3)

-- [[ ขั้นตอนที่ 2: ล้างอนิเมชั่นเดิม (Animation Remover) ]] --
if Animate then
    pcall(function()
        Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
        Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
        Humanoid.Jump = false
    end)
end

-- เว้นจังหวะนิดนึงเพื่อให้ระบบล้างค่าเก่าออก
task.wait(0.2)

-- [[ ขั้นตอนที่ 3: ใส่ท่าเดินใหม่ (I wanna run away) ]] --
if Animate then
    pcall(function()
        Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=76459424967458"
        Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=76459424967458"
        Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=121480327509940"
        Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=110698328520019"
        Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=76459424967458"
        Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=76459424967458"
        Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=76459424967458"
        Humanoid.Jump = false
    end)
    
    StarterGui:SetCore("SendNotification", {
        Title = "SUCCESS",
        Text = "โหลดท่าเดิน Sad Walk เรียบร้อย!",
        Duration = 3,
    })
end
