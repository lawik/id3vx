defmodule Id3vx.Frame.AttachedPicture do
  @moduledoc """
  APIC frame struct.
  """

  defstruct encoding: :utf16,
            mime_type: nil,
            picture_type: :other,
            description: nil,
            image_data: nil

  alias Id3vx.Frame
  alias Id3vx.Frame.AttachedPicture

  @type t :: %AttachedPicture{
          encoding: Frame.text_encoding_v3() | Frame.text_encoding_v4(),
          mime_type: String.t(),
          picture_type: Frame.picture_type(),
          description: String.t(),
          image_data: binary()
        }
end
