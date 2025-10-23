KNIGHT = 1
PALADIN = 2
SORCERER = 3
DRUID = 4
MONK = 5

local WheelIcons = {
	-- knight
	[KNIGHT] = {
		[1] = {
			iconRect = "240 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[2] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[3] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[4] = {
			iconRect = "210 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[5] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[6] = {
			iconRect = "360 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[7] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[8] = {
			iconRect = "390 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[9] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[10] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[11] = {
			iconRect = "420 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[12] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[13] = {
			iconRect = "330 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[14] = {
			iconRect = "210 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[15] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[16] = {
			iconRect = "300 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[17] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[18] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[19] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[20] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[21] = {
			iconRect = "360 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[22] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[23] = {
			iconRect = "210 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[24] = {
			iconRect = "390 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[25] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[26] = {
			iconRect = "420 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[27] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[28] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[29] = {
			iconRect = "330 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[30] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[31] = {
			iconRect = "300 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[32] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[33] = {
			iconRect = "210 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[34] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[35] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[36] = {
			iconRect = "270 0 30 30",
			miniIconRect = "32 0 16 16",
		},
	},
	[PALADIN] = {
		[1] = {
			iconRect = "510 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[2] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[3] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[4] = {
			iconRect = "450 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[5] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[6] = {
			iconRect = "660 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[7] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[8] = {
			iconRect = "630 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[9] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[10] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[11] = {
			iconRect = "600 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[12] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[13] = {
			iconRect = "570 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[14] = {
			iconRect = "450 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[15] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[16] = {
			iconRect = "540 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[17] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[18] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[19] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[20] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[21] = {
			iconRect = "660 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[22] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[23] = {
			iconRect = "450 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[24] = {
			iconRect = "630 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[25] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[26] = {
			iconRect = "600 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[27] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[28] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[29] = {
			iconRect = "570 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[30] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[31] = {
			iconRect = "540 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[32] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[33] = {
			iconRect = "450 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[34] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[35] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[36] = {
			iconRect = "480 0 30 30",
			miniIconRect = "32 0 16 16",
		},
	},
	[SORCERER] = {
		[1] = {
			iconRect = "1050 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[2] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[3] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[4] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[5] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[6] = {
			iconRect = "810 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[7] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[8] = {
			iconRect = "1080 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[9] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[10] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[11] = {
			iconRect = "780 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[12] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[13] = {
			iconRect = "750 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[14] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[15] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[16] = {
			iconRect = "720 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[17] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[18] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[19] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[20] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[21] = {
			iconRect = "810 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[22] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[23] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[24] = {
			iconRect = "1080 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[25] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[26] = {
			iconRect = "780 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[27] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[28] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[29] = {
			iconRect = "750 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[30] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[31] = {
			iconRect = "720 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[32] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[33] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[34] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[35] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[36] = {
			iconRect = "810 0 30 30",
			miniIconRect = "32 0 16 16",
		},
	},
	[DRUID] = {
		[1] = {
			iconRect = "840 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[2] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[3] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[4] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[5] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[6] = {
			iconRect = "930 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[7] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[8] = {
			iconRect = "960 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[9] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[10] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[11] = {
			iconRect = "990 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[12] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[13] = {
			iconRect = "900 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[14] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[15] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[16] = {
			iconRect = "870 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[17] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[18] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[19] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[20] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[21] = {
			iconRect = "930 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[22] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[23] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[24] = {
			iconRect = "960 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[25] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[26] = {
			iconRect = "990 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[27] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[28] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[29] = {
			iconRect = "900 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[30] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[31] = {
			iconRect = "870 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[32] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[33] = {
			iconRect = "1020 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[34] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[35] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[36] = {
			iconRect = "1050 0 30 30",
			miniIconRect = "32 0 16 16",
		},
	},
	[MONK] = {
		[1] = {
			iconRect = "1260 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[2] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[3] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[4] = {
			iconRect = "1290 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[5] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[6] = {
			iconRect = "1410 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[7] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[8] = {
			iconRect = "1350 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[9] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[10] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[11] = {
			iconRect = "1380 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[12] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[13] = {
			iconRect = "1440 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[14] = {
			iconRect = "1290 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[15] = {
			iconRect = "1110 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[16] = {
			iconRect = "1320 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[17] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[18] = {
			iconRect = "1140 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[19] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[20] = {
			iconRect = "150 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[21] = {
			iconRect = "1410 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[22] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[23] = {
			iconRect = "1290 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[24] = {
			iconRect = "1350 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[25] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[26] = {
			iconRect = "1380 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[27] = {
			iconRect = "1170 0 30 30",
			miniIconRect = "0 0 16 16",
		},
		[28] = {
			iconRect = "150 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[29] = {
			iconRect = "1440 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[30] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[31] = {
			iconRect = "1320 0 30 30",
			miniIconRect = "32 0 16 16",
		},
		[32] = {
			iconRect = "180 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[33] = {
			iconRect = "1290 0 30 30",
			miniIconRect = "64 0 16 16",
		},
		[34] = {
			iconRect = "1200 0 30 30",
			miniIconRect = "48 0 16 16",
		},
		[35] = {
			iconRect = "180 0 30 30",
			miniIconRect = "16 0 16 16",
		},
		[36] = {
			iconRect = "1230 0 30 30",
			miniIconRect = "32 0 16 16",
		},
	},
}


local icons = {
	WheelIcons = WheelIcons,
}

return icons
