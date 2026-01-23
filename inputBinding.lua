FarmTabletInputBinding = {}

function FarmTabletInputBinding:keyEvent(unicode, sym, modifier, isDown)
    if not isDown then
        return
    end

    -- Hardcoded T key
    if sym == Input.KEY_t then
        if g_farmTablet ~= nil and g_farmTablet.toggleTablet ~= nil then
            g_farmTablet:toggleTablet()
            return true
        end
    end
end

function FarmTabletInputBinding:mouseEvent() end
function FarmTabletInputBinding:update() end
function FarmTabletInputBinding:draw() end

addModEventListener(FarmTabletInputBinding)
