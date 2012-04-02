

-----------------------------------------------
-- ChatFrameManager
-- to replace defaut tab manager of blizzard
-----------------------------------------------
local numchat = 0;

local function OpenChatframe(i, name)
	chatFrame = _G["ChatFrame"..i];
		
	-- initialize the frame
	FCF_SetWindowName(chatFrame, name);
	FCF_SetWindowColor(chatFrame, DEFAULT_CHATFRAME_COLOR.r, DEFAULT_CHATFRAME_COLOR.g, DEFAULT_CHATFRAME_COLOR.b, true);
	FCF_SetWindowAlpha(chatFrame, 0);

	-- clear stale messages
	chatFrame:Clear();

	-- Listen to the standard messages
	ChatFrame_RemoveAllMessageGroups(chatFrame);
	ChatFrame_RemoveAllChannels(chatFrame);
	ChatFrame_ReceiveAllPrivateMessages(chatFrame);
	ChatFrame_ReceiveAllBNConversations(chatFrame);
	
	ChatFrame_AddMessageGroup(chatFrame, "SAY");
	ChatFrame_AddMessageGroup(chatFrame, "YELL");
	ChatFrame_AddMessageGroup(chatFrame, "GUILD");
	ChatFrame_AddMessageGroup(chatFrame, "WHISPER");
	ChatFrame_AddMessageGroup(chatFrame, "BN_WHISPER");
	ChatFrame_AddMessageGroup(chatFrame, "PARTY");
	ChatFrame_AddMessageGroup(chatFrame, "PARTY_LEADER");
	ChatFrame_AddMessageGroup(chatFrame, "CHANNEL");

	chatFrame:Hide();
	--SetChatWindowShown(i, 1);
end

RDXUI.ChatframeManager = {};
function RDXUI.ChatframeManager:new(parent, desc)
	local self = VFLUI.AcquireFrame("Frame");
	
	local tabbox = VFLUI.TabBox:new(self, 22, "TOP", 5, 5);
	tabbox:SetHeight(desc.h); tabbox:SetWidth(desc.w);
	tabbox:SetPoint("TOPLEFT", self, "TOPLEFT");
	tabbox:SetBackdrop(nil);
	
	-- step 1 initialise all chat windows
	FCF_ResetChatWindows();
	
	--if not desc then desc = {}; end
	--desc.chatframe1 = true
	--if desc.chatframe1 then
		tabbox:GetTabBar():AddTab("60", function() tabbox:SetClient(ChatFrame1); end, function() end):SetText("Hello1");
		VFLUI.SetFont(ChatFrame1, desc.font);
		--FCF_OpenNewWindow("Hello3");
		OpenChatframe(3, "Hello3");
		tabbox:GetTabBar():AddTab("60", function() tabbox:SetClient(ChatFrame3); end, function() end):SetText("Hello3");
		VFLUI.SetFont(ChatFrame3, desc.font);
		--OpenChatframe(4, "Hello4");
		--tabbox:GetTabBar():AddTab("60", function() tabbox:SetClient(ChatFrame4); end, function() end):SetText("Hello4");
		--VFLUI.SetFont(ChatFrame4, desc.font);
	--end
	--local cli = nil;
	--for i=1,10 do
	--	cli = VFLUI.Button:new(); cli:SetText("cli " .. i); cli:Hide();
	--	tabbox:GetTabBar():AddTab(50, tabbox:GenerateTabFuncs(cli)):SetText(i);
	--end
	
	tabbox:GetTabBar():SelectTabName("Hello1");
	--tabbox:GetTabBar():SelectTabName("Hello3");
	--tabbox:GetTabBar():SelectTabName("Hello4");
	--tabbox:GetTabBar():SelectTabName("Hello1");
	tabbox:Show();
	
	self.tabbox = tabbox;
	
	self:Show();
	
	self.Destroy = VFL.hook(function(s)
		s.tabbox:GetTabBar():UnSelectTab();
		s.tabbox:Destroy(); s.tabbox = nil;
	end, self.Destroy);
	return self;
end


