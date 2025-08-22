        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:20 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE SOLVE__genmod
          INTERFACE 
            SUBROUTINE SOLVE(ERROR,NM,NZ,ZM,MODES)
              INTEGER(KIND=4), INTENT(IN) :: NZ
              INTEGER(KIND=4), INTENT(IN) :: NM
              REAL(KIND=8) :: ERROR
              REAL(KIND=8), INTENT(OUT) :: ZM(NZ)
              REAL(KIND=8), INTENT(OUT) :: MODES(NZ,NM)
            END SUBROUTINE SOLVE
          END INTERFACE 
        END MODULE SOLVE__genmod
