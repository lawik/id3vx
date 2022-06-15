defmodule Id3vx.Frame.EncryptionMethodRegistration do
  defstruct owner_identifier: nil,
            method_symbol: nil,
            encryption_data: nil

  alias Id3vx.Frame.EncryptionMethodRegistration

  @type t :: %EncryptionMethodRegistration{
          owner_identifier: String.t(),
          method_symbol: integer(),
          encryption_data: binary()
        }
end
