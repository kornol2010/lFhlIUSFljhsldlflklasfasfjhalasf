-- Minimalny loader z GUI (bez emotek, bez szyfrowania, bez Base64)
local API_BASE_URL = "https://tds-key-backend.onrender.com"   -- ZMIEN NA SWOJ
local CONFIG_FILE = "ADS_Config.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function log(msg)
    print("[LOADER] " .. tostring(msg))
end

-- Funkcja pomocnicza do zapisu/odczytu (bezpieczna)
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

local function getHWID()
    local success, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success and hwid and hwid ~= "" then return hwid end
    -- Fallback
    return tostring(math.floor(tonumber(tostring({}):match("0x(%x+)")) or 0))
end

local function verifyKey(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/verify?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    log("Weryfikacja: " .. url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then
        return false, "Blad polaczenia"
    end
    log("Odpowiedz: " .. response)
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
    log("Pobieranie URL skryptu: " .. url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then
        error("Nie udalo sie pobrac URL skryptu: " .. tostring(response))
    end
    local data = HttpService:JSONDecode(response)
    if data.success and data.scriptUrl then
        return data.scriptUrl
    else
        error("Blad serwera: " .. (data.error or "nieznany"))
    end
end

-- Proste GUI do wpisania klucza
local function showKeyPrompt()
    log("Tworze GUI...")
    local screen = Instance.new("ScreenGui")
    screen.Name = "KeyPrompt"
    screen.ResetOnSpawn = false
    screen.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 140)
    frame.Position = UDim2.new(0.5, -140, 0.5, -70)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Wprowadz klucz licencyjny"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -30, 0, 35)
    textBox.Position = UDim2.new(0, 15, 0, 45)
    textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "TDS-XXXX-XXXX"
    textBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 14
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 30)
    button.Position = UDim2.new(0.5, -50, 0, 95)
    button.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Sprawdz"
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 125)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.Font = Enum.Font.SourceSans
    status.TextSize = 12
    status.Parent = frame

    local enteredKey = nil
    local finished = false

    button.MouseButton1Click:Connect(function()
        local key = textBox.Text:gsub("%s+", ""):upper()
        if key == "" then
            status.Text = "Wpisz klucz!"
            return
        end
        status.Text = "Weryfikacja..."
        button.Text = "Sprawdzam..."
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

        local ok, err = verifyKey(key)
        if ok then
            status.Text = "Poprawny! Laduje..."
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            enteredKey = key
            finished = true
            writeConfig(key)
            wait(1)
            screen:Destroy()
        else
            status.Text = "Blad: " .. (err or "nieznany")
            button.Text = "Sprawdz"
            button.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
        end
    end)

    repeat
        wait(0.2)
    until finished or not screen.Parent

    return enteredKey
end

-- Glowna logika
local function main()
    log("Start loadera")
    local key = readConfig()

    if key then
        log("Odczytano klucz z pliku: " .. key)
        local ok, err = verifyKey(key)
        if not ok then
            log("Klucz z pliku nieprawidlowy: " .. (err or "?"))
            key = nil
        else
            log("Klucz z pliku poprawny")
        end
    end

    if not key then
        log("Brak klucza - pokazuje GUI")
        key = showKeyPrompt()
        if not key then
            error("Nie wprowadzono klucza")
        end
    end

    log("Pobieram URL skryptu...")
    local scriptUrl = fetchScriptUrl(key)
    log("Pobieram skrypt z: " .. scriptUrl)
    local scriptContent = game:HttpGet(scriptUrl)
    log("Uruchamiam skrypt...")
    loadstring(scriptContent)()
end

local ok, err = pcall(main)
if not ok then
    log("BLAD GLOWNY: " .. tostring(err))
end
