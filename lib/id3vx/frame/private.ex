defmodule Id3vx.Frame.Private do
  defstruct owner_identifier: nil,
            private_data: nil

  alias Id3vx.Frame.Private

  @type t :: %Private{
          owner_identifier: String.t(),
          private_data: binary()
        }
end
