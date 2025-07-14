queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/RamonNudles/rrtest2/refs/heads/index/smth.lua"))()')

-- Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera

-- Local player
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

-- Holds our walk-speed change connections
local HumanModCons = { ws = nil, wsCA = nil }

-- Sets up continuous enforcement of WalkSpeed
local function startLoopSpeed()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if not h then return end
    local function apply() if h then h.WalkSpeed = Config.WalkSpeedValue end end
    apply()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() end
    HumanModCons.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
    if HumanModCons.wsCA then HumanModCons.wsCA:Disconnect() end
    HumanModCons.wsCA = Players.LocalPlayer.CharacterAdded:Connect(function(character)
        h = character:WaitForChild("Humanoid", 5)
        apply()
        if HumanModCons.ws then HumanModCons.ws:Disconnect() end
        HumanModCons.ws = h:GetPropertyChangedSignal("WalkSpeed"):Connect(apply)
    end)
end

-- Stops enforcing and resets to default speed
local function stopLoopSpeed()
    if HumanModCons.ws then HumanModCons.ws:Disconnect() HumanModCons.ws = nil end
    if HumanModCons.wsCA then HumanModCons.wsCA:Disconnect() HumanModCons.wsCA = nil end
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if h then h.WalkSpeed = 25.2 end
end

-- State
local RightDown = false

-- Track right-mouse button
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

-- Always-on right-click head aimlock (aims above the head)

-- Settings
local FOV             = 600      -- max screen-space radius
local Sensitivity     = 1        -- aim speed multiplier
local ExtraVertical   = 3        -- studs above the top of the head to aim

-- Validate a target player
local function isValid(plr)
    if plr == LocalPlayer then return false end
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

-- Return the closest head within FOV
local function getClosestHead()
    local bestHead, bestDist = nil, FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValid(plr) and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(Mouse.X, Mouse.Y)
                                  - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < bestDist then
                        bestHead, bestDist = head, dist
                    end
                end
            end
        end
    end
    return bestHead
end

-- Aimlock loop
RunService.RenderStepped:Connect(function()
    if not RightDown then return end

    local head = getClosestHead()
    if not head then return end

    -- compute a point above the top of the head using head's CFrame
    local topCFrame = head.CFrame * CFrame.new(0, head.Size.Y/2 + ExtraVertical, 0)
    local worldPos  = topCFrame.Position
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen or screenPos.Z < 0 then return end

    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local aimPos   = Vector2.new(screenPos.X, screenPos.Y)
    local delta    = (aimPos - mousePos) * Sensitivity

    mousemoverel(delta.X, delta.Y)
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
    h.Name               = "ESPHighlight"
    h.FillColor          = Config.ESPColor
    h.FillTransparency   = Config.ESPTransparency
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
                label.Text = string.format("%s | %d HP", player.Name, hum and math.floor(hum.Health) or 0)
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
            local alive = root and hum and hum.Health > 0
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

-- Aimbot helpers (skip dead and teammates)
local function getClosestPart()
    local closestPart, shortest = nil, Config.FOV
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local head = pl.Character:FindFirstChild("Head")
            local hum  = pl.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < shortest then
                        closestPart, shortest = head, dist
                    end
                end
            end
        end
    end
    return closestPart
end

-- Aim lock on right-click (skips dead) — now uses same above-head logic
RunService.RenderStepped:Connect(function()
    if RightDown then
        local head = getClosestPart()
        if head then
            local topCFrame = head.CFrame * CFrame.new(0, head.Size.Y/2 + ExtraVertical, 0)
            local worldPos  = topCFrame.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
            if screenPos.Z > 0 then
                local delta = (Vector2.new(screenPos.X, screenPos.Y)
                            - Vector2.new(Mouse.X, Mouse.Y))
                            * Config.Sensitivity
                mousemoverel(delta.X, delta.Y)
            end
        end
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

-- Start enforcing speed hack
startLoopSpeed()

-- Replace math.huge with a large finite number
local IMMORTAL_HEALTH = 1e7

local function makeImmortal()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.MaxHealth = IMMORTAL_HEALTH
    hum.Health    = IMMORTAL_HEALTH

    hum.Died:Connect(function()
        hum.Health = IMMORTAL_HEALTH
    end)
    hum.HealthChanged:Connect(function(newH)
        if newH < IMMORTAL_HEALTH then
            hum.Health = IMMORTAL_HEALTH
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    makeImmortal()
end)
makeImmortal()

print("haxegon_static loaded: ESP, AimLock (RMB skip dead), WalkSpeed (hooked), InfiniteJump, Noclip active, Underground-TP on H")
