local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Berkenens/UniversalAimbot/refs/heads/main/uimain.lua'))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = plr:GetMouse()

local hue = 0
local rainbowFov = false
local rainbowSpeed = 0.005

local aimFov = 150
local predictionStrength = 0
local smoothing = 1 

local aimbotEnabled = false 
local stickyAimEnabled = true
local wallCheck = false
local teamCheck = false

-- 360 
local mode360Enabled = true
local fovCheckEnabled = false

local healthCheck = false
local minHealth = 6000 

local prioritizeLowHP = true
local maxDistance = 460 


local currentTarget = nil

-- ALLIED 
local alliedPlayers = {}
local priorityTargetPlayer = nil 

-- UI 
local createdAlliedToggles = {}
local createdTargetToggles = {}

local circleColor = Color3.fromRGB(255,0,0)
local targetedCircleColor = Color3.fromRGB(0,255,0)

-- ESP
local espEnabled = false
local espName = true
local espHealth = true
local espDistance = true
local espChams = true

local nameColor = Color3.fromRGB(255,255,255)
local healthColor = Color3.fromRGB(0,255,0)
local distanceColor = Color3.fromRGB(255,255,0)
local chamsColor = Color3.fromRGB(255,0,0)

local espCache = {}

-- Main 
local Window = Rayfield:CreateWindow({
    Name = "▶ Universal Aimbot ◀",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Perseus",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalAimbot",
        FileName = "perseus"
    },
})

local Aimbot = Window:CreateTab("Aimbot", "crosshair")
local Hitbox = Window:CreateTab("Hitbox", "square")
local ESP = Window:CreateTab("ESP", "eye")
local TargetTab = Window:CreateTab("Target", "crosshair")
local Allied = Window:CreateTab("Allied", "user")
local Misc = Window:CreateTab("Misc", "droplet")
local Player = Window:CreateTab("Player", "user")
local Visuals = Window:CreateTab("Visuals", "eye")
local Ambience = Window:CreateTab("Ambience", "droplets")
local Other = Window:CreateTab("Other", "settings")

-- FOV
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Color = circleColor
fovCircle.Visible = false

local function isAllied(player)
    return alliedPlayers[player.Name] == true
end

local function checkTeam(player)
    if teamCheck and player.Team == plr.Team then
        return true
    end
    return false
end

local function checkWall(character)
    local head = character:FindFirstChild("Head")
    if not head then return true end

    local origin = camera.CFrame.Position
    local direction = (head.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {
        plr.Character,
        character
    }

    local result = Workspace:Raycast(origin, direction, params)
    return result and result.Instance ~= nil
end

local function validPlayer(player)
    if player == plr then return false end
    if isAllied(player) then return false end
    if checkTeam(player) then return false end

    local character = player.Character
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")

    if not humanoid or not head then return false end
    if humanoid.Health <= 0 then return false end

    local distance = (head.Position - camera.CFrame.Position).Magnitude
    if distance > maxDistance then return false end

    if not mode360Enabled then
        local pos, visible = camera:WorldToViewportPoint(head.Position)
        if not visible then return false end

        local mousePos = Vector2.new(mouse.X, mouse.Y)
        local screenPos = Vector2.new(pos.X, pos.Y)

        local cursorDistance = (screenPos - mousePos).Magnitude
        if cursorDistance > aimFov then return false end
    end

    if wallCheck and checkWall(character) then return false end

    return true
end

local function predict(player)
    local head = player.Character.Head
    local hrp = player.Character.HumanoidRootPart
    return head.Position + (hrp.Velocity * predictionStrength)
end

local function smooth(from,to)
    return from:Lerp(to, smoothing)
end

local function aimAt(player)
    local predictedPosition = predict(player)
    local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
    camera.CFrame = smooth(camera.CFrame, targetCFrame)
end

local function getTarget()
    local targets = {}
    
    -- 
    for _, player in ipairs(Players:GetPlayers()) do
        if validPlayer(player) then
            table.insert(targets, player)
        end
    end

    if #targets == 0 then return nil end

    -- 
    if prioritizeLowHP then
        local lowHpTargets = {}
        for _, player in ipairs(targets) do
            if player.Character.Humanoid.Health <= minHealth then
                table.insert(lowHpTargets, player)
            end
        end

        -- 
        if #lowHpTargets > 0 then
            table.sort(lowHpTargets, function(a, b)
                local ah = a.Character.Humanoid.Health
                local bh = b.Character.Humanoid.Health
                local ad = (a.Character.Head.Position - camera.CFrame.Position).Magnitude
                local bd = (b.Character.Head.Position - camera.CFrame.Position).Magnitude

                if math.abs(ah - bh) > 1 then
                    return ah < bh -- 
                end
                return ad < bd -- 
            end)
            return lowHpTargets[1]
        end
    end

    -- 
    if priorityTargetPlayer then
        local targetPlayer = Players:FindFirstChild(priorityTargetPlayer)
        if targetPlayer and validPlayer(targetPlayer) then
            return targetPlayer 
        end
    end

    -- 
    table.sort(targets, function(a, b)
        local ad = (a.Character.Head.Position - camera.CFrame.Position).Magnitude
        local bd = (b.Character.Head.Position - camera.CFrame.Position).Magnitude
        return ad < bd
    end)

    return targets[1]
end

-- ESP 
local function createESP(player)
    if espCache[player] then return end

    local text = Drawing.new("Text")
    text.Center = true
    text.Size = 16
    text.Outline = true
    text.Visible = false

    espCache[player] = { Text = text }
end

local function removeESP(player)
    if espCache[player] then
        espCache[player].Text:Remove()
        espCache[player] = nil
    end
    if player.Character then
        local highlight = player.Character:FindFirstChild("EspHighlight")
        if highlight then highlight:Destroy() end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr then createESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= plr then createESP(player) end
end)

-- 
local function refreshAlliedList()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr and not createdAlliedToggles[player.Name] then
            createdAlliedToggles[player.Name] = true 
            
            Allied:CreateToggle({
                Name = player.Name,
                CurrentValue = alliedPlayers[player.Name] or false,
                Flag = "Allied_" .. player.Name,
                Callback = function(v)
                    alliedPlayers[player.Name] = v
                end
            })
        end
    end
end

