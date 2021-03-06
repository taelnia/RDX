﻿

----------------------------------------------------------------------
-- Backdrop colorizers
----------------------------------------------------------------------
local function bdc_ef(desc, state, errs)
	if not RDXUI.DescriptorCheck(desc, state, errs) then return nil; end
	if not desc.flag then desc.flag = "true"; end
	local flg = true;
	flg = flg and RDXUI.UFOwnerCheck(desc.owner, state, errs);
	
	if not RDXUI.IsValidBoolVar(desc.flag, state) then
		VFL.AddError(errs, VFLI.i18n("Invalid flag variable")); flg = nil;
	end
	if (not desc.color) or (not state:Slot("ColorVar_" .. desc.color)) then
		VFL.AddError(errs, VFLI.i18n("Invalid color variable")); flg = nil;
	end
	return flg;
end

local function bdc_uifd(desc, parent, state)
	local ui = VFLUI.CompoundFrame:new(parent);

	-- Owner
	local owner = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Owner"), state, {"Frame_", "Button_", "Cooldown_", });
	if desc and desc.owner then owner:SetSelection(desc.owner); end

	-- Color var
	local color = RDXUI.MakeSlotSelectorDropdown(ui, VFLI.i18n("Color variable"), state, "ColorVar_");
	if desc and desc.color then color:SetSelection(desc.color); end

	function ui:GetDescriptor()
		return { 
			feature = desc.feature, owner = owner:GetSelection();
			color = color:GetSelection();
		};
	end

	return ui;
end

RDX.RegisterFeature({
	name = "Backdrop Border Colorizer";
	title = VFLI.i18n("Sh: BackdropBorder Colorizer");
	category = VFLI.i18n("Shaders");
	multiple = true;
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = bdc_ef;
	ApplyFeature = function(desc, state)
		local fvar = RDXUI.ResolveFrameReference(desc.owner);
		local paintCode = [[
		VFLUI.SetBackdropBorderColor(]] .. fvar .. [[, explodeRGBA(]] .. desc.color .. [[));
]];
		state:Attach(state:Slot("EmitPaint"), true, function(code) code:AppendCode(paintCode); end);
	end;
	UIFromDescriptor = bdc_uifd;
	CreateDescriptor = function()
		return { feature = "Backdrop Border Colorizer"; };
	end;
});

RDX.RegisterFeature({
	name = "Backdrop Colorizer";
	title = VFLI.i18n("Sh: Backdrop Colorizer");
	category = VFLI.i18n("Shaders");
	multiple = true;
	IsPossible = function(state)
		if not state:Slot("DesignFrame") then return nil; end
		if not state:Slot("Base") then return nil; end
		return true;
	end;
	ExposeFeature = bdc_ef;
	ApplyFeature = function(desc, state)
		local fvar = RDXUI.ResolveFrameReference(desc.owner);
		local paintCode = [[
		VFLUI.SetBackdropColor(]] .. fvar .. [[, explodeRGBA(]] .. desc.color .. [[));
]];
		state:Attach(state:Slot("EmitPaint"), true, function(code) code:AppendCode(paintCode); end);
	end;
	UIFromDescriptor = bdc_uifd;
	CreateDescriptor = function()
		return { feature = "Backdrop Colorizer"; };
	end;
});
