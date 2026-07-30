local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer

local function getParent()
	if gethui then return gethui() end
	local ok, res = pcall(function() return CoreGui end)
	if ok then return res end
	return Player:WaitForChild("PlayerGui")
end
local parentGui = getParent()

-- clear old
pcall(function()
	local old = parentGui:FindFirstChild("CrosshairGUI_Sleek")
	if old then old:Destroy() end
	local oldCross = parentGui:FindFirstChild("CrosshairDisplay")
	if oldCross then oldCross:Destroy() end
end)

local connections = {}

--
local BG_COLOR = Color3.fromRGB(20, 20, 20)
local CARD_COLOR = Color3.fromRGB(28, 28, 34)
local BORDER_COLOR = Color3.fromRGB(45, 45, 55)
local TEXT_MAIN = Color3.fromRGB(240, 240, 240)
local TEXT_MUTED = Color3.fromRGB(150, 150, 160)
local GREEN_ACCENT = Color3.fromRGB(46, 185, 110)
local RED_ACCENT = Color3.fromRGB(235, 75, 75)
local BTN_BG = Color3.fromRGB(35, 35, 42)
local ICON_BLUE = Color3.fromRGB(18, 35, 70) 


local currentType = "plus_light" -- plus_light, plus_empty, circle, dot
local currentSize = 18
local currentColor = Color3.fromRGB(0, 255, 100)
local selectedTypeBtn = nil


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrosshairGUI_Sleek"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = parentGui

--drag
local function makeDraggable(guiObject, handleObject)
	local dragging, dragInput, dragStart, startPos
	local dragThreshold = 5
	local hasMoved = false

	local conn1 = handleObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			hasMoved = false
			dragStart = input.Position
			startPos = guiObject.Position
		end
	end)

	local conn2 = handleObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	local conn3 = UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			if not hasMoved and (math.abs(delta.X) > dragThreshold or math.abs(delta.Y) > dragThreshold) then
				hasMoved = true
			end
			if hasMoved then
				guiObject.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	local conn4 = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	table.insert(connections, conn1)
	table.insert(connections, conn2)
	table.insert(connections, conn3)
	table.insert(connections, conn4)

	return function() return hasMoved end
end


local floatCircle = Instance.new("Frame")
floatCircle.Name = "FloatingIcon"
floatCircle.Size = UDim2.fromOffset(46, 46)
floatCircle.Position = UDim2.new(0, 20, 0.5, -23)
floatCircle.BackgroundColor3 = ICON_BLUE
floatCircle.Active = true
floatCircle.Visible = true
floatCircle.Parent = ScreenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatCircle

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(40, 70, 120)
floatStroke.Thickness = 1.5
floatStroke.Parent = floatCircle


local iconPlus = Instance.new("Frame")
iconPlus.Size = UDim2.fromOffset(18, 18)
iconPlus.AnchorPoint = Vector2.new(0.5, 0.5)
iconPlus.Position = UDim2.fromScale(0.5, 0.5)
iconPlus.BackgroundTransparency = 1
iconPlus.Parent = floatCircle

local hLine = Instance.new("Frame")
hLine.Size = UDim2.new(1, 0, 0, 2)
hLine.Position = UDim2.new(0, 0, 0.5, -1)
hLine.BackgroundColor3 = Color3.fromRGB(180, 210, 255)
hLine.BorderSizePixel = 0
hLine.Parent = iconPlus

local vLine = Instance.new("Frame")
vLine.Size = UDim2.new(0, 2, 1, 0)
vLine.Position = UDim2.new(0.5, -1, 0, 0)
vLine.BackgroundColor3 = Color3.fromRGB(180, 210, 255)
vLine.BorderSizePixel = 0
vLine.Parent = iconPlus

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.fromScale(1, 1)
floatBtn.BackgroundTransparency = 1
floatBtn.Text = ""
floatBtn.Parent = floatCircle

local wasDragged = makeDraggable(floatCircle, floatBtn)


local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(290, 420)
MainFrame.Position = UDim2.new(0.5, -145, 0.5, -210)
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = BORDER_COLOR
mainStroke.Thickness = 1
mainStroke.Parent = MainFrame