local function refreshTargetList()
    if priorityTargetPlayer and not Players:FindFirstChild(priorityTargetPlayer) then
        priorityTargetPlayer = nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr and not createdTargetToggles[player.Name] then
            createdTargetToggles[player.Name] = true 
            
            local fName = "Target_" .. player.Name
            TargetTab:CreateToggle({
                Name = player.Name,
                CurrentValue = (priorityTargetPlayer == player.Name),
                Flag = fName,
                Callback = function(v)
                    if v then
                        if priorityTargetPlayer and priorityTargetPlayer ~= player.Name then
                            local oldFlag = "Target_" .. priorityTargetPlayer
                            if Rayfield.Flags[oldFlag] then
                                pcall(function()
                                    for _, el in ipairs(TargetTab.Elements) do
                                        if el.Flag == oldFlag and el.Set then el:Set(false) end
                                    end
                                end)
                            end
                        end
                        priorityTargetPlayer = player.Name
                    else
                        if priorityTargetPlayer == player.Name then
                            priorityTargetPlayer = nil
                        end
                    end
                end
            })
        end
    end
end

-- BUTTONS
Allied:CreateButton({
    Name = "Refresh List",
    Callback = function()
        refreshAlliedList()
    end
})

TargetTab:CreateButton({
    Name = "Refresh Playerlist",
    Callback = function()
        refreshTargetList()
    end
})

-- 
refreshAlliedList()
refreshTargetList()

-- PLAYER CLEANUP
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    alliedPlayers[player.Name] = nil
    if priorityTargetPlayer == player.Name then
        priorityTargetPlayer = nil
    end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 50)

        if rainbowFov then
            hue += rainbowSpeed
            if hue > 1 then hue = 0 end
            fovCircle.Color = Color3.fromHSV(hue,1,1)
        else
            if currentTarget then
                fovCircle.Color = targetedCircleColor
            else
                fovCircle.Color = circleColor
            end
        end

        if stickyAimEnabled and currentTarget then
            if not validPlayer(currentTarget) then
                currentTarget = nil
            end
        end

        if not stickyAimEnabled or not currentTarget then
            currentTarget = getTarget()
        end

        if currentTarget then
            aimAt(currentTarget)
        end
    else
        currentTarget = nil
    end

    -- ESP 
    for player, drawings in pairs(espCache) do
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local head = character and character:FindFirstChild("Head")

        if espEnabled and character and humanoid and head then
            local pos, visible = camera:WorldToViewportPoint(head.Position)

            if visible then
                local distance = math.floor((head.Position - camera.CFrame.Position).Magnitude)
                local text = ""

                if espName then text = text .. player.Name end
                if espHealth then text = text .. "\nHP: "..math.floor(humanoid.Health) end
                if espDistance then text = text .. "\n"..distance.." studs" end

                drawings.Text.Text = text
                drawings.Text.Position = Vector2.new(pos.X, pos.Y - 40)
                drawings.Text.Color = nameColor
                drawings.Text.Visible = true

                if espChams then
                    local highlight = character:FindFirstChild("EspHighlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "EspHighlight"
                        highlight.FillColor = chamsColor
                        highlight.OutlineColor = chamsColor
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = character
                    else
                        highlight.FillColor = chamsColor
                        highlight.OutlineColor = chamsColor
                        highlight.Enabled = true
                    end
                else
                    local highlight = character:FindFirstChild("EspHighlight")
                    if highlight then highlight.Enabled = false end
                end
            else
                drawings.Text.Visible = false
                local highlight = character:FindFirstChild("EspHighlight")
                if highlight then highlight.Enabled = false end
            end
        else
            drawings.Text.Visible = false
            if character then
                local highlight = character:FindFirstChild("EspHighlight")
                if highlight then highlight.Enabled = false end
            end
        end
    end
end)

-- AIMBOT 
local AimbotToggle;
local fovToggle;
local mode360Toggle;

AimbotToggle = Aimbot:CreateToggle({
    Name = "Aimbot Enabled",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(v)
        aimbotEnabled = v
        fovCircle.Visible = (v and fovCheckEnabled)
    end
})

Aimbot:CreateKeybind({
    Name = "Aimbot Keybind",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Flag = "AimbotKeybind",
    Callback = function(Key)
        AimbotToggle:Set(not aimbotEnabled)
    end
})

-- 
fovToggle = Aimbot:CreateToggle({
    Name = "FOV Check",
    CurrentValue = false,
    Flag = "FOVCheck",
    Callback = function(v)
        fovCheckEnabled = v
        if v then
            fovCircle.Visible = aimbotEnabled
            if mode360Enabled then
                mode360Enabled = false
                if mode360Toggle then mode360Toggle:Set(false) end
            end
        else
            fovCircle.Visible = false
        end
    end
})

mode360Toggle = Aimbot:CreateToggle({
    Name = "360 Mode",
    CurrentValue = true,
    Flag = "Mode360",
    Callback = function(v)
        mode360Enabled = v
        if v then
            fovCircle.Visible = false
            if fovCheckEnabled then
                fovCheckEnabled = false
                if fovToggle then fovToggle:Set(false) end
            end
        end
    end
})

Aimbot:CreateToggle({
    Name = "Sticky Aim",
    CurrentValue = true,
    Flag = "StickyAim",
    Callback = function(v)
        stickyAimEnabled = v
    end
})

Aimbot:CreateToggle({
    Name = "Low HP Priority",
    CurrentValue = true,
    Flag = "LowHPPriority",
    Callback = function(v)
        prioritizeLowHP = v
    end
})

Aimbot:CreateSlider({
    Name = "Min Health Threshold",
    Range = {0, 25000},
    Increment = 100,
    CurrentValue = 6000,
    Flag = "MinHealth",
    Callback = function(v)
        minHealth = v
    end
})

Aimbot:CreateSlider({
    Name = "Max Distance",
    Range = {0,5000},
    Increment = 5,
    CurrentValue = 460, 
    Flag = "MaxDistance",
    Callback = function(v)
        maxDistance = v
    end
})

Aimbot:CreateSlider({
    Name = "Smoothing",
    Range = {0,100},
    Increment = 1,
    CurrentValue = 0,
    Flag = "Smoothing",
    Callback = function(v)
        smoothing = math.max(1 - (v / 100), 0.001) 
    end
})

Aimbot:CreateSlider({
    Name = "Prediction",
    Range = {0,0.2},
    Increment = 0.001,
    CurrentValue = 0,
    Flag = "Prediction",
    Callback = function(v)
        predictionStrength = v
    end
})

Aimbot:CreateSlider({
    Name = "FOV",
    Range = {0,1000},
    Increment = 1,
    CurrentValue = 150,
    Flag = "FOV",
    Callback = function(v)
        aimFov = v
        fovCircle.Radius = v
    end
})

Aimbot:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheck",
    Callback = function(v)
        wallCheck = v
    end
})

Aimbot:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(v)
        teamCheck = v
    end
})

