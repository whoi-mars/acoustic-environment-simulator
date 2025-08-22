function rho = hamilton(c)
    % HAMILTON Calculate layer density from sound speed using Hamilton
    % relations.
    %
    % Parameters
    % ----------
    % c: layer sound speed in m/s.
    %
    % Returns
    % -------
    % rho: layer density in g/cm^3

    % convert units
    c = c/1000; % [km/s]

    if ((c >= 1.55) && (c < 1.9))
        rho = 1.135*c - 0.190;
    elseif((c >= 1.90) && (c < 3.0))
        rho = 2.351 - 7.497*c^-4.656;
    elseif((c >= 3.0) && (c < 6.60))
        rho = 1.979*c + 0.112;
    else
        % warning('out of hamilton bounds');
        rho = 1.5;
    end
end