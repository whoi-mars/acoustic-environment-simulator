        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:20 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE BISECT__genmod
          INTERFACE 
            SUBROUTINE BISECT(XMIN,XMAX,XL,XR)
              USE KRAKMOD
              REAL(KIND=8) :: XMIN
              REAL(KIND=8) :: XMAX
              REAL(KIND=8) :: XL(M+1)
              REAL(KIND=8) :: XR(M+1)
            END SUBROUTINE BISECT
          END INTERFACE 
        END MODULE BISECT__genmod
