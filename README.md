# Id3vx

[![hex.pm](https://img.shields.io/hexpm/v/id3vx.svg)](https://hex.pm/packages/id3vx)

A library for reading and writing ID3 tags.

Docs can be found at <https://hexdocs.pm/id3vx>.

It currently supports only ID3v2.3. It specifically also supports Chapters and Table of Contents as it was created to support podcast chapters as a specific usage.

This library development was funded and open-sourced by [Changelog Media](https://changelog.com).

## Installation

Until a Hex package is published this can be used with:

```elixir
def deps do
  [
    {:id3vx, "~> 0.0.1-rc1"}
  ]
end
```

  ## Examples

  ### Parse from file

      {:ok, tag} = Id3vx.parse_file("test/samples/beamradio32.mp3")

  ### Encode new tag

  Creating tags is most easily done with the utilities in `Id3vx.Tag`.

      Id3vx.Tag.create(3)
      |> Id3vx.Tag.add_text_frame("TIT1", "Title!")
      |> Id3vx.encode_tag()

  ### Parse from binary

      tag = Id3vx.Tag.create(3)
            |> Id3vx.Tag.add_text_frame("TIT1", "Title!")
      tag_binary = Id3vx.encode_tag(tag)
      {:ok, tag} = Id3vx.parse_binary(tag_binary)

  ### Add Chapter to an existing ID3 tag

  A Chapter often has a URL and image. You can use `Id3vx.Tag.add_attached_picture` for the picture.

      tag =
        "test/samples/beamradio32.mp3"
        |> Id3vx.parse_file!()
        |> Id3vx.Tag.add_typical_chapter_and_toc(0, 60_000, 0, 12345,
          "A Great Title",
          fn chapter ->
            Id3vx.Tag.add_custom_url(
              chapter,
              "chapter url",
              "https://underjord.io"
            )
          end
        )
