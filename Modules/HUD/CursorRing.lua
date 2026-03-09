---@class addon
local addon = select(2, ...)
---@class API
local API = addon.API
local L = addon.L

local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local GCD_SPELL = 61304
local TEXTURE_FILE = "Interface/AddOns/AeonTools/Assets/CursorRing"

local CursorRing = CreateFrame("Frame")
CursorRing.inCombat = false
CursorRing.gcdInfo = nil
CursorRing.gcdReady = true

local REGISTERED_EVENTS = {
	PLAYER_LOGIN = true,
	PLAYER_ENTERING_WORLD = true,
	PLAYER_REGEN_ENABLED = true,
	PLAYER_REGEN_DISABLED = true,
	SPELL_UPDATE_COOLDOWN = true,
	ACTIONBAR_UPDATE_COOLDOWN = true,
	UNIT_SPELLCAST_SUCCEEDED = true,
}

-- Helpers
local function GetDB()
	local db = addon.GetDBValue("CursorRingSettings") or {}

	if db.size == nil then
		db.size = 56
	end
	if db.combat == nil then
		db.combat = false
	end
	if db.dot == nil then
		db.dot = true
	end
	if db.gcdRing == nil then
		db.gcdRing = true
	end
	if not db.color then
		db.color = { r = 1, g = 1, b = 1 }
	end

	return db
end

function CursorRing:RefreshCombatState()
	CursorRing.inCombat = InCombatLockdown() or UnitAffectingCombat("player")
end

-- Ring Frame Creations
function CursorRing:CreateFrames()
	if self.container then
		return
	end

	local db = GetDB()
	local size = db.size or 56

	local container = CreateFrame("Frame", nil, UIParent)
	container:SetSize(size, size)
	container:SetFrameStrata("TOOLTIP")
	container:EnableMouse(false)
	container:Hide()
	self.container = container

	-- Main ring
	local ring = container:CreateTexture(nil, "OVERLAY")
	ring:SetAllPoints(container)
	ring:SetTexture(TEXTURE_FILE)
	ring:SetBlendMode("BLEND")
	self.ring = ring

	-- Center dot
	local dot = CreateFrame("Frame", nil, UIParent)
	dot:SetSize(6, 6)
	dot:SetFrameStrata("TOOLTIP")
	dot:Hide()
	self.dot = dot

	local dotTex = dot:CreateTexture(nil, "OVERLAY")
	dotTex:SetAllPoints(dot)
	dotTex:SetTexture("Interface/AddOns/AeonTools/Assets/Circle_White")
	dotTex:SetBlendMode("BLEND")
	dot.texture = dotTex

	-- GCD radial
	-- GCD Radial (inner ring)
	local gcdSize = size * 0.7142857143

	local gcdCooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
	gcdCooldown:SetSize(gcdSize, gcdSize)
	gcdCooldown:ClearAllPoints()
	gcdCooldown:SetPoint("CENTER", container, "CENTER", 0, 0)

	gcdCooldown:EnableMouse(false)
	gcdCooldown:SetDrawSwipe(true)
	gcdCooldown:SetDrawEdge(false)
	gcdCooldown:SetHideCountdownNumbers(true)

	if gcdCooldown.SetUseCircularEdge then
		gcdCooldown:SetUseCircularEdge(true)
	end

	---@diagnostic disable-next-line: missing-parameter
	gcdCooldown:SetSwipeTexture(TEXTURE_FILE)
	gcdCooldown:SetReverse(true)
	gcdCooldown:Hide()

	self.gcdCooldown = gcdCooldown

	-- Cursor follow (throttled)
	local lastX, lastY = 0, 0
	local acc = 0
	local THROTTLE = 0.0167

	self.container:SetScript("OnUpdate", function(self, elapsed)
		acc = acc + elapsed
		if acc < THROTTLE then
			return
		end
		acc = 0

		local db = GetDB()
		local visible = (not db.combat) or CursorRing.inCombat
		if not visible then
			return
		end

		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		x, y = math.floor(x / scale + 0.5), math.floor(y / scale + 0.5)

		if x ~= lastX or y ~= lastY then
			lastX, lastY = x, y
			self:ClearAllPoints()
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

			dot:ClearAllPoints()
			dot:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
		end
	end)
