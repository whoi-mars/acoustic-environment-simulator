function [b, ssp] = make_layered_b_and_ssp(D,dD_sed,cw_vec,c_sed,rho_w,rho_sed,z_vec,atten)
    % Create the sound speed profile (SSP) and medium information matrices
    % for KRAKEN.
    %
    % Input Parameters:
    % D               : Water depth.
    % dD_sed          : Thickness of sediment layer.
    % cw_vec          : 3-point vector containing sound speeds of the water
    %                   column to interpolate.
    % c_sed           : sound speed of the sediment layer.
    % rho_w           : Density of the water column.
    % z_vec           : Depth of valued in cw_vec.
    % atten           : sediment attenuation 
    %
    % Returns:
    % b   : Medium information
    % ssp : Sound speed profile
    
    Lz = length(z_vec);
    
    % Medium information
    % (1) - number mesh points
    % (2) - RMS roughness at interface
    % (3) - Depth at bottom of medium [m]
    broke = false;
    for i=1:Lz
        if z_vec(i) >= D
            broke = true;
            break;
        end
        b_cell{i,1}=[0 0.0 z_vec(i)]; % Water column
    end
    if ~broke
        i = i + 1;
    end
    b_cell{i,1}=[0 0.0 D];
    b_cell{i+1,1}=[0 0.0 D+dD_sed]; % Sediment
    b=cell2mat(b_cell);

    % Sound speed profile
    % Z()[m]  CP()[m/s]  CS()[m/s]  RHO()[g/cm^3]  AP()[dB/wavelength]  AS()[dB/wavelength]
    broke = false;
    ssp_cell{1,1} = [0.0 cw_vec(1) 0.0 rho_w 0.0 0.0];
    % CASE 1: D is below deepest SSP node
    if D > z_vec(end)
        for i=1:Lz
            ssp_cell{i+1,1}=[z_vec(i) cw_vec(i+1) 0.0 rho_w 0.0 0.0
                             z_vec(i) cw_vec(i+1) 0.0 rho_w 0.0 0.0];
        end
        ssp_cell{i+2,1}=[D cw_vec(i+2) 0.0 rho_w 0.0 0.0
                         D c_sed 0.0 rho_sed atten 0.0
                         D+dD_sed c_sed 0.0 rho_sed atten 0.0];
    % CASE 2: D is above the deepest SSP node
    elseif D <= z_vec(end)
        [M,I] = min(abs([0 z_vec] - D));
        % CASE 2a: D falls exactly on an SSP node
        if M == 0 && I > 1
            for i=1:I-1
                ssp_cell{i+1,1}=[z_vec(i) cw_vec(i+1) 0.0 rho_w 0.0 0.0
                                 z_vec(i) cw_vec(i+1) 0.0 rho_w 0.0 0.0];
            end
                ssp_cell{i+2,1}=[z_vec(i)+dD_sed c_sed 0.0 rho_sed atten 0.0];
                ssp_cell{i+1,1}(2,2) = c_sed;
        % CASE 2b: D falls in-between two SSP nodes
        elseif M ~= 0
            if I == 1
                ss = interp1([0 z_vec(1)],[cw_vec(1) cw_vec(2)],D);
                ssp_cell{2,1} = [D ss 0.0 rho_w 0.0 0.0
                                 D c_sed 0.0 rho_sed 0.0 0.0
                                 D+dD_sed c_sed 0.0 rho_sed atten 0.0];
            else
                z_vec = [0 z_vec];
                for i=2:I
                    if z_vec(i) > D
                        break;
                    end
                    ssp_cell{i+1,1}=[z_vec(i) cw_vec(i) 0.0 rho_w 0.0 0.0
                                     z_vec(i) cw_vec(i) 0.0 rho_w 0.0 0.0];
                end
                    if D < z_vec(I)
                        ss = interp1([z_vec(I-1) z_vec(I)],[cw_vec(I-1) cw_vec(I)],D);
                    else
                        ss = interp1([z_vec(I) z_vec(I+1)],[cw_vec(I) cw_vec(I+1)],D);
                    end
                    ssp_cell{i+2,1} = [D ss 0.0 rho_w 0.0 0.0
                                       D c_sed 0.0 rho_sed 0.0 0.0
                                       D+dD_sed c_sed 0.0 rho_sed atten 0.0];
            end
        else
            error("Invald SSP. D is probably 0.");
        end
    end
    ssp=cell2mat(ssp_cell);
end