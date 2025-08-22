open GitRus

let () =
  let b = Git_object.blob_of_file "myfile.txt" in
  let x = Hash.obj_hex b in
  match x with
  | Ok raw ->
    Printf.printf "%s\n" raw
  | Error _ ->
    Printf.printf "Nothin";
  Printf.printf "Mode is: %d\n" (Git_object.filemode "/Users/tomp/Documents/file/proj/gitRus/myfile.txt");
  let y = Git_object.get_files "/Users/tomp/Documents/file/proj/gitRus" in
  let rec print_string_list = function
    | [] -> ()
    | [x] -> print_endline x
    | x :: xs ->
        print_string x;
        print_string ", ";
        print_string_list xs
  in
  print_string_list y