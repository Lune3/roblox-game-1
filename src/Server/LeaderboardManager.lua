local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local LeaderboardManager = {}

local RizzStore = DataStoreService:GetOrderedDataStore("Leaderboard_RizzScore_v1")
local ApproacherStore = DataStoreService:GetOrderedDataStore("Leaderboard_Approaches_v1")
local ApproachedStore = DataStoreService:GetOrderedDataStore("Leaderboard_Approached_v1")

local function SavePlayerStats()
    for _, player in ipairs(Players:GetPlayers()) do
        local rizz = player:GetAttribute("RizzScore")
        local approaches = player:GetAttribute("TotalApproaches")
        local approached = player:GetAttribute("TotalApproached")

        if rizz then
            pcall(function()
                RizzStore:SetAsync(player.UserId, rizz)
            end)
        end
        if approaches then
            pcall(function()
                ApproacherStore:SetAsync(player.UserId, approaches)
            end)
        end
        if approached then
            pcall(function()
                ApproachedStore:SetAsync(player.UserId, approached)
            end)
        end
    end
end

local function PrintLeaderboard(title, store)
    print("\n--- " .. title .. " LEADERBOARD ---")
    local success, pages = pcall(function()
        return store:GetSortedAsync(false, 10)
    end)

    if success and pages then
        local data = pages:GetCurrentPage()
        if #data == 0 then
            print("No data yet.")
        else
            for rank, entry in ipairs(data) do
                local name = "Unknown"
                pcall(function()
                    name = Players:GetNameFromUserIdAsync(entry.key)
                end)
                print(rank .. ". " .. name .. " - " .. entry.value)
            end
        end
    else
        print("Failed to load " .. title .. " leaderboard.")
    end
    print("----------------------------------\n")
end

function LeaderboardManager.Init()
    task.spawn(function()
        while true do
            task.wait(60) -- Update every 60 seconds
            
            -- 1. Save current server players to the OrderedDataStore
            SavePlayerStats()
            
            -- 2. Fetch and print the top global players
            PrintLeaderboard("HIGHEST RIZZ", RizzStore)
            PrintLeaderboard("MOST APPROACHER", ApproacherStore)
            PrintLeaderboard("MOST APPROACHED", ApproachedStore)
        end
    end)
    
    -- Save when a player leaves to ensure their final score is on the board
    Players.PlayerRemoving:Connect(function(player)
        local rizz = player:GetAttribute("RizzScore")
        local approaches = player:GetAttribute("TotalApproaches")
        local approached = player:GetAttribute("TotalApproached")

        if rizz then pcall(function() RizzStore:SetAsync(player.UserId, rizz) end) end
        if approaches then pcall(function() ApproacherStore:SetAsync(player.UserId, approaches) end) end
        if approached then pcall(function() ApproachedStore:SetAsync(player.UserId, approached) end) end
    end)
end

return LeaderboardManager
