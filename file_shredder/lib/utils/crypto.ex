defmodule Utils.Crypto do

  # erlang crypto adapted from: https://stackoverflow.com/a/37660251
  @aes_block_size 32
  @key_size 32
  @zero_iv to_string(:string.chars(0, 16)) #:crypto.strong_rand_bytes(16)

  def pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> to_string(:string.chars(to_add, to_add))
  end

  def unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  def encode_and_trim(data, desired_len) do
    data
    |> Base.encode32(padding: false)
    |> String.slice(0..desired_len - 1)
  end

  def encrypt(data, key, :aes_ctr) do
    stream_state = :crypto.stream_init(:aes_ctr, key, @zero_iv)
    {_, cipher_text} = :crypto.stream_encrypt(stream_state, data)
    cipher_text
  end
  def encrypt(data, key, :aes_cbc, pad_size) do
    :crypto.block_encrypt(:aes_cbc, key, @zero_iv, pad(data, pad_size))
  end

  def decrypt(data, key, :aes_ctr) do
    stream_state = :crypto.stream_init(:aes_ctr, key, @zero_iv)
    {_, plain_text} = :crypto.stream_decrypt(stream_state, data)
    plain_text
  end
  def decrypt(data, key, :aes_cbc) do
    padded = :crypto.block_decrypt(:aes_cbc, key, @zero_iv, data)
    unpad(padded)
  end

  def gen_key(password) do
    :crypto.hash(:sha256, password) |> String.slice(0..@key_size-1)
  end

  def gen_hash(data) do
    :crypto.hash(:sha256, data)
  end

end