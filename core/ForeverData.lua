--------------------------------------------------------
-- Mount data for World of Warcraft: Forever
--------------------------------------------------------
-- Loaded by MCL_Forever.toc in place of core/data.lua.  Forever's mount
-- table is its own: of the 144 mounts in the client, 99 are shared with
-- retail and 45 exist only here, and the two sets do not share a
-- collection -- a mount earned in Forever does not appear on retail.
-- Generated from wago.tools Mount.db2 for build 1.60.1.70862.
--
-- Every entry is keyed by "m<mountJournalID>".  Forever's Mount.db2
-- carries no SourceText_lang at all and most rows report SourceTypeEnum
-- -1, so there is no source data in the client to read; the journal ID is
-- also the one key MCL resolves without an item or spell lookup, which
-- matters on a client this addon has not been able to test against.
--
-- Sources come from warcraft.wiki.gg, which days after launch documents
-- only a fraction of them.  Anything Blizzard has not revealed sits in
-- the Unconfirmed section rather than being guessed at from the mount's
-- name.
--
-- Sections are flat and named for how a mount is obtained.  Forever has
-- one expansion and will only ever have one, so nothing here sets
-- isExpansion: an expansion grid of one icon is not a grouping, and the
-- nav draws labelled rows instead.
--------------------------------------------------------
local _, MCLcore = ...;

MCLcore.sectionNames = {}
MCLcore.mountList = {}

MCLcore.mountList[1] = {
	name = "Alliance",
	categories = {
		Human = {
			name = "Human",
			mounts = {"m6", "m8", "m9", "m11", "m18", "m91", "m92", "m93"},
			mountID = {}
		},
		Dwarf = {
			name = "Dwarf",
			mounts = {"m21", "m22", "m24", "m25", "m94", "m95", "m96"},
			mountID = {}
		},
		Gnome = {
			name = "Gnome",
			mounts = {"m39", "m40", "m43", "m57", "m58", "m88", "m89", "m90"},
			mountID = {}
		},
		NightElf = {
			name = "Night Elf",
			mounts = {"m26", "m31", "m32", "m34", "m2995", "m85", "m87", "m107"},
			mountID = {}
		},
		Skyborne = {
			name = "Skyborne",
			mounts = {"m2955", "m2957", "m2958", "m2997", "m2952", "m2953", "m2954", "m2998"},
			mountID = {}
		},
	}
}
MCLcore.mountList[2] = {
	name = "Horde",
	categories = {
		Orc = {
			name = "Orc",
			mounts = {"m7", "m12", "m13", "m14", "m15", "m19", "m20", "m104", "m105", "m106"},
			mountID = {}
		},
		Troll = {
			name = "Troll",
			mounts = {"m27", "m35", "m36", "m38", "m97", "m98", "m99"},
			mountID = {}
		},
		Tauren = {
			name = "Tauren",
			mounts = {"m70", "m71", "m72", "m3037", "m101", "m102", "m103"},
			mountID = {}
		},
		Undead = {
			name = "Undead",
			mounts = {"m28", "m65", "m66", "m67", "m3038", "m68", "m100"},
			mountID = {}
		},
		Skyborne = {
			name = "Skyborne",
			mounts = {"m2955", "m2957", "m2958", "m2997", "m2952", "m2953", "m2954", "m2998"},
			mountID = {}
		},
	}
}
MCLcore.mountList[3] = {
	name = "Reputation",
	categories = {
		Reputation = {
			name = "Reputation",
			mounts = {"m55", "m311", "m3067"},
			mountID = {}
		},
	}
}
MCLcore.mountList[4] = {
	name = "Dungeons & Raids",
	categories = {
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {"m69"},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {"m110", "m111", "m117", "m118", "m119", "m120"},
			mountID = {}
		},
	}
}
MCLcore.mountList[5] = {
	name = "PVP",
	categories = {
		PvPRewards = {
			name = "PvP Rewards",
			mounts = {"m75", "m76", "m77", "m78", "m79", "m80", "m81", "m82", "m108", "m109"},
			mountID = {}
		},
	}
}
MCLcore.mountList[6] = {
	name = "Class",
	categories = {
		Paladin = {
			name = "Paladin",
			mounts = {"m41", "m84", "m2923", "m3001"},
			mountID = {}
		},
		Warlock = {
			name = "Warlock",
			mounts = {"m17", "m83"},
			mountID = {}
		},
	}
}
MCLcore.mountList[7] = {
	name = "Rewards",
	categories = {
		Legacy = {
			name = "Legacy",
			mounts = {"m3085"},
			mountID = {}
		},
		Shop = {
			name = "Shop",
			mounts = {"m3111", "m3130"},
			mountID = {}
		},
	}
}
MCLcore.mountList[8] = {
	name = "Unconfirmed",
	categories = {
		SkeletalHorses = {
			name = "Skeletal Horses",
			mounts = {"m2918", "m2919", "m2920", "m2996"},
			mountID = {}
		},
		Kodos = {
			name = "Kodos",
			mounts = {"m3089"},
			mountID = {}
		},
	}
}

