        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE CRCI__genmod
          INTERFACE 
            FUNCTION CRCI(C,ALPHA,FREQ,ATTENUNIT)
              REAL(KIND=8) :: C
              REAL(KIND=8) :: ALPHA
              REAL(KIND=8) :: FREQ
              CHARACTER(LEN=2) :: ATTENUNIT
              COMPLEX(KIND=8) :: CRCI
            END FUNCTION CRCI
          END INTERFACE 
        END MODULE CRCI__genmod
