PLUGIN.name = "Improved Areas"
PLUGIN.author = "Geferon"
PLUGIN.desc = "New Improved Areas plugin"

nut.util.include("sh_zones.lua")

local PLUGIN = PLUGIN
local ZONE_CLASS = "Schema Zones"

local Zone_Types = {
	"Scrollable"
}

local color = nut.config.get("color")

zones.RegisterClass(ZONE_CLASS, color)

function PLUGIN:GetPlayerCurrentArea(ply)
	local zone, id = ply:GetCurrentZone(ZONE_CLASS)

	if (zone and zone.data.CustomData) then
		return zone.data.CustomData.name or (L and L("unknown") or "Unknown")
	end

	return L and L("unknown") or "Unknown"
end

if SERVER then
	function PLUGIN:Think()
		for k, v in pairs(player.GetHumans()) do
			local zone, id = v:GetCurrentZone(ZONE_CLASS)

			if (not v.LastZone or v.LastZone[1] != zone) then
				if (v.LastZone and v.LastZone[1] and v.LastZone[2]) then
					self:PlayerExitArea(v, v.LastZone[1], v.LastZone[2])
				end

				v.LastZone = {zone, id}

				if (zone and id) then
					self:PlayerEnteredArea(v, zone, id)
				end
			end
		end
	end

	function PLUGIN:PlayerEnteredArea(ply, area, id)
		netstream.Start(ply, "AdvAreasEntered", id)
	end

	function PLUGIN:PlayerExitArea(ply, area, id)
	end

	netstream.Hook("ModifyAreaData", function(ply, id, data)
		if !ply:IsAdmin() then return end

		if not zones.List[id] then return end


		zones.List[id].data.CustomData = data
		zones.Sync()
	end)
