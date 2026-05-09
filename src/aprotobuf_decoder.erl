%
% This file is part of aprotobuf.
%
% Copyright 2023 Davide Bettio <davide@uninstall.it>
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% SPDX-License-Identifier: Apache-2.0
%

-module(aprotobuf_decoder).
-export([parse/2, parse/3, transform_schema/1, transform_schemas/1]).

transform_schema(Schema) ->
    Iterator = maps:iterator(Schema),
    decode_schema(maps:next(Iterator), #{}).

transform_schemas(Registry) ->
    maps:map(fun(_Name, Schema) -> transform_schema(Schema) end, Registry).

decode_schema(none, Acc) ->
    Acc;
decode_schema({K, {FieldNum, Type}, I}, Acc) when
    is_atom(Type) and is_integer(FieldNum) and (FieldNum >= 0)
->
    decode_schema(maps:next(I), Acc#{FieldNum => {K, Type}});
decode_schema({K, {FieldNum, Type}, I}, Acc) when
    is_map(Type) and is_integer(FieldNum) and (FieldNum >= 0)
->
    decode_schema(maps:next(I), Acc#{FieldNum => {K, transform_schema(Type)}});
decode_schema({K, {FieldNum, {enum, LabelsToInts}}, I}, Acc) when
    is_map(LabelsToInts) and is_integer(FieldNum) and (FieldNum >= 0)
->
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {enum, transform_enum_map(LabelsToInts)}}});
decode_schema({K, {FieldNum, {repeated, ElemType}}, I}, Acc) when
    is_atom(ElemType) and is_integer(FieldNum) and (FieldNum >= 0)
->
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {repeated, ElemType}}});
decode_schema({K, {FieldNum, {repeated, {ref, Name}}}, I}, Acc) when
    is_atom(Name) and is_integer(FieldNum) and (FieldNum >= 0)
->
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {repeated, {ref, Name}}}});
decode_schema({K, {FieldNum, {map, KeyType, ValueType}}, I}, Acc) when
    is_atom(KeyType) and is_atom(ValueType) and is_integer(FieldNum) and (FieldNum >= 0)
->
    EntrySubSchema = transform_schema(#{key => {1, KeyType}, value => {2, ValueType}}),
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {map, EntrySubSchema}}});
decode_schema({K, {FieldNum, {map, KeyType, {ref, Name}}}, I}, Acc) when
    is_atom(KeyType) and is_atom(Name) and is_integer(FieldNum) and (FieldNum >= 0)
->
    EntrySubSchema = transform_schema(#{key => {1, KeyType}, value => {2, {ref, Name}}}),
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {map, EntrySubSchema}}});
decode_schema({K, {FieldNum, {ref, Name}}, I}, Acc) when
    is_atom(Name) and is_integer(FieldNum) and (FieldNum >= 0)
->
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {ref, Name}}});
decode_schema({K, T, _I}, _Acc) ->
    error({badarg, K, T}).

