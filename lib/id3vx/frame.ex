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
            grouping_identity: nil,
            data: nil,
            raw_data: nil

  alias Id3vx.Frame

  @type t :: %Frame{
          id: String.t(),
          size: integer(),
          flags: %Id3vx.FrameFlags{},
          label: String.t(),
          grouping_identity: nil | integer(),
          data: %{optional(any) => any},
          raw_data: binary()
        }

  require Logger

  alias Id3vx.Tag
  alias Id3vx.Utils

  @text_encoding %{
    0x00 => :iso8859_1,
    0x01 => :utf16,
    0x02 => :utf16be,
    0x03 => :utf8
  }

  @boolean_encoding %{
    0x00 => false,
    0x01 => true
  }

  @type text_encoding_v3 :: :iso8859_1 | :utf16
  @type text_encoding_v4 :: :iso8859_1 | :utf16 | :utf16be | :utf8

  def text_encodings, do: @text_encoding

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

  @type picture_type ::
          :other
          | :basic_file_icon
          | :other_file_icon
          | :cover
          | :cover_back
          | :leaflet_page
          | :media
          | :lead_artist
          | :artist
          | :conductor
          | :band
          | :composer
          | :lyricist
          | :recording_location
          | :during_recording
          | :during_performance
          | :video_capture
          | :a_bright_coloured_fish
          | :illustration
          | :band_logotype
          | :studio_logotype

  def picture_types, do: @picture_type

  @channel_type %{
    0x00 => :other,
    0x01 => :master_volume,
    0x02 => :front_right,
    0x03 => :front_left,
    0x04 => :back_right,
    0x05 => :back_left,
    0x06 => :front_centre,
    0x07 => :back_centre,
    0x08 => :subwoofer
  }
  @type channel_type ::
          :other
          | :master_volume
          | :front_right
          | :front_left
          | :back_right
          | :back_left
          | :front_centre
          | :back_centre
          | :subwoofer

  def channel_types, do: @channel_type
  @spec encode_frame(Frame.t(), Id3vx.Tag.t()) :: binary()
  def encode_frame(frame, tag)

  def encode_frame(
        %Frame{id: id, flags: %{read_only: true}, raw_data: raw} = frame,
        %{version: 3} = tag
      ) do
    # Encode unmodified raw
    Logger.info(
      "Disregarding any edits to #{id} as it is flagged read_only. Re-using original data."
    )

    frame_size = byte_size(raw)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, raw])
  end

  def encode_frame(
        %Frame{id: id, flags: %{encryption: true}, raw_data: raw} = frame,
        %{version: 3} = tag
      ) do
    # Encode unmodified raw
    Logger.info("Disregarding any edits to #{id} as it is encrypted. Re-using original data.")

    frame_size = byte_size(raw)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, raw])
  end

  def encode_frame(
        %Frame{flags: %{compression: true}} = frame,
        %{version: 3} = tag
      ) do
    # Encode as if uncompressed, toss out the header we get
    <<_header::binary-size(10), uncompressed_data::binary>> =
      encode_frame(%{frame | flags: %{frame.flags | compression: false}}, tag)

    uncompressed_size = byte_size(uncompressed_data)

    z = :zlib.open()
    :zlib.deflateInit(z)

    compressed_data = :zlib.deflate(z, uncompressed_data, :full) |> IO.iodata_to_binary()

    :zlib.close(z)

    full_data = <<uncompressed_size::32>> <> compressed_data

    compressed_size = byte_size(full_data)

    header = encode_header(frame, compressed_size, tag)
    IO.iodata_to_binary([header, full_data])
  end

  def encode_frame(
        %Frame{flags: %{grouping_identity: true}, grouping_identity: gi} = frame,
        %{version: 3} = tag
      ) do
    # Encode as if no grouping identity
    <<_header::binary-size(10), frame_data::binary>> =
      encode_frame(%{frame | flags: %{frame.flags | grouping_identity: false}}, tag)

    # Build in the grouping identity
    grouped_data = <<gi::8>> <> frame_data
    size = byte_size(grouped_data)

    # Make a new header
    header = encode_header(frame, size, tag)
    IO.iodata_to_binary([header, grouped_data])
  end

  def encode_frame(%Frame{id: "CHAP"} = frame, %{version: 3} = tag) do
    %{
      element_id: element_id,
      start_time: start_time,
      end_time: end_time,
      start_offset: start_offset,
      end_offset: end_offset,
      frames: frames
    } = frame.data

    # Encode sub-frames
    encoded_frames =
      Enum.map(frames, fn frame ->
        encode_frame(frame, tag)
      end)

    frame_binary = [
      element_id,
      <<0>>,
      <<
        start_time::size(32),
        end_time::size(32),
        start_offset::size(32),
        end_offset::size(32)
      >>,
      encoded_frames
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)

    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "CTOC"} = frame, %{version: 3} = tag) do
    %{
      element_id: element_id,
      top_level: top_level,
      ordered: ordered,
      child_elements: child_elements,
      frames: frames
    } = frame.data

    entry_count = length(child_elements)

    encoded_child_elements = Enum.join(child_elements, <<0>>)

    # Encode sub-frames
    encoded_frames =
      Enum.map(frames, fn frame ->
        encode_frame(frame, tag)
      end)

    top_level = Utils.to_flag_int(top_level)
    ordered = Utils.to_flag_int(ordered)

    frame_binary = [
      element_id,
      <<0>>,
      <<0::6, top_level::1, ordered::1, entry_count::8>>,
      encoded_child_elements,
      encoded_frames
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "T" <> _} = frame, %{version: 3} = tag) do
    {bom, encoding, terminator} =
      case frame.data.encoding do
        :iso8859_1 ->
          {<<>>, :latin1, <<0x00>>}

        :utf16 ->
          encoding = {:utf16, :big}
          {:unicode.encoding_to_bom(encoding), encoding, <<0x00, 0x00>>}
      end

    text =
      case frame.data.text do
        text when is_binary(text) ->
          text

        [text | []] ->
          text

        [text | extra] ->
          Logger.warn(
            "Multiple text strings while encoding text frame to ID3v2.3. This is not supported. Will throw out: #{inspect(extra)}"
          )

          text
      end

    encoded_text = [
      bom,
      :unicode.characters_to_binary(text, :utf8, encoding),
      terminator
    ]

    encoding_byte =
      @text_encoding
      |> Utils.flip_map()
      |> Map.get(frame.data.encoding)

    frame_binary = [<<encoding_byte>>, encoded_text]
    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "APIC"} = frame, %{version: 3} = tag) do
    %Frame.AttachedPicture{
      encoding: encoding,
      mime_type: mime_type,
      picture_type: picture_type,
      description: description,
      image_data: image_data
    } = frame.data

    encoding_byte = get_encoding_byte(encoding)
    null_byte = get_null_byte(encoding)

    picture_type =
      @picture_type
      |> Utils.flip_map()
      |> Map.get(picture_type)

    frame_binary = [
      <<encoding_byte>>,
      mime_type,
      <<0>>,
      picture_type,
      description,
      null_byte,
      image_data
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{data: %Frame.Unknown{}} = frame, %{version: 3} = tag) do
    frame_size = byte_size(frame.raw_data)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame.raw_data])
  end

  def encode_frame(%Frame{id: "OWNE"} = frame, %{version: 3} = tag) do
    %{
      encoding: encoding,
      currency: currency,
      price_paid: price_paid,
      date: date,
      seller: seller
    } = frame.data

    encoding_byte =
      @text_encoding
      |> Utils.flip_map()
      |> Map.get(encoding)

    frame_binary = [<<encoding_byte>>, currency, price_paid, <<0>>, date, seller]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{data: %Frame.Unknown{}} = frame, %{version: 3} = tag) do
    frame_size = byte_size(frame.raw_data)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame.raw_data])
  end

  def encode_frame(%Frame{id: "COMM"} = frame, %{version: 3} = tag) do
    %Frame.Comment{
      encoding: encoding,
      language: language,
      content_description: content_description,
      content_text: content_text
    } = frame.data

    encoding_byte = get_encoding_byte(encoding)
    null_byte = get_null_byte(encoding)

    content_description = convert_string(encoding, content_description)
    content_text = convert_string(encoding, content_text)

    frame_binary = [<<encoding_byte>>, language, content_description, null_byte, content_text]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "WXXX"} = frame, %{version: 3} = tag) do
    %Frame.CustomURL{
      encoding: encoding,
      description: description,
      url: url
    } = frame.data

    encoding_byte = get_encoding_byte(encoding)
    null_byte = get_null_byte(encoding)
    url = convert_string(:iso8859_1, url)
    description = convert_string(encoding, description)
    frame_binary = [<<encoding_byte>>, description, null_byte, url]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "W" <> _} = frame, %{version: 3} = tag) do
    %Frame.URL{
      url: url
    } = frame.data

    url = convert_string(:iso8859_1, url)
    frame_binary = [url]
    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "RBUF"} = frame, %{version: 3} = tag) do
    %Frame.RecommendedBufferSize{
      buffer_size: buffer_size,
      embedded_info: embedded_info,
      offset: offset
    } = frame.data

    embedded_info = boolean_byte(embedded_info)
    frame_binary = [<<buffer_size::24>>, <<embedded_info::8>>, <<offset::32>>]
    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{raw_data: raw} = frame, tag) do
    if frame.flags.tag_alter_preservation do
      # According to spec, discard unknown frame if flag is set for it and tag is modified
      throw(:discard_frame)
    else
      frame_size = byte_size(raw)
      header = encode_header(frame, frame_size, tag)
      IO.iodata_to_binary([header, raw])
    end
  end

  def encode_header(%Frame{id: id, flags: flags}, size, %{version: 3} = tag) do
    flags = Id3vx.FrameFlags.as_binary(flags, tag)
    size = Utils.pad_to_byte_size(size, 4)
    [id, size, flags]
  end

  @spec parse(
          id :: binary(),
          tag :: Tag.t(),
          flags :: term(),
          data :: binary()
        ) :: Frame.t()
  def parse(id, tag, flags, data)

  def parse(id, %{version: 3} = tag, %{compression: true} = flags, data) do
    <<_decompressed_size::size(32), compressed_data::binary>> = data

    z = :zlib.open()
    :zlib.inflateInit(z)
    decompressed_data = :zlib.inflate(z, compressed_data) |> IO.iodata_to_binary()

    # Treat it like uncompressed data
    frame = parse(id, tag, %{flags | compression: false}, decompressed_data)
    # Re-introduce the compression flag
    %{frame | flags: %{flags | compression: true}}
  end

  def parse("APIC" = id, _tag, _flags, data) do
    <<encoding::size(8), rest::binary>> = data
    {mime_type, rest} = split_at_next_null(rest)
    <<picture_type::size(8), rest::binary>> = rest
    picture_type = @picture_type[picture_type]

    encoding = @text_encoding[encoding]
    {description, rest} = split_at_null(encoding, rest)
    description = convert_string(encoding, description)

    %Frame{
      id: id,
      data: %Frame.AttachedPicture{
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
      data: %Frame.Chapter{
        element_id: element_id,
        start_time: start_time,
        end_time: end_time,
        start_offset: start_offset,
        end_offset: end_offset,
        frames: sub_frames
      }
    }
  end

  def parse("CTOC" = id, tag, _flags, data) do
    {element_id, data} = split_at_next_null(data)

    <<_unused_flags::size(6), top_level::size(1), ordered::size(1), entry_count::size(8),
      rest::binary>> = data

    {ids_reversed, rest} =
      Enum.reduce(1..entry_count, {[], rest}, fn _, {ids, rest} ->
        {child_element_id, rest} = split_at_next_null(rest)
        {[child_element_id | ids], rest}
      end)

    child_element_ids = Enum.reverse(ids_reversed)

    sub_frames =
      if byte_size(rest) > 0 do
        Id3vx.parse_frames(tag, rest)
      else
        []
      end

    %Frame{
      id: id,
      data: %Frame.TableOfContents{
        element_id: element_id,
        top_level: top_level == 1,
        ordered: ordered == 1,
        child_elements: child_element_ids,
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

  def parse("PCST" = id, _tag, _flags, _data) do
    %Frame{
      id: id,
      data: %{
        purpose: "iTunes extension, if present indicates that this is a podcast."
      }
    }
  end

  def parse("T" <> _ = id, %Tag{version: 3}, _flags, data) do
    <<encoding::size(8), data::binary>> = data
    encoding = @text_encoding[encoding]
    %{text: text} = parse_encoded_text(encoding, data)
    # Ignore any extra text pieces, according to spec
    [text | []] = text

    %Frame{
      id: id,
      data: %Frame.Text{encoding: encoding, text: text}
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
      data: %Frame.CustomURL{
        encoding: encoding,
        description: description,
        url: url
      }
    }
  end

  def parse("W" <> _ = id, _tag, _flags, data) do
    %{text: pieces} = parse_encoded_text(:iso8859_1, data)

    # If there is a leading null, skip it
    url =
      case pieces do
        ["" | [url | _]] -> url
        [url | _] -> url
      end

    %Frame{
      id: id,
      data: %Frame.URL{
        url: url
      }
    }
  end

  def parse("OWNE" = id, _tag, _flags, data) do
    <<encoding::size(8), rest::binary>> = data
    encoding = @text_encoding[encoding]

    {price, rest} = split_at_null(encoding, rest)
    <<currency::binary-size(3), price_paid::binary>> = price

    <<date::binary-size(8), rest::binary>> = rest
    seller = rest

    seller = convert_string(encoding, seller)

    %Frame{
      id: id,
      data: %{
        encoding: encoding,
        currency: currency,
        price_paid: price_paid,
        date: date,
        seller: seller
      }
    }
  end

  def parse("RBUF" = id, _tag, _flags, data) do
    <<buffer_size::size(24), embedded_info::size(8), offset::size(32)>> = data

    %Frame{
      id: id,
      data: %Frame.RecommendedBufferSize{
        buffer_size: buffer_size,
        embedded_info: embedded_info,
        offset: offset
      }
    }
  end

  def parse(id, _tag, _flags, data) do
    %Frame{
      id: id,
      label: "#{id} is not implemented, please contribute, it's not hard.",
      data: %Frame.Unknown{unused: :frame}
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

  defp get_null_byte(encoding) do
    case encoding do
      :iso8859_1 ->
        <<0>>

      :utf16 ->
        <<0, 0>>
    end
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
    case :binary.split(data, <<0>>) do
      [pre, post] ->
        {pre, post}

      [pre] ->
        {pre, <<>>}
    end
  end

  defp split_at_next_double_null(data) do
    case :binary.split(data, <<0, 0>>) do
      [pre, post] ->
        {pre, post}

      [pre] ->
        {pre, <<>>}
    end
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

  defp get_encoding_byte(encoding) do
    @text_encoding
    |> Utils.flip_map()
    |> Map.get(encoding)
  end

  defp boolean_byte(boolean) do
    @boolean_encoding
    |> Utils.flip_map()
    |> Map.get(boolean)
  end
end