MCLcore.sectionNames[1] = {
	name = "Alliance",
	mounts = MCLcore.mountList[1],
	icon = "Interface\\AddOns\\MCL\\icons\\alliance.blp",
	isExpansion = false,
}
MCLcore.sectionNames[2] = {
	name = "Horde",
	mounts = MCLcore.mountList[2],
	icon = "Interface\\AddOns\\MCL\\icons\\horde.blp",
	isExpansion = false,
}
MCLcore.sectionNames[3] = {
	name = "Reputation",
	mounts = MCLcore.mountList[3],
	icon = "Interface\\AddOns\\MCL\\icons\\classic.blp",
	isExpansion = false,
}
MCLcore.sectionNames[4] = {
	name = "Dungeons & Raids",
	mounts = MCLcore.mountList[4],
	icon = "Interface\\AddOns\\MCL\\icons\\wrath.blp",
	isExpansion = false,
}
MCLcore.sectionNames[5] = {
	name = "PVP",
	mounts = MCLcore.mountList[5],
	icon = "Interface\\AddOns\\MCL\\icons\\pvp.blp",
	isExpansion = false,
}
MCLcore.sectionNames[6] = {
	name = "Class",
	mounts = MCLcore.mountList[6],
	icon = "Interface\\AddOns\\MCL\\icons\\sl.blp",
	isExpansion = false,
}
MCLcore.sectionNames[7] = {
	name = "Rewards",
	mounts = MCLcore.mountList[7],
	icon = "Interface\\AddOns\\MCL\\icons\\other.blp",
	isExpansion = false,
}
MCLcore.sectionNames[8] = {
	name = "Unconfirmed",
	mounts = MCLcore.mountList[8],
	icon = "Interface\\AddOns\\MCL\\icons\\unobtainable.blp",
	isExpansion = false,
}
MCLcore.sectionNames[9] = {
	name = "Pinned",
	mounts = {MCL_PINNED},
	icon = "Interface\\AddOns\\MCL\\icons\\pin.blp",
	isExpansion = false,
}
MCLcore.sectionNames[10] = {
	name = "Hidden",
	mounts = {MCL_HIDDEN},
	icon = "Interface\\AddOns\\MCL\\icons\\unobtainable.blp",
	isExpansion = false,
	hiddenFromOverview = true,
}
MCLcore.sectionNames[11] = {
	name = "Overview",
	mounts = {},
	icon = "Interface\\AddOns\\MCL\\icons\\mcl.blp",
	isExpansion = false,
}

-- No regional mount restrictions are known for Forever.  main.lua indexes
-- this table by region, so it has to exist even when it is empty.
MCLcore.regionalFilter = {}

