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
