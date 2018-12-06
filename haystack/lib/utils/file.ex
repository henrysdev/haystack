defmodule Utils.File do
  @moduledoc """
  Utils.File is a module for providing common file-system related utilities.
  """

  @doc """
  Returns the size (in bytes) of a file by its path.
  """
  def size(fpath) do
    %{size: size} = File.stat!(fpath)
    size
  end

  @doc """
  Returns a segment of a given size (in bytes) from an open file starting from a 
  given position in the file.
  """
  def seek_read(file, start_pos, seg_size) do
    {:ok, _pos} = :file.position(file, start_pos)
    {:ok, content} = :file.read(file, seg_size)
    content
  end

  @doc """
  Writes a given chunk of data to an open file at a given position.
  """
  def seek_write(file, start_pos, content) do
    {:ok, _pos} = :file.position(file, start_pos)
    :file.write(file, content)
  end

  @doc """
  Creates an arbitrary file of the given size (in bytes) on disk.
  """
  def create(fpath, file_size) do
    case :os.type() do
      {:unix, :linux}  -> System.cmd("fallocate", ["-l", file_size |> Integer.to_string(), fpath])
      {:unix, :darwin} -> System.cmd("mkfile", ["-n", file_size |> Integer.to_string(), fpath])
    end
  end

  @doc """
  Deletes a file at the given path
  """
  def delete(fpath) do
    File.rm!(fpath)
  end

  @doc """
  Creates a directory at the given path
  """
  def create_dir(dirpath) do
    System.cmd("mkdir", [Path.dirname(dirpath)])
  end

  @doc """
  Deletes the directory at the given path
  """
  def delete_dir(dirpath) do
    System.cmd("rm", ["-rf", Path.dirname(dirpath)])
  end

  @doc """
  Returns a boolean pertaining to if the content of the two files at the given 
  filepaths are identical.
  """
  def diff?(fpath1, fpath2) do
    { dif, _ } = System.cmd("diff", [fpath1, fpath2])
    dif != ""
  end

  @doc """
  Returns the correct directory path string for a given path string
  """
  def form_dirpath(path) do
    # no way to pattern match the end of a string in Elixir
    # https://stackoverflow.com/questions/32448423/pattern-match-on-end-of-a-string-binary-argument#comment52766593_32451767

    # alternative to nested condition blocks
    dpath = fn {true, _}      -> path
               {false, true}  -> path <> "/"
               {false, false} -> Path.dirname(path) <> "/"
            end

    {String.ends_with?(path, "/"), File.dir?(path)}
    |> dpath.()
  end

  @doc """
  Returns the contents of a keyfile at the given path without any 
  trailing whitespace.
  """
  def parse_keyfile(fpath) do
    File.read!(fpath) |> String.trim()
  end

  @doc """
  Returns the generated path to a fragment file from a given sequence hash and 
  directory path.
  """
  def gen_frag_path(seq_hash, dirpath) do
    form_dirpath(dirpath) <> Base.encode16(seq_hash) <> ".frg"
  end

end