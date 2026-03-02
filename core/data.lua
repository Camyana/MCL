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
			mounts = {186654, 186637, 184183, 182596, 186653, 184166, 186655, 187673, "m1549", 217612},
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
			mounts = {49098, 49096, 49046, 49044, 44164, 33809, 21176, "m937", "m1576"},
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
			mounts = {201440, 198825, 192777, 192779},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {206673, 206680, 206676, 206678, 206674, 206679, 206675, 192796},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {192601, 198873, 198871, 192775, 201454, 192800, 204382, 192785, 192790, 192772, 191838, 205203, 205197, 210775, 210769, 210058, 210057, 209947, 209950, 212645, 192807, 198824, 205204, 210059},
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
			mounts = {252017, 257223, 257444, 257446, 256423, "m2912"},
			mountID = {2912}
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
	[155656] = "Reward for unlocking the Lightforged Draenei allied race. Complete the Argus storyline and reach Exalted with Army of the Light, then complete the recruitment questline.",
	[155662] = "Reward for unlocking the Void Elf allied race. Complete the Argussian Reach storyline and reach Exalted with Argussian Reach, then complete the recruitment questline.",
	[156486] = "Reward for unlocking the Nightborne allied race. Complete the Suramar storyline and reach Exalted with The Nightfallen, then complete the recruitment questline.",
	[156487] = "Reward for unlocking the Highmountain Tauren allied race. Complete the Highmountain storyline and reach Exalted with Highmountain Tribe, then complete the recruitment questline.",
	[156798] = "Secret mount requiring a group of 5 players to solve an intricate cross-zone puzzle. Follow the WoW Secret Finding Discord guide. Involves solving monocle puzzles across multiple zones, ending with a ritual that all 5 players complete simultaneously. The mount can carry up to 4 additional passengers who were in your Hivemind group.",
	[157870] = "Reward for unlocking the Dark Iron Dwarf allied race (Alliance only). Requires completing the Ready for War achievement and the Dark Iron recruitment questline.",
	[159146] = "Reward from the Kua'fon's Harness quest chain in Zuldazar (Horde only). A multi-day questline where you raise a pterrordax from an egg. Starts from {{npc:127377,Pa'ku}} at {{m:862,71.4,49.1}}. Requires several days of daily quests to hatch and train.",
	[159842] = "Drops from {{npc:126983,Harlan Sweete}} (final boss) in Freehold dungeon on Mythic difficulty. Approximately 1% drop rate. Must clear entire dungeon each run.",
	[159921] = "Drops from the last boss in Kings' Rest dungeon on Mythic difficulty. Approximately 1% drop rate. Farm by running Mythic (non-keystone) and resetting. Subject to 10 instances/hour lockout.",
	[160829] = "Drops from {{npc:131817,Elder Leaxa}} (first boss) in The Underrot dungeon on Mythic difficulty. Approximately 1% drop rate. Fast farm: kill first boss, leave, reset.",
	[161215] = "Reward from the Glory of the Wartorn Hero achievement. Requires completing specific dungeon achievements across all BFA dungeons.",
	[161330] = "Reward for unlocking the Mag'har Orc allied race (Horde only). Requires completing the Ready for War achievement and the Mag'har recruitment questline.",
	[161331] = "Reward for unlocking the Dark Iron Dwarf allied race (Alliance only). Requires completing the Ready for War achievement and the Dark Iron recruitment questline.",
	[161479] = "Crafted by combining 20 Abhorrent Essences and a Ruddy Saddlebag at the Deepcoil Workstation in Nazjatar. Abhorrent Essences drop from rares, treasures, and World Quests in Nazjatar. The Ruddy Saddlebag is purchased from {{npc:154169,Finder Palta}} (Horde) or {{npc:154140,Artisan Okata}} (Alliance) for 3 Prismatic Manapearls.",
	[161664] = "Purchased from {{npc:131287,Natal'hakata}} in Dazar'alor for 10,000g. Requires Exalted with Zandalari Empire. Horde only.",
	[161665] = "Purchased from {{npc:131287,Natal'hakata}} in Dazar'alor for 10,000g. Requires Exalted with Zandalari Empire. Horde only.",
	[161666] = "Purchased from {{npc:131287,Natal'hakata}} in Dazar'alor for 10,000g. Requires Exalted with Zandalari Empire. Horde only.",
	[161667] = "Purchased from {{npc:135804,Hoarder Jena}} in Vol'dun for 10,000g. Requires Exalted with Voldunai. Horde only.",
	[161773] = "Purchased from {{npc:135804,Hoarder Jena}} in Vol'dun for 10,000g. Requires Exalted with Voldunai. Horde only.",
	[161774] = "Purchased from {{npc:135459,Provisioner Lija}} in Zuldazar for 10,000g. Requires Exalted with Talanji's Expedition. Horde only.",
	[161879] = "Purchased from {{npc:135808,Provisioner Fray}} in Boralus for 10,000g. Requires Exalted with Proudmoore Admiralty. Alliance only.",
	[161908] = "Purchased from {{npc:135815,Quartermaster Alcorn}} in Drustvar for 10,000g. Requires Exalted with Order of Embers. Alliance only.",
	[161909] = "Purchased from {{npc:135800,Sister Lilyana}} in Stormsong Valley for 10,000g. Requires Exalted with Storm's Wake. Alliance only.",
	[161910] = "Purchased from {{npc:135815,Quartermaster Alcorn}} in Drustvar for 10,000g. Requires Exalted with Order of Embers. Alliance only.",
	[161911] = "Purchased from {{npc:135808,Provisioner Fray}} in Boralus for 10,000g. Requires Exalted with Proudmoore Admiralty. Alliance only.",
	[161912] = "Purchased from {{npc:135800,Sister Lilyana}} in Stormsong Valley for 10,000g. Requires Exalted with Storm's Wake. Alliance only.",
	[163183] = "Purchased from {{npc:141008,Gottum}} in {{m:896,Drustvar}} for 333,333g {{m:896,20.8,44.6}}. No reputation requirement.",
	[163216] = "Reward from the Glory of the Uldir Raider achievement. Requires completing all boss-specific achievements in the Uldir raid.",
	[163573] = "Zone drop from any mob in {{m:942,Stormsong Valley}}. Very low drop rate (~0.03%). Farm dense mob areas like the Quilboar or Naga camps for best results.",
	[163574] = "Zone drop from any mob in {{m:896,Drustvar}}. Very low drop rate (~0.03%). Farm dense mob areas like Crimson Forest or Waycrest Manor exterior for best results.",
	[163575] = "Zone drop from any mob in {{m:863,Nazmir}}. Very low drop rate (~0.03%). Farm blood troll areas or other dense mob packs for best results.",
	[163576] = "Zone drop from any mob in {{m:864,Vol'dun}}. Very low drop rate (~0.03%). Any mob can drop it. Farm densely packed areas for best results.",
	[163577] = "Reward from the Conqueror of Azeroth achievement. Requires completing all BFA world PvP achievements including Slayer of the Alliance/Horde bounty kills in War Mode.",
	[163578] = "Drops from {{npc:142436,Knight-Captain Aldrin}} in Arathi Highlands during the Warfront at approximately 3-5% drop rate {{m:14,48.8,40.2}}. Alliance-controlled phase only.",
	[163579] = "Drops from {{npc:142423,Overseer Krix}} in Arathi Highlands during the Warfront at approximately 3-5% drop rate {{m:14,27.1,56.2}}.",
	[163582] = "Random drop from Island Expedition end-of-run reward caches. Very low drop rate. Run Heroic or Mythic Islands for best chances.",
	[163583] = "Random drop from Island Expedition end-of-run reward caches. Drop rate is very low. Run Heroic or Mythic Islands for best chances. Can also appear on the Black Market Auction House.",
	[163584] = "Random drop from Island Expedition end-of-run reward caches. Drop rate is very low. Run Heroic or Mythic Islands for best chances. Can also appear on the Black Market Auction House.",
	[163585] = "Random drop from Island Expedition end-of-run reward caches. Drop rate is very low. Run Heroic or Mythic Islands for best chances. Can also appear on the Black Market Auction House.",
	[163586] = "Random drop from Island Expedition end-of-run reward caches. Very low drop rate. This mount can also appear on the Black Market Auction House.",
	[163589] = "Purchased from {{npc:131287,Natal'hakata}} (Horde) in Dazar'alor or {{npc:135808,Provisioner Fray}} (Alliance) in Boralus for 500,000g. Requires Exalted with respective BFA faction.",
	[163644] = "Drops from {{npc:142440,Doomrider Helgrim}} in Arathi Highlands during the Warfront at approximately 3% drop rate {{m:14,53.8,57.2}}. Horde-controlled phase only.",
	[163645] = "Drops from {{npc:142739,Skycap'n Kragg}} in Arathi Highlands during the Warfront at approximately 3% drop rate {{m:14,36.7,61.1}}.",
	[163646] = "Drops from {{npc:142437,Skullripper}} in Arathi Highlands during the Warfront at approximately 3-5% drop rate {{m:14,57.4,45.8}}.",
	[163706] = "Drops from {{npc:142508,Darbel Montrose}} in Arathi Highlands during the Warfront at approximately 3% drop rate {{m:14,50.7,36.4}}.",
	[164762] = "Reward for unlocking the Zandalari Troll allied race (Horde only). Requires completing the Zandalar Forever! achievement and the Zandalari recruitment questline.",
	[166428] = "Drops from {{npc:149652,Blackpaw}} in Darkshore during the Warfront at approximately 3-5% drop rate {{m:62,49.7,24.3}}. Horde-controlled phase.",
	[166432] = "Drops from {{npc:148787,Alash'anir}} in Darkshore during the Warfront at approximately 3% drop rate {{m:62,56.3,30.8}}. Horde-controlled phase. Can also drop from Darkshore Warfront completion cache.",
	[166433] = "Drops from {{npc:148787,Alash'anir}} in Darkshore during the Warfront at approximately 3% drop rate {{m:62,56.3,30.8}}. Also drops from other Darkshore rares at lower rates. Horde only.",
	[166434] = "Drops from {{npc:148787,Alash'anir}} in Darkshore during the Warfront at approximately 3-5% drop rate {{m:62,56.3,30.8}}. Drops when your faction controls Darkshore.",
	[166435] = "Drops from {{npc:148790,Frightened Kodo}} in Darkshore during the Warfront at approximately 3-5% drop rate {{m:62,41.4,76.1}}. Drops when your faction controls Darkshore.",
	[166436] = "Purchased for 750 7th Legion Service Medals (Alliance) or Honorbound Service Medals (Horde) from {{npc:135446,Provisioner Stoutforge}} in Boralus or {{npc:135447,Provisioner Mukra}} in Dazar'alor.",
	[166438] = "Drops from {{npc:149652,Blackpaw}} in Darkshore during the Warfront at approximately 3-5% drop rate {{m:62,49.7,24.3}}. Drops when your faction controls Darkshore.",
	[166442] = "Purchased from {{npc:141008,Gottum}} in {{m:896,Drustvar}} for 333,333g {{m:896,20.8,44.6}}. No reputation requirement.",
	[166443] = "Purchased from {{npc:141008,Gottum}} in {{m:896,Drustvar}} for 333,333g {{m:896,20.8,44.6}}. No reputation requirement.",
	[166463] = "Purchased for 750 7th Legion Service Medals from {{npc:135446,Provisioner Stoutforge}} in Boralus. Alliance only. Medals are earned from Warfront contributions and PvP activities.",
	[166464] = "Purchased for 750 7th Legion Service Medals (Alliance) or Honorbound Service Medals (Horde) from {{npc:135446,Provisioner Stoutforge}} in Boralus or {{npc:135447,Provisioner Mukra}} in Dazar'alor. Medals are earned from Warfront contributions and PvP activities.",
	[166465] = "Purchased for 750 7th Legion Service Medals from {{npc:135446,Provisioner Stoutforge}} in Boralus. Alliance only. Medals are earned from Warfront contributions and PvP activities.",
	[166466] = "Random drop from Island Expedition end-of-run reward caches. Very low drop rate. Run Heroic or Mythic Islands for best chances.",
	[166467] = "Random drop from Island Expedition end-of-run reward caches. Very low drop rate. Run Heroic or Mythic Islands for best chances. Can also appear on the Black Market Auction House.",
	[166468] = "Random drop from Island Expedition end-of-run reward caches. Very low drop rate. Run Heroic or Mythic Islands for best chances.",
	[166469] = "Purchased for 750 Honorbound Service Medals from {{npc:135447,Provisioner Mukra}} in Dazar'alor. Horde only. Medals are earned from Warfront contributions and PvP activities.",
	[166470] = "Random drop from Island Expedition end-of-run reward caches. Very low drop rate. Run Heroic or Mythic Islands for best chances. Can also appear on the Black Market Auction House.",
	[166471] = "Purchased from {{npc:142692,Captain Klarisa}} (Alliance) or {{npc:142693,Captain Zen'taga}} (Horde) for 500 Seafarer's Dubloons. Dubloons are earned from Island Expeditions.",
	[166518] = "Drops from {{npc:146409,Lady Jaina Proudmoore}} in Battle of Dazar'alor on Mythic difficulty. Approximately 1% drop rate (was 100% during current content). Soloable at current gear. Also available on the Black Market Auction House.",
	[166539] = "Reward from the Glory of the Dazar'alor Raider achievement. Requires completing all boss-specific achievements in Battle of Dazar'alor.",
	[166705] = "Drops from {{npc:158041,N'Zoth the Corruptor}} in Ny'alotha, the Waking City on Mythic difficulty. Very low drop rate (~1%). Was 100% during current content. Also available on the Black Market Auction House.",
	[166745] = "Purchased from {{npc:142692,Captain Klarisa}} (Alliance) or {{npc:142693,Captain Zen'taga}} (Horde) for 1,000 Seafarer's Dubloons. Dubloons are earned from Island Expeditions.",
	[167167] = "Purchased from {{npc:154140,Artisan Okata}} in Nazjatar for 150 Prismatic Manapearls. Requires Revered with Waveblade Ankoan. Alliance only.",
	[167170] = "Purchased from {{npc:154169,Finder Palta}} in Nazjatar for 150 Prismatic Manapearls. Requires Revered with The Unshackled. Horde only.",
	[167171] = "Reward from the Glory of the Eternal Raider achievement. Requires completing all boss-specific achievements in The Eternal Palace raid.",
	[167751] = "Crafted through the Paint Vial system in Mechagon. Collect 8 different color Paint Vials from Mechagon rares and treasures, then apply them to the Junkyard Tinkering crafting station with a Blueprint: Mechanocat. Paint Vials drop from specific Mechagon rares at ~5-10% rates.",
	[168055] = "Reward from the Two Sides to Every Tale achievement (Horde version). Requires completing both the Kul Tiras and Zandalar storyline achievements on one character.",
	[168056] = "Reward from the Two Sides to Every Tale achievement (Alliance version). Requires completing both the Kul Tiras and Zandalar storyline achievements on one character.",
	[168329] = "Reward from the Mecha-Done meta-achievement. Requires completing a wide range of Mechagon activities including rares, events, construction projects, and exploration.",
	[168370] = "Drops from {{npc:150394,Aerial Unit R-21/X}} in {{m:1462,Mechagon}} at approximately 2-4% drop rate {{m:1462,65.5,51.7}}. Standard rare kill, respawns every 30-60 minutes.",
	[168408] = "Reward from the Child of Torcali quest chain in Zuldazar (Horde only). Multi-day questline starting from {{npc:126334,Torcali}} in Zuldazar. Raise a direhorn over several days of daily quests.",
	[168823] = "Drops from {{npc:152113,The Rusty Prince}} in the Mechagon underwater area at approximately 2-3% drop rate {{m:1462,58.0,24.0}}. Requires clicking fungal growth nodes to summon. Can also drop from the Reclamation Rig event.",
	[168826] = "Drops from {{npc:150396,HK-8 Aerial Oppression Unit}} in Operation: Mechagon dungeon. Approximately 1-2% drop rate. Drops on Mythic difficulty.",
	[168827] = "Reward from the Scrapforged Mechaspider questline in Mechagon. Complete the quest chain starting with Junkyard Treasures. Requires collecting various mechanical parts and blueprints across Mechagon.",
	[168829] = "Purchased from {{npc:150716,Stolen Royal Vendorbot}} in Mechagon for 524,288g. Requires Exalted with Rustbolt Resistance. Price fluctuates based on Pascal running.",
	[168830] = "Drops from {{npc:144838,King Mechagon}} in Operation: Mechagon dungeon on Hard Mode. Approximately 1-2% drop rate. Hard Mode requires not pressing any red buttons throughout the dungeon.",
	[169162] = "Reward from the Battle for Azeroth Pathfinder, Part Two achievement. Requires completing Part One (exploration, rep, story) plus the Mechagon and Nazjatar exploration achievements.",
	[169163] = "Drops from {{npc:152681,Prince Typhonus}} or {{npc:152682,Prince Vortran}} in Nazjatar at approximately 1-3% drop rate. These are summoned rares in the murloc area.",
	[169194] = "Reward from the Undersea Usurper achievement. Requires completing a large number of Nazjatar achievements including exploration, combat, and quest-related tasks.",
	[169198] = "Drops from the Waveblade Ankoan (Alliance) or Unshackled (Horde) Paragon reputation cache at approximately 3-5% drop rate. Continue earning rep past Exalted for paragon caches by doing Nazjatar world quests and dailies.",
	[169199] = "Reward from completing the quest Friends in Need in Nazjatar. Requires completing the full Nazjatar introductory campaign and befriending all three Nazjatar bodyguards.",
	[169200] = "Reward from completing the quest Snapdragon Apprentice in Nazjatar. Requires reaching Rank 3 with a Nazjatar bodyguard (Alliance: Hunter Akana, Farseer Ori, or Bladesman Inowari; Horde: Neri Sharpfin, Vim Brineheart, or Poen Gillbrack).",
	[169201] = "Drops from various rares in Nazjatar at a very low drop rate. Can drop from {{npc:152712,Blindlight}} {{m:1355,37.0,13.4}} or other Nazjatar rares. Very rare zone-wide drop.",
	[169202] = "Purchased from {{npc:152084,Mrrl}} in Nazjatar through a secret murloc trading chain. Requires buying and trading specific items between Mrrl's murloc vendors in the correct sequence. Stock rotates daily. Use an addon like MrrlHelper to track the correct trade sequence.",
	[169203] = "Purchased from {{npc:153512,Finder Palta}} (Horde) or {{npc:151310,Artisan Okata}} (Alliance) in Nazjatar for 150 Prismatic Manapearls. Requires Revered with The Unshackled or Waveblade Ankoan.",
	[170069] = "Reward from raising the Honeyback Hive reputation to Revered in {{m:942,Stormsong Valley}} (Alliance only). Start at {{m:942,69.0,64.0}} by finding Barry the Bee. Feed jelly to the hive daily. Farming thin and royal jelly from mobs and flowers speeds up the process significantly.",
	[173887] = "Drops from {{npc:157153,Ha-Li}} in {{m:1530,Vale of Eternal Blossoms}} at approximately 2-5% drop rate {{m:1530,34.0,68.0}}. Ha-Li flies around the northwestern area of the Vale during Mogu assaults.",
	[174066] = "Reward for unlocking the Mechagnome allied race (Alliance only). Requires completing the Mechagon storyline and the Mechagnome recruitment questline.",
	[174067] = "Reward for unlocking the Vulpera allied race (Horde only). Requires completing the Vol'dun storyline and reaching Exalted with the Voldunai, then completing the recruitment questline.",
	[174641] = "Drops from {{npc:162372,Ishak of the Four Winds}} during Amathet assault in {{m:1527,Uldum}} at approximately 2-5% drop rate {{m:1527,73.7,83.5}}. Can also be looted from the Uldum Accord paragon cache.",
	[174649] = "Purchased from {{npc:160711,Zhang Ku}} in {{m:1530,Vale of Eternal Blossoms}} for 1 Pristine Cloud Serpent Scale. The scale drops from {{npc:157160,Lei}} world boss or can be purchased from the Rajani reputation vendor at Exalted.",
	[174653] = "Rare drop from a mailbox mimic that randomly spawns in Horrific Visions of Stormwind or Orgrimmar at approximately 1-2% chance per vision. The mailbox can appear in any district. Click the mailbox to spawn a hostile Mail Muncher that drops the mount.",
	[174654] = "Reward from the Ahead of the Curve: N'Zoth the Corruptor achievement. This was the BFA Season 4 AotC reward for defeating N'Zoth on Heroic difficulty before the Shadowlands pre-patch. No longer obtainable.",
	[174752] = "Drops from {{npc:157160,Houndlord Ren}} in {{m:1530,Vale of Eternal Blossoms}} at approximately 2-3% drop rate {{m:1530,12.0,34.0}}. Spawns during Mogu assaults.",
	[174753] = "Obtained through the Aqir Hatchling questline in {{m:1527,Uldum}}. Find a Shadowbarb Egg during an Aqir assault, then complete daily quests over several days to hatch and raise the drone. Start by finding a Voidtouched Egg at {{m:1527,54.8,30.8}}.",
	[174754] = "Purchased from {{npc:160714,Provisioner Qorra}} in Uldum for 5,000g. Requires Exalted with Uldum Accord. Complete N'Zoth assaults and dailies in Uldum for reputation.",
	[174769] = "Drops from {{npc:162147,Corpse Eater}} during Aqir assault in {{m:1527,Uldum}} at approximately 2-3% drop rate. The Aqir assault must be the active minor assault in Uldum.",
	[174770] = "Purchased from {{npc:162396,Wrathion}} in the Chamber of Heart for 100,000 Corrupted Mementos. Corrupted Mementos are earned from Horrific Visions of N'Zoth.",
	[174771] = "Obtained through the Aqir Hatchling questline in {{m:1527,Uldum}}. Find a Voidtouched Egg during an Aqir assault at {{m:1527,54.8,30.8}}, then complete a multi-day quest chain to raise the drone through stages.",
	[174840] = "Drops from {{npc:157468,Ivory Cloud Serpent}} that spawns as a rare mob during the Rajani daily assault in {{m:1530,Vale of Eternal Blossoms}}. Approximately 3-5% drop rate. Use Rajani faction daily quest items to trigger the spawn.",
	[174841] = "Drops from {{npc:157266,Anh-De the Loyal}} in {{m:1530,Vale of Eternal Blossoms}} at approximately 2-5% drop rate {{m:1530,34.0,26.0}}. Spawns during Mantid assaults.",
	[174842] = "Drops from {{npc:156884,Vuk'laz the Earthbreaker}} or other 8.3 world bosses in Uldum/Vale at very low drop rate (~1%). Kill the weekly world boss during N'Zoth assaults for a chance.",
	[174859] = "Reward from befriending the Friendly Alpaca in {{m:1527,Uldum}} by feeding it Gersahl Greens 7 times over 7 days. The alpaca spawns at various locations in Uldum. Gersahl Greens are picked from nodes scattered around Uldum.",
	[174860] = "Feed Seaside Leafy Greens Mix to the Elusive Quickhoof rare alpaca in {{m:864,Vol'dun}}. The alpaca spawns at different locations and must be found while active. Seaside Leafy Greens Mix is crafted from cooking reagents or bought from the AH.",
	[174861] = "Reward from the Glory of the Ny'alotha Raider achievement. Requires completing all boss-specific achievements in Ny'alotha, the Waking City.",
	[174872] = "Drops from {{npc:158041,N'Zoth the Corruptor}} in Ny'alotha, the Waking City on Mythic difficulty. Very low drop rate (~1%). Soloable at max level. Also available on the Black Market Auction House.",
	[180263] = "Quest reward from 'What's My Motivation?' (Night Fae covenant campaign).\n\nAutomatically awarded during the Night Fae covenant campaign storyline.\nNo reputation or currency required.",
	[180413] = "Purchased from Elwyn (Renown Quartermaster) in Heart of the Forest, Ardenweald.\n\nCost: 5,000 Reservoir Anima. Requires Night Fae covenant + Renown 23.",
	[180414] = "Rare drop from Queen's Conservatory Cache (approximately 0.3% drop rate).\n\nPlant a Wildseed of Regrowth (highest tier) with a Spirit in the Queen's Conservatory.\nUse Tier 3 Catalysts for best results. Cache spawns after ~3 days.\nRNG drop - keep planting higher-tier spirits and catalysts.",
	[180415] = "Purchased from Spindlenose (Court of Night Quartermaster) in Ardenweald.\n\nCost: 5,000 Reservoir Anima + 5 Grateful Offerings.\nRequires Court of Night - Revered + Night Fae covenant.\nSame vendor/requirements as Umbral Scythehorn.",
	[180461] = "Rare drop from Harika the Horrid (rare in Revendreth) at approximately 2.1% drop rate.\n\nSpawned via the Venthyr Anima Conductor - channel anima to the Forest Ward.\nAlso purchasable from vendor in Sinfall with Grateful Offerings as a backup.",
	[180581] = "Rare drop from Hopecrusher (rare elite in Revendreth) at approximately 1.5% drop rate.\n\nLocated in the Chalice District of Revendreth. Requires Venthyr covenant.\nLow drop rate - expect repeated kills.",
	[180582] = "Drops from Famu the Infinite (rare in Revendreth) at approximately 0.9% drop rate.\n\nLarge world boss-style rare in the Endmire area {{m:1525,62.4,47.0}}.\nLong respawn (~30-60 min). Very low drop rate - expect a long farm.",
	[180721] = "Quest reward from 'Drust and Ashes' (Night Fae covenant campaign, later chapter).\n\nReward from a later campaign chapter. Pick-one reward option.",
	[180722] = "Purchased from Elwyn (Renown Quartermaster) in Heart of the Forest, Ardenweald.\n\nCost: 100 Reservoir Anima + 40 Grateful Offerings.\nRequires Night Fae covenant + Renown 39.",
	[180723] = "Rare drop from Queen's Conservatory Cache (approximately 0.2% drop rate).\n\nRarer version of the Wakener's Runestag from the same mechanic.\nUse Divine spirit + Tier 3 catalysts in the highest-tier wildseed.\nVery low drop rate - plan for many attempts.",
	[180724] = "Purchased from Cortinarius (Marasmius Quartermaster) in Ardenweald.\n\nCost: 5,000 Reservoir Anima. Requires Marasmius - Revered.\nSame vendor/rep as Vibrant Flutterwing.",
	[180725] = "Drops from Gormtamer Tizo (rare in Ardenweald) at approximately 64% drop rate {{m:1565,32.4,46.4}}.\n\nStraightforward rare kill with high drop rate. Respawn timer ~10-15 minutes.",
	[180726] = "Purchased from covenant feature vendors after completing certain covenant feature achievements.\n\nCheapest vendor: Binkiros in Elysian Hold (Bastion) for 2,500 Reservoir Anima.\nAlso sold by Atticus or Abomination in Maldraxxus for 5,000 Reservoir Anima.\nRelated to Necrolord Abomination Factory 'Bare Necessities' achievement.",
	[180727] = "Reward from completing the Shimmermist Maze in Mistveil Tangle, Ardenweald {{m:1565,31.0,55.0}}.\n\nNavigate the maze and kill the Shimmermist Runner at the end to loot the mount.\nEssentially 100% drop upon maze completion. The maze resets periodically.",
	[180728] = "Drops from the Night Mare (rare in Ardenweald) at approximately 86% drop rate.\n\nRequires a Dream Catcher + Crescent Mirror Shard to summon {{m:1565,57.6,72.8}}.\nEssentially guaranteed if you can summon it. The challenge is obtaining the summoning items.\nSpawns near Tirna Noch in Ardenweald.",
	[180729] = "Purchased from Aithlyn (Wild Hunt Quartermaster) in Ardenweald.\n\nCost: 24,000 gold (or 28,500g in Oribos from Liawyn). Requires The Wild Hunt - Exalted.\nDo Ardenweald world quests, callings, and use a Wild Hunt contract.",
	[180730] = "Rare drop from Valfir the Unrelenting (rare in Ardenweald) at approximately 1% drop rate.\n\nValfir is an Anima Conductor rare that only spawns when Night Fae players\nchannel anima to the right location. Requires Anima Conductor active.\nFarm daily. Can also be purchased from vendor as a backup.",
	[180731] = "Drops from Cache of the Moon treasure in Ardenweald at approximately 90% drop rate {{m:1565,36.7,55.3}}.\n\nRequires completing a multi-step puzzle involving moonlit objects near the water.\nEssentially guaranteed from the cache. The challenge is unlocking it.\nRequires Night Fae campaign progress or a specific activation sequence.",
	[180748] = "Must participate in 7 different performances at the Star Lake Amphitheater.\nRequires Night Fae Anima Conductor channeled to Star Lake Amphitheater.\nPerformances rotate daily - takes minimum 7 different days.",
	[180761] = "Kyrian Path of Ascension reward. Earned by completing combat trials in the Kyrian proving grounds.\n\nRequires Kyrian covenant membership. Path of Ascension is a soulbind-based combat system.\nYou control soulbinds directly and gather materials in Bastion to summon opponents.",
	[180762] = "Purchased from Adjutant Galos (Renown Quartermaster) in Elysian Hold, Bastion.\n\nCost: 5,000 Reservoir Anima + 100 Grateful Offerings.\nRequires Kyrian covenant. Grateful Offerings come from Anima Conductor activities.",
	[180763] = "Quest reward from 'Building the Base' (Kyrian covenant campaign, Chapter 3).\n\nAutomatically awarded during the Kyrian covenant campaign storyline.\nNo currency needed - just progress through the campaign.",
	[180764] = "Purchased from Adjutant Galos (Renown Quartermaster) in Elysian Hold, Bastion.\n\nCost: 5,000 Reservoir Anima. Requires Kyrian covenant + Renown 23.",
	[180765] = "Purchased from Adjutant Galos (Renown Quartermaster) in Elysian Hold, Bastion.\n\nCost: 100 Medallion of Service + 50 Grateful Offerings.\nRequires Kyrian covenant + Renown 39. Armored upgrade of the base Phalynx.",
	[180766] = "Quest reward from 'A New Age' - the final quest of the Kyrian covenant campaign.\n\nGilded armored version. Automatically awarded at campaign completion.",
	[180767] = "Purchased from Binkiros (Mount Vendor) in Elysian Hold, Archon's Rise.\n\nCost: 2,500 Reservoir Anima. Requires Kyrian covenant + 'Death Foursworn' achievement.\nMust defeat all 4 Forsworn bosses in Path of Ascension.",
	[180768] = "Purchased from Binkiros (Mount Vendor) in Elysian Hold, Archon's Rise.\n\nCost: 2,500 Reservoir Anima. Requires Kyrian covenant + 'Learning from the Masters' achievement.\nMust defeat all Path of Ascension bosses on Loyalty difficulty - the hardest tier.",
	[180772] = "Drops from Gift of the Silver Wind treasure in Bastion {{m:1533,53.0,88.0}}.\n\nRequires finding and activating 5 Silver Wind scrolls/vespers across Bastion first.\nEach scroll is in a hard-to-reach location requiring exploration and platforming.\nSome scrolls require the larion network flight paths. Approximately 68% drop rate from chest.",
	[180773] = "Obtained from Sundancer on a floating platform in Bastion {{m:1533,60.2,28.4}}.\n\nRequires an Anima-Tinged Egg (purchased from Elios in Bastion).\nUse Skystrider Glider or similar to reach the floating platform.\nUse the egg near Sundancer to tame it - mount is added directly. 1-2 hour respawn.",
	[180945] = "Quest reward from 'Mirror, Mirror...' (Venthyr covenant campaign, Chapter ~5).\n\nEarly campaign reward. Automatically guaranteed upon quest completion.",
	[180948] = "Quest reward from 'The Medallion of Dominion' (Venthyr covenant campaign, Chapter 12).\n\nPrince Renathal's loyal gargon. Automatically awarded upon quest completion.",
	[181300] = "Purchased from covenant feature vendors. Related to Night Fae Queen's Conservatory.\n\nCheapest vendor: Binkiros in Elysian Hold (Bastion) for 2,500 Reservoir Anima.\nAlso sold in Maldraxxus for 5,000 Reservoir Anima.\nRequires the 'All The Colors of the Painbow' achievement from growing different wildseeds.",
	[181316] = "Purchased from covenant feature vendors. Related to the Venthyr Ember Court.\n\nCheapest vendor: Binkiros in Elysian Hold (Bastion) for 2,500 Reservoir Anima.\nAlso sold by Temel (Revendreth), Atticus (Maldraxxus) for 5,000 Reservoir Anima.\nEmber Court is a weekly Venthyr event requiring multiple weeks of progression.",
	[181317] = "Purchased from covenant feature vendors. Related to Kyrian Path of Ascension.\n\nSold by Atticus/Abomination in Maldraxxus for 5,000 Reservoir Anima.\nPath of Ascension requires defeating NPCs in proving grounds scenarios using soulbinds.",
	[181815] = "Rare drop from Sabriel the Bonecleaver (rare elite in Maldraxxus) at approximately 0.5% drop rate.\n\nSpawns in the Theater of Pain area {{m:1536,50.8,47.2}}.\nTied to Necrolord Anima Conductor - must channel anima to the specific location to spawn her.\nAlso purchasable from vendor with Grateful Offerings.",
	[181818] = "Contained in a Cracked Blight-Touched Egg in Maldraxxus (100% mount chance from the egg).\n\nThe egg spawns as a clickable object near the Plaguefall area/Festering Sanctum {{m:1536,58.0,74.0}}.\nThe egg itself is the rare find - it has a long respawn timer and can be looted by others.\nCamp known egg spawn points in the Blighted Scar / House of Plagues area.",
	[181819] = "Drops from Nalthor the Rimebinder (final boss) in The Necrotic Wake on Mythic difficulty.\n\nDrop rate approximately 1-2%. Also available from M+ Challenger's Cache when in rotation.\nFastest farm: run Mythic (non-keystone), kill Nalthor, leave, reset. Capped at 10 instances/hour.\nDoes NOT drop on Normal/Heroic - Mythic or higher only.",
	[181820] = "Achievement reward: 'Things To Do When You're Dead' (Abominable Stitching meta-achievement).\n\nRequires completing ALL Abominable Stitching sub-achievements.\nVery long grind - craft many constructs across multiple weeks.",
	[181821] = "Purchased from Su Zettai (Renown Quartermaster) at the Seat of the Primus.\n\nCost: 100 Reservoir Anima + 50 Grateful Offerings. Requires Necrolord covenant + Renown 39.\nGrateful Offerings come from Anima Conductor activities.",
	[181822] = "Quest reward from 'The Third Fall of Kel'Thuzad' (Necrolord covenant campaign, later chapter).\n\nContinue the Necrolord campaign to earn this armored variant. Automatically awarded.",
	[182074] = "Achievement reward: 'The Gang's All Here' (Abominable Stitching).\n\nRequires building each of the required constructs with the Necrolord Abominable Stitching feature.\nTakes significant time and materials to craft every construct.",
	[182075] = "Rare drop from Tahonta (rare mob in Maldraxxus) at approximately 0.6% drop rate.\n\nTahonta spawns in Maldraxxus {{m:1536,44.6,52.0}}. Standard ~15-30 min respawn.\nVery low drop rate - expect many kills.",
	[182076] = "Purchased from Su Zettai (Renown Quartermaster) at the Seat of the Primus, Maldraxxus.\n\nCost: 5,000 Reservoir Anima. Requires Necrolord covenant + Renown 23.",
	[182077] = "Quest reward from 'Enemy at the Door' (Necrolord covenant campaign, early chapter).\n\nFirst mount earned just by doing the Necrolord campaign. Automatically awarded.",
	[182078] = "Created via Abominable Stitching (Necrolord covenant crafting feature) at the Seat of the Primus.\n\nRequires the Bonesewn Fleshroc recipe + 50 materials + 5 specific reagents.\nOnly available to Necrolord covenant members.",
	[182079] = "Drops from Violet Mistake (rare in Maldraxxus) at approximately 3.7% drop rate.\n\nSpawns in the slime-filled pool area of eastern Maldraxxus {{m:1536,72.4,45.2}}.\nStandard rare kill with ~15-30 min respawn.",
	[182080] = "Rare drop from Gieger (rare mob in Maldraxxus) at approximately 2.3% drop rate.\n\nSpawns at {{m:1536,31.4,35.6}} in the House of Constructs area.\nNecrolord-only - must be spawned via Necrolord Anima Conductor.\nBetter drop rate than most SL rare mount drops.",
	[182081] = "Drops from Supplies of the Undying Army (Paragon cache) at approximately 3.6% drop rate.\n\nContinue earning Undying Army reputation past Exalted. Every 10,000 rep past Exalted awards a paragon cache.\nDo Maldraxxus world quests, callings, and use a contract.",
	[182082] = "Purchased from Nalcorn Talsen (Undying Army Quartermaster) in Maldraxxus.\n\nCost: 24,000 gold (Maldraxxus). Requires The Undying Army - Exalted.\nMaldraxxus world quests, callings, and contract.",
	[182084] = "Drops from Nerissa Heartless (rare in Maldraxxus) at approximately 2.2% drop rate.\n\nLocated in the House of Rituals area {{m:1536,66.3,35.2}}.\nStandard rare kill with ~15-30 min respawn.",
	[182085] = "Drops from Warbringer Mal'Korak (rare in Maldraxxus) at approximately 2.5% drop rate.\n\nLocated in Keres' Rest {{m:1536,35.4,55.6}}. ~15-30 min respawn.\nStandard rare kill - no special summoning needed.",
	[182209] = "Drops from The Countess' Extravagant Tribute (~8%) or Substantial Tribute (~1.7%) at the Ember Court.\n\nRequires Venthyr covenant. Invite The Countess as an Ember Court guest.\nAchieve highest happiness tier for Extravagant Tribute for best drop chance.\nWeekly event - may take many weeks.",
	[182332] = "Purchased from Chachi the Artiste (Renown Quartermaster) in Sinfall.\n\nCost: 100 Reservoir Anima + 50 Grateful Offerings. Requires Venthyr covenant + Renown 39.\nGrateful Offerings from Anima Conductor activities.",
	[182589] = "Questline begins by looting Worldedge Gorger {{m:10413,38.8,72}}",
	[182614] = "To get Blanchy's Reins Blanchy's Reins you have to bring items to Dead Blanchy 6 times in Revendreth.\nYou can do it only once per day so you need 6 days to get the mount. The day starts with the daily quest reset.\nYou can obtain all the items you need in advance.\nDead Blanchy spawns on the river in Endmire north of Darkhaven\nand starts to run until it bumps into a player. Everyone can interact with it.\nBlanchy runs faster than your mount so take the right position to intercept it.\nIt despawns after 5 minutes. The respawn timer is from 1 to 2 hours.",
	[182650] = "Drops from Humon'gozz (summoned rare in Ardenweald) at approximately 72% drop rate.\n\nPick up an Unusually Large Mushroom (from mobs or found near {{m:1565,54.2,72.2}}).\nBring it to the Damp Loam {{m:1565,67.0,50.0}} and plant it to spawn Humon'gozz.",
	[182954] = "Purchased from Archivist Janeera (Revendreth) or Archivist Leonara (Oribos).\n\nCost: 2,000 Reservoir Anima. Requires Venthyr covenant + Exalted with The Avowed.\nThe Avowed reputation is gated behind Venthyr-only content (Halls of Atonement/Sinfall).",
	[183052] = "Chance to appear in mission table.",
	[183053] = "Purchased from Spindlenose (Court of Night Quartermaster) in Ardenweald.\n\nCost: 5,000 Reservoir Anima + 5 Grateful Offerings.\nRequires Court of Night - Revered. Court of Night rep is earned via the Night Fae Anima Conductor.",
	[183518] = "Purchased from Mistress Mihaela (Court of Harvesters Quartermaster) in Revendreth.\n\nCost: 30,000 gold. Requires Court of Harvesters - Exalted.\nRevendreth world quests, callings, and contract.",
	[183615] = "Chance to appear in mission table.",
	[183617] = "Chance to appear in mission table.",
	[183618] = "Chance to appear in mission table.",
	[183715] = "Purchased from Chachi the Artiste (Renown Quartermaster) in Sinfall.\n\nCost: 5,000 Reservoir Anima. Requires Venthyr covenant + Renown 23.",
	[183740] = "Purchased from Adjutant Nikos (Ascended Quartermaster) in Bastion.\n\nCost: 24,000-30,000 gold. Requires The Ascended - Exalted.\nBastion world quests, callings, and contract.",
	[183741] = "Drops from Cache of the Ascended (treasure in Bastion) at approximately 5% drop rate.\n\nRequires completing the Bastion 'Purity's Pinnacle' rare event {{m:1533,33.2,56.6}}.\nDefeat all 4 Ascended champions at their shrines, then a 5th Vesper spawns.\nAfter all 5 are defeated, the Cache of the Ascended spawns. Coordinate with other players.",
	[183798] = "Very rare drop (~0.5-1%) from Forgotten Chests scattered across Revendreth.\n\n12 different Forgotten Chest spawn locations in Revendreth.\nFarm all chest locations daily. Very RNG-heavy.",
	[183800] = "Drops from Wild Hunt Supplies (Paragon cache) at approximately 3.0% drop rate.\n\nContinue grinding Wild Hunt reputation past Exalted for paragon caches.\nNight Fae covenant members earn rep faster in Ardenweald.",
	[183801] = "Purchased from Cortinarius (Marasmius Quartermaster) in Ardenweald.\n\nCost: 5,000 Reservoir Anima. Requires Marasmius - Revered.\nMarasmius is the Night Fae Transportation Network faction. Upgrade your mushroom network fully.",
	[184062] = "Zone drop from Theater of Pain dungeon bosses in Maldraxxus (approximately 0.4-0.6% per boss).\n\nCan drop from any boss in the dungeon on any difficulty.\nFarm Normal for fastest runs. One of the rarest SL dungeon drops.",
	[184160] = "Contained in an Oozing Necroray Egg (~34% chance per egg).\n\nOozing Necroray Eggs are rare drops from Maldraxxus-zone Calling reward caches.\nEach egg gives one random necroray mount (Bulbous, Infested, or Pestilent - equal chance).\nDo Maldraxxus Callings on multiple characters for more egg chances.",
	[184161] = "Contained in an Oozing Necroray Egg (~33% chance per egg).\n\nOozing Necroray Eggs are rare drops from Maldraxxus-zone Calling reward caches.\nEach egg gives one random necroray mount. Equal probability between the 3 variants.\nFarm on multiple alts to increase egg drops.",
	[184162] = "Contained in an Oozing Necroray Egg (~33% chance per egg).\n\nOozing Necroray Eggs are rare drops from Maldraxxus-zone Calling reward caches.\nEach egg gives one random necroray mount. All 3 share equal probability from the egg.",
	[184167] = "Drops from Gorged Shadehound (event rare in The Maw) at approximately 1.8% drop rate.\n\nRequires players to use Stygia to unlock during Maw activities.\nSpawns after feeding a caged Shadehound. Multiple spawn points across The Maw.",
	[184168] = "Secret mount obtained via quest 'Feral Shadehound' in The Maw.\n\nRequires finding Spectral Hound Clues throughout The Maw and performing a binding ritual.\nNeed significant Maw exploration and Ve'nari reputation progress.\nFollow a comprehensive guide for the full puzzle chain.",
	[185973] = "Extremely rare drop from Tormentors of Torghast event in The Maw (approximately 0.03-0.16% drop rate).\n\nTormentors spawn every 2 hours at set locations in The Maw.\nComplete the event and loot the rewards chest. One loot per event per character.\nBring alts for more chances. Extremely low drop rate - expect a very long farm.",
	[185996] = "Drops from Harvester's War Chest - reward for completing the Venthyr Covenant Assault in The Maw.\n\nDrop rate approximately 4.2%. Covenant assaults rotate every ~3.5 days (2 active at a time).\nComplete all assault objectives and the final boss to receive the war chest.\nRun on multiple characters per cycle for more chances.",
	[186000] = "Drops from War Chest of the Wild Hunt - reward for completing the Night Fae Covenant Assault in The Maw.\n\nDrop rate approximately 4.1%. Wait for the Night Fae assault to be active.\nComplete objectives and kill the final boss. Run on alts for extra chances.",
	[186103] = "Drops from War Chest of the Undying Army - reward for completing the Necrolord Covenant Assault in The Maw.\n\nDrop rate approximately 4.4%. Wait for the Necrolord assault to be active.\nComplete objectives and kill the final boss. Run on alts for extra chances.",
	[186476] = "Venthyr covenant reward from patch 9.1 (Chains of Domination).\n\nUnlocked via Venthyr covenant progression in the 9.1 campaign.",
	[186477] = "Purchased from Duchess Mynx (Death's Advance Quartermaster) in Korthia.\n\nCost: 1,000 Stygia. Requires Exalted with Death's Advance + 'On the Offensive' achievement.\nFarm Korthia dailies and complete all Maw assault achievements.",
	[186478] = "Purchased from Chachi the Artiste (Renown Quartermaster) in Sinfall.\n\nCost: 7,500 Reservoir Anima. Requires Venthyr covenant + Renown 70.\nDark/black obsidian coloring.",
	[186479] = "Rare drop from Stygian Stonecrusher (rare in Korthia).\n\nThe Gravewing Crystal quest auto-accepts upon looting the item.\nRequires Venthyr covenant. Handcrafted by the Stonewright.",
	[186480] = "Purchased from Duchess Mynx (Death's Advance Quartermaster) in Korthia.\n\nCost: 1,000 Stygia. Requires Exalted with Death's Advance + 'On the Offensive' achievement.\n'On the Offensive' requires completing all 4 covenant assault meta-achievements in The Maw.",
	[186482] = "Quest reward from the 9.1 Kyrian covenant campaign (Chains of Domination).\n\nAutomatically awarded upon completing the 9.1 Kyrian campaign chapters.\nNo currency purchase needed.",
	[186483] = "Drops from Wild Worldcracker (rare mob in Korthia) as the Intact Aquilon Core quest item.\n\nVery low drop rate. The quest auto-accepts upon looting.\nRequires Kyrian covenant to use the quest item.\nGroup up and camp the rare. Check /1 general chat for spawn callouts.",
	[186485] = "Purchased from Adjutant Galos (Renown Quartermaster) in Elysian Hold, Bastion.\n\nCost: 7,500 Reservoir Anima. Requires Kyrian covenant + Renown 70.\nPrestige Kyrian flying mount from patch 9.1.",
	[186487] = "Necrolord covenant reward from patch 9.1 (Chains of Domination).\n\nObtained through Necrolord covenant progression in the 9.1 campaign.\nBase corpsefly model.",
	[186488] = "Purchased from Su Zettai (Renown Quartermaster) at the Seat of the Primus.\n\nCost: 7,500 Reservoir Anima. Requires Necrolord covenant + Renown 70.\nHighest renown requirement among Necrolord vendor mounts.",
	[186489] = "Contained in Hatching Corpsefly Egg in Korthia (Necrolord-only).\n\nInteract with Corpsefly eggs found around Korthia over multiple days.\nEventually one hatches into Fleshwing {{m:1961,60.0,73.0}}.\nRequires multiple daily interactions before it hatches.",
	[186490] = "Purchased from Duchess Mynx (Death's Advance Quartermaster) in Korthia.\n\nCost: 1,000 Stygia. Requires Exalted with Death's Advance + 'On the Offensive' achievement.\nFarm Korthia dailies and complete all Maw assault achievements.",
	[186492] = "Drops from the Escaped Wilderling (rare spawn event in Korthia).\n\nWhen the Escaped Wilderling appears, pick up the Wilderling Saddle quest item.\nQuest auto-accepts and awards the mount. Check the rare spawn timer daily.\nContested with other players - be quick.",
	[186493] = "Night Fae covenant reward from patch 9.1 (Chains of Domination).\n\nAutomatically rewarded during 9.1 covenant campaign completion.",
	[186494] = "Purchased from Elwyn (Renown Quartermaster) in Heart of the Forest, Ardenweald.\n\nCost: 7,500 Reservoir Anima. Requires Night Fae covenant + Renown 70.",
	[186495] = "Purchased from Duchess Mynx (Death's Advance Quartermaster) in Korthia.\n\nCost: 1,000 Stygia. Requires Exalted with Death's Advance + 'On the Offensive' achievement.\nFarm Korthia dailies and complete all Maw assault achievements.",
	[186638] = "Drops from So'leah (final boss) in Tazavesh: So'leah's Gambit on Mythic/Hard Mode.\n\nDrop rate approximately 2.1%. Also from M+ Challenger's Cache when Tazavesh is in rotation.\nOriginally a mega-dungeon, later split into two M+ wings.\nFarm Mythic (non-keystone) and reset. Subject to 10 instances/hour lockout.",
	[186639] = "Secret mount. Requires Renown 8 with Manaforge Vandals.\n\nStep 1 - Join all 3 cartels:\nUse {{item:249702}} (Deal: Cartel Ba), {{item:249704}} (Deal: Cartel Om), and {{item:249700}} (Deal: Cartel Zo). Crafted by Inscription or buy from the AH. Normally limited to one per week, but a macro can apply all three at once:\n/use Deal: Cartel Ba\n/use Deal: Cartel Om\n/use Deal: Cartel Zo\n\nStep 2 - Loot the dead drops inside Manaforge Omega (any difficulty, LFR works):\n- Cartel Ba Dead Drop: After Plexus Sentinel, on the right path before the Phase Warp gap crossing.\n- Cartel Om Dead Drop: Behind the building after Fractillus, on top of a rock. Can be reached without killing the boss by keeping left.\n- Cartel Zo Dead Drop: On the first mana-vent pipe before Forgeweaver Araz.\n\nNote: Ba and Zo dead drops become unreachable once Forgeweaver Araz is defeated in your instance. Dead drops can be collected across different characters.\n\nStep 3 - Complete the quest:\nAfter looting all 3 dead drops, Zo'turu on Shadow Point (outside the raid) offers the quest Someone Like Me. Rewards both the mount and {{item:249713}} (Cartel Transmorpher).",
	[186641] = "Drops from Supplies of the Archivists' Codex (Paragon cache) at approximately 8.3% drop rate.\n\nContinue earning Cataloged Research past Tier 6 for paragon caches.\nFarm Korthia relics and treasures.",
	[186642] = "Drops from Sylvanas Windrunner (final boss) in Sanctum of Domination on Mythic only.\n\nWas 100% during Shadowlands Season 2, now approximately 1%.\nMust clear full raid or use Mythic lockout extension strategy.\nSoloable at current gear levels. Available on the Black Market Auction House.",
	[186643] = "Find the doe Maelie the Wanderer in Korthia and bring her back to Tinybell {{m:13570,60.6,21.8}} every day for 6 days. On the 6th day the mount is rewarded.",
	[186644] = "Drops from Death's Advance Supplies (Paragon cache) at approximately 8.8% drop rate.\n\nSame paragon cache as Fierce Razorwing. You can get either mount from the same cache.\nContinue Korthia dailies past Exalted.",
	[186645] = "Drops from Malbog (rare in Korthia) at approximately 2.0% drop rate.\n\nStandard rare kill {{m:1961,45.6,43.6}}. ~15-30 min respawn.",
	[186646] = "Feed 10x Tasty Mawshroom to Darkmaul {{m:1961,42.6,33}}",
	[186647] = "Purchased from Duchess Mynx (Death's Advance Quartermaster) in Korthia.\n\nCost: 5,000 Stygia. Requires Death's Advance - Revered.\nDo Korthia dailies for rep. Only Revered needed, not Exalted.",
	[186648] = "Purchased from Archivist Roh-Suir in Korthia.\n\nCost: 5,000 Cataloged Research. Requires The Archivists' Codex - Tier 6.\nFarm relics and treasures in Korthia for Cataloged Research.",
	[186649] = "Drops from Death's Advance Supplies (Paragon cache) at approximately 9.1% drop rate.\n\nContinue doing Korthia dailies past Exalted for paragon caches.\nBetter drop rate than most SL paragon mounts.",
	[186651] = "Hand in 10x Lost Razorwing Egg to the Razorwing Nest {{m:13570,25.9,51.1}}",
	[186652] = "Drops from Reliwik the Defiant (rare in Korthia) at approximately 2.6% drop rate.\n\nStandard rare kill {{m:1961,56.2,31.6}}. ~15-30 min respawn.",
	[186656] = "Drops from The Nine (Skyja/Kyra) in Sanctum of Domination at approximately 0.3% drop rate.\n\nFarmable on all difficulties each week per character. Run LFR/Normal/Heroic/Mythic on multiple alts.\nThe Nine is an early boss so resets are fast. Easily soloable at current gear levels.\nAvailable on the Black Market Auction House.",
	[186657] = "Drops from Mysterious Gift from Ve'nari (Paragon cache) at approximately 10.4% drop rate.\n\nVe'nari reputation is earned from Maw activities. Continue past max rep for paragon caches.\nDecent drop rate compared to other SL paragon mounts.",
	[186659] = "Drops from the Fallen Charger (rare event in The Maw) at approximately 10.6% drop rate.\n\nThe Fallen Charger runs a set patrol across The Maw (added in 9.1).\nWatch for zone yell: 'The Fallen Charger is thundering through the Maw!'\nMust intercept and kill before it despawns. Use speed boosts. Respawn ~1-4 hours (random).\nDecent drop rate when you do kill it.",
	[186713] = "Secret mount - collect 5 rings scattered across The Maw and Korthia to form the Nilganihmaht Control Ring.\n\nRings needed: Ring of Duplicity, Ring of Foreboding, Ring of Malice, Ring of Pain, Ring of Relinquished.\nEach ring requires a different challenge: Tormentors, hidden areas, rare kills, Maw activities.\nOne of the most complex puzzle mounts in Shadowlands. Follow a comprehensive guide.",
	[187183] = "Drops from Konthrogz the Obliterator (rare in Korthia) at approximately 2.4% drop rate.\n\nStandard rare kill {{m:1961,59.6,22.2}}. ~15-30 min respawn.",
	[187629] = "Purchased from Vilo (Enlightened Quartermaster) in Zereth Mortis.\n\nCost: 5,000 Reservoir Anima. Requires The Enlightened - Exalted.\nZereth Mortis dailies, Patterns Within Patterns weekly, rares/treasures.",
	[187630] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found in the Halondrus boss encounter area in Sepulcher of the First Ones raid. Located by one of the pillar structures in the room where the second phase happens. Schematic doesn't spawn until Halondrus is defeated - kill the boss, then run back to the second phase room to loot. Note: Once the raid resets, the walls separating Halondrus's rooms go back up, blocking access.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189172}} x1 (Crystallized Echo of the First Song)\n{{item:189156}} x1 (Vombata Lattice - drops from vombata mobs)",
	[187631] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside a cage in the Arrangement Index. Reachable from a broken pillar - fly, use Door of Shadows, or glide from above.\n\n{{m:1970,64.1,35.6}} Schematic location (glide from here or Door of Shadows)\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189175}} x1 (Mawforged Bridle - from High Value Cache in Sepulcher raid)\n{{item:189156}} x1 (Vombata Lattice - drops from vombata mobs)",
	[187632] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Get the Grateful Boon treasure (requires flying or Door of Shadows).\n1. Reach the hilltop at 37.1, 78.3 in Zereth Mortis.\n2. Pet all 12 animals: 5x Agitated Vombata, 4x Agitated Cervid, 3x Agitated Lupine.\n3. Two hard-to-reach animals at 37.41, 78.23 (top of sphere) and 36.66, 76.27 (on the wall) - use Door of Shadows.\n4. After petting all, Tah Fen unlocks the Grateful Boon treasure.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) by getting Sopranian Understanding from the Cypher Console, completing The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect -> Schematic Reassimilation: Deathrunner.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189174}} x1 (Lens of Focused Intention)\n{{item:189156}} x1 (Vombata Lattice)\n\n{{m:1970,37.1,78.3}} Grateful Boon treasure",
	[187638] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Awarded as a quest reward from A New Architect, the quest that unlocks the Protoform Synthesis mount system. Note: Only given to the first character on your account to unlock the system.\n\nPrerequisites: Research Sopranian Understanding at the Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189178}} x1 (Tools of Incomprehensible Experimentation - drops from Lihuvim in Sepulcher raid)\n{{item:187635}} x1 (Cervid Lattice - drops from stag mobs)",
	[187639] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Reward for the achievement Cyphers of the First Ones, which requires fully researching all Cypher of the First Ones research. Once completed, check your mailbox for the schematic.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189176}} x1 (Protoform Sentience Crown - drops from Automa/Jiro elites)\n{{item:187635}} x1 (Cervid Lattice - drops from stag mobs)",
	[187640] = "Purchased from Vilo (Enlightened Quartermaster) in Zereth Mortis.\n\nCost: 5,000 Reservoir Anima. Requires The Enlightened - Revered.\nOnly Revered needed - easier than Heartlight Stone.",
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
	[187676] = "Drops from Hirukon (rare in Zereth Mortis) at approximately 4.6% drop rate.\n\nRequires special bait to summon: Aurelid Lure (crafted from fish/materials in Zereth Mortis).\nFish at his pool {{m:1970,52.2,74.6}} to summon him.",
	[187677] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Located by the Genesis Vestibule, atop the structure leading to the Genesis Alcove. Climb from the left side of the building to reach the schematic.\n\n{{m:1970,31.5,50.3}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189171}} x1 (Bauble of Pure Innovation)\n{{item:189152}} x1 (Tarachnid Lattice - drops from spider mobs)",
	[187678] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside a small building in the Arrangement Index. The schematic is to the right as you enter.\n\n{{m:1970,62.8,22.0}} Schematic location\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x450 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189177}} x1 (Revelation Key - drops from Protector of the First Ones)\n{{item:189152}} x1 (Tarachnid Lattice - drops from spider mobs)",
	[187679] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Given by the Shade of Irik-tu, a ghost NPC at the back of Firim's cave in Exile's Hollow. You must die near the cavern and run there as a ghost to see and speak to the spirit.\n\n{{m:1970,34.9,48.7}} Shade of Irik-tu (must be dead/ghost form)\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x500 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189176}} x1 (Protoform Sentience Crown - drops from Automa/Jiro elites)\n{{item:189152}} x1 (Tarachnid Lattice - drops from spider mobs)",
	[187683] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to drop from Accelerated Bufonid mobs in Zereth Mortis. These mobs are found on the Sepulcher of the First Ones island and near Hirukon's pool.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x400 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189171}} x1 (Bauble of Pure Innovation)\n{{item:187633}} x1 (Bufonid Lattice - drops from frog mobs)",
	[188696] = "Achievement reward: 'The Jailer's Gauntlet: Layer 4' in Torghast.\n\nComplete Layer 4 of The Jailer's Gauntlet (special Torghast mode - wave combat without resting).\nModerately challenging. Strong solo classes (tanks, pet classes) have an easier time.\nOne-time achievement - mount is mailed upon completion.",
	[188700] = "Drops from Torghast bosses on Layer 13 or higher.\n\nBest farm: Adamant Vaults wing (~1.4% from bosses vs ~0.2% from other wings).\nRun Layer 13+ repeatedly. Adamant Vaults is a bonus wing after clearing a normal wing.\nUse multiple wings and alts for more attempts.",
	[188736] = "Achievement reward: 'Flawless Master (Layer 16)' in Torghast.\n\nAchieve a Flawless run (5-star, no deaths) on Layer 16 in EVERY wing of Torghast.\nThe hardest Torghast mount. Must be perfect across all wings at highest difficulty.\nPet classes (Hunter, Warlock) and tanks have the easiest time.",
	[188808] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nRequires 450 Genesis Motes + Patient Bufonid schematic + Progenitor Essentia.\nGenesis Motes are gathered from nodes throughout Zereth Mortis.\nCraft at a Protoform Synthesis forge in Zereth Mortis.",
	[188809] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Found inside the Forgotten Proto-Vault, atop a mountain overlooking the Untamed Verdure. Requires flying or the frog from the World Quest Frog'it to reach.\n\n{{m:1970,67.0,69.4}} Forgotten Proto-Vault\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189178}} x1 (Tools of Incomprehensible Experimentation - drops from Lihuvim in Sepulcher raid)\n{{item:187633}} x1 (Bufonid Lattice - drops from frog mobs)",
	[188810] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to loot from {{item:199191}} (Enlightened Broker Supplies), the Paragon reputation cache for The Enlightened.\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x350 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189174}} x1 (Lens of Focused Intention - Revered with The Enlightened)\n{{item:187633}} x1 (Bufonid Lattice - drops from frog mobs)",
	[190580] = "Crafted via Protoform Synthesis in Zereth Mortis.\n\nSchematic: Chance to drop from Maw-Frenzied Lupine mob inside Choral Residium cave.\n\n{{m:1970,51.8,62.7}} Choral Residium cave entrance\n\nPrerequisites: Unlock Protoform Synthesis (Mount) - research Sopranian Understanding at Cypher Console, complete The Final Song questline (starts with Finding Tahli), then The Lost Component -> A New Architect.\n\nCrafting Materials:\n{{item:188957}} x500 (Genesis Mote - drops from mobs in Zereth Mortis)\n{{item:189172}} x1 (Crystallized Echo of the First Song)\n{{item:190388}} x1 (Lupine Lattice - drops from wolf mobs)",
	[190765] = "Drops from Rhuv, Gorger of Ruin (rare in Zereth Mortis) at approximately 25% drop rate.\n\nStandard rare kill {{m:1970,39.4,68.6}}. Highest drop rate among SL rare mount drops.",
	[190766] = "Rare drop from Mawsworn Supply Chests in Zereth Mortis at approximately 0.5% drop rate.\n\nChests spawn in the Mawsworn-occupied areas of Zereth Mortis (southern/eastern regions).\nThey respawn frequently and can be farmed on a loop. Bring alts for daily attempts.\nCheck Antecedent Isle and Mawsworn zones. Persistence is key.",
	[190768] = "Drops from The Jailer (final boss) in Sepulcher of the First Ones on Mythic only.\n\nApproximately 0.6% drop rate. Was 100% during current content tier.\n11-boss raid - use lockout extension/sharing to skip to The Jailer.\nSoloable at current power levels but some mechanics remain tricky. Available on BMAH.",
	[191838] = "Sold by Sacratros in Zaralek Cavern {{m:2133,55.8,55.4}} for 100 Coveted Baubles.\n\nFarm Unearthed Fragrant Coins from Yellow Horn events in Zaralek Cavern, then trade coins for Coveted Baubles at Sacratros.\n\nBest farm method: Researchers Under Fire event (~60 coins for epic chest, ~45 for blue). About 2 event completions needed. Baubles are BoA so you can farm on alts.\n\nYellow Horn event locations:\n{{m:2133,40.2,43.4}} Mortar Warfare\n{{m:2133,35.1,52.1}} Imperfect Balance\n{{m:2133,34.3,48.0}} Seismic Ceremony\n{{m:2133,61.7,72.0}} Monument Maintenance\n{{m:2133,44.7,20.7}} Strike the Colors\n{{m:2133,60.5,53.4}} Smellincense\n{{m:2133,57.7,57.0}} Smelly Scramble\n{{m:2133,58.3,67.5}} Whirling Zephyr",
	[192601] = "Requires True Friend reputation with both Wrathion and Sabellian at the Obsidian Citadel in The Waking Shores.\n\n1. Reach max reputation with both factions via daily/weekly quests at the Obsidian Citadel.\n2. Buy {{item:201839}} (800g) from Samia Inkling {{m:2022,24.7,56.8}} or Xaldrass {{m:2022,27.7,56.2}}.\n3. Buy {{item:201840}} (800g) from Lorena Belle {{m:2022,25.2,55.8}} or Atticus Belle {{m:2022,26.5,62.4}}.\n4. Trade both items to Yries Lightfingers {{m:2022,26.4,55.5}} for {{item:201837}}.\n5. Fly to a Tame Magmammoth at Burning Ascent {{m:2022,33.4,72.1}} - kill the Qalashi Necksnapper next to it first.\n6. Mount the Tame Magmammoth and use the {{item:201837}} from your bags.\n\nIf the mount prompt doesn't appear, try /reload or relog. The Burning Ascent mammoth is the most reliable location.",
	[192764] = "It has a small chance to drop from Expedition Scout's Pack after reaching the Renown requirement.",
	[192772] = "Drops from any of the 16 rares in The Forbidden Reach at approximately 1% drop rate.\n\nTips:\n- First kill of each rare per day has the best drop chance. Kill all 16 rares once per day.\n- Use Essence of Divination (from Storykeeper Ashekh at Morqut Village) to see rares on your map 90 seconds before they spawn.\n- Using multiple alts dramatically improves efficiency - some players report getting the mount in 10-34 alt attempts.\n- Rares die very fast at current ilvl, so arrive early.\n- Mount is tradeable to anyone who tagged the same rare kill.",
	[192775] = "Sold by Mythressa in Valdrakken for 2,000 Elemental Overflow.\n\nFarm Elemental Overflow from Primal Invasions (Elemental Storms) across the Dragon Isles. These rotating events appear in all four original Dragon Isles zones.\n\nTips:\n- Use Group Finder to join raid groups during active invasions for faster farming.\n- Brackenhide Hollow area in Azure Span is excellent for farming during invasions - tons of densely packed mobs.\n- Killing rares and looting during invasions yields the most overflow.\n- Easily farmable in 1-2 hours during an active invasion event.",
	[192777] = "Step 1: Farm {{item:201883}} from Lavaslurper, Lava Slug, or Lava Snail mobs near the lava river in western Waking Shores {{m:2022,22.6,71.6}}. Not soulbound - can be bought from the AH or mailed to alts.\nStep 2: Go to the lava pool at Scalecracker Keep {{m:2022,71,25}}. Use /tar Empowered Snail to locate it at the bottom of the pool (it has a ~25 min respawn timer).\nStep 3: Dive into the lava and interact with the Empowered Snail. The channel takes ~20 seconds. You will need lava protection:\n- Hunters: Aspect of the Turtle (grants immunity even after it expires)\n- Rogues: Cloak of Shadows (full immunity while in lava)\n- DKs: Anti-Magic Shell (immunity persists after buff expires)\n- Paladins: Divine Shield + Shield of Vengeance\n- Any class: Use {{item:200116}} (Everlasting Horn of Lavaswimming) for full immunity\n\nTip: Lava damage is %%-based, so gear shields are extra effective if you remove your gear first.",
	[192779] = "Obtained by clicking 3 Seething Orbs around the Zaqali Caldera in Zaralek Cavern, then looting the Seething Cache that spawns.\n\nStep 1: Fly around the Zaqali Caldera area checking known orb spawn points. Each click gives a stack of Insidious Insight (persists through death, but lost on logout/DC).\nStep 2: After clicking all 3 orbs, a zone message announces the Seething Cache. Fly to it and loot the mount.\n\nTips:\n- Use a normal flying mount (not Dragonriding) to avoid the anti-flying stacks from the Djaradin.\n- Die and search as a ghost to avoid being dismounted. Use /console ffxDeath 0 to see colors while dead.\n- Try War Mode and/or off-peak hours for less competition. Orbs are first-come first-serve per shard.\n- The cache is also first-come first-serve. If someone else loots it, your stacks reset.\n- You can realm hop via group finder to find fresh orb spawns.\n\nOrb locations (use TomTom):\n/way #2133 28.75 55.30\n/way #2133 29.95 47.97\n/way #2133 34.41 45.71\n/way #2133 36.20 44.01\n/way #2133 31.18 51.95\n/way #2133 30.20 40.00\n/way #2133 27.70 49.00\n/way #2133 26.70 47.00\n/way #2133 27.90 51.00\n/way #2133 25.24 44.80\n/way #2133 29.15 42.50\n/way #2133 35.63 48.77\n/way #2133 37.59 46.72\n/way #2133 32.73 52.23\n/way #2133 35.80 41.39\n\nSeething Cache: {{m:2133,32.3,39.3}}",
	[192785] = "Collect 50x Leftover Elemental Slime by killing the Froststone Vault Primal Storm event boss in The Forbidden Reach.\n\nEvent spawns every 2 hours (odd hours US, even hours EU). Kill 5 trash elementals to activate the boss. Each kill awards 0-5 slime (average 2-4).\n\nTips:\n- No daily lockout - server-hop via custom groups to get 2-3 kills per spawn window.\n- The boss dies extremely fast at high ilvl - be present before the event starts.\n- Leave boss-platform elementals for last so everyone can tag the boss.\n- Expect ~15-25 event completions to collect all 50 slime.",
	[192786] = "Costs 1000x {{item:202173}} from Dealer Vexil in the Obsidian Citadel. Requires the Worldbreaker buff to interact with the vendor.\n\nStep 1 - Unlock Igys the Believer:\nComplete The Shadow of His Wings questline (part of Sojourner of the Waking Shores). This unlocks Igys the Believer {{m:13644,32.2,52.4}}\n\nStep 2 - Get a Worldbreaker Membership:\nFarm {{item:199202}} and {{item:199203}} from mobs in and around the Obsidian Citadel. Combine fragments into keys, then turn keys in to Igys. Open the caches he gives you for a chance at {{item:199215}} (~33%% drop rate). Use it to gain the Worldbreaker title and buff.\n\nStep 3 - Farm 1000 Magmotes:\nKill mobs in and around the Obsidian Citadel. The Vault basement area has fast respawns and is the best spot. Takes ~1-2 hours. Save your keys for Wrathion/Sabellian rep instead of opening caches for magmotes.\n\nIf you die you lose the Worldbreaker buff. You can buy a backup {{item:199215}} from Dealer Vexil for 20x {{item:202173}} once you have the title.",
	[192790] = "Crafted from items found inside the Zskera Vaults in The Forbidden Reach through a 5-step combining chain:\n\n1. Strange Petrified Orb + Scrap of Black Dragonscales = Particularly Ordinary Egg\n2. Particularly Ordinary Egg + Drop of Blue Dragon Magic = Magically Altered Egg\n3. Magically Altered Egg + Everburning Ruby Coals = Egg of Unknown Contents\n4. Egg of Unknown Contents + Speck of Bronze Dust = Sleeping Ancient Mammoth\n5. Sleeping Ancient Mammoth + Emerald Dragon Brooch = Mossy Mammoth\n\nAll reagents are found in chests inside the Zskera Vaults. You must complete each named vault week (Az, Ur, Ix, Kx) to progress. The final reagents appear in the unnamed vaults after completing all 4 named weeks.\n\nMinimum 5 weeks originally, but vault progression may be faster now. Items combine automatically when both reagents are in your bags.",
	[192791] = "Plainswalker Bearer Plainswalker Bearer drops from Grand Hunt Spoils Grand Hunt Spoils, and ONLY the epic version, which is rewarded for the first weekly completion of a Grand Hunt event.\n\nGrand Hunt Events are unlocked at renown 5 with Maruuk Centaur, the major faction of Ohn'ahran Plains.",
	[192799] = "To unlock the quests you'll need\nRenown 9 with Maruuk Centaur\nComplete Initiate's Day out from the achievement Sojourner of Ohn'ahran Plains\n\nInitiate's Day out from Sojourner of Ohn'ahran Plains starts from Initiate Radiya at 56.12 77.01 in Ohn'iri Springs in Ohn'ahran Plains\n\nOnce unlocked the quests can be picked can be picked up from Initiate Radiya\nOnce a quest is completed you'll have to wait for the daily reset to get the next quest in the chain.",
	[192800] = "Sold by Brendormi in the Primalist Future for 150 Essence of the Storm + 3,000 Elemental Overflow.\n\nEssence of the Storm is earned from the Storm's Fury event:\n- 6 Essence from killing the final boss\n- 3 Essence from the mission chest\n- Event is repeatable - join other realm groups via LFG for extra completions\n\nThe event involves closing 4 portals then killing an elemental boss. Boss rotates between Earth, Storm, and Winter variants. Events spawn approximately every 5 hours, lasting about 30 min to complete with a group.",
	[192807] = "Collect 20x Charred Elemental Remains from Waking Dream portals in the Emerald Dream, then use them to create the mount.\n\nKill Waking Dream minor portals (4-5 waves of mobs, then an elite). Easily soloable.\n\nWaking Dream spawn points:\n{{m:2200,37.8,73.4}}\n{{m:2200,38.6,91.0}}\n{{m:2200,47.6,44.4}}\n{{m:2200,48.2,52.8}}\n{{m:2200,50.8,36.0}}\n{{m:2200,52.2,61.0}}\n{{m:2200,53.8,80.2}}\n{{m:2200,54.6,23.6}}\n{{m:2200,62.2,37.8}}\n{{m:2200,76.4,46.4}}\n\nNote: After learning, the mount may not appear in your journal. Use /cast Renewed Magmammoth to summon it as a workaround.",
	[194034] = "Reward from The Waking Shores main storyline Waking Hope.",
	[194521] = "Reward from Thaldraszus main storyline Just Don't Ask Me to Spell It",
	[194549] = "Reward from Ohn'ahran Plains main storyline Ohn'a'Roll",
	[194705] = "Reward from The Azure Span main storyline Azure Spanner.",
	[198808] = "Requires to Dracthyr race to interact with vendor.",
	[198809] = "Requires to Dracthyr race to interact with vendor.",
	[198810] = "Requires to Dracthyr race to interact with vendor.",
	[198811] = "Requires to Dracthyr race to interact with vendor.",
	[198824] = "Sold by Celestine of the Harvest for 1,000 Dreamsurge Coalescence.\n\nDreamsurge Coalescence is earned from Dreamsurge events that rotate through the four original Dragon Isles zones. The vendor moves to whichever zone has the active Dreamsurge.\n\nFarming methods:\n- Collect green orbs scattered across the active Dreamsurge zone (~330 in 18 min by flying around)\n- Kill rares during Dreamsurge events\n- Complete world quests (~20 each)\n\nBug note: Mount may not appear in journal after learning. Use /use Duskwing Ohuna to summon it as a workaround.",
	[198870] = "Fishing quest chain. Buy a {{item:199340}} from The Great Swog (costs 75 Copper Coins total: 15 per Silver Coin, 5 Silver per Gold). Use the Gold Coin to buy {{item:202102}} — repeat until you get {{item:202042}}.\n\nEquip the shades and go underwater at {{m:2022,19.1,36.6}}. Talk to the NPC, then /dance on the dance floor for ~5 minutes. Pick up the {{item:202061}}.\n\nFill the barrel in order:\n1. Catch 100x {{item:202072}} near Iskaara {{m:2024,13.7,48.5}}\n2. Catch 25x {{item:202073}} from lava rivers east of Obsidian Citadel in Waking Shores\n3. Catch 1x {{item:202074}} near Algethar Academy in Thaldraszus\n\nReturn the full barrel to where you found it to summon Otto and complete the quest.",
	[198871] = "Sold by Tattukiaka in Iskaara, The Azure Span {{m:2024,14.0,49.6}} for 2 raid necklaces.\n\nRequired necklaces (~26% drop rate each):\n- {{item:195502}} from Terros (2nd boss, Vault of the Incarnates)\n- {{item:195496}} from Dathea, Ascended (5th boss, Vault of the Incarnates)\n\nAny difficulty works. Mythic guarantees 4 loot drops per boss regardless of group size. Soloable at 640+ ilvl on Mythic (use a class with self-heal). For Dathea Mythic, stand in front of a stationary tornado during her knockback to avoid falling off.\n\nWARNING: Same vendor ring-taking rules apply - the vendor takes necklaces from your bags/bank. Sell duplicates you want to keep before purchasing.",
	[198873] = "Sold by Tattukiaka in Iskaara, The Azure Span {{m:2024,14.0,49.6}} for 3 dungeon rings.\n\nRequired rings (~26% drop rate each):\n- {{item:193696}} from The Raging Tempest (2nd boss, The Nokhud Offensive)\n- {{item:193633}} from Leymor (1st boss, The Azure Vault)\n- {{item:193708}} from Vexamus (Algeth'ar Academy)\n\nAny difficulty works. Rings can come from the Great Vault. Follower Dungeons are an efficient way to farm. Soloable on Mythic at high ilvl for 4 guaranteed drops per boss.\n\nWARNING: The vendor takes rings from your bags (including bank). To protect high-ilvl duplicates, sell the ones you want to KEEP to the vendor first, buy the mount, then buy back the kept rings from the Buyback tab.",
	[201454] = "Feed 3 types of gnoll food (20 each) to Zon'Wogi at Three-Falls Lookout in The Azure Span {{m:2024,19.1,24.0}}.\n\nRequired items:\n- 20x {{item:201422}} - drops from Snowhide Gnolls {{m:2024,57.9,43.3}}\n- 20x {{item:201421}} - drops from Darktooth gnolls {{m:2024,33.6,47.5}}\n- 20x {{item:201420}} - drops from gnolls INSIDE the big tree inn at Brackenhide Waterhole {{m:2024,22.8,43.6}}\n\nAll items can also be bought on the Auction House. Drop rates are low (~15-30%), expect 30-60 min of farming per type.\n\nTalk to Zon'Wogi and select 'Ask about the saddled slyvern' - you must have all 60 items in your bags. Do NOT right-click the food items or you will eat them!",
	[201702] = "Requires to Dracthyr race to interact with vendor.",
	[201704] = "Requires to Dracthyr race to interact with vendor.",
	[201719] = "Requires to Dracthyr race to interact with vendor.",
	[201720] = "Requires to Dracthyr race to interact with vendor.",
	[204091] = "Current reward for Recruit a Friend, subject to be retired.",
	[204361] = "Zaralek Cavern Campaign.",
	[204382] = "Sold by Storykeeper Ashekh in The Forbidden Reach for 100,000 Elemental Overflow.\n\nFarm overflow by:\n- Killing rares (500-1,100 overflow each, ~30 rares in the zone)\n- Looting chests in the Zskera Vaults\n- Completing quests and world events\n- Farming the War Creche (full clear + reset loop)\n\nEasily achievable in 3-5 days of casual play. Rares are farmable daily on each alt. Ground mount only.",
	[205197] = "Sold by Sacratros in Zaralek Cavern {{m:2133,55.8,55.4}} for 400 Coveted Baubles.\n\nSame farm as the Subterranean Magmammoth but requires 4x as many baubles. Farm Unearthed Fragrant Coins from Yellow Horn caldera events and Researchers Under Fire, then exchange coins for baubles at Sacratros.\n\nResearchers Under Fire is the fastest method (~60 coins for epic chest). Baubles are BoA so farm on multiple alts to speed things up. Expect roughly 8 event completions to gather enough.",
	[205203] = "Drops from rare elite Karokta in Zaralek Cavern {{m:2133,42.6,65.7}} at approximately 0.8% drop rate.\n\nKarokta spawns on a zone rotation - available 3 out of every 4 days. Respawns approximately every 60-90 minutes when the area is active.\n\nTips:\n- Use alts to maximize attempts per cycle - each character gets one loot chance per spawn cycle.\n- No renown requirement - drops at Loamm Niffen renown 1.\n- Can drop for characters as low as level 10.\n- Join custom groups in LFG for 'Karokta' to find active shards.\n- Mount is NOT tradeable.",
	[205204] = "Drops from the Researchers Under Fire public event in Zaralek Cavern. The event runs every hour at the half-hour mark.\n\nHow it works:\n1. Join the Researchers Under Fire event when it begins. Group up via the Group Finder for best results.\n2. Complete as many of the 12 objectives as possible before defeating the final boss.\n3. Rewards scale with objectives completed: green bag (low), blue bag (mid), purple bag (12/12).\n4. The mount can drop from ANY quality bag, including the green (Appreciative) bag.\n\nTips:\n- The first bag of the week (per character) may have a higher drop rate than subsequent bags.\n- You can farm the event repeatedly on the same character - the purple repeatable bag (Indebted Researcher's Scrounged Goods) also drops the mount.\n- Multiple copies of the mount can drop from a single bag.\n- Can be obtained just by flying through the event area when rewards are distributed.\n- In current content, finding enough players may be challenging. Try looking for groups in the Group Finder before the event starts.",
	[206566] = "By reaching level 30 and visiting Boralus (Alliance) or Dazar'alor (Horde), a quest will be automatically received to learn a new flying mount, either Harbor Gryphon Harbor Gryphon (Alliance) or Reins of the Scarlet Pterrordax Reins of the Scarlet Pterrordax (Horde).",
	[206567] = "By reaching level 30 and visiting Boralus (Alliance) or Dazar'alor (Horde), a quest will be automatically received to learn a new flying mount, either Harbor Gryphon Harbor Gryphon (Alliance) or Reins of the Scarlet Pterrordax Reins of the Scarlet Pterrordax (Horde).",
	[209947] = "Purchasable from Sylvia Whisperbloom {{m:2200,49.8,62.0}} for 1 Seedbloom (requires Dream Wardens Renown 18). Also drops from Emerald Bounty caches (Gigantic Dreamseeds).\n\nSame Dreamseed farming method as the other Emerald Dream mounts. If it appears greyed out in your mount journal after learning, use /reload to fix it. Ground mount.",
	[209950] = "Purchasable from Talisa Whisperbloom {{m:2200,49.8,62.0}} for 1 Seedbloom (requires Dream Wardens Renown 18). Also drops from Emerald Bounty caches - confirmed from both Gigantic and Plump Dreamseeds.\n\nPlump seeds have a lower chance but are cheaper to plant. Gigantic seeds remain the best source. Drop rate can be frustrating (some report 10-50+ attempts). Duplicates are possible. Ground mount.",
	[210022] = "Secrets of Azeroth mount. Collect 3 Booster Parts and combine them at the Arcane Forge in Valdrakken.\n\nPart 1 - {{item:208984}}:\nRequires 3 players each using {{item:208092}} at the braziers on Jaguero Isle {{m:210,59.0,78.0}}. Kills the Enigma Ward rare — loot the part. Can be soloed with alts: open multiple WoW instances, position alts at the braziers with torches active, then quickly swap between them (disable addons for faster loading).\n\nPart 2 - {{item:209781}}:\nFelwood {{m:77,50.0,26.3}} — just click and loot, no group needed.\n\nPart 3 - {{item:209055}}:\nBlasted Lands, on the Dark Portal ramp {{m:17,54.8,52.1}}. Destroy the 2 cannons first, then loot. Use Zidormi to switch to the pre-invasion timeline to avoid constant mob aggro. Can also hover on a flying mount to loot safely.\n\nCombine: Use any of the 3 parts at the Empowered Arcane Forge in Valdrakken {{m:2134,36.4,62.2}} (next to Artisan's Market). The forge is permanently empowered — no event needed.",
	[210057] = "Purchasable from Talisa Whisperbloom {{m:2200,49.8,62.0}} for 1 Seedbloom (requires Dream Wardens Renown 18). Also drops from Emerald Bounty caches (Gigantic Dreamseeds).\n\nStrategy: Farm Small Dreamseeds to harvest Dewdrops, then invest Dewdrops into Gigantic seeds for mount chances. Drop rate is RNG - some get it in 1-2 seeds, others take 15+. Ground mount only.",
	[210058] = "Purchasable from Talisa Whisperbloom {{m:2200,49.8,62.0}} for 1 Seedbloom (requires Dream Wardens Renown 18). Also drops from Emerald Bounty caches (Gigantic Dreamseeds).\n\nPlant Gigantic Dreamseeds at soil nodes in the Emerald Dream, nurture to 100%, and loot the bounty for a chance. Alternatively, contribute Dewdrops to other players' Gigantic seeds for a loot chance. Duplicates can drop. Ground mount.",
	[210059] = "Drops from Dreamseed Caches in the Emerald Dream. Can drop from any quality seed (Small, Medium, Large, or Gigantic Dreamseed), though higher quality seeds may have better odds.\n\nHow to farm:\n1. Collect Emerald Dewdrops from Superbloom, Emerald Frenzy, or Emerald Bounty events.\n2. Plant a Dreamseed at any soil mound in the Emerald Dream and contribute Dewdrops to grow it.\n3. Once the seed blooms, loot the Dreamseed Cache for a chance at the mount.\n\nTips:\n- Farmable with no daily lockout - you can open as many caches as you have seeds and dewdrops for.\n- Contributing even 1 dewdrop to someone else's seed can award the mount.\n- The mount is not soulbound on drop initially, so duplicates can appear.\n- Use the Plumber addon for seed locations, timers, and auto-click contribution.\n- Expect roughly 50-300+ attempts based on community reports.",
	[210412] = "Emerald Dream Campaign",
	[210769] = "Purchasable from Talisa Whisperbloom {{m:2200,49.8,62.0}} for 1 Seedbloom (requires Dream Wardens Renown 18). Also drops from Emerald Bounty caches (Gigantic Dreamseeds).\n\nSame farming method as all Dreamseed mounts - plant Gigantic Dreamseeds and nurture to 100%. Can drop from both self-planted and other players' seeds. Drop rate is moderate - players report getting it anywhere from 1 to 25+ attempts.",
	[210774] = "23-day quest chain in the Emerald Dream. Requires completing Chapter 5 of the Emerald Dream storyline. Must dismount before interacting with the sprout.\n\nStart: Interact with the Smoldering Sprout {{m:2200,48.68,67.90}}\n\n1. Some Water - Get a water bucket from Professor Ash, fill it at {{m:2200,51.11,65.70}}, return to sprout. Wait 5 days.\n2. A Dash of Minerals - Kill Fathomless Lurkers near {{m:2200,51.0,31.0}} for 5x {{item:210457}}. Wait 5 days.\n3. The Right Food - Collect 5x {{item:4537}} from vendor, 3x {{item:209416}} from turtle eggs near {{m:2200,41.15,75.97}}, 5x {{item:208644}} from lashers near {{m:2200,56.46,55.18}}. Click the {{item:208644}} to combine (NOT the bananas). Wait 3 days for fertilizer to compost, then log out/in before using. Apply to sprout, wait 5 days.\n4. And a Pinch of Magic - Collect items near {{m:2200,63.0,52.0}}. Wait 5 days.\n5. A Little Hope is Never Without Worth - Turn in at sprout for mount.\n\nTimers are real-time (not tied to weekly reset). Total ~23 days.",
	[210775] = "Purchasable from Talisa Whisperbloom {{m:2200,49.8,62.0}} for 1 Seedbloom (requires Dream Wardens Renown 18). Also drops from Emerald Bounty caches (Gigantic Dreamseeds).\n\nTo farm from seeds: Plant a Gigantic Dreamseed at soil nodes throughout Emerald Dream. Nurture to 100% for the best drop chance, then loot the Emerald Bounty.\n\nFarm Small Dreamseeds to harvest Dewdrops, then use Dewdrops to fund Gigantic seeds for mount chances. Drop rate is RNG - some get it on the first seed, others take 25+ attempts. Duplicates are possible from seeds.",
	[212645] = "Drops from The Big Dig event (Azerothian Archives) at Traitor's Rest in Ohn'ahran Plains.\n\nCan drop from:\n- Doomshadow (the elite end-boss dragon)\n- Any quality Tome earned during the event (green, blue, or epic)\n- Meticulous Archivist's Appendix\n\nNo lockout - the event can be farmed endlessly on the same character. No reputation requirement. Drop rate is roughly 0.7% but many players report getting it within 3-5 runs. If you miss looting, The Postmaster can mail it to you.",
	[222988] = "Nice guide written up on Wowhead for this. Too long to fit in MCL.",
	[223269] = "Complete all 20 waves of the Awakened Machinist weekly event in The Ringing Deeps. The mount has a chance to drop from the Awakened Cache chests that spawn after wave 20. \n\n{{m:2214,66.5,61.9}} Awakened Machinist event",
	[223270] = "Kill any mob on the Isle of Dorn for a low chance to loot Crackling Shard (collect 10). Combine them into a Storm Vessel, then use it on Alunira to make her attackable. \nKill and loot for the mount.",
	[223315] = "Rare Elite in Hallowfall that spawns when Beledar's Shadow begins (~5% mount drop). Daily loot per character, can drop at level 70. Part of the Adventurer of Hallowfall achievement.",
	[223318] = "Chance to drop from {{item:228741}} (Lamplighter Supply Satchel), earned by completing Spreading the Light objectives in Hallowfall. Do all main fires plus side quests from giving 3/3 crystals to small fires. \n\n{{m:2215}} Hallowfall - Spreading the Light",
	[223501] = "Activate all five levers simultaneously.\nCoordinates: 49.2/8.8, 53.91/25.28, 57.62/23.57, 62.83/44.64, 59.08/92.40.\nChat message confirms activation.\nRare spawns in western zone at (61.02, 76.79) after a delay. \nKill and loot for mount.",
	[223572] = "Reward for unlocking the Earthen allied race. Requires completing The War Within campaign through the Earthen storyline, then completing the Earthen recruitment questline.",
	[229941] = "The best way to farm Miscellaneous Mechanica Miscellaneous Mechanica seems to be continuous kills of any of the Cartel-specific Rares (e.g. Voltstrike the Charged, Scrapchewer, M.A.G.N.O., Giovante)",
	[229949] = "While you're  Shoveling Trash during S.C.R.A.P. jobs in Undermine (requires Renown 2 with The Cartels of Undermine) you keep looting Empty Kaja'Cola Can Empty Kaja'Cola Can. You can exchange 333 of them (or later at Renown 14 one Vintage Kaja'Cola Can Vintage Kaja'Cola Can) for one of these Sifted Pile of Scrap Sifted Pile of Scrap containers at S.C.R.A.P.",
	[229952] = "The best way to farm Miscellaneous Mechanica Miscellaneous Mechanica seems to be continuous kills of any of the Cartel-specific Rares (e.g. Voltstrike the Charged, Scrapchewer, M.A.G.N.O., Giovante)",
	[229954] = "The best way to farm Miscellaneous Mechanica Miscellaneous Mechanica seems to be continuous kills of any of the Cartel-specific Rares (e.g. Voltstrike the Charged, Scrapchewer, M.A.G.N.O., Giovante)",
	[232639] = "Located in the Forgotten Vault. Requires an active storm event (Special Assignment active/completed for the week).\n\nThrayir is surrounded by 5 Runestones. Bring the matching Runekey to each:\n\n{{item:232571}} - Guaranteed drop from Ksvir the Forgotten in the southern room of the Forgotten Vault during a storm.\n\n{{item:232572}} - Combine 7 {{item:234328}}. Drops from any mob on the island during a storm.\n\n{{item:232573}} - Combine 5 {{item:232605}}. Found in treasure chests inside the storm and underwater chests outside. Farm Seafarer's Caches (requires quest Dipping a Toe).\n\n{{item:232569}} - Drops from Zek'ul the Shipbreaker in Deadfin Mire during a storm. Can also be fished up nearby.\n\n{{item:232570}} - Combine 3 {{item:234327}} found around the island during a storm:\n1. Garden of the abandoned inn (center-west) - pile of dirt\n2. Rotting Hole cave (southeast) - small yellow crystal\n3. Spirit-Scarred Cave - held by a ghost\n\n{{m:2369,38.19,51.78}} Garden Fragment\n{{m:2369,67.08,78.44}} Rotting Hole Fragment\n{{m:2369,52.39,38.59}} Spirit-Scarred Fragment\n{{m:2369,44.04,23.13}} Forgotten Vault entrance\n\nUse all five keys, then talk to Thrayir.",
	[235515] = "Reward from the A Farewell to Arms achievement. This is the BFA expansion meta-achievement requiring completion of a large number of BFA content achievements.",
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
	["m2912"] = "Reward from the Treasures of Harandar achievement. Discover all hidden treasures scattered across Harandar in the Midnight expansion.",
}
