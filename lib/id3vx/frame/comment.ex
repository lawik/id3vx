defmodule Id3vx.Frame.Comment do
  @moduledoc """
  COMM frame struct.
  """

  defstruct encoding: :utf16,
            language: nil,
            content_description: nil,
            content_text: nil

  alias Id3vx.Frame
  alias Id3vx.Frame.Comment

  @type t :: %Comment{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          language: String.t(),
          content_description: String.t(),
          content_text: String.t()
        }
end
