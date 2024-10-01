-- Is temp fix : you would have to see how this reading is done in the assets editor and put it in the OTC
-- temp. TODO assets search
-- LuaFormatter off

ItemsDatabase = {}

ItemsDatabase.lib = {
    ['yellow'] = {
        ['gold coin'] = {
            clientId = 3031,
            sell = 1070000,
        },
        ['fiery tear'] = {
            clientId = 39040,
            sell = 1070000,
        },
        ['megalomania\'s essence'] = {
            clientId = 33928,
            sell = 1900000,
        },
        ['megalomania\'s skull'] = {
            clientId = 33925,
            sell = 1500000,
        },
        ['morshabaal\'s extract'] = {
            clientId = 37810,
            sell = 3250000,
        },
        ['figurine of cruelty'] = {
            clientId = 34019,
            sell = 3100000,
        },
        ['figurine of greed'] = {
            clientId = 34021,
            sell = 2900000,
        },
        ['figurine of hatred'] = {
            clientId = 34020,
            sell = 2700000,
        },
        ['figurine of malice'] = {
            clientId = 34018,
            sell = 2800000,
        },
        ['figurine of megalomania'] = {
            clientId = 33953,
            sell = 5000000,
        },
        ['figurine of spite'] = {
            clientId = 33952,
            sell = 3000000,
        },
    },
    ['purple'] = {
        ['abomination\'s eye'] = {
            clientId = 36792,
            sell = 650000,
        },
        ['abomination\'s tail'] = {
            clientId = 36791,
            sell = 700000,
        },
        ['abomination\'s tongue'] = {
            clientId = 36793,
            sell = 950000,
        },
        ['alptramun\'s toothbrush'] = {
            clientId = 29943,
            sell = 270000,
        },
        ['brain head\'s giant neuron'] = {
            clientId = 32578,
            sell = 100000,
        },
        ['brainstealer\'s brain'] = {
            clientId = 36795,
            sell = 300000,
        },
        ['brainstealer\'s brainwave'] = {
            clientId = 36796,
            sell = 440000,
        },
        ['brainstealer\'s tissue'] = {
            clientId = 36794,
            sell = 240000,
        },
        ['cheesy membership card'] = {
            clientId = 35614,
            sell = 120000,
        },
        ['cruelty\'s chest'] = {
            clientId = 33923,
            sell = 720000,
        },
        ['cruelty\'s claw'] = {
            clientId = 33922,
            sell = 640000,
        },
        ['curl of hair'] = {
            clientId = 36809,
            sell = 320000,
        },
        ['dark bell'] = {
            clientId = 32596,
            sell = 310000,
        },
        ['greed\'s arm'] = {
            clientId = 33924,
            sell = 950000,
        },
        ['grimace'] = {
            clientId = 32593,
            sell = 120000,
        },
        ['izcandar\'s snow globe'] = {
            clientId = 29944,
            sell = 180000,
        },
        ['izcandar\'s sundial'] = {
            clientId = 29945,
            sell = 225000,
        },
        ['malice\'s horn'] = {
            clientId = 33920,
            sell = 620000,
        },
        ['malice\'s spine'] = {
            clientId = 33921,
            sell = 850000,
        },
        ['malofur\'s lunchbox'] = {
            clientId = 30088,
            sell = 240000,
        },
        ['maxxenius head'] = {
            clientId = 29942,
            sell = 500000,
        },
        ['one of timira\'s many heads'] = {
            clientId = 39399,
            sell = 215000,
        },
        ['pale worm\'s scalp'] = {
            clientId = 32598,
            sell = 489000,
        },
        ['piece of timira\'s sensors'] = {
            clientId = 39400,
            sell = 150000,
        },
        ['plagueroot offshoot'] = {
            clientId = 30087,
            sell = 280000,
        },
        ['ratmiral\'s hat'] = {
            clientId = 35613,
            sell = 150000,
        },
        ['ravenous circlet'] = {
            clientId = 32597,
            sell = 220000,
        },
        ['smoldering eye'] = {
            clientId = 39543,
            sell = 470000,
        },
        ['spite\'s spirit'] = {
            clientId = 33926,
            sell = 840000,
        },
        ['token of love'] = {
            clientId = 31594,
            sell = 440000,
        },
        ['urmahlullus mane'] = {
            clientId = 31623,
            sell = 490000,
        },
        ['urmahlullus paws'] = {
            clientId = 31624,
            sell = 245000,
        },
        ['urmahlullus tail'] = {
            clientId = 31622,
            sell = 210000,
        },
        ['vial of hatred'] = {
            clientId = 33927,
            sell = 737000,
        },
        ['writhing brain'] = {
            clientId = 32600,
            sell = 370000,
        },
        ['writhing heart'] = {
            clientId = 32599,
            sell = 185000,
        },
        ['jagged sickle'] = {
            clientId = 32595,
            sell = 150000,
        },
        ['noble cape'] = {
            clientId = 31593,
            sell = 425000,
        },
        ['noble amulet'] = {
            clientId = 31595,
            sell = 430000,
        },
        ['signet ring'] = {
            clientId = 31592,
            sell = 480000,
        },
        ['beast\'s nightmare-cushion'] = {
            clientId = 29946,
            sell = 630000,
        },
        ['medal of valiance'] = {
            clientId = 31591,
            sell = 410000,
        },
        ['royal almandine'] = {
            clientId = 39038,
            sell = 460000,
        },
        ['watermelon tourmaline'] = {
            clientId = 33780,
            sell = 230000,
        },
    },
    ['blue'] = {
        ['amber with a bug'] = {
            clientId = 32624,
            sell = 41000,
        },
        ['amber with a dragonfly'] = {
            clientId = 32625,
            sell = 56000,
        },
        ['amber'] = {
            clientId = 32626,
            sell = 20000,
        },
        ['ancient liche bone'] = {
            clientId = 31588,
            sell = 28000,
        },
        ['bejeweled ship\'s telescope'] = {
            clientId = 9616,
            sell = 20000,
        },
        ['berserker'] = {
            clientId = 7403,
            sell = 40000,
        },
        ['bloody tears'] = {
            clientId = 32594,
            sell = 70000,
        },
        ['bones of zorvorax'] = {
            clientId = 24942,
            sell = 10000,
        },
        ['brain head\'s left hemisphere'] = {
            clientId = 32579,
            sell = 90000,
        },
        ['brain head\'s right hemisphere'] = {
            clientId = 32580,
            sell = 50000,
        },
        ['brooch of embracement'] = {
            clientId = 34023,
            sell = 14000,
        },
        ['chitinous mouth'] = {
            clientId = 27626,
            sell = 10000,
        },
        ['countess sorrow\'s frozen tear'] = {
            clientId = 6536,
            sell = 50000,
        },
        ['crest of the deep seas'] = {
            clientId = 21892,
            sell = 10000,
        },
        ['crunor idol'] = {
            clientId = 30055,
            sell = 30000,
        },
        ['diabolic skull'] = {
            clientId = 34025,
            sell = 19000,
        },
        ['dracola\'s eye'] = {
            clientId = 6546,
            sell = 50000,
        },
        ['flask of warrior\'s sweat'] = {
            clientId = 5885,
            sell = 10000,
        },
        ['giant tentacle'] = {
            clientId = 27619,
            sell = 10000,
        },
        ['goblet of gloom'] = {
            clientId = 34022,
            sell = 12000,
        },
        ['grasshopper legs'] = {
            clientId = 14087,
            sell = 15000,
        },
        ['gruesome fan'] = {
            clientId = 34024,
            sell = 15000,
        },
        ['harpoon of a giant snail'] = {
            clientId = 27625,
            sell = 15000,
        },
        ['horn of kalyassa'] = {
            clientId = 24941,
            sell = 10000,
        },
        ['huge chunk of crude iron'] = {
            clientId = 5892,
            sell = 15000,
        },
        ['huge shell'] = {
            clientId = 27621,
            sell = 15000,
        },
        ['lion figurine'] = {
            clientId = 33781,
            sell = 10000,
        },
        ['magma coat'] = {
            clientId = 826,
            sell = 11000,
        },
        ['moon pin'] = {
            clientId = 43736,
            sell = 18000,
        },
        ['morgaroth\'s heart'] = {
            clientId = 5943,
            sell = 15000,
        },
        ['morshabaal\'s brain'] = {
            clientId = 37613,
            sell = 15000,
        },
        ['mr. punish\'s handcuffs'] = {
            clientId = 6537,
            sell = 50000,
        },
        ['orshabaal\'s brain'] = {
            clientId = 5808,
            sell = 12000,
        },
        ['piece of massacre\'s shell'] = {
            clientId = 6540,
            sell = 50000,
        },
        ['pristine worm head'] = {
            clientId = 27618,
            sell = 15000,
        },
        ['rotten heart'] = {
            clientId = 31589,
            sell = 74000,
        },
        ['scale of gelidrazah'] = {
            clientId = 24939,
            sell = 10000,
        },
        ['sun brooch'] = {
            clientId = 43737,
            sell = 18000,
        },
        ['tentacle of tentugly'] = {
            clientId = 35611,
            sell = 27000,
        },
        ['tentugly\'s eye'] = {
            clientId = 35610,
            sell = 52000,
        },
        ['tentugly\'s jaws'] = {
            clientId = 35612,
            sell = 80000,
        },
        ['the handmaiden\'s protector'] = {
            clientId = 6539,
            sell = 50000,
        },
        ['the imperor\'s trident'] = {
            clientId = 6534,
            sell = 50000,
        },
        ['the plasmother\'s remains'] = {
            clientId = 6535,
            sell = 50000,
        },
        ['tooth of tazhadur'] = {
            clientId = 24940,
            sell = 10000,
        },
        ['unholy book'] = {
            clientId = 6103,
            sell = 30000,
        },
        ['young lich worm'] = {
            clientId = 31590,
            sell = 25000,
        },
        ['abyss hammer'] = {
            clientId = 7414,
            sell = 20000,
        },
        ['alloy legs'] = {
            clientId = 21168,
            sell = 11000,
        },
        ['arbalest'] = {
            clientId = 5803,
            sell = 42000,
        },
        ['arcane staff'] = {
            clientId = 3341,
            sell = 42000,
        },
        ['assassin dagger'] = {
            clientId = 7404,
            sell = 20000,
        },
        ['blade of corruption'] = {
            clientId = 11693,
            sell = 60000,
        },
        ['blessed sceptre'] = {
            clientId = 7429,
            sell = 40000,
        },
        ['bloody edge'] = {
            clientId = 7416,
            sell = 30000,
        },
        ['blue legs'] = {
            clientId = 645,
            sell = 15000,
        },
        ['blue robe'] = {
            clientId = 3567,
            sell = 10000,
        },
        ['bonebreaker'] = {
            clientId = 7428,
            sell = 10000,
        },
        ['boots of haste'] = {
            clientId = 3079,
            sell = 30000,
        },
        ['butcher\'s axe'] = {
            clientId = 7412,
            sell = 18000,
        },
        ['calopteryx cape'] = {
            clientId = 14086,
            sell = 15000,
        },
        ['carapace shield'] = {
            clientId = 14088,
            sell = 32000,
        },
        ['chain bolter'] = {
            clientId = 8022,
            sell = 40000,
        },
        ['claw of \'the noxious spawn\''] = {
            clientId = 9392,
            sell = 15000,
        },
        ['cobra crown'] = {
            clientId = 11674,
            sell = 50000,
        },
        ['composite hornbow'] = {
            clientId = 8027,
            sell = 25000,
        },
        ['cranial basher'] = {
            clientId = 7415,
            sell = 30000,
        },
        ['crown armor'] = {
            clientId = 3381,
            sell = 12000,
        },
        ['crown legs'] = {
            clientId = 3382,
            sell = 12000,
        },
        ['crystal crossbow'] = {
            clientId = 16163,
            sell = 35000,
        },
        ['crystal mace'] = {
            clientId = 3333,
            sell = 12000,
        },
        ['crystal wand'] = {
            clientId = 3068,
            sell = 10000,
        },
        ['crystalline armor'] = {
            clientId = 8050,
            sell = 16000,
        },
        ['crystalline axe'] = {
            clientId = 16161,
            sell = 10000,
        },
        ['deepling axe'] = {
            clientId = 13991,
            sell = 40000,
        },
        ['demon helmet'] = {
            clientId = 3387,
            sell = 40000,
        },
        ['demon shield'] = {
            clientId = 3420,
            sell = 30000,
        },
        ['demonbone amulet'] = {
            clientId = 3019,
            sell = 32000,
        },
        ['demonrage sword'] = {
            clientId = 7382,
            sell = 36000,
        },
        ['depth calcei'] = {
            clientId = 13997,
            sell = 25000,
        },
        ['depth galea'] = {
            clientId = 13995,
            sell = 35000,
        },
        ['depth lorica'] = {
            clientId = 13994,
            sell = 30000,
        },
        ['depth ocrea'] = {
            clientId = 13996,
            sell = 16000,
        },
        ['depth scutum'] = {
            clientId = 13998,
            sell = 36000,
        },
        ['divine plate'] = {
            clientId = 8057,
            sell = 55000,
        },
        ['djinn blade'] = {
            clientId = 3339,
            sell = 15000,
        },
        ['drachaku'] = {
            clientId = 10391,
            sell = 10000,
        },
        ['dragon robe'] = {
            clientId = 8039,
            sell = 50000,
        },
        ['dragon scale mail'] = {
            clientId = 3386,
            sell = 40000,
        },
        ['dragon slayer'] = {
            clientId = 7402,
            sell = 15000,
        },
        ['draken boots'] = {
            clientId = 4033,
            sell = 40000,
        },
        ['drakinata'] = {
            clientId = 10388,
            sell = 10000,
        },
        ['dreaded cleaver'] = {
            clientId = 7419,
            sell = 15000,
        },
        ['dwarven armor'] = {
            clientId = 3397,
            sell = 30000,
        },
        ['dwarven legs'] = {
            clientId = 3398,
            sell = 40000,
        },
        ['elite draken mail'] = {
            clientId = 11651,
            sell = 50000,
        },
        ['execowtioner axe'] = {
            clientId = 21176,
            sell = 12000,
        },
        ['executioner'] = {
            clientId = 7453,
            sell = 55000,
        },
        ['giant sword'] = {
            clientId = 3281,
            sell = 17000,
        },
        ['glacier kilt'] = {
            clientId = 823,
            sell = 11000,
        },
        ['glacier robe'] = {
            clientId = 824,
            sell = 11000,
        },
        ['golden armor'] = {
            clientId = 3360,
            sell = 20000,
        },
        ['golden legs'] = {
            clientId = 3364,
            sell = 30000,
        },
        ['greenwood coat'] = {
            clientId = 8041,
            sell = 50000,
        },
        ['guardian boots'] = {
            clientId = 10323,
            sell = 35000,
        },
        ['guardian halberd'] = {
            clientId = 3315,
            sell = 11000,
        },
        ['hammer of wrath'] = {
            clientId = 3332,
            sell = 30000,
        },
        ['heat core'] = {
            clientId = 21167,
            sell = 10000,
        },
        ['heavy mace'] = {
            clientId = 3340,
            sell = 50000,
        },
        ['heroic axe'] = {
            clientId = 7389,
            sell = 30000,
        },
        ['hive bow'] = {
            clientId = 14246,
            sell = 28000,
        },
        ['hive scythe'] = {
            clientId = 14089,
            sell = 17000,
        },
        ['jade hammer'] = {
            clientId = 7422,
            sell = 25000,
        },
        ['lavos armor'] = {
            clientId = 8049,
            sell = 16000,
        },
        ['lightning legs'] = {
            clientId = 822,
            sell = 11000,
        },
        ['lightning robe'] = {
            clientId = 825,
            sell = 11000,
        },
        ['magic plate armor'] = {
            clientId = 3366,
            sell = 90000,
        },
        ['magma legs'] = {
            clientId = 821,
            sell = 11000,
        },
        ['mastermind shield'] = {
            clientId = 3414,
            sell = 50000,
        },
        ['mercenary sword'] = {
            clientId = 7386,
            sell = 12000,
        },
        ['modified crossbow'] = {
            clientId = 8021,
            sell = 10000,
        },
        ['moohtant cudgel'] = {
            clientId = 21173,
            sell = 14000,
        },
        ['mycological bow'] = {
            clientId = 16164,
            sell = 35000,
        },
        ['mystic blade'] = {
            clientId = 7384,
            sell = 30000,
        },
        ['nightmare blade'] = {
            clientId = 7418,
            sell = 35000,
        },
        ['noble axe'] = {
            clientId = 7456,
            sell = 10000,
        },
        ['onyx flail'] = {
            clientId = 7421,
            sell = 22000,
        },
        ['oriental shoes'] = {
            clientId = 21981,
            sell = 15000,
        },
        ['ornamented axe'] = {
            clientId = 7411,
            sell = 20000,
        },
        ['ornate chestplate'] = {
            clientId = 13993,
            sell = 60000,
        },
        ['ornate crossbow'] = {
            clientId = 14247,
            sell = 12000,
        },
        ['ornate legs'] = {
            clientId = 13999,
            sell = 40000,
        },
        ['ornate mace'] = {
            clientId = 14001,
            sell = 42000,
        },
        ['ornate shield'] = {
            clientId = 14000,
            sell = 42000,
        },
        ['paladin armor'] = {
            clientId = 8063,
            sell = 15000,
        },
        ['pharaoh sword'] = {
            clientId = 3334,
            sell = 23000,
        },
        ['phoenix shield'] = {
            clientId = 3439,
            sell = 16000,
        },
        ['queen\'s sceptre'] = {
            clientId = 7410,
            sell = 20000,
        },
        ['relic sword'] = {
            clientId = 7383,
            sell = 25000,
        },
        ['rift bow'] = {
            clientId = 22866,
            sell = 45000,
        },
        ['rift crossbow'] = {
            clientId = 22867,
            sell = 45000,
        },
        ['rift lance'] = {
            clientId = 22727,
            sell = 30000,
        },
        ['rift shield'] = {
            clientId = 22726,
            sell = 50000,
        },
        ['royal axe'] = {
            clientId = 7434,
            sell = 40000,
        },
        ['royal helmet'] = {
            clientId = 3392,
            sell = 30000,
        },
        ['rubber cap'] = {
            clientId = 21165,
            sell = 11000,
        },
        ['runed sword'] = {
            clientId = 7417,
            sell = 45000,
        },
        ['ruthless axe'] = {
            clientId = 6553,
            sell = 45000,
        },
        ['sai'] = {
            clientId = 10389,
            sell = 16500,
        },
        ['shadow sceptre'] = {
            clientId = 7451,
            sell = 10000,
        },
        ['silkweaver bow'] = {
            clientId = 8029,
            sell = 12000,
        },
        ['skull helmet'] = {
            clientId = 5741,
            sell = 40000,
        },
        ['skullcracker armor'] = {
            clientId = 8061,
            sell = 18000,
        },
        ['spellbook of lost souls'] = {
            clientId = 8075,
            sell = 19000,
        },
        ['spellbook of mind control'] = {
            clientId = 8074,
            sell = 13000,
        },
        ['spellweaver\'s robe'] = {
            clientId = 10438,
            sell = 12000,
        },
        ['steel boots'] = {
            clientId = 3554,
            sell = 30000,
        },
        ['swamplair armor'] = {
            clientId = 8052,
            sell = 16000,
        },
        ['tempest shield'] = {
            clientId = 3442,
            sell = 35000,
        },
        ['terra legs'] = {
            clientId = 812,
            sell = 11000,
        },
        ['terra mantle'] = {
            clientId = 811,
            sell = 11000,
        },
        ['thaian sword'] = {
            clientId = 7391,
            sell = 16000,
        },
        ['the avenger'] = {
            clientId = 6527,
            sell = 42000,
        },
        ['the ironworker'] = {
            clientId = 8025,
            sell = 50000,
        },
        ['the justice seeker'] = {
            clientId = 7390,
            sell = 40000,
        },
        ['tiara'] = {
            clientId = 35578,
            sell = 11000,
        },
        ['twiceslicer'] = {
            clientId = 11657,
            sell = 28000,
        },
        ['vampire shield'] = {
            clientId = 3434,
            sell = 15000,
        },
        ['vile axe'] = {
            clientId = 7388,
            sell = 30000,
        },
        ['war axe'] = {
            clientId = 3342,
            sell = 12000,
        },
        ['warrior\'s axe'] = {
            clientId = 14040,
            sell = 11000,
        },
        ['windborn colossus armor'] = {
            clientId = 8055,
            sell = 50000,
        },
        ['wooden spellbook'] = {
            clientId = 25699,
            sell = 12000,
        },
        ['zaoan armor'] = {
            clientId = 10384,
            sell = 14000,
        },
        ['zaoan helmet'] = {
            clientId = 10385,
            sell = 45000,
        },
        ['zaoan legs'] = {
            clientId = 10387,
            sell = 14000,
        },
        ['zaoan robe'] = {
            clientId = 10439,
            sell = 12000,
        },
        ['zaoan sword'] = {
            clientId = 10390,
            sell = 30000,
        },
        ['amulet of loss'] = {
            clientId = 3057,
            sell = 45000,
        },
        ['ornate locket'] = {
            clientId = 30056,
            sell = 18000,
        },
        ['ring of the sky'] = {
            clientId = 3006,
            sell = 30000,
        },
        ['angel figurine'] = {
            clientId = 32589,
            sell = 36000,
        },
        ['bar of gold'] = {
            clientId = 14112,
            sell = 10000,
        },
        ['blood goblet'] = {
            clientId = 8531,
            sell = 10000,
        },
        ['ceremonial ankh'] = {
            clientId = 6561,
            sell = 20000,
        },
        ['diamond'] = {
            clientId = 32770,
            sell = 15000,
        },
        ['dragon figurine'] = {
            clientId = 30053,
            sell = 45000,
        },
        ['eldritch crystal'] = {
            clientId = 36835,
            sell = 48000,
        },
        ['frozen starlight'] = {
            clientId = 3249,
            sell = 20000,
        },
        ['giant amethyst'] = {
            clientId = 32622,
            sell = 60000,
        },
        ['giant emerald'] = {
            clientId = 30060,
            sell = 90000,
        },
        ['giant ruby'] = {
            clientId = 30059,
            sell = 70000,
        },
        ['giant sapphire'] = {
            clientId = 30061,
            sell = 50000,
        },
        ['giant topaz'] = {
            clientId = 32623,
            sell = 80000,
        },
        ['golden fafnar trophy'] = {
            clientId = 9626,
            sell = 10000,
        },
        ['golden mask'] = {
            clientId = 31324,
            sell = 38000,
        },
        ['golden sun coin'] = {
            clientId = 43734,
            sell = 11000,
        },
        ['golden tiger coin'] = {
            clientId = 43735,
            sell = 11000,
        },
        ['greater guardian gem'] = {
            clientId = 44604,
            sell = 10000,
        },
        ['greater marksman gem'] = {
            clientId = 44607,
            sell = 10000,
        },
        ['greater mystic gem'] = {
            clientId = 44613,
            sell = 10000,
        },
        ['greater sage gem'] = {
            clientId = 44610,
            sell = 10000,
        },
        ['hexagonal ruby'] = {
            clientId = 30180,
            sell = 30000,
        },
        ['moonstone'] = {
            clientId = 32771,
            sell = 13000,
        },
        ['sea horse figurine'] = {
            clientId = 31323,
            sell = 42000,
        },
        ['silver foxmouse coin'] = {
            clientId = 43733,
            sell = 11000,
        },
        ['silver hand mirror'] = {
            clientId = 32772,
            sell = 10000,
        },
        ['silver moon coin'] = {
            clientId = 43732,
            sell = 11000,
        },
        ['skull coin'] = {
            clientId = 32583,
            sell = 12000,
        },
        ['unicorn figurine'] = {
            clientId = 30054,
            sell = 50000,
        },
        ['violet gem'] = {
            clientId = 3036,
            sell = 10000,
        },
        ['watermelon tourmaline (slice)'] = {
            clientId = 33779,
            sell = 30000,
        },
        ['white gem'] = {
            clientId = 32769,
            sell = 12000,
        },
        ['egg of the many'] = {
            clientId = 9606,
            sell = 15000,
        },
        ['enchanted chicken wing'] = {
            clientId = 5891,
            sell = 20000,
        },
        ['piece of royal steel'] = {
            clientId = 5887,
            sell = 10000,
        },
        ['spirit container'] = {
            clientId = 5884,
            sell = 40000,
        },
        ['baby seal doll'] = {
            clientId = 7183,
            sell = 20000,
        },
        ['behemoth trophy'] = {
            clientId = 7396,
            sell = 20000,
        },
        ['demon trophy'] = {
            clientId = 7393,
            sell = 40000,
        },
        ['dragon lord trophy'] = {
            clientId = 7399,
            sell = 10000,
        },
        ['draken trophy'] = {
            clientId = 10398,
            sell = 15000,
        },
        ['morbid tapestry'] = {
            clientId = 34170,
            sell = 30000,
        },
        ['panda teddy'] = {
            clientId = 5080,
            sell = 30000,
        },
        ['sea serpent trophy'] = {
            clientId = 9613,
            sell = 10000,
        },
        ['werebear trophy'] = {
            clientId = 22103,
            sell = 11000,
        },
        ['wereboar trophy'] = {
            clientId = 22102,
            sell = 10000,
        },
        ['werecrocodile trophy'] = {
            clientId = 43916,
            sell = 15000,
        },
        ['werehyaena trophy'] = {
            clientId = 34219,
            sell = 12000,
        },
        ['werepanther trophy'] = {
            clientId = 43917,
            sell = 14000,
        },
        ['weretiger trophy'] = {
            clientId = 43915,
            sell = 14000,
        },
    },
    ['green'] = {
        ['apron'] = {
            clientId = 33933,
            sell = 1300,
        },
        ['beetle necklace'] = {
            clientId = 10457,
            sell = 1500,
        },
        ['black skull'] = {
            clientId = 9056,
            sell = 4000,
        },
        ['blemished spawn tail'] = {
            clientId = 36780,
            sell = 1000,
        },
        ['broken key ring'] = {
            clientId = 11652,
            sell = 8000,
        },
        ['broken macuahuitl'] = {
            clientId = 40530,
            sell = 1000,
        },
        ['broken ring of ending'] = {
            clientId = 12737,
            sell = 4000,
        },
        ['broken visor'] = {
            clientId = 20184,
            sell = 1900,
        },
        ['brutetamer\'s staff'] = {
            clientId = 7379,
            sell = 1500,
        },
        ['buckle'] = {
            clientId = 17829,
            sell = 7000,
        },
        ['capricious heart'] = {
            clientId = 34138,
            sell = 2100,
        },
        ['capricious robe'] = {
            clientId = 34145,
            sell = 1200,
        },
        ['cat\'s paw'] = {
            clientId = 5479,
            sell = 2000,
        },
        ['cave chimera head'] = {
            clientId = 36787,
            sell = 1200,
        },
        ['crawler\'s essence'] = {
            clientId = 33982,
            sell = 3700,
        },
        ['cursed bone'] = {
            clientId = 32774,
            sell = 6000,
        },
        ['damaged worm head'] = {
            clientId = 27620,
            sell = 8000,
        },
        ['demon horn'] = {
            clientId = 5954,
            sell = 1000,
        },
        ['demonic finger'] = {
            clientId = 12541,
            sell = 1000,
        },
        ['distorted heart'] = {
            clientId = 34142,
            sell = 2100,
        },
        ['distorted robe'] = {
            clientId = 34149,
            sell = 1200,
        },
        ['emerald tortoise shell'] = {
            clientId = 39379,
            sell = 2150,
        },
        ['enigmatic voodoo skull'] = {
            clientId = 5669,
            sell = 4000,
        },
        ['eternal flames'] = {
            clientId = 946,
            sell = 5000,
        },
        ['flower dress'] = {
            clientId = 9015,
            sell = 1000,
        },
        ['goo shell'] = {
            clientId = 19372,
            sell = 4000,
        },
        ['gore horn'] = {
            clientId = 39377,
            sell = 2900,
        },
        ['gorerilla mane'] = {
            clientId = 39392,
            sell = 2750,
        },
        ['gorerilla tail'] = {
            clientId = 39393,
            sell = 2650,
        },
        ['hand'] = {
            clientId = 33936,
            sell = 1450,
        },
        ['hazardous heart'] = {
            clientId = 34140,
            sell = 5000,
        },
        ['hazardous robe'] = {
            clientId = 34147,
            sell = 3000,
        },
        ['head'] = {
            clientId = 33937,
            sell = 3200,
        },
        ['headpecker beak'] = {
            clientId = 39387,
            sell = 2998,
        },
        ['headpecker feather'] = {
            clientId = 39388,
            sell = 1300,
        },
        ['huge spiky snail shell'] = {
            clientId = 27627,
            sell = 8000,
        },
        ['infernal heart'] = {
            clientId = 34139,
            sell = 2100,
        },
        ['infernal robe'] = {
            clientId = 34146,
            sell = 1200,
        },
        ['ivory comb'] = {
            clientId = 32773,
            sell = 8000,
        },
        ['jaws'] = {
            clientId = 34014,
            sell = 3900,
        },
        ['lavaworm jaws'] = {
            clientId = 36771,
            sell = 1100,
        },
        ['longing eyes'] = {
            clientId = 27624,
            sell = 8000,
        },
        ['luminous orb'] = {
            clientId = 11454,
            sell = 1000,
        },
        ['mantosaurus jaw'] = {
            clientId = 39386,
            sell = 2998,
        },
        ['mould heart'] = {
            clientId = 34141,
            sell = 2100,
        },
        ['mould robe'] = {
            clientId = 34148,
            sell = 1200,
        },
        ['mysterious voodoo skull'] = {
            clientId = 5668,
            sell = 4000,
        },
        ['neutral matter'] = {
            clientId = 954,
            sell = 5000,
        },
        ['nighthunter wing'] = {
            clientId = 39381,
            sell = 2000,
        },
        ['orc trophy'] = {
            clientId = 7395,
            sell = 1000,
        },
        ['pair of hellflayer horns'] = {
            clientId = 22729,
            sell = 1300,
        },
        ['pair of iron fists'] = {
            clientId = 17828,
            sell = 4000,
        },
        ['patch of fine cloth'] = {
            clientId = 28821,
            sell = 1350,
        },
        ['pharaoh banner'] = {
            clientId = 12483,
            sell = 1000,
        },
        ['porcelain mask'] = {
            clientId = 25088,
            sell = 2000,
        },
        ['prehemoth claw'] = {
            clientId = 39383,
            sell = 2300,
        },
        ['prehemoth horns'] = {
            clientId = 39382,
            sell = 3000,
        },
        ['quill'] = {
            clientId = 28567,
            sell = 1100,
        },
        ['ripptor claw'] = {
            clientId = 39389,
            sell = 2000,
        },
        ['ripptor scales'] = {
            clientId = 39391,
            sell = 1200,
        },
        ['roots'] = {
            clientId = 33938,
            sell = 1200,
        },
        ['sabretooth fur'] = {
            clientId = 39378,
            sell = 2500,
        },
        ['shamanic mask'] = {
            clientId = 22192,
            sell = 2000,
        },
        ['sight of surrender\'s eye'] = {
            clientId = 20183,
            sell = 3000,
        },
        ['silken bookmark'] = {
            clientId = 28566,
            sell = 1300,
        },
        ['single human eye'] = {
            clientId = 25701,
            sell = 1000,
        },
        ['slimy leg'] = {
            clientId = 27623,
            sell = 4500,
        },
        ['some grimeleech wings'] = {
            clientId = 22730,
            sell = 1200,
        },
        ['stalking seeds'] = {
            clientId = 39384,
            sell = 1800,
        },
        ['sulphider shell'] = {
            clientId = 39375,
            sell = 2200,
        },
        ['sulphur powder'] = {
            clientId = 39376,
            sell = 1900,
        },
        ['summer dress'] = {
            clientId = 8046,
            sell = 1500,
        },
        ['telescope eye'] = {
            clientId = 33934,
            sell = 1600,
        },
        ['tentacle piece'] = {
            clientId = 11666,
            sell = 5000,
        },
        ['undertaker fangs'] = {
            clientId = 39380,
            sell = 2700,
        },
        ['vexclaw talon'] = {
            clientId = 22728,
            sell = 1100,
        },
        ['vibrant heart'] = {
            clientId = 34143,
            sell = 2100,
        },
        ['vibrant robe'] = {
            clientId = 34144,
            sell = 1200,
        },
        ['violet glass plate'] = {
            clientId = 29347,
            sell = 2150,
        },
        ['war horn'] = {
            clientId = 2958,
            sell = 8000,
        },
        ['white silk flower'] = {
            clientId = 34008,
            sell = 9000,
        },
        ['albino plate'] = {
            clientId = 19358,
            sell = 1500,
        },
        ['amber staff'] = {
            clientId = 7426,
            sell = 8000,
        },
        ['angelic axe'] = {
            clientId = 7436,
            sell = 5000,
        },
        ['badger boots'] = {
            clientId = 22086,
            sell = 7500,
        },
        ['batwing hat'] = {
            clientId = 9103,
            sell = 8000,
        },
        ['beastslayer axe'] = {
            clientId = 3344,
            sell = 1500,
        },
        ['blacksteel sword'] = {
            clientId = 7406,
            sell = 6000,
        },
        ['bonelord helmet'] = {
            clientId = 3408,
            sell = 7500,
        },
        ['bonelord shield'] = {
            clientId = 3418,
            sell = 1200,
        },
        ['bright sword'] = {
            clientId = 3295,
            sell = 6000,
        },
        ['butterfly ring'] = {
            clientId = 25698,
            sell = 2000,
        },
        ['castle shield'] = {
            clientId = 3435,
            sell = 5000,
        },
        ['chaos mace'] = {
            clientId = 7427,
            sell = 9000,
        },
        ['cowtana'] = {
            clientId = 21177,
            sell = 2500,
        },
        ['crocodile boots'] = {
            clientId = 3556,
            sell = 1000,
        },
        ['crown helmet'] = {
            clientId = 3385,
            sell = 2500,
        },
        ['crown shield'] = {
            clientId = 3419,
            sell = 8000,
        },
        ['crusader helmet'] = {
            clientId = 3391,
            sell = 6000,
        },
        ['crystalline sword'] = {
            clientId = 16160,
            sell = 2000,
        },
        ['daramian waraxe'] = {
            clientId = 3328,
            sell = 1000,
        },
        ['death ring'] = {
            clientId = 6299,
            sell = 1000,
        },
        ['deepling squelcher'] = {
            clientId = 14250,
            sell = 7000,
        },
        ['deepling staff'] = {
            clientId = 13987,
            sell = 4000,
        },
        ['devil helmet'] = {
            clientId = 3356,
            sell = 1000,
        },
        ['diamond sceptre'] = {
            clientId = 7387,
            sell = 3000,
        },
        ['dragon hammer'] = {
            clientId = 3322,
            sell = 2000,
        },
        ['dragon lance'] = {
            clientId = 3302,
            sell = 9000,
        },
        ['dragon shield'] = {
            clientId = 3416,
            sell = 4000,
        },
        ['dragonbone staff'] = {
            clientId = 7430,
            sell = 3000,
        },
        ['dream blossom staff'] = {
            clientId = 25700,
            sell = 5000,
        },
        ['dwarven axe'] = {
            clientId = 3323,
            sell = 1500,
        },
        ['elvish bow'] = {
            clientId = 7438,
            sell = 2000,
        },
        ['epee'] = {
            clientId = 3326,
            sell = 8000,
        },
        ['fire axe'] = {
            clientId = 3320,
            sell = 8000,
        },
        ['fire sword'] = {
            clientId = 3280,
            sell = 4000,
        },
        ['focus cape'] = {
            clientId = 8043,
            sell = 6000,
        },
        ['fur armor'] = {
            clientId = 22085,
            sell = 5000,
        },
        ['fur boots'] = {
            clientId = 7457,
            sell = 2000,
        },
        ['furry club'] = {
            clientId = 7432,
            sell = 1000,
        },
        ['glacial rod'] = {
            clientId = 16118,
            sell = 6500,
        },
        ['glacier amulet'] = {
            clientId = 815,
            sell = 1500,
        },
        ['glacier mask'] = {
            clientId = 829,
            sell = 2500,
        },
        ['glacier shoes'] = {
            clientId = 819,
            sell = 2500,
        },
        ['glooth axe'] = {
            clientId = 21180,
            sell = 1500,
        },
        ['glooth blade'] = {
            clientId = 21179,
            sell = 1500,
        },
        ['glooth cap'] = {
            clientId = 21164,
            sell = 7000,
        },
        ['glooth club'] = {
            clientId = 21178,
            sell = 1500,
        },
        ['glooth whip'] = {
            clientId = 21172,
            sell = 2500,
        },
        ['glorious axe'] = {
            clientId = 7454,
            sell = 3000,
        },
        ['griffin shield'] = {
            clientId = 3433,
            sell = 3000,
        },
        ['guardian axe'] = {
            clientId = 14043,
            sell = 9000,
        },
        ['guardian shield'] = {
            clientId = 3415,
            sell = 2000,
        },
        ['hailstorm rod'] = {
            clientId = 3067,
            sell = 3000,
        },
        ['haunted blade'] = {
            clientId = 7407,
            sell = 8000,
        },
        ['headchopper'] = {
            clientId = 7380,
            sell = 6000,
        },
        ['heavy trident'] = {
            clientId = 12683,
            sell = 2000,
        },
        ['helmet of the lost'] = {
            clientId = 17852,
            sell = 2000,
        },
        ['hibiscus dress'] = {
            clientId = 8045,
            sell = 3000,
        },
        ['ice rapier'] = {
            clientId = 3284,
            sell = 1000,
        },
        ['jade hat'] = {
            clientId = 10451,
            sell = 9000,
        },
        ['knight armor'] = {
            clientId = 3370,
            sell = 5000,
        },
        ['knight axe'] = {
            clientId = 3318,
            sell = 2000,
        },
        ['knight legs'] = {
            clientId = 3371,
            sell = 5000,
        },
        ['leopard armor'] = {
            clientId = 3404,
            sell = 1000,
        },
        ['lightning boots'] = {
            clientId = 820,
            sell = 2500,
        },
        ['lightning headband'] = {
            clientId = 828,
            sell = 2500,
        },
        ['lightning pendant'] = {
            clientId = 816,
            sell = 1500,
        },
        ['lunar staff'] = {
            clientId = 7424,
            sell = 5000,
        },
        ['magma boots'] = {
            clientId = 818,
            sell = 2500,
        },
        ['magma monocle'] = {
            clientId = 827,
            sell = 2500,
        },
        ['mammoth fur cape'] = {
            clientId = 7463,
            sell = 6000,
        },
        ['medusa shield'] = {
            clientId = 3436,
            sell = 9000,
        },
        ['mercurial wing'] = {
            clientId = 39395,
            sell = 2500,
        },
        ['metal bat'] = {
            clientId = 21171,
            sell = 9000,
        },
        ['metal spats'] = {
            clientId = 21169,
            sell = 2000,
        },
        ['mino lance'] = {
            clientId = 21174,
            sell = 7000,
        },
        ['mino shield'] = {
            clientId = 21175,
            sell = 3000,
        },
        ['mooh\'tah plate'] = {
            clientId = 21166,
            sell = 6000,
        },
        ['muck rod'] = {
            clientId = 16117,
            sell = 6000,
        },
        ['naginata'] = {
            clientId = 3314,
            sell = 2000,
        },
        ['necrotic rod'] = {
            clientId = 3069,
            sell = 1000,
        },
        ['norse shield'] = {
            clientId = 7460,
            sell = 1500,
        },
        ['northwind rod'] = {
            clientId = 8083,
            sell = 1500,
        },
        ['ogre choppa'] = {
            clientId = 22172,
            sell = 1500,
        },
        ['ogre klubba'] = {
            clientId = 22171,
            sell = 2500,
        },
        ['ogre scepta'] = {
            clientId = 22183,
            sell = 3600,
        },
        ['orcish maul'] = {
            clientId = 7392,
            sell = 6000,
        },
        ['ornamented shield'] = {
            clientId = 3424,
            sell = 1500,
        },
        ['patched boots'] = {
            clientId = 3550,
            sell = 2000,
        },
        ['platinum amulet'] = {
            clientId = 3055,
            sell = 2500,
        },
        ['rod'] = {
            clientId = 33929,
            sell = 2200,
        },
        ['sapphire hammer'] = {
            clientId = 7437,
            sell = 7000,
        },
        ['scarab shield'] = {
            clientId = 3440,
            sell = 2000,
        },
        ['skull staff'] = {
            clientId = 3324,
            sell = 6000,
        },
        ['spellbook of enlightenment'] = {
            clientId = 8072,
            sell = 4000,
        },
        ['spellbook of warding'] = {
            clientId = 8073,
            sell = 8000,
        },
        ['spike sword'] = {
            clientId = 3271,
            sell = 1000,
        },
        ['spiked squelcher'] = {
            clientId = 7452,
            sell = 5000,
        },
        ['springsprout rod'] = {
            clientId = 8084,
            sell = 3600,
        },
        ['terra boots'] = {
            clientId = 813,
            sell = 2500,
        },
        ['terra hood'] = {
            clientId = 830,
            sell = 2500,
        },
        ['terra rod'] = {
            clientId = 3065,
            sell = 2000,
        },
        ['titan axe'] = {
            clientId = 7413,
            sell = 4000,
        },
        ['tower shield'] = {
            clientId = 3428,
            sell = 8000,
        },
        ['underworld rod'] = {
            clientId = 8082,
            sell = 4400,
        },
        ['wand of cosmic energy'] = {
            clientId = 3073,
            sell = 2000,
        },
        ['wand of decay'] = {
            clientId = 3072,
            sell = 1000,
        },
        ['wand of defiance'] = {
            clientId = 16096,
            sell = 6500,
        },
        ['wand of draconia'] = {
            clientId = 8093,
            sell = 1500,
        },
        ['wand of everblazing'] = {
            clientId = 16115,
            sell = 6000,
        },
        ['wand of inferno'] = {
            clientId = 3071,
            sell = 3000,
        },
        ['wand of starstorm'] = {
            clientId = 8092,
            sell = 3600,
        },
        ['wand of voodoo'] = {
            clientId = 8094,
            sell = 4400,
        },
        ['war hammer'] = {
            clientId = 3279,
            sell = 1200,
        },
        ['warrior helmet'] = {
            clientId = 3369,
            sell = 5000,
        },
        ['warrior\'s shield'] = {
            clientId = 14042,
            sell = 9000,
        },
        ['wereboar loincloth'] = {
            clientId = 22087,
            sell = 1500,
        },
        ['witch hat'] = {
            clientId = 9653,
            sell = 5000,
        },
        ['wood cape'] = {
            clientId = 3575,
            sell = 5000,
        },
        ['wyvern fang'] = {
            clientId = 7408,
            sell = 1500,
        },
        ['zaoan shoes'] = {
            clientId = 10386,
            sell = 5000,
        },
        ['collar of blue plasma'] = {
            clientId = 23542,
            sell = 6000,
        },
        ['collar of green plasma'] = {
            clientId = 23543,
            sell = 6000,
        },
        ['collar of red plasma'] = {
            clientId = 23544,
            sell = 6000,
        },
        ['gearwheel chain'] = {
            clientId = 21170,
            sell = 5000,
        },
        ['glooth amulet'] = {
            clientId = 21183,
            sell = 2000,
        },
        ['leviathan\'s amulet'] = {
            clientId = 9303,
            sell = 3000,
        },
        ['magma amulet'] = {
            clientId = 817,
            sell = 1500,
        },
        ['onyx pendant'] = {
            clientId = 22195,
            sell = 3500,
        },
        ['ruby necklace'] = {
            clientId = 3016,
            sell = 2000,
        },
        ['sacred tree amulet'] = {
            clientId = 9302,
            sell = 3000,
        },
        ['shockwave amulet'] = {
            clientId = 9304,
            sell = 3000,
        },
        ['terra amulet'] = {
            clientId = 814,
            sell = 1500,
        },
        ['wailing widow\'s necklace'] = {
            clientId = 10412,
            sell = 3000,
        },
        ['werewolf amulet'] = {
            clientId = 22060,
            sell = 3000,
        },
        ['ring of blue plasma'] = {
            clientId = 23529,
            sell = 8000,
        },
        ['ring of green plasma'] = {
            clientId = 23531,
            sell = 8000,
        },
        ['ring of red plasma'] = {
            clientId = 23533,
            sell = 8000,
        },
        ['blue crystal shard'] = {
            clientId = 16119,
            sell = 1500,
        },
        ['blue gem'] = {
            clientId = 3041,
            sell = 5000,
        },
        ['brown giant shimmering pearl'] = {
            clientId = 282,
            sell = 3000,
        },
        ['crown'] = {
            clientId = 33935,
            sell = 2700,
        },
        ['cry-stal'] = {
            clientId = 39394,
            sell = 3200,
        },
        ['crystal of balance'] = {
            clientId = 9028,
            sell = 1000,
        },
        ['crystal of focus'] = {
            clientId = 9027,
            sell = 2000,
        },
        ['crystal of power'] = {
            clientId = 9067,
            sell = 3000,
        },
        ['death toll'] = {
            clientId = 32703,
            sell = 1000,
        },
        ['flawless ice crystal'] = {
            clientId = 942,
            sell = 5000,
        },
        ['gemmed figurine'] = {
            clientId = 24392,
            sell = 3500,
        },
        ['gold ingot'] = {
            clientId = 9058,
            sell = 5000,
        },
        ['gold ring'] = {
            clientId = 3063,
            sell = 8000,
        },
        ['golden amulet'] = {
            clientId = 3013,
            sell = 2000,
        },
        ['golden cheese wedge'] = {
            clientId = 35581,
            sell = 6000,
        },
        ['golden dustbin'] = {
            clientId = 35579,
            sell = 7000,
        },
        ['golden figurine'] = {
            clientId = 5799,
            sell = 3000,
        },
        ['golden sickle'] = {
            clientId = 3306,
            sell = 1000,
        },
        ['golden skull'] = {
            clientId = 35580,
            sell = 9000,
        },
        ['green crystal shard'] = {
            clientId = 16121,
            sell = 1500,
        },
        ['green gem'] = {
            clientId = 3038,
            sell = 5000,
        },
        ['green giant shimmering pearl'] = {
            clientId = 281,
            sell = 3000,
        },
        ['guardian gem'] = {
            clientId = 44603,
            sell = 5000,
        },
        ['lesser guardian gem'] = {
            clientId = 44602,
            sell = 1000,
        },
        ['lesser marksman gem'] = {
            clientId = 44605,
            sell = 1000,
        },
        ['lesser mystic gem'] = {
            clientId = 44611,
            sell = 1000,
        },
        ['lesser sage gem'] = {
            clientId = 44608,
            sell = 1000,
        },
        ['marksman gem'] = {
            clientId = 44606,
            sell = 5000,
        },
        ['mystic gem'] = {
            clientId = 44612,
            sell = 5000,
        },
        ['purple tome'] = {
            clientId = 2848,
            sell = 2000,
        },
        ['red gem'] = {
            clientId = 3039,
            sell = 1000,
        },
        ['red tome'] = {
            clientId = 2852,
            sell = 2000,
        },
        ['sage gem'] = {
            clientId = 44609,
            sell = 5000,
        },
        ['silver rune emblem explosion'] = {
            clientId = 11607,
            sell = 5000,
        },
        ['silver rune emblem heavy magic missile'] = {
            clientId = 11605,
            sell = 5000,
        },
        ['silver rune emblem sudden death'] = {
            clientId = 11609,
            sell = 5000,
        },
        ['silver rune emblem ultimate healing'] = {
            clientId = 11603,
            sell = 5000,
        },
        ['violet crystal shard'] = {
            clientId = 16120,
            sell = 1500,
        },
        ['yellow gem'] = {
            clientId = 3037,
            sell = 1000,
        },
        ['behemoth claw'] = {
            clientId = 5930,
            sell = 2000,
        },
        ['demonic essence'] = {
            clientId = 6499,
            sell = 1000,
        },
        ['dragon claw'] = {
            clientId = 5919,
            sell = 8000,
        },
        ['iced soil'] = {
            clientId = 944,
            sell = 2000,
        },
        ['energy soil'] = {
            clientId = 945,
            sell = 2000,
        },
        ['magic sulphur'] = {
            clientId = 5904,
            sell = 8000,
        },
        ['mandrake'] = {
            clientId = 5014,
            sell = 5000,
        },
        ['mother soil'] = {
            clientId = 947,
            sell = 5000,
        },
        ['natural soil'] = {
            clientId = 940,
            sell = 2000,
        },
        ['necklace of the deep'] = {
            clientId = 13990,
            sell = 3000,
        },
        ['nose ring'] = {
            clientId = 5804,
            sell = 2000,
        },
        ['piece of draconian steel'] = {
            clientId = 5889,
            sell = 3000,
        },
        ['shard'] = {
            clientId = 7290,
            sell = 2000,
        },
        ['sniper gloves'] = {
            clientId = 5875,
            sell = 2000,
        },
        ['soul stone'] = {
            clientId = 5809,
            sell = 6000,
        },
        ['spool of yarn'] = {
            clientId = 5886,
            sell = 1000,
        },
        ['bat decoration'] = {
            clientId = 6491,
            sell = 2000,
        },
        ['bonebeast trophy'] = {
            clientId = 10244,
            sell = 6000,
        },
        ['deer trophy'] = {
            clientId = 7397,
            sell = 3000,
        },
        ['disgusting trophy'] = {
            clientId = 10421,
            sell = 3000,
        },
        ['dracoyle statue'] = {
            clientId = 9034,
            sell = 5000,
        },
        ['lion trophy'] = {
            clientId = 7400,
            sell = 3000,
        },
        ['lizard trophy'] = {
            clientId = 10419,
            sell = 8000,
        },
        ['marlin trophy'] = {
            clientId = 902,
            sell = 5000,
        },
        ['model ship'] = {
            clientId = 2994,
            sell = 1000,
        },
        ['pet pig'] = {
            clientId = 16165,
            sell = 1500,
        },
        ['silver fafnar trophy'] = {
            clientId = 9627,
            sell = 1000,
        },
        ['skeleton decoration'] = {
            clientId = 6525,
            sell = 3000,
        },
        ['souleater trophy'] = {
            clientId = 11679,
            sell = 7500,
        },
        ['statue of abyssador'] = {
            clientId = 16232,
            sell = 4000,
        },
        ['statue of deathstrike'] = {
            clientId = 16236,
            sell = 3000,
        },
        ['statue of devovorga'] = {
            clientId = 4065,
            sell = 1500,
        },
        ['statue of gnomevil'] = {
            clientId = 16240,
            sell = 2000,
        },
        ['stuffed dragon'] = {
            clientId = 5791,
            sell = 6000,
        },
        ['trophy of jaul'] = {
            clientId = 14006,
            sell = 4000,
        },
        ['trophy of obujos'] = {
            clientId = 14002,
            sell = 3000,
        },
        ['trophy of tanjis'] = {
            clientId = 14004,
            sell = 2000,
        },
        ['werebadger trophy'] = {
            clientId = 22101,
            sell = 9000,
        },
        ['werefox trophy'] = {
            clientId = 27706,
            sell = 9000,
        },
        ['wolf trophy'] = {
            clientId = 7394,
            sell = 3000,
        },
    },
    ['grey'] = {
        ['afflicted strider head'] = {
            clientId = 36789,
            sell = 900,
        },
        ['afflicted strider worms'] = {
            clientId = 36790,
            sell = 500,
        },
        ['ancient belt buckle'] = {
            clientId = 24384,
            sell = 260,
        },
        ['antlers'] = {
            clientId = 10297,
            sell = 50,
        },
        ['banana sash'] = {
            clientId = 11511,
            sell = 55,
        },
        ['basalt fetish'] = {
            clientId = 17856,
            sell = 210,
        },
        ['bashmu fang'] = {
            clientId = 36820,
            sell = 600,
        },
        ['bashmu feather'] = {
            clientId = 36823,
            sell = 350,
        },
        ['bashmu tongue'] = {
            clientId = 36821,
            sell = 400,
        },
        ['bed of nails'] = {
            clientId = 25743,
            sell = 500,
        },
        ['beer tap'] = {
            clientId = 32114,
            sell = 50,
        },
        ['beetle carapace'] = {
            clientId = 24381,
            sell = 200,
        },
        ['black hood'] = {
            clientId = 9645,
            sell = 190,
        },
        ['black wool'] = {
            clientId = 11448,
            sell = 300,
        },
        ['blazing bone'] = {
            clientId = 16131,
            sell = 610,
        },
        ['blemished spawn abdomen'] = {
            clientId = 36779,
            sell = 550,
        },
        ['blemished spawn head'] = {
            clientId = 36778,
            sell = 800,
        },
        ['blood preservation'] = {
            clientId = 11449,
            sell = 320,
        },
        ['blood tincture in a vial'] = {
            clientId = 18928,
            sell = 360,
        },
        ['bloody dwarven beard'] = {
            clientId = 17827,
            sell = 110,
        },
        ['bloody pincers'] = {
            clientId = 9633,
            sell = 100,
        },
        ['blue glass plate'] = {
            clientId = 29345,
            sell = 60,
        },
        ['blue goanna scale'] = {
            clientId = 31559,
            sell = 230,
        },
        ['boar man hoof'] = {
            clientId = 40584,
            sell = 600,
        },
        ['boggy dreads'] = {
            clientId = 9667,
            sell = 200,
        },
        ['bone fetish'] = {
            clientId = 17831,
            sell = 150,
        },
        ['bone shoulderplate'] = {
            clientId = 10404,
            sell = 150,
        },
        ['bone toothpick'] = {
            clientId = 24380,
            sell = 150,
        },
        ['bonecarving knife'] = {
            clientId = 17830,
            sell = 190,
        },
        ['bony tail'] = {
            clientId = 10277,
            sell = 210,
        },
        ['book of necromantic rituals'] = {
            clientId = 10320,
            sell = 180,
        },
        ['book of prayers'] = {
            clientId = 9646,
            sell = 120,
        },
        ['book page'] = {
            clientId = 28569,
            sell = 640,
        },
        ['bowl of terror sweat'] = {
            clientId = 20204,
            sell = 500,
        },
        ['bright bell'] = {
            clientId = 30324,
            sell = 220,
        },
        ['brimstone fangs'] = {
            clientId = 11702,
            sell = 380,
        },
        ['brimstone shell'] = {
            clientId = 11703,
            sell = 210,
        },
        ['broken bell'] = {
            clientId = 30185,
            sell = 150,
        },
        ['broken draken mail'] = {
            clientId = 11660,
            sell = 340,
        },
        ['broken gladiator shield'] = {
            clientId = 9656,
            sell = 190,
        },
        ['broken halberd'] = {
            clientId = 10418,
            sell = 100,
        },
        ['broken iks faulds'] = {
            clientId = 40531,
            sell = 530,
        },
        ['broken iks headpiece'] = {
            clientId = 40532,
            sell = 560,
        },
        ['broken iks sandals'] = {
            clientId = 40534,
            sell = 440,
        },
        ['broken longbow'] = {
            clientId = 34161,
            sell = 130,
        },
        ['broken slicer'] = {
            clientId = 11661,
            sell = 120,
        },
        ['broken throwing axe'] = {
            clientId = 17851,
            sell = 230,
        },
        ['bunch of ripe rice'] = {
            clientId = 10328,
            sell = 75,
        },
        ['bundle of cursed straw'] = {
            clientId = 9688,
            sell = 800,
        },
        ['carniphila seeds'] = {
            clientId = 10300,
            sell = 50,
        },
        ['carnisylvan bark'] = {
            clientId = 36806,
            sell = 230,
        },
        ['carnisylvan finger'] = {
            clientId = 36805,
            sell = 250,
        },
        ['carnivostrich feathers'] = {
            clientId = 40586,
            sell = 550,
        },
        ['cave chimera leg'] = {
            clientId = 36788,
            sell = 650,
        },
        ['cave devourer eyes'] = {
            clientId = 27599,
            sell = 550,
        },
        ['cave devourer legs'] = {
            clientId = 27601,
            sell = 350,
        },
        ['cave devourer maw'] = {
            clientId = 27600,
            sell = 600,
        },
        ['cavebear skull'] = {
            clientId = 12316,
            sell = 550,
        },
        ['chasm spawn abdomen'] = {
            clientId = 27603,
            sell = 240,
        },
        ['chasm spawn head'] = {
            clientId = 27602,
            sell = 850,
        },
        ['chasm spawn tail'] = {
            clientId = 27604,
            sell = 120,
        },
        ['cheese cutter'] = {
            clientId = 17817,
            sell = 50,
        },
        ['cheesy figurine'] = {
            clientId = 17818,
            sell = 150,
        },
        ['cliff strider claw'] = {
            clientId = 16134,
            sell = 800,
        },
        ['closed trap'] = {
            clientId = 3481,
            sell = 75,
        },
        ['cobra crest'] = {
            clientId = 31678,
            sell = 650,
        },
        ['colourful feather'] = {
            clientId = 11514,
            sell = 110,
        },
        ['colourful feathers'] = {
            clientId = 25089,
            sell = 400,
        },
        ['colourful snail shell'] = {
            clientId = 25696,
            sell = 250,
        },
        ['compound eye'] = {
            clientId = 14083,
            sell = 150,
        },
        ['condensed energy'] = {
            clientId = 23501,
            sell = 260,
        },
        ['coral branch'] = {
            clientId = 39406,
            sell = 360,
        },
        ['coral brooch'] = {
            clientId = 24391,
            sell = 750,
        },
        ['corrupt naga scales'] = {
            clientId = 39415,
            sell = 570,
        },
        ['corrupted flag'] = {
            clientId = 10409,
            sell = 700,
        },
        ['cow bell'] = {
            clientId = 32012,
            sell = 120,
        },
        ['cowbell'] = {
            clientId = 21204,
            sell = 210,
        },
        ['crab man claw'] = {
            clientId = 40582,
            sell = 550,
        },
        ['crawler head plating'] = {
            clientId = 14079,
            sell = 210,
        },
        ['crystal bone'] = {
            clientId = 23521,
            sell = 250,
        },
        ['cultish mask'] = {
            clientId = 9638,
            sell = 280,
        },
        ['cultish robe'] = {
            clientId = 9639,
            sell = 150,
        },
        ['cultish symbol'] = {
            clientId = 11455,
            sell = 500,
        },
        ['curious matter'] = {
            clientId = 23511,
            sell = 430,
        },
        ['cursed shoulder spikes'] = {
            clientId = 10410,
            sell = 320,
        },
        ['cyclops toe'] = {
            clientId = 9657,
            sell = 55,
        },
        ['daedal chisel'] = {
            clientId = 40522,
            sell = 480,
        },
        ['damaged armor plates'] = {
            clientId = 28822,
            sell = 280,
        },
        ['dandelion seeds'] = {
            clientId = 25695,
            sell = 200,
        },
        ['dangerous proto matter'] = {
            clientId = 23515,
            sell = 300,
        },
        ['dark bell'] = {
            clientId = 30325,
            sell = 250,
        },
        ['dead weight'] = {
            clientId = 20202,
            sell = 450,
        },
        ['deepling breaktime snack'] = {
            clientId = 14011,
            sell = 90,
        },
        ['deepling claw'] = {
            clientId = 14044,
            sell = 430,
        },
        ['deepling guard belt buckle'] = {
            clientId = 14010,
            sell = 230,
        },
        ['deepling ridge'] = {
            clientId = 14041,
            sell = 360,
        },
        ['deepling scales'] = {
            clientId = 14017,
            sell = 80,
        },
        ['deepling warts'] = {
            clientId = 14012,
            sell = 180,
        },
        ['deeptags'] = {
            clientId = 14013,
            sell = 290,
        },
        ['deepworm jaws'] = {
            clientId = 27594,
            sell = 500,
        },
        ['deepworm spike roots'] = {
            clientId = 27593,
            sell = 650,
        },
        ['deepworm spikes'] = {
            clientId = 27592,
            sell = 800,
        },
        ['demonic skeletal hand'] = {
            clientId = 9647,
            sell = 80,
        },
        ['diremaw brainpan'] = {
            clientId = 27597,
            sell = 350,
        },
        ['diremaw legs'] = {
            clientId = 27598,
            sell = 270,
        },
        ['dirty turban'] = {
            clientId = 11456,
            sell = 120,
        },
        ['dragon blood'] = {
            clientId = 24937,
            sell = 700,
        },
        ['dragon priest\'s wandtip'] = {
            clientId = 10444,
            sell = 175,
        },
        ['dragon tongue'] = {
            clientId = 24938,
            sell = 550,
        },
        ['dragon\'s tail'] = {
            clientId = 11457,
            sell = 100,
        },
        ['draken sulphur'] = {
            clientId = 11658,
            sell = 550,
        },
        ['draken wristbands'] = {
            clientId = 11659,
            sell = 430,
        },
        ['draptor scales'] = {
            clientId = 12309,
            sell = 800,
        },
        ['dream essence egg'] = {
            clientId = 30005,
            sell = 205,
        },
        ['dung ball'] = {
            clientId = 14225,
            sell = 130,
        },
        ['elder bonelord tentacle'] = {
            clientId = 10276,
            sell = 150,
        },
        ['elven astral observer'] = {
            clientId = 11465,
            sell = 90,
        },
        ['elven hoof'] = {
            clientId = 18994,
            sell = 115,
        },
        ['elven scouting glass'] = {
            clientId = 11464,
            sell = 50,
        },
        ['empty honey glass'] = {
            clientId = 31331,
            sell = 270,
        },
        ['energy ball'] = {
            clientId = 23523,
            sell = 300,
        },
        ['energy vein'] = {
            clientId = 23508,
            sell = 270,
        },
        ['ensouled essence'] = {
            clientId = 32698,
            sell = 820,
        },
        ['essence of a bad dream'] = {
            clientId = 10306,
            sell = 360,
        },
        ['execowtioner mask'] = {
            clientId = 21201,
            sell = 240,
        },
        ['ethno coat'] = {
            clientId = 8064,
            sell = 200,
        },
        ['eye of a deepling'] = {
            clientId = 12730,
            sell = 150,
        },
        ['eye of a weeper'] = {
            clientId = 16132,
            sell = 650,
        },
        ['eye of corruption'] = {
            clientId = 11671,
            sell = 390,
        },
        ['eyeless devourer legs'] = {
            clientId = 36776,
            sell = 650,
        },
        ['eyeless devourer maw'] = {
            clientId = 36775,
            sell = 420,
        },
        ['eyeless devourer tongue'] = {
            clientId = 36777,
            sell = 900,
        },
        ['fafnar symbol'] = {
            clientId = 31443,
            sell = 950,
        },
        ['fairy wings'] = {
            clientId = 25694,
            sell = 200,
        },
        ['falcon crest'] = {
            clientId = 28823,
            sell = 650,
        },
        ['fiery heart'] = {
            clientId = 9636,
            sell = 375,
        },
        ['fig leaf'] = {
            clientId = 25742,
            sell = 200,
        },
        ['flotsam'] = {
            clientId = 39407,
            sell = 330,
        },
        ['flower wreath'] = {
            clientId = 9013,
            sell = 500,
        },
        ['fox paw'] = {
            clientId = 27462,
            sell = 100,
        },
        ['frazzle skin'] = {
            clientId = 20199,
            sell = 400,
        },
        ['frazzle tongue'] = {
            clientId = 20198,
            sell = 700,
        },
        ['frost giant pelt'] = {
            clientId = 9658,
            sell = 160,
        },
        ['frosty heart'] = {
            clientId = 9661,
            sell = 280,
        },
        ['gauze bandage'] = {
            clientId = 9649,
            sell = 90,
        },
        ['gear crystal'] = {
            clientId = 9655,
            sell = 200,
        },
        ['gear wheel'] = {
            clientId = 8775,
            sell = 500,
        },
        ['fur shred'] = {
            clientId = 34164,
            sell = 200,
        },
        ['geomancer\'s robe'] = {
            clientId = 11458,
            sell = 80,
        },
        ['geomancer\'s staff'] = {
            clientId = 11463,
            sell = 120,
        },
        ['ghastly dragon head'] = {
            clientId = 10449,
            sell = 700,
        },
        ['ghostly tissue'] = {
            clientId = 9690,
            sell = 90,
        },
        ['ghoul snack'] = {
            clientId = 11467,
            sell = 60,
        },
        ['giant crab pincer'] = {
            clientId = 12317,
            sell = 950,
        },
        ['giant eye'] = {
            clientId = 10280,
            sell = 380,
        },
        ['girtablilu warrior carapace'] = {
            clientId = 36971,
            sell = 520,
        },
        ['gland'] = {
            clientId = 8143,
            sell = 500,
        },
        ['glistening bone'] = {
            clientId = 23522,
            sell = 250,
        },
        ['glob of glooth'] = {
            clientId = 21182,
            sell = 125,
        },
        ['gloom wolf fur'] = {
            clientId = 22007,
            sell = 70,
        },
        ['glooth injection tube'] = {
            clientId = 21103,
            sell = 350,
        },
        ['goanna claw'] = {
            clientId = 31561,
            sell = 260,
        },
        ['goanna meat'] = {
            clientId = 31560,
            sell = 190,
        },
        ['goat grass'] = {
            clientId = 3674,
            sell = 50,
        },
        ['goosebump leather'] = {
            clientId = 20205,
            sell = 650,
        },
        ['grant of arms'] = {
            clientId = 28824,
            sell = 950,
        },
        ['grappling hook'] = {
            clientId = 35588,
            sell = 150,
        },
        ['green bandage'] = {
            clientId = 25697,
            sell = 180,
        },
        ['green glass plate'] = {
            clientId = 29346,
            sell = 180,
        },
        ['guidebook'] = {
            clientId = 25745,
            sell = 200,
        },
        ['hair of a banshee'] = {
            clientId = 11446,
            sell = 350,
        },
        ['half-digested piece of meat'] = {
            clientId = 10283,
            sell = 55,
        },
        ['half-eaten brain'] = {
            clientId = 9659,
            sell = 85,
        },
        ['harpy feathers'] = {
            clientId = 40585,
            sell = 730,
        },
        ['haunted piece of wood'] = {
            clientId = 9683,
            sell = 115,
        },
        ['heaven blossom'] = {
            clientId = 5921,
            sell = 50,
        },
        ['heavy machete'] = {
            clientId = 3330,
            sell = 90,
        },
        ['hellhound slobber'] = {
            clientId = 9637,
            sell = 500,
        },
        ['hellspawn tail'] = {
            clientId = 10304,
            sell = 475,
        },
        ['hemp rope'] = {
            clientId = 20206,
            sell = 350,
        },
        ['hideous chunk'] = {
            clientId = 16140,
            sell = 510,
        },
        ['hieroglyph banner'] = {
            clientId = 12482,
            sell = 500,
        },
        ['high guard flag'] = {
            clientId = 10415,
            sell = 550,
        },
        ['high guard shoulderplates'] = {
            clientId = 10416,
            sell = 130,
        },
        ['hollow stampor hoof'] = {
            clientId = 12314,
            sell = 400,
        },
        ['holy ash'] = {
            clientId = 17850,
            sell = 160,
        },
        ['horn'] = {
            clientId = 19359,
            sell = 300,
        },
        ['humongous chunk'] = {
            clientId = 16139,
            sell = 540,
        },
        ['hunter\'s quiver'] = {
            clientId = 11469,
            sell = 80,
        },
        ['hydra egg'] = {
            clientId = 4839,
            sell = 500,
        },
        ['hydra head'] = {
            clientId = 10282,
            sell = 600,
        },
        ['hydrophytes'] = {
            clientId = 39410,
            sell = 220,
        },
        ['ice flower'] = {
            clientId = 30058,
            sell = 370,
        },
        ['incantation notes'] = {
            clientId = 18929,
            sell = 90,
        },
        ['inkwell'] = {
            clientId = 28568,
            sell = 720,
        },
        ['instable proto matter'] = {
            clientId = 23516,
            sell = 300,
        },
        ['ivory carving'] = {
            clientId = 33945,
            sell = 300,
        },
        ['jewelled belt'] = {
            clientId = 11470,
            sell = 180,
        },
        ['jungle moa claw'] = {
            clientId = 39404,
            sell = 160,
        },
        ['jungle moa egg'] = {
            clientId = 39405,
            sell = 250,
        },
        ['jungle moa feather'] = {
            clientId = 39403,
            sell = 140,
        },
        ['katex\' blood'] = {
            clientId = 34100,
            sell = 210,
        },
        ['key to the drowned library'] = {
            clientId = 14009,
            sell = 330,
        },
        ['kollos shell'] = {
            clientId = 14077,
            sell = 420,
        },
        ['kongra\'s shoulderpad'] = {
            clientId = 11471,
            sell = 100,
        },
        ['lamassu hoof'] = {
            clientId = 31441,
            sell = 330,
        },
        ['lamassu horn'] = {
            clientId = 31442,
            sell = 240,
        },
        ['lancer beetle shell'] = {
            clientId = 10455,
            sell = 80,
        },
        ['lancet'] = {
            clientId = 18925,
            sell = 90,
        },
        ['lava fungus head'] = {
            clientId = 36785,
            sell = 900,
        },
        ['lava fungus ring'] = {
            clientId = 36786,
            sell = 390,
        },
        ['lavaworm spike roots'] = {
            clientId = 36769,
            sell = 600,
        },
        ['lavaworm spikes'] = {
            clientId = 36770,
            sell = 750,
        },
        ['legionnaire flags'] = {
            clientId = 10417,
            sell = 500,
        },
        ['liodile fang'] = {
            clientId = 40583,
            sell = 480,
        },
        ['lion cloak patch'] = {
            clientId = 34162,
            sell = 190,
        },
        ['lion crest'] = {
            clientId = 34160,
            sell = 270,
        },
        ['lion seal'] = {
            clientId = 34163,
            sell = 210,
        },
        ['lion\'s mane'] = {
            clientId = 9691,
            sell = 60,
        },
        ['little bowl of myrrh'] = {
            clientId = 25702,
            sell = 500,
        },
        ['lizard essence'] = {
            clientId = 11680,
            sell = 300,
        },
        ['lizard heart'] = {
            clientId = 31340,
            sell = 530,
        },
        ['lost basher\'s spike'] = {
            clientId = 17826,
            sell = 280,
        },
        ['lost bracers'] = {
            clientId = 17853,
            sell = 140,
        },
        ['lost husher\'s staff'] = {
            clientId = 17848,
            sell = 250,
        },
        ['lost soul'] = {
            clientId = 32227,
            sell = 120,
        },
        ['luminescent crystal pickaxe'] = {
            clientId = 32711,
            sell = 50,
        },
        ['lump of earth'] = {
            clientId = 10305,
            sell = 130,
        },
        ['mad froth'] = {
            clientId = 17854,
            sell = 80,
        },
        ['magma clump'] = {
            clientId = 16130,
            sell = 570,
        },
        ['makara fin'] = {
            clientId = 39401,
            sell = 350,
        },
        ['makara tongue'] = {
            clientId = 39402,
            sell = 320,
        },
        ['mantassin tail'] = {
            clientId = 11489,
            sell = 280,
        },
        ['manticore ear'] = {
            clientId = 31440,
            sell = 310,
        },
        ['manticore tail'] = {
            clientId = 31439,
            sell = 220,
        },
        ['marsh stalker beak'] = {
            clientId = 17461,
            sell = 65,
        },
        ['marsh stalker feather'] = {
            clientId = 17462,
            sell = 50,
        },
        ['maxilla'] = {
            clientId = 12315,
            sell = 250,
        },
        ['metal spike'] = {
            clientId = 10298,
            sell = 320,
        },
        ['metal toe'] = {
            clientId = 21198,
            sell = 430,
        },
        ['milk churn'] = {
            clientId = 32011,
            sell = 100,
        },
        ['minotaur horn'] = {
            clientId = 11472,
            sell = 75,
        },
        ['miraculum'] = {
            clientId = 11474,
            sell = 60,
        },
        ['mooh\'tah shell'] = {
            clientId = 21202,
            sell = 110,
        },
        ['moohtant horn'] = {
            clientId = 21200,
            sell = 140,
        },
        ['mouldy powder'] = {
            clientId = 35596,
            sell = 200,
        },
        ['mucus plug'] = {
            clientId = 16102,
            sell = 500,
        },
        ['mutated bat ear'] = {
            clientId = 9662,
            sell = 420,
        },
        ['mutated flesh'] = {
            clientId = 10308,
            sell = 50,
        },
        ['mutated rat tail'] = {
            clientId = 9668,
            sell = 150,
        },
        ['mysterious fetish'] = {
            clientId = 3078,
            sell = 50,
        },
        ['mystical hourglass'] = {
            clientId = 9660,
            sell = 700,
        },
        ['naga archer scales'] = {
            clientId = 39413,
            sell = 340,
        },
        ['naga armring'] = {
            clientId = 39411,
            sell = 390,
        },
        ['naga earring'] = {
            clientId = 39412,
            sell = 380,
        },
        ['naga warrior scales'] = {
            clientId = 39414,
            sell = 340,
        },
        ['necromantic robe'] = {
            clientId = 11475,
            sell = 250,
        },
        ['necromantic rust'] = {
            clientId = 21196,
            sell = 390,
        },
        ['nettle blossom'] = {
            clientId = 10314,
            sell = 75,
        },
        ['odd organ'] = {
            clientId = 23510,
            sell = 410,
        },
        ['ogre ear stud'] = {
            clientId = 22188,
            sell = 180,
        },
        ['ogre nose ring'] = {
            clientId = 22189,
            sell = 210,
        },
        ['old girtablilu carapace'] = {
            clientId = 36972,
            sell = 570,
        },
        ['old parchment'] = {
            clientId = 4831,
            sell = 500,
        },
        ['orc tooth'] = {
            clientId = 10196,
            sell = 150,
        },
        ['orc tusk'] = {
            clientId = 7786,
            sell = 700,
        },
        ['orcish gear'] = {
            clientId = 11477,
            sell = 85,
        },
        ['pair of old bracers'] = {
            clientId = 32705,
            sell = 500,
        },
        ['panpipes'] = {
            clientId = 2953,
            sell = 150,
        },
        ['panther head'] = {
            clientId = 12039,
            sell = 750,
        },
        ['panther paw'] = {
            clientId = 12040,
            sell = 300,
        },
        ['parder fur'] = {
            clientId = 39418,
            sell = 150,
        },
        ['parder tooth'] = {
            clientId = 39417,
            sell = 150,
        },
        ['peacock feather fan'] = {
            clientId = 21975,
            sell = 350,
        },
        ['percht horns'] = {
            clientId = 30186,
            sell = 200,
        },
        ['petrified scream'] = {
            clientId = 10420,
            sell = 250,
        },
        ['phantasmal hair'] = {
            clientId = 32704,
            sell = 500,
        },
        ['piece of dead brain'] = {
            clientId = 9663,
            sell = 420,
        },
        ['piece of hellfire armor'] = {
            clientId = 9664,
            sell = 550,
        },
        ['piece of warrior armor'] = {
            clientId = 11482,
            sell = 50,
        },
        ['pieces of magic chalk'] = {
            clientId = 18930,
            sell = 210,
        },
        ['pirat\'s tail'] = {
            clientId = 35573,
            sell = 180,
        },
        ['plasmatic lightning'] = {
            clientId = 23520,
            sell = 270,
        },
        ['poison gland'] = {
            clientId = 29348,
            sell = 210,
        },
        ['poisoned fang'] = {
            clientId = 21195,
            sell = 130,
        },
        ['poisonous slime'] = {
            clientId = 9640,
            sell = 50,
        },
        ['pool of chitinous glue'] = {
            clientId = 20207,
            sell = 480,
        },
        ['protective charm'] = {
            clientId = 11444,
            sell = 60,
        },
        ['pulverized ore'] = {
            clientId = 16133,
            sell = 400,
        },
        ['purified soul'] = {
            clientId = 32228,
            sell = 260,
        },
        ['purple robe'] = {
            clientId = 11473,
            sell = 110,
        },
        ['quara bone'] = {
            clientId = 11491,
            sell = 500,
        },
        ['quara eye'] = {
            clientId = 11488,
            sell = 350,
        },
        ['quara pincers'] = {
            clientId = 11490,
            sell = 410,
        },
        ['quara tentacle'] = {
            clientId = 11487,
            sell = 140,
        },
        ['rabbit\'s foot'] = {
            clientId = 12172,
            sell = 50,
        },
        ['rare earth'] = {
            clientId = 27301,
            sell = 80,
        },
        ['red goanna scale'] = {
            clientId = 31558,
            sell = 270,
        },
        ['red lantern'] = {
            clientId = 10289,
            sell = 250,
        },
        ['rhindeer antlers'] = {
            clientId = 40587,
            sell = 680,
        },
        ['rhino hide'] = {
            clientId = 24388,
            sell = 175,
        },
        ['rhino horn carving'] = {
            clientId = 24386,
            sell = 300,
        },
        ['rhino horn'] = {
            clientId = 24389,
            sell = 265,
        },
        ['ritual tooth'] = {
            clientId = 40528,
            sell = 135,
        },
        ['rogue naga scales'] = {
            clientId = 39416,
            sell = 570,
        },
        ['rope belt'] = {
            clientId = 11492,
            sell = 66,
        },
        ['rorc egg'] = {
            clientId = 18996,
            sell = 120,
        },
        ['rorc feather'] = {
            clientId = 18993,
            sell = 70,
        },
        ['rotten feather'] = {
            clientId = 40527,
            sell = 120,
        },
        ['sabretooth'] = {
            clientId = 10311,
            sell = 400,
        },
        ['safety pin'] = {
            clientId = 11493,
            sell = 120,
        },
        ['sample of monster blood'] = {
            clientId = 27874,
            sell = 250,
        },
        ['scale of corruption'] = {
            clientId = 11673,
            sell = 680,
        },
        ['scorpion charm'] = {
            clientId = 36822,
            sell = 620,
        },
        ['scroll of heroic deeds'] = {
            clientId = 11510,
            sell = 230,
        },
        ['scythe leg'] = {
            clientId = 10312,
            sell = 450,
        },
        ['scarab pincers'] = {
            clientId = 9631,
            sell = 280,
        },
        ['sea serpent scale'] = {
            clientId = 9666,
            sell = 520,
        },
        ['seacrest hair'] = {
            clientId = 21801,
            sell = 260,
        },
        ['seacrest scale'] = {
            clientId = 21800,
            sell = 150,
        },
        ['seeds'] = {
            clientId = 647,
            sell = 150,
        },
        ['shamanic talisman'] = {
            clientId = 22184,
            sell = 200,
        },
        ['shark fins'] = {
            clientId = 35574,
            sell = 250,
        },
        ['shimmering beetles'] = {
            clientId = 25693,
            sell = 150,
        },
        ['silencer claws'] = {
            clientId = 20200,
            sell = 390,
        },
        ['silencer resonating chamber'] = {
            clientId = 20201,
            sell = 600,
        },
        ['skull belt'] = {
            clientId = 11480,
            sell = 80,
        },
        ['skull fetish'] = {
            clientId = 22191,
            sell = 250,
        },
        ['skull shatterer'] = {
            clientId = 17849,
            sell = 170,
        },
        ['skunk tail'] = {
            clientId = 10274,
            sell = 50,
        },
        ['slime heart'] = {
            clientId = 21194,
            sell = 160,
        },
        ['slime mould'] = {
            clientId = 12601,
            sell = 175,
        },
        ['slimy leaf tentacle'] = {
            clientId = 21197,
            sell = 320,
        },
        ['small energy ball'] = {
            clientId = 23524,
            sell = 250,
        },
        ['small flask of eyedrops'] = {
            clientId = 11512,
            sell = 95,
        },
        ['small notebook'] = {
            clientId = 11450,
            sell = 480,
        },
        ['small oil lamp'] = {
            clientId = 2933,
            sell = 150,
        },
        ['small pitchfork'] = {
            clientId = 11513,
            sell = 70,
        },
        ['small tropical fish'] = {
            clientId = 39408,
            sell = 380,
        },
        ['snake skin'] = {
            clientId = 9694,
            sell = 400,
        },
        ['solid rage'] = {
            clientId = 23517,
            sell = 310,
        },
        ['spark sphere'] = {
            clientId = 23518,
            sell = 350,
        },
        ['sparkion claw'] = {
            clientId = 23502,
            sell = 290,
        },
        ['sparkion legs'] = {
            clientId = 23504,
            sell = 310,
        },
        ['sparkion stings'] = {
            clientId = 23505,
            sell = 280,
        },
        ['sparkion tail'] = {
            clientId = 23503,
            sell = 300,
        },
        ['spellsinger\'s seal'] = {
            clientId = 14008,
            sell = 280,
        },
        ['sphinx feather'] = {
            clientId = 31437,
            sell = 470,
        },
        ['sphinx tiara'] = {
            clientId = 31438,
            sell = 360,
        },
        ['spidris mandible'] = {
            clientId = 14082,
            sell = 450,
        },
        ['spiked iron ball'] = {
            clientId = 10408,
            sell = 100,
        },
        ['spiky club'] = {
            clientId = 17859,
            sell = 300,
        },
        ['spitter nose'] = {
            clientId = 14078,
            sell = 340,
        },
        ['spooky blue eye'] = {
            clientId = 9642,
            sell = 95,
        },
        ['srezz\' eye'] = {
            clientId = 34103,
            sell = 300,
        },
        ['stampor horn'] = {
            clientId = 12312,
            sell = 280,
        },
        ['stampor talons'] = {
            clientId = 12313,
            sell = 150,
        },
        ['stone nose'] = {
            clientId = 16137,
            sell = 590,
        },
        ['stone wing'] = {
            clientId = 10278,
            sell = 120,
        },
        ['stonerefiner\'s skull'] = {
            clientId = 27606,
            sell = 100,
        },
        ['strand of medusa hair'] = {
            clientId = 10309,
            sell = 600,
        },
        ['strange proto matter'] = {
            clientId = 23513,
            sell = 300,
        },
        ['strange symbol'] = {
            clientId = 3058,
            sell = 200,
        },
        ['streaked devourer eyes'] = {
            clientId = 36772,
            sell = 500,
        },
        ['streaked devourer legs'] = {
            clientId = 36774,
            sell = 600,
        },
        ['streaked devourer maw'] = {
            clientId = 36773,
            sell = 400,
        },
        ['striped fur'] = {
            clientId = 10293,
            sell = 50,
        },
        ['sulphurous stone'] = {
            clientId = 10315,
            sell = 100,
        },
        ['swarmer antenna'] = {
            clientId = 14076,
            sell = 130,
        },
        ['tail of corruption'] = {
            clientId = 11672,
            sell = 240,
        },
        ['tarantula egg'] = {
            clientId = 10281,
            sell = 80,
        },
        ['tarnished rhino figurine'] = {
            clientId = 24387,
            sell = 320,
        },
        ['tattered piece of robe'] = {
            clientId = 9684,
            sell = 120,
        },
        ['terramite eggs'] = {
            clientId = 10453,
            sell = 50,
        },
        ['terramite legs'] = {
            clientId = 10454,
            sell = 60,
        },
        ['terramite shell'] = {
            clientId = 10452,
            sell = 170,
        },
        ['terrorbird beak'] = {
            clientId = 10273,
            sell = 95,
        },
        ['thick fur'] = {
            clientId = 10307,
            sell = 150,
        },
        ['thorn'] = {
            clientId = 9643,
            sell = 100,
        },
        ['tiger eye'] = {
            clientId = 24961,
            sell = 350,
        },
        ['tooth file'] = {
            clientId = 18924,
            sell = 60,
        },
        ['torn shirt'] = {
            clientId = 25744,
            sell = 250,
        },
        ['trapped bad dream monster'] = {
            clientId = 20203,
            sell = 900,
        },
        ['tremendous tyrant head'] = {
            clientId = 36783,
            sell = 930,
        },
        ['tremendous tyrant shell'] = {
            clientId = 36784,
            sell = 740,
        },
        ['tribal mask'] = {
            clientId = 3403,
            sell = 250,
        },
        ['trollroot'] = {
            clientId = 11515,
            sell = 50,
        },
        ['tunnel tyrant head'] = {
            clientId = 27595,
            sell = 500,
        },
        ['tunnel tyrant shell'] = {
            clientId = 27596,
            sell = 700,
        },
        ['tusk'] = {
            clientId = 3044,
            sell = 100,
        },
        ['two-headed turtle heads'] = {
            clientId = 39409,
            sell = 460,
        },
        ['undead heart'] = {
            clientId = 10450,
            sell = 200,
        },
        ['unholy bone'] = {
            clientId = 10316,
            sell = 480,
        },
        ['utua\'s poison'] = {
            clientId = 34101,
            sell = 230,
        },
        ['vampire teeth'] = {
            clientId = 9685,
            sell = 275,
        },
        ['vampire\'s cape chain'] = {
            clientId = 18927,
            sell = 150,
        },
        ['varnished diremaw brainpan'] = {
            clientId = 36781,
            sell = 750,
        },
        ['varnished diremaw legs'] = {
            clientId = 36782,
            sell = 670,
        },
        ['vein of ore'] = {
            clientId = 16135,
            sell = 330,
        },
        ['venison'] = {
            clientId = 18995,
            sell = 55,
        },
        ['volatile proto matter'] = {
            clientId = 23514,
            sell = 300,
        },
        ['warmaster\'s wristguards'] = {
            clientId = 10405,
            sell = 200,
        },
        ['waspoid claw'] = {
            clientId = 14080,
            sell = 320,
        },
        ['waspoid wing'] = {
            clientId = 14081,
            sell = 190,
        },
        ['weaver\'s wandtip'] = {
            clientId = 10397,
            sell = 250,
        },
        ['werebadger claws'] = {
            clientId = 22051,
            sell = 160,
        },
        ['werebadger skull'] = {
            clientId = 22055,
            sell = 185,
        },
        ['werebear fur'] = {
            clientId = 22057,
            sell = 185,
        },
        ['werebear skull'] = {
            clientId = 22056,
            sell = 195,
        },
        ['wereboar hooves'] = {
            clientId = 22053,
            sell = 175,
        },
        ['wereboar tusk'] = {
            clientId = 22054,
            sell = 165,
        },
        ['werecrocodile tongue'] = {
            clientId = 43729,
            sell = 570,
        },
        ['werefox tail'] = {
            clientId = 27463,
            sell = 200,
        },
        ['werehyaena nose'] = {
            clientId = 33943,
            sell = 220,
        },
        ['werehyaena talisman'] = {
            clientId = 33944,
            sell = 350,
        },
        ['werepanther claw'] = {
            clientId = 43731,
            sell = 280,
        },
        ['weretiger tooth'] = {
            clientId = 43730,
            sell = 490,
        },
        ['werewolf fangs'] = {
            clientId = 22052,
            sell = 180,
        },
        ['werewolf fur'] = {
            clientId = 10317,
            sell = 380,
        },
        ['white deer antlers'] = {
            clientId = 12544,
            sell = 400,
        },
        ['white deer skin'] = {
            clientId = 12545,
            sell = 245,
        },
        ['widow\'s mandibles'] = {
            clientId = 10411,
            sell = 110,
        },
        ['wild flowers'] = {
            clientId = 25691,
            sell = 120,
        },
        ['wimp tooth chain'] = {
            clientId = 17847,
            sell = 120,
        },
        ['winged tail'] = {
            clientId = 10313,
            sell = 800,
        },
        ['witch broom'] = {
            clientId = 9652,
            sell = 60,
        },
        ['withered pauldrons'] = {
            clientId = 27607,
            sell = 850,
        },
        ['withered scalp'] = {
            clientId = 27608,
            sell = 900,
        },
        ['wyrm scale'] = {
            clientId = 9665,
            sell = 400,
        },
        ['wyvern talisman'] = {
            clientId = 9644,
            sell = 265,
        },
        ['yielocks'] = {
            clientId = 12805,
            sell = 600,
        },
        ['yielowax'] = {
            clientId = 12742,
            sell = 600,
        },
        ['yirkas\' egg'] = {
            clientId = 34102,
            sell = 280,
        },
        ['zaogun flag'] = {
            clientId = 10413,
            sell = 600,
        },
        ['zaogun\'s shoulderplates'] = {
            clientId = 10414,
            sell = 150,
        },
        ['ancient shield'] = {
            clientId = 3432,
            sell = 900,
        },
        ['bandana'] = {
            clientId = 5917,
            sell = 150,
        },
        ['battle axe'] = {
            clientId = 3266,
            sell = 80,
        },
        ['battle hammer'] = {
            clientId = 3305,
            sell = 120,
        },
        ['battle shield'] = {
            clientId = 3413,
            sell = 95,
        },
        ['belted cape'] = {
            clientId = 8044,
            sell = 500,
        },
        ['black shield'] = {
            clientId = 3429,
            sell = 800,
        },
        ['bone shield'] = {
            clientId = 3441,
            sell = 80,
        },
        ['brass armor'] = {
            clientId = 3359,
            sell = 150,
        },
        ['broadsword'] = {
            clientId = 3301,
            sell = 500,
        },
        ['carlin sword'] = {
            clientId = 3283,
            sell = 118,
        },
        ['chain armor'] = {
            clientId = 3358,
            sell = 70,
        },
        ['coconut shoes'] = {
            clientId = 9017,
            sell = 500,
        },
        ['copper shield'] = {
            clientId = 3430,
            sell = 50,
        },
        ['crowbar'] = {
            clientId = 3304,
            sell = 50,
        },
        ['crystal ring'] = {
            clientId = 3007,
            sell = 250,
        },
        ['crystal sword'] = {
            clientId = 7449,
            sell = 600,
        },
        ['crystalline spikes'] = {
            clientId = 16138,
            sell = 440,
        },
        ['daramian mace'] = {
            clientId = 3327,
            sell = 110,
        },
        ['dark armor'] = {
            clientId = 3383,
            sell = 400,
        },
        ['dark helmet'] = {
            clientId = 3384,
            sell = 250,
        },
        ['dark shield'] = {
            clientId = 3421,
            sell = 400,
        },
        ['double axe'] = {
            clientId = 3275,
            sell = 260,
        },
        ['dwarven shield'] = {
            clientId = 3425,
            sell = 100,
        },
        ['halberd'] = {
            clientId = 3269,
            sell = 400,
        },
        ['iron helmet'] = {
            clientId = 3353,
            sell = 150,
        },
        ['krimhorn helmet'] = {
            clientId = 7461,
            sell = 200,
        },
        ['leaf legs'] = {
            clientId = 9014,
            sell = 500,
        },
        ['leaf star'] = {
            clientId = 25735,
            sell = 50,
        },
        ['life preserver'] = {
            clientId = 17813,
            sell = 300,
        },
        ['light shovel'] = {
            clientId = 5710,
            sell = 300,
        },
        ['longsword'] = {
            clientId = 3285,
            sell = 51,
        },
        ['mammoth fur shorts'] = {
            clientId = 7464,
            sell = 850,
        },
        ['mammoth whopper'] = {
            clientId = 7381,
            sell = 300,
        },
        ['meat hammer'] = {
            clientId = 32093,
            sell = 60,
        },
        ['metal jaw'] = {
            clientId = 21193,
            sell = 260,
        },
        ['moonlight rod'] = {
            clientId = 3070,
            sell = 200,
        },
        ['morning star'] = {
            clientId = 3282,
            sell = 100,
        },
        ['mystic turban'] = {
            clientId = 3574,
            sell = 150,
        },
        ['noble armor'] = {
            clientId = 3380,
            sell = 900,
        },
        ['noble turban'] = {
            clientId = 11486,
            sell = 430,
        },
        ['obsidian lance'] = {
            clientId = 3313,
            sell = 500,
        },
        ['orcish axe'] = {
            clientId = 3316,
            sell = 350,
        },
        ['plate armor'] = {
            clientId = 3357,
            sell = 400,
        },
        ['plate legs'] = {
            clientId = 3557,
            sell = 115,
        },
        ['poison dagger'] = {
            clientId = 3299,
            sell = 50,
        },
        ['ragnir helmet'] = {
            clientId = 7462,
            sell = 400,
        },
        ['ratana'] = {
            clientId = 17812,
            sell = 500,
        },
        ['ripper lance'] = {
            clientId = 3346,
            sell = 500,
        },
        ['scale armor'] = {
            clientId = 3377,
            sell = 75,
        },
        ['scimitar'] = {
            clientId = 3307,
            sell = 150,
        },
        ['serpent sword'] = {
            clientId = 3297,
            sell = 900,
        },
        ['silver dagger'] = {
            clientId = 3290,
            sell = 500,
        },
        ['snakebite rod'] = {
            clientId = 3066,
            sell = 100,
        },
        ['spellwand'] = {
            clientId = 651,
            sell = 299,
        },
        ['spike shield'] = {
            clientId = 17810,
            sell = 250,
        },
        ['spirit cloak'] = {
            clientId = 8042,
            sell = 350,
        },
        ['steel helmet'] = {
            clientId = 3351,
            sell = 293,
        },
        ['steel shield'] = {
            clientId = 3409,
            sell = 80,
        },
        ['strange helmet'] = {
            clientId = 3373,
            sell = 500,
        },
        ['taurus mace'] = {
            clientId = 7425,
            sell = 500,
        },
        ['tortoise shield'] = {
            clientId = 6131,
            sell = 150,
        },
        ['twin hooks'] = {
            clientId = 10392,
            sell = 500,
        },
        ['two handed sword'] = {
            clientId = 3265,
            sell = 450,
        },
        ['viking helmet'] = {
            clientId = 3367,
            sell = 66,
        },
        ['viking shield'] = {
            clientId = 3431,
            sell = 85,
        },
        ['wand of dragonbreath'] = {
            clientId = 3075,
            sell = 200,
        },
        ['wand of vortex'] = {
            clientId = 3074,
            sell = 100,
        },
        ['zaoan halberd'] = {
            clientId = 10406,
            sell = 500,
        },
        ['ancient amulet'] = {
            clientId = 3025,
            sell = 200,
        },
        ['crystal necklace'] = {
            clientId = 3008,
            sell = 400,
        },
        ['garlic necklace'] = {
            clientId = 3083,
            sell = 50,
        },
        ['scarab amulet'] = {
            clientId = 3018,
            sell = 200,
        },
        ['star amulet'] = {
            clientId = 3014,
            sell = 500,
        },
        ['wolf tooth chain'] = {
            clientId = 3012,
            sell = 100,
        },
        ['axe ring'] = {
            clientId = 3092,
            sell = 100,
        },
        ['club ring'] = {
            clientId = 3093,
            sell = 100,
        },
        ['dwarven ring'] = {
            clientId = 3097,
            sell = 100,
        },
        ['energy ring'] = {
            clientId = 3051,
            sell = 100,
        },
        ['life ring'] = {
            clientId = 3052,
            sell = 50,
        },
        ['power ring'] = {
            clientId = 3050,
            sell = 50,
        },
        ['ring of healing'] = {
            clientId = 3098,
            sell = 100,
        },
        ['stealth ring'] = {
            clientId = 3049,
            sell = 200,
        },
        ['sword ring'] = {
            clientId = 3091,
            sell = 100,
        },
        ['time ring'] = {
            clientId = 3053,
            sell = 100,
        },
        ['wedding ring'] = {
            clientId = 3004,
            sell = 100,
        },
        ['ancient coin'] = {
            clientId = 24390,
            sell = 350,
        },
        ['ancient stone'] = {
            clientId = 9632,
            sell = 200,
        },
        ['ankh'] = {
            clientId = 3077,
            sell = 100,
        },
        ['basalt figurine'] = {
            clientId = 17857,
            sell = 160,
        },
        ['battle stone'] = {
            clientId = 11447,
            sell = 290,
        },
        ['black pearl'] = {
            clientId = 3027,
            sell = 280,
        },
        ['blue crystal splinter'] = {
            clientId = 16124,
            sell = 400,
        },
        ['broken iks cuirass'] = {
            clientId = 40533,
            sell = 640,
        },
        ['brown crystal splinter'] = {
            clientId = 16123,
            sell = 400,
        },
        ['cracked alabaster vase'] = {
            clientId = 24385,
            sell = 180,
        },
        ['crystal ball'] = {
            clientId = 3076,
            sell = 190,
        },
        ['crystallized anger'] = {
            clientId = 23507,
            sell = 400,
        },
        ['cyan crystal fragment'] = {
            clientId = 16125,
            sell = 800,
        },
        ['emerald bangle'] = {
            clientId = 3010,
            sell = 800,
        },
        ['explorer brooch'] = {
            clientId = 4871,
            sell = 50,
        },
        ['flintstone'] = {
            clientId = 12806,
            sell = 800,
        },
        ['frozen lightning'] = {
            clientId = 23519,
            sell = 270,
        },
        ['giant pacifier'] = {
            clientId = 21199,
            sell = 170,
        },
        ['glowing rune'] = {
            clientId = 28570,
            sell = 350,
        },
        ['gold nugget'] = {
            clientId = 3040,
            sell = 850,
        },
        ['gold-brocaded cloth'] = {
            clientId = 40529,
            sell = 175,
        },
        ['golden brush'] = {
            clientId = 25689,
            sell = 250,
        },
        ['golden lotus brooch'] = {
            clientId = 21974,
            sell = 270,
        },
        ['golden mug'] = {
            clientId = 2903,
            sell = 250,
        },
        ['green crystal fragment'] = {
            clientId = 16127,
            sell = 800,
        },
        ['green crystal splinter'] = {
            clientId = 16122,
            sell = 400,
        },
        ['life crystal'] = {
            clientId = 3061,
            sell = 85,
        },
        ['mind stone'] = {
            clientId = 3062,
            sell = 100,
        },
        ['onyx chip'] = {
            clientId = 22193,
            sell = 500,
        },
        ['opal'] = {
            clientId = 22194,
            sell = 500,
        },
        ['orb'] = {
            clientId = 3060,
            sell = 750,
        },
        ['pirate coin'] = {
            clientId = 35572,
            sell = 110,
        },
        ['plasma pearls'] = {
            clientId = 23506,
            sell = 250,
        },
        ['prismatic quartz'] = {
            clientId = 24962,
            sell = 450,
        },
        ['rainbow quartz'] = {
            clientId = 25737,
            sell = 800,
        },
        ['red crystal fragment'] = {
            clientId = 16126,
            sell = 800,
        },
        ['scarab coin'] = {
            clientId = 3042,
            sell = 100,
        },
        ['seacrest pearl'] = {
            clientId = 21747,
            sell = 400,
        },
        ['shiny stone'] = {
            clientId = 10310,
            sell = 500,
        },
        ['silver brooch'] = {
            clientId = 3017,
            sell = 150,
        },
        ['small amethyst'] = {
            clientId = 3033,
            sell = 200,
        },
        ['small diamond'] = {
            clientId = 3028,
            sell = 300,
        },
        ['small emerald'] = {
            clientId = 3032,
            sell = 250,
        },
        ['small enchanted amethyst'] = {
            clientId = 678,
            sell = 200,
        },
        ['small enchanted emerald'] = {
            clientId = 677,
            sell = 250,
        },
        ['small enchanted ruby'] = {
            clientId = 676,
            sell = 250,
        },
        ['small enchanted sapphire'] = {
            clientId = 675,
            sell = 250,
        },
        ['small ruby'] = {
            clientId = 3030,
            sell = 250,
        },
        ['small sapphire'] = {
            clientId = 3029,
            sell = 250,
        },
        ['small topaz'] = {
            clientId = 9057,
            sell = 200,
        },
        ['small treasure chest'] = {
            clientId = 35571,
            sell = 500,
        },
        ['spectral gold nugget'] = {
            clientId = 32724,
            sell = 500,
        },
        ['spectral silver nugget'] = {
            clientId = 32725,
            sell = 250,
        },
        ['spectral stone'] = {
            clientId = 4840,
            sell = 50,
        },
        ['talon'] = {
            clientId = 3034,
            sell = 320,
        },
        ['war crystal'] = {
            clientId = 9654,
            sell = 460,
        },
        ['white pearl'] = {
            clientId = 3026,
            sell = 160,
        },
        ['ape fur'] = {
            clientId = 5883,
            sell = 120,
        },
        ['bat wing'] = {
            clientId = 5894,
            sell = 50,
        },
        ['bear paw'] = {
            clientId = 5896,
            sell = 100,
        },
        ['blue piece of cloth'] = {
            clientId = 5912,
            sell = 200,
        },
        ['bonelord eye'] = {
            clientId = 5898,
            sell = 80,
        },
        ['brown piece of cloth'] = {
            clientId = 5913,
            sell = 100,
        },
        ['cluster of solace'] = {
            clientId = 20062,
            sell = 500,
        },
        ['demon dust'] = {
            clientId = 5906,
            sell = 300,
        },
        ['first verse of the hymn'] = {
            clientId = 6087,
            sell = 100,
        },
        ['fish fin'] = {
            clientId = 5895,
            sell = 150,
        },
        ['fourth verse of the hymn'] = {
            clientId = 6090,
            sell = 800,
        },
        ['green dragon leather'] = {
            clientId = 5877,
            sell = 100,
        },
        ['green dragon scale'] = {
            clientId = 5920,
            sell = 100,
        },
        ['green piece of cloth'] = {
            clientId = 5910,
            sell = 200,
        },
        ['hardened bone'] = {
            clientId = 5925,
            sell = 70,
        },
        ['holy orchid'] = {
            clientId = 5922,
            sell = 90,
        },
        ['iron ore'] = {
            clientId = 5880,
            sell = 500,
        },
        ['lizard leather'] = {
            clientId = 5876,
            sell = 150,
        },
        ['lizard scale'] = {
            clientId = 5881,
            sell = 120,
        },
        ['mammoth tusk'] = {
            clientId = 10321,
            sell = 100,
        },
        ['minotaur leather'] = {
            clientId = 5878,
            sell = 80,
        },
        ['perfect behemoth fang'] = {
            clientId = 5893,
            sell = 250,
        },
        ['piece of hell steel'] = {
            clientId = 5888,
            sell = 500,
        },
        ['pirate voodoo doll'] = {
            clientId = 5810,
            sell = 500,
        },
        ['red dragon leather'] = {
            clientId = 5948,
            sell = 200,
        },
        ['red dragon scale'] = {
            clientId = 5882,
            sell = 200,
        },
        ['red piece of cloth'] = {
            clientId = 5911,
            sell = 300,
        },
        ['second verse of the hymn'] = {
            clientId = 6088,
            sell = 250,
        },
        ['spider silk'] = {
            clientId = 5879,
            sell = 100,
        },
        ['third verse of the hymn'] = {
            clientId = 6089,
            sell = 400,
        },
        ['turtle shell'] = {
            clientId = 5899,
            sell = 90,
        },
        ['vampire dust'] = {
            clientId = 5905,
            sell = 100,
        },
        ['voodoo doll'] = {
            clientId = 3002,
            sell = 400,
        },
        ['white piece of cloth'] = {
            clientId = 5909,
            sell = 100,
        },
        ['wolf paw'] = {
            clientId = 5897,
            sell = 70,
        },
        ['yellow piece of cloth'] = {
            clientId = 5914,
            sell = 150,
        },
        ['blood herb'] = {
            clientId = 3734,
            sell = 500,
        },
        ['blue rose'] = {
            clientId = 3659,
            sell = 250,
        },
        ['crystal pedestal'] = {
            clientId = 9063,
            sell = 500,
        },
        ['cyclops trophy'] = {
            clientId = 7398,
            sell = 500,
        },
        ['doll'] = {
            clientId = 2991,
            sell = 200,
        },
        ['minotaur trophy'] = {
            clientId = 7401,
            sell = 500,
        },
        ['berserk potion'] = {
            clientId = 7439,
            sell = 500,
        },
        ['bullseye potion'] = {
            clientId = 7443,
            sell = 500,
        },
        ['mastermind potion'] = {
            clientId = 7440,
            sell = 500,
        },
        ['dark mushroom'] = {
            clientId = 3728,
            sell = 100,
        },
        ['ectoplasmic sushi'] = {
            clientId = 11681,
            sell = 300,
        },
        ['fire mushroom'] = {
            clientId = 3731,
            sell = 200,
        },
        ['green mushroom'] = {
            clientId = 3732,
            sell = 100,
        },
        ['orange mushroom'] = {
            clientId = 3726,
            sell = 150,
        },
    },
}