Aimbot:CreateToggle({
    Name = "Rainbow FOV",
    CurrentValue = false,
    Flag = "RainbowFOV",
    Callback = function(v)
        rainbowFov = v
    end
})

-- ESP UI 
ESP:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v)
        espEnabled = v
    end
})

ESP:CreateToggle({
    Name = "Player Names",
    CurrentValue = true,
    Flag = "ESPNames",
    Callback = function(v)
        espName = v
    end
})

ESP:CreateToggle({
    Name = "Health",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(v)
        espHealth = v
    end
})

ESP:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(v)
        espDistance = v
    end
})

ESP:CreateToggle({
    Name = "Chams",
    CurrentValue = true,
    Flag = "ESPChams",
    Callback = function(v)
        espChams = v
    end
})

ESP:CreateColorPicker({
    Name = "Text Color",
    Color = nameColor,
    Flag = "ESPNameColor",
    Callback = function(v)
        nameColor = v
    end
})

ESP:CreateColorPicker({
    Name = "Chams Color",
    Color = chamsColor,
    Flag = "ESPChamsColor",
    Callback = function(v)
        chamsColor = v
    end
})

-- Other Tabs
Other:CreateButton({
    Name = "Aimbot Loader",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Berkenens/UniversalAimbot/refs/heads/main/guiLOADER.lua"))()
    end
})

Other:CreateButton({
    Name = "FPS GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Berkenens/BloxFruitsFPSBOOSTER/refs/heads/main/bfFPSbooster.lua"))()
    end
})

Other:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

Other:CreateButton({
    Name = "DeSync",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Berkenens/DeSync/refs/heads/main/maingui.lua"))()
    end
})

-- AUTO RACE V4
local AUTO_V4 = false
local NORMAL_CHECK_INTERVAL = 0.25
local FAST_CHECK_INTERVAL = 0.03
local ACTIVATION_THRESHOLD = 0.92
local ACTIVATION_COOLDOWN = 8
local lastActivation = 0
local cachedEvent

local function getActivateEvent()
    if cachedEvent and cachedEvent.Parent then
        return cachedEvent
    end
    cachedEvent = (plr:FindFirstChild("Events") and plr.Events:FindFirstChild("ActivateRaceV4"))
        or (plr:FindFirstChild("PlayerGui") and plr.PlayerGui:FindFirstChild("ActivateRaceV4", true))
        or game:FindFirstChild("ActivateRaceV4", true)
    return cachedEvent
end

local function getRaceEnergy()
    local char = plr.Character
    if not char then return nil end

    local energy = plr:FindFirstChild("RaceEnergy") or char:FindFirstChild("RaceEnergy")
    if energy then return energy end

    for _, obj in ipairs(plr:GetDescendants()) do
        if obj.Name == "RaceEnergy" then
            return obj
        end
    end
    return nil
end

task.spawn(function()
    while true do
        local waitTime = NORMAL_CHECK_INTERVAL
        if AUTO_V4 then
            local char = plr.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if humanoid then
                local raceEnergy = getRaceEnergy()
                if raceEnergy then
                    if raceEnergy.Value >= 0.95 then 
                        waitTime = FAST_CHECK_INTERVAL
                    end

                    if raceEnergy.Value >= ACTIVATION_THRESHOLD then
                        local now = tick()
                        if now - lastActivation >= ACTIVATION_COOLDOWN then
                            local activateEvent = getActivateEvent()
                            if activateEvent and activateEvent:IsA("BindableEvent") then
                                lastActivation = now
                                task.spawn(function()
                                    for _ = 1, 100 do ----- xxx
                                        pcall(function()
                                            activateEvent:Fire()
                                        end)
                                        task.wait(0.03)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(waitTime)
    end
end)

Misc:CreateToggle({
    Name = "Auto Race V4",
    CurrentValue = false,
    Flag = "AutoRaceV4",
    Callback = function(Value)
        AUTO_V4 = Value
    end,
})

-- Hitbox Expander

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer


local HitboxEnabled = false
local HitboxSize = 16
local HitboxTransparency = 0.4
local DEFAULT_SIZE = Vector3.new(2, 1, 1)


local function ApplyHitbox()
    if not HitboxEnabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                
                root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                root.Transparency = HitboxTransparency
                root.CanCollide = false
            end
        end
    end
end


local function ResetHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Size = DEFAULT_SIZE
                root.Transparency = 1
                root.CanCollide = false
            end
        end
    end
end


local lastUpdate = 0
RunService.Heartbeat:Connect(function(deltaTime)
    if not HitboxEnabled then return end
    
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate >= 5 then -- loop config every 5 sec now
        ApplyHitbox()
        lastUpdate = 0
    end
end)


Hitbox:CreateToggle({
    Name = "Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        HitboxEnabled = Value
        if Value then
            ApplyHitbox() 
        else
            ResetHitboxes() 
        end
    end,
})

Hitbox:CreateSlider({
    Name = "Hitbox Expander",
    Range = {1, 70},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        HitboxSize = Value
        if HitboxEnabled then ApplyHitbox() end
    end,
})

Hitbox:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 40,
    Callback = function(Value)
        HitboxTransparency = Value / 100
        if HitboxEnabled then ApplyHitbox() end
    end,
})


--TPWALK (ANTISTUN)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- 

local TPWalkEnabled = false
local TPWalkSpeed = 1

local TPWalkConnection

local function StopTPWalk()

    if TPWalkConnection then
        TPWalkConnection:Disconnect()
        TPWalkConnection = nil
    end
end

local function StartTPWalk()

    StopTPWalk()

    TPWalkConnection = RunService.Heartbeat:Connect(function(delta)

        if not TPWalkEnabled then
            return
        end

        local character = LocalPlayer.Character
        if not character then
            return
        end

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not root then
            return
        end

        local moveDirection = humanoid.MoveDirection

        if moveDirection.Magnitude > 0 then

            character:TranslateBy(
                moveDirection * TPWalkSpeed * delta * 10
            )
        end
    end)
end

-- 

Misc:CreateToggle({

    Name = "Speed (AntiStun)",
    CurrentValue = false,
    Flag = "TPWalkToggle",

    Callback = function(Value)

        TPWalkEnabled = Value

        if Value then
            StartTPWalk()
        else
            StopTPWalk()
        end
    end,
})

-- 

Misc:CreateSlider({

    Name = "Speed Value",
    Range = {1, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = 1,
    Flag = "TPWalkSpeedSlider",

    Callback = function(Value)

        TPWalkSpeed = Value
    end,
})

-- 

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)

    if TPWalkEnabled then
        StartTPWalk()
    end
