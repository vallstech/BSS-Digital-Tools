local players = game:GetService("Players");
local httpService = game:GetService("HttpService");

local rawmain = "https://raw.githubusercontent.com/vallstech/BSS-Digital-Tools/refs/heads/main/";
local clientstat = require(game.ReplicatedStorage.ClientStatCache);
local ITEMS = loadstring(game:HttpGet(rawmain.."src/info.luau"))();

local CONFIG = {
    ["settings"] = {
        showcraft = true,
        showprice = true,
        left = true,
        webhook = "",
    },
    ["funcs"] = {};
}

local imgui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()
local Window = imgui:CreateWindow({
	Title = "💿 Digital Tools v1.0",
	Size = UDim2.new(0, 346, 0, 235),
    NoClose = false
});
Window:Center();
Window.Content.TitleBar.Close.Icon.Image = "rbxassetid://8511577140";
local tabs = {
    items = {tab = Window:CreateTab({Name = "Items"}),},
    webhook = { tab = Window:CreateTab({Name = "Webhook"})},
    settings = {tab = Window:CreateTab({Name = "Settings"})},
    credits = {tab = Window:CreateTab({Name = "Credits"})}
};
tabs.items.headers = {
    masks = tabs.items.tab:CollapsingHeader({Title = "🎭 Masks"}),
    tools = tabs.items.tab:CollapsingHeader({Title = "⚒️ Tools"}),
    bags = tabs.items.tab:CollapsingHeader({Title = "🎒 Bags"}),
    belts = tabs.items.tab:CollapsingHeader({Title = "🎗 Belts"}),
    boots = tabs.items.tab:CollapsingHeader({Title = "👢 Boots"})
};
tabs.webhook.headers = {
    general = tabs.webhook.tab:CollapsingHeader({Title = "General", Open = true})
};
tabs.settings.headers = {
    general = tabs.settings.tab:CollapsingHeader({Title = "General", Open = true}),
};

