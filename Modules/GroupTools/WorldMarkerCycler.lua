local _, addon = ...
local L = addon.L
local API = addon.API

local InCombatLockdown = InCombatLockdown
local SecureHandlerExecute = SecureHandlerExecute
local SecureHandlerUnwrapScript = SecureHandlerUnwrapScript
local SecureHandlerWrapScript = SecureHandlerWrapScript

local WORLD_MARKERS = {
	{ id = 1, icon = "Star", texAtlas = 8, wmID = 5 },
	{ id = 2, icon = "Circle", texAtlas = 7, wmID = 6 },
	{ id = 3, icon = "Diamond", texAtlas = 6, wmID = 3 },
	{ id = 4, icon = "Triangle", texAtlas = 5, wmID = 2 },
	{ id = 5, icon = "Moon", texAtlas = 4, wmID = 7 },
	{ id = 6, icon = "Square", texAtlas = 3, wmID = 1 },
	{ id = 7, icon = "X", texAtlas = 2, wmID = 4 },
	{ id = 8, icon = "Skull", texAtlas = 1, wmID = 8 },
}

local WMC = CreateFrame("Frame")

-- Helper Functions
function WMC:ProcessPlacerOrder()
	local db = addon.GetDBValue("WorldMarkerCyclerSettings")
	local order = db.order
	local markers = db.markers

	if not order or #order == 0 then
		order = { 1, 2, 3, 4, 5, 6, 7, 8 }
	end

	local result = {}
	for _, markerID in ipairs(order) do
		-- Only include enabled markers
		if markers[markerID] then
			local wmID = WORLD_MARKERS[markerID].wmID
			if wmID then
				table.insert(result, wmID)
			end
		end
	end

	return result
end

function WMC:Initialize()
	if WMC.Placer and WMC.Remover then
		return
	end

	WMC.order = self:ProcessPlacerOrder()

	WMC.Placer = WMC.Placer or CreateFrame("Button", "AeonTools_WMC_Placer", nil, "SecureActionButtonTemplate")
	WMC.Placer:SetAttribute("typerelease", "macro")
	WMC.Placer:SetAttribute("pressAndHoldAction", true)
	WMC.Placer:SetAttribute("WorldMarker_Current", WMC.order[1])
	WMC.Placer:SetAttribute("enableMarkers", true)

	WMC.Placer:HookScript("PreClick", function()
		if not IsInRaid() and not IsInGroup() then
			return
		end
	end)

	WMC.Placer:HookScript("PostClick", function()
		if not IsInRaid() and not IsInGroup() then
			return
		end
		if not WMC.Placer:GetAttribute("enableMarkers") then
			addon:PrintDebug("Marker placement disabled")
		else
			local placed = WMC.Placer:GetAttribute("placedMarker")
			local atlas

			for _, marker in ipairs(WORLD_MARKERS) do
				if marker.wmID == placed then
					atlas = "GM-raidMarker" .. marker.texAtlas
					break
				end
			end

			if atlas then
				addon:PrintDebug(CreateAtlasMarkup(atlas) .. " Marker Placed")
			end
		end
	end)

	WMC:WrapPlacer()

	WMC.Remover = WMC.Remover or CreateFrame("Button", "AeonTools_WMC_Remover", nil, "SecureActionButtonTemplate")
	WMC.Remover:SetAttribute("type", "macro")
	WMC.Remover:RegisterForClicks("AnyUp", "AnyDown")
	WMC.Remover:SetAttribute("macrotext", "/clearworldmarker all")
	WMC.Remover:SetScript("PreClick", function()
		if not InCombatLockdown() then
			WMC.Placer:SetAttribute("resetMarker", true)
		end
	end)
end

function WMC:WrapPlacer()
	if not WMC.Placer then
		return
	end

	WMC.Placer:SetAttribute("WorldMarker_Current", WMC.order[1])

	local body = "i = 0;order = newtable()"
	for _, index in ipairs(WMC.order) do
		body = body .. format("tinsert(order, %s)", index)
	end

	SecureHandlerExecute(WMC.Placer, body)
	SecureHandlerUnwrapScript(WMC.Placer, "PreClick")
	SecureHandlerWrapScript(
		WMC.Placer,
		"PreClick",
		WMC.Placer,
		[=[
		
	if not self:GetAttribute("enableMarkers") then
		self:SetAttribute("macrotext", "")
		return
	end
	
	if self:GetAttribute("resetMarker") then
		i=1
		self:SetAttribute("resetMarker",false)
		self:SetAttribute("currentMarker",order[i])
	else
		i = i%#order + 1
		self:SetAttribute("currentMarker",order[i])
	end
	self:SetAttribute("placedMarker",order[i])
	self:SetAttribute("macrotext", "/wm [@cursor]"..self:GetAttribute("currentMarker"))
	]=]
	)
