defmodule Utils.File do

  def size(fpath) do
    %{size: size} = File.stat!(fpath)
    size
  end

  def read(fpath) do
    File.open!(fpath, [:read, :binary])
  end

  def write(fpath, content) do
    { :ok, file } = File.open(fpath, [:write])
    IO.binwrite file, content
    File.close file
  end

  def seek_read(file, start_pos, seg_size) do
    {:ok, _pos} = :file.position(file, start_pos)
    {:ok, content} = :file.read(file, seg_size)
    content
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

  def clear_dir(dirpath) do
    Path.wildcard(dirpath)
    |> Enum.each(&File.rm!(&1))
  end

  def diff?(fpath1, fpath2) do
    IO.inspect fpath1, label: "fpath1"
    IO.inspect fpath2, label: "fpath2"
    { dif, _ } = System.cmd("diff", [fpath1, fpath2])
    dif != ""
  end

end