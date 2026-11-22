local addonName, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- WoW Forever camp data (spell IDs from the game's hotfix data)
---------------------------------------------------------------------------

-- The aura you get at a camp. Its tooltip lists only the features that are active.
local CAMP_BENEFITS = 1229741

-- Throwing Violet Dust into the campfire: campfire effects last longer.
local VIOLET_FLAMES = { 1328362, 1328364, 1328367, 1328371, 1328375, 1328376, 1328377 }

-- Each camp feature gives its own buff. "stat" is used when the game has no text for it yet.
local FEATURES = {
	{ key = "LODESTONE", spell = 1230164, name = "Lodestone", icon = "Interface\\Icons\\INV_Stone_15" },
	{ key = "FIRST_AID", spell = 1230124, name = "First Aid Kit", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice" },
	{ key = "SHARPENING", spell = 1230172, name = "Sharpening Wheel", icon = "Interface\\Icons\\INV_Stone_SharpeningStone_01" },
	{ key = "INCENSE", spell = 1229513, name = "Incense Candle", icon = "Interface\\Icons\\INV_Misc_Candle_01" },
	{ key = "BANNER", spell = 1229718, name = "Faction Banner", icon = "Interface\\Icons\\INV_BannerPVP_02" },
	{ key = "CHAIR", spell = 1229519, name = "Camp Chair", icon = "Interface\\Icons\\Spell_Nature_Sleep" },
	{ key = "FISH_BOWL", spell = 1230098, name = "Fish Bowl", icon = "Interface\\Icons\\INV_Misc_Fish_02" },
	{ key = "LUTE", spell = 1230653, name = "Enchanted Lute", icon = "Interface\\Icons\\INV_Misc_Drum_01" },
	{ key = "MANA_WELL", spell = 1230587, name = "Mana Well", icon = "Interface\\Icons\\INV_Drink_07" },
}
ns.FEATURES = FEATURES
ns.CAMP_BENEFITS = CAMP_BENEFITS
ns.ICON_UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark"

local DEFAULTS = {
	autoShow = true,
	autoHide = true,
	hideAfter = 15,
	onlyAvailable = false,
	showInCities = false,
	chat = false,
	locked = false,
	scale = 1,
	compact = false,
	sound = false,
	shareChannel = "AUTO",
	announce = false,
	whisperReply = false,
}

-- Capital cities (Classic map IDs). Camps there do not open the panel on their own.
local CITY_MAPS = {
	[1453] = true, -- Stormwind City
	[1454] = true, -- Orgrimmar
	[1455] = true, -- Ironforge
	[1456] = true, -- Thunder Bluff
	[1457] = true, -- Darnassus
	[1458] = true, -- Undercity
}

local function InCity()
	if not (C_Map and C_Map.GetBestMapForUnit) then
		return false
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	-- Walk up a few levels in case the city has sub-maps.
	for _ = 1, 3 do
		if not mapID then
			return false
		end
		if CITY_MAPS[mapID] then
			return true
		end
		local info = C_Map.GetMapInfo(mapID)
		mapID = info and info.parentMapID
	end
	return false
end

-- Auto-open only for camps out in the world: not in cities, dungeons or raids.
function ns.IsOutdoorCamp()
	if IsInInstance() then
		return false
	end
	if InCity() and not ns.db.settings.showInCities then
		return false
	end
	return true
end

local state = {
	inCamp = false,
	active = {}, -- [spellId] = true for features giving a buff right now
	shownByAddon = false,
	announced = {}, -- [place] = time of the last automatic announcement
}
ns.state = state

ns.LOGO = "Interface\\AddOns\\CampInfoForever\\Media\\Logo64"
ns.LOGO_LARGE = "Interface\\AddOns\\CampInfoForever\\Media\\Logo256"

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|T" .. ns.LOGO .. ":14:14|t |cffffb040" .. L.TITLE .. "|r: " .. tostring(msg))
end
ns.Print = Print

-- The client can hand out "secret" values that addons may not read. Treat them as missing.
local function Unsecret(value)
	if value ~= nil and issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

---------------------------------------------------------------------------
-- Spell and aura helpers
---------------------------------------------------------------------------

local function SpellName(spellId)
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(spellId)
	elseif GetSpellInfo then
		return (GetSpellInfo(spellId))
	end
end

local function SpellIcon(spellId)
	if C_Spell and C_Spell.GetSpellTexture then
		return C_Spell.GetSpellTexture(spellId)
	elseif GetSpellTexture then
		return GetSpellTexture(spellId)
	end
end

local function SpellDescription(spellId)
	local text
	if C_Spell and C_Spell.GetSpellDescription then
		text = C_Spell.GetSpellDescription(spellId)
	elseif GetSpellDescription then
		text = GetSpellDescription(spellId)
	end
	text = Unsecret(text)
	if text and text ~= "" then
		return (text:gsub("[\r\n]+", " "))
	end
end

-- Ask the client to load spell text we will need; refresh the panel when it arrives.
local function PreloadSpells()
	if not (Spell and Spell.CreateFromSpellID) then
		return
	end
	for _, feature in ipairs(FEATURES) do
		local ok, spell = pcall(Spell.CreateFromSpellID, Spell, feature.spell)
		if ok and spell and spell.ContinueOnSpellLoad then
			spell:ContinueOnSpellLoad(function()
				ns.Panel.RefreshIfShown()
			end)
		end
	end
end

-- Buffs on the player, keyed by spell ID: { aura data, index }.
local function ScanBuffs()
	local buffs = {}
	for i = 1, 40 do
		local spellId, aura
		if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
			aura = C_UnitAuras.GetBuffDataByIndex("player", i)
			if not aura then
				break
			end
			spellId = Unsecret(aura.spellId)
		elseif UnitBuff then
			local name, icon, _, _, duration, expirationTime, _, _, _, sid = UnitBuff("player", i)
			if not name then
				break
			end
			spellId = Unsecret(sid)
			aura = { name = name, icon = icon, duration = duration, expirationTime = expirationTime, spellId = spellId }
		else
			break
		end
		if spellId then
			buffs[spellId] = { aura = aura, index = i }
		end
	end
	return buffs
end

-- Hidden auras do not show up in the index scan, so ask for them by ID too.
local function FindAura(buffs, spellId)
	if buffs[spellId] then
		return buffs[spellId].aura, buffs[spellId].index
	end
	if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
		local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellId)
		if ok and aura then
			return aura
		end
	end
end

local scanTip
local function ScanTooltip()
	if not scanTip then
		scanTip = CreateFrame("GameTooltip", "CampInfoForeverScanTip", nil, "GameTooltipTemplate")
	end
	scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
	scanTip:ClearLines()
	return scanTip
end

-- The text lines of the Camp Benefits tooltip, one per line.
local function AuraTooltipLines(aura, index)
	local lines = {}
	local function addText(text)
		text = Unsecret(text)
		if text then
			for part in text:gmatch("[^\r\n]+") do
				lines[#lines + 1] = part
			end
		end
	end

	local instanceID = aura and Unsecret(aura.auraInstanceID)
	if instanceID and C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID then
		local ok, data = pcall(C_TooltipInfo.GetUnitBuffByAuraInstanceID, "player", instanceID)
		if ok and data and data.lines then
			for _, line in ipairs(data.lines) do
				addText(line.leftText)
			end
		end
	end

	if #lines == 0 and index then
		local tip = ScanTooltip()
		if pcall(tip.SetUnitBuff, tip, "player", index) then
			for i = 1, tip:NumLines() do
				local fs = _G["CampInfoForeverScanTipTextLeft" .. i]
				addText(fs and fs:GetText())
			end
		end
		tip:Hide()
	end
	return lines
end

-- Remove color codes and plural escapes ("|4minute:minutes;") so a colon inside them
-- is not taken for the "Feature: buff" separator.
local function CleanText(text)
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("|4([^:;]*):([^;]*);", "%2")
	return text
end

-- "Lodestone: Melee Attack Power increased by 20." -> "Lodestone", "Melee Attack Power increased by 20."
-- Lines without a separator, or whose label has digits (the "36 minutes remaining" line), are skipped.
local function SplitBenefitLine(line)
	line = CleanText(line)
	local label, text = line:match("^%s*(.-)%s*:%s*(.+)$")
	if not label then
		label, text = line:match("^%s*(.-)%s*：%s*(.+)$")
	end
	if not label or label == "" or label:find("%d") or #label > 40 then
		return nil
	end
	return label, text
end

-- Text with numbers and spaces removed, to compare a tooltip line with a spell description.
local function Shape(text)
	return (text or ""):lower():gsub("[%d%s%.,%%]+", "")
end

-- The tooltip names the feature ("Lodestone"); the buff spell has another name
-- ("Boosted Attack Power"). Match on the English feature name, and on other
-- clients by comparing the buff text with the buff spell's own description.
local function MatchFeature(label, text)
	local lowered = label:lower()
	for _, feature in ipairs(FEATURES) do
		if feature.name:lower() == lowered then
			return feature
		end
	end
	local shape = Shape(text)
	if shape ~= "" then
		for _, feature in ipairs(FEATURES) do
			local desc = SpellDescription(feature.spell)
			if desc and Shape(desc) == shape then
				return feature
			end
		end
	end
end

local function StatName(feature)
	local stats = {
		LODESTONE = MELEE_ATTACK_POWER or ATTACK_POWER,
		FIRST_AID = SPELL_STAT3_NAME,
		SHARPENING = SPELL_STAT1_NAME,
		INCENSE = SPELL_STAT4_NAME,
		BANNER = SPELL_STAT5_NAME,
		CHAIR = CRIT_CHANCE,
		FISH_BOWL = L.ALL_STATS_PCT,
		LUTE = (ARMOR or "Armor") .. ", " .. L.ALL_STATS .. ", " .. L.ALL_RES,
		MANA_WELL = MANA_REGEN,
	}
	local english = {
		LODESTONE = "Melee Attack Power",
		FIRST_AID = "Stamina",
		SHARPENING = "Strength",
		INCENSE = "Intellect",
		BANNER = "Spirit",
		CHAIR = "Critical strike chance",
		MANA_WELL = "Mana every 5 sec",
	}
	return stats[feature.key] or english[feature.key] or "?"
end

local function FallbackStat(feature)
	return "+" .. StatName(feature)
end

-- A short value for chat: "Spirit +14", "Crit Chance +2%".
local function ShortValue(feature, text)
	local nums = {}
	for n in (text or ""):gmatch("%d+%%?") do
		nums[#nums + 1] = n
	end
	if feature.key == "LUTE" and #nums >= 3 then
		return string.format("%s +%s, %s +%s, %s +%s", ARMOR or "Armor", nums[1], L.ALL_STATS, nums[2], L.ALL_RES, nums[3])
	elseif feature.key == "FISH_BOWL" and nums[1] then
		local n = nums[1]:find("%%") and nums[1] or (nums[1] .. "%")
		return L.ALL_STATS .. " +" .. n
	elseif nums[1] then
		return StatName(feature) .. " +" .. nums[1]
	end
	return FallbackStat(feature)
end

local function RemainingText(aura)
	local expires = aura and Unsecret(aura.expirationTime)
	if expires and expires > 0 then
		local left = expires - GetTime()
		if left > 0 then
			if SecondsToTime then
				return SecondsToTime(left, true)
			end
			return string.format("%d min", math.ceil(left / 60))
		end
	end
end

---------------------------------------------------------------------------
-- What the camp gives right now
---------------------------------------------------------------------------

function ns.Snapshot()
	local buffs = ScanBuffs()
	local campAura, campIndex = FindAura(buffs, CAMP_BENEFITS)

	local active, inactive, extras = {}, {}, {}
	local seen = {}

	-- Real values from the Camp Benefits tooltip, keyed by feature.
	local tooltipText, tooltipLabel = {}, {}
	if campAura then
		for _, line in ipairs(AuraTooltipLines(campAura, campIndex)) do
			local label, text = SplitBenefitLine(line)
			if label then
				local feature = MatchFeature(label, text)
				if feature then
					tooltipText[feature.spell] = text
					tooltipLabel[feature.spell] = label
				else
					-- A feature this version of the addon does not know yet.
					extras[#extras + 1] = { icon = ns.ICON_UNKNOWN, name = label, text = text, short = text, compact = text }
				end
			end
		end
	end

	for _, feature in ipairs(FEATURES) do
		local aura = FindAura(buffs, feature.spell)
		local isActive = aura ~= nil or tooltipText[feature.spell] ~= nil
		local row = {
			spellId = feature.spell,
			icon = SpellIcon(feature.spell) or feature.icon,
			-- The game's own label for the feature when we have it (localized), else the English name.
			name = tooltipLabel[feature.spell] or feature.name,
		}
		if isActive then
			row.text = tooltipText[feature.spell] or SpellDescription(feature.spell) or FallbackStat(feature)
			-- The camp's time left is already in the header; repeat it only if this buff has its own.
			row.status = (aura and RemainingText(aura)) or L.ACTIVE
			row.short = ShortValue(feature, row.text)
			row.compact = row.short
			active[#active + 1] = row
			seen[feature.spell] = true
		else
			row.text = SpellDescription(feature.spell) or FallbackStat(feature)
			row.compact = FallbackStat(feature)
			inactive[#inactive + 1] = row
		end
	end

	local violet
	for _, spellId in ipairs(VIOLET_FLAMES) do
		local aura = FindAura(buffs, spellId)
		if aura then
			violet = { spellId = spellId, icon = SpellIcon(spellId) or ns.ICON_UNKNOWN, name = SpellName(spellId) or "Violet Flames", text = L.VIOLET, compact = L.VIOLET, status = RemainingText(aura) }
			break
		end
	end

	local zone = GetRealZoneText and GetRealZoneText() or GetZoneText() or ""
	local sub = GetSubZoneText() or ""

	return {
		inCamp = campAura ~= nil or #active > 0 or violet ~= nil,
		campStatus = RemainingText(campAura),
		title = L.CAMP,
		place = (sub ~= "" and sub) or zone,
		zone = (sub ~= "" and sub ~= zone) and (sub .. ", " .. zone) or zone,
		active = active,
		inactive = inactive,
		extras = extras,
		violet = violet,
	}
end

local function PrintSummary(info)
	if #info.active == 0 then
		Print(L.NONE_ACTIVE)
		return
	end
	for _, row in ipairs(info.active) do
		Print("|cffffd100" .. row.name .. "|r: " .. row.text)
	end
	for _, row in ipairs(info.extras) do
		Print("|cffffd100" .. row.name .. "|r: " .. (row.text or ""))
	end
end

---------------------------------------------------------------------------
-- Sharing in chat
---------------------------------------------------------------------------

local MAX_MESSAGE = 250

-- Where "automatic" sends: raid, then party, then /say.
local function ResolveChannel(channel, allowSay)
	if channel == "AUTO" or not channel then
		if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			return "INSTANCE_CHAT"
		elseif IsInRaid() then
			return "RAID"
		elseif IsInGroup() then
			return "PARTY"
		end
		return allowSay and "SAY" or nil
	end
	if channel == "RAID" and not IsInRaid() then
		return IsInGroup() and "PARTY" or nil
	elseif channel == "PARTY" and not IsInGroup() then
		return nil
	elseif channel == "GUILD" and not IsInGuild() then
		return nil
	elseif channel == "SAY" and not allowSay then
		return nil
	end
	return channel
end

-- Join parts with "; ", splitting into several messages if one would be too long.
local function Pack(prefix, parts, suffix)
	local messages, current = {}, prefix
	for i, part in ipairs(parts) do
		local piece = (current == prefix and " " or "; ") .. part
		if #current + #piece > MAX_MESSAGE and current ~= prefix then
			messages[#messages + 1] = current
			current = prefix .. " " .. part
		else
			current = current .. piece
		end
	end
	if suffix and suffix ~= "" then
		if #current + #suffix + 3 > MAX_MESSAGE then
			messages[#messages + 1] = current
			current = prefix .. " " .. suffix
		else
			current = current .. " | " .. suffix
		end
	end
	messages[#messages + 1] = current
	return messages
end

function ns.BuildShareMessages(info)
	local prefix = L.SHARE_PREFIX .. " " .. info.place .. ":"
	if not info.inCamp then
		return { L.SHARE_PREFIX .. " " .. L.NOT_IN_CAMP_SHORT }
	end
	local parts = {}
	for _, row in ipairs(info.active) do
		parts[#parts + 1] = row.name .. " (" .. row.short .. ")"
	end
	for _, row in ipairs(info.extras) do
		parts[#parts + 1] = row.name .. " (" .. tostring(row.short) .. ")"
	end
	if #parts == 0 then
		parts[1] = L.SHARE_NONE
	end
	local suffix = info.campStatus and L.SHARE_LEFT:format(info.campStatus) or nil
	return Pack(prefix, parts, suffix)
end

function ns.BuildMissingMessages(info)
	if not info.inCamp then
		return { L.SHARE_PREFIX .. " " .. L.NOT_IN_CAMP_SHORT }
	end
	if #info.inactive == 0 then
		return { L.SHARE_PREFIX .. " " .. L.SHARE_COMPLETE }
	end
	local names = {}
	for _, row in ipairs(info.inactive) do
		names[#names + 1] = row.name
	end
	local text = L.SHARE_MISSING:format(table.concat(names, ", "))
	return Pack(L.SHARE_PREFIX, { text })
end

local function Send(messages, channel, target)
	for _, msg in ipairs(messages) do
		SendChatMessage(msg, channel, nil, target)
	end
end

-- From a button click (a hardware event), so /say is allowed too.
function ns.Share(kind)
	local info = ns.Snapshot()
	local channel = ResolveChannel(ns.db.settings.shareChannel, true)
	if not channel then
		Print(L.NO_CHANNEL)
		return
	end
	local messages = kind == "missing" and ns.BuildMissingMessages(info) or ns.BuildShareMessages(info)
	Send(messages, channel)
end

local ANNOUNCE_COOLDOWN = 300
local function AutoAnnounce(info)
	local settings = ns.db.settings
	if not settings.announce then
		return
	end
	-- Not from a click, so only group channels: /say would be blocked.
	local channel = ResolveChannel("AUTO", false)
	if not channel then
		return
	end
	local key = info.place
	local now = GetTime()
	if state.announced[key] and now - state.announced[key] < ANNOUNCE_COOLDOWN then
		return
	end
	state.announced[key] = now
	Send(ns.BuildShareMessages(info), channel)
end

local whisperCooldown = {}
local function OnWhisper(text, sender)
	if not ns.db.settings.whisperReply or not text or not sender then
		return
	end
	text = Unsecret(text)
	sender = Unsecret(sender)
	if not text or not sender or strtrim(text):lower() ~= "!camp" then
		return
	end
	local now = GetTime()
	if whisperCooldown[sender] and now - whisperCooldown[sender] < 10 then
		return
	end
	whisperCooldown[sender] = now
	local info = ns.Snapshot()
	Send(ns.BuildShareMessages(info), "WHISPER", sender)
end

local function PlayArrivalSound()
	if not ns.db.settings.sound then
		return
	end
	local id = (SOUNDKIT and SOUNDKIT.READY_CHECK) or 8960
	PlaySound(id, "Master")
end

---------------------------------------------------------------------------
-- Reacting to aura changes
---------------------------------------------------------------------------

local function Update()
	local info = ns.Snapshot()
	local newActive = {}
	local gained = {}
	for _, row in ipairs(info.active) do
		newActive[row.spellId] = true
		if not state.active[row.spellId] then
			gained[#gained + 1] = row
		end
	end

	local arrived = info.inCamp and not state.inCamp
	local left = state.inCamp and not info.inCamp
	state.inCamp = info.inCamp
	state.active = newActive

	local settings = ns.db.settings
	if (arrived or (info.inCamp and #gained > 0)) and ns.IsOutdoorCamp() then
		if arrived then
			PlayArrivalSound()
			AutoAnnounce(info)
		end
		if settings.autoShow then
			state.shownByAddon = true
			ns.Panel.Show(true)
		end
		if settings.chat then
			if arrived then
				PrintSummary(info)
			else
				for _, row in ipairs(gained) do
					Print(L.NEW_FEATURE:format(row.name) .. " " .. row.text)
				end
			end
		end
	elseif left then
		if state.shownByAddon then
			ns.Panel.Hide()
		end
		state.shownByAddon = false
	else
		ns.Panel.RefreshIfShown()
	end
end

-- UNIT_AURA can fire many times in a row; handle it once per frame.
local pending = false
local function QueueUpdate()
	if pending then
		return
	end
	pending = true
	C_Timer.After(0.2, function()
		pending = false
		Update()
	end)
end

---------------------------------------------------------------------------
-- Debug report: helps map new camp features
---------------------------------------------------------------------------

local function DebugReport()
	Print(L.DEBUG_HEAD)
	local buffs = ScanBuffs()
	for spellId, entry in pairs(buffs) do
		local aura = entry.aura
		Print(string.format("  buff %d: %s", spellId, tostring(Unsecret(aura.name))))
	end
	local campAura, campIndex = FindAura(buffs, CAMP_BENEFITS)
	Print("  Camp Benefits (" .. CAMP_BENEFITS .. "): " .. (campAura and "yes" or "no"))
	if campAura then
		for _, line in ipairs(AuraTooltipLines(campAura, campIndex)) do
			Print("    > " .. line)
		end
	end
	for _, feature in ipairs(FEATURES) do
		local aura = FindAura(buffs, feature.spell)
		Print(string.format("  %s / %s (%d): %s", feature.name, tostring(SpellName(feature.spell)), feature.spell, aura and "yes" or "no"))
	end
	local info = ns.Snapshot()
	for _, row in ipairs(info.active) do
		Print("  = " .. row.name .. ": " .. row.text)
	end
	for _, row in ipairs(info.extras) do
		Print("  ? " .. row.name .. ": " .. tostring(row.text))
	end
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------

local function InitDB()
	CampInfoForeverDB = CampInfoForeverDB or {}
	local db = CampInfoForeverDB
	db.settings = db.settings or {}
	for k, v in pairs(DEFAULTS) do
		if db.settings[k] == nil then
			db.settings[k] = v
		end
	end
	db.areas = nil -- data from 1.0.0, no longer used
	-- 1.3.0 had the opposite option, "also list missing features".
	if db.settings.showInactive == false then
		db.settings.onlyAvailable = true
	end
	db.settings.showInactive = nil
	ns.db = db
end

local function SlashHandler(msg)
	local cmd = strtrim((msg or ""):lower())
	if cmd == "" then
		ns.Panel.Toggle()
	elseif cmd == "options" or cmd == "config" or cmd == "settings" then
		ns.Options.Open()
	elseif cmd == "reset" then
		ns.Panel.ResetPosition()
		Print(L.POS_RESET)
	elseif cmd == "debug" then
		DebugReport()
	else
		Print(L.HELP)
	end
end
ns.DebugReport = DebugReport

function CampInfoForever_OnCompartmentClick()
	ns.Panel.Toggle()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
	if event == "ADDON_LOADED" then
		if arg1 ~= addonName then
			return
		end
		self:UnregisterEvent("ADDON_LOADED")
		InitDB()
		ns.Options.Init()
		SLASH_CAMPINFOFOREVER1 = "/cif"
		SLASH_CAMPINFOFOREVER2 = "/campinfo"
		SlashCmdList.CAMPINFOFOREVER = SlashHandler
		self:RegisterEvent("PLAYER_LOGIN")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterUnitEvent("UNIT_AURA", "player")
		self:RegisterEvent("CHAT_MSG_WHISPER")
	elseif event == "PLAYER_LOGIN" then
		PreloadSpells()
		Print(L.LOADED)
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(2, Update)
	elseif event == "UNIT_AURA" then
		QueueUpdate()
	elseif event == "CHAT_MSG_WHISPER" then
		OnWhisper(arg1, arg2)
	end
end)
