local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
local smoothing = 0.5

local aimbotEnabled = false 
local stickyAimEnabled = false
local wallCheck = true
local teamCheck = false

local healthCheck = false
local minHealth = 0

local prioritizeLowHP = true
local maxDistance = 500

local currentTarget = nil

-- ALLIED

local alliedPlayers = {}
local alliedToggles = {}

local priorityTargetPlayer = nil 
local targetToggles = {} 



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
        FileName = "byAgreed"
    },
})

local Aimbot = Window:CreateTab("Aimbot")
local ESP = Window:CreateTab("ESP")
local TargetTab = Window:CreateTab("Target")
local Allied = Window:CreateTab("Allied")
local Misc = Window:CreateTab("Misc")
local Other = Window:CreateTab("Other")

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

    local pos, visible = camera:WorldToViewportPoint(head.Position)
    if not visible then return false end

    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local screenPos = Vector2.new(pos.X, pos.Y)

    local cursorDistance = (screenPos - mousePos).Magnitude
    if cursorDistance > aimFov then return false end

    if wallCheck and checkWall(character) then return false end

    return true
end

local function predict(player)
    local head = player.Character.Head
    local hrp = player.Character.HumanoidRootPart
    return head.Position + (hrp.Velocity * predictionStrength)
end

local function smooth(from,to)
    return from:Lerp(to,smoothing)
end

local function aimAt(player)
    local predictedPosition = predict(player)
    local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
    camera.CFrame = smooth(camera.CFrame, targetCFrame)
end

local function getTarget()
   
    if priorityTargetPlayer then
        local targetPlayer = Players:FindFirstChild(priorityTargetPlayer)
      
        if targetPlayer and validPlayer(targetPlayer) then
            return targetPlayer
        else
           
            return nil
        end
    end

    
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if validPlayer(player) then
            table.insert(targets, player)
        end
    end

    if #targets == 0 then return nil end

    table.sort(targets, function(a, b)
        local ah = a.Character.Humanoid.Health
        local bh = b.Character.Humanoid.Health

        local ad = (a.Character.Head.Position - camera.CFrame.Position).Magnitude
        local bd = (b.Character.Head.Position - camera.CFrame.Position).Magnitude

        if prioritizeLowHP then
            if ah ~= bh then
                return ah < bh
            end
            return ad < bd
        else
            return ad < bd
        end
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
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr then createESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= plr then createESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    alliedPlayers[player.Name] = nil
    if priorityTargetPlayer == player.Name then
        priorityTargetPlayer = nil
    end
end)

-- ALLIED CORE

