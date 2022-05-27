defmodule Id3vx.Frame do
  @moduledoc """

  Natives types:
    AENC Audio encryption
    APIC Attached picture
    ASPI Audio seek point index
    COMM Comments
    COMR Commercial frame
    ENCR Encryption method registration
    EQU2 Equalisation (2)
    ETCO Event timing codes
    GEOB General encapsulated object
    GRID Group identification registration
    LINK Linked information
    MCDI Music CD identifier
    MLLT MPEG location lookup table
    OWNE Ownership frame
    PRIV Private frame
    PCNT Play counter
    POPM Popularimeter
    POSS Position synchronisation frame
    RBUF Recommended buffer size
    RVA2 Relative volume adjustment (2)
    RVRB Reverb
    SEEK Seek frame
    SIGN Signature frame
    SYLT Synchronised lyric/text
    SYTC Synchronised tempo codes
    TALB Album/Movie/Show title
    TBPM BPM (beats per minute)
    TCOM Composer
    TCON Content type
    TCOP Copyright message
    TDEN Encoding time
    TDLY Playlist delay
    TDOR Original release time
    TDRC Recording time
    TDRL Release time
    TDTG Tagging time
    TENC Encoded by
    TEXT Lyricist/Text writer
    TFLT File type
    TIPL Involved people list
    TIT1 Content group description
    TIT2 Title/songname/content description
    TIT3 Subtitle/Description refinement
    TKEY Initial key
    TLAN Language(s)
    TLEN Length
    TMCL Musician credits list
    TMED Media type
    TMOO Mood
    TOAL Original album/movie/show title
    TOFN Original filename
    TOLY Original lyricist(s)/text writer(s)
    TOPE Original artist(s)/performer(s)
    TOWN File owner/licensee
    TPE1 Lead performer(s)/Soloist(s)
    TPE2 Band/orchestra/accompaniment
    TPE3 Conductor/performer refinement
    TPE4 Interpreted, remixed, or otherwise modified by
    TPOS Part of a set
    TPRO Produced notice
    TPUB Publisher
    TRCK Track number/Position in set
    TRSN Internet radio station name
    TRSO Internet radio station owner
    TSOA Album sort order
    TSOP Performer sort order
    TSOT Title sort order
    TSRC ISRC (international standard recording code)
    TSSE Software/Hardware and settings used for encoding
    TSST Set subtitle
    TXXX User defined text information frame
    UFID Unique file identifier
    USER Terms of use
    USLT Unsynchronised lyric/text transcription
    WCOM Commercial information
    WCOP Copyright/Legal information
    WOAF Official audio file webpage
    WOAR Official artist/performer webpage
    WOAS Official audio source webpage
    WORS Official Internet radio station homepage
    WPAY Payment
    WPUB Publishers official webpage
    WXXX User defined URL link frame
  """

  defstruct id: nil,
            size: nil,
            flags: nil,
            # "Payment", "Album sort order", "Title/songname/content description"
            label: nil,
            data: nil

  alias Id3vx.Frame
  alias Id3vx.Tag

  def encode_frame(%Frame{id: "T" <> _} = frame, %{version: 3}) do
    data =
      case frame.data.encoding do
        0 ->
          Enum.reduce(frame.data.text, <<>>, fn string, acc ->
            acc <> string <> <<0x00>>
          end)

        1 ->
          raise "unicode string encoding not implemented"
      end

    flags = <<0x00, 0x00>>
    frame_size = byte_size(data)
  end

  @text_encoding %{
    0x00 => :iso8859_1,
    0x01 => :utf16,
    0x02 => :utf16be,
    0x03 => :utf8
  }
  def parse("T" <> _ = id, %Tag{version: 3}, flags, data) do
    <<encoding::size(8), data::binary>> = data
    encoding = @text_encoding[encoding]
    %{text: text} = frame_data = parse_encoded_text(encoding, data)
    # Ignore any extra text pieces, according to spec
    [text | []] = text

    %Frame{
      id: id,
      data: %{encoding: encoding, text: text}
    }
  end

  @picture_type %{
    0x00 => :other,
    0x01 => :basic_file_icon,
    0x02 => :other_file_icon,
    0x03 => :cover,
    0x04 => :cover_back,
    0x05 => :leaflet_page,
    0x06 => :media,
    0x07 => :lead_artist,
    0x08 => :artist,
    0x09 => :conductor,
    0x0A => :band,
    0x0B => :composer,
    0x0C => :lyricist,
    0x0D => :recording_location,
    0x0E => :during_recording,
    0x0F => :during_performance,
    0x10 => :video_capture,
    0x11 => :a_bright_coloured_fish,
    0x12 => :illustration,
    0x13 => :band_logotype,
    0x14 => :studio_logotype
  }
  def parse("APIC" = id, _tag, flags, data) do
    <<encoding::size(8), rest::binary>> = data
    {mime_type, rest} = split_at_next_null(rest)
    <<picture_type::size(8), rest::binary>> = rest
    picture_type = @picture_type[picture_type]

    encoding = @text_encoding[encoding]
    {description, rest} = split_at_null(encoding, rest)
    description = convert_string(encoding, description)

    %Frame{
      id: id,
      data: %{
        encoding: encoding,
        mime_type: mime_type,
        picture_type: picture_type,
        description: description,
        image_data: rest
      }
    }
  end

  def parse("CHAP" = id, tag, _flags, data) do
    {element_id, data} = split_at_next_null(data)

    <<start_time::size(32), end_time::size(32), start_offset::size(32), end_offset::size(32),
      sub_frames_data::binary>> = data

    sub_frames = Id3vx.parse_frames(tag, sub_frames_data)

    %Frame{
      id: id,
      data: %{
        element_id: element_id,
        start_time: start_time,
        end_time: end_time,
        start_offset: start_offset,
        end_offset: end_offset,
        frames: sub_frames
      }
    }
  end

  def parse("COMM" = id, %Tag{version: 3}, _flags, data) do
    <<encoding::size(8), language::binary-size(3), data::binary>> = data
    encoding = @text_encoding[encoding]

    %{text: text_parts} = parse_encoded_text(encoding, data)
    # This construction makes it ignore any extra termination which
    # is according to spec and resilient to issue
    # The Podcast Chapters app produces some odd COMM fields
    [description | [text | _]] = text_parts

    %Frame{
      id: id,
      data: %{
        encoding: encoding,
        language: language,
        description: description,
        text: text
      }
    }
  end

  def parse("WXXX" = id, _tag, _flags, data) do
    <<encoding::size(8), data::binary>> = data
    encoding = @text_encoding[encoding]

    # I've seen double null leading here, not sure why
    {description, rest} = split_at_a_null_or_two(data)
    description = convert_string(encoding, description)

    %{text: [url]} = parse_encoded_text(:iso8859_1, rest)

    %Frame{
      id: id,
      data: %{
        encoding: encoding,
        description: description,
        url: url
      }
    }
  end

  def parse(id, _tag, _flags, data) do
    %Frame{
      id: id,
      label: "#{id} is not implemented, please contribute, it's not hard.",
      data: %{status: :not_implemented, raw_data: data}
    }
  end

  defp split_at_a_null_or_two(data) do
    {first, rest} = split_at_next_null(data)

    rest =
      case rest do
        <<0::size(8), rest::binary>> -> rest
        rest -> rest
      end

    {first, rest}
  end

  defp split_at_null(encoding, data) do
    case encoding do
      :iso8859_1 ->
        split_at_next_null(data)

      :utf8 ->
        split_at_next_null(data)

      :utf16 ->
        split_at_next_double_null(data)

      :utf16_be ->
        split_at_next_double_null(data)
    end
  end

  defp split_at_next_null(data) do
    [pre, post] = :binary.split(data, <<0>>)
    {pre, post}
  end

  defp split_at_next_double_null(data, acc \\ <<>>) do
    [pre, post] = :binary.split(data, <<0, 0>>)
    {pre, post}
  end

  def parse_encoded_text(encoding, data) do
    {strings, _rest} = decode_string_sequence(encoding, byte_size(data), data)

    %{
      encoding: encoding,
      text: strings
    }
  end

  defp decode_string_sequence(encoding, max_byte_size, data, acc \\ [])

  # Out of data, clean up and return
  defp decode_string_sequence(_, max_byte_size, data, acc) when max_byte_size <= 0 do
    {Enum.reverse(acc), data}
  end

  # decode_string and recurse
  defp decode_string_sequence(encoding, max_byte_size, data, acc) do
    {str, str_size, rest} = decode_string(encoding, max_byte_size, data)
    decode_string_sequence(encoding, max_byte_size - str_size, rest, [str | acc])
  end

  defp decode_string(encoding, max_byte_size, data) when encoding in [:utf16, :utf16be] do
    {str, rest} = get_double_null_terminated(data, max_byte_size)

    {convert_string(encoding, str), byte_size(str) + 2, rest}
  end

  defp decode_string(encoding, max_byte_size, data) when encoding in [:iso8859_1, :utf8] do
    case :binary.split(data, <<0>>) do
      [str, rest] when byte_size(str) + 1 <= max_byte_size ->
        {str, byte_size(str) + 1, rest}

      _ ->
        {str, rest} = :erlang.split_binary(data, max_byte_size)
        {str, max_byte_size, rest}
    end
  end

  defp convert_string(encoding, str) when encoding in [:iso8859_1, :utf8] do
    str
  end

  defp convert_string(:utf16, data) do
    {encoding, bom_length} = :unicode.bom_to_encoding(data)
    {_, string_data} = String.split_at(data, bom_length)
    :unicode.characters_to_binary(string_data, encoding)
  end

  defp convert_string(:utf16be, data) do
    :unicode.characters_to_binary(data, {:utf16, :big})
  end

  defp get_double_null_terminated(data, max_byte_size, acc \\ [])

  defp get_double_null_terminated(rest, 0, acc) do
    {acc |> Enum.reverse() |> :binary.list_to_bin(), rest}
  end

  defp get_double_null_terminated(<<0, 0, rest::binary>>, _, acc) do
    {acc |> Enum.reverse() |> :binary.list_to_bin(), rest}
  end

  defp get_double_null_terminated(<<a::size(8), b::size(8), rest::binary>>, max_byte_size, acc) do
    next_max_byte_size = max_byte_size - 2
    get_double_null_terminated(rest, next_max_byte_size, [b, a | acc])
  end
end
