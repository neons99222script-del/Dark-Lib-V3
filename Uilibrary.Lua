--[[
	DarkUI Library
	A custom, self-contained UI Library for Roblox (PC + Mobile)

	Usage:
		local DarkUI = loadstring(game:HttpGet("PATH_TO_THIS_FILE"))()

		local Window = DarkUI:CreateWindow({
			Title = "DarkUI",
			KeySystem = true,
			KeySettings = {
				Title = "Key System",
				Subtitle = "Made By Darker - Official",
				Key = "By Dark",
				AutoSaveKey = true,
				AutoLoadKey = true,
			}
		})

		local MainTab = Window:CreateTab("Main")
		MainTab:CreateButton({Name = "Click Me", Callback = function() end})

		Window:AddConfig()

	All elements: Button, Dropdown, MultiDropdown, MegaDropdown, Toggle, Bind,
	Slider, Textbox, Notification, SeparateText, Text, Section, ProgressionBar
]]

local UserInputService = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local CoreGuiService    = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--=============================================================
-- FILESYSTEM SHIMS (executor functions, safe no-ops otherwise)
--=============================================================
local function safeCall(fn, ...)
	if typeof(fn) ~= "function" then return nil end
	local ok, res = pcall(fn, ...)
	if ok then return res end
	return nil
end

local writefile   = writefile or function() end
local readfile    = readfile or function() return nil end
local isfile      = isfile or function() return false end
local makefolder  = makefolder or function() end
local isfolder    = isfolder or function() return false end
local listfiles   = listfiles or function() return {} end
local delfile     = delfile or function() end

local CONFIG_FOLDER = "DarkUI"
local CONFIG_SUBFOLDER = "DarkUI/saves"
local KEY_FOLDER = "DarkUI/key"

pcall(function()
	if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
	if not isfolder(CONFIG_SUBFOLDER) then makefolder(CONFIG_SUBFOLDER) end
	if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
end)

--=============================================================
-- THEMES (20 built-in themes)
--=============================================================
local Themes = {
	["Dark Default"]  = {Main = Color3.fromRGB(24,24,27),  Second = Color3.fromRGB(32,32,36),  Stroke = Color3.fromRGB(50,50,55),  Accent = Color3.fromRGB(90,110,255), Text = Color3.fromRGB(240,240,245), SubText = Color3.fromRGB(160,160,170)},
	["Midnight Blue"]  = {Main = Color3.fromRGB(15,20,30),  Second = Color3.fromRGB(22,28,42),  Stroke = Color3.fromRGB(40,50,70),  Accent = Color3.fromRGB(60,140,255), Text = Color3.fromRGB(235,240,255), SubText = Color3.fromRGB(150,165,190)},
	["Crimson"]        = {Main = Color3.fromRGB(24,16,18),  Second = Color3.fromRGB(34,22,25),  Stroke = Color3.fromRGB(60,30,34),  Accent = Color3.fromRGB(220,60,70),  Text = Color3.fromRGB(245,235,236), SubText = Color3.fromRGB(180,150,152)},
	["Emerald"]        = {Main = Color3.fromRGB(14,22,18),  Second = Color3.fromRGB(20,32,26),  Stroke = Color3.fromRGB(35,60,45),  Accent = Color3.fromRGB(50,200,120), Text = Color3.fromRGB(235,245,238), SubText = Color3.fromRGB(155,180,163)},
	["Amethyst"]       = {Main = Color3.fromRGB(20,16,26),  Second = Color3.fromRGB(28,22,36),  Stroke = Color3.fromRGB(55,40,70),  Accent = Color3.fromRGB(160,90,230), Text = Color3.fromRGB(240,235,247), SubText = Color3.fromRGB(170,155,190)},
	["Sunset"]         = {Main = Color3.fromRGB(26,18,16),  Second = Color3.fromRGB(36,24,20),  Stroke = Color3.fromRGB(70,42,30),  Accent = Color3.fromRGB(255,130,60),  Text = Color3.fromRGB(247,238,233), SubText = Color3.fromRGB(190,160,145)},
	["Ocean"]          = {Main = Color3.fromRGB(12,20,24),  Second = Color3.fromRGB(18,30,35),  Stroke = Color3.fromRGB(30,55,63),  Accent = Color3.fromRGB(40,190,210), Text = Color3.fromRGB(232,245,247), SubText = Color3.fromRGB(150,180,185)},
	["Rose Gold"]      = {Main = Color3.fromRGB(26,20,22),  Second = Color3.fromRGB(36,28,30),  Stroke = Color3.fromRGB(70,48,50),  Accent = Color3.fromRGB(235,150,150), Text = Color3.fromRGB(247,238,238), SubText = Color3.fromRGB(190,160,160)},
	["Graphite"]       = {Main = Color3.fromRGB(18,18,18),  Second = Color3.fromRGB(26,26,26),  Stroke = Color3.fromRGB(45,45,45),  Accent = Color3.fromRGB(180,180,190), Text = Color3.fromRGB(240,240,240), SubText = Color3.fromRGB(150,150,150)},
	["Solar"]          = {Main = Color3.fromRGB(28,24,12),  Second = Color3.fromRGB(38,33,17),  Stroke = Color3.fromRGB(75,63,26),  Accent = Color3.fromRGB(255,205,60),  Text = Color3.fromRGB(247,244,232), SubText = Color3.fromRGB(190,180,145)},
	["Neon Pink"]      = {Main = Color3.fromRGB(20,10,18),  Second = Color3.fromRGB(30,15,27),  Stroke = Color3.fromRGB(60,25,55),  Accent = Color3.fromRGB(255,60,180), Text = Color3.fromRGB(247,235,245), SubText = Color3.fromRGB(190,150,180)},
	["Forest"]         = {Main = Color3.fromRGB(14,20,14),  Second = Color3.fromRGB(20,28,20),  Stroke = Color3.fromRGB(35,50,35),  Accent = Color3.fromRGB(110,180,80),  Text = Color3.fromRGB(235,242,233), SubText = Color3.fromRGB(160,178,155)},
	["Ice"]            = {Main = Color3.fromRGB(18,22,26),  Second = Color3.fromRGB(26,32,38),  Stroke = Color3.fromRGB(45,55,65),  Accent = Color3.fromRGB(150,220,245), Text = Color3.fromRGB(235,244,247), SubText = Color3.fromRGB(160,185,195)},
	["Blood Moon"]     = {Main = Color3.fromRGB(16,12,12),  Second = Color3.fromRGB(26,18,18),  Stroke = Color3.fromRGB(55,25,25),  Accent = Color3.fromRGB(200,30,30),  Text = Color3.fromRGB(245,232,232), SubText = Color3.fromRGB(180,145,145)},
	["Lavender"]       = {Main = Color3.fromRGB(22,20,28),  Second = Color3.fromRGB(30,28,38),  Stroke = Color3.fromRGB(55,50,70),  Accent = Color3.fromRGB(180,160,240), Text = Color3.fromRGB(242,240,247), SubText = Color3.fromRGB(175,168,190)},
	["Copper"]         = {Main = Color3.fromRGB(24,18,14),  Second = Color3.fromRGB(34,26,20),  Stroke = Color3.fromRGB(70,48,32),  Accent = Color3.fromRGB(220,130,70),  Text = Color3.fromRGB(245,236,230), SubText = Color3.fromRGB(185,158,140)},
	["Cyberpunk"]      = {Main = Color3.fromRGB(12,14,20),  Second = Color3.fromRGB(18,20,30),  Stroke = Color3.fromRGB(35,45,70),  Accent = Color3.fromRGB(255,225,50),  Text = Color3.fromRGB(235,240,247), SubText = Color3.fromRGB(150,180,190)},
	["Slate"]          = {Main = Color3.fromRGB(22,24,27),  Second = Color3.fromRGB(30,33,37),  Stroke = Color3.fromRGB(50,54,60),  Accent = Color3.fromRGB(120,150,180), Text = Color3.fromRGB(238,240,242), SubText = Color3.fromRGB(160,165,172)},
	["Light"]          = {Main = Color3.fromRGB(238,238,242), Second = Color3.fromRGB(248,248,250), Stroke = Color3.fromRGB(210,210,215), Accent = Color3.fromRGB(70,110,240), Text = Color3.fromRGB(25,25,30), SubText = Color3.fromRGB(90,90,100)},
	["Mono"]           = {Main = Color3.fromRGB(10,10,10),  Second = Color3.fromRGB(20,20,20),  Stroke = Color3.fromRGB(45,45,45),  Accent = Color3.fromRGB(255,255,255), Text = Color3.fromRGB(240,240,240), SubText = Color3.fromRGB(150,150,150)},
	["Gold"]           = {Main = Color3.fromRGB(22,20,14),  Second = Color3.fromRGB(32,29,20),  Stroke = Color3.fromRGB(70,60,30),  Accent = Color3.fromRGB(255,205,90),  Text = Color3.fromRGB(247,243,232), SubText = Color3.fromRGB(190,178,145)},
}

