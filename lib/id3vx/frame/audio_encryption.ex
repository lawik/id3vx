defmodule Id3vx.Frame.AudioEncryption do
  defstruct owner_identifier: nil,
            preview_start: nil,
            preview_length: nil,
            encryption_info: nil

  alias Id3vx.Frame.AudioEncryption

  @type t :: %AudioEncryption{
          owner_identifier: String.t(),
          preview_start: binary(),
          preview_length: binary(),
          encryption_info: binary()
        }
end
