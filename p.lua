--[[
    Title: Enchant Reroller (Fluent Edition)
    Description: A full-featured pet enchant reroller built with the Fluent UI library.
    Version: 3.0
    Update: Now finds pets by scanning Workspace and checking attributes.
]]

--// =================================================================================
--// Part 1: Setup & Services
--// =================================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

local rerolling = false

--// =================================================================================
--// Part 2: Fluent UI Initialization
--// =================================================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "v3.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(460, 550),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://10222013164" })
local PetSection = MainTab:AddSection("Pet Selection")
local SettingsSection = MainTab:AddSection("Settings & Control")

--// =================================================================================
--// Part 3: UI Element Definitions
--// =================================================================================

-- Pet Selection UI
local petDataMap = {}
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
SettingsSection:AddInput("EnchantLevel", {
    Title = "Enchant Level",
    Placeholder = "e.g., 9",
    Default = "",
})
local StatusLabel = SettingsSection:AddLabel({ Text = "Status: Waiting..." })
local EnchantToggle

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

-- NEW: Finds pets by scanning Workspace attributes
function updatePetList()
    local petsForDropdown = {}
    petDataMap = {}
    local petsFolder = game:GetService("Workspace"):WaitForChild("Markers"):WaitForChild("Pets")
    if not petsFolder then
        print("Could not find the Pets marker folder.")
        return
    end

    for _, petFolder in ipairs(petsFolder:GetChildren()) do
        local ownerId = petFolder:GetAttribute("OwnerId")
        if ownerId and ownerId == LocalPlayer.UserId then
            local petId = petFolder.Name
            local petName = petFolder:GetAttribute("Name") or "Unknown"
            local isShiny = petFolder:GetAttribute("Shiny") or false
            local isMythic = petFolder:GetAttribute("Mythic") or false

            local prefix = ""
            if isShiny and isMythic then
                prefix = "Shiny Mythic "
            elseif isShiny then
                prefix = "Shiny "
            elseif isMythic then
                prefix = "Mythic "
            end

            local finalName = prefix .. petName
            local displayName = string.format("%s [%s]", finalName, tostring(petId):sub(1, 5))

            table.insert(petsForDropdown, displayName)
            petDataMap[displayName] = petId
        end
    end

    PetDropdown:SetValues(petsForDropdown)
    if #petsForDropdown > 0 then
        Fluent:Notify({ Title = "Success", Content = "Found " .. #petsForDropdown .. " of your pets.", Duration = 4 })
    else
        Fluent:Notify({ Title = "No Pets Found", Content = "Could not find any pets owned by you in Workspace.", Duration = 6 })
    end
end

local function startRerollProcess()
    local targetEnchants = Fluent.Options.EnchantDropdown.Value
    local targetLevel = tonumber(Fluent.Options.EnchantLevel.Value)
    local rerollQueue = {}

    local selectedPetIds = {}
    for _, displayName in pairs(Fluent.Options.PetDropdown.Value) do
        if petDataMap[displayName] then table.insert(selectedPetIds, petDataMap[displayName]) end
    end

    if #selectedPetIds == 0 or #targetEnchants == 0 or not targetLevel then
        StatusLabel:SetText("⚠️ Select pets, enchants, and a level.")
        EnchantToggle:Set({ Value = false, Silent = true })
        EnchantToggle:SetText("Start Enchanting")
        return
    end

    rerolling = true
    StatusLabel:SetText("⏳ Initializing...")

    coroutine.wrap(function()
        -- Note: This part of the logic still relies on the original reroll method.
        -- It queues up the PET IDs, not the full pet objects from Workspace.
        -- The game's remote function should handle finding the pet from its ID.
        for _, petId in pairs(selectedPetIds) do
            table.insert(rerollQueue, petId)
        end

        while rerolling do
            if #rerollQueue > 0 then
                local currentPetId = table.remove(rerollQueue, 1)
                StatusLabel:SetText("🔁 Rerolling pet ID: " .. tostring(currentPetId):sub(1, 8))
                RemoteFunction:InvokeServer("RerollEnchants", currentPetId, "Gems")

                -- Since we can't reliably check the enchant status from workspace attributes after a reroll,
                -- we will simply re-queue it. A small delay is added to prevent instant re-rolls.
                task.wait(0.5)
                table.insert(rerollQueue, currentPetId)
            else
                rerolling = false -- No pets were queued, stop the process.
                StatusLabel:SetText("⚠️ No pets needed rerolling initially.")
                EnchantToggle:Set({ Value = false, Silent = true })
                EnchantToggle:SetText("Start Enchanting")
            end
        end
    end)()
end

local function stopRerollProcess()
    rerolling = false
    StatusLabel:SetText("⏹️ Reroll stopped by user.")
end

--// =================================================================================
--// Part 5: Final UI Connections
--// =================================================================================

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

task.wait(2)
updatePetList()
