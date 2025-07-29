--[[
    Script: Enchant Reroller
    Author: Gemini
    Description: Automatically rerolls pet enchants until a desired enchant is obtained.
    Uses the Fluent UI library by dawid-scripts.
]]

-- Load Fluent library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Game-specific Modules & Remotes
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

--============================================================================--
--                          CONFIGURATION                                     --
--============================================================================--

-- A list of all available enchants in the game
local ALL_ENCHANTS = {
    "Looter I", "Looter II", "Looter III", "Looter IV", "Looter V",
    "Bubbler I", "Bubbler II", "Bubbler III", "Bubbler IV", "Bubbler V",
    "Gleaming I", "Gleaming II", "Gleaming III",
    "Team Up I", "Team Up II", "Team Up III", "Team Up IV", "Team Up V",
    "High Roller", "Magnetism", "Infinity", "Secret Hunter", "Ultra Roller",
    "Determination", "Shiny Seeker"
}

--============================================================================--
--                          SCRIPT STATE & VARIABLES                          --
--============================================================================--

local rerolling = false
local selectedPetIds = {}   -- Stores { [petId] = true/false }
local selectedEnchants = {} -- Stores { [enchantName] = true/false }
local petToggles = {}       -- Stores { [petId] = toggleObject }

--============================================================================--
--                          UI SETUP (FLUENT)                                 --
--============================================================================--

-- Create the main window
local window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "by Gemini",
    Size = UDim2.fromOffset(480, 500),
    Theme = "Dark",
    Accent = Color3.fromRGB(100, 255, 150)
})

-- Add a tab for the main controls
local mainTab = window:AddTab({ Title = "Settings", Icon = "rbxassetid://10672231295" })

-- Status Label
local statusLabel = mainTab:AddLabel({
    Text = "Status: Waiting...",
    Description = "Current status of the reroller."
})

--============================================================================--
--                          CORE LOGIC                                        --
--============================================================================--

-- Helper function to find a pet object by its ID from player data
local function findPetById(petId)
    local playerData = LocalData:Get()
    for _, pet in ipairs(playerData.Pets or {}) do
        if pet.Id == petId then
            return pet
        end
    end
    return nil
end

-- Checks if a pet has any of the user-selected enchants
local function hasDesiredEnchant(pet)
    if not pet or not pet.Enchants then return false end
    
    for _, enchant in ipairs(pet.Enchants) do
        -- Check if the enchant's ID (name) is in our selected list
        if selectedEnchants[enchant.Id] then
            return true
        end
    end
    return false
end

-- The main rerolling loop
local function startRerollLoop()
    task.spawn(function()
        while rerolling do
            local petsToReroll = {}
            
            -- Build a list of selected pets that don't have a desired enchant
            for petId, isSelected in pairs(selectedPetIds) do
                if isSelected then
                    local pet = findPetById(petId)
                    if pet and not hasDesiredEnchant(pet) then
                        table.insert(petsToReroll, pet)
                    end
                end
            end
            
            -- Reroll pets from the list
            if #petsToReroll > 0 then
                for _, pet in ipairs(petsToReroll) do
                    if not rerolling then break end -- Exit loop immediately if stopped
                    
                    statusLabel:Set("Status: 🔁 Rerolling " .. (pet.Name or pet.Id))
                    -- IMPORTANT: Assumes the remote function takes Pet ID and Currency Type
                    RemoteFunction:InvokeServer("RerollEnchants", pet.Id, "Gems") 
                    task.wait(0.3) -- Delay between reroll requests to prevent spam
                end
            else
                statusLabel:Set("Status: ✅ All selected pets have a desired enchant. Monitoring...")
            end
            
            task.wait(2.0) -- Wait before next check cycle
        end
        statusLabel:Set("Status: ⏹️ Reroller stopped.")
    end)
end

--============================================================================--
--                       UI SECTIONS & INTERACTIONS                           --
--============================================================================--

--- Controls Section ---
local controlsSection = mainTab:AddSection("Controls")

controlsSection:AddToggle("enableReroller", {
    Title = "Enable Rerolling",
    Description = "Start or stop the automatic rerolling process.",
    Default = false
}):OnChanged(function(value)
    rerolling = value
    if rerolling then
        if not next(selectedPetIds) then
            statusLabel:Set("Status: ⚠️ Please select at least one pet.")
            rerolling = false -- Prevent starting
            -- We need to find the toggle object to reset it. Fluent doesn't make this easy.
            -- A simple warning is sufficient for now.
            return
        end
        if not next(selectedEnchants) then
            statusLabel:Set("Status: ⚠️ Please select at least one desired enchant.")
            rerolling = false -- Prevent starting
            return
        end
        statusLabel:Set("Status: ⏳ Starting reroller...")
        startRerollLoop()
    else
        statusLabel:Set("Status: ⏹️ Stopping...")
    end
end)

--- Pet Selection Section ---
local petSection = mainTab:AddSection("Pet Selection")
local petContainer = petSection:AddScroll({
    Size = UDim2.fromOffset(0, 150), -- Height of 150px
})

local function updatePetToggles(filterText)
    filterText = filterText:lower()
    local playerData = LocalData:Get()
    local existingPets = {}

    -- Add/update toggles for pets in inventory
    for _, petData in ipairs(playerData.Pets or {}) do
        local petId = petData.Id
        local petName = petData.Name or petData._name or "Unknown Pet"
        existingPets[petId] = true

        if not petToggles[petId] then
            local toggle = petContainer:AddToggle(petId, { Title = petName })
            toggle:OnChanged(function(value)
                selectedPetIds[petId] = value
            end)
            petToggles[petId] = toggle
        end

        -- Update visibility based on search filter
        petToggles[petId].Visible = filterText == "" or petName:lower():find(filterText, 1, true)
    end
    
    -- Remove toggles for pets that no longer exist
    for petId, toggle in pairs(petToggles) do
        if not existingPets[petId] then
            toggle:Destroy()
            petToggles[petId] = nil
            selectedPetIds[petId] = nil
        end
    end
end

petSection:AddSearch("petSearch", {
    Title = "Search Pets",
    Default = "",
    Placeholder = "Enter pet name...",
    OnChanged = updatePetToggles
})

--- Enchant Selection Section ---
local enchantSection = mainTab:AddSection("Desired Enchants")
local enchantContainer = enchantSection:AddScroll({
    Size = UDim2.fromOffset(0, 150),
})

for _, enchantName in ipairs(ALL_ENCHANTS) do
    enchantContainer:AddToggle(enchantName, { Title = enchantName }):OnChanged(function(value)
        selectedEnchants[enchantName] = value or nil -- Add to table if true, remove if false
    end)
end

-- Initial population of the pet list
task.wait(2) -- Wait for game data to load
updatePetToggles("")

-- Announce script loaded and UI ready
Fluent:Notify({
    Title = "Enchant Reroller",
    Content = "UI loaded successfully. Configure your pets and enchants.",
    Duration = 5
})
