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

-module(aprotobuf_encoder_test).

-include_lib("eunit/include/eunit.hrl").

encode_int32_small_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#2A>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_int32_two_to_21_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 2097152}, Schema))
    ).

encode_int32_two_to_28_minus_one_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 268435455}, Schema))
    ).

encode_int32_two_to_28_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#80, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 268435456}, Schema))
    ).

encode_int32_minus_one_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1}, Schema))
    ).

encode_int32_minus_42_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#D6, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -42}, Schema))
    ).

encode_int32_min_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#80, 16#F8, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -2147483648}, Schema))
    ).

encode_int32_overflow_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 2147483648}, Schema)).

encode_int32_underflow_test() ->
    Schema = #{
        a => {1, int32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -2147483649}, Schema)).

encode_int64_small_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#2A>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_int64_two_to_31_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#80, 16#08>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 2147483648}, Schema))
    ).

encode_int64_max_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 9223372036854775807}, Schema))
    ).

encode_int64_minus_one_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1}, Schema))
    ).

encode_int64_minus_42_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#D6, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -42}, Schema))
    ).

encode_int64_min_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -9223372036854775808}, Schema))
    ).

encode_int64_overflow_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 9223372036854775808}, Schema)).

encode_int64_underflow_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -9223372036854775809}, Schema)).

encode_int64_complex_test() ->
    Schema = #{
        a => {1, int64}
    },
    ?assertEqual(
        <<16#08, 16#82, 16#EA, 16#FC, 16#D4, 16#CB, 16#DB, 16#CB, 16#A1, 16#F5, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -16#ABCD1234560CAFE}, Schema))
    ).
