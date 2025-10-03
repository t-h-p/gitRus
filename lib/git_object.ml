open Core
open Core_unix
open Util

type t =
  | Blob of string
  | Tree of tree_entry list
  | Commit of {
    tree_hash : string;
    parents : string list;
    author : string;
    committer : string;
    message : string;
  }
  | Tag of {
    object_hash : string;
    object_type : string;
    tag_name : string;
    tagger : string;
    message : string;
  }
and tree_entry = {
  mode : string;
  name : string;
  (* Hash should be 20 byte representation, as opposed to hexidecimal *)
  hash : string;
}
;;

(*
let git_compare_entries e1 e2 =
  let name1 = if (String.equal e1.mode "40000") then e1.name ^ "/" else e1.name in
  let name2 = if (String.equal e2.mode "40000") then e2.name ^ "/" else e2.name in
  String.compare name1 name2
*)

(*
| THE FUNCTION BELOW DOES NOT WORK AS INTENDED |
V                                              V
It is pretty much useless in its current state.
*)
(*
let rec add_to_tree_no_opt tree item path =
  match path with
  | fst::rest -> (
    match find_in_tree tree ~item:fst with
    | true -> add_to_tree_no_opt (List.sort (fst :: tree) ~compare:git_compare_entries) item rest
    | false -> failwith "Something went wrong parsing tree")
  | [] -> List.sort (item :: tree) ~compare:git_compare_entries
and find_in_tree tree ~item =
  let comp e = (String.equal e.name item.name) && (String.equal e.mode item.mode) in
  let item = List.find tree ~f:comp in
  match item with
  | Some _ -> true
  | None -> false

let add_to_tree tree item path =
  try
    Ok (add_to_tree_no_opt tree item path)
  with _ ->
    Error "Couldn't add to tree"
*)


let obj_hash obj =
  match obj with
  | Blob content ->
    let len = String.length content in
    let raw = (Printf.sprintf "blob %d\000" len) ^ content in
    Ok (raw |> Sha1.string)
  | Tree items ->
    let name_concat (acc:string) (tree_item: tree_entry) = acc ^ tree_item.mode ^ " " ^ tree_item.name ^ "\000" ^ tree_item.hash in
    let content = List.fold items ~init:"" ~f:name_concat in
    let len = String.length content in
    let raw = (Printf.sprintf "tree %d\000" len) ^ content in
    Ok (raw |> Sha1.string)
  | _ ->
    Error "Wrong object type"

let hash_hex obj =
  match obj_hash obj with
  | Ok digest -> Sha1.to_hex digest
  | Error _ -> failwith "Couldn't hash object"

let hash_bin obj =
  match obj_hash obj with
  | Ok digest -> Sha1.to_bin digest
  | Error _ -> failwith "Couldn't hash object"

let blob_of_file path =
  match (stat path).st_kind with
  | S_REG -> Blob (In_channel.read_all path ^ "\n")
  | S_LNK -> Blob (Core_unix.readlink path)
  | _ -> failwith "Cannot make blob of that filetype"

let te_of_blob blob ~mode ~name = { mode = mode ; name = name ; hash = hash_bin blob }

(**
    Some testing for git hash-object. Hard coding hashes in here...
    Good way to emulate real behavior for trees is by creating new git repo
    with appropriate files, run 'git add . && git write-tree'
*)

let%test "hash_blob_hex_1" =
  let test_val = blob_of_file (from_root "/test/b1.txt") |> hash_hex in
  let expt_val = "a5bce3fd2565d8f458555a0c6f42d0504a848bd5" in
  String.equal test_val expt_val

let%test "hash_tree_hex_1" =
  let b1 = blob_of_file (from_root "/test/b1.txt") in
  let b2 = blob_of_file (from_root "/test/b2.txt") in
  let t1 = Tree [te_of_blob b1 ~mode:"100644" ~name:"b1.txt" ; te_of_blob b2 ~mode:"100644" ~name:"b2.txt"] in
  let test_val = hash_hex t1 in
  let expt_val = "21a2e3a7b4f696d6ea5182d1b500571beebcf25a" in
  String.equal test_val expt_val

(*
Directory (040000) -- (Unix.S_DIR, 0o755)
Regular file (100644) -- (Unix.S_REG, 0o644)
Executable file (100755) -- (Unix.S_REG, 0o755)
Symlink (120000) -- (Unix.S_LNK, 0o777)
*)
(*
let kind_and_perms filename =
  let stats = Core_unix.stat filename in
  (stats.st_kind, stats.st_perm)


let filemode filename =
  let kp = kind_and_perms filename in
  match kp with
  | (Core_unix.S_DIR,_) -> 0o040000
  | (Core_unix.S_REG,0o644) -> 0o100644
  | (Core_unix.S_REG,0o755) -> 0o100755
  | (Core_unix.S_LNK,_) -> 0o120000
  | _ -> failwith "Wrong filemode"

let get_files dirname =
  let handle = Core_unix.opendir dirname in
  let rec read entries =
    let entry = Core_unix.readdir_opt handle in
      match entry with
      | Some "." | Some ".." | Some ".git" -> read entries
      | Some(filename) -> read (filename :: entries)
      | None -> entries
    in
  try
  let result = read [] in
    Core_unix.closedir handle;
    result
  with exn ->
    Core_unix.closedir handle;
    raise exn
*)

(*
module Index_ir = struct
  type tree =
    (** Here, only Blob will be used from type t.
    The string represents a fully qualified path as present in .git/index. *)
    | Node of { name: string ; items: tree list }
    | Leaf of { name: string ; mode: string ; blob: t }
  ;;
  let rec to_git_tree tree =
    let fn item =
      match item with
      | Node { name ; items } ->
        let hash = hash_bin (to_git_tree items)
        in {mode = "40000"; name = name; hash = hash}
      | Leaf { name ; mode ; blob } ->
        let hash = hash_bin blob
        in {mode = mode ; name = name ; hash = hash}
    in
    let items = Stdlib.List.sort git_compare_entries (Stdlib.List.map fn tree) in
    Tree items
end
*)
(*
      Testing for index to tree intermediate representation
*)

let%test "ir_to_tree_1" = true



(* This function is only useful for example purposes *)
(**
let rec tree_of_directory dirname =
  let files = get_files dirname in
  let pairs = Stdlib.List.combine files (List.map ~f:(fun f -> filemode (Filename.concat dirname f)) files) in
  let fn item =
    match item with
    | (f, 0o100644) -> {mode = "100644"; name = f; hash = hash_bin (blob_of_file (Filename.concat dirname f))}
    | (f, 0o100755) -> {mode = "100755"; name = f; hash = hash_bin (blob_of_file (Filename.concat dirname f))}
    | (d, 0o040000) -> {mode = "40000"; name = d; hash = hash_bin (tree_of_directory (Filename.concat dirname d))}
    | (l, 0o120000) -> {mode = "120000"; name = l; hash = hash_bin (blob_of_link (Filename.concat dirname l))}
    | (_,_) -> failwith "Wrong filemode"
  in
  let items = Stdlib.List.sort git_compare_entries (Stdlib.List.map fn pairs) in
  Tree items
*)