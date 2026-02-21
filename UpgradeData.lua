AursUpgradeInfo_NextUpgradeCostByLevel = {
  [1] = 20,  -- 1/6 → 2/6
  [2] = 20,  -- 2/6 → 3/6
  [3] = 20,  -- 3/6 → 4/6
  [4] = 20,  -- 4/6 → 5/6
  [5] = 20,  -- 5/6 → 6/6
  -- [6] = nil (max)
}

crests = {
  [1] = { shortName = "Adventurer Dawncrest", color = UNCOMMON_GREEN_COLOR },
  [2] = { shortName = "Veteran Dawncrest", color = RARE_BLUE_COLOR },
  [3] = { shortName = "Champion Dawncrest", color = ITEM_EPIC_COLOR },
  [4] = { shortName = "Hero Dawncrest", color = ITEM_LEGENDARY_COLOR },
  [5] = { shortName = "Myth Dawncrest", color = HEIRLOOM_BLUE_COLOR },
}

upgradeTiers = {
  { name = "Adventurer", crestType = 1 },
  { name = "Veteran", crestType = 2 },
  { name = "Champion", crestType = 3 },
  { name = "Hero", crestType = 4 },
  { name = "Myth", crestType = 5 },
}
