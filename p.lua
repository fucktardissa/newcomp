--[[
    Original script functionality maintained.
    UI construction is now handled by the Fluent library.
    - Replaced manual Frame/Button/etc. creation with Fluent's API.
    - Used Fluent's Dropdown for multi-select pet functionality.
    - Used Fluent's Textbox, Button, and Label elements.
    - Logic is connected via Fluent's callback and options system.
]]

--// Services & Variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

--// Fluent Initialization
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "by you",
    TabWidth = 160,
    Size = UDim2.fromOffset(440, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Add a tab for our features
local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://10222013164" })

--// UI Elements
local StatusLabel = MainTab:AddLabel({ Text = "Status: Waiting..." })

-- Section for pet selection
local PetSection = MainTab:AddSection("Pet Selection")
local PetDropdown = PetSection:AddDropdown("PetDropdown", {
    Title = "Select Pets",
    Values = {}, -- Will be populated later
    MultiSelect = true,
    Text = "Click to select pets...",
})

-- Section for reroll configuration and controls
local SettingsSection = MainTab:AddSection("Settings & Control")
SettingsSection:AddTextbox("EnchantName", {
    Title = "Enchant Name",
    PlaceholderText = "e.g., Agility",
    Default = ""
})

SettingsSection:AddTextbox("EnchantLevel", {
    Title = "Enchant Level",
    PlaceholderText = "e.g., 9",
    Default = ""
})

--// Core Logic
local rerolling = false
local petDataMap = {} -- Maps "DisplayName [ID]" back to the raw pet ID

-- Function to update the pet list in the dropdown
local function updatePetList()
    local petsForDropdown = {}
    petDataMap = {} -- Clear previous map

    local data = LocalData:Get()
    if not data or not data.Pets then return end

    for _, pet in pairs(data.Pets) do
        local petName = pet.Name or pet.name or pet._name or "Unknown"
        local petId = pet.Id
        -- Create a unique display name for the dropdown to handle pets with the same name
        local displayName = string.format("%s [%s]", petName, tostring(petId):sub(1, 5))

        table.insert(petsForDropdown, displayName)
        petDataMap[displayName] = petId -- Map the display name to the actual ID
    end

    PetDropdown:SetValues(petsForDropdown)
end

-- Call it once to populate initially and add a button to refresh
updatePetList()
PetSection:AddButton({
    Title = "Refresh Pet List",
    Callback = function()
        updatePetList()
        Fluent:Notify({
            Title = "Success",
            Content = "Pet list has been updated.",
            Duration = 3
        })
    end
})

--// Control Logic
local rerollQueue = {}

local function hasDesiredEnchant(pet, id, lvl)
    if not pet or not pet.Enchants then return false end
    for _, enchant in pairs(pet.Enchants) do
        -- Case-insensitive and partial match for enchant name
        if string.find(string.lower(enchant.Id), string.lower(id)) and enchant.Level == tonumber(lvl) then
            return true
        end
    end
    return false
end

-- Reroll processing loop
local function processRerolls()
    local targetEnchant = Fluent.Options.EnchantName.Value
    local targetLevel = tonumber(Fluent.Options.EnchantLevel.Value)
    
    coroutine.wrap(function()
        -- Initial queue population
        local selectedDisplayNames = Fluent.Options.PetDropdown.Value
        for _, displayName in pairs(selectedDisplayNames) do
            local petId = petDataMap[displayName]
            if petId then
                table.insert(rerollQueue, petId)
            end
        end

        -- Main processing loop
        while rerolling do
            if #rerollQueue > 0 then
                local currentPetId = table.remove(rerollQueue, 1)
                local currentPet
                
                -- Find the pet object from local data
                for _, p in pairs(LocalData:Get().Pets or {}) do
                    if p.Id == currentPetId then
                        currentPet = p
                        break
                    end
                end

                if currentPet and not hasDesiredEnchant(currentPet, targetEnchant, targetLevel) then
                    StatusLabel:Set("🔁 Rerolling " .. (currentPet.Name or currentPetId))
                    RemoteFunction:InvokeServer("RerollEnchants", currentPetId, "Gems")
                    -- Add the pet back to the end of the queue to check it again after others
                    table.insert(rerollQueue, currentPetId)
                else
                    StatusLabel:Set("✅ " .. (currentPet and currentPet.Name or currentPetId) .. " has desired enchant.")
                end

            else -- If queue is empty, monitor selected pets
                StatusLabel:Set("✅ All pets have the desired enchant. Monitoring...")
                task.wait(2.0) -- Wait before checking again

                local selectedDisplayNames = Fluent.Options.PetDropdown.Value
                for _, displayName in pairs(selectedDisplayNames) do
                    local petId = petDataMap[displayName]
                    local pet
                    for _, p in pairs(LocalData:Get().Pets or {}) do
                        if p.Id == petId then pet = p; break end
                    end

                    if pet and not hasDesiredEnchant(pet, targetEnchant, targetLevel) then
                        StatusLabel:Set("⚠️ " .. (pet.Name or pet.Id) .. " lost enchant. Re-queuing...")
                        table.insert(rerollQueue, pet.Id)
                    end
                end
            end
            task.wait(0.4) -- Delay between actions
        end
        StatusLabel:Set("⏹️ Reroll stopped.")
    end)()
end

-- Start Button
SettingsSection:AddButton({
    Title = "▶ Start Rerolling",
    Callback = function()
        local targetEnchant = Fluent.Options.EnchantName.Value
        local targetLevel = tonumber(Fluent.Options.EnchantLevel.Value)
        local selectedPets = Fluent.Options.PetDropdown.Value

        if #selectedPets == 0 then
            StatusLabel:Set("⚠️ Select at least one pet.")
            return
        end
        if targetEnchant == "" or not targetLevel then
            StatusLabel:Set("⚠️ Enter a valid enchant name and level.")
            return
        end

        rerolling = true
        rerollQueue = {} -- Clear queue before starting
        StatusLabel:Set("⏳ Starting reroll...")
        processRerolls()
    end
})

-- Stop Button
SettingsSection:AddButton({
    Title = "■ Stop Rerolling",
    Callback = function()
        rerolling = false
        rerollQueue = {} -- Clear the queue
        StatusLabel:Set("⏹️ Reroll stopped by user.")
    end
})
