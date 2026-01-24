-- =========================================================
-- FS22 Farm Tablet Mod (version 1.0.5.9)
-- =========================================================
-- Central tablet interface for farm management mods
-- =========================================================
-- Author: TisonK
-- Im new to modding, so be gentle :)
-- If you like my work, consider looking at my other mods!
-- =========================================================
-- COPYRIGHT NOTICE:
-- All rights reserved. Unauthorized redistribution, copying,
-- or claiming this code as your own is strictly prohibited.
-- Original author: TisonK
-- =========================================================

-- =====================
-- GLOBAL TABLE & DEFAULTS
-- =====================
FarmTablet = {}
FarmTablet.modName = "FS22_FarmTablet"
FarmTablet.settings = {}
FarmTablet.hasRegisteredSettings = false
FarmTablet.version = "1.0.5.9"

-- =====================
-- DEFAULT CONFIGURATION
-- =====================
FarmTablet.DEFAULT_CONFIG = {
    enabled = true,
    tabletKeybind = "T",               
    showTabletNotifications = true,
    startupApp = "financial_dashboard", 
    vibrationFeedback = true,         
    soundEffects = true,              
    debugMode = false
}

-- =====================
-- REGISTERED APPS
-- =====================
FarmTablet.registeredApps = {
    {
        id = "financial_dashboard",
        name = "tablet_app_dashboard",
        icon = "dashboard_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "app_store",
        name = "tablet_app_store",
        icon = "store_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "updates",
        name = "tablet_app_updates",
        icon = "updates_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "settings",
        name = "tablet_app_settings",
        icon = "settings_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "workshop",
        name = "tablet_app_workshop",
        icon = "workshop_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "weather",
        name = "tablet_app_weather",
        icon = "weather_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "digging",
        name = "tablet_app_digging",
        icon = "digging_app",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    },
    {
        id = "bucket_tracker",
        name = "tablet_app_bucket_tracker",
        icon = "bucket_icon",
        developer = "FarmTablet",
        version = "Installed by DEFAULT",
        enabled = true
    }
    -- {
    --     id = "income_mod",
    --     name = "tablet_app_income_mod",
    --     icon = "income_icon",
    --     developer = "FarmTablet",
    --     version = "Installed by DEFAULT",
    --     enabled = true
    -- },
    -- {
    --     id = "tax_mod",
    --     name = "tablet_app_tax_mod",
    --     icon = "tax_icon",
    --     developer = "FarmTablet",
    --     version = "Installed by DEFAULT",
    --     enabled = true
    -- }
}

-- =====================
-- INTERNAL STATE
-- =====================
FarmTablet.isLoaded = false
FarmTablet.isTabletOpen = false
FarmTablet.currentApp = "financial_dashboard"
FarmTablet.welcomeTimer = nil
FarmTablet.settingsRetryTimer = nil

FarmTablet.liveCache = {
    balance = -1,
    income = -1,
    expenses = -1,
    profit = -1
}

FarmTablet.liveUpdateTimer = 0
FarmTablet.liveUpdateInterval = 1000

-- =====================
-- UI ELEMENTS
-- =====================
FarmTablet.ui = {}
FarmTablet.ui.background = nil
FarmTablet.ui.appContent = nil
FarmTablet.ui.navBar = nil
FarmTablet.ui.appButtons = {}
FarmTablet.ui.titleText = nil
FarmTablet.ui.closeButton = nil

-- ======================
-- ASSET PATHS
-- ======================
FarmTablet.TABLET_BACKGROUND = "hud/backScreen_2.dds"

-- ======================
-- UI CONSTANTS
-- ======================
FarmTablet.UI_CONSTANTS = {
    WIDTH = 800,          
    HEIGHT = 600,         
    NAV_BAR_HEIGHT = 40,
    PADDING = 20,
    BACKGROUND_COLOR = {0.1, 0.1, 0.1, 0.95},  
    NAV_BAR_COLOR = {0.2, 0.2, 0.2, 0.98},
    APP_BUTTON_SIZE = 40,
    BUTTON_HOVER_COLOR = {0.3, 0.6, 0.3, 0.8},
    BUTTON_NORMAL_COLOR = {0.25, 0.25, 0.25, 0.9},
    TEXT_COLOR = {1, 1, 1, 1},
    BORDER_COLOR = {0.4, 0.7, 0.4, 1},
    CONTENT_BG_COLOR = {0.15, 0.15, 0.15, 0.7}  
}

-- =====================
-- UTILITY FUNCTIONS
-- =====================
function FarmTablet:getPlayerFarmId()
    if g_currentMission ~= nil and g_currentMission.player ~= nil then
        return g_currentMission.player.farmId
    end
    return FarmManager.SINGLEPLAYER_FARM_ID
end

function FarmTablet:log(msg)
    if self.settings.debugMode then
        print("[" .. self.modName .. "] " .. tostring(msg))
    end
end

