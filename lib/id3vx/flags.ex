defmodule Id3vx.Flags do
  defmacro __using__(_) do
    quote do
      def b(true), do: 1
      def b(_), do: 0
    end
  end
end
