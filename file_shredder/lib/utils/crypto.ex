defmodule Utils.Crypto do

  # erlang crypto adapted from: https://stackoverflow.com/a/37660251
  @aes_block_size 16
  @key_size 32
  @zero_iv to_string(:string.chars(0, 16)) # TODO: Implement legitimate init vector!

  def pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> to_string(:string.chars(to_add, to_add))
  end

  def unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end

  def encrypt(data, key) do
    :crypto.block_encrypt(:aes_cbc, key, @zero_iv, pad(data, @aes_block_size))
    #|> Base.encode64
  end

  def decrypt(data, key) do
    #{ :ok, data } = Base.decode64(data)
    padded = :crypto.block_decrypt(:aes_cbc, key, @zero_iv, data)
    unpad(padded)
  end

  def gen_key(password) do
    :crypto.hash(:sha256, password) |> String.slice(0..@key_size-1)
  end

  def gen_multi_hash(parts) do
    :crypto.hash(:sha256, Enum.join(parts))
    |> to_string
    #|> Base.encode64
  end

end