--------------------------------------------------------
-- Namespaces
--------------------------------------------------------
local _, core = ...;

core.sectionNames = {}
core.mountList = {}

core.mountList[1] = {
	name = "SL",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {186654, 186637, 184183, 182596, 186653, 184166, 186655, 187673, "m1549", "m1576"},
			mountID = {"m15491", "m1549", "m1576"}
		},
		Vendor = {
			name = "Vendor",
			mounts = {180748},
			mountID = {}
		},
		Treasures = {
			name = "Treasures",
			mounts = {180731, 180772, 190766},
			mountID = {}
		},
		Adventures = {
			name = "Adventures",
			mounts = {183052, 183617, 183615, 183618},
			mountID = {}
		},
		Riddles = {
			name = "Riddles",
			mounts = {184168,186713},
			mountID = {}
		},
		Tormentors = {
			name = "Tormentors",
			mounts = {185973},
			mountID = {}
		},
		MawAssaults = {
			name = "Maw Assaults",
			mounts = {185996, 186000, 186103},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {180729, 182082, 183518, 183740, 186647, 186648, 187629, 187640},
			mountID = {}
		},
		ParagonReputation = {
			name = "Paragon Reputation",
			mounts = {182081, 183800, 186649, 186644, 186657, 186641},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {181819, 186638, "m1445"},
			mountID = {1445}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {186656, 186642, 190768},
			mountID = {}
		},
		Zone = {
			name = "Zone",
			mounts = {181818},
			mountID = {}
		},
		DailyActivities = {
			name = "Daily Activities",
			mounts = {182614, 182589, 186643, 186651, 186646, 188808},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {180728, 180727, 180725, 182650, 180773, 182085, 184062, 182084, 182079, 180582, 183741, 184167, 187183, 186652 ,186645, 186659, 187676, 190765},
			mountID = {}
		},
		OozingNecrorayEgg = {
			name = "Oozing Necroray Egg",
			mounts = {184160, 184161, 184162},
			mountID = {}
		},
		CovenantFeature = {
			name = "Covenant Feature",
			mounts = {180726, 181316, 181300, 181317},
			mountID = {}
		},
		NightFae = {
			name = "Night Fae",
			mounts = {180263, 180721, 183053, 180722, 180413, 180415, 180414, 180723, 183801, 180724, 180730, 186493, 186494, 186495, 186492},
			mountID = {}
		},
		Kyrian = {
			name = "Kyrian",
			mounts = {180761, 180762, 180763, 180764, 180765, 180766, 180767, 180768, 186482, 186485, 186480, 186483},
			mountID = {}
		},
		Necrolords = {
			name = "Necrolords",
			mounts = {182078, 182077, 181822, 182076, 182075, 181821, 181815, 182074, 181820, 182080, 186487, 186488, 186490, 186489},
			mountID = {}
		},
		Venthyr = {
			name = "Venthyr",
			mounts = {182954, 180581, 180948, 183715, 180945, 182209, 182332, 183798, 180461, 186476, 186478, 186477, 186479},
			mountID = {}				
		},
		ProtoformSynthesis = {
			name = "Protoform Synthesis",
			mounts = {187632, 187670, 187663, 187665, 187630, 187631, 187638, 187664, 187677, 187683, 190580, 187679, 187667, 187639, 188809, 187668, 188810, 187672, 187669, 187641, 187678, 187671, 187660, 187666},
			mountID = {}
		},
		Torghast = {
			name = "Torghast",
			mounts = {188700, 188696, 188736},
			mountID = {}
		}
	}
}
core.mountList[2] = {
	name = "BFA",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {168056, 168055, 169162, 163577, 169194, 168329, 161215, 163216, 166539, 167171, 174861, 174654},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {163183, 166442, 166443, 163589, 169203, 169202, 174770},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {159146, 168827, 168408, 169199, 174859, 174771, 169200, 170069},
			mountID = {}
		},
		Medals = {
			name = "Medals",
			mounts = {166464, 166436, 166469, 166465, 166463},
			mountID = {}
		},
		AlliedRaces = {
			name = "Allied Races",
			mounts = {155662, 156487, 161330, 157870, 174066, 156486, 155656, 161331, 164762, 174067},
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
		Zone = {
			name = "Zone",
			mounts = {163576, 163574, 163575, 163573},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {161479, 166433, 169201, 168370, 168823, 169163, 174860},
			mountID = {}
		},
		WorldBoss = {
			name = "World Boss",
			mounts = {174842},
			mountID = {}
		},
		WarfrontArathi = {
			name = "Warfront: Arathi",
			mounts = {163579, 163578, 163644, 163645, 163706, 163646},
			mountID = {}
		},
		WarfrontDarkshore = {
			name = "Warfront: Darkshore",
			mounts = {166438, 166434, 166435, 166432},
			mountID = {}
		},
		AssaultVale = {
			name = "Assault: Vale of Eternal Blossoms",
			mounts = {173887, 174752, 174841, 174840, 174649},
			mountID = {}
		},
		AssaultUldum = {
			name = "Assault: Uldum",
			mounts = {174769, 174641, 174753},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {159921, 160829, 159842, 168826, 168830},
			mountID = {}
		},	
		RaidDrop = {
			name = "Raid Drop",
			mounts = {166518, 166705, 174872},
			mountID = {}
		},	
		IslandExpedition = {
			name = "Island Expedition",
			mounts = {163584, 163585, 163583, 163586, 163582, 166470, 166468, 166467, 166466},
			mountID = {}
		},	
		Dubloons = {
			name = "Dubloons",
			mounts = {166471, 166745},
			mountID = {}
		},
		Visions = {
			name = "Visions",
			mounts = {174653},
			mountID = {}
		},
		ParagonReputation = {
			name = "Paragon Reputation",
			mounts = {169198},
			mountID = {}
		}
	}
}
core.mountList[3] = {
	name = "LEGION",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {141216, 138387, 141217, 143864, 152815, 153041, 129280},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {138811, 141713, 137570},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {137573, 142436, 137577, 137578, 137579, 137580},
			mountID = {}
		},
		Riddle = {
			name = "Riddle",
			mounts = {138201, 147835, 151623},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {138258, 152814, 152844, 152842, 152840, 152841, 152843, 152904, 152905, 152903, 152790},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {142236, 142552},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {137574, 143643, 152816, 137575, 152789},
			mountID = {}
		},
		Class = {
			name = "Class",
			mounts = {142231, 143502, 143503, 143505, 143504, 143493, 143492, 143490, 143491, 142225, 142232, 143489, 142227, 142228, 142226, 142233, 143637, "m868", "m860", "m861", "m898"},
			mountID = {868, 860, 861, 898}
		},
		ParagonReputation = {
			name = "Paragon Reputation",
			mounts = {147806, 147804, 147807, 147805, 143764, 153042, 153044, 153043},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {152788, 152797, 152793, 152795, 152794, 152796, 152791},
			mountID = {}
		}
	}																										
}
core.mountList[4] = {
	name = "WOD",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {116670, 116383, 127140, 128706},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {116664, 116785, 116776, 116775, 116772, 116672, 116768, 116671, 128480, 128526, 123974, 116667, 116655},
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
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {116674, 116659, 116661, 116792, 116767, 116773, 116794, 121815, 116780, 116669, 116658},
			mountID = {}
		},
		WorldBoss = {
			name = "World Boss",
			mounts = {116771},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {116660, 123890},
			mountID = {}
		},
		FishingShack = {
			name = "Fishing Shack",
			mounts = {87791},
			mountID = {}
		}		
	}		
}
core.mountList[5] = {
	name = "MOP",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {87769, 87773, 81559, 93662, 104208, 89785},
			mountID = {}
		},
		GoldenLotus = {
			name = "Golden Lotus",
			mounts = {87781, 87782, 87783},
			mountID = {}
		},
		CloudSerpent = {
			name = "Order of the Cloud Serpent",
			mounts = {85430, 85429, 79802},
			mountID = {}
		},
		ShadoPan = {
			name = "Shado-Pan",
			mounts = {89305, 89306, 89307},
			mountID = {}
		},
		KunLai = {
			name = "Kun-Lai Vendor",
			mounts = {87788, 87789, 84101},
			mountID = {}
		},
		TheTillers = {
			name = "The Tillers",
			mounts = {89362, 89390, 89391},
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
			mounts = {90655, 94229, 94230, 94231, 104269},
			mountID = {}
		},
		WorldBoss = {
			name = "World Boss",
			mounts = {94228, 87771, 89783, 95057},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {93169, 95565, 81354, 89304, 85262, 89363, 87774, 93168, 95564},
			mountID = {}
		}
	}																																
}
core.mountList[6] = {
	name = "CATA",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {62900, 62901, 69213, 69230, 77068},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {54465},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {65356, 64999, 63044, 63045, 64998},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {69747, 63040, 63043, 68823, 68824},
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
		}		
	}										
}
core.mountList[7] = {
	name = "WOTLK",
	categories = {
		Achievement = {
			name = "Achievement",
			mounts = {44160, 45801, 45802, 51954, 51955},
			mountID = {}
		},
		Quest = {
			name = "Quest",
			mounts = {43962, 52200},
			mountID = {}
		},
		Vendor = {
			name = "Vendor",
			mounts = {44690, 44231, 44234, 44226, 44689, 44230, 44235, 44225},
			mountID = {}
		},
		ArgentTournament = {
			name = "Argent Tournament",
			mounts = {46814, 45592, 45593, 45595, 45596, 45597, 46743, 46746, 46749, 46750, 46751, 46816, 47180, 45725, 45125, 45586, 45589, 45590, 45591, 46744, 46745, 46747, 46748, 46752, 46815, 46813},
			mountID = {}
		},
		Reputation = {
			name = "Reputation",
			mounts = {44080, 44086, 43955, 44707, 43958, 43961},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {43951, 44151},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {43952, 43953, 43954, 43986, 49636, 43959, 45693, 50818, 44083},
			mountID = {}
		},
		RareSpawn = {
			name = "Rare Spawn",
			mounts = {44168},
			mountID = {}
		}			
	}																		
}
core.mountList[8] = {
	name = "TBC",
	categories = {
		CenarionExpedition = {
			name = "Cenarion Expedition",
			mounts = {33999},
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
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {32768, 35513},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {32458, 30480},
			mountID = {}
		}
	}
}
core.mountList[9] = {
	name = "Classic",
	categories = {	
		Reputation = {
			name = "Reputation",
			mounts = {13086, 46102},
			mountID = {}
		},
		DungeonDrop = {
			name = "Dungeon Drop",
			mounts = {13335},
			mountID = {}
		},
		RaidDrop = {
			name = "Raid Drop",
			mounts = {21218, 21321, 21323, 21324},
			mountID = {}
		}
	}						
}
core.mountList[10] = {
	name = "Alliance",
	categories = {	
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
		Dwarf = {
			name = "Dwarf",
			mounts = {18785, 18786, 18787, 5864, 5872, 5873},
			mountID = {}
		},
		DarkIronDwarf = {
			name = "Dark Iron Dwarf",
			mounts = {191123},
			mountID = {}
		},
		Gnome = {
			name = "Gnome",
			mounts = {18772, 18773, 18774, 8563, 8595, 13322, 13321},
			mountID = {}
		},
		Draenei = {
			name = "Draenei",
			mounts = {29745, 29746, 29747, 28481, 29743, 29744},
			mountID = {}
		},
		Worgen = {
			name = "Worgen",
			mounts = {73839, 73838},
			mountID = {}
		},
		Pandaren = {
			name = "Pandaren",
			mounts = {91010, 91012, 91011, 91013, 91014, 91015, 91004, 91008, 91009, 91005, 91006, 91007},
			mountID = {}
		},
		Dracthyr = {
			name = "Dracthyr",
			mounts = {201720, 201702, 201719, 201704, 198809, 198811, 198810, 198808},
			mountID = {},
		}		
	}				
}
core.mountList[11] = {
	name = "Horde",
	categories = {	
		Orc = {
			name = "Orc",
			mounts = {18796, 18798, 18797, 46099, 5668, 5665, 1132},
			mountID = {}
		},
		Undead = {
			name = "Undead",
			mounts = {13334, 18791, 13331, 13332, 13333, 46308, 47101},
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
		Bloodelf = {
			name = "Blood Elf",
			mounts = {28936, 29223, 29224, 28927, 29220, 29221, 29222, 191566},
			mountID = {}
		},
		Goblin = {
			name = "Goblin",
			mounts = {62462, 62461},
			mountID = {}
		},			
		Pandaren = {
			name = "Pandaren",
			mounts = {91010, 91012, 91011, 91013, 91014, 91015, 91004, 91008, 91009, 91005, 91006, 91007},
			mountID = {}
		},
		Dracthyr = {
			name = "Dracthyr",
			mounts = {201720, 201702, 201719, 201704, 198809, 198811, 198810, 198808},
			mountID = {},
		}
	}
}
core.mountList[12] = {
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
		Engineering = {
			name = "Engineering",
			mounts = {34060, 41508, 34061, 44413, 87250, 87251, 95416, 161134, 153594},
			mountID = {}
		},
		Fishing = {
			name = "Fishing",
			mounts = {46109, 23720, 152912, 163131},
			mountID = {}
		},
		Jewelcrafting = {
			name = "Jewelcrafting",
			mounts = {83088, 83087, 83090, 83089, 82453},
			mountID = {}
		},
		Tailoring = {
			name = "Tailoring",
			mounts = {44554, 54797, 44558, 115363},
			mountID = {}
		},
		Leatherworking = {
			name = "Leatherworking",
			mounts = {108883, 129962},
			mountID = {}
		},
		Blacksmith = {
			name = "Blacksmith",
			mounts = {137686},
			mountID = {}
		}
	}
}
core.mountList[13] = {
	name = "PVP",
	categories = {	
		Achievement = {
			name = "Achievement",
			mounts = {44223, 44224},
			mountID = {}
		},
		MarkHonor = {
			name = "Mark of Honor",
			mounts = {19030, 29465, 29467, 29468, 29471, 35906, 43956, 29466, 29469, 29470, 29472, 19029, 34129, 44077},
			mountID = {}
		},
		Honor = {
			name = "Honor",
			mounts = {140228, 140233, 140408, 140232, 140230, 140407, 164250},
			mountID = {}
		},
		ViciousSaddle = {
			name = "Vicious Saddle",
			mounts = { 102533, 70910, 116778, 124540, 140348, 140354, 143649, 142235, 142437, 152869, 163124, 165020, 163121, 173713, 184013,184014, 186179, 70909, 102514, 116777, 124089, 140353, 140350, 143648, 142234, 142237, 152870, 163123, 163122, 173714, 186178, 187681, 187680, 187642, 187644, 201788, 201789},
			mountID = {}
		},
		Gladiator = {
			name = "Gladiator",
			mounts = {202086},
			mountID = {}
		},
		Halaa = {
			name = "Halaa",
			mounts = {28915, 29228},
			mountID = {}
		},
		TimelessIsle = {
			name = "Timeless Isle",
			mounts = {103638},
			mountID = {}
		},
		TalonsVengeance = {
			name = "Talon's Vengeance",
			mounts = {142369},
			mountID = {}
		}
	}
}
core.mountList[14] = {
	name = "WorldEvents",
	categories = {	
		Achievement = {
			name = "Achievement",
			mounts = {44177},
			mountID = {}
		},
		Brewfest = {
			name = "Brewfest",
			mounts = {33977, 37828},
			mountID = {}
		},
		HallowsEnd = {
			name = "Hallow's End",
			mounts = {37012},
			mountID = {}
		},
		LoveAir = {
			name = "Love is in the Air",
			mounts = {72146, 50250},
			mountID = {}
		},
		NobleGarden = {
			name = "Noblegarden",
			mounts = {72145},
			mountID = {}
		},
		WinterVeil = {
			name = "Winter Veil",
			mounts = {128671},
			mountID = {}
		},
		Brawlers = {
			name = "Brawler's Guild",
			mounts = {98405, 142403, 166724},
			mountID = {}
		},
		DarkmoonFaire = {
			name = "Darkmoon Faire",
			mounts = {72140, 73766, 142398, 153485},
			mountID = {}
		},
		TimeWalking = {
			name = "Timewalking",
			mounts = {129923, 129922, 87775, 167894, 167895, 133543, 188674, 187595},
			mountID = {}
		}
	}
}
core.mountList[15] = {
	name = "Promotion",
	categories = {	
		BlizzardStore = {
			name = "Blizzard Store",
			mounts = {54811, 69846, 78924, 95341, 97989, 107951, 112326, 122469, 147901, 156564, 160589, 166775, 166774, 166776, "m1266", "m1267", "m1290", "m1346", "m1291", "m1456", "m1330", "m1531", "m1581", "m1312", "m1662"},
			mountID = {1266, 1267, 1290, 1346, 1291, 1456, 1330, 1531, 1581}
		},
		CollectorsEdition = {
			name = "Collector's Edition",
			mounts = {85870, 109013, 128425, 153539, 153540, "m1289", "m1556"},
			mountID = {1289, 1556}
		},
		WowClassic = {
			name = "WoW Classic",
			mounts = {"m1444", "m1602"},
			mountID = {1444, 1602}
		},
		anniversary = {
			name = "WoW Anniversary Mounts",
			mounts = {172022, 172023, 186469},
			mountID = {}
		},
		Hearthstone = {
			name = "Hearthstone",
			mounts = {98618, "m1513"},
			mountID = {1513}
		},
		WarcraftIII = {
			name = "Warcraft III Reforged",
			mounts = {164571},
			mountID = {}
		},
		DiabloIV = {
			name = "Diablo IV",
			mounts = {"m1596"},
			mountID = {}
		},		
		RAF = {
			name = "Recruit-A-Friend",
			mounts = {173297, 173299},
			mountID = {}
		},
		AzerothChoppers = {
			name = "Azeroth Choppers",
			mounts = {116789},
			mountID = {}
		},
		TCG = {
			name = "Trading Card Game",
			mounts = {49283, 49284, 49285, 49286, 49282, 49290, 54069, 54068, 68008, 69228, 68825, 71718, 72582, 72575, 79771, 93671},
			mountID = {}
		},
		AV = {
			name = "Timewalking Alterac Valley",
			mounts = {172023, 172022},
			mountID = {}
		}
	}	
}
core.mountList[16] = {
	name = "Other",
	categories = {	
		GuildVendor = {
			name = "Guild Vendor",
			mounts = {63125, 62298, 67107, 85666, 116666},
			mountID = {}
		},
		BMAH = {
			name = "BMAH",
			mounts = {19872, 19902, 44175, 163042},
			mountID = {}
		},
		MountCollection = {
			name = "Mount Collection",
			mounts = {44178, 44843, 44842, 98104, 91802, 98259, 69226, 87776, 137614, 163981, 118676, 198654},
			mountID = {}
		},
		ExaltedReputations = {
			name = "Exalted Reputations",
			mounts = {163982},
			mountID = {}
		},
		Toy = {
			name = "Toy",
			mounts = {140500},
			mountID = {}
		},
		Heirlooms = {
			name = "Heirlooms",
			mounts = {120968, 122703},
			mountID = {}
		},
		Paladin = {
			name="Paladin",
			mounts = {47179},
			mountID = {41, 84, 149, 150, 350, 351, 367, 368, 1046, 1047, 1568}
		},
		Warlock = {
			name="Warlock",
			mounts = {"m17", "m83"},
			mountID = {17, 83},
		},
		DemonHunter = {
			name="Demon Hunter",
			mounts = {"m780"},
		}
	}
}
core.mountList[17] = {
	name = "Unobtainable",
	categories = {	
		MythicPlus = {
			name = "Mythic +",
			mounts = {182717, 187525, 174836, 187682, 192557},
			mountID = {}
		},
		ScrollOfResurrection = {
			name = "Scroll of Resurrection",
			mounts = {76902, 76889},
			mountID = {}
		},
		ChallengeMode = {
			name = "Challenge Mode",
			mounts = {89154, 90710, 90711, 90712, 116791},
			mountID = {}
		},
		RAF = {
			name = "Recruit-A-Friend",
			mounts = {83086, 106246, 118515, 37719, "m382"},
			mountID = {}
		},
		AOTC = {
			name = "Ahead of the Curve",
			mounts = {104246, 128422, 152901, 174862, 190771},
			mountID = {}
		},
		Brawl = {
			name = "Brawler's Guild",
			mounts = {142403, 98405},
			mountID = {}
		},
		Arena = {
			name = "Arena Mounts",
			mounts = {30609, 34092, 37676, 43516, 46708, 46171, 47840, 50435, 71339, 71954, 85785, 95041, 104325, 104326, 104327, 128277, 128281, 128282, 141843, 141844, 141845, 141846, 141847, 141848, 153493, 156879, 156880, 156881, 156884, 183937, 186177, 189507, 191290},
			mountID = {}
		},
		DCAzerothChopper = {
			name = "Azeroth Choppers",
			mounts = {116788},
			mountID = {}
		},
		OriginalEpic = {
			name = "Original Epic Mounts",
			mounts = {13328, 13329, 13327, 13326, 12354, 12353, 12302, 12303, 12351, 12330, 15292, 15293, 13317, 8586},
			mountID = {}
		},
		Promotion = {
			name = "Old Promotion Mounts",
			mounts = {76755, 95341, 112327, 92724, 143631, 163128, 163127, 76755, 43599, 151618, "m1458"},
			mountID = {}
		},	
		RaidMounts = {
			name = "Unobtainable Raid Mounts",
			mounts = {49098, 49096, 49046, 49044, 44164, 33809, 21176, "m937"},
			mountID = {937}
		},
		BrewFest = {
			name = "BrewFest",
			mounts = {33976},
			mountID = {}
		},
		Anniversary = {
			name="Old Anniversary Mounts",
			mounts = {172012, 115484, "m1424"},
			mountID = {}
		},
		PreLaunchEvent = {
			name = "Pre-Launch Event",
			mounts = {163127, 163128},
			mountID = {}
		}	
	}
}
core.mountList[18] = {
	name = "Dragonflight",
	categories = {
		DragonRiding = {
			name = "Dragon Riding",
			mounts = {194034, 194705, 194521, 194549}
		},
		Achievement = {
			name = "Achievement",
			mounts = {199412, 192806, 192791, 192784},
		},
		Treasures = {
			name = "Treasures",
			mounts = {201440, 198825, 192777},
		},
		Quest = {
			name = "Quest",
			mounts = {192799, 198870, "m1545"},
		},
		Reputation = {		
			name = "Renown",
			mounts = {192762, 198872, 192761, 192764, 200118, 201426, 201425},
		},
		Zone = {
			name = "Zone",
			mounts = {192601, 198873, 198871, 192775, 201454},
		},
		Secret = {
			name = "Secret",
			mounts = {192786}
		},
	}
}


