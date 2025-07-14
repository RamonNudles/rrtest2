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

-- ──────────── WalkSpeed Enforcement & Permanent Fly ────────────

local function enforceSpeed(h)
    if not h then return end
    h.WalkSpeed = Config.WalkSpeedValue
    h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if h.WalkSpeed ~= Config.WalkSpeedValue then
            h.WalkSpeed = Config.WalkSpeedValue
        end
    end)
end

local function hookCharacter(char)
    -- WalkSpeed
    local h = char:WaitForChild("Humanoid",5)
    enforceSpeed(h)

    -- Permanent Fly
    local hrp = char:WaitForChild("HumanoidRootPart",5)
    for _,c in ipairs({"FlyGyro","FlyVelocity"}) do
        local old = hrp:FindFirstChild(c)
        if old then old:Destroy() end
    end

    local gyro = Instance.new("BodyGyro", hrp)
    gyro.Name      = "FlyGyro"
    gyro.MaxTorque = Vector3.new(1,1,1)*math.huge
    gyro.P         = 100000

    local vel = Instance.new("BodyVelocity", hrp)
    vel.Name      = "FlyVelocity"
    vel.MaxForce  = Vector3.new(1,1,1)*math.huge
    vel.P         = 10000
    vel.Velocity  = Vector3.zero

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

        vel.Velocity = (move.Magnitude>0) and move.Unit*Config.FlySpeed or Vector3.zero
        gyro.CFrame  = Camera.CFrame
    end)
end

if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- ──────────── AimLock + TriggerBot ────────────

local RightDown    = false
local lockedPart   = nil

UserInputService.InputBegan:Connect(function(i,p)
    if not p and i.UserInputType==Enum.UserInputType.MouseButton2 then
        RightDown = true
        VirtualUser:CaptureController()  -- for click simulation
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton2 then
        RightDown = false
        lockedPart = nil
    end
end)

local function isValid(pl)
    if pl==LocalPlayer then return false end
    local c,h = pl.Character, pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health>0
end

local function pickTarget()
    local best,bd = nil, Config.FOV
    for _,pl in ipairs(Players:GetPlayers()) do
        if isValid(pl) and pl.Character then
            local part = pl.Character:FindFirstChild(Config.AimbotPart)
            if part then
                local sp,on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(Mouse.X,Mouse.Y)-Vector2.new(sp.X,sp.Y)).Magnitude
                    if d<bd then best,bd = part,d end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if RightDown then
        if not lockedPart then
            lockedPart = pickTarget()
        end
        if lockedPart and lockedPart.Parent then
            local sp,on = Camera:WorldToViewportPoint(lockedPart.Position)
            if on then
                local delta = (Vector2.new(sp.X,sp.Y)-Vector2.new(Mouse.X,Mouse.Y))*Config.Sensitivity
                mousemoverel(delta.X, delta.Y)
                -- TriggerBot via VirtualUser
                VirtualUser:Button1Down(Enum.UserInputType.MouseButton1)
                VirtualUser:Button1Up(Enum.UserInputType.MouseButton1)
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
    local L = Drawing.new("Line")
    L.Visible      = false
    L.Color        = Config.ESPColor
    L.Thickness    = 2
    L.Transparency = 1
    return L
end

local function CreateHighlight(c)
    if c:FindFirstChild("ESPHighlight") then return end
    local h = Instance.new("Highlight", c)
    h.Name               = "ESPHighlight"
    h.FillColor          = Config.ESPColor
    h.FillTransparency   = Config.ESPTransparency
    h.OutlineTransparency= 1
end

local function RemoveHighlight(c)
    local h = c and c:FindFirstChild("ESPHighlight")
    if h then h:Destroy() end
end

