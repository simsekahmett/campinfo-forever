local _, ns = ...
local L = ns.L

-- A page that tells what a new version brings, shown once after an update.
--
-- Each release with something to tell adds an entry on top of NOTES. The page opens when
-- the newest entry has not been seen, so it works the same for a release and for a
-- development copy. A fresh install is shown nothing: nothing is new to a new user.

local WhatsNew = {}
ns.WhatsNew = WhatsNew

local GOLD = "|cffffd100"
local GRAY = "|cff909090"
local WIDTH, MIN_HEIGHT, PADDING = 460, 300, 16

-- The newest first. In each language: a section title, followed by its lines ("- ...").
WhatsNew.NOTES = {
	{
		version = "1.6.0",
		enUS = {
			"Camps shared between players",
			"- Camps you visit are shared with other players of the addon. Before you sit, the panel shows what others saw at the fire and when.",
			"- Nothing older than 15 minutes is shown: that is how long a fire lasts. You can turn sharing off in the settings.",
			"Camps on the map",
			"- Recently seen camps are campfires on the world map. Point at one for its objects and buffs.",
			"Camp objects",
			"- Every tier of camp object is known, such as the Anvil, Greenhouse and Spinning Wheel.",
			"- Tooltips warn you when a class buff you have already gives the camp's buff.",
			"- A campfire's tooltip shows how many camp features fit around it.",
		},
		trTR = {
			"Oyuncular arası kamp paylaşımı",
			"- Uğradığın kamplar addonu kullanan diğer oyuncularla paylaşılır. Oturmadan önce panel, başkalarının o ateşte ne gördüğünü ve saatini gösterir.",
			"- 15 dakikadan eski bilgi gösterilmez, çünkü ateş o kadar yanar. Paylaşımı ayarlardan kapatabilirsin.",
			"Haritada kamplar",
			"- Son görülen kamplar dünya haritasında kamp ateşi olarak çıkar. Objeleri ve buffları için üstüne gel.",
			"Kamp objeleri",
			"- Anvil, Greenhouse ve Spinning Wheel gibi tüm kademelerdeki objeler tanınıyor.",
			"- Sendeki bir sınıf buffı kampın buffını zaten veriyorsa tooltip uyarır.",
			"- Kamp ateşinin tooltipi kaç kamp özelliği aldığını gösterir.",
		},
		deDE = {
			"Lager mit anderen teilen",
			"- Lager, die du besuchst, werden mit anderen Nutzern des Addons geteilt. Schon vor dem Hinsetzen zeigt das Fenster, was andere dort wann gesehen haben.",
			"- Nichts ist älter als 15 Minuten: So lange brennt ein Feuer. Das Teilen lässt sich in den Einstellungen abschalten.",
			"Lager auf der Karte",
			"- Zuletzt gesehene Lager erscheinen als Lagerfeuer auf der Weltkarte. Zeige darauf, um Objekte und Buffs zu sehen.",
			"Lagerobjekte",
			"- Alle Stufen der Lagerobjekte sind bekannt.",
			"- Tooltips warnen, wenn ein Klassenbuff den Lagerbuff schon gibt.",
			"- Der Tooltip eines Lagerfeuers zeigt, wie viele Einrichtungen Platz haben.",
		},
		frFR = {
			"Camps partagés entre joueurs",
			"- Les camps visités sont partagés avec les autres utilisateurs de l'addon. Avant de vous asseoir, le panneau montre ce que d'autres y ont vu et quand.",
			"- Rien de plus de 15 minutes n'est montré : c'est la durée d'un feu. Le partage se désactive dans les options.",
			"Camps sur la carte",
			"- Les camps vus récemment apparaissent comme des feux de camp sur la carte du monde. Survolez-les pour voir objets et buffs.",
			"Objets de camp",
			"- Tous les niveaux d'objets de camp sont reconnus.",
			"- Les infobulles préviennent si un buff de classe donne déjà celui du camp.",
			"- L'infobulle d'un feu indique combien d'éléments il accueille.",
		},
		esES = {
			"Campamentos compartidos",
			"- Los campamentos que visitas se comparten con otros usuarios del addon. Antes de sentarte, el panel muestra qué vieron otros allí y cuándo.",
			"- No se muestra nada de más de 15 minutos: es lo que dura un fuego. Puedes desactivarlo en las opciones.",
			"Campamentos en el mapa",
			"- Los campamentos vistos hace poco aparecen como hogueras en el mapa. Apunta a uno para ver sus objetos y beneficios.",
			"Objetos de campamento",
			"- Se reconocen todos los niveles de objetos.",
			"- Los tooltips avisan si un beneficio de clase ya da el del campamento.",
			"- El tooltip de una hoguera muestra cuántos elementos admite.",
		},
		ptBR = {
			"Acampamentos compartilhados",
			"- Os acampamentos que você visita são compartilhados com outros usuários do addon. Antes de sentar, o painel mostra o que outros viram ali e quando.",
			"- Nada com mais de 15 minutos é mostrado: é o que dura uma fogueira. Desative nas opções.",
			"Acampamentos no mapa",
			"- Acampamentos vistos recentemente aparecem como fogueiras no mapa. Aponte para ver objetos e bônus.",
			"Objetos de acampamento",
			"- Todos os níveis de objetos são reconhecidos.",
			"- As dicas avisam quando um bônus de classe já dá o do acampamento.",
			"- A dica da fogueira mostra quantos itens ela comporta.",
		},
		ruRU = {
			"Общие лагеря",
			"- Посещённые лагеря передаются другим пользователям аддона. Ещё до отдыха окно показывает, что и когда видели там другие.",
			"- Данные старше 15 минут не показываются: столько горит костёр. Отключить можно в настройках.",
			"Лагеря на карте",
			"- Недавно замеченные лагеря отмечены кострами на карте мира. Наведите курсор, чтобы увидеть объекты и эффекты.",
			"Объекты лагеря",
			"- Распознаются объекты всех уровней.",
			"- Подсказка предупредит, если классовый эффект уже даёт то же самое.",
			"- Подсказка костра показывает, сколько объектов он вмещает.",
		},
		itIT = {
			"Accampamenti condivisi",
			"- Gli accampamenti che visiti sono condivisi con gli altri utenti dell'addon. Prima di sederti, il pannello mostra cosa hanno visto gli altri e quando.",
			"- Nulla di più vecchio di 15 minuti: tanto dura un fuoco. Puoi disattivarlo nelle opzioni.",
			"Accampamenti sulla mappa",
			"- Gli accampamenti visti di recente appaiono come falò sulla mappa. Passaci sopra per oggetti e benefici.",
			"Oggetti",
			"- Sono riconosciuti gli oggetti di ogni livello.",
			"- I tooltip avvisano se un beneficio di classe dà già quello dell'accampamento.",
			"- Il tooltip del falò mostra quanti elementi contiene.",
		},
		koKR = {
			"야영지 공유",
			"- 방문한 야영지가 다른 애드온 사용자와 공유됩니다. 앉기 전에도 다른 사람이 언제 무엇을 봤는지 볼 수 있습니다.",
			"- 모닥불이 15분간 타므로 15분이 지난 정보는 표시되지 않습니다. 설정에서 공유를 끌 수 있습니다.",
			"지도의 야영지",
			"- 최근 확인된 야영지가 세계 지도에 모닥불로 표시됩니다. 마우스를 올리면 시설과 효과가 보입니다.",
			"야영 시설",
			"- 모든 등급의 시설을 인식합니다.",
			"- 직업 강화 효과와 겹치면 툴팁에서 알려 줍니다.",
			"- 모닥불 툴팁에 설치 가능한 시설 수가 표시됩니다.",
		},
		zhCN = {
			"玩家共享营地",
			"- 你到过的营地会与其他插件用户分享。坐下之前，面板就会显示别人在何时看到了什么。",
			"- 不显示超过 15 分钟的信息，因为营火只燃烧这么久。可在设置中关闭。",
			"地图上的营地",
			"- 最近看到的营地会以营火显示在世界地图上，指向它可查看设施和增益。",
			"营地设施",
			"- 可识别所有等级的设施。",
			"- 若职业增益已提供相同效果，提示中会提醒。",
			"- 营火的提示会显示可容纳的设施数量。",
		},
		zhTW = {
			"玩家共享營地",
			"- 你到過的營地會與其他插件使用者分享。坐下之前，面板就會顯示別人在何時看到了什麼。",
			"- 不顯示超過 15 分鐘的資訊，因為營火只燃燒這麼久。可在設定中關閉。",
			"地圖上的營地",
			"- 最近看到的營地會以營火顯示在世界地圖上，指向它可查看設施和增益。",
			"營地設施",
			"- 可辨識所有等級的設施。",
			"- 若職業增益已提供相同效果，提示中會提醒。",
			"- 營火的提示會顯示可容納的設施數量。",
		},
	},
}

