defmodule Id3vx.Frame.RelativeVolumeAdjustment do
  defstruct channel: nil,
            volume_adjustment: nil,
            peak: nil,
            volume: nil

  alias Id3vx.Frame.RelativeVolumeAdjustment

  @type t :: %RelativeVolumeAdjustment{
          channel: binary(),
          volume_adjustment: binary(),
          peak: binary(),
          volume: binary()
        }
end
