queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/RamonNudles/rrtest2/refs/heads/index/smth.lua"))()')

-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")

-- Local player + mouse
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- Config
local Config = {
    AimbotPart      = "Head",
    FOV             = 600,
    Sensitivity     = 1,
    WalkSpeedValue  = 50,
    FlySpeed        = 80,       -- permanent fly speed
    Noclip          = true,
    ShowESP         = true,
    ShowNameTags    = true,
    HPESP           = true,
    ESPTransparency = 0.5,
    ESPColor        = Color3.fromRGB(214, 0, 255),
}

-- … (walkspeed / fly / aimlock / ESP code unchanged) …

-- ──────────── Teleport Behind Enemy (toggle “O”) ────────────

local behindToggle = false
local lockedPart   = nil

UserInputService.InputBegan:Connect(function(i,p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.O then
        behindToggle = not behindToggle
        -- clear any old target when toggling off
        if not behindToggle then
            lockedPart = nil
        end
    end
end)

spawn(function()
    while true do
        if behindToggle then
            -- gather all ViewModels (works in both maps)
            local models = {}
            if ReplicatedStorage:FindFirstChild("Assets")
            and ReplicatedStorage.Assets:FindFirstChild("Temp")
            and ReplicatedStorage.Assets.Temp:FindFirstChild("ViewModels") then
                models = ReplicatedStorage.Assets.Temp.ViewModels:GetChildren()
            elseif workspace:FindFirstChild("Temp")
            and workspace.Temp:FindFirstChild("ViewModels") then
                models = workspace.Temp.ViewModels:GetChildren()
            else
                -- fallback: any model named "* - ViewModel"
                for _,m in ipairs(workspace:GetDescendants()) do
                    if m:IsA("Model") and m.Name:find(" %- ViewModel") then
                        table.insert(models, m)
                    end
                end
            end

            -- map of alive opponents
            local seen = {}
            for _,m in ipairs(models) do
                local nm = m.Name:gsub(" %- .*","")
                if nm ~= LocalPlayer.Name then
                    seen[nm] = true
                end
            end

            local found = false
            for nm,_ in pairs(seen) do
                local pl = Players:FindFirstChild(nm)
                if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local hrpE = pl.Character.HumanoidRootPart
                    local h    = pl.Character:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            -- teleport 3 studs behind with no vertical offset
                            local back = hrpE.Position - hrpE.CFrame.LookVector * 3
                            myHRP.CFrame = CFrame.new(back, hrpE.Position)
                            lockedPart = pl.Character:FindFirstChild(Config.AimbotPart)

                            -- **watch for death** and clear lockedPart when they die
                            h.Died:Connect(function()
                                if lockedPart and lockedPart.Parent == pl.Character then
                                    lockedPart = nil
                                end
                            end)

                            found = true
                        end
                    end
                end
                if found then
                    -- **remove the old break** so we stay in loop next tick
                    break
                end
            end
        end
        task.wait(0.01)
    end
end)

print("haxegon_static loaded: AimLock+TriggerBot, WalkSpeed, Fly ON, Noclip, ESP, Teleport-Behind [O]")
