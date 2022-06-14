defmodule Id3vx.Frame.SynchronisedTempoCodes do
  defstruct timestamp_format: nil, tempo_data: nil

  alias Id3vx.Frame.SynchronisedTempoCodes

  @type t :: %SynchronisedTempoCodes{
          timestamp_format: Frame.timestamp_format(),
          tempo_data: binary()
        }
end
