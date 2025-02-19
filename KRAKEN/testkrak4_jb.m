clear all
clear mkrak
close all

nm=20;    % Max number of modes calculated
nl=2; %number of layer, including water
%%% one must have [nl,~]=size(b); 

note1='NVW';  %%% Options - see Krakan_HELP.txt (4)
% 'NVW' = N2-linear profile
%         VACUUM above top
%         attenuation in dB/wavelength

%%% top halfspace boundary condition 
% syntax:  ZT  CPT  CST  RHOT  APT  AST
sspTHS=[0  343.0     0.000   0.00121    0    0.000 ];   %%% useless if note1(2) ~= A

b1=[0  0.0  100.]; 
% b_out = [ NMESH SIGMA Z(NSSP) ]
%
%          NMESH:   Number of mesh points to use initially.
%                   The number of mesh points should be about 10
%                   per vertical wavelength in acoustic media. In
%                   elastic media, the number needed can vary quite
%                   a bit; 20 per wavelength is a reasonable
%                   starting point.
% 
%                   The maximum allowable number of mesh points is
%                   given by 'MAXN' in the dimension statements. 
%                   At present 'MAXN' is 50000.  The number of mesh
%                   points used depends on the initial mesh and the
%                   number of times it is refined (doubled).  The
%                   number of mesh doublings can vary from 1 to 5
%                   depending on the parameter RMAX described
%                   below.
% 
%                   If you type 0 for the number of mesh points,
%                   the code will calculated NMESH automatically.
%          SIGMA:   RMS roughness at the interface.
% 
%          Z(NSSP): Depth at bottom of medium (m).
%                   This value is used to detect the last SSP point
%                   when reading in the profile that follows. 

%%% SSP syntax 
% [Z(1)     CP(1)     CS(1)     RHO(1)     AP(1)     AS(1)
%  Z(2)     CP(2)     CS(2)     RHO(2)     AP(2)     AS(2)
% .... ]

ssp1= [0.000  1500     0.000   1.03000     0.000    0.000
       100.000  1500     0.000   1.03000     0.000    0.000];
      
b2=[0  0.0  120];
ssp2=[100   1600     0.000   1.6     0.0100    0.000
      120  1600     0.000   1.6     0.0100    0.000];


note2='A'; %%%% Bottom boundary condition
%%% bottom halfspace boundary condition 
% syntax:  Z  CP  CS  RHO  AP  AS
sspBHS=[120  1800     0.000   2    0.05    0.000 ];  %%% useless if note2 ~= A
bsig=0;  % Bottom interfacial roughness(m)

%%% collect top/bottom half space boundary conditions
sspHS = [sspTHS;sspBHS];
%%% collect ssp
b=[b1; b2];
ssp=[ssp1; ssp2];
[nc, ~]=size(ssp);

%%% Phase speed limits
CHigh =max([max(ssp(:,2)),sspBHS(2)]);
CLow = 0;
clh=[CLow  CHigh];

%%% Source/receiver config
rng=5000; % range (m); used for error estimate
zr_=0:ssp(end,1); % depth for modal depth function computation

%%% do not change that
ns=  1; % number of sources 
zs=zr_(1) ; % source depth
nzr=length(zr_)-1; % number of points for modal depth function computation
zrc=[zr_(2) zr_(end)] ;



freq_krak=[3:0.1:100];
Nf=length(freq_krak);
Nz=length(zr_);

vp_krak=zeros(nm,Nf);
vg_krak=zeros(nm,Nf);
kr_re_krak=zeros(nm,Nf);
kr_im_krak=zeros(nm,Nf);
phi_krak=zeros(Nz,nm,Nf);

tic
for ff=1:Nf
  frq0=freq_krak(ff);
  [cg, cp, kr_re ,kr_im, z_krak, modes]=mkrak_jb(nm,frq0,nl,note1,b,nc,ssp,note2,bsig,sspHS,clh,rng,ns,zs,nzr,zrc);
  vp_krak(:,ff)=cp;
  vg_krak(:,ff)=cg;
  kr_re_krak(:,ff)=kr_re;
  kr_im_krak(:,ff)=kr_im;
  phi_krak(:,:,ff)=modes;
end
t=toc

vp_krak(vp_krak==0)=NaN;
vg_krak(vg_krak==0)=NaN;
kr_re_krak(kr_re_krak==0)=NaN;
kr_im_krak(kr_im_krak==0)=NaN;
kr_krak=kr_re_krak+1i*kr_im_krak;

figure
subplot(121)
plot(vp_krak, freq_krak)
ylabel('Frequency (Hz)','FontSize',14)
xlabel('Phase Speed (m/s)','FontSize',14)
xlim([1500 1800])

subplot(122)
plot(vg_krak,freq_krak)
ylabel('Frequency (Hz)','FontSize',14)
xlabel('Group Speed (m/s)','FontSize',14)
xlim([1300 1600])

figure
plot(modes(:,1:8), z_krak)
axis ij

figure
subplot(121)
plot(kr_re_krak, freq_krak)
ylabel('Frequency (Hz)','FontSize',14)
xlabel('Wavenumber - real part','FontSize',14)
grid on

subplot(122)
plot(kr_im_krak,freq_krak)
ylabel('Frequency (Hz)','FontSize',14)
xlabel('Wavenumber - imaginary part','FontSize',14)
grid on

save example_kraken vg_krak vp_krak kr_krak phi_krak z_krak freq_krak
