-- Services
local GuiService = game:GetService("GuiService")

-- Variables
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Main screenGui
local screenGui = Instance.new("ScreenGui", playerGui)
local min_transparency = 0
local max_transparency = 0.9
local delta = 0.2


local function showPlayerInfo()
	-- Onscreen player info
	local playerInfo = Instance.new("TextButton", screenGui)

	playerInfo.Name = "playerInfo"
	playerInfo.Text = " Keyboard Key Info: \n Press 'A', 'S', 'D', 'W' \n or Arrow Keys to move."

	-- Set text UI
	playerInfo.Size = UDim2.new(0, 300, 0, 75)
	playerInfo.Font = Enum.Font.SourceSans
	playerInfo.FontSize = Enum.FontSize.Size24

	playerInfo.BackgroundTransparency = min_transparency + delta	
end


showPlayerInfo()