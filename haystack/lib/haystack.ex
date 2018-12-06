defmodule Haystack do
  @moduledoc """
  Haystack is a top-level API module for the application's two primary functions 
  of fragmentation and reassembly.
  """

  @doc """
  Fragments a file into a collection of fragment files.

  ## Examples

      #iex> Haystack.fragment("path/to/secret_file", 20, "secretword", "destination/for/fragment_files/")

  """
  defdelegate fragment(filepath, n, password, outdir, save_orig \\ false), to: Haystack.Fragmentor

  @doc """
  Reassembles a file from a collection of fragments files.
  ## Examples

      #iex> Haystack.reassemble("path/to/fragment_files/", "secretword", "destination/for/reassembled_file/")

  """
  defdelegate reassemble(dirpath, password, outdir), to: Haystack.Reassembler

end
