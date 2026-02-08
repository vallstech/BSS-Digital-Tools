local players = game:GetService("Players");

local clientstat = require(game.ReplicatedStorage.ClientStatCache);
local ITEMS = loadstring(game:HttpGet("https://pastebin.com/raw/hkgnzxjJ"))();

local imgui = loadstring(game:HttpGet('https://github.com/depthso/Roblox-ImGUI/raw/main/ImGui.lua'))()
local Window = imgui:CreateWindow({
	Title = "💿 Digital Tools v1.0",
	Size = UDim2.new(0, 346, 0, 235)
});
Window:Center();
local tabs = {
    items = {
        tab = Window:CreateTab({Name = "Items"}),
    },
    webhook = {
        tab = Window:CreateTab({Name = "Webhook"})
    },
    settings = {
        tab = Window:CreateTab({Name = "Settings"})
    }
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
    config = tabs.settings.tab:CollapsingHeader({Title = "Config", Open = true}),
};

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
function funcs.getItem(name: string): number
    local gsubed = name:gsub(" ", "");
    local count = clientstat:Get({ "Eggs", gsubed });
    if count == nil then
        return 0;
    end
    return count;
end
function funcs.getCoreStat(stat: string)
    return players.LocalPlayer.CoreStats[stat];
end
function funcs.clickOnButton(button: GuiButton): nil
    for i, connection in pairs(getconnections(button.MouseButton1Click)) do
        connection:Fire()
    end
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
function funcs.blender(item: string, amount: number): table
    
end

local uiFuncs = {};

function uiFuncs.createCraft(parent, item) -- item = {Name, Count}
    for ingName, ingValue in ITEMS.Blender[item.Name] do
        local craftCount = funcs.getItem(ingName);
        local dif = item.Count - funcs.getItem(item.Name);
        local label = parent:Label({Text = ingName..": "..funcs.formatNum(craftCount).." / "..funcs.formatNum(ingValue*dif)});
        
        if craftCount >= ingValue*dif then label.TextColor3 = Color3.fromRGB(0, 255, 0) end;
        if ITEMS.Blender[ingName] ~= nil then
            local node = parent:TreeNode({Title = "❓ Craft"});
            uiFuncs.createCraft(node, {Name = ingName, Count = ingValue*dif});
        end
    end
end
function uiFuncs.createIngredients(parent, item): nil
    for ingName, ingValue in item.Ingredients do
        local itemCount = funcs.getItem(ingName); -- item count
        local left = ingValue - itemCount;
        local text = ingName..": "..funcs.formatNum(itemCount).." / "..funcs.formatNum(ingValue).." ("..left.." left)";
        local label = parent:Label({Text = text}); -- goal
        if itemCount >= ingValue then label.TextColor3 = Color3.fromRGB(0, 255, 0) end;
        if ITEMS.Blender[ingName] ~= nil then -- если у ПЕРВОГО ингредиента есть крафт (пример cumдроп)
            local craftNode = parent:TreeNode({Title = "❓ Craft"}); -- еще одна нода
            uiFuncs.createCraft(craftNode, {Name = ingName, Count = ingValue});
        end
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
    general:Button({Text = "Refresh", Callback = function()
        uiFuncs.updateUi()
    end})
end
function uiFuncs.createWebhook(): nil
    local general = tabs.webhook.headers.general;
    general:Label({Text = "🔗 Webhook URL"})
    general:InputText({
        PlaceHolder = "https://discord.com/api/webhooks/...",
        Title = ""
    })
    general:Button({Text = "Send Test", Callback = function()
        
    end})
end

uiFuncs.updateUi();
uiFuncs.createWebhook();
uiFuncs.createSettings();
