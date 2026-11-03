%GENERATE_GAUSSIAN_NOISE_H5 Generate Gaussian-noise signals and save to HDF5.
%
% The HDF5 file contains:
%   /data : [numSamples x numSignals] single-precision signals
%   /fs   : scalar sampling frequency in Hz
%
% Each signal is stored as one column of /data.

clear;
clc;

% Configuration
numSignals = 10000;
durationSeconds = 10;
fs = 1000;                         % Sampling frequency, Hz
outputFile = 'gaussian_noise.h5';
batchSize = 64;                    % Number of signals generated per write
noiseMean = 0;
noiseStd = 1;

numSamples = round(durationSeconds * fs);

if numSamples < 1 || numSignals < 1
    error('numSamples and numSignals must both be positive.');
end

% Remove an existing output file so the datasets are recreated cleanly.
if isfile(outputFile)
    delete(outputFile);
end

% Create the datasets before writing. Signals are columns of /data.
h5create(outputFile, '/data', [numSamples, numSignals], ...
    'Datatype', 'single', ...
    'ChunkSize', [min(numSamples, 1000), min(numSignals, batchSize)], ...
    'Deflate', 5);
h5create(outputFile, '/fs', [1, 1], 'Datatype', 'double');
h5write(outputFile, '/fs', fs);

% Generate and write batches to keep peak memory usage bounded.
for firstSignal = 1:batchSize:numSignals
    lastSignal = min(firstSignal + batchSize - 1, numSignals);
    currentBatchSize = lastSignal - firstSignal + 1;

    noise = noiseMean + noiseStd .* randn(numSamples, currentBatchSize, 'single');
    h5write(outputFile, '/data', noise, ...
        [1, firstSignal], [numSamples, currentBatchSize]);
end

fprintf('Saved %d signals (%g seconds each, %g Hz) to %s\n', ...
    numSignals, durationSeconds, fs, outputFile);