function FarmTablet:printBanner()
    self:log("===================================")
    self:log("Farm Tablet Mod")
    self:log("Version: " .. self.version)
    self:log("Author: TisonK")
    self:log("Registered Apps: " .. #self.registeredApps)
    self:log("Open Tablet Key: T")
    self:log("===================================")
end

function FarmTablet:isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function FarmTablet:copyTable(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

function FarmTablet:getModPath()
    local modsDirectory = g_modsDirectory or ""
    return modsDirectory .. "/" .. self.modName .. "/"
end

function FarmTablet:createBlankOverlay(x, y, width, height, color, texturePath)
    local overlay

    if texturePath then
        overlay = Overlay.new(texturePath, x, y, width, height)
    else
        overlay = Overlay.new(nil, x, y, width, height)
    end

    if color then
        overlay:setColor(unpack(color))
    end

    return overlay
end

-- =====================
-- TABLET UI FUNCTIONS
-- =====================
function FarmTablet:openTablet()
    if not self.settings.enabled or self.isTabletOpen then
        return
    end

    self.isTabletOpen = true
    self:log("Opening farm tablet")

    self:createTabletUI()

    if g_currentMission ~= nil then
        g_currentMission:addDrawable(self)
    end

    if g_inputBinding ~= nil then
        g_inputBinding:setShowMouseCursor(true)
    end
end

function FarmTablet:closeTablet()
    if not self.isTabletOpen then
        return
    end

    self.isTabletOpen = false
    self:log("Closing farm tablet")

    self:destroyTabletUI()

    if g_currentMission ~= nil then
        g_currentMission:removeDrawable(self)
    end

    if g_inputBinding ~= nil then
        g_inputBinding:setShowMouseCursor(false)
    end
end

function FarmTablet:toggleTablet()
    if self.isTabletOpen then
        self:closeTablet()
    else
        self:openTablet()
    end
end

function FarmTablet:createTabletUI()
    self.ui = {}
    self.ui.overlays = {}
    self.ui.texts = {}
    self.ui.appButtons = {}
    self.ui.contentOverlays = {}

    local tabletWidth, tabletHeight = getNormalizedScreenValues(800, 600)

    self.ui.backgroundX = 0.5 - tabletWidth / 2
    self.ui.backgroundY = 0.5 - tabletHeight / 2

    self.UI_CONSTANTS.WIDTH = tabletWidth
    self.UI_CONSTANTS.HEIGHT = tabletHeight

    self.ui.scaleX = tabletWidth / 500
    self.ui.scaleY = tabletHeight / 375

    function FarmTablet:px(x)
        return x * self.ui.scaleX
    end

    function FarmTablet:py(y)
        return y * self.ui.scaleY
    end

    local bgPath = self:getModPath() .. "hud/backScreen_2.dds"
    self.ui.background = self:createBlankOverlay(
        self.ui.backgroundX,
        self.ui.backgroundY,
        tabletWidth,
        tabletHeight,
        {1, 1, 1, 1},
        bgPath
    )

    self.ui.background:setVisible(true)
    table.insert(self.ui.overlays, self.ui.background)

    self:createTabletElements()
end

function FarmTablet:createTabletElements()
    self.ui.texts = {}

    local bgX = self.ui.backgroundX
    local bgY = self.ui.backgroundY
    local bgWidth = self.UI_CONSTANTS.WIDTH
    local bgHeight = self.UI_CONSTANTS.HEIGHT

    local navPadX = self:px(15) 
    local navPadY = self:py(15)  
    local navHeight = self:py(35)
    local navWidth = bgWidth - (navPadX * 2) 
    
    local navBarX = bgX + navPadX
    local navBarY = bgY + bgHeight - navPadY - navHeight  

    local navBar = self:createBlankOverlay(
        navBarX,
        navBarY,
        navWidth,
        navHeight,
        self.UI_CONSTANTS.NAV_BAR_COLOR
    )
    navBar:setVisible(true)
    self.ui.navBar = navBar
    table.insert(self.ui.overlays, navBar)

    local closeSize = self:px(25)
    local closeBtnX = navBarX + navWidth - navPadX - closeSize 
    local closeBtnY = navBarY + (navHeight - closeSize) / 2   

    local closeButton = self:createBlankOverlay(
        closeBtnX,
        closeBtnY,
        closeSize,
        closeSize,
        {0.8, 0.2, 0.2, 0.9}
    )
    closeButton:setVisible(true)

    self.ui.closeButton = {
        overlay = closeButton,
        x = closeBtnX,
        y = closeBtnY,
        width = closeSize,
        height = closeSize
    }
    table.insert(self.ui.overlays, closeButton)

    table.insert(self.ui.texts, {
        text = "Close",
        x = closeBtnX + closeSize / 2,
        y = closeBtnY + closeSize / 2 - 0.003,
        size = 0.010,
        align = RenderText.ALIGN_CENTER,
        color = {1, 1, 1, 1}
    })

    table.insert(self.ui.texts, {
        text = "Farm Tablet v" .. self.version,
        x = navBarX + navPadX, 
        y = navBarY + navHeight / 2 - 0.004,
        size = 0.014,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    self:createAppContentArea()
    self:createAppNavigationButtons()
end

function FarmTablet:createAppContentArea()
    self.ui.contentOverlays = {}
    
    local pad = self:px(20)

    local headerHeight = self:py(40)
    local y = self.ui.backgroundY + pad + headerHeight
    
    local appButtonsHeight = self:py(40)
    local navBarHeight = self:py(35)  
    local bottomPadding = self:py(20)     
    
    local availableHeight = self.UI_CONSTANTS.HEIGHT - (y - self.ui.backgroundY) - 
                           appButtonsHeight - navBarHeight - bottomPadding

    local x = self.ui.backgroundX + pad
    local w = self.UI_CONSTANTS.WIDTH - pad * 2
    
    local h = math.max(availableHeight, self:py(200))

    local bg = self:createBlankOverlay(
        x,
        y,
        w,
        h,
        self.UI_CONSTANTS.CONTENT_BG_COLOR
    )
    bg:setVisible(true)

    table.insert(self.ui.overlays, bg)
    table.insert(self.ui.contentOverlays, bg)

    self.ui.appContentArea = {
        x = x,
        y = y,
        width = w,
        height = h
    }

    self.ui.appTexts = {} 
    
    if self.currentApp == "financial_dashboard" then
        self:loadDashboardApp()
    elseif self.currentApp == "app_store" then
        self:loadAppStoreApp()
    elseif self.currentApp == "settings" then
        self:loadSettingsApp()
    elseif self.currentApp == "updates" then
        self:loadUpdatesApp()
    elseif self.currentApp == "weather" then
        self:loadWeatherApp()
    elseif self.currentApp == "workshop" then
        self:loadWorkshopApp()
    elseif self.currentApp == "digging" then
        self:loadDiggingApp()
    elseif self.currentApp == "bucket_tracker" then
        self:loadBucketTrackerApp() 
    elseif self.currentApp == "income_mod" then
        self:loadIncomeApp()
    elseif self.currentApp == "tax_mod" then
        self:loadTaxApp()
    else
        self:loadDefaultApp()
    end
end

function FarmTablet:createAppNavigationButtons()
    local navBar = self.ui.navBar
    if navBar == nil then return end

    local navX = navBar.x
    local navY = navBar.y
    local navH = navBar.height
    local navW = navBar.width

    self.ui.appButtons = {}
    self.ui.texts = self.ui.texts or {}

    local btnSize = self:px(26)
    local spacing = self:px(6)

    local startY = navY - btnSize - self:py(10) 
    
    local leftPadding = self:px(15)
    local rightPadding = self:px(120)

    local startX = navX + leftPadding
    local maxX = navX + navW - rightPadding

    for i, app in ipairs(self:getEnabledApps()) do
        local x = startX + (i - 1) * (btnSize + spacing)

        if x + btnSize > maxX then
            break
        end

        local overlay = self:createBlankOverlay(
            x,
            startY,
            btnSize,
            btnSize,
            app.id == self.currentApp and
                self.UI_CONSTANTS.BUTTON_HOVER_COLOR or
                self.UI_CONSTANTS.BUTTON_NORMAL_COLOR
        )
        overlay:setVisible(true)
        table.insert(self.ui.overlays, overlay)

        table.insert(self.ui.appButtons, {
            overlay = overlay,
            x = x,
            y = startY,
            width = btnSize,
            height = btnSize,
            appId = app.id
        })

        table.insert(self.ui.texts, {
            text = string.sub(g_i18n:getText(app.name) or app.name, 1, 1),
            x = x + btnSize / 2,
            y = startY + btnSize / 2 - 0.005,
            size = 0.011,
            align = RenderText.ALIGN_CENTER,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
    end
end

-- =====================
-- APP FUNCTIONS
-- =====================
local function formatMoney(amount)
    return string.format("€ %s", tostring(amount):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", ""))
end

function FarmTablet:loadDashboardApp()
    local content = self.ui.appContentArea
    if not content then return end

    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))

    local titleY = content.y + content.height - padY - 0.03

    -- Title
    table.insert(self.ui.appTexts, {
        text = "Farm Dashboard",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local itemsStartY = titleY - 0.035
    local farmId = self:getPlayerFarmId()

    local items = {
        {label = "Current Balance", value = formatMoney(self:TotalMoney(farmId))},
        {label = "Total Income", value = formatMoney(self:TotalIncome(farmId))},
        {label = "Total Expenses", value = formatMoney(self:TotalExpenses(farmId))},
        {label = "Loaned Money", value = formatMoney(self:LoanedMoney(farmId))},
        {label = "Active Fields", value = self:ActiveFields(farmId)},
        {label = "Vehicles", value = self:VehiclesCount(farmId)}
    }

    self.ui.dashboardValues = {} 

    local maxVisibleItems = #items 

    for i = 1, math.min(#items, maxVisibleItems) do
        local item = items[i]
        local yPos = itemsStartY - (i * 0.025)

        if yPos > content.y + padY then
            
            table.insert(self.ui.appTexts, {
                text = item.label .. ":",
                x = content.x + padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_LEFT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            })

            local valueEntry = {
                text = tostring(item.value),
                x = content.x + content.width - padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_RIGHT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            }

            table.insert(self.ui.appTexts, valueEntry)

            if item.label == "Current Balance" then
                self.ui.dashboardValues.balance = valueEntry
            elseif item.label == "Total Income" then
                self.ui.dashboardValues.income = valueEntry
            elseif item.label == "Total Expenses" then
                self.ui.dashboardValues.expenses = valueEntry
            elseif item.label == "Loaned Money" then
                self.ui.dashboardValues.loan = valueEntry
            elseif item.label == "Active Fields" then
                self.ui.dashboardValues.fields = valueEntry
            elseif item.label == "Vehicles" then
                self.ui.dashboardValues.vehicles = valueEntry
            end
        end
    end

    -- Initialize live cache
    self.liveCache = {
        balance = -1,
        income = -1,
        expenses = -1,
        loan = -1,
        fields = -1,
        vehicles = -1
    }
end

function FarmTablet:updateDashboardLive(dt)
    if not self.isTabletOpen then return end
    if self.currentApp ~= "financial_dashboard" then return end
    if self.ui.dashboardValues == nil then return end

    self.liveUpdateTimer = (self.liveUpdateTimer or 0) + dt
    if self.liveUpdateTimer < (self.liveUpdateInterval or 1000) then
        return
    end
    self.liveUpdateTimer = 0

    local farmId = self:getPlayerFarmId()
    if not farmId then return end

    -- Get current stats
    local balance  = self:TotalMoney(farmId)
    local income   = self:TotalIncome(farmId)
    local expenses = self:TotalExpenses(farmId)
    local loan     = self:LoanedMoney(farmId)
    local fields   = self:ActiveFields(farmId)
    local vehicles = self:VehiclesCount(farmId)

    -- Update text if changed
    local cache = self.liveCache
    local ui = self.ui.dashboardValues

    if balance ~= cache.balance then
        ui.balance.text = formatMoney(balance)
        cache.balance = balance
    end
    if income ~= cache.income then
        ui.income.text = formatMoney(income)
        cache.income = income
    end
    if expenses ~= cache.expenses then
        ui.expenses.text = formatMoney(expenses)
        cache.expenses = expenses
    end
    if loan ~= cache.loan then
        ui.loan.text = formatMoney(loan)
        cache.loan = loan
    end
    if fields ~= cache.fields then
        ui.fields.text = tostring(fields)
        cache.fields = fields
    end
    if vehicles ~= cache.vehicles then
        ui.vehicles.text = tostring(vehicles)
        cache.vehicles = vehicles
    end
end

function FarmTablet:isDiggingCapable(vehicle)
    -- Check for standard FS22 terrain deformation
    if vehicle ~= nil and vehicle.getIsTerrainDeformationActive ~= nil then
        return true
    end
    
    -- Check for TerraFarm compatibility
    if vehicle ~= nil then
        -- Look for TerraFarm specific properties
        local typeName = vehicle.typeName or ""
        local hasDiggingInName = typeName:lower():find("digger") or 
                                typeName:lower():find("excavator") or
                                typeName:lower():find("backhoe") or
                                typeName:lower():find("loader") or
                                typeName:lower():find("terra")
        
        -- Check for attached tools that might be digging tools
        if vehicle.getAttachedImplements then
            local attached = vehicle:getAttachedImplements()
            for _, impl in ipairs(attached) do
                local spec = impl.object.spec_digging or impl.object.spec_terraFarm
                if spec ~= nil then
                    return true
                end
            end
        end
        
        return hasDiggingInName
    end
    
    return false
end

function FarmTablet:isVehicleDigging(vehicle)
    -- Standard FS22 terrain deformation
    if vehicle.getIsTerrainDeformationActive ~= nil then
        return vehicle:getIsTerrainDeformationActive()
    end
    
    -- TerraFarm specific detection
    if vehicle.spec_terraFarm ~= nil then
        local terraSpec = vehicle.spec_terraFarm
        if terraSpec.isActive ~= nil then
            return terraSpec.isActive
        end
        
        -- Check fill type changes (digging usually creates terrain)
        if terraSpec.fillLevel ~= nil and terraSpec.fillLevel > 0 then
            return true
        end
    end
    
    -- Check digging attachments
    if vehicle.getAttachedImplements then
        local attached = vehicle:getAttachedImplements()
        for _, impl in ipairs(attached) do
            local implObject = impl.object
            
            -- Check if implement has digging functionality
            if implObject.spec_digging then
                local diggingSpec = implObject.spec_digging
                if diggingSpec.isActive ~= nil then
                    return diggingSpec.isActive
                end
            end
            
            -- Check for TerraFarm attachment
            if implObject.spec_terraFarm then
                local terraSpec = implObject.spec_terraFarm
                if terraSpec.isActive ~= nil then
                    return terraSpec.isActive
                end
            end
        end
    end
    
    -- Check vehicle animation/working state
    if vehicle.getIsWorkAreaActive ~= nil then
        return vehicle:getIsWorkAreaActive()
    end
    
    return false
end

function FarmTablet:getDiggingInfo()
    local info = {
        hasTerrainSystem = false,
        terrainSystem = "Unknown",
        supportsTerraFarm = false,
        terraFarmActive = false,
        
        diggingTools = 0,
        activeDiggers = 0,
        
        supportsTerrainDeformation = false,
        terrainDeformationActive = false,
        
        currentPosition = nil,
        currentTerrainHeight = nil,
        terrainDelta = nil,
        
        availableTools = {},
        terraFarmVehicles = {}
    }
    
    -- Check for TerraFarm mod
    if g_terraFarm ~= nil then
        info.supportsTerraFarm = true
        info.terraFarmActive = true
        info.terrainSystem = "TerraFarm + FS22 Terrain"
        
        -- Get TerraFarm specific info
        if g_terraFarm.getVersion then
            info.terraFarmVersion = g_terraFarm:getVersion()
        end
        
        -- Check for active TerraFarm vehicles
        if g_currentMission and g_currentMission.vehicles then
            for _, vehicle in pairs(g_currentMission.vehicles) do
                if vehicle.spec_terraFarm ~= nil then
                    table.insert(info.terraFarmVehicles, {
                        name = vehicle.getName and vehicle:getName() or "Unknown",
                        isActive = self:isVehicleDigging(vehicle)
                    })
                end
            end
        end
    elseif g_currentMission and g_currentMission.terrainRootNode then
        info.hasTerrainSystem = true
        info.terrainSystem = "FS22 Terrain"
        
        if g_currentMission.terrainDeformationSystem then
            info.supportsTerrainDeformation = true
            info.terrainDeformationActive = true
        end
    end
    
    -- Vehicles detection (REAL digging detection)
    if g_currentMission and g_currentMission.vehicles then
        for _, vehicle in pairs(g_currentMission.vehicles) do
            if self:isDiggingCapable(vehicle) then
                info.diggingTools = info.diggingTools + 1
                
                local active = self:isVehicleDigging(vehicle)
                if active then
                    info.activeDiggers = info.activeDiggers + 1
                end
                
                local vehicleType = "Unknown"
                if vehicle.spec_terraFarm then
                    vehicleType = "TerraFarm"
                elseif vehicle.spec_digging then
                    vehicleType = "Digging"
                elseif vehicle.typeName then
                    vehicleType = vehicle.typeName
                end
                
                table.insert(info.availableTools, {
                    name = vehicle.getName and vehicle:getName() or "Unknown",
                    type = vehicleType,
                    status = active and "ACTIVE" or "Idle"
                })
            end
        end
    end
    
    -- Player position & terrain delta
    if g_currentMission and g_currentMission.player then
        local player = g_currentMission.player
        if player.rootNode and (g_currentMission.terrainRootNode or info.supportsTerraFarm) then
            local x, _, z = getWorldTranslation(player.rootNode)
            info.currentPosition = { x = x, z = z }
            
            -- Get terrain height from appropriate system
            if g_currentMission.terrainRootNode then
                local currentH = getTerrainHeightAtWorldPos(
                    g_currentMission.terrainRootNode,
                    x, 0, z
                )
                info.currentTerrainHeight = currentH
                
                -- Cache original terrain height (cut/fill detection)
                self._terrainCache = self._terrainCache or {}
                local key = string.format("%.1f_%.1f", x, z)
                
                if self._terrainCache[key] == nil then
                    self._terrainCache[key] = currentH
                end
                
                info.terrainDelta = currentH - self._terrainCache[key]
            end
        end
    end
    
    return info
end

function FarmTablet:loadDiggingApp()
    local content = self.ui.appContentArea
    if not content then
        self:log("No content area in digging app")
        return
    end

    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    local titleY = content.y + content.height - padY - 0.03

    -- Title
    table.insert(self.ui.appTexts, {
        text = "Digging Information",
        x = content.x + padX,
        y = titleY,
        size = 0.022,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local diggingInfo = self:getDiggingInfo()
    local yPos = titleY - 0.035

    -- TerraFarm Status
    if diggingInfo.supportsTerraFarm then
        table.insert(self.ui.appTexts, {
            text = "✓ TerraFarm Mod Detected",
            x = content.x + padX,
            y = yPos,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {0.4, 0.9, 0.4, 1}
        })
        
        if diggingInfo.terraFarmVersion then
            table.insert(self.ui.appTexts, {
                text = "Version: " .. diggingInfo.terraFarmVersion,
                x = content.x + content.width - padX,
                y = yPos,
                size = 0.014,
                align = RenderText.ALIGN_RIGHT,
                color = {0.7, 0.7, 0.7, 1}
            })
        end
        
        yPos = yPos - 0.024
    end

    if diggingInfo.hasTerrainSystem then
        local labelColor = {0.4, 0.8, 0.4, 1}
        local valueColor = {0.8, 0.8, 0.8, 1}
        
        local items = {
            { "Terrain System", diggingInfo.terrainSystem },
            { "Terrain Deformation", diggingInfo.supportsTerrainDeformation and "Enabled" or "Not Supported" },
            { "Active Diggers", string.format("%d / %d", diggingInfo.activeDiggers, diggingInfo.diggingTools) }
        }
        
        for _, item in ipairs(items) do
            table.insert(self.ui.appTexts, {
                text = item[1] .. ":",
                x = content.x + padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_LEFT,
                color = labelColor
            })

            table.insert(self.ui.appTexts, {
                text = item[2],
                x = content.x + content.width - padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_RIGHT,
                color = valueColor
            })

            yPos = yPos - 0.024
        end

        -- Player position
        if diggingInfo.currentPosition then
            yPos = yPos - 0.010
            table.insert(self.ui.appTexts, {
                text = string.format(
                    "Position: X %.1f  Z %.1f",
                    diggingInfo.currentPosition.x,
                    diggingInfo.currentPosition.z
                ),
                x = content.x + padX,
                y = yPos,
                size = 0.015,
                align = RenderText.ALIGN_LEFT,
                color = valueColor
            })

            yPos = yPos - 0.022
            table.insert(self.ui.appTexts, {
                text = string.format("Terrain Height: %.2f m", diggingInfo.currentTerrainHeight or 0),
                x = content.x + padX,
                y = yPos,
                size = 0.015,
                align = RenderText.ALIGN_LEFT,
                color = valueColor
            })

            if diggingInfo.terrainDelta then
                yPos = yPos - 0.020
                local d = diggingInfo.terrainDelta
                local deltaText =
                    d < 0 and string.format("Cut: %.2f m", math.abs(d))
                    or d > 0 and string.format("Fill: %.2f m", d)
                    or "No terrain change"

                table.insert(self.ui.appTexts, {
                    text = deltaText,
                    x = content.x + padX,
                    y = yPos,
                    size = 0.015,
                    align = RenderText.ALIGN_LEFT,
                    color = {0.9, 0.7, 0.4, 1}
                })
            end
        end

        -- TerraFarm specific vehicles
        if diggingInfo.supportsTerraFarm and #diggingInfo.terraFarmVehicles > 0 then
            yPos = yPos - 0.030
            table.insert(self.ui.appTexts, {
                text = "TerraFarm Vehicles:",
                x = content.x + padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_LEFT,
                color = {0.3, 0.6, 0.8, 1}
            })

            yPos = yPos - 0.022
            for i = 1, math.min(3, #diggingInfo.terraFarmVehicles) do
                local vehicle = diggingInfo.terraFarmVehicles[i]
                table.insert(self.ui.appTexts, {
                    text = "• " .. vehicle.name,
                    x = content.x + padX + 0.01,
                    y = yPos,
                    size = 0.013,
                    align = RenderText.ALIGN_LEFT,
                    color = {0.8, 0.8, 0.8, 1}
                })

                table.insert(self.ui.appTexts, {
                    text = vehicle.isActive and "ACTIVE" or "Idle",
                    x = content.x + content.width - padX,
                    y = yPos,
                    size = 0.013,
                    align = RenderText.ALIGN_RIGHT,
                    color = vehicle.isActive and {0.4, 0.9, 0.4, 1} or {0.7, 0.7, 0.7, 1}
                })

                yPos = yPos - 0.018
            end
        end

        -- All digging vehicles list
        if diggingInfo.availableTools and #diggingInfo.availableTools > 0 then
            yPos = yPos - 0.030
            table.insert(self.ui.appTexts, {
                text = "All Digging Vehicles:",
                x = content.x + padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_LEFT,
                color = {0.3, 0.6, 0.8, 1}
            })

            yPos = yPos - 0.022
            for i = 1, math.min(5, #diggingInfo.availableTools) do
                local tool = diggingInfo.availableTools[i]
                table.insert(self.ui.appTexts, {
                    text = "• " .. tool.name,
                    x = content.x + padX + 0.01,
                    y = yPos,
                    size = 0.013,
                    align = RenderText.ALIGN_LEFT,
                    color = {0.8, 0.8, 0.8, 1}
                })

                local statusText = tool.status
                if tool.type ~= "Unknown" then
                    statusText = tool.type .. " - " .. statusText
                end
                
                table.insert(self.ui.appTexts, {
                    text = statusText,
                    x = content.x + content.width - padX,
                    y = yPos,
                    size = 0.013,
                    align = RenderText.ALIGN_RIGHT,
                    color = tool.status == "ACTIVE" and {0.4, 0.9, 0.4, 1} or {0.7, 0.7, 0.7, 1}
                })

                yPos = yPos - 0.018
            end
        end
    else
        table.insert(self.ui.appTexts, {
            text = "No terrain system detected",
            x = content.x + padX,
            y = yPos,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0.5, 0, 1}
        })
    end

    self:log("Digging app loaded successfully")
end

-- Add this function to update digging info in real-time
function FarmTablet:updateDiggingLive(dt)
    if not self.isTabletOpen then return end
    if self.currentApp ~= "digging" then return end
    
    -- Update every 2 seconds
    self.diggingUpdateTimer = (self.diggingUpdateTimer or 0) + dt
    if self.diggingUpdateTimer < 2000 then
        return
    end
    self.diggingUpdateTimer = 0
    
    -- Refresh the digging app to update information
    if self.ui.contentOverlays then
        for _, overlay in ipairs(self.ui.contentOverlays) do
            if overlay ~= nil then
                overlay:delete()
            end
        end
    end
    
    self.ui.contentOverlays = {}
    self.ui.appTexts = {}
    
    self:createAppContentArea()
end


function FarmTablet:loadWeatherApp()
    local content = self.ui.appContentArea
    if not content then 
        self:log("No content area in weather app")
        return 
    end

    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))

    local titleY = content.y + content.height - padY - 0.03

    table.insert(self.ui.appTexts, {
        text = "Weather Information",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local weather = self:getWeatherInfo()
    
    local y = titleY - 0.035
    
    if not weather then
        table.insert(self.ui.appTexts, {
            text = "Weather data unavailable",
            x = content.x + padX,
            y = y,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0.5, 0, 1}
        })
        return
    end

    local items = {}
    
    local weatherName = self:getWeatherName(weather.weatherType)

    table.insert(items, {"Current Weather", weatherName})
    
    table.insert(items, {"Temperature", string.format("%.1f °C", weather.temperature)})
    
    table.insert(items, {"Cloud Coverage", string.format("%.0f%%", weather.clouds * 100)})
    
    if weather.isRaining then
        table.insert(items, {"Rain", string.format("%.0f%%", weather.rainAmount * 100)})
    else
        table.insert(items, {"Rain", "No"})
    end
    
    table.insert(items, {"Snow", weather.isSnowing and "Yes" or "No"})
    
    table.insert(items, {"Thunder", weather.thunder and "Yes" or "No"})

    for i, item in ipairs(items) do

        table.insert(self.ui.appTexts, {
            text = item[1] .. ":",
            x = content.x + padX,
            y = y,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })

        table.insert(self.ui.appTexts, {
            text = item[2],
            x = content.x + content.width - padX,
            y = y,
            size = 0.016,
            align = RenderText.ALIGN_RIGHT,
            color = {0.4, 0.8, 0.4, 1}
        })

        y = y - 0.024
    end

    y = y - 0.015
    
    table.insert(self.ui.appTexts, {
        text = "Forecast:",
        x = content.x + padX,
        y = y,
        size = 0.016,
        align = RenderText.ALIGN_LEFT,
        color = {0.6, 0.9, 0.6, 1}
    })

    y = y - 0.022
    
    if weather.forecast and #weather.forecast > 0 then
        for i, f in ipairs(weather.forecast) do
            local forecastText = string.format("Day %d: %s, %.1f°C", 
                i, 
                self:getWeatherName(f.weatherType), 
                f.temperature)
            
            table.insert(self.ui.appTexts, {
                text = forecastText,
                x = content.x + padX + 0.01,
                y = y,
                size = 0.013,
                align = RenderText.ALIGN_LEFT,
                color = {0.7, 0.7, 0.7, 1}
            })
            y = y - 0.018
        end
    else
        table.insert(self.ui.appTexts, {
            text = "Not available",
            x = content.x + padX + 0.01,
            y = y,
            size = 0.013,
            align = RenderText.ALIGN_LEFT,
            color = {0.7, 0.7, 0.7, 1}
        })
    end
    
    self:log("Weather app loaded with " .. #items .. " items")
end

function FarmTablet:debugWeather()
    if not g_currentMission or not g_currentMission.environment then
        print("No environment available")
        return
    end
    
    local env = g_currentMission.environment
    
    print("=== WEATHER DEBUG INFO ===")
    print("Environment properties:")
    
    local weatherProps = {
        "currentRainScale", "currentWeatherType", "temperature", "isSnowing",
        "weather", "thunderHandler", "cloudUpdater"
    }
    
    for _, prop in ipairs(weatherProps) do
        if env[prop] ~= nil then
            print(string.format("  env.%s = %s", prop, tostring(env[prop])))
        else
            print(string.format("  env.%s = NOT FOUND", prop))
        end
    end
    
    if env.weather then
        print("\nWeather system properties:")
        local w = env.weather
        
        if w.forecast then
            print("  Forecast available, entries: " .. #w.forecast)
            if w.forecast[1] then
                print("  First forecast entry:")
                local f = w.forecast[1]
                for k, v in pairs(f) do
                    if type(k) == "string" then
                        print(string.format("    %s = %s", k, tostring(v)))
                    end
                end
            end
        else
            print("  No forecast available")
        end
    end
    
    print("\nCurrent weather values:")
    print("  Temperature: " .. tostring(env.temperature))
    print("  CurrentRainScale: " .. tostring(env.currentRainScale))
    print("  IsSnowing: " .. tostring(env.isSnowing))
    
    if env.cloudUpdater then
        local clouds = env.cloudUpdater:getCloudCoverage()
        print("  Cloud coverage: " .. tostring(clouds))
    end
    
    print("=== END DEBUG ===")
end

function FarmTablet:getWeatherName(weatherType)
    
    local weatherNames = {
        [0] = "Sunny",
        [1] = "Cloudy",
        [2] = "Rainy",
        [3] = "Stormy",
        [4] = "Snowy"
    }
    
    local name = weatherNames[weatherType]
    
    if not name then
        if weatherType < 1.5 then
            name = "Clear"
        elseif weatherType < 2.5 then
            name = "Cloudy"
        elseif weatherType < 3.5 then
            name = "Rainy"
        else
            name = "Stormy"
        end
    end
    
    return name
end

function FarmTablet:getWeatherInfo()
    self:log("Getting weather info...")
    
    if not g_currentMission or not g_currentMission.environment then
        self:log("ERROR: No mission environment")
        return nil
    end
    
    local env = g_currentMission.environment
    
    self:log("=== WEATHER DATA DEBUG ===")
    self:log("env.currentWeatherType: " .. tostring(env.currentWeatherType))
    self:log("env.temperature: " .. tostring(env.temperature))
    self:log("env.currentRainScale: " .. tostring(env.currentRainScale))
    self:log("env.isSnowing: " .. tostring(env.isSnowing))
    
    local weatherType = env.currentWeatherType or 0
    local temperature = env.temperature or 20
    
    local rainScale = env.currentRainScale or 0
    local isRaining = rainScale > 0.05  
    local rainAmount = rainScale  
    
    local isSnowing = env.isSnowing or false
    
    local clouds = 0
    if env.cloudUpdater then
        clouds = env.cloudUpdater:getCloudCoverage() or 0
    end
    
    local thunder = false
    if env.thunderHandler then
        thunder = env.thunderHandler:getIsThundering()
    end
    
    self:log("Parsed weather data:")
    self:log("  Weather type: " .. weatherType)
    self:log("  Temperature: " .. temperature)
    self:log("  Rain scale: " .. rainScale .. ", Is raining: " .. tostring(isRaining))
    self:log("  Is snowing: " .. tostring(isSnowing))
    self:log("  Thunder: " .. tostring(thunder))
    self:log("  Clouds: " .. clouds)
    
    return {
        weatherType = weatherType,
        temperature = temperature,
        clouds = clouds,
        isRaining = isRaining,
        rainAmount = rainScale, 
        isSnowing = isSnowing,
        thunder = thunder,
        forecast = {}
    }
end

function FarmTablet:TotalIncome(farmId)
    local totalIncome = 0

    if g_currentMission == nil or g_currentMission.statistics == nil then
        return 0
    end

    local incomeKeywords = {
        "income",
        "revenue",
        "harvest",
        "mission",
        "selling",
        "contract"
    }

    for _, statsItem in ipairs(g_currentMission.statistics.statsItems or {}) do
        if statsItem.farmId == farmId and statsItem.name then
            local name = statsItem.name:lower()
            for _, key in ipairs(incomeKeywords) do
                if name:find(key) then
                    local v = statsItem:getValue() or 0
                    if v > 0 then
                        totalIncome = totalIncome + v
                    end
                    break
                end
            end
        end
    end

    return math.floor(totalIncome)
end

function FarmTablet:TotalExpenses(farmId)
    self:log("Calculating total expenses for farm: " .. tostring(farmId))

    local totalExpenses = 0

    if g_currentMission == nil or g_currentMission.statistics == nil then
        return 0
    end

    local expenseKeywords = {
        "expense",
        "cost",
        "maintenance",
        "wage",
        "fuel",
        "seed",
        "fertilizer",
        "spray",
        "repair",
        "lease",
        "insurance",
        "animal",
        "property",
        "loanInterest"
    }

    if g_currentMission.statistics.statsItems ~= nil then
        for _, statsItem in ipairs(g_currentMission.statistics.statsItems) do
            if statsItem.farmId == farmId and statsItem.name ~= nil then
                local nameLower = statsItem.name:lower()

                for _, keyword in ipairs(expenseKeywords) do
                    if nameLower:find(keyword) then
                        local value = statsItem:getValue() or 0
                        if value > 0 then
                            totalExpenses = totalExpenses + value
                            self:log("Expense [" .. statsItem.name .. "] = " .. tostring(value))
                        end
                        break
                    end
                end
            end
        end
    end

    return math.floor(totalExpenses)
end

function FarmTablet:TotalMoney(farmId)
    if g_farmManager ~= nil then
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil then
            return math.floor(farm:getBalance() or 0)
        end
    end
    return 0
end

function FarmTablet:LoanedMoney(farmId)
    if g_farmManager ~= nil then
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil and farm.loan ~= nil then
            return math.floor(farm.loan)
        end
    end
    return 0
end


function FarmTablet:ExpenseToMoneyRatio(farmId)
    local expenses = self:TotalExpenses(farmId)
    local totalMoney = self:TotalMoney(farmId)
    
    if totalMoney > 0 then
        local percentage = (expenses / totalMoney) * 100
        return math.floor(percentage * 100) / 100 
    end
    
    return 0
end

function FarmTablet:NetProfit(farmId)
    return self:TotalIncome(farmId) - self:TotalExpenses(farmId)
end

function FarmTablet:ActiveFields(farmId)
    local count = 0

    if g_farmlandManager == nil then
        return 0
    end

    for farmlandId, farmland in pairs(g_farmlandManager.farmlands) do
        if farmland.farmId == farmId then
            if farmland.fieldIds ~= nil then
                count = count + #farmland.fieldIds
            end
        end
    end

    return count
end

function FarmTablet:VehiclesCount(farmId)
    local count = 0

    if g_currentMission ~= nil and g_currentMission.vehicles ~= nil then
        for _, vehicle in pairs(g_currentMission.vehicles) do

            if vehicle.spec_motorized ~= nil then

                local ownerFarmId = nil

                if vehicle.getOwnerFarmId ~= nil then
                    ownerFarmId = vehicle:getOwnerFarmId()
                elseif vehicle.farmId ~= nil then
                    ownerFarmId = vehicle.farmId
                end

                if ownerFarmId == farmId then
                    count = count + 1
                end
            end
        end
    end

    return count
end


function FarmTablet:getPlayerFarmId()
    if g_currentMission ~= nil then
        if g_currentMission.player ~= nil then
            local player = g_currentMission.player
            if player.getFarmId ~= nil then
                return player:getFarmId()
            elseif player.farmId ~= nil then
                return player.farmId
            end
        end
        
        if g_currentMission:getFarmId() ~= nil then
            return g_currentMission:getFarmId()
        end
    end
    
    return 1 
end

function FarmTablet:debugFinancialData(farmId)
    print("=== FINANCIAL DATA DEBUG ===")
    
    if g_farmManager ~= nil then
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil then
            print("Farm found! ID: " .. farmId)
            print("Farm balance (getBalance): " .. tostring(farm:getBalance()))
            print("Farm money property: " .. tostring(farm.money))
            print("Farm loan: " .. tostring(farm.loan))
            
            for key, value in pairs(farm) do
                if type(value) == "number" and (key:find("money") or key:find("income") or key:find("balance")) then
                    print("Farm." .. key .. " = " .. tostring(value))
                end
            end
        else
            print("Farm NOT found for ID: " .. farmId)
            print("Available farms:")
            for id, farm in pairs(g_farmManager.farms) do
                print("  - Farm ID: " .. id .. ", Name: " .. tostring(farm.name))
            end
        end
    else
        print("Farm Manager is nil!")
    end
    
    if g_currentMission ~= nil and g_currentMission.statistics ~= nil then
        print("Statistics system available")
        
        if g_currentMission.statistics.getStatsItemByName ~= nil then
            local incomeItem = g_currentMission.statistics:getStatsItemByName("income", farmId)
            print("Income item via getStatsItemByName: " .. tostring(incomeItem))
            if incomeItem ~= nil then
                print("Income value: " .. tostring(incomeItem:getValue()))
            end
        end
        
        if g_currentMission.statistics.statsItems ~= nil then
            print("Total stats items: " .. tostring(#g_currentMission.statistics.statsItems))
            for i, statsItem in ipairs(g_currentMission.statistics.statsItems) do
                if statsItem.farmId == farmId then
                    print("Item " .. i .. ": " .. tostring(statsItem.name) .. " = " .. tostring(statsItem:getValue()))
                end
            end
        end
    else
        print("Statistics NOT available")
    end
    
    print("=== END DEBUG ===")
end

function FarmTablet:loadWorkshopApp()
    local content = self.ui.appContentArea
    if not content then return end

    local padX = select(1, getNormalizedScreenValues(15, 0))
    local centerY = content.y + content.height / 2

    table.insert(self.ui.appTexts, {
        text = "Workshop",
        x = content.x + padX,
        y = content.y + content.height - 0.035,
        size = 0.022,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local buttonWidth = 0.22
    local buttonHeight = 0.045
    local bx = content.x + (content.width - buttonWidth) / 2
    local by = centerY - buttonHeight / 2

    local btn = self:createBlankOverlay(
        bx,
        by,
        buttonWidth,
        buttonHeight,
        {0.3, 0.6, 0.3, 0.9}
    )
    btn:setVisible(true)

    table.insert(self.ui.overlays, btn)

    self.ui.workshopButton = {
        overlay = btn,
        x = bx,
        y = by,
        width = buttonWidth,
        height = buttonHeight
    }

    table.insert(self.ui.appTexts, {
        text = "Select Vehicle",
        x = bx + buttonWidth / 2,
        y = by + buttonHeight / 2 - 0.006,
        size = 0.018,
        align = RenderText.ALIGN_LEFT,
        color = {1,1,1,1}
    })
end


function FarmTablet:loadAppStoreApp()
    local content = self.ui.appContentArea
    if not content then return end
    
    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    
    local titleY = content.y + content.height - padY - 0.03
    
    table.insert(self.ui.appTexts, {
        text = "App Store",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local subtitleY = titleY - 0.03
    
    table.insert(self.ui.appTexts, {
        text = "Available Apps:",
        x = content.x + padX,
        y = subtitleY,
        size = 0.016,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local itemsStartY = subtitleY - 0.025
    local lineHeight = 0.020
    local maxVisibleApps = math.floor((itemsStartY - (content.y + padY)) / lineHeight)
    
    for i = 1, math.min(#self.registeredApps, maxVisibleApps) do
        local app = self.registeredApps[i]
        local yPos = itemsStartY - (i - 1) * lineHeight

        if yPos > content.y + padY then
            local status = app.enabled and "✓" or "✗"
            local statusColor = app.enabled and {0,1,0,1} or {1,0,0,1}

            table.insert(self.ui.appTexts, {
                text = status,
                x = content.x + padX,
                y = yPos,
                size = 0.018,
                align = RenderText.ALIGN_LEFT,
                color = statusColor
            })

            table.insert(self.ui.appTexts, {
                text = g_i18n:getText(app.name) or app.name,
                x = content.x + padX + 0.02,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_LEFT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            })

            table.insert(self.ui.appTexts, {
                text = app.version,
                x = content.x + content.width - padX,
                y = yPos,
                size = 0.014,
                align = RenderText.ALIGN_RIGHT,
                color = {0.7,0.7,0.7,1}
            })
        end
    end
end

function FarmTablet:openWorkshopForNearestVehicle(maxDistance)
    if g_currentMission == nil or g_currentMission.player == nil then
        return false
    end

    local player = g_currentMission.player
    local px, py, pz = getWorldTranslation(player.rootNode)

    maxDistance = maxDistance or 5
    local closestVehicle = nil
    local closestDistSq = maxDistance * maxDistance

    for _, vehicle in pairs(g_currentMission.vehicles) do
        if vehicle.rootNode ~= nil
        and vehicle.getSellPrice ~= nil
        and vehicle.price ~= nil
        and not SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
        and vehicle.typeName ~= "pallet" then

            if g_currentMission.accessHandler:canPlayerAccess(vehicle, player) then
                local vx, vy, vz = getWorldTranslation(vehicle.rootNode)
                local dx = px - vx
                local dz = pz - vz
                local distSq = dx * dx + dz * dz

                if distSq < closestDistSq then
                    closestDistSq = distSq
                    closestVehicle = vehicle
                end
            end
        end
    end

    if closestVehicle == nil then
        self:showNotification(
            g_i18n:getText("tablet_workshop"),
            g_i18n:getText("tablet_no_vehicle_nearby") or "No vehicle nearby"
        )
        return false
    end

    local vehicles = {}
    local childVehicles = closestVehicle.rootVehicle:getChildVehicles()

    for i = 1, #childVehicles do
        local child = childVehicles[i]
        if g_currentMission.accessHandler:canPlayerAccess(child, player) then
            table.insert(vehicles, child)
        end
    end

    table.sort(vehicles, function(a, b)
        return a.rootNode < b.rootNode
    end)

    g_workshopScreen:setSellingPoint(nil, false, false, true)
    g_workshopScreen:setVehicles(vehicles)
    g_workshopScreen.list:setSelectedIndex(
        table.findListElementFirstIndex(vehicles, closestVehicle)
    )

    self:closeTablet()
    g_gui:showGui("WorkshopScreen")

    return true
end


function FarmTablet:loadUpdatesApp()
    local content = self.ui.appContentArea
    if not content then return end
    
    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    
    local titleY = content.y + content.height - padY - 0.03
    
    table.insert(self.ui.appTexts, {
        text = "Updates",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local itemsStartY = titleY - 0.035
    local lineHeight = 0.025
    local maxVisibleUpdates = math.floor((itemsStartY - (content.y + padY)) / lineHeight)
    
    local updates = {
        "Version 1.0.5.9 == [added Bucket Load Tracker app and fixed bugs]",
        "Version 1.0.5.8 == [reworked Digging app with real terrain deformation data]",
        "Version 1.0.5.7 == [added \"Digging\" app]",
        "Version 1.0.5.6 == [changed 2 apps and fixed debug spam in console]",
        "Version 1.0.5.5 == [added weather app and fixed workshop issues]",
        "Version 1.0.5.4 == [added 3 new apps and fixed minor bugs]",
        "Version 1.0.5.3 == [UI improvements and bug fixes]",
        "END OF LIST >> To see lower version updates, please look to changelog on KingMods",
    }
    
    for i = 1, math.min(#updates, maxVisibleUpdates) do
        local updateText = updates[i]
        local yPos = itemsStartY - (i - 1) * lineHeight
        
        if yPos > content.y + padY then
            table.insert(self.ui.appTexts, {
                text = updateText,
                x = content.x + padX,
                y = yPos,
                size = 0.016,
                align = RenderText.ALIGN_LEFT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            })
        end
    end
end

function FarmTablet:loadSettingsApp()
    local content = self.ui.appContentArea
    if not content then return end

    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))

    local titleY = content.y + content.height - padY - 0.03

    table.insert(self.ui.appTexts, {
        text = "Tablet Settings",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    -- Center block start
    local startY = content.y + (content.height / 2) + 0.02
    local lineHeight = 0.025

    local lines = {
        {
            text = "Settings are managed via the console.",
            size = 0.018,
            color = self.UI_CONSTANTS.TEXT_COLOR
        },
        {
            text = 'Type "tablet" to see available commands',
            size = 0.018,
            color = self.UI_CONSTANTS.TEXT_COLOR
        },
        {
            text = 'To enable the console, locate a file named "game.xml" in your FS22 user folder',
            size = 0.011,
            color = {0.8, 0.8, 0.8, 1}
        },
        {
            text = 'Change the <developer><controls> from "false" to "true" and restart the game',
            size = 0.011,
            color = {0.8, 0.8, 0.8, 1}
        },
        {
            text = 'When in the game press "~" to open the console, press again to execute commands',
            size = 0.011,
            color = {0.8, 0.8, 0.8, 1}
        }
    }

    for i, line in ipairs(lines) do
        table.insert(self.ui.appTexts, {
            text = line.text,
            x = content.x + padX,
            y = startY - ((i - 1) * lineHeight),
            size = line.size,
            align = RenderText.ALIGN_LEFT,
            color = line.color
        })
    end
end


function FarmTablet:loadDefaultApp()
    local contentX = self.ui.appContentArea.x
    local contentY = self.ui.appContentArea.y

    local padX = select(1, getNormalizedScreenValues(self.UI_CONSTANTS.PADDING, 0))
    local padY = select(2, getNormalizedScreenValues(0, self.UI_CONSTANTS.PADDING))

    table.insert(self.ui.texts, {
        text = g_i18n:getText(self.currentApp) or "Unknown App",
        x = contentX + padX,
        y = contentY + padY,
        size = 0.022,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    table.insert(self.ui.texts, {
        text = "App content is not yet implemented",
        x = contentX + padX,
        y = contentY + padY + 0.04,
        size = 0.018,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })
end

function FarmTablet:loadBucketTrackerApp()
    local content = self.ui.appContentArea
    if not content then
        self:log("No content area in bucket tracker app")
        return
    end

    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    local titleY = content.y + content.height - padY - 0.03

    -- Title
    table.insert(self.ui.appTexts, {
        text = "Bucket Load Tracker",
        x = content.x + padX,
        y = titleY,
        size = 0.022,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })

    local tracker = self.bucketTracker
    local vehicle = self:getCurrentBucketVehicle()
    local yPos = titleY - 0.035
    
    -- Current Vehicle Status
    if vehicle then
        local vehicleName = vehicle.getName and vehicle:getName() or "Unknown"
        table.insert(self.ui.appTexts, {
            text = "Vehicle: " .. vehicleName,
            x = content.x + padX,
            y = yPos,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {0.4, 0.8, 0.4, 1}
        })
        
        -- Current load info
        local fillInfo = self:getBucketFillInfo(vehicle)
        yPos = yPos - 0.024
        
        if fillInfo.totalFillLevel > 0 then
            table.insert(self.ui.appTexts, {
                text = "Current Load:",
                x = content.x + padX,
                y = yPos,
                size = 0.015,
                align = RenderText.ALIGN_LEFT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            })
            
            table.insert(self.ui.appTexts, {
                text = fillInfo.fillTypeName,
                x = content.x + content.width - padX,
                y = yPos,
                size = 0.015,
                align = RenderText.ALIGN_RIGHT,
                color = {0.8, 0.8, 0.8, 1}
            })
            
            yPos = yPos - 0.020
            table.insert(self.ui.appTexts, {
                text = string.format("Volume: %d / %d L", 
                    math.floor(fillInfo.totalFillLevel), 
                    math.floor(fillInfo.totalCapacity)),
                x = content.x + padX,
                y = yPos,
                size = 0.014,
                align = RenderText.ALIGN_LEFT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            })
            
            yPos = yPos - 0.020
            table.insert(self.ui.appTexts, {
                text = string.format("Fill: %.0f%%", fillInfo.fillPercentage),
                x = content.x + padX,
                y = yPos,
                size = 0.014,
                align = RenderText.ALIGN_LEFT,
                color = fillInfo.fillPercentage > 80 and {0, 1, 0, 1} or 
                       fillInfo.fillPercentage > 50 and {1, 1, 0, 1} or {1, 0.5, 0, 1}
            })
            
            yPos = yPos - 0.020
            local weight = self:estimateBucketWeight(fillInfo)
            table.insert(self.ui.appTexts, {
                text = string.format("Est. Weight: %d kg", weight),
                x = content.x + padX,
                y = yPos,
                size = 0.014,
                align = RenderText.ALIGN_LEFT,
                color = {0.6, 0.8, 1, 1}
            })
            
            yPos = yPos - 0.010
        else
            table.insert(self.ui.appTexts, {
                text = "Bucket: EMPTY",
                x = content.x + padX,
                y = yPos,
                size = 0.015,
                align = RenderText.ALIGN_LEFT,
                color = {1, 0.5, 0, 1}
            })
            yPos = yPos - 0.024
        end
    else
        table.insert(self.ui.appTexts, {
            text = "No bucket vehicle detected",
            x = content.x + padX,
            y = yPos,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0.5, 0, 1}
        })
        table.insert(self.ui.appTexts, {
            text = "Drive a loader or excavator",
            x = content.x + padX,
            y = yPos - 0.024,
            size = 0.014,
            align = RenderText.ALIGN_LEFT,
            color = {0.8, 0.8, 0.8, 1}
        })
        yPos = yPos - 0.048
    end
    
    -- Session Statistics
    yPos = yPos - 0.020
    table.insert(self.ui.appTexts, {
        text = "Session Statistics:",
        x = content.x + padX,
        y = yPos,
        size = 0.016,
        align = RenderText.ALIGN_LEFT,
        color = {0.6, 0.9, 0.6, 1}
    })
    
    yPos = yPos - 0.024
    table.insert(self.ui.appTexts, {
        text = "Total Loads: " .. tracker.totalLoads,
        x = content.x + padX,
        y = yPos,
        size = 0.015,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })
    
    yPos = yPos - 0.020
    table.insert(self.ui.appTexts, {
        text = "Total Weight: " .. string.format("%d kg", tracker.totalWeight),
        x = content.x + padX,
        y = yPos,
        size = 0.015,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })
    
    if tracker.startTime > 0 then
        local currentTime = g_currentMission.time or 0
        local duration = currentTime - tracker.startTime
        
        yPos = yPos - 0.020
        table.insert(self.ui.appTexts, {
            text = "Session Time: " .. self:formatTime(duration / 1000),
            x = content.x + padX,
            y = yPos,
            size = 0.015,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        
        if tracker.totalLoads > 0 then
            local avgWeight = math.floor(tracker.totalWeight / tracker.totalLoads)
            yPos = yPos - 0.020
            table.insert(self.ui.appTexts, {
                text = "Avg. Load: " .. string.format("%d kg", avgWeight),
                x = content.x + padX,
                y = yPos,
                size = 0.015,
                align = RenderText.ALIGN_LEFT,
                color = self.UI_CONSTANTS.TEXT_COLOR
            })
        end
    end
    
    -- Recent Loads History
    if #tracker.bucketHistory > 0 then
        yPos = yPos - 0.030
        table.insert(self.ui.appTexts, {
            text = "Recent Loads:",
            x = content.x + padX,
            y = yPos,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {0.3, 0.6, 0.8, 1}
        })
        
        yPos = yPos - 0.022
        for i = math.max(1, #tracker.bucketHistory - 4), #tracker.bucketHistory do
            local load = tracker.bucketHistory[i]
            if load and yPos > content.y + padY then
                local loadText = string.format("#%d: %dL %s", 
                    load.number, load.volume, load.fillType)
                
                table.insert(self.ui.appTexts, {
                    text = loadText,
                    x = content.x + padX + 0.01,
                    y = yPos,
                    size = 0.013,
                    align = RenderText.ALIGN_LEFT,
                    color = {0.8, 0.8, 0.8, 1}
                })
                
                table.insert(self.ui.appTexts, {
                    text = string.format("%d kg", load.weight),
                    x = content.x + content.width - padX,
                    y = yPos,
                    size = 0.013,
                    align = RenderText.ALIGN_RIGHT,
                    color = {0.6, 0.8, 1, 1}
                })
                
                yPos = yPos - 0.018
            end
        end
    end
    
    -- Reset Button
    local buttonWidth = 0.18
    local buttonHeight = 0.035
    local buttonY = content.y + padY + buttonHeight/2
    
    local resetButton = self:createBlankOverlay(
        content.x + content.width - padX - buttonWidth,
        buttonY,
        buttonWidth,
        buttonHeight,
        {0.8, 0.3, 0.3, 0.9}
    )
    resetButton:setVisible(true)
    table.insert(self.ui.overlays, resetButton)
    
    self.ui.resetBucketButton = {
        overlay = resetButton,
        x = content.x + content.width - padX - buttonWidth,
        y = buttonY,
        width = buttonWidth,
        height = buttonHeight
    }
    
    table.insert(self.ui.appTexts, {
        text = "Reset Session",
        x = content.x + content.width - padX - buttonWidth/2,
        y = buttonY + buttonHeight/2 - 0.004,
        size = 0.012,
        align = RenderText.ALIGN_CENTER,
        color = {1, 1, 1, 1}
    })
    
    self:log("Bucket tracker app loaded")
end

-- =====================
-- BUCKET TRACKER SYSTEM
-- =====================
FarmTablet.bucketTracker = {
    isEnabled = true,
    currentVehicle = nil,
    bucketHistory = {},
    totalLoads = 0,
    totalWeight = 0,
    currentFillLevel = 0,
    currentFillType = nil,
    startTime = 0,
    lastLoadTime = 0
}

-- Vehicle type detection for bucket/loader vehicles
FarmTablet.bucketVehicleTypes = {
    "wheelLoader",
    "frontLoader",
    "loader",
    "excavator",
    "backhoe",
    "telehandler",
    "skidSteer",
    "materialHandler"
}

-- Common fill types for construction/gravel
FarmTablet.bucketFillTypes = {
    FillType.SAND,
    FillType.GRAVEL,
    FillType.CRUSHEDSTONE,
    FillType.STONE,
    FillType.DIRT,
    FillType.CLAY,
    FillType.LIMESTONE,
    FillType.COAL,
    FillType.ORE,
    FillType.CONCRETE
}

function FarmTablet:isBucketVehicle(vehicle)
    if not vehicle then return false end
    
    -- Check type name
    local typeName = vehicle.typeName or ""
    typeName = typeName:lower()
    
    for _, vehicleType in ipairs(self.bucketVehicleTypes) do
        if typeName:find(vehicleType) then
            return true
        end
    end
    
    -- Check for bucket/loader attachments
    if vehicle.getAttachedImplements then
        local attached = vehicle:getAttachedImplements()
        for _, impl in ipairs(attached) do
            local implType = impl.object.typeName or ""
            implType = implType:lower()
            
            if implType:find("bucket") or 
               implType:find("loader") or 
               implType:find("grapple") or
               implType:find("fork") then
                return true
            end
            
            -- Check for fillable spec
            if impl.object.spec_fillUnit then
                return true
            end
        end
    end
    
    -- Check for fillable vehicle
    if vehicle.spec_fillUnit then
        return true
    end
    
    return false
end

function FarmTablet:getCurrentBucketVehicle()
    if g_currentMission == nil or g_currentMission.controlledVehicle == nil then
        return nil
    end
    
    local vehicle = g_currentMission.controlledVehicle
    
    if self:isBucketVehicle(vehicle) then
        return vehicle
    end
    
    return nil
end

function FarmTablet:getBucketFillInfo(vehicle)
    local fillInfo = {
        hasFillUnit = false,
        fillUnits = {},
        totalCapacity = 0,
        totalFillLevel = 0,
        currentFillType = nil,
        fillTypeName = "Empty",
        fillPercentage = 0
    }
    
    if vehicle == nil or g_fillTypeManager == nil then  -- Add this check
            return fillInfo
    end
    
    -- Check vehicle's own fill units
    if vehicle.spec_fillUnit then
        local fillUnitSpec = vehicle.spec_fillUnit
        fillInfo.hasFillUnit = true
        
        for _, fillUnit in ipairs(fillUnitSpec.fillUnits) do
            table.insert(fillInfo.fillUnits, {
                fillLevel = fillUnit.fillLevel or 0,
                capacity = fillUnit.capacity or 0,
                fillType = fillUnit.lastValidFillType or FillType.UNKNOWN,
                fillTypeIndex = fillUnit.fillType or FillType.UNKNOWN
            })
            
            fillInfo.totalCapacity = fillInfo.totalCapacity + (fillUnit.capacity or 0)
            fillInfo.totalFillLevel = fillInfo.totalFillLevel + (fillUnit.fillLevel or 0)
            
            if (fillUnit.fillLevel or 0) > 0 then
                fillInfo.currentFillType = fillUnit.fillType or FillType.UNKNOWN
            end
        end
    end
    
    -- Check attached implements
    if vehicle.getAttachedImplements then
        local attached = vehicle:getAttachedImplements()
        for _, impl in ipairs(attached) do
            if impl.object.spec_fillUnit then
                fillInfo.hasFillUnit = true
                local fillUnitSpec = impl.object.spec_fillUnit
                
                for _, fillUnit in ipairs(fillUnitSpec.fillUnits) do
                    table.insert(fillInfo.fillUnits, {
                        fillLevel = fillUnit.fillLevel or 0,
                        capacity = fillUnit.capacity or 0,
                        fillType = fillUnit.lastValidFillType or FillType.UNKNOWN,
                        fillTypeIndex = fillUnit.fillType or FillType.UNKNOWN
                    })
                    
                    fillInfo.totalCapacity = fillInfo.totalCapacity + (fillUnit.capacity or 0)
                    fillInfo.totalFillLevel = fillInfo.totalFillLevel + (fillUnit.fillLevel or 0)
                    
                    if (fillUnit.fillLevel or 0) > 0 then
                        fillInfo.currentFillType = fillUnit.fillType or FillType.UNKNOWN
                    end
                end
            end
        end
    end
    
    -- Calculate percentage
    if fillInfo.totalCapacity > 0 then
        fillInfo.fillPercentage = (fillInfo.totalFillLevel / fillInfo.totalCapacity) * 100
    end
    
    -- Get fill type name
    if fillInfo.currentFillType then
        fillInfo.fillTypeName = g_fillTypeManager:getFillTypeByIndex(fillInfo.currentFillType).title or "Unknown"
    end
    
    return fillInfo
end

function FarmTablet:estimateBucketWeight(fillInfo)
    if fillInfo.totalFillLevel <= 0 then
        return 0
    end
    
    -- Rough weight estimation in liters -> kg conversion
    -- Common material densities (kg per liter approximation)
    local densities = {
        [FillType.SAND] = 1.6,          -- Sand: ~1.6 kg/L
        [FillType.GRAVEL] = 1.7,        -- Gravel: ~1.7 kg/L
        [FillType.CRUSHEDSTONE] = 1.6,  -- Crushed stone: ~1.6 kg/L
        [FillType.STONE] = 2.6,         -- Stone: ~2.6 kg/L
        [FillType.DIRT] = 1.3,          -- Dirt: ~1.3 kg/L
        [FillType.CLAY] = 1.8,          -- Clay: ~1.8 kg/L
        [FillType.LIMESTONE] = 2.6,     -- Limestone: ~2.6 kg/L
        [FillType.COAL] = 1.3,          -- Coal: ~1.3 kg/L
        [FillType.ORE] = 2.5,           -- Ore: ~2.5 kg/L
        [FillType.CONCRETE] = 2.4       -- Concrete: ~2.4 kg/L
    }
    
    local fillType = fillInfo.currentFillType or FillType.UNKNOWN
    local density = densities[fillType] or 1.5  -- Default density if unknown
    
    -- Convert liters to kg (rough estimation)
    return math.floor(fillInfo.totalFillLevel * density)
end

function FarmTablet:trackBucketLoad()
    local vehicle = self:getCurrentBucketVehicle()
    local tracker = self.bucketTracker
    
    if not vehicle then
        tracker.currentVehicle = nil
        return
    end
    
    -- Check if we switched vehicles
    if tracker.currentVehicle ~= vehicle then
        tracker.currentVehicle = vehicle
        tracker.startTime = g_currentMission.time
        self:log("Started tracking bucket for: " .. (vehicle.getName and vehicle:getName() or "Unknown"))
    end
    
    local fillInfo = self:getBucketFillInfo(vehicle)
    local currentTime = g_currentMission.time or 0
    
    -- Detect bucket emptied (load completed)
    if tracker.currentFillLevel > 50 and fillInfo.totalFillLevel < 10 then
        -- A load was just dumped/completed
        local loadWeight = self:estimateBucketWeight({
            totalFillLevel = tracker.currentFillLevel,
            currentFillType = tracker.currentFillType
        })
        
        local loadEntry = {
            number = tracker.totalLoads + 1,
            timestamp = currentTime,
            fillType = tracker.fillTypeName or "Unknown",
            volume = math.floor(tracker.currentFillLevel),
            weight = loadWeight,
            vehicle = vehicle.getName and vehicle:getName() or "Unknown"
        }
        
        table.insert(tracker.bucketHistory, loadEntry)
        tracker.totalLoads = tracker.totalLoads + 1
        tracker.totalWeight = tracker.totalWeight + loadWeight
        tracker.lastLoadTime = currentTime
        
        -- Show notification
        if self.settings.showTabletNotifications then
            self:showNotification(
                "Bucket Load #" .. loadEntry.number,
                string.format("%s - %dL (%d kg)", 
                    loadEntry.fillType, 
                    loadEntry.volume, 
                    loadEntry.weight)
            )
        end
        
        self:log(string.format("Load recorded: #%d - %dL - %d kg", 
            loadEntry.number, loadEntry.volume, loadEntry.weight))
    end
    
    -- Update current state
    tracker.currentFillLevel = fillInfo.totalFillLevel
    tracker.currentFillType = fillInfo.currentFillType
    tracker.fillTypeName = fillInfo.fillTypeName
end

function FarmTablet:resetBucketTracker()
    local tracker = self.bucketTracker
    tracker.bucketHistory = {}
    tracker.totalLoads = 0
    tracker.totalWeight = 0
    tracker.currentFillLevel = 0
    tracker.currentFillType = nil
    tracker.startTime = g_currentMission.time or 0
    tracker.lastLoadTime = 0
    
    self:showNotification("Bucket Tracker", "Tracking reset")
    self:log("Bucket tracker reset")
end

function FarmTablet:formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

function FarmTablet:destroyTabletUI()
    if self.ui.overlays then
        for _, overlay in ipairs(self.ui.overlays) do
            if overlay ~= nil then
                overlay:delete()
            end
        end
    end
    
    self.ui = {
        background = nil,
        backgroundX = 0,
        backgroundY = 0,
        overlays = {},
        appButtons = {},
        contentOverlays = {},
        titleText = nil,
        closeButton = nil,
        navBar = nil,
        appContentArea = nil
    }
end

function FarmTablet:switchApp(appId)
    local app = self:getApp(appId)
    if not app or not app.enabled then
        return false
    end

    if app.isExternal and app.openFunction ~= nil then
        self:log("Opening external app: " .. appId)
        self:closeTablet()
        app.openFunction()
        return true
    end

    self.currentApp = appId
    self:log("Switched to app: " .. appId)

    if self.settings.soundEffects and g_soundManager then
        g_soundManager:playSample(g_soundManager.samples.GUI_CLICK)
    end

    if self.isTabletOpen then
        if self.ui.contentOverlays then
            for _, overlay in ipairs(self.ui.contentOverlays) do
                if overlay ~= nil then
                    overlay:delete()
                end
            end
        end

        self.ui.contentOverlays = {}
        self.ui.appTexts = {}

        for _, buttonInfo in ipairs(self.ui.appButtons) do
            buttonInfo.overlay:setColor(unpack(
                buttonInfo.appId == appId and
                self.UI_CONSTANTS.BUTTON_HOVER_COLOR or
                self.UI_CONSTANTS.BUTTON_NORMAL_COLOR
            ))
        end

        self:createAppContentArea()
    end

    return true
end

-- =====================
-- APP REGISTRATION SYSTEM
-- =====================
function FarmTablet:registerApp(appData)
    for _, app in ipairs(self.registeredApps) do
        if app.id == appData.id then
            self:log("App '" .. appData.id .. "' already registered")
            return false
        end
    end
    
    if not appData.id or not appData.name or not appData.developer then
        self:log("Failed to register app: missing required fields")
        return false
    end
    
    appData.enabled = Utils.getNoNil(appData.enabled, true)
    appData.version = Utils.getNoNil(appData.version, "Installed")
    
    table.insert(self.registeredApps, appData)
    self:log("Registered app: " .. appData.id .. " by " .. appData.developer)
    
    if self.isTabletOpen then
        self:createAppNavigationButtons()
    end
    
    if self.settings.showTabletNotifications then
        self:showNotification(
            g_i18n:getText("tablet_app_installed"),
            string.format(g_i18n:getText("tablet_app_installed_message"), 
                         g_i18n:getText(appData.name))
        )
    end
    
    return true
end

function FarmTablet:unregisterApp(appId)
    for i, app in ipairs(self.registeredApps) do
        if app.id == appId then
            table.remove(self.registeredApps, i)
            self:log("Unregistered app: " .. appId)
            
            if self.isTabletOpen then
                self:createAppNavigationButtons()
            end
            
            return true
        end
    end
    return false
end

function FarmTablet:getApp(appId)
    for _, app in ipairs(self.registeredApps) do
        if app.id == appId then
            return app
        end
    end
    return nil
end

function FarmTablet:getEnabledApps()
    local enabledApps = {}
    for _, app in ipairs(self.registeredApps) do
        if app.enabled then
            table.insert(enabledApps, app)
        end
    end
    return enabledApps
end

-- =====================
-- NOTIFICATIONS
-- =====================
function FarmTablet:showNotification(title, message)
    if not self.settings.showTabletNotifications then
        return
    end
    
    if g_currentMission and g_currentMission.addIngameNotification then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            string.format("[%s] %s", title, message)
        )
    end
end

-- =====================
-- SETTINGS SYSTEM
-- =====================
function FarmTablet:getSettingsFilePath()
    local baseDir = getUserProfileAppPath() .. "modSettings"
    local modDir  = baseDir .. "/FS22_FarmTablet"

    createFolder(baseDir)
    createFolder(modDir)

    return modDir .. "/settings.xml"
end

function FarmTablet:loadSettingsFromXML()
    local filePath = self:getSettingsFilePath()
    local xmlFile = loadXMLFile("settings", filePath)
    
    if xmlFile ~= 0 then
        self.settings.enabled = Utils.getNoNil(getXMLBool(xmlFile, "FS22_FarmTablet.enabled"), self.DEFAULT_CONFIG.enabled)
        self.settings.tabletKeybind = Utils.getNoNil(getXMLString(xmlFile, "FS22_FarmTablet.tabletKeybind"), self.DEFAULT_CONFIG.tabletKeybind)
        self.settings.showTabletNotifications = Utils.getNoNil(getXMLBool(xmlFile, "FS22_FarmTablet.showTabletNotifications"), self.DEFAULT_CONFIG.showTabletNotifications)
        self.settings.startupApp = Utils.getNoNil(getXMLString(xmlFile, "FS22_FarmTablet.startupApp"), self.DEFAULT_CONFIG.startupApp)
        self.settings.vibrationFeedback = Utils.getNoNil(getXMLBool(xmlFile, "FS22_FarmTablet.vibrationFeedback"), self.DEFAULT_CONFIG.vibrationFeedback)
        self.settings.soundEffects = Utils.getNoNil(getXMLBool(xmlFile, "FS22_FarmTablet.soundEffects"), self.DEFAULT_CONFIG.soundEffects)
        self.settings.debugMode = Utils.getNoNil(getXMLBool(xmlFile, "FS22_FarmTablet.debugMode"), self.DEFAULT_CONFIG.debugMode)
        
        delete(xmlFile)
        self:log("[Farm Tablet] Settings loaded from XML: " .. filePath)
    else
        self.settings = self:copyTable(self.DEFAULT_CONFIG)
        self:log("[Farm Tablet] Using default settings")
        self:saveSettingsToXML()
    end
end

function FarmTablet:saveSettingsToXML()
    local filePath = self:getSettingsFilePath()
    local xmlFile = createXMLFile("settings", filePath, "FS22_FarmTablet")
    
    if xmlFile ~= 0 then
        setXMLBool(xmlFile, "FS22_FarmTablet.enabled", self.settings.enabled)
        setXMLString(xmlFile, "FS22_FarmTablet.tabletKeybind", self.settings.tabletKeybind)
        setXMLBool(xmlFile, "FS22_FarmTablet.showTabletNotifications", self.settings.showTabletNotifications)
        setXMLString(xmlFile, "FS22_FarmTablet.startupApp", self.settings.startupApp)
        setXMLBool(xmlFile, "FS22_FarmTablet.vibrationFeedback", self.settings.vibrationFeedback)
        setXMLBool(xmlFile, "FS22_FarmTablet.soundEffects", self.settings.soundEffects)
        setXMLBool(xmlFile, "FS22_FarmTablet.debugMode", self.settings.debugMode)
        
        saveXMLFile(xmlFile)
        delete(xmlFile)
        self:log("[Farm Tablet] Settings saved to XML: " .. filePath)
    else
        self:log("Failed to create XML file: " .. filePath)
    end
end

-- =====================
-- DEBUG FUNCTIONS
-- =====================
-- function FarmTablet:debugModDetection()
--     self:log("=== DEBUG MOD DETECTION ===")
--     self:log("Checking for Income Mod...")
    
--     -- NIEUW: Check g_ prefixed globals
--     self:log("g_IncomeMod exists: " .. tostring(g_IncomeMod ~= nil))
--     self:log("g_TaxMod exists: " .. tostring(g_TaxMod ~= nil))
    
--     -- Methode 1: Global variable
--     self:log("_G['Income'] exists: " .. tostring(_G["Income"] ~= nil))
--     if _G["Income"] then
--         self:log("Income.modName: " .. tostring(_G["Income"].modName))
--         self:log("Income.version: " .. tostring(_G["Income"].version))
--         self:log("Income.openFromTablet type: " .. type(_G["Income"].openFromTablet))
--     end
    
--     -- Methode 2: g_modIsLoaded
--     self:log("g_modIsLoaded exists: " .. tostring(g_modIsLoaded ~= nil))
--     if g_modIsLoaded then
--         self:log("FS22_IncomeMod loaded: " .. tostring(g_modIsLoaded["FS22_IncomeMod"]))
--         self:log("FS22_TaxMod loaded: " .. tostring(g_modIsLoaded["FS22_TaxMod"]))
--     end
    
--     self:log("=== END DEBUG ===")
-- end

function FarmTablet:autoRegisterModApps()
    self:log("=== Starting mod auto-registration ===")
    
    local incomeRegistered = false
    local taxRegistered = false
    
    for _, app in ipairs(self.registeredApps) do
        if app.id == "income_mod" then
            incomeRegistered = true
        elseif app.id == "tax_mod" then
            taxRegistered = true
        end
    end
    
    self:log("Income mod already registered: " .. tostring(incomeRegistered))
    self:log("Tax mod already registered: " .. tostring(taxRegistered))
    
    if not incomeRegistered then
        self:log("Looking for Income Mod...")
        
        if g_IncomeMod ~= nil then
            self:log("✓ Income Mod found via g_IncomeMod")
            local incomeApp = {
                id = "income_mod",
                name = "tablet_app_income_mod",
                icon = "income_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(incomeApp)
            self:log("✓ Income Mod app registered")
        elseif _G["Income"] ~= nil then
            self:log("✓ Income Mod found via global variable")
            local incomeApp = {
                id = "income_mod",
                name = "tablet_app_income_mod",
                icon = "income_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(incomeApp)
            self:log("✓ Income Mod app registered")
        elseif g_modIsLoaded and g_modIsLoaded["FS22_IncomeMod"] then
            self:log("✓ Income Mod found via g_modIsLoaded")
            local incomeApp = {
                id = "income_mod",
                name = "tablet_app_income_mod",
                icon = "income_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(incomeApp)
        else
            self:log("✗ Income Mod not found")
        end
    end

    if not taxRegistered then
        self:log("Looking for Tax Mod...")
        
        if g_TaxMod ~= nil then
            self:log("✓ Tax Mod found via g_TaxMod")
            local taxApp = {
                id = "tax_mod",
                name = "tablet_app_tax_mod",
                icon = "tax_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(taxApp)
            self:log("✓ Tax Mod app registered")
        elseif _G["TaxMod"] ~= nil then
            self:log("✓ Tax Mod found via global variable")
            local taxApp = {
                id = "tax_mod",
                name = "tablet_app_tax_mod",
                icon = "tax_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(taxApp)
            self:log("✓ Tax Mod app registered")
        elseif g_modIsLoaded and g_modIsLoaded["FS22_TaxMod"] then
            self:log("✓ Tax Mod found via g_modIsLoaded")
            local taxApp = {
                id = "tax_mod",
                name = "tablet_app_tax_mod",
                icon = "tax_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(taxApp)
        else
            self:log("✗ Tax Mod not found")
        end
    end
    
    self:log("=== Mod auto-registration complete ===")
    self:log("Total registered apps: " .. #self.registeredApps)
end

function FarmTablet:loadIncomeApp()
    local content = self.ui.appContentArea
    if not content then return end
    
    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    
    local titleY = content.y + content.height - padY - 0.03
    
    -- Title
    table.insert(self.ui.appTexts, {
        text = "Income Mod",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })
    
    local incomeInstance = nil
    
    if g_IncomeMod then
        incomeInstance = g_IncomeMod
        self:log("Found Income Mod via g_IncomeMod")
    elseif _G["Income"] then
        incomeInstance = _G["Income"]
        self:log("Found Income Mod via _G['Income']")
    elseif g_modIsLoaded and g_modIsLoaded["FS22_IncomeMod"] then
        self:log("Income Mod is loaded (via g_modIsLoaded) but instance not accessible")
        table.insert(self.ui.appTexts, {
            text = "Status: LOADED",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {0, 1, 0, 1}
        })
        
        table.insert(self.ui.appTexts, {
            text = "Configure via console: 'income'",
            x = content.x + padX,
            y = titleY - 0.060,
            size = 0.014,
            align = RenderText.ALIGN_LEFT,
            color = {0.8, 0.8, 0.8, 1}
        })
        
        return 
    else
        table.insert(self.ui.appTexts, {
            text = "Income Mod not installed",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0, 0, 1}
        })
        return
    end
    
    self:log("Income Mod instance available, loading data...")
    
    -- Haal data op
    local incomeData = {}
    local success = false
    
    if incomeInstance.openFromTablet then
        local result = incomeInstance:openFromTablet("status")
        if result then
            incomeData = result
            success = true
            self:log("Got data via openFromTablet")
        end
    end
    
    if not success and incomeInstance.settings then
        incomeData = {
            enabled = incomeInstance.settings.enabled,
            mode = incomeInstance.settings.mode,
            modeText = (incomeInstance.settings.mode == "hourly") and "Hourly" or "Daily",
            amount = incomeInstance:getDynamicIncome() or 0
        }
        success = true
        self:log("Got data via direct access")
    end
    
    if success then
        local statusText = incomeData.enabled and "ENABLED" or "DISABLED"
        local statusColor = incomeData.enabled and {0, 1, 0, 1} or {1, 0, 0, 1}
        
        table.insert(self.ui.appTexts, {
            text = "Status: " .. statusText,
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = statusColor
        })
        
        local modeText = incomeData.modeText or 
                        (incomeData.mode == "hourly" and "Hourly" or "Daily") or 
                        "Unknown"
        
        table.insert(self.ui.appTexts, {
            text = "Mode: " .. modeText,
            x = content.x + padX,
            y = titleY - 0.060,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        
        local amount = incomeData.amount or 0
        local amountText = incomeData.formattedAmount or formatMoney(amount)
        
        table.insert(self.ui.appTexts, {
            text = "Amount: " .. amountText,
            x = content.x + padX,
            y = titleY - 0.085,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        
        local buttonWidth = 0.20
        local buttonHeight = 0.04
        local buttonY = titleY - 0.140
        
        local enableX = content.x + padX
        local enableButton = self:createBlankOverlay(
            enableX,
            buttonY,
            buttonWidth,
            buttonHeight,
            {0.3, 0.6, 0.3, 0.9}
        )
        enableButton:setVisible(true)
        table.insert(self.ui.overlays, enableButton)
        
        self.ui.enableIncomeButton = {
            overlay = enableButton,
            x = enableX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        }
        
        table.insert(self.ui.appTexts, {
            text = "Enable",
            x = enableX + buttonWidth / 2,
            y = buttonY + buttonHeight / 2 - 0.005,
            size = 0.014,
            align = RenderText.ALIGN_CENTER,
            color = {1, 1, 1, 1}
        })
        
        local disableX = enableX + buttonWidth + padX
        local disableButton = self:createBlankOverlay(
            disableX,
            buttonY,
            buttonWidth,
            buttonHeight,
            {0.8, 0.3, 0.3, 0.9}
        )
        disableButton:setVisible(true)
        table.insert(self.ui.overlays, disableButton)
        
        self.ui.disableIncomeButton = {
            overlay = disableButton,
            x = disableX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        }
        
        table.insert(self.ui.appTexts, {
            text = "Disable",
            x = disableX + buttonWidth / 2,
            y = buttonY + buttonHeight / 2 - 0.005,
            size = 0.014,
            align = RenderText.ALIGN_CENTER,
            color = {1, 1, 1, 1}
        })
    else
        table.insert(self.ui.appTexts, {
            text = "Could not load mod data",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0.5, 0, 1}
        })
    end
end

function FarmTablet:mouseEvent(posX, posY, isDown, isUp, button) 
    if not self.isTabletOpen or not isDown then
        return false
    end
    
    if self.ui.closeButton then
        local btn = self.ui.closeButton
        if posX >= btn.x and posX <= btn.x + btn.width and
           posY >= btn.y and posY <= btn.y + btn.height then
            self:closeTablet()
            return true
        end
    end
    
    for _, buttonInfo in ipairs(self.ui.appButtons) do
        if posX >= buttonInfo.x and posX <= buttonInfo.x + buttonInfo.width and
           posY >= buttonInfo.y and posY <= buttonInfo.y + buttonInfo.height then
            self:switchApp(buttonInfo.appId)
            return true
        end
    end
    
    if self.currentApp == "workshop" and self.ui.workshopButton then
        local b = self.ui.workshopButton
        if posX >= b.x and posX <= b.x + b.width and
        posY >= b.y and posY <= b.y + b.height then
            self:openWorkshopForNearestVehicle(6)
            return true
        end
    end

    if self.currentApp == "income_mod" then
        if self.ui.enableIncomeButton then
            local b = self.ui.enableIncomeButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local incomeInstance = g_IncomeMod or _G["Income"]
                if incomeInstance and incomeInstance.openFromTablet then
                    incomeInstance:openFromTablet("enable")
                    self:switchApp("income_mod")
                end
                return true
            end
        end
        
        if self.ui.disableIncomeButton then
            local b = self.ui.disableIncomeButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local incomeInstance = g_IncomeMod or _G["Income"]
                if incomeInstance and incomeInstance.openFromTablet then
                    incomeInstance:openFromTablet("disable")
                    self:switchApp("income_mod")
                end
                return true
            end
        end
    end
    
    if self.currentApp == "tax_mod" then
        if self.ui.enableTaxButton then
            local b = self.ui.enableTaxButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local taxInstance = g_TaxMod or _G["TaxMod"]
                if taxInstance and taxInstance.openFromTablet then
                    taxInstance:openFromTablet("enable")
                    self:switchApp("tax_mod")
                end
                return true
            end
        end
        
        if self.ui.disableTaxButton then
            local b = self.ui.disableTaxButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local taxInstance = g_TaxMod or _G["TaxMod"]
                if taxInstance and taxInstance.openFromTablet then
                    taxInstance:openFromTablet("disable")
                    self:switchApp("tax_mod")
                end
                return true
            end
        end
    end
    
    -- Handle bucket tracker reset button (MOVED OUTSIDE tax_mod block!)
    if self.currentApp == "bucket_tracker" and self.ui.resetBucketButton then
        local b = self.ui.resetBucketButton
        if posX >= b.x and posX <= b.x + b.width and
           posY >= b.y and posY <= b.y + b.height then
            self:resetBucketTracker()
            self:switchApp("bucket_tracker") -- Refresh the display
            return true
        end
    end

    return false
end

-- =====================
-- MOD LIFECYCLE
-- =====================
function FarmTablet:loadMap()
    if g_currentMission == nil or self.isLoaded then return end

    self:loadSettingsFromXML()
    
    if self.settings.enabled then
        self.welcomeTimer = 5.0 
    end

    self.isLoaded = true
    addConsoleCommand("tablet", "Farm Tablet commands", "onConsoleCommand", self)
    
    -- self:debugModDetection()

    self:tryRegisterSettings()
    self:autoRegisterModApps()
    self:registerKeybind()
end

function FarmTablet:update(dt)
    if not self.settings.enabled then return end
    
    if self.welcomeTimer ~= nil then
        self.welcomeTimer = self.welcomeTimer - dt
        if self.welcomeTimer <= 0 then
            self:printBanner()
            self:showNotification(
                g_i18n:getText("tablet_welcome_title"),
                string.format(g_i18n:getText("tablet_welcome_message"), self.settings.tabletKeybind)
            )
            self.welcomeTimer = nil
        end
    end
    
    if self.settingsRetryTimer ~= nil then
        self.settingsRetryTimer = self.settingsRetryTimer - dt
        if self.settingsRetryTimer <= 0 then
            self:tryRegisterSettings()
            self.settingsRetryTimer = nil
        end
    end
    
    if self.currentApp == "digging" then 
        self:updateDiggingLive(dt) 
    end

    if self.bucketTracker.isEnabled then
        self:trackBucketLoad()
    end

    self:autoRegisterModApps()
    self:updateDashboardLive(dt)
end

function FarmTablet:autoRegisterModApps()
    self:log("=== Starting mod auto-registration ===")
    
    local incomeRegistered = false
    local taxRegistered = false
    
    for _, app in ipairs(self.registeredApps) do
        if app.id == "income_mod" then
            incomeRegistered = true
        elseif app.id == "tax_mod" then
            taxRegistered = true
        end
    end
    
    self:log("Income mod already registered: " .. tostring(incomeRegistered))
    self:log("Tax mod already registered: " .. tostring(taxRegistered))
    
    if not incomeRegistered then
        self:log("Looking for Income Mod...")
        
        if g_IncomeMod ~= nil then
            self:log("✓ Income Mod found via g_IncomeMod")
            local incomeApp = {
                id = "income_mod",
                name = "tablet_app_income_mod",
                icon = "income_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(incomeApp)
            self:log("✓ Income Mod app registered")

        elseif _G["Income"] ~= nil then
            self:log("✓ Income Mod found via global variable")
            local incomeApp = {
                id = "income_mod",
                name = "tablet_app_income_mod",
                icon = "income_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(incomeApp)
            self:log("✓ Income Mod app registered")
        elseif g_modIsLoaded and g_modIsLoaded["FS22_IncomeMod"] then
            self:log("✓ Income Mod found via g_modIsLoaded")
            local incomeApp = {
                id = "income_mod",
                name = "tablet_app_income_mod",
                icon = "income_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(incomeApp)
        else
            self:log("✗ Income Mod not found")
        end
    end
    
    if not taxRegistered then
        self:log("Looking for Tax Mod...")
        
        if g_TaxMod ~= nil then
            self:log("✓ Tax Mod found via g_TaxMod")
            local taxApp = {
                id = "tax_mod",
                name = "tablet_app_tax_mod",
                icon = "tax_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(taxApp)
            self:log("✓ Tax Mod app registered")

        elseif _G["TaxMod"] ~= nil then
            self:log("✓ Tax Mod found via global variable")
            local taxApp = {
                id = "tax_mod",
                name = "tablet_app_tax_mod",
                icon = "tax_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(taxApp)
            self:log("✓ Tax Mod app registered")
        elseif g_modIsLoaded and g_modIsLoaded["FS22_TaxMod"] then
            self:log("✓ Tax Mod found via g_modIsLoaded")
            local taxApp = {
                id = "tax_mod",
                name = "tablet_app_tax_mod",
                icon = "tax_icon",
                developer = "TisonK",
                version = "Installed via MOD MANAGER",
                enabled = true,
                isExternal = false
            }
            
            self:registerApp(taxApp)
        else
            self:log("✗ Tax Mod not found")
        end
    end
    
    self:log("=== Mod auto-registration complete ===")
    self:log("Total registered apps: " .. #self.registeredApps)
end

function FarmTablet:loadIncomeApp()
    local content = self.ui.appContentArea
    if not content then return end
    
    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    
    local titleY = content.y + content.height - padY - 0.03
    
    table.insert(self.ui.appTexts, {
        text = "Income Mod",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })
    
    self:log("=== LOAD INCOME APP DEBUG ===")
    self:log("g_IncomeMod: " .. tostring(g_IncomeMod ~= nil))
    self:log("_G['Income']: " .. tostring(_G["Income"] ~= nil))
    self:log("g_modIsLoaded['FS22_IncomeMod']: " .. tostring(g_modIsLoaded and g_modIsLoaded["FS22_IncomeMod"]))

    local modLoaded = (g_modIsLoaded and g_modIsLoaded["FS22_IncomeMod"]) or 
                     (g_IncomeMod ~= nil) or 
                     (_G["Income"] ~= nil)
    
    if not modLoaded then

        table.insert(self.ui.appTexts, {
            text = "Income Mod not installed",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0, 0, 1}
        })
        return
    end
    
    local incomeInstance = g_IncomeMod or _G["Income"]
    
    if not incomeInstance then
        table.insert(self.ui.appTexts, {
            text = "Status: LOADED",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {0, 1, 0, 1}
        })
        
        table.insert(self.ui.appTexts, {
            text = "Configure via console: 'income'",
            x = content.x + padX,
            y = titleY - 0.060,
            size = 0.014,
            align = RenderText.ALIGN_LEFT,
            color = {0.8, 0.8, 0.8, 1}
        })
        return
    end
    
    self:log("Income mod instance found, loading data...")

    local incomeInfo = {}
    local gotData = false
    
    if incomeInstance.openFromTablet then
        self:log("openFromTablet function found, calling...")
        local success, result = pcall(function()
            return incomeInstance:openFromTablet("status")
        end)
        
        if success and result then
            incomeInfo = result
            gotData = true
            self:log("Successfully loaded income data via openFromTablet")
            self:log("Data received: enabled=" .. tostring(incomeInfo.enabled))
        else
            self:log("openFromTablet call failed: " .. tostring(result))
        end
    else
        self:log("openFromTablet function not found")
    end
    
    if not gotData and incomeInstance.settings then
        self:log("Trying direct access to settings...")
        incomeInfo.enabled = incomeInstance.settings.enabled
        incomeInfo.mode = incomeInstance.settings.mode
        incomeInfo.modeText = (incomeInstance.settings.mode == "hourly") and "Hourly" or "Daily"
        
        if incomeInstance.getDynamicIncome then
            local amount = incomeInstance:getDynamicIncome()
            incomeInfo.amount = amount
            incomeInfo.formattedAmount = formatMoney(amount)
        end
        
        gotData = true
        self:log("Got data via direct access")
    end
    
    if gotData then
        local statusText = (incomeInfo.enabled == true) and "ENABLED" or "DISABLED"
        local statusColor = (incomeInfo.enabled == true) and {0, 1, 0, 1} or {1, 0, 0, 1}
        
        table.insert(self.ui.appTexts, {
            text = "Status: " .. statusText,
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = statusColor
        })
        
        local modeText = incomeInfo.modeText or 
                        (incomeInfo.mode == "hourly" and "Hourly" or 
                         incomeInfo.mode == "daily" and "Daily" or "Unknown")
        
        table.insert(self.ui.appTexts, {
            text = "Mode: " .. modeText,
            x = content.x + padX,
            y = titleY - 0.060,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        
        local amountText = incomeInfo.formattedAmount or 
                          (incomeInfo.amount and formatMoney(incomeInfo.amount)) or 
                          "€0"
        
        table.insert(self.ui.appTexts, {
            text = "Amount: " .. amountText,
            x = content.x + padX,
            y = titleY - 0.085,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        
        if incomeInstance.settings and incomeInstance.settings.difficulty then
            table.insert(self.ui.appTexts, {
                text = "Difficulty: " .. incomeInstance.settings.difficulty,
                x = content.x + padX,
                y = titleY - 0.110,
                size = 0.014,
                align = RenderText.ALIGN_LEFT,
                color = {0.8, 0.8, 0.8, 1}
            })
        end

        local buttonWidth = 0.20
        local buttonHeight = 0.04
        local buttonY = titleY - 0.160

        local enableX = content.x + padX
        local enableButton = self:createBlankOverlay(
            enableX,
            buttonY,
            buttonWidth,
            buttonHeight,
            {0.3, 0.6, 0.3, 0.9}
        )
        enableButton:setVisible(true)
        table.insert(self.ui.overlays, enableButton)
        
        self.ui.enableIncomeButton = {
            overlay = enableButton,
            x = enableX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        }
        
        table.insert(self.ui.appTexts, {
            text = "Enable",
            x = enableX + buttonWidth / 2,
            y = buttonY + buttonHeight / 2 - 0.005,
            size = 0.014,
            align = RenderText.ALIGN_CENTER,
            color = {1, 1, 1, 1}
        })
        
        local disableX = enableX + buttonWidth + padX
        local disableButton = self:createBlankOverlay(
            disableX,
            buttonY,
            buttonWidth,
            buttonHeight,
            {0.8, 0.3, 0.3, 0.9}
        )
        disableButton:setVisible(true)
        table.insert(self.ui.overlays, disableButton)
        
        self.ui.disableIncomeButton = {
            overlay = disableButton,
            x = disableX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        }
        
        table.insert(self.ui.appTexts, {
            text = "Disable",
            x = disableX + buttonWidth / 2,
            y = buttonY + buttonHeight / 2 - 0.005,
            size = 0.014,
            align = RenderText.ALIGN_CENTER,
            color = {1, 1, 1, 1}
        })
    else
        table.insert(self.ui.appTexts, {
            text = "Could not load mod data",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0.5, 0, 1}
        })
        
        local buttonWidth = 0.25
        local buttonHeight = 0.04
        local buttonY = titleY - 0.080
        
        table.insert(self.ui.appTexts, {
            text = "Configure via console: 'income'",
            x = content.x + padX,
            y = buttonY - 0.025,
            size = 0.012,
            align = RenderText.ALIGN_LEFT,
            color = {0.8, 0.8, 0.8, 1}
        })
    end
end

function FarmTablet:loadTaxApp()
    local content = self.ui.appContentArea
    if not content then return end
    
    local padX = select(1, getNormalizedScreenValues(15, 0))
    local padY = select(2, getNormalizedScreenValues(0, 15))
    
    local titleY = content.y + content.height - padY - 0.03
    
    -- Title
    table.insert(self.ui.appTexts, {
        text = "Tax Mod",
        x = content.x + padX,
        y = titleY,
        size = 0.020,
        align = RenderText.ALIGN_LEFT,
        color = self.UI_CONSTANTS.TEXT_COLOR
    })
    
    local taxInstance = nil
    

    if g_TaxMod then
        taxInstance = g_TaxMod
        self:log("Found Tax Mod via g_TaxMod")

    elseif _G["TaxMod"] then
        taxInstance = _G["TaxMod"]
        self:log("Found Tax Mod via _G['TaxMod']")

    elseif g_modIsLoaded and g_modIsLoaded["FS22_TaxMod"] then
        self:log("Tax Mod is loaded (via g_modIsLoaded) but instance not accessible")
        -- Toon een eenvoudige status
        table.insert(self.ui.appTexts, {
            text = "Status: LOADED",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {0, 1, 0, 1}
        })
        
        table.insert(self.ui.appTexts, {
            text = "Configure via console: 'tax'",
            x = content.x + padX,
            y = titleY - 0.060,
            size = 0.014,
            align = RenderText.ALIGN_LEFT,
            color = {0.8, 0.8, 0.8, 1}
        })
        
        return 
    else
       
        table.insert(self.ui.appTexts, {
            text = "Tax Mod not installed",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0, 0, 1}
        })
        return
    end
    
    self:log("Tax Mod instance available, loading data...")
    

    local taxData = {}
    local success = false
    
    if taxInstance.openFromTablet then
        local result = taxInstance:openFromTablet("status")
        if result then
            taxData = result
            success = true
            self:log("Got data via openFromTablet")
        end
    end
    
    if not success and taxInstance.settings then
        taxData = {
            enabled = taxInstance.settings.enabled,
            taxRate = taxInstance.settings.taxRate,
            returnPercentage = taxInstance.settings.returnPercentage,
            stats = taxInstance.stats or {}
        }
        success = true
        self:log("Got data via direct access")
    end
    

    if success then
        local statusText = taxData.enabled and "ENABLED" or "DISABLED"
        local statusColor = taxData.enabled and {0, 1, 0, 1} or {1, 0, 0, 1}
        
        table.insert(self.ui.appTexts, {
            text = "Status: " .. statusText,
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = statusColor
        })
        

        local taxRateValue = taxData.taxRate or "medium"
        local taxRatePercent = (taxInstance:getTaxRate() or 0.02) * 100
        
        table.insert(self.ui.appTexts, {
            text = "Tax Rate: " .. taxRateValue .. " (" .. 
                   taxRatePercent .. "%)",
            x = content.x + padX,
            y = titleY - 0.060,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        

        local returnPercent = taxData.returnPercentage or 20
        
        table.insert(self.ui.appTexts, {
            text = "Return %: " .. returnPercent .. "%",
            x = content.x + padX,
            y = titleY - 0.085,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = self.UI_CONSTANTS.TEXT_COLOR
        })
        

        if taxData.stats and taxData.stats.totalTaxesPaid then
            local moneyFunc = taxInstance.formatMoney or formatMoney
            table.insert(self.ui.appTexts, {
                text = "Total Taxes Paid: " .. moneyFunc(taxData.stats.totalTaxesPaid),
                x = content.x + padX,
                y = titleY - 0.120,
                size = 0.014,
                align = RenderText.ALIGN_LEFT,
                color = {0.8, 0.8, 0.8, 1}
            })
        end
        

        local buttonWidth = 0.20
        local buttonHeight = 0.04
        local buttonY = titleY - 0.180
        

        local enableX = content.x + padX
        local enableButton = self:createBlankOverlay(
            enableX,
            buttonY,
            buttonWidth,
            buttonHeight,
            {0.3, 0.6, 0.3, 0.9}
        )
        enableButton:setVisible(true)
        table.insert(self.ui.overlays, enableButton)
        
        self.ui.enableTaxButton = {
            overlay = enableButton,
            x = enableX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        }
        
        table.insert(self.ui.appTexts, {
            text = "Enable",
            x = enableX + buttonWidth / 2,
            y = buttonY + buttonHeight / 2 - 0.005,
            size = 0.014,
            align = RenderText.ALIGN_CENTER,
            color = {1, 1, 1, 1}
        })
        
        -- Disable button
        local disableX = enableX + buttonWidth + padX
        local disableButton = self:createBlankOverlay(
            disableX,
            buttonY,
            buttonWidth,
            buttonHeight,
            {0.8, 0.3, 0.3, 0.9}
        )
        disableButton:setVisible(true)
        table.insert(self.ui.overlays, disableButton)
        
        self.ui.disableTaxButton = {
            overlay = disableButton,
            x = disableX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        }
        
        table.insert(self.ui.appTexts, {
            text = "Disable",
            x = disableX + buttonWidth / 2,
            y = buttonY + buttonHeight / 2 - 0.005,
            size = 0.014,
            align = RenderText.ALIGN_CENTER,
            color = {1, 1, 1, 1}
        })
    else

        table.insert(self.ui.appTexts, {
            text = "Could not load mod data",
            x = content.x + padX,
            y = titleY - 0.035,
            size = 0.016,
            align = RenderText.ALIGN_LEFT,
            color = {1, 0.5, 0, 1}
        })
    end
end

function FarmTablet:registerKeybind()
    self:log("Tablet keybind registered: " .. self.settings.tabletKeybind)
    -- InputBinding.registerKeyBinding("TOGGLE_TABLET", self.settings.tabletKeybind, nil, nil, self.toggleTablet, self)
end

-- =====================
-- SETTINGS & PAUSE MENU
-- =====================
function FarmTablet:tryRegisterSettings()
    if not self.hasRegisteredSettings then
        if g_modSettingsManager ~= nil then
            self:registerModSettings()
            self.hasRegisteredSettings = true
            self:log("Settings registered in pause menu")
        else
            self.settingsRetryTimer = 2000
            self:log("Settings page not available yet, use the console to configure settings")
        end
    end
end

function FarmTablet:registerModSettings()
    if g_modSettingsManager == nil then return false end

    local settings = {
        {
            key = "tabletEnabled",
            name = "tablet_enabled",
            tooltip = "tablet_enabled_tooltip",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.enabled,
            current = self.settings.enabled,
            onChange = function(value)
                self.settings.enabled = value
                self:saveSettingsToXML()
                self:log("Tablet Enabled: " .. tostring(value))
            end
        },
        {
            key = "tabletKeybind",
            name = "tablet_keybind",
            tooltip = "tablet_keybind_tooltip",
            type = "textinput",
            default = self.DEFAULT_CONFIG.tabletKeybind,
            current = self.settings.tabletKeybind,
            onChange = function(value)
                self.settings.tabletKeybind = value
                self:saveSettingsToXML()
                self:registerKeybind()
                self:log("Tablet Keybind: " .. value)
            end
        },
        {
            key = "tabletNotifications",
            name = "tablet_notifications",
            tooltip = "tablet_notifications_tooltip",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.showTabletNotifications,
            current = self.settings.showTabletNotifications,
            onChange = function(value)
                self.settings.showTabletNotifications = value
                self:saveSettingsToXML()
                self:log("Show Notifications: " .. tostring(value))
            end
        },
        {
            key = "tabletStartupApp",
            name = "tablet_startup_app",
            tooltip = "tablet_startup_app_tooltip",
            type = "list",
            default = self.DEFAULT_CONFIG.startupApp,
            current = self.settings.startupApp,
            values = {
                {name = "tablet_app_dashboard", value = "financial_dashboard"},
                {name = "tablet_app_store", value = "app_store"}
            },
            onChange = function(value)
                self.settings.startupApp = value
                self.currentApp = value
                self:saveSettingsToXML()
                self:log("Startup App: " .. value)
            end
        },
        {
            key = "tabletSoundEffects",
            name = "tablet_sound_effects",
            tooltip = "tablet_sound_effects_tooltip",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.soundEffects,
            current = self.settings.soundEffects,
            onChange = function(value)
                self.settings.soundEffects = value
                self:saveSettingsToXML()
                self:log("Sound Effects: " .. tostring(value))
            end
        },
        {
            key = "tabletDebug",
            name = "tablet_debug",
            tooltip = "tablet_debug_tooltip",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.debugMode,
            current = self.settings.debugMode,
            onChange = function(value)
                self.settings.debugMode = value
                self:saveSettingsToXML()
                self:log("Debug Mode: " .. tostring(value))
            end
        }
    }

    g_modSettingsManager:addModSettings(self.modName, settings, g_i18n:getText("tablet_category"))
    return true
end

-- =====================
-- CONSOLE COMMANDS
-- =====================
function FarmTablet:onConsoleCommand(...)
    local args = {...}

    if #args == 0 then
        print(g_i18n:getText("tablet_console_help"))
        return true
    end

    local action = args[1]:lower()

    if action == "status" then
        print("=== Farm Tablet Status ===")
        print("Enabled: " .. tostring(self.settings.enabled))
        print("Keybind: " .. self.settings.tabletKeybind)
        print("Current App: " .. self.currentApp)
        print("Registered Apps: " .. #self.registeredApps)
        print("Enabled Apps: " .. #self:getEnabledApps())
        print("Tablet Open: " .. tostring(self.isTabletOpen))
        
        print("\n=== Installed Apps ===")
        for _, app in ipairs(self:getEnabledApps()) do
            print("  • " .. g_i18n:getText(app.name) .. " v" .. app.version .. " by " .. app.developer)
        end
        
    elseif action == "open" then
        self:openTablet()
        print("Tablet opened")
        
    elseif action == "debugweather" then
        self:debugWeather()
        return true

    elseif action == "close" then
        self:closeTablet()
        print("Tablet closed")
        
    -- elseif action == "debugmods" then
    --     self:debugModDetection()
    --     return true
    
    elseif action == "toggle" then
        self:toggleTablet()
        print("Tablet toggled")
        
    elseif action == "app" and args[2] then
        local appId = args[2]:lower()
        if self:switchApp(appId) then
            print("Switched to app: " .. appId)
        else
            print("App not found or disabled: " .. appId)
        end
    elseif action == "debugfinance" then
        local farmId = self:getPlayerFarmId()
        self:debugFinancialData(farmId)
        return true
    
    elseif action == "apps" then
        print("=== Available Apps ===")
        for _, app in ipairs(self.registeredApps) do
            local status = app.enabled and "ENABLED" or "DISABLED"
            print("  • " .. app.id .. " - " .. g_i18n:getText(app.name) .. " [" .. status .. "]")
        end
        
    elseif action == "bucket" then
        local subcmd = args[2] or "status"
        
        if subcmd == "status" then
            print("=== Bucket Tracker Status ===")
            print("Enabled: " .. tostring(self.bucketTracker.isEnabled))
            print("Total Loads: " .. self.bucketTracker.totalLoads)
            print("Total Weight: " .. self.bucketTracker.totalWeight .. " kg")
            print("Current Fill: " .. self.bucketTracker.currentFillLevel .. " L")
            
            if #self.bucketTracker.bucketHistory > 0 then
                print("\nRecent Loads:")
                for i = math.max(1, #self.bucketTracker.bucketHistory - 4), #self.bucketTracker.bucketHistory do
                    local load = self.bucketTracker.bucketHistory[i]
                    print(string.format("  #%d: %dL %s (%d kg)", 
                        load.number, load.volume, load.fillType, load.weight))
                end
            end
            
        elseif subcmd == "reset" then
            self:resetBucketTracker()
            print("Bucket tracker reset")
            
        elseif subcmd == "enable" then
            self.bucketTracker.isEnabled = true
            print("Bucket tracker enabled")
            
        elseif subcmd == "disable" then
            self.bucketTracker.isEnabled = false
            print("Bucket tracker disabled")
            
        else
            print("Usage: tablet bucket [status|reset|enable|disable]")
        end

    elseif action == "enable" and args[2] then
        local appId = args[2]:lower()
        local app = self:getApp(appId)
        if app then
            app.enabled = true
            print("App enabled: " .. appId)
            if self.isTabletOpen then
                self:createAppNavigationButtons()
            end
        else
            print("App not found: " .. appId)
        end
        
    elseif action == "disable" and args[2] then
        local appId = args[2]:lower()
        local app = self:getApp(appId)
        if app then
            app.enabled = false
            print("App disabled: " .. appId)
            if self.isTabletOpen then
                self:createAppNavigationButtons()
            end
        else
            print("App not found: " .. appId)
        end
        
    elseif action == "keybind" and args[2] then
        self.settings.tabletKeybind = args[2]
        self:registerKeybind()
        self:saveSettingsToXML()
        print("Keybind set to: " .. args[2])
        
    elseif action == "debug" then
        self.settings.debugMode = not self.settings.debugMode
        self:saveSettingsToXML()
        print("Debug mode: " .. tostring(self.settings.debugMode))
        
    elseif action == "reload" then
        self:loadSettingsFromXML()
        print("Settings reloaded from XML")
        
    elseif action == "register" and args[2] then
        local testApp = {
            id = args[2],
            name = "tablet_app_" .. args[2],
            icon = "test_icon",
            developer = "Manual",
            version = "1.0",
            enabled = true
        }
        if self:registerApp(testApp) then
            print("App registered: " .. args[2])
        else
            print("Failed to register app")
        end
        
    else
        print("Unknown command. Type 'tablet' for help.")
    end

    return true
end

-- =====================
-- INPUT HANDLING
-- =====================
function FarmTablet:mouseEvent(posX, posY, isDown, isUp, button) 
    if not self.isTabletOpen or not isDown then
        return
    end
    
    if self.ui.closeButton then
        local btn = self.ui.closeButton
        if posX >= btn.x and posX <= btn.x + btn.width and
           posY >= btn.y and posY <= btn.y + btn.height then
            self:closeTablet()
            return true
        end
    end
    
    for _, buttonInfo in ipairs(self.ui.appButtons) do
        if posX >= buttonInfo.x and posX <= buttonInfo.x + buttonInfo.width and
           posY >= buttonInfo.y and posY <= buttonInfo.y + buttonInfo.height then
            self:switchApp(buttonInfo.appId)
            return true
        end
    end
    
    if self.currentApp == "workshop" and self.ui.workshopButton then
        local b = self.ui.workshopButton
        if posX >= b.x and posX <= b.x + b.width and
        posY >= b.y and posY <= b.y + b.height then
            self:openWorkshopForNearestVehicle(6)
            return true
        end
    end

    if self.currentApp == "income_mod" then
        if self.ui.enableIncomeButton then
            local b = self.ui.enableIncomeButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local incomeInstance = g_IncomeMod or _G["Income"]
                if incomeInstance and incomeInstance.openFromTablet then
                    incomeInstance:openFromTablet("enable")
                    self:switchApp("income_mod")
                end
                return true
            end
        end
        
        if self.ui.disableIncomeButton then
            local b = self.ui.disableIncomeButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local incomeInstance = g_IncomeMod or _G["Income"]
                if incomeInstance and incomeInstance.openFromTablet then
                    incomeInstance:openFromTablet("disable")
                    self:switchApp("income_mod")
                end
                return true
            end
        end
    end
    
    if self.currentApp == "tax_mod" then
        if self.ui.enableTaxButton then
            local b = self.ui.enableTaxButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local taxInstance = g_TaxMod or _G["TaxMod"]
                if taxInstance and taxInstance.openFromTablet then
                    taxInstance:openFromTablet("enable")
                    self:switchApp("tax_mod")
                end
                return true
            end
        end
        
        if self.ui.disableTaxButton then
            local b = self.ui.disableTaxButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                local taxInstance = g_TaxMod or _G["TaxMod"]
                if taxInstance and taxInstance.openFromTablet then
                    taxInstance:openFromTablet("disable")
                    self:switchApp("tax_mod")
                end
                return true
            end
        end
    end
    
    -- Handle Tax Mod buttons
    if self.currentApp == "tax_mod" then
        if self.ui.enableTaxButton then
            local b = self.ui.enableTaxButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                if TaxMod then
                    TaxMod.settings.enabled = true
                    TaxMod:saveSettingsToXML()
                    self:switchApp("tax_mod")
                end
                return true
            end
        end
        
        if self.ui.disableTaxButton then
            local b = self.ui.disableTaxButton
            if posX >= b.x and posX <= b.x + b.width and
               posY >= b.y and posY <= b.y + b.height then
                if TaxMod then
                    TaxMod.settings.enabled = false
                    TaxMod:saveSettingsToXML()
                    self:switchApp("tax_mod")
                end
                return true
            end
        end
    end

    return false
end

function FarmTablet:draw()
    if not self.isTabletOpen then
        return
    end

    for _, overlay in ipairs(self.ui.overlays or {}) do
        overlay:render()
    end

    for _, t in ipairs(self.ui.texts or {}) do
        setTextAlignment(t.align)
        setTextColor(unpack(t.color))
        renderText(t.x, t.y, t.size, t.text)
    end
    
    for _, t in ipairs(self.ui.appTexts or {}) do
        setTextAlignment(t.align)
        setTextColor(unpack(t.color))
        renderText(t.x, t.y, t.size, t.text)
    end

    setTextAlignment(RenderText.ALIGN_LEFT)
end

-- =====================
-- MOD EVENTS
-- =====================
function FarmTablet:deleteMap()
    self.isLoaded = false
    self.hasRegisteredSettings = false
    self.isTabletOpen = false
    
    self:destroyTabletUI()
end

-- =====================
-- PUBLIC API FOR OTHER MODS
-- =====================
function FarmTablet.registerAsApp(modInstance, appData)
    if FarmTablet.isLoaded then
        return FarmTablet:registerApp(appData)
    end
    return false
end

function FarmTablet.sendNotification(title, message)
    if FarmTablet.isLoaded then
        FarmTablet:showNotification(title, message)
    end
end

function FarmTablet.getCurrentApp()
    if FarmTablet.isLoaded then
        return FarmTablet.currentApp
    end
    return nil
end

-- =====================
-- REGISTER MOD
-- =====================
addModEventListener(FarmTablet)

-- =====================
-- GLOBAL ACCESS
-- =====================
g_farmTablet = FarmTablet
