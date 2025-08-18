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
  hash : string;
}

module TextFile : sig
  val to_blob: string -> t
end = struct
  let with_in_channel filename f =
    let ic = open_in filename in
    try
      let result = f ic in
      close_in ic;
      result
    with e ->
      close_in_noerr ic;
      raise e

  let to_blob filename =
    Blob (with_in_channel filename (fun ic ->
      let len  = in_channel_length ic in
      really_input_string ic len
    ))
end