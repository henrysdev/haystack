defmodule FileShredder.CryptoUtils do
    
    # These will need to be in a module of course
    def pad(data, block_size) do
      to_add = block_size - rem(byte_size(data), block_size)
      data <> to_string(:string.chars(to_add, to_add))
    end

    def unpad(data) do
      to_remove = :binary.last(data)
      :binary.part(data, 0, byte_size(data) - to_remove)
    end

    # BAD, don't do this!
    # This is just to reproduce your code, where you are not using 
    # an initialisation vector.
    @zero_iv to_string(:string.chars(0, 16))
    @aes_block_size 16

    def encrypt(data, key) do
      :crypto.block_encrypt(:aes_cbc128, key, @zero_iv, pad(data, @aes_block_size))
      data
    end

    def decrypt(data, key) do
      padded = :crypto.block_decrypt(:aes_cbc128, key, @zero_iv, data)
      unpad(padded)
    end

    def gen_key(password) do
      password
    end

    def gen_hmac(password, seq_id) do
      "_"
    end

end