local frame
local texts = {}

local function Create()
	frame = CreateFrame("Frame", "CampInfoForeverWhatsNew", UIParent, "BackdropTemplate")
	frame:SetSize(WIDTH, MIN_HEIGHT)
	frame:SetPoint("CENTER", 0, 40)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		frame:SetBackdropColor(0, 0, 0, 0.95)
		frame:SetBackdropBorderColor(1, 0.69, 0.25, 0.9)
	end
	-- Escape closes the page.
	table.insert(UISpecialFrames, "CampInfoForeverWhatsNew")

	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetTexture(ns.LOGO)
	logo:SetSize(40, 40)
	logo:SetPoint("TOPLEFT", PADDING - 4, -PADDING + 6)

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 6, -4)

	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -3)
	subtitle:SetText(L.NEWS_SUBTITLE)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	local done = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	done:SetSize(110, 22)
	done:SetPoint("BOTTOMRIGHT", -PADDING, PADDING - 4)
	done:SetText(OKAY or "OK")
	done:SetScript("OnClick", function()
		frame:Hide()
	end)

	local footer = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	footer:SetPoint("BOTTOMLEFT", PADDING, PADDING + 2)
	footer:SetPoint("RIGHT", done, "LEFT", -8, 0)
	footer:SetJustifyH("LEFT")
	footer:SetText(L.NEWS_AGAIN)
