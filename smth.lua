-- BEGIN SCRIPT ONE (Anti Chat & Screenshot Logger)
if not game:IsLoaded() then
    game.Loaded:Wait()
end
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

print("Loading Vadrift's Anti Chat & Screenshot Logger..")

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    local startTime = tick()
    task.wait(0.21)
    local function showNotification(title, description, imageId)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title;
                Text = description;
                Icon = imageId;
                Duration = 15;
            })
        end)
    end

    if _G.VadriftsACLLoaded then
        showNotification("Vadrifts ACL", "Anti Chat & Screenshot Logger already loaded!", "rbxassetid://2541869220")
        print("Anti Chat Logger already loaded!")
        return
    end
    _G.VadriftsACLLoaded = true

    showNotification("Vadrifts ACL", string.format("Anti Chat & Screenshot Logger Loaded in %.2fs!", tick() - startTime), "rbxassetid://2541869220")
    print(string.format("Semi Anti Chat Logger successfully loaded in %.2f seconds!", tick() - startTime))

    if setfflag then
        pcall(function()
            setfflag("AbuseReportScreenshot", "False")
            setfflag("AbuseReportScreenshotPercentage", "0")
        end) --anti screenshot logger
    end

    --anti chat logger code
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    local spamText = "/e cheer"
    local isPlayingEmote = false
    local useTextMethod = false
    local hasCharacterWithHumanoid = false

    if not _G.VadriftsACLConnections then
        _G.VadriftsACLConnections = {}
    end

    local function checkCharacterType()
        local char = lp.Character
        if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChild("Animate") then
            hasCharacterWithHumanoid = true
        else
            hasCharacterWithHumanoid = false
        end
    end

    local function getIdleAnimationId()
        local char = lp.Character
        if not char then return nil end
        local animate = char:FindFirstChild("Animate")
        if not animate then return nil end
        local idle = animate:FindFirstChild("idle")
        if not idle then return nil end
        local idleAnim1 = idle:FindFirstChild("Animation1")
        if idleAnim1 and idleAnim1:IsA("Animation") then
            return idleAnim1.AnimationId
        end
        local idleAnim2 = idle:FindFirstChild("Animation2")
        if idleAnim2 and idleAnim2:IsA("Animation") then
            return idleAnim2.AnimationId
        end
        return nil
    end

    local function isEmoteAnimation(animationTrack)
        local char = lp.Character
        if not char then return false end
        local animate = char:FindFirstChild("Animate")
        if not animate then return false end
        
        local animId = animationTrack.Animation.AnimationId
        
        local defaultAnimations = {
            "idle", "walk", "run", "jump", "fall", "climb", "sit", "swimidle", "swim"
        }
        
        for _, animType in pairs(defaultAnimations) do
            local animFolder = animate:FindFirstChild(animType)
            if animFolder then
                for _, child in pairs(animFolder:GetChildren()) do
                    if child:IsA("Animation") and child.AnimationId == animId then
                        return false
                    end
                end
            end
        end
        
        local toolFolder = animate:FindFirstChild("toolnone")
        if toolFolder then
            for _, child in pairs(toolFolder:GetChildren()) do
                if child:IsA("Animation") and child.AnimationId == animId then
                    return false
                end
            end
        end
        
        return true
    end

    local function setupEmoteDetection(character)
        local humanoid = character:WaitForChild("Humanoid")
        if humanoid then
            humanoid.AnimationPlayed:Connect(function(animationTrack)
                if isEmoteAnimation(animationTrack) then
                    isPlayingEmote = true
                    useTextMethod = true
                    
                    animationTrack.Stopped:Connect(function()
                        isPlayingEmote = false
                        useTextMethod = false
                    end)
                end
            end)
        end
    end

    lp.CharacterAdded:Connect(function(character)
        checkCharacterType()
        isPlayingEmote = false
        useTextMethod = false
        setupEmoteDetection(character)
    end)
    
    if lp.Character then
        checkCharacterType()
        setupEmoteDetection(lp.Character)
    end

    task.spawn(function()
        while _G.VadriftsACLLoaded do
            if hasCharacterWithHumanoid and not useTextMethod then
                pcall(function()
                    local char = lp.Character
                    if not char then return end
                    local animate = char:FindFirstChild("Animate")
                    if not animate then return end
                    local cheer = animate:FindFirstChild("cheer")
                    if not cheer then return end
                    local cheerAnim = cheer:FindFirstChild("CheerAnim")
                    if not cheerAnim or not cheerAnim:IsA("Animation") then return end
                    local idleAnimId = getIdleAnimationId()
                    if idleAnimId and cheerAnim.AnimationId ~= idleAnimId then
                        cheerAnim.AnimationId = idleAnimId
                    end
                end)
            end
            task.wait(0.1)
        end
    end)

    local function AntiChatLog(message)
        if message:sub(1, 1) == "/" then
            return message
        else
            return "ּ" .. message
        end
    end

    local function setupChatHook()
        if hasCharacterWithHumanoid then
            local chatBar
            local chat = playerGui:FindFirstChild("Chat")
            if chat then
                chatBar = chat:FindFirstChild("ChatBar", true)
            end
            if not chatBar then
                local container = CoreGui:FindFirstChild("TextBoxContainer", true)
                if container then
                    chatBar = container:FindFirstChild("TextBox")
                end
            end
            if not chatBar then
                warn("Could not find chat bar.")
                return
            end
            local connection = chatBar.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local message = chatBar.Text
                    
                    if useTextMethod then
                        chatBar.Text = ""
                        if message and message ~= "" then
                            local modifiedMessage = AntiChatLog(message)
                            if channel then
                                channel:SendAsync(modifiedMessage)
                            end
                        end
                    end
                end
            end)
            table.insert(_G.VadriftsACLConnections, connection)
        else
            local ChatBar
            local function findChatBar()
                local textBoxContainer = CoreGui:FindFirstChild("TextBoxContainer", true)
                if textBoxContainer then
                    return textBoxContainer:FindFirstChild("TextBox") or textBoxContainer
                end
                return nil
            end
            
            ChatBar = findChatBar()
            
            if ChatBar then
                local success, err = pcall(function()
                    for _, c in pairs(getconnections(ChatBar.FocusLost)) do
                        c:Disconnect()
                    end
                end)
                
                local connection = ChatBar.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        local message = ChatBar.Text
                        ChatBar.Text = ""
                        
                        if message and message ~= "" then
                            local modifiedMessage = AntiChatLog(message)
                            local Channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                            if Channel then
                                Channel:SendAsync(modifiedMessage)
                            end
                        end
                    end
                end)
                table.insert(_G.VadriftsACLConnections, connection)
            else
                warn("Could not find ChatBar")
            end
        end
    end

    setupChatHook()

    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not hasCharacterWithHumanoid or useTextMethod then return end
        pcall(function()
            if channel then
                channel:SendAsync(spamText)
            end
        end)
    end)
    table.insert(_G.VadriftsACLConnections, heartbeatConnection)

    local renderSteppedConnection = RunService.RenderStepped:Connect(function()
        if not hasCharacterWithHumanoid or useTextMethod then return end
        pcall(function()
            if channel then
                channel:SendAsync(spamText)
            end
        end)
    end)
    table.insert(_G.VadriftsACLConnections, renderSteppedConnection)

    task.spawn(function()
        local sayRemote = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
        while _G.VadriftsACLLoaded do
            if hasCharacterWithHumanoid and sayRemote and not useTextMethod then
                pcall(function()
                    sayRemote:FireServer(spamText, "All")
                end)
            end
            task.wait(0.04)
        end
    end)

    task.spawn(function()
        local emoteErr = '<font color="#f74b52">You can\'t use Emotes here.</font>'
        local function onDescendantAdded(obj)
            if not _G.VadriftsACLLoaded then return end
            if obj:IsA("TextLabel") and obj.Text == emoteErr then
                if hasCharacterWithHumanoid and not useTextMethod then
                    local msg = obj:FindFirstAncestor("TextMessage")
                    if msg then
                        msg:Destroy()
                    end
                end
            end
        end

        for _, obj in ipairs(CoreGui:GetDescendants()) do
            onDescendantAdded(obj)
        end
        CoreGui.DescendantAdded:Connect(onDescendantAdded)
    end)
