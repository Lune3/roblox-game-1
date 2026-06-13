local Players = game:GetService("Players")

local LockMechanism = {}

local APPROACH_DISTANCE = 50
local HOLD_DURATION = 2
local RELEASE_DURATION = 2

-- Table to keep track of locked pairs (we can use this later for UI/Audio)
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

    -- Disable both of their ProximityPrompts so no one else can interact with them
    local promptA = hrpA:FindFirstChild("ApproachPrompt")
    local promptB = hrpB:FindFirstChild("ApproachPrompt")
    
    if promptA then promptA.Enabled = false end
    if promptB then promptB.Enabled = false end

    -- Create a temporary Release Prompt on the Approacher for the Target to use
    local releasePrompt = Instance.new("ProximityPrompt")
    releasePrompt.Name = "ReleasePrompt"
    releasePrompt.ActionText = "Release Lock"
    releasePrompt.ObjectText = approacher.DisplayName
    releasePrompt.HoldDuration = RELEASE_DURATION
    releasePrompt.KeyboardKeyCode = Enum.KeyCode.E
    releasePrompt.RequiresLineOfSight = false
    releasePrompt.MaxActivationDistance = APPROACH_DISTANCE
    releasePrompt.Parent = hrpA

    -- Function to unlock them
    local function UnlockPlayers()
        if not charA or not charB then return end

        print("Lock released between " .. approacher.Name .. " and " .. target.Name)

        charA:SetAttribute("IsLocked", false)
        charB:SetAttribute("IsLocked", false)

        if humA then
            humA.WalkSpeed = 16
            humA.JumpPower = 50
        end
        if humB then
            humB.WalkSpeed = 16
            humB.JumpPower = 50
        end

        if promptA then promptA.Enabled = true end
        if promptB then promptB.Enabled = true end

        releasePrompt:Destroy()
    end

    -- Listen for the target to release the lock
    releasePrompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer == target then
            UnlockPlayers()
        end
    end)
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
end

return LockMechanism