else
	netstream.Hook("AdvAreasEntered", function(id)
		local area = zones.List[id]
		PLUGIN:PlayerEnteredArea(area, id)
	end)

	PLUGIN.ActiveAreaDisplays = {}
	function PLUGIN:PlayerEnteredArea(area, id)
		if PLUGIN.ActiveAreaDisplays[id] then return end

		local AreaData = area.data.CustomData or {}
		PLUGIN.ActiveAreaDisplays[id] = {
			area = area,
			areaName = AreaData.name or "",
			entered = CurTime(),
			type = AreaData.type or "Scrolling"
		}
	end

	function PLUGIN:CalculateAreaScrolling(display)
		if display.finished then return end

		if (!display.ScrollingInfo) then
			display.ScrollingInfo = {
				nextCharacter = CurTime() + 0.1,
				index = 0,
				invert = false,
				text = ""
			}
		end

		if (display.ScrollingInfo.nextCharacter <= CurTime()) then
			if (!display.ScrollingInfo.invert) then
				if (string.len(display.areaName) > display.ScrollingInfo.index) then
					display.ScrollingInfo.index = display.ScrollingInfo.index + 1
					display.ScrollingInfo.nextCharacter = CurTime() + 0.1
					surface.PlaySound("common/talk.wav")
				else
					display.ScrollingInfo.nextCharacter = CurTime() + 5
					display.ScrollingInfo.index = 0
					display.ScrollingInfo.invert = true
				end
				display.ScrollingInfo.text = string.sub(display.areaName, 0, display.ScrollingInfo.invert and string.len(display.areaName) or display.ScrollingInfo.index)
			else
				if (string.len(display.ScrollingInfo.text) > 0) then
					display.ScrollingInfo.index = display.ScrollingInfo.index + 1
					display.ScrollingInfo.nextCharacter = CurTime() + 0.1
				else
					display.finished = true
				end
				display.ScrollingInfo.text = string.sub(display.areaName, display.ScrollingInfo.index + 1)

				surface.PlaySound("common/talk.wav")
			end
		end
	end

	-- local lastText = "asdfasdfasdfasdfasdfasdf"
	function PLUGIN:HUDPaint()
		local textColor = color_white
		local font = "nutMediumFont"

		local x, y = ScrW() * 0.1, ScrH() * 0.6

		for k, v in SortedPairsByMemberValue(self.ActiveAreaDisplays, "entered") do
			if v.finished then continue end
			if not v.ScrollingInfo then continue end

			surface.SetFont(font)

			local curX = x

			local mW, mH = surface.GetTextSize(string.upper(v.areaName))
			local tW, tH = surface.GetTextSize(string.upper(v.ScrollingInfo.text))

			local lastChar = string.sub(v.areaName, v.ScrollingInfo.index + 1, v.ScrollingInfo.index + 1)
			if (v.ScrollingInfo.invert) then
				lastChar = string.sub(v.areaName, v.ScrollingInfo.index, v.ScrollingInfo.index)

				local charW, _ = surface.GetTextSize(string.upper(lastChar))

				// TODO: Replace color with alpha
				local alpha = ((v.ScrollingInfo.nextCharacter - CurTime()) / 0.1) * 255
				nut.util.drawText(string.upper(lastChar), x + (mW - tW) - charW, y, color_white, nil, nil, font, alpha)

				curX = x + (mW - tW)
			end

			nut.util.drawText(string.upper(v.ScrollingInfo.text), curX, y, color_white, nil, nil, font, 255)

			if (!v.ScrollingInfo.invert and lastChar != "") then
				local alpha = (1 - ((v.ScrollingInfo.nextCharacter - CurTime()) / 0.1)) * 255
				nut.util.drawText(string.upper(lastChar), curX + tW, y, color_white, nil, nil, font, alpha)

				if (lastText != v.ScrollingInfo.text .. lastChar) then
					lastText = v.ScrollingInfo.text .. lastChar
				end
			end

			y = y + mH + 4
		end
	end

	function PLUGIN:Think()
		for k, v in pairs(self.ActiveAreaDisplays) do
			if v.finished then
				self.ActiveAreaDisplays[k] = nil
				return
			end

			self:CalculateAreaScrolling(v)
		end
	end

	function PLUGIN:ShowZoneOptions(zone, class, panel, id, frame)
		if class != ZONE_CLASS then return end

		local w, h = ScrW() * 0.5, ScrH() * 0.6

		local ZoneData = zone.data.CustomData or {}

		local AreaNameLabel = panel:Add("DLabel")
		AreaNameLabel:SetFont("nutMediumFont")
		AreaNameLabel:SetText("Area Name")
		AreaNameLabel:SizeToContentsY()
		AreaNameLabel:DockMargin(5, 5, 5, 0)
		AreaNameLabel:Dock(TOP)

		local AreaName = panel:Add("DTextEntry")
		AreaName:DockMargin(5, 5, 5, 0)
		AreaName:Dock(TOP)
		AreaName:SetText(ZoneData.name or "")
		-- AreaName.OnEnter = function(this)
		-- 	print(this:GetValue())
		-- end

		local AreaNameLabel = panel:Add("DLabel")
		AreaNameLabel:SetFont("nutMediumFont")
		AreaNameLabel:SetText("Area Type")
		AreaNameLabel:SizeToContentsY()
		AreaNameLabel:DockMargin(5, 10, 5, 0)
		AreaNameLabel:Dock(TOP)

		local AreaType = panel:Add("DComboBox")
		AreaType:DockMargin(5, 5, 5, 0)
		AreaType:Dock(TOP)
		AreaType:SetValue(ZoneData.type or Zone_Types[1])
		for k, v in pairs(Zone_Types) do
			AreaType:AddChoice(v)
		end

		-- local lastPanel = AreaName
		-- local x, y = lastPanel:GetPos()
		-- local h = y + lastPanel:GetTall() + 5

		local DoneButton = panel:Add("DButton")
		DoneButton:DockMargin(20, 20, 20, 5)
		DoneButton:Dock(BOTTOM)
		DoneButton:SetText("Done")
		DoneButton.DoClick = function(this)
			local AreaData = {
				name = AreaName:GetValue(),
				type = AreaType:GetSelected()
			}
			netstream.Start("ModifyAreaData", id, AreaData)
			frame:Close()
		end

		return w, h
	end
end
