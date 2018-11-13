defmodule FileShredderTest do
  use ExUnit.Case
  doctest FileShredder

  @small_file  "debug/in/small_file"
  @small_size  26 # 100 bytes

  @medium_file "debug/in/medium_file"
  @medium_size 1073741824 # 1 GB

  @large_file  "debug/in/large_file"
  @large_size  1073741824 * 5 # 5 GB

  @frag_dir "debug/out/*.frg"


  stale_files = Path.wildcard("debug/out/*.frg")
  if length(stale_files) > 0 do
    stale_files
    |> Enum.each(&File.rm!(&1))
  end

  setup context do
    Utils.File.create(@small_file,  @small_size)
    Utils.File.create(@medium_file, @medium_size)
    Utils.File.create(@large_file,  @large_size)

    file_types = %{
      :small  => @small_file,
      :medium => @medium_file,
      :large  => @large_file,
    }
    {:ok,[
      file_type: Map.get(file_types, :small),
      frag_dir: @frag_dir
    ]}
  end

  defp clean_up(fragments) do
    fragments
    |> Enum.each(&File.rm!(&1))
  end

  defp bound_n(n) when n > 50 do
    50
  end
  defp bound_n(n), do: n

  test "fragment DEBUG_FILE where n < filesize / 2", context do
    file_name = context[:file_type]
    n = div(Utils.File.size(file_name), 2) - 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n < filesize / 2", context do
    file_name = context[:file_type]
    n = div(Utils.File.size(file_name), 2) - 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    fname = Path.basename(file_name)
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n == filesize / 2", context do
    file_name = context[:file_type]
    n = div(Utils.File.size(file_name), 2)
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n == filesize / 2", context do
    file_name = context[:file_type]
    n = div(Utils.File.size(file_name),2)
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    fname = Path.basename(file_name)
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n > filesize / 2", context do
    file_name = context[:file_type]
    n = div(Utils.File.size(file_name),2) + 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n > filesize / 2", context do
    file_name = context[:file_type]
    n = div(Utils.File.size(file_name),2) + 1
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    fname = Path.basename(file_name)
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n == filesize", context do
    file_name = context[:file_type]
    n = Utils.File.size(file_name)
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    assert length(fragments) == n
    clean_up(fragments)
  end

  test "reassemble DEBUG_FILE where n == filesize", context do
    file_name = context[:file_type]
    n = Utils.File.size(file_name)
    |> bound_n()
    {:ok, fragments} = FileShredder.fragment(file_name, n, "pword")
    fname = Path.basename(file_name)
    assert {{:ok, fname}, n} = {FileShredder.reassemble(context[:frag_dir], "pword"), length(fragments)}
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment with n = 0", context do
    file_name = context[:file_type]
    assert :error == FileShredder.fragment(file_name, 0, "pword")
  end

  test "fragment with n = 1", context do
    file_name = context[:file_type]
    assert :error == FileShredder.fragment(file_name, 1, "pword")
  end

  test "fragment with n < 0", context do
    file_name = context[:file_type]
    assert :error == FileShredder.fragment(file_name, -3, "pword")
  end

end