end

local function Options_Update_PlacerOrder()
	WMC.order = WMC:ProcessPlacerOrder()
	WMC:WrapPlacer()
end

-- ============================================================================
-- Preview Frame with Drag-and-Drop Reordering
-- ============================================================================
local function CreateIconCheckboxFrame(parent, iconTexture, widgetData, markerID)
	local WIDTH = 52
	local HEIGHT = WIDTH * (2.5 / 1) -- 1:3 ratio
	local ICON_SIZE = WIDTH * 0.7 -- top half is square

	-- Main frame
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(WIDTH, HEIGHT)
	f.markerID = markerID

	---------------------------------------------------------
	-- 1. Background (same as dropdown menu background)
	---------------------------------------------------------
	local bg = addon.CreateNineSliceFrame(f, "ExpansionBorder_TWW")
	f.Background = bg
	bg:SetUsingParentLevel(true)
	bg:SetCornerSize(38, 38)
	bg:SetDisableSharpening(false)
	bg:CoverParent(0)
	bg:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/ExpansionBorder_TWW")
	bg.pieces[1]:SetTexCoord(512 / 1024, 544 / 1024, 320 / 1024, 352 / 1024)
	bg.pieces[2]:SetTexCoord(544 / 1024, 736 / 1024, 320 / 1024, 352 / 1024)
	bg.pieces[3]:SetTexCoord(736 / 1024, 768 / 1024, 320 / 1024, 352 / 1024)
	bg.pieces[4]:SetTexCoord(512 / 1024, 544 / 1024, 352 / 1024, 544 / 1024)
	bg.pieces[5]:SetTexCoord(544 / 1024, 736 / 1024, 352 / 1024, 544 / 1024)
	bg.pieces[6]:SetTexCoord(736 / 1024, 768 / 1024, 352 / 1024, 544 / 1024)
	bg.pieces[7]:SetTexCoord(512 / 1024, 544 / 1024, 544 / 1024, 576 / 1024)
	bg.pieces[8]:SetTexCoord(544 / 1024, 736 / 1024, 544 / 1024, 576 / 1024)
	bg.pieces[9]:SetTexCoord(736 / 1024, 768 / 1024, 544 / 1024, 576 / 1024)

	---------------------------------------------------------
	-- 2. Icon (top half)
	---------------------------------------------------------
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOP", f, "TOP", 0, -5)
	tex:SetSize(ICON_SIZE, ICON_SIZE)
	tex:SetTexture(iconTexture)
	f.icon = tex

	---------------------------------------------------------
	-- 3. Drag Indicator (shown while dragging)
	---------------------------------------------------------
	-- local dragOverlay = f:CreateTexture(nil, "OVERLAY")
	-- dragOverlay:SetAllPoints(f)
	-- dragOverlay:SetColorTexture(1, 1, 1, 0.3)
	-- dragOverlay:Hide()
	-- f.dragOverlay = dragOverlay

	---------------------------------------------------------
	-- 3. Drag Overlay (nine-slice clone of background)
	---------------------------------------------------------
	local dragOverlay = addon.CreateNineSliceFrame(f, "ExpansionBorder_TWW")
	dragOverlay:SetUsingParentLevel(true)
	dragOverlay:SetFrameLevel(f:GetFrameLevel() + 20)
	dragOverlay:CoverParent(0)

	-- Match the background's corner size
	dragOverlay:SetCornerSize(38, 38)

	-- Apply same texcoords as background
	for i = 1, 9 do
		dragOverlay.pieces[i]:SetTexCoord(bg.pieces[i]:GetTexCoord())
	end

	-- Tint overlay
	for i = 1, 9 do
		dragOverlay.pieces[i]:SetVertexColor(1, 1, 1, 0.35)
	end

	dragOverlay:Hide()
	f.dragOverlay = dragOverlay

	---------------------------------------------------------
	-- 4. Reposition Button (center) - now acts as drag handle
	---------------------------------------------------------
	local reposition = addon.CreateRepositionButton(f, ICON_SIZE)
	reposition:SetOrientation("x")
	reposition:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.RepositionButton = reposition

	---------------------------------------------------------
	-- 5. Checkbox (bottom half)
	---------------------------------------------------------
	f.Checkbox = addon.CreateCheckboxOnly(f, nil, ICON_SIZE)
	f.Checkbox:SetPoint("BOTTOM", f, "BOTTOM", 1, 5)
	f.Checkbox:SetData(widgetData)
	f.Checkbox:SetChecked(addon.GetDBValue(widgetData.dbKey))

	return f
