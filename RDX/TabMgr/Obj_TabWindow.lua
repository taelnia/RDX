-- Obj_WindowTab.lua
-- OpenRDX
--


-- The Window object type.
RDXDB.RegisterObjectType({
	name = "TabWindow";
	isFeatureDriven = true;
	invisible = true;
	New = function(path, md)
		md.version = 1;
	end,
	Edit = function(path, md, parent)
		RDX.EditWindow(parent, path, md);
	end,
	Instantiate = function(path, md)
		local f = VFLUI.AcquireFrame("Frame");
		local w = RDX.Window:new(f);
		-- Attempt to setup the window; if it fails, just bail out.
		if not RDX.SetupWindow(path, w, md.data) then 
			w:Destroy();
		else
			RDXDK.StdMove(w, w:GetTitleBar());
			RDX:Debug(5, "Instantiate WindowObject<", path, ">");
			w:WMGetPositionalFrame():SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2);
			f.w = w;
		end
		return f;
	end,
	Deinstantiate = function(instance, path, md)
		--instance:_Hide(RDX.smooth, nil, function() instance:Destroy(); instance._path = nil; instance = nil; end);
		if instance.w then
			instance.w:Destroy();
			instance.w._path = nil;
			instance.w = nil;
		end
		instance:Destroy();
		instance = nil;
	end,
	OpenTab = function(tabbox, path, md, objdesc, desc, tm)
		local tabtitle, tabwidth = "Tab", 80;
		for k, v in pairs(md.data) do
			if v.feature == "taboptions" then
				tabtitle = v.tabtitle;
				tabwidth = v.tabwidth;
			end
		end
		local f = RDXDB.GetObjectInstance(path);
		local tab = tabbox:GetTabBar():AddTab(tabwidth, function(self, arg1)
			tabbox:SetClient(f);
			VFLUI.SetBackdrop(f, desc.bkd);
			--f.font = desc.font;
		end,
		function() end, 
		function(mnu, dlg) 
			return objdesc.GenerateBrowserMenu(mnu, path, nil, dlg, tm)
		end);
		tab.font:SetText(tabtitle);
		tab.f = f;
		return tab;
	end,
	GenerateBrowserMenu = function(mnu, path, md, dlg, tm)
		table.insert(mnu, {
			text = VFLI.i18n("Edit"),
			OnClick = function()
				VFL.poptree:Release();
				RDXDB.OpenObject(path, "Edit", dlg);
			end
		});
		local feat = RDXDB.GetFeatureData(path, "Design");
		if not feat then feat = RDXDB.GetFeatureData(path, "Assist Frames"); end
		if feat then
			local upath = feat["design"];
			table.insert(mnu, {
				text = VFLI.i18n("Edit Design"),
				OnClick = function() 
					VFL.poptree:Release();
					if IsShiftKeyDown() then
						RDXDB.OpenObject(upath, "Edit", VFLDIALOG, true);
					else
						RDXDB.OpenObject(upath, "Edit", VFLDIALOG);
					end
				end
			});
		end
		if IsShiftKeyDown() then
			table.insert(mnu, {
				text = VFLI.i18n("Transform Window"),
				OnClick = function() 
					VFL.poptree:Release();
					local pkg, file = RDXDB.ParsePath(path);
					md.ty = "Window";
					md.version = 2;
					RDXDBEvents:Dispatch("OBJECT_MOVED", pkg, file, pkg, file, md);
				end
			});
		end
		if tm then 
			table.insert(mnu, {
				text = VFLI.i18n("Close Tab");
				OnClick = function()
					VFL.poptree:Release();
					tm:RemoveTab(path, true);
				end;
			});
		end
	end,
});

--
-- function to ckeck if a windows is secured or not.
--
function RDX.IsWindowTabSecured(path)
	
end

--------------- Tab Manager
--[[
RDXPM.RegisterTabCategory(VFLI.i18n("Windows"));

------------------------------------------
-- Update hooks
------------------------------------------
RDXDBEvents:Bind("OBJECT_DELETED", nil, function(pkg, file, md)
	if md and md.ty == "TabWindow" then
		local path = RDXDB.MakePath(pkg,file);
		RDXPM.UnregisterTab(path, "Windows")
	end
end);
RDXDBEvents:Bind("OBJECT_MOVED", nil, function(pkg, file, newpkg, newfile, md)
	if md and md.ty == "TabWindow" then
		local path = RDXDB.MakePath(pkg,file);
		RDXPM.UnregisterTab(path, "Windows")
	end
end);
RDXDBEvents:Bind("OBJECT_CREATED", nil, function(pkg, file) 
	local path = RDXDB.MakePath(pkg,file);
	local obj,_,_,ty = RDXDB.GetObjectData(path)
	if ty == "TabWindow" then
		local data = obj.data;
		local tit = "";
		--if data then tit = obj.data.title; end
		RDXPM.RegisterTab({
			name = path;
			title = path .. " " .. tit;
			category = VFLI.i18n("Windows");
			GetUI = RDXPM.TrivialChatFrameUI(path, path .. " " .. tit);
			GetBlankDescriptor = function() return {op = path}; end;
		});
	end
end);
RDXDBEvents:Bind("OBJECT_UPDATED", nil, function(pkg, file) 
	local path = RDXDB.MakePath(pkg,file);
	local obj,_,_,ty = RDXDB.GetObjectData(path)
	if ty == "TabWindow" then
		RDXPM.UnregisterTab(path, "Windows");
		local data = obj.data;
		local tit = "";
		--if data then tit = obj.data.title; end
		RDXPM.RegisterTab({
			name = path;
			title = path .. " " .. tit;
			category = VFLI.i18n("Windows");
			GetUI = RDXPM.TrivialChatFrameUI(path, path .. " " .. tit);
			GetBlankDescriptor = function() return {op = path}; end;
		});
	end
end);

-- run on UI load 
local function RegisterTabWindows()
	for pkgName,pkg in pairs(RDXData) do
		for objName,obj in pairs(pkg) do
			if type(obj) == "table" and obj.ty == "TabWindow" then 
				local path = RDXDB.MakePath(pkgName, objName);
				local data = obj.data;
				local tit = "";
				--if data then tit = obj.data.title; end
				RDXPM.RegisterTab({
					name = path;
					title = path .. " " .. tit;
					category = VFLI.i18n("Windows");
					GetUI = RDXPM.TrivialChatFrameUI(path, path .. " " .. tit);
					GetBlankDescriptor = function() return {op = path}; end;
				});
			end
		end
	end
end

RDXEvents:Bind("INIT_VARIABLES_LOADED", nil, function()
	RegisterTabWindows();
end);




]]