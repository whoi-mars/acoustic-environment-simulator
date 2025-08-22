        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:18 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE ERROUT__genmod
          INTERFACE 
            SUBROUTINE ERROUT(PRTFIL,SEVRTY,WHERE,ERRMSG)
              INTEGER(KIND=4) :: PRTFIL
              CHARACTER(LEN=1) :: SEVRTY
              CHARACTER(*) :: WHERE
              CHARACTER(*) :: ERRMSG
            END SUBROUTINE ERROUT
          END INTERFACE 
        END MODULE ERROUT__genmod
