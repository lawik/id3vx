defmodule Id3vx.Frame.FrameFlagsTest do
  use ExUnit.Case

  alias Id3vx.Tag
  alias Id3vx.TagFlags
  alias Id3vx.Frame
  alias Id3vx.FrameFlags

  test "v2.3 use a frame with compression" do
    tag1 = %Tag{
      version: 3,
      revision: 0,
      flags: %TagFlags{
        unsynchronisation: false,
        extended_header: false,
        experimental: false
      },
      frames: [
        %Frame{
          id: "TIT2",
          flags: %FrameFlags{compression: true},
          data: %{
            encoding: :utf16,
            text: "Dolor sit amet, consectitur."
          }
        }
      ]
    }

    binary = Id3vx.encode_tag(tag1)

    encoded_string = :unicode.characters_to_binary("My Title", :utf8, {:utf16, :big})

    encoded_text = :unicode.encoding_to_bom({:utf16, :big}) <> encoded_string <> <<0x00, 0x00>>
    IO.inspect(byte_size(encoded_text), label: "encode_text size")
    z = :zlib.open()
    :zlib.deflateInit(z)
    compressed_text = :zlib.deflate(z, encoded_text) |> IO.iodata_to_binary()
    uncompressed_size = <<byte_size(encoded_text)::32>>

    assert <<tag_header::binary-size(10), tag_rest::binary>> = binary
    assert <<"ID3", 3::integer, 0::integer, 0::size(8), tag_size::binary-size(4)>> = tag_header
    tag_size = Id3vx.decode_synchsafe_integer(tag_size)

    assert <<"TIT2", frame_size::size(32), 0::size(8), 1::1, 0::7, ^uncompressed_size::32,
             ^compressed_text::binary>> = tag_rest

    assert 31 == tag_size
    assert 21 == frame_size

    tag2 = Id3vx.parse_binary!(binary)

    assert %Tag{
      frames: [
        %Frame{
          id: "TIT2",
          flags: %FrameFlags{compression: true},
          data: %{
            encoding: :utf16,
            text: "Dolor sit amet, consectitur."
          }
        }
      ]
    }
  end
end
