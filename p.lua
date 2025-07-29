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

local CurrencyDropdown = Tabs.Main:AddDropdown("CurrencyType", {
    Title = "Currency",
    Values = {"Gems", "Diamonds", "Tokens"},
    Multi = false,
    Default = "Gems"
})

CurrencyDropdown:OnChanged(function(value)
    print("Currency selected:", value)
end)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Enchant Reroller",
    Content = "UI loaded!",
    Duration = 5
})
