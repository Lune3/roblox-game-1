local Players = game:GetService("Players")
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local ProfileStore = ProfileService.GetProfileStore(
    "PlayerData_v1",
    {
        RizzScore = 100,
        TotalApproaches = 0,
        TotalApproached = 0,
        LastVoted = {}, -- [tostring(userId)] = timestamp
    }
)

local Profiles = {}
local DataManager = {}

function DataManager.Init()
    local function PlayerAdded(player)
        local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
        if profile ~= nil then
            profile:AddUserId(player.UserId)
            profile:Reconcile()
            
            profile:ListenToRelease(function()
                Profiles[player] = nil
                player:Kick("Data profile was loaded elsewhere.")
            end)
            
            if player:IsDescendantOf(Players) then
                Profiles[player] = profile
                
                -- Create Leaderstats so they can see it in standard Roblox UI too
                local leaderstats = Instance.new("Folder")
                leaderstats.Name = "leaderstats"
                leaderstats.Parent = player
                
                local rizz = Instance.new("IntValue")
                rizz.Name = "Aura"
                rizz.Value = profile.Data.RizzScore
                rizz.Parent = leaderstats
                
                -- Update the player's attributes so the rest of the game can easily read it
                player:SetAttribute("RizzScore", profile.Data.RizzScore)
                player:SetAttribute("TotalApproaches", profile.Data.TotalApproaches)
                player:SetAttribute("TotalApproached", profile.Data.TotalApproached)
                
                -- Sync Attributes -> Profile Data automatically
                player:GetAttributeChangedSignal("RizzScore"):Connect(function()
                    profile.Data.RizzScore = player:GetAttribute("RizzScore")
                    rizz.Value = profile.Data.RizzScore
                end)
                player:GetAttributeChangedSignal("TotalApproaches"):Connect(function()
                    profile.Data.TotalApproaches = player:GetAttribute("TotalApproaches")
                end)
                player:GetAttributeChangedSignal("TotalApproached"):Connect(function()
                    profile.Data.TotalApproached = player:GetAttribute("TotalApproached")
                end)
            else
                profile:Release()
            end
        else
            player:Kick("Data could not load. Please rejoin.")
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(PlayerAdded, player)
    end
    Players.PlayerAdded:Connect(PlayerAdded)

    Players.PlayerRemoving:Connect(function(player)
        local profile = Profiles[player]
        if profile then
            profile:Release()
        end
    end)
end

function DataManager.GetProfile(player)
    return Profiles[player]
end

return DataManager
