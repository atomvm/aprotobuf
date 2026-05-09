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

-module(aprotobuf_decoder_test).

-include_lib("eunit/include/eunit.hrl").

transform_schema_test() ->
    Schema = #{
        a => {1, int32},
        b =>
            {2, #{
                c => {1, fixed32},
                d =>
                    {2,
                        {enum, #{
                            "FIRST" => 1,
                            "SECOND" => 2,
                            "THIRD" => 3
                        }}}
            }},
        c => {3, string}
    },
    ExpectedSchema = #{
        1 => {a, int32},
        2 =>
            {b, #{
                1 => {c, fixed32},
                2 =>
                    {d,
                        {enum, #{
                            1 => "FIRST",
                            2 => "SECOND",
                            3 => "THIRD"
                        }}}
            }},
        3 => {c, string}
    },
    ?assertEqual(ExpectedSchema, aprotobuf_decoder:transform_schema(Schema)).

decode_varint_test() ->
    Schema = #{
        a => {1, int32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 150}, aprotobuf_decoder:parse(<<16#08, 16#96, 16#01>>, DecoderSchema)).

decode_string_test() ->
    Schema = #{
        b => {2, string}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{b => <<"testing">>},
        aprotobuf_decoder:parse(
            <<16#12, 16#07, 16#74, 16#65, 16#73, 16#74, 16#69, 16#6E, 16#67>>, DecoderSchema
        )
    ).

decode_submsg_test() ->
    Schema = #{
        c => {3, #{a => {1, int32}}}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{c => #{a => 150}},
        aprotobuf_decoder:parse(<<16#1A, 16#03, 16#08, 16#96, 16#01>>, DecoderSchema)
    ).

decode_int32_string_int32_message_test() ->
    Encoded =
        <<16#10, 16#05, 16#1A, 16#0B, 16#48, 16#65, 16#6C, 16#6C, 16#6F, 16#20, 16#57, 16#6F, 16#72,
            16#6C, 16#64, 16#20, 16#C5, 16#0F>>,
    Schema = #{
        b => {2, int32},
        c => {3, string},
        d => {4, int32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{b => 5, c => <<"Hello World">>, d => 1989},
        aprotobuf_decoder:parse(Encoded, DecoderSchema)
    ).

decode_int32_max_test() ->
    Schema = #{
        a => {1, int32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 2147483647},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#07>>, DecoderSchema
        )
    ).

decode_int32_minus_one_test() ->
    Schema = #{
        a => {1, int32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_int32_minus_42_test() ->
    Schema = #{
        a => {1, int32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -42},
        aprotobuf_decoder:parse(
            <<16#08, 16#D6, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_int32_min_test() ->
    Schema = #{
        a => {1, int32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -2147483648},
        aprotobuf_decoder:parse(
            <<16#08, 16#80, 16#80, 16#80, 16#80, 16#F8, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_int64_two_to_31_test() ->
    Schema = #{
        a => {1, int64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 2147483648},
        aprotobuf_decoder:parse(
            <<16#08, 16#80, 16#80, 16#80, 16#80, 16#08>>, DecoderSchema
        )
    ).

decode_int64_max_test() ->
    Schema = #{
        a => {1, int64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 9223372036854775807},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#7F>>,
            DecoderSchema
        )
    ).

decode_int64_minus_one_test() ->
    Schema = #{
        a => {1, int64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_int64_minus_42_test() ->
    Schema = #{
        a => {1, int64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -42},
        aprotobuf_decoder:parse(
            <<16#08, 16#D6, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_int64_min_test() ->
    Schema = #{
        a => {1, int64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -9223372036854775808},
        aprotobuf_decoder:parse(
            <<16#08, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#01>>,
            DecoderSchema
        )
    ).

decode_int64_complex_test() ->
    Schema = #{
        a => {1, int64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -16#ABCD1234560CAFE},
        aprotobuf_decoder:parse(
            <<16#08, 16#82, 16#EA, 16#FC, 16#D4, 16#CB, 16#DB, 16#CB, 16#A1, 16#F5, 16#01>>,
            DecoderSchema
        )
    ).

decode_uint32_small_test() ->
    Schema = #{
        a => {1, uint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 42}, aprotobuf_decoder:parse(<<16#08, 16#2A>>, DecoderSchema)).

decode_uint32_two_to_31_test() ->
    Schema = #{
        a => {1, uint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 2147483648},
        aprotobuf_decoder:parse(
            <<16#08, 16#80, 16#80, 16#80, 16#80, 16#08>>, DecoderSchema
        )
    ).

decode_uint32_max_test() ->
    Schema = #{
        a => {1, uint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 4294967295},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#0F>>, DecoderSchema
        )
    ).

