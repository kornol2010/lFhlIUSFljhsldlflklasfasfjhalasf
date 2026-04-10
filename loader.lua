-- ==================== LOADER (JEDEN PLIK) ====================
local API_VERIFY_URL = "https://tds-key-backend.onrender.com/api/verify"
local ENCRYPTION_KEY = "MojeTajneHasloSzyfrujace123"  -- MUSI być taki sam jak w backendzie!
local CONFIG_FILE = "ADS_Config.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== FUNKCJE POMOCNICZE =====
local function getHWID()
    local success, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success and hwid ~= "" then return hwid end
    return tostring(math.floor(tonumber(tostring({}):match("0x(%x+)")) or 0))
end

local function saveKey(key)
    local data = { key = key }
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function loadKeyFromFile()
    if not isfile or not readfile or not isfile(CONFIG_FILE) then return nil end
    local success, content = pcall(function() return readfile(CONFIG_FILE) end)
    if not success then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if ok and data and data.key then return data.key end
    return nil
end

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

-- ===== WYSYŁANIE ZAPYTANIA O WERYFIKACJĘ (z URL) =====
local function verifyKeyAndGetURL(key)
    local hwid = getHWID()
    local url = API_VERIFY_URL .. "?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then return false, "Błąd połączenia" end
    local data = HttpService:JSONDecode(response)
    if data.success and data.url then
        return true, data.url
    else
        return false, data.error or "Nieznany błąd"
    end
end

-- ===== GUI LOGOWANIA (uproszczone) =====
local function showLoginGUI()
    local screen = Instance.new("ScreenGui")
    screen.Name = "KeyLogin"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 130)
    frame.Position = UDim2.new(0.5, -150, 0.5, -65)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screen
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔑 Wprowadź klucz licencyjny"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -40, 0, 30)
    textBox.Position = UDim2.new(0, 20, 0, 45)
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "TDS-XXXX-XXXX"
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 14
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 4)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 28)
    button.Position = UDim2.new(0.5, -50, 0, 85)
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "Sprawdź"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 110)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = frame

    local success = false
    local scriptURL = nil

    button.MouseButton1Click:Connect(function()
        local key = textBox.Text:gsub("%s+", ""):upper()
        if key == "" then status.Text = "❌ Wpisz klucz!"; return end
        status.Text = "⏳ Weryfikacja..."
        button.Text = "Sprawdzam..."
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

        local ok, urlOrMsg = verifyKeyAndGetURL(key)
        if ok then
            status.Text = "✅ Klucz poprawny! Ładowanie..."
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            success = true
            scriptURL = urlOrMsg
            saveKey(key)  -- zapisz klucz w ADS_Config.json
            wait(1)
            screen:Destroy()
        else
            status.Text = "❌ " .. urlOrMsg
            button.Text = "Sprawdź"
            button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        end
    end)

    repeat wait(0.2) until success or not screen.Parent
    return scriptURL
end

-- ===== GŁÓWNA LOGIKA =====
local function main()
    local key = loadKeyFromFile()
    local scriptURL = nil

    if key then
        local ok, urlOrMsg = verifyKeyAndGetURL(key)
        if ok then
            print("✅ Klucz z pliku poprawny.")
            scriptURL = urlOrMsg
        else
            print("⚠️ Klucz w pliku nieprawidłowy: " .. urlOrMsg)
            key = nil
        end
    end

    if not key then
        scriptURL = showLoginGUI()
        if not scriptURL then error("Nie udało się pobrać URL skryptu.") end
    end

    -- Odszyfruj URL i pobierz właściwy skrypt
    local realURL = decryptBase64(scriptURL, ENCRYPTION_KEY)
    print("📥 Pobieranie skryptu z: " .. realURL)
    local success, mainScript = pcall(function() return game:HttpGet(realURL) end)
    if not success then error("Nie udało się pobrać głównego skryptu.") end

    local chunk, err = loadstring(mainScript)
    if not chunk then error("Błąd składni w głównym skrypcie: " .. err) end
    chunk()
end

task.spawn(main)
