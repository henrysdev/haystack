# Haystack

Haystack is a small command-line utility for splitting up sensitive files into a user-determined number of indistinguishble, cryptographically secure fragments.

## Installation
After cloning this repository, navigate to the top level of the project directory and run the following commands. 
```elixir
mix escript.build
``` 
```elixir
mix escript.install
```

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
* ```--save_orig | -s```  
&nbsp;&nbsp;Optional flag to prevent deletion of original file upon fragmentation.
  
#### Examples
Output 20 fragments and use a password prompt for encryption.
```
./safe_split fragment --in path/to/original_file --count 20 --out path/to/fragments_dir/
```
Output 20 fragments, use a keyfile for encryption, and keep original file.
```
./safe_split fragment --in path/to/original_file --count 20 --keyfile path/to/keyfile --out path/to/fragments_dir/ --save_orig
```
  
### Reassembly
* ```--in | -i```  
&nbsp;&nbsp;Path to the input directory containing all the fragment files.
* ```--keyfile | -k```  
&nbsp;&nbsp;Path to a file containing the plaintext password to be used for encryption/decryption.
* ```--out | -o```  
&nbsp;&nbsp;Path to the output location where the original file will be reassembled.

#### Examples
Reassemble using a password prompt for decryption.
```
./safe_split reassemble --in path/to/fragments_dir/ --out path/to/reassembly_dir/
```
Reassemble using a keyfile for decryption.
```
./safe_split reassemble --in path/to/fragments_dir/ --keyfile path/to/keyfile --out path/to/reassembly_dir/
