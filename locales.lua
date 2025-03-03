local MCL, core = ...
local AceLocale = LibStub("AceLocale-3.0")

core.L = AceLocale:GetLocale("MCL", true)  -- 'true' ensures fallback to enUS if needed

print("Locale HELLO: " .. core.L["Zone"])  -- Should print the zhCN version if working