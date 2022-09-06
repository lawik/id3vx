defmodule Id3vx.BinaryUtils do
  def step_compare(a, b, result \\ %{})

  def step_compare(<<>>, <<>>, r) do
    Map.put(r, :same_size?, true)
  end

  def step_compare(<<>>, b, r) do
    Map.merge(r, %{
      same_size?: false,
      remainder_b: byte_size(b)
    })
  end

  def step_compare(a, <<>>, r) do
    Map.merge(r, %{
      same_size?: false,
      remainder_a: byte_size(a)
    })
  end

  def step_compare(<<byte_a::8, a::binary>>, <<byte_b, b::binary>>, r) do
    steps = Map.get(r, :steps, [])
    steps = [steps, [byte_a, byte_b]]

    r =
      if byte_a != byte_b do
        offset = IO.iodata_length(steps)
        diffs = Map.get(r, :diffs, [])
        diffs = [diffs, [<<offset::32>>, byte_a, byte_b]]
        diff_count = IO.iodata_length(diffs) / 3

        Map.merge(r, %{
          steps: steps,
          diffs: diffs,
          diff_count: diff_count
        })
      else
        diff_count = Map.get(r, :diff_count, 0)
        diffs = Map.get(r, :diffs, [])

        Map.merge(r, %{
          steps: steps,
          diffs: diffs,
          diff_count: diff_count
        })
      end

    step_compare(a, b, r)
  end

  def print_compared(result) do
    IO.inspect(Map.take(result, [:same_size?, :remainder_a, :remainder_b, :diff_count]))

    steps =
      result.steps
      |> IO.iodata_to_binary()
      |> steps_to_io()

    diffs =
      result.diffs
      |> IO.iodata_to_binary()
      |> diffs_to_io()

    File.write!("/tmp/diffs.txt", diffs)
    File.write!("/tmp/steps.txt", steps)
  end

  defp steps_to_io(steps, str \\ []) do
    case steps do
      <<a::8, b::8, rest::binary>> -> steps_to_io(rest, [str, inspect(a), ", ", inspect(b), "\n"])
      <<>> -> str
    end
  end

  defp diffs_to_io(steps, str \\ []) do
    case steps do
      <<offset::32, a::8, b::8, rest::binary>> ->
        diffs_to_io(rest, [
          str,
          inspect(round(offset / 2)),
          ": ",
          inspect(a),
          ",",
          inspect(b),
          "\n"
        ])

      <<>> ->
        str
    end
  end
end
