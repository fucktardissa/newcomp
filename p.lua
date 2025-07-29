--[[
    Title: Enchant Reroller (Fluent Edition)
    Description: A full-featured petasdasdasdasfgasgasggsaagsgasgasasg enchant reroller built with the Fluent UI library.
    Features:
    - Multi-select pet dropdown with a refresh button.
    - Multi-select enchant dropdown.
    - Single toggle button for starting and stopping the process.
    - Real-time status updates.
]]

--// =================================================================================
--// Part 1: Setup & Services
--// =================================================================================

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Game-Specific Modules
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

-- State Variables
local rerolling = false

--// =================================================================================
--// Part 2: Fluent UI Initialization
--// =================================================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "v2.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(460, 550),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Create the main tab and sections
local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://10222013164" })
local PetSection = MainTab:AddSection("Pet Selection")
local SettingsSection = MainTab:AddSection("Settings & Control")

--// =================================================================================
--// Part 3: UI Element Definitions
--// =================================================================================

-- Pet Selection UI
local petDataMap = {} -- Links dropdown names to unique pet IDs
local PetDropdown = PetSection:AddDropdown("PetDropdown", {
    Title = "Select Pets",
    Values = {},
    MultiSelect = true,
    Text = "Click Refresh Pet List below...",
})
PetSection:AddButton({
    Title = "🔄 Refresh Pet List",
    Callback = function()
        updatePetList()
    end,
})

-- Settings & Control UI
local availableEnchants = {
    "Secret Hunter", "Determination", "Ultra Roller", "Shiny Seeker", "Magnetism", 
    "Infinity", "High Roller", "Team Up I", "Team up II", "Team up III", 
    "Team Up IV", "Team Up V", "Looter I", "Looter II", "Looter III", "Looter IV", 
    "Looter V", "Gleaming I", "Gleaming II", "Gleaming III", "Bubbler I", 
    "Bubbler II", "Bubbler III", "Bubbler IV", "Bubbler V"
}
local EnchantDropdown = SettingsSection:AddDropdown("EnchantDropdown", {
    Title = "Desired Enchant(s)",
    Values = availableEnchants,
    MultiSelect = true,
    Text = "Click to select enchants...",
})
SettingsSection:AddTextbox("EnchantLevel", {
    Title = "Enchant Level",
    PlaceholderText = "e.g., 9",
    Default = "",
})
local StatusLabel = SettingsSection:AddLabel({ Text = "Status: Waiting..." })
local EnchantToggle -- Forward-declare so the functions below can reference it

--// =================================================================================
--// Part 4: Core Logic & Functions
--// =================================================================================

-- Checks if a pet has ANY of the desired enchants
local function hasDesiredEnchant(pet, targetEnchants, enchantLevel)
    for _, desiredId in pairs(targetEnchants) do
        for _, petEnchant in pairs(pet.Enchants or {}) do
            if string.lower(petEnchant.Id) == string.lower(desiredId) and petEnchant.Level == tonumber(enchantLevel) then
                return true
            end
        end
    end
    return false
end

-- Finds pets and updates the PetDropdown
function updatePetList()
    local petsForDropdown = {}
    petDataMap = {}
    local data = LocalData:Get()
    if not (data and data.Pets) then return end

    for _, pet in pairs(data.Pets) do
        local displayName = string.format("%s [%s]", (pet.Name or "Unknown"), tostring(pet.Id):sub(1, 5))
        table.insert(petsForDropdown, displayName)
        petDataMap[displayName] = pet.Id
    end
    
    PetDropdown:SetValues(petsForDropdown)
    if #petsForDropdown > 0 then
        Fluent:Notify({ Title = "Success", Content = "Found " .. #petsForDropdown .. " pets.", Duration = 4 })
    end
end

-- Main reroll process, started by the toggle
local function startRerollProcess()
    local targetEnchants = Fluent.Options.EnchantDropdown.Value
    local targetLevel = tonumber(Fluent.Options.EnchantLevel.Value)
    local rerollQueue = {}
    
    -- Convert selected dropdown names back to real pet IDs
    local selectedPetIds = {}
    for _, displayName in pairs(Fluent.Options.PetDropdown.Value) do
        if petDataMap[displayName] then table.insert(selectedPetIds, petDataMap[displayName]) end
    end
    
    -- Validation checks
    if #selectedPetIds == 0 or #targetEnchants == 0 or not targetLevel then
        StatusLabel:SetText("⚠️ Please select pets, enchants, and a level.")
        EnchantToggle:Set({ Value = false, Silent = true })
        EnchantToggle:SetText("Start Enchanting")
        return
    end
    
    rerolling = true
    StatusLabel:SetText("⏳ Initializing...")
    
    -- Main reroll and monitoring loop
    coroutine.wrap(function()
        -- Initial queue population
        local allPets = LocalData:Get().Pets or {}
        for _, petId in pairs(selectedPetIds) do
            local pet
            for _, p in pairs(allPets) do
                if p.Id == petId then pet = p; break end
            end
            if pet and not hasDesiredEnchant(pet, targetEnchants, targetLevel) then
                table.insert(rerollQueue, petId)
            end
        end

        while rerolling do
            if #rerollQueue > 0 then
                local currentPetId = table.remove(rerollQueue, 1)
                StatusLabel:SetText("🔁 Rerolling pet ID: " .. tostring(currentPetId):sub(1, 8))
                RemoteFunction:InvokeServer("RerollEnchants", currentPetId, "Gems")
                
                -- Check the result without waiting, then requeue if necessary
                local pet
                for _, p in pairs(LocalData:Get().Pets or {}) do if p.Id == currentPetId then pet = p; break end end
                if pet and not hasDesiredEnchant(pet, targetEnchants, targetLevel) then
                    table.insert(rerollQueue, currentPetId) -- Put it at the back of the line
                end
            else
                StatusLabel:SetText("✅ All selected pets have a desired enchant. Monitoring...")
                task.wait(2.0) -- Wait before monitoring
                
                -- Monitor for any pets that lost the enchant
                for _, petId in pairs(selectedPetIds) do
                    local pet
                    for _, p in pairs(LocalData:Get().Pets or {}) do if p.Id == petId then pet = p; break end end
                    if pet and not hasDesiredEnchant(pet, targetEnchants, targetLevel) then
                        StatusLabel:SetText("⚠️ Pet " .. pet.Name .. " lost enchant. Re-queuing...")
                        table.insert(rerollQueue, pet.Id)
                    end
                end
            end
            task.wait(0.4) -- Delay between actions
        end
    end)()
end

-- Function to stop the process
local function stopRerollProcess()
    rerolling = false
    StatusLabel:SetText("⏹️ Reroll stopped by user.")
end

--// =================================================================================
--// Part 5: Final UI Connections
--// =================================================================================

-- Define the toggle here now that its functions exist
EnchantToggle = SettingsSection:AddToggle("EnchantToggle", {
    Text = "Start Enchanting",
    Default = false,
    Callback = function(toggledOn)
        if toggledOn then
            EnchantToggle:SetText("Stop Enchanting")
            startRerollProcess()
        else
            EnchantToggle:SetText("Start Enchanting")
            stopRerollProcess()
        end
    end,
})

-- Initial setup call after a brief delay for the game to load
task.wait(2)
updatePetList()
