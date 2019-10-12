# OPCAnalyserl

OPCAnalyserl uses SSQSA input files, eCST files and eGDN files to calulate Overall Path Complexity metrics for input files used in SSQSA framework. 

OPCAnalysers supports calculating:
* Cycomatic Complexity CC
* Interlined Cyclomatic Complexity ICC
* Length or recursion, Lor
* Overal Path Complexity OPC

## How to run it

Navigate to OPCAnalyser folder in your file system using terminal. Type `erl` to enter into erlang shell. Further `c(calculate).` will compile the module. After that you can use provided functions for calculation:

* CC - You need to provide eCST file containing desired function/procedure/method

 `calculate:cc(Path_to_ecst_file, Function_id).`
 
  example: 
  
 `calculate:cc("ecst/Sum1.xml","test.Sum.sum@int#int").`
 
 * ICC - You need to provide both eCST and eGDN files 
 
 `calculate:icc(Function_id, Path_to_ecst, Path_to_egdn).`
 
 example:
 
 `calculate:icc("test.Sum2.sum@int@int#int", "ecst/Sum2.xml", "egdn/GDN_sum2.xml").`
 
 * Lor - You need to provide eGDN file
` calculate:lor(Fun1_id, Fun2_id, Path_to_egdn). `

  example:
  
  `calculate:lor("test.M_changed1.f@int#int", "test.M_changed1.f@int#int", "egdn/GDN_m_changed1.xml"). `
  
  * OPC - You need to provide both eCST and eGDN files
  
 ` calculate:opc(Function_id, Path_to_ecst, Path_to_egdn").`
 
  example:
  
 `calculate:opc("test.M.f@int#int", "ecst/M.xml", "egdn/GDN_m.xml").`
 
 Java source files from which eCST and eGDN files are generated are provided in java_source folder. Ecst files are provided in ecst folder, and eGDN files in egdn folder.
