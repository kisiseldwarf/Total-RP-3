--[[
	Copyright 2021 Total RP 3 Development Team

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]--

TRP3_TextureUtil = {};

function TRP3_TextureUtil.GetAtlasInfo(atlas)
	atlas = string.lower(atlas);

	local customAtlasInfo = TRP3_AtlasData[atlas];

	if customAtlasInfo then
		return customAtlasInfo;
	end

	local blizzardAtlasInfo;

	if C_Texture then
		blizzardAtlasInfo = C_Texture.GetAtlasInfo(atlas);
	else
		local file, width, height, leftTexCoord, rightTexCoord, topTexCoord, bottomTexCoord, tilesHorizontally, tilesVertically = GetAtlasInfo(atlas);

		if file then
			blizzardAtlasInfo = {};
			blizzardAtlasInfo.file = (type(file) == "number") and file or nil;
			blizzardAtlasInfo.filename = (type(file) == "string") and file or nil;
			blizzardAtlasInfo.width = width;
			blizzardAtlasInfo.height = height;
			blizzardAtlasInfo.leftTexCoord = leftTexCoord;
			blizzardAtlasInfo.rightTexCoord = rightTexCoord;
			blizzardAtlasInfo.topTexCoord = topTexCoord;
			blizzardAtlasInfo.bottomTexCoord = bottomTexCoord;
			blizzardAtlasInfo.tilesHorizontally = tilesHorizontally;
			blizzardAtlasInfo.tilesVertically = tilesVertically;
		end
	end

	return blizzardAtlasInfo;
end

function TRP3_TextureUtil.GetAtlasForTexture(texture)
	return texture:GetAtlas() or texture.lastAppliedAtlas;
end

function TRP3_TextureUtil.SetTextureToAtlas(texture, atlas, useAtlasSize)
	atlas = string.lower(atlas);

	local atlasInfo = TRP3_AtlasData[atlas];

	if not atlasInfo then
		texture:SetAtlas(atlas, useAtlasSize);
	else
		local file       = atlasInfo.file or atlasInfo.filename;
		local horizWrap  = atlasInfo.tilesHorizontally and "REPEAT" or "CLAMP";
		local vertWrap   = atlasInfo.tilesVertically and "REPEAT" or "CLAMP";
		local filterMode = "LINEAR";
		local minX       = atlasInfo.leftTexCoord;
		local maxX       = atlasInfo.rightTexCoord;
		local minY       = atlasInfo.topTexCoord;
		local maxY       = atlasInfo.bottomTexCoord;

		texture:SetTexCoord(minX, maxX, minY, maxY);
		texture:SetTexture(file, horizWrap, vertWrap, filterMode);

		if useAtlasSize then
			texture:SetSize(atlasInfo.width, atlasInfo.height);
		end
	end

	texture.lastAppliedAtlas = atlas;
end

-- Constants copied from TextureUtil.lua for compatibility with Classic; these
-- will be removed one day.

TRP3_TextureKitConstants =
{
	SetVisibility = true;
	DoNotSetVisibility = false;

	UseAtlasSize = true;
	IgnoreAtlasSize = false;
};
