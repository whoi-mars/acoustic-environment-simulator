import os
import glob
import numpy as np
import h5py
import zarr
import yaml

from utils.split import train_test_split_inds


def get_dimension_names(name, shape):
    """
    Return xarray-compatible dimension names for a Zarr array.
    """
    # number of dimensions
    ndim = len(shape)

    # determine dimension names based on dataset name and shape
    if name in {"p_f_re", "p_f_im"}:
        return ("sample",) + tuple(f"pressure_dim_{i}" for i in range(1, ndim))
    if name == "labels":
        return ("sample",) + tuple(f"label_dim_{i}" for i in range(1, ndim))
    if name == "fs" and ndim == 1:
        return ("frequency",)
    if name == "df" and ndim == 1:
        return ("dfrequency",)
    if name == "depth_vec" and ndim == 1:
        return ("depth",)
    if name == "mu" and ndim == 1:
        return ("latent",)
    if name == "V" and ndim == 2:
        return ("depth", "latent")
    if name in {"D", "sigma"} and ndim == 1:
        return ("latent",)

    return tuple(f"{name}_dim_{i}" for i in range(ndim))


def infer_sample_axes(h5_file, keys):
    """
    Return axis 0 as the sample axis for every dataset.
    """
    sample_count = h5_file[keys[0]].shape[0]
    sample_axes = {}
    for key in keys:
        shape = h5_file[key].shape
        if not shape or shape[0] != sample_count:
            raise ValueError(
                f"Expected {key} to have {sample_count} samples on axis 0, "
                f"for {key}, whose shape is {shape}."
            )
        sample_axes[key] = 0

    return sample_count, sample_axes


