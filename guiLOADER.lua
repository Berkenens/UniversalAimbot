local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Berkenens/UniversalAimbot/refs/heads/main/uimain.lua'))()

local Window = Rayfield:CreateWindow({
    Name = "Ui Loader",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Perseus",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalAimbot",
        FileName = "perseus"
    },
})

local Loader = Window:CreateTab("Loader", "copy")

Loader:CreateButton({
    Name = "FPS GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Berkenens/UniversalAimbot/refs/heads/main/aimbotADVANCED"))()
    end
})

Loader:CreateButton({
    Name = "Aimbot Lite",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Berkenens/UniversalAimbot/refs/heads/main/aimbotLITE"))()
    end
})
