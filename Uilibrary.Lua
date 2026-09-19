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
			},
			-- Optional personalization (both default to the flat theme look
			-- when omitted or left as an empty string):
			BackgroundImage = "rbxassetid://0",  -- texture for the window's background
			OpenButtonImage = "rbxassetid://0",  -- texture for the floating open bubble
			Theme = "Ocean",                     -- starting theme name (see ThemeOrder / the Theme dropdown); omit for "Dark Default"
		})

		local MainTab = Window:CreateTab("Main")
		MainTab:CreateButton({Name = "Click Me", Callback = function() end})

		Window:AddConfig()

	The window background texture (when set) fades in/out together with the
	"UI Transparency" slider in the Settings tab added by Window:AddConfig(),
	just like the rest of the window.

	Changing the theme at runtime (e.g. from your own script, not just the
	Settings tab) works the same way: DarkUI:SetTheme("Cyberpunk").

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

-- Like MakeDraggable, but for a small standalone button that should also
-- respond to a plain click/tap: dragging it moves it around the screen,
-- while a tap that doesn't move past a small threshold fires onClick.
-- Used by the floating "reopen" bubble.
local function MakeDraggableToggle(button, onClick)
	local dragging = false
	local dragInput, dragStart, startPos
	local moved = false
	local MOVE_THRESHOLD = 6

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = button.Position
		end
	end)

	button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			if delta.Magnitude > MOVE_THRESHOLD then moved = true end
			button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
			dragging = false
			if not moved then
				onClick()
			end
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
Library.CurrentTheme = {}
Library.CurrentThemeName = "Dark Default"
for k, v in pairs(Themes[Library.CurrentThemeName]) do Library.CurrentTheme[k] = v end
Library.ThemeObjects = {} -- objects registered for live theme updates
Library.Options = {} -- element registry for search + config

function Library:RegisterThemeObject(obj, prop, key)
	table.insert(self.ThemeObjects, {Object = obj, Prop = prop, Key = key})
end

