-- Minimal Archaeology

local AceAddon = LibStub("AceAddon-3.0");
MinArch = AceAddon:NewAddon('Minimal Archaeology');
MinArch.HelperFrame = CreateFrame("Frame", "MinArchHelper");

MinArchHideNext = false;
MinArchIsReady = false;
MinArchShowOnSurvey = true;
MinArchShowInDigsite = true;

MinArch.firstRun = true;
MinArch.artifacts = {};
MinArch.artifactbars = {};
MinArch.barlinks = {};
MinArch.raceButtons = {};
MinArch.frame = {};
MinArchOptions = {};
MinArchOptions.ABOptions = {};
MinArch.ArchaeologyRaces = {};
MinArch.MapContinents = {};
MinArch.RacesLoaded = false;
MinArch.RelevantRaces = {};
MinArch.qLineRaces = {ARCHAEOLOGY_RACE_DEMONIC, ARCHAEOLOGY_RACE_HIGHMOUNTAIN_TAUREN, ARCHAEOLOGY_RACE_HIGHBORNE};
MinArch.ResearchBranchMap = {
	[1] = ARCHAEOLOGY_RACE_DWARF, -- Dwarf
	[2] = ARCHAEOLOGY_RACE_DRAENEI, -- Draenei
	[3] = ARCHAEOLOGY_RACE_FOSSIL, -- Fossil
	[4] = ARCHAEOLOGY_RACE_NIGHTELF, -- Night Elf
	[5] = ARCHAEOLOGY_RACE_NERUBIAN, -- Nerubian
	[6] = ARCHAEOLOGY_RACE_ORC, -- Orc
	[7] = ARCHAEOLOGY_RACE_TOLVIR, -- Tol\'vir
	[8] = ARCHAEOLOGY_RACE_TROLL, -- Troll
	[27] = ARCHAEOLOGY_RACE_VRYKUL, -- Vrykul
	[29] = ARCHAEOLOGY_RACE_MANTID, -- Mantid
	[229] = ARCHAEOLOGY_RACE_PANDAREN, -- Pandaren
	[231] = ARCHAEOLOGY_RACE_MOGU, -- Mogu
	[315] = ARCHAEOLOGY_RACE_ARAKKOA, -- Arakkoa
	[350] = ARCHAEOLOGY_RACE_DRAENOR, -- Draenor Clans
	[382] = ARCHAEOLOGY_RACE_OGRE, -- Ogre
	[404] = ARCHAEOLOGY_RACE_HIGHBORNE, -- Highborne
	[406] = ARCHAEOLOGY_RACE_HIGHMOUNTAIN_TAUREN, -- Highmountain Tauren
	[408] = ARCHAEOLOGY_RACE_DEMONIC, -- Demonic
	[423] = ARCHAEOLOGY_RACE_ZANDALARI, -- Zandalari
	[424] = ARCHAEOLOGY_RACE_DRUSTVARI, -- Drust
};

-- MinArch.db.profile.
MinArch.defaults = {
	char = {
		TomTom = {
			waypoints = {}
		}
	},
	profile = {
		settingsVersion = 0,
		disableSound = false,
		startHidden = false,
		hideMain = false,
		frameScale = 100,
		showStatusMessages = false,
		showDebugMessages = false,
		showWorldMapOverlay = true,
		hideAfterDigsite = false,
		hideInCombat = false,
		waitForSolve = false,
		autoShowOnSurvey = false,
		autoShowOnSolve = false,
		autoShowInDigsites = false,
		autoShowOnCap = true,
		relevancy = {
			relevantOnly = false,
			nearby = true,
			continentSpecific = false,
			solvable = true
		},
		minimap = {
			minimapPos = 45,
			hide = false
		},
		TomTom = {
			enable = true,
			arrow = true,
			persistent = false,
			autoWayOnMove = false,
			autoWayOnComplete = true
		},
		
		-- dynamic options
		raceOptions = {
			hide = {},
			cap = {},
			keystone = {}
		},

		-- deprecated, left for compatibility
		hideMinimapButton = false, -- moved into minimap (databroker)
		minimapPos = 45,           -- not needed anymore (databroker)
	},	
}

