import numpy as np

def trim_dc(arr, axis):
    """
    Function to trim the dispersion curves near the cutoff frequency. In a more
    technical sense, the function looks along 'axis' in 'arr' and finds the first
    point at which it starts to decrease. Then, all values before this point are
    set to np.nan.

    Parameters
    ----------
    arr : array-like
        numpy array of interst
    axis : int
        axis of interest within arr

    Returns
    -------
    arr : array-like
        arr with values along 'axis' before the first increase --> decrease transition
        set to np.nan
    """

    # ------ get indices -------- 

    # get differences along the axis of interest
    diffs = np.diff(arr, axis=axis)

    # compare diffs to diffs offset by 1 to detect a shift from positive to negative
    cond = (np.take(diffs, indices=range(diffs.shape[axis]-1), axis=axis) >= 0) & \
            (np.take(diffs, indices=range(1, diffs.shape[axis]), axis=axis) < 0)

    # add a false slice to the end to make it the same shape as diffs
    pad_shape = list(cond.shape)
    pad_shape[axis] = 1
    false_pad = np.zeros(pad_shape, dtype=bool)
    cond_padded = np.concatenate([cond, false_pad], axis=axis)

    # get first indieces
    first_idx_in_cond = np.argmax(cond_padded, axis=axis, keepdims=True)

    # detect slices with no True (no flip)
    has_flip = cond.any(axis=axis, keepdims=True)

    # convert to array index space (k+1). If non, set -1
    indices = np.where(has_flip, first_idx_in_cond + 1, -1).astype(int)

    # ------ zero out dispersion curves -------- 

    # ensure we can write nans
    out = arr.astype(float, copy=True)
    n = out.shape[axis]

    # indices 0..n-1 along the axis of interest shaped for broadcasting
    pos = np.arange(n)
    shp = [1] * out.ndim
    shp[axis] = n
    pos = pos.reshape(shp)
    
    # mask for elements before the index
    mask = pos < indices

    # apply mask
    out[mask] = np.nan

    return out