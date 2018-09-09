MinArchScroll = {}

MinArch.HistoryListLoaded = {}
MinArch.HasPristine = {}

function MinArch:IsItemDetailsLoaded(RaceID)
	return MinArch.HistoryListLoaded[RaceID] or false
end

function MinArch:LoadItemDetails(RaceID, caller)
	if MinArch:IsItemDetailsLoaded(RaceID) then
		return true
	end
	
	local newItemCount = 0
	
	local allGood = true
	for itemid, details in pairs(MinArchHistDB[RaceID]) do
		if not details.name then
			newItemCount = newItemCount + 1

			local name, _, rarity, _, _, _, _, _, _, icon, sellPrice = GetItemInfo(itemid);
			
			if name ~= nil and icon ~= nil then
				details.name = name
				details.rarity = rarity
				details.icon = "interface\\icons\\"..LibIconPath_getName(icon)..".blp"
				details.sellprice = sellPrice
				if details.pqid then
					MinArch.HasPristine[RaceID] = true
				end
			else
				-- item info not available yet, need to retry later
				allGood = false
			end
		end
	end

	MinArch.HistoryListLoaded[RaceID] = allGood
	if allGood then
		MinArch:DisplayStatusMessage("Minimal Archaeology - All " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)) .. " items are loaded now.", MINARCH_MSG_DEBUG)
		MinArch:DisplayStatusMessage("Minimal Archaeology - All " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)) .. " items are loaded now (" .. caller .. ").", MINARCH_MSG_DEBUG)
	else
		MinArch:DisplayStatusMessage("Minimal Archaeology - Some " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)) .. " items are not loaded yet (" .. caller .. ").", MINARCH_MSG_DEBUG)
	end

	return allGood
end

