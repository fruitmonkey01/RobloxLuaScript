Date: December 16, 2021
Environment: Mac OSX with Roblox Studio
Roblox Game scene: The Suburban Place template

Screen UI:
![alt RobloxGameUI](https://github.com/fruitmonkey01/RobloxLuaScript/blob/main/RobloxGame.png)


Lua Script with following functions:
1. Display information to the player with "GuiService" and Text, BackgroundTransparency
(File: ShowInfo.lua)

2. Used "PathfindingService" with ComputeAsync to create path for Player to move to the destination and avoid obstacles with WayPoints visible for the GUI.
Another is to use "SetPrimaryPartCFrame" method to move player to the destination directly like Teleport approach. (File: Walk.lua)

3. The player can following the instruction provided by the ScreenGUI to drive Jeep in the Suburban and visit several destinations like School, Playground, Library, etc.
Experiment: Tried to use "TweenService" and "PathfindingService" and "Teleport-like" way to let player to move to the destination.  (File: Car.lua)
