        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE VSPLINE__genmod
          INTERFACE 
            SUBROUTINE VSPLINE(TAU,C,M,MDIM,F,N)
              INTEGER(KIND=4) :: N
              INTEGER(KIND=4) :: MDIM
              INTEGER(KIND=4) :: M
              REAL(KIND=8) :: TAU(M)
              COMPLEX(KIND=8) :: C(4,MDIM)
              COMPLEX(KIND=8) :: F(N)
            END SUBROUTINE VSPLINE
          END INTERFACE 
        END MODULE VSPLINE__genmod
