defmodule Id3vx.Frame do
  @moduledoc """
  Implementation of frame parsing and encoding.

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
  alias Id3vx.Error

  defstruct id: nil,
            size: nil,
            flags: nil,
            # "Payment", "Album sort order", "Title/songname/content description"
            label: nil,
            grouping_identity: nil,
            data: nil,
            raw_data: nil

  alias Id3vx.Frame
  alias Id3vx.FrameFlags
  alias Id3vx.Frame.Labels

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

  @recieved_as_type %{
    0x00 => :other,
    0x01 => :standard_cd_album_with_other_songs,
    0x02 => :compressed_audio_on_cd,
    0x03 => :file_over_the_internet,
    0x04 => :stream_over_the_internet,
    0x05 => :as_note_sheets,
    0x06 => :as_note_sheets_in_a_book_with_other_sheets,
    0x07 => :music_on_other_media,
    0x08 => :non_musical_merchandise
  }
  @type recieved_as_type ::
          :other
          | :standard_cd_album_with_other_songs
          | :compressed_audio_on_cd
          | :file_over_the_internet
          | :stream_over_the_internet
          | :as_note_sheets
          | :as_note_sheets_in_a_book_with_other_sheets
          | :music_on_other_media
          | :non_musical_merchandise
  def recieved_as_types, do: @recieved_as_type

  @content_type %{
    0x0 => :other,
    0x1 => :lyrics,
    0x2 => :text_transcription,
    0x3 => :movement,
    0x4 => :events,
    0x5 => :chord,
    0x6 => :trivia,
    0x7 => :webpages_url,
    0x8 => :images_url
  }

  @type content_type ::
          :other
          | :lyrics
          | :text_transcription
          | :movement
          | :events
          | :chord
          | :trivia
          | :webpages_url
          | :images_url

  def content_types, do: @content_type

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

  def encode_frame(%Frame{data: %Frame.Unknown{}} = frame, %{version: 3} = tag) do
    frame_size = byte_size(frame.raw_data)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame.raw_data])
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

    start_t = Utils.pad_to_byte_size(start_time, 4)
    end_t = Utils.pad_to_byte_size(end_time, 4)
    start_o = Utils.pad_to_byte_size(start_offset, 4)
    end_o = Utils.pad_to_byte_size(end_offset, 4)

    frame_binary = [
      encode_string(:iso8859_1, element_id),
      <<0>>,
      start_t,
      end_t,
      start_o,
      end_o,
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

    # null-separated with trailing null
    encoded_child_elements = Enum.join(child_elements, <<0>>) <> <<0>>

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

    encoding = frame.data.encoding

    encoded_text = encode_string(encoding, text)

    encoding_byte = get_encoding_byte(encoding)
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
    image_description = encode_string(encoding, description)

    picture_type =
      @picture_type
      |> Utils.flip_map()
      |> Map.get(picture_type)

    frame_binary = [
      <<encoding_byte>>,
      mime_type,
      <<0>>,
      picture_type,
      image_description,
      null_byte,
      image_data
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
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

  def encode_frame(%Frame{id: "COMM"} = frame, %{version: 3} = tag) do
    %Frame.Comment{
      encoding: encoding,
      language: language,
      content_description: content_description,
      content_text: content_text
    } = frame.data

    if byte_size(language) != 3 do
      throw(%Error{
        message: "The language must be a 3 byte ISO-639-2 code.",
        context: {:frame, frame}
      })
    end

    encoding_byte = get_encoding_byte(encoding)
    null_byte = get_null_byte(encoding)

    content_description = encode_string(encoding, content_description)
    content_text = encode_string(encoding, content_text)

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
    url = encode_string(:iso8859_1, url)
    description = encode_string(encoding, description)
    frame_binary = [<<encoding_byte>>, description, null_byte, url]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "W" <> _} = frame, %{version: 3} = tag) do
    %Frame.URL{
      url: url
    } = frame.data

    url = encode_string(:iso8859_1, url)
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

  def encode_frame(%Frame{id: "MCDI"} = frame, %{version: 3} = tag) do
    %Frame.MusicCDIdentifier{
      cd_toc_binary: cd_toc_binary
    } = frame.data

    frame_binary = [cd_toc_binary]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "PRIV"} = frame, %{version: 3} = tag) do
    %Frame.Private{
      owner_identifier: owner_identifier,
      private_data: private_data
    } = frame.data

    frame_binary = [owner_identifier, <<0>>, private_data]
    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "GRID"} = frame, %{version: 3} = tag) do
    %Frame.GroupIdentificationRegistration{
      owner_identifier: owner_identifier,
      symbol: symbol,
      group_dependent_data: group_dependent_data
    } = frame.data

    frame_binary = [owner_identifier, <<0>>, <<symbol::8>>, group_dependent_data]
    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "ENCR"} = frame, %{version: 3} = tag) do
    %Frame.EncryptionMethodRegistration{
      owner_identifier: owner_identifier,
      method_symbol: method_symbol,
      encryption_data: encryption_data
    } = frame.data

    frame_binary = [owner_identifier, <<0, 0>>, <<method_symbol::8>>, encryption_data]
    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "PCNT"} = frame, %{version: 3} = tag) do
    %{
      counter: counter
    } = frame.data

    # byte size of counter
    counter_binary_size = counter |> :binary.encode_unsigned() |> byte_size()

    # use minimum 32 bits
    counter_size = max(counter_binary_size * 8, 32)

    binary = <<counter::size(counter_size)>>

    frame_binary = [binary]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "AENC"} = frame, %{version: 3} = tag) do
    %Frame.AudioEncryption{
      owner_identifier: owner_identifier,
      preview_start: preview_start,
      preview_length: preview_length,
      encryption_info: encryption_info
    } = frame.data

    frame_binary = [
      owner_identifier,
      <<0>>,
      <<preview_start::16>>,
      <<preview_length::16>>,
      encryption_info
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "COMR"} = frame, %{version: 3} = tag) do
    %{
      encoding: encoding,
      price: price,
      valid_until: valid_until,
      contact_url: contact_url,
      recieved_as: recieved_as,
      seller_name: seller_name,
      description: description,
      picture_mime: picture_mime,
      logo: logo
    } = frame.data

    null_byte = get_null_byte(encoding)
    encoding_byte = get_encoding_byte(encoding)
    contact_url = encode_string(:iso8859_1, contact_url)

    recieved_as =
      @recieved_as_type
      |> Utils.flip_map()
      |> Map.get(recieved_as)

    seller_name = encode_string(encoding, seller_name)
    description = encode_string(encoding, description)

    frame_binary = [
      <<encoding_byte>>,
      price,
      <<0>>,
      <<valid_until::binary-size(8)>>,
      contact_url,
      <<0>>,
      <<recieved_as::8>>,
      seller_name,
      null_byte,
      description,
      null_byte,
      picture_mime,
      <<0>>,
      logo
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "RVRB"} = frame, %{version: 3} = tag) do
    %Frame.Reverb{
      reverb_left: reverb_left,
      reverb_right: reverb_right,
      bounces_left: bounces_left,
      bounces_right: bounces_right,
      feedback_left_to_left: feedback_left_to_left,
      feedback_left_to_right: feedback_left_to_right,
      feedback_right_to_right: feedback_right_to_right,
      feedback_right_to_left: feedback_right_to_left,
      premix_left_to_right: premix_left_to_right,
      premix_right_to_left: premix_right_to_left
    } = frame.data

    frame_binary = [
      <<reverb_left::16>>,
      <<reverb_right::16>>,
      <<bounces_left::8>>,
      <<bounces_right::8>>,
      <<feedback_left_to_left::8>>,
      <<feedback_left_to_right::8>>,
      <<feedback_right_to_right::8>>,
      <<feedback_right_to_left::8>>,
      <<premix_left_to_right::8>>,
      <<premix_right_to_left::8>>
    ]

    frame_size = IO.iodata_length(frame_binary)
    header = encode_header(frame, frame_size, tag)
    IO.iodata_to_binary([header, frame_binary])
  end

  def encode_frame(%Frame{id: "USLT"} = frame, %{version: 3} = tag) do
    %Frame.UnsynchronisedLyricsText{
      encoding: encoding,
      language: language,
      content_descriptor: content_descriptor,
      lyrics_text: lyrics_text
    } = frame.data

    null_byte = get_null_byte(encoding)
    encoding_byte = get_encoding_byte(encoding)

    content_descriptor = encode_string(encoding, content_descriptor)
    lyrics_text = encode_string(encoding, lyrics_text)

    frame_binary = [
      <<encoding_byte>>,
      language,
      content_descriptor,
      null_byte,
      lyrics_text
    ]

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
    description = decode_string(encoding, description)

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

    sub_frames = parse_frames(tag, sub_frames_data)

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
        parse_frames(tag, rest)
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

    {first, second} = split_at_null(encoding, data)
    description = decode_string(encoding, first)
    text = decode_string(encoding, second)

    %Frame{
      id: id,
      data: %Frame.Comment{
        encoding: encoding,
        language: language,
        content_description: description,
        content_text: text
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
    {first, _second} = split_at_null(encoding, data)
    text = decode_string(encoding, first)

    %Frame{
      id: id,
      data: %Frame.Text{encoding: encoding, text: text}
    }
  end

  def parse("WXXX" = id, _tag, _flags, data) do
    <<encoding::size(8), data::binary>> = data
    encoding = @text_encoding[encoding]

    # I've seen double null leading here, not sure why
    {description, rest} = split_at_null(encoding, data)

    description = decode_string(encoding, description)

    rest = skip_leading_null(rest)
    # Drop trailing nulls
    {url, _drop} = split_at_next_null(rest)
    url = decode_string(:iso88591_1, url)

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
    # For some reason I've seen leading nulls here
    data = skip_leading_null(data)
    {data, _skip} = split_at_null(:iso8859_1, data)
    # Drop trailing nulls
    {url, _drop} = split_at_next_null(data)
    url = decode_string(:iso88591_1, url)

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

    seller = decode_string(encoding, seller)

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

  def parse("PRIV" = id, _tag, _flags, data) do
    [owner_identifier, private_data] = :binary.split(data, <<0>>)

    %Frame{
      id: id,
      data: %Frame.Private{
        owner_identifier: owner_identifier,
        private_data: private_data
      }
    }
  end

  def parse("MCDI" = id, _tag, _flags, data) do
    cd_toc_binary = data

    %Frame{
      id: id,
      data: %Frame.MusicCDIdentifier{
        cd_toc_binary: cd_toc_binary
      }
    }
  end

  def parse("GRID" = id, _tag, _flags, data) do
    [owner_identifier, rest] = :binary.split(data, <<0>>)
    <<symbol::binary-size(8), group_dependent_data::binary>> = rest

    %Frame{
      id: id,
      data: %Frame.GroupIdentificationRegistration{
        owner_identifier: owner_identifier,
        symbol: symbol,
        group_dependent_data: group_dependent_data
      }
    }
  end

  def parse("ENCR" = id, _tag, _flags, data) do
    [owner_identifier, rest] = :binary.split(data, <<0, 0>>)
    <<method_symbol::size(8), encryption_data::binary>> = rest

    %Frame{
      id: id,
      data: %Frame.EncryptionMethodRegistration{
        owner_identifier: owner_identifier,
        method_symbol: method_symbol,
        encryption_data: encryption_data
      }
    }
  end

  def parse("PCNT" = id, _tag, _flags, data) do
    counter = :binary.decode_unsigned(data)

    %Frame{
      id: id,
      data: %Frame.PlayCounter{
        counter: counter
      }
    }
  end

  def parse("AENC" = id, _tag, _flags, data) do
    [owner_identifier, rest] = :binary.split(data, <<0>>)

    <<preview_start::size(16), preview_length::size(16), encryption_info::binary>> = rest

    %Frame{
      id: id,
      data: %Frame.AudioEncryption{
        owner_identifier: owner_identifier,
        preview_start: preview_start,
        preview_length: preview_length,
        encryption_info: encryption_info
      }
    }
  end

  def parse("COMR" = id, _tag, _flags, data) do
    <<encoding::size(8), rest::binary>> = data
    encoding = @text_encoding[encoding]

    [price, rest] = :binary.split(rest, <<0>>)

    <<valid_until::binary-size(8), rest::binary>> = rest

    [contact_url, rest] = :binary.split(rest, <<0>>)

    <<recieved_as::size(8), rest::binary>> = rest
    recieved_as = @recieved_as_type[recieved_as]

    {seller_name, rest} = split_at_null(encoding, rest)

    {description, rest} = split_at_null(encoding, rest)
    description = decode_string(encoding, description)

    [picture_mime, rest] = :binary.split(rest, <<0>>)

    logo = rest

    %Frame{
      id: id,
      data: %Frame.Commercial{
        encoding: encoding,
        price: price,
        valid_until: valid_until,
        contact_url: contact_url,
        recieved_as: recieved_as,
        seller_name: seller_name,
        description: description,
        picture_mime: picture_mime,
        logo: logo
      }
    }
  end

  def parse("RVRB" = id, _tag, _flags, data) do
    <<reverb_left::size(16), reverb_right::size(16), bounces_left::size(8),
      bounces_right::size(8), feedback_left_to_left::size(8), feedback_left_to_right::size(8),
      feedback_right_to_right::size(8), feedback_right_to_left::size(8),
      premix_left_to_right::size(8), premix_right_to_left::size(8)>> = data

    %Frame{
      id: id,
      data: %Frame.Reverb{
        reverb_left: reverb_left,
        reverb_right: reverb_right,
        bounces_left: bounces_left,
        bounces_right: bounces_right,
        feedback_left_to_left: feedback_left_to_left,
        feedback_left_to_right: feedback_left_to_right,
        feedback_right_to_right: feedback_right_to_right,
        feedback_right_to_left: feedback_right_to_left,
        premix_left_to_right: premix_left_to_right,
        premix_right_to_left: premix_right_to_left
      }
    }
  end

  def parse("USLT" = id, _tag, _flags, data) do
    <<encoding::size(8), language::binary-size(3), data::binary>> = data
    encoding = @text_encoding[encoding]
    {content_descriptor, rest} = split_at_null(encoding, data)
    content_descriptor = decode_string(encoding, content_descriptor)

    lyrics_text = decode_string(encoding, rest)

    %Frame{
      id: id,
      data: %Frame.UnsynchronisedLyricsText{
        encoding: encoding,
        language: language,
        content_descriptor: content_descriptor,
        lyrics_text: lyrics_text
      }
    }
  end

  def parse(id, _tag, _flags, _data) do
    Logger.warn("Unimplemented frame parsed: #{id}")

    %Frame{
      id: id,
      label: "#{id} is not implemented, please contribute, it's not hard.",
      data: %Frame.Unknown{unused: :frame}
    }
  end

  def parse_frames(tag, frames_data, frames \\ [])

  def parse_frames(%{version: 4} = tag, frames_data, frames) do
    # A tag must have at least one frame, a frame must have at least one byte
    # in it after the header
    <<id::binary-size(4), frame_size::binary-size(4), flags::binary-size(2), frames_data::binary>> =
      frames_data

    decoded_frame_size = Utils.decode_synchsafe_integer(frame_size)

    {frame_data, frames_data} =
      case frames_data do
        <<frame_data::binary-size(decoded_frame_size)>> -> {frame_data, <<>>}
        <<frame_data::binary-size(decoded_frame_size), rest::binary>> -> {frame_data, rest}
      end

    flags = parse_frame_flags(flags, tag)

    frame = parse_frame(tag, id, decoded_frame_size, flags, frame_data)
    frames = [frame | frames]

    # Does it contain enough data for another frame?
    if byte_size(frames_data) > 10 do
      parse_frames(tag, frames_data, frames)
    else
      Enum.reverse(frames)
    end
  end

  def parse_frames(%{version: 3} = tag, frames_data, frames) do
    # A tag must have at least one frame, a frame must have at least one byte
    # in it after the header
    <<id::binary-size(4), frame_size::binary-size(4), flags::binary-size(2), frames_data::binary>> =
      frames_data

    frame_size = :binary.decode_unsigned(frame_size, :big)

    {frames_data, frames} =
      cond do
        not Regex.match?(~r/[A-Z0-9]{4}/, id) ->
          Logger.warn("Invalid frame ID. Weird.")
          {frames_data, frames, false}

        byte_size(frames_data) < frame_size ->
          Logger.warn("Frame data is less than parsed size field. Weird.")
          {frames_data, frames, false}

        true ->
          {frame_data, frames_data} =
            case frames_data do
              <<frame_data::binary-size(frame_size)>> -> {frame_data, <<>>}
              <<frame_data::binary-size(frame_size), rest::binary>> -> {frame_data, rest}
            end

          flags = parse_frame_flags(flags, tag)

          frame = parse_frame(tag, id, frame_size, flags, frame_data)
          frames = [frame | frames]
          {frames_data, frames}
      end

    # Does it contain enough data for another frame?
    if byte_size(frames_data) > 10 do
      parse_frames(tag, frames_data, frames)
    else
      Enum.reverse(frames)
    end
  end

  defp parse_frame(%{version: 3} = tag, id, size, flags, data) do
    {gi, data} =
      if flags.grouping_identity do
        <<gi::8, data::binary>> = data
        {gi, data}
      else
        {nil, data}
      end

    frame = Frame.parse(id, tag, flags, data)

    %{
      frame
      | size: size,
        flags: flags,
        label: Labels.from_id(frame.id),
        raw_data: data,
        grouping_identity: gi
    }
  end

  defp parse_frame(%Tag{version: 4} = tag, id, size, flags, data) do
    data =
      if flags.unsynchronisation do
        Utils.decode_unsynchronized(data)
      else
        data
      end

    frame = Frame.parse(id, tag, flags, data)
    %{frame | size: size, flags: flags, raw_data: data}
  end

  defp parse_frame_flags(flags, %{version: 4}) do
    <<0::1, tap::1, fap::1, ro::1, 0::4, gi::1, 0::2, c::1, e::1, u::1, dli::1>> = flags

    %FrameFlags{
      tag_alter_preservation: tap == 1,
      file_alter_preservation: fap == 1,
      read_only: ro == 1,
      grouping_identity: gi == 1,
      compression: c == 1,
      encryption: e == 1,
      unsynchronisation: u == 1,
      data_length_indicator: dli == 1
    }
  end

  defp parse_frame_flags(flags, %{version: 3}) do
    <<tap::1, fap::1, ro::1, 0::5, c::1, e::1, gi::1, 0::5>> = flags

    %FrameFlags{
      tag_alter_preservation: tap == 1,
      file_alter_preservation: fap == 1,
      read_only: ro == 1,
      compression: c == 1,
      encryption: e == 1,
      grouping_identity: gi == 1
    }
  end

  defp get_null_byte(encoding) do
    case encoding do
      :iso8859_1 ->
        <<0>>

      :utf16 ->
        <<0, 0>>
    end
  end

  defp skip_leading_null(data) do
    case data do
      <<0x00, data::binary>> -> skip_leading_null(data)
      data -> data
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

  def decode_string(:iso8859_1, data) do
    decode_string(:latin1, data)
  end

  def decode_string(:utf16be, data) do
    decode_string({:utf16, :big}, data)
  end

  def decode_string(_encoding, data) do
    {found_encoding, _bom_size} = :unicode.bom_to_encoding(data)
    bom = :unicode.encoding_to_bom(found_encoding)

    data =
      if byte_size(bom) > 0 do
        [_ | data] = :binary.split(data, bom)
        data
      else
        data
      end

    :unicode.characters_to_binary(data, found_encoding, :utf8)
  end

  def encode_string(:utf16be, data) do
    encode_string({:utf16, :big}, data, skip_bom: true)
  end

  def encode_string(:utf16, data) do
    encode_string({:utf16, :big}, data)
  end

  def encode_string(:iso8859_1, data) do
    encode_string(:latin1, data)
  end

  def encode_string(to_encoding, data, opts \\ []) do
    # Elixir default string is UTF-8
    current_encoding = :utf8

    if opts[:skip_bom] == true do
      :unicode.characters_to_binary(data, current_encoding, to_encoding)
    else
      bom = :unicode.encoding_to_bom(to_encoding)
      bom <> :unicode.characters_to_binary(data, current_encoding, to_encoding)
    end
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
