%------------------------------------------------------------------------
%========================================================================
%                             Setup
%========================================================================
%------------------------------------------------------------------------

%------------------------
%     Save Config
%------------------------
struct2json(config,fullfile(config.DATA_PATH,'config.json'));

%-------------------------------------
%         Constant Parameters
%-------------------------------------
fs = 2*config.FREQ_RANGE(2); % [Hz]
T = 1/config.DF; % [s]
rho_w = 1.0; % [g/cm^3]
freq_krak = config.FREQ_RANGE(1):config.DF:config.FREQ_RANGE(2); % [Hz]
Nf = length(freq_krak); % []
find_tolerance = 1e-6; % []

%-------------------------------------
%             Load Noise
%-------------------------------------
if config.ADD_NOISE
    fprintf('Loading Noise Examples...');
    noise = load_experimental_noise(config.NOISE_PATH, fs, config.ADD_NOISE, T);
    fprintf("Done!\n");
else
    % required for parfor
    noise_from_data = [];
end

%------------------------------------------------------------------------
%========================================================================
%                             Run Simulations
%========================================================================
%------------------------------------------------------------------------

disp('Running Simulation(s)...');

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
rng=0;

%----------------------------------
%   Set Sources For Depth Vector 
%----------------------------------
% exact source depth is not relevant. The goal here is just to get
% the returned z vector to be 0:1:D_basement.
nsd=1;
sd=0; % [m]

%----------------------------------
%      Set Parameter Vectors 
%----------------------------------
csed_vec = config.CSED_RANGE(1):config.DELTA_CSED:config.CSED_RANGE(2); % [m/s]
cb_vec = config.CB_RANGE(1):config.DELTA_CB:config.CB_RANGE(2); % [m/s]
zs_vec = config.ZS_RANGE(1):config.DELTA_ZS:config.ZS_RANGE(2); % [m]
r_vec = config.R_RANGE(1):config.DELTA_R:config.R_RANGE(2); % [m]
H_vec = config.H_RANGE(1):config.DELTA_H:config.H_RANGE(2); % [m]
L_cb = length(cb_vec);
L_csed = length(csed_vec);
L_zs = length(zs_vec);
L_r = length(r_vec);
L_H = length(H_vec);
total_sims = L_cb*L_csed*L_zs*L_r*L_H;
per_env_sims = L_r*L_zs;

%----------------------------------
%  Prepare signal Frequency Axis 
%----------------------------------
freq_sig = 0:config.DF:fs-config.DF; % [Hz]
nfft = length(freq_sig);
min_ind_f = find_in_vec(freq_sig,config.FREQ_RANGE(1),'thresh',find_tolerance);
max_ind_f = find_in_vec(freq_sig,config.FREQ_RANGE(2),'thresh',find_tolerance);
ind_f = min_ind_f:max_ind_f;

%----------------------------------
%         Parameter Loops
%----------------------------------
if config.SAVE_RESULTS
    q = parallel.pool.DataQueue;
    afterEach(q,@(data) update(data,config.DATA_PATH,config.NM,config.ENV_CHUNK,L_r*L_zs,nfft,total_sims));
end

% queue for displaying progress
prog_q = parallel.pool.DataQueue;
afterEach(prog_q,@(prog_info) updateProgress(prog_info));

% start parallel pool
p = parpool(config.N);