-- For elements whose color depends on runtime state (a Toggle's on/off color,
-- a Dropdown's selected-option highlight, the active Tab), register a callback
-- here. ApplyTheme calls every refresher after the theme table is updated so
-- these elements re-render with the new colors immediately.
Library.ThemeRefreshers = {}
function Library:OnThemeRefresh(fn)
	table.insert(self.ThemeRefreshers, fn)
end

-- Deletes any saved Key System key so ShowKeySystem stops auto-bypassing.
-- Call DarkUI:ResetKey() from the command bar/console while testing.
function Library:ResetKey()
	local ok = pcall(function()
		if isfile(KEY_FOLDER .. "/key.txt") then
			delfile(KEY_FOLDER .. "/key.txt")
		end
	end)
	return ok
end

function Library:ApplyTheme(newTheme)
	-- Mutate the existing CurrentTheme table in place (instead of replacing the
	-- reference) so every element that captured "local theme = Library.CurrentTheme"
	-- at creation time automatically reads the new colors on its next hover/click/
	-- state-change, without needing to be individually re-registered.
	local theme = self.CurrentTheme
	for key, value in pairs(newTheme) do
		theme[key] = value
	end
	for _, entry in ipairs(self.ThemeObjects) do
		if entry.Object and entry.Object.Parent then
			pcall(function()
				Tween(entry.Object, {[entry.Prop] = theme[entry.Key]}, 0.25)
			end)
		end
	end
	for _, refresh in ipairs(self.ThemeRefreshers) do
		pcall(refresh)
	end
end

-- Sets the theme by its name, exactly as it appears in the "Theme" dropdown
-- (e.g. "Ocean", "Cyberpunk", "Light"...). Returns true on success, false if
-- the name doesn't match any built-in theme. This is what CreateWindow's
-- Theme = "..." option and the Settings tab's Theme dropdown both call under
-- the hood, so Library.CurrentThemeName always reflects what's on screen.
function Library:SetTheme(name)
	local themeTable = Themes[name]
	if not themeTable then
		warn("[DarkUI] Unknown theme name: \"" .. tostring(name) .. "\". Check the spelling against the Theme dropdown options.")
		return false
	end
	self.CurrentThemeName = name
	self:ApplyTheme(themeTable)
	return true
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
		Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 1}),
		Create("UIPadding", {PaddingTop = UDim.new(0,12), PaddingBottom = UDim.new(0,12), PaddingLeft = UDim.new(0,16), PaddingRight = UDim.new(0,14)}),
	})

	local AccentBar = Create("Frame", {
		Parent = frame, BackgroundColor3 = theme.Accent, BackgroundTransparency = 1,
		Size = UDim2.new(0,3,1,-16), Position = UDim2.new(0,0,0,8),
	}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,-4,0,18), Position = UDim2.new(0,4,0,0),
		Font = Enum.Font.GothamBold, Text = Title, TextColor3 = theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1,
	})
	Create("TextLabel", {
		Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,-4,0,0),
		AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0,4,0,20),
		Font = Enum.Font.Gotham, Text = Content, TextColor3 = theme.SubText, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextTransparency = 1,
	})
	frame.Parent = holder

	Tween(frame, {BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Quint)
	Tween(AccentBar, {BackgroundTransparency = 0}, 0.3)
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") then Tween(d, {TextTransparency = 0}, 0.3) end
		if d:IsA("UIStroke") then Tween(d, {Transparency = 0.4}, 0.3) end
	end

	task.delay(Duration, function()
		if not frame.Parent then return end
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("TextLabel") then Tween(d, {TextTransparency = 1}, 0.2) end
			if d:IsA("UIStroke") then Tween(d, {Transparency = 1}, 0.2) end
			if d == AccentBar then Tween(d, {BackgroundTransparency = 1}, 0.2) end
		end
		Tween(frame, {BackgroundTransparency = 1}, 0.25)
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

	local function cleanRead()
		local saved = safeCall(readfile, keyFile)
		if saved then
			saved = saved:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace/newlines
		end
		return saved
	end

	-- auto load
	if settings.AutoLoadKey then
		local saved = cleanRead()
		if saved and saved == settings.Key then
			warn("[DarkUI] Key System skipped: a matching saved key was found (AutoLoadKey = true). Call DarkUI:ResetKey() to force it to show again.")
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
		Size = UDim2.new(0, 360, 0, 230),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1001,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 16)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 1, Thickness = 1}),
	})

	-- accent glow strip along the top of the modal
	local GlowStrip = Create("Frame", {
		Parent = box, BackgroundColor3 = theme.Accent, BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,4), ZIndex = 1002,
	}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
	Library:RegisterThemeObject(GlowStrip, "BackgroundColor3", "Accent")

	-- lock icon badge
	local IconBadge = Create("Frame", {
		Parent = box, BackgroundColor3 = theme.Second, BackgroundTransparency = 1,
		Size = UDim2.new(0,48,0,48), AnchorPoint = Vector2.new(0.5,0),
		Position = UDim2.new(0.5,0,0,20), ZIndex = 1002,
	}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
	local IconImage = Create("ImageLabel", {
		Parent = IconBadge, BackgroundTransparency = 1, Size = UDim2.new(0,22,0,22),
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
		Image = "rbxassetid://10723396438", ImageColor3 = theme.Accent, ImageTransparency = 1, ZIndex = 1003,
	})
	Library:RegisterThemeObject(IconImage, "ImageColor3", "Accent")

	local title = Create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1,-40,0,26),
		Position = UDim2.new(0,20,0,78), Font = Enum.Font.GothamBold,
		Text = settings.Title or "Key System", TextColor3 = theme.Text, TextSize = 18,
		TextTransparency = 1, ZIndex = 1002, TextXAlignment = Enum.TextXAlignment.Center,
	})
	local subtitle = Create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1,-40,0,18),
		Position = UDim2.new(0,20,0,104), Font = Enum.Font.Gotham,
		Text = settings.Subtitle or "", TextColor3 = theme.SubText, TextSize = 13,
		TextTransparency = 1, ZIndex = 1002, TextXAlignment = Enum.TextXAlignment.Center,
	})

	local inputHolder = Create("Frame", {
		Parent = box, BackgroundColor3 = theme.Second, BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 0, 38), Position = UDim2.new(0, 20, 0, 134), ZIndex = 1002,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0,10)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 1}),
	})

	local textbox = Create("TextBox", {
		Parent = inputHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-24,1,0),
		Position = UDim2.new(0,12,0,0), Font = Enum.Font.Gotham, PlaceholderText = "Enter key...",
		Text = "", TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 14,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1,
		ZIndex = 1002,
	})

	local submit = Create("TextButton", {
		Parent = box, BackgroundColor3 = theme.Accent, BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 0, 38), Position = UDim2.new(0, 20, 0, 182),
		Font = Enum.Font.GothamBold, Text = "Submit", TextColor3 = Color3.new(1,1,1),
		TextTransparency = 1, TextSize = 14, ZIndex = 1002, AutoButtonColor = false,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0,10)}),
		Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(230,230,230)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.85),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rotation = 90,
		}),
	})
	Library:RegisterThemeObject(submit, "BackgroundColor3", "Accent")

	-- fade in
	Tween(overlay, {BackgroundTransparency = 0.55}, 0.35)
	Tween(box, {BackgroundTransparency = 0}, 0.35)
	Tween(GlowStrip, {BackgroundTransparency = 0}, 0.4)
	Tween(IconImage, {ImageTransparency = 0}, 0.45)
	for _, d in ipairs(box:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			Tween(d, {TextTransparency = 0}, 0.35)
			if d:IsA("TextButton") then Tween(d, {BackgroundTransparency = 0}, 0.35) end
		elseif d:IsA("UIStroke") then
			Tween(d, {Transparency = 0.5}, 0.35)
		elseif d:IsA("Frame") and d ~= box and d ~= GlowStrip then
			Tween(d, {BackgroundTransparency = 0}, 0.35)
		elseif d:IsA("TextBox") then
			Tween(d, {TextTransparency = 0}, 0.35)
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
				if d:IsA("ImageLabel") then Tween(d, {ImageTransparency = 1}, 0.3) end
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
	-- Optional personalization: pass a texture asset id to replace the default
	-- flat background / floating open-button look. Leave nil/"" for the
	-- built-in theme-colored default.
	local BackgroundImageId = config.BackgroundImage
	local OpenButtonImageId = config.OpenButtonImage
	if BackgroundImageId == "" then BackgroundImageId = nil end
	if OpenButtonImageId == "" then OpenButtonImageId = nil end

	-- Accept a bare numeric id (e.g. "1286772516") as well as a full
	-- "rbxassetid://..." / "http(s)://..." / "rbxthumb://..." string, so a
	-- forgotten prefix doesn't silently render as a blank image.
	local function normalizeAssetId(id)
		if not id then return nil end
		if id:match("^%d+$") then
			return "rbxassetid://" .. id
		end
		return id
	end
	BackgroundImageId = normalizeAssetId(BackgroundImageId)
	OpenButtonImageId = normalizeAssetId(OpenButtonImageId)

	-- Optional: set the window's starting theme by name (must match one of
	-- the "Theme" dropdown's options exactly, e.g. "Ocean", "Cyberpunk").
	-- Applied before any UI is built, so the window opens already themed
	-- instead of flashing the default look first.
	if config.Theme then
		Library:SetTheme(config.Theme)
	end

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

	-- soft drop shadow behind the window for depth
	local Shadow = Create("ImageLabel", {
		Name = "Shadow",
		Parent = ScreenGui,
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49,49,450,450),
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.new(0.5,0,0.5,0),
		Size = UDim2.new(1,60,1,60),
		ZIndex = 0,
	})

	local Main = Create("Frame", {
		Name = "Main",
		Parent = ScreenGui,
		BackgroundColor3 = theme.Main,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = mainSize,
		ClipsDescendants = true,
		ZIndex = 1,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0, 14)}),
		Create("UIStroke", {Color = theme.Stroke, Thickness = 1, Transparency = 0.2}),
		Create("UIGradient", {
			Name = "MainShade",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
				ColorSequenceKeypoint.new(1, Color3.new(0.9,0.9,0.9)),
			}),
			Rotation = 90,
		}),
	})

	-- Optional custom background texture. Left with Image = "" (invisible)
	-- when no BackgroundImage id was supplied, so the default flat theme
	-- color shows through untouched.
	local BackgroundTexture = Create("ImageLabel", {
		Name = "BackgroundTexture",
		Parent = Main,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,1,0),
		Image = BackgroundImageId or "",
		ImageTransparency = BackgroundImageId and 1 or 1, -- starts hidden, faded in below
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
	}, {Create("UICorner", {CornerRadius = UDim.new(0,14)})})
	-- how transparent the texture should be at rest once faded in (kept in
	-- sync with the Config tab's transparency slider — see AddConfig below)
	local backgroundTextureAlpha = 0

	Shadow.Parent = ScreenGui
	-- NOTE: intentionally no Position-sync connection here — the shadow stays
	-- put and does not follow Main around while the window is being dragged.
	Library:RegisterThemeObject(Main, "BackgroundColor3", "Main")

	-- opening animation
	Main.Size = UDim2.new(0,0,0,0)
	Main.BackgroundTransparency = 1
	Shadow.ImageTransparency = 1
	Tween(Main, {Size = mainSize, BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back)
	Tween(Shadow, {ImageTransparency = 0.55}, 0.5)
	if BackgroundImageId then
		task.delay(0.15, function()
			Tween(BackgroundTexture, {ImageTransparency = backgroundTextureAlpha}, 0.35)
		end)
	end

	-- top bar
	local TopBar = Create("Frame", {
		Parent = Main, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,42),
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0,14)}),
		Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
				ColorSequenceKeypoint.new(1, Color3.new(0.88,0.88,0.88)),
			}),
			Rotation = 90,
		}),
	})
	Library:RegisterThemeObject(TopBar, "BackgroundColor3", "Second")

	-- corner patch so bottom corners of topbar stay square
	Create("Frame", {Parent = TopBar, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,1,-14), BorderSizePixel = 0, ZIndex = 0})

	-- small accent dot + title
	local AccentDot = Create("Frame", {
		Parent = TopBar, BackgroundColor3 = theme.Accent, Size = UDim2.new(0,8,0,8),
		Position = UDim2.new(0,16,0.5,-4),
	}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
	Library:RegisterThemeObject(AccentDot, "BackgroundColor3", "Accent")

	Create("TextLabel", {
		Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,32,0,0),
		Font = Enum.Font.GothamBold, Text = WindowTitle, TextColor3 = theme.Text, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local function StyledIconButton(icon, posOffset)
		local Btn = Create("TextButton", {
			Parent = TopBar, BackgroundColor3 = theme.Main, Size = UDim2.new(0,28,0,28),
			Position = UDim2.new(1, posOffset, 0.5, -14), Text = "", AutoButtonColor = false,
		}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})
		Library:RegisterThemeObject(Btn, "BackgroundColor3", "Main")
		local Icon = Create("ImageLabel", {
			Parent = Btn, BackgroundTransparency = 1, Size = UDim2.new(0,14,0,14),
			AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
			Image = icon, ImageColor3 = theme.Text,
		})
		Library:RegisterThemeObject(Icon, "ImageColor3", "Text")
		Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = theme.Accent}, 0.15) end)
		Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = theme.Main}, 0.15) end)
		return Btn
	end

	local CloseBtn = StyledIconButton("rbxassetid://10747384394", -36)
	local MinimizeBtn = StyledIconButton("rbxassetid://10734943151", -70)

	MakeDraggable(TopBar, Main)

	local minimized = false
	MinimizeBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Tween(Main, {Size = UDim2.new(mainSize.X.Scale, mainSize.X.Offset, 0, 42)}, 0.32, Enum.EasingStyle.Quint)
		else
			Tween(Main, {Size = mainSize}, 0.32, Enum.EasingStyle.Quint)
		end
	end)

	-- floating draggable bubble shown while the UI is closed; clicking it
	-- (without dragging) reopens the window with a smooth effect
	local FloatingToggle = Create("ImageButton", {
		Name = "DarkUI_FloatingToggle",
		Parent = ScreenGui,
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0,0,0,0),
		Position = UDim2.new(0, 24, 0.5, -24),
		AutoButtonColor = false,
		Image = "",
		Visible = false,
		ZIndex = 500,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(1,0)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 0.4, Thickness = 1}),
	})
	Library:RegisterThemeObject(FloatingToggle, "BackgroundColor3", "Accent")
	local FloatingIcon = Create("ImageLabel", {
		Parent = FloatingToggle,
		BackgroundTransparency = 1,
		Size = OpenButtonImageId and UDim2.new(1,-6,1,-6) or UDim2.new(0,22,0,22),
		AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
		Image = OpenButtonImageId or "rbxassetid://10734950309",
		ImageColor3 = Color3.new(1,1,1),
		ScaleType = OpenButtonImageId and Enum.ScaleType.Fit or Enum.ScaleType.Stretch,
		ZIndex = 501,
	})
	if OpenButtonImageId then
		Create("UICorner", {Parent = FloatingIcon, CornerRadius = UDim.new(1,0)})
	end
	local floatingIconRestSize = FloatingIcon.Size
	FloatingToggle.MouseEnter:Connect(function()
		Tween(FloatingIcon, {Size = UDim2.new(floatingIconRestSize.X.Scale, floatingIconRestSize.X.Offset + 3, floatingIconRestSize.Y.Scale, floatingIconRestSize.Y.Offset + 3)}, 0.15)
	end)
	FloatingToggle.MouseLeave:Connect(function() Tween(FloatingIcon, {Size = floatingIconRestSize}, 0.15) end)

	local uiVisible = true

	local function closeUI()
		uiVisible = false
		Tween(Main, {Size = UDim2.new(0,0,0,0)}, 0.28, Enum.EasingStyle.Quint)
		Tween(Shadow, {ImageTransparency = 1}, 0.28)
		task.delay(0.2, function()
			if uiVisible then return end
			FloatingToggle.Visible = true
			Tween(FloatingToggle, {Size = UDim2.new(0,48,0,48)}, 0.3, Enum.EasingStyle.Back)
		end)
	end

	local function openUI()
		uiVisible = true
		Tween(FloatingToggle, {Size = UDim2.new(0,0,0,0)}, 0.2, Enum.EasingStyle.Quint)
		task.delay(0.2, function()
			if not uiVisible then return end
			FloatingToggle.Visible = false
		end)
		Tween(Main, {Size = minimized and UDim2.new(mainSize.X.Scale, mainSize.X.Offset, 0, 42) or mainSize}, 0.32, Enum.EasingStyle.Back)
		Tween(Shadow, {ImageTransparency = 0.55}, 0.32)
	end

	CloseBtn.MouseButton1Click:Connect(function()
		if uiVisible then closeUI() else openUI() end
	end)

	MakeDraggableToggle(FloatingToggle, openUI)

	-- search bar
	local SearchHolder = Create("Frame", {
		Parent = Main, BackgroundColor3 = theme.Second, Size = UDim2.new(1,-32,0,34),
		Position = UDim2.new(0,16,0,52),
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0,10)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 0.5}),
	})
	Library:RegisterThemeObject(SearchHolder, "BackgroundColor3", "Second")

	local SearchIcon = Create("ImageLabel", {
		Parent = SearchHolder, BackgroundTransparency = 1, Size = UDim2.new(0,14,0,14),
		Position = UDim2.new(0,10,0.5,-7), Image = "rbxassetid://10709790948", ImageColor3 = theme.SubText,
	})
	Library:RegisterThemeObject(SearchIcon, "ImageColor3", "SubText")

	local SearchBox = Create("TextBox", {
		Parent = SearchHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-36,1,0), Position = UDim2.new(0,30,0,0),
		Font = Enum.Font.Gotham, PlaceholderText = "Search elements...", Text = "",
		TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	})
	Library:RegisterThemeObject(SearchBox, "TextColor3", "Text")
	Library:RegisterThemeObject(SearchBox, "PlaceholderColor3", "SubText")

	-- tab bar (left, auto scroll)
	local TabBar = Create("ScrollingFrame", {
		Parent = Main, BackgroundColor3 = theme.Second, Size = UDim2.new(0, 140, 1, -104),
		Position = UDim2.new(0, 16, 0, 96), ScrollBarThickness = 3, CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = theme.Accent,
		BorderSizePixel = 0,
	}, {
		Create("UICorner", {CornerRadius = UDim.new(0,10)}),
		Create("UIStroke", {Color = theme.Stroke, Transparency = 0.5}),
		Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)}),
		Create("UIPadding", {PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8)}),
	})
	Library:RegisterThemeObject(TabBar, "BackgroundColor3", "Second")

	-- content area
	local ContentHolder = Create("Frame", {
		Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, -172, 1, -104),
		Position = UDim2.new(0, 164, 0, 96),
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
		self.ActiveTab = tab
		for _, t in pairs(self.Tabs) do
			local isActive = (t == tab)
			t.Container.Visible = isActive
			Tween(t.Button, {BackgroundColor3 = isActive and theme.Accent or theme.Second}, 0.2)
			Tween(t.Label, {TextColor3 = isActive and Color3.new(1,1,1) or theme.Text}, 0.2)
			if t.Indicator then
				Tween(t.Indicator, {BackgroundTransparency = isActive and 0 or 1}, 0.2)
			end
		end
	end
	Library:OnThemeRefresh(function()
		if Window.ActiveTab then Window:SelectTab(Window.ActiveTab) end
	end)

	function Window:CreateTab(name, order)
		local theme = Library.CurrentTheme
		local TabButton = Create("TextButton", {
			Parent = TabBar, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,34),
			Text = "", AutoButtonColor = false, LayoutOrder = order or #self.Tabs + 1,
		}, {Create("UICorner", {CornerRadius = UDim.new(0,8)})})
		Library:RegisterThemeObject(TabButton, "BackgroundColor3", "Second")

		local Indicator = Create("Frame", {
			Parent = TabButton, BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1,
			Size = UDim2.new(0,3,0,16), Position = UDim2.new(0,4,0.5,-8),
		}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})

		local TabLabel = Create("TextLabel", {
			Parent = TabButton, BackgroundTransparency = 1, Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,12,0,0),
			Font = Enum.Font.GothamMedium, Text = name, TextColor3 = theme.Text, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		})

		TabButton.MouseEnter:Connect(function()
			if TabButton.BackgroundColor3 ~= theme.Accent then Tween(TabButton, {BackgroundColor3 = theme.Main}, 0.15) end
		end)
		TabButton.MouseLeave:Connect(function()
			if TabButton.BackgroundColor3 ~= theme.Accent then Tween(TabButton, {BackgroundColor3 = theme.Second}, 0.15) end
		end)

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
		Tab.Label = TabLabel
		Tab.Indicator = Indicator
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
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.5}),
				Create("UIPadding", {PaddingTop = UDim.new(0,12), PaddingBottom = UDim.new(0,12), PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14)}),
				Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")
			local Header = Create("Frame", {Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18)})
			local AccentBar = Create("Frame", {
				Parent = Header, BackgroundColor3 = theme.Accent, Size = UDim2.new(0,3,0,14), Position = UDim2.new(0,0,0.5,-7),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
			Library:RegisterThemeObject(AccentBar, "BackgroundColor3", "Accent")
			local HeaderLabel = Create("TextLabel", {
				Parent = Header, BackgroundTransparency = 1, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,10,0,0),
				Font = Enum.Font.GothamBold, Text = name, TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(HeaderLabel, "TextColor3", "Text")
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
			Library:RegisterThemeObject(Label, "TextColor3", "SubText")
			table.insert(self.Elements, {Name = text, Frame = Frame})
			return {Set = function(_, t) Label.Text = t end}
		end

		function Tab:CreateSeparateText(text)
			local theme = Library.CurrentTheme
			local Frame = Create("Frame", {Parent = self.Container, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,26)})
			local Label = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-20,0,16),
				Font = Enum.Font.GothamBold, Text = string.upper(text), TextColor3 = theme.SubText, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0,0,0,2),
			})
			Library:RegisterThemeObject(Label, "TextColor3", "SubText")
			local Line = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Stroke, Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,22),
			}, {Create("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 0.9),
				}),
			})})
			Library:RegisterThemeObject(Line, "BackgroundColor3", "Stroke")
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38),
				Font = Enum.Font.Gotham, Text = "", AutoButtonColor = false,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")
			local Label = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,14,0,0),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Button", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})			Library:RegisterThemeObject(Label, "TextColor3", "Text")
			local Chevron = Create("ImageLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0,10,0,10),
				Position = UDim2.new(1,-22,0.5,-5), Image = "rbxassetid://10709790787",
				ImageColor3 = theme.SubText, Rotation = 0,
			})
			Library:RegisterThemeObject(Chevron, "ImageColor3", "SubText")
			Frame.MouseEnter:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Main}, 0.15) end)
			Frame.MouseLeave:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Second}, 0.15) end)
			Frame.MouseButton1Click:Connect(function()
				Tween(Frame, {BackgroundColor3 = theme.Accent}, 0.1)
				task.wait(0.1)
				Tween(Frame, {BackgroundColor3 = theme.Second}, 0.2)
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-70,1,0), Position = UDim2.new(0,14,0,0),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Toggle", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")

			local SwitchBG = Create("Frame", {
				Parent = Frame, BackgroundColor3 = state and theme.Accent or theme.Main,
				Size = UDim2.new(0,42,0,22), Position = UDim2.new(1,-56,0.5,-11),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(1,0)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(SwitchBG.UIStroke, "Color", "Stroke")

			local Knob = Create("Frame", {
				Parent = SwitchBG, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,16,0,16),
				Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(1,0)}),
				Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(225,225,230)),
					}),
					Rotation = 90,
				}),
			})

			local Click = Create("TextButton", {Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = ""})

			local Toggle = {}
			Toggle.Value = state

			local function updateVisual()
				Tween(SwitchBG, {BackgroundColor3 = Toggle.Value and theme.Accent or theme.Main}, 0.2)
				Tween(Knob, {Position = Toggle.Value and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.2, Enum.EasingStyle.Back)
			end
			Library:OnThemeRefresh(updateVisual)

			function Toggle:Set(v)
				Toggle.Value = v
				updateVisual()
				if opts.Callback then pcall(opts.Callback, v) end
			end

			Frame.MouseEnter:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Main}, 0.15) end)
			Frame.MouseLeave:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Second}, 0.15) end)

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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,50),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-90,0,20), Position = UDim2.new(0,14,0,8),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Slider", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")
			local ValuePill = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0,54,0,20), Position = UDim2.new(1,-68,0,8),
			}, {Create("UICorner", {CornerRadius = UDim.new(0,6)})})
			Library:RegisterThemeObject(ValuePill, "BackgroundColor3", "Main")
			local ValueLabel = Create("TextLabel", {
				Parent = ValuePill, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
				Font = Enum.Font.GothamBold, Text = tostring(value), TextColor3 = theme.Accent, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center,
			})
			Library:RegisterThemeObject(ValueLabel, "TextColor3", "Accent")

			local Track = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(1,-28,0,6), Position = UDim2.new(0,14,0,34),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
			Library:RegisterThemeObject(Track, "BackgroundColor3", "Main")

			local Fill = Create("Frame", {
				Parent = Track, BackgroundColor3 = theme.Accent, Size = UDim2.new((value-Min)/(Max-Min),0,1,0),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(1,0)}),
				Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, theme.Accent),
						ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
					}),
				}),
			})

			local Handle = Create("Frame", {
				Parent = Track, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,14,0,14),
				AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new((value-Min)/(Max-Min),0,0.5,0),
				ZIndex = 2,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(1,0)}),
				Create("UIStroke", {Color = theme.Accent, Thickness = 2}),
			})
			Library:RegisterThemeObject(Fill, "BackgroundColor3", "Accent")
			Library:RegisterThemeObject(Handle.UIStroke, "Color", "Accent")

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
				local pct = (v-Min)/(Max-Min)
				Fill.Size = UDim2.new(pct,0,1,0)
				Handle.Position = UDim2.new(pct,0,0.5,0)
				ValueLabel.Text = tostring(v)
				if opts.Callback then pcall(opts.Callback, v) end
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					Tween(Handle, {Size = UDim2.new(0,18,0,18)}, 0.1)
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
					if dragging then Tween(Handle, {Size = UDim2.new(0,14,0,14)}, 0.1) end
					dragging = false
				end
			end)

			function Slider:Set(v)
				v = math.clamp(v, Min, Max)
				Slider.Value = v
				local pct = (v-Min)/(Max-Min)
				Fill.Size = UDim2.new(pct,0,1,0)
				Handle.Position = UDim2.new(pct,0,0.5,0)
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.4,0,1,0), Position = UDim2.new(0,14,0,0),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Textbox", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")
			local BoxHolder = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0.55,-14,0,28), Position = UDim2.new(0.45,0,0.5,-14),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,8)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(BoxHolder, "BackgroundColor3", "Main")
			Library:RegisterThemeObject(BoxHolder.UIStroke, "Color", "Stroke")
			local Box = Create("TextBox", {
				Parent = BoxHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,8,0,0),
				Font = Enum.Font.Gotham, PlaceholderText = opts.PlaceholderText or "...", Text = opts.Default or "",
				TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 13, ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(Box, "TextColor3", "Text")
			Library:RegisterThemeObject(Box, "PlaceholderColor3", "SubText")

			local Textbox = {Value = opts.Default or ""}
			Box.Focused:Connect(function() Tween(BoxHolder, {BackgroundColor3 = theme.Main}, 0.15) end)
			Box.FocusLost:Connect(function(enterPressed)
				Textbox.Value = Box.Text
				if opts.Callback then pcall(opts.Callback, Box.Text, enterPressed) end
			end)

			Frame.MouseEnter:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Main}, 0.15) end)
			Frame.MouseLeave:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Second}, 0.15) end)

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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,14,0,0),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Bind", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")

			local KeyButton = Create("TextButton", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0,80,0,26), Position = UDim2.new(1,-94,0.5,-13),
				Font = Enum.Font.GothamBold, Text = currentKey.Name, TextColor3 = theme.Accent, TextSize = 12, AutoButtonColor = false,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,7)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(KeyButton, "TextColor3", "Accent")
			Library:RegisterThemeObject(KeyButton, "BackgroundColor3", "Main")
			Library:RegisterThemeObject(KeyButton.UIStroke, "Color", "Stroke")

			local Bind = {Value = currentKey}

			KeyButton.MouseButton1Click:Connect(function()
				listening = true
				KeyButton.Text = "..."
				Tween(KeyButton, {BackgroundColor3 = theme.Accent}, 0.15)
			end)

			Frame.MouseEnter:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Main}, 0.15) end)
			Frame.MouseLeave:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Second}, 0.15) end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					Bind.Value = input.KeyCode
					KeyButton.Text = input.KeyCode.Name
					listening = false
					Tween(KeyButton, {BackgroundColor3 = theme.Main}, 0.15)
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,46),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.7,0,0,16), Position = UDim2.new(0,14,0,8),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Progress", TextColor3 = theme.Text, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")
			local PercentLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.3,-14,0,16), Position = UDim2.new(0.7,0,0,8),
				Font = Enum.Font.GothamBold, Text = string.format("%d%%", math.floor(((value-Min)/(Max-Min))*100)),
				TextColor3 = theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
			})
			Library:RegisterThemeObject(PercentLabel, "TextColor3", "Accent")

			local Track = Create("Frame", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(1,-28,0,10), Position = UDim2.new(0,14,0,28),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
			Library:RegisterThemeObject(Track, "BackgroundColor3", "Main")

			local Fill = Create("Frame", {
				Parent = Track, BackgroundColor3 = theme.Accent, Size = UDim2.new((value-Min)/(Max-Min),0,1,0),
			}, {
				Create("UICorner", {CornerRadius = UDim.new(1,0)}),
				Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, theme.Accent),
						ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
					}),
				}),
			})
			Library:RegisterThemeObject(Fill, "BackgroundColor3", "Accent")

			local Bar = {Value = value}
			function Bar:Set(v)
				v = math.clamp(v, Min, Max)
				Bar.Value = v
				local pct = (v-Min)/(Max-Min)
				Tween(Fill, {Size = UDim2.new(pct,0,1,0)}, 0.25)
				PercentLabel.Text = string.format("%d%%", math.floor(pct*100))
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38), ClipsDescendants = true,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.5,0,0,38), Position = UDim2.new(0,14,0,0),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "Dropdown", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")

			local SelectedLabel = Create("TextButton", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0.45,-14,0,28), Position = UDim2.new(0.55,0,0,5),
				Font = Enum.Font.Gotham, Text = tostring(selected or "Select..."), TextColor3 = theme.SubText, TextSize = 12,
				AutoButtonColor = false,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,7)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
				Create("UIPadding", {PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,22)}),
			})
			Library:RegisterThemeObject(SelectedLabel, "BackgroundColor3", "Main")
			Library:RegisterThemeObject(SelectedLabel.UIStroke, "Color", "Stroke")

			local Chevron = Create("ImageLabel", {
				Parent = SelectedLabel, BackgroundTransparency = 1, Size = UDim2.new(0,10,0,10),
				Position = UDim2.new(1,-18,0.5,-5), Image = "rbxassetid://10709790787", ImageColor3 = theme.SubText,
			})
			Library:RegisterThemeObject(Chevron, "ImageColor3", "SubText")

			local ListHolder = Create("Frame", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-24,0,0), Position = UDim2.new(0,12,0,44),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})})

			local Dropdown = {Value = selected, Options = options}
			local open = false

			local function rebuildList()
				for _, c in ipairs(ListHolder:GetChildren()) do
					if not c:IsA("UIListLayout") then c:Destroy() end
				end
				for _, opt in ipairs(Dropdown.Options) do
					local isSelected = (Dropdown.Value == opt)
					local OptBtn = Create("TextButton", {
						Parent = ListHolder, BackgroundColor3 = isSelected and theme.Accent or theme.Main, Size = UDim2.new(1,0,0,28),
						Font = Enum.Font.Gotham, Text = tostring(opt), TextColor3 = isSelected and Color3.new(1,1,1) or theme.Text, TextSize = 12,
						AutoButtonColor = false,
					}, {Create("UICorner", {CornerRadius = UDim.new(0,7)})})
					OptBtn.MouseEnter:Connect(function()
						if Dropdown.Value ~= opt then Tween(OptBtn, {BackgroundColor3 = theme.Stroke}, 0.12) end
					end)
					OptBtn.MouseLeave:Connect(function()
						if Dropdown.Value ~= opt then Tween(OptBtn, {BackgroundColor3 = theme.Main}, 0.12) end
					end)
					OptBtn.MouseButton1Click:Connect(function()
						Dropdown.Value = opt
						SelectedLabel.Text = tostring(opt)
						open = false
						Tween(Chevron, {Rotation = 0}, 0.2)
						Tween(Frame, {Size = UDim2.new(1,0,0,38)}, 0.2)
						if opts.Callback then pcall(opts.Callback, opt) end
					end)
				end
			end
			rebuildList()
			Library:OnThemeRefresh(rebuildList)

			function Dropdown:Refresh(newOptions)
				Dropdown.Options = newOptions
				rebuildList()
			end

			function Dropdown:Set(v)
				Dropdown.Value = v
				SelectedLabel.Text = tostring(v)
				rebuildList()
				if opts.Callback then pcall(opts.Callback, v) end
			end

			SelectedLabel.MouseButton1Click:Connect(function()
				open = not open
				Tween(Chevron, {Rotation = open and 180 or 0}, 0.2)
				if open then
					local h = 44 + (#Dropdown.Options * 30)
					Tween(Frame, {Size = UDim2.new(1,0,0,h)}, 0.22)
				else
					Tween(Frame, {Size = UDim2.new(1,0,0,38)}, 0.22)
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38), ClipsDescendants = true,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame, "BackgroundColor3", "Second")
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local NameLabel = Create("TextLabel", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.5,0,0,38), Position = UDim2.new(0,14,0,0),
				Font = Enum.Font.GothamMedium, Text = opts.Name or "MultiDropdown", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(NameLabel, "TextColor3", "Text")

			local SelectedLabel = Create("TextButton", {
				Parent = Frame, BackgroundColor3 = theme.Main, Size = UDim2.new(0.45,-14,0,28), Position = UDim2.new(0.55,0,0,5),
				Font = Enum.Font.Gotham, Text = "Select...", TextColor3 = theme.SubText, TextSize = 12,
				AutoButtonColor = false,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,7)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
				Create("UIPadding", {PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,22)}),
			})
			Library:RegisterThemeObject(SelectedLabel, "BackgroundColor3", "Main")
			Library:RegisterThemeObject(SelectedLabel.UIStroke, "Color", "Stroke")
			local MultiChevron = Create("ImageLabel", {
				Parent = SelectedLabel, BackgroundTransparency = 1, Size = UDim2.new(0,10,0,10),
				Position = UDim2.new(1,-18,0.5,-5), Image = "rbxassetid://10709790787", ImageColor3 = theme.SubText,
			})
			Library:RegisterThemeObject(MultiChevron, "ImageColor3", "SubText")

			local ListHolder = Create("Frame", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-24,0,0), Position = UDim2.new(0,12,0,44),
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
						Parent = ListHolder, BackgroundColor3 = isOn and theme.Accent or theme.Main, Size = UDim2.new(1,0,0,28),
						Font = Enum.Font.Gotham, Text = tostring(opt), TextColor3 = isOn and Color3.new(1,1,1) or theme.Text, TextSize = 12,
						AutoButtonColor = false,
					}, {Create("UICorner", {CornerRadius = UDim.new(0,7)})})
					OptBtn.MouseButton1Click:Connect(function()
						MultiDropdown.Value[opt] = not MultiDropdown.Value[opt]
						local nowOn = MultiDropdown.Value[opt]
						Tween(OptBtn, {BackgroundColor3 = nowOn and theme.Accent or theme.Main}, 0.15)
						Tween(OptBtn, {TextColor3 = nowOn and Color3.new(1,1,1) or theme.Text}, 0.15)
						updateLabel()
						if opts.Callback then pcall(opts.Callback, MultiDropdown.Value) end
					end)
				end
			end
			rebuildList()
			updateLabel()
			Library:OnThemeRefresh(function() rebuildList(); updateLabel() end)

			function MultiDropdown:Set(set)
				MultiDropdown.Value = set
				rebuildList()
				updateLabel()
				if opts.Callback then pcall(opts.Callback, MultiDropdown.Value) end
			end

			SelectedLabel.MouseButton1Click:Connect(function()
				open = not open
				Tween(MultiChevron, {Rotation = open and 180 or 0}, 0.2)
				if open then
					local h = 44 + (#MultiDropdown.Options * 32)
					Tween(Frame, {Size = UDim2.new(1,0,0,h)}, 0.22)
				else
					Tween(Frame, {Size = UDim2.new(1,0,0,38)}, 0.22)
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
				Parent = self.Container, BackgroundColor3 = theme.Second, Size = UDim2.new(1,0,0,38), ClipsDescendants = true,
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0,10)}),
				Create("UIStroke", {Color = theme.Stroke, Transparency = 0.6}),
			})
			Library:RegisterThemeObject(Frame.UIStroke, "Color", "Stroke")

			local HeaderBtn = Create("TextButton", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,38),
				Text = "", AutoButtonColor = false,
			})
			local AccentBar = Create("Frame", {
				Parent = HeaderBtn, BackgroundColor3 = theme.Accent, Size = UDim2.new(0,3,0,16), Position = UDim2.new(0,14,0.5,-8),
			}, {Create("UICorner", {CornerRadius = UDim.new(1,0)})})
			Library:RegisterThemeObject(AccentBar, "BackgroundColor3", "Accent")
			local HeaderLabel = Create("TextLabel", {
				Parent = HeaderBtn, BackgroundTransparency = 1, Size = UDim2.new(1,-46,1,0), Position = UDim2.new(0,26,0,0),
				Font = Enum.Font.GothamBold, Text = opts.Name or "Mega Dropdown", TextColor3 = theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Library:RegisterThemeObject(HeaderLabel, "TextColor3", "Text")
			local MegaChevron = Create("ImageLabel", {
				Parent = HeaderBtn, BackgroundTransparency = 1, Size = UDim2.new(0,10,0,10),
				Position = UDim2.new(1,-24,0.5,-5), Image = "rbxassetid://10709790787", ImageColor3 = theme.SubText,
			})
			Library:RegisterThemeObject(MegaChevron, "ImageColor3", "SubText")

			local Inner = Create("Frame", {
				Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1,-28,0,0), Position = UDim2.new(0,14,0,44),
				AutomaticSize = Enum.AutomaticSize.Y,
			}, {Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})})

			local open = false
			HeaderBtn.MouseEnter:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Main}, 0.15) end)
			HeaderBtn.MouseLeave:Connect(function() Tween(Frame, {BackgroundColor3 = theme.Second}, 0.15) end)
			HeaderBtn.MouseButton1Click:Connect(function()
				open = not open
				Tween(MegaChevron, {Rotation = open and 180 or 0}, 0.2)
				if open then
					task.wait()
					Tween(Frame, {Size = UDim2.new(1,0,0, 52 + Inner.AbsoluteSize.Y)}, 0.25)
				else
					Tween(Frame, {Size = UDim2.new(1,0,0,38)}, 0.22)
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
			Flag = "DarkUI_Transparency",
			Callback = function(v)
				if applyTransparency then
					local alpha = v / 100
					backgroundTextureAlpha = alpha
					Tween(Main, {BackgroundTransparency = alpha}, 0.15)
					Tween(TopBar, {BackgroundTransparency = alpha}, 0.15)
					if BackgroundImageId then
						Tween(BackgroundTexture, {ImageTransparency = alpha}, 0.15)
					end
				end
			end,
		})

		ConfigTab:CreateToggle({
			Name = "Apply Transparency",
			Default = false,
			Flag = "DarkUI_ApplyTransparency",
			Callback = function(v)
				applyTransparency = v
				local alpha = applyTransparency and (TransparencySlider.Value / 100) or 0
				backgroundTextureAlpha = alpha
				Tween(Main, {BackgroundTransparency = alpha}, 0.15)
				Tween(TopBar, {BackgroundTransparency = alpha}, 0.15)
				if BackgroundImageId then
					Tween(BackgroundTexture, {ImageTransparency = alpha}, 0.15)
				end
			end,
		})

		-- theme dropdown (20 themes)
		ConfigTab:CreateDropdown({
			Name = "Theme",
			Options = ThemeOrder,
			Default = Library.CurrentThemeName,
			Flag = "DarkUI_Theme",
			Callback = function(v)
				Library:SetTheme(v)
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

		-- Build a JSON-serializable snapshot of every flagged element.
		-- EnumItems (e.g. Bind keycodes) and MultiDropdown sets are converted
		-- into plain JSON-friendly shapes since Roblox's JSONEncode can't
		-- handle Enums or sparse/mixed tables directly.
		local function gatherFlags()
			local data = {}
			for flag, obj in pairs(Library.Flags) do
				if obj.Value ~= nil then
					if typeof(obj.Value) == "EnumItem" then
						data[flag] = {__type = "enum", name = obj.Value.Name}
					elseif typeof(obj.Value) == "table" then
						-- MultiDropdown stores {[option]=bool}; JSON needs an array of the selected ones
						local selected = {}
						for k, v in pairs(obj.Value) do
							if v then table.insert(selected, k) end
						end
						data[flag] = {__type = "multiselect", values = selected}
					else
						data[flag] = obj.Value
					end
				end
			end
			return data
		end

		-- Wraps the flags into a versioned JSON document and encodes it.
		local function buildSaveJSON()
			local payload = {
				DarkUI_Version = 1,
				SavedAt = os.date("%Y-%m-%d %H:%M:%S"),
				Flags = gatherFlags(),
			}
			return HttpService:JSONEncode(payload)
		end

		-- Decodes a JSON save file and pushes every value back into its element.
		local function applyFlags(json)
			local ok, payload = pcall(function()
				return HttpService:JSONDecode(json)
			end)
			if not ok or typeof(payload) ~= "table" then return false end

			-- Support both the new {Flags = {...}} wrapper and a raw flag table
			local data = payload.Flags or payload

			for flag, val in pairs(data) do
				local obj = Library.Flags[flag]
				if obj then
					if typeof(val) == "table" and val.__type == "enum" then
						local key = Enum.KeyCode[val.name]
						if obj.Set then obj:Set(key) else obj.Value = key end
					elseif typeof(val) == "table" and val.__type == "multiselect" then
						local set = {}
						for _, name in ipairs(val.values) do set[name] = true end
						if obj.Set then obj:Set(set) else obj.Value = set end
					else
						if obj.Set then obj:Set(val) else obj.Value = val end
					end
				end
			end
			return true
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
					Parent = Overlay, BackgroundColor3 = theme.Main, Size = UDim2.new(0,340,0,160),
					AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0),
					BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 901,
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0,14)}),
					Create("UIStroke", {Color = theme.Stroke, Transparency = 1}),
				})

				local MGlow = Create("Frame", {
					Parent = Modal, BackgroundColor3 = theme.Accent, BackgroundTransparency = 1,
					Size = UDim2.new(1,0,0,4), ZIndex = 902,
				})
				Library:RegisterThemeObject(MGlow, "BackgroundColor3", "Accent")

				local MTitle = Create("TextLabel", {
					Parent = Modal, BackgroundTransparency = 1, Size = UDim2.new(1,-32,0,24), Position = UDim2.new(0,16,0,20),
					Font = Enum.Font.GothamBold, Text = "Save Configuration", TextColor3 = theme.Text, TextSize = 16, TextTransparency = 1, ZIndex = 902,
				})
				local MSubtitle = Create("TextLabel", {
					Parent = Modal, BackgroundTransparency = 1, Size = UDim2.new(1,-32,0,16), Position = UDim2.new(0,16,0,44),
					Font = Enum.Font.Gotham, Text = "Give this configuration a name", TextColor3 = theme.SubText, TextSize = 12, TextTransparency = 1, ZIndex = 902,
				})

				local NameBoxHolder = Create("Frame", {
					Parent = Modal, BackgroundColor3 = theme.Second, BackgroundTransparency = 1,
					Size = UDim2.new(1,-32,0,36), Position = UDim2.new(0,16,0,70), ZIndex = 902,
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0,10)}),
					Create("UIStroke", {Color = theme.Stroke, Transparency = 1}),
				})

				local NameBox = Create("TextBox", {
					Parent = NameBoxHolder, BackgroundTransparency = 1, Size = UDim2.new(1,-24,1,0), Position = UDim2.new(0,12,0,0),
					Font = Enum.Font.Gotham, PlaceholderText = "Save name...", Text = "",
					TextColor3 = theme.Text, PlaceholderColor3 = theme.SubText, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 902,
				})

				local HintLabel = Create("TextLabel", {
					Parent = Modal, BackgroundTransparency = 1, Size = UDim2.new(1,-32,0,16), Position = UDim2.new(0,16,0,114),
					Font = Enum.Font.Gotham, Text = "Press Enter to save", TextColor3 = theme.SubText, TextSize = 11, TextTransparency = 1, ZIndex = 902,
				})

				Tween(Modal, {BackgroundTransparency = 0}, 0.3)
				Tween(MGlow, {BackgroundTransparency = 0}, 0.35)
				for _, d in ipairs(Modal:GetDescendants()) do
					if d:IsA("TextLabel") then Tween(d, {TextTransparency = 0}, 0.3) end
					if d:IsA("Frame") and d ~= MGlow then Tween(d, {BackgroundTransparency = 0}, 0.3) end
					if d:IsA("UIStroke") then Tween(d, {Transparency = 0.5}, 0.3) end
					if d:IsA("TextBox") then Tween(d, {TextTransparency = 0}, 0.3) end
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
						local saveName = NameBox.Text:gsub("[^%w%s%-_]", "")
						local ok, jsonString = pcall(buildSaveJSON)
						if ok and jsonString then
							safeCall(writefile, CONFIG_SUBFOLDER .. "/" .. saveName .. ".json", jsonString)
							SavesDropdown:Refresh(getSaveNames())
							SavesDropdown:Set(saveName)
							Library:Notify({Title = "Configuration Saved", Content = "Saved as \"" .. saveName .. "\" (.json)", Duration = 3})
						else
							Library:Notify({Title = "Save Failed", Content = "Could not encode configuration to JSON.", Duration = 3})
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
				local jsonString = safeCall(readfile, CONFIG_SUBFOLDER .. "/" .. name .. ".json")
				if not jsonString then
					Library:Notify({Title = "Load Failed", Content = "Could not read save file.", Duration = 3})
					return
				end
				local success = applyFlags(jsonString)
				if success then
					Library:Notify({Title = "Configuration Loaded", Content = "Loaded \"" .. name .. "\" from JSON", Duration = 3})
				else
					Library:Notify({Title = "Load Failed", Content = "Corrupted or invalid JSON save file.", Duration = 3})
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
