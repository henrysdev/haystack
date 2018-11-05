defmodule Utils.Protobuf do
    use Protobuf, """
    message Fragment {
      required bytes payload = 0;
      required bytes pad_amt = 0;
      required bytes file_name = 0;
      required bytes file_size = 0;
      required bytes seq_hash = 0;
      required bytes hmac = 0;
    }
  """
end