MinArchRaceConfig = {};
for i=1, ARCHAEOLOGY_NUM_RACES do
    MinArchRaceConfig[i] = {};
end
MinArchRaceConfig[ARCHAEOLOGY_RACE_DRUSTVARI] = {
	texture = "Interface\\Archeology\\Arch-Race-Drustvari",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_ZANDALARI] = {
	texture = "Interface\\Archeology\\Arch-Race-Zandalari",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_DEMONIC] = {
	texture = "Interface\\Archeology\\Arch-Race-Demons",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_HIGHMOUNTAIN_TAUREN] = {
	texture = "Interface\\Archeology\\Arch-Race-HighmountainTauren",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_HIGHBORNE] = {
	texture = "Interface\\Archeology\\Arch-Race-HighborneNightElves",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_OGRE] = {
	texture = "Interface\\Archeology\\Arch-Race-Ogre",
	fragmentCap = 250,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_DRAENOR] = {
	texture = "Interface\\Archeology\\Arch-Race-DraenorOrc",
	fragmentCap = 250,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_ARAKKOA] = {
	texture = "Interface\\Archeology\\Arch-Race-Arakkoa",
	fragmentCap = 250,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_MOGU] = {
	texture = "Interface\\Archeology\\Arch-Race-Mogu",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_PANDAREN] = {
	texture = "Interface\\Archeology\\Arch-Race-Pandaren",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_MANTID] = {
	texture = "Interface\\Archeology\\Arch-Race-Mantid",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_VRYKUL] = {
	texture = "Interface\\Archeology\\Arch-Race-Vrykul",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_TROLL] = {
	texture = "Interface\\Archeology\\Arch-Race-Troll",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_TOLVIR] = {
	texture = "Interface\\Archeology\\Arch-Race-Tolvir",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_ORC] = {
	texture = "Interface\\Archeology\\Arch-Race-Orc",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_NERUBIAN] = {
	texture = "Interface\\Archeology\\Arch-Race-Nerubian",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_NIGHTELF] = {
	texture = "Interface\\Archeology\\Arch-Race-NightElf",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_FOSSIL] = {
	texture = "Interface\\Archeology\\Arch-Race-Fossil",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_DRAENEI] = {
	texture = "Interface\\Archeology\\Arch-Race-Draenei",
	fragmentCap = 200,
};
MinArchRaceConfig[ARCHAEOLOGY_RACE_DWARF] = {
	texture = "Interface\\Archeology\\Arch-Race-Dwarf",
	fragmentCap = 200,
};

SLASH_MINARCH1 = "/minarch"
SlashCmdList["MINARCH"] = function(msg, editBox)
	if (msg == "hide") then
		MinArch:HideMain();
	elseif (msg == "show") then
		MinArch:ShowMain();
	elseif (msg == "toggle") then
		MinArch:ToggleMain();
	elseif (msg == "version") then
		ChatFrame1:AddMessage("Minimal Archaeology "..tostring(GetAddOnMetadata("MinimalArchaeology", "Version")));
	else
		ChatFrame1:AddMessage("Minimal Archaeology Commands");
		ChatFrame1:AddMessage(" Usage: /minarch [cmd]");
		ChatFrame1:AddMessage(" Commands:");
		ChatFrame1:AddMessage("  hide - Hide the main Minimal Archaeology Frame");
		ChatFrame1:AddMessage("  show - Show the main Minimal Archaeology Frame");
		ChatFrame1:AddMessage("  toggle - Toggle the main Minimal Archaeology Frame");
		ChatFrame1:AddMessage("  version - Display the running version of Minimal Archaeology");
	end
end