core.dragonRiding = {
	[194034] = {
		manuscripts = {
			[1] = {201790,72367, "Raid - Vault of the Incarnates"},
			[2] = {197351,69552, "DragonRiding Races - All Advanced Races (Bronze) - The Waking Shores"},
			[3] = {197399,69600, "Quest - Home Is Where the Frogs Are"},
			[4] = {197398,69599, "Rare - Gnarls (Azure Span)"},
			[5] = {197392,69593, "Reputation - Wrathion/Sabellian"},
			[6] = {197400,69601, "Rare - Liskheszaera (Ohn'ahran Plains)"},
			[7] = {197346,69547, "Reputation - Wrathion/Sabellian"},
			[8] = {197370,69571, "DragonRiding Races - Waking Shores (Gold)"},
			[9] = {197379,69580, "Rare - Firava the Rekindler (Waking Shores)"},
			[10] = {197394,69595, "Profession - Inscription"},
			[11] = {197383,69584, "Rare - Prozela Galeshot (Ohn'ahran Plains)"},
			[12] = {197396,69597, "Dungeon - Decay Tainted Chest (Brackenhide Hollow)"},
			[13] = {197357,69558, "Renown - Valdrakken Accord - Renown 26"},
			[14] = {197361,69562, "Quest - Memories"},
			[15] = {192523,66720, "Reputation - Maruukai Centaur"},
			[16] = {197347,69548, "Profession - Inscription"},
			[17] = {197385,69586, "Quest - Whack-a-Gnoll"},
			[18] = {197401,69602, "Dungeon - Ruby Life Pools - Erkhart Stormvein"},
			[19] = {197403,69604, "Rare - Ancient Hornswog"},
			[20] = {197368,69569, "Reputation - Cobalt Assembly"},
			[21] = {197381,69582, "Quest - Mad Mordigan & The Crystal King"},
			[22] = {197355,69585, "Reputation - Cobalt Assembly"},
			[23] = {197354,69555, "Quest - Exeunt, Triumphant"},
			[24] = {197397,69598, "Dungeon - Neltharus - Warlord Sargha"},
			-- [25] = {197393,69594, },
			[26] = {197391,69592, "Reputation - Valdrakken Accord"},
			[27] = {197377,69578, "Profession - Inscription"},
			[28] = {197352,69553, "Profession - Inscription"},
			[29] = {197406,69607, "Quest - Training Wings"},
			[30] = {197389,69590, "Reputation - Maruukai Centaur"},
			[31] = {197390,69591, "Reputation - Iskaara Tuskarr"},
			[32] = {197360,69561, "Quest - Initial Mysteries of the Dragon Isles Drakes"},
			[33] = {197382,69583, "Rare - Shade of Grief (Ohn'ahran Plains)"},
			[34] = {197372,69573, "Rare - Zenet Avis (Ohn'ahran Plains)"},
			[35] = {197375,69576, "Quest - Renewal of Vows"},
			[36] = {197365,69566, "Quest - A New Set of Horns"},
			[37] = {197402,69603, "Reputation - Dragonscale Expedition"},
			[38] = {197407,69608, "Quest - The Black Locus"},
			[39] = {197350,69551, "Reputation - Valdrakken Accord"},
			[40] = {197380,69581, "Quest - A New Set of Horns"},
			[41] = {197363,69564, "Quest - Initial Mysteries of the Dragon Isles Drakes"},
			[42] = {197386,69587, "Quest - Initial Mysteries of the Dragon Isles Drakes"},
			[43] = {197395,69596, "Reputation - Dragonscale Expedition"},
			[44] = {197366,69567, "World Quest - DragonRiding Races"},
			[45] = {197362,69563, "Profession - Inscription"},
			[46] = {197376,69577, "Dungeon - Neltharus - Warlord Sargha"},
			[47] = {197359,69560, "Quest - The Nokhud Offensive: Founders Keepers"},
			[48] = {197358,69559, "Quest - Unknown"},
			[49] = {197367,69568, "Rare - Ronsak the Decimator (Ohn'ahran Plains)"},
			[50] = {197356,69557, "Renown - Dragonscale Expedition"},
			[51] = {197404,69605, "Rare - Blightfur (The Azure Span)"},
			[52] = {197378,69579, "Quest - Exeunt, Triumphant"},
			[53] = {197374,69575, "Reputation - Dragonscale Expedition"},
			[54] = {197408,69609, "Quest - Echoes of the Fallen"},
			[55] = {197384,69585, "World Quest - DragonRiding Races"},
			-- [56] = {197348,69549, "No Source"},
			[57] = {197405,69606, "Quest - Covering Their Tails"},
			-- [58] = {197373,69574, "Helmet No Info"}, --! Helmet
			[59] = {197369,69570, "Quest"},
			[60] = {197388,69589, "Quest - Howling in the Big Tree Hills"},
			-- [61] = {197364,69565, "No Source"},
			[62] = {197387,69588, "World Quest - DragonRiding Races"},
			-- [63] = {197371,69572, "No Source"},
			-- [64] = {197349,69550, "No Source"},
			-- [65] = {197353,69554, "No Source"},			
		}
	},
	[194705] = {
		manuscripts = {
			[1] = {197142,69343, "Reputation - True Friend Wrathion or Sabellian"},
			[2] = {197135,69343, "Rare - Magmaton (Waking Shores)"},
			[3] = {197138,69339, "Rare - Seeker Teryx (Ohn'ahran Plains)"},
			[4] = {197094,69295, "DragonRiding Races - All Advanced Races (Bronze) - Azure Span"},
			[5] = {197127,69328, "Dungeon Drop - Azure Vault - Umbrelskul"},
			[6] = {197090,69290, "Reputation - Wrathion or Sabellian"},
			[7] = {201792,72371, "PVP - Gladiator Season 1"},
			[8] = {197147,69348, "Dungeon Drop - Algeth'ar Academy - Echo of Doragosa"},
			[9] = {197150,69351, "Rare - Sharpfang (The Azure Span)"},
			[10] = {197144,69345, "Reputation - Dragonscale Expedition"}, --! Check Vendor - Need Rep level
			[11] = {197122,69323, "Quest - Cache and Release"},
			[12] = {197099,69300, "Renown - Valdrakken Accord - Renown 26"},
			[13] = {197149,69350, "Rare - Magmaton (Waking Shores)"},
			[14] = {197111,69312, "Grand Hunt"},
			[15] = {197091,69291, "Profession - Inscription"},
			[16] = {197128,69329, "World Quest - DragonRiding Races"},
			-- [17] = {197146,69347, "No source"}, --! Not listed in Rostrum
			[18] = {197103,69304, "Quest - The Land Awakens"},
			[19] = {197155,69356, "Rostrum Source - Quest"}, --! No info on which quest on wowhead.
			[20] = {197143,69344, "Reputation - Maruukai"},
			[21] = {197116,69317, "Rare - Shadeslash Trakken (The Waking Shores)"},
			[22] = {197098,69299, "Rare - Gushgut the Beaksinker (The Waking Shores)"},
			-- [23] = {197130,69331, "No Source"},  --! Not listed in Rostrum
			[24] = {197145,69346, "Reputation - Valdrakken Accord"}, --! Need Rep level
			[25] = {197118,69319, "DragonRiding Races - Normal - Azure Span Gold"},
			[26] = {197107,69308, "Quest - Send It!"},
			[27] = {197117,69318, "Profession - Inscription"},
			[28] = {197113,69314, "World Quest - DragonRiding Races"},
			[29] = {197132,69333, "Quest - Mounting Curiosity"},
			[30] = {197114,69315, "Quest - Mounting Curiosity"},
			[31] = {197096,69297, "Profession - Inscription"},
			[32] = {197097,69298, "Quest - What Once Was Ours"},
			[33] = {197093,69294, "Reputation - Valdrakken Accord"},
			[34] = {197108,69309, "Profession - Inscription"},
			[35] = {197123,69324, "Reputation - Iskaara Tuskarr"},
			[36] = {197110,69311, "Quest - Vengeance Served Hot"},
			[37] = {197154,69355, "Profession - Inscription"},
			[38] = {197125,69326, "World Drop - No Info"}, --! Missing more information, Rostrum says World Drop.
			-- [39] = {197119,69320, "No Info"}, --! Not in Rostrum?
			[40] = {197101,69302, "Quest - Mounting Curiosity"},
			[41] = {197133,69334, "Quest - The Awaited Egg-splosion"},
			[42] = {197131,69332, "World Drop - No Info"}, --! Missing more information,
			[43] = {197126,69327, "Quest - Clear the Sky"},
			-- [44] = {197104,69305, "No Info"}, --! Missing in Rostrum
			[45] = {197152,69353, "World Quest - DragonRiding Races"},
			[46] = {197151,69352, "Quest - Cracks in Time"},
			-- [47] = {197120,69321, "No Info"}, --! Helmet, missing info
			[48] = {197141,69342, "Quest - Glowing Arcane Jewel"},
			[49] = {197100,69301, "Rare - Phenran (Thaldraszus)"},
			[50] = {197105,69306, "Rare - Seeker Teryx (Ohn'ahran Plains)"},
			-- [51] = {197134,69335, "No Info"}, --! Legs, missing info
			-- [52] = {197124,69325, "No Info"}, --! Missing in Rostrum
			[53] = {197153,69354, "Reputation - Iskaara Tuskarr"},
			[54] = {197112,69313, "Dungeon - Algeth'ar Academy - Echo of Doragosa"},
			-- [55] = {197095,69296, "No Info"}, --! Missing in Rostrum
			[56] = {197115,69316, "Rare - Shade of Grief (Ohn'ahran Plains)"},
			[57] = {197140,69341, "Dungeon - The Azure Vault - Umbrelskul"},
			[58] = {197139,69340, "Reputation - Iskaara Tuskarr"},
			-- [59] = {197136,69337, "No Info"}, --! Missing in Rostrum
			[60] = {197148,69349, "Reputations - Cobalt Assembly"},
			[61] = {197137,69338, "Quest - Glowing Arcane Jewel"},
			[62] = {197106,69307, "Rare - Liskheszaera (Ohn'ahran Plains)"},
			[63] = {197121,69322, "Rare - Azra's Prized Peony (The Waking Shores)"},
			-- [64] = {197129,69330, "No Info"}, --! Missing in Rostrum
			-- [65] = {197102,69303, "No Info"}, --! Missing in Rostrum
			-- [66] = {197156,69357, "Default?"}, --! Default Color maybe
			[67] = {197109,69310, "World Quest - DragonRiding Races"},
		}
	},
	[194521] = {
		manuscripts = {
			[1] = {197010,69210, "Reputation - Dragonscale Expedition"},
			[2] = {197013,69213, "Reputation - Wrathion/Sabellian"},
			[3] = {196966,69166, "DragonRiding Races - Thaldraszus Advanced: Bronze"},
			[4] = {196976,69176, "Rare - Blisterhide (Azure Span)"},
			[5] = {196989,69189, "Quest"},
			[6] = {196991,69191, "Rare - Amethyzar the Glittering (Waking Shores)"},
			[7] = {196964,69164, "Reputation - Wrathion/Sabellian"},
			[8] = {196992,69192, "Rare - Ancient Hornswog (Waking Shores)"},
			[9] = {196999,69199, "World Drop"},
			[10] = {196985,69185, "Rare - Nulltheria the Void Gazer (Waking Shores)"},
			[11] = {196987,69187, "DragonRiding Races - Thaldraszus: Gold"},
			[12] = {196996,69196, "Rare - Shade of Grief (Ohn'ahran Plains)"},
			[13] = {196961,69161, "Renown - Valdrakken Accord - Renown 26"},
			[14] = {197005,69205, "Rare - Dragonhunter Igordan (Waking Shores)"},
			[15] = {197019,69219, "Rare - Dragonhunter Igordan (Waking Shores)"},
			[16] = {196972,69172, "Quest - Feeling Freedom"},
			[17] = {196994,69194, "World Drop"},
			[18] = {196981,69181, "Profession - Inscription"},
			[19] = {196980,69180, "Profession - Inscription"},
			[20] = {196982,69182, "Rare - Sharpfang (Azure Span)"},
			[21] = {196963,69163, "Profession - Inscription"},
			-- [22] = {197014,69214, "No Source"},
			[23] = {196986,69186, "Rare - Blightpaw the Depraved (Ohn'ahran Plains)"},
			[24] = {196968,69168, "Profession - Inscription"},
			[25] = {196988,69188, "Profession - Inscription"},
			[26] = {197011,69211, "Reputation - Maruuk Centaur"},
			[27] = {197023,69223, "Rare - Klozicc the Ascended (Waking Shores)"},
			-- [28] = {197015,69215, "No Source"},
			[29] = {196962,69162, "Reputation - Valdrakken Accord"},
			[30] = {196979,69179, "World Quest - DragonRiding Races"},
			[31] = {196969,69169, "Reputation - Cobalt Assembly"},
			[32] = {197003,69203, "Quest - Feeling Freedom"},
			[33] = {197017,69217, "World Quest - DragonRiding Races"},
			[34] = {197004,69204, "Quest"},
			[35] = {197007,69207, "Dungeon - Halls of Infusion - Primal Tsunami"},
			[36] = {196998,69198, "Reputation - Valdrakken Accord"},
			[37] = {197009,69209, "Reputation - Valdrakken Accord"},
			[38] = {197008,69208, "World Drop"},
			[39] = {197016,69216, "Rare - Ronsak the Decimator (Ohn'ahran Plains)"},
			[40] = {197018,69218, "Reputation - Cobalt Assembly"},
			[41] = {196970,69170, "Rare - Seeker Teryx (Ohn'ahran Plains)"},
			-- [42] = {197000,69200, "No Source"},
			[43] = {196973,69173, "Rare - Blightpaw the Depraved (Ohn'ahran Plains)"},
			[44] = {197022,69222, "Rare - Brackle (Azure Span)"},
			[45] = {197001,69201, "Rare - Anhydros the Tidetaker (Waking Shores)"},
			[46] = {197020,69220, "Reputation - Valdrakken Accord"},
			[47] = {196975,69175, "Dungeon - Halls of Infusion - Primal Tsunami"},
			-- [48] = {197021,69221, "No Source"},
			-- [49] = {196967,69167, "No Source"},
			-- [50] = {196974,69174, "No Source"},
			-- [51] = {196993,69193, "No Source"},
			-- [52] = {196990,69190, "No Source"},
			[53] = {196971,69171, "World Quest - DragonRiding Races"},
			-- [54] = {196997,69197, "No Source"},
			[55] = {196984,69184, "World Drop"},
			-- [56] = {196983,69183, "No Source"},
			-- [57] = {196995,69195, "No Source"},
			-- [58] = {196965,69165, "No Source"},
			-- [59] = {196978,69178, "No Source"},
			-- [60] = {197006,69206, "No Source"},
			-- [61] = {197002,69202, "No Source"},			
		}
	},
	[194549] = {
		manuscripts = {
			[1] = {197596,69800, "Quest - Observing the Wind"},
			[2] = {197610,69814, "Quest - Observing the Wind"},
			[3] = {197611,69815, "Reputation - Wrathion/Sabellian"},
			[4] = {197619,69823, "World Quests - DragonRiding Races"},
			[5] = {197617,69821, "Quest"},
			[6] = {197580,69784, "DragonRiding - Ohn'ahran Plains: Gold"},
			[7] = {197634,69845, "Profession - Inscription"},
			[8] = {197620,69824, "Reputation - Cobalt Assembly"},
			[9] = {197599,69803, "DragonRiding - Ohn'ahran Plains: Gold"},
			[10] = {197635,69846, "Dungeon - The Nokhud Offensive - Balakar Khan"},
			[11] = {197614,69818, "Reputation - Dragonscale Expedition"},
			[12] = {197584,69788, "Reputation - Cobalt Assembly"},
			[13] = {197597,69801, "Profession - Inscription"},
			[14] = {197585,69789, "Treasure"},
			-- [15] = {197615,69819, "No Source"},
			[16] = {197593,69797, "Quest"},
			[17] = {197601,69805, "Dungeon - Ruby Life Pools - Erkhart Stormvein"},
			[18] = {197587,69791, "Quest"},
			-- [19] = {197616,69820, "No Source"},
			[20] = {197602,69806, "Rare - Mikrin of the Raging Winds (Ohn'ahran Plains)"},
			[21] = {197624,69828, "Rare - Klozicc the Ascended (Waking Shores)"},
			[22] = {197613,69817, "Reputation - Valdrakken Accord"},
			[23] = {197612,69816, "Reputation  - Iskaara Tuskarr"},
			[24] = {197578,69782, "Profession - Inscription"},
			[25] = {197589,69793, "Rare - Skewersnout (Waking Shores)"},
			[26] = {197625,69829, "Dungeon - The Nokhud Offensive - Balakar Khan"},
			[27] = {197630,69836, "Quest"},
			[28] = {197607,69811, "Quest - Ruriq's River Rapids Ride"},
			[29] = {197588,69792, "Renown - Valdrakken Accord - Renown 26"},
			[30] = {197618,69822, "Reputation - Maruuk Centaur"},
			[31] = {197579,69783, "Profession - Inscription"},
			[32] = {197604,69808, "Reputation - Maruuk Centaur"},
			[33] = {197605,69809, "World Quests - DragonRiding Races"},
			[34] = {197592,69796, "Profession - Inscription"},
			-- [35] = {197591,69795, "No Source"},
			[36] = {197595,69799, "Rare - Blue Terror (Azure Span)"},
			[37] = {197606,69810, "Rare - Zenet Avis (Ohn'ahran Plains)"},
			[38] = {197603,69807, "Quest - In Defense of Vakthros"},
			[39] = {197623,69827, "Reputation - Maruuk Centaur"},
			[40] = {197581,69785, "Reputation - Valdrakken Accord"},
			[41] = {197627,69832, "Quest - Ice Cave Ya Got There"},
			[42] = {197636,69847, "Reputation - Maruuk Centaur"},
			[43] = {197590,69794, "World Drop"},
			[44] = {197586,69790, "Rare - Forgotten Creation (Azure Span)"},
			-- [45] = {197600,69804, "No Source"},
			-- [46] = {197583,69787, "No Source"},
			[47] = {197598,69802, "Dungeon - Brackenhide Hollow - Decay Tainted Chest"},
			[48] = {197622,69826, "Quest - Driven Mad"},
			-- [49] = {197577,69781, "No Source"},
			-- [50] = {197582,69786, "No Source"},
			[51] = {197608,69812, "Rare - Spellforged Brute (Azure Span)"},
			[52] = {197609,69813, "World Drop"},
			[53] = {197628,69834, "World Drop"},
			-- [54] = {197629,69835, "No Source"},
			-- [55] = {197626,69831, "No Source"},
			-- [56] = {197621,69825, "No Source"},
			-- [57] = {197594,69798, "No Source"},			
		}
	},			
}


