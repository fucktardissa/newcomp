--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Fluent UI Library (adjust the path if necessary)
local Fluent = loadstring(game:HttpGet("https://github.com/1-Development/Fluent/releases/latest/download/Fluent.lua"))()
--// Note: The above line fetches the latest version of Fluent. 
--// For production, it's better to save Fluent as a ModuleScript in your game.
--// local Fluent = require(ReplicatedStorage.Fluent)

--// Original Game Services & Variables
local LocalPlayer = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction

--// Configuration
local Enchants = {
    "Looter I", "Looter II", "Looter III", "Looter IV", "Looter V",
    "Bubbler I", "Bubbler II", "Bubbler III", "Bubbler IV", "Bubbler V",
    "Gleaming I", "Gleaming II", "Gleaming III",
    "Team Up I", "Team Up II", "Team Up III", "Team Up IV", "Team Up V",
    "High Roller", "Magnetism", "Infinity", "Secret Hunter", "Ultra Roller",
    "Determination", "Shiny Seeker"
}

local options = {
    SelectedEnchant = Enchants[1],
    RerollToggle = false
}

local selectedPetIds = {}
local petCheckboxes = {}
local rerolling = false

--============================================================================--
--//                                 LOGIC                                  --//
--============================================================================--

--// Helper function to parse enchant string (e.g., "Looter III") into name and level
local function parseEnchant(enchantString)
    local romanMap = { I = 1, II = 2, III = 3, IV = 4, V = 5 }
    local name, roman = enchantString:match("^(.*) (%S+)$")

    if name and romanMap[roman] then
        return name:lower(), romanMap[roman]
    else
        --// Handles enchants without a level, like "High Roller"
        return enchantString:lower(), 1 --// Default level to 1 if not specified
    end
end

--// Checks if a pet has the desired enchant
local function hasDesiredEnchant(pet, id, lvl)
    if not pet or not pet.Enchants then return false end
    for _, enchant in ipairs(pet.Enchants) do
        if enchant.Id == id and enchant.Level == lvl then
            return true
        end
    end
    return false
end

--// The main rerolling coroutine
local rerollCoroutine
local function startRerollLoop()
    rerolling = true
    rerollCoroutine = coroutine.create(function()
        local StatusLabel = Fluent.StatusLabel -- Reference the status label
        
        while rerolling do
            local targetEnchantName, targetEnchantLevel = parseEnchant(options.SelectedEnchant)
            
            if not next(selectedPetIds) then
                StatusLabel:Set("⚠️ Select at least one pet.")
                task.wait(2)
                goto continueLoop
            end
            
            local playerData = LocalData:Get()
            if not playerData or not playerData.Pets then
                StatusLabel:Set("⏳ Waiting for player data...")
                task.wait(1)
                goto continueLoop
            end
            
            local petsToReroll = {}
            --// Find all selected pets that DON'T have the enchant
            for petId, _ in pairs(selectedPetIds) do
                local currentPet
                for _, p in ipairs(playerData.Pets) do
                    if p.Id == petId then
                        currentPet = p
                        break
                    end
                end
                
                if currentPet and not hasDesiredEnchant(currentPet, targetEnchantName, targetEnchantLevel) then
                    table.insert(petsToReroll, currentPet)
                end
            end
            
            if #petsToReroll == 0 then
                StatusLabel:Set("✅ All selected pets have the desired enchant.")
                task.wait(2) -- Check again after 2 seconds
            else
                for _, pet in ipairs(petsToReroll) do
                    if not rerolling then break end -- Stop if toggle is flipped
                    
                    StatusLabel:Set("🔁 Rerolling " .. (pet.Name or pet.Id))
                    RemoteFunction:InvokeServer("RerollEnchants", pet.Id, "Gems")
                    task.wait(0.3) -- Delay between rerolls
                end
            end
            
            ::continueLoop::
            task.wait(0.1) -- Brief pause at the end of each main loop
        end
    end)
    coroutine.resume(rerollCoroutine)
end

local function stopRerollLoop()
    rerolling = false
    if rerollCoroutine and coroutine.status(rerollCoroutine) ~= "dead" then
        --// No direct way to kill, but setting `rerolling` to false will stop the loop
        rerollCoroutine = nil
    end
    Fluent.StatusLabel:Set("⏹️ Reroll stopped. Toggle on to start.")
end


--============================================================================--
--//                                  GUI                                   --//
--============================================================================--

local Window = Fluent:CreateWindow({
    Title = "🔁 Enchant Reroller",
    SubTitle = "by your_name_here",
    Size = UDim2.fromOffset(450, 400),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MainTab = Window:AddTab({ Title = "Reroller", Icon = "rbxassetid://10609232348" })

---
## Controls Section
---

local ControlsSection = MainTab:AddSection("Controls")

ControlsSection:AddDropdown("EnchantDropdown", {
    Title = "Target Enchant",
    Values = Enchants,
    Default = options.SelectedEnchant,
    Callback = function(value)
        options.SelectedEnchant = value
    end
})

ControlsSection:AddToggle("RerollToggle", {
    Title = "Start / Stop Rerolling",
    Default = options.RerollToggle,
    Callback = function(value)
        options.RerollToggle = value
        if value then
            startRerollLoop()
        else
            stopRerollLoop()
        end
    end
})

--// We assign the label to the Fluent object to access it later for updates
Fluent.StatusLabel = ControlsSection:AddLabel("Status", {
    Text = "⏹️ Reroll stopped. Toggle on to start."
})

---
## Pet Selection Section
---

local PetSection = MainTab:AddSection("Pet Selection")
local PetCheckboxesContainer = PetSection:AddScrollbox("PetList", {
    Size = UDim2.new(1, 0, 0, 150),
    CanvasSize = UDim2.new(0,0,0,0) -- Will be auto-sized
})

--// Function to populate/update the pet list with checkboxes
local function updatePetList(filterText)
    filterText = filterText:lower()
    
    --// Clear previous checkboxes
    for _, checkbox in pairs(petCheckboxes) do
        checkbox:Destroy()
    end
    table.clear(petCheckboxes)

    local data = LocalData:Get()
    if not data or not data.Pets then return end

    for _, pet in ipairs(data.Pets) do
        local petName = pet.Name or pet.name or pet._name or "Unknown"
        local petId = pet.Id
        
        --// Filter by search text
        if filterText == "" or petName:lower():find(filterText, 1, true) then
            local checkbox = PetCheckboxesContainer:AddCheckbox(petId, {
                Title = petName,
                Default = selectedPetIds[petId] or false, -- Keep checked state on refresh
                Callback = function(value)
                    selectedPetIds[petId] = value and true or nil
                end
            })
            petCheckboxes[petId] = checkbox
        end
    end
end

PetSection:AddSearchbar("PetSearch", {
    Title = "Search Pets...",
    Default = "",
    Callback = function(text)
        updatePetList(text)
    end
})

--// Initial population & setup periodic refresh
updatePetList("") 
task.spawn(function()
    while task.wait(5) do -- Refresh pet list every 5 seconds
        if Window.Visible then
            local searchbar = PetSection.elements.PetSearch
            updatePetList(searchbar.Value)
        end
    end
end)

--// Finalize the UI
Fluent:Notify({
    Title = "Enchant Reroller",
    Content = "UI Loaded! Press Right CTRL to toggle.",
    Duration = 5
})
