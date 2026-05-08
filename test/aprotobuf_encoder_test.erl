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

encode_uint32_small_test() ->
    Schema = #{
        a => {1, uint32}
    },
    ?assertEqual(
        <<16#08, 16#2A>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_uint32_two_to_31_test() ->
    Schema = #{
        a => {1, uint32}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#80, 16#08>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 2147483648}, Schema))
    ).

encode_uint32_max_test() ->
    Schema = #{
        a => {1, uint32}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 4294967295}, Schema))
    ).

encode_uint32_overflow_test() ->
    Schema = #{
        a => {1, uint32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 4294967296}, Schema)).

encode_uint32_underflow_test() ->
    Schema = #{
        a => {1, uint32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -1}, Schema)).

encode_uint64_small_test() ->
    Schema = #{
        a => {1, uint64}
    },
    ?assertEqual(
        <<16#08, 16#2A>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_uint64_two_to_32_test() ->
    Schema = #{
        a => {1, uint64}
    },
    ?assertEqual(
        <<16#08, 16#80, 16#80, 16#80, 16#80, 16#10>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 4294967296}, Schema))
    ).

encode_uint64_max_test() ->
    Schema = #{
        a => {1, uint64}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 18446744073709551615}, Schema))
    ).

encode_uint64_overflow_test() ->
    Schema = #{
        a => {1, uint64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 18446744073709551616}, Schema)).

encode_uint64_underflow_test() ->
    Schema = #{
        a => {1, uint64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -1}, Schema)).

encode_uint64_complex_test() ->
    Schema = #{
        a => {1, uint64}
    },
    ?assertEqual(
        <<16#08, 16#FE, 16#95, 16#83, 16#AB, 16#B4, 16#A4, 16#B4, 16#DE, 16#0A>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 16#ABCD1234560CAFE}, Schema))
    ).

encode_sint32_small_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#54>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_sint32_minus_one_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1}, Schema))
    ).

encode_sint32_minus_42_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#53>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -42}, Schema))
    ).

encode_sint32_max_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#FE, 16#FF, 16#FF, 16#FF, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 2147483647}, Schema))
    ).

encode_sint32_min_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -2147483648}, Schema))
    ).

encode_sint32_overflow_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 2147483648}, Schema)).

encode_sint32_underflow_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -2147483649}, Schema)).

encode_sint32_complex_pos_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#C6, 16#84, 16#FF, 16#CA, 16#0D>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 16#6CAFE123}, Schema))
    ).

encode_sint32_complex_neg_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#81, 16#F8, 16#D7, 16#9C, 16#02>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -16#11CAFE01}, Schema))
    ).

encode_sint32_zero_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0}, Schema))
    ).

encode_sint32_one_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#02>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 1}, Schema))
    ).

encode_sint32_1000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#D0, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 1000}, Schema))
    ).

encode_sint32_minus_1000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#CF, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1000}, Schema))
    ).

encode_sint32_66000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#A0, 16#87, 16#08>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 66000}, Schema))
    ).

encode_sint32_minus_66000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    ?assertEqual(
        <<16#08, 16#9F, 16#87, 16#08>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -66000}, Schema))
    ).

encode_sint64_small_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#54>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_sint64_minus_one_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1}, Schema))
    ).

encode_sint64_minus_42_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#53>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -42}, Schema))
    ).

encode_sint64_max_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#FE, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 9223372036854775807}, Schema))
    ).

encode_sint64_min_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -9223372036854775808}, Schema))
    ).

encode_sint64_overflow_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 9223372036854775808}, Schema)).

encode_sint64_underflow_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -9223372036854775809}, Schema)).

encode_sint64_complex_pos_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#9A, 16#AF, 16#A5, 16#A3, 16#C2, 16#BF, 16#E5, 16#C3, 16#CA, 16#01>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 16#6543CAFE1234ABCD}, Schema))
    ).

encode_sint64_complex_neg_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#99, 16#AF, 16#B5, 16#87, 16#D3, 16#BF, 16#E5, 16#B4, 16#24>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -16#1234CAFE9876ABCD}, Schema))
    ).

encode_sint64_zero_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0}, Schema))
    ).

encode_sint64_one_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#02>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 1}, Schema))
    ).

encode_sint64_1000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#D0, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 1000}, Schema))
    ).

encode_sint64_minus_1000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#CF, 16#0F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1000}, Schema))
    ).

encode_sint64_66000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#A0, 16#87, 16#08>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 66000}, Schema))
    ).