local ThemeOrder = {}
for name in pairs(Themes) do table.insert(ThemeOrder, name) end
table.sort(ThemeOrder)

--=============================================================
-- CORE HELPERS
--=============================================================
local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function Tween(obj, props, time, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(time or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function MakeDraggable(topbar, frame)
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		Tween(frame, {Position = newPos}, 0.08, Enum.EasingStyle.Sine)
	end

	topbar.InputBegan:Connect(function(input)
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

	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local function GetParentGui()
	local ok, gui = pcall(function()
		return CoreGuiService
	end)
	if ok and gui then
		local success = pcall(function()
			local test = Instance.new("ScreenGui")
			test.Parent = gui
			test:Destroy()
		end)
		if success then return gui end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

--=============================================================
-- LIBRARY OBJECT
--=============================================================
local Library = {}
Library.__index = Library
Library.Flags = {}
Library.CurrentTheme = Themes["Dark Default"]
Library.ThemeObjects = {} -- objects registered for live theme updates
Library.Options = {} -- element registry for search + config

function Library:RegisterThemeObject(obj, prop, key)
	table.insert(self.ThemeObjects, {Object = obj, Prop = prop, Key = key})
end

function Library:ApplyTheme(theme)
	self.CurrentTheme = theme
	for _, entry in ipairs(self.ThemeObjects) do
		if entry.Object and entry.Object.Parent then
			pcall(function()
				Tween(entry.Object, {[entry.Prop] = theme[entry.Key]}, 0.25)
			end)
		end
	end
end

--=============================================================
-- NOTIFICATIONS
--=============================================================
function Library:Notify(opts)
	opts = opts or {}
	local Title = opts.Title or "Notification"
	local Content = opts.Content or ""
	local Duration = opts.Duration or 4

	local theme = self.CurrentTheme
	local holder = self.NotificationHolder
	if not holder then return end

	local frame = Create("Frame", {
		BackgroundColor3 = theme.Second,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		BackgroundTransparency = 1,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 1}),
		Create("UIPadding", {PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12)}),
	})
	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18),
		Font = Enum.Font.GothamBold, Text = Title, TextColor3 = theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1,
	})
	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0),
		AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0,0,0,20),
		Font = Enum.Font.Gotham, Text = Content, TextColor3 = theme.SubText, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextTransparency = 1,
	})
	frame.Parent = holder

	Tween(frame, {BackgroundTransparency = 0}, 0.25)
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") then Tween(d, {TextTransparency = 0}, 0.25) end
		if d:IsA("UIStroke") then Tween(d, {Transparency = 0.4}, 0.25) end
	end

	task.delay(Duration, function()
		if not frame.Parent then return end
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("TextLabel") then Tween(d, {TextTransparency = 1}, 0.2) end
			if d:IsA("UIStroke") then Tween(d, {Transparency = 1}, 0.2) end
		end
		Tween(frame, {BackgroundTransparency = 1}, 0.2)
		task.wait(0.25)
		frame:Destroy()
	end)
end

