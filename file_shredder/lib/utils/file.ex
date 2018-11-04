defmodule Utils.File do

  def size(fpath) do
    %{size: size} = File.stat!(fpath)
    size
  end

  def read(fpath) do
    File.open!(fpath, [:read, :binary])
  end

  def create(file_name, file_size) do
    case :os.type() do
      {:unix, :linux}  -> System.cmd("fallocate", ["-l", file_size |> Integer.to_string(), file_name])
      {:unix, :darwin} -> System.cmd("mkfile", ["-n", file_size |> Integer.to_string(), file_name])
    end
  end

end