local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local tpwalking = nil
local isOn = false

-- 
local tpSpeed = 2.0             
local currentKeybind = Enum.KeyCode.Z 
local isBinding = false         
local sliderActive = false      

-- 
local globalInputConnection = nil
local dragChangedConnection = nil
local dragEndedConnection = nil
local sliderChangedConnection = nil
local sliderEndedConnection = nil

-- 
local BG_COLOR = Color3.fromRGB(20, 20, 20)       
local BORDER_COLOR = Color3.fromRGB(45, 45, 45)   
local BTN_OFF_COLOR = Color3.fromRGB(30, 30, 30)  
local BTN_ON_COLOR = Color3.fromRGB(55, 55, 55)   
local TEXT_COLOR = Color3.fromRGB(180, 180, 180)  
local TEXT_ON_COLOR = Color3.fromRGB(255, 255, 255)

-- 
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SleekConfigurableGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 160, 0, 135)
mainFrame.Position = UDim2.new(0.5, -80, 0.4, -67)
mainFrame.BackgroundColor3 = BG_COLOR
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = BORDER_COLOR
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

--
local dragHandle = Instance.new("Frame")
dragHandle.Size = UDim2.new(1, -25, 0, 22) 
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundTransparency = 1
dragHandle.Active = true
dragHandle.Parent = mainFrame

-- close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 16, 0, 16)
closeBtn.Position = UDim2.new(1, -20, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 2 
closeBtn.Parent = mainFrame

-- button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 140, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 25)
toggleBtn.BackgroundColor3 = BTN_OFF_COLOR
toggleBtn.Text = "TPWALK: OFF"
toggleBtn.TextColor3 = TEXT_COLOR
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 13
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 4)
btnCorner.Parent = toggleBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = BORDER_COLOR
btnStroke.Thickness = 1
btnStroke.Parent = toggleBtn

-- keybind visual
local bindLabel = Instance.new("TextLabel")
bindLabel.Size = UDim2.new(0, 60, 0, 20)
bindLabel.Position = UDim2.new(0, 10, 0, 63)
bindLabel.BackgroundTransparency = 1
bindLabel.Text = "Keybind:"
bindLabel.TextColor3 = TEXT_COLOR
bindLabel.Font = Enum.Font.SourceSans
bindLabel.TextSize = 13
bindLabel.TextXAlignment = Enum.TextXAlignment.Left
bindLabel.Parent = mainFrame

local bindBtn = Instance.new("TextButton")
bindBtn.Size = UDim2.new(0, 75, 0, 20)
bindBtn.Position = UDim2.new(0, 75, 0, 63)
bindBtn.BackgroundColor3 = BTN_OFF_COLOR
bindBtn.Text = currentKeybind.Name
bindBtn.TextColor3 = TEXT_ON_COLOR
bindBtn.Font = Enum.Font.SourceSansBold
bindBtn.TextSize = 12
bindBtn.Parent = mainFrame

local bindCorner = Instance.new("UICorner")
bindCorner.CornerRadius = UDim.new(0, 4)
bindCorner.Parent = bindBtn

local bindStroke = Instance.new("UIStroke")
bindStroke.Color = BORDER_COLOR
bindStroke.Thickness = 1
bindStroke.Parent = bindBtn

-- slider visual
local speedValueLabel = Instance.new("TextLabel")
speedValueLabel.Size = UDim2.new(0, 140, 0, 15)
speedValueLabel.Position = UDim2.new(0, 10, 0, 92)
speedValueLabel.BackgroundTransparency = 1
speedValueLabel.Text = "Speed: " .. string.format("%.1f", tpSpeed)
speedValueLabel.TextColor3 = TEXT_COLOR
speedValueLabel.Font = Enum.Font.SourceSans
speedValueLabel.TextSize = 13
speedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
speedValueLabel.Parent = mainFrame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0, 140, 0, 6)
sliderTrack.Position = UDim2.new(0, 10, 0, 112)
sliderTrack.BackgroundColor3 = BTN_OFF_COLOR
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = mainFrame

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 3)
trackCorner.Parent = sliderTrack

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(tpSpeed / 10, 0, 1, 0)
sliderFill.BackgroundColor3 = BTN_ON_COLOR
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 3)
fillCorner.Parent = sliderFill

-- 
local dragging, dragInput, dragStart, startPos
dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

dragHandle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

dragChangedConnection = UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

dragEndedConnection = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- slider
local function updateSlider(input)
    local minVal = 0
    local maxVal = 10
    local percentage = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
    
    sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    tpSpeed = math.round((minVal + (maxVal - minVal) * percentage) * 10) / 10
    speedValueLabel.Text = "Speed: " .. string.format("%.1f", tpSpeed)
end

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderActive = true
        updateSlider(input)
    end
end)

sliderChangedConnection = UserInputService.InputChanged:Connect(function(input)
    if sliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)

sliderEndedConnection = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderActive = false
    end
end)

-- keybind
bindBtn.MouseButton1Click:Connect(function()
    if isBinding then return end
    isBinding = true
    bindBtn.Text = "..."
    bindBtn.TextColor3 = Color3.fromRGB(255, 150, 0)
end)

-- infinite yield tpwalk
local function startTpWalk()
    if tpwalking then tpwalking:Disconnect() end
    
    tpwalking = RunService.Heartbeat:Connect(function(delta)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        if not (character and humanoid and humanoid.Parent) then
            if tpwalking then tpwalking:Disconnect() end
            return
        end

        if humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * tpSpeed * delta * 10)
        end
    end)
end

local function stopTpWalk()
    if tpwalking then
        tpwalking:Disconnect()
        tpwalking = nil
    end
end


local function setToggleState(state)
    isOn = state
    if isOn then
        toggleBtn.Text = "TPWALK: ON"
        toggleBtn.BackgroundColor3 = BTN_ON_COLOR
        toggleBtn.TextColor3 = TEXT_ON_COLOR
        startTpWalk()
    else
        toggleBtn.Text = "TPWALK: OFF"
        toggleBtn.BackgroundColor3 = BTN_OFF_COLOR
        toggleBtn.TextColor3 = TEXT_COLOR
        stopTpWalk()
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    setToggleState(not isOn)
end)


globalInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
        currentKeybind = input.KeyCode
        bindBtn.Text = currentKeybind.Name
        bindBtn.TextColor3 = TEXT_ON_COLOR
        isBinding = false
        return
    end
    
    if gameProcessed or isBinding then return end
    
    if input.KeyCode == currentKeybind then
        setToggleState(not isOn)
    end
end)

-- clean
closeBtn.MouseButton1Click:Connect(function()
    setToggleState(false) 
    
    if globalInputConnection then globalInputConnection:Disconnect() globalInputConnection = nil end
    if dragChangedConnection then dragChangedConnection:Disconnect() dragChangedConnection = nil end
    if dragEndedConnection then dragEndedConnection:Disconnect() dragEndedConnection = nil end
    if sliderChangedConnection then sliderChangedConnection:Disconnect() sliderChangedConnection = nil end
    if sliderEndedConnection then sliderEndedConnection:Disconnect() sliderEndedConnection = nil end
    
    screenGui:Destroy() 
end)
