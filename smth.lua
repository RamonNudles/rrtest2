queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/RamonNudles/rrtest2/refs/heads/index/smth.lua"))()')

-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- ──────────── WalkSpeed Enforcement & Permanent Fly ────────────

local function enforceSpeed(humanoid)
    if not humanoid then return end
    humanoid.WalkSpeed = Config.WalkSpeedValue
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if humanoid.WalkSpeed ~= Config.WalkSpeedValue then
            humanoid.WalkSpeed = Config.WalkSpeedValue
        end
    end)
end

local function hookCharacter(character)
    -- WalkSpeed
    local hum = character:WaitForChild("Humanoid", 5)
    enforceSpeed(hum)

    -- Fly (always on)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
    if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end

    local gyro = Instance.new("BodyGyro")
    gyro.Name      = "FlyGyro"
    gyro.MaxTorque = Vector3.new(1,1,1) * math.huge
    gyro.P         = 100000
    gyro.CFrame    = hrp.CFrame
    gyro.Parent    = hrp

    local vel = Instance.new("BodyVelocity")
    vel.Name      = "FlyVelocity"
    vel.MaxForce  = Vector3.new(1,1,1) * math.huge
    vel.P         = 10000
    vel.Velocity  = Vector3.zero
    vel.Parent    = hrp

    RunService.RenderStepped:Connect(function()
        if UserInputService:GetFocusedTextBox() then
            vel.Velocity = Vector3.zero
            return
        end
        if not hrp.Parent then return end

        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

        if move.Magnitude > 0 then
            vel.Velocity = move.Unit * Config.FlySpeed
        else
            vel.Velocity = Vector3.zero
        end
        gyro.CFrame = Camera.CFrame
    end)
end

-- Hook current and future characters
if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- ──────────── AimLock ────────────

local RightDown = false
UserInputService.InputBegan:Connect(function(inp, processed)
    if not processed and inp.UserInputType == Enum.UserInputType.MouseButton2 then
        RightDown = true
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        RightDown = false
    end
end)

local function isValid(plr)
    if plr == LocalPlayer then return false end
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getBestTarget()
    local best, bestDist = nil, Config.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValid(plr) and plr.Character then
            local part = plr.Character:FindFirstChild(Config.AimbotPart)
            if part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(Mouse.X,Mouse.Y) - Vector2.new(sp.X,sp.Y)).Magnitude
                    if d < bestDist then
                        best, bestDist = part, d
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if RightDown then
        local tgt = getBestTarget()
        if tgt then
            local sp, on = Camera:WorldToViewportPoint(tgt.Position)
            if on then
                local delta = (Vector2.new(sp.X,sp.Y) - Vector2.new(Mouse.X,Mouse.Y)) * Config.Sensitivity
                mousemoverel(delta.X, delta.Y)
            end
        end
    end
end)

-- ──────────── ESP & Tracers & Noclip ────────────

local Tracers             = {}
local MAX_TRACER_DISTANCE = 1200

local function GetTracerOrigin()
    local sz = Camera.ViewportSize
    return Vector2.new(sz.X/2, sz.Y)
end

local function CreateTracer()
    local line = Drawing.new("Line")
    line.Visible      = false
    line.Color        = Config.ESPColor
    line.Thickness    = 2
    line.Transparency = 1
    return line
end

local function CreateHighlight(char)
    if char:FindFirstChild("ESPHighlight") then return end
    local h = Instance.new("Highlight", char)
    h.Name                = "ESPHighlight"
    h.FillColor           = Config.ESPColor
    h.FillTransparency    = Config.ESPTransparency
    h.OutlineTransparency = 1
end

local function RemoveHighlight(char)
    local h = char and char:FindFirstChild("ESPHighlight")
    if h then h:Destroy() end
end

local function CreateNametag(plr, char)
    if char:FindFirstChild("ESPNameTag") then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui", char)
    bb.Name        = "ESPNameTag"
    bb.Adornee     = head
    bb.Size        = UDim2.new(0,100,0,20)
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size                   = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.TextColor3             = Color3.new(0,1,0)
    lbl.TextScaled             = false
    lbl.TextSize               = 30
    if Config.HPESP then
        task.spawn(function()
            while bb.Parent and Config.ShowESP and Config.HPESP do
                local h = char:FindFirstChildOfClass("Humanoid")
                lbl.Text = ("%s | %d HP"):format(plr.Name, h and math.floor(h.Health) or 0)
                task.wait(0.1)
            end
        end)
    else
        lbl.Text = plr.Name
    end
end

local function RemoveNametag(char)
    local bb = char and char:FindFirstChild("ESPNameTag")
    if bb then bb:Destroy() end
end

local function RefreshESP()
    local origin = GetTracerOrigin()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local alive= root and hum and hum.Health > 0
            if Config.ShowESP and alive then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                if on and dist < MAX_TRACER_DISTANCE then
                    local t = Tracers[plr] or CreateTracer()
                    Tracers[plr] = t
                    t.Visible = true
                    t.From    = origin
                    t.To      = Vector2.new(pos.X, pos.Y)
                elseif Tracers[plr] then
                    Tracers[plr].Visible = false
                end
                CreateHighlight(char)
                if Config.ShowNameTags then CreateNametag(plr, char) end
            else
                if Tracers[plr] then Tracers[plr].Visible = false end
                RemoveHighlight(char)
                RemoveNametag(char)
            end
        end
    end
end

local function ClearAllESP()
    for p, t in pairs(Tracers) do t:Remove() end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            RemoveHighlight(plr.Character)
            RemoveNametag(plr.Character)
        end
    end
    Tracers = {}
end

Players.PlayerRemoving:Connect(function(plr)
    if Tracers[plr] then
        Tracers[plr]:Remove()
        Tracers[plr] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.ShowESP then
        RefreshESP()
    else
        ClearAllESP()
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ──────────── Teleport Behind Enemy (toggle with O) ────────────

local behindToggle = false
UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.KeyCode == Enum.KeyCode.O then
        behindToggle = not behindToggle
    end
end)

spawn(function()
    while true do
        if behindToggle then
            local models = ReplicatedStorage.Assets.Temp.ViewModels:GetChildren()
            local seen   = {}
            for _, m in ipairs(models) do
                local nm = m.Name:gsub(" %- .*","")
                if nm ~= LocalPlayer.Name then
                    seen[nm] = true
                end
            end
            for nm, _ in pairs(seen) do
                local pl = Players:FindFirstChild(nm)
                if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local hrpE = pl.Character.HumanoidRootPart
                    if pl.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            local back = hrpE.Position - hrpE.CFrame.LookVector * 3
                            myHRP.CFrame = CFrame.new(back, hrpE.Position)
                        end
                    end
                end
                break
            end
        end
        task.wait(0.01)
    end
end)

print("haxegon_static loaded: AimLock, WalkSpeed, Fly always on, Noclip, ESP, Teleport-Behind [O]")
