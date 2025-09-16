(*
open Bitstring
open Git_object
let index_bits = bitstring_of_file "./.git/index"

let split_path path =
    let re = Str.regexp (String.make 1 '/') in
    Str.split re path

let name_with_path path =
    let items = (path |> split_path |> List.rev) in
    match items with
    | fst::rest -> (fst,rest)
    | _ -> failwith "Couldn't split path"

(* Only Version 2 index entries for the time being *)
let rec parse_entries_v2 entries entry_num l n =
  if n = entry_num then l else match%bitstring entries with
  | {| _ : 32*6 : bitstring ;
       item_mode : 32 : int ;
       _ : 32*3 : bitstring ;
       item_hash : 160 : bitstring ;
       _ : 4 : bitstring ;
       name_length : 12 : int ;
       full_item_name : name_length : string ;
       rest : -1 : bitstring
    |} ->
      let mode_int =
        match item_mode with
        | 33261l -> 100755 (* Regular, executable file *)
        | 33188l -> 100644 (* Regular, non-executable file *)
        | 40960l -> 120000 (* Symlink *)
                           (* Gitlink not added yet *)
        | _ -> failwith "Unknown mode"
      in
      (* This needs to be changed to appropriately account for level1/level2/file.xyz when constructing trees
         Ultimately, it is best for this to return a full tree structure *)
      let (item_name, path) = name_with_path full_item_name in
      let new_item = {mode = Int.to_string mode_int; name = item_name; hash = string_of_bitstring item_hash} in
      parse_entries_v2 rest entry_num (l @ [new_item]) (n + 1)
  | {|_|} -> failwith "Couldn't parse entry"
(* Needs version sensitive checking for 2, 3, and 4. Git now uses Version 4, and it is important that this works on an existing .git/index. *)
let to_items bits =
  match%bitstring bits with
  | {| _ : 4*8 : string ;
       _ : 4*8 ;
       entry_num : 4*8 ;
       entries : -1 : bitstring |} -> parse_entries_v2 entries (Int32.to_int entry_num) [] 0
  | {| _ |} -> failwith "Couldn't parse index"
*)