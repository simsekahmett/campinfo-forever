local _, ns = ...
local L = ns.L

local Panel = {}
ns.Panel = Panel

local WIDTH = 310
local PAD = 12
local ROW_MIN = 18
local ICON = 16
local LOGO = 38

local frame
local rows = {}
local hideTimer

local function SavePosition()
	local point, _, relPoint, x, y = frame:GetPoint(1)
	ns.db.settings.point = { point, relPoint, x, y }
end

local function ApplyPosition()
	frame:ClearAllPoints()
	local p = ns.db.settings.point
	if p and p[1] then
		frame:SetPoint(p[1], UIParent, p[2] or p[1], p[3] or 0, p[4] or 0)
	else
		frame:SetPoint("LEFT", UIParent, "LEFT", 40, 120)
	end
end

local function CancelHide()
	if hideTimer then
		hideTimer:Cancel()
		hideTimer = nil
	end
end

local function ScheduleHide(seconds)
	CancelHide()
	hideTimer = C_Timer.NewTimer(seconds, function()
		hideTimer = nil
		if frame and frame:IsShown() then
			-- Stay open over the mouse, and while the sitting countdown runs.
			if MouseIsOver(frame) or ns.state.sitting then
				ScheduleHide(3)
			else
				frame:Hide()
			end
		end
	end)
end

local function RowOnEnter(self)
	if not self.spellId then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellId)
	if not ok or GameTooltip:NumLines() == 0 then
		GameTooltip:SetText(self.text:GetText() or "")
	end
	GameTooltip:Show()
end

local function RowOnLeave()
	GameTooltip:Hide()
end

local function GetRow(i)
	local row = rows[i]
	if row then
		return row
	end
	row = CreateFrame("Frame", nil, frame)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON, ICON)
	row.icon:SetPoint("TOPLEFT", 0, -1)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.status:SetPoint("TOPRIGHT", 0, -3)
	row.status:SetJustifyH("RIGHT")
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.text:SetJustifyH("LEFT")
	row.text:SetJustifyV("TOP")
	row.text:SetWordWrap(true)
	row:SetScript("OnEnter", RowOnEnter)
	row:SetScript("OnLeave", RowOnLeave)
	rows[i] = row
	return row
end

local function Create()
	frame = CreateFrame("Frame", "CampInfoForeverPanel", UIParent, "BackdropTemplate")
	frame:SetSize(WIDTH, 120)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if not ns.db.settings.locked then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		frame:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
		frame:SetBackdropBorderColor(1, 0.69, 0.25, 0.9)
	end

	frame.logo = frame:CreateTexture(nil, "ARTWORK")
	frame.logo:SetTexture(ns.LOGO)
	frame.logo:SetSize(LOGO, LOGO)
	frame.logo:SetPoint("TOPLEFT", PAD - 4, -PAD + 4)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", frame.logo, "TOPRIGHT", 4, -4)
	frame.title:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
	frame.title:SetJustifyH("LEFT")
	frame.title:SetWordWrap(false)

	frame.zone = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.zone:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -2)
	frame.zone:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
	frame.zone:SetJustifyH("LEFT")
	frame.zone:SetWordWrap(false)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 2)
	close:SetScript("OnClick", function()
		Panel.Hide()
	end)

	local function footerButton(label, onClick)
		local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		b:SetText(label)
		b:SetHeight(20)
		local fs = b:GetFontString()
		if fs then
			fs:SetFontObject("GameFontNormalSmall")
		end
		b:SetScript("OnClick", onClick)
		return b
	end
	frame.share = footerButton(L.BTN_SHARE, function()
		ns.Share("camp")
	end)
	frame.missing = footerButton(L.BTN_MISSING, function()
		ns.Share("missing")
	end)

	frame:Hide()
	ApplyPosition()
	Panel.ApplyScale()
end

