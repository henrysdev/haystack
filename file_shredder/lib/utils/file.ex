defmodule Utils.File do

  def size(fpath) do
    %{size: size} = File.stat!(fpath)
    size
  end

  def read(fpath) do
    File.open!(fpath, [:read, :binary])
  end

end