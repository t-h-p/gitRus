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
  mode : int;
  name : string;
  (* Hash should be 20 byte representation, as opposed to hexidecimal *)
  hash : string;
}

val blob_of_file : string -> t

val filemode : string -> int

val get_files : string -> string list