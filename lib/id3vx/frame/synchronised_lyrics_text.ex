defmodule Id3vx.Frame.SynchronisedLyricsText do
  defstruct encoding: :utf16,
            language: nil,
            format: nil,
            content_type: nil,
            content_descriptor: nil

  alias Id3vx.Frame.SynchronisedLyricsText

  @type t :: %SynchronisedLyricsText{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          language: String.t(),
          format: Frame.timestamp_format(),
          content_type: Frame.content_type(),
          content_descriptor: String.t()
        }
end
