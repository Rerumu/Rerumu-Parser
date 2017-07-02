local Encode, Decode, Extract;

local SetMeta	= setmetatable;
local Tostring	= tostring;
local Tonumber	= tonumber;
local Concat	= table.concat;
local Gsub, Sub	= string.gsub, string.sub;
local Match		= string.match;
local Type		= type;

local EFormat, DFormat	= {}, {};
local Backs = {
	{'\b', '\\b'};
	{'\t', '\\t'};
	{'\n', '\\n'};
	{'\f', '\\f'};
	{'\r', '\\r'};
	{'"', '\\"'};
	{'\\', '\\\\'};
};

for Idx = 1, #Backs do
	local Pair	= Backs[Idx];

	EFormat[Pair[1]]	= Pair[2];
	DFormat[Pair[2]]	= Pair[1];
end;

Backs	= nil;

local __tMemoize	= {
	__index	= function(self, String)
		local Res	= Match(self[1], String);

		self[2]	= Res;

		return Res;
	end;
};

local function SafeString(String, EncStr)
	if EncStr then
		return (Gsub(String, '[\b\t\n\f\r\\"]', EFormat));
	else
		return (Gsub(String, '\\.', DFormat));
	end;
end;

function Extract(Data)
	local Mem	= SetMeta({Data}, __tMemoize);

	if Mem['^%[.-%]$'] then -- Things are decoded here, feel free to add.
		return Decode(Mem[2]);
	elseif Mem['^"(.-)"$'] then
		return SafeString(Mem[2]);
	elseif Mem['^true$'] then
		return true;
	elseif Mem['^false$'] then
		return false;
	else
		return Tonumber(Data) or Data;
	end;
end;

function Encode(Table, Buff)
	local Result	= {};
	local Buff		= Buff or {};

	for Index, Value in next, Table do
		local Idx, Val	= '', 'null';
		local ValT		= Type(Value);

		if (Type(Index) == 'string') then
			Idx	= Concat{'"', SafeString(Index, true), '":'};
		end;

		if (ValT == 'number') or (ValT == 'boolean') then -- Things are encoded here; feel free to add.
			Val	= Tostring(Value);
		elseif (ValT == 'string') then
			Val	= Concat{'"', SafeString(Value, true), '"'};
		elseif (ValT == 'table') and (not Buff[Value]) then
			Buff[Value]	= true;

			Val	= Encode(Value, Buff);
		end;

		Result[#Result + 1]	= (Idx .. Val);
	end;

	return Concat{'[', Concat(Result, ';'), ']'};
end;

function Decode(String)
	local Result	= {};
	local Tables	= 0;
	local Len		= #String;
	local Esc, Quo;
	local Layer;

	for Idx = 1, Len do
		local Char	= Sub(String, Idx, Idx);

		if Layer then
			Layer[#Layer + 1]	= Char;
		elseif (not Layer) and (Idx ~= 1) then
			Layer	= {Char};
		end;

		if (not Esc) then
			if (Char == '\\') then
				Esc	= true;
			elseif (Char == '"') then
				Quo	= (not Quo);
			elseif ((not Quo) and (Char == ';') and (Tables == 1)) or (Idx == Len) then
				local Lay	= Concat(Layer);
				local Index	= Match(Gsub(Lay, '\\"', ''), '^".-":.+$');

				if Index then
					Index	= false;

					for Idz = 2, #Layer do
						local Char	= Layer[Idz];

						if (not Index) then
							if (Char == '"') then
								Index	= Idz - 1;

								break;
							else
								Index	= (Char == '\\');
							end;
						else
							Index	= false;
						end;
					end;

					Result[SafeString(Sub(Lay, 2, Index))]	= Extract(Sub(Lay, Index + 3, -2));
				elseif (Lay ~= '') then
					Result[#Result + 1]	= Extract(Sub(Lay, 1, -2));
				end;
				
				Layer	= nil;
			elseif (not Quo) then
				if (Char == '[') then
					Tables	= Tables + 1;
				elseif (Char == ']') then
					Tables	= Tables - 1;
				end;
			end;
		else
			Esc	= false;
		end;
	end;

	return Result;
end;

return {Encode, Decode};