local function refreshAlliedList()
    for name, toggle in pairs(alliedToggles) do
        if toggle and toggle.Interact then
            toggle.Interact:Destroy()
        end
    end
    alliedToggles = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            alliedToggles[player.Name] = Allied:CreateToggle({
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

Allied:CreateButton({
    Name = "Refresh List",
    Callback = function()
        refreshAlliedList()
    end
})

refreshAlliedList()

-- TARGET SYSTEM

local function refreshTargetList()
    for name, toggle in pairs(targetToggles) do
        if toggle and toggle.Interact then
            toggle.Interact:Destroy()
        end
    end
    targetToggles = {}

    if priorityTargetPlayer and not Players:FindFirstChild(priorityTargetPlayer) then
        priorityTargetPlayer = nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            targetToggles[player.Name] = TargetTab:CreateToggle({
                Name = player.Name,
                CurrentValue = (priorityTargetPlayer == player.Name),
                Flag = "Target_" .. player.Name,
                Callback = function(v)
                    if v then
                        if priorityTargetPlayer and priorityTargetPlayer ~= player.Name and targetToggles[priorityTargetPlayer] then
                            targetToggles[priorityTargetPlayer]:Set(false)
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

TargetTab:CreateButton({
    Name = "Refresh Playerlist",
    Callback = function()
        refreshTargetList()
    end
})

refreshTargetList()

-- LOOP
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
                    for _, part in ipairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            if not part:FindFirstChild("Cham") then
                                local cham = Instance.new("BoxHandleAdornment")
                                cham.Name = "Cham"
                                cham.Adornee = part
                                cham.AlwaysOnTop = true
                                cham.ZIndex = 5
                                cham.Size = part.Size + Vector3.new(0.02,0.02,0.02)
                                cham.Transparency = 0.5
                                cham.Color3 = chamsColor
                                cham.Parent = part
                            end
                        end
                    end
                end
            else
                drawings.Text.Visible = false
            end
        else
            drawings.Text.Visible = false
        end
    end
end)

-- AIMBOT UI
local AimbotToggle;

AimbotToggle = Aimbot:CreateToggle({
    Name = "Aimbot Enabled",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(v)
        aimbotEnabled = v
        fovCircle.Visible = v
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

Aimbot:CreateToggle({
    Name = "Sticky Aim",
    CurrentValue = false,
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
    Name = "Max Distance",
    Range = {0,5000},
    Increment = 5,
    CurrentValue = 500,
    Flag = "MaxDistance",
    Callback = function(v)
        maxDistance = v
    end
})

Aimbot:CreateSlider({
    Name = "Smoothing",
    Range = {0,100},
    Increment = 1,
    CurrentValue = 0.5,
    Flag = "Smoothing",
    Callback = function(v)
        smoothing = 1 - (v / 100)
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
    CurrentValue = true,
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
    Name = "Name Color",
    Color = nameColor,
    Flag = "ESPNameColor",
    Callback = function(v)
        nameColor = v
    end
})

ESP:CreateColorPicker({
    Name = "Health Color",
    Color = healthColor,
    Flag = "ESPHealthColor",
    Callback = function(v)
        healthColor = v
    end
})

ESP:CreateColorPicker({
    Name = "Distance Color",
    Color = distanceColor,
    Flag = "ESPDistanceColor",
    Callback = function(v)
        distanceColor = v
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

-- Other
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

-- AUTO V4
local Players = game:GetService("Players")

--
local player = Players.LocalPlayer

-- settings
local AUTO_V4 = false
local NORMAL_CHECK_INTERVAL = 0.25
local FAST_CHECK_INTERVAL = 0.03

local ACTIVATION_THRESHOLD = 0.92
local ACTIVATION_COOLDOWN = 8

--
local lastActivation = 0
local cachedEvent

--
local function getActivateEvent()
    if cachedEvent and cachedEvent.Parent then
        return cachedEvent
    end

    cachedEvent =
        (player:FindFirstChild("Events") and player.Events:FindFirstChild("ActivateRaceV4"))
        or player.PlayerGui:FindFirstChild("ActivateRaceV4", true)
        or game:FindFirstChild("ActivateRaceV4", true)

    return cachedEvent
end

--
local function getRaceEnergy()
    local char = player.Character
    if not char then
        return nil
    end

    local energy =
        player:FindFirstChild("RaceEnergy")
        or char:FindFirstChild("RaceEnergy")

    if energy then
        return energy
    end

    for _, obj in ipairs(player:GetDescendants()) do
        if obj.Name == "RaceEnergy" then
            return obj
        end
    end

    return nil
end

--
task.spawn(function()
    while true do
        local waitTime = NORMAL_CHECK_INTERVAL

        if AUTO_V4 then
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            if humanoid then
                local raceEnergy = getRaceEnergy()

                if raceEnergy then
                    -- 
                    if raceEnergy.Value >= 0.85 then
                        waitTime = FAST_CHECK_INTERVAL
                    end

                    -- activ
                    if raceEnergy.Value >= ACTIVATION_THRESHOLD then
                        local now = tick()

                        if now - lastActivation >= ACTIVATION_COOLDOWN then
                            local activateEvent = getActivateEvent()

                            if activateEvent and activateEvent:IsA("BindableEvent") then
                                lastActivation = now

                                -- spam configuration
                                task.spawn(function()
                                    for _ = 1, 15 do
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

--
local Toggle = Misc:CreateToggle({
    Name = "Auto Race V4",
    CurrentValue = false,
    Flag = "AutoRaceV4",

    Callback = function(Value)
        AUTO_V4 = Value
    end,
})

Rayfield:Notify({
    Name = "Aimbot Loaded",
    Content = "Script Loaded",
    Duration = 5
})
