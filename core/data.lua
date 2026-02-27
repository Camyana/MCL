--------------------------------------------------------
-- Namespaces
--------------------------------------------------------
local _, MCLcore = ...;

MCLcore.sectionNames = {}
MCLcore.mountList = {}

MCLcore.mountList[1] = {
	name = "SL",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {186654, 186637, 184183, 182596, 186653, 184166, 186655, 187673, "m1549", "m1576", 217612},
			mountID = {}
		},
		Adventures = {
			name = "Adventures",
			mounts = {183052, 183617, 183615, 183618},
			mountID = {}
		},
		CovenantFeature = {
			name = "Covenant Feature",
			mounts = {180726, 181316, 181300, 181317},
			mountID = {}
		},
		DailyActivities = {
			name = "Daily Activities",
			mounts = {182614, 182589, 186643, 186651, 186646, 188808},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {181819, 186638, "m1445"},
			mountID = {1445}
		},
		Kyrian = {
			name = "Kyrian",
			mounts = {180761, 180762, 180763, 180764, 180765, 180766, 180767, 180768, 186482, 186485, 186480, 186483},
			mountID = {}
		},
		MawAssaults = {
			name = "Maw Assaults",
			mounts = {185996, 186000, 186103},
			mountID = {}
		},
		Necrolords = {
			name = "Necrolords",
			mounts = {182078, 182077, 181822, 182076, 182075, 181821, 181815, 182074, 181820, 182080, 186487, 186488, 186490, 186489},
			mountID = {}
		},
		NightFae = {
			name = "Night Fae",
			mounts = {180263, 180721, 183053, 180722, 180413, 180415, 180414, 180723, 183801, 180724, 180730, 186493, 186494, 186495, 186492},
			mountID = {}
		},
		OozingNecrorayEgg = {
			name = "Oozing Necroray Egg",
			mounts = {184160, 184161, 184162},
			mountID = {}
		},
		ParagonReputation = {
			name = "Paragon Reputation",
			mounts = {182081, 183800, 186649, 186644, 186657, 186641},
			mountID = {}
		},
		ProtoformSynthesis = {
			name = "Protoform Synthesis",
			mounts = {187632, 187670, 187663, 187665, 187630, 187631, 187638, 187664, 187677, 187683, 190580, 187679, 187667, 187639, 188809, 187668, 188810, 187672, 187669, 187641, 187678, 187671, 187660, 187666},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {186656, 186642, 190768},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {180728, 180727, 180725, 182650, 180773, 182085, 184062, 182084, 182079, 180582, 183741, 184167, 187183, 186652, 186645, 186659, 187676, 190765},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {180729, 182082, 183518, 183740, 186647, 186648, 187629, 187640},
			mountID = {}
		},
		Riddles = {
			name = "Riddles",
			mounts = {184168, 186713},
			mountID = {}
		},
		Torghast = {
			name = "Torghast",
			mounts = {188700, 188696, 188736},
			mountID = {}
		},
		Tormentors = {
			name = "Tormentors",
			mounts = {185973},
			mountID = {}
		},
		Treasures = {
			name = "Treasures",
			mounts = {180731, 180772, 190766},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {180748},
			mountID = {}
		},
		Venthyr = {
			name = "Venthyr",
			mounts = {182954, 180581, 180948, 183715, 180945, 182209, 182332, 183798, 180461, 186476, 186478, 186477, 186479},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {181818},
			mountID = {}
		},
	}
}
MCLcore.mountList[2] = {
	name = "BFA",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {168056, 168055, 169162, 163577, 169194, 168329, 161215, 163216, 166539, 167171, 174861, 174654, 235515},
			mountID = {}
		},
		AlliedRaces = {
			name = "Allied Races",
			mounts = {155662, 156487, 161330, 157870, 174066, 156486, 155656, 161331, 164762, 174067, 223572},
			mountID = {}
		},
		AssaultUldum = {
			name = "Assault: Uldum",
			mounts = {174769, 174641, 174753},
			mountID = {}
		},
		AssaultVale = {
			name = "Assault: Vale of Eternal Blossoms",
			mounts = {173887, 174752, 174841, 174840, 174649},
			mountID = {}
		},
		Dubloons = {
			name = "Dubloons",
			mounts = {166471, 166745},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {159921, 160829, 159842, 168826, 168830},
			mountID = {}
		},
		IslandExpedition = {
			name = "Island Expedition",
			mounts = {163584, 163585, 163583, 163586, 163582, 166470, 166468, 166467, 166466},
			mountID = {}
		},
		Medals = {
			name = "Medals",
			mounts = {166464, 166436, 166469, 166465, 166463},
			mountID = {}
		},
		ParagonReputation = {
			name = "Paragon Reputation",
			mounts = {169198},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {159146, 168827, 168408, 169199, 174859, 174771, 169200, 170069},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {166518, 166705, 174872},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {161479, 166433, 169201, 168370, 168823, 169163, 174860},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {161773, 161774, 161665, 161666, 161667, 161664, 167167, 167170, 168829, 174754, 161911, 161912, 161910, 161879, 161909, 161908},
			mountID = {}
		},
		Riddle = {
			name = "Riddle",
			mounts = {156798},
			mountID = {}
		},
		Tinkering = {
			name = "Tinkering",
			mounts = {167751},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {163183, 166442, 166443, 163589, 169203, 169202, 174770},
			mountID = {}
		},
		Visions = {
			name = "Visions",
			mounts = {174653},
			mountID = {}
		},
		WarfrontArathi = {
			name = "Warfront: Arathi",
			mounts = {163579, 163578, 163644, 163645, 163706, 163646},
			mountID = {}
		},
		WarfrontDarkshore = {
			name = "Warfront: Darkshore",
			mounts = {166438, 166434, 166435, 166432, 166428},
			mountID = {}
		},
		WorldBoss = {
			name = "World Boss",
			mounts = {174842},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {163576, 163574, 163575, 163573},
			mountID = {}
		},
	}
}
MCLcore.mountList[3] = {
	name = "LEGION",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {141216, 138387, 141217, 143864, 152815, 153041, 129280},
			mountID = {}
		},
		Class = {
			name = "Class",
			mounts = {142231, 143502, 143503, 143505, 143504, 143493, 143492, 143490, 143491, 142225, 142232, 143489, 142227, 142228, 142226, 142233, 143637, "m868", "m860", "m861", "m898"},
			mountID = {868, 860, 861, 898}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {142236, 142552},
			mountID = {}
		},
		ParagonReputation = {
			name = "Paragon Reputation",
			mounts = {147806, 147804, 147807, 147805, 143764, 153042, 153044, 153043},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {137573, 142436, 137577, 137578, 137579, 137580},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {137574, 143643, 152816, 137575, 152789},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {138258, 152814, 152844, 152842, 152840, 152841, 152843, 152904, 152905, 152903, 152790},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {152788, 152797, 152793, 152795, 152794, 152796, 152791},
			mountID = {}
		},
		Riddle = {
			name = "Riddle",
			mounts = {138201, 147835, 151623},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {138811, 141713, 137570},
			mountID = {}
		},
	}
}
MCLcore.mountList[4] = {
	name = "WOD",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {116670, 116383, 127140, 128706},
			mountID = {}
		},
		FishingShack = {
			name = "Fishing Shack",
			mounts = {87791},
			mountID = {}
		},
		Garrison = {
			name = "Garrison",
			mounts = {116779, 116673, 116786, 116663},
			mountID = {}
		},
		Missions = {
			name = "Missions",
			mounts = {116769, 128311},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {116660, 123890},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {116674, 116659, 116661, 116792, 116767, 116773, 116794, 121815, 116780, 116669, 116658},
			mountID = {}
		},
		Stables = {
			name = "Stables",
			mounts = {116784, 116662, 116676, 116675, 116774, 116656, 116668, 116781},
			mountID = {}
		},
		TradingPost = {
			name = "Trading Post",
			mounts = {116782, 116665},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {116664, 116785, 116772, 116672, 116768, 116671, 128480, 128526, 123974, 116667, 116655},
			mountID = {}
		},
		WorldBoss = {
			name = "World Boss",
			mounts = {116771},
			mountID = {}
		},
	}
}
MCLcore.mountList[5] = {
	name = "MOP",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {87769, 87773, 81559, 93662, 104208, 89785},
			mountID = {}
		},
		CloudSerpent = {
			name = "Order of the Cloud Serpent",
			mounts = {85430, 85429, 79802},
			mountID = {}
		},
		GoldenLotus = {
			name = "Golden Lotus",
			mounts = {87781, 87782, 87783},
			mountID = {}
		},
		KunLai = {
			name = "Kun-Lai Vendor",
			mounts = {87788, 87789, 84101},
			mountID = {}
		},
		PrimalEggs = {
			name = "Primal Eggs",
			mounts = {94291, 94292, 94293},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {93386, 87768, 94290, 93385},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {87777, 93666, 95059, 104253},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {90655, 94229, 94230, 94231},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {93169, 95565, 81354, 89304, 85262, 89363, 87774, 93168, 95564},
			mountID = {}
		},
		ShadoPan = {
			name = "Shado-Pan",
			mounts = {89305, 89306, 89307},
			mountID = {}
		},
		TheTillers = {
			name = "The Tillers",
			mounts = {89362, 89390, 89391},
			mountID = {}
		},
		WorldBoss = {
			name = "World Boss",
			mounts = {94228, 87771, 89783, 95057, 104269},
			mountID = {}
		},
	}
}
MCLcore.mountList[6] = {
	name = "CATA",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {62900, 62901, 69213, 69230, 77068},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {69747, 63040, 63043, 68823, 68824},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {54465},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {77067, 77069, 78919, 63041, 69224, 71665},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {67151, 63042, 63046},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {65356, 64999, 63044, 63045, 64998},
			mountID = {}
		},
	}
}
MCLcore.mountList[7] = {
	name = "WOTLK",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {44160, 45801, 45802, 51954, 51955},
			mountID = {}
		},
		ArgentTournament = {
			name = "Argent Tournament",
			mounts = {46814, 45592, 45593, 45595, 45596, 45597, 46743, 46746, 46749, 46750, 46751, 46816, 47180, 45725, 45125, 45586, 45589, 45590, 45591, 46744, 46745, 46747, 46748, 46752, 46815, 46813},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {43951, 44151},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {43962, 52200},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {43952, 43953, 43954, 43986, 49636, 43959, 45693, 50818, 44083, 206585},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {44168},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {44080, 44086, 43955, 44707, 43958, 43961},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {44690, 44231, 44234, 44226, 44689, 44230, 44235, 44225},
			mountID = {}
		},
	}
}
MCLcore.mountList[8] = {
	name = "TBC",
	categories = {
		CenarionExpedition = {
			name = "Cenarion Expedition",
			mounts = {33999},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {32768, 35513},
			mountID = {}
		},
		Kurenai = {
			name = "Kurenai/The Mag'har",
			mounts = {29227, 29231, 29229, 29230, 31830, 31832, 31834, 31836},
			mountID = {}
		},
		Netherwing = {
			name = "Netherwing",
			mounts = {32858, 32859, 32857, 32860, 32861, 32862},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {32458, 30480},
			mountID = {}
		},
		Shatari = {
			name = "Sha'tari Skyguard",
			mounts = {32319, 32314, 32316, 32317, 32318},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {25473, 25527, 25528, 25529, 25470, 25471, 25472, 25477, 25531, 25532, 25533, 25474, 25475, 25476},
			mountID = {}
		},
	}
}
MCLcore.mountList[9] = {
	name = "Classic",
	categories = {
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {13335},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {21218, 21321, 21323, 21324},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {13086, 46102},
			mountID = {}
		},
	}
}
MCLcore.mountList[10] = {
	name = "Alliance",
	categories = {
		DarkIronDwarf = {
			name = "Dark Iron Dwarf",
			mounts = {191123},
			mountID = {}
		},
		Dracthyr = {
			name = "Dracthyr",
			mounts = {201720, 201702, 201719, 201704, 198809, 198811, 198810, 198808},
			mountID = {}
		},
		Draenei = {
			name = "Draenei",
			mounts = {29745, 29746, 29747, 28481, 29743, 29744},
			mountID = {}
		},
		Dwarf = {
			name = "Dwarf",
			mounts = {18785, 18786, 18787, 5864, 5872, 5873},
			mountID = {}
		},
		Gnome = {
			name = "Gnome",
			mounts = {18772, 18773, 18774, 8563, 8595, 13322, 13321},
			mountID = {}
		},
		Haranir = {
			name = "Haranir",
			mounts = {246736},
			mountID = {}
		},
		Human = {
			name = "Human",
			mounts = {18776, 18777, 18778, 5655, 2411, 2414, 5656},
			mountID = {}
		},
		NightElf = {
			name = "Night Elf",
			mounts = {18766, 18767, 18902, 8629, 8631, 8632, 47100},
			mountID = {}
		},
		Pandaren = {
			name = "Pandaren",
			mounts = {91010, 91012, 91011, 91013, 91014, 91015, 91004, 91008, 91009, 91005, 91006, 91007},
			mountID = {}
		},
		Worgen = {
			name = "Worgen",
			mounts = {73839, 73838},
			mountID = {}
		},
	}
}
MCLcore.mountList[11] = {
	name = "Horde",
	categories = {
		Bloodelf = {
			name = "Blood Elf",
			mounts = {28936, 29223, 29224, 28927, 29220, 29221, 29222},
			mountID = {}
		},
		Dracthyr = {
			name = "Dracthyr",
			mounts = {201720, 201702, 201719, 201704, 198809, 198811, 198810, 198808},
			mountID = {}
		},
		Goblin = {
			name = "Goblin",
			mounts = {62462, 62461},
			mountID = {}
		},
		Haranir = {
			name = "Haranir",
			mounts = {246736},
			mountID = {}
		},
		Orc = {
			name = "Orc",
			mounts = {18796, 18798, 18797, 46099, 5668, 5665, 1132},
			mountID = {}
		},
		Pandaren = {
			name = "Pandaren",
			mounts = {91010, 91012, 91011, 91013, 91014, 91015, 91004, 91008, 91009, 91005, 91006, 91007},
			mountID = {}
		},
		Tauren = {
			name = "Tauren",
			mounts = {18793, 18794, 18795, 15277, 15290, 46100},
			mountID = {}
		},
		Troll = {
			name = "Troll",
			mounts = {18788, 18789, 18790, 8588, 8591, 8592},
			mountID = {}
		},
		Undead = {
			name = "Undead",
			mounts = {13334, 18791, 13331, 13332, 13333, 46308, 47101},
			mountID = {}
		},
	}
}
MCLcore.mountList[12] = {
	name = "Professions",
	categories = {
		Alchemy = {
			name = "Alchemy",
			mounts = {65891},
			mountID = {}
		},
		Archeology = {
			name = "Archeology",
			mounts = {60954, 64883, 131734},
			mountID = {}
		},
		Blacksmith = {
			name = "Blacksmith",
			mounts = {137686},
			mountID = {}
		},
		Engineering = {
			name = "Engineering",
			mounts = {34060, 41508, 34061, 44413, 87250, 87251, 95416, 161134, 153594, 221967},
			mountID = {}
		},
		Fishing = {
			name = "Fishing",
			mounts = {46109, 23720, 152912, 163131, 260916},
			mountID = {}
		},
		Jewelcrafting = {
			name = "Jewelcrafting",
			mounts = {83088, 83087, 83090, 83089, 82453, 235712},
			mountID = {}
		},
		Leatherworking = {
			name = "Leatherworking",
			mounts = {108883, 129962},
			mountID = {}
		},
		Tailoring = {
			name = "Tailoring",
			mounts = {44554, 54797, 44558, 115363},
			mountID = {}
		},
	}
}
MCLcore.mountList[13] = {
	name = "PVP",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {44223, 44224},
			mountID = {}
		},
		Ashran = {
			name = "Ashran",
			mounts = {116776, 116775},
			mountID = {}
		},
		Gladiator = {
			name = "Gladiator",
			mounts = {232617},
			mountID = {}
		},
		Halaa = {
			name = "Halaa",
			mounts = {28915, 29228},
			mountID = {}
		},
		Honor = {
			name = "Honor",
			mounts = {140228, 140233, 140408, 140232, 140230, 140407, 164250},
			mountID = {}
		},
		MarkHonor = {
			name = "Mark of Honor",
			mounts = {19030, 29465, 29467, 29468, 29471, 35906, 43956, 29466, 29469, 29470, 29472, 19029, 34129, 44077},
			mountID = {}
		},
		TalonsVengeance = {
			name = "Talon's Vengeance",
			mounts = {142369},
			mountID = {}
		},
		TimelessIsle = {
			name = "Timeless Isle",
			mounts = {103638},
			mountID = {}
		},
		ViciousSaddle = {
			name = "Vicious Saddle",
			mounts = {102533, 70910, 116778, 124540, 140348, 140354, 143649, 142235, 142437, 152869, 163124, 165020, 163121, 173713, 184013, 184014, 186179, 70909, 102514, 116777, 124089, 140353, 140350, 143648, 142234, 142237, 152870, 163123, 163122, 173714, 186178, 187681, 187680, 187642, 187644, 201788, 201789, 205245, 205246, 210070, 210069, 213439, 213440, 223511, 221813, 229989, 229988, 165019, 243157, 243159, 257502, 257504},
			mountID = {}
		},
	}
}
MCLcore.mountList[14] = {
	name = "WorldEvents",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {44177},
			mountID = {}
		},
		Brewfest = {
			name = "Brewfest",
			mounts = {33977, 37828, 248761},
			mountID = {}
		},
		DarkmoonFaire = {
			name = "Darkmoon Faire",
			mounts = {72140, 73766, 142398, 153485},
			mountID = {}
		},
		HallowsEnd = {
			name = "Hallow's End",
			mounts = {37012},
			mountID = {}
		},
		LoveAir = {
			name = "Love is in the Air",
			mounts = {72146, 50250, 210973, 232926},
			mountID = {}
		},
		Lunar = {
			name = "Lunar Festival",
			mounts = {232901},
			mountID = {}
		},
		NobleGarden = {
			name = "Noblegarden",
			mounts = {72145, 212599},
			mountID = {}
		},
		TimeWalking = {
			name = "Timewalking",
			mounts = {129923, 129922, 87775, 167894, 167895, 133543, 188674, 187595, 231374, 224398, 224399, 234730, 232624, 205208, 234721, 234716, 234740, 238739, 245694, 245695, 257513, 257514, 257516, 257511, 258515, 258488, 259463},
			mountID = {}
		},
		WinterVeil = {
			name = "Winter Veil",
			mounts = {128671},
			mountID = {}
		},
	}
}
MCLcore.mountList[15] = {
	name = "Promotion",
	categories = {
		AV = {
			name = "Timewalking Alterac Valley",
			mounts = {172023},
			mountID = {}
		},
		AzerothChoppers = {
			name = "Azeroth Choppers",
			mounts = {116789},
			mountID = {}
		},
		BlizzardStore = {
			name = "Blizzard Store",
			mounts = {54811, 69846, 78924, 97989, 107951, 112326, 122469, 147901, 156564, 160589, 166775, 166774, 166776, "m1266", "m1267", "m1290", "m1346", "m1291", "m1456", "m1330", "m1531", "m1581", "m1312", "m1594", "m1583", "m1797", 203727, "m1795", "m1692", 212229, 228751, 229128, 219450, 224574, "m2237", 229418, 230184, 230200, 230201, 230185, 227362, 235344, 231297, 233285, 233284, 233282, 233283, 233286, 238943, 238994, 238966, 221270, 190581, 212228, 225250, 206167, 246698, 247848, 258427, 258423, 258425, 243194, 248088, 242795, 252679, 252681, 258477, 248681, 239076, 262661},
			mountID = {1266, 1267, 1290, 1346, 1291, 1456, 1330, 1531, 1581}
		},
		CollectorsEdition = {
			name = "Collector's Edition",
			mounts = {85870, 109013, 128425, 153539, 153540, "m1289", 248089, 258479, 243019, 243020, 245610},
			mountID = {1289}
		},
		DiabloIV = {
			name = "Diablo IV",
			mounts = {"m1596", 246264, 191114},
			mountID = {}
		},
		Hearthstone = {
			name = "Hearthstone",
			mounts = {98618, "m1513", 163186, 212522},
			mountID = {1513}
		},
		LegionRemix = {
			name = "Legion Remix",
			mounts = {253026, 253024, 253027, 253032, 252954, 253029, 253031, 253033, 250728, 250760, 250758, 250759, 250761, 253025, 250192, 250757, 250429, 253028, 250428, 250723, 253030, 253013, 250803, 250804, 250747, 250426, 239667, 250191, 239665, 250746, 251795, 251796, 250745, 250425, 239686, 250752, 250427, 250726, 250424, 250805, 250806, 250802, 250748, 250727, 239666, 250423, 250721, 250321, 250756, 250751, 239687, 239647},
			mountID = {}
		},
		PlunderStorm = {
			name = "Plunderstorm",
			mounts = {233241, 233240, 233243, 233242, 226042},
			mountID = {}
		},
		ProductPromotion = {
			name = "Product Promotion",
			mounts = {"m1946", 211087},
			mountID = {}
		},
		RAF = {
			name = "Recruit-A-Friend",
			mounts = {173297, 173299, 204091},
			mountID = {}
		},
		TCG = {
			name = "Trading Card Game",
			mounts = {49283, 49284, 49285, 49286, 49282, 49290, 54069, 54068, 68008, 69228, 68825, 71718, 72582, 72575, 79771, 93671, 74269},
			mountID = {}
		},
		WarcraftIII = {
			name = "Warcraft III Reforged",
			mounts = {164571},
			mountID = {}
		},
		WowClassic = {
			name = "WoW Classic",
			mounts = {248090, 258475, 235287, 210008, 253573, 258476, 252950, 235286},
			mountID = {}
		},
		anniversary = {
			name = "WoW Anniversary Mounts",
			mounts = {172022, 186469, 208572, 228760, 229348, 223459, 223471, 258428},
			mountID = {}
		},
	}
}
MCLcore.mountList[16] = {
	name = "Other",
	categories = {
		BMAH = {
			name = "BMAH",
			mounts = {19872, 19902, 44175, 163042, 211084},
			mountID = {}
		},
		BrawlerGuild = {
			name = "Brawler's Guild",
			mounts = {259238, 259227},
			mountID = {}
		},
		CurrentTradingPost = {
			name = "Current Trading Post",
			mounts = {},
			mountID = {}
		},
		DeathKnight = {
			name = "Death Knight",
			mounts = {40775},
			mountID = {}
		},
		DemonHunter = {
			name = "Demon Hunter",
			mounts = {"m780"},
			mountID = {}
		},
		ExaltedReputations = {
			name = "Exalted Reputations",
			mounts = {163982},
			mountID = {}
		},
		GuildVendor = {
			name = "Guild Vendor",
			mounts = {63125, 62298, 67107, 85666, 116666},
			mountID = {}
		},
		Heirlooms = {
			name = "Heirlooms",
			mounts = {120968, 122703},
			mountID = {}
		},
		MountCollection = {
			name = "Mount Collection",
			mounts = {44178, 44843, 44842, 98104, 91802, 98259, 69226, 87776, 137614, 163981, 118676, 198654, 265656},
			mountID = {}
		},
		Paladin = {
			name = "Paladin",
			mounts = {47179, "m2233", "m41", "m84", "m149", "m150", "m350", "m351", "m367", "m368", "m1046", "m1047", "m1568", 191566},
			mountID = {}
		},
		Toy = {
			name = "Toy",
			mounts = {140500},
			mountID = {}
		},
		TradingPost = {
			name = "Trading Post",
			mounts = {190231, 190168, 190539, 190767, 190613, 206156, 137576, 208598, 211074, 210919, 212227, 212630, 212920, 192766, 226041, 226040, 226044, 226506, 223449, 223469, 187674, 233019, 233020, 233023, 233354, 212631, 223285, 221814, 207821, 190169, 189978, 206976, 206027, "m1595", 235646, 235650, 235555, 235556, 235554, 235657, 235557, 235658, 235659, 235662, 238967, 238897, 238941, 236415, 238902, 238901, 238968, 238900, 243593, 243597, 243594, 243590, 243572, 243591, 243592, 245936, 243596, 76755, 207964, 207963, 190636, 210141, 137615, 229951, 54860, 247791, 247793, 246919, 247794, 247792, 246921, 247795, 247722, 247720, 247721, 247723, 246917, 246920, 260580, 250108, 250106, 250926, 248994, 250928, 250929, 250927, 260409, 250105, 260896, 260893, 262707, 260894, 263451, 263452, 262706, 263449, 263450, 260895, 262708, 262705, 211085},
			mountID = {}
		},
		TradingPostTBA = {
			name = "Future Trading Post",
			mounts = {},
			mountID = {}
		},
		Warlock = {
			name = "Warlock",
			mounts = {"m17", "m83"},
			mountID = {17, 83}
		},
	}
}
MCLcore.mountList[17] = {
	name = "Unobtainable",
	categories = {
		AOTC = {
			name = "Ahead of the Curve",
			mounts = {104246, 128422, 152901, 174862, 190771},
			mountID = {}
		},
		Anniversary = {
			name = "Old Anniversary Mounts",
			mounts = {172012, 115484, "m1424"},
			mountID = {}
		},
		Arena = {
			name = "Arena Mounts",
			mounts = {30609, 34092, 37676, 43516, 46708, 46171, 47840, 50435, 71339, 71954, 85785, 95041, 104325, 104326, 104327, 128277, 128281, 128282, 141843, 141844, 141845, 141846, 141847, 141848, 153493, 156879, 156880, 156881, 156884, 183937, 186177, 189507, 191290, 202086, 205233, 210345, "m1822", 223586, 210077, 229987},
			mountID = {}
		},
		Brawl = {
			name = "Brawler's Guild",
			mounts = {142403, 98405, 166724},
			mountID = {}
		},
		BrewFest = {
			name = "BrewFest",
			mounts = {33976},
			mountID = {}
		},
		ChallengeMode = {
			name = "Challenge Mode",
			mounts = {89154, 90710, 90711, 90712, 116791},
			mountID = {}
		},
		DCAzerothChopper = {
			name = "Azeroth Choppers",
			mounts = {116788},
			mountID = {}
		},
		DastardlyDuos = {
			name = "Dastardly Duos",
			mounts = {239020},
			mountID = {}
		},
		MythicPlus = {
			name = "Mythic +",
			mounts = {182717, 187525, 174836, 187682, 192557, 199412, 204798, 209060, 213438, 226357, 235549, 237141, 247822, 248248},
			mountID = {}
		},
		OriginalEpic = {
			name = "Original Epic Mounts",
			mounts = {13328, 13329, 13327, 13326, 12354, 12353, 12302, 12303, 12351, 12330, 15292, 15293, 13317, 8586},
			mountID = {}
		},
		PreLaunchEvent = {
			name = "Pre-Launch Event",
			mounts = {163128, 217987, 217985, 224148},
			mountID = {}
		},
		Promotion = {
			name = "Old Promotion Mounts",
			mounts = {95341, 112327, 92724, 143631, 163127, 43599, 151618, 151617, 258430},
			mountID = {}
		},
		RAF = {
			name = "Recruit-A-Friend",
			mounts = {83086, 106246, 118515, 37719, "m382"},
			mountID = {}
		},
		RaidMounts = {
			name = "Unobtainable Raid Mounts",
			mounts = {49098, 49096, 49046, 49044, 44164, 33809, 21176, "m937"},
			mountID = {937}
		},
		RemixMOP = {
			name = "Remix MOP",
			mounts = {220766, 220768, 213582, 213576, 213584, 213595, 87784, 213602, 213603, 213605, 213606, 213607, 213604, 213608, 213609, 213628, 213627, 87786, 87787, 84753, 213626, 213624, 213625, 213623, 213622, 213621, 218111, 213600, 213601, 213598, 213597, 213596, 224374},
			mountID = {}
		},
		ScrollOfResurrection = {
			name = "Scroll of Resurrection",
			mounts = {76902, 76889},
			mountID = {}
		},
	}
}
MCLcore.mountList[18] = {
	name = "Dragonflight",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {192806, 192784, 205205, 208152, 210060, 192774, 210142, "m1614", 198822, 192792, 192788, 211862, 192765, "m1733", 217340},
			mountID = {}
		},
		DragonRiding = {
			name = "Dragon Riding",
			mounts = {194034, 194705, 194521, 194549, 204361, 210412},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {192799, 198870, 206567, 206566, "m1545", 210774, 211873, 192791},
			mountID = {}
		},
		Raid = {
			name = "Raid",
			mounts = {210061},
			mountID = {}
		},
		Reputation = {
			name = "Renown",
			mounts = {192762, 198872, 192761, 192764, 200118, 201426, 201425, 205155, 205209, 205207, 210969, 210833, 210831, 210946, 210948, 210945, 209951, 209949},
			mountID = {}
		},
		Secret = {
			name = "Secret",
			mounts = {192786, 210022},
			mountID = {}
		},
		Treasures = {
			name = "Treasures",
			mounts = {201440, 198825, 192777, 192779, 205204, 210059},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {206673, 206680, 206676, 206678, 206674, 206679, 206675, 192796},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {192601, 198873, 198871, 192775, 201454, 192800, 204382, 192785, 192790, 192772, 191838, 205203, 205197, 210775, 210769, 210058, 210057, 209947, 209950, 212645, 192807, 198824},
			mountID = {}
		},
	}
}
MCLcore.mountList[19] = {
	name = "The War Within",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {223266, 224415, 223267, 223286, 223158, "m2190", 231173, 250240, 237485, 242714, 258188},
			mountID = {}
		},
		Dungeon = {
			name = "Dungeon",
			mounts = {225548},
			mountID = {}
		},
		HorrificVisions = {
			name = "Horrific Visions",
			mounts = {235711, 235709, 235705, 235700, 235706, 235707, 211089, 223265},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {219391, 224150, 242733, 242734, 238051, 246445, 242713, 242715, 221765, 239563},
			mountID = {}
		},
		Raid = {
			name = "Raid",
			mounts = {224147, 224151, 236960, 235626, 229945, 229924, 229940, 243061},
			mountID = {}
		},
		RareDrops = {
			name = "Rare Drops",
			mounts = {223315, 223270, 223501, 246067, 246160, 246159},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {223571, 221753, 223505, 222989, 223317, 223314, 223274, 223264, 223276, 223278, 223279, 238829, 229936, 229944, 229935, 242729, 237484, 242728, 186640, 229956, 229948, 229946, 229950},
			mountID = {}
		},
		Secret = {
			name = "Secret",
			mounts = {186639},
			mountID = {}
		},
		SirenIsle = {
			name = "Siren Isle",
			mounts = {232639, 233058, 233489, 232991},
			mountID = {}
		},
		UnderMine = {
			name = "Undermine",
			mounts = {229974, 229953, 229955, 229954, 229941, 229952, 229949, 229947, 233064, "m2295", "m2289", "m2274", 229943},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {223153, 242730, 242717, 246237},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {223269, 223318},
			mountID = {}
		},
	}
}
MCLcore.mountList[20] = {
	name = "Midnight",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {252011, 262620, 262621, 257145, 260228, 246594, 260887, 257144},
			mountID = {}
		},
		Delves = {
			name = "Delves",
			mounts = {263222, 262496, 262500, 262502},
			mountID = {}
		},
		Dungeon = {
			name = "Dungeon",
			mounts = {260231, 262914},
			mountID = {}
		},
		Exploration = {
			name = "Exploration",
			mounts = {263580, 222988},
			mountID = {}
		},
		Prey = {
			name = "Prey",
			mounts = {257191, 257192, 257193},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {257240},
			mountID = {}
		},
		Raid = {
			name = "Raid",
			mounts = {246590},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {257152, 257085, 257156, 257147, 257200, 246735, 252012, 260635},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {257219, 250889, 252014, 257154, 257176, 246734, 257142, 257448, 257447},
			mountID = {}
		},
		Treasure = {
			name = "Treasures",
			mounts = {252017, 257223, 257444, 257446, 256423},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {250782, 257197, 256424},
			mountID = {}
		},
	}
}
MCLcore.sectionNames[1] = {
	name = "Midnight",
	mounts = MCLcore.mountList[20],
	icon = "Interface\\AddOns\\MCL\\icons\\midnight.blp",
	isExpansion = true,
}
MCLcore.sectionNames[2] = {
	name = "The War Within",
	mounts = MCLcore.mountList[19],
	icon = "Interface\\AddOns\\MCL\\icons\\tww.blp",
	isExpansion = true,
}
MCLcore.sectionNames[3] = {
	name = "Dragonflight",
	mounts = MCLcore.mountList[18],
	icon = "Interface\\AddOns\\MCL\\icons\\df.blp",
	isExpansion = true,
}
MCLcore.sectionNames[4] = {
	name = "Shadowlands",
	mounts = MCLcore.mountList[1],
	icon = "Interface\\AddOns\\MCL\\icons\\sl.blp",
	isExpansion = true,
}
MCLcore.sectionNames[5] = {
	name = "Battle for Azeroth",
	mounts = MCLcore.mountList[2],
	icon = "Interface\\AddOns\\MCL\\icons\\bfa.blp",
	isExpansion = true,
}
MCLcore.sectionNames[6] = {
	name = "Legion",
	mounts = MCLcore.mountList[3],
	icon = "Interface\\AddOns\\MCL\\icons\\legion.blp",
	isExpansion = true,
}
MCLcore.sectionNames[7] = {
	name = "Warlords of Draenor",
	mounts = MCLcore.mountList[4],
	icon = "Interface\\AddOns\\MCL\\icons\\wod.blp",
	isExpansion = true,
}
MCLcore.sectionNames[8] = {
	name = "Mists of Pandaria",
	mounts = MCLcore.mountList[5],
	icon = "Interface\\AddOns\\MCL\\icons\\mists.blp",
	isExpansion = true,
}
MCLcore.sectionNames[9] = {
	name = "Cataclysm",
	mounts = MCLcore.mountList[6],
	icon = "Interface\\AddOns\\MCL\\icons\\cata.blp",
	isExpansion = true,
}
MCLcore.sectionNames[10] = {
	name = "Wrath of the Lich King",
	mounts = MCLcore.mountList[7],
	icon = "Interface\\AddOns\\MCL\\icons\\wrath.blp",
	isExpansion = true,
}
MCLcore.sectionNames[11] = {
	name = "The Burning Crusade",
	mounts = MCLcore.mountList[8],
	icon = "Interface\\AddOns\\MCL\\icons\\bc.blp",
	isExpansion = true,
}
MCLcore.sectionNames[12] = {
	name = "Vanilla",
	mounts = MCLcore.mountList[9],
	icon = "Interface\\AddOns\\MCL\\icons\\classic.blp",
	isExpansion = true,
}
MCLcore.sectionNames[13] = {
	name = "Horde",
	mounts = MCLcore.mountList[11],
	icon = "Interface\\AddOns\\MCL\\icons\\horde.blp",
	isExpansion = false,
}
MCLcore.sectionNames[14] = {
	name = "Alliance",
	mounts = MCLcore.mountList[10],
	icon = "Interface\\AddOns\\MCL\\icons\\alliance.blp",
	isExpansion = false,
}
MCLcore.sectionNames[15] = {
	name = "Professions",
	mounts = MCLcore.mountList[12],
	icon = "Interface\\AddOns\\MCL\\icons\\professions.blp",
	isExpansion = false,
}
MCLcore.sectionNames[16] = {
	name = "PVP",
	mounts = MCLcore.mountList[13],
	icon = "Interface\\AddOns\\MCL\\icons\\pvp.blp",
	isExpansion = false,
}
MCLcore.sectionNames[17] = {
	name = "World Events",
	mounts = MCLcore.mountList[14],
	icon = "Interface\\AddOns\\MCL\\icons\\holiday.blp",
	isExpansion = false,
}
MCLcore.sectionNames[18] = {
	name = "Promotion",
	mounts = MCLcore.mountList[15],
	icon = "Interface\\AddOns\\MCL\\icons\\promotion.blp",
	isExpansion = false,
}
MCLcore.sectionNames[19] = {
	name = "Other",
	mounts = MCLcore.mountList[16],
	icon = "Interface\\AddOns\\MCL\\icons\\other.blp",
	isExpansion = false,
}
MCLcore.sectionNames[20] = {
	name = "Unobtainable",
	mounts = MCLcore.mountList[17],
	icon = "Interface\\AddOns\\MCL\\icons\\unobtainable.blp",
	isExpansion = false,
}
MCLcore.sectionNames[21] = {
	name = "Pinned",
	mounts = {MCL_PINNED},
	icon = "Interface\\AddOns\\MCL\\icons\\pin.blp",
	isExpansion = false,
}
MCLcore.sectionNames[22] = {
	name = "Overview",
	mounts = {},
	icon = "Interface\\AddOns\\MCL\\icons\\mcl.blp",
	isExpansion = false,
}