RDX.RegisterFeature({
	name = "chatframemanager";
	version = 1;
	title = VFLI.i18n("RDX ChatFrames Manager");
	category = VFLI.i18n("Complexes");
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = function(desc, state, errs)
		if not RDXUI.DescriptorCheck(desc, state, errs) then return nil; end
		if desc.owner == "Base" then desc.owner = "decor"; end
		local flg = true;
		flg = flg and RDXUI.UFFrameCheck_Proto("Frame_", desc, state, errs);
		flg = flg and RDXUI.UFAnchorCheck(desc.anchor, state, errs);
		flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
		if flg then state:AddSlot("Frame_" .. desc.name); end
		return flg;
	end;
	ApplyFeature = function(desc, state)
		local objname = "Frame_" .. desc.name;
		------------------ On frame creation
		local createCode = [[
local _f = RDXUI.ChatframeManager:new(parent, ]] .. Serialize(desc) .. [[)
_f:SetParent(]] .. RDXUI.ResolveFrameReference(desc.owner) .. [[);
_f:SetFrameLevel(frame:GetFrameLevel());
_f:SetPoint(]] .. RDXUI.AnchorCodeFromDescriptor(desc.anchor) .. [[);
_f:SetWidth(]] .. desc.w .. [[); _f:SetHeight(]] .. desc.h .. [[);
_f:Show();
frame.]] .. objname .. [[ = _f;
]];
		state:Attach(state:Slot("EmitCreate"), true, function(code) code:AppendCode(createCode); end);

		------------------ On frame destruction.
		local destroyCode = [[
local btn = frame.]] .. objname .. [[;
btn:Destroy(); btn = nil; 
frame.]] .. objname .. [[ = nil;
]];
		state:Attach(state:Slot("EmitDestroy"), true, function(code) code:AppendCode(destroyCode); end);

		return true;
	end;
	UIFromDescriptor = function(desc, parent, state)
		local ui = VFLUI.CompoundFrame:new(parent);

		-- Name/width/height
		local ed_name, ed_width, ed_height = RDXUI.GenNameWidthHeightPortion(ui, desc, state);

		-- Owner
		local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, "Subframe_");
		if desc and desc.owner then owner:SetSelection(desc.owner); end

		-- Anchor
		local anchor = RDXUI.UnitFrameAnchorSelector:new(ui); anchor:Show();
		anchor:SetAFArray(RDXUI.ComposeAnchorList(state));
		if desc and desc.anchor then anchor:SetAnchorInfo(desc.anchor); end
		ui:InsertFrame(anchor);
		
		local er = VFLUI.EmbedRight(ui, VFLI.i18n("ChatFrame number"));
		local dd_number = VFLUI.Dropdown:new(er, RDXUI.NumberListSelectionFunc);
		dd_number:SetWidth(150); dd_number:Show();
		if desc and desc.number then
			dd_number:SetSelection(desc.number);
		else
			dd_number:SetSelection("1");
		end
		er:EmbedChild(dd_number); er:Show();
		ui:InsertFrame(er);
		
		local er_ts = VFLUI.EmbedRight(ui, VFLI.i18n("Timestamp type"));
		local dd_ts = VFLUI.Dropdown:new(er_ts, VFL.ASDateListSelectionFunc);
		dd_ts:SetWidth(150); dd_ts:Show();
		if desc and desc.ts then
			dd_ts:SetSelection(desc.ts);
		else
			dd_ts:SetSelection("None");
		end
		er_ts:EmbedChild(dd_ts); er_ts:Show();
		ui:InsertFrame(er_ts);
		
		local color = RDXUI.GenerateColorSwatch(ui, VFLI.i18n("Timestamp color"));
		if desc and desc.color then color:SetColor(VFL.explodeRGBA(desc.color)); end
		
		local chk_channel = VFLUI.Checkbox:new(ui); chk_channel:Show();
		chk_channel:SetText(VFLI.i18n("Minimize channel name"));
		if desc and desc.channel then chk_channel:SetChecked(true); else chk_channel:SetChecked(); end
		ui:InsertFrame(chk_channel);
		
		local er_font = VFLUI.EmbedRight(ui, VFLI.i18n("Font"));
		local fontsel = VFLUI.MakeFontSelectButton(er_font, desc.font); fontsel:Show();
		er_font:EmbedChild(fontsel); er_font:Show();
		ui:InsertFrame(er_font);
		
		local chk_fading = VFLUI.Checkbox:new(ui); chk_fading:Show();
		chk_fading:SetText(VFLI.i18n("Fading"));
		if desc and desc.fading then chk_fading:SetChecked(true); else chk_fading:SetChecked(); end
		ui:InsertFrame(chk_fading);
		
		function ui:GetDescriptor()
			return { 
				feature = "chatframemanager"; version = 1;
				name = ed_name.editBox:GetText();
				owner = owner:GetSelection();
				w = ed_width:GetSelection();
				h = ed_height:GetSelection();
				anchor = anchor:GetAnchorInfo();
				number = dd_number:GetSelection();
				ts = dd_ts:GetSelection();
				color = color:GetColor();
				channel = chk_channel:GetChecked();
				font = fontsel:GetSelectedFont();
				fading = chk_fading:GetChecked();
			};
		end

		return ui;
	end;
	CreateDescriptor = function()
		return { 
			feature = "chatframemanager"; version = 1; 
			name = "cf1", owner = "decor";
			w = 140; h = 20;
			anchor = { lp = "TOPLEFT", af = "Base", rp = "TOPLEFT", dx = 0, dy = 0};
			number = "1";
			ts = "None";
			color = {r=1,g=1,b=1,a=1};
			font = VFL.copy(Fonts.Default);
		};
	end;
});