decode_uint64_small_test() ->
    Schema = #{
        a => {1, uint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 42}, aprotobuf_decoder:parse(<<16#08, 16#2A>>, DecoderSchema)).

decode_uint64_two_to_32_test() ->
    Schema = #{
        a => {1, uint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 4294967296},
        aprotobuf_decoder:parse(
            <<16#08, 16#80, 16#80, 16#80, 16#80, 16#10>>, DecoderSchema
        )
    ).

decode_uint64_max_test() ->
    Schema = #{
        a => {1, uint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 18446744073709551615},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_uint64_complex_test() ->
    Schema = #{
        a => {1, uint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 16#ABCD1234560CAFE},
        aprotobuf_decoder:parse(
            <<16#08, 16#FE, 16#95, 16#83, 16#AB, 16#B4, 16#A4, 16#B4, 16#DE, 16#0A>>,
            DecoderSchema
        )
    ).

decode_sint32_minus_one_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => -1}, aprotobuf_decoder:parse(<<16#08, 16#01>>, DecoderSchema)).

decode_sint32_minus_42_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => -42}, aprotobuf_decoder:parse(<<16#08, 16#53>>, DecoderSchema)).

decode_sint32_max_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 2147483647},
        aprotobuf_decoder:parse(
            <<16#08, 16#FE, 16#FF, 16#FF, 16#FF, 16#0F>>, DecoderSchema
        )
    ).

decode_sint32_min_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -2147483648},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#0F>>, DecoderSchema
        )
    ).

decode_sint32_complex_pos_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 16#6CAFE123},
        aprotobuf_decoder:parse(
            <<16#08, 16#C6, 16#84, 16#FF, 16#CA, 16#0D>>, DecoderSchema
        )
    ).

decode_sint32_complex_neg_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -16#11CAFE01},
        aprotobuf_decoder:parse(
            <<16#08, 16#81, 16#F8, 16#D7, 16#9C, 16#02>>, DecoderSchema
        )
    ).

decode_sint32_zero_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 0}, aprotobuf_decoder:parse(<<16#08, 16#00>>, DecoderSchema)).

decode_sint32_one_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 1}, aprotobuf_decoder:parse(<<16#08, 16#02>>, DecoderSchema)).

decode_sint32_42_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 42}, aprotobuf_decoder:parse(<<16#08, 16#54>>, DecoderSchema)).

decode_sint32_1000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 1000},
        aprotobuf_decoder:parse(<<16#08, 16#D0, 16#0F>>, DecoderSchema)
    ).

decode_sint32_minus_1000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1000},
        aprotobuf_decoder:parse(<<16#08, 16#CF, 16#0F>>, DecoderSchema)
    ).

decode_sint32_66000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 66000},
        aprotobuf_decoder:parse(<<16#08, 16#A0, 16#87, 16#08>>, DecoderSchema)
    ).

decode_sint32_minus_66000_test() ->
    Schema = #{
        a => {1, sint32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -66000},
        aprotobuf_decoder:parse(<<16#08, 16#9F, 16#87, 16#08>>, DecoderSchema)
    ).

decode_sint64_minus_one_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => -1}, aprotobuf_decoder:parse(<<16#08, 16#01>>, DecoderSchema)).

decode_sint64_minus_42_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => -42}, aprotobuf_decoder:parse(<<16#08, 16#53>>, DecoderSchema)).

decode_sint64_max_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 9223372036854775807},
        aprotobuf_decoder:parse(
            <<16#08, 16#FE, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_sint64_min_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -9223372036854775808},
        aprotobuf_decoder:parse(
            <<16#08, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_sint64_complex_pos_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 16#6543CAFE1234ABCD},
        aprotobuf_decoder:parse(
            <<16#08, 16#9A, 16#AF, 16#A5, 16#A3, 16#C2, 16#BF, 16#E5, 16#C3, 16#CA, 16#01>>,
            DecoderSchema
        )
    ).

decode_sint64_complex_neg_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -16#1234CAFE9876ABCD},
        aprotobuf_decoder:parse(
            <<16#08, 16#99, 16#AF, 16#B5, 16#87, 16#D3, 16#BF, 16#E5, 16#B4, 16#24>>,
            DecoderSchema
        )
    ).

