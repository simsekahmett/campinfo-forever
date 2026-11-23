local _, ns = ...
local L = ns.L

-- Camps shared between players with the addon, over a hidden chat channel.
--
-- Messages (addon messages, never visible chat):
--   C;1;mapID;x;y;layer;full;id:age,id:age   a camp: position in 1/10000 of the map, the
--       layer's number (0 = unknown), full = 1 when the list is the whole camp (read from
--       Camp Benefits), and each object's build spell ID with the seconds since it was seen
--   Q;1;mapID                                "which camps are known on this map?"
--
-- Fires and camp objects last 15 minutes, so nothing seen longer ago is kept.

local Comm = {}
ns.Comm = Comm

local PREFIX = "CampInfoFvr"
local CHANNEL = "CampInfoForever"
local KEEP = 15 * 60
Comm.KEEP = KEEP
local SAME_CAMP = 60 -- yards: two reports this close are one camp
local HERE = 120 -- yards: Campfire Nearby reaches about this far
local MAX_CAMPS = 100
local MAX_OBJECTS = 12
local MAX_ANSWERS = 5
local QUERY_EVERY = 600

local camps = {} -- { mapID, x, y, layer, continent, wx, wy, objects = { [key] = server time } }
local layer
local queue, sending = {}, false
local lastResult = "nothing sent yet"
local received = 0

local function Now()
	return GetServerTime()
end

local function Enabled()
	return ns.db and ns.db.settings.network
end

---------------------------------------------------------------------------
-- Where things are
---------------------------------------------------------------------------

local function WorldPosition(mapID, x, y)
	if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
		return nil
	end
	local ok, continent, pos = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x, y))
	if ok and continent and pos then
		return continent, pos.x, pos.y
	end
end

local function Here()
	if IsInInstance() or not (C_Map and C_Map.GetBestMapForUnit) then
		return nil
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	local x, y = ns.Unsecret(pos and pos.x), ns.Unsecret(pos and pos.y)
	if not x or not y or (x == 0 and y == 0) then
		return nil
	end
	return mapID, x, y
end

local function Distance(camp, continent, wx, wy)
	if not continent or camp.continent ~= continent then
		return nil
	end
	return math.sqrt((camp.wx - wx) ^ 2 + (camp.wy - wy) ^ 2)
end

-- Two layers of a zone have different camps in the same place.
local function OtherLayer(camp, mapID, otherLayer)
	return camp.mapID == mapID and camp.layer and otherLayer and camp.layer ~= otherLayer
end

local function Prune()
	local now = Now()
	for i = #camps, 1, -1 do
		local any
		for key, at in pairs(camps[i].objects) do
			if now - at > KEEP then
				camps[i].objects[key] = nil
			else
				any = true
			end
		end
		if not any then
			table.remove(camps, i)
		end
	end
end

local function FindCamp(mapID, x, y, campLayer, radius)
	local continent, wx, wy = WorldPosition(mapID, x, y)
	local best, bestDistance
	for _, camp in ipairs(camps) do
		local distance = not OtherLayer(camp, mapID, campLayer) and Distance(camp, continent, wx, wy)
		if distance and distance <= radius and (not bestDistance or distance < bestDistance) then
			best, bestDistance = camp, distance
		end
	end
	return best
end