core.sectionNames[10] = {
	name = "Vanilla",
	mounts = core.mountList[9],
	icon = "Interface\\AddOns\\MCL\\icons\\classic.blp",
}
core.sectionNames[9] = {
	name = "The Burning Crusade",
	mounts = core.mountList[8],
	icon = "Interface\\AddOns\\MCL\\icons\\bc.blp",
}
core.sectionNames[8] = {
	name = "Wrath of the Lich King",
	mounts = core.mountList[7],
	icon = "Interface\\AddOns\\MCL\\icons\\wrath.blp",
}
core.sectionNames[7] = {
	name = "Cataclysm",
	mounts = core.mountList[6],
	icon = "Interface\\AddOns\\MCL\\icons\\cata.blp",
}
core.sectionNames[6] = {
	name = "Mists of Pandaria",
	mounts = core.mountList[5],
	icon = "Interface\\AddOns\\MCL\\icons\\mists.blp",
}
core.sectionNames[5] = {
	name = "Warlords of Draenor",
	mounts = core.mountList[4],
	icon = "Interface\\AddOns\\MCL\\icons\\wod.blp",
}
core.sectionNames[4] = {
	name = "Legion",
	mounts = core.mountList[3],
	icon = "Interface\\AddOns\\MCL\\icons\\legion.blp",
}
core.sectionNames[3] = {
	name = "Battle for Azeroth",
	mounts = core.mountList[2],
	icon = "Interface\\AddOns\\MCL\\icons\\bfa.blp",
}
core.sectionNames[2] = {
	name = "Shadowlands",
	mounts = core.mountList[1],
	icon = "Interface\\AddOns\\MCL\\icons\\sl.blp",
}
core.sectionNames[1] = {
	name = "Dragonflight",
	mounts = core.mountList[18],
	icon = "Interface\\AddOns\\MCL\\icons\\df.blp",
}
core.sectionNames[11] = {
	name = "Horde",
	mounts = core.mountList[11],
	icon = "Interface\\AddOns\\MCL\\icons\\horde.blp",
}
core.sectionNames[12] = {
	name = "Alliance",
	mounts = core.mountList[10],
	icon = "Interface\\AddOns\\MCL\\icons\\alliance.blp",
}
core.sectionNames[13] = {
	name = "Professions",
	mounts = core.mountList[12],
	icon = "Interface\\AddOns\\MCL\\icons\\professions.blp",
}
core.sectionNames[14] = {
	name = "PVP",
	mounts = core.mountList[13],
	icon = "Interface\\AddOns\\MCL\\icons\\pvp.blp",
}
core.sectionNames[15] = {
	name = "World Events",
	mounts = core.mountList[14],
	icon = "Interface\\AddOns\\MCL\\icons\\holiday.blp",
}
core.sectionNames[16] = {
	name = "Promotion",
	mounts = core.mountList[15],
	icon = "Interface\\AddOns\\MCL\\icons\\promotion.blp",
}
core.sectionNames[17] = {
	name = "Other",
	mounts = core.mountList[16],
	icon = "Interface\\AddOns\\MCL\\icons\\other.blp",
}
core.sectionNames[18] = {
	name = "Unobtainable",
	mounts = core.mountList[17],
	icon = "Interface\\AddOns\\MCL\\icons\\unobtainable.blp",
}
core.sectionNames[19] = {
	name = "Pinned",
	mounts = {MCL_PINNED},
	icon = "Interface\\AddOns\\MCL\\icons\\pin.blp",	
}
core.sectionNames[20] = {
	name = "Overview",
	mounts = {},
	icon = "Interface\\AddOns\\MCL\\icons\\mcl.blp",	
}