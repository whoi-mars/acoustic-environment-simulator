        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:19 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE SINVIT__genmod
          INTERFACE 
            SUBROUTINE SINVIT(N,D,E,IERR,RV1,RV2,RV3,RV4,RV6)
              INTEGER(KIND=4) :: N
              REAL(KIND=8) :: D(N)
              REAL(KIND=8) :: E(N+1)
              INTEGER(KIND=4) :: IERR
              REAL(KIND=8) :: RV1(N)
              REAL(KIND=8) :: RV2(N)
              REAL(KIND=8) :: RV3(N)
              REAL(KIND=8) :: RV4(N)
              REAL(KIND=8) :: RV6(N)
            END SUBROUTINE SINVIT
          END INTERFACE 
        END MODULE SINVIT__genmod
