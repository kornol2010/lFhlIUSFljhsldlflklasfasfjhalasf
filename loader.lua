-- ==================== LOADER (CICHY, ELEGANCKI GUI) ====================
local API_BASE_URL = "https://tds-key-backend.onrender.com"   -- ZMIEN NA SWOJ
local CONFIG_FILE = "ADS_Config.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Funkcje pomocnicze bez logow
local function readConfig()
    if not isfile or not readfile then return nil end
    if not isfile(CONFIG_FILE) then return nil end
    local success, content = pcall(function() return readfile(CONFIG_FILE) end)
    if not success then return nil end
    local data = HttpService:JSONDecode(content)
    return data and data.key
end

local function writeConfig(key)
    if not writefile then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({key = key}))
    end)
end

local function deleteConfig()
    if not delfile then return end
    pcall(function() delfile(CONFIG_FILE) end)
end

local function getHWID()
    local success, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success and hwid and hwid ~= "" then return hwid end
    return tostring(math.floor(tonumber(tostring({}):match("0x(%x+)")) or 0))
end

local function verifyKey(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/verify?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then return false, "Blad polaczenia" end
    local data = HttpService:JSONDecode(response)
    if data.success then
        return true
    else
        return false, data.error or "Nieznany blad"
    end
end

local function fetchScriptUrl(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/get-script?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then error("Nie udalo sie pobrac URL skryptu") end
    local data = HttpService:JSONDecode(response)
    if data.success and data.scriptUrl then
        return data.scriptUrl
    else
        error(data.error or "Nieznany blad")
    end
end

-- Eleganckie, przezroczyste GUI
local function showKeyPrompt()
    local screen = Instance.new("ScreenGui")
    screen.Name = "KeyPrompt"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = game:GetService("CoreGui")

    local background = Instance.new("Frame")
    background.Size = UDim2.new(0, 320, 0, 180)
    background.Position = UDim2.new(0.5, -160, 0.5, -90)
    background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    background.BackgroundTransparency = 0.15
    background.BorderSizePixel = 0
    background.Parent = screen
    Instance.new("UICorner", background).CornerRadius = UDim.new(0, 12)

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084" -- biały okrągły gradient
    glow.ImageColor3 = Color3.fromRGB(100, 150, 255)
    glow.ImageTransparency = 0.7
    glow.Parent = background
    glow.ZIndex = 0

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Weryfikacja klucza"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = background

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, 0, 0, 20)
    desc.Position = UDim2.new(0, 0, 0, 55)
    desc.BackgroundTransparency = 1
    desc.Text = "Wprowadz swoj klucz licencyjny"
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.Parent = background

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -40, 0, 35)
    textBox.Position = UDim2.new(0, 20, 0, 80)
    textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BackgroundTransparency = 0.85
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "TDS-XXXX-XXXX"
    textBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 16
    textBox.ClearTextOnFocus = false
    textBox.Parent = background
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 35)
    button.Position = UDim2.new(0.5, -60, 0, 130)
    button.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "ZWERYFIKUJ"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = background
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 165)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 120, 120)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = background

    local enteredKey = nil
    local finished = false

    button.MouseButton1Click:Connect(function()
        local rawKey = textBox.Text:gsub("%s+", ""):upper()
        if rawKey == "" then
            status.Text = "Wpisz klucz"
            return
        end
        status.Text = "Weryfikacja..."
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        button.Text = "SPRAWDZAM..."
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 120)

        local ok, err = verifyKey(rawKey)
        if ok then
            status.Text = "Klucz poprawny. Laduje..."
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            enteredKey = rawKey
            finished = true
            writeConfig(rawKey)
            wait(1)
            screen:Destroy()
        else
            status.Text = "Blad: " .. (err or "nieznany")
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
            button.Text = "ZWERYFIKUJ"
            button.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
        end
    end)

    repeat wait(0.2) until finished or not screen.Parent
    return enteredKey
end

-- Glowna funkcja
local function main()
    local key = readConfig()

    if key then
        local ok, err = verifyKey(key)
        if not ok then
            -- Klucz nieprawidlowy lub wygasl - usun z pliku
            deleteConfig()
            key = nil
        end
    end

    if not key then
        key = showKeyPrompt()
        if not key then
            return -- uzytkownik zamknal okno
        end
    end

    local scriptUrl = fetchScriptUrl(key)
    local scriptContent = game:HttpGet(scriptUrl)
    loadstring(scriptContent)()
end

local success, err = pcall(main)
if not success then
    -- Cicha obsluga bledu - mozna ewentualnie pokazac komunikat w GUI
    warn("Loader error: " .. tostring(err))
end
