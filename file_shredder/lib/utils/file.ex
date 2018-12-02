defmodule Utils.File do

  def size(fpath) do
    %{size: size} = File.stat!(fpath)
    size
  end

  def seek_read(file, start_pos, seg_size) do
    {:ok, _pos} = :file.position(file, start_pos)
    {:ok, content} = :file.read(file, seg_size)
    content
  end

  def seek_write(file, start_pos, content) do
    {:ok, _pos} = :file.position(file, start_pos)
    :file.write(file, content)
  end

  def create(fpath, file_size) do
    case :os.type() do
      {:unix, :linux}  -> System.cmd("fallocate", ["-l", file_size |> Integer.to_string(), fpath])
      {:unix, :darwin} -> System.cmd("mkfile", ["-n", file_size |> Integer.to_string(), fpath])
    end
  end

  def delete(fpath) do
    File.rm!(fpath)
  end

  def create_dir(dirpath) do
    System.cmd("mkdir", [Path.dirname(dirpath)])
  end

  def delete_dir(dirpath) do
    System.cmd("rm", ["-rf", Path.dirname(dirpath)])
  end

  def diff?(fpath1, fpath2) do
    { dif, _ } = System.cmd("diff", [fpath1, fpath2])
    dif != ""
  end

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

  def parse_keyfile(fpath) do
    File.read!(fpath) |> String.trim()
  end

  def gen_frag_path(seq_hash, dirpath) do
    form_dirpath(dirpath) <> Base.encode16(seq_hash) <> ".frg"
  end

end