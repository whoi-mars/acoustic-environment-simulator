        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:20 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE VECTOR__genmod
          INTERFACE 
            SUBROUTINE VECTOR(NM,NZ,ZM,MODES)
              USE SDRDRMOD
              INTEGER(KIND=4), INTENT(IN) :: NZ
              INTEGER(KIND=4), INTENT(IN) :: NM
              REAL(KIND=8), INTENT(OUT) :: ZM(NZ)
              REAL(KIND=8), INTENT(OUT) :: MODES(NZ,NM)
            END SUBROUTINE VECTOR
          END INTERFACE 
        END MODULE VECTOR__genmod
