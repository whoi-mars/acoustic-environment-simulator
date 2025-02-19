#include "mex.h"
#include "matrix.h"

/* N.B.:  Requires matching C and fortran compilers, compatible with your version of matlab.   */
/*        Symptoms of a problem are a failure to compile, or a Segmentation Fault on running.  */

/*  mkrak.c - Mex function gateway function for kraken.f90

  function [cg,cp,zm,modes]=mkrak(frq,nm,nl,note1,b,ssp,note2,bsig,clh,rng,nsr,zsr,nrc,zrc)

Input:
  frq = frequency
  nm = # modes
  nl= no. layers, e.g., 2
  note1 = text flags for modes, e.g., 'SVW'
  b= NG,sigma,depth of each layer - stacked
  ssp=depths, alphaR, betaR, rhoR, alphaI, betaI for layers 1,2 
                   [  C       0    1.03     0      0  ]
         matrix has each layer - stacked
  note2 = text flag for bottom option
  bsig=bottom sigma
  clh= CLow, CHigh - spectral limits
  rng = range (m); used for error estimate
  nsr,zsr = # and source depths (m)
  nrc,zrc = # and receiver depths (m)    
         If nrc or nsr is greater than the number of depths given, kraken
         will do an autointerpolation.  Thus if nrc is 500 with 
         zrc's = [0 5000], 500 depths between 0 and 5000 will be used for 
         the mode eigenvectors.

Output:
  cg = nm group speeds
  cp = nm phase spees
  zm = depths of mode functions
  modes = nm mode functions at depths zm

*/

void  kraken_(int * nm, double * frq,int * nl,char *note1, double *bb, int * nc, double *ssp, char *note2, double * bsig, double *sspHS, \
             double *clh,double * rng,int * nsr,double *zsr,int * nrc,double *zrc, int * nz, \
             double *cg,double *cp,double *kr, double *att,double *zm,double *modes);

/*void  kraken_(int * nm, double * frq,int * nl,char *note1, double *bb, int * nc, double *ssp, char *note2, double * bsig, double *sspHS, \
             double *clh,double * rng,int * nsr,double *zsr,int * nrc,double *zrc, int * nz, \
             double *cg,double *cp,double *zm,double *modes);*/
			 
void mexFunction( int nlhs, mxArray *plhs[],
		  int nrhs, const mxArray *prhs[])
{
      double frq, sig, rng, bsig;
      double *bb, *ssp, *sspHS, *clh, *zsr, *zrc;
      double *cg, *cp, *zm, *modes, *att, *kr;
	  // double *cg, *cp, *zm, *modes;
      int   nm,nl,nc,nsr, nrc, nz; 
      char *note1, *note2;
      int buflen1, buflen2;

/* The parameters must be consistent between this program and the */
/* kraken program to avoid scrambling the arrays or crashing.     */

      if (nrhs != 16) {
          mexErrMsgTxt("meig requires 16 input arguments");
      } else if (nlhs != 6) {
          mexErrMsgTxt("meig requires 6 output argument");
      }
  
/* Get the length of the input string. */
  buflen1 = (mxGetM(prhs[3]) * mxGetN(prhs[3]) * sizeof(mxChar)) + 1;   
     /* +1 for the null character, perhaps  */
  buflen2 = (mxGetM(prhs[8]) * mxGetN(prhs[8]) * sizeof(mxChar)) + 1; 

/* Allocate memory for input and output strings.  */
  note1 = mxCalloc(buflen1, sizeof(char));
  note2 = mxCalloc(buflen2, sizeof(char)); 

/* load number of modes */
      nm =  mxGetScalar(prhs[0]); 
/* load frequency */
      frq =  mxGetScalar(prhs[1]); 
/* load number of layers  */
      nl =  mxGetScalar(prhs[2]); 
/* load note1 */
      mxGetString(prhs[3], note1, buflen1);
/* load bb   */
      bb = mxGetPr(prhs[4]);
/* load No ssps   */
      nc =  mxGetScalar(prhs[5]); 
/* load ssp   */
      ssp = mxGetPr(prhs[6]);
/* load note1 */
      mxGetString(prhs[7], note2, buflen2);
/* load bottom density */
      bsig = mxGetScalar(prhs[8]);
/* load ssp   */
      sspHS = mxGetPr(prhs[9]);
/* load Clow, Chigh */
      clh = mxGetPr(prhs[10]);
/* load range  */
      rng = mxGetScalar(prhs[11]);
/* load number of sources  */
      nsr = mxGetScalar(prhs[12]);
/* load source depths */
      zsr = mxGetPr(prhs[13]);
/* load number of receivers  */
      nrc = mxGetScalar(prhs[14]);
/* load receiver depths */
      zrc = mxGetPr(prhs[15]);

/* Number of depths=source depths+receiver depths  */
/* The modes are defined at these depths           */
      nz = nsr+ nrc; 

//Store the mode phase and group speeds                           
      plhs[0] = mxCreateDoubleMatrix(1, nm, mxREAL);
      cg = mxGetPr(plhs[0]);
      plhs[1] = mxCreateDoubleMatrix(1, nm, mxREAL);
      cp = mxGetPr(plhs[1]);
	  plhs[2] = mxCreateDoubleMatrix(1, nm, mxREAL);
      kr = mxGetPr(plhs[2]);
	 plhs[3] = mxCreateDoubleMatrix(1, nm, mxREAL);
     att = mxGetPr(plhs[3]);
     plhs[4] = mxCreateDoubleMatrix(nz, 1, mxREAL);
      zm = mxGetPr(plhs[4]);
      plhs[5] = mxCreateDoubleMatrix(nz, nm, mxREAL);
      modes = mxGetPr(plhs[5]);

/* Need to send pointers to kraken... */
/* The arrays are pointers already, but the scalars need the & in front */
/* I love C.  (note sarcasm...) */
/* kraken_(&nm,&frq,&nl,note1,bb,&nc,ssp,note2,&bsig,sspHS,clh,&rng,&nsr,zsr,&nrc,zrc,&nz,cg,cp,kr,zm,modes); */
	kraken_(&nm,&frq,&nl,note1,bb,&nc,ssp,note2,&bsig,sspHS,clh,&rng,&nsr,zsr,&nrc,zrc,&nz,cg,cp,kr,att,zm,modes);
/*  Returns with cg,cp,zm,modes.         */
  
   mxFree(note1);
   mxFree(note2);

}

