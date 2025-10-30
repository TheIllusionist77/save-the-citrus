-- bad orange pathfinding script
local players = game:GetService("Players")
local tween = game:GetService("TweenService")
local pathfinder = game:GetService("PathfindingService")

local orange = script.Parent
local humanoid = orange:WaitForChild("Humanoid")
local root = orange:WaitForChild("HumanoidRootPart")

humanoid.WalkSpeed = 8

-- defining some variables
local attackRange = 4
local scoreDamage = 5
local repathTime = 1
local cooldown = 1

local lastHit = {}

-- creates a pop-up to show score
local function popScore(part, text, color)
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(math.random(-5, 5) / 10, math.random(-5, 5) / 10, math.random(-5, 5) / 10)
	attachment.Parent = part

	local gui = Instance.new("BillboardGui")
	gui.Adornee = attachment
	gui.AlwaysOnTop = true
	gui.Size = UDim2.new(0, 100, 0, 50)
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui

	-- create the tween animation
	local tweenDuration = 1
	tween:Create(attachment, TweenInfo.new(tweenDuration), {Position = attachment.Position + Vector3.new(0, 1, 0)}):Play()
	tween:Create(label, TweenInfo.new(tweenDuration), {TextTransparency = 1}):Play()

	task.delay(tweenDuration, function()
		gui:Destroy()
		attachment:Destroy()
	end)
end

-- make sure the player has a score
local function createScore(player)
	local stats = player:FindFirstChild("leaderstats")
	
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player

		local score = Instance.new("IntValue")
		score.Name = "Score"
		score.Value = 0
		score.Parent = stats
		
		return score
	end
end

-- function for finding nearest character
local function nearestChar()
	local bestChar, bestDist
	
	for _, player in pairs(players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
			if not bestDist or dist < bestDist then
				bestChar, bestDist = char, dist
			end
		end
	end
	
	return bestChar, bestDist
end

-- trying to hit the player
local function hit(player)
	local dt = lastHit[player] or 0
	if os.clock() - dt >= cooldown then
		local score = createScore(player)
		local leaderstats = player:FindFirstChild("leaderstats")
		
		if leaderstats and leaderstats:FindFirstChild("Score") then
			leaderstats.Score.Value = leaderstats.Score.Value - scoreDamage
			if leaderstats.Score.Value < 0 then leaderstats.Score.Value = 0 end
			popScore(player.Character, "-" .. scoreDamage, Color3.fromRGB(255, 38, 0))
		end
		
		lastHit[player] = os.clock()
	end
end

-- pathfinding loop
while task.wait(repathTime) do
	local targetChar, dist = nearestChar()
	
	if targetChar then
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		local player = players:GetPlayerFromCharacter(targetChar)
		
		if targetRoot then
			humanoid:MoveTo(targetRoot.Position)

			if dist <= attackRange and player then
				hit(player)
			end
		end
	end
end