end

-- Ring Updates & Rendering
function CursorRing:UpdateRingColor()
	local db = GetDB()
	local r, g, b = db.color.r or 1, db.color.g or 1, db.color.b or 1

	if self.ring then
		self.ring:SetVertexColor(r, g, b, 1)
	end
	if self.dot and self.dot.texture then
		self.dot.texture:SetVertexColor(r, g, b, 1)
	end
	if self.gcdCooldown then
		self.gcdCooldown:SetSwipeColor(r, g, b, 1)
	end
end

function CursorRing:UpdateGCDState()
	local db = GetDB()
	if not db.gcdRing then
		CursorRing.gcdInfo = nil
		CursorRing.gcdReady = true
		return
	end

	local info = C_Spell.GetSpellCooldown(GCD_SPELL)
	if info and info.duration and info.duration > 0 then
		CursorRing.gcdInfo = info
		CursorRing.gcdReady = false
	else
		CursorRing.gcdInfo = nil
		CursorRing.gcdReady = true
	end
end

local function IsOptionsOpen()
	return CursorRing.OptionFrame and CursorRing.OptionFrame:IsShown()
end

function CursorRing:UpdateRender()
	if not self.container then
		return
	end

	local db = GetDB()

	-- Visibility (combat only or always)
	local visible = (not db.combat) or CursorRing.inCombat
	if not visible then
		self.container:Hide()
		if self.dot then
			self.dot:Hide()
		end
		if self.gcdCooldown then
			self.gcdCooldown:Hide()
		end
		return
	end

	self.container:Show()

	-- Dot
	if db.dot then
		self.dot:Show()
	else
		self.dot:Hide()
	end

	-- GCD
	if db.gcdRing and CursorRing.gcdInfo and CursorRing.gcdInfo.duration and CursorRing.gcdInfo.duration > 0 then
		local info = CursorRing.gcdInfo
		if info.modRate then
			self.gcdCooldown:SetCooldown(info.startTime, info.duration, info.modRate)
		else
			self.gcdCooldown:SetCooldown(info.startTime, info.duration)
		end
		self.gcdCooldown:Show()
	else
		self.gcdCooldown:Hide()
	end
end

function CursorRing:UpdateRingProperties()
	if not self.container then
		return
	end

	local db = GetDB()
	local size = db.size or 56
	self.container:SetSize(size, size)

	local gcdSize = size * 0.7142857143
	if self.gcdCooldown then
		self.gcdCooldown:SetSize(gcdSize, gcdSize)
		self.gcdCooldown:ClearAllPoints()
		self.gcdCooldown:SetPoint("CENTER", self.container, "CENTER", 0, 0)
	end

	self:UpdateRingColor()
	self:UpdateRender()
end

-- Event Handling
CursorRing:SetScript("OnEvent", function(self, event, unit, _, spellID)
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		self:RefreshCombatState()
		self:CreateFrames()
		self:UpdateRingProperties()
		self:UpdateGCDState()
		self:UpdateRender()
	elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		self:RefreshCombatState()
		self:UpdateGCDState()
		self:UpdateRender()
	elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
		self:UpdateGCDState()
		self:UpdateRender()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if unit == "player" and spellID then
			self:UpdateGCDState()
			self:UpdateRender()
		end
	end
end)

-- Options
function CursorRing:OptionsFrameShowRings()
	local db = GetDB()
	if self:IsShown() and not self.OptionFrame:IsShown() and db.combat then
		self.container:Hide()
		self.dot:Hide()
	else
		self.container:Show()
		if db.dot then
			self.dot:Show()
		end
	end
end

