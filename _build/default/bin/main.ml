open GitRus

let () =
  let t1 = Git_object.tree_of_directory "/Users/tomp/Documents/file/proj/test" in
  print_endline (Git_object.hash_hex t1)