local addonName, ns = ...
local L = ns.L

---------------------------------------------------------------------------
-- WoW Forever camp data (spell IDs from the game's hotfix data)
---------------------------------------------------------------------------

-- The aura you get at a camp. Its tooltip lists only the features that are active.
local CAMP_BENEFITS = 1229741

-- The "Campfire Nearby" buff you get next to a campfire, before any camp feature is built.
-- Found by spell ID; the English name is a fallback in case another ID turns up.
local CAMPFIRE_NEARBY = { 1283391 }

-- Sitting by the fire starts this one-minute timer; when it ends, Camp Benefits is
-- put on you with the buffs of the objects placed around this campfire.
local WELCOMING_CAMPFIRE = 1229739
local CAMPFIRE_NEARBY_NAME = "campfire nearby"

-- Throwing Violet Dust into the campfire: campfire effects last longer.
local VIOLET_FLAMES = { 1328362, 1328364, 1328367, 1328371, 1328375, 1328376, 1328377 }

-- Each camp feature gives its own buff ("spell"). "place" is the spell that builds the
-- object; its description says what the object gives, with real values. "ids" are the
-- placed object's game IDs, and "covered" the class buffs (any rank, matched by name) that
-- the camp buff does not stack with. All from the game's spell data, build 1.60.1.71037.
local FEATURES = {
	{ key = "LODESTONE", ids = { 651956, 573385 }, covered = { 19740, 25782 }, place = 1307254, spell = 1230164, name = "Lodestone", icon = "Interface\\Icons\\INV_Stone_15" },
	{ key = "FIRST_AID", ids = { 651953 }, covered = { 1243, 21562 }, place = 1307244, spell = 1230124, name = "First Aid Kit", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice" },
	{ key = "SHARPENING", ids = { 651950 }, covered = { 8076 }, place = 1307392, spell = 1230172, name = "Sharpening Wheel", icon = "Interface\\Icons\\INV_Stone_SharpeningStone_01" },
	{ key = "INCENSE", ids = { 651955 }, covered = { 1459, 23028 }, place = 1307251, spell = 1229513, name = "Incense Candle", icon = "Interface\\Icons\\INV_Misc_Candle_01" },
	{ key = "BANNER", ids = { 612350, 612351 }, covered = { 14752, 27681 }, place = 1307239, placeHorde = 1307240, spell = 1229718, name = "Faction Banner", icon = "Interface\\Icons\\INV_BannerPVP_02" },
	{ key = "CHAIR", ids = { 612275 }, covered = { 24907 }, place = 1307229, spell = 1229519, name = "Camp Chair", icon = "Interface\\Icons\\Spell_Nature_Sleep" },
	{ key = "FISH_BOWL", ids = { 651954 }, covered = { 20217, 25898 }, place = 1307245, spell = 1230098, name = "Fish Bowl", icon = "Interface\\Icons\\INV_Misc_Fish_02" },
	{ key = "LUTE", ids = { 651952 }, covered = { 1126, 21849 }, place = 1307234, spell = 1230653, name = "Enchanted Lute", icon = "Interface\\Icons\\INV_Misc_Drum_01" },
	{ key = "MANA_WELL", ids = { 651948 }, covered = { 19742, 25894 }, place = 1307259, spell = 1230587, name = "Mana Well", icon = "Interface\\Icons\\INV_Drink_07" },
}
ns.FEATURES = FEATURES

-- Objects you can place around a campfire. The game names each object after its
-- feature, so seeing "Fish Bowl" under the mouse means this camp has one.
-- "same" means the object gives the same buff as that one (a Loom counts as a banner).
-- "utility" objects give no buff; their tooltip says what they are for.
local OTHER_OBJECTS = {
	{ key = "CAMP_TENT", place = 1307230, ids = { 528996 }, name = "Camp Tent" },
	{ key = "FERMENTER", place = 1307242, ids = { 612120 }, same = "MANA_WELL", name = "Fermenter" },
	{ key = "ALCHEMY_LAB", place = 1307172, ids = { 612139 }, same = "MANA_WELL", name = "Alchemy Laboratory" },
	{ key = "ANVIL", place = 1307175, ids = { 612125 }, same = "SHARPENING", name = "Anvil" },
	{ key = "MASTER_FORGE", place = 1307261, ids = { 612136 }, same = "SHARPENING", name = "Master Forge" },
	{ key = "SALVAGER", place = 1307223, ids = { 612130 }, same = "LUTE", name = "Arcane Salvager" },
	{ key = "ARCANE_FORGE", place = 1307176, ids = { 612143 }, same = "LUTE", name = "Arcane Forge" },
	{ key = "GREENHOUSE", place = 1307248, ids = { 612087, 260078 }, same = "INCENSE", name = "Greenhouse" },
	{ key = "HYBRIDIZER", place = 1307387, ids = { 260105 }, same = "INCENSE", name = "Seed Hybridizer" },
	{ key = "TANNING_RACK", place = 1307395, ids = { 612122 }, same = "CAMP_TENT", name = "Tanning Rack" },
	{ key = "SEWING", place = 1307391, ids = { 612140 }, same = "CAMP_TENT", name = "Sewing Machine" },
	{ key = "ROCK_GARDEN", place = 1307386, ids = { 654285, 259224 }, same = "LODESTONE", name = "Rock Garden" },
	{ key = "FOUNDRY", place = 1307264, ids = { 612134 }, same = "LODESTONE", name = "Molten Foundry" },
	{ key = "FIELD_GUIDE", place = 1307243, ids = { 612088 }, same = "CHAIR", name = "Field Guide" },
	{ key = "TRAPPER", place = 1307397, ids = { 612082 }, same = "CHAIR", name = "Trapper's Workbench" },
	{ key = "SPINNING", place = 1307393, ids = { 612123 }, same = "BANNER", name = "Spinning Wheel" },
	{ key = "LOOM", place = 1307255, ids = { 612142 }, same = "BANNER", name = "Loom" },
	{ key = "TOXIN", place = 1307396, ids = { 612091 }, same = "FIRST_AID", name = "Toxin Study" },
	{ key = "PLAGUE_LAB", place = 1307265, ids = { 612110 }, same = "FIRST_AID", name = "Plague Doctor's Laboratory" },
	{ key = "FISHING_RACK", place = 1307247, ids = { 612090 }, same = "FISH_BOWL", name = "Fishing Rack" },
	{ key = "FISHING_HUT", place = 1307246, ids = { 612092 }, same = "FISH_BOWL", name = "Fishing Hut" },
	{ key = "REAGENT_BOT", place = 1307266, ids = { 242498 }, utility = true, name = "Reagent Bot" },
	{ key = "REPAIR_BOT", place = 1307385, ids = { 254695 }, utility = true, name = "Repair Bot" },
	{ key = "WORKBENCH", place = 1307174, ids = { 612145 }, utility = true, name = "Anarchist's Workbench" },
	{ key = "FEAST", place = 1307257, ids = { 612073 }, utility = true, name = "Cookie's Feast" },
	{ key = "IRON_OVEN", place = 1307226, ids = { 612132 }, utility = true, name = "Iron Oven" },
}

-- Campfires, and how many camp features fit around each.
local FIRES = {
	{ place = 1307227, slots = 3, name = "Basic Campfire" },
	{ place = 1307252, slots = 5, name = "Journeyman Campfire" },
	{ place = 1307237, slots = 10, name = "Expert Campfire" },
}
local FIRE_IDS = { [529161] = 3, [630660] = 5, [650137] = 10 }

local CAMP_OBJECTS = {}
for _, feature in ipairs(FEATURES) do
	CAMP_OBJECTS[#CAMP_OBJECTS + 1] = feature
end
for _, object in ipairs(OTHER_OBJECTS) do
	CAMP_OBJECTS[#CAMP_OBJECTS + 1] = object
end
local OBJECT_BY_ID, OBJECT_BY_PLACE = {}, {}
for _, object in ipairs(CAMP_OBJECTS) do
	for _, id in ipairs(object.ids) do
		OBJECT_BY_ID[id] = object
	end
	OBJECT_BY_PLACE[object.place] = object
	if object.placeHorde then
		OBJECT_BY_PLACE[object.placeHorde] = object
	end
end
function ns.ObjectByPlace(spellId)
	return OBJECT_BY_PLACE[spellId]
end
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
	network = true,
	mapPins = true,
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
	nearCampfire = false,
	active = {}, -- [spellId] = true for features giving a buff right now
	shownByAddon = false,
	announced = {}, -- [place] = time of the last automatic announcement
	seen = {}, -- [object key] = true for camp objects pointed at near this campfire
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
ns.Unsecret = Unsecret

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
	local function load(spellId)
		local ok, spell = pcall(Spell.CreateFromSpellID, Spell, spellId)
		if ok and spell and spell.ContinueOnSpellLoad then
			spell:ContinueOnSpellLoad(function()
				ns.Panel.RefreshIfShown()
			end)
		end
	end
	for _, object in ipairs(CAMP_OBJECTS) do
		if object.spell then load(object.spell) end
		if object.place then load(object.place) end
		if object.placeHorde then load(object.placeHorde) end
	end
	for _, fire in ipairs(FIRES) do
		load(fire.place)
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

-- The "Campfire Nearby" buff, by spell ID or else by name.
local function FindCampfire(buffs)
	for _, spellId in ipairs(CAMPFIRE_NEARBY) do
		local aura = FindAura(buffs, spellId)
		if aura then
			return aura, spellId
		end
	end
	for spellId, entry in pairs(buffs) do
		local name = Unsecret(entry.aura.name)
		if type(name) == "string" and name:lower() == CAMPFIRE_NEARBY_NAME then
			return entry.aura, spellId
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

local OBJECT_BY_KEY = {}
for _, object in ipairs(CAMP_OBJECTS) do
	OBJECT_BY_KEY[object.key] = object
end
local function ObjectByKey(key)
	return OBJECT_BY_KEY[key]
end
ns.ObjectByKey = ObjectByKey

-- What an object gives, from the description of the spell that builds it:
-- "...sitting nearby to gain 20 increased melee Attack Power, mutually exclusive..."
-- becomes "20 increased melee Attack Power". Other languages: the first sentence.
local function PlaceBenefit(object)
	local spellId = object.place
	if object.placeHorde and UnitFactionGroup and UnitFactionGroup("player") == "Horde" then
		spellId = object.placeHorde
	end
	local text = spellId and SpellDescription(spellId)
	if not text then
		return nil
	end
	if not object.utility then
		local part = text:match("nearby to (.-), mutually") or text:match("nearby (.-), mutually")
			or text:match("nearby to (.-)%. ") or text:match("nearby (.-)%. ")
		if part then
			part = part:gsub("^gain ", "")
			return part:sub(1, 1):upper() .. part:sub(2), true
		end
	end
	return text:match("^(.-%.)%s") or text
end

-- What a higher tier object is for besides its buff: the first sentence of its build spell.
local function PlaceSentence(object)
	local text = SpellDescription(object.place)
	return text and (text:match("^(.-%.)%s") or text)
end

-- The name of a class buff on you that already gives this object's buff, if any.
local function CoveredBy(object)
	local target = (object.same and ObjectByKey(object.same)) or object
	if not target.covered then
		return nil
	end
	local names = {}
	for _, spellId in ipairs(target.covered) do
		local name = Unsecret(SpellName(spellId))
		if name then
			names[name] = true
		end
	end
	for _, entry in pairs(ScanBuffs()) do
		local name = Unsecret(entry.aura.name)
		if name and names[name] then
			return name
		end
	end
end

-- The buff text for a camp object: what the game showed us, the buff's own text,
-- the builder spell's text, or just the stat name.
local function BuffText(object)
	local target = (object.same and ObjectByKey(object.same)) or object
	if target.utility then
		return (PlaceBenefit(target))
	end
	-- The build spell's text has the value for your level right now.
	local benefit, exact = PlaceBenefit(target)
	return (exact and benefit) or ns.db.known[object.key] or ns.db.known[target.key]
		or (target.spell and SpellDescription(target.spell))
		or benefit
		or (target.spell and FallbackStat(target))
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

-- A camp object by its name in the world: the English name, or the label the
-- game used for it in a Camp Benefits tooltip (so other languages work too).
local function ObjectByName(name)
	name = Unsecret(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local lowered = strtrim(name):lower()
	for _, object in ipairs(CAMP_OBJECTS) do
		local label = ns.db.labels[object.key]
		local localName = Unsecret(SpellName(object.place))
		if object.name:lower() == lowered or (label and label:lower() == lowered)
			or (type(localName) == "string" and localName:lower() == lowered) then
			return object
		end
	end
end

-- A camp object's name in your language: the game's own label, or the build spell's name.
local function ObjectName(object)
	local localName = Unsecret(SpellName(object.place))
	return ns.db.labels[object.key] or (type(localName) == "string" and localName ~= "" and localName) or object.name
end

-- Called with a camp object whose tooltip you looked at. Near a campfire, that object is
-- part of this camp, so the panel can list it before you sit.
local function SeeObject(object)
	if not state.seen[object.key] then
		state.seen[object.key] = true
		ns.Comm.Seen(object.key)
		ns.Panel.RefreshIfShown()
	end
end

-- When an aura was put on you (GetTime() clock), or nil if the client hides it.
local function AppliedAt(aura)
	if not aura then
		return nil
	end
	local expires, duration = Unsecret(aura.expirationTime), Unsecret(aura.duration)
	if type(expires) == "number" and type(duration) == "number" and duration > 0 and expires > 0 then
		return expires - duration
	end
end

-- Time left on the sit timer, or nil once it is over. The Welcoming Campfire aura can
-- linger for a moment after the buffs arrive, with no time left on it.
local function SittingLeft(welcoming, campAura)
	if not welcoming then
		return nil
	end
	local started, applied = AppliedAt(welcoming), AppliedAt(campAura)
	if started and applied and applied >= started then
		return nil -- Camp Benefits came after you sat down: the sit is done.
	end
	local expires = Unsecret(welcoming.expirationTime)
	if type(expires) == "number" and expires > 0 then
		if expires - GetTime() < 1 then
			return nil
		end
		local text = RemainingText(welcoming)
		return (text and text ~= "") and text or nil
	end
	return "1 min" -- the client hides the time
end

function ns.Snapshot()
	local buffs = ScanBuffs()
	local campAura, campIndex = FindAura(buffs, CAMP_BENEFITS)
	local campfire = FindCampfire(buffs)
	local welcoming = FindAura(buffs, WELCOMING_CAMPFIRE)

	local active, inactive, extras = {}, {}, {}
	local seen = {}

	-- Real values from the Camp Benefits tooltip, keyed by feature.
	local tooltipText, tooltipLabel = {}, {}
	local campKeys = {} -- every known object Camp Benefits lists
	if campAura then
		for _, line in ipairs(AuraTooltipLines(campAura, campIndex)) do
			local label, text = SplitBenefitLine(line)
			if label then
				local named = ObjectByName(label)
				local base = named and ((named.same and ObjectByKey(named.same)) or named)
				local feature = (base and base.spell and base) or (not named and MatchFeature(label, text)) or nil
				local listed = named or feature
				if listed then
					campKeys[#campKeys + 1] = listed.key
				end
				if feature then
					tooltipText[feature.spell] = text
					tooltipLabel[feature.spell] = label
					-- Remember the game's label and buff text, to name objects and
					-- show what they give before you sit at the next camp.
					-- A Loom or Fermenter gives a banner's or mana well's buff under its own
					-- name: that name must not become the label of the banner or well.
					if not named or named == feature then
						ns.db.labels[feature.key] = label
						ns.db.known[feature.key] = text
					elseif named then
						ns.db.known[named.key] = text
					end
				else
					-- A feature this version of the addon does not know yet.
					if named then
						ns.db.known[named.key] = text
					end
					extras[#extras + 1] = { key = named and named.key, icon = named and SpellIcon(named.place) or ns.ICON_UNKNOWN, name = label, text = text, short = text, compact = text }
				end
			end
		end
	end

	for _, feature in ipairs(FEATURES) do
		local aura = FindAura(buffs, feature.spell)
		local isActive = aura ~= nil or tooltipText[feature.spell] ~= nil
		local row = {
			key = feature.key,
			spellId = feature.spell,
			icon = SpellIcon(feature.spell) or feature.icon,
			-- The game's own label for the feature when we have it (localized), else the English name.
			name = tooltipLabel[feature.spell] or feature.name,
		}
		if isActive then
			row.text = tooltipText[feature.spell] or SpellDescription(feature.spell) or PlaceBenefit(feature) or FallbackStat(feature)
			-- The camp's time left is already in the header; repeat it only if this buff has its own.
			row.status = (aura and RemainingText(aura)) or L.ACTIVE
			row.short = ShortValue(feature, row.text)
			row.compact = row.short
			active[#active + 1] = row
			seen[feature.spell] = true
		else
			row.text = SpellDescription(feature.spell) or PlaceBenefit(feature) or FallbackStat(feature)
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

	-- At a campfire: the objects you pointed at or other players saw here, and the buff each
	-- gives when you sit. What others saw may be gone, so it says when it was last seen.
	local seenRows = {}
	if campfire then
		local shared = ns.Comm.CampHere() or {}
		for _, object in ipairs(CAMP_OBJECTS) do
			if state.seen[object.key] or shared[object.key] then
				local text = BuffText(object) or L.NO_BUFF_KNOWN
				local target = (object.same and ObjectByKey(object.same)) or object
				local short = target.spell and ShortValue(target, text) or text
				seenRows[#seenRows + 1] = {
					key = object.key, spellId = object.spell or object.place, name = ObjectName(object),
					icon = SpellIcon(object.place) or object.icon,
					text = text, short = short, compact = short,
					status = not state.seen[object.key] and L.LAST_SEEN:format(date("%H:%M", shared[object.key])) or nil,
				}
			end
		end
	end

	-- Away from camps: the camps other players saw on this map.
	local nearby = {}
	if not campfire then
		for _, camp in ipairs(ns.Comm.Nearby(5)) do
			local names = {}
			for _, object in ipairs(CAMP_OBJECTS) do
				if camp.objects[object.key] then
					names[#names + 1] = ObjectName(object)
				end
			end
			nearby[#nearby + 1] = {
				name = ("%.0f, %.0f (%d yd)"):format(camp.x * 100, camp.y * 100, camp.distance),
				text = table.concat(names, ", "), compact = table.concat(names, ", "),
				status = L.LAST_SEEN:format(date("%H:%M", camp.at)),
			}
		end
	end

	local zone = GetRealZoneText and GetRealZoneText() or GetZoneText() or ""
	local sub = GetSubZoneText() or ""

	return {
		inCamp = campAura ~= nil or campfire ~= nil or #active > 0 or violet ~= nil,
		nearCampfire = campfire ~= nil,
		sitting = SittingLeft(welcoming, campAura),
		campStatus = RemainingText(campAura),
		hasCampAura = campAura ~= nil,
		campApplied = AppliedAt(campAura),
		title = L.CAMP,
		place = (sub ~= "" and sub) or zone,
		zone = (sub ~= "" and sub ~= zone) and (sub .. ", " .. zone) or zone,
		active = active,
		inactive = inactive,
		extras = extras,
		violet = violet,
		seen = seenRows,
		nearby = nearby,
		campKeys = campKeys,
	}
end

-- The objects of a camp for a tooltip: { name, icon, text, at } in the usual order.
function ns.CampRows(objects)
	local rows = {}
	for _, object in ipairs(CAMP_OBJECTS) do
		if objects[object.key] then
			rows[#rows + 1] = {
				name = ObjectName(object), icon = SpellIcon(object.place) or object.icon,
				text = BuffText(object) or L.NO_BUFF_KNOWN, at = objects[object.key],
			}
		end
	end
	return rows
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

-- Join parts with " / ", splitting into several messages if one would be too long.
local function Pack(prefix, parts, suffix)
	local messages, current = {}, prefix
	for i, part in ipairs(parts) do
		local piece = (current == prefix and " " or " / ") .. part
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
			current = current .. " - " .. suffix
		end
	end
	messages[#messages + 1] = current
	return messages
end

-- withoutTime leaves out the camp's time left (for the automatic share).
function ns.BuildShareMessages(info, withoutTime)
	local prefix = L.SHARE_PREFIX .. " " .. info.place .. ":"
	if not info.inCamp then
		return { L.SHARE_PREFIX .. " " .. L.NOT_IN_CAMP_SHORT }
	end
	-- Until you sit, the buffs on you are from your last camp, not this one.
	if state.needsSit then
		return { L.SHARE_PREFIX .. " " .. L.SIT_HINT }
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
	local suffix = (info.campStatus and not withoutTime) and L.SHARE_LEFT:format(info.campStatus) or nil
	return Pack(prefix, parts, suffix)
end

function ns.BuildMissingMessages(info)
	if not info.inCamp then
		return { L.SHARE_PREFIX .. " " .. L.NOT_IN_CAMP_SHORT }
	end
	if state.needsSit then
		return { L.SHARE_PREFIX .. " " .. L.SIT_HINT }
	end
	local missing = info.inactive
	if #missing == 0 then
		return { L.SHARE_PREFIX .. " " .. L.SHARE_COMPLETE }
	end
	local names = {}
	for _, row in ipairs(missing) do
		names[#names + 1] = row.name
	end
	local text = L.SHARE_MISSING:format(table.concat(names, ", "))
	return Pack(L.SHARE_PREFIX, { text })
end

-- Chat refuses a message with a stray "|" (the start of a color or link code),
-- so remove color codes and textures and replace any "|" that is left.
local function ChatSafe(msg)
	msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	msg = msg:gsub("|T.-|t", ""):gsub("|A.-|a", "")
	msg = msg:gsub("|", "/")
	return msg
end

local function Send(messages, channel, target)
	local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
	if not send then
		return
	end
	for _, msg in ipairs(messages) do
		local ok, err = pcall(send, ChatSafe(msg), channel, nil, target)
		if not ok then
			Print("|cffff4040" .. tostring(err) .. "|r")
			return
		end
	end
end

-- From a button click (a hardware event), so /say is allowed too.
function ns.Share(kind)
	local info = ns.Snapshot()
	-- Whoever is at the camp can build what is missing, so ask everyone nearby.
	if kind == "missing" then
		Send(ns.BuildMissingMessages(info), "SAY")
		return
	end
	local channel = ResolveChannel(ns.db.settings.shareChannel, true)
	if not channel then
		Print(L.NO_CHANNEL)
		return
	end
	Send(ns.BuildShareMessages(info), channel)
end

local ANNOUNCE_COOLDOWN = 300
-- Share the camp's buffs in the chosen channel once they arrive, at most once every
-- 5 minutes per place.
local function AutoShare(info)
	local settings = ns.db.settings
	if not settings.announce then
		return
	end
	-- Not from a click, so the game blocks /say: use the group then, if there is one.
	local channel = ResolveChannel(settings.shareChannel, false) or ResolveChannel("AUTO", false)
	if not channel then
		Print(L.AUTOSHARE_NO_CHANNEL)
		return
	end
	local key = info.place
	local now = GetTime()
	if state.announced[key] and now - state.announced[key] < ANNOUNCE_COOLDOWN then
		return
	end
	state.announced[key] = now
	Send(ns.BuildShareMessages(info, true), channel)
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

	-- Camp Benefits stays on you for an hour after you walk away, so it cannot tell
	-- when you reach a camp. The Campfire Nearby buff can: it comes and goes with the fire.
	local reachedFire = info.nearCampfire and not state.nearCampfire
	local leftFire = state.nearCampfire and not info.nearCampfire
	local arrived = reachedFire or (info.inCamp and not state.inCamp)
	local left = leftFire or (state.inCamp and not info.inCamp)
	state.inCamp = info.inCamp
	state.nearCampfire = info.nearCampfire
	local sitStarted = info.sitting ~= nil and not state.sitting
	state.sitting = info.sitting ~= nil

	-- Camp Benefits only lists this camp's buffs once you sit by the fire: that puts it on
	-- you again. Until then it still shows what you got at your last camp.
	if reachedFire or leftFire then
		state.seen = {}
	end
	if reachedFire then
		state.arrivedAt = GetTime()
	end
	local fresh = info.nearCampfire and info.campApplied ~= nil and state.arrivedAt ~= nil
		and info.campApplied >= state.arrivedAt - 2
	local refreshedNow = fresh and not state.campFresh
	state.campFresh = fresh and true or false
	-- Without a readable time we cannot tell, so do not nag.
	local readable = info.campApplied ~= nil or not info.hasCampAura
	state.needsSit = (info.nearCampfire and readable and not fresh) and true or false
	state.active = newActive

	if refreshedNow and not IsInInstance() then
		ns.Comm.Confirm(info.campKeys)
	end

	local settings = ns.db.settings
	if (arrived or refreshedNow or sitStarted or (info.inCamp and #gained > 0)) and ns.IsOutdoorCamp() then
		if arrived then
			PlayArrivalSound()
		end
		-- Share once this camp's buffs arrive, not the ones left from your last camp.
		if refreshedNow then
			AutoShare(info)
		end
		if settings.autoShow then
			state.shownByAddon = true
			ns.Panel.Show(true)
		end
		if settings.chat then
			if arrived and state.needsSit then
				Print(L.SIT_HINT)
			elseif arrived or refreshedNow then
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
		local name = Unsecret(aura.name)
		Print(string.format("  buff %d: %s", spellId, tostring(name)))
		-- Tooltips of the other buffs too: Campfire Nearby or Welcoming Campfire
		-- may describe what the camp has. Camp Benefits is printed below.
		if spellId ~= CAMP_BENEFITS then
			for _, line in ipairs(AuraTooltipLines(aura, entry.index)) do
				if line ~= name then
					Print("      " .. CleanText(line))
				end
			end
		end
	end
	local campAura, campIndex = FindAura(buffs, CAMP_BENEFITS)
	Print("  Camp Benefits (" .. CAMP_BENEFITS .. "): " .. (campAura and "yes" or "no"))
	local campfire, campfireId = FindCampfire(buffs)
	Print("  Campfire Nearby: " .. (campfire and ("yes (" .. tostring(campfireId) .. ")") or "no"))
	local seenNames = {}
	for _, object in ipairs(CAMP_OBJECTS) do
		if state.seen[object.key] then
			seenNames[#seenNames + 1] = object.name
		end
	end
	Print("  Sharing: " .. ns.Comm.Status())
	Print("  Objects pointed at here: " .. (#seenNames > 0 and table.concat(seenNames, ", ") or "none"))
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
	db.apiDump = nil -- left by a test build
	db.spellScan = nil -- left by a test build
	-- 1.3.0 had the opposite option, "also list missing features".
	if db.settings.showInactive == false then
		db.settings.onlyAvailable = true
	end
	db.settings.showInactive = nil
	-- The game's label and buff text for each camp object, learned from Camp Benefits.
	db.labels = db.labels or {}
	db.known = db.known or {}
	-- 1.5.0 could save "Loom" as the banner's label: drop labels that name another object.
	for key, label in pairs(db.labels) do
		for _, object in ipairs(CAMP_OBJECTS) do
			if object.key ~= key and type(label) == "string" and object.name:lower() == label:lower() then
				db.labels[key] = nil
				db.known[key] = nil
			end
		end
	end
	ns.db = db
end

-- The game's ID of a world object or creature, from its GUID (the client may hide it).
local function GuidID(guid)
	guid = Unsecret(guid)
	if type(guid) ~= "string" then
		return nil
	end
	local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
	if kind == "GameObject" or kind == "Creature" or kind == "Vehicle" then
		return tonumber(id)
	end
end

-- The camp object a tooltip is about. Towns have plain anvils and looms: an ID settles it,
-- and without one only objects near a campfire count. Creatures need the ID, as any
-- player or pet could have an object's name.
local function TooltipObject(name, id, isUnit)
	if id then
		return OBJECT_BY_ID[id]
	elseif not isUnit and state.nearCampfire then
		return ObjectByName(name)
	end
end

local function FireSlots(name, id)
	if id then
		return FIRE_IDS[id]
	end
	for _, fire in ipairs(FIRES) do
		if name == fire.name or name == Unsecret(SpellName(fire.place)) then
			return fire.slots
		end
	end
end

-- Under a camp object's name, add the buff it gives when you sit by the campfire.
local function AddBuffToTooltip(tooltip, object)
	local logo = "|T" .. ns.LOGO .. ":14:14|t "
	local text = BuffText(object)
	if object.utility then
		-- No camp buff: say what it is for, in grey.
		tooltip:AddLine(logo .. (text or L.NO_BUFF_KNOWN), 0.7, 0.7, 0.7, true)
	elseif text and text ~= "" then
		local target = (object.same and ObjectByKey(object.same)) or object
		local buff = target.spell and SpellName(target.spell)
		tooltip:AddLine(logo .. (buff or ObjectName(target)), 0.3, 1, 0.3)
		tooltip:AddLine(text, 1, 1, 1, true)
		local covered = CoveredBy(object)
		if covered then
			tooltip:AddLine(L.COVERED:format(covered), 1, 0.4, 0.3, true)
		end
		local use = object.same and PlaceSentence(object)
		if use then
			tooltip:AddLine(use, 0.7, 0.7, 0.7, true)
		end
	else
		tooltip:AddLine(logo .. L.NO_BUFF_KNOWN, 0.7, 0.7, 0.7, true)
	end
	tooltip:Show()
end

local function HookObjectTooltips()
	local types = Enum and Enum.TooltipDataType
	if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and types) then
		return
	end
	local function firstLine(tooltip)
		local name = tooltip.GetName and tooltip:GetName()
		local fs = name and _G[name .. "TextLeft1"]
		return fs and Unsecret(fs:GetText())
	end
	local function hook(isUnit)
		return function(tooltip, data)
			if not tooltip or not tooltip.AddLine or not ns.db then
				return
			end
			local id = GuidID(data and data.guid)
			if isUnit and not id then
				return
			end
			local line = data and data.lines and data.lines[1]
			local name = (line and Unsecret(line.leftText)) or firstLine(tooltip)
			local object = TooltipObject(name, id, isUnit)
			if object then
				AddBuffToTooltip(tooltip, object)
				if state.nearCampfire then
					SeeObject(object)
				end
				return
			end
			local slots = not isUnit and FireSlots(name, id)
			if slots then
				tooltip:AddLine("|T" .. ns.LOGO .. ":14:14|t " .. L.FIRE_SLOTS:format(slots), 0.3, 1, 0.3, true)
				tooltip:Show()
			end
		end
	end
	if types.Object then
		TooltipDataProcessor.AddTooltipPostCall(types.Object, hook(false))
	end
	if types.Unit then
		TooltipDataProcessor.AddTooltipPostCall(types.Unit, hook(true))
	end
end

-- Buff values grow with your level, so values learned at another level are dropped.
local function CheckLevel(level)
	level = level or UnitLevel("player")
	if ns.db.knownLevel ~= level then
		ns.db.knownLevel = level
		ns.db.known = {}
	end
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
	elseif cmd == "news" then
		ns.WhatsNew.Show()
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
		state.firstRun = CampInfoForeverDB == nil
		InitDB()
		ns.Options.Init()
		SLASH_CAMPINFOFOREVER1 = "/cif"
		SLASH_CAMPINFOFOREVER2 = "/campinfo"
		SlashCmdList.CAMPINFOFOREVER = SlashHandler
		self:RegisterEvent("PLAYER_LOGIN")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterUnitEvent("UNIT_AURA", "player")
		self:RegisterEvent("CHAT_MSG_WHISPER")
		self:RegisterEvent("PLAYER_LEVEL_UP")
	elseif event == "PLAYER_LOGIN" then
		CheckLevel()
		PreloadSpells()
		HookObjectTooltips()
		Print(L.LOADED)
		ns.WhatsNew.Init(state.firstRun)
	elseif event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(2, Update)
	elseif event == "PLAYER_LEVEL_UP" then
		CheckLevel(arg1)
	elseif event == "UNIT_AURA" then
		QueueUpdate()
	elseif event == "CHAT_MSG_WHISPER" then
		OnWhisper(arg1, arg2)
	end
end)