end)

--CLICK TP

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local TPEnabled = false
local TPCConnection = nil

--

local function SetClickTP(state)
    TPEnabled = state

    if TPCConnection then
        TPCConnection:Disconnect()
        TPCConnection = nil
    end

    if not TPEnabled then return end

    TPCConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local Camera = workspace.CurrentCamera
        local mousePos = UserInputService:GetMouseLocation()

        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 2000)

        if result then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 5, 0))
            end
        end
    end)
end


Player:CreateToggle({
    Name = "Click TP",
    CurrentValue = false,
    Flag = "Toggle_ClickTP",

    Callback = function(Value)
        SetClickTP(Value)
    end,
})




--NAME PROTECTION

local CONFIG = {
    FakeName = "NameProtected",
    FakeDisplay = "NameProtected"
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local RealName = LocalPlayer.Name
local RealDisplay = LocalPlayer.DisplayName

local NameProtectEnabled = true
local NameProtectMode = "Only Me"

local Connections = {}

local function AddConnection(Connection)
    table.insert(Connections, Connection)
end

local function DisconnectAll()

    for _, Connection in ipairs(Connections) do

        if Connection then
            Connection:Disconnect()
        end
    end

    table.clear(Connections)
end

local function ReplaceNames(Text)

    if NameProtectMode == "Only Me" then

        Text = Text:gsub(RealName, CONFIG.FakeName)
        Text = Text:gsub(RealDisplay, CONFIG.FakeDisplay)

    elseif NameProtectMode == "All Players" then

        for _, Player in ipairs(Players:GetPlayers()) do

            Text = Text:gsub(
                Player.Name,
                CONFIG.FakeName
            )

            Text = Text:gsub(
                Player.DisplayName,
                CONFIG.FakeDisplay
            )
        end
    end

    return Text
end

local function SpoofText(Object)

    if not NameProtectEnabled then
        return
    end

    local OriginalText = Object.Text
    local NewText = ReplaceNames(OriginalText)

    if NewText ~= OriginalText then
        Object.Text = NewText
    end
end

local function MonitorObject(Object)

    if not (
        Object:IsA("TextLabel")
        or Object:IsA("TextButton")
        or Object:IsA("TextBox")
    ) then
        return
    end

    SpoofText(Object)

    AddConnection(
        Object:GetPropertyChangedSignal("Text"):Connect(function()

            if NameProtectEnabled then
                SpoofText(Object)
            end
        end)
    )
end

local function MonitorCharacter(Character)

    local Humanoid = Character:WaitForChild("Humanoid", 10)

    if not Humanoid then
        return
    end

    if NameProtectMode == "Only Me" then

        Humanoid.DisplayName = CONFIG.FakeDisplay

        AddConnection(
            Humanoid:GetPropertyChangedSignal("DisplayName"):Connect(function()

                if NameProtectEnabled and Humanoid.DisplayName ~= CONFIG.FakeDisplay then
                    Humanoid.DisplayName = CONFIG.FakeDisplay
                end
            end)
        )
    end
end

local function RefreshEverything()

    if not NameProtectEnabled then
        return
    end

    for _, Object in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do

        if Object:IsA("TextLabel")
        or Object:IsA("TextButton")
        or Object:IsA("TextBox") then

            SpoofText(Object)
        end
    end

    pcall(function()

        for _, Object in ipairs(CoreGui:GetDescendants()) do

            if Object:IsA("TextLabel")
            or Object:IsA("TextButton")
            or Object:IsA("TextBox") then

                SpoofText(Object)
            end
        end
    end)

    if LocalPlayer.Character then

        local Humanoid =
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

        if Humanoid and NameProtectMode == "Only Me" then
            Humanoid.DisplayName = CONFIG.FakeDisplay
        end
    end
end

local function EnableNameProtect()

    DisconnectAll()

    NameProtectEnabled = true

    for _, Object in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        MonitorObject(Object)
    end

    AddConnection(
        LocalPlayer.PlayerGui.DescendantAdded:Connect(MonitorObject)
    )

    pcall(function()

        for _, Object in ipairs(CoreGui:GetDescendants()) do
            MonitorObject(Object)
        end

        AddConnection(
            CoreGui.DescendantAdded:Connect(MonitorObject)
        )
    end)

    if LocalPlayer.Character then
        MonitorCharacter(LocalPlayer.Character)
    end

    AddConnection(
        LocalPlayer.CharacterAdded:Connect(MonitorCharacter)
    )

    RefreshEverything()
end

local function DisableNameProtect()

    NameProtectEnabled = false

    DisconnectAll()

    local Character = LocalPlayer.Character

    if Character then

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            Humanoid.DisplayName = RealDisplay
        end
    end
end

--

Misc:CreateToggle({

    Name = "Name Protect",
    CurrentValue = true,
    Flag = "NameProtectToggle",

    Callback = function(Value)

        if Value then
            EnableNameProtect()
        else
            DisableNameProtect()
        end
    end,
})

--

Misc:CreateDropdown({

    Name = "Protection Mode",

    Options = {
        "Only Me",
        "All Players"
    },

    CurrentOption = {
        "Only Me"
    },

    Flag = "NameProtectMode",

    Callback = function(Options)

        NameProtectMode = Options[1]

        if NameProtectEnabled then
            RefreshEverything()
        end
    end,
})

--

task.spawn(function()
    EnableNameProtect()
end)

--AntiAfk

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")


local AntiAfkEnabled = true 


Players.LocalPlayer.Idled:Connect(function()
    
    if AntiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)



Misc:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true, 
    Flag = "AntiAfkToggle", 
    Callback = function(Value)
        AntiAfkEnabled = Value
    end,
})

-----Rainbow Cursor



local CursorEnabled = true
local CursorConnection = nil
local CursorGUI = nil

