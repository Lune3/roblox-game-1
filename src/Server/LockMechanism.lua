local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LockMechanism = {}

local APPROACH_DISTANCE = 10
local HOLD_DURATION = 1
local DEFAULT_APPROACHER_COOLDOWN = 10 -- 10 seconds default spam cooldown

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ChatManager = require(script.Parent:WaitForChild("ChatManager"))

local ReleaseLockEvent = Instance.new("RemoteEvent")
ReleaseLockEvent.Name = "ReleaseLockEvent"
ReleaseLockEvent.Parent = Shared

local UpdateSettingsEvent = Instance.new("RemoteEvent")
UpdateSettingsEvent.Name = "UpdateSettingsEvent"
UpdateSettingsEvent.Parent = Shared

local ReactionEvent = Instance.new("RemoteEvent")
ReactionEvent.Name = "ReactionEvent"
ReactionEvent.Parent = Shared

-- Table to keep track of locked pairs
local activeLocks = {}

-- Function to lock two players together
local function LockPlayers(approacher, target)
    local charA = approacher.Character
    local charB = target.Character

    if not charA or not charB then return end

    -- Check if either player is already locked to prevent 3-way interactions
    if charA:GetAttribute("IsLocked") or charB:GetAttribute("IsLocked") then
        return
    end

    local hrpA = charA:FindFirstChild("HumanoidRootPart")
    local hrpB = charB:FindFirstChild("HumanoidRootPart")
    local humA = charA:FindFirstChild("Humanoid")
    local humB = charB:FindFirstChild("Humanoid")

    if not hrpA or not hrpB or not humA or not humB then return end

    -- Distance validation
    if (hrpA.Position - hrpB.Position).Magnitude > APPROACH_DISTANCE then return end

    print(approacher.Name .. " has locked in with " .. target.Name)
    
    local currApp = approacher:GetAttribute("TotalApproaches") or 0
    approacher:SetAttribute("TotalApproaches", currApp + 1)
    
    local currTargeted = target:GetAttribute("TotalApproached") or 0
    target:SetAttribute("TotalApproached", currTargeted + 1)

    -- Mark them as locked
    charA:SetAttribute("IsLocked", true)
    charB:SetAttribute("IsLocked", true)

    -- Freeze both players
    humA.WalkSpeed = 0
    humA.JumpPower = 0
    humB.WalkSpeed = 0
    humB.JumpPower = 0

    -- Force them to face each other (keeping Y axis flat so they don't tilt up/down)
    local posA = hrpA.Position
    local posB = hrpB.Position
    
    local lookPosA = Vector3.new(posB.X, posA.Y, posB.Z)
    local lookPosB = Vector3.new(posA.X, posB.Y, posA.Z)

    hrpA.CFrame = CFrame.lookAt(posA, lookPosA)
    hrpB.CFrame = CFrame.lookAt(posB, lookPosB)

    -- Anchor them so nobody can push them around
    hrpA.Anchored = true
    hrpB.Anchored = true

    -- Calculate Session Count for Diminishing Returns
    local DataManager = require(script.Parent:WaitForChild("DataManager"))
    local profileA = DataManager.GetProfile(approacher)
    local profileB = DataManager.GetProfile(target)
    
    local sessionCountA = 1
    local sessionCountB = 1
    
    if profileA then
        local targetIdStr = tostring(target.UserId)
        local voteData = profileA.Data.LastVoted[targetIdStr]
        if not voteData then
            voteData = { count = 0, timestamp = os.time() }
            profileA.Data.LastVoted[targetIdStr] = voteData
        end
        if os.time() - voteData.timestamp > 86400 then
            voteData.count = 0
        end
        voteData.count = voteData.count + 1
        voteData.timestamp = os.time()
        sessionCountA = voteData.count
    end
    
    if profileB then
        local approacherIdStr = tostring(approacher.UserId)
        local voteData = profileB.Data.LastVoted[approacherIdStr]
        if not voteData then
            voteData = { count = 0, timestamp = os.time() }
            profileB.Data.LastVoted[approacherIdStr] = voteData
        end
        if os.time() - voteData.timestamp > 86400 then
            voteData.count = 0
        end
        voteData.count = voteData.count + 1
        voteData.timestamp = os.time()
        sessionCountB = voteData.count
    end

    -- Store the lock in the dictionary with roles and a unique timestamp
    local currentLockTime = os.time()
    activeLocks[approacher] = { target = target, isApproacher = true, sessionCount = sessionCountA, lockTime = currentLockTime }
    activeLocks[target] = { target = approacher, isApproacher = false, sessionCount = sessionCountB, lockTime = currentLockTime }
    
    -- AFK Timer: Auto-unlock after 5 minutes (300 seconds)
    task.delay(300, function()
        local lockData = activeLocks[approacher]
        if lockData and lockData.target == target and lockData.lockTime == currentLockTime then
            print("5 minute AFK limit reached. Auto-unlocking " .. approacher.Name .. " and " .. target.Name)
            UnlockPlayer(approacher)
        end
    end)

    -- Disable both of their ProximityPrompts so no one else can interact with them
    local promptA = hrpA:FindFirstChild("ApproachPrompt")
    local promptB = hrpB:FindFirstChild("ApproachPrompt")
    
    if promptA then promptA.Enabled = false end
    if promptB then promptB.Enabled = false end

    -- Tell BOTH players to show their UI!
    ReleaseLockEvent:FireClient(target, "Show", false) -- isApproacher = false
    ReleaseLockEvent:FireClient(approacher, "Show", true)  -- isApproacher = true
    
    -- Create Private Chat Session
    ChatManager.CreatePrivateSession(approacher, target)
end

-- Global function to unlock whoever the player is currently locked to
local function UnlockPlayer(player)
    local lockData = activeLocks[player]
    if not lockData then return end

    local target = lockData.target

    print("Lock released between " .. player.Name .. " and " .. target.Name)

    -- Tell both clients to hide their UI
    ReleaseLockEvent:FireClient(player, "Hide")
    ReleaseLockEvent:FireClient(target, "Hide")

    -- Apply Approacher spam cooldown
    if activeLocks[player].isApproacher then
        player:SetAttribute("NextApproachTime", os.time() + DEFAULT_APPROACHER_COOLDOWN)
    end
    if activeLocks[target].isApproacher then
        target:SetAttribute("NextApproachTime", os.time() + DEFAULT_APPROACHER_COOLDOWN)
    end
    
    -- End Private Chat Session
    ChatManager.EndPrivateSession(player, target)

    -- Remove from lock table
    activeLocks[player] = nil
    activeLocks[target] = nil

    local charA = player.Character
    local charB = target.Character

    if charA then
        charA:SetAttribute("IsLocked", false)
        local humA = charA:FindFirstChild("Humanoid")
        if humA then
            humA.WalkSpeed = 16
            humA.JumpPower = 50
        end
        local hrpA = charA:FindFirstChild("HumanoidRootPart")
        if hrpA then
            hrpA.Anchored = false
            local cooldownA = player:GetAttribute("ApproachCooldown") or 5
            task.delay(cooldownA, function()
                if hrpA and hrpA:FindFirstChild("ApproachPrompt") and not charA:GetAttribute("IsLocked") then
                    hrpA.ApproachPrompt.Enabled = true
                end
            end)
        end
    end

    if charB then
        charB:SetAttribute("IsLocked", false)
        local humB = charB:FindFirstChild("Humanoid")
        if humB then
            humB.WalkSpeed = 16
            humB.JumpPower = 50
        end
        local hrpB = charB:FindFirstChild("HumanoidRootPart")
        if hrpB then
            hrpB.Anchored = false
            local cooldownB = target:GetAttribute("ApproachCooldown") or 5
            task.delay(cooldownB, function()
                if hrpB and hrpB:FindFirstChild("ApproachPrompt") and not charB:GetAttribute("IsLocked") then
                    hrpB.ApproachPrompt.Enabled = true
                end
            end)
        end
    end
end

-- Setup player when they spawn
local function SetupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        -- Ensure they start unlocked
        character:SetAttribute("IsLocked", false)

        -- Set a default cooldown of 5 seconds for testing (players can change this later via UI)
        if not player:GetAttribute("ApproachCooldown") then
            player:SetAttribute("ApproachCooldown", 5)
        end
        if not player:GetAttribute("RizzScore") then
            player:SetAttribute("RizzScore", 100)
        end

        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end

        -- Create the Approach prompt
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "ApproachPrompt"
        prompt.ActionText = "Approach"
        prompt.ObjectText = player.DisplayName
        prompt.HoldDuration = HOLD_DURATION
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = APPROACH_DISTANCE
        prompt.Parent = hrp

        -- Handle the trigger
        prompt.Triggered:Connect(function(triggeringPlayer)
            -- You can't approach yourself
            if triggeringPlayer == player then return end

            -- Check if Approacher is on spam cooldown
            local nextTime = triggeringPlayer:GetAttribute("NextApproachTime")
            if nextTime and os.time() < nextTime then
                local timeLeft = nextTime - os.time()
                print(triggeringPlayer.Name .. " is on approach cooldown for " .. timeLeft .. " more seconds.")
                return
            end
            
            -- Lock them together
            LockPlayers(triggeringPlayer, player)
        end)
    end)
