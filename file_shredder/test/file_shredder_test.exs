defmodule FileShredderTest do
  use ExUnit.Case
  doctest FileShredder

  @small_file "debug/in/small_file"
  @small_file_size 50 # 50 bytes

  @medium_file "debug/in/medium_file"
  @medium_file_size 1_073_741_824  # 1 GB

  @frag_dir  "debug/out/*.frg"
  @password "pword"


  setup context do

    # allocate dummy files
    #Utils.File.create(@small_file, @small_file_size)
    Utils.File.create(@medium_file, @medium_file_size)

    test_files = %{
      :small   => @small_file,
      :medium  => @medium_file,
    }
    {:ok,[
      medium_file: Map.get(test_files, :medium),
      small_file: Map.get(test_files, :small),
      frag_dir: @frag_dir,
    ]}
  end

  defp clean_up(path) do
    Path.wildcard(path)
    |> Enum.each(&File.rm!(&1))
  end

  defp count_files(path) do
    Path.wildcard(path) |> length()
  end



  test "fragment DEBUG_FILE where n < filesize / 2", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = 3
    {:ok, fragments} = FileShredder.fragment(file_name, n, @password)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble DEBUG_FILE where n < filesize / 2", context do
    file_name = context[:small_file]
    n = 3
    FileShredder.fragment(file_name, n, @password)
    assert n == FileShredder.reassemble(@frag_dir, @password) |> length()
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n == filesize / 2", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name), 2)
    {:ok, fragments} = FileShredder.fragment(file_name, n, @password)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble DEBUG_FILE where n == filesize / 2", context do
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name), 2)
    FileShredder.fragment(file_name, n, @password)
    assert n == FileShredder.reassemble(@frag_dir, @password) |> length()
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n > filesize / 2", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name),2) + 1
    {:ok, fragments} = FileShredder.fragment(file_name, n, @password)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble DEBUG_FILE where n > filesize / 2", context do
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name),2) + 1
    FileShredder.fragment(file_name, n, @password)
    assert n == FileShredder.reassemble(@frag_dir, @password) |> length()
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n == filesize", context do
    clean_up(@frag_dir) 
    file_name = context[:small_file]
    n = Utils.File.size(file_name)
    {:ok, fragments} = FileShredder.fragment(file_name, n, @password)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble DEBUG_FILE where n == filesize", context do
    file_name = context[:small_file]
    n = Utils.File.size(file_name)
    FileShredder.fragment(file_name, n, @password)
    assert n == FileShredder.reassemble(@frag_dir, @password) |> length()
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment DEBUG_FILE where n > filesize", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = Utils.File.size(file_name) + 1
    {:ok, fragments} = FileShredder.fragment(file_name, n, @password)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble DEBUG_FILE where  n > filesize", context do
    file_name = context[:small_file]
    n = Utils.File.size(file_name) + 1
    FileShredder.fragment(file_name, n, @password)
    assert n == FileShredder.reassemble(@frag_dir, @password) |> length()
    assert false == Utils.File.diff?(file_name, Path.basename(file_name))
  end



  test "fragment with n < 2", context do
    clean_up(@frag_dir)
    file_name = context[:medium_file]
    n = 1
    assert :error == FileShredder.fragment(file_name, n, @password)
    clean_up(@frag_dir)
  end

end
