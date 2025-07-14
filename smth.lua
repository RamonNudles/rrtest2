queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/RamonNudles/rrtest2/refs/heads/index/smth.lua"))()')

-- Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera

-- Local player + mouse
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- Config
local Config = {
    AimbotPart      = "Head",
    FOV             = 600,
    Sensitivity     = 1,
    WalkSpeedValue  = 50,
    InfiniteJump    = true,
    Noclip          = true,
    ShowESP         = true,
    ShowNameTags    = true,
    HPESP           = true,
    ESPTransparency = 0.5,
    BlinkingESP     = false,
    ESPColor        = Color3.fromRGB(214, 0, 255),
}

-- Robust WalkSpeed enforcement
local function enforceSpeed(humanoid)
    if not humanoid then return end
    -- Immediately apply
    humanoid.WalkSpeed = Config.WalkSpeedValue
    -- Snap back if anything else tries to change it
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if humanoid.WalkSpeed ~= Config.WalkSpeedValue then
            humanoid.WalkSpeed = Config.WalkSpeedValue
        end
    end)
end

local function hookCharacter(character)
    local hum = character:WaitForChild("Humanoid", 5)
    enforceSpeed(hum)
end

-- Hook current and future characters
if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- Helpers for aimbot
local function isValid(plr)
    if plr == LocalPlayer then return false end
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getBestTarget()
    local best, bestMag = nil, Config.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValid(plr) and plr.Character then
            local part = plr.Character:FindFirstChild(Config.AimbotPart)
            if part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(Mouse.X, Mouse.Y)
                              - Vector2.new(sp.X, sp.Y)).Magnitude
                    if d < bestMag then
                        best, bestMag = part, d
                    end
                end
            end
        end
    end
    return best
end

-- State
local RightDown = false

-- Track right-mouse
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightDown = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightDown = false
    end
end)

-- Main loop: AimLock only (WalkSpeed is now event-driven)
RunService.RenderStepped:Connect(function()
    if RightDown then
        local targetPart = getBestTarget()
        if targetPart then
            local sp, on = Camera:WorldToViewportPoint(targetPart.Position)
            if on then
                local delta = (Vector2.new(sp.X, sp.Y)
                              - Vector2.new(Mouse.X, Mouse.Y))
                              * Config.Sensitivity
                mousemoverel(delta.X, delta.Y)
            end
        end
    end
end)

-- ─── UPDATED ESP & TRACERS ─────────────────────────────────────────────

local Tracers             = {}
local MAX_TRACER_DISTANCE = 1200

local function GetTracerOrigin()
    local size = Camera.ViewportSize
    return Vector2.new(size.X/2, size.Y)
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

local function CreateNametag(player, char)
    if char:FindFirstChild("ESPNameTag") then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui", char)
    bb.Name        = "ESPNameTag"
    bb.Adornee     = head
    bb.Size        = UDim2.new(0,100,0,20)
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    local label = Instance.new("TextLabel", bb)
    label.Size                   = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Font                   = Enum.Font.SourceSansBold
    label.TextColor3             = Color3.fromRGB(0,255,0)
    label.TextScaled             = false
    label.TextSize               = 30
    if Config.HPESP then
        task.spawn(function()
            while bb.Parent and Config.ShowESP and Config.HPESP do
                local hum = char:FindFirstChildOfClass("Humanoid")
                label.Text = ("%d HP"):format(hum and math.floor(hum.Health) or 0)
                task.wait(0.1)
            end
        end)
    else
        label.Text = player.Name
    end
end

local function RemoveNametag(char)
    local bb = char and char:FindFirstChild("ESPNameTag")
    if bb then bb:Destroy() end
end

local function RefreshESP()
    local origin = GetTracerOrigin()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local alive= root and hum and hum.Health > 0
            if Config.ShowESP and alive then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                if onScreen and dist < MAX_TRACER_DISTANCE then
                    local t = Tracers[player] or CreateTracer()
                    Tracers[player] = t
                    t.Visible = true
                    t.From    = origin
                    t.To      = Vector2.new(pos.X, pos.Y)
                elseif Tracers[player] then
                    Tracers[player].Visible = false
                end
                CreateHighlight(char)
                if Config.ShowNameTags then CreateNametag(player, char) end
            else
                if Tracers[player] then Tracers[player].Visible = false end
                RemoveHighlight(char)
                RemoveNametag(char)
            end
        end
    end
end

local function ClearAllESP()
    for p, tracer in pairs(Tracers) do tracer:Remove() end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character then
            RemoveHighlight(pl.Character)
            RemoveNametag(pl.Character)
        end
    end
    Tracers = {}
end

Players.PlayerRemoving:Connect(function(pl)
    if Tracers[pl] then
        Tracers[pl]:Remove()
        Tracers[pl] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.ShowESP then
        RefreshESP()
    else
        ClearAllESP()
    end
end)

-- Infinite Jump
if Config.InfiniteJump then
    UserInputService.JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

-- Noclip
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

print("haxegon_static loaded: AimLock (RMB), WalkSpeed enforced, InfiniteJump, Noclip, ESP")
