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

    assert <<tag_header::binary-size(10), tag_rest::binary>> = binary
    assert <<"ID3", 3::integer, 0::integer, 0::size(8), tag_size::binary-size(4)>> = tag_header
    tag_size = Id3vx.decode_synchsafe_integer(tag_size)

    assert <<"TIT2", frame_size::size(32), 0::size(8), 1::1, 0::7, 0::8, 0::8, 0::8, 61::8,
             _compressed_data::binary>> = tag_rest

    assert 70 == tag_size
    assert 60 == frame_size

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
           } = tag2
  end
end
