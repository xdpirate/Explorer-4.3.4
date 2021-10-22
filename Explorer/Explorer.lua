local _, addon = ...
local Overlays = addon.Overlays

local PinFrame = CreateFrame('frame', nil, WorldMapButton)
PinFrame:SetAllPoints()

local Pins = {} -- this is just to recycle textures
function HidePins()
	for i, pin in pairs(Pins) do
		pin:Hide()
	end
end

local EXPLORE_S = 'Explore: %s'
local CLICK_WAYPOINT = 'Ctrl-Click to set a TomTom waypoint.'
if GetLocale() == 'deDE' then
	EXPLORE_S = 'Erkundet: %s'
	CLICK_WAYPOINT = 'Strg-Klick, um einen Zielpunkt mit TomTom zu setzen.'
elseif GetLocale():match('es') then
	EXPLORE_S = 'Explora: %s'
	CLICK_WAYPOINT = 'Ctrl-Clic para establecer un waypoint con TomTom.'
end

local function Pin_OnMouseUp(self)
	if TomTom and IsControlKeyDown() then
		local mapID, mapFloor = GetCurrentMapAreaID()
		local width, height = WorldMapDetailFrame:GetWidth(), WorldMapDetailFrame:GetHeight()
		local _, _, _, x, y = self:GetPoint()
		x = x / width
		y = -y / height
		TomTom:AddMFWaypoint(mapID, mapFloor, x, y, {
			title = format(EXPLORE_S, self.text),
			persistent = false,
		})
	end
end

local function Pin_OnEnter(self)
	if self.text then
		WorldMapPOIFrame.allowBlobTooltip = false
		WorldMapTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
		WorldMapTooltip:ClearLines()
		WorldMapTooltip:AddLine(self.text)
		if TomTom then
			WorldMapTooltip:AddLine(CLICK_WAYPOINT, 1, 1, 1, true)
		end
		WorldMapTooltip:Show()
	end
end

local function Pin_OnLeave()
	WorldMapPOIFrame.allowBlobTooltip = true
	WorldMapTooltip:Hide()
end

local function GetPin()
	for i, pin in pairs(Pins) do
		if not pin:IsShown() then
			return pin
		end
	end
	
	local pin = CreateFrame('frame', nil, PinFrame)
	pin:SetSize(18, 18)
	
	pin.texture = pin:CreateTexture()
	pin.texture:SetAllPoints()
	pin.texture:SetTexture('interface\\addons\\Explorer\\images\\coordicon')
	
	pin:EnableMouse(true)
	pin:SetScript('OnMouseUp', Pin_OnMouseUp)
	pin:SetScript('OnEnter', Pin_OnEnter)
	pin:SetScript('OnLeave', Pin_OnLeave)
	
	tinsert(Pins, pin)
	return pin
end

local function GetPinInfo(achievementID, criteriaID) 
	for i = 1, GetAchievementNumCriteria(achievementID) do
		local name, _, completed, _, _, _, _, zoneID = GetAchievementCriteriaInfo(achievementID, i)
		if zoneID == criteriaID then
			return name, completed
		end
	end
end

hooksecurefunc('WorldMapFrame_Update', function()
	HidePins()

	local areaID = GetCurrentMapAreaID()
	local mapName, _, _, isMicroDungeon, microDungeonPath = GetMapInfo()
	
	local info = Overlays[areaID]
	if not isMicroDungeon and info then
		local achievementID = info[1]
		for i = 2, #info, 3 do
			local criteriaID, x, y = info[i], info[i + 1], info[i + 2]
			local name, completed = GetPinInfo(achievementID, criteriaID)
			if name and not completed then
				local pin = GetPin()
				pin:SetPoint('CENTER', WorldMapDetailFrame, 'TOPLEFT', x, -y)
				pin.text = name or (achievementID .. ', ' .. criteriaID)
				pin:Show()
			end
		end
	end
end)