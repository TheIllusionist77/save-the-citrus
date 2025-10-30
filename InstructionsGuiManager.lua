-- defining some elements
local player = game.Players.LocalPlayer
local gui = script.Parent
local panel = gui:WaitForChild("Frame")
local close = panel:WaitForChild("Close")

-- show pop-up on join
gui.Enabled = true

local function closeHandler()
	gui.Enabled = false
end

close.MouseButton1Click:Connect(closeHandler)