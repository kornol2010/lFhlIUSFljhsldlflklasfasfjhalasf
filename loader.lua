-- ==================== LOADER (BEZPIECZNY, ADS_CONFIG) ====================
local API_BASE_URL = "https://tds-key-backend.onrender.com"   -- TWÓJ URL
local ENCRYPTION_KEY = "MojeTajneHasloSzyfrujace123"          -- ten sam co w backendzie
local CONFIG_FILE = "ADS_Config.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("🔵 Loader started")

-- ===== FUNKCJE POMOCNICZE =====
local function getHWID()
    local success, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success and hwid ~= "" then return hwid end
    -- Fallback
    local fallback = tostring(math.floor(tonumber(tostring({}):match("0x(%x+)")) or 0))
    print("HWID fallback:", fallback)
    return fallback
end

local function loadKeyFromConfig()
    if not isfile or not readfile or not isfile(CONFIG_FILE) then
        print("Plik konfiguracyjny nie istnieje")
        return nil
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if success and data and data.key then
        print("Odczytano klucz z pliku:", data.key)
        return data.key
    end
    print("Nieprawidłowy format pliku konfiguracyjnego")
    return nil
end

local function saveKeyToConfig(key)
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({key = key}))
        print("Zapisano klucz do pliku:", key)
    end)
end

local function verifyKey(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/verify?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    print("Weryfikacja klucza:", url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then
        print("Błąd połączenia przy weryfikacji:", response)
        return false, "Błąd połączenia"
    end
    print("Odpowiedź API:", response)
    local data = HttpService:JSONDecode(response)
    if data.success then
        return true, nil, data.expiresAt
    else
        return false, data.error or "Nieznany błąd"
    end
end

-- ===== DESZYFROWANIE XOR (base64) =====
local function decryptBase64(encryptedBase64, key)
    local data = encryptedBase64:gsub("%s", "")
    local decoded = HttpService:Base64Decode(data)
    local b = {}
    for i = 1, #decoded do
        local k = key:byte((i - 1) % #key + 1)
        b[i] = string.char(decoded:byte(i) ~ k)
    end
    return table.concat(b)
end

-- ===== GUI LOGOWANIA =====
local function showLoginGUI()
    print("Wyświetlam GUI logowania")
    local screen = Instance.new("ScreenGui")
    screen.Name = "KeyLogin"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔑 Wprowadź klucz licencyjny"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -40, 0, 35)
    textBox.Position = UDim2.new(0, 20, 0, 50)
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
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
    button.Position = UDim2.new(0.5, -50, 0, 100)
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Sprawdź"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 130)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = frame

    local success = false
    local enteredKey = nil

    button.MouseButton1Click:Connect(function()
        local key = textBox.Text:gsub("%s+", ""):upper()
        if key == "" then status.Text = "❌ Wpisz klucz!"; return end
        status.Text = "⏳ Weryfikacja..."
        button.Text = "Sprawdzam..."
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

        local ok, msg = verifyKey(key)
        if ok then
            status.Text = "✅ Klucz poprawny! Pobieranie skryptu..."
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            success = true
            enteredKey = key
            saveKeyToConfig(key)
            wait(1)
            screen:Destroy()
        else
            status.Text = "❌ " .. msg
            button.Text = "Sprawdź"
            button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        end
    end)

    repeat wait(0.2) until success or not screen.Parent
    return enteredKey
end

-- ===== POBIERANIE SKRYPTU Z API =====
local function fetchEncryptedScript(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/get-script?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    print("Pobieranie zaszyfrowanego skryptu:", url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then
        error("Nie udało się pobrać skryptu: " .. tostring(response))
    end
    -- Sprawdź, czy odpowiedź to JSON z błędem
    if response:sub(1,1) == "{" then
        local data = HttpService:JSONDecode(response)
        error("Błąd serwera: " .. (data.error or "nieznany"))
    end
    return response
end

-- ===== GŁÓWNA LOGIKA =====
local function main()
    print("🔍 Sprawdzam zapisany klucz w ADS_Config.json")
    local key = loadKeyFromConfig()

    if key then
        print("Znaleziono klucz, weryfikuję...")
        local ok, msg = verifyKey(key)
        if ok then
            print("✅ Klucz poprawny!")
        else
            print("❌ Klucz nieprawidłowy:", msg)
            key = nil
        end
    end

    if not key then
        print("Brak klucza, pokazuję GUI...")
        key = showLoginGUI()
        if not key then
            error("Nie wprowadzono poprawnego klucza. Skrypt zatrzymany.")
        end
    end

    -- Pobierz zaszyfrowany skrypt z API
    print("📥 Pobieranie skryptu przez API...")
    local encryptedBase64 = fetchEncryptedScript(key)

    -- Deszyfruj
    print("🔓 Deszyfrowanie...")
    local decrypted = decryptBase64(encryptedBase64, ENCRYPTION_KEY)

    -- Wykonaj
    local chunk, err = loadstring(decrypted)
    if not chunk then
        error("Błąd składni w skrypcie: " .. err)
    end
    print("🚀 Uruchamianie głównego skryptu...")
    chunk()
end

-- Start
local success, err = pcall(main)
if not success then
    warn("Loader error:", err)
    -- Opcjonalnie pokaż błąd w GUI
    local screen = Instance.new("ScreenGui")
    screen.Name = "KeyError"
    screen.Parent = game:GetService("CoreGui")
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 100)
    label.Position = UDim2.new(0.5, -150, 0.5, -50)
    label.BackgroundColor3 = Color3.fromRGB(30,30,40)
    label.TextColor3 = Color3.fromRGB(255,100,100)
    label.Text = "Błąd loadera:\n" .. tostring(err)
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.Parent = screen
    Instance.new("UICorner", label).CornerRadius = UDim.new(0,8)
end