encode_sint64_minus_66000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    ?assertEqual(
        <<16#08, 16#9F, 16#87, 16#08>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -66000}, Schema))
    ).

encode_fixed32_zero_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0}, Schema))
    ).

encode_fixed32_small_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    ?assertEqual(
        <<16#0D, 16#2A, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_fixed32_max_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    ?assertEqual(
        <<16#0D, 16#FF, 16#FF, 16#FF, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 4294967295}, Schema))
    ).

encode_fixed32_complex_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    ?assertEqual(
        <<16#0D, 16#EF, 16#BE, 16#AD, 16#DE>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 16#DEADBEEF}, Schema))
    ).

encode_fixed32_overflow_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 4294967296}, Schema)).

encode_fixed32_underflow_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -1}, Schema)).

encode_sfixed32_zero_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0}, Schema))
    ).

encode_sfixed32_small_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    ?assertEqual(
        <<16#0D, 16#2A, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_sfixed32_minus_one_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    ?assertEqual(
        <<16#0D, 16#FF, 16#FF, 16#FF, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1}, Schema))
    ).

encode_sfixed32_minus_42_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    ?assertEqual(
        <<16#0D, 16#D6, 16#FF, 16#FF, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -42}, Schema))
    ).

encode_sfixed32_max_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    ?assertEqual(
        <<16#0D, 16#FF, 16#FF, 16#FF, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 2147483647}, Schema))
    ).

encode_sfixed32_min_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#00, 16#80>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -2147483648}, Schema))
    ).

encode_fixed64_zero_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0}, Schema))
    ).

encode_fixed64_small_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    ?assertEqual(
        <<16#09, 16#2A, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_fixed64_max_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    ?assertEqual(
        <<16#09, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 18446744073709551615}, Schema))
    ).

encode_fixed64_complex_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    ?assertEqual(
        <<16#09, 16#34, 16#12, 16#FE, 16#CA, 16#EF, 16#BE, 16#AD, 16#DE>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 16#DEADBEEFCAFE1234}, Schema))
    ).

encode_fixed64_overflow_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 18446744073709551616}, Schema)).

encode_fixed64_underflow_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -1}, Schema)).

encode_sfixed64_zero_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0}, Schema))
    ).

encode_sfixed64_small_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    ?assertEqual(
        <<16#09, 16#2A, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_sfixed64_minus_one_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    ?assertEqual(
        <<16#09, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1}, Schema))
    ).

encode_sfixed64_minus_42_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    ?assertEqual(
        <<16#09, 16#D6, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -42}, Schema))
    ).

encode_sfixed64_max_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    ?assertEqual(
        <<16#09, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 9223372036854775807}, Schema))
    ).

encode_sfixed64_min_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#80>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -9223372036854775808}, Schema))
    ).

encode_float_zero_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0.0}, Schema))
    ).

encode_float_positive_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#C0, 16#3F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 1.5}, Schema))
    ).

encode_float_negative_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#C0, 16#BF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1.5}, Schema))
    ).

encode_float_positive_infinity_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#80, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => infinity}, Schema))
    ).

encode_float_negative_infinity_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#80, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => '-infinity'}, Schema))
    ).

encode_float_nan_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#C0, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => nan}, Schema))
    ).

%% Integer values are auto-converted to float; 42 must produce the same wire
%% bytes as 42.0.
encode_float_integer_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertEqual(
        <<16#0D, 16#00, 16#00, 16#28, 16#42>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).

encode_float_overflow_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 1.0e40}, Schema)).

encode_float_underflow_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => -1.0e40}, Schema)).

encode_float_huge_integer_test() ->
    Schema = #{
        a => {1, float}
    },
    ?assertError(badarg, aprotobuf_encoder:encode(#{a => 1 bsl 200}, Schema)).

encode_double_zero_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 0.0}, Schema))
    ).

encode_double_positive_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F8, 16#3F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 1.5}, Schema))
    ).

encode_double_negative_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F8, 16#BF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => -1.5}, Schema))
    ).

encode_double_positive_infinity_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => infinity}, Schema))
    ).

encode_double_negative_infinity_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0, 16#FF>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => '-infinity'}, Schema))
    ).

encode_double_nan_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F8, 16#7F>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => nan}, Schema))
    ).

%% Integer 42 must auto-convert to 42.0 and produce identical wire bytes.
encode_double_integer_test() ->
    Schema = #{
        a => {1, double}
    },
    ?assertEqual(
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#45, 16#40>>,
        iolist_to_binary(aprotobuf_encoder:encode(#{a => 42}, Schema))
    ).
