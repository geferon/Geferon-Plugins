PLUGIN.name = "Observer Plus"
PLUGIN.author = "Geferon"
PLUGIN.desc = "Adds extra functionality to the Observer"

if (CLIENT) then
	NUT_CVAR_ADMINESP_EXTRINFO = CreateClientConVar("nut_obespadv", 1, true, true)

	local dimDistance = 1024
	local function GetClrRGB(clr)
		return clr.r, clr.g, clr.b, clr.a or 255
	end
	local function LerpColor(delta, colorOrig, colorTo)
		local clrFrR, clrFrG, clrFrB, clrFrA = GetClrRGB(colorOrig)
		local clrToR, clrToG, clrToB, clrToA = GetClrRGB(colorTo)
		
		local clrR, clrG, clrB
		clrR = Lerp(delta, clrFrR, clrToR)
		clrG = Lerp(delta, clrFrG, clrToG)
		clrB = Lerp(delta, clrFrB, clrToB)
		clrA = Lerp(delta, clrFrA, clrToA)

		return Color(clrR, clrG, clrB, clrA)
	end

	function PLUGIN:HUDPaint()
		local client = LocalPlayer()

		if !(client:IsAdmin() and client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle() and NUT_CVAR_ADMINESP_EXTRINFO:GetBool()) then return end

		local sx, sy = surface.ScreenWidth(), surface.ScreenHeight()
		local marginx, marginy = sy * 0.1, sy * 0.1

		for k, v in pairs(player.GetAll()) do
			if (v == client) then continue end

			local scrPos = v:GetPos():ToScreen()
			local x, y = math.Clamp(scrPos.x, marginx, sx - marginx), math.Clamp(scrPos.y, marginy, sy - marginy)
			local teamColor = team.GetColor(v:Team())
			local distance = client:GetPos():Distance(v:GetPos())
			local factor = 1 - math.Clamp(distance / dimDistance, 0, 1)
			local sizeW = math.max(70, 200 * factor)
			local sizeH = math.max(10, 30 * factor)
			local squareSize = math.max(10, 32 * factor)
			local alpha = math.Clamp(255 * factor, 80, 255)

			local yPos = y + squareSize / 2 + 10
			local BarOffset = 8 * factor

			-- HP Bar --
			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(x - sizeW / 2, yPos, sizeW, sizeH)

			local HPDelta = math.Clamp(v:Health() / v:GetMaxHealth(), 0, 1)
			-- local HPColor = LerpColor(HPDelta, Color(255, 0, 0), Color(0, 255, 0))
			local HPColor = Color(0, 255, 0)
			surface.SetDrawColor(HPColor.r, HPColor.g, HPColor.b, alpha)
			surface.DrawRect(x - (sizeW - BarOffset) / 2, yPos + (BarOffset / 2), (sizeW - BarOffset) * HPDelta, sizeH - BarOffset)

			-- local textCol = LerpColor(HPDelta, Color(255, 255, 255, alpha), Color(0, 0, 0, alpha))
			local textCol = Color(255, 255, 255, alpha)
			draw.SimpleTextOutlined(v:Health() .. "/" .. v:GetMaxHealth(), "nutSmallFont", x, yPos + sizeH / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))

			yPos = yPos + sizeH + 5

			if (v:Armor() > 0) then
				-- Armor Bar --

				surface.SetDrawColor(0, 0, 0, alpha)
				surface.DrawRect(x - sizeW / 2, yPos, sizeW, sizeH)
				local ArmorDelta = math.Clamp(v:Armor() / 100, 0, 1)
				local ArmorColor = Color(0, 0, 255)
				local ArmorOffset = 8 * factor
				surface.SetDrawColor(ArmorColor.r, ArmorColor.g, ArmorColor.b, alpha)
				surface.DrawRect(x - (sizeW - BarOffset) / 2, yPos + (BarOffset / 2), (sizeW - BarOffset) * ArmorDelta, sizeH - BarOffset)

				-- local textCol = LerpColor(HPDelta, Color(255, 255, 255, alpha), Color(0, 0, 0, alpha))
				local textCol = Color(255, 255, 255, alpha)
				draw.SimpleTextOutlined(v:Armor() .. "/" .. 100, "nutSmallFont", x, yPos + sizeH / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))

				yPos = yPos + sizeH + 5
			end

			local activeWep = v:GetActiveWeapon()
			if (IsValid(activeWep)) then
				draw.SimpleTextOutlined(activeWep:GetPrintName(), "nutSmallFont", x, yPos, v:isWepRaised() and Color(255, 150, 150, alpha) or Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, alpha))

				local txtW, txtH = surface.GetTextSize(activeWep:GetPrintName())
				yPos = yPos + txtH + 5
			end
		end
	end

	function PLUGIN:SetupQuickMenu(menu)
		if !(LocalPlayer():IsAdmin()) then return end

		local buttonAdvESP = menu:addCheck(L"toggleAdvESP", function(pnl, state)
			if (state) then
				RunConsoleCommand("nut_obespadv", "1")
			else
				RunConsoleCommand("nut_obespadv", "0")
			end
		end, NUT_CVAR_ADMINESP_EXTRINFO:GetBool())

		-- menu:addSpacer()
		-- Dont add the spacer. The official ESP option should be right below us.
	end
end