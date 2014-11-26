--[[--------------------------------------------------------------------
	PhanxConfig-Slider
	Simple slider widget generator. Requires LibStub.
	Based on tekKonfig-Slider and AceGUI-3.0-Slider.

	Copyright (c) 2009-2014 Phanx <addons@phanx.net>. All rights reserved.

	Permission is granted for anyone to use, read, or otherwise interpret
	this software for any purpose, without any restrictions.

	Permission is granted for anyone to embed or include this software in
	another work not derived from this software that makes use of the
	interface provided by this software for the purpose of creating a
	package of the work and its required libraries, and to distribute such
	packages as long as the software is not modified in any way, including
	by modifying or removing any files.

	Permission is granted for anyone to modify this software or sample from
	it, and to distribute such modified versions or derivative works as long
	as neither the names of this software nor its authors are used in the
	name or title of the work or in any other way that may cause it to be
	confused with or interfere with the simultaneous use of this software.

	This software may not be distributed standalone or in any other way, in
	whole or in part, modified or unmodified, without specific prior written
	permission from the authors of this software.

	The names of this software and/or its authors may not be used to
	promote or endorse works derived from this software without specific
	prior written permission from the authors of this software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.
----------------------------------------------------------------------]]

local MINOR_VERSION = 176

local lib, oldminor = LibStub:NewLibrary("PhanxConfig-Slider", MINOR_VERSION)
if not lib then return end

------------------------------------------------------------------------

local methods = {}

function methods:GetValue()
	return self.slider:GetValue()
end

function methods:SetValue(value)
	value = tonumber(value or nil)
	return value and self.slider:SetValue(value)
end

function methods:GetLabel()
	return self.labelText:GetText()
end

function methods:SetLabel(text)
	self.labelText:SetText(tostring(text or ""))
end

function methods:GetTooltip()
	return self.tooltipText
end

function methods:SetTooltip(text)
	self.tooltipText = text and tostring(text) or nil
end

------------------------------------------------------------------------

local function Slider_OnEnter(self)
	local container = self:GetParent()
	local text = container.tooltipText
	if text then
		GameTooltip:SetOwner(container, "ANCHOR_RIGHT")
		GameTooltip:SetText(container.tooltipText, nil, nil, nil, nil, true)
	end
end

local function Slider_OnLeave(self)
	GameTooltip:Hide()
end

local function Slider_OnMouseWheel(self, delta)
	local parent = self:GetParent()
	local minValue, maxValue = self:GetMinMaxValues()
	local step = self:GetValueStep() * delta

	if step > 0 then
		value = min(self:GetValue() + step, maxValue)
	else
		value = max(self:GetValue() + step, minValue)
	end

	self:SetValue(value)

	local callback = parent.OnValueChanged or parent.Callback
	if callback then
		callback(parent, value)
	end
end

local function Slider_OnValueChanged(self, value, userInput)
	local parent = self:GetParent()
	if parent.lastValue == value then return end

	if parent.isPercent then
		parent.valueText:SetFormattedText("%.0f%%", value * 100)
	else
		parent.valueText:SetText(value)
	end

	if parent.lastValue and parent.Callback then
		parent:Callback(value)
	end

	parent.lastValue = value
end

------------------------------------------------------------------------

local function EditBox_OnEnter(self)
	local parent = self:GetParent():GetParent()
	return Slider_OnEnter(parent.slider)
end

local function EditBox_OnLeave(self)
	local parent = self:GetParent():GetParent()
	return Slider_OnLeave(parent.slider)
end

local function EditBox_OnEnterPressed(self)
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

------------------------------------------------------------------------

local sliderBG = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	edgeSize = 8, tile = true, tileSize = 8,
	insets = { left = 3, right = 3, top = 6, bottom = 6 }
}

function lib:New(parent, name, tooltipText, minValue, maxValue, valueStep, percent, noEditBox)
	assert(type(parent) == "table" and type(rawget(parent, 0)) == "userdata", "PhanxConfig-Slider: parent must be a frame")
	if type(name) ~= "string" then name = nil end
	if type(tooltipText) ~= "string" then tooltipText = nil end
	if type(minValue) ~= "number" then minValue = 0 end
	if type(maxValue) ~= "number" then maxValue = 100 end
	if type(valueStep) ~= "number" then valueStep = 1 end

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
	frame.slider = slider

	local label = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetPoint("TOPLEFT", frame, 5, 0)
	label:SetPoint("TOPRIGHT", frame, -5, 0)
	label:SetJustifyH("LEFT")
	frame.labelText = label

	local minText = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	minText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, 3)
	frame.minText = minText

	if percent then
		minText:SetFormattedText("%.0f%%", minValue * 100)
	else
		minText:SetText(minValue)
	end

	local maxText = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	maxText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, 3)
	frame.maxText = high

	if percent then
		maxText:SetFormattedText("%.0f%%", maxValue * 100)
	else
		maxText:SetText(maxValue)
	end

	local valueText
	if not noEditBox and LibStub("PhanxConfig-EditBox", true) then
		valueText = LibStub("PhanxConfig-EditBox"):New(frame, nil, tooltipText, 5)
		valueText:SetPoint("TOP", slider, "BOTTOM", 0, 13)
		valueText:SetWidth(100)
		valueText.editbox:SetFontObject(GameFontHighlightSmall)
		valueText.editbox:SetJustifyH("CENTER")
		valueText.editbox:SetScript("OnEnter", EditBox_OnEnter)
		valueText.editbox:SetScript("OnLeave", EditBox_OnLeave)
		valueText.editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
		valueText.editbox:SetScript("OnTabPressed", EditBox_OnEnterPressed)
	else
		valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		valueText:SetPoint("TOP", slider, "BOTTOM", 0, 3)
	end
	frame.valueText = valueText

	slider:EnableMouseWheel(true)
	slider:SetObeyStepOnDrag(true)
	slider:SetScript("OnEnter", Slider_OnEnter)
	slider:SetScript("OnLeave", Slider_OnLeave)
	slider:SetScript("OnMouseWheel", Slider_OnMouseWheel)
	slider:SetScript("OnValueChanged", Slider_OnValueChanged)

	for name, func in pairs(methods) do
		frame[name] = func
	end

	label:SetText(name)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetValueStep(valueStep)
	frame.tooltipText = tooltipText
	frame.isPercent = percent

	return frame
end

function lib.CreateSlider(...) return lib:New(...) end