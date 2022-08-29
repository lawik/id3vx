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
    assert <<"ID3", 3::integer, 0::integer, 128::size(8), tag_size::binary-size(4)>> = tag_header
    tag_size = Id3vx.Utils.decode_synchsafe_integer(tag_size)
    assert 32 == tag_size

    assert <<"TIT2", frame_size::size(32), _flags::binary-size(2), frames_data::binary>> =
             tag_rest

    assert 21 == frame_size

    assert <<0x01::size(8), frame_text::binary>> = frames_data
    assert encoded_text == Id3vx.Utils.decode_unsynchronized(frame_text)
  end

  test "encoding synchsafe numbers" do
    max = 256 * 1024 * 1024

    for num1 <- 1..256 do
      num2 =
        num1
        |> Id3vx.Utils.encode_synchsafe_integer()
        |> Id3vx.Utils.decode_synchsafe_integer()

      assert num1 == num2
    end

    for num1 <- 1..256 do
      num1 = num1 * 1024 * 1024 - 1

      num2 =
        num1
        |> Id3vx.Utils.encode_synchsafe_integer()
        |> Id3vx.Utils.decode_synchsafe_integer()

      assert num1 == num2
    end

    try do
      Id3vx.Utils.encode_synchsafe_integer(max)
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

  test "v2.3 encoding COMM frame" do
    frame = %Frame{
      id: "COMM",
      flags: %FrameFlags{},
      data: %Frame.Comment{
        encoding: :utf16,
        language: "english",
        content_description: "foobarbaz",
        content_text: "it's about foobarbaz"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary

    assert <<"COMM", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 39 == frame_size

    assert <<0x01::size(8), frame_rest::binary>> = frame_data
    assert <<"english", frame_rest::binary>> = frame_rest

    [content_description, content_text] = :binary.split(frame_rest, <<0, 0>>)

    assert content_description == frame.data.content_description
    assert content_text == frame.data.content_text
  end

  test "v2.3 encoding url frames" do
    frame = %Frame{
      id: "WCOM",
      flags: %FrameFlags{},
      data: %Frame.URL{
        url: "https://example.com"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"WCOM", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 19 == frame_size
    assert frame.data.url == frame_data

    frame = %Frame{
      id: "WCOP",
      flags: %FrameFlags{},
      data: %Frame.URL{
        url: "https://example.com"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"WCOP", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 19 == frame_size
    assert frame.data.url == frame_data
  end

  test "v2.3 encoding WXXX frame" do
    frame = %Frame{
      id: "WXXX",
      flags: %FrameFlags{},
      data: %Frame.CustomURL{
        encoding: :utf16,
        description: "it's a custom description",
        url: "https://example.com"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"WXXX", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 47 == frame_size
    assert <<0x01::size(8), frame_rest::binary>> = frame_data
    [description, url] = :binary.split(frame_rest, <<0, 0>>)
    assert description == frame.data.description
    assert url == frame.data.url
  end

  test "v2.3 encoding RBUF frame" do
    frame = %Frame{
      id: "RBUF",
      flags: %FrameFlags{},
      data: %Frame.RecommendedBufferSize{
        buffer_size: 308,
        embedded_info: true,
        offset: 308
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary

    assert <<"RBUF", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 8 == frame_size

    <<buffer_size::size(24), 0x01::size(8), offset::size(32)>> = frame_data

    assert buffer_size == frame.data.buffer_size
    assert offset == frame.data.offset
  end

  test "v2.3 encoding PRIV frame" do
    frame = %Frame{
      id: "PRIV",
      flags: %FrameFlags{},
      data: %Frame.Private{
        owner_identifier: "FOOBARBAZ",
        private_data: "foobarbaz"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"PRIV", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 19 == frame_size

    [owner_identifier, private_data] = :binary.split(frame_data, <<0>>)

    assert owner_identifier == frame.data.owner_identifier
    assert private_data == frame.data.private_data
  end

  test "v2.3 encoding GRID frame" do
    frame = %Frame{
      id: "GRID",
      flags: %FrameFlags{},
      data: %Frame.GroupIdentificationRegistration{
        owner_identifier: "FOOBARBAZ",
        symbol: 80,
        group_dependent_data: "foobarbaz"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"GRID", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 20 == frame_size
    [owner_identifier, rest] = :binary.split(frame_data, <<0>>)
    assert owner_identifier == frame.data.owner_identifier

    <<symbol::size(8), group_dependent_data::binary>> = rest

    assert symbol == frame.data.symbol
    assert group_dependent_data == frame.data.group_dependent_data
  end

  test "v2.3 encoding ENCR frame" do
    frame = %Frame{
      id: "ENCR",
      flags: %FrameFlags{},
      data: %Frame.EncryptionMethodRegistration{
        owner_identifier: "FOOBARBAZ",
        method_symbol: 80,
        encryption_data: "foobarbaz"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"ENCR", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 21 == frame_size
    [owner_identifier, rest] = :binary.split(frame_data, <<0, 0>>)
    assert owner_identifier == frame.data.owner_identifier

    <<method_symbol::size(8), encryption_data::binary>> = rest

    assert method_symbol == frame.data.method_symbol
    assert encryption_data == frame.data.encryption_data
  end

  test "v2.3 PCNT encoding" do
    frame = %Frame{
      id: "PCNT",
      flags: %FrameFlags{},
      data: %Frame.PlayCounter{
        counter: 2
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"PCNT", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 4 == frame_size
    counter = :binary.decode_unsigned(frame_data)
    assert counter == frame.data.counter
  end

  test "v2.3 encoding MCDI frame" do
    frame = %Frame{
      id: "MCDI",
      flags: %FrameFlags{},
      data: %Frame.MusicCDIdentifier{
        cd_toc_binary: "foo bar baz"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), _frame_data::binary>> = binary
    assert <<"MCDI", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 11 == frame_size
  end

  test "v2.3 encoding AENC frame" do
    frame = %Frame{
      id: "AENC",
      flags: %FrameFlags{},
      data: %Frame.AudioEncryption{
        owner_identifier: "Owner Foo",
        preview_start: 02,
        preview_length: 10,
        encryption_info: "data info encrypter"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"AENC", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 33 == frame_size

    [owner_identifier, rest] = :binary.split(frame_data, <<0>>)
    assert frame.data.owner_identifier == owner_identifier

    <<0x02::size(16), 0xA::size(16), encryption_info::binary>> = rest

    assert encryption_info == frame.data.encryption_info
  end

  test "v2.3 encoding COMR frame" do
    frame = %Frame{
      id: "COMR",
      flags: %FrameFlags{},
      data: %Frame.Commercial{
        encoding: :utf16,
        price: "SEK100",
        valid_until: "20220101",
        contact_url: "http://example.com",
        recieved_as: :standard_cd_album_with_other_songs,
        seller_name: "Joe",
        description: "this is a soft description",
        picture_mime: "image/jpeg",
        logo: "random bit string"
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"COMR", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 97 == frame_size

    assert <<0x01::size(8), frame_rest::binary>> = frame_data

    [price, frame_rest] = :binary.split(frame_rest, <<0>>)
    assert price == frame.data.price

    <<valid_until::binary-size(8), frame_rest::binary>> = frame_rest

    assert valid_until == frame.data.valid_until

    [contact_url, _rest] = :binary.split(frame_rest, <<0>>)
    assert contact_url == frame.data.contact_url
  end

  test "v2.3 encoding of RVRB frame" do
    frame = %Frame{
      id: "RVRB",
      flags: %FrameFlags{},
      data: %Frame.Reverb{
        reverb_left: 32,
        reverb_right: 32,
        bounces_left: 3,
        bounces_right: 3,
        feedback_left_to_left: 50,
        feedback_left_to_right: 50,
        feedback_right_to_right: 50,
        feedback_right_to_left: 50,
        premix_left_to_right: 27,
        premix_right_to_left: 27
      }
    }

    binary = Frame.encode_frame(frame, %Tag{version: 3})
    assert <<frame_header::binary-size(10), frame_data::binary>> = binary
    assert <<"RVRB", frame_size::size(32), _flags::binary-size(2)>> = frame_header
    assert 12 == frame_size

    assert <<reverb_left::size(16), reverb_right::size(16), frame_rest::binary>> = frame_data

    assert reverb_left == frame.data.reverb_left
    assert reverb_right == frame.data.reverb_right

    assert <<bounces_left::size(8), bounces_right::size(8), frame_rest::binary>> = frame_rest
    assert bounces_left == frame.data.bounces_left
    assert bounces_right == frame.data.bounces_right

    assert <<feedback_left_to_left::size(8), feedback_left_to_right::size(8), frame_rest::binary>> =
             frame_rest

    assert feedback_left_to_left == frame.data.feedback_left_to_left
    assert feedback_left_to_right == frame.data.feedback_left_to_right

    assert <<feedback_right_to_right::size(8), feedback_right_to_left::size(8),
             frame_rest::binary>> = frame_rest

    assert feedback_right_to_right == frame.data.feedback_right_to_right
    assert feedback_right_to_left == frame.data.feedback_right_to_left

    assert <<premix_left_to_right::size(8), premix_right_to_left::size(8), _frame_rest::binary>> =
             frame_rest

    assert premix_left_to_right == frame.data.premix_left_to_right
    assert premix_right_to_left == frame.data.premix_right_to_left
  end
end
