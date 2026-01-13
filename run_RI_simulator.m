% clear everything
clear all
clc

% add paths
addpath('KRAKEN');
addpath('utils');
addpath('simulators');

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
config.ADD_NOISE = 0;
% number of environments to save per file
config.ENV_CHUNK = 1;
% number of processe in parallel pool
config.N = 12;
% frequency used to find asymptotic group speed
config.F_ASYM = 400; % [Hz]
% If not 0, removed all simulated signals of shorter duration
config.DURATION_FILTER = 0; % [sec]
% noise is added to each simulated signal
config.SNR_RANGE = [-7 3]; % [dB]
% randomly shift simulated signal in simulation window
config.RANDOM_SHIFT = 0;

%---------------------------------------------
%          Water Column Sound Speed
%---------------------------------------------
config.CW_RANGE = [1478, 1497]; % [m/s]
config.CW_NODE_DEPTHS = [20 40]; % [m]

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
config.CB_RANGE = [1849 1849]; % [m/s]
config.DELTA_CB = 1; % [m/s]
config.B_ALPHA_RANGE = [0.25 0.25]; % [db/wavelength]

%---------------------------------------------
%            Water Column Depth
%---------------------------------------------
config.D_RANGE = [68 78]; % [m]

%---------------------------------------------
%              Source Depths
%---------------------------------------------
config.ZS_RANGE = [45 60]; % [m]
config.DELTA_ZS = 1; % [m]

%---------------------------------------------
%              Source Ranges
%---------------------------------------------
config.R_RANGE = [4000 15000]; % [m]
config.DELTA_R = 10; % [m]

%---------------------------------------------
%                    Paths
%---------------------------------------------
config.NOISE_PATH = '/media/mark/extradrive2/uncertain_inversion/environmental_data/noise/sbcex22_noise.h5';
config.DATA_PATH = '/media/mark/extradrive2/uncertain_inversion/single_sensor_spectrum_RI/sim_data';

%------------------------------------------------------------------------
%========================================================================
%                           Run Simulation
%========================================================================
%------------------------------------------------------------------------

RI_simulator;