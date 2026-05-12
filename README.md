<!---
  Copyright 2023 Davide Bettio <davide@uninstall.it>

  SPDX-License-Identifier: Apache-2.0
-->

# aprotobuf

Erlang Protobuf library optimized for [AtomVM](https://atomvm.org/) (an Erlang
VM for embedded devices). Also runs unchanged on stock Erlang/OTP, so the
same code can be developed and tested on a workstation and deployed on
microcontrollers.

Pure Erlang, no NIFs, no code generation (schemas are plain Erlang maps
consumed at runtime), and no dependencies beyond `kernel` and `stdlib`.
Implements the subset of the Protobuf wire format needed by typical embedded
consumers: all proto3 scalar types, sub-messages, `repeated` (packed and
unpacked), `map<K, V>`, `enum`, `oneof`, and message references for
recursive or mutually-recursive schemas.

## Modules

- **`aprotobuf_encoder`**: encodes an Erlang map into Protobuf wire bytes
  against a user-written schema (`encode/2`, `encode/3`).
- **`aprotobuf_decoder`**: parses Protobuf wire bytes into an Erlang map
  (`parse/2`, `parse/3`). The user-written schema is first run through
  `transform_schema/1` (or `transform_schemas/1` for a registry).

## Adding to your project

### rebar3

```erlang
{deps, [
    {aprotobuf,
        {git, "https://github.com/atomvm/aprotobuf.git",
            {branch, "main"}}}
]}.
```

### Elixir (`mix.exs`)

```elixir
defp deps do
  [
    {:aprotobuf,
     git: "https://github.com/atomvm/aprotobuf.git",
     branch: "main"}
  ]
end
```

## Quick usage

### Defining a schema

Given this `.proto`:

```protobuf
message Person {
  enum Role {
    USER  = 0;
    ADMIN = 1;
  }
  message Address {
    string street  = 1;
    string city    = 2;
    string country = 3;
  }
  int32           id    = 1;
  string          name  = 2;
  Role            role  = 3;
  repeated string email = 4;
  Address         home  = 5;
}
```

the equivalent aprotobuf schema is an Erlang map from field-name atom to
`{FieldNumber, Type}`:

```erlang
PersonSchema = #{
    id    => {1, int32},
    name  => {2, string},
    role  => {3, {enum, #{'USER' => 0, 'ADMIN' => 1}}},
    email => {4, {repeated, string}},
    home  => {5, #{
        street  => {1, string},
        city    => {2, string},
        country => {3, string}
    }}
}.
```

Supported scalar types: `int32`, `int64`, `uint32`, `uint64`, `sint32`,
`sint64`, `bool`, `bytes`, `string`, `float`, `double`, `fixed32`, `fixed64`,
`sfixed32`, `sfixed64`. Composite types: `{enum, #{Label => Int}}`,
`{repeated, ElemType}`, `{map, KeyType, ValueType}`, `{oneof, #{Variant =>
{FieldNum, Type}}}`, nested map schemas for inline sub-messages, and
`{ref, Name}` for references resolved through a registry.

### Encoding

The encoder returns an iolist; flatten it with `iolist_to_binary/1` when you
need a binary.

Erlang:

```erlang
Person = #{
    id    => 42,
    name  => <<"Ada">>,
    role  => 'ADMIN',
    email => [<<"ada@example.com">>],
    home  => #{street => <<"1 Lovelace Ln">>, city => <<"London">>,
               country => <<"UK">>}
},
Wire = iolist_to_binary(aprotobuf_encoder:encode(Person, PersonSchema)).
```

Elixir:

```elixir
person = %{
  id: 42,
  name: "Ada",
  role: :ADMIN,
  email: ["ada@example.com"],
  home: %{street: "1 Lovelace Ln", city: "London", country: "UK"}
}

wire =
  :aprotobuf_encoder.encode(person, person_schema)
  |> :erlang.iolist_to_binary()
```

### Decoding

The decoder consumes the **transformed** schema produced by
`aprotobuf_decoder:transform_schema/1` (field-number-keyed). Transform once
and reuse.

Erlang:

```erlang
DecSchema = aprotobuf_decoder:transform_schema(PersonSchema),
Person    = aprotobuf_decoder:parse(Wire, DecSchema).
```

Elixir:

```elixir
dec_schema = :aprotobuf_decoder.transform_schema(person_schema)
person     = :aprotobuf_decoder.parse(wire, dec_schema)
```

### Multi-message schemas (registry)

For recursive, mutually-recursive, or cross-message schemas, build a registry
keyed by message name and use the arity-3 variants (`encode/3`, `parse/3`,
`transform_schemas/1`):

```erlang
Registry = #{
    'Node' => #{
        value    => {1, int32},
        children => {2, {repeated, {ref, 'Node'}}}
    }
},
DecRegistry = aprotobuf_decoder:transform_schemas(Registry),

Tree = #{value => 1, children => [
    #{value => 2, children => []},
    #{value => 3, children => [#{value => 4, children => []}]}
]},
Wire = iolist_to_binary(aprotobuf_encoder:encode(Tree, 'Node', Registry)),
Tree = aprotobuf_decoder:parse(Wire, 'Node', DecRegistry).
```

The arity-2 functions are convenience wrappers that build a single-entry
registry under the sentinel name `root`.

## Erlang representation

| Protobuf form         | Erlang representation                                                    |
|-----------------------|--------------------------------------------------------------------------|
| message               | map keyed by field-name atoms                                            |
| `string` / `bytes`    | binary                                                                   |
| integer types         | integer                                                                  |
| `float` / `double`    | float; `infinity`, `'-infinity'`, and `nan` for non-finite values        |
| `bool`                | atom `true` / `false`                                                    |
| `enum`                | label (atom or string, matching how it appears in the schema)            |
| `repeated T`          | list of `T`                                                              |
| `map<K, V>`           | Erlang map                                                               |
| `oneof` (set)         | `{Variant, Value}` 2-tuple stored under the oneof field name             |
| `oneof` (unset)       | key absent from the message map                                          |
| absent optional field | key absent from the message map (no default materialization)             |

The encoder packs primitive `repeated` fields by default; the decoder
transparently accepts both packed and unpacked wire forms.

## Build, test, format

```sh
rebar3 compile
rebar3 eunit
rebar3 fmt          # format with erlfmt
rebar3 fmt --check  # format check (CI gate)
```

CI runs `rebar3 fmt --check && rebar3 compile && rebar3 eunit` on OTP 28.0;
a separate workflow runs the REUSE compliance check.

See [`test/`](test/) for runnable examples covering every supported type and
schema form.

## License

aprotobuf is released under the [Apache License 2.0](LICENSE). The repository
is REUSE-compliant: every source, test, and CI file carries an SPDX header,
with full license texts in [`LICENSES/`](LICENSES/).
