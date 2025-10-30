-- getting services
local orchard = game.Workspace:WaitForChild("Orchard")
local tween = game:GetService("TweenService")
local replicated = game:GetService("ReplicatedStorage")

-- spawn variables
local spawnInterval = 3
local minSpawnInterval = 1
local spawnFactor = 0.9

-- timing variables
local levelTimer = 30
local dt = 0.5

-- greening variables
local greenTime = 30
local greenSpeed = 1
local maxGreenSpeed = 4
local greenFactor = 1.1
local expirationPenalty = 1

-- point boundaries for oranges
local freshPoints = 10
local greenPoints = 3

-- colors
local fresh = Color3.fromRGB(255, 147, 0)
local green = Color3.fromRGB(0, 249, 0)

-- shared game information (stored in ReplicatedStorage)
local information = replicated:FindFirstChild("Information")
local level = information:FindFirstChild("Level")
local nextLevelTime = information:FindFirstChild("NextLevelTime")
nextLevelTime.Value = levelTimer

-- table to hold oranges
local oranges = {}

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
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	
	-- create the tween animation
	local tweenDuration = 1
	tween:Create(attachment, TweenInfo.new(tweenDuration), {Position = attachment.Position + Vector3.new(0, 1, 0)}):Play()
	tween:Create(label, TweenInfo.new(tweenDuration), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	
	task.delay(tweenDuration, function()
		gui:Destroy()
		attachment:Destroy()
	end)
end

-- loop through all trees and oranges
for _, tree in pairs(orchard:GetChildren()) do
	for _, orange in pairs(tree:GetChildren()) do
		if orange:IsA("BasePart") then
			-- setting up oranges
			local progress = orange:FindFirstChild("Progress")
			
			if progress then
				progress.Value = 0
			end
			
			orange.Transparency = 1
			orange.Color = fresh
			orange.CanTouch = false
			table.insert(oranges, orange)
			
			-- logic for when oranges are clicked
			local click = orange:FindFirstChild("ClickDetector")
			if click then
				click.MouseClick:Connect(function(player)
					if orange:GetAttribute("Active") then
						local percent = progress.Value / 100
						local points = math.floor(freshPoints - (freshPoints - greenPoints) * percent)
						
						-- change the player's score
						local leaderstats = player:FindFirstChild("leaderstats")
						if not leaderstats then
							leaderstats = Instance.new("Folder")
							leaderstats.Name = "leaderstats"
							leaderstats.Parent = player
							
							local score = Instance.new("IntValue")
							score.Name = "Score"
							score.Parent = leaderstats
						end
						
						leaderstats.Score.Value = leaderstats.Score.Value + points
						
						-- reset the orange
						popScore(orange, "+" .. points, orange.Color)
						orange:SetAttribute("Active", false)
						progress.Value = 0
						orange.Transparency = 1
						orange.Color = fresh
					end
				end)
			end
		end
	end
end

-- picking a random orange
local function getRandomOrange()
	local choices = {}
	
	for _, orange in pairs(oranges) do
		if not orange:GetAttribute("Active") then
			table.insert(choices, orange)
		end
	end
	
	if #choices == 0 then return nil end
	
	return choices[math.random(1, #choices)]
end

-- spawn loop for oranges
task.spawn(function()
	while true do
		local orange = getRandomOrange()
		if orange then
			orange:SetAttribute("Active", true)
			orange.Transparency = 0
			orange.Color = fresh
			
			local progress = orange:FindFirstChild("Progress")
			
			if progress then
				progress.Value = 0
			end
		end
		
		task.wait(spawnInterval)
	end
end)

-- level manager
task.spawn(function()
	while true do
		for t = levelTimer, 1, -1 do
			nextLevelTime.Value = t
			task.wait(1)
		end
		
		level.Value = level.Value + 1
		
		if spawnInterval > minSpawnInterval then
			spawnInterval = math.max(minSpawnInterval, spawnInterval * spawnFactor)
		end
		
		if greenSpeed < maxGreenSpeed then
			greenSpeed = math.min(maxGreenSpeed, greenSpeed * greenFactor)
		end
		
		nextLevelTime.Value = levelTimer
	end
end)

-- making oranges green
task.spawn(function()
	while true do
		for _, orange in pairs(oranges) do
			if orange:GetAttribute("Active") then
				local progress = orange:FindFirstChild("Progress")
				
				if progress then
					if progress.Value < 100 then
						progress.Value = progress.Value + (dt / greenTime) * 100 * greenSpeed
					end
					
					local ratio = progress.Value / 100
					local r = fresh.R + (green.R - fresh.R) * ratio
					local g = fresh.G + (green.G - fresh.G) * ratio
					local b = fresh.B + (green.B - fresh.B) * ratio
					orange.Color = Color3.new(r, g, b)
					
					if progress.Value >= 100 then
						orange:SetAttribute("Active", false)
						progress.Value = 0
						orange.Transparency = 1
						orange.Color = fresh
						orange.CanTouch = false
						
						-- removing points for letting oranges expire
						for _, player in pairs(game.Players:GetPlayers()) do
							local leaderstats = player:FindFirstChild("leaderstats")
							
							if leaderstats and leaderstats:FindFirstChild("Score") then
								leaderstats.Score.Value = leaderstats.Score.Value - expirationPenalty
								if leaderstats.Score.Value < 0 then leaderstats.Score.Value = 0 end
							end
						end
						
						popScore(orange, "-1", Color3.fromRGB(255, 38, 0))
					end
				end
			end
		end
		task.wait(dt)
	end
end)