function MinArch:GetHistory(RaceID, caller)
	local i = 1
	while true do
		local name, desc, rarity, icon, spelldesc, itemrare, _, spellId, firstcomplete, totalcomplete = GetArtifactInfoByRace(RaceID, i)

		if not name then
			break
		end

		-- icon = icon:lower()
		icon = "interface\\icons\\"..LibIconPath_getName(icon) or icon
		if MinArchIconDB[RaceID] and MinArchIconDB[RaceID][icon] then
			icon = MinArchIconDB[RaceID][icon]
		end
		icon = icon..".blp"
		
		local foundCount = 0
		for itemid, details in pairs(MinArchHistDB[RaceID]) do
			if (details.name == name and details.icon ~= icon) then
				MinArchIconDB[RaceID] = MinArchIconDB[RaceID] or {}
				MinArchIconDB[RaceID][icon] = details.icon
				MinArch:DisplayStatusMessage("Minimal Archaeology - icon discrepancy detected", MINARCH_MSG_DEBUG)
				MinArch:DisplayStatusMessage("Race " .. RaceID .. ": " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)), MINARCH_MSG_DEBUG)
				MinArch:DisplayStatusMessage("Item " .. itemid .. ": " .. details.name, MINARCH_MSG_DEBUG)
				MinArch:DisplayStatusMessage("Item icon '" .. details.icon .. "'", MINARCH_MSG_DEBUG)
				MinArch:DisplayStatusMessage("Artifact icon '" .. icon .. "'", MINARCH_MSG_DEBUG)
				icon = details.icon
			end
		end
		
		-- pass 1: match both name and icon (because "Insect in Amber" and "Ancient Amber" have the same icon)
		-- pass 2: match only the icon if no matches in pass 1 were found (because some artifact names are different than the items they give)
		for pass = 1,2,1 do
			for itemid, details in pairs(MinArchHistDB[RaceID]) do
				if ((pass == 2 or details.name == name) and details.icon == icon) then
					details.artifactname = name
					foundCount = foundCount + 1
					if foundCount > 1 then
						MinArch:DisplayStatusMessage("Minimal Archaeology - found duplicate #" .. foundCount, MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Race " .. RaceID .. ": " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)), MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Item " .. itemid .. ": " .. details.name, MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Artifact: " .. name, MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Item icon '" .. details.icon .. "'", MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Artifact icon '" .. icon .. "'", MINARCH_MSG_DEBUG)
					end
					
					--TODO: In the tooltip, display icon/name/info for artifact and all associated item icons
					-- Change MinArchHistDB to include the alternate item IDs (for example, Orb of Sciallax can give 6 different relics items)
					-- Gather the name and icon info here.
					--[[if (details.name ~= name) then
						MinArch:DisplayStatusMessage("Minimal Archaeology - item and artifact names differ", MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Race " .. RaceID .. ": " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)), MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Item " .. itemid .. ": " .. details.name, MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Artifact: " .. name, MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Item icon '" .. details.icon .. "'", MINARCH_MSG_DEBUG)
						MinArch:DisplayStatusMessage("Artifact icon '" .. icon .. "'", MINARCH_MSG_DEBUG)
					end]]--
					
					details.firstcomplete = firstcomplete
					details.totalcomplete = totalcomplete
					details.description = desc
					details.spelldescription = spelldesc
					
					if (MinArch.artifacts[RaceID].project == name) then
						MinArch.artifacts[RaceID].firstcomplete = firstcomplete
						MinArch.artifacts[RaceID].totalcomplete = totalcomplete
						MinArch.artifacts[RaceID].sellprice = details.sellprice
					end
				end
			end
			if foundCount > 0 then
				break
			end
		end
		
		if foundCount == 0 and MinArch:IsItemDetailsLoaded(RaceID) then
			MinArch:DisplayStatusMessage("Minimal Archaeology - found unknown artifact", MINARCH_MSG_DEBUG)
			MinArch:DisplayStatusMessage("Race " .. RaceID .. ": " .. (MinArch.artifacts[RaceID].race or ("Race" .. RaceID)), MINARCH_MSG_DEBUG)
			MinArch:DisplayStatusMessage("Artifact: " .. name, MINARCH_MSG_DEBUG)
			MinArch:DisplayStatusMessage("Artifact icon '" .. icon .. "'", MINARCH_MSG_DEBUG)
		end

		i=i+1;
	end
end

function MinArch:IsQuestAvailableForArtifact(RaceID, artifactID)
	local qLineId = MinArchHistDB[RaceID][artifactID]['qline'];
	if (qLineId == nil) then
		return false;
	end

	local availableQuestLines = C_QuestLine.GetAvailableQuestLines(619);

	local qLineQuests = C_QuestLine.GetQuestLineQuests(qLineId);
	for i=1, #qLineQuests do
		if (C_QuestLog.IsOnQuest(qLineQuests[i])) then
			return true, true;
		end

		
		for k, quest in pairs(availableQuestLines) do
			if (quest.questID == qLineQuests[i]) then
				return true
			end
		end
	end
	
	return false
end

function MinArch:CreateHistoryList(RaceID, caller)
	caller = (caller or "race button")
	local nextcaller = (caller or "race button") .. " -> CreateHistoryList(" .. ((MinArch.artifacts[RaceID].race or ("Race" .. RaceID)) or ("Race" .. RaceID)) .. ")"

	if (not MinArch:IsItemDetailsLoaded(RaceID)) then
		local allGood = true
		for i = 1, ARCHAEOLOGY_NUM_RACES do
			allGood = MinArch:LoadItemDetails(i, nextcaller .. "{i=" .. i .. "}") and allGood
		end

		if allGood then
			MinArch:DisplayStatusMessage("Minimal Archaeology - All items are loaded now.", MINARCH_MSG_DEBUG)
		else
			return
		end
	end

	MinArch:GetHistory(RaceID, nextcaller)

	local PADDING = 5;
	local width = 260; -- fixme get parent width
	
	for i=1, ARCHAEOLOGY_NUM_RACES do
		if (MinArchScroll[i]) then
			MinArchScroll[i]:Hide();
		end
	end

	local scrollf = MinArchScrollFrame
	if not scrollf then
		scrollf = CreateFrame("ScrollFrame", "MinArchScrollFrame", MinArchHist)
		scrollf:SetClipsChildren(true)
		scrollf:SetPoint("BOTTOMLEFT", MinArchHist, "BOTTOMLEFT", 12, 10)
	end
	scrollf:SetSize(width, 230)

	local scrollc = MinArchScroll[RaceID]
	if not scrollc then
		scrollc = CreateFrame("Frame", "MinArchScroll" .. RaceID)
		MinArchScroll[RaceID] = scrollc
	end
	scrollc:SetSize(width, 230)

	local scrollb = MinArchScrollBar or CreateFrame("Slider", "MinArchScrollBar", MinArchHist)
	local scrollPos = scrollb:GetValue() or 0;

	if (not scrollb.bg) then
		scrollb.bg = scrollb:CreateTexture(nil, "BACKGROUND");
		scrollb.bg:SetAllPoints(true);
		scrollb.bg:SetTexture(0, 0, 0, 0.80);
	end

	if (not scrollf.bg) then
		scrollf.bg = scrollf:CreateTexture(nil, "BACKGROUND");
		scrollf.bg:SetAllPoints(true);
		scrollf.bg:SetTexture(0, 0, 0, 0.60);
	end

	if (not scrollb.thumb) then
		scrollb.thumb = scrollb:CreateTexture(nil, "OVERLAY");
		scrollb.thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob");
		scrollb.thumb:SetSize(25, 25);
		scrollb:SetThumbTexture(scrollb.thumb);
	end

	scrollc.artifacts = scrollc.artifacts or {};

	local groups = {
		[1]={rarity=7},
		[2]={rarity=4},
		[3]={rarity=3},
		[4]={rarity=2},
		[5]={rarity=0,goldmin=500000}, -- put the Crown Jewels of Suramar higher up in the list
		[6]={rarity=1},
		[7]={rarity=0,goldmax=500000},
	}

	-- Calculate all font strings twice, because measurements are wrong if they are done only once.
	-- To test this: set scale to 30%. Click a race button. The text should not have ellipse.
	-- If only one pass is used, click a race button, and see text has ellipse at 30%. click button again and it draws properly.
	for pass = 1, 2, 1 do
		local height = 0;
		local count = 0;
		local currentArtifact, currentFontString, cwidth, cheight, mouseframe, tmpText
		
		for group, gparams in ipairs(groups) do
			--print ("Group:", group, "rarity:", gparams.rarity, "min:", gparams.goldmin, "max:", gparams.goldmax)
			for itemid, details in pairs(MinArchHistDB[RaceID]) do
				if details.rarity == gparams.rarity
						and ((not gparams.goldmin) or details.sellprice >= gparams.goldmin)
						and ((not gparams.goldmax) or details.sellprice < gparams.goldmax) then
					count = count + 1

					currentArtifact = scrollc.artifacts[count]
					if not currentArtifact then
						currentArtifact = {
							description = scrollc:CreateFontString("Artifact" .. RaceID .. "_" .. count .. "Description", "OVERLAY"),
							status = scrollc:CreateFontString("Artifact" .. RaceID .. "_" .. count .. "Status", "OVERLAY"),
							mouseframe = CreateFrame("Frame", "Artifact" .. RaceID .. "_" .. count .. "MouseOver", scrollc)
						}
						if MinArch.HasPristine[RaceID] == true then
							currentArtifact.pristine = scrollc:CreateFontString("Artifact" .. RaceID .. "_" .. count .. "Pristine", "OVERLAY")
						end
						scrollc.artifacts[count] = currentArtifact
					end
				
					-- Description
					currentFontString = currentArtifact.description
					currentFontString:SetSize(width, 100)
					currentFontString:SetFontObject("ChatFontSmall")
					currentFontString:SetWordWrap(true)
					currentFontString:SetJustifyH("LEFT")
					currentFontString:SetJustifyV("TOP")
					local displayName = details.name;
					if (strlen(details.name) > 31) then
						displayName = strsub(details.name, 0, 28) .. '...';
					end
					currentFontString:SetText(" " .. displayName)
					currentFontString:SetTextColor(ITEM_QUALITY_COLORS[details.rarity].r, ITEM_QUALITY_COLORS[details.rarity].g, ITEM_QUALITY_COLORS[details.rarity].b, 1.0)
				
					cwidth = currentFontString:GetStringWidth()
					cheight = currentFontString:GetStringHeight()
					currentFontString:SetSize(cwidth + 18, cheight)
					
					if count == 1 then
						currentFontString:SetPoint("TOPLEFT", scrollc, "TOPLEFT", 0, 0)
					else
						currentFontString:SetPoint("LEFT", scrollc, "LEFT", 0, 0)
						currentFontString:SetPoint("TOP", scrollc.artifacts[count - 1].description, "TOP", 0, - PADDING - cheight)
						height = height + PADDING
					end
				
					-- Status
					currentFontString = currentArtifact.status
					currentFontString:SetSize(width, 100)
					currentFontString:SetFontObject("ChatFontSmall")
					currentFontString:SetWordWrap(false)
					currentFontString:SetJustifyH("RIGHT")
					currentFontString:SetJustifyV("TOP")
					
					if not details.firstcomplete then
						currentFontString:SetText("Incomplete")
						currentFontString:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1)
					elseif MinArch.artifacts[RaceID].project == details.artifactname then
						if not details.totalcomplete or details.totalcomplete == 0 then
							currentFontString:SetText("In Progress")
						else
							currentFontString:SetText("#" .. (details.totalcomplete + 1) .. " In Progress")
						end
						currentFontString:SetTextColor(1.0, 0.8, 0.0, 1.0)
					else
						currentFontString:SetText(details.totalcomplete .. " Completed")
						currentFontString:SetTextColor(0.0, 1.0, 0.0, 1.0)
					end
				
					-- Legion quests
					local isQuestAvailable = false;
					local isOnQuest = false;
					if (RaceID == ARCHAEOLOGY_RACE_DEMONIC or RaceID == ARCHAEOLOGY_RACE_HIGHMOUNTAIN_TAUREN or RaceID == ARCHAEOLOGY_RACE_HIGHBORNE) then
						isQuestAvailable, isOnQuest = MinArch:IsQuestAvailableForArtifact(RaceID, itemid)
						tmpText = "";
						if (details.totalcomplete and details.totalcomplete > 0) then
							tmpText = "#" .. (details.totalcomplete + 1) .. " ";
						end

						if (isQuestAvailable and isOnQuest) then
							currentFontString:SetText(tmpText .. "On quest");
							currentFontString:SetTextColor(1.0, 0.5, 0.0, 1.0)
						elseif (isQuestAvailable) then
							currentFontString:SetText(tmpText .. "Quest available");
							currentFontString:SetTextColor(1.0, 0.5, 0.0, 1.0)
						end
					end

					cwidth = currentFontString:GetStringWidth()
					currentFontString:SetSize(cwidth + 5, cheight)
				
					local statusoffset = MinArch.HasPristine[RaceID] == true and -12 or 0
				
					if count == 1 then
						currentFontString:SetPoint("TOPRIGHT", scrollc, "TOPRIGHT", statusoffset, 0)
					else
						currentFontString:SetPoint("RIGHT", scrollc, "RIGHT", statusoffset, 0)
						currentFontString:SetPoint("TOP", scrollc.artifacts[count - 1].status, "TOP", 0, - PADDING - cheight)
					end

					-- Pristine
					if MinArch.HasPristine[RaceID] == true then
						currentFontString = currentArtifact.pristine
						currentFontString:SetSize(width, 100)
						currentFontString:SetFontObject("ChatFontSmall")
						currentFontString:SetWordWrap(false)
						currentFontString:SetJustifyH("RIGHT")
						currentFontString:SetJustifyV("TOP")

						if not details.pqid then
							currentFontString:SetText("-")
							currentFontString:SetTextColor(0.0, 1.0, 0.0, 1.0)
						elseif IsQuestFlaggedCompleted(details.pqid) == true then
							currentFontString:SetText("+")
							currentFontString:SetTextColor(0.0, 1.0, 0.0, 1.0)
						else
							currentFontString:SetText("x")
							currentFontString:SetTextColor(1.0, 0.0, 0.0, 1.0)
						end
					
						cwidth = currentFontString:GetStringWidth()
						currentFontString:SetSize(cwidth + 5, cheight)
					
						if count == 1 then
							currentFontString:SetPoint("TOPRIGHT", scrollc, "TOPRIGHT", 0, 0)
						else
							currentFontString:SetPoint("RIGHT", scrollc, "RIGHT", 0, 0)
							currentFontString:SetPoint("TOP", scrollc.artifacts[count - 1].pristine, "TOP", 0, - PADDING - cheight)
						end
					end
					
					-- height calc
					height = height + cheight
					--print("height", height, "cheight", cheight)
					
					-- Tooltip					
					mouseframe = currentArtifact.mouseframe
					mouseframe:SetSize(width, cheight)
					mouseframe:SetPoint("BOTTOMRIGHT", currentFontString, "BOTTOMRIGHT", 0, 0)
				
					mouseframe:SetScript("OnEnter", function(self)
												MinArch:HistoryTooltip(self, RaceID, itemid)
											end)
					mouseframe:SetScript("OnLeave", function()
												MinArchTooltipIcon:Hide();
												GameTooltip:Hide()
											end)
				end
			end
		end
	
		-- Set the size of the scroll child
		if height > 2 then
			scrollc:SetHeight(height-2)
		end
	
		-- Set the scrollchild to be the frame of font strings we've created
		scrollf:SetScrollChild(scrollc)
	
		-- Set up the scrollbar to work properly
		local scrollMax = 0
		if height > 230 then
			scrollMax = height - 220
		end
	
		if (scrollMax == 0) then
			scrollb.thumb:Hide();
		else
			scrollb.thumb:Show();
		end
	
		scrollb:SetOrientation("VERTICAL")
		scrollb:SetSize(16, 230)
		scrollb:SetPoint("TOPLEFT", scrollf, "TOPRIGHT", 0, 0)
		scrollb:SetMinMaxValues(0, scrollMax)
		scrollb:SetValue(scrollPos)
		scrollb:SetScript("OnValueChanged", function(self)
			scrollf:SetVerticalScroll(self:GetValue())
		end)
	
		-- Enable mousewheel scrolling
		scrollf:EnableMouseWheel(true)
		scrollf:SetScript("OnMouseWheel", function(self, delta)
			local current = scrollb:GetValue()
		
			if IsShiftKeyDown() and (delta > 0) then
				scrollb:SetValue(0)
			elseif IsShiftKeyDown() and (delta < 0) then
				scrollb:SetValue(scrollMax)
			elseif (delta < 0) and (current < scrollMax) then
				scrollb:SetValue(current + 20)
			elseif (delta > 0) and (current > 1) then
				scrollb:SetValue(current - 20)
			end
		end)
	end

	scrollc:Show()
