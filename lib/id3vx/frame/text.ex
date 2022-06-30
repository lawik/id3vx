defmodule Id3vx.Frame.Text do
  @moduledoc """
  Text frame structs, all T??? frames.
  """

  defstruct encoding: :utf16, text: []

  alias Id3vx.Frame
  alias Id3vx.Frame.Text

  @type t :: %Text{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          text: String.t() | [String.t()]
        }
end
