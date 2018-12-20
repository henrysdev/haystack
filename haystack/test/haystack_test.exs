defmodule HaystackTest do
  use ExUnit.Case
  doctest Haystack

  @small_file "debug/in/small_file"
  @small_file_size 200 # 200 bytes

  @medium_file "debug/in/medium_file"
  @medium_file_size 1_073_741_824  # 1 GB

  @large_file "debug/in/large_file"
  @large_file_size 5_737_418_240  # 5 GB

  @frag_dir "debug/out/*.frg"
  @password "pword"

  @out_dir "debug/out/"
  @done_dir "debug/done/"


  setup do
    Utils.File.delete_dir(@frag_dir)
    Utils.File.create_dir(@frag_dir)
    
    # allocate arbitrary test files
    Utils.File.create(@small_file, @small_file_size)
    Utils.File.create(@medium_file, @medium_file_size)
    Utils.File.create(@large_file, @large_file_size)

    test_files = %{
      :small  => @small_file,
      :medium => @medium_file,
      :large  => @large_file,
    }
    {:ok,[
      small_file:  Map.get(test_files, :small),
      medium_file: Map.get(test_files, :medium),
      large_file:  Map.get(test_files, :large),
      frag_dir:    @frag_dir,
    ]}
  end

  defp clean_up(path) do
    Path.wildcard(path)
    |> Enum.each(&File.rm!(&1))
  end


  test "fragment when n < filesize / 2", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = 3
    {:ok, fragments} = Haystack.fragment(file_name, n, @password, @out_dir)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble when n < filesize / 2", context do
    file_name = context[:small_file]
    n = 3
    Haystack.fragment(file_name, n, @password, @out_dir, true)
    assert n == Haystack.reassemble(@frag_dir, @password, @done_dir) |> length()
    assert false == Utils.File.diff?(file_name, @done_dir <> Path.basename(file_name))
  end



  test "fragment when n == filesize / 2", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name), 2)
    {:ok, fragments} = Haystack.fragment(file_name, n, @password, @out_dir)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble when n == filesize / 2", context do
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name), 2)
    Haystack.fragment(file_name, n, @password, @out_dir, true)
    assert n == Haystack.reassemble(@frag_dir, @password, @done_dir) |> length()
    assert false == Utils.File.diff?(file_name, @done_dir <> Path.basename(file_name))
  end



  test "fragment when n > filesize / 2", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name),2) + 1
    {:ok, fragments} = Haystack.fragment(file_name, n, @password, @out_dir)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble when n > filesize / 2", context do
    file_name = context[:small_file]
    n = div(Utils.File.size(file_name),2) + 1
    Haystack.fragment(file_name, n, @password, @out_dir, true)
    assert n == Haystack.reassemble(@frag_dir, @password, @done_dir) |> length()
    assert false == Utils.File.diff?(file_name, @done_dir <> Path.basename(file_name))
  end



  test "fragment when n == filesize", context do
    clean_up(@frag_dir) 
    file_name = context[:small_file]
    n = Utils.File.size(file_name)
    {:ok, fragments} = Haystack.fragment(file_name, n, @password, @out_dir)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble when n == filesize", context do
    file_name = context[:small_file]
    n = Utils.File.size(file_name)
    Haystack.fragment(file_name, n, @password, @out_dir, true)
    assert n == Haystack.reassemble(@frag_dir, @password, @done_dir) |> length()
    assert false == Utils.File.diff?(file_name, @done_dir <> Path.basename(file_name))
  end



  test "fragment when n > filesize", context do
    clean_up(@frag_dir)
    file_name = context[:small_file]
    n = Utils.File.size(file_name) + 1
    {:ok, fragments} = Haystack.fragment(file_name, n, @password, @out_dir)
    assert n == length(fragments)
    clean_up(@frag_dir)
  end
  test "reassemble when n > filesize", context do
    file_name = context[:small_file]
    n = Utils.File.size(file_name) + 1
    Haystack.fragment(file_name, n, @password, @out_dir, true)
    assert n == Haystack.reassemble(@frag_dir, @password, @done_dir) |> length()
    assert false == Utils.File.diff?(file_name, @done_dir <> Path.basename(file_name))
  end



  test "fragment when n < 2", context do
    clean_up(@frag_dir)
    file_name = context[:medium_file]
    n = 1
    assert :error == Haystack.fragment(file_name, n, @password, @out_dir)
    clean_up(@frag_dir)
  end

end