end

function LockMechanism.Init()
    Players.PlayerAdded:Connect(SetupPlayer)

    -- Handle any players already in the server when the script starts
    for _, player in ipairs(Players:GetPlayers()) do
        SetupPlayer(player)
    end

    -- Listen for clients pressing the UI button
    ReleaseLockEvent.OnServerEvent:Connect(function(player)
        UnlockPlayer(player)
    end)

    -- Handle player disconnecting while locked
    Players.PlayerRemoving:Connect(function(player)
        UnlockPlayer(player)
    end)

    -- Handle setting updates
    UpdateSettingsEvent.OnServerEvent:Connect(function(player, newCooldown)
        if type(newCooldown) == "number" then
            -- Clamp the value between 0 seconds and 1000 seconds (15 minutes) to prevent crashing
            local clamped = math.clamp(math.floor(newCooldown), 0, 1000)
            player:SetAttribute("ApproachCooldown", clamped)
            print(player.Name .. " updated their cooldown to " .. clamped .. " seconds.")
        end
    end)

    -- Handle Reaction Event
    local reactionScores = {
        ["W Rizz"] = 20,
        ["Smooth"] = 10,
        ["Neutral"] = 0,
        ["Awkward"] = -10,
        ["Cringe"] = -20
    }

    ReactionEvent.OnServerEvent:Connect(function(player, reactionName)
        local lockData = activeLocks[player]
        if not lockData then return end
        
        -- Anti-spam cooldown (Set to 0 for testing!)
        if lockData.lastReactionTime and (os.time() - lockData.lastReactionTime) < 0 then
            return
        end
        
        -- Anti-griefing limit: Max 5 reactions per conversation
        lockData.reactionCount = (lockData.reactionCount or 0) + 1
        if lockData.reactionCount > 5 then
            return
        end
        
        lockData.lastReactionTime = os.time()
        
        -- The player clicking the reaction is the Target.
        local approacher = lockData.target
        local scoreChange = reactionScores[reactionName] or 0
        
        -- Anti-Abuse: Diminishing Returns (Calculated per session, not per reaction)
        if scoreChange ~= 0 then
            local sessionCount = lockData.sessionCount or 1
            local multiplier = 1
            if sessionCount == 2 then multiplier = 0.5
            elseif sessionCount == 3 then multiplier = 0.25
            elseif sessionCount >= 4 then multiplier = 0 end
            
            scoreChange = math.floor(scoreChange * multiplier)
            if multiplier < 1 then
                print(player.Name .. " diminishing returns applied. Session Multiplier: " .. multiplier)
            end
        end
        
        if scoreChange ~= 0 then
            local currentScore = approacher:GetAttribute("RizzScore") or 100
            approacher:SetAttribute("RizzScore", currentScore + scoreChange)
            print(approacher.Name .. " Rizz Score updated to " .. (currentScore + scoreChange))
        end
        
        local targetChar = player.Character
        if targetChar then
            -- Tell everyone in the server, now including reactionName for VFX
            ReactionEvent:FireAllClients(targetChar, scoreChange, reactionName)
        end
    end)
end

return LockMechanism
