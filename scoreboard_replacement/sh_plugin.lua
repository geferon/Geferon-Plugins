PLUGIN.name = "Scoreboard Replacement"
PLUGIN.author = "Geferon"
PLUGIN.desc = "Replaces the Scoreboard by the F1 Menu and adds some little improvements to it, like more options and adding it to the Main NutScript menu"

nut.config.add("sbShowF1Menu", true, "Replace the Tab button by the F1 menu", nil, {
	category = "visual"
})
nut.config.add("sbOnMainMenu", true, "Show the Scoreboard on the F1 menu?", nil, {
	category = "visual"
})

if CLIENT then
	local menuPanel = vgui.GetControlTable("nutMenu")
	menuPanel.OldOnKeyCodePressed = menuPanel.OnKeyCodePressed
	menuPanel.OnKeyCodePressed = function(pnl, key)
		if key == KEY_TAB or key == KEY_F1 then
			pnl:remove()
		end

		pnl:OldOnKeyCodePressed()
	end

	-- if nut.config.get("sbShowF1Menu") then
		-- menuPanel.OnKeyCodePressed = menuPanel.NewOnKeyCodePressed
	-- end
end

function PLUGIN:ScoreboardShow()
	if !nut.config.get("sbShowF1Menu") then return end
	if (IsValid(nut.gui.menu)) then
		nut.gui.menu:remove()
	else
		vgui.Create("nutMenu")

		self.ScoreboardShown = RealTime()
	end
	return true
end

function PLUGIN:ScoreboardHide()
	if !nut.config.get("sbShowF1Menu") then return end
	if (IsValid(nut.gui.menu) and self.ScoreboardShown + 0.5 <= RealTime()) then
		nut.gui.menu:remove()
	end
	return true
end

function PLUGIN:CreateMenuButtons(tabs)
	if !nut.config.get("sbOnMainMenu") then return end
	tabs["scoreboard"] = function(panel)
		local pnl = panel:Add("nutScoreboard")
		pnl:Dock(FILL)
	end
end



function PLUGIN:ShowPlayerOptions(ply, options)
	if LocalPlayer():IsAdmin() then
		local totalWhitelistAdd = {}
		local totalWhitelistRemove = {}

		for k, v in pairs(nut.faction.indices) do
			if (ply:hasWhitelist(v.index)) then
				totalWhitelistRemove[v.name] = {"", function()
					if IsValid(ply) then
						nut.command.send("plyunwhitelist", ply:Name(), v.uniqueID)
					end
				end}
			else
				totalWhitelistAdd[v.name] = {"", function()
					if IsValid(ply) then
						nut.command.send("plywhitelist", ply:Name(), v.uniqueID)
					end
				end}
			end
		end

		options["whilelist0start"] = "spacer"
		options["whilelistAdd"] = {"icon16/script_add.png", totalWhitelistAdd}
		options["whilelistRemove"] = {"icon16/script_delete.png", totalWhitelistRemove}
		options["zCharRen0start"] = "spacer"
		options["zCharRename"] = {"icon16/text_bold.png", function()
			if IsValid(ply) then
				local OldName = ply:Name()
				Derma_StringRequest("Do you want to rename this player?", "Rename Player", OldName, function(NewName)
					if IsValid(ply) and OldName == ply:Name() then
						nut.command.send("charsetname", OldName, NewName)
					end
				end, nil, "Change")
			end
		end}
	end
end
