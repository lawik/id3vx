defmodule Id3vx.Frame.CustomURL do
  defstruct encoding: :utf16, description: nil, url: nil

  alias Id3vx.Frame
  alias Id3vx.Frame.CustomURL

  @type t :: %CustomURL{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          description: String.t(),
          url: String.t()
        }
end
