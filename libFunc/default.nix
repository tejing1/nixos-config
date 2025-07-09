{ inputs, lib, my, ...}:

let
  inherit (my.lib) importAllExceptWithArg;
in

{
  flake.libFunc = pkgs: let
    result = my.lib //
             # import everything in this directory
             importAllExceptWithArg ./. [ "default" ] (
               inputs //
               {
                 inherit pkgs lib;

                 # pass the final (merged) structure as my.lib
                 my.lib = result;
               }
             );
  in
    result
  ;
}