local function Layout(info)
	frame.title:SetText(info.title)
	frame.zone:SetText(info.zone)

	local y = -PAD - frame.title:GetStringHeight() - 4
	if info.zone ~= "" then
		y = y - frame.zone:GetStringHeight() - 2
	end
	y = math.min(y, -PAD + 4 - LOGO) - 6
	local count = 0

	local function add(kind, icon, text, status, statusColor, spellId)
		count = count + 1
		local row = GetRow(count)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
		row:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
		row.spellId = spellId
		row:EnableMouse(spellId ~= nil)

		row.text:ClearAllPoints()
		row.status:SetText(status or "")
		if statusColor then
			row.status:SetTextColor(statusColor[1], statusColor[2], statusColor[3])
		end

		if kind == "header" then
			row.icon:Hide()
			row.text:SetFontObject("GameFontNormal")
			row.text:SetTextColor(1, 0.69, 0.25)
			row.text:SetPoint("TOPLEFT", 0, -2)
		elseif kind == "dim" then
			row.icon:Hide()
			row.text:SetFontObject("GameFontHighlightSmall")
			row.text:SetTextColor(0.6, 0.6, 0.6)
			row.text:SetPoint("TOPLEFT", 0, -3)
		else
			row.icon:SetTexture(icon or ns.ICON_UNKNOWN)
			row.icon:Show()
			row.icon:SetDesaturated(kind == "off")
			row.icon:SetAlpha(kind == "off" and 0.5 or 1)
			row.text:SetFontObject("GameFontHighlightSmall")
			if kind == "off" then
				row.text:SetTextColor(0.55, 0.55, 0.55)
			else
				row.text:SetTextColor(1, 1, 1)
			end
			row.text:SetPoint("TOPLEFT", ICON + 6, -3)
		end
		row.text:SetPoint("RIGHT", row.status, "LEFT", -6, 0)
		row.text:SetText(text)

		local height = math.max(ROW_MIN, row.text:GetStringHeight() + 6)
		row:SetHeight(height)
		row:Show()
		y = y - height
	end

	local compact = ns.db.settings.compact
	local function line(r, off)
		local nameColor = off and "|cff8c8c8c" or "|cffffd100"
		if compact then
			return nameColor .. r.name .. "|r  " .. (r.compact or "")
		end
		if r.text then
			return nameColor .. r.name .. "|r\n" .. r.text
		end
		return nameColor .. r.name .. "|r"
	end

	if not info.inCamp then
		add("dim", nil, L.NOT_IN_CAMP)
	end

	if info.sitting and not ns.state.campFresh then
		add("dim", nil, "|cffffd100" .. L.SITTING:format(info.sitting) .. "|r")
	elseif ns.state.needsSit then
		add("dim", nil, "|cffffd100" .. L.SIT_HINT .. "|r")
	end
	-- At a new campfire, the buffs on you are still from your last camp until you sit,
	-- so list nothing until this camp's buffs arrive.
	local waiting = ns.state.needsSit or (info.sitting ~= nil and not ns.state.campFresh)
	local green = { 0.3, 1, 0.3 }

	if not waiting then
		add("header", nil, L.FEATURES_ON, info.campStatus, { 0.8, 0.8, 0.8 })
		if #info.active == 0 and #info.extras == 0 then
			add("dim", nil, L.NONE_ACTIVE)
		end
		for _, r in ipairs(info.active) do
			add("on", r.icon, line(r), r.status, green, r.spellId)
		end
		for _, r in ipairs(info.extras) do
			add("on", r.icon, line(r), L.ACTIVE, green)
		end
	end
	-- Before you sit: the objects you pointed at here, and what each will give.
	if waiting and #info.seen > 0 then
		add("header", nil, L.THIS_CAMP, nil, { 0.8, 0.8, 0.8 })
		for _, r in ipairs(info.seen) do
			add("on", r.icon, line(r), r.status, { 0.8, 0.8, 0.8 }, r.spellId)
		end
	end
	if #info.nearby > 0 then
		add("header", nil, L.NEARBY_CAMPS)
		for _, r in ipairs(info.nearby) do
			add("on", "Interface\\Icons\\Spell_Fire_Fire", line(r), r.status, { 0.8, 0.8, 0.8 })
		end
	end
	if info.violet then
		add("on", info.violet.icon, line(info.violet), info.violet.status, { 0.75, 0.5, 1 }, info.violet.spellId)
	end

	if not waiting and not ns.db.settings.onlyAvailable and #info.inactive > 0 then
		y = y - 6
		add("header", nil, L.FEATURES_OFF)
		for _, r in ipairs(info.inactive) do
			add("off", r.icon, line(r, true), nil, nil, r.spellId)
		end
	end

	for i = count + 1, #rows do
		rows[i]:Hide()
	end

	-- Share buttons along the bottom.
	y = y - 8
	local half = (WIDTH - PAD * 2 - 6) / 2
	frame.share:ClearAllPoints()
	frame.share:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
	frame.share:SetWidth(half)
	frame.missing:ClearAllPoints()
	frame.missing:SetPoint("LEFT", frame.share, "RIGHT", 6, 0)
	frame.missing:SetWidth(half)
	local canShare = info.inCamp and not waiting
	frame.share:SetEnabled(canShare)
	frame.missing:SetEnabled(canShare)
	y = y - 20

	frame:SetHeight(-y + PAD)
end

-- Ticks once a second while the sitting countdown is on the panel.
local ticker
function Panel.Refresh()
	if not frame then
		Create()
	end
	local info = ns.Snapshot()
	Layout(info)
	if info.sitting and not ticker then
		ticker = C_Timer.NewTicker(1, function()
			if frame:IsShown() then
				Panel.Refresh()
			elseif ticker then
				ticker:Cancel()
				ticker = nil
			end
		end)
	elseif not info.sitting and ticker then
		ticker:Cancel()
		ticker = nil
	end
end

function Panel.RefreshIfShown()
	if frame and frame:IsShown() then
		Panel.Refresh()
	end
end

function Panel.Show(auto)
	Panel.Refresh()
	frame:Show()
	local settings = ns.db.settings
	if auto and settings.autoHide then
		ScheduleHide(settings.hideAfter or 15)
	else
		CancelHide()
	end
end

function Panel.Hide()
	CancelHide()
	if frame then
		frame:Hide()
	end
end

function Panel.Toggle()
	if frame and frame:IsShown() then
		Panel.Hide()
	else
		Panel.Show(false)
	end
end

function Panel.ApplyScale()
	if frame then
		frame:SetScale(ns.db.settings.scale or 1)
	end
end

function Panel.ResetPosition()
	ns.db.settings.point = nil
	if frame then
		ApplyPosition()
	end
end