end

function MinArch:DimHistoryButtons()
	for i=1, ARCHAEOLOGY_NUM_RACES do
		if (MinArch.raceButtons[i]) then
			MinArch.raceButtons[i]:SetAlpha(0.5);
		end
	end
end

function MinArch:HistoryTooltip(self, RaceID, ItemID)
	local artifact = MinArchHistDB[RaceID][ItemID];
	local discovereddate = {};
	
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
	
	MinArchTooltipIcon.icon:SetTexture(artifact.icon)
	if (artifact.rarity == 4) then
		GameTooltip:AddLine(artifact.name, 0.65, 0.2, 0.93, 1.0)
	elseif (artifact.rarity == 3) then
		GameTooltip:AddLine(artifact.name, 0.0, 0.4, 0.8, 1.0)
	else
		GameTooltip:AddLine(artifact.name, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1)
	end
	
	GameTooltip:AddLine(artifact.description, 1.0, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(artifact.spelldescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	
	if not artifact["firstcomplete"] then
		GameTooltip:AddLine("Incomplete", GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1);
	elseif artifact["firstcomplete"] == 0 then
		GameTooltip:AddLine(" ", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		if (artifact["sellprice"] ~= nil) then
			if (tonumber(artifact["sellprice"]) > 0) then
				GameTooltip:AddLine("|cffffffff"..GetCoinTextureString(artifact["sellprice"]), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
			end
		end
		GameTooltip:AddLine("In Progress", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
	else
		GameTooltip:AddLine(" ", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		if (artifact["sellprice"] ~= nil) then
			if (tonumber(artifact["sellprice"]) > 0) then
				GameTooltip:AddLine("|cffffffff"..GetCoinTextureString(artifact["sellprice"]), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
			end
		end
		discovereddate = date("*t", artifact["firstcomplete"]);
		if (discovereddate) then
			GameTooltip:AddDoubleLine("Discovered On: |cffffffff"..discovereddate["month"].."/"..discovereddate["day"].."/"..discovereddate["year"], "x"..artifact["totalcomplete"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		end
	end
	
	
	
	MinArchTooltipIcon:Show();
	GameTooltip:Show();
end

function MinArch:HistoryButtonTooltip(RaceID)
	GameTooltip:SetOwner(MinArch.raceButtons[RaceID], "ANCHOR_TOPLEFT");
	GameTooltip:AddLine((MinArch.artifacts[RaceID].race or ("Race" .. RaceID)), 1.0, 1.0, 1.0, 1.0)
	GameTooltip:Show();
end

function MinArch:ToggleHistory()
	if (MinArchHist:IsVisible()) then
		MinArchHist:Hide()
	else
		MinArchHist:Show()
	end
end