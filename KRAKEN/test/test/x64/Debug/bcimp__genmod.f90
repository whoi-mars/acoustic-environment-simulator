        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:20 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE BCIMP__genmod
          INTERFACE 
            SUBROUTINE BCIMP(X,BCTYPE,BOTTOP,CPHS,CSHS,RHOHS,F,G,IPOW)
              REAL(KIND=8) :: X
              CHARACTER(LEN=1) :: BCTYPE
              CHARACTER(LEN=3) :: BOTTOP
              COMPLEX(KIND=8) :: CPHS
              COMPLEX(KIND=8) :: CSHS
              REAL(KIND=8) :: RHOHS
              REAL(KIND=8), INTENT(OUT) :: F
              REAL(KIND=8), INTENT(OUT) :: G
              INTEGER(KIND=4), INTENT(OUT) :: IPOW
            END SUBROUTINE BCIMP
          END INTERFACE 
        END MODULE BCIMP__genmod
