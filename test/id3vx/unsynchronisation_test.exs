defmodule Id3vx.UnsynchronisationTest do
  use ExUnit.Case

  alias Id3vx.Tag
  alias Id3vx.Frame
  alias Id3vx.FrameFlags
  alias Id3vx.TagFlags

  test "v2.3 unsynchronisation required" do
    tag = %Tag{
      version: 3,
      revision: 0,
      flags: %TagFlags{
        unsynchronisation: false
      },
      frames: [
        %Frame{
          id: "APIC",
          flags: %FrameFlags{},
          data: %Frame.AttachedPicture{
            description: "image",
            mime_type: "image/jpg",
            picture_type: :other,
            image_data: <<0xFF::8, 1::3, 0::5>>
          }
        }
      ]
    }

    binary = Id3vx.encode_tag(tag)
    t = Id3vx.parse_binary!(binary)
    assert t.flags.unsynchronisation
  end

  test "v2.3 unsynchronisation not required" do
    tag = %Tag{
      version: 3,
      revision: 0,
      flags: %TagFlags{
        unsynchronisation: false
      },
      frames: [
        %Frame{
          id: "APIC",
          flags: %FrameFlags{},
          data: %Frame.AttachedPicture{
            description: "image",
            mime_type: "image/jpg",
            picture_type: :other,
            image_data: <<0xFE::8, 1::3, 0::5>>
          }
        }
      ]
    }

    binary = Id3vx.encode_tag(tag)
    t = Id3vx.parse_binary!(binary)
    refute t.flags.unsynchronisation
  end
end
