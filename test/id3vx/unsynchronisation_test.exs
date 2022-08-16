defmodule Id3vx.UnsynchronisationTest do
  use ExUnit.Case

  alias Id3vx.Tag
  alias Id3vx.Frame
  alias Id3vx.FrameFlags
  alias Id3vx.TagFlags
  alias Id3vx.Utils

  describe "unsynchronisation utility" do
    test "is needed" do
      binary = <<0xFF, 0xFF>>
      assert {<<0xFF, 0x00, 0xFF>> = unsynched, true, _} = Utils.unsynchronise_if_needed(binary)
      assert binary == Utils.decode_unsynchronized(unsynched)
    end

    test "is corner-case" do
      binary = <<0x00, 0xFF>>
      assert {<<0x00, 0xFF, 0x00>> = unsynched, true, _} = Utils.unsynchronise_if_needed(binary)
      assert binary == Utils.decode_unsynchronized(unsynched)
    end

    test "multiple" do
      binary = <<0xFF, 0xFE, 0x00, 0x00, 0xAA, 0xFF, 0xFF>>

      assert {<<0xFF, 0x00, 0xFE, 0x00, 0x00, 0xAA, 0xFF, 0x00, 0xFF>> = unsynched, true, _} =
               Utils.unsynchronise_if_needed(binary)

      assert binary == Utils.decode_unsynchronized(unsynched)
    end
  end

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
            image_data: <<0xFF::8, 0xFF::88>>
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
            image_data: <<0xFE::8, 0xFE::8>>
          }
        }
      ]
    }

    binary = Id3vx.encode_tag(tag)
    t = Id3vx.parse_binary!(binary)
    refute t.flags.unsynchronisation
  end
end
