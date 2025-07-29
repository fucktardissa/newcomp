--// Services & Fluent Setup //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Load Fluent library and its SaveManager addon
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
SaveManager:SetLibrary(Fluent)

--// Main Variables & Dependencies //--
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local rerolling = false
local rerollThread = nil

--// Create the Fluent Window //--
local Window = Fluent:CreateWindow({
    Title = "Enchant Reroller 🔁",
    SubTitle = "by your_name_here",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 420), -- Adjusted size for the new layout
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Add a tab for the main functionality
local RerollerTab = Window:AddTab({ Title = "Reroller", Icon = "refresh" })

--// Helper Functions //--

-- Fetches and formats pet data for the dropdown
local function getPetOptions()
    local petData = LocalData:Get()
    local petOptions = {}
    if not petData or not petData.Pets then return petOptions end

    for _, pet in pairs(petData.Pets) do
        -- Create a display name and store the ID in a way we can retrieve it
        local petName = pet.Name or pet.name or pet._name or "Unknown"
        local petId = pet.Id
        -- Format: "Pet Name [ID]" to ensure uniqueness and provide info
        petOptions[petName .. " [" .. tostring(petId) .. "]"] = true
    end
    return petOptions
end

-- Extracts the Pet ID from the dropdown's formatted string
local function getPetIdFromString(petString)
    -- Matches the content within the square brackets at the end of the string
    return string.match(petString, "%[(.+)%]$")
end

-- Checks if a pet has the desired enchant
local function hasDesiredEnchant(pet, enchantId, enchantLevel)
    if not pet or not pet.Enchants then return false end
    for _, enchant in pairs(pet.Enchants) do
        if string.lower(tostring(enchant.Id)) == string.lower(tostring(enchantId)) and enchant.Level == tonumber(enchantLevel) then
            return true
        end
    end
    return false
end

--// UI Elements //--

-- A paragraph for status updates
local StatusLabel = RerollerTab:AddParagraph({
    Title = "Status",
    Content = "Waiting for instructions..."
})

-- Multi-selection dropdown for pets
local PetDropdown = RerollerTab:AddMultiDropdown("PetSelector", {
    Title = "Select Pets",
    Values = getPetOptions(),
    Default = {},
})

-- Input field for the enchant name
local EnchantNameInput = RerollerTab:AddInput("EnchantName", {
    Title = "Enchant Name",
    Placeholder = "e.g., Agility",
    Default = ""
})

-- Input field for the enchant level
local EnchantLevelInput = RerollerTab:AddInput("EnchantLevel", {
    Title = "Enchant Level",
    Placeholder = "e.g., 9",
    Default = "",
    Numeric = true -- Restrict input to numbers
})

RerollerTab:AddButton({
    Title = "Refresh Pet List",
    Description = "Click if your pets have changed.",
    Callback = function()
        PetDropdown:SetValues(getPetOptions())
        Fluent:Notify({ Title = "Pets Refreshed", Content = "The pet list has been updated." })
    end
})

-- The main toggle to start and stop the rerolling process
RerollerTab:AddToggle("RerollToggle", {
    Title = "Start / Stop Rerolling",
    Default = false,
    Callback = function(value)
        rerolling = value

        if not rerolling then
            -- Stop the process
            if rerollThread then
                task.cancel(rerollThread)
                rerollThread = nil
            end
            StatusLabel:Set("⏹️ Reroll stopped by user.")
            return
        end

        -- Start the process
        local selectedPetsRaw = PetDropdown.Value
        local targetEnchant = EnchantNameInput.Value
        local targetLevel = tonumber(EnchantLevelInput.Value)

        -- --- Validation ---
        if not next(selectedPetsRaw) then
            StatusLabel:Set("⚠️ Error: Select at least one pet.")
            rerolling = false
            return
        end
        if targetEnchant == "" or not targetLevel then
            StatusLabel:Set("⚠️ Error: Enter a valid enchant name and level.")
            rerolling = false
            return
        end
        -- --- End Validation ---

        -- Create and start the main reroll coroutine
        rerollThread = task.spawn(function()
            local rerollQueue = {}

            -- Main loop, continues as long as the toggle is on
            while rerolling do
                local playerData = LocalData:Get()
                rerollQueue = {} -- Clear and rebuild the queue each cycle

                -- Check all selected pets and queue the ones needing a reroll
                for petString, _ in pairs(selectedPetsRaw) do
                    local petId = getPetIdFromString(petString)
                    local currentPet
                    for _, p in pairs(playerData.Pets or {}) do
                        if p.Id == petId then
                            currentPet = p
                            break
                        end
                    end

                    if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                        table.insert(rerollQueue, {id = petId, name = currentPet.Name or petId})
                    end
                end

                -- Process the queue
                if #rerollQueue > 0 then
                    for _, petToReroll in ipairs(rerollQueue) do
                        if not rerolling then break end -- Check if stopped mid-queue
                        
                        StatusLabel:Set("🔁 Rerolling: " .. petToReroll.name)
                        RemoteFunction:InvokeServer("RerollEnchants", petToReroll.id, "Gems")
                        task.wait(0.3) -- Wait between rerolls
                    end
                else
                    StatusLabel:Set("✅ All selected pets have the desired enchant. Monitoring...")
                end

                task.wait(1.5) -- Wait before checking all pets again
            end
            StatusLabel:Set("⏹️ Reroll process finished.")
        end)
    end
})

--// Finalize UI //--
Window:SelectTab(1)
Fluent:Notify({
    Title = "Script Loaded",
    Content = "Enchant Reroller is ready.",
    Duration = 8
})
