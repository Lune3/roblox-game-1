print("Aura Simulator Server Started")

local DataManager = require(script.Parent:WaitForChild("DataManager"))
DataManager.Init()

local LockMechanism = require(script.Parent:WaitForChild("LockMechanism"))
LockMechanism.Init()

local LeaderboardManager = require(script.Parent:WaitForChild("LeaderboardManager"))
LeaderboardManager.Init()

local MonetizationManager = require(script.Parent:WaitForChild("MonetizationManager"))
MonetizationManager.Init()






 
