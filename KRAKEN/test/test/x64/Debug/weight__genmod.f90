        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:19 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE WEIGHT__genmod
          INTERFACE 
            SUBROUTINE WEIGHT(X,NX,XTAB,NXTAB,W,IX)
              INTEGER(KIND=4) :: NXTAB
              INTEGER(KIND=4) :: NX
              REAL(KIND=4) :: X(NX)
              REAL(KIND=4) :: XTAB(NXTAB)
              REAL(KIND=4) :: W(NXTAB)
              INTEGER(KIND=4) :: IX(NXTAB)
            END SUBROUTINE WEIGHT
          END INTERFACE 
        END MODULE WEIGHT__genmod