else
    if not pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/vqmpjayZ/More-Scripts/main/Anthony's%20ACL"))()
    end) then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/vqmpjayZ/More-Scripts/main/Anthony's%20ACL"))()
    end
    print("Anti Chat & Screenshot Logger Loaded!")
end

task.spawn(function()
    repeat
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        task.wait()
    until StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
end)

task.spawn(function()
    task.wait(5)
    print("https://dsc.gg/vadriftz")
end)
-- END SCRIPT ONE


-- BEGIN SCRIPT TWO (AimLock / Fly / ESP / Teleport-Behind)
queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/RamonNudles/rrtest2/refs/heads/index/smth.lua"))()')

-- Services
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Camera             = workspace.CurrentCamera
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

-- Local player + mouse
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- Config
local Config = {
    AimbotPart      = "Head",
    FOV             = 600,
    Sensitivity     = 1,
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

-- ─── WalkSpeed Enforcement & Permanent Fly ─────────────────────────────────
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
    local h = char:WaitForChild("Humanoid", 5)
    enforceSpeed(h)

    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    -- clean up any old fly parts
    if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
    if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end

    local gyro = Instance.new("BodyGyro", hrp)
    gyro.Name      = "FlyGyro"
    gyro.MaxTorque = Vector3.new(1,1,1) * math.huge
    gyro.P         = 100000

    local vel = Instance.new("BodyVelocity", hrp)
    vel.Name       = "FlyVelocity"
    vel.MaxForce   = Vector3.new(1,1,1) * math.huge
    vel.P          = 10000
    vel.Velocity   = Vector3.zero

    RunService.RenderStepped:Connect(function()
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

if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- ─── AimLock Only ──────────────────────────────────────────────────────────

local behindToggle = false
local RightDown    = false

UserInputService.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        RightDown = true
    end
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.O then
        behindToggle = not behindToggle
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        RightDown = false
    end
end)

local function isValid(p)
    if p == LocalPlayer then return false end
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getBestTarget()
    local best, bestDist = nil, Config.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if isValid(p) and p.Character then
            local part = p.Character:FindFirstChild(Config.AimbotPart)
            if part then
                local sp,on = Camera:WorldToViewportPoint(part.Position)
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
        local t = getBestTarget()
        if t then
            local sp,on = Camera:WorldToViewportPoint(t.Position)
            if on then
                local d = (Vector2.new(sp.X,sp.Y) - Vector2.new(Mouse.X,Mouse.Y)) * Config.Sensitivity
                mousemoverel(d.X, d.Y)
            end
        end
    end
end)

