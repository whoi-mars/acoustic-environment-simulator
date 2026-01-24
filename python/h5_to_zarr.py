import os
import glob
import numpy as np
import h5py
import zarr
import yaml
from utils.split import train_test_split_inds

def convert_hdf5_shards_to_zarr(
    h5_glob_pattern: str,
    out_zarr_path: str,
    out_stats_path: str,
    keys=("p_f_re", "p_f_im", "labels"),
    chunk_samples: int = 32,
    overwrite: bool = False,
    tts=(0.8, 0.1, 0.1),
):
    """
    Convert multiple HDF5 shard files into a single Zarr store, streaming along axis 0.

    Assumptions:
      - Each shard contains datasets named in `keys`
      - Datasets have shape (n_i, ...) where axis 0 is sample index
      - All shards share identical trailing dimensions and dtypes per key
    """

    h5_files = sorted(glob.glob(h5_glob_pattern))
    if not h5_files:
        raise FileNotFoundError(f"No HDF5 files matched: {h5_glob_pattern}")

    # If overwrite, delete existing Zarr directory
    if overwrite and os.path.exists(out_zarr_path):
        import shutil
        shutil.rmtree(out_zarr_path)

    # --- First pass: compute total N and validate shapes/dtypes ---
    total_n = 0
    ref_info = {}  # key -> (dtype, tail_shape)
    shard_ns = []

    # --- Save fs (once) ---
    with h5py.File(h5_files[0], "r") as f0:
        fs = np.asarray(f0["fs"][...])

    for fp in h5_files:
        with h5py.File(fp, "r") as f:
            n = f[keys[0]].shape[0]
            shard_ns.append(n)
            total_n += n

            for k in keys:
                dset = f[k]
                tail_shape = dset.shape[1:]
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
    root = zarr.open_group(out_zarr_path, mode="a")

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
    zarr_arrays["fs"] = root.create_dataset(
                            name="fs",
                            data=fs,
                            shape=fs.shape,
                            dtype=fs.dtype,
                        )

    for k in keys:
        dtype, tail_shape = ref_info[k]
        chunks = (chunk_samples,) + tail_shape  # chunk along samples
        zarr_arrays[k] = root.create_dataset(
            name=k,
            shape=(total_n,) + tail_shape,
            chunks=chunks,
            dtype=dtype,
        )

    # --- Second pass: copy data shard by shard, chunked along sample axis ---
    write_cursor = 0
    for fp, n_shard in zip(h5_files, shard_ns):
        with h5py.File(fp, "r") as f:
            for start in range(0, n_shard, chunk_samples):
                end = min(start + chunk_samples, n_shard)
                out_start = write_cursor + start
                out_end = write_cursor + end

                for k in keys:
                    block = f[k][start:end]  # small NumPy block
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
    with open("../global_config.yaml", 'r') as yaml_file:
        global_config = yaml.load(yaml_file, Loader=yaml.Loader)

    convert_hdf5_shards_to_zarr(
        h5_glob_pattern=os.path.join(global_config["remote_paths"]["data"], "*.h5"), # "/media/mark/extradrive2/uncertain_inversion/single_sensor_spectrum_RI/sim_data/*.h5",
        out_zarr_path=os.path.join(global_config["remote_paths"]["data"], "out_dataset.zarr"), # "/media/mark/extradrive2/uncertain_inversion/single_sensor_spectrum_RI/sim_data/out_dataset.zarr",
        out_stats_path=os.path.join(global_config["remote_paths"]["data"], "split_indices.npz"), # "/media/mark/extradrive2/uncertain_inversion/single_sensor_spectrum_RI/sim_data/split_indices.npz",
        keys=("p_f_re", "p_f_im", "labels"),
        chunk_samples=32,
        overwrite=False,
        tts=[0.8, 0.1, 0.1],
    )