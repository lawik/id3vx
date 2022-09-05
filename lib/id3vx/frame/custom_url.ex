defmodule Id3vx.Frame.CustomURL do
  @moduledoc """
  WXXX frame struct.
  """

  # Encoding defaults to iso8859_1 as Overcast (podcast player)
  # does not seem to handle utf16 for this particular frame.
  defstruct encoding: :iso8859_1, description: nil, url: nil

  alias Id3vx.Frame
  alias Id3vx.Frame.CustomURL

  @type t :: %CustomURL{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          description: String.t(),
          url: String.t()
        }

  def new(description, url) do
    %CustomURL{
      description: description,
      url: url
    }
  end
end
