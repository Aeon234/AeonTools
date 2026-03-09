---@class addon
local addon = select(2, ...)
local L = addon.L

local APT = CreateFrame("Frame")
local APT_THROTTLE = {}

function APT:ShowAltPowerText(frame)
	if not frame or not frame.statusFrame then
		return
	end

	if frame._AeonToolsHooked then
		return
	end

	frame.statusFrame:Show()

	frame:HookScript("OnShow", function(self)
		if self.statusFrame then
			self.statusFrame:Show()
		end
	end)

	frame.statusFrame:HookScript("OnUpdate", function(self)
		if not APT.enabled then
			return
		end

		local parent = self:GetParent()
		if not parent then
			return
		end

		local parentName = parent:GetName()
		if parentName and APT_THROTTLE[parentName] and APT_THROTTLE[parentName] + 0.25 > GetTime() then
			return
		end
		APT_THROTTLE[parentName] = GetTime()

		self:Show()
		self.text:Show()

		if self.text then
			self.text:ClearAllPoints()
			self.text:SetPoint("CENTER", self, "CENTER", 0, 0)

			local fontFile, height = self.text:GetFont()
			self.text:SetFont(fontFile, height, "OUTLINE")

			local strata = parent:GetFrameStrata() or "MEDIUM"
			local level = (parent:GetFrameLevel() or 0) + 5
			self:SetFrameStrata(strata)
			self:SetFrameLevel(level)

			local bg
			if not self._at_bg then
				bg = self:CreateTexture(nil, "BACKGROUND", nil, 7)
				bg:SetAtlas("Rewards-Shadow", true) -- evergreen-scenario-titlebg
				bg:SetPoint("CENTER", self.text, "CENTER", 0, 0)
				self._at_bg = bg
			else
				bg = self._at_bg
			end

			bg:SetAlphaFromBoolean(type(self.text:GetText()) ~= "nil", 0.8, 0)
			bg:SetPoint("TOPLEFT", self.text, "TOPLEFT", -20, 6)
			bg:SetPoint("BOTTOMRIGHT", self.text, "BOTTOMRIGHT", 20, -6)
		end
	end)

	if not frame.statusFrame._enhanceAltPowerBarStatusText_hideHooked then
		frame.statusFrame:HookScript("OnHide", function(self)
			self:Show()
		end)
		frame.statusFrame._enhanceAltPowerBarStatusText_hideHooked = true
	end
	frame._AeonToolsHooked = true
end

function APT:Enable()
	APT.enabled = true
	local frames = {
		PlayerPowerBarAlt,
		FocusFramePowerBarAlt,
		TargetFramePowerBarAlt,
		Boss1TargetFramePowerBarAlt,
		Boss2TargetFramePowerBarAlt,
		Boss3TargetFramePowerBarAlt,
		Boss4TargetFramePowerBarAlt,
		Boss5TargetFramePowerBarAlt,
	}

	for _, frame in ipairs(frames) do
		APT:ShowAltPowerText(frame)
	end
end

function APT:Disable()
	APT.enabled = false
end

do
	local function EnableModule(state)
		if state then
			APT:Enable()
		else
			APT:Disable()
		end
	end

	local moduleData = {
		name = L["AltPower_Title"],
		dbKey = "AltPowerText",
		description = L["AltPower_Desc"],
		toggleFunc = EnableModule,
		categoryID = 2,
	}

	addon.SettingsPanel:AddModule(moduleData)
end
