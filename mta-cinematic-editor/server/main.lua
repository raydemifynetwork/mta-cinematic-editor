-- server/main.lua
-- Sistema de gerenciamento do servidor para o Cinematic Editor

-- Configurações do servidor
local config = {
    version = "1.0.0",
    allowCinematicCreation = true,
    maxCinematicsPerPlayer = 5,
    enableLogging = true
}

-- Armazenamento de dados do servidor
local playerCinematics = {}
local globalCinematics = {}

-- Funções utilitárias do servidor
local function logMessage(message, player)
    if config.enableLogging then
        local playerName = player and getPlayerName(player) or "SYSTEM"
        local timestamp = getRealTime()
        local timeString = string.format("[%02d:%02d:%02d]", timestamp.hour, timestamp.minute, timestamp.second)
        outputServerLog(timeString .. " [CinematicEditor] " .. playerName .. ": " .. message)
    end
end

local function sendClientMessage(player, message, r, g, b)
    r = r or 100
    g = g or 200
    b = b or 255
    outputChatBox("[CinematicEditor] " .. message, player, r, g, b)
end

-- Eventos do servidor
addEventHandler("onResourceStart", resourceRoot, function()
    logMessage("Cinematic Editor v" .. config.version .. " iniciado", nil)
    outputServerLog("=== Cinematic Editor Server Loaded ===")
end)

addEventHandler("onResourceStop", resourceRoot, function()
    logMessage("Cinematic Editor parado", nil)
    outputServerLog("=== Cinematic Editor Server Unloaded ===")
end)

addEventHandler("onPlayerJoin", root, function()
    local player = source
    playerCinematics[player] = {
        cinematics = {},
        lastActivity = getTickCount()
    }
    
    logMessage("Jogador entrou no servidor", player)
    
    -- Enviar mensagem de boas-vindas
    setTimer(function()
        if isElement(player) then
            sendClientMessage(player, "Bem-vindo! Cinematic Editor v" .. config.version .. " está disponível.")
            sendClientMessage(player, "Use /cineditor para abrir o editor.")
        end
    end, 2000, 1)
end)

addEventHandler("onPlayerQuit", root, function()
    local player = source
    if playerCinematics[player] then
        playerCinematics[player] = nil
    end
    logMessage("Jogador saiu do servidor", player)
end)

-- Comandos do servidor
addCommandHandler("cineditor", function(player, cmd)
    if not config.allowCinematicCreation then
        sendClientMessage(player, "Criação de cinematicas está desativada!", 255, 100, 100)
        return
    end
    
    -- Verificar se o jogador tem permissão
    if hasObjectPermissionTo(player, "general.adminpanel", false) or 
       hasObjectPermissionTo(player, "command.cineditor", false) then
        
        -- Trigger client event para iniciar o editor
        triggerClientEvent(player, "onClientStartCinematicEditor", player)
        sendClientMessage(player, "Editor de cinematicas ativado!")
        logMessage("Editor ativado", player)
    else
        sendClientMessage(player, "Você não tem permissão para usar o editor!", 255, 100, 100)
        logMessage("Tentativa de acesso negada", player)
    end
end)

addCommandHandler("cinematiclist", function(player, cmd)
    if not hasObjectPermissionTo(player, "general.adminpanel", false) then
        sendClientMessage(player, "Você não tem permissão para ver esta lista!", 255, 100, 100)
        return
    end
    
    sendClientMessage(player, "=== Cinematicas Globais ===")
    if #globalCinematics == 0 then
        sendClientMessage(player, "Nenhuma cinematica global encontrada.")
    else
        for i, cinematic in ipairs(globalCinematics) do
            sendClientMessage(player, i .. ". " .. cinematic.name .. " (" .. cinematic.author .. ")")
        end
    end
end)

addCommandHandler("cinematicinfo", function(player, cmd)
    sendClientMessage(player, "=== Informações do Cinematic Editor ===")
    sendClientMessage(player, "Versão: " .. config.version)
    sendClientMessage(player, "Status: " .. (config.allowCinematicCreation and "Ativo" or "Inativo"))
    
    if playerCinematics[player] then
        local count = #playerCinematics[player].cinematics
        sendClientMessage(player, "Suas cinematicas: " .. count .. "/" .. config.maxCinematicsPerPlayer)
    end
end)

-- Sistema de salvamento de cinematicas (simplificado)
function savePlayerCinematic(player, cinematicData)
    if not playerCinematics[player] then
        playerCinematics[player] = { cinematics = {}, lastActivity = getTickCount() }
    end
    
    local playerData = playerCinematics[player]
    
    if #playerData.cinematics >= config.maxCinematicsPerPlayer then
        sendClientMessage(player, "Limite máximo de cinematicas atingido!", 255, 100, 100)
        return false
    end
    
    table.insert(playerData.cinematics, {
        id = #playerData.cinematics + 1,
        data = cinematicData,
        created = getRealTime().timestamp,
        name = cinematicData.name or "Cinematica " .. (#playerData.cinematics + 1)
    })
    
    sendClientMessage(player, "Cinematica salva com sucesso!")
    logMessage("Cinematica salva", player)
    return true
end

function loadPlayerCinematic(player, cinematicId)
    if not playerCinematics[player] then return nil end
    
    local playerData = playerCinematics[player]
    for _, cinematic in ipairs(playerData.cinematics) do
        if cinematic.id == cinematicId then
            return cinematic.data
        end
    end
    
    return nil
end

function getPlayerCinematics(player)
    if not playerCinematics[player] then return {} end
    return playerCinematics[player].cinematics
end

-- Eventos personalizados
addEvent("onPlayerSaveCinematic", true)
addEventHandler("onPlayerSaveCinematic", root, function(cinematicData)
    local player = source
    if cinematicData and type(cinematicData) == "table" then
        savePlayerCinematic(player, cinematicData)
    end
end)

addEvent("onPlayerLoadCinematic", true)
addEventHandler("onPlayerLoadCinematic", root, function(cinematicId)
    local player = source
    local cinematicData = loadPlayerCinematic(player, cinematicId)
    if cinematicData then
        triggerClientEvent(player, "onClientLoadCinematic", player, cinematicData)
    else
        sendClientMessage(player, "Cinematica não encontrada!", 255, 100, 100)
    end
end)

-- Funções exportadas
function isCinematicEditorEnabled()
    return config.allowCinematicCreation
end

function getCinematicEditorVersion()
    return config.version
end

function setCinematicEditorStatus(status)
    if type(status) == "boolean" then
        config.allowCinematicCreation = status
        logMessage("Status do editor alterado para: " .. tostring(status))
        return true
    end
    return false
end

-- Exportar funções
_G.savePlayerCinematic = savePlayerCinematic
_G.loadPlayerCinematic = loadPlayerCinematic
_G.getPlayerCinematics = getPlayerCinematics
_G.isCinematicEditorEnabled = isCinematicEditorEnabled
_G.getCinematicEditorVersion = getCinematicEditorVersion
_G.setCinematicEditorStatus = setCinematicEditorStatus

logMessage("Server script carregado", nil)
