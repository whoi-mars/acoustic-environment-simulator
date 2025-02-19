        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:17 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE READIN__genmod
          INTERFACE 
            SUBROUTINE READIN(FREQ,MAXMEDIA,NMEDIA,TOPOPT,CPT,CST,RHOT, &
     &BUMDEN,ETA,XI,NG,SIGMA,DEPTH,BOTOPT,CPB,CSB,RHOB,NC,SSP,SSPHS)
              INTEGER(KIND=4) :: NC
              REAL(KIND=8) :: FREQ
              INTEGER(KIND=4) :: MAXMEDIA
              INTEGER(KIND=4) :: NMEDIA
              CHARACTER(*) :: TOPOPT
              COMPLEX(KIND=8) :: CPT
              COMPLEX(KIND=8) :: CST
              REAL(KIND=8) :: RHOT
              REAL(KIND=8) :: BUMDEN
              REAL(KIND=8) :: ETA
              REAL(KIND=8) :: XI
              INTEGER(KIND=4) :: NG(*)
              REAL(KIND=8) :: SIGMA(*)
              REAL(KIND=8) :: DEPTH(*)
              CHARACTER(*) :: BOTOPT
              COMPLEX(KIND=8) :: CPB
              COMPLEX(KIND=8) :: CSB
              REAL(KIND=8) :: RHOB
              REAL(KIND=8) :: SSP(NC,6)
              REAL(KIND=8) :: SSPHS(2,6)
            END SUBROUTINE READIN
          END INTERFACE 
        END MODULE READIN__genmod
