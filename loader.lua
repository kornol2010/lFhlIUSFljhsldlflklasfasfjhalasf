local API_BASE_URL = "https://tds-key-backend.onrender.com"  -- Twój URL
local CONFIG_FILE = "key.json"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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
    if not success then return false, "Connection error" end
    local data = HttpService:JSONDecode(response)
    if data.success then return true
    else return false, data.error or "Unknown error" end
end

local function fetchScript(scriptName, key)
    local hwid = getHWID()
    local url = API_BASE_URL .. "/api/get-script?key=" .. HttpService:UrlEncode(key)
                .. "&hwid=" .. HttpService:UrlEncode(hwid)
                .. "&script=" .. HttpService:UrlEncode(scriptName)
    local success, response = pcall(function() return game:HttpGet(url) end)
    if not success then error("Failed to fetch script") end
    if response:sub(1,1) == "{" then
        local data = HttpService:JSONDecode(response)
        error(data.error or "Unknown error")
    end
    return response
end

local function showKeyPrompt()
    local screen = Instance.new("ScreenGui")
    screen.Name = "KeyPrompt"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = game:GetService("CoreGui")

    local background = Instance.new("Frame")
    background.Size = UDim2.new(0, 320, 0, 180)
    background.Position = UDim2.new(0.5, -160, 0.5, -90)
    background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    background.BackgroundTransparency = 0.1
    background.BorderSizePixel = 0
    background.Parent = screen
    Instance.new("UICorner", background).CornerRadius = UDim.new(0, 12)

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -28, 0, 8)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.Parent = background
    closeButton.MouseButton1Click:Connect(function()
        screen:Destroy()
        pcall(function() error("Closed by user") end)
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Key Verification"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = background

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 20)
    desc.Position = UDim2.new(0, 20, 0, 55)
    desc.BackgroundTransparency = 1
    desc.Text = "Enter your license key"
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.Parent = background

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -40, 0, 35)
    textBox.Position = UDim2.new(0, 20, 0, 80)
    textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    textBox.BackgroundTransparency = 0.3
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 16
    textBox.ClearTextOnFocus = false
    textBox.Text = ""
    textBox.Parent = background
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 0, 35)
    button.Position = UDim2.new(0.5, -60, 0, 130)
    button.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = "VERIFY"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = background
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 0, 165)
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
            status.Text = "Enter key"
            return
        end
        status.Text = "Verifying..."
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        button.Text = "CHECKING..."
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 120)

        local ok, err = verifyKey(rawKey)
        if ok then
            status.Text = "Valid key. Loading..."
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
            enteredKey = rawKey
            finished = true
            writeConfig(rawKey)
            wait(1)
            screen:Destroy()
        else
            status.Text = "Error: " .. (err or "unknown")
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
            button.Text = "VERIFY"
            button.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
        end
    end)

    repeat wait(0.2) until finished or not screen.Parent
    return enteredKey
end

local function main()
    wait(1)
    local key = readConfig()
    if key then
        local ok, err = verifyKey(key)
        if not ok then
            deleteConfig()
            key = nil
        end
    end
    if not key then
        key = showKeyPrompt()
        if not key then return end
    end

    -- Pobierz główny skrypt (tds.lua) z API
    local scriptContent = fetchScript("tds.lua", key)
    loadstring(scriptContent)()
end

pcall(main)