local function Options_MainRingSize(value)
	addon.db.CursorRingSettings.size = value
	CursorRing:UpdateRingProperties()
end

local function Options_RingColorChanged()
	CursorRing:UpdateRingColor()
	CursorRing:UpdateRender()
end

local OPTIONS_SCHEMATIC = {
	title = L["AeonTools_Colon"] .. L["CR_Title"],
	widgets = {
		{
			type = "Slider",
			label = L["CR_RingSize"],
			dbKey = "CursorRingSettings.size",
			minValue = 5,
			maxValue = 100,
			valueStep = 1,
			onValueChangedFunc = Options_MainRingSize,
			formatValueFunc = API.ReturnWholeNum,
		},
		{
			type = "Checkbox",
			label = L["CR_CombatOnly"],
			dbKey = "CursorRingSettings.combat",
			onClickFunc = function()
				CursorRing:RefreshCombatState()
				CursorRing:UpdateRender()
			end,
		},
		{
			type = "Checkbox",
			label = L["CR_CenteredDot"],
			dbKey = "CursorRingSettings.dot",
			onClickFunc = function()
				CursorRing:UpdateRender()
			end,
		},
		{
			type = "Checkbox",
			label = L["CR_GCDShow"],
			dbKey = "CursorRingSettings.gcdRing",
			onClickFunc = function()
				CursorRing:UpdateGCDState()
				CursorRing:UpdateRender()
			end,
		},
		{
			type = "ColorPicker",
			label = L["CR_RingColor"],
			tooltip = L["CR_RingColorTooltip"],
			dbKey = "CursorRingSettings.color",
			onValueChangedFunc = Options_RingColorChanged,
		},
	},
}

function CursorRing:CreateOptions(forceUpdate)
	self.OptionFrame = addon.SetupSettingsDialog(self, OPTIONS_SCHEMATIC, forceUpdate)
end

function CursorRing:ShowOptions(state)
	if state then
		self:CreateOptions(true)
		self.OptionFrame:Show()
		self.OptionFrame:SetScript("OnHide", function()
			self:UpdateRender()
			self:OptionsFrameShowRings()
		end)
		self:OptionsFrameShowRings()
		if self.OptionFrame.requireResetPosition then
			self.OptionFrame.requireResetPosition = false
			self.OptionFrame:ClearAllPoints()
			self.OptionFrame:SetPoint("LEFT", UIParent, "CENTER", 256, 0)
		end
	else
		if self.OptionFrame then
			self.OptionFrame:HideOption(self)
		end
	end
end

-- Enable/Disable
function CursorRing:Enable()
	for event in pairs(REGISTERED_EVENTS) do
		CursorRing:RegisterEvent(event)
	end

	self:CreateFrames()
	self:RefreshCombatState()
	self:UpdateRingProperties()
	self:UpdateGCDState()
	self:UpdateRender()
end

function CursorRing:Disable()
	for event in pairs(REGISTERED_EVENTS) do
		CursorRing:UnregisterEvent(event)
	end

	if self.container then
		self.container:Hide()
	end
	if self.dot then
		self.dot:Hide()
	end
	if self.gcdCooldown then
		self.gcdCooldown:Hide()
	end
end

do
	local function EnableModule(state)
		if state then
			CursorRing:Enable()
		else
			CursorRing:Disable()
		end
	end

	local function OptionToggle_OnClick(self, button)
		local OptionFrame = CursorRing.OptionFrame
		if OptionFrame and OptionFrame:IsShown() and OptionFrame:IsFromSchematic(OPTIONS_SCHEMATIC) then
			CursorRing:ShowOptions(false)
		else
			CursorRing:ShowOptions(true)
		end
	end

	local moduleData = {
		name = L["CR_Title"],
		dbKey = "CursorRing",
		description = L["CR_Desc"],
		toggleFunc = EnableModule,
		optionToggleFunc = OptionToggle_OnClick,
		categoryID = 2,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
