-- Get tier data for Midnight (crestType only)
local function GetUpgradeTierData(tierName)
  for _, tier in ipairs(upgradeTiers) do
    if tier.name == tierName then
      local crest = tier.crestType and crests[tier.crestType] or nil
      return {
        name = tier.name,
        crest = crest,
      }
    end
  end
  return nil
end

local function GetCurrencyCount(crest)
  if not C_CurrencyInfo then
    return 0
  end
  for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
    local currencyInfo = C_CurrencyInfo.GetCurrencyListInfo(i)
    if currencyInfo and currencyInfo.name then
      local name = currencyInfo.name
      -- Match "Adventurer Dawncrest" or "Adventurer's Dawncrest" etc.
      if string.find(name, crest.shortName, 1, true) then
        return currencyInfo.quantity or 0
      end
      local tierWord = crest.shortName:match("^%S+") -- e.g. "Adventurer"
      if tierWord and string.find(name, "Dawncrest", 1, true) and string.find(name, tierWord, 1, true) then
        return currencyInfo.quantity or 0
      end
    end
  end
  return 0
end

-- Resolve ItemLocation from itemLink (bags then equipment) for C_ItemUpgrade
local function GetItemLocationFromLink(itemLink)
  local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
  if not itemID then
    return nil
  end
  for bag = 0, NUM_BAG_SLOTS do
    local numSlots = C_Container.GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      local slotItemID = C_Container.GetContainerItemID(bag, slot)
      if slotItemID == itemID then
        local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
        if location and location:IsValid() then
          return location
        end
      end
    end
  end
  for slot = 1, 19 do
    local invItemID = GetInventoryItemID("player", slot)
    if invItemID == itemID then
      local location = ItemLocation:CreateFromEquipmentSlot(slot)
      if location and location:IsValid() then
        return location
      end
    end
  end
  return nil
end

-- Get cost for next upgrade: prefer API (when item in bags/equipped), else tooltip scan (current/total) + static table.
local function GetNextUpgradeCost(itemLocation, currentLevel, totalLevel)
  currentLevel = tonumber(currentLevel) or 0
  totalLevel = tonumber(totalLevel) or 6
  if currentLevel >= totalLevel then
    return 0 -- maxed
  end

  -- API: when we have a valid item location, use game data
  if C_ItemUpgrade and itemLocation and itemLocation:IsValid() then
    if C_ItemUpgrade.CanUpgradeItem(itemLocation) then
      local info = C_ItemUpgrade.GetItemUpgradeItemInfo(itemLocation)
      if info then
        if info.upgradeCost and type(info.upgradeCost) == "number" and info.upgradeCost > 0 then
          return info.upgradeCost
        end
        local season = C_ItemUpgrade.GetCurrentItemUpgradeSeason and C_ItemUpgrade.GetCurrentItemUpgradeSeason()
        if season and info.upgradeCostTypesForSeasonIndex and info.upgradeCostTypesForSeason then
          local idx = info.upgradeCostTypesForSeasonIndex[season]
          if idx and info.upgradeCostTypesForSeason[idx] then
            local cost = info.upgradeCostTypesForSeason[idx]
            if type(cost) == "number" and cost > 0 then
              return cost
            end
          end
        end
      end
    end
  end

  -- Item scan / tooltip: use Midnight per-level table 
  local costByLevel = AursUpgradeInfo_NextUpgradeCostByLevel
  if costByLevel and costByLevel[currentLevel] then
    return costByLevel[currentLevel]
  end
  return 0
end

local function OnTooltipSetItem(tooltip, data)
  local _, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
  if not itemLink then
    return
  end
  local item = Item:CreateFromItemLink(itemLink)
  if item:IsItemEmpty() then
    return
  end

  local itemLocation = GetItemLocationFromLink(itemLink)

  for i = 1, tooltip:NumLines() do
    local line = _G[tooltip:GetName() .. "TextLeft" .. i]
    local text = line and line:GetText()

    if text and string.find(text, "Upgrade Level:") then
      local tier, current, total = text:match("Upgrade Level: (.+) (%d+)/(%d+)")
      local tierData = GetUpgradeTierData(tier)
      if not tierData then
        return
      end

      if tierData.crest then
        local nextCost = GetNextUpgradeCost(itemLocation, current, total)
        local currencyCount = GetCurrencyCount(tierData.crest)
        local crestColor = tierData.crest.color
        local coloredCrestName = crestColor:WrapTextInColorCode(tierData.crest.shortName)

        local haveColor = (nextCost and currencyCount >= nextCost) and GREEN_FONT_COLOR or RED_FONT_COLOR
        local haveText = haveColor:WrapTextInColorCode(tostring(currencyCount))
        local costLabel = NORMAL_FONT_COLOR:WrapTextInColorCode("Have: ")
        local rightParts = { costLabel, haveText }

        if nextCost and nextCost > 0 then
          local nextLabel = NORMAL_FONT_COLOR:WrapTextInColorCode(" | Next: ")
          local nextText = NORMAL_FONT_COLOR:WrapTextInColorCode(tostring(nextCost))
          table.insert(rightParts, nextLabel)
          table.insert(rightParts, nextText)
        end

        line:SetText(string.format("%s %s/%s", tierData.name, current, total))
        local rightLine = _G[tooltip:GetName() .. "TextRight" .. i]
        if rightLine then
          rightLine:SetText(table.concat(rightParts) .. " " .. coloredCrestName)
          rightLine:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
          rightLine:Show()
        end
      end
    end
  end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
