        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE TWERSK__genmod
          INTERFACE 
            FUNCTION TWERSK(OPT,OMEGA,BUMDEN,XI,ETA,KX,RHO0,C0)
              CHARACTER(LEN=1) :: OPT
              REAL(KIND=8) :: OMEGA
              REAL(KIND=8) :: BUMDEN
              REAL(KIND=8) :: XI
              REAL(KIND=8) :: ETA
              COMPLEX(KIND=8) :: KX
              REAL(KIND=8) :: RHO0
              REAL(KIND=8) :: C0
              COMPLEX(KIND=8) :: TWERSK
            END FUNCTION TWERSK
          END INTERFACE 
        END MODULE TWERSK__genmod
