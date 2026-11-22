local _, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local panel, category
local refreshers = {}

local CHANNELS = { "AUTO", "PARTY", "RAID", "GUILD", "SAY" }

local function ChannelLabel(channel)
	if channel == "PARTY" then
		return PARTY or "Party"
	elseif channel == "RAID" then
		return RAID or "Raid"
	elseif channel == "GUILD" then
		return GUILD or "Guild"
	elseif channel == "SAY" then
		return SAY or "Say"
	end
	return L.CH_AUTO
end

local function Header(text, y)
	local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", 16, y)
	fs:SetText(text)
	local line = panel:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 0.69, 0.25, 0.35)
	line:SetHeight(1)
	line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
	line:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
	return y - 22
end

local function Check(label, key, y, onChange)
	local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", 20, y)
	cb:SetSize(24, 24)
	local fs = cb.text or cb.Text
	if not fs then
		fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
	end
	fs:SetFontObject("GameFontHighlight")
	fs:SetText(label)
	cb:SetScript("OnClick", function(self)
		ns.db.settings[key] = self:GetChecked() and true or false
		if onChange then
			onChange()
		end
	end)
	refreshers[#refreshers + 1] = function()
		cb:SetChecked(ns.db.settings[key] and true or false)
	end
	return y - 26
end

local sliderCount = 0
local function Slider(key, minValue, maxValue, step, y, format, onChange)
	sliderCount = sliderCount + 1
	local name = "CampInfoForeverSlider" .. sliderCount
	local ok, slider = pcall(CreateFrame, "Slider", name, panel, "OptionsSliderTemplate")
	if not ok or not slider then
		slider = CreateFrame("Slider", name, panel)
		slider:SetOrientation("HORIZONTAL")
		slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	end
	slider:SetPoint("TOPLEFT", 26, y - 16)
	slider:SetSize(240, 16)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(step)
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true)
	end

	local label = _G[name .. "Text"] or slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:ClearAllPoints()
	label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 3)
	local low, high = _G[name .. "Low"], _G[name .. "High"]
	if low then
		low:SetText(format(minValue))
	end
	if high then
		high:SetText(format(maxValue))
	end

	local function show(value)
		label:SetText(format(value, true))
	end
	slider:SetScript("OnValueChanged", function(_, value)
		value = math.floor(value / step + 0.5) * step
		ns.db.settings[key] = value
		show(value)
		if onChange then
			onChange()
		end
	end)
	refreshers[#refreshers + 1] = function()
		slider:SetValue(ns.db.settings[key])
		show(ns.db.settings[key])
	end
	return y - 50
end

local function Button(label, x, y, onClick)
	local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	b:SetText(label)
	b:SetSize(math.max(140, b:GetFontString():GetStringWidth() + 30), 24)
	b:SetPoint("TOPLEFT", x, y)
	if onClick then
		b:SetScript("OnClick", onClick)
	end
	return b
end

local function RefreshPanel()
	for _, refresh in ipairs(refreshers) do
		refresh()
	end
end

local function RefreshAll()
	ns.Panel.RefreshIfShown()
end

function Options.Init()
	panel = CreateFrame("Frame")
	panel.name = L.TITLE

	local logo = panel:CreateTexture(nil, "ARTWORK")
	logo:SetTexture(ns.LOGO_LARGE)
	logo:SetSize(64, 64)
	logo:SetPoint("TOPRIGHT", -16, -8)

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L.TITLE)

	local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	desc:SetPoint("RIGHT", logo, "LEFT", -12, 0)
	desc:SetJustifyH("LEFT")
	desc:SetWordWrap(true)
	desc:SetText(L.OPT_DESC)

	local y = -72

	-- General
	y = Header(L.SEC_GENERAL, y)
	y = Check(L.OPT_AUTO, "autoShow", y)
	y = Check(L.OPT_CITIES, "showInCities", y)
	y = Check(L.OPT_ONLY_AVAILABLE, "onlyAvailable", y, RefreshAll)
	y = Check(L.OPT_AUTOHIDE, "autoHide", y)
	y = Slider("hideAfter", 5, 60, 5, y, function(v, long)
		return long and L.OPT_HIDE_SECONDS:format(v) or tostring(v)
	end)

	-- Appearance
	y = Header(L.SEC_LOOK, y)
	y = Slider("scale", 0.7, 1.5, 0.05, y, function(v, long)
		local pct = math.floor(v * 100 + 0.5)
		return long and L.OPT_SCALE:format(pct) or (pct .. "%")
	end, function()
		ns.Panel.ApplyScale()
	end)
	y = Check(L.OPT_COMPACT, "compact", y, RefreshAll)
	y = Check(L.OPT_LOCK, "locked", y)
	y = Check(L.OPT_SOUND, "sound", y)

	-- Chat and sharing
	y = Header(L.SEC_CHAT, y)
	y = Check(L.OPT_CHAT, "chat", y)
	y = Check(L.OPT_ANNOUNCE, "announce", y)
	y = Check(L.OPT_WHISPER, "whisperReply", y)

	local channelButton = Button("", 24, y - 4)
	channelButton:SetWidth(300)
	local function showChannel()
		channelButton:SetText(L.OPT_CHANNEL:format(ChannelLabel(ns.db.settings.shareChannel)))
	end
	channelButton:SetScript("OnClick", function()
		local current = ns.db.settings.shareChannel
		local nextIndex = 1
		for i, channel in ipairs(CHANNELS) do
			if channel == current then
				nextIndex = i % #CHANNELS + 1
			end
		end
		ns.db.settings.shareChannel = CHANNELS[nextIndex]
		showChannel()
	end)
	refreshers[#refreshers + 1] = showChannel
	y = y - 36

	-- Buttons
	local show = Button(L.BTN_SHOW, 20, y - 6, function()
		ns.Panel.Show(false)
	end)
	local reset = Button(L.BTN_RESET, 0, 0, function()
		ns.Panel.ResetPosition()
		ns.Print(L.POS_RESET)
	end)
	reset:ClearAllPoints()
	reset:SetPoint("LEFT", show, "RIGHT", 8, 0)
	local debug = Button(L.BTN_DEBUG, 0, 0, function()
		ns.DebugReport()
	end)
	debug:ClearAllPoints()
	debug:SetPoint("LEFT", reset, "RIGHT", 8, 0)

	local help = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	help:SetPoint("TOPLEFT", 20, y - 40)
	help:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
	help:SetJustifyH("LEFT")
	help:SetWordWrap(true)
	help:SetText(L.HELP)

	panel:SetScript("OnShow", RefreshPanel)

	if Settings and Settings.RegisterCanvasLayoutCategory then
		category = Settings.RegisterCanvasLayoutCategory(panel, L.TITLE)
		Settings.RegisterAddOnCategory(category)
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
end

function Options.Open()
	if category and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(category:GetID())
	elseif InterfaceOptionsFrame_OpenToCategory then
		-- Called twice: the first call only opens the frame on older clients.
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel)
	end
end
