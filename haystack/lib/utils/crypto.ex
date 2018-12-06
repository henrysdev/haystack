defmodule Utils.Crypto do
  @moduledoc """
  Utils.Crypto is a module for providing common cryptographic functions.
  """

  # erlang crypto adapted from: https://stackoverflow.com/a/37660251
  @aes_block_size 32
  @key_size 32
  @zero_iv to_string(:string.chars(0, 16)) #:crypto.strong_rand_bytes(16)

  @doc """
  Returns a PK57 padded binary of the given data to the given block size.
  """
  def pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> to_string(:string.chars(to_add, to_add))
  end

  @doc """
  Returns an unpadded version of a given PK57 padded binary.
  """
  def unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  @doc """
  Returns an encrypted version of the given data in AES-CTR mode using the given key.
  """
  def encrypt(data, key, :aes_ctr) do
    stream_state = :crypto.stream_init(:aes_ctr, key, @zero_iv)
    {_, cipher_text} = :crypto.stream_encrypt(stream_state, data)
    cipher_text
  end
  @doc """
  Returns an encrypted version of the given data in AES-CBC mode using the given key and 
  padded to the given size.
  """
  def encrypt(data, key, :aes_cbc, pad_size \\ @aes_block_size) do
    :crypto.block_encrypt(:aes_cbc, key, @zero_iv, pad(data, pad_size))
  end

  @doc """
  Returns a decrypted version of the given data in AES-CTR mode using the given key.
  """
  def decrypt(data, key, :aes_ctr) do
    stream_state = :crypto.stream_init(:aes_ctr, key, @zero_iv)
    {_, plain_text} = :crypto.stream_decrypt(stream_state, data)
    plain_text
  end
  @doc """
  Returns a decrypted version of the given data in AES-CBC mode using the given key.
  """
  def decrypt(data, key, :aes_cbc) do
    padded = :crypto.block_decrypt(:aes_cbc, key, @zero_iv, data)
    unpad(padded)
  end

  @doc """
  Returns a slice of a SHA256 hash of the given string to serve as a key 
  """
  def gen_key(password) do
    :crypto.hash(:sha256, password) |> String.slice(0..@key_size-1)
  end

  @doc """
  Returns a SHA256 hash of the given data.
  """
  def gen_hash(data) do
    :crypto.hash(:sha256, data)
  end

end