open Core
open Bitstring
open! Git_object
open! Stdint
open Util
let index_bits = bitstring_of_file (from_root "/.git/index")

(*
type index_entry = {
  ctime_s: int32;
  ctime_ns: int32;
  mtime_sec : int32;
  mtime_nsec : int32;
  dev : int32;
  ino : int32;
  mode : int32;
  uid : int32;
  gid : int32;
  size : int32;
  sha1 : string;  (* 20-byte SHA1 hash *)
  flags:
  file_path : string;
}
*)

let name_with_pathlist path =
    let items = List.rev (String.split path ~on:'/') in
    match items with
    | fst::rest -> (fst, List.rev rest)
    | [] -> failwith "Empty list"

(*
(* Only Version 2 index entries for the time being *)
let rec parse_entries_v2 entries l =
  match%bitstring entries with
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
      let (item_name, path) = name_with_pathlist full_item_name in
      let new_item = {mode = Int.to_string mode_int; name = item_name; hash = string_of_bitstring item_hash} in
      if bitstring_length rest = 0 then l else parse_entries_v2 rest (l @ [new_item])
  | {|_|} -> failwith "Couldn't parse entry"

(* Needs version sensitive checking for 2, 3, and 4. Git now uses Version 4, and it is important that this works on an existing .git/index. *)
let to_items bits =
  match%bitstring bits with
  | {| _ : 4*8 : string ;
       _ : 4*8 ;
       entry_num : 4*8 ;
       entries : -1 : bitstring |} ->
        match (Int32.to_int entry_num) with
        | Some num -> parse_entries_v2 entries num [] 0
        | None -> failwith "Unable to cast int32 to int"
*)