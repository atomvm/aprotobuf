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
encode_field(FieldNum, V, MapSchema) when is_map(MapSchema) ->
    Encoded = encode(V, MapSchema),
    Len = erlang:iolist_size(Encoded),
    [encode_varint((FieldNum bsl 3) bor ?LEN_TAG), encode_varint(Len), Encoded];
encode_field(_FiledNum, _V, _Type) ->
    [].

encode_sfixed32(Int) ->
    <<Int:32/little-signed-integer>>.

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