--=============================================================
-- LOADING SCREEN
--=============================================================
local function ShowLoadingScreen(parentGui, libraryName, onComplete)
	local overlay = Create("Frame", {
		Name = "DarkUI_Loading",
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		ZIndex = 1000,
		Parent = parentGui,
	})

	local ring = Create("ImageLabel", {
		Parent = overlay,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 56, 0, 56),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -20),
		Image = "rbxassetid://4965945816", -- circular ring image (built-in style)
		ImageColor3 = Color3.fromRGB(255,255,255),
		ImageTransparency = 1,
		ZIndex = 1001,
	})

	local label = Create("TextLabel", {
		Parent = overlay,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 45),
		Font = Enum.Font.GothamBold,
		Text = "Loading " .. libraryName .. "...",
		TextColor3 = Color3.fromRGB(255,255,255),
		TextTransparency = 1,
		TextSize = 16,
		ZIndex = 1001,
	})

	-- fade in overlay to 60% transparency (40% opaque black)
	Tween(overlay, {BackgroundTransparency = 0.6}, 0.4)
	Tween(ring, {ImageTransparency = 0}, 0.4)
	Tween(label, {TextTransparency = 0}, 0.4)

	-- spin the ring
	local spinning = true
	task.spawn(function()
		while spinning do
			ring.Rotation = (ring.Rotation + 6) % 360
			task.wait(0.016)
		end
	end)

	task.delay(10, function()
		spinning = false
		Tween(overlay, {BackgroundTransparency = 1}, 0.4)
		Tween(ring, {ImageTransparency = 1}, 0.35)
		Tween(label, {TextTransparency = 1}, 0.35)
		task.wait(0.45)
		overlay:Destroy()
		if onComplete then onComplete() end
	end)
end

