
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
[CTD, full_depth_vec] = load_asc_CTD_data(config.CTD_PATH,config.DZ,'fill_top',true);

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
rho_w = 1; % [g/cm^3]
num_TOSSITs = size(TOSSIT_latlons_grid,1);

%------------------------------------------------------------------------
%========================================================================
%                               KRAKEN
%========================================================================
%------------------------------------------------------------------------

fprintf("KRAKEN Setup...")

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

fprintf("Done!\n");

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
            rho_sed = hamilton(curr_c_sed); % [g/cm^3]
            rho_b = hamilton(curr_cb); % [g/cm^3]
            alpha_sed = unifrnd(config.ALPHA_SED_RANGE(1),config.ALPHA_SED_RANGE(2)); % [dB/lambda]
            alpha_b = unifrnd(config.ALPHA_B_RANGE(1),config.ALPHA_B_RANGE(2)); % [dB/lambda]

            % TODO: Display Progress %

            %----------------------------------------------
            %   Run KRAKEN For All Depths In Environment 
            %----------------------------------------------
            kr_krak_mem = zeros(L_D,Nf,config.NM,'single'); % [1/m]
            phi_krak_mem = zeros(L_D,Nf,config.NM,(1/config.BATHYM_ROUND) * (D_max + curr_H + 1),'single');
            z_axis_mem = cell(L_D,1); % [m]
            for i_d = 1:L_D
                
                % get current water depth
                curr_D = unique_D(i_d);

                % define receiver parameters
                nrd = (1/config.BATHYM_ROUND) * (curr_D + curr_H); % []
                rd = [config.BATHYM_ROUND, curr_D + curr_H]; % [m]
                
                % get the medium information and SSP
                [b,ssp] = make_b_and_ssp(curr_D,curr_H,c_w,curr_c_sed,rho_w,rho_sed,full_depth_vec,alpha_sed);
            
                nl = size(b,1);

                % get number of rows in SSP
                [nc,~] = size(ssp);
                
                % top/bottom halfspaces
                sspTHS = [0 343 0.000 0.00121 0 0.000];
                sspBHS = [curr_D + curr_H curr_cb 0 rho_b alpha_b 0];
                sspHS = [sspTHS; sspBHS];

                %----------------------------------------------
                % Phase Speed Limits
                % CLOW - lower phase limit [m/s]
                % CHIGH - upper phase limit [m/s]
                %----------------------------------------------
                clh=[0 max([max(ssp(:,2)), sspBHS(2)])];
                
                for i_f = 1:Nf
                    freq = freq_krak(i_f); % [Hz]
                    [vg,~,kr_re,kr_im,zm,modes] = mkrak_jb(config.NM,...
                                                           freq,...
                                                           nl,...
                                                           note1,...
                                                           b,...
                                                           nc,...
                                                           ssp,...
                                                           note2,...
                                                           bsig,...
                                                           sspHS,...
                                                           clh,...
                                                           rng,...
                                                           nsd,...
                                                           sd,...
                                                           nrd,...
                                                           rd);
                    
                    %----------------------------------------------
                    %                 Store Results 
                    %----------------------------------------------
                    kr_krak_mem(i_d,i_f,:) = kr_re + 1i*abs(kr_im);
                    mode_ind = find_in_vec(zm,curr_D + curr_H);
                    phi_krak_mem(i_d,i_f,:,1:mode_ind) = modes.';
                    z_axis_mem{i_d} = zm;
                end
            end

            %----------------------------------------------------------
            %==========================================================
            %       Use KRAKEN Results In Adiabatic Approximation 
            %==========================================================
            %----------------------------------------------------------

            %----------------------------------------------
            %      KRAKEN Results at Each TOSSIT 
            %----------------------------------------------
            % horizontal wavenumbers
            kr_krak_r = kr_krak_mem(TOSSITs_D_inds,:,:);
            % modal depth functions
            phi_krak_r = phi_krak_mem(TOSSITs_D_inds,:,:,:);
            % depth vector at each TOSSIT and receiver index
            z_axis_r = cell(1,num_TOSSITs);
            i_zr = zeros(1,num_TOSSITs);
            for t = 1:num_TOSSITs
                z_axis_r{t} = z_axis_mem{TOSSITs_D_inds(t)};
                i_zr(t) = find_in_vec(z_axis_r{t},TOSSITs_D(t)-1);
            end

            %----------------------------------------------
            %      Simulate Source at Each Location
            %----------------------------------------------
            for i_loc = 1:L_locs
                % store results
                p_m_f = zeros(nfft,config.NM,num_TOSSITs,L_zs,'single');

                %----------------------------------------------
                %                Labels/Metadata
                %----------------------------------------------
                cw_coeffs = zeros(length(lambda),L_zs,'single');
                cb_labels = zeros(1,L_zs,'single'); % [m/s]
                c_sed_labels = zeros(1,L_zs,'single'); % [m/s]
                H_labels = zeros(1,L_zs,'single'); % [m]
                zs_labels = zeros(1,L_zs,'single'); % [m]
                loc_labels = zeros(2,L_zs,'single'); % [m,m]
                r_labels = zeros(num_TOSSITs,L_zs,'single'); % [m]

                %---------------------------------------------------------
                %  Initialize Environmental Parameters for a Given Source 
                %---------------------------------------------------------
                ranges_s = zeros(1,num_TOSSITs); % [km]
                kr_integral = zeros(num_TOSSITs,Nf,config.NM); % [1/m]

                % sample location
                [y_s,x_s] = ind2sub(size(D_grid),randsample(loc_inds,1));
                
                % flag for if a shallow bathymetry region is crossed for a
                % particular source location
                shallow_flag = 0;

                for t = 1:num_TOSSITs
                    %-----------------------------------------
                    %          Get Bathymetry Slice 
                    %-----------------------------------------     
                    % get bathymetry slice for integration from source to
                    % each TOSSIT
                    [pts,r_list] = getBathymSlice(range_grids(:,:,t),...
                                                  [y_s,x_s],...
                                                  TOSSIT_latlons_inds(t,:),...
                                                  config.DR,...
                                                  mesh_x(:,:,t),...
                                                  mesh_y(:,:,t));

                    % save source-receiver range
                    ranges_s(t) = r_list(end); % [km]

                    % get depths along the source/receiver path and
                    % corresponding index in unique depth list
                    Ds_bath_path = D_grid(sub2ind(size(D_grid),pts(:,1),pts(:,2))); % [m]
                    [~,Ds_bath_path_inds] = ismember(Ds_bath_path,unique_D);

                    % check if a depth too shallow is between the source
                    % and receiver
                    if nnz(Ds_bath_path >= 0 & (Ds_bath_path < config.MIN_WATER_DEPTH))
                        shallow_flag = 1;
                        break;
                    end
                    
                    %-----------------------------------------
                    %      Zero Out Decayed Frequencies 
                    %-----------------------------------------
                    % store quantities to be integrated
                    kr_bathline = kr_krak_mem(Ds_bath_path_inds,:,:);
                    
                    % find frequency/mode indices where energy decays
                    has_zeros = ~squeeze(any(kr_bathline == 0,1));
                    has_zeros_3d(1,:,:) = has_zeros;

                    % zero out
                    kr_bathline = kr_bathline.*has_zeros_3d;
                    
                    %-----------------------------------------
                    %    Integrate And Save Relevant Values 
                    %-----------------------------------------
                    kr_integral(t,:,:) = squeeze(trapz(r_list,kr_bathline,1)); % [1/m]

                end
                
                % check if shallow water flag triggered. if so go to
                % another location
                % TODO: if triggered sample another location
                if shallow_flag
                    continue;
                end

                %----------------------------------------------------------
                %==========================================================
                %               Calculate Pressure Fields 
                %==========================================================
                %----------------------------------------------------------          
                
                % get complex scalar constant
                Q = (1i*exp(-1i*pi/4)) ./ (rho_w*sqrt(8*pi*ranges_s'));
                
                % calculate pressure fields for each source depth when
                % possible
                call_num = 1;
                for i_zs = 1:L_zs
                    
                    % get current source depth
                    curr_zs = zs_vec(i_zs); % [m]
                
                    % ensure source depth is in water column. if not skip 
                    if nnz(curr_zs >= Ds_bath_path)
                        continue;
                    end

                    %----------------------------------------------
                    %           Store Labels/Metadata
                    %----------------------------------------------
                    cw_coeffs(:,call_num) = lambda;
                    cb_labels(call_num) = curr_cb; % [m/s]
                    c_sed_labels(call_num) = curr_c_sed; % [m/s]
                    H_labels(call_num) = curr_H; % [m]
                    zs_labels(call_num) = curr_zs; % [m]
                    loc_labels(:,call_num) = [mesh_y(y_s,x_s,1); mesh_x(y_s,x_s,1)]; % [km,km], w.r.t. first TOSSIT
                    r_labels(:,call_num) = ranges_s; % [km]

                    for ff = 1:Nf
                        for mm = 1:config.NM
                            
                            % skip if wavenumbers for all TOSSITs at a
                            % given [ff,mm] are zero. check the integral
                            % and the wavenumber at the TOSSITs
                            if nnz(kr_integral(:,ff,mm)) && nnz(kr_krak_r(:,ff,mm))
                                
                                % if we've made it to this point, there is
                                % signal at at least one TOSSIT for this
                                % [ff,mm]. so we make a logical vector
                                % indicating which are nonzero.
                                valid_t_inds = (kr_integral(:,ff,mm) ~= 0) & (kr_krak_r(:,ff,mm) ~= 0);

                            end
                        end
                    end

                end

                % get current total call numbers simulated (including those
                % that were ignored)
                data = struct;
                data.total_call_count = sub2ind([L_zs L_locs L_H L_c_sed L_cb],i_zs,i_loc,i_H,i_c_sed,i_cb);

            end
        end
    end
end