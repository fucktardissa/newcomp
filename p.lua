local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Enchant Reroller",
    SubTitle = "by ",
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

-- Currency dropdown
local CurrencyDropdown = Tabs.Main:AddDropdown("CurrencyType", {
    Title = "Currency",
    Values = {"Gems", "Diamonds", "Tokens"},
    Multi = false,
    Default = "Gems"
})

-- Pet dropdown (example pet list, replace with your LocalData later)
local PetDropdown = Tabs.Main:AddDropdown("SelectedPet", {
    Title = "Pet",
    Values = {"Pixel Demon", "Huge Cat", "Golden Dragon"},
    Multi = false,
    Default = nil
})

-- Reroll button
Tabs.Main:AddButton({
    Title = "Reroll Enchants",
    Description = "Click to reroll selected pet using selected currency.",
    Callback = function()
        local pet = Options.SelectedPet.Value
        local currency = Options.CurrencyType.Value
        if not pet then
            Fluent:Notify({
                Title = "Error",
                Content = "No pet selected!",
                Duration = 3
            })
            return
        end

        print("Sending reroll request for:", pet, "using", currency)
        -- Put RemoteFunction logic here later
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Enchant Reroller",
    Content = "UI loaded!",
    Duration = 5
})