-- Adds what was seen. objects = { [key] = time }. A full list (from Camp Benefits) also
-- drops objects that were last seen before it and are not on it.
local function Merge(mapID, x, y, campLayer, full, objects)
	Prune()
	local camp = FindCamp(mapID, x, y, campLayer, SAME_CAMP)
	if not camp then
		local continent, wx, wy = WorldPosition(mapID, x, y)
		if not continent or #camps >= MAX_CAMPS then
			return nil
		end
		camp = { mapID = mapID, x = x, y = y, layer = campLayer, continent = continent, wx = wx, wy = wy, objects = {} }
		camps[#camps + 1] = camp
	end
	camp.layer = camp.layer or campLayer
	local newest = 0
	for key, at in pairs(objects) do
		camp.objects[key] = math.max(camp.objects[key] or 0, at)
		newest = math.max(newest, at)
	end
	if full then
		for key, at in pairs(camp.objects) do
			local object = ns.ObjectByKey(key)
			-- Camp Benefits never lists objects without a buff, so it says nothing of those.
			if not objects[key] and at <= newest and not (object and object.utility) then
				camp.objects[key] = nil
			end
		end
	end
	ns.Panel.RefreshIfShown()
	ns.Map.Refresh()
	return camp
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------

local function ChannelNumber()
	local number = GetChannelName(CHANNEL)
	return type(number) == "number" and number > 0 and number or nil
end

local function Pump()
	local message = table.remove(queue, 1)
	if not message then
		sending = false
		return
	end
	local number = ChannelNumber()
	if Enabled() and number then
		local ok, result = pcall(C_ChatInfo.SendAddonMessage, PREFIX, message, "CHANNEL", tostring(number))
		lastResult = ok and tostring(result) or ("error: " .. tostring(result))
	end
	C_Timer.After(1.2, Pump)
end

local function Send(message)
	if not Enabled() or not (C_ChatInfo and C_ChatInfo.SendAddonMessage) or #queue >= 20 or #message > 250 then
		return
	end
	queue[#queue + 1] = message
	if not sending then
		sending = true
		Pump()
	end
end

local function CampMessage(camp, full)
	local now, list = Now(), {}
	for key, at in pairs(camp.objects) do
		local object = ns.ObjectByKey(key)
		if object and object.place and #list < MAX_OBJECTS then
			list[#list + 1] = object.place .. ":" .. math.max(0, now - at)
		end
	end
	if #list == 0 then
		return nil
	end
	return ("C;1;%d;%d;%d;%d;%d;%s"):format(camp.mapID, math.floor(camp.x * 10000 + 0.5), math.floor(camp.y * 10000 + 0.5),
		camp.layer or 0, full and 1 or 0, table.concat(list, ","))
end

-- You sat at this camp and its buffs arrived: keys is everything Camp Benefits listed.
function Comm.Confirm(keys)
	local mapID, x, y = Here()
	if not mapID or #keys == 0 then
		return
	end
	local objects = {}
	for _, key in ipairs(keys) do
		objects[key] = Now()
	end
	local camp = Merge(mapID, x, y, layer, true, objects)
	local message = camp and CampMessage(camp, true)
	if message then
		Send(message)
	end
end

-- You pointed at an object near a fire. Sent a few seconds later, so that pointing at
-- several objects makes one message.
local seenPending
function Comm.Seen(key)
	local mapID, x, y = Here()
	if not mapID then
		return
	end
	-- At a camp already known, the object is at its fire, not where you stand.
	local known = FindCamp(mapID, x, y, layer, HERE)
	if known then
		mapID, x, y = known.mapID, known.x, known.y
	end
	local camp = Merge(mapID, x, y, layer, false, { [key] = Now() })
	if not camp or seenPending then
		return
	end
	seenPending = true
	C_Timer.After(6, function()
		seenPending = nil
		local message = CampMessage(camp, false)
		if message then
			Send(message)
		end
	end)
end

local lastQuery = {}
function Comm.Query(mapID)
	mapID = mapID or Here()
	local now = GetTime()
	if not mapID or not ChannelNumber() or (lastQuery[mapID] and now - lastQuery[mapID] < QUERY_EVERY) then
		return
	end
	lastQuery[mapID] = now
	Send("Q;1;" .. mapID)
end

---------------------------------------------------------------------------
-- Receiving. Nothing a player sends is ever shown as text: only known objects and numbers.
---------------------------------------------------------------------------

local recent, total, windowAt = {}, 0, 0
local function Flooding(sender)
	local now = GetTime()
	if now - windowAt > 60 then
		recent, total, windowAt = {}, 0, now
	end
	recent[sender] = (recent[sender] or 0) + 1
	total = total + 1
	return recent[sender] > 15 or total > 120
end

local function WholeNumber(text, low, high)
	local n = type(text) == "string" and text:match("^%d+$") and tonumber(text)
	return n and n >= low and n <= high and n or nil
end

local function OnCamp(mapID, x, y, campLayer, full, list)
	mapID, x, y = WholeNumber(mapID, 1, 100000), WholeNumber(x, 0, 10000), WholeNumber(y, 0, 10000)
	campLayer = WholeNumber(campLayer, 0, 2 ^ 31)
	if not (mapID and x and y and campLayer and list) or not C_Map.GetMapInfo(mapID) then
		return
	end
	local objects, count = {}, 0
	for id, age in list:gmatch("(%d+):(%d+)") do
		local object = ns.ObjectByPlace(tonumber(id))
		age = WholeNumber(age, 0, KEEP)
		if object and age and count < MAX_OBJECTS then
			objects[object.key] = Now() - age
			count = count + 1
		end
	end
	if count > 0 then
		Merge(mapID, x / 10000, y / 10000, campLayer > 0 and campLayer or nil, full == "1", objects)
	end
end

-- Someone asked about a map. Everyone who knows something waits a random moment, and
-- leaves out the camps somebody else told about meanwhile.
local lastAnswer = {}
local function OnQuery(mapID)
	mapID = WholeNumber(mapID, 1, 100000)
	local now = GetTime()
	if not mapID or (lastAnswer[mapID] and now - lastAnswer[mapID] < 30) then
		return
	end
	lastAnswer[mapID] = now
	C_Timer.After(1 + math.random() * 7, function()
		Prune()
		local sent = 0
		for _, camp in ipairs(camps) do
			if camp.mapID == mapID and sent < MAX_ANSWERS and (camp.toldAt or 0) < now then
				local message = CampMessage(camp, false)
				if message then
					Send(message)
					camp.toldAt = GetTime()
					sent = sent + 1
				end
			end
		end
	end)
end

function Comm.OnMessage(prefix, message, chatType, sender)
	prefix, message, chatType, sender = ns.Unsecret(prefix), ns.Unsecret(message), ns.Unsecret(chatType), ns.Unsecret(sender)
	if prefix ~= PREFIX or chatType ~= "CHANNEL" or type(message) ~= "string" or type(sender) ~= "string" or not Enabled() then
		return
	end
	if Ambiguate(sender, "none") == UnitName("player") or Flooding(sender) then
		return
	end
	received = received + 1
	local kind, version, a, b, c, d, e, f = strsplit(";", message)
	if version ~= "1" then
		return
	end
	if kind == "C" then
		OnCamp(a, b, c, d, e, f)
		local mapID, x, y = tonumber(a), tonumber(b), tonumber(c)
		local camp = mapID and x and y and FindCamp(mapID, x / 10000, y / 10000, nil, SAME_CAMP)
		if camp then
			camp.toldAt = GetTime()
		end
	elseif kind == "Q" then
		OnQuery(a)
	end
end

---------------------------------------------------------------------------
-- For the panel
---------------------------------------------------------------------------

-- The camp whose fire you are at: { [key] = server time last seen }, or nil.
function Comm.CampHere()
	local mapID, x, y = Here()
	if not mapID or not Enabled() then
		return nil
	end
	Prune()
	local camp = FindCamp(mapID, x, y, layer, HERE)
	return camp and camp.objects
end

-- Other camps on your map, nearest first: { x, y, distance, objects, at }.
function Comm.Nearby(limit)
	local mapID, x, y = Here()
	local list = {}
	if not mapID or not Enabled() then
		return list
	end
	Prune()
	local continent, wx, wy = WorldPosition(mapID, x, y)
	for _, camp in ipairs(camps) do
		local distance = Distance(camp, continent, wx, wy)
		if camp.mapID == mapID and distance and not OtherLayer(camp, mapID, layer) then
			local at = 0
			for _, t in pairs(camp.objects) do
				at = math.max(at, t)
			end
			list[#list + 1] = { x = camp.x, y = camp.y, distance = distance, objects = camp.objects, at = at }
		end
	end
	table.sort(list, function(a, b)
		return a.distance < b.distance
	end)
	for i = #list, limit + 1, -1 do
		list[i] = nil
	end
	return list
end

-- Every camp known, for the world map.
function Comm.All()
	local list = {}
	if not ns.db then
		return list
	end
	Prune()
	local here = C_Map.GetBestMapForUnit("player")
	for _, camp in ipairs(camps) do
		if not OtherLayer(camp, here, layer) then
			local at, count = 0, 0
			for _, t in pairs(camp.objects) do
				at, count = math.max(at, t), count + 1
			end
			list[#list + 1] = { mapID = camp.mapID, x = camp.x, y = camp.y, continent = camp.continent,
				wx = camp.wx, wy = camp.wy, objects = camp.objects, at = at, count = count }
		end
	end
	return list
end

-- Camps are kept over a /reload, for each realm and faction.
local function LoadCamps()
	local key = tostring(GetRealmName()) .. "-" .. tostring(UnitFactionGroup("player"))
	ns.db.camps = ns.db.camps or {}
	camps = ns.db.camps[key] or {}
	ns.db.camps = { [key] = camps } -- others would be too old by the time they are needed
	for _, camp in ipairs(camps) do
		camp.toldAt = nil -- a time from the last session
	end
	Prune()
end

function Comm.Status()
	local number = ChannelNumber()
	return ("channel %s, layer %s, last send: %s, received: %d, camps: %d"):format(
		number and tostring(number) or "not joined", tostring(layer), lastResult, received, #camps)
end

---------------------------------------------------------------------------
-- Joining and leaving the channel
---------------------------------------------------------------------------

local function Hide()
	if ChatFrame_RemoveChannel then
		for i = 1, NUM_CHAT_WINDOWS or 10 do
			local chatFrame = _G["ChatFrame" .. i]
			if chatFrame then
				pcall(ChatFrame_RemoveChannel, chatFrame, CHANNEL)
			end
		end
	end
end

-- Waits until the game's own channels (General, Trade...) have their numbers.
local function Join(tries)
	if not Enabled() then
		return
	elseif ChannelNumber() then -- still joined after a /reload
		Hide()
		Comm.Query()
		return
	end
	if not GetChannelList() and tries > 0 then
		C_Timer.After(5, function()
			Join(tries - 1)
		end)
		return
	end
	local join = JoinTemporaryChannel or JoinChannelByName
	if join then
		pcall(join, CHANNEL)
		C_Timer.After(2, function()
			Hide()
			Comm.Query()
		end)
	end
end

function Comm.Apply()
	if Enabled() then
		Join(6)
	elseif ChannelNumber() and LeaveChannelByName then
		LeaveChannelByName(CHANNEL)
		wipe(camps)
		wipe(queue)
	end
	ns.Panel.RefreshIfShown()
	ns.Map.Refresh()
end

local function SeeUnit(unit)
	local guid = UnitGUID(unit)
	guid = ns.Unsecret(guid)
	if type(guid) == "string" then
		local uid = guid:match("^Creature%-%d+%-%d+%-%d+%-(%d+)%-")
		uid = uid and tonumber(uid)
		if uid and uid > 0 then
			layer = uid
		end
	end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "ZONE_CHANGED_NEW_AREA", "CHAT_MSG_ADDON" }) do
	events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, ...)
	if event == "CHAT_MSG_ADDON" then
		Comm.OnMessage(...)
	elseif event == "PLAYER_TARGET_CHANGED" then
		SeeUnit("target")
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		SeeUnit("mouseover")
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		SeeUnit((...))
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		layer = nil
		C_Timer.After(5, function()
			Comm.Query()
		end)
	elseif event == "PLAYER_LOGIN" then
		LoadCamps()
		if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
			C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
		end
		if Enabled() and not ns.db.networkNotice then
			ns.db.networkNotice = true
			ns.Print(L.NET_NOTICE)
		end
		C_Timer.After(15, Comm.Apply)
	end
end)
