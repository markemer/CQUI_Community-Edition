-- ===========================================================================
-- Base File
-- ===========================================================================
include("WorldViewIconsManager");
include("CQUICommon.lua");

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_CQUI_SetResourceIcon = SetResourceIcon;

-- ===========================================================================
-- CQUI Members
-- ===========================================================================
local CQUI_RESOURCEICONSTYLE_SOLID = 0;
local CQUI_RESOURCEICONSTYLE_TRANSPARENT = 1;
local CQUI_RESOURCEICONSTYLE_HIDDEN = 2;

local CQUI_ResourceIconStyle = CQUI_RESOURCEICONSTYLE_TRANSPARENT;

-- ===========================================================================
function print_debug(...)
    print_debug_masked(g_CQUI_DebugMask_World, ...)
end

-- ===========================================================================
function CQUI_GetSettingsValues()
    CQUI_ResourceIconStyle = GameConfiguration.GetValue("CQUI_ResourceDimmingStyle");
    if CQUI_ResourceIconStyle == nil then
        print("CQUI_ResourceIconStyle is nil!  Using default value (CQUI_RESOURCEICONSTYLE_TRANSPARENT).");
        CQUI_ResourceIconStyle = CQUI_RESOURCEICONSTYLE_TRANSPARENT;
    end
end

-- ===========================================================================
function CQUI_OnIconStyleSettingsUpdate()
    CQUI_GetSettingsValues();
    Rebuild();
end

-- ===========================================================================
function CQUI_IsResourceOptimalImproved(resourceInfo, pPlot)
    if table.count(resourceInfo.ImprovementCollection) > 0 then
        for _, improvement in ipairs(resourceInfo.ImprovementCollection) do
            local optimalTileImprovement = improvement.ImprovementType; --Represents the tile improvement that utilizes the resource most effectively
            local tileImprovement = GameInfo.Improvements[pPlot:GetImprovementType()]; --Can be nil if there is no tile improvement

            --If the tile improvement isn't nil, find the ImprovementType value
            if (tileImprovement ~= nil) then
                tileImprovement = tileImprovement.ImprovementType;
            end

            if tileImprovement == optimalTileImprovement then
                return true;
            end
        end
    end

    return false;
end

-- ===========================================================================
--  CQUI modified SetResourceIcon functiton : Improved resource icon dimming/hiding
-- ===========================================================================
function SetResourceIcon( pInstance:table, pPlot, type, state)
    BASE_CQUI_SetResourceIcon(pInstance, pPlot, type, state);
    CQUI_SetResourceIconStyle(pInstance, pPlot, type, state, CQUI_ResourceIconStyle);
end

-- ===========================================================================
function CQUI_SetResourceIconStyle(pInstance, pPlot, type, state, iconStyle)
    local resourceInfo = GameInfo.Resources[type];
    if (pPlot and resourceInfo ~= nil) then
        local resourceType:string = resourceInfo.ResourceType;
        local iconName = "ICON_" .. resourceType;
        if (state == RevealedState.REVEALED) then
            iconName = iconName .. "_FOW";
        end

        local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName, 256);
        if (textureSheet ~= nil) then
            if (pPlot:GetOwner() == Game.GetLocalPlayer()) then --Only affects plots we own
                if (iconStyle == CQUI_RESOURCEICONSTYLE_SOLID) then
                    pInstance.ResourceIcon:SetColor(1,1,1,1);
                elseif (iconStyle == CQUI_RESOURCEICONSTYLE_TRANSPARENT) then
                    if (CQUI_IsResourceOptimalImproved(resourceInfo, pPlot)) then
                        pInstance.ResourceIcon:SetColor(1,1,1,0.5);
                    else
                        pInstance.ResourceIcon:SetColor(nil);
                    end
                elseif (iconStyle == CQUI_RESOURCEICONSTYLE_HIDDEN) then
                    if (CQUI_IsResourceOptimalImproved(resourceInfo, pPlot)) then
                        pInstance.ResourceIcon:SetColor(1,1,1,0);
                    else
                        pInstance.ResourceIcon:SetColor(nil);
                    end
                end
            end
        end
    end
end

-- ===========================================================================
--  CQUI modified AddImprovementRecommendationsForCity functiton
--  Don't show builder recommandation, it's often stupid
-- ===========================================================================
function AddImprovementRecommendationsForCity( pCity:table, pSelectedUnit:table )
    return;
end

-- ===========================================================================
function CQUI_OnImprovementAdded(locationX, locationY)
    CQUI_OnImprovementChanged(locationX, locationY, true);
end

-- ===========================================================================
function CQUI_OnImprovementRemoved(locationX, locationY)
    CQUI_OnImprovementChanged(locationX, locationY, false);
end

-- ===========================================================================
function CQUI_OnImprovementChanged(locationX, locationY, isAdded)
    -- print_debug("CQUI_OnImprovementChanged ENTRY. x:"..locationX.."  y:"..locationY);

    local plot = Map.GetPlot(locationX, locationY);
    local resourceType = plot:GetResourceType();
    local plotIndex = Map.GetPlotIndex(locationX, locationY);
    local pInstance = GetInstanceAt(plotIndex);
    local iconStyle = CQUI_ResourceIconStyle;
    if (isAdded == false) then
        iconStyle = CQUI_RESOURCEICONSTYLE_SOLID;
    end

    CQUI_SetResourceIconStyle(pInstance, plot, resourceType, RevealedState.VISIBLE, iconStyle);
end

-- ===========================================================================
function Initialize()
    LuaEvents.CQUI_SettingsUpdate.Add( CQUI_OnIconStyleSettingsUpdate );
    LuaEvents.CQUI_SettingsInitialized.Add(CQUI_GetSettingsValues);
    Events.ImprovementAddedToMap.Add(CQUI_OnImprovementAdded);
    Events.ImprovementRemovedFromMap.Add(CQUI_OnImprovementRemoved);
end
Initialize();
