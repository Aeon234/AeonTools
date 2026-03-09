---@class addon
local addon = select(2, ...)
local L = addon.L

local REGISTERED_EVENTS = {
	CRAFTINGORDERS_SHOW_CUSTOMER = true,
	AUCTION_HOUSE_SHOW = true,
}

local CEF = CreateFrame("Frame")

function CEF:CraftingOrderFilter()
	local frame = ProfessionsCustomerOrdersFrame
	if not frame then
		return
	end

	local dropdown = frame.BrowseOrders and frame.BrowseOrders.SearchBar and frame.BrowseOrders.SearchBar.FilterDropdown
	if not dropdown or not dropdown.filters then
		return
	end

	dropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
	dropdown:ValidateResetState()
end

function CEF:AuctionFilter()
	local frame = AuctionHouseFrame
	if not frame or not frame.SearchBar then
		return
	end

	local searchBar = frame.SearchBar
	if not searchBar.FilterButton or not searchBar.FilterButton.filters then
		return
	end

	searchBar.FilterButton.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
	searchBar:UpdateClearFiltersButton()
end

local function CEF_EventHandler(self, event)
	if event == "AUCTION_HOUSE_SHOW" then
		CEF:AuctionFilter()
	elseif event == "CRAFTINGORDERS_SHOW_CUSTOMER" then
		CEF:CraftingOrderFilter()
	end
end

function CEF:Enable()
	for event in pairs(REGISTERED_EVENTS) do
		self:RegisterEvent(event)
	end
	self:SetScript("OnEvent", CEF_EventHandler)
end

function CEF:Disable()
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
end

do
	local function EnableModule(state)
		if state then
			CEF:Enable()
		else
			CEF:Disable()
		end
	end

	local moduleData = {
		name = L["CEF_Title"],
		dbKey = "CurrentExpansionFilter",
		description = L["CEF_Desc"],
		toggleFunc = EnableModule,
		categoryID = 4,
	}
	addon.SettingsPanel:AddModule(moduleData)
end
