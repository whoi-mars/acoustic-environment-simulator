import sys
import os
import glob
from pathlib import Path
import h5py
import json
from tqdm import tqdm
import numpy as np

# Ensure imports resolve against this repo's local python/ directory first.
SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from utils.split import train_test_split_inds

##########################################################################
#                            CONFIGURATION                               #
##########################################################################

# saved data that is constant for every signal
constants = ["fs", "df"]

##########################################################################
#                             GET H5 FILES                               #
##########################################################################

# where the data has been saved
data_dir = sys.argv[1]

# load config file JSON and get lower case keys
# with open(os.path.join(data_dir, 'config.json'), 'r') as f:
#     config = json.load(f)
# config_keys = [k.lower() for k in config.keys()]

# get .h5 files in data directory
files = glob.glob(sys.argv[1] + '/*.h5')

# get keys in each data file by peaking at one
with h5py.File(files[0], "r") as f:
    entry_keys = list(f.keys())

# determine which keys are config variables because
# these are constant and only need one virtual source
# stored_config_keys = []
# data_keys = []
# for k in entry_keys:
#     if k.lower() in config_keys:
#         stored_config_keys.append(k)
#     else:
#         data_keys.append(k)

sources_dict = {k : [] for k in entry_keys} # store virtual sources for each key
shape_dict = {} # store data shape for each key
dtype_dict = {} # store data type for each key
total_length = 0 # keep track of dataset length

for i, filename in enumerate(tqdm(files), start=1):
    with h5py.File(filename, 'r') as f:
        for k in entry_keys:

            # use first file to get entry shapes and dtypes
            if i == 1:
                shape_dict[k] = f[k].shape[1:]
                dtype_dict[k] = f[k].dtype

            # only add one source for keys that are also in the config
            # because they are assumed constant
            if k in constants and i > 1:
                continue
            else:
                vsource = h5py.VirtualSource(f[k])
                sources_dict[k].append(vsource)

        # add to total dataset length
        total_length += f['p_f_re'].shape[0]

# make layouts
layout_dict = {}
for k in entry_keys:
    if k in constants:
        layout_dict[k] = h5py.VirtualLayout(shape=(1,)+shape_dict[k], dtype=dtype_dict[k])
    else:
        layout_dict[k] = h5py.VirtualLayout(shape=(total_length,)+shape_dict[k], dtype=dtype_dict[k])

# fill layouts
for k in entry_keys:
    offset = 0
    for vsource in sources_dict[k]:
        length = vsource.shape[0]
        layout_dict[k][offset:offset+length] = vsource
        offset += length

# create virtual dataset
with h5py.File(os.path.join(data_dir, "VDS_main.h5"), 'w', libver='latest') as f:
    for k in entry_keys:
        f.create_virtual_dataset(k, layout_dict[k], fillvalue=0)
        
##########################################################################
#                GENERATE TRAIN/VAL/TEST SPLIT INDICES                   #
##########################################################################

# get split percentages
train_split, val_split, test_split = float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])

# get split indices
train_inds, val_inds, test_inds = train_test_split_inds(np.arange(total_length), train_size=train_split, test_size=test_split, val_size=val_split)

# save indices
np.savez(os.path.join(data_dir, "split_indices.npz"),
         train_inds=train_inds,
         val_inds=val_inds,
         test_inds=test_inds)