ItemsDatabase.rarityColors = {
    yellow = TextColors.yellow,
    purple = TextColors.purple,
    blue = TextColors.blue,
    green = TextColors.green,
    grey = TextColors.white,
}

--[[ python
import re

file_path = r'D:/kzn/github/canary2/data/scripts/lib/shops.lua'

with open(file_path, 'r') as file:
    lua_content = file.read()

pattern = re.compile(r'\{ itemName = "([^"]+)", clientId = (\d+), sell = (\d+) \}')

matches = pattern.findall(lua_content)

items_database = {
    'yellow': {},
    'purple': {},
    'blue': {},
    'green': {},
    'grey': {}
}

def categorize_sell(value):
    if value >= 1000000:
        return 'yellow'
    elif value >= 100000:
        return 'purple'
    elif value >= 10000:
        return 'blue'
    elif value >= 1000:
        return 'green'
    elif value >= 50:
        return 'grey'
    return None

for match in matches:
    item_name, client_id, sell = match
    client_id = int(client_id)
    sell = int(sell)
    category = categorize_sell(sell)
    if category:
        escaped_item_name = item_name.replace("'", "\\'")
        items_database[category][escaped_item_name] = {'clientId': client_id, 'sell': sell}

lua_output = ["ItemsDatabase.lib = {"]
for category, items in items_database.items():
    lua_output.append(f"    ['{category}'] = {{")
    for item_name, details in items.items():
        lua_output.append(f"        ['{item_name}'] = {{")
        lua_output.append(f"            clientId = {details['clientId']},")
        lua_output.append(f"            sell = {details['sell']},")
        lua_output.append(f"        }},")
    lua_output.append("    },")
lua_output.append("}")

lua_output_str = "\n".join(lua_output)
print(lua_output_str) ]]

