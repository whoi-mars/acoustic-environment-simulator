        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE CSPLINE__genmod
          INTERFACE 
            SUBROUTINE CSPLINE(TAU,C,N,IBCBEG,IBCEND,NDIM)
              INTEGER(KIND=4) :: NDIM
              INTEGER(KIND=4) :: N
              REAL(KIND=8) :: TAU(N)
              COMPLEX(KIND=8) :: C(4,NDIM)
              INTEGER(KIND=4) :: IBCBEG
              INTEGER(KIND=4) :: IBCEND
            END SUBROUTINE CSPLINE
          END INTERFACE 
        END MODULE CSPLINE__genmod
