# SafeSplit

SafeSplit is a commandline utility for fragmenting and reassembling files for 
security purposes.

## Installation
This project can be installed by running the following commands from the top level 
of the project directory  
```
mix escript.build
```  
```
export PATH=$PATH:<path/to/this/directory/safe_split>
```

<!-- ## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `file_shredder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:file_shredder, "~> 0.1.0"}
  ]
end
``` -->

## Usage
### Fragmentation
* ```--in | -i```  
&nbsp;&nbsp;Path to the input file to be fragmented. or the input directory (for reassembly).
* ```--count | -c```  
&nbsp;&nbsp;Number of fragments to split the file into during fragmentation.
* ```--keyfile | -k```  
&nbsp;&nbsp;Path to a file containing the plaintext password to be used for encryption/decryption.
* ```--out | -o```  
&nbsp;&nbsp;Path to the output directory where fragments (for fragmentation) or the original file (for reassembly) will be located.
  
Create 20 fragment files and use a password prompt for encryption.
```
./safe_split fragment --in path/to/original_file --count 20 --out path/to/fragments_dir/
```
Create 20 fragment files and use a keyfile for encryption.
```
./safe_split fragment --in path/to/original_file --count 20 --keyfile path/to/keyfile --out path/to/fragments_dir/
```
  
### Reassembly
* ```--in | -i```  
&nbsp;&nbsp;Path to the input directory containing all the fragment files.
* ```--keyfile | -k```  
&nbsp;&nbsp;Path to a file containing the plaintext password to be used for encryption/decryption.
* ```--out | -o```  
&nbsp;&nbsp;Path to the output location where the original file will be reassembled.
  
Reassemble using a password prompt for decryption.
```
./safe_split reassemble --in path/to/fragments_dir/ --out path/to/reassembly_dir/
```
Reassemble using a keyfile for decryption.
```
./safe_split reassemble --in path/to/fragments_dir/ --keyfile path/to/keyfile --out path/to/reassembly_dir/
```
  
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/file_shredder](https://hexdocs.pm/file_shredder).

