local _, addon = ...
local L = addon.L
local API = addon.API
local UIParent = UIParent
local GCD_SPELL = 61304
local InCombatLockdown = InCombatLockdown
local TEXTURE_FILE = "Interface/AddOns/AeonTools/Assets/CursorRing"

local CursorRing = CreateFrame("Frame")

local REGISTERED_EVENTS = {
	PLAYER_LOGIN = true,
	PLAYER_ENTERING_WORLD = true,
	PLAYER_REGEN_ENABLED = true,
	PLAYER_REGEN_DISABLED = true,
	SPELL_UPDATE_COOLDOWN = true,
	ACTIONBAR_UPDATE_COOLDOWN = true,
}

-- Helpers
function CursorRing:GetCursorPos()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	return x / scale, y / scale
end

function CursorRing:UpdateGCD()
	local start, duration, modRate = CursorRing:GetGCDCooldown(GCD_SPELL)

	if CursorRing:IsCooldownActive(start, duration) then
		self.gcd:Show()
		if modRate then
			self.gcd.ring:SetCooldown(start, duration, modRate)
		else
			self.gcd.ring:SetCooldown(start, duration)
		end
	else
		self.gcd:Hide()
	end
end

function CursorRing:IsCooldownActive(start, duration)
	if not start or not duration then
		return false
	end
	local ok, result = pcall(function()
		if duration == 0 or start == 0 then
			return false
		else
			return true
		end
	end)
	if not ok then
		return true
	end
	return result and true or false
end

function CursorRing:GetGCDCooldown(spellID)
	local startTime, duration, modRate, enabled

	local cd = C_Spell.GetSpellCooldown(spellID)
	if cd then
		startTime, duration, modRate, enabled = cd.startTime, cd.duration, cd.modRate, cd.isEnabled
		return startTime, duration, modRate
	end
end

function CursorRing:RingVisibility()
	CursorRing:SetScript("OnEvent", function(self, event, unit, _, spellID)
		local db = addon.db.CursorRingSettings
		if not db then
			return
		end

		local combatOnly = db.combat
		local gcdEnabled = db.gcdRing
		local dot = db.dot
		local dotCombat = dot and combatOnly

		-- Main Ring Visibility
		if event == "PLAYER_REGEN_DISABLED" then
			self.ring:Show()
		elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
			-- Leaving combat or loading
			if combatOnly then
				if InCombatLockdown() then
					self.ring:Show()
					if dotCombat then
						self.dot:Show()
					end
				else
					self.ring:Hide()
					self.dot:Hide()
				end
			else
				self.ring:Show()
				if dot then
					self.dot:Show()
				else
					self.dot:Hide()
				end
			end
		end

		-- GCD Visibility
		if not self.ring:IsShown() then
			self.gcd:Hide()
			return
		end
		if gcdEnabled then
			if
				event == "SPELL_UPDATE_COOLDOWN"
				or event == "ACTIONBAR_UPDATE_COOLDOWN"
				or event == "PLAYER_REGEN_DISABLED"
				or event == "PLAYER_REGEN_ENABLED"
				or event == "PLAYER_ENTERING_WORLD"
				or event == "PLAYER_LOGIN"
			then
				CursorRing:UpdateGCD()
			end

			if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" and spellID then
				CursorRing:UpdateGCD()
			end
		else
			self.gcd:Hide()
		end
	end)

	CursorRing:GetScript("OnEvent")(CursorRing, "PLAYER_ENTERING_WORLD")
end

function CursorRing:UpdateRingProperties()
	local db = addon.db and addon.db.CursorRingSettings
	if not db then
		return
	end

	self.ring:SetSize(db.size, db.size)

	local gcdSize = db.size * 0.7142857143
	self.gcd:SetSize(gcdSize, gcdSize)

	self:UpdateRingColor()
end

function CursorRing:UpdateRingColor()
	local db = addon.db and addon.db.CursorRingSettings
	if not db or not db.color then
		return
	end

	local r, g, b = db.color.r or 1, db.color.g or 1, db.color.b or 1

	-- Update main ring texture color
	if self.ring and self.ring.texture then
		self.ring.texture:SetVertexColor(r, g, b, 1)
	end

	-- Update GCD ring swipe color
	if self.gcd and self.gcd.ring then
		self.gcd.ring:SetSwipeColor(r, g, b, 1)
	end

	if self.dot and self.dot.texture then
		self.dot.texture:SetVertexColor(r, g, b, 1)
	end
