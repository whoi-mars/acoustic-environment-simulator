function [signal_f_out,snr] = add_noise(s,n,snr_range)
    % ADD_NOISE Add noise to signal with SNR sampled from a specified
    % range.
    %
    % Parameters
    % ----------
    % s:         signals from multiple sensors of shape [# samples X # sensors].
    % n:         noise signals of the same shape as 's'.
    % snr_range: range of SNR values to sample from.
    %
    % Returns
    % -------
    % signal_f_out: 's' with noise added.
    % snr:          SNR of each signal contained in the columns of
    %               'signal_f_out'.
    
    assert(isequal(size(s),size(n)),"'s' and 'n' must be the same size.");

    % get number of signals
    num_sigs = size(s,2);

    % sample SNRs
    snr = unifrnd(snr_range(1),snr_range(2),1,num_sigs);

    % calculate linear SNRs
    snr_linear = 10.^(snr/10);

    % get signal and noise energies
    Es = sum(abs(s).^2,1);
    En = sum(abs(n).^2,1);

    % noise scaling constant
    A = sqrt(Es ./ (snr_linear.*En));
    
    % calculate final signal
    signal_f_out = s + A.*n;
end