def convert_hdf5_shards_to_zarr(
    data_path,
    keys=("p_f_re", "p_f_im", "labels"),
    chunk_samples=32,
    overwrite=False,
    tts=(0.8, 0.1, 0.1),
):
    """
    Convert multiple HDF5 shard files into a single Zarr store, streaming along axis 0.

    Assumptions:
      - Each shard contains datasets named in `keys`
      - HDF5 datasets have samples on axis 0; output Zarr arrays are also
        sample-first
      - All shards share identical trailing dimensions and dtypes per key
    """

    # get needed paths
    h5_glob_pattern = os.path.join(data_path, "*.h5")
    out_zarr_path = os.path.join(data_path, "out_dataset.zarr")
    out_stats_path = os.path.join(data_path, "split_indices.npz")

    # get MATLAB-generated h5 files
    h5_files = sorted(glob.glob(h5_glob_pattern))
    if not h5_files:
        raise FileNotFoundError(f"No HDF5 files matched: {h5_glob_pattern}")

    # filter out KLE.h5 if it exists
    h5_files = [
        file_path for file_path in h5_files 
        if os.path.basename(file_path) != "KLE.h5"
    ]

    # If overwrite, delete existing Zarr directory
    if overwrite and os.path.exists(out_zarr_path):
        import shutil
        shutil.rmtree(out_zarr_path)

    # --- First pass: compute total N and validate shapes/dtypes ---
    total_n = 0
    ref_info = {}  # key -> (dtype, tail_shape)
    shard_ns = []
    shard_sample_axes = []

    # --- Save fs and df (once) ---
    with h5py.File(h5_files[0], "r") as f0:
        fs = np.asarray(f0["fs"][...])
        df = np.asarray(f0["df"][...])

    if os.path.exists(os.path.join(data_path, "KLE.h5")):
        with h5py.File(os.path.join(data_path, "KLE.h5"), "r") as f:
            mu = f["mu"][:]
            V = f["V"][:]
            D = f["D"][:]
            sigma = f["sigma"][:]
            depth_vec = f["depth_vec"][:]

    for fp in h5_files:
        with h5py.File(fp, "r") as f:
            n, sample_axes = infer_sample_axes(f, keys)
            shard_ns.append(n)
            shard_sample_axes.append(sample_axes)
            total_n += n

            for k in keys:
                dset = f[k]
                sample_axis = sample_axes[k]
                tail_shape = dset.shape[:sample_axis] + dset.shape[sample_axis + 1:]
                dtype = dset.dtype
                if k not in ref_info:
                    ref_info[k] = (dtype, tail_shape)
                else:
                    ref_dtype, ref_tail = ref_info[k]
                    if tail_shape != ref_tail:
                        raise ValueError(f"Shape mismatch for {k} in {fp}: {tail_shape} != {ref_tail}")
                    if dtype != ref_dtype:
                        raise ValueError(f"Dtype mismatch for {k} in {fp}: {dtype} != {ref_dtype}")

    # --- Create Zarr group at the given path ---
    root = zarr.open_group(out_zarr_path, mode="a", zarr_format=3)

    # Guard against accidentally clobbering arrays when overwrite=False
    for k in keys:
        if k in root:
            raise ValueError(
                f"Zarr array '{k}' already exists in {out_zarr_path}. "
                "Set overwrite=True or choose a new output path."
            )

    # --- Create Zarr arrays (no explicit compressor: let Zarr pick defaults) ---
    zarr_arrays = {}

    # Create fs array in Zarr (1D, small)
    zarr_arrays["fs"] = root.create_array(
        name="fs",
        data=fs,
        dimension_names=get_dimension_names("fs", fs.shape),
    )

    # Create df array in Zarr (1D, small)
    zarr_arrays["df"] = root.create_array(
        name="df",
        data=df,
        dimension_names=get_dimension_names("df", df.shape),
    )
    
    if os.path.exists(os.path.join(data_path, "KLE.h5")):
        for name, values in {
            "mu": mu,
            "V": V,
            "D": D,
            "sigma": sigma,
            "depth_vec": depth_vec,
        }.items():
            zarr_arrays[name] = root.create_array(
                name=name,
                data=values,
                dimension_names=get_dimension_names(name, values.shape),
            )

    for k in keys:
        dtype, tail_shape = ref_info[k]
        chunks = (chunk_samples,) + tail_shape  # chunk along samples
        array_shape = (total_n,) + tail_shape
        zarr_arrays[k] = root.create_array(
            name=k,
            shape=array_shape,
            chunks=chunks,
            dtype=dtype,
            dimension_names=get_dimension_names(k, array_shape),
        )

    # --- Second pass: copy data shard by shard, chunked along sample axis ---
    write_cursor = 0
    for fp, n_shard, sample_axes in zip(h5_files, shard_ns, shard_sample_axes):
        with h5py.File(fp, "r") as f:
            for start in range(0, n_shard, chunk_samples):
                end = min(start + chunk_samples, n_shard)
                out_start = write_cursor + start
                out_end = write_cursor + end

                for k in keys:
                    sample_axis = sample_axes[k]
                    source_slices = [slice(None)] * f[k].ndim
                    source_slices[sample_axis] = slice(start, end)
                    block = f[k][tuple(source_slices)]
                    block = np.moveaxis(block, sample_axis, 0)
                    zarr_arrays[k][out_start:out_end] = block

        write_cursor += n_shard
        print(f"Copied {fp} ({n_shard} samples). Total written: {write_cursor}/{total_n}")

    print(f"Done. Zarr written to: {out_zarr_path}")

    ##########################################################################
    #                GENERATE TRAIN/VAL/TEST SPLIT INDICES                   #
    ##########################################################################

    # get split percentages
    train_split, val_split, test_split = tts[0], tts[1], tts[2]

    # get split indices
    train_inds, val_inds, test_inds = train_test_split_inds(np.arange(total_n), train_size=train_split, test_size=test_split, val_size=val_split)

    # save indices
    np.savez(out_stats_path,
            train_inds=train_inds,
            val_inds=val_inds,
            test_inds=test_inds)

if __name__ == "__main__":
    # load global config file
    with open("../config_global.yaml", 'r') as yaml_file:
        config_global = yaml.load(yaml_file, Loader=yaml.Loader)

    # load paths
    if config_global["local"]:
        noise_path = config_global["local_paths"]["noise"]
        data_path = os.path.join(config_global["local_paths"]["data"], "target")
    else:
        noise_path = config_global["remote_paths"]["noise"]
        data_path = os.path.join(config_global["remote_paths"]["data"])

    convert_hdf5_shards_to_zarr(
        data_path=data_path,
        keys=("p_f_re", "p_f_im", "labels"),
        chunk_samples=32,
        overwrite=False,
        tts=[0.8, 0.1, 0.1],
    )