end

-- Create Rings
function CursorRing:CreateRings()
	local db = addon.db and addon.db.CursorRingSettings
	if self._init or not db then
		return
	end

	-- Initialize default color if not set
	if not db.color then
		db.color = { r = 1, g = 1, b = 1 }
	end

	-- Ring
	self.ring = CreateFrame("Frame", nil, UIParent)
	self.ring:SetSize(db.size, db.size)
	self.ring:SetFrameStrata("TOOLTIP")
	self.ring:Hide()

	local tex = self.ring:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints(self.ring)
	tex:SetTexture(TEXTURE_FILE)
	tex:SetBlendMode("BLEND")
	-- tex:SetVertexColor(1, 1, 1, 1)
	self.ring.texture = tex

	-- Ring Dot
	self.dot = CreateFrame("Frame", nil, UIParent)
	self.dot:SetSize(6, 6)
	self.dot:SetFrameStrata("TOOLTIP")
	self.dot:Hide()

	local dotText = self.dot:CreateTexture(nil, "OVERLAY")
	dotText:SetAllPoints(self.dot)
	dotText:SetTexture("Interface/AddOns/AeonTools/Assets/Circle_White")
	dotText:SetBlendMode("BLEND")
	self.dot.texture = dotText

	-- GCD Radial
	local gcdSize = db.size * 0.7142857143

	self.gcd = CreateFrame("Frame", nil, UIParent)
	self.gcd:SetFrameStrata("TOOLTIP")
	self.gcd:SetSize(gcdSize, gcdSize)
	self.gcd:SetAlpha(1)

	local gcdRing = CreateFrame("Cooldown", nil, self.gcd, "CooldownFrameTemplate")
	gcdRing:SetAllPoints()
	gcdRing:EnableMouse(false)
	gcdRing:SetDrawSwipe(true)
	gcdRing:SetDrawEdge(false)
	gcdRing:SetHideCountdownNumbers(true)
	if gcdRing.SetUseCircularEdge then
		gcdRing:SetUseCircularEdge(true)
	end
	---@diagnostic disable-next-line: missing-parameter
	gcdRing:SetSwipeTexture(TEXTURE_FILE)
	-- ring:SetSwipeColor(1, 1, 1, 1)
	gcdRing:SetReverse(true)
	self.gcd.ring = gcdRing

	self:UpdateRingColor()

	self._init = true
	self:RingVisibility()
end

-- Options
function CursorRing:OptionsFrameShowRings()
	local db = addon.db and addon.db.CursorRingSettings
	if self:IsShown() and not self.OptionFrame:IsShown() and db.combat then
		self.ring:Hide()
		if not db.dot then
			self.ring:Hide()
		end
	else
		self.ring:Show()
		if db.dot then
			self.ring:Show()
		end
	end
end

local function Options_MainRingSize(value)
	addon.db.CursorRingSettings.size = value
	CursorRing:UpdateRingProperties()
end

local function Options_RingColorChanged()
	CursorRing:UpdateRingColor()
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
			onClickFunc = nil,
		},
		{
			type = "Checkbox",
			label = L["CR_CenteredDot"],
			dbKey = "CursorRingSettings.dot",
			onClickFunc = function(state)
				if addon.db.CursorRingSettings.dot then
					CursorRing.dot:Show()
				else
					CursorRing.dot:Hide()
				end
			end,
		},
		{
			type = "Checkbox",
			label = L["CR_GCDShow"],
			dbKey = "CursorRingSettings.gcdRing",
			onClickFunc = nil,
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
			CursorRing:RingVisibility()
			CursorRing:OptionsFrameShowRings()
		end)
		CursorRing:OptionsFrameShowRings()
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

	CursorRing:CreateRings()

	CursorRing:SetScript("OnUpdate", function(self, elapsed)
		local x, y = CursorRing:GetCursorPos()

		self.ring:ClearAllPoints()
		self.ring:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
		self.dot:ClearAllPoints()
		self.dot:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
		self.gcd:ClearAllPoints()
		self.gcd:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
	end)
end

function CursorRing:Disable()
	if not CursorRing._init then
		return
	end
	CursorRing:SetScript("OnUpdate", function(self, elapsed) end)
	CursorRing:SetScript("OnEvent", function(self, event) end)
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
		categoryID = 1,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
