%------------------------------------------------------------------------
%========================================================================
%                            Configuration
%========================================================================
%------------------------------------------------------------------------

% clear everything
clear all
clc

% add relevant paths
addpath("KRAKEN");
addpath("simulators");
addpath("data");
addpath("utils");

% set RNG
rng(1234); 

%------------------------------------------------------------------------
%========================================================================
%                      Simulation Parameters
%========================================================================
%------------------------------------------------------------------------

%---------------------------------------------
%             Simulation Settings
%---------------------------------------------
% add experimental noise flag
config.ADD_NOISE = 0;
% number of parallel proesses
config.N = 2;
% frequency value to approximate vg as f --> infinity
config.FREQ_ASYM = 10000;


%---------------------------------------------
%     TOSSIT Configuration + Bathymetry
%---------------------------------------------
% TOSSIT positions
config.TOSSIT_LATLONS_RAW = get_TOSSIT_latlons('mudpatch'); % [lat lon]
% minimum acceptable source water depth
config.MIN_WATER_DEPTH = 10; % [m]
% rectangular region of environment to consider
config.ENV_BOUNDS = [40.55 -70.67
                     40.4 -70.67 
                     40.4 -70.46
                     40.55 -70.46]; % [UL; LL; LR; UR]
% path to bathymetry file
config.BATH_FILE = 'data/bathymetry/MudpatchDEM.mat';

%---------------------------------------------
%               Signal Parameters
%---------------------------------------------
% frequency range
config.FREQ_RANGE = [10 300]; % [Hz]
% frequency sample spacing
config.DF = 1/6; % [Hz]
% sample rate
config.FS = 600; % [Hz]
% number of modes
config.NM = 12; % []
% number of experimental noise examples to load
config.NUM_NOISE = 5000; % []
% path to noise data
config.NOISE_FILE = 'data/noise/sbcex_noise.h5';

%---------------------------------------------
%               Source Parameters
%---------------------------------------------
% source depth
config.ZS_RANGE = [55 65]; % [m]
config.DELTA_ZS = 2; % [m]
% number of locations to sample
config.N_LOCS = 1500; % []


%---------------------------------------------
%           Environment Parameters
%---------------------------------------------
%------------------Bathymetry--------------------
% which interval to round to (e.g., to the nearest 0.5)
config.BATHYM_ROUND = 0.5; % []
% valid locations dilation factor
config.LOC_DILATION = 2; % []
%-------------------Water Column-----------------
% path to CTD data
config.CTD_PATH = 'data/ctd';
% depth vector spacing for SSP
config.DZ = 1; % [m]
% explained variance threshold
config.ALPHA_V = 0.95; % []
%------------------Sediment Layer----------------
% sound speed
config.C_SED_RANGE = [1400 1600]; % [m/s]
config.DELTA_C_SED = 15; % [m/s]
% thickness
config.H_RANGE = [1 15]; % [m]
config.DELTA_H = 2; % [m]
% attenuation
config.ALPHA_SED_RANGE = [0.05 0.05]; % [dB/lambda]
%-----------------Basement Layer-----------------
% sound speed
config.CB_RANGE = [1600 2200]; % [m/s]
config.DELTA_CB = 40; % [m/s]
% attenuation
config.ALPHA_B_RANGE = [0.25 0.25]; % [dB/lambda]

%------------------------------------------------------------------------
%========================================================================
%                           Run Simulation
%========================================================================
%------------------------------------------------------------------------

TOSSIT_network_simulator;