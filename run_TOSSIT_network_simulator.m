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
%                     Flags
%---------------------------------------------
config.ADD_NOISE = 0;

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
% frequency sample spacing
config.DF = 1/6; % [Hz]
% sample rate
config.FS = 600; % [Hz]
% number of experimental noise examples to load
config.NUM_NOISE = 5000; % []
% path to noise data
config.NOISE_FILE = 'data/noise/sbcex_noise.h5';

%---------------------------------------------
%           Environment Parameters
%---------------------------------------------
% path to CTD data
config.CTD_PATH = 'data/ctd';
% depth vector spacing for SSP
config.DZ = 1; % [m]

%------------------------------------------------------------------------
%========================================================================
%                           Run Simulation
%========================================================================
%------------------------------------------------------------------------

TOSSIT_network_simulator;