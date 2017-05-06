local type, typeof										= type, typeof;
local string, unpack, Insert							= string, unpack, table.insert;
local tonumber, tostring, Fort, Gsub, Gmatch, Sub		= tonumber, tostring, string.format, string.gsub, string.gmatch, string.sub;
local CFrame, Vector3, Vector3int16, Vector2, Vector2int16, UDim, UDim2, Color3, Ray	= CFrame, Vector3, Vector3int16, Vector2, Vector2int16, UDim, UDim2, Color3, Ray;
local Backslashes = {
	['\b']	= '\\b';
	['\t']	= '\\t';
	['\n']	= '\\n';
	['\f']	= '\\f';
	['\r']	= '\\r';
	['"']	= '\\"';
	['\\']	= '';
};

local Http, ParseTemp	= game:GetService'HttpService', '%s%s:%s';
local Yield				= game:GetService'RunService'.Stepped;
local Format, UnForm, Form, Assert;

local Methods	= {
	JSONE	= function(Data)
		return Http:JSONEncode(Data);
	end;
	JSOND	= function(Data)
		return Http:JSONDecode(Data);
	end;
	RerE	= function(Data)
		Assert(Data, 'table', 'Error: Item to parse must be a table.')

		local Buffer	= {};
		local Parse		= '[';

		local function LookE(Tab)
			if (typeof(Tab) ~= 'table') then return nil end;
			local LocalParse = '';

			for Index, Value in next, Tab do
				local IndType	= type(Index);

				if (IndType == 'string') or (IndType == 'number') then
					local ValType	= typeof(Value);
					local RealType	= type(Value);
					local IndexForm	= ((IndType == 'string') and Fort('%q', Index)) or 'x'

					if (RealType == 'table') and (not Buffer[Value]) then
						LocalParse = Format(LocalParse, IndexForm, '[' .. LookE(Value) .. ']')
						Buffer[Value] = true;
					elseif (RealType == 'number') or (RealType == 'boolean') then
						LocalParse = Format(LocalParse, IndexForm, tostring(Value))
					elseif (RealType == 'string') then
						LocalParse = Format(LocalParse, IndexForm, Fort('%q', Value));--:gsub('"', '\\"')));
					elseif (ValType == 'CFrame') then
						LocalParse = Format(LocalParse, IndexForm, Fort('CF(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)', Value:components()))
					elseif (ValType == 'Vector2') then
						LocalParse = Format(LocalParse, IndexForm, Fort('V2(%s,%s)', Value.X, Value.Y))
					elseif (ValType == 'UDim') then
						LocalParse = Format(LocalParse, IndexForm, Fort('U1(%s,%s)', Value.Scale, Value.Offset))
					elseif (ValType == 'UDim2') then
						LocalParse = Format(LocalParse, IndexForm, Fort('U2(%s,%s,%s,%s)', Value.X.Scale, Value.X.Offset, Value.Y.Scale, Value.Y.Offset))
					elseif (ValType == 'Vector2int16') then
						LocalParse = Format(LocalParse, IndexForm, Fort('V216(%s,%s)', Value.X, Value.Y))
					elseif (ValType == 'Vector3') then
						LocalParse = Format(LocalParse, IndexForm, Fort('V3(%s,%s,%s)', Value.X, Value.Y, Value.Z))
					elseif (ValType == 'Vector3int16') then
						LocalParse = Format(LocalParse, IndexForm, Fort('V316(%s,%s,%s)', Value.X, Value.Y, Value.Z))
					elseif (ValType == 'Color3') then
						LocalParse = Format(LocalParse, IndexForm, Fort('C3(%s,%s,%s)', Value.r, Value.g, Value.b))
					elseif (ValType == 'Ray') then
						LocalParse = Format(LocalParse, IndexForm, Fort('R(%s,%s,%s,%s,%s,%s)', Value.Origin.X, Value.Origin.Y, Value.Origin.Z, Value.Direction.X, Value.Direction.Y, Value.Direction.Z))
					end;
				end
			end

			return LocalParse
		end

		Parse = Parse .. LookE(Data) .. ']';

		return Parse;
	end;
	RerD	= function(Data)
		Assert(Data, 'string', 'Error: Item to decode must be a string.')

		local IsData = Data:match('^%[(.*)%]$');

		assert(IsData, 'Error: Could not decode, incorrect format.')
		local DataChunk = {};

		local function Separate(String)
			local Iteration		= 0;
			local TableOpen		= 0;
			local StringOpen
			local Last

			local LocalBuffer	= '';
			local Index, Value

			for K = 1, #String do
				local L	= Sub(String, K, K);

				if (L == '"') and (Last ~= '\\') and (TableOpen == 0) then
					StringOpen = (not StringOpen);
				elseif (L == '[') and (not StringOpen) then
					TableOpen = TableOpen + 1;
				elseif (L == ']') and (not StringOpen) then
					TableOpen = TableOpen - 1;
				end

				if (L == ':') and (not StringOpen) and (TableOpen == 0) and (not Index) then
					Index = ((LocalBuffer == 'x') and 0) or LocalBuffer;
					LocalBuffer = '';
				elseif Index then
					Value = (Value and (Value .. L)) or L;
				end;

				Iteration	= Iteration + 1;
				LocalBuffer = LocalBuffer .. L;

				if (Iteration % 240 == 0) then
					Yield:wait(); -- No weird errors because too many iterations.
				end;
			end

			if (type(Index) == 'string') then
				Index	= Gsub(Index, '\\', '');
			end;

			return Index, Value;
		end;

		local function Iterate(Table, String)
			local Run			= 0
			local LocalBuffer	= '';
			local HasCond
			local TableOpen		= 0;
			local StringOpen
			local Last

			for K = 1, #String do
				local L	= Sub(String, K, K);

				HasCond		= false;
				Run			= Run + 1;
				LocalBuffer	= LocalBuffer .. L;

				if (L == '"') and (Last ~= '\\') and (TableOpen == 0) then
					StringOpen	= (not StringOpen);
					HasCond		= true;
				elseif (L == '[') and (not StringOpen) then
					TableOpen	= TableOpen + 1;
					HasCond		= true;
				elseif (L == ']') and (not StringOpen) then
					TableOpen	= TableOpen - 1;
					HasCond		= true;
				end;

				if ((not HasCond) and (L == ';') and (not StringOpen) and (TableOpen == 0)) or (Run == #String) then
					local Got, Result	= Separate(LocalBuffer)
					local IsTable		= Result:match('^%[(.*)%];?$')

					local Index = ((Got ~= 0) and ((Got:match('"(.*)"') or Got))) or (#Table + 1);

					if IsTable then
						local NewTab = {};

						Table[Index] = NewTab;

						Iterate(NewTab, IsTable);
					else
						Table[Index] = Form(Result);
					end

					LocalBuffer = '';
				end
			end;
		end;

		Iterate(DataChunk, Data:match('^%[(.*)%];?$'))

		return DataChunk;
	end;
};

function Format(LocalParse, Index, Item)
	return Fort(ParseTemp, ((LocalParse == '') and LocalParse) or (LocalParse .. ';'), Index, Item);
end

function UnForm(String)
	return Gsub(String, '[%z%c\\"/]', function(S)
		return Backslashes[S] or S;--Format('\\u%.4X', Byte(S));
	end);
end;

function Form(Data)
	local Match	= setmetatable({},{__index = function(Tab, Set) rawset(Tab, Set, Data:match(Set)) return rawget(Tab, Set) end})

	if Match['"(.*)"'] then
		return UnForm(Match['"(.*)"']);
	elseif tonumber(Match['^[^;]+']) then
		return tonumber(Match['^[^;]+'])
	elseif Match['CF%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['CF%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return CFrame.new(unpack(Args))
	elseif Match['V2%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['V2%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return Vector2.new(unpack(Args))
	elseif Match['V216%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['V216%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return Vector2int16.new(unpack(Args))
	elseif Match['V3%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['V3%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return Vector3.new(unpack(Args))
	elseif Match['V316%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['V316%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return Vector3int16.new(unpack(Args))
	elseif Match['U2%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['U2%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return UDim2.new(unpack(Args))
	elseif Match['U1%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['U1%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return UDim.new(unpack(Args))
	elseif Match['C3%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['C3%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return Color3.new(unpack(Args))
	elseif Match['R%((.*)%)'] then
		local Args	= {};

		for L in Gmatch(Match['R%((.*)%)'], '[^,]+') do
			Insert(Args, L)
		end

		return Ray.new(Vector3.new(Args[1], Args[2], Args[3]), Vector3.new(Args[4], Args[5], Args[6]))
	elseif Match['^true'] then
		return true;
	elseif Match['^false'] then
		return false;
	end

	return 'null';
end

function Assert(Data, DType, Error)
	return assert(type(Data) == DType, Error);
end

return function(Method, Data)
	return Methods[Method](Data);
end
