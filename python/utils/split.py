import numpy as np
import sklearn.model_selection

def train_test_split_inds(*args, val_size=None, **kwargs):
    
    """
    Wrapper for sklearn.model_selection.train_test_split which also 
    does a validation split and assumes we are operating on indices
    """

    assert (val_size is None and 'test_size' in kwargs) or (val_size is not None and 'test_size' in kwargs),\
    "If you want to split into two sets, set only 'train_size' and/or 'test_size'."
    
    # if val_size is None, use base function
    if val_size is None:
        train_inds, test_inds = sklearn.model_selection.train_test_split(*args, **kwargs)
        return train_inds, np.asarray([]), test_inds 
        
    # get new test size
    test_size_1 = kwargs['test_size'] + val_size
    test_size_2 = np.around(kwargs['test_size'] / (val_size + kwargs['test_size']), 2)
    
    # first split
    kwargs['test_size'] = test_size_1
    train_inds, remain_inds = sklearn.model_selection.train_test_split(*args, **kwargs)
    
    # second split
    kwargs['test_size'] = test_size_2
    kwargs['train_size'] = None # clear whatever train setting we had for the first split
    val_inds, test_inds = sklearn.model_selection.train_test_split(remain_inds, **kwargs)
    
    return train_inds, val_inds, test_inds