local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundTransparency = 1
TitleBar.Active = true
TitleBar.Parent = MainFrame

makeDraggable(MainFrame, TitleBar)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -65, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Percy's Crosshair"
Title.TextColor3 = TEXT_MAIN
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(20, 20)
minBtn.Position = UDim2.new(1, -48, 0, 6)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = TEXT_MUTED
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(20, 20)
CloseButton.Position = UDim2.new(1, -24, 0, 6)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = RED_ACCENT
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.Parent = TitleBar


local CrosshairScreen = Instance.new("ScreenGui")
CrosshairScreen.Name = "CrosshairDisplay"
CrosshairScreen.ResetOnSpawn = false
CrosshairScreen.IgnoreGuiInset = true
CrosshairScreen.DisplayOrder = 999990
CrosshairScreen.Parent = parentGui


local containers = {}

local function createPlus(gap)
	local cont = Instance.new("Frame")
	cont.Name = "Plus"
	cont.Size = UDim2.fromOffset(1, 1)
	cont.AnchorPoint = Vector2.new(0.5, 0.5)
	cont.Position = UDim2.fromScale(0.5, 0.5)
	cont.BackgroundTransparency = 1
	cont.Visible = false
	cont.Parent = CrosshairScreen

	local thickness = 2
	local arm = currentSize

	local function makeArm(size, pos)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = currentColor
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = size
		f.Position = pos
		f.Parent = cont
		return f
	end

	
	makeArm(UDim2.fromOffset(arm, thickness), UDim2.new(0.5, -(gap/2 + arm/2), 0.5, 0))
	makeArm(UDim2.fromOffset(arm, thickness), UDim2.new(0.5, (gap/2 + arm/2), 0.5, 0))
	
	makeArm(UDim2.fromOffset(thickness, arm), UDim2.new(0.5, 0, 0.5, -(gap/2 + arm/2)))
	makeArm(UDim2.fromOffset(thickness, arm), UDim2.new(0.5, 0, 0.5, (gap/2 + arm/2)))

	return cont
end

local function createCircle()
	local cont = Instance.new("Frame")
	cont.Name = "Circle"
	cont.Size = UDim2.fromOffset(currentSize * 2, currentSize * 2)
	cont.AnchorPoint = Vector2.new(0.5, 0.5)
	cont.Position = UDim2.fromScale(0.5, 0.5)
	cont.BackgroundTransparency = 1
	cont.Visible = false
	cont.Parent = CrosshairScreen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = cont

	local stroke = Instance.new("UIStroke")
	stroke.Color = currentColor
	stroke.Thickness = math.clamp(currentSize / 9, 1.5, 4)
	stroke.Parent = cont

	return cont
end

local function createDot()
	local cont = Instance.new("Frame")
	cont.Name = "Dot"
	cont.Size = UDim2.fromOffset(math.max(3, currentSize / 3), math.max(3, currentSize / 3))
	cont.AnchorPoint = Vector2.new(0.5, 0.5)
	cont.Position = UDim2.fromScale(0.5, 0.5)
	cont.BackgroundColor3 = currentColor
	cont.BorderSizePixel = 0
	cont.Visible = false
	cont.Parent = CrosshairScreen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = cont

	return cont
end


containers.plus_light = createPlus(4)
containers.plus_empty = createPlus(10)
containers.circle = createCircle()
containers.dot = createDot()

local function clearAllCrosshairs()
	for _, c in pairs(containers) do
		if c then c:Destroy() end
	end
	containers = {}
end

local function rebuildCrosshair()
	
	if containers[currentType] then
		containers[currentType]:Destroy()
	end

	if currentType == "plus_light" then
		containers.plus_light = createPlus(4)
	elseif currentType == "plus_empty" then
		containers.plus_empty = createPlus(10)
	elseif currentType == "circle" then
		containers.circle = createCircle()
	elseif currentType == "dot" then
		containers.dot = createDot()
	end

	
	for name, cont in pairs(containers) do
		cont.Visible = (name == currentType)
	end
end

local function applySettings()
	rebuildCrosshair()