MCLcore.regionalFilter = {
	['CN'] = {210077},
	['KR'] = {210077},
}

MCLcore.mountNotes = {
	[43954] = "Rewarded from defeating Sartharion with 3 drakes alive on 25-man difficulty. Leave the trash alone and just kill the boss.",
	[43962] = "Random drop from Hyldnir Spoils (reward from Storm Peaks daily quests).",
	[43986] = "Rewarded from defeating Sartharion with 3 drakes alive on 10-man difficulty. Leave the trash alone and just kill the boss.",
	[44707] = "Chance to hatch from Mysterious Egg.",
	[63042] = "Most spawns are located around the temple of earth.",
	[69747] = "Kasha's bag drops from freeing Kasha the bear in the dungeon Zul'aman. A good way of getting the bag is doing achievement Bear-ly made it.",
	[90655] = "Most of the spawns are around burial",
	[94231] = "Jade Primordial Direhorn spawns in the 4 following zones: The Jade forest, Dread Wastes, Townlong Steppes and Kun-lai Summit.",
	[94291] = "The three primal raptors are obtained through hatching a primal egg. Primal eggs are turned into cracked primal eggs which takes 3 days of real time waiting. Once you have received a cracked primal egg you have a chance to obtain either a red, black or green raptor. The chances are 33% to obtain a specific raptor. \n\nThe Primal eggs are obtained from killing Elite Primal Dinosaurs on the Isle of Giants.",
	[182589] = "Questline begins by looting Worldedge Gorger {{m:10413,38.8,72}}",
	[182614] = "To get Blanchy's Reins Blanchy's Reins you have to bring items to Dead Blanchy 6 times in Revendreth.\nYou can do it only once per day so you need 6 days to get the mount. The day starts with the daily quest reset.\nYou can obtain all the items you need in advance.\nDead Blanchy spawns on the river in Endmire north of Darkhaven\nand starts to run until it bumps into a player. Everyone can interact with it.\nBlanchy runs faster than your mount so take the right position to intercept it.\nIt despawns after 5 minutes. The respawn timer is from 1 to 2 hours.",
	[183052] = "Chance to appear in mission table.",
	[183615] = "Chance to appear in mission table.",
	[183617] = "Chance to appear in mission table.",
	[183618] = "Chance to appear in mission table.",
	[186639] = "Secret mount. Requires Renown 8 with Manaforge Vandals.\n\nStep 1 - Join all 3 cartels:\nUse {{item:249702}} (Deal: Cartel Ba), {{item:249704}} (Deal: Cartel Om), and {{item:249700}} (Deal: Cartel Zo). Crafted by Inscription or buy from the AH. Normally limited to one per week, but a macro can apply all three at once:\n/use Deal: Cartel Ba\n/use Deal: Cartel Om\n/use Deal: Cartel Zo\n\nStep 2 - Loot the dead drops inside Manaforge Omega (any difficulty, LFR works):\n- Cartel Ba Dead Drop: After Plexus Sentinel, on the right path before the Phase Warp gap crossing.\n- Cartel Om Dead Drop: Behind the building after Fractillus, on top of a rock. Can be reached without killing the boss by keeping left.\n- Cartel Zo Dead Drop: On the first mana-vent pipe before Forgeweaver Araz.\n\nNote: Ba and Zo dead drops become unreachable once Forgeweaver Araz is defeated in your instance. Dead drops can be collected across different characters.\n\nStep 3 - Complete the quest:\nAfter looting all 3 dead drops, Zo'turu on Shadow Point (outside the raid) offers the quest Someone Like Me. Rewards both the mount and {{item:249713}} (Cartel Transmorpher).",
	[186643] = "Find the doe Maelie the Wanderer in Korthia and bring her back to Tinybell {{m:13570,60.6,21.8}} every day for 6 days. On the 6th day the mount is rewarded.",
	[186646] = "Feed 10x Tasty Mawshroom to Darkmaul {{m:13570,42.6,33}}",
	[186651] = "Hand in 10x Lost Razorwing Egg to the Razorwing Nest {{m:13570,25.9,51.1}}",
	[187630] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found in the Halondrus boss encounter area in Sepulcher of the First Ones raid. Located by one of the pillar structures in the room where the second phase happens. Schematic doesn't spawn until Halondrus is defeated - kill the boss, then run back to the second phase room to loot. Note: Once the raid resets, the walls separating Halondrus's rooms go back up, blocking access.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189172}} x1 (Crystallized Echo of the First Song)\n{{item:189156}} x1 (Vombata Lattice - drops from vombata mobs)",
	[187631] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside a cage in the Arrangement Index. Reachable from a broken pillar - fly, use Door of Shadows, or glide from above.\n\n{{m:1970,64.1,35.6}} Schematic location (glide from here or Door of Shadows)\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189175}} x1 (Mawforged Bridle - from High Value Cache in Sepulcher raid)\n{{item:189156}} x1 (Vombata Lattice - drops from vombata mobs)",
	[187632] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Get the Grateful Boon treasure (requires flying or Door of Shadows).\n1. Reach the hilltop at 37.1, 78.3 in Zereth Mortis.\n2. Pet all 12 animals: 5x Agitated Vombata, 4x Agitated Cervid, 3x Agitated Lupine.\n3. Two hard-to-reach animals at 37.41, 78.23 (top of sphere) and 36.66, 76.27 (on the wall) - use Door of Shadows.\n4. After petting all, Tah Fen unlocks the Grateful Boon treasure.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) by getting Sopranian Understanding from the Cypher Console, completing The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect -> Schematic Reassimilation: Deathrunner.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189174}} x1 (Lens of Focused Intention)\n{{item:189156}} x1 (Vombata Lattice)\n\n{{m:1970,37.1,78.3}} Grateful Boon treasure",
	[187638] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Awarded as a quest reward from A New Architect, the quest that unlocks the Protoform Synthesis mount system. Note: Only given to the first character on your account to unlock the system.\n\nPrerequisites: Research Sopranian Understanding at the Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189178}} x1 (Tools of Incomprehensible Experimentation - drops from Lihuvim in Sepulcher raid)\n{{item:187635}} x1 (Cervid Lattice - drops from stag mobs)",
	[187639] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Reward for the achievement Cyphers of the First Ones, which requires fully researching all Cypher of the First Ones research. Once completed, check your mailbox for the schematic.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189176}} x1 (Protoform Sentience Crown - drops from Automa/Jiro elites)\n{{item:187635}} x1 (Cervid Lattice - drops from stag mobs)",
	[187641] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside the Mawsworn Cache treasure between two cages. Clear the group of common mobs to safely pick it up.\n\n{{m:1970,60.5,30.5}} Mawsworn Cache\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x300 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189175}} x1 (Mawforged Bridle - from High Value Cache in Sepulcher raid)\n{{item:187635}} x1 (Cervid Lattice - drops from stag mobs)",
	[187660] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Located within the Resonant Peaks puzzles, on the same level as Primus Locus. Can fly there, or climb using Door of Shadows:\n1. Start at 50.4, 28.5\n2. Door of Shadows to top of broken pillar (50.2, 29.0)\n3. Door of Shadows to top of floating orb (50.0, 28.4)\n4. Door of Shadows to platform (50.3, 27.2)\n\n{{m:1970,50.3,27.0}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189180}} x1 (Wind's Infinite Call - drops from Enhanced Avian)\n{{item:189154}} x1 (Vespoid Lattice - drops from wasp mobs)",
	[187663] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside the Gravid Repose archive. Enter at 50.6, 31.8 then take the ramp to the right. The schematic is in a small structure at the top of the ramp.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189179}} x1 (Unalloyed Bronze Ingot - from Requisites Originator)\n{{item:189154}} x1 (Vespoid Lattice - drops from wasp mobs)\n\n{{m:1970,50.6,31.8}} Gravid Repose entrance",
	[187664] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside a vespoid hive at ground level of the Resonant Peaks.\n\n{{m:1970,53.3,25.6}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189173}} x1 (Eternal Ragepearl - drops from Dominated Runeshaper)\n{{item:189154}} x1 (Vespoid Lattice - drops from wasp mobs)",
	[187665] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Has a chance to be found inside the Pulp-Covered Relic treasure, which spawns randomly across Zereth Mortis. Can only loot once per day.\n\nPossible locations:\n{{m:1970,42.0,34.2}} Pulp-Covered Relic\n{{m:1970,53.4,25.8}} Pulp-Covered Relic\n{{m:1970,52.8,45.8}} Pulp-Covered Relic\n{{m:1970,50.3,41.2}} Pulp-Covered Relic\n{{m:1970,64.3,63.4}} Pulp-Covered Relic\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x500 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189176}} x1 (Protoform Sentience Crown - drops from Automa/Jiro elites)\n{{item:189154}} x1 (Vespoid Lattice - drops from wasp mobs)",
	[187666] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Located atop a tall pillar in the Plain of Actualization. Requires flying or Door of Shadows to reach.\n\n{{m:1970,62.0,43.5}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189180}} x1 (Wind's Infinite Call - drops from Enhanced Avian)\n{{item:189150}} x1 (Raptora Lattice - drops from hawk mobs)",
	[187667] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to drop from Mawsworn Hulk mobs in the Endless Sands area.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189175}} x1 (Mawforged Bridle - from High Value Cache in Sepulcher raid)\n{{item:189150}} x1 (Raptora Lattice - drops from hawk mobs)",
	[187668] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside the Chamber of Shaping within the Arrangement Index. Located on a bench-like structure behind the Dominated Architect.\n\n{{m:1970,65.7,35.9}} Chamber of Shaping entrance\n{{m:1970,67.4,40.1}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189173}} x1 (Eternal Ragepearl - drops from Dominated Runeshaper)\n{{item:189150}} x1 (Raptora Lattice - drops from hawk mobs)",
	[187669] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found on the northeastern end of the Vigilant Guardian room in the Sepulcher of the First Ones raid. Hanging by some decorative elements. Can be looted on a lockout that has already killed the boss.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x500 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189172}} x1 (Crystallized Echo of the First Song)\n{{item:189145}} x1 (Helicid Lattice - drops from snail mobs)",
	[187670] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to loot from {{item:190610}} (Tribute of the Enlightened Elders), the cache reward from the Patterns Within Patterns weekly quest.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189179}} x1 (Unalloyed Bronze Ingot - from Requisites Originator)\n{{item:189145}} x1 (Helicid Lattice - drops from snail mobs)",
	[187671] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Requires researching Altonian Understanding AND completing the achievement A Means to an End.\n1. Go to 47.7, 34.5 (Camber Alcove Arrangement) to unlock the secret teleporter for the Resonant Peaks.\n2. Get at least 60 Cosmic Energy.\n3. Go to Gravid Repose, teleport to Interior Locus.\n4. Use the Arcae Locus teleporter to reach the Camber Alcove.\n5. Inside, enter the Inert Prototype vehicle and complete the course to earn the schematic.\n\n{{m:1970,47.7,34.5}} Camber Alcove entrance\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x300 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189178}} x1 (Tools of Incomprehensible Experimentation - drops from Lihuvim in Sepulcher raid)\n{{item:189145}} x1 (Helicid Lattice - drops from snail mobs)",
	[187672] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Located atop an arch structure in Antecedent Isle. Requires flying or Door of Shadows to climb the arch.\n\n{{m:1970,47.7,9.5}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189177}} x1 (Revelation Key - drops from Protector of the First Ones)\n{{item:189145}} x1 (Helicid Lattice - drops from snail mobs)",
	[187677] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Located by the Genesis Vestibule, atop the structure leading to the Genesis Alcove. Climb from the left side of the building to reach the schematic.\n\n{{m:1970,31.5,50.3}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189171}} x1 (Bauble of Pure Innovation)\n{{item:189152}} x1 (Tarachnid Lattice - drops from spider mobs)",
	[187678] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside a small building in the Arrangement Index. The schematic is to the right as you enter.\n\n{{m:1970,62.8,22.0}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189177}} x1 (Revelation Key - drops from Protector of the First Ones)\n{{item:189152}} x1 (Tarachnid Lattice - drops from spider mobs)",
	[187679] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Given by the Shade of Irik-tu, a ghost NPC at the back of Firim's cave in Exile's Hollow. You must die near the cavern and run there as a ghost to see and speak to the spirit.\n\n{{m:1970,34.9,48.7}} Shade of Irik-tu (must be dead/ghost form)\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x500 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189176}} x1 (Protoform Sentience Crown - drops from Automa/Jiro elites)\n{{item:189152}} x1 (Tarachnid Lattice - drops from spider mobs)",
	[187683] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to drop from Accelerated Bufonid mobs in Zereth Mortis. These mobs are found on the Sepulcher of the First Ones island and near Hirukon's pool.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189171}} x1 (Bauble of Pure Innovation)\n{{item:187633}} x1 (Bufonid Lattice - drops from frog mobs)",
	[188809] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside the Forgotten Proto-Vault, atop a mountain overlooking the Untamed Verdure. Requires flying or the frog from the World Quest Frog'it to reach.\n\n{{m:1970,67.0,69.4}} Forgotten Proto-Vault\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189178}} x1 (Tools of Incomprehensible Experimentation - drops from Lihuvim in Sepulcher raid)\n{{item:187633}} x1 (Bufonid Lattice - drops from frog mobs)",
	[188810] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to loot from {{item:199191}} (Enlightened Broker Supplies), the Paragon reputation cache for The Enlightened.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189174}} x1 (Lens of Focused Intention - Revered with The Enlightened)\n{{item:187633}} x1 (Bufonid Lattice - drops from frog mobs)",
	[190580] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to drop from Maw-Frenzied Lupine mob inside Choral Residium cave.\n\n{{m:1970,51.8,62.7}} Choral Residium cave entrance\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x500 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189172}} x1 (Crystallized Echo of the First Song)\n{{item:190388}} x1 (Lupine Lattice - drops from wolf mobs)",
	[192764] = "It has a small chance to drop from Expedition Scout's Pack after reaching the Renown requirement.",
	[192786] = "Costs 1000x {{item:202173}} from Dealer Vexil in the Obsidian Citadel. Requires the Worldbreaker buff to interact with the vendor.\n\nStep 1 - Unlock Igys the Believer:\nComplete The Shadow of His Wings questline (part of Sojourner of the Waking Shores). This unlocks Igys the Believer {{m:13644,32.2,52.4}}\n\nStep 2 - Get a Worldbreaker Membership:\nFarm {{item:199202}} and {{item:199203}} from mobs in and around the Obsidian Citadel. Combine fragments into keys, then turn keys in to Igys. Open the caches he gives you for a chance at {{item:199215}} (~33%% drop rate). Use it to gain the Worldbreaker title and buff.\n\nStep 3 - Farm 1000 Magmotes:\nKill mobs in and around the Obsidian Citadel. The Vault basement area has fast respawns and is the best spot. Takes ~1-2 hours. Save your keys for Wrathion/Sabellian rep instead of opening caches for magmotes.\n\nIf you die you lose the Worldbreaker buff. You can buy a backup {{item:199215}} from Dealer Vexil for 20x {{item:202173}} once you have the title.",
	[192791] = "Plainswalker Bearer Plainswalker Bearer drops from Grand Hunt Spoils Grand Hunt Spoils, and ONLY the epic version, which is rewarded for the first weekly completion of a Grand Hunt event.\n\nGrand Hunt Events are unlocked at renown 5 with Maruuk Centaur, the major faction of Ohn'ahran Plains.",
	[192799] = "To unlock the quests you'll need\nRenown 9 with Maruuk Centaur\nComplete Initiate's Day out from the achievement Sojourner of Ohn'ahran Plains\n\nInitiate's Day out from Sojourner of Ohn'ahran Plains starts from Initiate Radiya at 56.12 77.01 in Ohn'iri Springs in Ohn'ahran Plains\n\nOnce unlocked the quests can be picked can be picked up from Initiate Radiya\nOnce a quest is completed you'll have to wait for the daily reset to get the next quest in the chain.",
	[194034] = "Reward from The Waking Shores main storyline Waking Hope.",
	[194521] = "Reward from Thaldraszus main storyline Just Don't Ask Me to Spell It",
	[194549] = "Reward from Ohn'ahran Plains main storyline Ohn'a'Roll",
	[194705] = "Reward from The Azure Span main storyline Azure Spanner.",
	[198808] = "Requires to Dracthyr race to interact with vendor.",
	[198809] = "Requires to Dracthyr race to interact with vendor.",
	[198810] = "Requires to Dracthyr race to interact with vendor.",
	[198811] = "Requires to Dracthyr race to interact with vendor.",
	[198870] = "Fishing quest chain. Buy a {{item:199340}} from The Great Swog (costs 75 Copper Coins total: 15 per Silver Coin, 5 Silver per Gold). Use the Gold Coin to buy {{item:202102}} — repeat until you get {{item:202042}}.\n\nEquip the shades and go underwater at {{m:2022,19.1,36.6}}. Talk to the NPC, then /dance on the dance floor for ~5 minutes. Pick up the {{item:202061}}.\n\nFill the barrel in order:\n1. Catch 100x {{item:202072}} near Iskaara {{m:2024,13.7,48.5}}\n2. Catch 25x {{item:202073}} from lava rivers east of Obsidian Citadel in Waking Shores\n3. Catch 1x {{item:202074}} near Algethar Academy in Thaldraszus\n\nReturn the full barrel to where you found it to summon Otto and complete the quest.",
	[201702] = "Requires to Dracthyr race to interact with vendor.",
	[201704] = "Requires to Dracthyr race to interact with vendor.",
	[201719] = "Requires to Dracthyr race to interact with vendor.",
	[201720] = "Requires to Dracthyr race to interact with vendor.",
	[204091] = "Current reward for Recruit a Friend, subject to be retired.",
	[204361] = "Zaralek Cavern Campaign.",
	[206566] = "By reaching level 30 and visiting Boralus (Alliance) or Dazar'alor (Horde), a quest will be automatically received to learn a new flying mount, either Harbor Gryphon Harbor Gryphon (Alliance) or Reins of the Scarlet Pterrordax Reins of the Scarlet Pterrordax (Horde).",
	[206567] = "By reaching level 30 and visiting Boralus (Alliance) or Dazar'alor (Horde), a quest will be automatically received to learn a new flying mount, either Harbor Gryphon Harbor Gryphon (Alliance) or Reins of the Scarlet Pterrordax Reins of the Scarlet Pterrordax (Horde).",
	[210022] = "Secrets of Azeroth mount. Collect 3 Booster Parts and combine them at the Arcane Forge in Valdrakken.\n\nPart 1 - {{item:208984}}:\nRequires 3 players each using {{item:208092}} at the braziers on Jaguero Isle {{m:210,59.0,78.0}}. Kills the Enigma Ward rare — loot the part. Can be soloed with alts: open multiple WoW instances, position alts at the braziers with torches active, then quickly swap between them (disable addons for faster loading).\n\nPart 2 - {{item:209781}}:\nFelwood {{m:77,50.0,26.3}} — just click and loot, no group needed.\n\nPart 3 - {{item:209055}}:\nBlasted Lands, on the Dark Portal ramp {{m:17,54.8,52.1}}. Destroy the 2 cannons first, then loot. Use Zidormi to switch to the pre-invasion timeline to avoid constant mob aggro. Can also hover on a flying mount to loot safely.\n\nCombine: Use any of the 3 parts at the Empowered Arcane Forge in Valdrakken {{m:2134,36.4,62.2}} (next to Artisan's Market). The forge is permanently empowered — no event needed.",
	[210412] = "Emerald Dream Campaign",
	[210774] = "23-day quest chain in the Emerald Dream. Requires completing Chapter 5 of the Emerald Dream storyline. Must dismount before interacting with the sprout.\n\nStart: Interact with the Smoldering Sprout {{m:2200,48.68,67.90}}\n\n1. Some Water - Get a water bucket from Professor Ash, fill it at {{m:2200,51.11,65.70}}, return to sprout. Wait 5 days.\n2. A Dash of Minerals - Kill Fathomless Lurkers near {{m:2200,51.0,31.0}} for 5x {{item:210457}}. Wait 5 days.\n3. The Right Food - Collect 5x {{item:4537}} from vendor, 3x {{item:209416}} from turtle eggs near {{m:2200,41.15,75.97}}, 5x {{item:208644}} from lashers near {{m:2200,56.46,55.18}}. Click the {{item:208644}} to combine (NOT the bananas). Wait 3 days for fertilizer to compost, then log out/in before using. Apply to sprout, wait 5 days.\n4. And a Pinch of Magic - Collect items near {{m:2200,63.0,52.0}}. Wait 5 days.\n5. A Little Hope is Never Without Worth - Turn in at sprout for mount.\n\nTimers are real-time (not tied to weekly reset). Total ~23 days.",
	[222988] = "Nice guide written up on Wowhead for this. Too long to fit in MCL.",
	[223269] = "Complete all 20 waves of the Awakened Machinist weekly event in The Ringing Deeps. The mount has a chance to drop from the Awakened Cache chests that spawn after wave 20. \n\n{{m:2214,66.5,61.9}} Awakened Machinist event",
	[223270] = "Kill any mob on the Isle of Dorn for a low chance to loot Crackling Shard (collect 10). Combine them into a Storm Vessel, then use it on Alunira to make her attackable. \nKill and loot for the mount.",
	[223315] = "Rare Elite in Hallowfall that spawns when Beledar's Shadow begins (~5% mount drop). Daily loot per character, can drop at level 70. Part of the Adventurer of Hallowfall achievement.",
	[223318] = "Chance to drop from {{item:228741}} (Lamplighter Supply Satchel), earned by completing Spreading the Light objectives in Hallowfall. Do all main fires plus side quests from giving 3/3 crystals to small fires. \n\n{{m:2215}} Hallowfall - Spreading the Light",
	[223501] = "Activate all five levers simultaneously.\nCoordinates: 49.2/8.8, 53.91/25.28, 57.62/23.57, 62.83/44.64, 59.08/92.40.\nChat message confirms activation.\nRare spawns in western zone at (61.02, 76.79) after a delay. \nKill and loot for mount.",
	[229941] = "The best way to farm Miscellaneous Mechanica Miscellaneous Mechanica seems to be continuous kills of any of the Cartel-specific Rares (e.g. Voltstrike the Charged, Scrapchewer, M.A.G.N.O., Giovante)",
	[229949] = "While you're  Shoveling Trash during S.C.R.A.P. jobs in Undermine (requires Renown 2 with The Cartels of Undermine) you keep looting Empty Kaja'Cola Can Empty Kaja'Cola Can. You can exchange 333 of them (or later at Renown 14 one Vintage Kaja'Cola Can Vintage Kaja'Cola Can) for one of these Sifted Pile of Scrap Sifted Pile of Scrap containers at S.C.R.A.P.",
	[229952] = "The best way to farm Miscellaneous Mechanica Miscellaneous Mechanica seems to be continuous kills of any of the Cartel-specific Rares (e.g. Voltstrike the Charged, Scrapchewer, M.A.G.N.O., Giovante)",
	[229954] = "The best way to farm Miscellaneous Mechanica Miscellaneous Mechanica seems to be continuous kills of any of the Cartel-specific Rares (e.g. Voltstrike the Charged, Scrapchewer, M.A.G.N.O., Giovante)",
	[232639] = "Located in the Forgotten Vault. Requires an active storm event (Special Assignment active/completed for the week).\n\nThrayir is surrounded by 5 Runestones. Bring the matching Runekey to each:\n\n{{item:232571}} - Guaranteed drop from Ksvir the Forgotten in the southern room of the Forgotten Vault during a storm.\n\n{{item:232572}} - Combine 7 {{item:234328}}. Drops from any mob on the island during a storm.\n\n{{item:232573}} - Combine 5 {{item:232605}}. Found in treasure chests inside the storm and underwater chests outside. Farm Seafarer's Caches (requires quest Dipping a Toe).\n\n{{item:232569}} - Drops from Zek'ul the Shipbreaker in Deadfin Mire during a storm. Can also be fished up nearby.\n\n{{item:232570}} - Combine 3 {{item:234327}} found around the island during a storm:\n1. Garden of the abandoned inn (center-west) - pile of dirt\n2. Rotting Hole cave (southeast) - small yellow crystal\n3. Spirit-Scarred Cave - held by a ghost\n\n{{m:2369,38.19,51.78}} Garden Fragment\n{{m:2369,67.08,78.44}} Rotting Hole Fragment\n{{m:2369,52.39,38.59}} Spirit-Scarred Fragment\n{{m:2369,44.04,23.13}} Forgotten Vault entrance\n\nUse all five keys, then talk to Thrayir.",
	[235700] = "In the Trade District, find the first note near the well (right of the mini-boss) to learn if the recipe is Cooked or Uncooked. \nAfter the boss, check the second note at the top of the stairs for the required food. \nIf Raw: use the ingredient as-is (Fresh Fillet, Chopped Mycobloom, Spiced Meat Stock, or Portioned Steak).\nIf Cooked: use the cooked version (Fresh Fillet → Skewered Fillet, Portioned Steak → Unseasoned Field Steak). \nAdd the correct food to the bowl right of the stairs, then click \"Rattle the Bowl.\"\nKill the gryphon that spawns and loot the mount.",
	[235705] = "Collect 4 horseshoes in the Stormwind Horrific Vision (requires 1+ mask equipped) and use the forge to summon a rare that drops the mount. Queue in Dornogal — must be a Stormwind week.\n\nHorseshoes: \n56, 56 (Cathedral planter)\n52, 82.5 (Mage Quarter) \n61.5, 75.5 (Trade District bank)\n75.5, 58 (Old Town)\nForge: 63, 37 (Dwarven District)\nKill the spawned rare to loot the mount.",
	[235706] = "Requires 1+ mask.\nCollect the Wolf Saddle (67.39, 36.19)\nCollect the Wolf Tack (39.17, 49.58)\nThen use the Wolf Skin Rug (60.92, 55.05) in the leatherworking building to summon a rare.\nKill it to loot the mount.",
	[235707] = "Requires 2+ masks.\nComplete the Valley of Wisdom objective to unlock the elevator (49.15, 50.66).\nTake it up, then head south to the Wind Rider area (48.70, 54.89)\nKill all waves until a rare spawns.",
	[246237] = "Achievement no longer available.",
	[256423] = "Interact with the Fungal Mallet in Fungara Village to get the  Fungal Mallet buff, and use it to ring the Mycelium Gong.\n\n{{m:2413,41.3,67.9}} Fungal Mallet\n{{m:2413,46.6,67.8}} Mycelium Gong",
	[257191] = "Preyseeker's Journey Rank 5",
	[257192] = "Preyseeker's Journey Rank 10",
	[257223] = "After you've interacted with the cache, you have to go find four urns across the zone, kill the guardian that spawns from them, and bring back the key-items they drop:\n{{m:2437,32.69,83.50}} Nalorakk's Chosen\n{{m:2437,34.55,33.46}} Halazzi's Chosen\n{{m:2437,54.78,22.39}} Jan'alai's Chosen\n{{m:2437,51.58,84.92}} Akil'zon's Chosen",
	[257240] = "Part of the main storyline for Arator's Journey",
	[257446] = "Inside the cave you'll find a bunch of broken eggs forming a maze. The eggs emit lightning. If you're hit by lightning you return to the entrance, and at the end of the maze you'll find Final Clutch of Predaxas.",
	[259227] = "Requires Rank 6",
	[259238] = "Requires Rank 8",
	[262500] = "Delver's Journey Rank 5",
	[263580] = "Requires 120 Glowing Moths captured to purchase",
	["m1445"] = "You must solo the entire dungeon Plaguefall on Heroic or Mythic difficulty.\nAfter defeating the last boss, backtrack to the Domina Venomblade boss arena.\nThe Slime Serpent appears in the pool on the side.",
	["m1545"] = "Requires Renown 25 with Maruuk Centaur and completing the Lizis Reins questline.\n\n1. Complete the questline starting with Sneaking Out from Initiate Radiya to unlock Godoloto {{m:2023,56.2,75.8}}\n2. Collect 3x {{item:201929}} from Balakar Khan (last boss of Nokhud Offensive, any difficulty)\n3. Get 1x {{item:191507}} (Tier 3) - crafted by Alchemists or buy from the Auction House\n4. Get 1x {{item:201323}} from Quartermaster Huseng (Renown 7, costs 1x {{item:194562}} + 50 Dragon Isles Supplies)\n\n{{item:194562}} drops from Time-Lost mobs in Thaldraszus (~5-10%% drop) {{m:2025,60.0,82.0}}\n\nDo NOT use the {{item:201323}} early - it will be consumed.\n\nTurn in quest A Whispering Breeze to Ohnahra {{m:2023,57.59,31.92}}",
}
