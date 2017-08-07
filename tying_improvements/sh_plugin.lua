PLUGIN.name = "Tying Improvements"
PLUGIN.author = "Geferon"
PLUGIN.desc = "Enables Tying players and searching them if they are tied with the F2 menu."

function PLUGIN:ShowTeam(client)
	if not nut.plugin.list.tying then return end -- Tying plugin doesn't exist

	local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector()*96
		data.filter = client
	local trace = util.TraceLine(data)
	local target = trace.Entity

	if !(IsValid(target) and target:IsPlayer()) then return end

	if (target:getNetVar("tying")) then return end

	if (!target:getNetVar("restricted")) then
		local item
		for k, v in pairs(client:getChar():getInv():getItems()) do
			if v.uniqueID == "zip_tie" then
				item = v
				break
			end
		end

		if (!item) then return end

		item.beingUsed = true

		client:EmitSound("physics/plastic/plastic_barrel_strain"..math.random(1, 3)..".wav")
		client:setAction("@tying", 5)
		client:doStaredAction(target, function()
			item:remove()

			target:setRestricted(true)
			target:setNetVar("tying")

			client:EmitSound("npc/barnacle/neck_snap1.wav", 100, 140)
		end, 5, function()
			client:setAction()

			target:setAction()
			target:setNetVar("tying")

			item.beingUsed = false
		end)

		target:setNetVar("tying", true)
		target:setAction("@beingTied", 5)

		return true
	else
		nut.plugin.list.tying:searchPlayer(client, target)
	end
end
