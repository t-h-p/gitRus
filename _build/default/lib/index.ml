open Bitstring
open Git_object
let index_bits = bitstring_of_file "./.git/index"
(* Only Version 2 index entries for the time being *)
let parse_entries_v2 entries entry_num l n =
  if n = entry_num then l else match%bitstring entries with
  | {| _ : 32*6 : bitstring ;
       mode : 32 : bind (
         match mode with
         | 2179792896 -> 100755
         | 2175008768 -> 100644
         | 2684354560 -> 120000
       ) |} -> raise (Failure "todo")

(* todo : Add Version sensitive checking for 2 3 or 4. Git now uses Version 4, and it is important that this works on existing .git/index files at some point. *)
let index_items bits =
  match%bitstring bits with
  | {| signature : 4*8 : string ;
       version : 4*8 ;
       entry_num : 4*8 ;
       entries : -1 : bitstring |} -> raise (Failure "todo")
  | {| _ |} -> raise (Failure "Couldn't parse index")