Misc:CreateToggle({
    Name = "Custom Cursor",
    CurrentValue = true,
    Flag = "CustomCursor",
    Callback = function(Value)
        CursorEnabled = Value

        if CursorEnabled then
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")

            local player = Players.LocalPlayer
            local mouse = player:GetMouse()

            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "AimSightGUI"
            screenGui.ResetOnSpawn = false
            screenGui.Parent = player:WaitForChild("PlayerGui")
            CursorGUI = screenGui

            local aimContainer = Instance.new("Frame")
            aimContainer.BackgroundTransparency = 1
            aimContainer.Size = UDim2.new(0, 25, 0, 25)
            aimContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            aimContainer.Parent = screenGui

            local function CreateLine(parent, size, pos)
                local f = Instance.new("Frame")
                f.Size = size
                f.Position = pos
                f.BorderSizePixel = 0
                f.ZIndex = 5
                f.Parent = parent

                local stroke = Instance.new("UIStroke")
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Color = Color3.new(0, 0, 0)
                stroke.Thickness = 1
                stroke.Parent = f

                return f
            end

            local topLine    = CreateLine(aimContainer, UDim2.new(0, 3, 0, 25), UDim2.new(0.5, -1.5, 0, 0))
            local bottomLine = CreateLine(aimContainer, UDim2.new(0, 3, 0, 25), UDim2.new(0.5, -1.5, 1, -25))
            local leftLine   = CreateLine(aimContainer, UDim2.new(0, 25, 0, 3), UDim2.new(0, 0, 0.5, -1.5))
            local rightLine  = CreateLine(aimContainer, UDim2.new(0, 25, 0, 3), UDim2.new(1, -25, 0.5, -1.5))

            local textLabel = Instance.new("TextLabel")
            textLabel.BackgroundTransparency = 1
            textLabel.Size = UDim2.new(0, 150, 0, 23)
            textLabel.Font = Enum.Font.Arcade
            textLabel.TextScaled = true
            textLabel.Text = "Percy.win"
            textLabel.ZIndex = 10
            textLabel.Parent = screenGui

            local textStroke = Instance.new("UIStroke")
            textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
            textStroke.Color = Color3.new(0, 0, 0)
            textStroke.Thickness = 1
            textStroke.LineJoinMode = Enum.LineJoinMode.Round
            textStroke.Parent = textLabel

            -- Orijinal script değişkenleri
            local lineThickness     = 3
            local baseRotationSpeed = 0.8
            local pulseSpeed        = 2.5
            local minLength         = -10
            local maxLength         = -30

            local t                  = 0
            local rotationProgress   = 0
            local currentRotSpeed    = baseRotationSpeed
            local smoothedRot        = 5

            local function getRainbow(time)
                local r = math.sin(time * 0.6) * 0.5 + 0.5
                local g = math.sin(time * 0.6 + 2) * 0.5 + 0.5
                local b = math.sin(time * 0.6 + 4) * 0.5 + 0.5
                return Color3.new(r, g, b)
            end

            local function calcRotSpeed(progress)
                local slowdownStart    = 0.6
                local slowdownDuration = 0.35
                local minSpeed         = 0.3
                if progress >= slowdownStart then
                    local sp = (progress - slowdownStart) / slowdownDuration
                    local ep = sp * sp
                    local sf = 1 - (ep * (1 - minSpeed))
                    return baseRotationSpeed * math.max(sf, minSpeed)
                end
                return baseRotationSpeed
            end

            local function smoothPulse(time, speed)
                local raw = math.sin(time * speed) * 0.5 + 0.5
                return raw * raw
            end

            CursorConnection = RunService.RenderStepped:Connect(function(dt)
                t = t + dt

                aimContainer.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
                textLabel.Position    = UDim2.new(0, mouse.X - 70, 0, mouse.Y + 50)

                rotationProgress = (rotationProgress + currentRotSpeed * dt) % 1
                currentRotSpeed  = calcRotSpeed(rotationProgress)

                local targetRot = rotationProgress * 360
                smoothedRot = smoothedRot + (targetRot - smoothedRot) * 1
                aimContainer.Rotation = smoothedRot

                local pulse  = smoothPulse(t, pulseSpeed)
                local curLen = minLength + (maxLength - minLength) * pulse

                topLine.Size    = UDim2.new(0, lineThickness, 0, curLen)
                bottomLine.Size = UDim2.new(0, lineThickness, 0, curLen)
                leftLine.Size   = UDim2.new(0, curLen, 0, lineThickness)
                rightLine.Size  = UDim2.new(0, curLen, 0, lineThickness)

                topLine.Position    = UDim2.new(0.5, -lineThickness / 2, 0, 0)
                bottomLine.Position = UDim2.new(0.5, -lineThickness / 2, 1, -curLen)
                leftLine.Position   = UDim2.new(0, 0, 0.5, -lineThickness / 2)
                rightLine.Position  = UDim2.new(1, -curLen, 0.5, -lineThickness / 2)

                local color = getRainbow(t)
                topLine.BackgroundColor3    = color
                bottomLine.BackgroundColor3 = color
                leftLine.BackgroundColor3   = color
                rightLine.BackgroundColor3  = color
                textLabel.TextColor3        = color
            end)

        else
            if CursorConnection then
                CursorConnection:Disconnect()
                CursorConnection = nil
            end
            if CursorGUI then
                CursorGUI:Destroy()
                CursorGUI = nil
            end
        end
    end
})

Rayfield.Flags.CustomCursor:Set(true)

--Antilag


Misc:CreateButton({
    Name = "Anti Lag / FPS Boost",
    Callback = function()

        local Lighting = game:GetService("Lighting")
        local RunService = game:GetService("RunService")

        local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CastShadow = false
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0

                pcall(function()
                    v.BackSurface = Enum.SurfaceType.Smooth
                    v.BottomSurface = Enum.SurfaceType.Smooth
                    v.FrontSurface = Enum.SurfaceType.Smooth
                    v.LeftSurface = Enum.SurfaceType.Smooth
                    v.RightSurface = Enum.SurfaceType.Smooth
                    v.TopSurface = Enum.SurfaceType.Smooth
                end)

            elseif v:IsA("Decal") then
                v.Transparency = 1
                v.Texture = ""

            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            end
        end

        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end

        workspace.DescendantAdded:Connect(function(child)
            task.spawn(function()

                if child:IsA("ForceField")
                or child:IsA("Sparkles")
                or child:IsA("Smoke")
                or child:IsA("Fire")
                or child:IsA("Beam") then

                    RunService.Heartbeat:Wait()

                    pcall(function()
                        child:Destroy()
                    end)

                elseif child:IsA("BasePart") then
                    child.CastShadow = false
                end
            end)
        end)

    end
})

------Player--------

--INF JUMP

local InfiniteJumpEnabled = false

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local hum = game.Players.LocalPlayer.Character 
            and game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Player:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "Toggle_InfiniteJump",
    
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end,
})

--Noclip

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local NoclipEnabled = false
local NoclipConnection = nil

--
local function SetNoclip(state)
    NoclipEnabled = state

    
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    local Character = LocalPlayer.Character
    if not Character then return end

    if not NoclipEnabled then
        
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        return
    end

  
    NoclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end


-- 

Player:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Toggle_Noclip",

    Callback = function(Value)
        SetNoclip(Value)
    end,
})


---- VISUALS PART & Ambience

