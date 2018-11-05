defmodule Utils.File do

  def size(fpath) do
    %{size: size} = File.stat!(fpath)
    size
  end

  def read(fpath) do
    File.open!(fpath, [:read, :binary])
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
    |> delete()
  end

end