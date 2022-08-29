defmodule Id3vx.Frame.AudioSeekPointIndex do
  defstruct indexed_data_start: nil,
            indexed_data_length: nil,
            number_of_index_points: nil,
            bits_per_index_point: nil

  alias Id3vx.Frame.AudioSeekPointIndex

  @type t :: %AudioSeekPointIndex{
          indexed_data_start: binary(),
          indexed_data_length: binary(),
          number_of_index_points: binary(),
          bits_per_index_point: binary()
        }
end
