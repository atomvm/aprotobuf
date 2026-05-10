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

-module(aprotobuf_encoder).
-export([encode/2]).

-define(LEN_TAG, 2).
-define(FIXED32_TAG, 5).
-define(FIXED64_TAG, 1).

encode(Map, Schema) ->
    Iterator = maps:iterator(Map),
    encode(maps:next(Iterator), Schema, [<<>>]).

encode(none, _Schema, Acc) ->
    Acc;
encode({K, V, I}, Schema, Acc) ->
    {FieldNum, Type} = maps:get(K, Schema),
    NewAcc = [encode_field(FieldNum, V, Type) | Acc],
    encode(maps:next(I), Schema, NewAcc).

encode_field(FieldNum, V, bytes) ->
    Len = erlang:iolist_size(V),
    [encode_varint((FieldNum bsl 3) bor ?LEN_TAG), encode_varint(Len), V];
encode_field(FieldNum, V, string) ->
    encode_field(FieldNum, V, bytes);
encode_field(FieldNum, V, {enum, LabelsToInt}) ->
    IntVal = maps:get(V, LabelsToInt),
    [encode_varint(FieldNum bsl 3), encode_varint(IntVal)];
encode_field(FieldNum, V, int32) when is_integer(V), V >= 0, V < (1 bsl 31) ->
    [encode_varint(FieldNum bsl 3), encode_varint(V)];
