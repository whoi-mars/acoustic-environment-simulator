% clear everything
clear all
clc

% add paths
addpath('KRAKEN');
addpath('utils');
addpath('simulators');
addpath('/home/mark/Documents/MATLAB/')

% set RNG
rng(1234)

%------------------------------------------------------------------------
%========================================================================
%                             Configuration
%========================================================================
%------------------------------------------------------------------------

%---------------------------------------------
%                 Debug Flags
%---------------------------------------------
% save simulation results
config.SAVE_RESULTS = 1;

%---------------------------------------------
%            Constant Parameters
%---------------------------------------------
% frequency range
config.FREQ_RANGE = [20 300]; % [Hz]
config.DF = 1/6; % [Hz]
config.NM = 8; % []

%---------------------------------------------
%           Simulation Metaparameters
%---------------------------------------------
% adding noise to the calls
config.ADD_NOISE = 5000;
% number of environments to save per file
config.ENV_CHUNK = 16;
% number of processe in parallel pool
config.N = 12;
% frequency used to find asymptotic group speed
config.F_ASYM = 400; % [Hz]
% If not 0, removed all simulated signals of shorter duration
config.DURATION_FILTER = 0; % [sec]
% noise is added to each simulated signal
config.SNR_RANGE = [2 5]; % [dB]
% randomly shift simulated signal in simulation window
config.RANDOM_SHIFT = 1;

%---------------------------------------------
%          Water Column Sound Speed
%---------------------------------------------
% desired spacing between SSP measurements
config.DZ = 1; % [m]
% desired percent of variance to keep in SSP KLE
config.ALPHA_V = 0.80; % []

%---------------------------------------------
%     Sediment Sound Speed + Attenuation
%---------------------------------------------
config.CSED_RANGE = [1400 1600]; % [m/s]
config.DELTA_CSED = 15; % [m/s]
config.SED_ALPHA_RANGE = [0.05 0.05]; % [dB/wavelength]

%---------------------------------------------
%             Sediment Thickness
%---------------------------------------------
config.H_RANGE = [5 15]; % [m]
config.DELTA_H = 1; % [m]

%---------------------------------------------
%      Basement Sound Speed + Attenuation
%---------------------------------------------
config.CB_RANGE = [1600 2200]; % [m/s]
config.DELTA_CB = 40; % [m/s]
config.B_ALPHA_RANGE = [0.25 0.25]; % [db/wavelength]

%---------------------------------------------
%            Water Column Depth
%---------------------------------------------
config.D_RANGE = [68 78]; % [m]

%---------------------------------------------
%              Source Depths
%---------------------------------------------
config.ZS_RANGE = [58 62]; % [m]
config.DELTA_ZS = 1; % [m]

%---------------------------------------------
%              Source Ranges
%---------------------------------------------
config.R_RANGE = [4000 15000]; % [m]
config.DELTA_R = 10; % 10; % [m]

%------------------------------------------------------------------------
%========================================================================
%                           Run Simulation
%========================================================================
%------------------------------------------------------------------------

RI_dense_SSP_simulator;