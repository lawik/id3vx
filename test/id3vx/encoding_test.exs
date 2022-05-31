defmodule Id3vx.EncodingTest do
  use ExUnit.Case

  alias Id3vx.Tag
  alias Id3vx.TagFlags
  alias Id3vx.Frame
  alias Id3vx.FrameFlags
  alias Id3vx.ExtendedHeaderV3
  alias Id3vx.ExtendedHeaderFlags

  test "tag v2.3 with a TIT2 frame" do
    tag = %Tag{
      version: 3,
      revision: 0,
      flags: %TagFlags{
        unsynchronisation: false,
        extended_header: false,
        experimental: false
      },
      # size will be calculated, not provided
      frames: [
        %Frame{
          id: "TIT2",
          flags: %FrameFlags{},
          data: %{
            encoding: :utf16,
            text: "My Title"
          }
        }
      ]
    }

    encoded_string = :unicode.characters_to_binary("My Title", :utf8, {:utf16, :big})

    encoded_text = :unicode.encoding_to_bom({:utf16, :big}) <> encoded_string <> <<0x00, 0x00>>
    binary = Id3vx.encode_tag(tag)

    assert <<tag_header::binary-size(10), tag_rest::binary>> = binary
    assert <<"ID3", 3::integer, 0::integer, 0::size(8), tag_size::binary-size(4)>> = tag_header
    tag_size = Id3vx.decode_synchsafe_integer(tag_size)
    assert 31 == tag_size

    assert <<"TIT2", frame_size::size(32), flags::binary-size(2), frames_data::binary>> = tag_rest

    assert 20 == frame_size

    assert <<0x01::size(8), frame_text::binary>> = frames_data
    assert encoded_text == frame_text
  end

  test "encoding synchsafe numbers" do
    max = 256 * 1024 * 1024

    for num1 <- 1..256 do
      num2 =
        num1
        |> Id3vx.encode_synchsafe_integer()
        |> Id3vx.decode_synchsafe_integer()

      assert num1 == num2
    end

    for num1 <- 1..256 do
      num1 = num1 * 1024 * 1024 - 1

      num2 =
        num1
        |> Id3vx.encode_synchsafe_integer()
        |> Id3vx.decode_synchsafe_integer()

      assert num1 == num2
    end

    assert_raise(RuntimeError, fn ->
      Id3vx.encode_synchsafe_integer(max)
    end)
  end
end
