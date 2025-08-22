function [noise] = load_experimental_noise(filepath, fs_dec, n, T)
    % LOAD_EXPERIMENTAL_NOISE load noise signals from experimental data
    % from an H5 file.
    %
    % Parameters
    % ----------
    % filepath: path to H5 file containing noise signals.
    % fs_dec:   desired sampling frequency to resample to.
    % n:        desired number of signals to load.
    % T:        desired length in seconds for each signal.
    %
    % Results
    % -------
    % noise: prepared experimental noise of shape [# samples X # signals]

    % load data
    noise = h5read(filepath,"/data");
    fs = h5read(filepath,"/fs");

    % load desired number of signals
    if size(noise,2) < n
        error("'n' is less than the number of available signals.")
    else
        noise = noise(:,1:n);
    end

    % resample
    if fs_dec ~= fs
        noise = resample(noise, fs_dec, fs, Dimension=1);
    end

    % clip signals to desired length
    if round(fs_dec * T) > size(noise,1)
        error("signals are less than 'T' seconds long.");
    else
        noise = noise(1:round(fs_dec * T),:);
    end
end