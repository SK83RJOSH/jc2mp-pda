class "PDA"

PDA.ToggleDelay = 0.25

function PDA:__init()
	self.active            = false
	self.dragging          = false
	self.lastMousePosition = Mouse:GetPosition()
	self.timer             = Timer()

	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
end

function PDA:IsUsingGamepad()
	return Game:GetSetting(GameSetting.GamepadInUse) ~= 0
end

function PDA:ModuleLoad()
	Events:Subscribe("MouseDown", self, self.MouseDown)
	Events:Subscribe("MouseMove", self, self.MouseMove)
	Events:Subscribe("MouseUp", self, self.MouseUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("PostRender", self, self.PostRender)
end

function PDA:MouseDown(args)
	if args.button == 1 then
		if not Map.ActiveLocation then
			self.dragging = true
			self.lastMousePosition = Mouse:GetPosition()
		elseif self.active then
			self.active = false

			Network:Send("Teleport", {
				position = Map.ActiveLocation.position
			})
		end
	end
end

function PDA:MouseMove(args)
	if self.active and self.dragging then
		Map.Offset = Map.Offset + ((args.position - self.lastMousePosition) / Map.Zoom)
	end

	self.lastMousePosition = args.position
end

function PDA:MouseUp(args)
	if args.button == 1 then
		self.dragging = false
	end
end

function PDA:LocalPlayerInput(args)
	if args.input == Action.GuiPDA then
		if self.timer:GetSeconds() > PDA.ToggleDelay then
			self.active = not self.active
			self.timer:Restart()

			if self.active then
				Map.Zoom = 1.5

				Map.Image:SetSize(Vector2.One * Render.Height * Map.Zoom)

				Map.Offset = Vector2(LocalPlayer:GetPosition().x, LocalPlayer:GetPosition().z) / 16384
				Map.Offset = -Vector2(Map.Offset.x * (Map.Image:GetSize().x / 2), Map.Offset.y * (Map.Image:GetSize().y / 2)) / Map.Zoom
			end
		end

		return false
	elseif self.active then
		if (args.input == Action.GuiPDAZoomIn or args.input == Action.GuiPDAZoomOut) and args.state > 0.15 then
			local oldZoom = Map.Zoom

			Map.Zoom = math.max(math.min(Map.Zoom + (0.1 * args.state * (PDA:IsUsingGamepad() and -1 or 1) * (args.input == Action.GuiPDAZoomIn and 1 or -1)), 3), 1)

			local zoomFactor  = Map.Zoom - oldZoom
			local zoomProduct = oldZoom * oldZoom + oldZoom * zoomFactor
			local zoomTarget  = ((PDA:IsUsingGamepad() and (Render.Size / 2) or Mouse:GetPosition()) - (Render.Size / 2))

			Map.Offset = Map.Offset - ((zoomTarget * zoomFactor) / zoomProduct)
		elseif args.input == Action.GuiAnalogDown and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Down * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.GuiAnalogUp and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Up * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.GuiAnalogLeft and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Left * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.GuiAnalogRight and args.state > 0.15 then
			Map.Offset = Map.Offset - (Vector2.Right * 5 * math.pow(args.state, 2) / Map.Zoom)
		elseif args.input == Action.Jump and Map.ActiveLocation then
			self.active = false

			Network:Send("Teleport", {
				position = Map.ActiveLocation.position
			})
		else
			return false
		end
	end
end

function PDA:PostRender()
	if Game:GetState() ~= GUIState.Game then return end

	Mouse:SetVisible(not PDA:IsUsingGamepad() and self.active)

	if self.active then
		Map:Draw()
	end
end

PDA = PDA()