--=============================================================
-- KEY SYSTEM
--=============================================================
local function ShowKeySystem(parentGui, settings, onSuccess)
	local theme = Library.CurrentTheme
	local keyFile = KEY_FOLDER .. "/key.txt"

	-- auto load
	if settings.AutoLoadKey then
		local saved = safeCall(readfile, keyFile)
		if saved and saved == settings.Key then
			onSuccess()
			return
		end
	end

	local overlay = Create("Frame", {
		Name = "DarkUI_KeySystem",
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		ZIndex = 1000,
		Parent = parentGui,
	})

	local box = Create("Frame", {
		Parent = overlay,
		BackgroundColor3 = theme.Main,
		Size = UDim2.new(0, 340, 0, 190),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		BackgroundTransparency = 1,
		ZIndex = 1001,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 1}),
	})

	local title = Create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,26),
		Position = UDim2.new(0,0,0,16), Font = Enum.Font.GothamBold,
		Text = settings.Title or "Key System", TextColor3 = theme.Text, TextSize = 18,
		TextTransparency = 1, ZIndex = 1002,
	})
	local subtitle = Create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18),
		Position = UDim2.new(0,0,0,42), Font = Enum.Font.Gotham,
		Text = settings.Subtitle or "", TextColor3 = theme.SubText, TextSize = 13,
		TextTransparency = 1, ZIndex = 1002,
	})

	local inputHolder = Create("Frame", {
		Parent = box, BackgroundColor3 = theme.Second, BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 36), Position = UDim2.new(0, 16, 0, 78), ZIndex = 1002,
	}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

	local textbox = Create("TextBox", {
		Parent = inputHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-20,1,0),
		Position = UDim2.new(0,10,0,0), Font = Enum.Font.Gotham, PlaceholderText = "Enter key...",
		Text = "", TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 14,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1,
		PlaceholderTransparency = 1, ZIndex = 1002,
	})

	local submit = Create("TextButton", {
		Parent = box, BackgroundColor3 = theme.Accent, BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 36), Position = UDim2.new(0, 16, 0, 126),
		Font = Enum.Font.GothamBold, Text = "Submit", TextColor3 = Color3.new(1,1,1),
		TextTransparency = 1, TextSize = 14, ZIndex = 1002, AutoButtonColor = false,
	}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

	-- fade in
	Tween(overlay, {BackgroundTransparency = 0.55}, 0.35)
	Tween(box, {BackgroundTransparency = 0}, 0.35)
	for _, d in ipairs(box:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			Tween(d, {TextTransparency = 0}, 0.35)
			if d:IsA("TextButton") then Tween(d, {BackgroundTransparency = 0}, 0.35) end
		elseif d:IsA("UIStroke") then
			Tween(d, {Transparency = 0}, 0.35)
		elseif d:IsA("Frame") and d ~= box then
			Tween(d, {BackgroundTransparency = 0}, 0.35)
		elseif d:IsA("TextBox") then
			Tween(d, {TextTransparency = 0, PlaceholderTransparency = 0}, 0.35)
		end
	end

	local function attempt()
		local val = textbox.Text
		if val == settings.Key then
			if settings.AutoSaveKey then
				safeCall(writefile, keyFile, val)
			end
			for _, d in ipairs(box:GetDescendants()) do
				if d:IsA("GuiObject") then Tween(d, {BackgroundTransparency = 1}, 0.3) end
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then Tween(d, {TextTransparency = 1}, 0.3) end
			end
			Tween(overlay, {BackgroundTransparency = 1}, 0.35)
			Tween(box, {BackgroundTransparency = 1}, 0.3)
			task.wait(0.4)
			overlay:Destroy()
			onSuccess()
		else
			Tween(inputHolder, {BackgroundColor3 = Color3.fromRGB(120,40,40)}, 0.15)
			task.wait(0.2)
			Tween(inputHolder, {BackgroundColor3 = theme.Second}, 0.3)
		end
	end

	submit.MouseButton1Click:Connect(attempt)
	textbox.FocusLost:Connect(function(enterPressed)
		if enterPressed then attempt() end
	end)
end

--=============================================================
-- CREATE WINDOW
--=============================================================
function Library:CreateWindow(config)
	config = config or {}
	local WindowTitle = config.Title or "DarkUI"
	local KeySystemEnabled = config.KeySystem or false
	local KeySettings = config.KeySettings or {}

	local ParentGui = GetParentGui()

	local ScreenGui = Create("ScreenGui", {
		Name = "DarkUI_" .. WindowTitle:gsub("%s+", ""),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = ParentGui,
	})

	Library.ScreenGui = ScreenGui
	Library.NotificationHolder = Create("Frame", {
		Parent = ScreenGui, BackgroundTransparency = 1,
		Size = UDim2.new(0, 300, 1, -20), Position = UDim2.new(1, -320, 0, 10),
		AnchorPoint = Vector2.new(0,0),
	}, {
		Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8), VerticalAlignment = Enum.VerticalAlignment.Top}),
	})

	local theme = Library.CurrentTheme

	local mainSize = IS_MOBILE and UDim2.new(0, 480, 0, 320) or UDim2.new(0, 620, 0, 420)

	local Main = Create("Frame", {
		Name = "Main",
		Parent = ScreenGui,
		BackgroundColor3 = theme.Main,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = mainSize,
		ClipsDescendants = true,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
		Create("UIStroke", {Color = theme.Stroke, Thickness = 1}),
	})
	Library:RegisterThemeObject(Main, "BackgroundColor3", "Main")

	-- opening animation
	Main.Size = UDim2.new(0,0,0,0)
	Main.BackgroundTransparency = 1
	Tween(Main, {Size = mainSize, BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Back)

	-- top bar
	local TopBar = Create("Frame", {
		Parent = Main, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,40),
	}, {Create("UICorner", {CornerRadius = UDim.new(0,10)})})
	Library:RegisterThemeObject(TopBar, "BackgroundColor3", "Second")

	-- corner patch so bottom corners of topbar stay square
	Create("Frame", {Parent = TopBar, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,1,-10), BorderSizePixel = 0, ZIndex = 0})

	Create("TextLabel", {
		Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(1,-90,1,0), Position = UDim2.new(0,16,0,0),
		Font = Enum.Font.GothamBold, Text = WindowTitle, TextColor3 = theme.Text, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local CloseBtn = Create("TextButton", {
		Parent = TopBar, BackgroundColor3 = theme.Main, Size = UDim2.new(0,26,0,26),
		Position = UDim2.new(1,-34,0.5,-13), Text = "X", Font = Enum.Font.GothamBold,
		TextColor3 = theme.Text, TextSize = 13, AutoButtonColor = false,
	}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

	local MinimizeBtn = Create("TextButton", {
		Parent = TopBar, BackgroundColor3 = theme.Main, Size = UDim2.new(0,26,0,26),
		Position = UDim2.new(1,-66,0.5,-13), Text = "-", Font = Enum.Font.GothamBold,
		TextColor3 = theme.Text, TextSize = 16, AutoButtonColor = false,
	}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

	MakeDraggable(TopBar, Main)

	local minimized = false
	MinimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Tween(Main, {Size = UDim2.new(mainSize.X.Scale, mainSize.X.Offset, 0, 40)}, 0.3)
		else
			Tween(Main, {Size = mainSize}, 0.3)
		end
	end)

	local uiVisible = true
	CloseBtn.MouseButton1Click:Connect(function()
		uiVisible = not uiVisible
		if uiVisible then
			ScreenGui.Enabled = true
			Main.Size = UDim2.new(0,0,0,0)
			Tween(Main, {Size = minimized and UDim2.new(mainSize.X.Scale, mainSize.X.Offset, 0, 40) or mainSize}, 0.3)
		else
			Tween(Main, {Size = UDim2.new(0,0,0,0)}, 0.25)
			task.delay(0.26, function() if not uiVisible then ScreenGui.Enabled = false end end)
		end
	end)

	-- search bar
	local SearchHolder = Create("Frame", {
		Parent = Main, BackgroundColor3 = theme.Second, Size = UDim2.new(1,-32,0,32),
		Position = UDim2.new(0,16,0,50),
	}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})
	Library:RegisterThemeObject(SearchHolder, "BackgroundColor3", "Second")

	local SearchBox = Create("TextBox", {
		Parent = SearchHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0),
		Font = Enum.Font.Gotham, PlaceholderText = "Search elements...", Text = "",
		TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	})

	-- tab bar (left, auto scroll)
	local TabBar = Create("ScrollingFrame", {
		Parent = Main, BackgroundColor3 = theme.Second, Size = UDim2.new(0, 140, 1, -94),
		Position = UDim2.new(0, 16, 0, 90), ScrollBarThickness = 3, CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = theme.Accent,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0,8)}),
		Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)}),
		Create("UIPadding", {PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8)}),
	})
	Library:RegisterThemeObject(TabBar, "BackgroundColor3", "Second")

	-- content area
	local ContentHolder = Create("Frame", {
		Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, -172, 1, -94),
		Position = UDim2.new(0, 164, 0, 90),
	})

	local Window = setmetatable({}, {__index = Library})
	Window.Tabs = {}
	Window.TabButtons = {}
	Window.Main = Main
	Window.ContentHolder = ContentHolder
	Window.TabBar = TabBar
	Window.SearchBox = SearchBox
	Window.AllElements = {} -- for search: {NameLower=..., Frame=..., TabButton=...}
	Window.ConfigAdded = false

	-- search filter logic
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = SearchBox.Text:lower()
		if query == "" then
			for _, tab in pairs(Window.Tabs) do
				for _, el in ipairs(tab.Elements) do
					el.Frame.Visible = true
				end
			end
			return
		end
		for _, tab in pairs(Window.Tabs) do
			local anyVisible = false
			for _, el in ipairs(tab.Elements) do
				local match = el.Name:lower():find(query, 1, true) ~= nil
				el.Frame.Visible = match
				if match then anyVisible = true end
			end
			if anyVisible then
				Window:SelectTab(tab)
			end
		end
	end)

	function Window:SelectTab(tab)
		for _, t in pairs(self.Tabs) do
			t.Container.Visible = (t == tab)
			Tween(t.Button, {BackgroundColor3 = (t == tab) and theme.Accent or theme.Second}, 0.2)
		end
	end

	function Window:CreateTab(name, order)
		local theme = Library.CurrentTheme
		local TabButton = Create("TextButton", {
			Parent = TabBar, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,32),
			Font = Enum.Font.Gotham, Text = name, TextColor3 = theme.Text, TextSize = 13,
			AutoButtonColor = false, LayoutOrder = order or #self.Tabs + 1,
		}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

		local Container = Create("ScrollingFrame", {
			Parent = ContentHolder, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
			ScrollBarThickness = 3, CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = theme.Accent,
			Visible = false,
		}, {
			Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)}),
			Create("UIPadding", {PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8)}),
		})

		local Tab = setmetatable({}, {__index = Library})
		Tab.Name = name
		Tab.Button = TabButton
		Tab.Container = Container
		Tab.Elements = {}
		Tab.Window = Window

		table.insert(Window.Tabs, Tab)

		TabButton.MouseButton1Click:Connect(function()
			Window:SelectTab(Tab)
		end)

		if #Window.Tabs == 1 then
			Window:SelectTab(Tab)
		end

		--=====================================================
		-- ELEMENT: SECTION
		--=====================================================
		function Tab:CreateSection(name)
			local theme = Library.CurrentTheme
			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,0),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,8)}),
				Create("UIPadding", {PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12)}),
				Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)}),
			})
			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18),
				Font = Enum.Font.GothamBold, Text = name, TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			table.insert(self.Elements, {Name = name, Frame = Frame})

			local Section = {}
			Section.Frame = Frame
			-- allow adding elements directly under a section container (nested list)
			Section.Holder = Frame
			return Section
		end

		--=====================================================
		-- ELEMENT: TEXT / SEPARATE TEXT
		--=====================================================
		function Tab:CreateText(text)
			local theme = Library.CurrentTheme
			local Frame = Create("Frame", {Parent = self.Container, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,20)})
			local Label = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
				Font = Enum.Font.Gotham, Text = text, TextColor3 = theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			})
			table.insert(self.Elements, {Name = text, Frame = Frame})
			return {Set = function(_, t) Label.Text = t end}
		end

		function Tab:CreateSeparateText(text)
			local theme = Library.CurrentTheme
			local Frame = Create("Frame", {Parent = self.Container, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,24)})
			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-20,0,16),
				Font = Enum.Font.GothamBold, Text = text, TextColor3 = theme.SubText, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,0,0,0),
			})
			Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Stroke, Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,20),
			})
			table.insert(self.Elements, {Name = text, Frame = Frame})
			return Frame
		end

		--=====================================================
		-- ELEMENT: BUTTON
		--=====================================================
		function Tab:CreateButton(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local Frame = Create("TextButton", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36),
				Font = Enum.Font.Gotham, Text = "", AutoButtonColor = false,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})
			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.Gotham, Text = opts.Name or "Button", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Frame.MouseButton1Click:Connect(function()
				Tween(Frame, {BackgroundColor3 = theme.Accent}, 0.12)
				task.wait(0.12)
				Tween(Frame, {BackgroundColor3 = theme.Second}, 0.18)
				if opts.Callback then pcall(opts.Callback) end
			end)
			table.insert(self.Elements, {Name = opts.Name or "Button", Frame = Frame})
			return Frame
		end

		--=====================================================
		-- ELEMENT: TOGGLE SWITCH
		--=====================================================
		function Tab:CreateToggle(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local state = opts.Default or false

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36),
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-70,1,0), Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.Gotham, Text = opts.Name or "Toggle", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local SwitchBG = Create("Frame", {
				Parent = Frame, BackgroundColor3 = state and theme.Accent or theme.Main,
				Size = UDim2.new(0,40,0,20), Position = UDim2.new(1,-52,0.5,-10),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

			local Knob = Create("Frame", {
				Parent = SwitchBG, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,16,0,16),
				Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

			local Click = Create("TextButton", {Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""})

			local Toggle = {}
			Toggle.Value = state

			local function updateVisual()
				Tween(SwitchBG, {BackgroundColor3 = Toggle.Value and theme.Accent or theme.Main}, 0.2)
				Tween(Knob, {Position = Toggle.Value and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}, 0.2)
			end

			function Toggle:Set(v)
				Toggle.Value = v
				updateVisual()
				if opts.Callback then pcall(opts.Callback, v) end
			end

			Click.MouseButton1Click:Connect(function()
				Toggle:Set(not Toggle.Value)
			end)

			if opts.Flag then Library.Flags[opts.Flag] = Toggle end
			table.insert(self.Elements, {Name = opts.Name or "Toggle", Frame = Frame})
			return Toggle
		end

		--=====================================================
		-- ELEMENT: SLIDER
		--=====================================================
		function Tab:CreateSlider(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local Min, Max = opts.Min or 0, opts.Max or 100
			local value = opts.Default or Min

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,46),
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-90,0,20), Position = UDim2.new(0,12,0,6),
				Font = Enum.Font.Gotham, Text = opts.Name or "Slider", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			local ValueLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0,70,0,20), Position = UDim2.new(1,-82,0,6),
				Font = Enum.Font.Gotham, Text = tostring(value), TextColor3 = theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
			})

			local Track = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(1,-24,0,8), Position = UDim2.new(0,12,0,30),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

			local Fill = Create("Frame", {
				Parent = Track, BackgroundColor3 = theme.Accent, Size = UDim2.new((value-Min)/(Max-Min),0,1,0),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

			local Slider = {Value = value}

			local dragging = false
			local function setFromX(x)
				local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local v = Min + (Max - Min) * rel
				if opts.Increment then
					v = math.floor(v / opts.Increment + 0.5) * opts.Increment
				end
				v = math.clamp(v, Min, Max)
				Slider.Value = v
				Fill.Size = UDim2.new((v-Min)/(Max-Min),0,1,0)
				ValueLabel.Text = tostring(v)
				if opts.Callback then pcall(opts.Callback, v) end
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					setFromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					setFromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			function Slider:Set(v)
				v = math.clamp(v, Min, Max)
				Slider.Value = v
				Fill.Size = UDim2.new((v-Min)/(Max-Min),0,1,0)
				ValueLabel.Text = tostring(v)
				if opts.Callback then pcall(opts.Callback, v) end
			end

			if opts.Flag then Library.Flags[opts.Flag] = Slider end
			table.insert(self.Elements, {Name = opts.Name or "Slider", Frame = Frame})
			return Slider
		end

		--=====================================================
		-- ELEMENT: TEXTBOX
		--=====================================================
		function Tab:CreateTextbox(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36),
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.4,0,1,0), Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.Gotham, Text = opts.Name or "Textbox", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			local Box = Create("TextBox", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0.55,-12,0,26), Position = UDim2.new(0.45,0,0.5,-13),
				Font = Enum.Font.Gotham, PlaceholderText = opts.PlaceholderText or "...", Text = opts.Default or "",
				TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 13, ClearTextOnFocus = false,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

			local Textbox = {Value = opts.Default or ""}
			Box.FocusLost:Connect(function(enterPressed)
				Textbox.Value = Box.Text
				if opts.Callback then pcall(opts.Callback, Box.Text, enterPressed) end
			end)

			if opts.Flag then Library.Flags[opts.Flag] = Textbox end
			table.insert(self.Elements, {Name = opts.Name or "Textbox", Frame = Frame})
			return Textbox
		end

		--=====================================================
		-- ELEMENT: BIND (keybind)
		--=====================================================
		function Tab:CreateBind(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local currentKey = opts.Default or Enum.KeyCode.Unknown
			local listening = false

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36),
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.Gotham, Text = opts.Name or "Bind", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local KeyButton = Create("TextButton", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0,80,0,26), Position = UDim2.new(1,-92,0.5,-13),
				Font = Enum.Font.Gotham, Text = currentKey.Name, TextColor3 = theme.Text, TextSize = 12, AutoButtonColor = false,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

			local Bind = {Value = currentKey}

			KeyButton.MouseButton1Click:Connect(function()
				listening = true
				KeyButton.Text = "..."
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					Bind.Value = input.KeyCode
					KeyButton.Text = input.KeyCode.Name
					listening = false
					if opts.Callback then pcall(opts.Callback, input.KeyCode) end
				elseif not listening and not gpe and input.KeyCode == Bind.Value and opts.OnPress then
					pcall(opts.OnPress)
				end
			end)

			if opts.Flag then Library.Flags[opts.Flag] = Bind end
			table.insert(self.Elements, {Name = opts.Name or "Bind", Frame = Frame})
			return Bind
		end

		--=====================================================
		-- ELEMENT: PROGRESSION BAR
		--=====================================================
		function Tab:CreateProgressionBar(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local Min, Max = opts.Min or 0, opts.Max or 100
			local value = opts.Default or Min

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,42),
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-20,0,16), Position = UDim2.new(0,12,0,6),
				Font = Enum.Font.Gotham, Text = opts.Name or "Progress", TextColor3 = theme.Text, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local Track = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(1,-24,0,10), Position = UDim2.new(0,12,0,25),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

			local Fill = Create("Frame", {
				Parent = Track, BackgroundColor3 = theme.Accent, Size = UDim2.new((value-Min)/(Max-Min),0,1,0),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

			local Bar = {Value = value}
			function Bar:Set(v)
				v = math.clamp(v, Min, Max)
				Bar.Value = v
				Tween(Fill, {Size = UDim2.new((v-Min)/(Max-Min),0,1,0)}, 0.25)
			end

			table.insert(self.Elements, {Name = opts.Name or "Progress", Frame = Frame})
			return Bar
		end

		--=====================================================
		-- ELEMENT: DROPDOWN (single select)
		--=====================================================
		function Tab:CreateDropdown(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local options = opts.Options or {}
			local selected = opts.Default

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36), ClipsDescendants = true,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.5,0,0,36), Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.Gotham, Text = opts.Name or "Dropdown", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local SelectedLabel = Create("TextButton", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0.45,-12,0,26), Position = UDim2.new(0.55,0,0,5),
				Font = Enum.Font.Gotham, Text = tostring(selected or "Select..."), TextColor3 = theme.SubText, TextSize = 12,
				AutoButtonColor = false,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

			local ListHolder = Create("Frame", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-24,0,0), Position = UDim2.new(0,12,0,40),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})})

			local Dropdown = {Value = selected, Options = options}
			local open = false

			local function rebuildList()
				for _, c in ipairs(ListHolder:GetChildren()) do
					if not c:IsA("UIListLayout") then c:Destroy() end
				end
				for _, opt in ipairs(Dropdown.Options) do
					local OptBtn = Create("TextButton", {
						Parent = ListHolder, BackgroundColor3 = theme.Main, Size = UDim2.new(1,0,0,26),
						Font = Enum.Font.Gotham, Text = tostring(opt), TextColor3 = theme.Text, TextSize = 12,
						AutoButtonColor = false,
					}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})
					OptBtn.MouseButton1Click:Connect(function()
						Dropdown.Value = opt
						SelectedLabel.Text = tostring(opt)
						open = false
						Tween(Frame, {Size = UDim2.new(1,0,0,36)}, 0.2)
						if opts.Callback then pcall(opts.Callback, opt) end
					end)
				end
			end
			rebuildList()

			function Dropdown:Refresh(newOptions)
				Dropdown.Options = newOptions
				rebuildList()
			end

			function Dropdown:Set(v)
				Dropdown.Value = v
				SelectedLabel.Text = tostring(v)
				if opts.Callback then pcall(opts.Callback, v) end
			end

			SelectedLabel.MouseButton1Click:Connect(function()
				open = not open
				if open then
					local h = 40 + (#Dropdown.Options * 30)
					Tween(Frame, {Size = UDim2.new(1,0,0,h)}, 0.22)
				else
					Tween(Frame, {Size = UDim2.new(1,0,0,36)}, 0.22)
				end
			end)

			if opts.Flag then Library.Flags[opts.Flag] = Dropdown end
			table.insert(self.Elements, {Name = opts.Name or "Dropdown", Frame = Frame})
			return Dropdown
		end

		--=====================================================
		-- ELEMENT: MULTI DROPDOWN
		--=====================================================
		function Tab:CreateMultiDropdown(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme
			local options = opts.Options or {}
			local selectedSet = {}
			for _, v in ipairs(opts.Default or {}) do selectedSet[v] = true end

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36), ClipsDescendants = true,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.5,0,0,36), Position = UDim2.new(0,12,0,0),
				Font = Enum.Font.Gotham, Text = opts.Name or "MultiDropdown", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local SelectedLabel = Create("TextButton", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0.45,-12,0,26), Position = UDim2.new(0.55,0,0,5),
				Font = Enum.Font.Gotham, Text = "Select...", TextColor3 = theme.SubText, TextSize = 12,
				AutoButtonColor = false,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})

			local ListHolder = Create("Frame", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-24,0,0), Position = UDim2.new(0,12,0,40),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})})

			local MultiDropdown = {Value = selectedSet, Options = options}
			local open = false

			local function updateLabel()
				local names = {}
				for k, v in pairs(MultiDropdown.Value) do if v then table.insert(names, k) end end
				SelectedLabel.Text = #names > 0 and table.concat(names, ", ") or "Select..."
			end

			local function rebuildList()
				for _, c in ipairs(ListHolder:GetChildren()) do
					if not c:IsA("UIListLayout") then c:Destroy() end
				end
				for _, opt in ipairs(MultiDropdown.Options) do
					local isOn = MultiDropdown.Value[opt] or false
					local OptBtn = Create("TextButton", {
						Parent = ListHolder, BackgroundColor3 = isOn and theme.Accent or theme.Main, Size = UDim2.new(1,0,0,26),
						Font = Enum.Font.Gotham, Text = tostring(opt), TextColor3 = theme.Text, TextSize = 12,
						AutoButtonColor = false,
					}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})
					OptBtn.MouseButton1Click:Connect(function()
						MultiDropdown.Value[opt] = not MultiDropdown.Value[opt]
						Tween(OptBtn, {BackgroundColor3 = MultiDropdown.Value[opt] and theme.Accent or theme.Main}, 0.15)
						updateLabel()
						if opts.Callback then pcall(opts.Callback, MultiDropdown.Value) end
					end)
				end
			end
			rebuildList()
			updateLabel()

			SelectedLabel.MouseButton1Click:Connect(function()
				open = not open
				if open then
					local h = 40 + (#MultiDropdown.Options * 30)
					Tween(Frame, {Size = UDim2.new(1,0,0,h)}, 0.22)
				else
					Tween(Frame, {Size = UDim2.new(1,0,0,36)}, 0.22)
				end
			end)

			if opts.Flag then Library.Flags[opts.Flag] = MultiDropdown end
			table.insert(self.Elements, {Name = opts.Name or "MultiDropdown", Frame = Frame})
			return MultiDropdown
		end

		--=====================================================
		-- ELEMENT: MEGA DROPDOWN (holds any elements except dropdowns)
		--=====================================================
		function Tab:CreateMegaDropdown(opts)
			opts = opts or {}
			local theme = Library.CurrentTheme

			local Frame = Create("Frame", {
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,36), ClipsDescendants = true,
			}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

			local HeaderBtn = Create("TextButton", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,36),
				Font = Enum.Font.GothamBold, Text = "  " .. (opts.Name or "Mega Dropdown"), TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
			})

			local Inner = Create("Frame", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-24,0,0), Position = UDim2.new(0,12,0,40),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})})

			local open = false
			HeaderBtn.MouseButton1Click:Connect(function()
				open = not open
				if open then
					task.wait()
					Tween(Frame, {Size = UDim2.new(1,0,0, 46 + Inner.AbsoluteSize.Y)}, 0.25)
				else
					Tween(Frame, {Size = UDim2.new(1,0,0,36)}, 0.22)
				end
			end)

			-- MegaDropdown accepts a limited element set (no nested dropdowns)
			local MegaTabProxy = setmetatable({Container = Inner, Elements = {}, Window = Window}, {__index = Tab})
			-- disable dropdown-type creation inside mega dropdown
			MegaTabProxy.CreateDropdown = function() warn("DarkUI: Dropdowns cannot be nested inside a MegaDropdown.") end
			MegaTabProxy.CreateMultiDropdown = function() warn("DarkUI: MultiDropdowns cannot be nested inside a MegaDropdown.") end
			MegaTabProxy.CreateMegaDropdown = function() warn("DarkUI: MegaDropdowns cannot be nested inside a MegaDropdown.") end

			table.insert(self.Elements, {Name = opts.Name or "Mega Dropdown", Frame = Frame})
			return MegaTabProxy
		end

		return Tab
	end

	--=========================================================
	-- CONFIG TAB (AddConfig)
	--=========================================================
	function Window:AddConfig()
		if self.ConfigAdded then return end
		self.ConfigAdded = true

		local ConfigTab = self:CreateTab("Settings")
		local theme = Library.CurrentTheme

		ConfigTab:CreateSeparateText("Appearance")

		-- transparency slider
		local applyTransparency = false
		local TransparencySlider = ConfigTab:CreateSlider({
			Name = "UI Transparency",
			Min = 0, Max = 90, Default = 0,
			Callback = function(v)
				if applyTransparency then
					local alpha = v / 100
					Tween(Main, {BackgroundTransparency = alpha}, 0.15)
					Tween(TopBar, {BackgroundTransparency = alpha}, 0.15)
				end
			end,
		})

		ConfigTab:CreateToggle({
			Name = "Apply Transparency",
			Default = false,
			Callback = function(v)
				applyTransparency = v
				local alpha = applyTransparency and (TransparencySlider.Value / 100) or 0
				Tween(Main, {BackgroundTransparency = alpha}, 0.15)
				Tween(TopBar, {BackgroundTransparency = alpha}, 0.15)
			end,
		})

		-- theme dropdown (20 themes)
		ConfigTab:CreateDropdown({
			Name = "Theme",
			Options = ThemeOrder,
			Default = "Dark Default",
			Callback = function(v)
				local newTheme = Themes[v]
				if newTheme then Library:ApplyTheme(newTheme) end
			end,
		})

		ConfigTab:CreateSeparateText("Configuration Saves")

		-- refresh saved files list
		local function getSaveNames()
			local names = {}
			local ok, files = pcall(listfiles, CONFIG_SUBFOLDER)
			if ok and files then
				for _, path in ipairs(files) do
					local fname = path:match("([^/\\]+)%.json$")
					if fname then table.insert(names, fname) end
				end
			end
			return names
		end

		local SavesDropdown = ConfigTab:CreateDropdown({
			Name = "Saved Configs",
			Options = getSaveNames(),
			Callback = function() end,
		})

		-- gather current config state from all flags
		local function gatherFlags()
			local data = {}
			for flag, obj in pairs(Library.Flags) do
				if obj.Value ~= nil then
					if typeof(obj.Value) == "EnumItem" then
						data[flag] = {__enum = true, name = obj.Value.Name}
					elseif typeof(obj.Value) == "table" then
						data[flag] = obj.Value
					else
						data[flag] = obj.Value
					end
				end
			end
			return data
		end

		local function applyFlags(data)
			for flag, val in pairs(data) do
				local obj = Library.Flags[flag]
				if obj then
					if typeof(val) == "table" and val.__enum then
						if obj.Set then obj:Set(Enum.KeyCode[val.name]) else obj.Value = Enum.KeyCode[val.name] end
					else
						if obj.Set then obj:Set(val) else obj.Value = val end
					end
				end
			end
		end

		-- SAVE modal (blur + name textbox, enter to confirm)
		local SaveBtn = ConfigTab:CreateButton({
			Name = "Save Configuration",
			Callback = function()
				local Blur = Instance.new("BlurEffect")
				Blur.Size = 0
				Blur.Parent = game:GetService("Lighting")
				Tween(Blur, {Size = 18}, 0.3)

				local Overlay = Create("Frame", {
					Parent = ScreenGui, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1,
					Size = UDim2.new(1,0,1,0), ZIndex = 900,
				})
				Tween(Overlay, {BackgroundTransparency = 0.5}, 0.3)

				local Modal = Create("Frame", {
					Parent = Overlay, BackgroundColor3 = theme.Main, Size = UDim2.new(0,320,0,140),
					AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
					BackgroundTransparency = 1, ZIndex = 901,
				}, {Create("UICorner", {CornerRadius = UDim.new(0,10)}), Create("UIStroke", {Color = theme.Stroke, Transparency = 1})})

				local MTitle = Create("TextLabel", {
					Parent = Modal, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,24), Position = UDim2.new(0,0,0,16),
					Font = Enum.Font.GothamBold, Text = "Save Configuration", TextColor3 = theme.Text, TextSize = 16, TextTransparency = 1, ZIndex = 902,
				})

				local NameBoxHolder = Create("Frame", {
					Parent = Modal, BackgroundColor3 = theme.Second, BackgroundTransparency = 1,
					Size = UDim2.new(1,-32,0,34), Position = UDim2.new(0,16,0,54), ZIndex = 902,
				}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})

				local NameBox = Create("TextBox", {
					Parent = NameBoxHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0),
					Font = Enum.Font.Gotham, PlaceholderText = "Save name...", Text = "",
					TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, PlaceholderTransparency = 1, ZIndex = 902,
				})

				Tween(Modal, {BackgroundTransparency = 0}, 0.3)
				for _, d in ipairs(Modal:GetDescendants()) do
					if d:IsA("TextLabel") then Tween(d, {TextTransparency = 0}, 0.3) end
					if d:IsA("Frame") then Tween(d, {BackgroundTransparency = 0}, 0.3) end
					if d:IsA("UIStroke") then Tween(d, {Transparency = 0}, 0.3) end
					if d:IsA("TextBox") then Tween(d, {TextTransparency = 0, PlaceholderTransparency = 0}, 0.3) end
				end
				NameBox:CaptureFocus()

				local function closeModal()
					Tween(Overlay, {BackgroundTransparency = 1}, 0.25)
					Tween(Modal, {BackgroundTransparency = 1}, 0.25)
					Tween(Blur, {Size = 0}, 0.3)
					for _, d in ipairs(Modal:GetDescendants()) do
						if d:IsA("TextLabel") or d:IsA("TextBox") then Tween(d, {TextTransparency = 1}, 0.25) end
						if d:IsA("Frame") then Tween(d, {BackgroundTransparency = 1}, 0.25) end
						if d:IsA("UIStroke") then Tween(d, {Transparency = 1}, 0.25) end
					end
					task.delay(0.35, function()
						Overlay:Destroy()
						Blur:Destroy()
					end)
				end

				NameBox.FocusLost:Connect(function(enterPressed)
					if enterPressed and NameBox.Text ~= "" then
						local saveName = NameBox.Text
						local data = gatherFlags()
						local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
						if ok then
							safeCall(writefile, CONFIG_SUBFOLDER .. "/" .. saveName .. ".json", encoded)
							SavesDropdown:Refresh(getSaveNames())
							SavesDropdown:Set(saveName)
							Library:Notify({Title = "Configuration Saved", Content = "Saved as \"" .. saveName .. "\"", Duration = 3})
						end
						closeModal()
					elseif not enterPressed then
						closeModal()
					end
				end)
			end,
		})

		-- LOAD button
		ConfigTab:CreateButton({
			Name = "Load Configuration",
			Callback = function()
				local name = SavesDropdown.Value
				if not name then
					Library:Notify({Title = "Load Failed", Content = "No configuration selected.", Duration = 3})
					return
				end
				local content = safeCall(readfile, CONFIG_SUBFOLDER .. "/" .. name .. ".json")
				if not content then
					Library:Notify({Title = "Load Failed", Content = "Could not read save file.", Duration = 3})
					return
				end
				local ok, data = pcall(HttpService.JSONDecode, HttpService, content)
				if ok then
					applyFlags(data)
					Library:Notify({Title = "Configuration Loaded", Content = "Loaded \"" .. name .. "\"", Duration = 3})
				else
					Library:Notify({Title = "Load Failed", Content = "Corrupted save file.", Duration = 3})
				end
			end,
		})

		return ConfigTab
	end

	-- Loading screen, then key system, then reveal
	Main.Visible = false
	ScreenGui.Enabled = true

	ShowLoadingScreen(ScreenGui, WindowTitle, function()
		Main.Visible = true
		if KeySystemEnabled then
			Main.Visible = false
			ShowKeySystem(ScreenGui, KeySettings, function()
				Main.Visible = true
			end)
		end
	end)

	return Window
end

return Library
