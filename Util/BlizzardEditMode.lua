---@class addon
local addon = select(2, ...)
local L = addon.L

local UIParent = UIParent
local MainFrame = CreateFrame("Frame", nil, UIParent)
MainFrame:Show()

local DBKEY_MASTER = "EditModeShow"

local ModuleInfo = {}

local function AddEditModeVisibleModule(moduleData)
	table.insert(ModuleInfo, moduleData)
end
addon.AddEditModeVisibleModule = AddEditModeVisibleModule

local function UpdateModuleVisibilities()
	local showUI = addon.GetDBValue(DBKEY_MASTER)
	local anyOn
	for _, moduleData in ipairs(ModuleInfo) do
		if addon.GetDBValue(moduleData.dbKey) then
			anyOn = true
			if showUI then
				moduleData.enterEditMode()
			else
				moduleData.exitEditMode()
			end
		else
			moduleData.exitEditMode()
		end
	end
	return anyOn
end

function MainFrame:Init()
	self.Init = nil

	local owner = EditModeManagerFrame
	if not owner then
		return
	end

	self.owner = owner

	self.Border = CreateFrame("Frame", nil, self, "DialogBorderTranslucentTemplate")
	self:SetFrameStrata("DIALOG")

	local Checkbox = addon.CreateBlizzardCheckButton(self)
	self.Checkbox = Checkbox
	Checkbox:SetPoint("CENTER", self, "CENTER", 0, 0)
	Checkbox:SetLabel("AeonTools")
	Checkbox:SetDBKey(DBKEY_MASTER)

	local function Checkbox_GetTooltip()
		local header = L["Toggle_EditMode"]
		local desc = L["Toggle_EditMode_Tooltip"]
		local text, name

		for _, moduleData in ipairs(ModuleInfo) do
			if addon.GetDBValue(moduleData.dbKey) then
				name = "- " .. moduleData.name
				if text then
					text = text .. "\n" .. name
				else
					text = name
				end
			end
		end

		if text then
			return header, string.format(desc, text)
		end
	end

	Checkbox:SetTooltip(Checkbox_GetTooltip)
	Checkbox:SetOnCheckedFunc(UpdateModuleVisibilities)

	local width, height = Checkbox:GetSize()
	self:SetSize(width + 32, height + 32)
	self.t = 1
	self:SetScript("OnUpdate", self.OnUpdate)
	self:SetFrameLevel(owner:GetFrameLevel() + 2)
end

function MainFrame:OnUpdate(elapsed)
	self.t = self.t + elapsed
	if self.t > 0.25 then
		self.t = 0
		self.x = self.owner:GetRight()
		self.y = self.owner:GetTop()
		self.x = self.x - 16
		self.y = self.y - 14

		if self.secondaryOwner and self.secondaryOwner:IsShown() then
			local f = EditModeExpandedWarningFrame
			if f and f:IsShown() then
				self:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -54)
			else
				self:SetPoint("TOPLEFT", self.secondaryOwner, "BOTTOMLEFT", 0, -4)
			end
		elseif self.plumberEnabled then
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.x, self.y - 150)
			self:ShowModules(true)
		elseif self.owner:IsShown() then
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.x, self.y)
			self:ShowModules(true)
		else
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, -8)
			self:ShowModules(false)
		end
	end
end

function MainFrame:EnterEditMode()
	if self.Init then
		self:Init()
	end

	if UpdateModuleVisibilities() then
		self.moduleShown = true
		self.t = 1
		self:SetScript("OnUpdate", self.OnUpdate)
		self.Checkbox:SetChecked(addon.GetDBValue(DBKEY_MASTER))
		self:Show()
	else
		self:Hide()
	end

	if EditModeManagerExpandedFrame then
		--Addon Compatibility: Edit Mode Expanded (https://github.com/teelolws/EditModeExpanded)
		self.secondaryOwner = EditModeManagerExpandedFrame
	end
	if PlumberDB then
		self.plumberEnabled = true
	end

	addon.CallbackRegistry:Trigger("EditMode.Enter")
end

function MainFrame:ExitEditMode()
	self:Hide()
	self.t = 0
	self:SetScript("OnUpdate", nil)
	self:ShowModules(false)
	addon.CallbackRegistry:Trigger("EditMode.Exit")
end

function MainFrame:ShowModules(state)
	if state == self.moduleShown then
		return
	end
	self.moduleShown = state

	if state then
		UpdateModuleVisibilities()
	else
		for _, moduleData in ipairs(ModuleInfo) do
			moduleData.exitEditMode()
		end
	end
end

EventRegistry:RegisterCallback("EditMode.Enter", MainFrame.EnterEditMode, MainFrame)
EventRegistry:RegisterCallback("EditMode.Exit", MainFrame.ExitEditMode, MainFrame)