decode_sint64_zero_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 0}, aprotobuf_decoder:parse(<<16#08, 16#00>>, DecoderSchema)).

decode_sint64_one_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 1}, aprotobuf_decoder:parse(<<16#08, 16#02>>, DecoderSchema)).

decode_sint64_42_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => 42}, aprotobuf_decoder:parse(<<16#08, 16#54>>, DecoderSchema)).

decode_sint64_1000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 1000},
        aprotobuf_decoder:parse(<<16#08, 16#D0, 16#0F>>, DecoderSchema)
    ).

decode_sint64_minus_1000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1000},
        aprotobuf_decoder:parse(<<16#08, 16#CF, 16#0F>>, DecoderSchema)
    ).

decode_sint64_66000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 66000},
        aprotobuf_decoder:parse(<<16#08, 16#A0, 16#87, 16#08>>, DecoderSchema)
    ).

decode_sint64_minus_66000_test() ->
    Schema = #{
        a => {1, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -66000},
        aprotobuf_decoder:parse(<<16#08, 16#9F, 16#87, 16#08>>, DecoderSchema)
    ).

decode_fixed32_zero_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 0},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema)
    ).

decode_fixed32_small_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 42},
        aprotobuf_decoder:parse(<<16#0D, 16#2A, 16#00, 16#00, 16#00>>, DecoderSchema)
    ).

decode_fixed32_max_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 4294967295},
        aprotobuf_decoder:parse(<<16#0D, 16#FF, 16#FF, 16#FF, 16#FF>>, DecoderSchema)
    ).

decode_fixed32_complex_test() ->
    Schema = #{
        a => {1, fixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 16#DEADBEEF},
        aprotobuf_decoder:parse(<<16#0D, 16#EF, 16#BE, 16#AD, 16#DE>>, DecoderSchema)
    ).

decode_sfixed32_zero_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 0},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema)
    ).

decode_sfixed32_small_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 42},
        aprotobuf_decoder:parse(<<16#0D, 16#2A, 16#00, 16#00, 16#00>>, DecoderSchema)
    ).

decode_sfixed32_minus_one_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1},
        aprotobuf_decoder:parse(<<16#0D, 16#FF, 16#FF, 16#FF, 16#FF>>, DecoderSchema)
    ).

decode_sfixed32_minus_42_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -42},
        aprotobuf_decoder:parse(<<16#0D, 16#D6, 16#FF, 16#FF, 16#FF>>, DecoderSchema)
    ).

decode_sfixed32_max_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 2147483647},
        aprotobuf_decoder:parse(<<16#0D, 16#FF, 16#FF, 16#FF, 16#7F>>, DecoderSchema)
    ).

decode_sfixed32_min_test() ->
    Schema = #{
        a => {1, sfixed32}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -2147483648},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#00, 16#80>>, DecoderSchema)
    ).

decode_fixed64_zero_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 0},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema
        )
    ).

decode_fixed64_small_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 42},
        aprotobuf_decoder:parse(
            <<16#09, 16#2A, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema
        )
    ).

decode_fixed64_max_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 18446744073709551615},
        aprotobuf_decoder:parse(
            <<16#09, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>, DecoderSchema
        )
    ).

decode_fixed64_complex_test() ->
    Schema = #{
        a => {1, fixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 16#DEADBEEFCAFE1234},
        aprotobuf_decoder:parse(
            <<16#09, 16#34, 16#12, 16#FE, 16#CA, 16#EF, 16#BE, 16#AD, 16#DE>>, DecoderSchema
        )
    ).

decode_sfixed64_zero_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 0},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema
        )
    ).

decode_sfixed64_small_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 42},
        aprotobuf_decoder:parse(
            <<16#09, 16#2A, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema
        )
    ).

decode_sfixed64_minus_one_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1},
        aprotobuf_decoder:parse(
            <<16#09, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>, DecoderSchema
        )
    ).