--- Motion Blur

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local MotionBlurEnabled = false
local BlurAmount = 15
local BlurAmplifier = 5

local LastVector = Camera.CFrame.LookVector
local MotionBlurConnection

local MotionBlur = Instance.new("BlurEffect")
MotionBlur.Name = "RayfieldMotionBlur"
MotionBlur.Size = 0

local function StartMotionBlur()
    if MotionBlurConnection then
        MotionBlurConnection:Disconnect()
    end

    Camera = workspace.CurrentCamera
    MotionBlur.Parent = Camera

    LastVector = Camera.CFrame.LookVector

    MotionBlurConnection = RunService.Heartbeat:Connect(function()
        if not MotionBlurEnabled then
            return
        end

        Camera = workspace.CurrentCamera

        if MotionBlur.Parent ~= Camera then
            MotionBlur.Parent = Camera
        end

        local Magnitude = (Camera.CFrame.LookVector - LastVector).Magnitude
        MotionBlur.Size = math.abs(Magnitude) * BlurAmount * BlurAmplifier / 2
        LastVector = Camera.CFrame.LookVector
    end)
end

local function StopMotionBlur()
    MotionBlur.Size = 0
    MotionBlur.Parent = nil

    if MotionBlurConnection then
        MotionBlurConnection:Disconnect()
        MotionBlurConnection = nil
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if MotionBlurEnabled then
        Camera = workspace.CurrentCamera
        MotionBlur.Parent = Camera
    end
end)

Ambience:CreateToggle({
    Name = "Motion Blur",
    CurrentValue = false,
    Flag = "MotionBlurToggle",
    Callback = function(Value)
        MotionBlurEnabled = Value

        if Value then
            StartMotionBlur()
        else
            StopMotionBlur()
        end
    end
})

