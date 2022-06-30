# Id3vx

A library for reading and writing ID3 tags.

It currently supports only ID3v2.3. It specifically also supports Chapters and Table of Contents as it was created to support podcast chapters as a specific usage.

This library development was funded and open-sourced by [Changelog Media](https://changelog.com).

## Installation

Until a Hex package is published this can be used with:

```elixir
def deps do
  [
    {:id3vx, github: "lawik/id3vx"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/id3vx>.

