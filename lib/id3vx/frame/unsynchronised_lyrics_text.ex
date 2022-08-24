defmodule Id3vx.Frame.UnsynchronisedLyricsText do
  @moduledoc """
  USLT frame struct.
  """
  defstruct encoding: :utf16,
            language: nil,
            content_descriptor: nil,
            lyrics_text: nil

  alias Id3vx.Frame.UnsynchronisedLyricsText

  @type t :: %UnsynchronisedLyricsText{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          language: String.t(),
          content_descriptor: String.t(),
          lyrics_text: String.t()
        }
end