end

local PreviewFrameMixin = {}

function PreviewFrameMixin:OnLoad()
	-- Marker icon mapping
	self.MARKER_ICONS = {
		[1] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
		[2] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
		[3] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
		[4] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
		[5] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
		[6] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
		[7] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
		[8] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
	}

	-- Layout constants
	self.itemWidth = 52
	self.N = 8
	self.containerWidth = self:GetWidth()
	self.gap = (self.containerWidth - (self.N * self.itemWidth)) / (self.N + 1)

	-- Dragged-frame tracking (set/cleared by OnDragStart/OnDragStop)
	self.draggedItem = nil
	self.insertIndex = nil

	-- Create insertion indicator
	self:CreateInsertionIndicator()

	-- Load current order from DB
	self:LoadOrder()

	-- Create all frames
	self:CreateFrames()
end

function PreviewFrameMixin:CreateInsertionIndicator()
	local indicator = self:CreateTexture(nil, "OVERLAY")
	indicator:SetAtlas("Adventure-MissionEnd-Line")
	indicator:SetRotation(math.rad(90))
	indicator:SetSize(self:GetHeight() - 32, 12)

	-- Create highlight as a separate texture
	local highlight = self:CreateTexture(nil, "OVERLAY")
	highlight:SetAtlas("QuestLog-header-glow-yellow")
	highlight:SetRotation(math.rad(90))
	highlight:SetSize(self:GetHeight() - 72, 16)
	highlight:SetPoint("CENTER", indicator, "CENTER", -8.5, 0)

	highlight:Hide()
	indicator:Hide()

	indicator.highlight = highlight
	self.insertionIndicator = indicator
end

function PreviewFrameMixin:LoadOrder()
	local settings = addon.GetDBValue("WorldMarkerCyclerSettings")
	local order = settings and settings.order

	-- Initialize default order if empty or missing
	if not order or #order == 0 then
		order = { 1, 2, 3, 4, 5, 6, 7, 8 }
		addon.SetDBValue("WorldMarkerCyclerSettings.order", order)
	end

	self.currentOrder = {}
	for i, markerID in ipairs(order) do
		self.currentOrder[i] = markerID
	end
end

function PreviewFrameMixin:SaveOrder()
	addon.SetDBValue("WorldMarkerCyclerSettings.order", self.currentOrder)
	addon:PrintDebug("WMC order saved:", unpack(self.currentOrder))
end

function PreviewFrameMixin:CreateFrames()
	self.Items = {}

	for index = 1, self.N do
		local markerID = self.currentOrder[index]
		local widgetData = {
			dbKey = string.format("WorldMarkerCyclerSettings.markers[%d]", markerID),
			onClickFunc = Options_Update_PlacerOrder,
		}
		local icon = self.MARKER_ICONS[markerID]
		local item = CreateIconCheckboxFrame(self, icon, widgetData, markerID)

		self.Items[index] = item
		self:PlaceItem(item, index)
		self:SetupItemDrag(item)
	end
end

-- Snap an item to its slot position without touching any other item
function PreviewFrameMixin:PlaceItem(item, index)
	local xOffset = self.gap * index + self.itemWidth * (index - 1)
	-- local xOffset = (index - 1) * (self.ITEM_WIDTH + self.ITEM_SPACING)
	item:ClearAllPoints()
	item:SetPoint("TOPLEFT", self, "TOPLEFT", xOffset, -40)
end

-- Layout all items in their current order
function PreviewFrameMixin:LayoutItems()
	for index, item in ipairs(self.Items) do
		self:PlaceItem(item, index)
	end
end

