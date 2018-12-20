# Haystack

Haystack is a command-line utility for breaking up sensitive files into user-determined quantities of indistinguishble, cryptographically secure fragments.

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
&nbsp;&nbsp;Path to the input file to be fragmented.
* ```--count | -c```  
&nbsp;&nbsp;Number of fragments to split the file into during fragmentation.
* ```--keyfile | -k```  
&nbsp;&nbsp;Path to a file containing the plaintext password to be used for encryption/decryption.
* ```--out | -o```  
&nbsp;&nbsp;Path to the output directory where fragments will be written out to.
* ```--save_orig | -s```  
&nbsp;&nbsp;(Optional) flag to prevent deletion of original file upon fragmentation.
  
#### Examples
Split file into 100 fragments (you will be prompted for an encryption password).
```
haystack fragment --in path/to/orig_file --count 100 --out path/to/frags_dir/
```
Split file into 100 fragments, read encryption password from a keyfile, and don't delete original file.
```
haystack fragment -i path/to/orig_file -c 100 -o path/to/frags_dir/ --keyfile path/to/keyfile --save_orig
```
  
### Reassembly
* ```--in | -i```  
&nbsp;&nbsp;Path to the input directory containing all fragment files.
* ```--keyfile | -k```  
&nbsp;&nbsp;Path to a file containing the plaintext password to be used for encryption/decryption.
* ```--out | -o```  
&nbsp;&nbsp;Path to the output location where the original file will be reassembled.

#### Examples
Reassemble original file using a password prompt for decryption.
```
haystack reassemble --in path/to/frags_dir/ --out path/to/reassem_dir/
```
Reassemble original file using a keyfile for decryption.
```
haystack reassemble --in path/to/frags_dir/ --keyfile path/to/keyfile --out path/to/reassem_dir/