encode_field(FieldNum, V, int32) when is_integer(V), V < 0, V >= -(1 bsl 31) ->
    [encode_varint(FieldNum bsl 3), encode_varint(V band 16#FFFFFFFFFFFFFFFF)];
encode_field(_FieldNum, _V, int32) ->
    error(badarg);
encode_field(FieldNum, V, int64) when is_integer(V), V >= 0, V < (1 bsl 63) ->
    [encode_varint(FieldNum bsl 3), encode_varint(V)];
encode_field(FieldNum, V, int64) when is_integer(V), V < 0, V >= -(1 bsl 63) ->
    [encode_varint(FieldNum bsl 3), encode_varint(V band 16#FFFFFFFFFFFFFFFF)];
encode_field(_FieldNum, _V, int64) ->
    error(badarg);
encode_field(FieldNum, V, uint32) when is_integer(V), V >= 0, V < (1 bsl 32) ->
    [encode_varint(FieldNum bsl 3), encode_varint(V)];
encode_field(_FieldNum, _V, uint32) ->
    error(badarg);
encode_field(FieldNum, V, uint64) when is_integer(V), V >= 0, V < (1 bsl 64) ->
    [encode_varint(FieldNum bsl 3), encode_varint(V)];
encode_field(_FieldNum, _V, uint64) ->
    error(badarg);
encode_field(FieldNum, V, sint32) when is_integer(V), V >= -(1 bsl 31), V < (1 bsl 31) ->
    Z = ((V bsl 1) bxor (V bsr 31)) band 16#FFFFFFFF,
    [encode_varint(FieldNum bsl 3), encode_varint(Z)];
encode_field(_FieldNum, _V, sint32) ->
    error(badarg);
encode_field(FieldNum, V, sint64) when is_integer(V), V >= -(1 bsl 63), V < (1 bsl 63) ->
    Z = ((V bsl 1) bxor (V bsr 63)) band 16#FFFFFFFFFFFFFFFF,
    [encode_varint(FieldNum bsl 3), encode_varint(Z)];
encode_field(_FieldNum, _V, sint64) ->
    error(badarg);
encode_field(FieldNum, V, sfixed32) ->
    [encode_varint((FieldNum bsl 3) bor ?FIXED32_TAG), encode_sfixed32(V)];
encode_field(FieldNum, V, fixed32) when is_integer(V), V >= 0, V < (1 bsl 32) ->
    [encode_varint((FieldNum bsl 3) bor ?FIXED32_TAG), encode_fixed32(V)];
encode_field(_FieldNum, _V, fixed32) ->
    error(badarg);
encode_field(FieldNum, V, fixed64) when is_integer(V), V >= 0, V < (1 bsl 64) ->
    [encode_varint((FieldNum bsl 3) bor ?FIXED64_TAG), encode_fixed64(V)];
encode_field(_FieldNum, _V, fixed64) ->
    error(badarg);
encode_field(FieldNum, V, sfixed64) when is_integer(V), V >= -(1 bsl 63), V < (1 bsl 63) ->
    [encode_varint((FieldNum bsl 3) bor ?FIXED64_TAG), encode_sfixed64(V)];
encode_field(_FieldNum, _V, sfixed64) ->
    error(badarg);
encode_field(FieldNum, V, float) ->
    [encode_varint((FieldNum bsl 3) bor ?FIXED32_TAG), encode_float(V)];
encode_field(FieldNum, V, double) ->
    [encode_varint((FieldNum bsl 3) bor ?FIXED64_TAG), encode_double(V)];
encode_field(FieldNum, false, bool) ->
    [encode_varint(FieldNum bsl 3), <<0>>];
encode_field(FieldNum, true, bool) ->
    [encode_varint(FieldNum bsl 3), <<1>>];
encode_field(_FieldNum, _V, bool) ->
    error(badarg);
encode_field(_FieldNum, [], {repeated, _ElemType}) ->
    [];
encode_field(FieldNum, V, {repeated, ElemType}) when is_list(V) ->
    case is_packable(ElemType) of
        true ->
            Body = iolist_to_binary([encode_packed_elem(E, ElemType) || E <- V]),
            Len = byte_size(Body),
            [encode_varint((FieldNum bsl 3) bor ?LEN_TAG), encode_varint(Len), Body];
        false ->
            [encode_field(FieldNum, E, ElemType) || E <- V]
    end;
encode_field(FieldNum, V, {map, KeyType, ValueType}) when is_map(V) ->
    EntrySubSchema = #{key => {1, KeyType}, value => {2, ValueType}},
    [
        encode_field(FieldNum, #{key => K0, value => V0}, EntrySubSchema)
     || {K0, V0} <- maps:to_list(V)
    ];
encode_field(FieldNum, V, MapSchema) when is_map(MapSchema) ->
    Encoded = encode(V, MapSchema),
    Len = erlang:iolist_size(Encoded),
    [encode_varint((FieldNum bsl 3) bor ?LEN_TAG), encode_varint(Len), Encoded];
encode_field(_FiledNum, _V, _Type) ->
    [].

encode_sfixed32(Int) ->
    <<Int:32/little-signed-integer>>.

encode_fixed32(Int) ->
    <<Int:32/little-unsigned-integer>>.

encode_float(V) when is_number(V), abs(V) =< 3.4028234663852886e+38 ->
    <<V:32/float-little>>;
encode_float(infinity) ->
    <<0, 0, 16#80, 16#7F>>;
encode_float('-infinity') ->
    <<0, 0, 16#80, 16#FF>>;
encode_float(nan) ->
    <<0, 0, 16#C0, 16#7F>>;
encode_float(_) ->
    error(badarg).

encode_double(V) when is_number(V) ->
    <<V:64/float-little>>;
encode_double(infinity) ->
    <<0, 0, 0, 0, 0, 0, 16#F0, 16#7F>>;
encode_double('-infinity') ->
    <<0, 0, 0, 0, 0, 0, 16#F0, 16#FF>>;
encode_double(nan) ->
    <<0, 0, 0, 0, 0, 0, 16#F8, 16#7F>>;
encode_double(_) ->
    error(badarg).

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

encode_packed_elem(V, int32) when is_integer(V), V >= 0, V < (1 bsl 31) ->
    encode_varint(V);
encode_packed_elem(V, int32) when is_integer(V), V < 0, V >= -(1 bsl 31) ->
    encode_varint(V band 16#FFFFFFFFFFFFFFFF);
encode_packed_elem(V, int64) when is_integer(V), V >= 0, V < (1 bsl 63) ->
    encode_varint(V);
encode_packed_elem(V, int64) when is_integer(V), V < 0, V >= -(1 bsl 63) ->
    encode_varint(V band 16#FFFFFFFFFFFFFFFF);
encode_packed_elem(false, bool) ->
    <<0>>;
encode_packed_elem(true, bool) ->
    <<1>>;
encode_packed_elem(V, fixed32) when is_integer(V), V >= 0, V < (1 bsl 32) ->
    encode_fixed32(V);
encode_packed_elem(V, uint32) when is_integer(V), V >= 0, V < (1 bsl 32) ->
    encode_varint(V);
encode_packed_elem(V, uint64) when is_integer(V), V >= 0, V < (1 bsl 64) ->
    encode_varint(V);
encode_packed_elem(V, sint32) when is_integer(V), V >= -(1 bsl 31), V < (1 bsl 31) ->
    encode_varint(((V bsl 1) bxor (V bsr 31)) band 16#FFFFFFFF);
encode_packed_elem(V, sint64) when is_integer(V), V >= -(1 bsl 63), V < (1 bsl 63) ->
    encode_varint(((V bsl 1) bxor (V bsr 63)) band 16#FFFFFFFFFFFFFFFF);
encode_packed_elem(V, sfixed32) ->
    encode_sfixed32(V);
encode_packed_elem(V, fixed64) when is_integer(V), V >= 0, V < (1 bsl 64) ->
    encode_fixed64(V);
encode_packed_elem(V, sfixed64) when is_integer(V), V >= -(1 bsl 63), V < (1 bsl 63) ->
    encode_sfixed64(V);
encode_packed_elem(V, float) ->
    encode_float(V);
encode_packed_elem(V, double) ->
    encode_double(V).

encode_fixed64(Int) ->
    <<Int:64/little-unsigned-integer>>.

encode_sfixed64(Int) ->
    <<Int:64/little-signed-integer>>.

encode_varint(Int) when is_integer(Int), Int >= 0, Int < 128 ->
    [Int];
encode_varint(Int) when is_integer(Int), Int >= 128, Int < (1 bsl 64) ->
    encode_varint_more(Int);
encode_varint(_Int) ->
    error(badarg).

encode_varint_more(Int) when Int < 128 ->
    [Int];
encode_varint_more(Int) ->
    [(Int band 16#7F) bor 16#80 | encode_varint_more(Int bsr 7)].
