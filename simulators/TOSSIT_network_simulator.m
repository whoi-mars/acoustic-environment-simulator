
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
 TOSSIT_latlons_inds,...
 range_grids,...
 mesh_lon,...
 mesh_lat,...
 mesh_x,...
 mesh_y] = get_bathymetry(config.BATH_FILE,...
                          config.BATHYM_ROUND,...
                          config.LOC_DILATION,...
                          config.ENV_BOUNDS,...
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

% create SSP sampler
kle = KLE(C_data,'sigma',12);
fprintf('Done!\n')

%---------------------------------------------
%           Helpful Constants
%---------------------------------------------
freq_krak = config.FREQ_RANGE(1):config.DF:config.FREQ_RANGE(2); % [Hz]
Nf = length(freq_krak); % []
D_max = max(D_grid,[],"all"); % [m]

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
note1 = 'NVW';

%----------------------------------------------
% Bottom Boundary Condition
% A - ACOUSTIC-ELASTIC half-space
% SIGMA - interfacial roughness [m]
%----------------------------------------------
note2 = 'A';
bsig = 0;

%-----------------------------------------------
% Maximum Range [km] (used in error calculation)
%-----------------------------------------------
rng = 0; % [km]

%----------------------------------
%   Set Sources For Depth Vector 
%----------------------------------
% exact source depth is not relevant. The goal here is just to get
% the returned z vector to be 0:1:D_basement.
nsd = 1; % []
sd = 0; % [m]

%----------------------------------
%  Samples for Gridded Parameters 
%----------------------------------
zs_vec = config.ZS_RANGE(1):config.DELTA_ZS:config.ZS_RANGE(2); % [m]
c_sed_vec = config.C_SED_RANGE(1):config.DELTA_C_SED:config.C_SED_RANGE(2); % [m/s]
H_vec = config.H_RANGE(1):config.DELTA_H:config.H_RANGE(2); % [m/s]
cb_vec = config.CB_RANGE(1):config.DELTA_CB:config.CB_RANGE(2); % [m/s]
L_zs = length(zs_vec);
L_c_sed = length(c_sed_vec);
L_H = length(H_vec);
L_cb = length(cb_vec);
L_locs = config.N_LOCS;
total_sims = L_zs*L_c_sed*L_H*L_cb*L_locs;

% get indices for valid locations to sample
loc_inds = find(locs_ok == 1);

% get unique depths. we run KRAKEN at each for all environments
unique_D = unique(D_grid);
L_D = length(unique_D);

% get indices in depth list for TOSSITs. they will be used for every
% simulated source location so we store their info separately.
TOSSITs_D = D_grid(sub2ind(size(D_grid),TOSSIT_latlons_inds(:,1),TOSSIT_latlons_inds(:,2)));
[~,TOSSITs_D_inds] = ismember(TOSSITs_D,unique_D);

%----------------------------------
%       Prepare Frequency Axis
%----------------------------------
if config.FS < 2*config.FREQ_RANGE(2)
    error("FS must be >= 2*FMAX.");
end
freq_sig = 0:config.DF:config.FS-config.DF;
nfft = length(freq_sig);
min_ind_f = find_in_vec(freq_sig',config.FREQ_RANGE(1));
max_ind_f = find_in_vec(freq_sig',config.FREQ_RANGE(2));
ind_f = min_ind_f:max_ind_f;

% TODO: Setup Saving Data %

% start parallel pool
% p = parpool(config.N);

%----------------------------------
%       Parameter Loops
%----------------------------------
for i_cb = 1:L_cb

    % get current cb value
    curr_cb = cb_vec(i_cb); % [m/s]

    for i_c_sed = 1:L_c_sed

        % get current sediment sound speed
        curr_c_sed = c_sed_vec(i_c_sed); % [m/s]

        for i_H = 1:L_H

            % get current sediment thickness
            curr_H = H_vec(i_H); % [m]
            
            % sample/calculate remaining parameters
            [c_w, lambda] = kle.sample(1,config.ALPHA_V,'coeffs',true);
            rho_sed = hamilton(c_sed); % [g/cm^3]
            rho_b = hamilton(c_b); % [g/cm^3]
            alpha_sed = unifrnd(config.ALPHA_SED_RANGE(1),config.ALPHA_SED_RANGE(2)); % [dB/lambda]
            alpha_b = unifrnd(config.ALPHA_B_RANGE(1),config.ALPHA_SED_RANGE(2)); % [dB/lambda]

            % TODO: Display Progress %

            %----------------------------------------------
            %   Run KRAKEN For All Depths In Environment 
            %----------------------------------------------
            kr_krak_mem = zeros(L_D,Nf,config.NM,'single'); % [1/m]
            phi_krak_mem = zeros(L_D,Nf,config.NM,D_max + curr_H + 1,'single');
            z_axis_mem = cell(L_D,1); % [m]
        end
    end
end

fprintf("Done!\n")

