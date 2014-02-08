--[[--------------------------------------------------------------------
	PhanxConfig-Slider
	Simple slider widget generator.
	Based on tekKonfig-Slider and AceGUI-3.0-Slider.
	Requires LibStub.

	This library is not intended for use by other authors. Absolutely no
	support of any kind will be provided for other authors using it, and
	its internals may change at any time without notice.
----------------------------------------------------------------------]]

local MINOR_VERSION = tonumber(strmatch("$Revision$", "%d+"))

local lib, oldminor = LibStub:NewLibrary("PhanxConfig-Slider", MINOR_VERSION)
if not lib then return end

------------------------------------------------------------------------

local scripts = {}

function scripts:OnEnter()
	local text = self:GetParent().tooltipText
	if text then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text, nil, nil, nil, nil, true)
	end
end
function scripts:OnLeave()
	GameTooltip:Hide()
end

function scripts:OnMouseWheel(delta)
	local step = self:GetValueStep() * delta
	local minValue, maxValue = self:GetMinMaxValues()
	if step > 0 then
		self:SetValue(min(self:GetValue() + step, maxValue))
	else
		self:SetValue(max(self:GetValue() + step, minValue))
	end
end

function scripts:OnValueChanged()
	local parent = self:GetParent()
	local value = self:GetValue()
	local minValue, maxValue = self:GetMinMaxValues()

	local valueStep = self.valueStep
	if valueStep and valueStep > 0 then
		value = floor((value - minValue) / valueStep + 0.5) * valueStep + minValue
	end

	if self.valueFactor then
		value = value / self.valueFactor
	end

	local func = parent.func or parent.ApplyValue or parent.OnValueChanged
	if func then
		value = func(parent, value) or value
	end

	if parent.isPercent then
		parent.valueText:SetFormattedText("%.0f%%", value * 100)
	else
		parent.valueText:SetText(value)
	end
end

------------------------------------------------------------------------

local methods = {}

function methods:GetValue()
	return self.slider:GetValue()
end
function methods:SetValue(value)
	if self.isPercent then
		self.valueText:SetFormattedText("%.0f%%", value * 100)
	else
		self.valueText:SetText(value)
	end

	if self.slider.valueFactor then
		value = value * self.slider.valueFactor
	end

	return self.slider:SetValue(value)
end

function methods:GetLabel()
	return self.labelText:GetText()
end
function methods:SetLabel(text)
	return self.labelText:SetText(text)
end

function methods:GetTooltipText()
	return self.tooltipText
end
function methods:SetTooltipText(text)
	self.tooltipText = text
end

function methods:SetFunction(func)
	self.func = func
end

------------------------------------------------------------------------

local function EditBox_OnEnterPressed(self) -- print("OnEnterPressed SLIDER")
	local parent = self:GetParent():GetParent()
	local text = self:GetText()
	self:ClearFocus()

	local value
	if parent.isPercent then
		value = tonumber(strmatch(text, "%d+")) / 100
	else
		value = tonumber(text)
	end
	if value then
		parent:SetValue(value)
	end
end

local function EditBoxContainer_SetFormattedText(self, text, ...)
	return self.editbox:SetFormattedText(text, ...)
end

local sliderBG = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	edgeSize = 8, tile = true, tileSize = 8,
	insets = { left = 3, right = 3, top = 6, bottom = 6 }
}

function lib:New(parent, name, tooltipText, lowvalue, highvalue, valuestep, percent, noEditBox)
	assert(type(parent) == "table" and parent.CreateFontString, "PhanxConfig-Slider: Parent is not a valid frame!")
	if type(name) ~= "string" then name = nil end
	if type(tooltipText) ~= "string" then tooltipText = nil end
	if type(lowvalue) ~= "number" then lowvalue = 0 end
	if type(highvalue) ~= "number" then highvalue = 100 end
	if type(valuestep) ~= "number" then valuestep = 1 end

	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(186)
	frame:SetHeight(42)

	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetAllPoints(true)
	frame.bg:SetTexture(0, 0, 0, 0)

	local slider = CreateFrame("Slider", nil, frame)
	slider:SetPoint("BOTTOMLEFT", 3, 10)
	slider:SetPoint("BOTTOMRIGHT", -3, 10)
	slider:SetHeight(17)
	slider:SetHitRectInsets(0, 0, -10, -10)
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(sliderBG)

	local label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetPoint("TOPLEFT", frame, 5, 0)
	label:SetPoint("TOPRIGHT", frame, -5, 0)
	label:SetJustifyH("LEFT")

	local low = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, 3)
	if percent then
		low:SetFormattedText("%.0f%%", lowvalue * 100)
	else
		low:SetText(lowvalue)
	end

	local high = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, 3)
	if percent then
		high:SetFormattedText("%.0f%%", highvalue * 100)
	else
		high:SetText(highvalue)
	end

	local value
	if not noEditBox and LibStub("PhanxConfig-EditBox", true) then
		value = LibStub("PhanxConfig-EditBox"):New(frame, nil, tooltipText, 5)
		value:SetPoint("TOP", slider, "BOTTOM", 0, 13)
		value:SetWidth(100)
		value.editbox:SetScript("OnEnter", scripts.OnEnter)
		value.editbox:SetScript("OnLeave", scripts.OnLeave)
		value.editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
		value.editbox:SetScript("OnTabPressed", EditBox_OnEnterPressed)
		value.editbox:SetFontObject(GameFontHighlightSmall)
		value.editbox:SetJustifyH("CENTER")
		value.SetFormattedText = EditBoxContainer_SetFormattedText
	else
		value = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		value:SetPoint("TOP", slider, "BOTTOM", 0, 3)
	end

	local factor = 10 ^ max(strlen(tostring(valuestep):match("%.(%d+)") or ""),
		strlen(tostring(minvalue):match("%.(%d+)") or ""),
		strlen(tostring(maxvalue):match("%.(%d+)") or ""))
	if factor > 1 then
		slider.valueFactor = factor
		slider:SetMinMaxValues(lowvalue * factor, highvalue * factor)
		slider.minValue, slider.maxValue = lowvalue * factor, highvalue * factor
		slider:SetValueStep(valuestep * factor)
		slider.valueStep = valuestep * factor
	else
		slider:SetMinMaxValues(lowvalue, highvalue)
		slider.minValue, slider.maxValue = lowvalue, highvalue
		slider:SetValueStep(valuestep)
		slider.valueStep = valuestep
	end

	slider:EnableMouseWheel(true)
	slider:SetScript("OnEnter", scripts.OnEnter)
	slider:SetScript("OnLeave", scripts.OnLeave)
	slider:SetScript("OnMouseWheel", scripts.OnMouseWheel)
	slider:SetScript("OnValueChanged", scripts.OnValueChanged)

	frame.slider = slider
	frame.labelText = label
	frame.lowText = low
	frame.highText = high
	frame.valueText = value

	frame.isPercent = percent

	for name, func in pairs(methods) do
		frame[name] = func
	end

	label:SetText(name)
	frame.tooltipText = tooltipText

	return frame
end

function lib.CreateSlider(...) return lib:New(...) end