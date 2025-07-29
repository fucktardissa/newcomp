local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Enchant Reroller",
    SubTitle = "by 2",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "wand-sparkles" }),
}

local Options = Fluent.Options

-- Pull pets from LocalData
local success, PetList = pcall(function()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("LocalData")).Save.Pets
end)

-- Create pet dropdown values
local petDisplayNames = {}
local uuidToDisplayMap = {}
local displayToUuidMap = {}

if success and typeof(PetList) == "table" then
    for uuid, pet in pairs(PetList) do
        local displayName = pet.nk or ("Unknown [" .. uuid:sub(1, 8) .. "]")
        local fullName = displayName .. " (" .. uuid:sub(1, 8) .. ")"
        table.insert(petDisplayNames, fullName)
        uuidToDisplayMap[uuid] = fullName
        displayToUuidMap[fullName] = uuid
    end
else
    table.insert(petDisplayNames, "No pets found")
end

-- Dropdowns
local CurrencyDropdown = Tabs.Main:AddDropdown("CurrencyType", {
    Title = "Currency",
    Values = {"Gems", "Diamonds", "Tokens"},
    Multi = false,
    Default = "Gems"
})

local PetDropdown = Tabs.Main:AddDropdown("SelectedPet", {
    Title = "Pet",
    Values = petDisplayNames,
    Multi = false,
    Default = #petDisplayNames > 0 and petDisplayNames[1] or nil
})

-- Reroll button
Tabs.Main:AddButton({
    Title = "Reroll Enchants",
    Description = "Click to reroll selected pet using selected currency.",
    Callback = function()
        local selectedPetDisplay = Options.SelectedPet.Value
        local currency = Options.CurrencyType.Value
        local uuid = displayToUuidMap[selectedPetDisplay]

        if not uuid then
            Fluent:Notify({
                Title = "Error",
                Content = "Invalid pet selection!",
                Duration = 3
            })
            return
        end

        print("Sending reroll request for pet UUID:", uuid, "with", currency)
        -- Insert RemoteFunction call here
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Enchant Reroller",
    Content = "UI loaded!",
    Duration = 5
})
