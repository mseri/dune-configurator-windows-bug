(*
 * OWL - OCaml Scientific and Engineering Computing
 * Copyright (c) 2016-2022 Liang Wang <liang@ocaml.xyz>
 *)

module C = Configurator.V1

let header = {|
    #define TEST "test"
|}

let default_cflags c =
  let _arch2 =
    let defines =
      C.C_define.import c ~includes:[]
        [
          ("__x86_64__", Switch);
          ("__i386__", Switch);
          ("__aarch64__", Switch);
          ("__arm__", Switch);
        ]
    in
    let open C in
    match List.map snd defines with
    | Switch true :: _ -> `x86_64
    | _ :: Switch true :: _ -> `x86
    | _ :: _ :: Switch true :: _ -> `arm64
    | _ :: _ :: _ :: Switch true :: _ -> `arm
    | _ -> `unknown
  in
  let test =
    let headerfile =
      let file, fd =
        Filename.open_temp_file ~mode:[ Open_wronly ] "discover" "test.h"
      in
      output_string fd header;
      close_out fd;
      file
    in
    let platform =
      assert (Sys.file_exists header);
      C.C_define.import c ~includes:[ headerfile ] [ ("TEST", String) ]
    in
    match List.map snd platform with
    | [ String "test" ] -> `test
    | _ -> `unknown
  in
  match test with `test -> [] | _ -> assert false

let () =
  C.main ~name:"test" (fun c ->
      let libs = [] in
      let cflags = default_cflags c in
      let conf : C.Pkg_config.package_conf = { cflags; libs } in
      C.Flags.write_sexp "c_flags.sexp" conf.cflags)
