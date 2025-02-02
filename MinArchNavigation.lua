MinArch.autoWaypoint = nil;
MinArch.TomTomAvailable = (_G.TomTom ~= nil);
local previousDigsite = nil;

function MinArch:IsNavigationEnabled()
	return (MinArch.TomTomAvailable and MinArch.db.profile.TomTom.enable);
end

local function SetWayToDigsite(title, digsite, isAuto)
	if not MinArch:IsNavigationEnabled() then return end;
	
	local persistent = MinArch.db.profile.TomTom.persistent;
	if (isAuto) then
		persistent = false
	end

	-- print(digsite.uiMapID, digsite.x/100, digsite.y/100)
	newWaypoint = _G.TomTom:AddWaypoint(digsite.uiMapID, digsite.x/100, digsite.y/100, {
		title = title,
		crazy = MinArch.db.profile.TomTom.arrow,
		persistent = persistent,
	});

	return newWaypoint
end

function MinArch:SetWayToNearestDigsite()
	if not MinArch:IsNavigationEnabled() then return end;
	
	local digsiteName, distance, digsite = MinArch:GetNearestDigsite();
	if (digsite and (digsiteName ~= previousDigsite or distance > 1.7)) then
		if (MinArch.autoWaypoint ~= nil) then
			_G.TomTom:RemoveWaypoint(MinArch.autoWaypoint);
		end

		previousDigsite = digsiteName;
		local newWayPoint = SetWayToDigsite(digsiteName .. " (closest)", digsite, true);
		MinArch.autoWaypoint = newWayPoint;
	end
end

function MinArch:SetWayToDigsiteOnClick(digsiteName, digsite)
	if not MinArch:IsNavigationEnabled() then return end;

	previousDigsite = digsiteName;
	local newWaypoint = SetWayToDigsite(digsiteName, digsite);
	MinArch.db.char.TomTom.waypoints[digsiteName] = newWaypoint;
end

function MinArch:RefreshDigsiteWaypoints(forceRefresh)
	if not MinArch:IsNavigationEnabled() and not forceRefresh then return end;

	for title, waypoint in pairs(MinArch.db.char.TomTom.waypoints) do
		if (_G.TomTom:WaypointExists(waypoint[1], waypoint[2], waypoint[3], title)) then
			-- re-add waypoint so we have the correct data
			local newWaypoint = _G.TomTom:AddWaypoint(waypoint[1], waypoint[2], waypoint[3], {
				title = title,
				crazy = waypoint.crazy,
				persistent = waypoint.persistent,
			});
			MinArch.db.char.TomTom.waypoints[title] = newWaypoint;
		else
			MinArch.db.char.TomTom.waypoints[title] = nil;
		end
	end
end

function MinArch:ClearAllDigsiteWaypoints()
	-- Make sure waypoints are up to date
	MinArch:RefreshDigsiteWaypoints(true);

	if (MinArch.autoWaypoint ~= nil) then
		_G.TomTom:RemoveWaypoint(MinArch.autoWaypoint);
	end

	for title, waypoint in pairs(MinArch.db.char.TomTom.waypoints) do
		MinArch.db.char.TomTom.waypoints[title] = nil;
		_G.TomTom:RemoveWaypoint(waypoint);
	end
end