tic
parfor i_cb = 1:L_cb
    % grab current cb value
    curr_cb = cb_vec(i_cb); % [m/s]
    for i_csed = 1:L_csed
        % grab current csed value
        curr_csed = csed_vec(i_csed); % [m/s]
        for i_H = 1:L_H
            % grab current H value
            curr_H = H_vec(i_H); % [m]

            % sample/calculate remaining non-concstant parameter
            % for a particular environement
            D = randi(config.D_RANGE); % [m]
            zr = D - 1; % [m]
            cw_vec = unifrnd(config.CW_RANGE(1), config.CW_RANGE(2), 1, length(config.CW_NODE_DEPTHS)+2); % [m/s]
            rho_sed = hamilton(curr_csed); % [g/cm^3]
            rho_b = hamilton(curr_cb); % [g/cm^3]
            b_alpha = unifrnd(config.B_ALPHA_RANGE(1), config.B_ALPHA_RANGE(2)); % [dB/wavelength]
            sed_alpha = unifrnd(config.SED_ALPHA_RANGE(1), config.SED_ALPHA_RANGE(2)); % [dB/wavelength]

            % display progress
            prog_info = sprintf("/%d -- c_b: %s m/s -- c_sed: %s m/s -- H: %s m\n",...
                    L_H*L_csed*L_cb,...
                    string(curr_cb),...
                    string(curr_csed),...
                    string(curr_H));
            send(prog_q, prog_info);

            % storage for labels
            t_max = zeros(1,per_env_sims,'single'); % [s]
            t_min = zeros(1,per_env_sims,'single'); % [s]
            cb_labels = zeros(1,per_env_sims,'single'); % [m/s]
            cw_labels = zeros(length(config.CW_NODE_DEPTHS)+2,per_env_sims,'single'); % [m/s]
            z_labels = zeros(length(config.CW_NODE_DEPTHS),'single'); % [m]
            c_sed_labels = zeros(1,per_env_sims,'single'); % [m/s]
            H_labels = zeros(1,per_env_sims,'single'); % [m]
            D_labels = zeros(1,per_env_sims,'single'); % [m]
            r_labels = zeros(1,per_env_sims,'single'); % [m]
            zs_labels = zeros(1,per_env_sims,'single'); % [m]

            % storage for KRAKEN output
            vg_krak = zeros(Nf,config.NM); % [m/s]
            kr_krak = zeros(Nf,config.NM); % [1/m]
            phi_krak = zeros(Nf,config.NM,D+curr_H+1); % []

            % run KRAKEN
            % number of receiver depths
            nrd = D + curr_H;
            % receiver depth range
            rd = [1 D+curr_H];
            % make environment
            [b,ssp] = make_layered_b_and_ssp(D,curr_H,cw_vec,curr_csed,rho_w,rho_sed,config.CW_NODE_DEPTHS,sed_alpha);
            % get number of layers
            nl = length(unique(ssp(:,1))) - 1;
            % number of columns in ssp object
            [nc,~] = size(ssp);
            % halfspace conditions
            sspTHS = [0, 343, 0.000, 0.00121, 0 0.000];
            sspBHS = [D+curr_H curr_cb 0.0 rho_b b_alpha 0.0];
            sspHS = [sspTHS; sspBHS];
            % phase speed limitations
            clh=[0 max([max(ssp(:,2)), sspBHS(2)])]; % [m/s]
            for ff=1:Nf
                frq = freq_krak(ff);
                [vg,~,kr_re,kr_im,zm,modes] = mkrak_jb(config.NM,...
                                                       frq,...
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
                vg_krak(ff,:) = vg;
                phi_krak(ff,:,:) = modes.';
                kr_krak(ff,:) = kr_re - 1i*abs(kr_im);
            end
            [vg,~,~,~,~,~] = mkrak_jb(config.NM,...
                                      config.F_ASYM,...
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
            vg_krak_asym = max(vg); % [m/s]

            %------------------------------------------------
            %          Calculate Pressure Fields
            %------------------------------------------------
            % keep track of call
            call_num = 1;
            % instantiate for parallel processing
            data = [];
            % index of receiver in depth vector
            zr_idx = find(zm == zr); % []
            % store signals
            p_m_f = zeros(nfft,config.NM,per_env_sims);
            for i_r = 1:L_r
                % get current range
                curr_r = r_vec(i_r); % [m]

                % get Q constant
                Q = (1i*exp(-1i*pi/4)) / (rho_w*sqrt(8*pi));

                for i_zs = 1:L_zs
                    % get current source depth and index in depth
                    % vector
                    curr_zs = zs_vec(i_zs); % [m]
                    curr_zs_idx = find(zm == zs_vec(i_zs)); % []

                    % check that source depth is in the water column
                    assert(D > curr_zs, "source depth not in the water column.");

                    % get current total call number
                    data.total_call_count = sub2ind([L_zs,L_r,L_H,L_csed,L_cb],i_zs,i_r,i_H,i_csed,i_cb);

                    % store labels
                    cb_labels(call_num) = curr_cb;
                    cw_labels(:,call_num) = cw_vec;
                    z_labels(:,call_num) = config.CW_NODE_DEPTHS;
                    c_sed_labels(call_num) = curr_csed;
                    H_labels(call_num) = curr_H;
                    D_labels(call_num) = D;
                    r_labels(call_num) = curr_r;
                    zs_labels(call_num) = curr_zs;

                    % store signal start/end times
                    vg_krak_curr = vg_krak;
                    vg_krak_curr(vg_krak_curr == 0) = NaN;
                    t_min(call_num) = curr_r / vg_krak_asym;
                    t_max(call_num) = curr_r / min(vg_krak_curr,[],"all");

                    % skip if call doesn't fit into window
                    if t_max(call_num) - t_min(call_num) > T
                        continue;
                    end

                    % apply duration filter if set
                    if config.DURATION_FILTER > 0 && ((t_max(call_num) - t_min(call_num) < config.DURATION_FILTER))
                        continue;
                    end
                    

                    % calculate pressure field
                    for ff=1:Nf
                        for mm=1:config.NM
                            if kr_krak(ff,mm) ~= 0
                                p_m_f(ind_f(ff),mm,call_num) = Q.*phi_krak(ff,mm,curr_zs_idx).*phi_krak(ff,mm,zr_idx)...
                                                               .*exp(-1i*curr_r*kr_krak(ff,mm)) / sqrt(curr_r*kr_krak(ff,mm))...
                                                               .*exp(2*1i*pi*freq_sig(ind_f(ff))*t_min(call_num));
                            end
                        end
                    end

                    % iterate call number for current environment
                    call_num = call_num + 1;

                end
            end

            % no successful calls
            if call_num == 1
                continue;
            end

            % sum modes
            p_f = squeeze(sum(p_m_f,2));

            % aggregate labels
            labels = [cb_labels
                      cw_labels
                      z_labels
                      c_sed_labels
                      H_labels
                      D_labels
                      r_labels
                      zs_labels];

            % trim storage vectors to simulated calls
            p_f = p_f(:,1:call_num-1);
            t_min = t_min(1:call_num-1);
            t_max = t_max(1:call_num-1);
            labels = labels(:,1:call_num-1);

            % add noise
            if config.ADD_NOISE
                % get noise examples
                noise_data = noise(:,randi(size(noise,2),1,size(p_f,2)));

                % randomly shift noise
                for i = 1:size(noise_data,2)
                    noise_data(:,i) = circshift(noise_data(:,i),randi(T*fs),1);
                end

                % get fft of noise signal
                noise_data = (1/nfft) * fft(noise_data,nfft,1);

                % zero out part of spectrum not generated by KRAKEN
                % along with the second half of the spectrum
                noise_data(1:min_ind_f-1,:) = 0;
                noise_data(max_ind_f+1:end,:) = 0;

                % add noise
                [p_f, snr] = add_noise(p_f, noise_data, config.SNR_RANGE);

                % save SNR labels
                labels = [labels; snr];
            end

            % random signal shift
            if config.RANDOM_SHIFT
                durations = t_max - t_min;
                for i = 1:size(p_f,2)
                    p_f(:,i) = circshift(p_f(:,i),randi(ceil(T*fs - durations(i)*fs)),1);
                end
            end

            % populate data struct for saving
            data.t_far = t_max;
            data.t_close = t_min;
            data.p_f = p_f;
            data.labels = labels;
            data.fs = fs;
            data.df = config.DF;
            data.T = T;
            data.chunk_size = call_num - 1;
            data.num_labels = size(cb_labels,1)...
                              + size(cw_labels,1)...
                              + size(z_labels,1)...
                              + size(c_sed_labels,1)...
                              + size(H_labels,1)...
                              + size(D_labels,1)...
                              + size(r_labels,1)...
                              + size(zs_labels,1);
            if config.ADD_NOISE
                data.num_labels = data.num_labels + 1;
            end 

            if config.SAVE_RESULTS
                update(data,config.DATA_PATH,config.ENV_CHUNK,per_env_sims,nfft,total_sims);
            end
        end
    end
end
toc






function updateProgress(prog_info)
    % UPDATEPROGRESS Callback function to display the progress in iterating 
    % through the different environments.
    % 
    % Parameters
    % ----------
    % prog_info : string that displays progress the "counter" value is
    %             prepended to the beginning of it before display.

    % load/initialize counter for environmnets
    persistent counter;
    if isempty(counter)
        counter = 1;
    end
    
    % display progress
    fprintf("\n" + string(counter) + prog_info);
    
    % iterate counter
    counter = counter + 1;
end

function update(data,path,L_CHUNK,N_SIGS,nfft,total_sims)
    % UPDATE Callback function used to save data in chunks.
    %
    % Parameters
    % ----------
    % data:        data struct containing relevant objects for each save.
    %               - p_f:         frequency domain signals.
    %               - labels:      matrix of labels.
    %               - fs:          sampling frequency.
    %               - df:          discrete step used to sample frequency.
    %               - i_loc:       index of sampled source location.
    %               - chunk_size:  number of simulated signals fed to 
    %                              function.
    %               - num_labels:  number of labels in 'labels'.
    %               - t_close:     arrival time of simulated signals at the 
    %                              receiver.
    %               - t_far:       end time of simulated signals at the 
    %                              receiver.
    %               - vg_integral: group speeds for each mode.
    % path:        path to directory where data is to be saved.
    % NM:          number of modes simulated.
    % L_CHUNK:     number of locations to save data from in a single file.
    % N_SIGS:      number of signals simulated per location.
    % total_sims:  total number of simulated signals to be
    %              produced/attempted.

    % persistent variables to save
    persistent p_f labels t_close t_far df fs;

    % persistent counter to know when to save a file
    persistent counter;

    % initialize when called the first time. note that we initialize with
    % an extra environment's worth of memory
    if isempty(p_f)
        t_far = zeros(1,(L_CHUNK+1)*N_SIGS,'single');
        t_close = zeros(1,(L_CHUNK+1)*N_SIGS,'single');
        p_f = zeros(nfft,(L_CHUNK+1)*N_SIGS,'single');
        labels = zeros(data.num_labels,(L_CHUNK+1)*N_SIGS,'single');
        fs = data.fs;
        df = data.df;
    
        counter = 1;
    end

    % add new data
    t_far(:,counter:counter+data.chunk_size-1) = data.t_far;
    t_close(:,counter:counter+data.chunk_size-1) = data.t_close;
    p_f(:,counter:counter+data.chunk_size-1) = data.p_f;
    labels(:,counter:counter+data.chunk_size-1) = data.labels;

    % iterate counter
    counter = counter + data.chunk_size;

    if data.total_call_count == total_sims
        % we are at the last chunk of data to be simulated and save now

        if counter >= L_CHUNK*N_SIGS + 2
            % save full file
            parsave_RI(path,p_f(:,1:L_CHUNK*N_SIGS),t_far(:,1:L_CHUNK*N_SIGS),t_close(:,1:L_CHUNK*N_SIGS),labels(:,1:L_CHUNK*N_SIGS),fs,df)
            
            % pause so timestamps are unique
            pause(10);

            % save remainder
            parsave_RI(path,p_f(:,L_CHUNK*N_SIGS+1:counter-1),t_far(:,L_CHUNK*N_SIGS+1:counter-1),t_close(:,L_CHUNK*N_SIGS+1:counter-1),labels(:,L_CHUNK*N_SIGS+1:counter-1),fs,df)
        else
            % clear out remaining empty elements. there will always be extra
            % because of the extra memory initialized
            t_far(:,counter:end) = [];
            t_close(:,counter:end) = [];
            p_f(:,counter:end) = [];
            labels(:,counter:end) = [];
    
            % save calls
            parsave_RI(path,p_f,t_far,t_close,labels,fs,df)
        end
        return;
    elseif counter >= L_CHUNK*N_SIGS + 1
        % if we've filled the persistent variables, we save now

        % save calls
        parsave_RI(path,p_f(:,1:L_CHUNK*N_SIGS),t_far(:,1:L_CHUNK*N_SIGS),t_close(:,1:L_CHUNK*N_SIGS),labels(:,1:L_CHUNK*N_SIGS),fs,df)
            
        % reset persistent variables, carrying over extra signals that did
        % not fit in the save chunk if they exist
        mod_res = mod(counter,L_CHUNK*N_SIGS+1);
        if mod_res == 0
            % no left over signals

            % zero out vectors
            t_far(:) = 0;
            t_close(:) = 0;
            p_f(:) = 0;
            labels(:) = 0;

            % reset counter
            counter = 1;
        else
            t_far(:,1:mod_res) = t_far(:,L_CHUNK*N_SIGS+1:L_CHUNK*N_SIGS+mod_res);
            t_far(:,mod_res+1:end) = 0;
            t_close(:,1:mod_res) = t_close(:,L_CHUNK*N_SIGS+1:L_CHUNK*N_SIGS+mod_res);
            t_close(:,mod_res+1:end) = 0;
            p_f(:,1:mod_res) = p_f(:,L_CHUNK*N_SIGS+1:L_CHUNK*N_SIGS+mod_res);
            p_f(:, mod_res+1:end) = 0;
            labels(:,1:mod_res) = labels(:,L_CHUNK*N_SIGS+1:L_CHUNK*N_SIGS+mod_res);
            labels(:,mod_res+1:end) = 0;

            % reset counter
            counter = mod_res + 1;
        end

        return;
    else
        return;
    end
end