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
local smoothing = 1 

local aimbotEnabled = false 
local stickyAimEnabled = true
local wallCheck = false
local teamCheck = true

-- 360 
local mode360Enabled = true
local fovCheckEnabled = false

local healthCheck = false
local minHealth = 6000 

local prioritizeLowHP = true
local maxDistance = 300 


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
    CurrentValue = 300, 
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
    CurrentValue = true,
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

-- Other Tabs
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

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


local HitboxEnabled = false
local HitboxSize = 0


local function UpdateHitbox(character)
    if not character then return end
    
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    if HitboxEnabled then
        if not hrp:GetAttribute("OriginalSize") then
            hrp:SetAttribute("OriginalSize", hrp.Size)
        end
        
        hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        hrp.Massless = true
        hrp.CanCollide = false
        hrp.Transparency = 0.7 
    else
        local origSize = hrp:GetAttribute("OriginalSize")
        if origSize then
            hrp.Size = origSize
            hrp.Transparency = 1 
        end
    end
end


local function RefreshAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            UpdateHitbox(player.Character)
        end
    end
end


Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        UpdateHitbox(char)
    end)
end)


for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            UpdateHitbox(char)
        end)
    end
end

Misc:CreateToggle({
    Name = "Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(v)
          HitboxEnabled = Value
        RefreshAllHitboxes() 
    end,
})

Misc:CreateSlider({
    Name = "Hitbox Expander",
    Range = {0, 200},
    Increment = 2,
    Suffix = "Studs",
    CurrentValue = 0,
    Flag = "HitboxSizeSlider",
    Callback = function(v)
        HitboxSize = Value
        
        if HitboxEnabled then
            RefreshAllHitboxes()
        end
    end,
})

Rayfield:Notify({
    Name = "Aimbot Loaded",
    Content = "Script Loaded Successfully!",
    Duration = 5
})