local function CreateNametag(plr,c)
    if c:FindFirstChild("ESPNameTag") then return end
    local head = c:FindFirstChild("Head") if not head then return end
    local bb = Instance.new("BillboardGui",c)
    bb.Name, bb.Adornee, bb.Size, bb.StudsOffset, bb.AlwaysOnTop =
      "ESPNameTag", head, UDim2.new(0,100,0,20), Vector3.new(0,2.5,0), true
    local lbl = Instance.new("TextLabel",bb)
    lbl.Size, lbl.BackgroundTransparency, lbl.Font, lbl.TextColor3, lbl.TextScaled, lbl.TextSize =
      UDim2.fromScale(1,1), 1, Enum.Font.SourceSansBold, Color3.new(0,1,0), false, 30
    if Config.HPESP then
      task.spawn(function()
        while bb.Parent and Config.ShowESP and Config.HPESP do
          local h = c:FindFirstChildOfClass("Humanoid")
          lbl.Text = ("%s | %d HP"):format(plr.Name, h and math.floor(h.Health) or 0)
          task.wait(0.1)
        end
      end)
    else
      lbl.Text = plr.Name
    end
end

local function RemoveNametag(c)
    local bb = c and c:FindFirstChild("ESPNameTag")
    if bb then bb:Destroy() end
end

local function RefreshESP()
    local origin = GetTracerOrigin()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LocalPlayer then
            local c = pl.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            local h    = c and c:FindFirstChildOfClass("Humanoid")
            local alive= root and h and h.Health>0
            if Config.ShowESP and alive then
                local pos,on = Camera:WorldToViewportPoint(root.Position)
                local dist = (root.Position-Camera.CFrame.Position).Magnitude
                if on and dist<MAX_TRACER_DISTANCE then
                    local t = Tracers[pl] or CreateTracer()
                    Tracers[pl]=t; t.Visible=true; t.From=origin; t.To=Vector2.new(pos.X,pos.Y)
                elseif Tracers[pl] then
                    Tracers[pl].Visible=false
                end
                CreateHighlight(c)
                if Config.ShowNameTags then CreateNametag(pl,c) end
            else
                if Tracers[pl] then Tracers[pl].Visible=false end
                RemoveHighlight(c)
                RemoveNametag(c)
            end
        end
    end
end

local function ClearAllESP()
    for pl,t in pairs(Tracers) do t:Remove() end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl.Character then
            RemoveHighlight(pl.Character)
            RemoveNametag(pl.Character)
        end
    end
    Tracers = {}
end

Players.PlayerRemoving:Connect(function(pl)
    if Tracers[pl] then Tracers[pl]:Remove(); Tracers[pl]=nil end
end)

RunService.RenderStepped:Connect(function()
    if Config.ShowESP then RefreshESP() else ClearAllESP() end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local c = LocalPlayer.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end
end)

-- ──────────── Teleport Behind Enemy (toggle “O”) ────────────

local behindToggle = false

UserInputService.InputBegan:Connect(function(i,p)
    if p then return end
    if i.KeyCode==Enum.KeyCode.O then
        behindToggle = not behindToggle
        if not behindToggle then lockedPart=nil end
    end
end)

spawn(function()
    while true do
        if behindToggle then
            -- try ReplicatedStorage path first
            local models = (ReplicatedStorage.Assets.Temp.ViewModels and ReplicatedStorage.Assets.Temp.ViewModels:GetChildren())
                        or (workspace.Temp.ViewModels and workspace.Temp.ViewModels:GetChildren())
                        or {}
            if #models==0 then
                -- fallback: scan workspace for “- ViewModel” suffix
                for _,m in ipairs(workspace:GetDescendants()) do
                    if m:IsA("Model") and m.Name:find(" %- ViewModel") then
                        table.insert(models,m)
                    end
                end
            end

            local seen = {}
            for _,m in ipairs(models) do
                local nm = m.Name:gsub(" %- .*","")
                if nm~=LocalPlayer.Name then seen[nm]=true end
            end

            for nm,_ in pairs(seen) do
                local pl = Players:FindFirstChild(nm)
                if pl and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local hrpE = pl.Character.HumanoidRootPart
                    local h    = pl.Character:FindFirstChildOfClass("Humanoid")
                    if h and h.Health>0 then
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            local back = hrpE.Position - hrpE.CFrame.LookVector*3
                            myHRP.CFrame = CFrame.new(back, hrpE.Position)
                            lockedPart = pl.Character:FindFirstChild(Config.AimbotPart)
                        end
                    end
                    break
                end
            end
        end
        task.wait(0.01)
    end
end)

print("haxegon_static loaded: AimLock+TriggerBot, WalkSpeed, Fly ON, Noclip, ESP, Teleport-Behind [O]")