end



local typeLabel = Instance.new("TextLabel")
typeLabel.Position = UDim2.new(0, 12, 0, 40)
typeLabel.Size = UDim2.new(1, -24, 0, 18)
typeLabel.BackgroundTransparency = 1
typeLabel.Text = "CROSSHAIR TYPE"
typeLabel.TextColor3 = TEXT_MUTED
typeLabel.Font = Enum.Font.GothamBold
typeLabel.TextSize = 11
typeLabel.TextXAlignment = Enum.TextXAlignment.Left
typeLabel.Parent = MainFrame

local typeFrame = Instance.new("Frame")
typeFrame.Position = UDim2.new(0, 12, 0, 62)
typeFrame.Size = UDim2.new(1, -24, 0, 110)
typeFrame.BackgroundColor3 = CARD_COLOR
typeFrame.BorderSizePixel = 0
typeFrame.Parent = MainFrame

local typeCorner = Instance.new("UICorner")
typeCorner.CornerRadius = UDim.new(0, 6)
typeCorner.Parent = typeFrame

local typeStroke = Instance.new("UIStroke")
typeStroke.Color = BORDER_COLOR
typeStroke.Thickness = 1
typeStroke.Parent = typeFrame

local types = {
	{id = "plus_light", name = "Cross"},
	{id = "plus_empty", name = "Cross v2"},
	{id = "circle", name = "Circle"},
	{id = "dot", name = "Dot"},
}

local typeButtons = {}

for i, t in ipairs(types) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 22)
	btn.Position = UDim2.new(0, 8, 0, 8 + (i-1) * 25)
	btn.BackgroundColor3 = BTN_BG
	btn.Text = t.name
	btn.TextColor3 = TEXT_MAIN
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 13
	btn.Parent = typeFrame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = btn

	btn.MouseButton1Click:Connect(function()
		currentType = t.id
		for _, b in pairs(typeButtons) do
			b.BackgroundColor3 = BTN_BG
			b.TextColor3 = TEXT_MAIN
		end
		btn.BackgroundColor3 = GREEN_ACCENT
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		applySettings()
	end)

	typeButtons[t.id] = btn
end

-- 
typeButtons["plus_light"].BackgroundColor3 = GREEN_ACCENT
typeButtons["plus_light"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- size
local sizeLabel = Instance.new("TextLabel")
sizeLabel.Position = UDim2.new(0, 12, 0, 184)
sizeLabel.Size = UDim2.new(1, -24, 0, 18)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "SIZE"
sizeLabel.TextColor3 = TEXT_MUTED
sizeLabel.Font = Enum.Font.GothamBold
sizeLabel.TextSize = 11
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.Parent = MainFrame

local sizeFrame = Instance.new("Frame")
sizeFrame.Position = UDim2.new(0, 12, 0, 206)
sizeFrame.Size = UDim2.new(1, -24, 0, 42)
sizeFrame.BackgroundColor3 = CARD_COLOR
sizeFrame.BorderSizePixel = 0
sizeFrame.Parent = MainFrame

local sizeCorner = Instance.new("UICorner")
sizeCorner.CornerRadius = UDim.new(0, 6)
sizeCorner.Parent = sizeFrame

local sizeStroke = Instance.new("UIStroke")
sizeStroke.Color = BORDER_COLOR
sizeStroke.Thickness = 1
sizeStroke.Parent = sizeFrame

local sizeValue = Instance.new("TextLabel")
sizeValue.Size = UDim2.new(0, 50, 1, 0)
sizeValue.Position = UDim2.new(0.5, -25, 0, 0)
sizeValue.BackgroundTransparency = 1
sizeValue.Text = tostring(currentSize)
sizeValue.TextColor3 = TEXT_MAIN
sizeValue.Font = Enum.Font.GothamBold
sizeValue.TextSize = 16
sizeValue.Parent = sizeFrame

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.fromOffset(36, 28)
minusBtn.Position = UDim2.new(0, 10, 0.5, -14)
minusBtn.BackgroundColor3 = BTN_BG
minusBtn.Text = "-"
minusBtn.TextColor3 = TEXT_MAIN
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 18
minusBtn.Parent = sizeFrame

local minusCorner = Instance.new("UICorner")
minusCorner.CornerRadius = UDim.new(0, 4)
minusCorner.Parent = minusBtn

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.fromOffset(36, 28)
plusBtn.Position = UDim2.new(1, -46, 0.5, -14)
plusBtn.BackgroundColor3 = BTN_BG
plusBtn.Text = "+"
plusBtn.TextColor3 = TEXT_MAIN
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 18
plusBtn.Parent = sizeFrame

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 4)
plusCorner.Parent = plusBtn

