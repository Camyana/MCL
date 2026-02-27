--- Vendor data for mounts, keyed by WoW Mount ID (C_MountJournal).
--- Each entry is an array of vendor tables (supports multiple vendors per mount).
--- Each vendor has NPC name, zone, optional faction (Alliance/Horde), and optional coordinates.
---@type table<number, {npc:string, zone:string, faction:string?, m:number?, x:number?, y:number?}[]>
MCL_GUIDE_VENDOR_DATA = {

    [6] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Brown Horse
    [7] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Gray Wolf
    [9] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Black Stallion
    [11] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Pinto
    [12] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Black Wolf
    [14] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Timber Wolf
    [18] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Chestnut Mare
    [19] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Dire Wolf
    [20] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Brown Wolf
    [21] = { { npc = "Veron Amberstill", zone = "Dun Morogh", m = 27, x = 70.4, y = 49 } },  -- Gray Ram
    [24] = { { npc = "Veron Amberstill", zone = "Dun Morogh", m = 27, x = 70.4, y = 49 } },  -- White Ram
    [25] = { { npc = "Veron Amberstill", zone = "Dun Morogh", m = 27, x = 70.4, y = 49 } },  -- Brown Ram
    [26] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Striped Frostsaber
    [27] = { { npc = "Zjolnir", zone = "Durotar", m = 1, x = 55.2, y = 75.4 } },  -- Emerald Raptor
    [31] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Spotted Frostsaber
    [34] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Striped Nightsaber
    [36] = { { npc = "Zjolnir", zone = "Durotar", m = 1, x = 55.2, y = 75.4 } },  -- Turquoise Raptor
    [38] = { { npc = "Zjolnir", zone = "Durotar", m = 1, x = 55.2, y = 75.4 } },  -- Violet Raptor
    [39] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Red Mechanostrider
    [40] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Blue Mechanostrider
    [43] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Green Mechanostrider
    [57] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Green Mechanostrider
    [58] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Unpainted Mechanostrider
    [65] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Red Skeletal Horse
    [66] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Blue Skeletal Horse
    [67] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Brown Skeletal Horse
    [68] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Green Skeletal Warhorse
    [71] = { { npc = "Harb Clawhoof", zone = "Mulgore", m = 7, x = 47.4, y = 58.2 } },  -- Gray Kodo
    [72] = { { npc = "Harb Clawhoof", zone = "Mulgore", m = 7, x = 47.4, y = 58.2 } },  -- Brown Kodo
    [75] = { { npc = "Lieutenant Karter", zone = "Stormwind City", m = 84, x = 76.2, y = 65.4 } },  -- Black War Steed
    [76] = { { npc = "Raider Bork", zone = "Orgrimmar", m = 85, x = 41.4, y = 72.2 } },  -- Black War Kodo
    [77] = { { npc = "Lieutenant Karter", zone = "Stormwind City", m = 84, x = 76.2, y = 65.4 } },  -- Black Battlestrider
    [78] = { { npc = "Lieutenant Karter", zone = "Stormwind City", m = 84, x = 76.2, y = 65.4 } },  -- Black War Ram
    [79] = { { npc = "Raider Bork", zone = "Orgrimmar", m = 85, x = 41.4, y = 72.2 } },  -- Black War Raptor
    [80] = { { npc = "Raider Bork", zone = "Orgrimmar", m = 85, x = 41.4, y = 72.2 } },  -- Red Skeletal Warhorse
    [81] = { { npc = "Lieutenant Karter", zone = "Stormwind City", m = 84, x = 76.2, y = 65.4 } },  -- Black War Tiger
    [82] = { { npc = "Raider Bork", zone = "Orgrimmar", m = 85, x = 41.4, y = 72.2 } },  -- Black War Wolf
    [85] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Swift Mistsaber
    [87] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Swift Frostsaber
    [88] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Swift Yellow Mechanostrider
    [89] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Swift White Mechanostrider
    [90] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Swift Green Mechanostrider
    [91] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Swift Palomino
    [92] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Swift White Steed
    [93] = { { npc = "Katie Stokx", zone = "Stormwind City", m = 1519, x = 77, y = 67.8 } },  -- Swift Brown Steed
    [94] = { { npc = "Veron Amberstill", zone = "Dun Morogh", m = 27, x = 70.4, y = 49 } },  -- Swift Brown Ram
    [95] = { { npc = "Veron Amberstill", zone = "Dun Morogh", m = 27, x = 70.4, y = 49 } },  -- Swift Gray Ram
    [96] = { { npc = "Veron Amberstill", zone = "Dun Morogh", m = 27, x = 70.4, y = 49 } },  -- Swift White Ram
    [97] = { { npc = "Zjolnir", zone = "Durotar", m = 1, x = 55.2, y = 75.4 } },  -- Swift Blue Raptor
    [98] = { { npc = "Zjolnir", zone = "Durotar", m = 1, x = 55.2, y = 75.4 } },  -- Swift Olive Raptor
    [99] = { { npc = "Zjolnir", zone = "Durotar", m = 1, x = 55.2, y = 75.4 } },  -- Swift Orange Raptor
    [100] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Purple Skeletal Warhorse
    [101] = { { npc = "Harb Clawhoof", zone = "Mulgore", m = 7, x = 47.4, y = 58.2 } },  -- Great White Kodo
    [102] = { { npc = "Harb Clawhoof", zone = "Mulgore", m = 7, x = 47.4, y = 58.2 } },  -- Great Gray Kodo
    [103] = { { npc = "Harb Clawhoof", zone = "Mulgore", m = 7, x = 47.4, y = 58.2 } },  -- Great Brown Kodo
    [104] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Swift Brown Wolf
    [105] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Swift Timber Wolf
    [106] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Swift Gray Wolf
    [107] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Swift Stormsaber
    [108] = { { npc = "Jorek Ironside", zone = "Hillsbrad Foothills", m = 25, x = 58, y = 33.4 } },  -- Frostwolf Howler
    [109] = { { npc = "Thanthaldis Snowgleam", zone = "Hillsbrad Foothills", m = 25, x = 44.6, y = 46.4 } },  -- Stormpike Battle Charger
    [123] = { { npc = "Drake Dealer Hurlunk", zone = "Shadowmoon Valley, Outland", m = 104, x = 65.4, y = 85.8 } },  -- Nether Drake
    [125] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Riding Turtle
    [129] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Golden Gryphon
    [130] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Ebon Gryphon
    [131] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Snowy Gryphon
    [132] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Swift Blue Gryphon
    [133] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Tawny Wind Rider
    [134] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Blue Wind Rider
    [135] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Green Wind Rider
    [136] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Swift Red Wind Rider
    [137] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Swift Red Gryphon
    [138] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Swift Green Gryphon
    [139] = { { npc = "Tannec Stonebeak", zone = "Stormwind City", m = 84, x = 71.2, y = 72.6 } },  -- Swift Purple Gryphon
    [140] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Swift Green Wind Rider
    [141] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Swift Yellow Wind Rider
    [142] = { { npc = "Drakma", zone = "Orgrimmar", m = 85, x = 48, y = 58.4 } },  -- Swift Purple Wind Rider
    [145] = { { npc = "Milli Featherwhistle", zone = "Dun Morogh", m = 27, x = 56.2, y = 46.2 } },  -- Blue Mechanostrider
    [146] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Swift Pink Hawkstrider
    [147] = { { npc = "Torallius the Pack Handler", zone = "Azuremyst Isle", m = 103, x = 31, y = 27 } },  -- Brown Elekk
    [151] = { { npc = "Aldraan (Alliance)", zone = "Nagrand, Outland", m = 107, x = 42.8, y = 42.4 } },  -- Dark War Talbuk
    [152] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Red Hawkstrider
    [153] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- Cobalt War Talbuk
    [154] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- White War Talbuk
    [155] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- Silver War Talbuk
    [156] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- Tan War Talbuk
    [157] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Purple Hawkstrider
    [158] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Blue Hawkstrider
    [159] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Black Hawkstrider
    [160] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Swift Green Hawkstrider
    [161] = { { npc = "Winaestra", zone = "Eversong Woods (Burning Crusade)", m = 94, x = 61, y = 54.6 } },  -- Swift Purple Hawkstrider
    [162] = { { npc = "Raider Bork", zone = "Orgrimmar", m = 85, x = 41.4, y = 72.2 } },  -- Swift Warstrider
    [163] = { { npc = "Torallius the Pack Handler", zone = "Azuremyst Isle", m = 103, x = 31, y = 27 } },  -- Gray Elekk
    [164] = { { npc = "Torallius the Pack Handler", zone = "Azuremyst Isle", m = 103, x = 31, y = 27 } },  -- Purple Elekk
    [165] = { { npc = "Torallius the Pack Handler", zone = "Azuremyst Isle", m = 103, x = 31, y = 27 } },  -- Great Green Elekk
    [166] = { { npc = "Torallius the Pack Handler", zone = "Azuremyst Isle", m = 103, x = 31, y = 27 } },  -- Great Blue Elekk
    [167] = { { npc = "Torallius the Pack Handler", zone = "Azuremyst Isle", m = 103, x = 31, y = 27 } },  -- Great Purple Elekk
    [170] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- Cobalt Riding Talbuk
    [171] = { { npc = "Aldraan (Alliance)", zone = "Nagrand, Outland", m = 107, x = 42.8, y = 42.4 } },  -- Dark Riding Talbuk
    [172] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- Silver Riding Talbuk
    [173] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- Tan Riding Talbuk
    [174] = { { npc = "Provisioner Nasela", zone = "Nagrand, Outland", m = 107, x = 53.4, y = 36.8 } },  -- White Riding Talbuk
    [176] = { { npc = "Grella", zone = "Terokkar Forest, Outland", m = 108, x = 11.2, y = 39.2 } },  -- Green Riding Nether Ray
    [177] = { { npc = "Grella", zone = "Terokkar Forest, Outland", m = 108, x = 11.2, y = 39.2 } },  -- Red Riding Nether Ray
    [178] = { { npc = "Grella", zone = "Terokkar Forest, Outland", m = 108, x = 11.2, y = 39.2 } },  -- Purple Riding Nether Ray
    [179] = { { npc = "Grella", zone = "Terokkar Forest, Outland", m = 108, x = 11.2, y = 39.2 } },  -- Silver Riding Nether Ray
    [180] = { { npc = "Grella", zone = "Terokkar Forest, Outland", m = 108, x = 11.2, y = 39.2 } },  -- Blue Riding Nether Ray
    [196] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Spectral Tiger
    [197] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Swift Spectral Tiger
    [203] = { { npc = "Fedryen Swiftspear", zone = "Zangarmarsh, Outland", m = 102, x = 1, y = 48.8 } },  -- Cenarion War Hippogryph
    [211] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- X-51 Nether-Rocket
    [212] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- X-51 Nether-Rocket X-TREME
    [220] = { { npc = "Lieutenant Karter", zone = "Stormwind City", m = 84, x = 76.2, y = 65.4 } },  -- Black War Elekk
    [230] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Big Battle Bear
    [236] = { { npc = "Dread Commander Thalanor", zone = "Eastern Plaguelands", m = 646, x = 44, y = 62.6 } },  -- Winged Steed of the Ebon Blade
    [249] = { { npc = "Cielstrasza", zone = "Dragonblight", m = 115, x = 59.8, y = 53 } },  -- Red Drake
    [254] = { { npc = "Knight Dameron", zone = "Wintergrasp", m = 123, x = 42.2, y = 97 } },  -- Black War Mammoth
    [255] = { { npc = "Stone Guard Mukar", zone = "Wintergrasp", m = 1, x = 55.4, y = 11 } },  -- Black War Mammoth
    [256] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Wooly Mammoth
    [257] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Wooly Mammoth
    [258] = { { npc = "Lillehoff", zone = "The Storm Peaks", m = 120, x = 66, y = 61.4 } },  -- Ice Mammoth
    [259] = { { npc = "Lillehoff", zone = "The Storm Peaks", m = 120, x = 66, y = 61.4 } },  -- Ice Mammoth
    [269] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Armored Brown Bear
    [270] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Armored Brown Bear
    [276] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Armored Snowy Gryphon
    [277] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Armored Blue Wind Rider
    [278] = { { npc = "Geen", zone = "Sholazar Basin", m = 119, x = 54.6, y = 56.2 } },
    [280] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Traveler's Tundra Mammoth
    [284] = { { npc = "Mei Francis", zone = "Crystalsong Forest", m = 627, x = 57.4, y = 42.2 } },  -- Traveler's Tundra Mammoth
    [288] = { { npc = "Lillehoff", zone = "The Storm Peaks", m = 120, x = 66, y = 61.4 } },  -- Grand Ice Mammoth
    [289] = { { npc = "Lillehoff", zone = "The Storm Peaks", m = 120, x = 66, y = 61.4 } },  -- Grand Ice Mammoth
    [294] = { { npc = "Corporal Arthur Flew", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Stormwind Steed
    [295] = { { npc = "Samamba", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Darkspear Raptor
    [296] = { { npc = "Derrick Brindlebeard", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Ironforge Ram
    [297] = { { npc = "Rook Hawkfist", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Darnassian Nightsaber
    [298] = { { npc = "Rillie Spindlenut", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Gnomeregan Mechanostrider
    [299] = { { npc = "Irisee", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Exodar Elekk
    [300] = { { npc = "Freka Bloodaxe", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Orgrimmar Wolf
    [301] = { { npc = "Doru Thunderhorn", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Thunder Bluff Kodo
    [302] = { { npc = "Trellis Morningsun", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Silvermoon Hawkstrider
    [303] = { { npc = "Eliza Killian", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Forsaken Warhorse
    [305] = { { npc = "Faction Quartermasters", zone = "Argent Tournament, Icecrown" } },  -- Argent Hippogryph
    [309] = { { npc = "Harb Clawhoof", zone = "Mulgore", m = 7, x = 47.4, y = 58.2 } },  -- White Kodo
    [310] = { { npc = "Ogunaro Wolfrunner", zone = "Orgrimmar", m = 85, x = 61, y = 35.2 } },  -- Black Wolf
    [314] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Black Skeletal Horse
    [318] = { { npc = "Irisee", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Great Red Elekk
    [319] = { { npc = "Rook Hawkfist", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Swift Moonsaber
    [320] = { { npc = "Trellis Morningsun", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Swift Red Hawkstrider
    [321] = { { npc = "Corporal Arthur Flew", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Swift Gray Steed
    [322] = { { npc = "Doru Thunderhorn", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Great Golden Kodo
    [323] = { { npc = "Rillie Spindlenut", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Turbostrider
    [324] = { { npc = "Derrick Brindlebeard", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Swift Violet Ram
    [325] = { { npc = "Samamba", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Swift Purple Raptor
    [326] = { { npc = "Eliza Killian", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- White Skeletal Warhorse
    [327] = { { npc = "Freka Bloodaxe", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Swift Burgundy Wolf
    [328] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Magic Rooster
    [329] = { { npc = "Hiren Loresong", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Silver Covenant Hippogryph
    [330] = { { npc = "Vasarin Redmorn", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Sunreaver Dragonhawk
    [331] = { { npc = "Hiren Loresong", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Quel'dorei Steed
    [332] = { { npc = "Vasarin Redmorn", zone = "Icecrown", m = 118, x = 76.2, y = 19.6 } },  -- Sunreaver Hawkstrider
    [333] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Magic Rooster
    [334] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Magic Rooster
    [335] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Magic Rooster
    [336] = { { npc = "Zachariah Post", zone = "Tirisfal Glades", m = 18, x = 61.8, y = 51.8 } },  -- Ochre Skeletal Warhorse
    [337] = { { npc = "Lelanai", zone = "Darnassus", m = 89, x = 42.4, y = 32.4 } },  -- Striped Dawnsaber
    [338] = { { npc = "Dame Evniki Kapsalis", zone = "Icecrown", m = 118, x = 69.4, y = 23.2 } },  -- Argent Charger
    [341] = { { npc = "Dame Evniki Kapsalis", zone = "Icecrown", m = 118, x = 69.4, y = 23.2 } },  -- Argent Warhorse
    [371] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Blazing Hippogryph
    [372] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Wooly White Rhino
    [388] = { { npc = "Kall Worthaton", zone = "Orgrimmar", m = 85, x = 36, y = 86.4 } },  -- Goblin Trike
    [389] = { { npc = "Kall Worthaton", zone = "Orgrimmar", m = 85, x = 36, y = 86.4 } },  -- Goblin Turbo-Trike
    [394] = { { npc = "Quartermaster Brazie", zone = "Tol Barad Peninsula", m = 245, x = 72.4, y = 62.4 } },  -- Drake of the West Wind
    [398] = { { npc = "Blacksmith Abasi", zone = "Uldum", m = 249, x = 54, y = 33.2 } },  -- Brown Riding Camel
    [399] = { { npc = "Blacksmith Abasi", zone = "Uldum", m = 249, x = 54, y = 33.2 } },  -- Tan Riding Camel
    [401] = { { npc = "Guild Vendors", zone = "" } },  -- Dark Phoenix
    [403] = { { npc = "World Vendors", zone = "" } },  -- Golden King
    [405] = { { npc = "Quartermaster Brazie", zone = "Tol Barad Peninsula", m = 245, x = 72.4, y = 62.4 } },  -- Spectral Steed
    [406] = { { npc = "Pogg", zone = "Tol Barad Peninsula", m = 245, x = 54.4, y = 80.4 } },  -- Spectral Wolf
    [408] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Mottled Drake
    [409] = { { npc = "Goram", zone = "Orgrimmar", m = 85, x = 45, y = 5.6 } },  -- Kor'kron Annihilator
    [412] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Amani Dragonhawk
    [418] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Savage Raptor
    [422] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [423] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [426] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Swift Shorestrider
    [429] = { { npc = "Lhara", zone = "Darkmoon Island", m = 407, x = 48.2, y = 69.4 } },  -- Swift Forest Strider
    [430] = { { npc = "Noblegarden Merchant", zone = "Durotar, Eversong Woods (Burning Crusade), Mulgore, Tirisfal Glades, Azuremyst Isle,", m = 1305 } },  -- Swift Springstrider
    [431] = { { npc = "Lovely Merchant (Alliance)", zone = "Stormwind City", m = 1264 } },  -- Swift Lovebird
    [432] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- White Riding Camel
    [433] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Corrupted Hippogryph
    [434] = { { npc = "Lhara", zone = "Darkmoon Island", m = 407, x = 48.2, y = 69.4 } },  -- Darkmoon Dancing Bear
    [435] = { { npc = "Astrid Langstrump", zone = "Darnassus", m = 89, x = 48.2, y = 21.4 } },  -- Mountain Horse
    [436] = { { npc = "Astrid Langstrump", zone = "Darnassus", m = 89, x = 48.2, y = 21.4 } },  -- Swift Mountain Horse
    [447] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Feldrake
    [449] = { { npc = "Nat Pagle", zone = "Krasarang Wilds", m = 418 } },  -- Azure Water Strider
    [452] = {  -- Green Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [453] = {  -- Great Red Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [460] = { { npc = "Uncle Bigpocket", zone = "Kun-Lai Summit", m = 379, x = 65.4, y = 61.6 } },  -- Grand Expedition Yak
    [463] = { { npc = "Ambersmith Zikk", zone = "Dread Wastes", m = 422, x = 55, y = 35.4 } },  -- Amber Scorpion
    [466] = { { npc = "Shay Pressler (Alliance)", zone = "Stormwind City", m = 84, x = 64.2, y = 77 } },  -- Thundering Jade Cloud Serpent
    [475] = { { npc = "Mistweaver Ku", zone = "Timeless Isle", m = 554 } },  -- Heavenly Golden Cloud Serpent
    [476] = { { npc = "Mistweaver Xia", zone = "Timeless Isle", m = 554, x = 43, y = 55.4 } },  -- Yu'lei, Daughter of Jade
    [479] = {  -- Azure Riding Crane
        { npc = "Jaluu the Generous", zone = "Vale of Eternal Blossoms", faction = "Horde", m = 390, x = 63, y = 22.2 },
        { npc = "Jaluu the Generous", zone = "Vale of Eternal Blossoms", faction = "Alliance", m = 390, x = 84, y = 63 },
    },
    [480] = {  -- Golden Riding Crane
        { npc = "Jaluu the Generous", zone = "Vale of Eternal Blossoms", faction = "Horde", m = 390, x = 63, y = 22.2 },
        { npc = "Jaluu the Generous", zone = "Vale of Eternal Blossoms", faction = "Alliance", m = 390, x = 84, y = 63 },
    },
    [481] = {  -- Regal Riding Crane
        { npc = "Jaluu the Generous", zone = "Vale of Eternal Blossoms", faction = "Horde", m = 390, x = 63, y = 22.2 },
        { npc = "Jaluu the Generous", zone = "Vale of Eternal Blossoms", faction = "Alliance", m = 390, x = 84, y = 63 },
    },
    [486] = { { npc = "Uncle Bigpocket", zone = "Kun-Lai Summit", m = 379, x = 65.4, y = 61.6 } },  -- Grey Riding Yak
    [487] = { { npc = "Uncle Bigpocket", zone = "Kun-Lai Summit", m = 379, x = 65.4, y = 61.6 } },  -- Blonde Riding Yak
    [488] = { { npc = "Nat Pagle", zone = "Krasarang Wilds", m = 418, x = 68.4, y = 43.6 } },  -- Crimson Water Strider
    [492] = {  -- Black Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [493] = {  -- Blue Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [494] = {  -- Brown Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [495] = {  -- Purple Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [496] = {  -- Red Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [497] = {  -- Great Green Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [498] = {  -- Great Black Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [499] = {  -- Great Blue Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [500] = {  -- Great Brown Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [501] = {  -- Great Purple Dragon Turtle
        { npc = "Turtlemaster Odai", zone = "Orgrimmar", m = 1637, x = 69.4, y = 41.2 },
        { npc = "Old Whitenose", zone = "Stormwind City", m = 1519, x = 67.8, y = 18.4 },
    },
    [503] = { { npc = "Kai Featherfall", zone = "Vale of Eternal Blossoms", m = 390, x = 82.2, y = 34 } },  -- Crimson Pandaren Phoenix
    [504] = { { npc = "Sage Whiteheart (Alliance)", zone = "Vale of Eternal Blossoms", m = 390, x = 84.6, y = 63.4 } },  -- Thundering August Cloud Serpent
    [505] = { { npc = "Rushi the Fox", zone = "Townlong Steppes", m = 388, x = 48.8, y = 70.4 } },  -- Green Shado-Pan Riding Tiger
    [506] = { { npc = "Rushi the Fox", zone = "Townlong Steppes", m = 388, x = 48.8, y = 70.4 } },  -- Blue Shado-Pan Riding Tiger
    [507] = { { npc = "Rushi the Fox", zone = "Townlong Steppes", m = 388, x = 48.8, y = 70.4 } },  -- Red Shado-Pan Riding Tiger
    [508] = { { npc = "Gina Mudclaw", zone = "Valley of the Four Winds", m = 376, x = 52.2, y = 48.6 } },  -- Brown Riding Goat
    [509] = { { npc = "Tan Shin Tiao", zone = "Vale of Eternal Blossoms", m = 390, x = 82.2, y = 29.4 } },  -- Red Flying Cloud
    [510] = { { npc = "Gina Mudclaw", zone = "Timeless Isle", m = 376, x = 52.2, y = 48.6 } },  -- White Riding Goat
    [511] = { { npc = "Gina Mudclaw", zone = "Timeless Isle", m = 376, x = 52.2, y = 48.6 } },  -- Black Riding Goat
    [518] = { { npc = "World Vendors", zone = "" } },  -- Ashen Pandaren Phoenix
    [519] = { { npc = "World Vendors", zone = "" } },  -- Emerald Pandaren Phoenix
    [520] = { { npc = "World Vendors", zone = "" } },  -- Violet Pandaren Phoenix
    [526] = { { npc = "Agent Malley", zone = "Krasarang Wilds", m = 418, x = 89.4, y = 33.4 } },  -- Grand Armored Gryphon
    [527] = { { npc = "Tuskripper Grukna", zone = "Krasarang Wilds", m = 418, x = 9.6, y = 50.8 } },  -- Grand Armored Wyvern
    [532] = { { npc = "Landro Longshot", zone = "Booty Bay", m = 210, x = 42.4, y = 71.4 } },  -- Ghastly Charger
    [545] = { { npc = "Hiren Loresong", zone = "Isle of Thunder", m = 118, x = 76.2, y = 19.6 } },  -- Golden Primal Direhorn
    [546] = { { npc = "Vasarin Redmorn", zone = "Isle of Thunder", m = 118, x = 76.2, y = 19.6 } },  -- Crimson Primal Direhorn
    [550] = { { npc = "Paul North", zone = "Brawl'gar Arena", m = 418, x = 48.4, y = 29.2 } },  -- Brawler's Burly Mushan Beast
    [552] = { { npc = "Auzin", zone = "Dalaran", m = 84, x = 49.2, y = 46.4 } },  -- Ironbound Wraithcharger
    [554] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious Kaldorei Warsaber
    [555] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious Skeletal Warhorse
    [560] = { { npc = "Speaker Gulan", zone = "Timeless Isle", m = 554, x = 74.6, y = 44.4 } },  -- Ashhide Mushan Beast
    [608] = { { npc = "Trader Araanda", zone = "Lunarfall" } },  -- Witherhide Cliffstomper
    [617] = { { npc = "Vindicator Nuurem", zone = "Stormshield", m = 588 } },  -- Dusty Rockhide
    [618] = { { npc = "", zone = "Garrison Trading Post" } },  -- Armored Irontusk
    [620] = { { npc = "Trader Araanda", zone = "Lunarfall" } },  -- Rocktusk Battleboar
    [624] = { { npc = "Z'tenga the Walker", zone = "Tanaan Jungle", m = 534, x = 55.2, y = 74.8 } },  -- Wild Goretusk
    [625] = { { npc = "Gazrix Gearlock / Mimi Wizzlebub", zone = "Stormshield / Warspear", m = 2112, x = 47.2, y = 41.4 } },  -- Domesticated Razorback
    [632] = { { npc = "Dawn-Seeker Krek / Dawn-Seeker Alkset", zone = "Stormshield / Warspear" } },  -- Mosshide Riverwallow
    [635] = { { npc = "Ravenspeaker Skeega / Shadow-Sage Brakoss", zone = "Stormshield / Warspear" } },  -- Shadowmane Charger
    [638] = { { npc = "Dazzerian", zone = "Warspear", m = 1355, x = 48.8, y = 60.8 } },  -- Breezestrider Stallion
    [639] = { { npc = "Crafticus Mindbender", zone = "Stormshield", m = 588 } },  -- Pale Thorngrazer
    [640] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Ram
    [641] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Raptor
    [645] = { { npc = "Kil'rip", zone = "Horde Garrison Trading Post" } },  -- Ironside Warwolf
    [648] = { { npc = "Beska Redtusk", zone = "Warspear", m = 624, x = 53.2, y = 61 } },  -- Swift Frostwolf
    [652] = { { npc = "Paulie", zone = "Stormwind, Old Town", m = 84, x = 73, y = 59.2 } },  -- Champion's Treadblade
    [663] = { { npc = "The Mad Merchant", zone = "", m = 627, x = 43.2, y = 46.4 } },  -- Bloodfang Widow
    [753] = { { npc = "Dawn-Seeker Krisek", zone = "Tanaan Jungle", m = 534, x = 57.8, y = 59.4 } },  -- Corrupted Dreadwing
    [755] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Mechanostrider
    [756] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Kodo
    [765] = { { npc = "Z'tenga the Walker", zone = "Tanaan Jungle", m = 534, x = 55.2, y = 74.8 } },  -- Bristling Hellboar
    [768] = { { npc = "Shadow Hunter Denjai", zone = "Tanaan Jungle", m = 534, x = 61.6, y = 45.6 } },  -- Deathtusk Felboar
    [778] = { { npc = "Cupri", zone = "Shattrath City", m = 111, x = 54.4, y = 38.4 } },  -- Eclipse Dragonhawk
    [800] = { { npc = "Conjurer Margoss", zone = "Dalaran", m = 627, x = 44.6, y = 62 } },  -- Brinedeep Bottom-Feeder
    [841] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious Gilnean Warhorse
    [842] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Trike
    [843] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious Warstrider
    [844] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Elekk
    [847] = { { npc = "Xur'ios", zone = "", m = 627, x = 48.4, y = 14 } },  -- Arcadian War Turtle
    [855] = { { npc = "Galissa Sundew", zone = "Darkmoon Island", m = 407, x = 52.4, y = 88.4 } },  -- Darkwater Skate
    [870] = { { npc = "Pan the Kind Hand", zone = "Trueshot Lodge", m = 739, x = 58.4, y = 32 } },  -- Huntmaster's Fierce Wolfhawk
    [872] = { { npc = "Pan the Kind Hand", zone = "Trueshot Lodge", m = 739, x = 58.4, y = 32 } },  -- Huntmaster's Dire Wolfhawk
    [873] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Bear
    [874] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Bear
    [876] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Lion
    [877] = { { npc = "Trinket", zone = "Highmountain", m = 650, x = 32.4, y = 66.8 } },  -- Ivory Hawkstrider
    [878] = { { npc = "Quackenbush", zone = "Deeprun Tram" } },  -- Brawler's Burly Basilisk
    [882] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Scorpion
    [889] = { { npc = "Zan Shivsproket", zone = "Dalaran", m = 627, x = 40.4, y = 78.6 } },  -- Shadowblade's Lethal Omen
    [890] = { { npc = "Zan Shivsproket", zone = "Dalaran", m = 627, x = 40.4, y = 78.6 } },  -- Shadowblade's Baneful Omen
    [891] = { { npc = "Zan Shivsproket", zone = "Dalaran", m = 627, x = 40.4, y = 78.6 } },  -- Shadowblade's Crimson Omen
    [892] = { { npc = "Crusader Lord Dalfors", zone = "Sanctum of Light", m = 646, x = 51.4, y = 73.4 } },  -- Highlord's Vengeful Charger
    [893] = { { npc = "Crusader Lord Dalfors", zone = "Sanctum of Light", m = 646, x = 51.4, y = 73.4 } },  -- Highlord's Vigilant Charger
    [894] = { { npc = "Crusader Lord Dalfors", zone = "Sanctum of Light", m = 646, x = 51.4, y = 73.4 } },  -- Highlord's Valorous Charger
    [900] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Turtle
    [901] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Turtle
    [926] = { { npc = "Hoarder Jena", zone = "Vol'dun", m = 864, x = 56.6, y = 49.8 } },  -- Alabaster Hyena
    [930] = { { npc = "Calydus", zone = "Dreadscar Rift", m = 627, x = 54.4, y = 63 } },  -- Netherlord's Brimstone Wrathsteed
    [932] = { { npc = "Vindicator Jaelaana", zone = "Argus", m = 2248, x = 34.2, y = 63.6 } },  -- Lightforged Warframe
    [939] = { { npc = "Toraan the Revered", zone = "Argus", m = 882, x = 55.4, y = 28.6 } },  -- Sable Ruinstrider
    [945] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Fox
    [946] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Fox
    [958] = { { npc = "Natal'hakata", zone = "Zuldazar", m = 862, x = 57.4, y = 44.4 } },  -- Spectral Pterrorwing
    [962] = { { npc = "Lhara", zone = "Darkmoon Island", m = 407, x = 48.2, y = 69.4 } },  -- Darkmoon Dirigible
    [964] = { { npc = "Toraan the Revered", zone = "Argus", m = 882, x = 55.4, y = 28.6 } },  -- Amethyst Ruinstrider
    [965] = { { npc = "Toraan the Revered", zone = "Argus", m = 882, x = 55.4, y = 28.6 } },  -- Cerulean Ruinstrider
    [966] = { { npc = "Toraan the Revered", zone = "Argus", m = 882, x = 55.4, y = 28.6 } },  -- Beryl Ruinstrider
    [967] = { { npc = "Toraan the Revered", zone = "Argus", m = 882, x = 55.4, y = 28.6 } },  -- Umber Ruinstrider
    [968] = { { npc = "Toraan the Revered", zone = "Argus", m = 882, x = 55.4, y = 28.6 } },  -- Russet Ruinstrider
    [1010] = { { npc = "Provisioner Fray", zone = "Tiragarde Sound", m = 84, x = 56, y = 17.4 } },  -- Admiralty Stallion
    [1012] = { { npc = "Gottum", zone = "Nazmir", m = 863, x = 70.8, y = 56.4 } },  -- Green Marsh Hopper
    [1015] = { { npc = "Sister Lilyana", zone = "Stormsong Valley", m = 942, x = 59.2, y = 69.4 } },  -- Dapple Gray
    [1016] = { { npc = "Quartermaster Alcorn", zone = "Drustvar", m = 896, x = 37.8, y = 49 } },  -- Smoky Charger
    [1026] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Basilisk
    [1027] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Basilisk
    [1039] = { { npc = "Talutu", zone = "Zuldazar", m = 1165, x = 48.4, y = 87.2 } },  -- Mighty Caravan Brutosaur
    [1042] = { { npc = "Captain Klarisa", zone = "Tiragarde Sound", m = 895, x = 66.2, y = 32.4 } },  -- Siltwing Albatross
    [1045] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious War Clefthoof
    [1050] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious War Riverbeast
    [1058] = { { npc = "Natal'hakata", zone = "Zuldazar", m = 862, x = 57.4, y = 44.4 } },  -- Cobalt Pterrordax
    [1059] = { { npc = "Provisioner Lija", zone = "Nazmir", m = 863, x = 39, y = 79.4 } },  -- Captured Swampstalker
    [1060] = { { npc = "Hoarder Jena", zone = "Vol'dun", m = 864, x = 56.6, y = 49.8 } },  -- Voldunai Dunescraper
    [1061] = { { npc = "Provisioner Lija", zone = "Nazmir", m = 863, x = 39, y = 79.4 } },  -- Expedition Bloodswarmer
    [1062] = { { npc = "Quartermaster Alcorn", zone = "Drustvar", m = 896, x = 37.8, y = 49 } },  -- Dusky Waycrest Gryphon
    [1063] = { { npc = "Sister Lilyana", zone = "Stormsong Valley", m = 942, x = 59.2, y = 69.4 } },  -- Stormsong Coastwatcher
    [1064] = { { npc = "Provisioner Fray", zone = "Tiragarde Sound", m = 84, x = 56, y = 17.4 } },  -- Proudmoore Sea Scout
    [1179] = { { npc = "Talutu", zone = "Zuldazar", m = 1165, x = 48.4, y = 87.2 } },  -- Palehide Direhorn
    [1194] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious White Warsaber
    [1195] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },  -- Vicious Black Warsaber
    [1196] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious Black Bonesteed
    [1197] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },  -- Vicious White Bonesteed
    [1204] = { { npc = "Provisioner Stoutforge", zone = "Tiragarde Sound", m = 895, x = 66.8, y = 25.4 } },  -- Sandy Nightsaber
    [1206] = { { npc = "Gottum", zone = "Nazmir", m = 863, x = 70.8, y = 56.4 } },  -- Blue Marsh Hopper
    [1207] = { { npc = "Gottum", zone = "Nazmir", m = 863, x = 70.8, y = 56.4 } },  -- Yellow Marsh Hopper
    [1208] = { { npc = "Captain Klarisa", zone = "Tiragarde Sound", m = 895, x = 66.2, y = 32.4 } },  -- Saltwater Seahorse
    [1210] = { { npc = "Provisioner Mukra", zone = "Zuldazar", m = 1165, x = 51.2, y = 95.2 } },  -- Bloodthirsty Dreadwing
    [1214] = { { npc = "Provisioner Stoutforge", zone = "Tiragarde Sound", m = 895, x = 66.8, y = 25.4 } },  -- Azureshell Krolusk
    [1215] = { { npc = "Provisioner Mukra", zone = "Zuldazar", m = 1165, x = 51.2, y = 95.2 } },  -- Rubyshell Krolusk
    [1216] = { { npc = "Provisioner Stoutforge", zone = "Tiragarde Sound", m = 895, x = 66.8, y = 25.4 } },  -- Priestess' Moonsaber
    [1230] = { { npc = "Finder Pruc", zone = "Nazjatar", m = 1355, x = 49, y = 62.2 } },  -- Unshackled Waveray
    [1231] = { { npc = "Artisan Okata", zone = "Nazjatar", m = 1355, x = 37.8, y = 55.6 } },  -- Ankoan Waveray
    [1239] = { { npc = "Pascal-K1N6", zone = "Mechagon", m = 1462, x = 71.4, y = 32.4 } },  -- X-995 Mechanocat
    [1242] = { { npc = "Kronnus", zone = "Warspear", m = 624, x = 42.4, y = 54.6 } },  -- Beastlord's Irontusk
    [1243] = { { npc = "Kronnus", zone = "Warspear", m = 624, x = 42.4, y = 54.6 } },  -- Beastlord's Warwolf
    [1254] = { { npc = "Stolen Royal Vendorbot", zone = "Mechagon", m = 1462, x = 73.6, y = 36.4 } },  -- Rustbolt Resistor
    [1260] = { { npc = "Mrrl", zone = "Nazjatar", m = 1355 } },  -- Crimson Tidestallion
    [1262] = { { npc = "Crafticus Mindbender", zone = "Nazjatar", m = 1355 } },  -- Inkscale Deepseeker
    [1313] = { { npc = "Zhang Ku", zone = "Vale of Eternal Blossoms", m = 1530, x = 44.4, y = 75.2 } },  -- Rajani Warserpent
    [1318] = { { npc = "Provisioner Qorra", zone = "Uldum", m = 1527, x = 55, y = 32.8 } },  -- Wastewander Skyterror
    [1321] = { { npc = "Torie", zone = "Dornogal", m = 2339, x = 34.2, y = 68.4 } },  -- Wicked Swarmer
    [1332] = { { npc = "Master Clerk Salorn", zone = "Ardenweald", m = 1565, x = 43, y = 47 } },  -- Silky Shimmermoth
    [1351] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1352] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1361] = { { npc = "Aithlyn", zone = "Ardenweald", m = 1565, x = 48.4, y = 50.4 } },  -- Duskflutter Ardenmoth
    [1369] = { { npc = "Su Zettai", zone = "Maldraxxus", m = 1741 } },  -- Armored Plaguerot Tauralus
    [1374] = { { npc = "Collector Ta'Steld", zone = "Oribos", m = 1670, x = 55.2, y = 63.4 } },  -- Bonecleaver's Skullboar
    [1375] = { { npc = "Nalcorn Talsen", zone = "Maldraxxus", m = 1536, x = 50.6, y = 53.4 } },  -- Lurid Bloodtusk
    [1420] = { { npc = "Spindlenose", zone = "Ardenweald", m = 1565, x = 59.4, y = 52.8 } },  -- Umbral Scythehorn
    [1421] = { { npc = "Mistress Mihaela", zone = "Revendreth", m = 1525, x = 61.4, y = 63.8 } },  -- Court Sinrunner
    [1425] = { { npc = "Adjutant Nikos", zone = "Bastion", m = 1533, x = 52.2, y = 47 } },  -- Gilded Prowler
    [1429] = { { npc = "Cortinarius", zone = "Ardenweald", m = 1565, x = 29.4, y = 34.8 } },  -- Vibrant Flutterwing
    [1436] = { { npc = "Duchess Mynx", zone = "Korthia", m = 1961, x = 63.4, y = 23.4 } },  -- Battle-Hardened Aquilon
    [1450] = { { npc = "Archivist Roh-Suir", zone = "Korthia", m = 1961, x = 61.4, y = 21.8 } },  -- Soaring Razorwing
    [1451] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1452] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1459] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1460] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1465] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1466] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1467] = { { npc = "Storykeeper Ashekh", zone = "The Forbidden Reach", m = 2151, x = 34, y = 59.8 } },  -- Noble Bruffalon
    [1478] = { { npc = "Brendormi", zone = "", m = 2025, x = 61.2, y = 47 } },  -- Skyskin Hornstrider
    [1485] = { { npc = "Elwyn", zone = "Ardenweald", m = 1565, x = 59.2, y = 34.6 } },  -- Autumnal Wilderling
    [1486] = { { npc = "Duchess Mynx", zone = "Korthia", m = 1961, x = 63.4, y = 23.4 } },  -- Winter Wilderling
    [1489] = { { npc = "Chachi the Artiste", zone = "Revendreth", m = 1525, x = 53.4, y = 24.4 } },  -- Obsidian Gravewing
    [1491] = { { npc = "Duchess Mynx", zone = "Korthia", m = 1961, x = 63.4, y = 23.4 } },  -- Pale Gravewing
    [1494] = { { npc = "Adjutant Galos", zone = "Bastion", m = 1533, x = 67.4, y = 15 } },  -- Ascendant's Aquilon
    [1496] = { { npc = "Su Zettai", zone = "Maldraxxus", m = 1741 } },  -- Regal Corpsefly
    [1497] = { { npc = "Duchess Mynx", zone = "Korthia", m = 1961, x = 63.4, y = 23.4 } },  -- Battlefield Swarmer
    [1505] = { { npc = "Duchess Mynx", zone = "Korthia", m = 1961, x = 63.4, y = 23.4 } },  -- Amber Shardhide
    [1521] = { { npc = "Aridormi", zone = "Dalaran", m = 627, x = 68.4, y = 48.4 } },  -- Val'sharah Hippogryph
    [1522] = { { npc = "Vilo", zone = "Zereth Mortis", m = 1970, x = 34.8, y = 64.2 } },  -- Heartlight Vombata
    [1529] = { { npc = "Vilo", zone = "Zereth Mortis", m = 1970, x = 34.8, y = 64.2 } },  -- Anointed Protostag
    [1546] = { { npc = "Tattukiaka", zone = "The Azure Span", m = 2024, x = 14, y = 49.6 } },  -- Iskaara Trader's Ottuk
    [1578] = { { npc = "Uncle Bigpocket", zone = "Kun-Lai Summit", m = 379, x = 65.4, y = 61.6 } },  -- [DND] Test Mount JZB
    [1603] = { { npc = "Sacratros", zone = "Zaralek Cavern", m = 2133, x = 55.8, y = 55.4 } },  -- Subterranean Magmammoth
    [1612] = { { npc = "Yries Lightfingers", zone = "The Waking Shores", m = 2022, x = 26.4, y = 55.4 } },  -- Loyal Magmammoth
    [1615] = { { npc = "Granpap Whiskers", zone = "Dragonscale Basecamp", m = 2022, x = 47.6, y = 83.2 } },  -- Tamed Skitterfly
    [1616] = { { npc = "Granpap Whiskers", zone = "Dragonscale Basecamp", m = 2022, x = 47.6, y = 83.2 } },  -- Azure Skitterfly
    [1622] = { { npc = "Mythressa", zone = "", m = 2112, x = 38, y = 37.4 } },  -- Stormhide Salamanther
    [1629] = { { npc = "Dealer Vexil", zone = "The Waking Shores", m = 2022, x = 34.8, y = 46.6 } },  -- Scrappy Worldsnail
    [1638] = { { npc = "Provisioner Aristta", zone = "Thaldraszus", m = 2024, x = 27, y = 46.4 } },  -- Explorer's Stonehide Packbeast
    [1653] = { { npc = "Tatto", zone = "Iskaara", m = 2024, x = 13.2, y = 48.8 } },  -- Brown War Ottuk
    [1655] = { { npc = "Tatto", zone = "Iskaara", m = 2024, x = 13.2, y = 48.8 } },  -- Yellow War Ottuk
    [1657] = { { npc = "Tatto", zone = "Iskaara", m = 2024, x = 13.2, y = 48.8 } },  -- Brown Scouting Ottuk
    [1658] = { { npc = "Tattukiaka", zone = "The Azure Span", m = 2024, x = 14, y = 49.6 } },  -- Ivory Trader's Ottuk
    [1659] = { { npc = "Tatto", zone = "Iskaara", m = 2024, x = 13.2, y = 48.8 } },  -- Yellow Scouting Ottuk
    [1664] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Guardian Vorquin
    [1665] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Swift Armored Vorquin
    [1667] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Armored Vorquin Leystrider
    [1668] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Majestic Armored Vorquin
    [1671] = { { npc = "Celestine of the Harvest", zone = "The Waking Shores", m = 2022, x = 64, y = 41.6 } },  -- Duskwing Ohuna
    [1674] = { { npc = "Zon'Wogi", zone = "The Azure Span", m = 2024, x = 19, y = 24 } },  -- Temperamental Skyclaw
    [1683] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Crimson Vorquin
    [1684] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Sapphire Vorquin
    [1685] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Bronze Vorquin
    [1686] = { { npc = "Tethalash", zone = "Valdrakken", m = 13862, x = 25.6, y = 33.8 } },  -- Obsidian Vorquin
    [1688] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1689] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1730] = { { npc = "Saccratros", zone = "Zaralek Cavern", m = 2133, x = 55.8, y = 55.4 } },  -- Igneous Shalewing
    [1736] = { { npc = "Ponzo", zone = "Zaralek Cavern", m = 2133, x = 58, y = 53.8 } },  -- Boulder Hauler
    [1737] = { { npc = "Any Timewalking Vendor", zone = "" } },  -- Sandy Shalewing
    [1738] = { { npc = "Harlowe Marl", zone = "Zaralek Cavern", m = 2601, x = 56, y = 55 } },  -- Morsel Sniffer
    [1740] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1741] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1776] = { { npc = "Warden Krizzik", zone = "Tyrhold Reservoir", m = 2025, x = 51, y = 56.6 } },  -- White War Wolf
    [1777] = { { npc = "Warden Krizzik", zone = "Tyrhold Reservoir", m = 2025, x = 51, y = 56.6 } },  -- Ravenous Black Gryphon
    [1778] = { { npc = "Sorotis", zone = "Tyrhold Reservoir", m = 2112, x = 25.8, y = 40 } },  -- Gold-Toed Albatross
    [1779] = { { npc = "Falara Nightsong", zone = "Tyrhold Reservoir", m = 2025, x = 51, y = 56.6 } },  -- Felstorm Dragon
    [1781] = { { npc = "Provisioner Qorra", zone = "Tyrhold Reservoir", m = 1527, x = 55, y = 32.8 } },  -- Sulfur Hound
    [1782] = { { npc = "Gill the Drill", zone = "Tyrhold Reservoir", m = 2025, x = 51, y = 56.6 } },  -- Perfected Juggernaut
    [1783] = { { npc = "Baron Silver", zone = "Tyrhold Reservoir", m = 210, x = 30.4, y = 77.3 } },  -- Scourgebound Vanquisher
    [1808] = { { npc = "Talisa Whisperbloom", zone = "Emerald Dream", m = 2200, x = 49.8, y = 62 } },  -- Blossoming Dreamstag
    [1809] = { { npc = "Moon Priestess Lasara", zone = "Emerald Dream", m = 2200, x = 50, y = 62 } },  -- Suntouched Dreamstag
    [1810] = { { npc = "Talisa Whisperbloom", zone = "Emerald Dream", m = 2200, x = 49.8, y = 62 } },  -- Rekindled Dreamstag
    [1811] = { { npc = "Moon Priestess Lasara", zone = "Emerald Dream", m = 2200, x = 50, y = 62 } },  -- Lunar Dreamstag
    [1816] = { { npc = "Talisa Whisperbloom", zone = "Emerald Dream", m = 2200, x = 49.8, y = 62 } },  -- Evening Sun Dreamsaber
    [1817] = { { npc = "Talisa Whisperbloom", zone = "Emerald Dream", m = 2200, x = 49.8, y = 62 } },  -- Morning Flourish Dreamsaber
    [1819] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [1820] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [1833] = { { npc = "Talisa Whisperbloom", zone = "Emerald Dream", m = 2200, x = 49.8, y = 62 } },  -- Springtide Dreamtalon
    [1835] = { { npc = "Talisa Whisperbloom", zone = "Emerald Dream", m = 2200, x = 49.8, y = 62 } },  -- Snowfluff Dreamtalon
    [1837] = { { npc = "Elianna", zone = "Emerald Dream", m = 2200, x = 50.2, y = 61.8 } },  -- Delugen
    [1838] = { { npc = "Elianna", zone = "Emerald Dream", m = 2200, x = 50.2, y = 61.8 } },  -- Talont
    [1839] = { { npc = "Elianna", zone = "Emerald Dream", m = 2200, x = 50.2, y = 61.8 } },  -- Stargrazer
    [1938] = { { npc = "Elianna", zone = "Emerald Dream", m = 2200, x = 50.2, y = 61.8 } },  -- Mammyth
    [1939] = { { npc = "Elianna", zone = "Emerald Dream", m = 2200, x = 50.2, y = 61.8 } },  -- Imagiwing
    [1940] = { { npc = "Elianna", zone = "Emerald Dream", m = 2200, x = 50.2, y = 61.8 } },  -- Salatrancer
    [2056] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [2057] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [2116] = { { npc = "Remembrancer Amuul", zone = "Dalaran", m = 627, x = 32.4, y = 82.4 } },  -- Remembered Golden Gryphon
    [2117] = { { npc = "Remembrancer Amuul", zone = "Dalaran", m = 627, x = 32.4, y = 82.4 } },  -- Remembered Wind Rider
    [2148] = { { npc = "Auditor Balwurz", zone = "Dornogal", m = 2339, x = 39.2, y = 24.2 } },  -- Smoldering Cinderbee
    [2150] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [2161] = { { npc = "Mothkeeper Wew'tam", zone = "Harandar", m = 2413, x = 49.3, y = 54.3 } },  -- Elder Glowmite
    [2162] = { { npc = "Waxmonger Squick", zone = "The Ringing Deeps", m = 2214, x = 43.2, y = 32.8 } },  -- Cyan Glowmite
    [2165] = { { npc = "Cendvin", zone = "The Isle of Dorn", m = 2248, x = 74.4, y = 45.2 } },  -- Soaring Meaderbee
    [2177] = { { npc = "Lady Vinazian", zone = "Azj-Kahet", m = 2255, x = 55.2, y = 41.2 } },  -- Aquamarine Swarmite
    [2184] = { { npc = "Lady Vinazian", zone = "Azj-Kahet", m = 2255, x = 55.2, y = 41.2 } },  -- Ferocious Jawcrawler
    [2191] = { { npc = "Auralia Steelstrike", zone = "Hallowfall", m = 2215, x = 42.6, y = 49.8 } },  -- Shackled Shadow
    [2193] = { { npc = "Auralia Steelstrike", zone = "Hallowfall", m = 2215, x = 42.6, y = 49.8 } },  -- Vermillion Imperial Lynx
    [2209] = { { npc = "Waxmonger Squick", zone = "The Ringing Deeps", m = 2214, x = 43.2, y = 32.8 } },  -- Crimson Mudnose
    [2211] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [2213] = { { npc = "Auditor Balwurz", zone = "Dornogal", m = 2339, x = 39.2, y = 24.2 } },  -- Shale Ramolith
    [2220] = { { npc = "Materialist Ophinell", zone = "Twilight Highlands", m = 241, x = 49.8, y = 81.2 } },  -- Retrained Skyrazor
    [2224] = { { npc = "Bobadormu", zone = "Tanaris", m = 85, x = 52.8, y = 82.4 } },  -- Frayfeather Hippogryph
    [2225] = { { npc = "Cupri", zone = "Shattrath City", m = 111, x = 54.4, y = 38.4 } },  -- Amani Hunting Bear
    [2272] = { { npc = "Rocco Razzboom", zone = "Undermine", m = 2346, x = 39, y = 22 } },  -- Crimson Armored Growler
    [2276] = { { npc = "Ando the Gat", zone = "Liberation of Undermine", m = 2346 } },  -- Darkfuse Chompactor
    [2277] = { { npc = "Smaks Topskimmer", zone = "Undermine", m = 2346, x = 43.6, y = 50.2 } },  -- Violet Armored Growler
    [2278] = { { npc = "Ando the Gat", zone = "Liberation of Undermine", m = 2346 } },  -- Flarendo the Furious
    [2279] = { { npc = "Ando the Gat", zone = "Liberation of Undermine", m = 2346 } },  -- Thunderdrum Misfire
    [2280] = { { npc = "Smaks Topskimmer", zone = "Undermine", m = 2346, x = 43.6, y = 50.2 } },  -- The Topskimmer Special
    [2283] = { { npc = "Skedgit Cinderbangs", zone = "Undermine", m = 2346, x = 43, y = 82.2 } },  -- Innovation Investigator
    [2284] = { { npc = "Shredz the Scrapper", zone = "Undermine", m = 2346, x = 53.2, y = 72.4 } },  -- Ochre Delivery Rocket
    [2286] = { { npc = "Boatswain Hardee", zone = "Undermine", m = 2346, x = 63.2, y = 16.2 } },  -- Blackwater Shredder Deluxe Mk 2
    [2287] = { { npc = "Sitch Lowdown", zone = "Undermine", m = 2346, x = 30.4, y = 38.8 } },  -- Darkfuse Demolisher
    [2290] = { { npc = "Skedgit Cinderbangs", zone = "Undermine", m = 2346, x = 43, y = 82.2 } },  -- Asset Advocator
    [2292] = { { npc = "Skedgit Cinderbangs", zone = "Undermine", m = 2346, x = 43, y = 82.2 } },  -- Margin Manipulator
    [2294] = { { npc = "Lab Assistant Laszly", zone = "Undermine", m = 2346, x = 27.2, y = 72.4 } },  -- Mean Green Flying Machine
    [2299] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [2300] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [2317] = { { npc = "Auzin", zone = "Dalaran", m = 84, x = 49.2, y = 46.4 } },  -- Enchanted Spellweave Carpet
    [2321] = { { npc = "Any Timewalking Vendor", zone = "" } },  -- Timely Buzzbee
    [2327] = { { npc = "Lunar Festival Vendor", zone = "" } },  -- Lunar Launcher
    [2333] = { { npc = "Soweezi", zone = "Siren Isle", m = 2369, x = 70, y = 48.6 } },  -- Soweezi's Vintage Waveshredder
    [2470] = { { npc = "Kronnus", zone = "Warspear", m = 624, x = 42.4, y = 54.6 } },  -- Nightfall Skyreaver
    [2471] = { { npc = "Aridormi", zone = "Dalaran", m = 627, x = 68.4, y = 48.4 } },  -- Ur'zul Fleshripper
    [2473] = { { npc = "Kiatke", zone = "Stormwind City", m = 84, x = 76, y = 17.4 } },  -- Broodling of Sinestra
    [2474] = { { npc = "Mistweaver Xia", zone = "Timeless Isle", m = 554, x = 43, y = 55.4 } },  -- Copper-Maned Quilen
    [2501] = { { npc = "Torie", zone = "Dornogal", m = 2339, x = 34.2, y = 68.4 } },  -- Corruption of the Aspects
    [2510] = { { npc = "Om'sirik", zone = "K'aresh", m = 2472, x = 40.6, y = 29.2 } },  -- Terror of the Wastes
    [2518] = { { npc = "Any Timewalking Vendor", zone = "" } },  -- Chrono Corsair
    [2519] = { { npc = "Lars Bronsmaelt", zone = "Hallowfall", m = 2215, x = 28.2, y = 56.2 } },  -- Radiant Imperial Lynx
    [2552] = { { npc = "Shad'anis", zone = "K'aresh", m = 2371, x = 50.4, y = 36.2 } },  -- Lavender K'arroc
    [2556] = { { npc = "Om'sirik", zone = "K'aresh", m = 2472, x = 40.6, y = 29.2 } },  -- Ruby Void Creeper
    [2557] = { { npc = "Shad'anis", zone = "K'aresh", m = 2371, x = 50.4, y = 36.2 } },  -- Acidic Void Creeper
    [2570] = { { npc = "Necrolord Sipe", zone = "Stormwind City", m = 84, x = 76.8, y = 65.4 } },
    [2571] = { { npc = "Deathguard Netharian", zone = "Orgrimmar", m = 85, x = 41.8, y = 73 } },
    [2586] = { { npc = "Churbro", zone = "Boralus Harbor", m = 1161, x = 70.8, y = 16.4 } },  -- Moonlit Nightsaber
    [2587] = { { npc = "Churbro", zone = "Boralus Harbor", m = 1161, x = 70.8, y = 16.4 } },  -- Ivory Savagemane
    [2604] = { { npc = "Sir Finley Mrrgglton", zone = "Dornogal", m = 2339, x = 47.4, y = 43.4 } },  -- OC91 Chariot
    [2614] = { { npc = "Naynar", zone = "Harandar", m = 2413, x = 51.0, y = 50.7 } },  -- Fierce Grimlynx
    [2693] = { { npc = "Chel the Chip", zone = "", m = 2437, x = 45.0, y = 67.5 } },  -- Amani Sunfeather
    [2694] = { { npc = "Magovu", zone = "Zul'Aman", m = 2437, x = 46.0, y = 65.9 } },  -- Amani Windcaller
    [2710] = { { npc = "Naynar", zone = "Harandar", m = 2413, x = 51.0, y = 50.7 } },  -- Cerulean Sporeglider
    [2753] = { { npc = "Caeris Fairdawn", zone = "Eversong Woods", m = 2395, x = 43.5, y = 47.5 } },  -- Fiery Dragonhawk
    [2761] = { { npc = "Caeris Fairdawn", zone = "Eversong Woods", m = 2395, x = 43.5, y = 47.5 } },  -- Crimson Silvermoon Hawkstrider
    [2769] = { { npc = "Construct V'anore", zone = "Silvermoon City", m = 2393, x = 55.7, y = 65.7 } },  -- Preyseeker's Hubris
    [2770] = { { npc = "Construct V'anore", zone = "Silvermoon City", m = 2393, x = 55.7, y = 65.7 } },  -- Preyseeker's Wrath
    [2772] = { { npc = "Chel the Chip", zone = "", m = 2437, x = 45.0, y = 67.5 } },  -- Blessed Amani Burrower
    [2776] = { { npc = "Magovu", zone = "Zul'Aman", m = 2437, x = 46.0, y = 65.9 } },  -- Amani Blessed Bear
    [2789] = { { npc = "Void Researcher Anomander", zone = "Voidstorm", m = 2664, x = 47.1, y = 66.2 } },  -- Ravenous Shredclaw
    [2791] = { { npc = "Thraxadar", zone = "Masters' Perch", m = 2444, x = 39.3, y = 81.1 } },  -- Prowling Shredclaw
    [2792] = { { npc = "Thraxadar", zone = "Masters' Perch", m = 2444, x = 39.3, y = 81.1 } },  -- Frenzied Shredclaw
    [2803] = { { npc = "Collector Ta'steld", zone = "Oribos", m = 1670, x = 55.2, y = 63.4 } },  -- Skypaw Glimmerfur
    [2804] = { { npc = "Collector Ta'steld", zone = "Oribos", m = 1670, x = 55.2, y = 63.4 } },  -- Crimson Lupine
    [2807] = {
        { npc = "Ulaani", zone = "Bizmo's Brawlpub", m = 500, x = 27, y = 25 },
        { npc = "\"Bad Luck\" Symmes", zone = "Brawl'gar Arena", m = 503, x = 52, y = 23 },
    },
    [2808] = {
        { npc = "Dershway the Triggered", zone = "Bizmo's Brawlpub", m = 500, x = 27, y = 25 },
        { npc = "\"Bad Luck\" Symmes", zone = "Brawl'gar Arena", m = 503, x = 52, y = 23 },
    },
    [2815] = { { npc = "Collector Ta'steld", zone = "Oribos", m = 1670, x = 55.2, y = 63.4 } },  -- Snowpaw Glimmerfur Prowler
    [2828] = { { npc = "Void Researcher Anomander", zone = "Voidstorm", m = 2664, x = 47.1, y = 66.2 } },  -- Voidbound Stormray
    [2840] = { { npc = "Telemancer Astrandis", zone = "Silvermoon City", m = 2393, x = 52.5, y = 78.8 } },  -- Silvermoon's Arcane Defender
    [2841] = { { npc = "Naleidea Rivergleam", zone = "Silvermoon City", m = 2393, x = 52.7, y = 78 } },  -- Elven Arcane Guardian
    [2913] = { { npc = "Mothkeeper Wew'tam", zone = "Harandar", m = 2413, x = 49.3, y = 54.3 } },  -- Vivid Chloroceros
}