end

local function Fill(notes)
	frame.title:SetText(L.TITLE .. " " .. notes.version)
	local top = -PADDING - 46
	local count = 0
	for _, line in ipairs(notes[GetLocale()] or notes.enUS) do
		count = count + 1
		local text = texts[count]
		if not text then
			text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			text:SetJustifyH("LEFT")
			text:SetJustifyV("TOP")
			text:SetWordWrap(true)
			texts[count] = text
		end
		local body = line:match("^%- (.+)$")
		local indent = body and 8 or 0
		top = top - (body and 5 or (count > 1 and 12 or 0))
		text:SetFontObject(body and "GameFontHighlight" or "GameFontNormal")
		text:ClearAllPoints()
		text:SetPoint("TOPLEFT", PADDING + indent, top)
		text:SetWidth(WIDTH - PADDING * 2 - indent)
		text:SetText(body and (GRAY .. "-|r " .. body) or (GOLD .. line .. "|r"))
		text:Show()
		top = top - (text:GetStringHeight() or 14)
	end
	for i = count + 1, #texts do
		texts[i]:Hide()
	end
	-- The page grows with the notes; the footer and button stay below them.
	frame:SetHeight(math.max(MIN_HEIGHT, -top + 56))
end

function WhatsNew.Show()
	if not frame then
		Create()
	end
	Fill(WhatsNew.NOTES[1])
	frame:Show()
end

-- Opens the page if the newest notes are unseen, once the login has settled and never in combat.
function WhatsNew.Init(firstRun)
	local newest = WhatsNew.NOTES[1].version
	if firstRun then
		ns.db.whatsNew = newest
	end
	if ns.db.whatsNew == newest then
		return
	end
	local function try()
		if InCombatLockdown() then
			local waiter = CreateFrame("Frame")
			waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
			waiter:SetScript("OnEvent", function(self)
				self:UnregisterAllEvents()
				try()
			end)
			return
		end
		ns.db.whatsNew = newest
		WhatsNew.Show()
	end
	C_Timer.After(4, try)
end