decode_sfixed64_minus_42_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -42},
        aprotobuf_decoder:parse(
            <<16#09, 16#D6, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF>>, DecoderSchema
        )
    ).

decode_sfixed64_max_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 9223372036854775807},
        aprotobuf_decoder:parse(
            <<16#09, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#7F>>, DecoderSchema
        )
    ).

decode_sfixed64_min_test() ->
    Schema = #{
        a => {1, sfixed64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -9223372036854775808},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#80>>, DecoderSchema
        )
    ).

decode_float_zero_test() ->
    Schema = #{
        a => {1, float}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 0.0},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema)
    ).

decode_float_positive_test() ->
    Schema = #{
        a => {1, float}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 1.5},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#C0, 16#3F>>, DecoderSchema)
    ).

decode_float_negative_test() ->
    Schema = #{
        a => {1, float}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1.5},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#C0, 16#BF>>, DecoderSchema)
    ).

decode_float_positive_infinity_test() ->
    Schema = #{
        a => {1, float}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => infinity},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#80, 16#7F>>, DecoderSchema)
    ).

decode_float_negative_infinity_test() ->
    Schema = #{
        a => {1, float}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => '-infinity'},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#80, 16#FF>>, DecoderSchema)
    ).

decode_float_nan_test() ->
    Schema = #{
        a => {1, float}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => nan},
        aprotobuf_decoder:parse(<<16#0D, 16#00, 16#00, 16#C0, 16#7F>>, DecoderSchema)
    ).

decode_double_zero_test() ->
    Schema = #{
        a => {1, double}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 0.0},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>, DecoderSchema
        )
    ).

decode_double_positive_test() ->
    Schema = #{
        a => {1, double}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 1.5},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F8, 16#3F>>, DecoderSchema
        )
    ).

decode_double_negative_test() ->
    Schema = #{
        a => {1, double}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => -1.5},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F8, 16#BF>>, DecoderSchema
        )
    ).

decode_double_positive_infinity_test() ->
    Schema = #{
        a => {1, double}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => infinity},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0, 16#7F>>, DecoderSchema
        )
    ).

decode_double_negative_infinity_test() ->
    Schema = #{
        a => {1, double}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => '-infinity'},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0, 16#FF>>, DecoderSchema
        )
    ).

decode_double_nan_test() ->
    Schema = #{
        a => {1, double}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => nan},
        aprotobuf_decoder:parse(
            <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F8, 16#7F>>, DecoderSchema
        )
    ).

decode_bool_false_test() ->
    Schema = #{
        a => {1, bool}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => false}, aprotobuf_decoder:parse(<<16#08, 16#00>>, DecoderSchema)).

decode_bool_true_test() ->
    Schema = #{
        a => {1, bool}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => true}, aprotobuf_decoder:parse(<<16#08, 16#01>>, DecoderSchema)).

%% Per the protobuf wire spec, any non-zero VARINT decodes to `true`.
decode_bool_nonzero_test() ->
    Schema = #{
        a => {1, bool}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(#{a => true}, aprotobuf_decoder:parse(<<16#08, 16#2A>>, DecoderSchema)).

decode_repeated_int64_packed_test() ->
    Schema = #{
        r => {1, {repeated, int64}}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#0A, 16#40, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01, 16#01,
            16#2A, 16#B4, 16#A4, 16#F8, 16#D7, 16#0C, 16#F6, 16#B0, 16#FA, 16#D7, 16#DC, 16#F9,
            16#AA, 16#9A, 16#12, 16#00, 16#FE, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF,
            16#FF, 16#01, 16#35, 16#00, 16#00, 16#00, 16#01, 16#01, 16#01, 16#FF, 16#FF, 16#FF,
            16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01, 16#FE, 16#FF, 16#FF, 16#FF, 16#FF,
            16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
    ?assertEqual(
        #{
            r =>
                [-1, 1, 42, 3405648436, 1311862291833985142, 0, -2, 53, 0, 0, 0, 1, 1, 1, -1, -2]
        },
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_repeated_bool_packed_test() ->
    Schema = #{
        r => {1, {repeated, bool}}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [true, false, true, false, true, false, true, true, false, false]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#0A, 16#01, 16#00, 16#01, 16#00, 16#01, 16#00, 16#01, 16#01, 16#00, 16#00>>,
            DecoderSchema
        )
    ).

