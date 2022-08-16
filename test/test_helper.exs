ExUnit.start()

try do
  System.cmd("id3v2", ["--version"])
  ExUnit.configure(include: [require_id3v2: true])
rescue
  _e in ErlangError -> ExUnit.configure(exclude: [require_id3v2: true])
end
