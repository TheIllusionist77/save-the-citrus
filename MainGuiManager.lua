-- getting services
local players = game:GetService("Players")
local replicated = game:GetService("ReplicatedStorage")
local player = players.LocalPlayer

-- create the GUI
local gui = script.Parent
local scoreLabel = gui:WaitForChild("ScoreLabel")
local levelLabel = gui:WaitForChild("LevelLabel")
local nextLabel = gui:WaitForChild("NextLabel")

-- update score from leaderstats
local function updateScore()
	local leaderstats = player:FindFirstChild("leaderstats")
	local score = leaderstats:FindFirstChild("Score")
	
	score:GetPropertyChangedSignal("Value"):Connect(function()
		scoreLabel.Text = "Score: " .. score.Value
	end)
end

-- connect to function when player joins
player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then updateScore() end
end)

-- update level and countdown from server
local information = replicated:WaitForChild("Information")
local level = information:FindFirstChild("Level")
local nextLevelTime = information:FindFirstChild("NextLevelTime")

level:GetPropertyChangedSignal("Value"):Connect(function()
	levelLabel.Text = "Level: " .. level.Value
end)

nextLevelTime:GetPropertyChangedSignal("Value"):Connect(function()
	nextLabel.Text = ("Next in: %ds"):format(nextLevelTime.Value)
end)