function PreviewFrameMixin:SetupItemDrag(item)
	local container = self -- captured reference to the preview frame
	local repoBtn = item.RepositionButton

	-- Only the reposition button initiates dragging; the item frame itself
	-- is NOT movable and does NOT have RegisterForDrag.
	repoBtn:RegisterForDrag("LeftButton")

	-- Suppress the built-in frame-moving logic from RepositionButtonMixin,
	-- but keep its icon visual nudge (SetPoint offset) for tactile feedback.
	repoBtn:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and self:IsEnabled() then
			self.Icon:SetPoint("CENTER", self, "CENTER", 0, -1)
			self:LockHighlight()
			-- intentionally do NOT set OnUpdate — we don't want the built-in mover
		end
	end)

	repoBtn:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
			self:UnlockHighlight()
		end
	end)

	repoBtn:SetScript("OnDragStart", function(self)
		container.draggedItem = item
		item:SetAlpha(0.5)

		-- OnUpdate on the container so we have live screen coords every frame
		container:SetScript("OnUpdate", function()
			local cursorX = GetCursorPosition() / UIParent:GetEffectiveScale()
			container:UpdateInsertionIndicator(cursorX)
		end)
	end)

	repoBtn:SetScript("OnDragStop", function(self)
		item:SetAlpha(1)

		self:UnlockHighlight()

		container:SetScript("OnUpdate", nil)
		container.insertionIndicator:Hide()
		container.insertionIndicator.highlight:Hide()

		-- Commit the reorder if we have a valid target
		if container.draggedItem and container.insertIndex then
			container:CommitReorder()
		end
		addon.UpdateSettingsDialog()
		container.draggedItem = nil
		container.insertIndex = nil
	end)
end

-- ---------------------------------------------------------------------------
-- Live indicator update  (identical algorithm to the working Ambrosia code)
-- ---------------------------------------------------------------------------

function PreviewFrameMixin:UpdateInsertionIndicator(cursorX)
	local items = self.Items
	local num = #items
	local newIndex = num + 1 -- default: insert at end

	for i, frame in ipairs(items) do
		if frame ~= self.draggedItem then
			local mid = (frame:GetLeft() + frame:GetRight()) / 2
			if cursorX < mid then
				newIndex = i
				break
			end
		end
	end

	self.insertIndex = newIndex

	-- Position the indicator bar
	self.insertionIndicator:ClearAllPoints()
	if newIndex == 1 then
		self.insertionIndicator:SetPoint("CENTER", items[1], "LEFT", -self.gap / 2, 0)
	elseif newIndex > num then
		self.insertionIndicator:SetPoint("CENTER", items[num], "RIGHT", self.gap / 2, 0)
	else
		self.insertionIndicator:SetPoint("CENTER", items[newIndex - 1], "RIGHT", self.gap / 2, 0)
	end
	self.insertionIndicator:Show()
	self.insertionIndicator.highlight:Show()
end

-- ---------------------------------------------------------------------------
-- Commit reorder after drag stops
-- ---------------------------------------------------------------------------

function PreviewFrameMixin:CommitReorder()
	local dragged = self.draggedItem
	local toIndex = self.insertIndex

	-- Find current slot of dragged item
	local fromIndex
	for i, item in ipairs(self.Items) do
		if item == dragged then
			fromIndex = i
			break
		end
	end

	if not fromIndex then
		return
	end

	-- Adjust target: if we're moving right, the insertion point shifts by -1
	-- after we remove the source element (same behaviour as the working code)
	local adjustedTo = toIndex
	if toIndex > fromIndex then
		adjustedTo = toIndex - 1
	end

	if adjustedTo == fromIndex then
		-- No real change; just snap everything back
		self:LayoutItems()
		return
	end

	-- Reorder self.Items and self.currentOrder in lockstep
	table.remove(self.Items, fromIndex)
	table.insert(self.Items, adjustedTo, dragged)

	table.remove(self.currentOrder, fromIndex)
	table.insert(self.currentOrder, adjustedTo, dragged.markerID)

	-- Snap all frames to their new positions
	self:LayoutItems()

	-- Persist
	self:SaveOrder()
end

-- Settings
function WMC:CreatePreviewFrame()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(650, 210)

	API.Mixin(f, PreviewFrameMixin)

	f.Background = f:CreateTexture(nil, "BACKGROUND")
	f.Background:SetAllPoints()
	f.Background:SetTexture("Interface/AddOns/AeonTools/Assets/Settings/PreviewPane.png")

	f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.label:SetPoint("TOP", 0, -8)
	f.label:SetJustifyH("CENTER")
	f.label:SetTextColor(215 / 255, 192 / 255, 163 / 255)
	f.label:SetText("Drag & Drop to Reorder World Markers")

	f:OnLoad()

	return f
end

local DEFAULT_ORDER = { 1, 2, 3, 4, 5, 6, 7, 8 }

