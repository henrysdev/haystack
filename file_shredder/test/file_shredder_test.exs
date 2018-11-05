defmodule FileShredderTest do
  use ExUnit.Case
  doctest FileShredder

  stale_files = Path.wildcard("debug/out/*.json")
  if length(stale_files) > 0 do
    stale_files
    |> Enum.each(&File.rm!(&1))
  end

  setup context do
    {:ok, [small_file: "debug/in/abc.txt"]}
  end

  defp clean_up(fragments) do
    fragments
    |> Enum.each(&File.rm!(&1))
  end

  test "fragment small file where n < filesize / 2", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 2, "pword")
    assert length(fragments) == 2
    clean_up(fragments)
  end

  test "reassemble small file where n < filesize / 2", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 2, "pword")
    assert {{:ok, "abc.txt"}, 2} = {FileShredder.reassemble("debug/out/*.json", "pword"), length(fragments)}
    clean_up(fragments)
  end



  test "fragment small file where n == filesize / 2", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 13, "pword")
    assert length(fragments) == 13
    clean_up(fragments)
  end

  test "reassemble small file where n == filesize / 2", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 13, "pword")
    assert {{:ok, "abc.txt"}, 13} = {FileShredder.reassemble("debug/out/*.json", "pword"), length(fragments)}
    clean_up(fragments)
  end



  test "fragment small file where n > filesize / 2", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 14, "pword")
    assert length(fragments) == 14
    clean_up(fragments)
  end

  test "reassemble small file where n > filesize / 2", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 14, "pword")
    assert {{:ok, "abc.txt"}, 14} = {FileShredder.reassemble("debug/out/*.json", "pword"), length(fragments)}
    clean_up(fragments)
  end



  test "fragment small file where n == filesize", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 26, "pword")
    assert length(fragments) == 26
    clean_up(fragments)
  end

  test "reassemble small file where n == filesize", context do
    {:ok, fragments} = FileShredder.fragment(context[:small_file], 26, "pword")
    assert {{:ok, "abc.txt"}, 26} = {FileShredder.reassemble("debug/out/*.json", "pword"), length(fragments)}
    clean_up(fragments)
  end



  test "fragment with n = 0", context do
    assert :error == FileShredder.fragment(context[:small_file], 0, "pword")
  end

  test "fragment with n = 1", context do
    assert :error == FileShredder.fragment(context[:small_file], 1, "pword")
  end

  test "fragment with n < 0", context do
    assert :error == FileShredder.fragment(context[:small_file], -3, "pword")
  end

  test "fragment with where n > filesize", context do
    assert :error == FileShredder.fragment(context[:small_file], 27, "pword")
  end

end