minusBtn.MouseButton1Click:Connect(function()
	currentSize = math.clamp(currentSize - 2, 6, 50)
	sizeValue.Text = tostring(currentSize)
	applySettings()
end)

plusBtn.MouseButton1Click:Connect(function()
	currentSize = math.clamp(currentSize + 2, 6, 50)
	sizeValue.Text = tostring(currentSize)
	applySettings()
end)

-- color
local colorLabel = Instance.new("TextLabel")
colorLabel.Position = UDim2.new(0, 12, 0, 260)
colorLabel.Size = UDim2.new(1, -24, 0, 18)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "COLOR"
colorLabel.TextColor3 = TEXT_MUTED
colorLabel.Font = Enum.Font.GothamBold
colorLabel.TextSize = 11
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = MainFrame

local colorFrame = Instance.new("Frame")
colorFrame.Position = UDim2.new(0, 12, 0, 282)
colorFrame.Size = UDim2.new(1, -24, 0, 78)
colorFrame.BackgroundColor3 = CARD_COLOR
colorFrame.BorderSizePixel = 0
colorFrame.Parent = MainFrame

local colorCorner = Instance.new("UICorner")
colorCorner.CornerRadius = UDim.new(0, 6)
colorCorner.Parent = colorFrame

local colorStroke = Instance.new("UIStroke")
colorStroke.Color = BORDER_COLOR
colorStroke.Thickness = 1
colorStroke.Parent = colorFrame

local colors = {
	Color3.fromRGB(0, 255, 100),   -- green
	Color3.fromRGB(255, 255, 255), -- whte
	Color3.fromRGB(255, 50, 50),   -- red
	Color3.fromRGB(0, 200, 255),   -- cyan
	Color3.fromRGB(255, 200, 0),   -- yellow
	Color3.fromRGB(200, 100, 255), -- prple
	Color3.fromRGB(255, 140, 0),   -- orange
	Color3.fromRGB(180, 180, 180), -- grey
}

for i, col in ipairs(colors) do
	local btn = Instance.new("TextButton")
	local row = math.ceil(i / 4)
	local colIdx = ((i - 1) % 4)
	btn.Size = UDim2.fromOffset(28, 28)
	btn.Position = UDim2.new(0, 12 + colIdx * 36, 0, 10 + (row - 1) * 36)
	btn.BackgroundColor3 = col
	btn.Text = ""
	btn.Parent = colorFrame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color = BORDER_COLOR
	s.Thickness = 1
	s.Parent = btn

	btn.MouseButton1Click:Connect(function()
		currentColor = col
		applySettings()
	end)
end

-- 
local infoLabel = Instance.new("TextLabel")
infoLabel.Position = UDim2.new(0, 12, 0, 372)
infoLabel.Size = UDim2.new(1, -24, 0, 30)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Use - To Minimize Gui | X to Remove Crosshair And Gui"
infoLabel.TextColor3 = TEXT_MUTED
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = MainFrame


floatBtn.MouseButton1Click:Connect(function()
	if not wasDragged() then
		floatCircle.Visible = false
		MainFrame.Visible = true
	end
end)

minBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	floatCircle.Visible = true
end)

CloseButton.MouseButton1Click:Connect(function()
	for _, conn in ipairs(connections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	clearAllCrosshairs()
	CrosshairScreen:Destroy()
	ScreenGui:Destroy()
	print("[Crosshair GUI] Closed and cleaned.")
end)


applySettings()

print("[Percy's Crosshair GUI] Loaded")
