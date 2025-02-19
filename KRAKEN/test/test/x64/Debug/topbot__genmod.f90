        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE TOPBOT__genmod
          INTERFACE 
            SUBROUTINE TOPBOT(FREQ,BCTYPE,ATTENUNIT,CPHS,CSHS,RHOHS,    &
     &BUMDEN,ETA,XI,SSPTMP,NC)
              REAL(KIND=8) :: FREQ
              CHARACTER(LEN=1) :: BCTYPE
              CHARACTER(LEN=2) :: ATTENUNIT
              COMPLEX(KIND=8) :: CPHS
              COMPLEX(KIND=8) :: CSHS
              REAL(KIND=8) :: RHOHS
              REAL(KIND=8) :: BUMDEN
              REAL(KIND=8) :: ETA
              REAL(KIND=8) :: XI
              REAL(KIND=8) :: SSPTMP(1,6)
              INTEGER(KIND=4) :: NC
            END SUBROUTINE TOPBOT
          END INTERFACE 
        END MODULE TOPBOT__genmod
