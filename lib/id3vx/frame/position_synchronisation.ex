defmodule Id3vx.Frame.PositionSynchronisation do
  defstruct timestamp_format: nil,
            position: nil

  alias Id3vx.Frame.PositionSynchronisation

  @type t :: %PositionSynchronisation{
          timestamp_format: Frame.timestamp_format(),
          position: binary()
        }
end