local function Options_ResetOrder_ShouldEnable()
	local dbOrder = addon.GetDBValue("WorldMarkerCyclerSettings.order")
	if not dbOrder then
		return
	end
	for i = 1, #DEFAULT_ORDER do
		if dbOrder[i] ~= DEFAULT_ORDER[i] then
			return true
		end
	end

	return false
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["WMC_Title"],
	customWidth = 700,
	widgets = {
		{
			type = "Custom",
			align = "center",
			widgetKey = "WMC_Preview",
			onAcquire = function()
				local frame = WMC:CreatePreviewFrame()
				frame.effectiveWidth = 650
				return frame
			end,
		},
		{
			type = "Divider",
		},
		{
			type = "HorizontalGroup",
			center = true,
			align = "center",
			spacing = 120,
			widgets = {

				{
					type = "Keybind",
					label = L["WMC_Placer_Label"],
					tooltip = L["WMC_Placer_Tooltip"],
					dbKey = "WorldMarkerCyclerSettings.placerKeybind",
					bindingName = "CLICK AeonTools_WMC_Placer:LeftButton",
					-- defaultKey = "=",
				},
				{
					type = "Keybind",
					label = L["WMC_Remover_Label"],
					tooltip = L["WMC_Remover_Tooltip"],
					dbKey = "WorldMarkerCyclerSettings.removerKeybind",
					bindingName = "CLICK AeonTools_WMC_Remover:LeftButton",
					-- defaultKey = "-",
				},
			},
		},

		{
			type = "UIPanelButton",
			widgetKey = "WMC_ResetOrder",
			label = L["WMC_ResetOrder"] or "Reset Order",
			stateCheckFunc = Options_ResetOrder_ShouldEnable,
			onClickFunc = function()
				local resetOrder = {}
				for i, v in ipairs(DEFAULT_ORDER) do
					resetOrder[i] = v
				end
				addon.SetDBValue("WorldMarkerCyclerSettings.order", resetOrder)
				WMC:CreateOptions(true)
			end,
		},
	},
}

function WMC:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function WMC:ShowOptions(state)
	if state then
		self:CreateOptions(true)
		self.OptionFrame:Show()
		self.OptionFrame:SetScript("OnHide", function() end)
		if self.OptionFrame.requireResetPosition then
			self.OptionFrame.requireResetPosition = false
			self.OptionFrame:ClearAllPoints()
			self.OptionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		end
	else
		if self.OptionFrame then
			self.OptionFrame:HideOption(self)
		end
	end
end

function addon:WMC_ToggleConfig()
	if not addon.db.WorldMarkerCycler then
		return
	end
	local OptionFrame = WMC.OptionFrame
	if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
		WMC:ShowOptions(false)
	else
		WMC:ShowOptions(true)
	end
end

addon:RegisterSlashSubCommand("wm", function()
	addon:WMC_ToggleConfig()
end)

-- Enable/Disable
function WMC:Enable()
	if WMC.Placer and WMC.Remover then
		WMC.Placer:SetAttribute("pressAndHoldAction", true)
		WMC.Placer:SetAttribute("enableMarkers", true)
		WMC:WrapPlacer()
	else
		WMC:Initialize()
	end
end

function WMC:Disable()
	if not WMC.Placer or not WMC.Remover then
		return
	end

	if InCombatLockdown() then
		if not self.disablePending then
			self.disablePending = CreateFrame("Frame")
			self.disablePending:RegisterEvent("PLAYER_REGEN_ENABLED")
			self.disablePending:SetScript("OnEvent", function(f)
				f:UnregisterEvent("PLAYER_REGEN_ENABLED")
				WMC:Disable()
			end)
		end
		return
	end

	WMC.Placer:SetAttribute("enableMarkers", false)
	WMC.Placer:SetAttribute("pressAndHoldAction", false)
	WMC.Placer:SetAttribute("macrotext", "")
	WMC.Placer:SetAttribute("resetMarker", false)

	SecureHandlerUnwrapScript(WMC.Placer, "PreClick")

	WMC.Placer:SetAttribute("placedMarker", nil)
	WMC.Placer:SetAttribute("currentMarker", nil)
end

do
	local function EnableModule(state)
		if state then
			WMC:Enable()
		else
			WMC:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = WMC.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			WMC:ShowOptions(false)
		else
			WMC:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["WMC_Title"],
		dbKey = "WorldMarkerCycler",
		description = L["WMC_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 5,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