decode_repeated_fixed32_packed_test() ->
    Schema = #{
        r => {1, {repeated, fixed32}}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#0A, 16#1C, 16#00, 16#00, 16#00, 16#00, 16#01, 16#00, 16#00, 16#00, 16#02, 16#00, 16#00,
            16#00, 16#03, 16#00, 16#00, 16#00, 16#04, 16#00, 16#00, 16#00, 16#05, 16#00, 16#00,
            16#00, 16#06, 16#00, 16#00, 16#00>>,
    ?assertEqual(
        #{r => [0, 1, 2, 3, 4, 5, 6]},
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_repeated_int32_packed_test() ->
    Schema = #{
        r => {1, {repeated, int32}}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [1]},
        aprotobuf_decoder:parse(<<16#0A, 16#01, 16#01>>, DecoderSchema)
    ).

decode_mixed_with_empty_repeated_test() ->
    Schema = #{
        a => {1, int32},
        r => {2, {repeated, int32}},
        b => {3, string}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{a => 1, b => <<"hello">>},
        aprotobuf_decoder:parse(
            <<16#08, 16#01, 16#1A, 16#05, "hello">>, DecoderSchema
        )
    ).

decode_repeated_uint32_packed_test() ->
    Schema = #{r => {1, {repeated, uint32}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [0, 2147483648, 4294967295]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#0B, 16#00, 16#80, 16#80, 16#80, 16#80, 16#08, 16#FF, 16#FF, 16#FF, 16#FF,
                16#0F>>,
            DecoderSchema
        )
    ).

decode_repeated_uint64_packed_test() ->
    Schema = #{r => {1, {repeated, uint64}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [0, 9223372036854775808, 18446744073709551615]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#15, 16#00, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80, 16#80,
                16#01, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#01>>,
            DecoderSchema
        )
    ).

decode_repeated_sint32_packed_test() ->
    Schema = #{r => {1, {repeated, sint32}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [-1, 0, 1, -2147483648, 2147483647]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#0D, 16#01, 16#00, 16#02, 16#FF, 16#FF, 16#FF, 16#FF, 16#0F, 16#FE, 16#FF,
                16#FF, 16#FF, 16#0F>>,
            DecoderSchema
        )
    ).

decode_repeated_sfixed32_packed_test() ->
    Schema = #{r => {1, {repeated, sfixed32}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [-1, 0, -2147483648, 2147483647]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#10, 16#FF, 16#FF, 16#FF, 16#FF, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00,
                16#00, 16#80, 16#FF, 16#FF, 16#FF, 16#7F>>,
            DecoderSchema
        )
    ).

decode_repeated_fixed64_packed_test() ->
    Schema = #{r => {1, {repeated, fixed64}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [0, 1, 18446744073709551615]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#18, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#01, 16#00,
                16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF,
                16#FF, 16#FF>>,
            DecoderSchema
        )
    ).

decode_repeated_sfixed64_packed_test() ->
    Schema = #{r => {1, {repeated, sfixed64}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [-1, 0, -9223372036854775808, 9223372036854775807]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#20, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#00, 16#00,
                16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00,
                16#00, 16#80, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#7F>>,
            DecoderSchema
        )
    ).

decode_repeated_double_with_string_test() ->
    Schema = #{
        r => {1, {repeated, double}},
        b => {2, string}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#0A, 16#30, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00,
            16#00, 16#00, 16#00, 16#F0, 16#BF, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0,
            16#3F, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#45, 16#C0, 16#00, 16#00, 16#00,
            16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#14,
            16#40, 16#12, 16#04, "test">>,
    ?assertEqual(
        #{r => [0.0, -1.0, 1.0, -42.0, 0.0, 5.0], b => <<"test">>},
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_repeated_float_with_string_test() ->
    Schema = #{
        r => {1, {repeated, float}},
        b => {2, string}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#0A, 16#18, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#80, 16#BF, 16#00, 16#00, 16#80,
            16#3F, 16#00, 16#00, 16#28, 16#C2, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#A0,
            16#40, 16#12, 16#04, "test">>,
    ?assertEqual(
        #{r => [0.0, -1.0, 1.0, -42.0, 0.0, 5.0], b => <<"test">>},
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_repeated_sint64_with_sint64_test() ->
    Schema = #{
        r => {1, {repeated, sint64}},
        b => {2, sint64}
    },
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [-1, -5, -7, 0, 0, 0, 1, 42, -1], b => -1},
        aprotobuf_decoder:parse(
            <<16#0A, 16#09, 16#01, 16#09, 16#0D, 16#00, 16#00, 16#00, 16#02, 16#54, 16#01, 16#10,
                16#01>>,
            DecoderSchema
        )
    ).

