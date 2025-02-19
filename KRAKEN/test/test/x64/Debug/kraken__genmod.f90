        !COMPILER-GENERATED INTERFACE MODULE: Fri Dec 13 19:44:20 2024
        ! This source file is for reference only and may not completely
        ! represent the generated interface used by the compiler.
        MODULE KRAKEN__genmod
          INTERFACE 
            SUBROUTINE KRAKEN(NM,FRQ,NL,NOTE1,BB,NC,SSP,NOTE2,BSIG,SSPHS&
     &,CLH,RNG,NSR,ZSR,NRC,ZRC,NZ,CG,CP,KR,ATT,ZM,MODES)
              INTEGER(KIND=4) :: NZ
              INTEGER(KIND=4) :: NC
              INTEGER(KIND=4) :: NL
              INTEGER(KIND=4) :: NM
              REAL(KIND=8) :: FRQ
              CHARACTER(LEN=1) :: NOTE1(3)
              REAL(KIND=8) :: BB(NL,3)
              REAL(KIND=8) :: SSP(NC,6)
              CHARACTER(LEN=1) :: NOTE2(1)
              REAL(KIND=8) :: BSIG
              REAL(KIND=8) :: SSPHS(2,6)
              REAL(KIND=8) :: CLH(2)
              REAL(KIND=8) :: RNG
              INTEGER(KIND=4) :: NSR
              REAL(KIND=8) :: ZSR(1)
              INTEGER(KIND=4) :: NRC
              REAL(KIND=8) :: ZRC(2)
              REAL(KIND=8) :: CG(NM)
              REAL(KIND=8) :: CP(NM)
              REAL(KIND=8) :: KR(NM)
              REAL(KIND=8) :: ATT(NM)
              REAL(KIND=8) :: ZM(NZ)
              REAL(KIND=8) :: MODES(NZ,NM)
            END SUBROUTINE KRAKEN
          END INTERFACE 
        END MODULE KRAKEN__genmod
