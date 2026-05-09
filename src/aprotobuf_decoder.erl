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
-export([parse/2, transform_schema/1]).

transform_schema(Schema) ->
    Iterator = maps:iterator(Schema),
    decode_schema(maps:next(Iterator), #{}).

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
decode_schema({K, {FieldNum, {map, KeyType, ValueType}}, I}, Acc) when
    is_atom(KeyType) and is_atom(ValueType) and is_integer(FieldNum) and (FieldNum >= 0)
->
    EntrySubSchema = transform_schema(#{key => {1, KeyType}, value => {2, ValueType}}),
    decode_schema(maps:next(I), Acc#{FieldNum => {K, {map, EntrySubSchema}}});
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
    parse(Bin, Schema, tag, #{}).

parse(<<>>, _Schema, tag, Acc) ->
    Acc;
parse(Bin, Schema, What, Acc) ->
    case What of
        tag ->
            parse_varint(Bin, 0, 0, value, Schema, Acc);
        value ->
            [Tag | _Built] = Acc,
            WireType = Tag band 7,
            case WireType of
                0 -> parse_varint(Bin, 0, 0, end_of_field, Schema, Acc);
                1 -> parse_fixed64(Bin, end_of_field, Schema, Acc);
                2 -> parse_varint(Bin, 0, 0, len_field_value, Schema, Acc);
                3 -> {error, unsupported_group};
                4 -> {error, invalid};
                5 -> parse_fixed32(Bin, end_of_field, Schema, Acc);
                6 -> {error, unsupported_feature};
                7 -> {error, unsupported_feature}
            end;
        end_of_field ->
            [Value, Tag | Built] = Acc,
            FieldNum = Tag bsr 3,
            {Key, Type} = maps:get(FieldNum, Schema, {x, undefined}),
            NewAcc = put_value(Built, Key, Type, Value),
            parse(Bin, Schema, tag, NewAcc);
        len_field_value ->
            [Len, Tag | Built] = Acc,
            <<SubBin:Len/binary, Rest/binary>> = Bin,
            FieldNum = Tag bsr 3,
            {Key, Type} = maps:get(FieldNum, Schema, {x, undefined}),
            NewAcc = put_len_value(Built, Key, Type, SubBin),
            parse(Rest, Schema, tag, NewAcc)
    end.

put_value(Built, Key, {repeated, ElemType}, Value) ->
    Existing = maps:get(Key, Built, []),
    maps:put(Key, Existing ++ [cast(Value, ElemType)], Built);
put_value(Built, Key, Type, Value) ->
    maps:put(Key, cast(Value, Type), Built).

put_len_value(Built, Key, {repeated, ElemType}, Bin) ->
    Existing = maps:get(Key, Built, []),
    NewElems =
        case is_packable(ElemType) of
            true -> parse_packed(Bin, ElemType, []);
            false -> [cast(Bin, ElemType)]
        end,
    maps:put(Key, Existing ++ NewElems, Built);
put_len_value(Built, Key, {map, EntrySubSchema}, Bin) ->
    EntryMap = cast(Bin, EntrySubSchema),
    K0 = maps:get(key, EntryMap),
    V0 = maps:get(value, EntryMap),
    Existing = maps:get(Key, Built, #{}),
    maps:put(Key, Existing#{K0 => V0}, Built);
put_len_value(Built, Key, Type, Bin) ->
    maps:put(Key, cast(Bin, Type), Built).

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

parse_varint(<<0:1, IntValue:7, Rest/binary>>, IntAcc, Bytes, Next, Schema, Acc) when Bytes =< 9 ->
    VarInt = (IntValue bsl 7 * Bytes) bor IntAcc,
    parse(Rest, Schema, Next, [VarInt | Acc]);
parse_varint(<<1:1, IntValue:7, Rest/binary>>, IntAcc, Bytes, Next, Schema, Acc) when Bytes =< 9 ->
    VarInt = (IntValue bsl 7 * Bytes) bor IntAcc,
    parse_varint(Rest, VarInt, Bytes + 1, Next, Schema, Acc);
parse_varint(Bin, _IntAcc, _Bytes, _Next, _Schema, Acc) ->
    {invalid, Bin, Acc}.

parse_fixed32(<<Fixed32:4/binary, Rest/binary>>, Next, Schema, Acc) ->
    parse(Rest, Schema, Next, [Fixed32 | Acc]).

parse_fixed64(<<Fixed64:8/binary, Rest/binary>>, Next, Schema, Acc) ->
    parse(Rest, Schema, Next, [Fixed64 | Acc]).

cast(Value, int32) ->
    case Value bsr 63 of
        0 -> Value;
        _ -> Value - (1 bsl 64)
    end;
cast(Value, int64) ->
    case Value bsr 63 of
        0 -> Value;
        _ -> Value - (1 bsl 64)
    end;
cast(Value, uint32) ->
    Value;
cast(Value, uint64) ->
    Value;
cast(Value, sint32) ->
    (Value bsr 1) bxor -(Value band 1);
cast(Value, sint64) ->
    (Value bsr 1) bxor -(Value band 1);
cast(Value, {enum, IntToLabels}) ->
    case maps:find(Value, IntToLabels) of
        {ok, Label} -> Label;
        error -> Value
    end;
cast(<<Value:32/integer-little-unsigned>>, fixed32) ->
    Value;
cast(<<Value:32/integer-little-signed>>, sfixed32) ->
    Value;
cast(<<Value:64/integer-little-unsigned>>, fixed64) ->
    Value;
cast(<<Value:64/integer-little-signed>>, sfixed64) ->
    Value;
cast(<<X:32/integer-little-unsigned>>, float) when X =:= 16#7F800000 ->
    infinity;
cast(<<X:32/integer-little-unsigned>>, float) when X =:= 16#FF800000 ->
    '-infinity';
cast(<<X:32/integer-little-unsigned>>, float) when (X band 16#7F800000) =:= 16#7F800000 ->
    nan;
cast(<<Value:32/float-little>>, float) ->
    Value;
cast(<<X:64/integer-little-unsigned>>, double) when X =:= 16#7FF0000000000000 ->
    infinity;
cast(<<X:64/integer-little-unsigned>>, double) when X =:= 16#FFF0000000000000 ->
    '-infinity';
cast(<<X:64/integer-little-unsigned>>, double) when
    (X band 16#7FF0000000000000) =:= 16#7FF0000000000000
->
    nan;
cast(<<Value:64/float-little>>, double) ->
    Value;
cast(Value, undefined) ->
    Value;
cast(Value, bytes) ->
    Value;
cast(Value, string) ->
    Value;
cast(Value, bool) ->
    Value =/= 0;
cast(Bin, {repeated, ElemType}) when is_binary(Bin) ->
    parse_packed(Bin, ElemType, []);
cast(Value, Proto) when is_map(Proto) ->
    parse(Value, Proto).

parse_packed(<<>>, _ElemType, Acc) ->
    lists:reverse(Acc);
parse_packed(Bin, ElemType, Acc) when
    ElemType =:= int32;
    ElemType =:= int64;
    ElemType =:= uint32;
    ElemType =:= uint64;
    ElemType =:= sint32;
    ElemType =:= sint64;
    ElemType =:= bool
->
    {V, Rest} = parse_packed_varint(Bin, 0, 0),
    parse_packed(Rest, ElemType, [cast(V, ElemType) | Acc]);
parse_packed(<<B:4/binary, Rest/binary>>, ElemType, Acc) when
    ElemType =:= fixed32; ElemType =:= sfixed32; ElemType =:= float
->
    parse_packed(Rest, ElemType, [cast(B, ElemType) | Acc]);
parse_packed(<<B:8/binary, Rest/binary>>, ElemType, Acc) when
    ElemType =:= fixed64; ElemType =:= sfixed64; ElemType =:= double
->
    parse_packed(Rest, ElemType, [cast(B, ElemType) | Acc]).

parse_packed_varint(<<0:1, V:7, Rest/binary>>, Acc, Bytes) when Bytes =< 9 ->
    {(V bsl 7 * Bytes) bor Acc, Rest};
parse_packed_varint(<<1:1, V:7, Rest/binary>>, Acc, Bytes) when Bytes =< 9 ->
    parse_packed_varint(Rest, (V bsl 7 * Bytes) bor Acc, Bytes + 1).