Ambience:CreateSlider({
    Name = "Blur Amount",
    Range = {1, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = 15,
    Flag = "BlurAmountSlider",
    Callback = function(Value)
        BlurAmount = Value
    end
})

Ambience:CreateSlider({
    Name = "Blur Amplifier",
    Range = {1, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "BlurAmplifierSlider",
    Callback = function(Value)
        BlurAmplifier = Value
    end
})



--Rain & ThunderStorm
---------------------
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 
local rainEnabled = false
local thunderEnabled = false
local rainIntensity = 2

-- 
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient
}

-- save current skybox
local OriginalSky = Lighting:FindFirstChildOfClass("Sky") and Lighting:FindFirstChildOfClass("Sky"):Clone() or nil

local MaxRainClones = 200 
local RainPool = {}
local ActiveRainOffsets = {} 
local AllSounds = {}
local MainRain = nil
local RainFolder = nil

---

-- rain intensity
local function UpdateRainDensity()
    if not MainRain then return end
    
    local rows = 3 + rainIntensity 
    local totalNeeded = rows * rows
    local spacing = 200 / rows 
    
    if totalNeeded > MaxRainClones then totalNeeded = MaxRainClones end
    
    local newOffsets = {}
    local halfRow = (rows - 1) / 2
    local currentIndex = 1
    
    for x = 0, rows - 1 do
        for z = 0, rows - 1 do
            if currentIndex <= MaxRainClones then
                local offsetX = (x - halfRow) * spacing
                local offsetZ = (z - halfRow) * spacing
                
                local clone = RainPool[currentIndex]
                table.insert(newOffsets, {
                    Model = clone,
                    Offset = Vector3.new(offsetX, 0, offsetZ)
                })
                
                -- Parçacıkları aktif et
                for _, obj in ipairs(clone:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") then
                        obj.Enabled = rainEnabled
                    end
                end
                currentIndex = currentIndex + 1
            end
        end
    end
    
    -- 
    for i = currentIndex, MaxRainClones do
        local clone = RainPool[i]
        clone:PivotTo(CFrame.new(0, 10000, 0)) 
        for _, obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then obj.Enabled = false end
        end
    end
    
    ActiveRainOffsets = newOffsets
end

-- 
local function InitializeRain()
    if MainRain then return end
    
    local success, result = pcall(function() return game:GetObjects("rbxassetid://11552439884")[1] end)
    if not success or not result then return end

    MainRain = result
    MainRain.Name = "RealisticRain_Main"
    MainRain.Parent = workspace

    for _, obj in ipairs(MainRain:GetDescendants()) do
        if obj:IsA("BasePart") then obj.Anchored = true; obj.CanCollide = false end
        if obj:IsA("ParticleEmitter") then obj.Enabled = rainEnabled end
        if obj:IsA("Sound") then table.insert(AllSounds, obj) if not rainEnabled then obj:Stop() end end
    end

    RainFolder = Instance.new("Folder", workspace)
    RainFolder.Name = "StormRainSystem"

    for i = 1, MaxRainClones do
        local Clone = result:Clone()
        for _, obj in ipairs(Clone:GetDescendants()) do
            if obj:IsA("BasePart") then obj.Anchored = true; obj.CanCollide = false end
            if obj:IsA("Sound") or obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then obj:Destroy() end
            if obj:IsA("ParticleEmitter") then obj.Enabled = false end
        end
        Clone.Parent = RainFolder
        table.insert(RainPool, Clone)
    end
    UpdateRainDensity()
end

-- 
local function ApplyLighting(state)
    -- 
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then v:Destroy() end
    end

    if state then
        -- 
        Lighting.Brightness = 1.5
        Lighting.FogColor = Color3.fromRGB(90, 90, 90)
        Lighting.FogStart = 0; Lighting.FogEnd = 3000
        Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 105)
        Lighting.Ambient = Color3.fromRGB(95, 95, 95)
        
        local RainSky = Instance.new("Sky", Lighting)
        RainSky.SkyboxBk = "http://www.roblox.com/asset/?id=4495864450"
        RainSky.SkyboxDn = "http://www.roblox.com/asset/?id=4495864887"
        RainSky.SkyboxFt = "http://www.roblox.com/asset/?id=4495865458"
        RainSky.SkyboxLf = "http://www.roblox.com/asset/?id=4495866035"
        RainSky.SkyboxRt = "http://www.roblox.com/asset/?id=4495866584"
        RainSky.SkyboxUp = "http://www.roblox.com/asset/?id=4495867486"
    else
        -- turn origin skybox
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.FogColor = OriginalLighting.FogColor
        Lighting.FogStart = OriginalLighting.FogStart; Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Ambient = OriginalLighting.Ambient
        
        if OriginalSky then OriginalSky:Clone().Parent = Lighting end
    end
end

-- respawn check
RunService.RenderStepped:Connect(function()
    if not rainEnabled then return end
    if Camera and MainRain then MainRain:PivotTo(Camera.CFrame) end

    local Character = Player.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if Root then
        local Center = Root.Position + Vector3.new(0, 120, 0)
        for _, Data in ipairs(ActiveRainOffsets) do
            if Data.Model then Data.Model:PivotTo(CFrame.new(Center + Data.Offset)) end
        end
    end
end)

-- thunder
local ThunderSound = Instance.new("Sound", SoundService)
ThunderSound.SoundId = "rbxassetid://136909414800877"
ThunderSound.Volume = 1.2; ThunderSound.RollOffMaxDistance = 100000

task.spawn(function()
    while true do
        task.wait(math.random(15, 45))
        if thunderEnabled and rainEnabled then
            local OldBright = Lighting.Brightness
            for i = 1, math.random(2, 5) do
                Lighting.Brightness = 7; task.wait(0.05)
                Lighting.Brightness = 1; task.wait(0.05)
            end
            ThunderSound:Play(); task.wait(0.5); Lighting.Brightness = OldBright
        end
    end
end)


Ambience:CreateToggle({
    Name = "Rain Ambience",
    CurrentValue = false,
    Callback = function(Value)
        rainEnabled = Value
        InitializeRain()
        ApplyLighting(Value)
        
        -- 
        UpdateRainDensity()
        
        -- 
        if MainRain then
            for _, obj in ipairs(MainRain:GetDescendants()) do
                if obj:IsA("ParticleEmitter") then obj.Enabled = Value end
            end
        end
        for _, sound in ipairs(AllSounds) do
            if sound then if Value then sound:Play() else sound:Stop() end end
        end
    end,
})

Ambience:CreateToggle({
    Name = "Thunder",
    CurrentValue = false,
    Callback = function(Value)
        thunderEnabled = Value
    end,
})

Ambience:CreateSlider({
    Name = "Rain Area Density",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 2,
    Flag = "RainDensitySlider",
    Callback = function(Value)
        rainIntensity = Value
        if rainEnabled then
            -- 
            UpdateRainDensity()
        end
    end
})


--------------------
--- Music 

local MusicEnabled = true
local MusicConnection = nil
local Sound = nil

Ambience:CreateToggle({
    Name = "Background Music",
    CurrentValue = true,
    Flag = "BackgroundMusic",
    Callback = function(Value)
        MusicEnabled = Value

        if MusicEnabled then
            Sound = Instance.new("Sound")
            Sound.SoundId = "rbxassetid://120102995443063"
            Sound.Volume = 0.5
            Sound.Parent = game:GetService("SoundService")
            Sound:Play()

            MusicConnection = Sound.Ended:Connect(function()
                if MusicEnabled then
                    Sound:Play()
                end
            end)

        else
            if MusicConnection then
                MusicConnection:Disconnect()
                MusicConnection = nil
            end
            if Sound then
                Sound:Stop()
                Sound:Destroy()
                Sound = nil
            end
        end
    end
})

Rayfield.Flags.BackgroundMusic:Set(true)


--Stretch

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ResolutionEnabled = false
local StretchAmount = 0.65

local ResolutionConnection

local function StartResolution()
    if ResolutionConnection then
        ResolutionConnection:Disconnect()
    end

    ResolutionConnection = RunService.RenderStepped:Connect(function()
        if not ResolutionEnabled then
            return
        end

        Camera = workspace.CurrentCamera

        Camera.CFrame =
            Camera.CFrame *
            CFrame.new(
                0, 0, 0,
                1, 0, 0,
                0, StretchAmount, 0,
                0, 0, 1
            )
    end)
end

local function StopResolution()
    if ResolutionConnection then
        ResolutionConnection:Disconnect()
        ResolutionConnection = nil
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

Visuals:CreateToggle({
    Name = "Resolution Stretch",
    CurrentValue = false,
    Flag = "ResolutionStretchToggle",
    Callback = function(Value)
        ResolutionEnabled = Value

        if Value then
            StartResolution()
        else
            StopResolution()
        end
    end
})

Visuals:CreateSlider({
    Name = "Stretch Amount",
    Range = {10, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 65,
    Flag = "StretchAmountSlider",
    Callback = function(Value)
        StretchAmount = Value / 100
    end
})


--HEADLESS & KORBLOX

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local HeadlessEnabled = false
local KorbloxEnabled = false

local HEADLESS_MESH_ID   = "rbxassetid://1095708"
local KORBLOX_MESH_ID    = "rbxassetid://101851696"
local KORBLOX_TEXTURE_ID = "rbxassetid://101851254"
local DARK_GREY          = Color3.fromRGB(64, 64, 64)


local originalR6Color = nil


---

local function removeFace(head)
    local face = head:FindFirstChild("face")
    if face and face:IsA("Decal") then
        face:Destroy()
    end
end

local function applyHeadless(head)
    if not head or not HeadlessEnabled then return end
    
    head.Transparency = 1
    head.CanCollide   = false
    
    removeFace(head)
    
    for _, child in ipairs(head:GetChildren()) do
        if child:IsA("SpecialMesh") and child.MeshId == HEADLESS_MESH_ID then
            child:Destroy()
        end
    end

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId   = HEADLESS_MESH_ID
    mesh.Scale    = Vector3.new(0.001, 0.001, 0.001)
    mesh.Parent   = head
    
    local transConn
    transConn = head:GetPropertyChangedSignal("Transparency"):Connect(function()
        if HeadlessEnabled and head.Transparency ~= 1 then
            head.Transparency = 1
        end
    end)
    
    head.ChildAdded:Connect(function(child)
        if HeadlessEnabled and child.Name == "face" and child:IsA("Decal") then
            child:Destroy()
        end
    end)
end


local function revertHeadless(character)
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    head.Transparency = 0 
    
   
    for _, child in ipairs(head:GetChildren()) do
        if child:IsA("SpecialMesh") and child.MeshId == HEADLESS_MESH_ID then
            child:Destroy()
        end
    end
end


---

local function applyKorbloxR6(rightLeg)
    if not rightLeg or not KorbloxEnabled then return end
    
    if not originalR6Color then
        originalR6Color = rightLeg.Color
    end
    
    for _, child in rightLeg:GetChildren() do
        if child:IsA("SpecialMesh") or child:IsA("CharacterMesh") then
            child:Destroy()
        end
    end
    
    rightLeg.Color = DARK_GREY
    
    local colorConn = rightLeg:GetPropertyChangedSignal("Color"):Connect(function()
        if KorbloxEnabled and rightLeg.Color ~= DARK_GREY then
            rightLeg.Color = DARK_GREY
        end
    end)
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType  = Enum.MeshType.FileMesh
    mesh.MeshId    = KORBLOX_MESH_ID
    mesh.TextureId = KORBLOX_TEXTURE_ID
    mesh.Scale     = Vector3.new(1, 1, 1)
    mesh.Parent    = rightLeg
end

local function applyKorbloxR15(character)
    if not KorbloxEnabled then return end
    local upper = character:FindFirstChild("RightUpperLeg")
    if not upper then return end
    
    upper.Transparency = 1
    local lower = character:FindFirstChild("RightLowerLeg")
    local foot  = character:FindFirstChild("RightFoot")
    if lower then lower.Transparency = 1 end
    if foot  then foot.Transparency  = 1  end
    
    if character:FindFirstChild("KorbloxRightLeg") then return end

    local korbloxPart = Instance.new("Part")
    korbloxPart.Name       = "KorbloxRightLeg"
    korbloxPart.Size       = Vector3.new(1, 2, 1)
    korbloxPart.Color      = DARK_GREY
    korbloxPart.CanCollide = false
    korbloxPart.Parent     = character
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType  = Enum.MeshType.FileMesh
    mesh.MeshId    = KORBLOX_MESH_ID
    mesh.TextureId = KORBLOX_TEXTURE_ID
    mesh.Scale     = Vector3.new(1, 1, 1)
    mesh.Parent    = korbloxPart
    
    local weld = Instance.new("Weld")
    weld.Part0 = upper
    weld.Part1 = korbloxPart
    weld.C0    = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, 0)  
    weld.Parent = korbloxPart
end


local function revertKorblox(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.RigType == Enum.HumanoidRigType.R15 then
        local upper = character:FindFirstChild("RightUpperLeg")
        local lower = character:FindFirstChild("RightLowerLeg")
        local foot  = character:FindFirstChild("RightFoot")

        
        if upper then upper.Transparency = 0 end
        if lower then lower.Transparency = 0 end
        if foot  then foot.Transparency = 0 end

        
        local kLeg = character:FindFirstChild("KorbloxRightLeg")
        if kLeg then kLeg:Destroy() end

    elseif humanoid.RigType == Enum.HumanoidRigType.R6 then
        local rightLeg = character:FindFirstChild("Right Leg")
        if rightLeg then
            for _, child in ipairs(rightLeg:GetChildren()) do
                if child:IsA("SpecialMesh") and child.MeshId == KORBLOX_MESH_ID then
                    child:Destroy()
                end
            end
            if originalR6Color then
                rightLeg.Color = originalR6Color
            end
        end
    end
end


----

local function refreshCharacter()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if HeadlessEnabled then
        local head = character:FindFirstChild("Head")
        if head then applyHeadless(head) end
    end

    if KorbloxEnabled then
        if humanoid.RigType == Enum.HumanoidRigType.R6 then
            local rightLeg = character:FindFirstChild("Right Leg")
            if rightLeg then applyKorbloxR6(rightLeg) end
        elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
            applyKorbloxR15(character)
        end
    end
end


player.CharacterAdded:Connect(function()
    task.wait(0.5) 
    refreshCharacter()
end)

---

Visuals:CreateToggle({
    Name = "Headless",
    CurrentValue = false,
    Flag = "HeadlessToggle",
    Callback = function(Value)
        HeadlessEnabled = Value
        if Value then
            refreshCharacter() 
        else
            revertHeadless(player.Character) 
        end
    end,
})

Visuals:CreateToggle({
    Name = "Korblox",
    CurrentValue = false,
    Flag = "KorbloxToggle",
    Callback = function(Value)
        KorbloxEnabled = Value
        if Value then
            refreshCharacter() 
        else
            revertKorblox(player.Character) 
        end
    end,
})


---AccessoryAdder-----

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


local SavedAccessories = {}

local function attachAccessory(char, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end

    local targetAttachment, accAttachment
    
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            for _, att in ipairs(part:GetChildren()) do
                if att:IsA("Attachment") then
                    local match = handle:FindFirstChild(att.Name)
                    if match and match:IsA("Attachment") then
                        targetAttachment = att
                        accAttachment = match
                        break
                    end
                end
            end
        end
        if targetAttachment then break end
    end

    if targetAttachment and accAttachment then
        handle.CFrame = targetAttachment.WorldCFrame * accAttachment.CFrame:Inverse()
    else
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            handle.CFrame = root.CFrame
        end
    end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = (targetAttachment and targetAttachment.Parent) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    weld.Parent = handle

    accessory.Parent = char
end

local function equipItemById(itemId, isRespawn)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(itemId))
    end)

    if success and objects and objects[1] then
        local item = objects[1]
        
        if item:IsA("Accessory") or item:IsA("Hat") then
           
            item:SetAttribute("FakeAccessory", true)
            
            attachAccessory(char, item)
            
            
            if not isRespawn then
                
                local alreadySaved = false
                for _, savedId in ipairs(SavedAccessories) do
                    if savedId == itemId then alreadySaved = true break end
                end
                
                if not alreadySaved then
                    table.insert(SavedAccessories, itemId)
                end
            end
            
            return true
        else
            item:Destroy() 
            return false
        end
    else
        return false
    end
end


LocalPlayer.CharacterAdded:Connect(function(newChar)
   
    task.wait(1) 
    for _, itemId in ipairs(SavedAccessories) do
        equipItemById(itemId, true)
    end
end)







local targetItemId = ""

Visuals:CreateInput({
    Name = "Accessory Adder",
    PlaceholderText = "Put ID Exmp: 1028713",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        targetItemId = text
    end
})

Visuals:CreateButton({
    Name = "Apply",
    Callback = function()
        local id = tonumber(targetItemId)
        if id then
            local success = equipItemById(id, false)
            if success then
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Accessory Added",
                    Duration = 3
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Couldnt Load Check If Id Is Correct Dont Put Clothing IDS",
                    Duration = 3
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Error Only Put Number",
                Duration = 3
            })
        end
    end
})

Visuals:CreateButton({
    Name = "Clear Accessorries",
    Callback = function()
        
        SavedAccessories = {}
        
        
        local char = LocalPlayer.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:GetAttribute("FakeAccessory") then
                    child:Destroy()
                end
            end
        end
        
        Rayfield:Notify({
            Title = "Success",
            Content = "Accessorries Cleared",
            Duration = 3
        })
    end
})


----------------------
Rayfield:Notify({
    Name = "Aimbot Loaded",
    Content = "Script Loaded Successfully!",
    Duration = 5
})
