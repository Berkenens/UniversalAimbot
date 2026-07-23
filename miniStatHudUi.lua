local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Stats        = game:GetService("Stats")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Pick the safest parent for executors
local function getParent()
    if gethui then
        return gethui()
    end
    local ok = pcall(function() return CoreGui:GetChildren() end)
    if ok then return CoreGui end
    return player:WaitForChild("PlayerGui")
end

local parentGui = getParent()

-- Remove old version if rerun
pcall(function()
    local old = parentGui:FindFirstChild("PerfOverlay")
    if old then old:Destroy() end
end)


local function getScale()
    local viewport = workspace.CurrentCamera.ViewportSize
    local minSide = math.min(viewport.X, viewport.Y)
    if UserInput.TouchEnabled and not UserInput.KeyboardEnabled then
        return math.clamp(minSide / 900, 0.85, 1.2)
    else
        return math.clamp(minSide / 1080, 0.95, 1.3)
    end
end


local gui = Instance.new("ScreenGui")
gui.Name = "PerfOverlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999
gui.Enabled = true

-- Try syn protect / hidden parenting
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    end
end)
gui.Parent = parentGui

local frame = Instance.new("Frame")
frame.Name = "Container"
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, -14, 0, 14) 
frame.Size = UDim2.fromOffset(160, 100)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true 
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.85
stroke.Thickness = 1
stroke.Parent = frame


local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, 0, 1, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop    = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft   = UDim.new(0, 12)
padding.PaddingRight  = UDim.new(0, 12)
padding.Parent = contentFrame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 3)
layout.Parent = contentFrame


local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(20, 20)
closeBtn.Position = UDim2.new(1, -5, 0, 5) -- close button location 
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.Parent = frame


closeBtn.MouseEnter:Connect(function()
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
end)


local function makeRow(name, color, order)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextColor3 = color
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Text = name .. ": --"
    lbl.LayoutOrder = order
    lbl.Parent = contentFrame
    return lbl
end

local pingLbl = makeRow("PING", Color3.fromRGB(120, 220, 140), 1)
local msLbl   = makeRow("MS",   Color3.fromRGB(120, 200, 255), 2)
local fpsLbl  = makeRow("FPS",  Color3.fromRGB(255, 200, 100), 3)
local timeLbl = makeRow("TIME", Color3.fromRGB(220, 220, 220), 4)


local uiScale = Instance.new("UIScale")
uiScale.Parent = frame

local function applyScale()
    uiScale.Scale = getScale()
end
applyScale()
local resizeConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)


local startTime = tick()
local frameCount = 0
local fps = 0
local lastUpdate = tick()

local function formatTime(sec)
    sec = math.floor(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then
        return string.format("%02d:%02d:%02d", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

local function getPing()
    local ok, val = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and val then return math.floor(val) end
    return 0
end

local function colorByPing(p)
    if p < 80 then return Color3.fromRGB(120, 220, 140)
    elseif p < 180 then return Color3.fromRGB(255, 220, 120)
    else return Color3.fromRGB(255, 110, 110) end
end

local function colorByFPS(f)
    if f >= 50 then return Color3.fromRGB(120, 220, 140)
    elseif f >= 30 then return Color3.fromRGB(255, 220, 120)
    else return Color3.fromRGB(255, 110, 110) end
end


local renderConn
renderConn = RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    if now - lastUpdate >= 0.5 then
        fps = math.floor(frameCount / (now - lastUpdate) + 0.5)
        frameCount = 0
        lastUpdate = now

        local ping = getPing()
        pingLbl.Text = "PING: " .. ping .. " ms"
        pingLbl.TextColor3 = colorByPing(ping)

        msLbl.Text = "MS:   " .. string.format("%.1f", 1000 / math.max(fps, 1))
        msLbl.TextColor3 = colorByPing(ping)

        fpsLbl.Text = "FPS:  " .. fps
        fpsLbl.TextColor3 = colorByFPS(fps)

        timeLbl.Text = "TIME: " .. formatTime(now - startTime)
    end
end)


closeBtn.MouseButton1Click:Connect(function()
    -- removing cache
    if renderConn then renderConn:Disconnect() end
    if resizeConn then resizeConn:Disconnect() end
    gui:Destroy()
end)


local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    
    local scale = uiScale.Scale
    frame.Position = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + (delta.X / scale), 
        startPos.Y.Scale, 
        startPos.Y.Offset + (delta.Y / scale)
    )
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInput.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)


frame.BackgroundTransparency = 1
stroke.Transparency = 1
closeBtn.TextTransparency = 1
for _, c in ipairs(contentFrame:GetChildren()) do
    if c:IsA("TextLabel") then c.TextTransparency = 1 end
end

TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency = 0.3}):Play()
TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0.85}):Play()
TweenService:Create(closeBtn, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

for _, c in ipairs(contentFrame:GetChildren()) do
    if c:IsA("TextLabel") then
        TweenService:Create(c, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    end
end
