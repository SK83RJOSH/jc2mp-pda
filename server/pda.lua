class "PDA"

function PDA:__init()
	Network:Subscribe("Teleport", self, self.Teleport)
end

function PDA:Teleport(args, sender)
	if sender:GetWorld() == DefaultWorld then
		sender:SetPosition(args.position)
	else
		sender:SendChatMessage("You must be in the Default World to teleport!", Color.Yellow)
	end
end

PDA = PDA()
