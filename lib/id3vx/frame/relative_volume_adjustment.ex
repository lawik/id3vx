defmodule Id3vx.Frame.RelativeVolumeAdjustment do
  defstruct identification: nil,
            channel: nil,
            volume_adjustment: nil,
            peak: nil,
            volume: nil

  alias Id3vx.Frame.RelativeVolumeAdjustment

  @type t :: %RelativeVolumeAdjustment{
          identification: String.t(),
          channel: binary(),
          volume_adjustment: binary(),
          peak: binary(),
          volume: binary()
        }
end