transform_enum_map(Map) ->
    Iterator = maps:iterator(Map),
    transform_enum_map(maps:next(Iterator), #{}).

transform_enum_map(none, Acc) ->
    Acc;
transform_enum_map({K, V, I}, Acc) ->
    transform_enum_map(maps:next(I), Acc#{V => K}).

parse(Bin, Schema) ->
    parse(Bin, root, #{root => Schema}).

parse(Bin, EntryName, Registry) ->
    Schema = maps:get(EntryName, Registry),
    parse_state(Bin, Schema, Registry, tag, #{}).

parse_state(<<>>, _Schema, _Registry, tag, Acc) ->
    Acc;
parse_state(Bin, Schema, Registry, What, Acc) ->
    case What of
        tag ->
            parse_varint(Bin, 0, 0, value, Schema, Registry, Acc);
        value ->
            [Tag | _Built] = Acc,
            WireType = Tag band 7,
            case WireType of
                0 -> parse_varint(Bin, 0, 0, end_of_field, Schema, Registry, Acc);
                1 -> parse_fixed64(Bin, end_of_field, Schema, Registry, Acc);
                2 -> parse_varint(Bin, 0, 0, len_field_value, Schema, Registry, Acc);
                3 -> {error, unsupported_group};
                4 -> {error, invalid};
                5 -> parse_fixed32(Bin, end_of_field, Schema, Registry, Acc);
                6 -> {error, unsupported_feature};
                7 -> {error, unsupported_feature}
            end;
        end_of_field ->
            [Value, Tag | Built] = Acc,
            FieldNum = Tag bsr 3,
            {Key, Type} = maps:get(FieldNum, Schema, {x, undefined}),
            NewAcc = put_value(Built, Key, Type, Value, Registry),
            parse_state(Bin, Schema, Registry, tag, NewAcc);
        len_field_value ->
            [Len, Tag | Built] = Acc,
            <<SubBin:Len/binary, Rest/binary>> = Bin,
            FieldNum = Tag bsr 3,
            {Key, Type} = maps:get(FieldNum, Schema, {x, undefined}),
            NewAcc = put_len_value(Built, Key, Type, SubBin, Registry),
            parse_state(Rest, Schema, Registry, tag, NewAcc)
    end.

put_value(Built, Key, {repeated, ElemType}, Value, Registry) ->
    Existing = maps:get(Key, Built, []),
    maps:put(Key, Existing ++ [cast(Value, ElemType, Registry)], Built);
put_value(Built, Key, Type, Value, Registry) ->
    maps:put(Key, cast(Value, Type, Registry), Built).

put_len_value(Built, Key, {repeated, {ref, Name}}, Bin, Registry) ->
    Schema = maps:get(Name, Registry),
    Existing = maps:get(Key, Built, []),
    maps:put(Key, Existing ++ [cast(Bin, Schema, Registry)], Built);
put_len_value(Built, Key, {repeated, ElemType}, Bin, Registry) ->
    Existing = maps:get(Key, Built, []),
    NewElems =
        case is_packable(ElemType) of
            true -> parse_packed(Bin, ElemType, Registry, []);
            false -> [cast(Bin, ElemType, Registry)]
        end,
    maps:put(Key, Existing ++ NewElems, Built);
put_len_value(Built, Key, {map, EntrySubSchema}, Bin, Registry) ->
    EntryMap = cast(Bin, EntrySubSchema, Registry),
    K0 = maps:get(key, EntryMap),
    V0 = maps:get(value, EntryMap),
    Existing = maps:get(Key, Built, #{}),
    maps:put(Key, Existing#{K0 => V0}, Built);
put_len_value(Built, Key, Type, Bin, Registry) ->
    maps:put(Key, cast(Bin, Type, Registry), Built).

is_packable(int32) -> true;
is_packable(int64) -> true;
is_packable(uint32) -> true;
is_packable(uint64) -> true;
is_packable(sint32) -> true;
is_packable(sint64) -> true;
is_packable(bool) -> true;
is_packable(fixed32) -> true;
is_packable(sfixed32) -> true;
is_packable(fixed64) -> true;
is_packable(sfixed64) -> true;
is_packable(float) -> true;
is_packable(double) -> true;
is_packable(_) -> false.

parse_varint(<<0:1, IntValue:7, Rest/binary>>, IntAcc, Bytes, Next, Schema, Registry, Acc) when
    Bytes =< 9
->
    VarInt = (IntValue bsl 7 * Bytes) bor IntAcc,
    parse_state(Rest, Schema, Registry, Next, [VarInt | Acc]);
parse_varint(<<1:1, IntValue:7, Rest/binary>>, IntAcc, Bytes, Next, Schema, Registry, Acc) when
    Bytes =< 9
->
    VarInt = (IntValue bsl 7 * Bytes) bor IntAcc,
    parse_varint(Rest, VarInt, Bytes + 1, Next, Schema, Registry, Acc);
parse_varint(Bin, _IntAcc, _Bytes, _Next, _Schema, _Registry, Acc) ->
    {invalid, Bin, Acc}.

parse_fixed32(<<Fixed32:4/binary, Rest/binary>>, Next, Schema, Registry, Acc) ->
    parse_state(Rest, Schema, Registry, Next, [Fixed32 | Acc]).

parse_fixed64(<<Fixed64:8/binary, Rest/binary>>, Next, Schema, Registry, Acc) ->
    parse_state(Rest, Schema, Registry, Next, [Fixed64 | Acc]).

cast(Value, int32, _Registry) ->
    case Value bsr 63 of
        0 -> Value;
        _ -> Value - (1 bsl 64)
    end;
cast(Value, int64, _Registry) ->
    case Value bsr 63 of
        0 -> Value;
        _ -> Value - (1 bsl 64)
    end;
cast(Value, uint32, _Registry) ->
    Value;
cast(Value, uint64, _Registry) ->
    Value;
cast(Value, sint32, _Registry) ->
    (Value bsr 1) bxor -(Value band 1);
cast(Value, sint64, _Registry) ->
    (Value bsr 1) bxor -(Value band 1);
cast(Value, {enum, IntToLabels}, _Registry) ->
    case maps:find(Value, IntToLabels) of
        {ok, Label} -> Label;
        error -> Value
    end;
cast(<<Value:32/integer-little-unsigned>>, fixed32, _Registry) ->
    Value;
cast(<<Value:32/integer-little-signed>>, sfixed32, _Registry) ->
    Value;
cast(<<Value:64/integer-little-unsigned>>, fixed64, _Registry) ->
    Value;
cast(<<Value:64/integer-little-signed>>, sfixed64, _Registry) ->
    Value;
cast(<<X:32/integer-little-unsigned>>, float, _Registry) when X =:= 16#7F800000 ->
    infinity;
cast(<<X:32/integer-little-unsigned>>, float, _Registry) when X =:= 16#FF800000 ->
    '-infinity';
cast(<<X:32/integer-little-unsigned>>, float, _Registry) when
    (X band 16#7F800000) =:= 16#7F800000
->
    nan;
cast(<<Value:32/float-little>>, float, _Registry) ->
    Value;
cast(<<X:64/integer-little-unsigned>>, double, _Registry) when X =:= 16#7FF0000000000000 ->
    infinity;
cast(<<X:64/integer-little-unsigned>>, double, _Registry) when X =:= 16#FFF0000000000000 ->
    '-infinity';
cast(<<X:64/integer-little-unsigned>>, double, _Registry) when
    (X band 16#7FF0000000000000) =:= 16#7FF0000000000000
->
    nan;
cast(<<Value:64/float-little>>, double, _Registry) ->
    Value;
cast(Value, undefined, _Registry) ->
    Value;
cast(Value, bytes, _Registry) ->
    Value;
cast(Value, string, _Registry) ->
    Value;
cast(Value, bool, _Registry) ->
    Value =/= 0;
cast(Value, {ref, Name}, Registry) ->
    Schema = maps:get(Name, Registry),
    cast(Value, Schema, Registry);
cast(Value, Proto, Registry) when is_map(Proto) ->
    parse_state(Value, Proto, Registry, tag, #{}).

parse_packed(<<>>, _ElemType, _Registry, Acc) ->
    lists:reverse(Acc);
parse_packed(Bin, ElemType, Registry, Acc) when
    ElemType =:= int32;
    ElemType =:= int64;
    ElemType =:= uint32;
    ElemType =:= uint64;
    ElemType =:= sint32;
    ElemType =:= sint64;
    ElemType =:= bool
->
    {V, Rest} = parse_packed_varint(Bin, 0, 0),
    parse_packed(Rest, ElemType, Registry, [cast(V, ElemType, Registry) | Acc]);
parse_packed(<<B:4/binary, Rest/binary>>, ElemType, Registry, Acc) when
    ElemType =:= fixed32; ElemType =:= sfixed32; ElemType =:= float
->
    parse_packed(Rest, ElemType, Registry, [cast(B, ElemType, Registry) | Acc]);
parse_packed(<<B:8/binary, Rest/binary>>, ElemType, Registry, Acc) when
    ElemType =:= fixed64; ElemType =:= sfixed64; ElemType =:= double
->
    parse_packed(Rest, ElemType, Registry, [cast(B, ElemType, Registry) | Acc]).

parse_packed_varint(<<0:1, V:7, Rest/binary>>, Acc, Bytes) when Bytes =< 9 ->
    {(V bsl 7 * Bytes) bor Acc, Rest};
parse_packed_varint(<<1:1, V:7, Rest/binary>>, Acc, Bytes) when Bytes =< 9 ->
    parse_packed_varint(Rest, (V bsl 7 * Bytes) bor Acc, Bytes + 1).
