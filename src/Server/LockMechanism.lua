local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LockMechanism = {}

local APPROACH_DISTANCE = 10
local HOLD_DURATION = 1

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReleaseLockEvent = Instance.new("RemoteEvent")
ReleaseLockEvent.Name = "ReleaseLockEvent"
ReleaseLockEvent.Parent = Shared

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

    -- Mark them as locked
    charA:SetAttribute("IsLocked", true)
    charB:SetAttribute("IsLocked", true)

    -- Freeze both players
    humA.WalkSpeed = 0
    humA.JumpPower = 0
    humB.WalkSpeed = 0
    humB.JumpPower = 0

    -- Force them to face each other
    local posA = hrpA.Position
    local posB = hrpB.Position
    
    local lookPosA = Vector3.new(posB.X, posA.Y, posB.Z)
    local lookPosB = Vector3.new(posA.X, posB.Y, posA.Z)

    hrpA.CFrame = CFrame.lookAt(posA, lookPosA)
    hrpB.CFrame = CFrame.lookAt(posB, lookPosB)

    -- Store the lock in the dictionary
    activeLocks[approacher] = target
    activeLocks[target] = approacher

    -- Disable both of their ProximityPrompts so no one else can interact with them
    local promptA = hrpA:FindFirstChild("ApproachPrompt")
    local promptB = hrpB:FindFirstChild("ApproachPrompt")
    
    if promptA then promptA.Enabled = false end
    if promptB then promptB.Enabled = false end

    -- Tell BOTH players to show their UI!
    ReleaseLockEvent:FireClient(target, "Show", false) -- isApproacher = false
    ReleaseLockEvent:FireClient(approacher, "Show", true)  -- isApproacher = true
end

-- Global function to unlock whoever the player is currently locked to
local function UnlockPlayer(player)
    local target = activeLocks[player]
    if not target then return end

    print("Lock released between " .. player.Name .. " and " .. target.Name)

    -- Tell both clients to hide their UI
    ReleaseLockEvent:FireClient(player, "Hide")
    ReleaseLockEvent:FireClient(target, "Hide")

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
        if hrpA and hrpA:FindFirstChild("ApproachPrompt") then
            hrpA.ApproachPrompt.Enabled = true
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
        if hrpB and hrpB:FindFirstChild("ApproachPrompt") then
            hrpB.ApproachPrompt.Enabled = true
        end
    end
end

-- Setup player when they spawn
local function SetupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        -- Ensure they start unlocked
        character:SetAttribute("IsLocked", false)

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
end

return LockMechanism