-- SHIT FUNCTIONS
local funcs = {};
function funcs.formatNum(num: number): number
    local str = tostring(num);
	return (str:reverse():gsub("...", "%0,", math.floor((#str - 1) / 3)):reverse())
end
function funcs.roundDown(num, decimalPlaces)
    local mult = 10^decimalPlaces;
    return math.floor(num * mult) / mult;
end
function funcs.percent(a: number, b: number): number
    if type(a) ~= "number" and type(b) ~= "number" then return nil end
    return (a / b) * 100;
end
function funcs.getCoreStat(stat: string)
    return players.LocalPlayer.CoreStats[stat];
end
function funcs.getItem(name: string): number
    local gsubed = name:gsub(" ", "");
    local count = clientstat:Get({ "Eggs", gsubed });
    if count == nil then
        local res = 0;
        if name == "Honey" then
            return funcs.getCoreStat(name).Value;
        end
        return 0;
    end
    return count;
end
function funcs.progress(info: table): number -- info {Honey, Ingredients}
    local weNeedTotal = 100;
    local numTotal = 0;

    local percent = 0;
    percent = math.floor(funcs.percent(funcs.getCoreStat("Honey").Value, info.Honey));
    numTotal += if percent > 100 then 100 else percent;

    for ingName, ingValue in info.Ingredients do
        percent = math.floor(funcs.percent(funcs.getItem(ingName), ingValue)); -- current
        weNeedTotal += 100;
        numTotal += if percent > 100 then 100 else percent;
    end

    return funcs.percent(numTotal, weNeedTotal);
end

-- MAIN UI FUNCTIONS
local uiFuncs = {};
function uiFuncs.createPrice(parent, item): nil -- item = {Name, Count}
    if ITEMS.Shops[item.Name] ~= nil and CONFIG.settings.showprice then
        local priceNode = parent:TreeNode({Title = "💸 Price"});
        local shopItem = ITEMS.Shops[item.Name];
        local price = math.ceil(item.Count / shopItem.Count) * shopItem.Price;
        
        local currency = shopItem.Currency;
        local currencyValue = funcs.getItem(currency);
        local icon = ITEMS.CurrencyIcons[currency];
        local text = icon..' '..currency..": "..funcs.formatNum(currencyValue).." / "..funcs.formatNum(price);
        print(item.Name, item.Count, price);
        print(item.Count.." / "..shopItem.Count.." = "..(item.Count / shopItem.Count).." -> "..math.ceil(item.Count / shopItem.Count).." * "..shopItem.Price.." = "..price);
        local label = priceNode:Label({Text = text});
        if currencyValue >= price then label.TextColor3 = Color3.fromRGB(0, 255, 0) end;
    end
end
function uiFuncs.createCraft(parent, item: table) -- item = {Name, Count}
    if ITEMS.Blender[item.Name] ~= nil and CONFIG.settings.showcraft then
        local craftNode = parent:TreeNode({Title = "❓ Craft"});
        for ingName, ingValue in ITEMS.Blender[item.Name] do
            local craftCount = funcs.getItem(ingName);
            local dif = item.Count - funcs.getItem(item.Name);
            local label = craftNode:Label({Text = ingName..": "..funcs.formatNum(craftCount).." / "..funcs.formatNum(ingValue*dif)});

            if craftCount >= ingValue*dif then label.TextColor3 = Color3.fromRGB(0, 255, 0) end;
            uiFuncs.createCraft(craftNode, {Name = ingName, Count = ingValue*dif});
            uiFuncs.createPrice(craftNode, {Name = ingName, Count = ingValue*dif});
        end 
    end
end
function uiFuncs.createIngredients(parent, item: table): nil
    for ingName, ingValue in item.Ingredients do
        local itemCount = funcs.getItem(ingName); -- item count
        local left = ingValue - itemCount;
        local leftText = if CONFIG.settings.left then " (Left: "..funcs.formatNum(left)..")" else "";
        local text = ingName..": "..funcs.formatNum(itemCount).." / "..funcs.formatNum(ingValue)..leftText;
        local label = parent:Label({Text = text}); -- goal
        if itemCount >= ingValue then label.TextColor3 = Color3.fromRGB(0, 255, 0) end;
        uiFuncs.createCraft(parent, {Name = ingName, Count = ingValue});
        uiFuncs.createPrice(parent, {Name = ingName, Count = ingValue});
    end
end
function uiFuncs.createItem(item: table): nil
    local playerHoney = funcs.getCoreStat("Honey").Value;

    local header = tabs.items.headers[item.Type]:CollapsingHeader({Title = item.Name});
    local progress = funcs.progress({
        Honey = item.Honey,
        Ingredients = item.Ingredients
    });
    local progressLabel: TextLabel = header:Label({Text = "⚙ Progress: "..funcs.roundDown(progress, 2).."%"});
    local honeyLabel = header:Label({Text = "🍯 Honey: "..funcs.formatNum(playerHoney).." / "..funcs.formatNum(item.Honey)});
    header:Checkbox({
    	Label = "Goal", Value = false,
    	Callback = function(self, Value)
    		
    	end,
    })
    if progress >= 100 then progressLabel.TextColor3 = Color3.fromRGB(0, 255, 0) end;
    if playerHoney >= item.Honey then honeyLabel.TextColor3 = Color3.fromRGB(0, 255, 0) end;
    
    local node = header:TreeNode({Title = "❓ Ingredients"});
    uiFuncs.createIngredients(node, item);

    return header;
end

-- OTHER UI FUNCTIONS
local uis = {};
function uiFuncs.updateUi()
    for _, v in uis do
        v:Destroy();
    end
    for _, v in ITEMS.Masks do table.insert(uis, uiFuncs.createItem(v)) end
    for _, v in ITEMS.Tools do table.insert(uis, uiFuncs.createItem(v)) end
    for _, v in ITEMS.Bags do table.insert(uis, uiFuncs.createItem(v)) end
    for _, v in ITEMS.Belts do table.insert(uis, uiFuncs.createItem(v)) end
    for _, v in ITEMS.Boots do table.insert(uis, uiFuncs.createItem(v)) end
end

function uiFuncs.createSettings()
    local general = tabs.settings.headers.general;
    general:Button({Text = "Refresh Information", Callback = function()
        uiFuncs.updateUi()
    end});
    general:Separator();

    general:Checkbox({
    	Label = "Show Item Craft", Value = CONFIG.settings.showcraft,
    	Callback = function(self, Value)
            CONFIG.settings.showcraft = Value;
            CONFIG.funcs.saveConfig();
    	end,
    });
    general:Checkbox({
    	Label = "Show Item Price", Value = CONFIG.settings.showprice,
    	Callback = function(self, Value)
    		CONFIG.settings.showprice = Value;
            CONFIG.funcs.saveConfig();
    	end,
    });
    general:Checkbox({
    	Label = "Show Items Left", Value = CONFIG.settings.left,
    	Callback = function(self, Value)
    		CONFIG.settings.left = Value;
            CONFIG.funcs.saveConfig();
    	end,
    });
end
function uiFuncs.createWebhook(): nil
    local general = tabs.webhook.headers.general;
    general:Label({Text = "‼‼‼ NOT WORKING (W.I.P) ‼‼‼", TextColor3 = Color3.fromRGB(255,0,0)});
    general:Label({Text = "🔗 Webhook URL"});
    local input = general:InputText({
        PlaceHolder = "https://discord.com/api/webhooks/...",
        Title = "",
        Value = CONFIG.settings.webhook,
        Callback = function(self, Value)
            CONFIG.settings.webhook = Value;
            CONFIG.funcs.saveConfig();
        end,
    });
    general:Button({Text = "Send Test", Callback = function()

    end})
end
function uiFuncs.createCredits()
    local tab = tabs.credits.tab;
    local link = "github.com/vallstech/BSS-Digital-Tools";
    tab:Image({Image = 109435679481703, Size = UDim2.fromOffset(200, 50)});
    tab:Label({Text = "Made by @vallstech (all soc. media)"});
    tab:Separator();

    tab:Label({Text = "Github (opensource):"});
    tab:Label({Text = link, TextColor3 = Color3.fromRGB(150, 190, 255)});
    tab:Button({Text = "Copy Link", Callback = function()
        setclipboard("https://"..link);
    end})
end

-- CONFIG FUNCTIONS
function CONFIG.funcs.saveConfig()
    makefolder("BSSDigitalTools");
    writefile("BSSDigitalTools/config.json", httpService:JSONEncode(CONFIG.settings));
end
function CONFIG.funcs.loadConfig()
    local configPath = "BSSDigitalTools/config.json";
    if isfile(configPath) then
        local data = httpService:JSONDecode(readfile(configPath));
        for index, value in data do
            if CONFIG.settings[index] ~= nil then
                print("Loaded config "..index..": "..tostring(value));
                CONFIG.settings[index] = value;
            end
        end
    end
end

CONFIG.funcs.loadConfig();
uiFuncs.updateUi();
uiFuncs.createWebhook();
uiFuncs.createSettings();
uiFuncs.createCredits();
Window:ShowTab(tabs.credits.tab);
