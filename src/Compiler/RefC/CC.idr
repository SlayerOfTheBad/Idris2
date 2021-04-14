module Compiler.RefC.CC

import Core.Context
import Core.Options

import System

import Idris.Version
import Libraries.Utils.Path

findCC : IO String
findCC
    = do Nothing <- getEnv "IDRIS2_CC"
           | Just cc => pure cc
         Nothing <- getEnv "CC"
           | Just cc => pure cc
         pure "cc"

fullprefix_dir : Dirs -> String -> String
fullprefix_dir dirs sub
    = prefix_dir dirs </> "idris2-" ++ showVersion False version </> sub

export
compileCObjectFile : {auto c : Ref Ctxt Defs}
                  -> {default False asLibrary : Bool}
                  -> (outn : String)
                  -> (outobj : String)
                  -> Core (Maybe String)
compileCObjectFile {asLibrary} outn outobj =
  do cc <- coreLift findCC
     dirs <- getDirs

     let libraryFlag = if asLibrary then "-fpic " else ""

     let runccobj = cc ++ " -c " ++ libraryFlag ++ outn ++
                       " -o " ++ outobj ++ " " ++
                       "-I" ++ fullprefix_dir dirs "refc " ++
                       "-I" ++ fullprefix_dir dirs "include"

     coreLift $ putStrLn runccobj
     0 <- coreLift $ system runccobj
       | _ => pure Nothing

     pure (Just outobj)

export
compileCFile : {auto c : Ref Ctxt Defs}
            -> {default False asShared : Bool}
            -> (outobj : String)
            -> (outexec : String)
            -> Core (Maybe String)
compileCFile {asShared} outobj outexec =
  do cc <- coreLift findCC
     dirs <- getDirs

     let sharedFlag = if asShared then "-shared " else ""

     let runcc = cc ++ " " ++ sharedFlag ++ outobj ++
                       " -o " ++ outexec ++ " " ++
                       fullprefix_dir dirs "lib" </> "libidris2_support.a" ++ " " ++
                       "-lidris2_refc " ++
                       "-L" ++ fullprefix_dir dirs "refc " ++
                       clibdirs (lib_dirs dirs)

     coreLift $ putStrLn runcc
     0 <- coreLift $ system runcc
       | _ => pure Nothing

     pure (Just outexec)

  where
    clibdirs : List String -> String
    clibdirs ds = concat (map (\d => "-L" ++ d ++ " ") ds)