-- ─── ESP & Tracers & Noclip ───────────────────────────────────────────────

local Tracers             = {}
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
    h.Name               = "ESPHighlight"
    h.FillColor          = Config.ESPColor
    h.FillTransparency   = Config.ESPTransparency
    h.OutlineTransparency= 1
end

local function CreateNametag(p,c)
    if c:FindFirstChild("ESPNameTag") then return end
    local head = c:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui", c)
    bb.Name        = "ESPNameTag"
    bb.Adornee     = head
    bb.Size        = UDim2.new(0,100,0,20)
    bb.StudsOffset = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size                   = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.TextColor3             = Color3.fromRGB(0,255,0)
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
            local c = p.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local alive = root and h and h.Health>0
            if Config.ShowESP and alive then
                local pos,on = Camera:WorldToViewportPoint(root.Position)
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                if on and dist<MAX_TRACER_DISTANCE then
                    local T = Tracers[p] or CreateTracer()
                    Tracers[p] = T
                    T.Visible = true
                    T.From    = origin
                    T.To      = Vector2.new(pos.X,pos.Y)
                elseif Tracers[p] then
                    Tracers[p].Visible = false
                end
                CreateHighlight(c)
                if Config.ShowNameTags then CreateNametag(p,c) end
            else
                if Tracers[p] then Tracers[p].Visible = false end
                if c then
                    if c:FindFirstChild("ESPHighlight") then c.ESPHighlight:Destroy() end
                    if c:FindFirstChild("ESPNameTag") then c.ESPNameTag:Destroy() end
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
    if Config.ShowESP then RefreshESP() else 
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
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local behindToggle = false
UserInputService.InputBegan:Connect(function(inp, processed)
    if not processed and inp.KeyCode == Enum.KeyCode.O then
        behindToggle = not behindToggle
    end
end)

-- On every Heartbeat (once per frame)
RunService.Heartbeat:Connect(function()
    if not behindToggle then return end

    local seen = {}
    -- collect all viewmodels
    for _, m in ipairs(ReplicatedStorage.Assets.Temp.ViewModels:GetChildren()) do
        local nm = m.Name:gsub(" %- .*","")
        if nm ~= LocalPlayer.Name then
            seen[nm] = true
        end
    end

    -- teleport behind the first live, enemy player
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
                break  -- only break on successful teleport
            end
        end
        break  -- ensure only first iteration is tried if none valid
    end
end)

print("haxegon_static loaded: AimLock, WalkSpeed, Fly ON, Noclip, ESP, Teleport-Behind [O]")
-- END SCRIPT TWO