MCLcore.mountNotes = {
	["m75"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m76"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m77"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m78"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m79"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m80"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m81"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m82"] = "Requires PvP Rank 11 - Commander for the Alliance, Lieutenant General for the Horde - earned through Forever's Rank Points system. 100 gold.",
	["m108"] = "Requires exalted reputation with the Frostwolf Clan. 200 gold.",
	["m109"] = "Requires exalted reputation with the Stormpike Guard. 200 gold.",
	["m2918"] = "Exclusive to Forever. Blizzard has not revealed how this is obtained; source unconfirmed.",
	["m2919"] = "Horde only, level 60, requires Undead Horsemanship (1). Exclusive to Forever. Blizzard has not revealed how this is obtained; source unconfirmed.",
	["m2920"] = "Exclusive to Forever. Blizzard has not revealed how this is obtained; source unconfirmed.",
	["m2923"] = "Forsaken paladin mount. Forever's acquisition details have not been revealed.",
	["m2952"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 200g. Requires level 60 and Galestrider Riding (1).",
	["m2953"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 200g. Requires level 60 and Galestrider Riding (1).",
	["m2954"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 200g. Requires level 60 and Galestrider Riding (1).",
	["m2955"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 20g. Requires level 40 and Galestrider Riding (1).",
	["m2957"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 20g. Requires level 40 and Galestrider Riding (1).",
	["m2958"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 20g. Requires level 40 and Galestrider Riding (1).",
	["m2995"] = "Reward from the quest Your First Feline Friend. Alliance only, level 40, requires Tiger Riding (1).",
	["m2996"] = "Horde only, level 60, requires Undead Horsemanship (1). Exclusive to Forever. Blizzard has not revealed how this is obtained; source unconfirmed.",
	["m2997"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 20g. Requires level 40 and Galestrider Riding (1).",
	["m2998"] = "Skyborne racial mount, sold by Genn Fairweather on Zephras Isle. Both High Order Skyborne (Alliance) and Windshaper Skyborne (Horde) buy from him. Sold by Genn Fairweather for 200g. Requires level 60 and Galestrider Riding (1).",
	["m3001"] = "Forsaken paladin mount. Forever's acquisition details have not been revealed.",
	["m3037"] = "Reward from the quest Your First Riding Kodo.",
	["m3038"] = "Reward from the quest A Steed in Death as They Were in Life. Horde only, level 40, requires Undead Horsemanship (1).",
	["m3067"] = "Sold by Huey Sunnydale or Okamache for 6,000 Merchant's Favor. Requires exalted with Durotar Supply and Logistics or Azeroth Commerce Authority, level 60 and Journeyman Riding.",
	["m3085"] = "Reward for reaching 55 points in the Legacy system. Requires level 60 and Journeyman Riding.",
	["m3089"] = "Horde only, level 40, requires Kodo Riding (1). Exclusive to Forever. Blizzard has not revealed how this is obtained; source unconfirmed.",
	["m3111"] = "From the Skyborne Heroic Pack, Skyborne Epic Pack, the limited-time Warcraft Forever Collection, or the Forever Collector's Edition. Requires level 60 and Journeyman Riding.",
	["m3130"] = "From the Skyborne Epic Pack, the limited-time Warcraft Forever Collection, or the Forever Collector's Edition. Requires level 40 and Apprentice Riding.",
}

-- Rows present in the Forever client but deliberately not listed:
--   42    White Mechanostrider                   pre-1.4 epic mount, trade-in only
--   45    Nightsaber                             pre-1.4 epic mount, trade-in only
--   46    Frostsaber                             pre-1.4 epic mount, trade-in only
--   50    Red Wolf                               pre-1.4 epic mount, trade-in only
--   51    Arctic Wolf                            pre-1.4 epic mount, trade-in only
--   52    Palomino Stallion                      pre-1.4 epic mount, trade-in only
--   53    White Stallion                         pre-1.4 epic mount, trade-in only
--   54    Mottled Red Raptor                     pre-1.4 epic mount, trade-in only
--   56    Ivory Raptor                           pre-1.4 epic mount, trade-in only
--   62    Icy Blue Mechanostrider                pre-1.4 epic mount, trade-in only
--   63    Frost Ram                              pre-1.4 epic mount, trade-in only
--   64    Black Ram                              pre-1.4 epic mount, trade-in only
--   73    Green Kodo                             pre-1.4 epic mount, trade-in only
--   74    Teal Kodo                              pre-1.4 epic mount, trade-in only
--   116   Summon Black Qiraji Battle Tank        retail marks it Legacy; the player tank, journal 122, is not in Forever
--   121   Summon Black Qiraji Battle Tank        retail marks it Legacy; the player tank, journal 122, is not in Forever
--   125   Riding Turtle                          Trading Card Game redemption (Landro Longshot); Forever has no TCG
--   2971  Translocation                          not a mount
--   3112  [PH] Purple Prideclaw                  [PH] placeholder name
--   3113  [PH] Brown Prideclaw                   [PH] placeholder name
--   3114  [PH] White Blue Prideclaw              [PH] placeholder name
--   3126  Black Druid Moose Mount                druid forms, not collectible mounts
--   3127  White Druid Moose Mount                druid forms, not collectible mounts
--   3128  Green Druid Moose Mount                druid forms, not collectible mounts
--   3129  Gray Druid Moose Mount                 druid forms, not collectible mounts
--   2864  Golden Sabercat                        not shipped: its item is not in this build yet
--   2978  Swift Hyjal Stag                       not shipped: its item is not in this build yet
--   3090  Caravan Kodo                           not shipped: its item is not in this build yet
--   3115  Black Warden Saber Mount               not shipped: its item is not in this build yet
--   3116  Brown Warden Saber Mount               not shipped: its item is not in this build yet
--   3117  Gray Warden Saber Mount                not shipped: its item is not in this build yet
--   3118  White Warden Saber Mount               not shipped: its item is not in this build yet
--   3120  Black Devilsaur Mount                  not shipped: its item is not in this build yet
--   3121  Blue Devilsaur Mount                   not shipped: its item is not in this build yet
--   3122  Green Devilsaur Mount                  not shipped: its item is not in this build yet
--   3123  Purple Devilsaur Mount                 not shipped: its item is not in this build yet
--   3124  White Devilsaur Mount                  not shipped: its item is not in this build yet
--   3167  Verdant Sea Turtle                     not in the mount journal (/mcl audit, 2026-11-08)
--   3168  Crimson Rooster                        not in the mount journal (/mcl audit, 2026-11-08)
--   3169  Spectral Wolf Pack                     not in the mount journal (/mcl audit, 2026-11-08)
