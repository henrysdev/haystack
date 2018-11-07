defmodule FileShredderTest do
  use ExUnit.Case
  doctest FileShredder

  stale_files = Path.wildcard("debug/out/*.frg")
  if length(stale_files) > 0 do
    stale_files
    |> Enum.each(&File.rm!(&1))
  end

  setup context do
    file_types = %{
      :small  => "debug/in/abc.txt",
      :medium => "debug/in/4kbees.mp4",
      :large  => "debug/in/large_file"
    }
    {:ok,[
      file_type: Map.get(file_types, :medium),
      frag_dir: "debug/out/*.frg"
    ]}
  end

  defp clean_up(fragments) do
    fragments
    |> Enum.each(&File.rm!(&1))
  end

  defp bound_n(n) when n > 50 do
    50
  end

  test "fragment DEBUG_FILE where n < filesize / 2", context do
    n = div(Utils.File.size(context[:file_type]), 2) - 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n < filesize / 2", context do
    n = div(Utils.File.size(context[:file_type]), 2) - 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    fname = Path.basename(context[:file_type])
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
  end



  test "fragment DEBUG_FILE where n == filesize / 2", context do
    n = div(Utils.File.size(context[:file_type]), 2)
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n == filesize / 2", context do
    n = div(Utils.File.size(context[:file_type]),2)
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    fname = Path.basename(context[:file_type])
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
  end



  test "fragment DEBUG_FILE where n > filesize / 2", context do
    n = div(Utils.File.size(context[:file_type]),2) + 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n > filesize / 2", context do
    n = div(Utils.File.size(context[:file_type]),2) + 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    fname = Path.basename(context[:file_type])
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
  end



  test "fragment DEBUG_FILE where n == filesize", context do
    n = Utils.File.size(context[:file_type])
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n == filesize", context do
    n = Utils.File.size(context[:file_type])
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(context[:file_type], n, "pword")
    fname = Path.basename(context[:file_type])
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
  end



  test "fragment with n = 0", context do
    assert :error == FileShredder.fragment(context[:file_type], 0, "pword")
  end

  test "fragment with n = 1", context do
    assert :error == FileShredder.fragment(context[:file_type], 1, "pword")
  end

  test "fragment with n < 0", context do
    assert :error == FileShredder.fragment(context[:file_type], -3, "pword")
  end

  test "fragment with where n > filesize", context do
    n = Utils.File.size(context[:file_type]) + 1
    |> bound_n()
    assert :error == FileShredder.fragment(context[:file_type], n, "pword")
  end

end
