-- Minimalny loader diagnostyczny (bez emotek)
local API_BASE_URL = "https://tds-key-backend.onrender.com"
local ENCRYPTION_KEY = "MojeTajneHasloSzyfrujace123"
local CONFIG_FILE = "ADS_Config.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function log(msg)
    print("[LOADER] " .. tostring(msg))
end

local function getHWID()
    local success, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success and hwid and hwid ~= "" then
        return hwid
    end
    -- fallback
    local fallback = tostring(math.floor(tonumber(tostring({}):match("0x(%x+)")) or 0))
    log("HWID fallback: " .. fallback)
    return fallback
end

local function loadKeyFromConfig()
    if not isfile or not readfile then
        log("isfile/readfile niedostepne")
        return nil
    end
    if not isfile(CONFIG_FILE) then
        log("Plik " .. CONFIG_FILE .. " nie istnieje")
        return nil
    end
    local success, content = pcall(function() return readfile(CONFIG_FILE) end)
    if not success then
        log("Nie udalo sie odczytac pliku")
        return nil
    end
    local data = HttpService:JSONDecode(content)
    if data and data.key then
        return data.key
    end
    return nil
end

local function saveKeyToConfig(key)
    if not writefile then
        log("writefile niedostepne")
        return
    end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({key = key}))
        log("Zapisano klucz: " .. key)
    end)
end

local function verifyKey(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/verify?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    log("Weryfikacja: " .. url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then
        log("Blad polaczenia: " .. tostring(response))
        return false, "Blad polaczenia"
    end
    log("Odpowiedz API: " .. response)
    local data = HttpService:JSONDecode(response)
    if data.success then
        return true, nil, data.expiresAt
    else
        return false, data.error or "Nieznany blad"
    end
end

local function decryptBase64(encryptedBase64, key)
    local decoded = HttpService:Base64Decode(encryptedBase64)
    local b = {}
    for i = 1, #decoded do
        local k = key:byte((i - 1) % #key + 1)
        b[i] = string.char(decoded:byte(i) ~ k)
    end
    return table.concat(b)
end

local function fetchEncryptedScript(key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/get-script?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(hwid)
    log("Pobieranie skryptu: " .. url)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then
        error("Nie udalo sie pobrac skryptu: " .. tostring(response))
    end
    if response:sub(1,1) == "{" then
        local data = HttpService:JSONDecode(response)
        error("Blad serwera: " .. (data.error or "nieznany"))
    end
    return response
end

local function main()
    log("=== START ===")
    
    local key = loadKeyFromConfig()
    if key then
        log("Zaladowano klucz: " .. key)
        local ok, msg = verifyKey(key)
        if ok then
            log("Klucz poprawny")
        else
            log("Klucz nieprawidlowy: " .. tostring(msg))
            key = nil
        end
    end
    
    if not key then
        log("Brak klucza. Wpisz go recznie (testowo) w konsoli: _G.KEY = 'TDS-...' i uruchom ponownie.")
        return
    end
    
    log("Pobieranie zaszyfrowanego skryptu...")
    local encrypted = fetchEncryptedScript(key)
    log("Deszyfrowanie...")
    local decrypted = decryptBase64(encrypted, ENCRYPTION_KEY)
    log("Uruchamianie skryptu...")
    local fn, err = loadstring(decrypted)
    if not fn then
        error("Blad skladni: " .. err)
    end
    fn()
end

local ok, err = pcall(main)
if not ok then
    log("KRYTYCZNY BLAD: " .. tostring(err))
end
