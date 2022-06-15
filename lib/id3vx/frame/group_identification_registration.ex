defmodule Id3vx.Frame.GroupIdentificationRegistration do
  defstruct owner_identifier: nil,
            symbol: nil,
            group_dependent_data: nil

  alias Id3vx.Frame.GroupIdentificationRegistration

  @type t :: %GroupIdentificationRegistration{
          owner_identifier: String.t(),
          symbol: integer(),
          group_dependent_data: binary()
        }
end
