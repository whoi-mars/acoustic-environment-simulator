function [b, ssp] = make_b_and_ssp(D,H,c_w,c_sed,rho_w,rho_sed,z,alpha_sed)
    % MAKE_B_AND_SSP Create the sound speed profile (SSP) and medium 
    % information matrices for KRAKEN.
    %
    % Parameters
    % ----------
    % D:     water depth.
    % H:     thickness of sediment layer.
    % c_w:   vector containing sound speeds of the water column.
    % c_sed: sound speed of the sediment layer.
    % rho_w: density of the water column.
    % z:     depth of values in cw_vec.
    % alpha: sediment attenuation 
    %
    % Returns
    % -------
    % b:   medium information
    % ssp: sound speed profile
    
    % check depth
    assert(D >= min(z), "D must be >= the smallest provided water SSP value.");

    %----------------------------------------------
    %              Create b Matrix 
    %----------------------------------------------
    % Medium information
    % (1) - number mesh points
    % (2) - RMS roughness at interface
    % (3) - Depth at bottom of medium [m]
    b{1,1} = [0 0 D];
    b{2,1} = [0 0 D + H];
    b = cell2mat(b);
    
    %----------------------------------------------
    %             Create ssp Matrix
    % Z()[m]  CP()[m/s]  CS()[m/s]  RHO()[g/cm^3]  AP()[dB/wavelength]  AS()[dB/wavelength]
    %----------------------------------------------
    % get length of c_w and z. should be the same.
    L_z = size(z,1);
    
    % CASE 1: D is below deepest SSP node
    if D > z(end)
        % extend known SSP as far as possible
        ssp_cell{1,1} = [z c_w zeros(L_z,1) rho_w*ones(L_z,1) zeros(L_z,2)];
        % extend the last value to the full water depth and add sediment
        ssp_cell{2,1} = [D c_w(end) zeros(L_z,1) rho_w*ones(L_z,1) zeros(L_z,2)
                         D c_sed 0 rho_sed alpha_sed 0
                         D + H c_sed 0 rho_sed alpha_sed 0];
    % CASE 2: D is above the deepest SSP node
    elseif D <= z(end)
        % compare z and D values
        z_D_diff = z - D;
        [M,I] = min(abs(z_D_diff));
        
        % CASE 2a: D falls exactly on an SSP node
        if M == 0
            % stop the SSP at water depth
            ssp_cell{1,1} = [z(1:I) c_w(1:I) zeros(I,1) rho_w*ones(I,1) zeros(I,2)];
            % sediment layer
            ssp_cell{2,1} = [D c_sed 0 rho_sed alpha_sed 0
                             D + H c_sed 0 rho_sed alpha_sed 0];
        % CASE 2b: D falls in-between two SSP nodes
        elseif z_D_diff(I) < 0
            % interpolate to get sound speed at water column depth
            c_w_interp = interp1([z(I) z(I+1)],[c_w(I) c_w(I+1)],D);

            % stop the SSP at closest water depth
            ssp_cell{1,1} = [z(1:I) c_w(1:I) zeros(I,1) rho_w*ones(I,1) zeros(I,2)];
            % sediment layer
            ssp_cell{2,1} = [D c_w_interp 0 rho_w 0 0
                             D c_sed 0 rho_sed alpha_sed 0
                             D + H c_sed 0 rho_sed alpha_sed 0];
        elseif z_D_diff(I) > 0
            % interpolate to get sound speed at water column depth
            c_w_interp = interp1([z(I-1) z(I)],[c_w(I-1) c_w(I)],D);

            % stop the SSP at the one before the closest water depth
            ssp_cell{1,1} = [z(1:I-1) c_w(1:I-1) zeros(I-1,1) rho_w*ones(I-1,1) zeros(I-1,2)];
            % sediment layer
            ssp_cell{2,1} = [D c_w_interp 0 rho_w 0 0
                             D c_sed 0 rho_sed alpha_sed 0
                             D + H c_sed 0 rho_sed alpha_sed 0];
        end
    end
    ssp = cell2mat(ssp_cell);
end