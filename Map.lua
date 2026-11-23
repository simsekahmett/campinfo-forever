local _, ns = ...
local L = ns.L

-- The camps you and other players saw lately, as campfires on the world map.

local Map = {}
ns.Map = Map

local PIN = "Interface\\AddOns\\CampInfoForever\\Media\\CampPin"
local GLOW = "Interface\\AddOns\\CampInfoForever\\Media\\CampGlow"
local ZONE_SIZE, CONTINENT_SIZE = 32, 20
local LEVEL = 1900 -- over the map's own art and most of its icons

local pins = {}
local hooked, ticker

-- Camps fade as they get older: the fire burns out 15 minutes after it was lit.
local function Freshness(at)
	return math.max(0, math.min(1, 1 - (GetServerTime() - at) / ns.Comm.KEEP))
end

local function OnEnter(pin)
	local camp = pin.camp
	if not camp then
		return
	end
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	GameTooltip:AddDoubleLine("|T" .. PIN .. ":18:18|t " .. L.CAMP, ("%.0f, %.0f"):format(camp.x * 100, camp.y * 100), 1, 0.82, 0, 0.7, 0.7, 0.7)
	for _, row in ipairs(ns.CampRows(camp.objects)) do
		GameTooltip:AddDoubleLine("|T" .. (row.icon or ns.ICON_UNKNOWN) .. ":16:16|t " .. row.name, date("%H:%M", row.at), 1, 1, 1, 0.7, 0.7, 0.7)
		GameTooltip:AddLine("      " .. row.text, 0.3, 1, 0.3)
	end
	GameTooltip:AddLine(L.LAST_SEEN:format(date("%H:%M", camp.at)), 0.7, 0.7, 0.7)
	GameTooltip:Show()
	pin.art:SetVertexColor(1, 1, 1)
	pin.art:SetAlpha(1)
end

local function OnLeave(pin)
	GameTooltip:Hide()
	if pin.camp then
		pin.art:SetAlpha(0.55 + 0.45 * Freshness(pin.camp.at))
	end
end

local function GetPin(index, canvas)
	local pin = pins[index]
	if pin then
		return pin
	end
	pin = CreateFrame("Frame", nil, canvas)
	pin.glow = pin:CreateTexture(nil, "BACKGROUND")
	pin.glow:SetTexture(GLOW)
	pin.glow:SetBlendMode("ADD")
	pin.glow:SetVertexColor(1, 0.55, 0.15)
	pin.glow:SetPoint("CENTER")
	pin.art = pin:CreateTexture(nil, "ARTWORK")
	pin.art:SetTexture(PIN)
	pin.art:SetAllPoints()
	pin.count = pin:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	pin.count:SetPoint("BOTTOMRIGHT", 3, -2)

	-- A slow flicker, like firelight.
	local group = pin.glow:CreateAnimationGroup()
	group:SetLooping("BOUNCE")
	local fade = group:CreateAnimation("Alpha")
	fade:SetFromAlpha(0.35)
	fade:SetToAlpha(0.9)
	fade:SetDuration(1.1)
	fade:SetSmoothing("IN_OUT")
	pin.flicker = group

	-- Only hovering: clicks and drags go to the map below.
	pin:EnableMouse(true)
	if pin.SetMouseClickEnabled then
		pin:SetMouseClickEnabled(false)
	end
	pin:SetScript("OnEnter", OnEnter)
	pin:SetScript("OnLeave", OnLeave)
	pins[index] = pin
	return pin
end

-- Whether mapID is the camp's own map or one above it (its continent, the world).
local function Shows(mapID, camp)
	local id = camp.mapID
	for _ = 1, 5 do
		if not id then
			return false
		elseif id == mapID then
			return true
		end
		local info = C_Map.GetMapInfo(id)
		id = info and info.parentMapID
	end
	return false
end

local function Project(mapID, camp)
	if camp.mapID == mapID then
		return camp.x, camp.y
	end
	local ok, _, pos = pcall(C_Map.GetMapPosFromWorldPos, camp.continent, CreateVector2D(camp.wx, camp.wy), mapID)
	if ok and pos and pos.x >= 0 and pos.x <= 1 and pos.y >= 0 and pos.y <= 1 then
		return pos.x, pos.y
	end
end

function Map.Refresh()
	if not hooked then
		return
	end
	local used = 0
	local mapID = WorldMapFrame:IsShown() and WorldMapFrame:GetMapID()
	if mapID and ns.db.settings.mapPins then
		local canvas = WorldMapFrame:GetCanvas()
		local width, height = canvas:GetSize()
		local zoom = WorldMapFrame:GetCanvasScale()
		if not zoom or zoom <= 0 then
			zoom = 1
		end
		for _, camp in ipairs(ns.Comm.All()) do
			local x, y
			if Shows(mapID, camp) then
				x, y = Project(mapID, camp)
			end
			if x then
				used = used + 1
				local pin = GetPin(used, canvas)
				-- The canvas zooms: undo that, so a pin is always the same size on screen.
				local size = camp.mapID == mapID and ZONE_SIZE or CONTINENT_SIZE
				pin:SetScale(1 / zoom)
				pin:SetSize(size, size)
				pin.glow:SetSize(size * 1.9, size * 1.9)
				pin:ClearAllPoints()
				pin:SetPoint("CENTER", canvas, "TOPLEFT", x * width * zoom, -y * height * zoom)
				pin:SetFrameLevel(LEVEL)
				pin.camp = camp
				pin.art:SetAlpha(0.55 + 0.45 * Freshness(camp.at))
				pin.count:SetText(camp.mapID == mapID and camp.count or "")
				pin.glow:SetShown(Freshness(camp.at) > 0.3)
				if not pin.flicker:IsPlaying() then
					pin.flicker:Play()
				end
				pin:Show()
			end
		end
	end
	for i = used + 1, #pins do
		pins[i]:Hide()
		pins[i].camp = nil
	end
end

local function OnMapChanged()
	Map.Refresh()
	-- Looking at another zone: ask the players who know its camps.
	local mapID = WorldMapFrame:IsShown() and WorldMapFrame:GetMapID()
	local info = mapID and C_Map.GetMapInfo(mapID)
	if info and ns.db.settings.mapPins and Enum.UIMapType and info.mapType == Enum.UIMapType.Zone then
		ns.Comm.Query(mapID)
	end
end

-- The world map can load after login.
function Map.Init()
	if hooked or not (WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame.GetMapID) then
		return
	end
	hooked = true
	hooksecurefunc(WorldMapFrame, "OnMapChanged", OnMapChanged)
	if WorldMapFrame.OnCanvasScaleChanged then
		hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", Map.Refresh)
	end
	if WorldMapFrame.OnFrameSizeChanged then
		hooksecurefunc(WorldMapFrame, "OnFrameSizeChanged", Map.Refresh)
	end
	WorldMapFrame:HookScript("OnShow", function()
		OnMapChanged()
		ticker = ticker or C_Timer.NewTicker(10, Map.Refresh)
	end)
	WorldMapFrame:HookScript("OnHide", function()
		if ticker then
			ticker:Cancel()
			ticker = nil
		end
	end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name)
	if event == "PLAYER_LOGIN" or name == "Blizzard_WorldMap" then
		Map.Init()
	end
end)
