-- client/speed_control.lua
SpeedControl = {}
SpeedControl.__index = SpeedControl

function SpeedControl:new(editor)
    local self = setmetatable({}, SpeedControl)
    
    self.editor = editor
    self.window = nil
    self.isVisible = false
    self.elements = {}
    
    self:createInterface()
    
    return self
end

function SpeedControl:createInterface()
    local screenWidth, screenHeight = guiGetScreenSize()
    local windowWidth, windowHeight = 300, 250
    local windowX, windowY = screenWidth - windowWidth - 20, 20
    
    -- Janela principal
    self.window = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "Controles de Velocidade", false)
    guiWindowSetSizable(self.window, false)
    guiWindowSetMovable(self.window, true)
    guiSetVisible(self.window, false)
    
    -- Velocidade de Movimento
    guiCreateLabel(10, 30, 200, 20, "Velocidade de Movimento:", false, self.window)
    self.elements.moveSpeedLabel = guiCreateLabel(10, 50, 200, 20, "Velocidade: 1.00", false, self.window)
    self.elements.moveSpeedSlider = guiCreateScrollBar(10, 70, windowWidth - 20, 20, true, false, self.window)
    guiScrollBarSetScrollPosition(self.elements.moveSpeedSlider, 50) -- 50% = velocidade 1.0
    
    -- Velocidade de Rotação
    guiCreateLabel(10, 100, 200, 20, "Velocidade de Rotação:", false, self.window)
    self.elements.rotationSpeedLabel = guiCreateLabel(10, 120, 200, 20, "Rotação: 2.00", false, self.window)
    self.elements.rotationSpeedSlider = guiCreateScrollBar(10, 140, windowWidth - 20, 20, true, false, self.window)
    guiScrollBarSetScrollPosition(self.elements.rotationSpeedSlider, 50) -- 50% = velocidade 2.0
    
    -- Sensibilidade do Mouse
    guiCreateLabel(10, 170, 200, 20, "Sensibilidade do Mouse:", false, self.window)
    self.elements.mouseSensitivityLabel = guiCreateLabel(10, 190, 200, 20, "Mouse: 1.00", false, self.window)
    self.elements.mouseSensitivitySlider = guiCreateScrollBar(10, 210, windowWidth - 20, 20, true, false, self.window)
    guiScrollBarSetScrollPosition(self.elements.mouseSensitivitySlider, 50) -- 50% = sensibilidade 1.0
    
    -- Bind dos eventos dos sliders
    self:bindSliderEvents()
    
    Utils.debug("Interface de controle de velocidade criada")
end

function SpeedControl:bindSliderEvents()
    -- Slider de velocidade de movimento
    addEventHandler("onClientGUIScroll", self.elements.moveSpeedSlider, function()
        local position = guiScrollBarGetScrollPosition(source)
        -- Converter posição (0-100) para velocidade (0.1-5.0)
        local speed = 0.1 + (position / 100) * 4.9
        self.editor.config.cameraSpeed = speed
        guiSetText(self.elements.moveSpeedLabel, string.format("Velocidade: %.2f", speed))
    end, false)
    
    -- Slider de velocidade de rotação
    addEventHandler("onClientGUIScroll", self.elements.rotationSpeedSlider, function()
        local position = guiScrollBarGetScrollPosition(source)
        -- Converter posição (0-100) para velocidade (0.5-10.0)
        local speed = 0.5 + (position / 100) * 9.5
        self.editor.config.rotationSpeed = speed
        guiSetText(self.elements.rotationSpeedLabel, string.format("Rotação: %.2f", speed))
    end, false)
    
    -- Slider de sensibilidade do mouse
    addEventHandler("onClientGUIScroll", self.elements.mouseSensitivitySlider, function()
        local position = guiScrollBarGetScrollPosition(source)
        -- Converter posição (0-100) para sensibilidade (0.1-3.0)
        local sensitivity = 0.1 + (position / 100) * 2.9
        self.editor.config.mouseSensitivity = sensitivity
        guiSetText(self.elements.mouseSensitivityLabel, string.format("Mouse: %.2f", sensitivity))
    end, false)
end

function SpeedControl:show()
    if self.window then
        guiSetVisible(self.window, true)
        self.isVisible = true
        Utils.debug("Controles de velocidade mostrados")
    end
end

function SpeedControl:hide()
    if self.window then
        guiSetVisible(self.window, false)
        self.isVisible = false
        Utils.debug("Controles de velocidade escondidos")
    end
end

function SpeedControl:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

function SpeedControl:isVisible()
    return self.isVisible
end

-- Exportar para uso global
_G.SpeedControl = SpeedControl