-- LuaFormatter on

function ItemsDatabase.getRarityByClientId(clientID)
    for profile, data in pairs(ItemsDatabase.lib) do
        for k, itemDatabase in pairs(data) do
            if itemDatabase.clientId == tonumber(clientID) then
                return profile
            end
        end
    end
    return nil
end

function ItemsDatabase.setRarityItem(widget, item, style)

    if not widget then
        return
    end

    if item then
        local itemId = item:getId()

        local itemRarity = ItemsDatabase.getRarityByClientId(itemId)
        local imagePath = '/images/ui/item'
        if itemRarity and itemRarity:lower() ~= "normal" then
            imagePath = '/images/ui/rarity_' .. itemRarity:lower()
        end
        widget:setImageSource(imagePath)

    else
        --[[         widget:getParent():setItem(nil)
        widget:getParent():setImageSource('/images/ui/item') ]]
    end

    if style then
        widget:setStyle(style)
    end
end

function ItemsDatabase.getColorForRarity(rarity)
    return ItemsDatabase.rarityColors[rarity] or TextColors.white
end

function ItemsDatabase.setColorLootMessage(text)
    -- temp. TODO assets search
    local function coloringLootName(match)
        local id, itemName = match:match("(%d+)|(.+)")

        local itemInfo = ItemsDatabase.getRarityByClientId(tonumber(id))
        if itemInfo then
            local color = ItemsDatabase.getColorForRarity(itemInfo)
            return "{" .. itemName .. ", " .. color .. "}"
        else
            return itemName
        end

    end
    return (text:gsub("{(.-)}", coloringLootName))
end

function ItemsDatabase.getSellValueAndColor(clientID)
    for profile, data in pairs(ItemsDatabase.lib) do
        for k, itemDatabase in pairs(data) do
            if itemDatabase.clientId == tonumber(clientID) then
                return itemDatabase.sell, profile
            end
        end
    end
    return 0, ""
end