decode_repeated_float_non_finite_test() ->
    Schema = #{r => {1, {repeated, float}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [infinity, '-infinity', nan]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#0C, 16#00, 16#00, 16#80, 16#7F, 16#00, 16#00, 16#80, 16#FF, 16#00, 16#00,
                16#C0, 16#7F>>,
            DecoderSchema
        )
    ).

decode_repeated_double_non_finite_test() ->
    Schema = #{r => {1, {repeated, double}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [infinity, '-infinity', nan]},
        aprotobuf_decoder:parse(
            <<16#0A, 16#18, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0, 16#7F, 16#00, 16#00,
                16#00, 16#00, 16#00, 16#00, 16#F0, 16#FF, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00,
                16#F8, 16#7F>>,
            DecoderSchema
        )
    ).

decode_repeated_sint64_unpacked_test() ->
    Schema = #{r => {1, {repeated, sint64}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    ?assertEqual(
        #{r => [11, -5, -7, 0, 0, 0, 1, 42, -1]},
        aprotobuf_decoder:parse(
            <<16#08, 16#16, 16#08, 16#09, 16#08, 16#0D, 16#08, 16#00, 16#08, 16#00, 16#08, 16#00,
                16#08, 16#02, 16#08, 16#54, 16#08, 16#01>>,
            DecoderSchema
        )
    ).

decode_repeated_double_unpacked_test() ->
    Schema = #{r => {1, {repeated, double}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#F0, 16#BF, 16#09, 16#00, 16#00, 16#00,
            16#00, 16#00, 16#00, 16#F0, 16#3F, 16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00,
            16#45, 16#40, 16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#09,
            16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#09, 16#00, 16#00, 16#00,
            16#00, 16#00, 16#00, 16#F0, 16#BF>>,
    ?assertEqual(
        #{r => [-1.0, 1.0, 42.0, 0.0, 0.0, -1.0]},
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_repeated_sfixed64_unpacked_test() ->
    Schema = #{r => {1, {repeated, sfixed64}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#09, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#09, 16#01, 16#00, 16#00,
            16#00, 16#00, 16#00, 16#00, 16#00, 16#09, 16#A0, 16#86, 16#01, 16#00, 16#00, 16#00,
            16#00, 16#00, 16#09, 16#CE, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#FF, 16#09,
            16#2A, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00, 16#00>>,
    ?assertEqual(
        #{r => [0, 1, 100000, -50, 42]},
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_repeated_string_test() ->
    Schema = #{r => {1, {repeated, string}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#0A, 16#05, "Hello", 16#0A, 16#05, "World", 16#0A, 16#04, "this", 16#0A, 16#02, "is",
            16#0A, 16#01, "a", 16#0A, 16#04, "test", 16#0A, 16#01, ".">>,
    ?assertEqual(
        #{r => [<<"Hello">>, <<"World">>, <<"this">>, <<"is">>, <<"a">>, <<"test">>, <<".">>]},
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).

decode_map_string_int32_test() ->
    Schema = #{count => {1, {map, string, int32}}},
    DecoderSchema = aprotobuf_decoder:transform_schema(Schema),
    Wire =
        <<16#0A, 16#09, 16#0A, 16#05, "Hello", 16#10, 16#05, 16#0A, 16#08, 16#0A, 16#04, "test",
            16#10, 16#04, 16#0A, 16#09, 16#0A, 16#05, "hello", 16#10, 16#05, 16#0A, 16#08, 16#0A,
            16#04, "ciao", 16#10, 16#04, 16#0A, 16#04, 16#0A, 16#00, 16#10, 16#00>>,
    ?assertEqual(
        #{
            count => #{
                <<"Hello">> => 5,
                <<"test">> => 4,
                <<"hello">> => 5,
                <<"ciao">> => 4,
                <<>> => 0
            }
        },
        aprotobuf_decoder:parse(Wire, DecoderSchema)
    ).
