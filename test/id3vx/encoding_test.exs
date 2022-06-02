defmodule Id3vx.EncodingTest do
  use ExUnit.Case

  alias Id3vx.Tag
  alias Id3vx.TagFlags
  alias Id3vx.Frame
  alias Id3vx.FrameFlags

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

    assert <<"TIT2", frame_size::size(32), _flags::binary-size(2), frames_data::binary>> =
             tag_rest

    assert 21 == frame_size

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

    try do
      Id3vx.encode_synchsafe_integer(max)
      refute true
    catch
      e ->
        assert %Id3vx.Error{} = e
    end
  end

  test "v2.3 encoding CHAP frame" do
    frame = %Frame{
      id: "CHAP",
      flags: %FrameFlags{},
      data: %{
        element_id: "chp1",
        start_time: 0,
        end_time: 5000,
        start_offset: 0,
        end_offset: 1024,
        frames: [
          %Frame{
            id: "TIT2",
            flags: %FrameFlags{},
            data: %{
              encoding: :utf16,
              text: "Title"
            }
          },
          %Frame{
            id: "TIT3",
            flags: %FrameFlags{},
            data: %{
              encoding: :utf16,
              text: "Title"
            }
          }
        ]
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})

    encoded_string = :unicode.characters_to_binary("Title", :utf8, {:utf16, :big})

    encoded_text = :unicode.encoding_to_bom({:utf16, :big}) <> encoded_string <> <<0x00, 0x00>>

    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"CHAP", frame_size::size(32), _flags::binary-size(2)>> = frame_header

    assert 71 == frame_size
    ["chp1", frame_rest] = :binary.split(frame_data, <<0>>)

    <<0::size(32), 5000::size(32), 0::size(32), 1024::size(32), sub_frames::binary>> = frame_rest

    assert <<"TIT2", frame_size::size(32), _flags::binary-size(2), frames_data::binary>> =
             sub_frames

    assert 15 == frame_size

    assert <<sub_frame1::binary-size(frame_size), more_frames::binary>> = frames_data

    assert <<0x01::size(8), frame_text::binary>> = sub_frame1
    assert encoded_text == frame_text

    assert <<"TIT3", frame_size::size(32), _flags::binary-size(2), frames_data::binary>> =
             more_frames

    assert 15 == frame_size

    assert <<sub_frame1::binary-size(frame_size)>> = frames_data

    assert <<0x01::size(8), frame_text::binary>> = sub_frame1
    assert encoded_text == frame_text
  end

  test "v2.3 encoding CTOC frame" do
    frame = %Frame{
      id: "CTOC",
      flags: %FrameFlags{},
      data: %{
        element_id: "toc1",
        top_level: true,
        ordered: true,
        child_elements: [
          "chp1",
          "chp2"
        ],
        frames: [
          %Frame{
            id: "TIT2",
            flags: %FrameFlags{},
            data: %{
              encoding: :utf16,
              text: "Title"
            }
          },
          %Frame{
            id: "TIT3",
            flags: %FrameFlags{},
            data: %{
              encoding: :utf16,
              text: "Title"
            }
          }
        ]
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})

    encoded_string = :unicode.characters_to_binary("Title", :utf8, {:utf16, :big})

    encoded_text = :unicode.encoding_to_bom({:utf16, :big}) <> encoded_string <> <<0x00, 0x00>>

    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"CTOC", frame_size::size(32), _flags::binary-size(2)>> = frame_header

    assert 66 == frame_size
    ["toc1", frame_rest] = :binary.split(frame_data, <<0>>)

    <<0::size(6), 1::size(1), 1::size(1), 2::size(8), rest::binary>> = frame_rest

    <<"chp1", 0::8, "chp2", sub_frames::binary>> = rest

    assert <<"TIT2", frame_size::size(32), _flags::binary-size(2), frames_data::binary>> =
             sub_frames

    assert 15 == frame_size

    assert <<sub_frame1::binary-size(frame_size), more_frames::binary>> = frames_data

    assert <<0x01::size(8), frame_text::binary>> = sub_frame1
    assert encoded_text == frame_text

    assert <<"TIT3", frame_size::size(32), _flags::binary-size(2), frames_data::binary>> =
             more_frames

    assert 15 == frame_size

    assert <<sub_frame1::binary-size(frame_size)>> = frames_data

    assert <<0x01::size(8), frame_text::binary>> = sub_frame1
    assert encoded_text == frame_text
  end

  test "v2.3 encoding APIC frame" do
    frame = %Frame{
      id: "APIC",
      data: %Frame.AttachedPicture{
        encoding: :utf16,
        mime_type: "image/png",
        picture_type: :cover,
        description: "it's a description",
        image_data: <<24, 32>>
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"APIC", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 34 == frame_size

    assert <<0x01::size(8), frame_rest::binary>> = frame_data

    [mime_type, frame_rest] = :binary.split(frame_rest, <<0>>)
    assert mime_type == "image/png"
    [pre, post] = :binary.split(frame_rest, <<0, 0>>)
    assert <<0x03, description::binary>> = pre

    assert description == frame.data.description
    image_data = post

    assert image_data == frame.data.image_data
  end

  test "v2.3 encoding OWNE frame" do
    frame = %Frame{
      id: "OWNE",
      flags: %FrameFlags{},
      data: %{
        encoding: :utf16,
        currency: "SEK",
        price_paid: "1000",
        date: "20220602",
        seller: "Underjord AB"
      }
    }
    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"OWNE", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 29 == frame_size

    assert <<0x01::size(8), frame_rest::binary>> = frame_data

    [price, rest] = :binary.split(frame_rest, <<0>>)

    assert <<"SEK", "1000">> = price

    assert <<"20220602", "Underjord AB">> = rest
  end
end
