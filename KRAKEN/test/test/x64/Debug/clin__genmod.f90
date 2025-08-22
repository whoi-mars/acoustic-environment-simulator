        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE CLIN__genmod
          INTERFACE 
            SUBROUTINE CLIN(DEPTH,CP,CS,RHOT,MEDIUM,N1,FREQ,ATTENUNIT,  &
     &TASK,NC,SSP)
              INTEGER(KIND=4) :: NC
              REAL(KIND=8) :: DEPTH(*)
              COMPLEX(KIND=8) :: CP(*)
              COMPLEX(KIND=8) :: CS(*)
              REAL(KIND=8) :: RHOT(*)
              INTEGER(KIND=4) :: MEDIUM
              INTEGER(KIND=4) :: N1
              REAL(KIND=8) :: FREQ
              CHARACTER(LEN=2) :: ATTENUNIT
              CHARACTER(LEN=8) :: TASK
              REAL(KIND=8) :: SSP(NC,6)
            END SUBROUTINE CLIN
          END INTERFACE 
        END MODULE CLIN__genmod
