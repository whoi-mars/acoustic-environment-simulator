
%------------------------------------------------------------------------
%========================================================================
%                               Setup
%========================================================================
%------------------------------------------------------------------------

%---------------------------------------------
%     Get TOSSIT/Bathymetry Information
%---------------------------------------------
fprintf('Loading Bathymetry...')
[D_grid, locs_ok,...
 TOSSIT_latlons_grid,...
 range_grids,...
 mesh_lon,...
 mesh_lat,...
 mesh_x,...
 mesh_y] = get_bathymetry(config.BATH_FILE,config.ENV_BOUNDS,...
                          config.TOSSIT_LATLONS_RAW,...
                          config.MIN_WATER_DEPTH);
fprintf('Done!\n')

%---------------------------------------------
%                Load Noise
%---------------------------------------------
if config.ADD_NOISE
    fprintf('Loading Noise Examples...')
    noise = load_experimental_noise(config.NOISE_FILE,config.FS,...
                                    config.NUM_NOISE,1 / config.DF);
    fprintf('Done!\n')
end

%---------------------------------------------
%           KLE Sound Speed Sampler
%---------------------------------------------
fprintf('Loading CTD Data...')
% load data
[CTD, full_depth_vec] = load_asc_CTD_data(config.CTD_PATH,config.DZ);

% isolate sound speed
C_data = CTD(:,:,end);

% make zeros (where data was not sampled) NaN values
for i=1:size(C_data,1)
    ind = find(C_data(i,:),1,'last');
    C_data(i,ind+1:end) = NaN;
end
fprintf('Done!\n')

%------------------------------------------------------------------------
%========================================================================
%                               KRAKEN
%========================================================================
%------------------------------------------------------------------------

fprintf("Running KRAKEN...")

%----------------------------------------------
% Simulation Options
% N - N2-linear (n the index of refraction)
% V - vacuum above top
% W - attenuation units are [dB/wavelength]
%----------------------------------------------
note1='NVW';

%----------------------------------------------
% Bottom Boundary Condition
% A - ACOUSTIC-ELASTIC half-space
% SIGMA - interfacial roughness [m]
%----------------------------------------------
note2='A';
bsig=0;

%-----------------------------------------------
% Maximum Range [km] (used in error calculation)
%-----------------------------------------------
rng=0; % [km]

%----------------------------------
%   Set Sources For Depth Vector 
%----------------------------------
% exact source depth is not relevant. The goal here is just to get
% the returned z vector to be 0:1:D_basement.
nsd=1; % []
sd=0; % [m]

fprintf("Done!\n")