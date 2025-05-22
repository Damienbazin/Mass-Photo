# Mass-Photo
Pipeline for mass photometry

-----------------------------------------------------------------------------------

## MP_pipeline_live_flatflied_V2.m ou MP_pipeline_live_flatflied_V2.mlx

This script represents the **main pipeline** used to process interferometric scattering microscopy (iSCAT) data in this project.  
It converts raw ND2 images into processed HDF5 datasets, applies flat-field correction, and performs spot detection using the methods described in the previous functions.

### Overview of the Pipeline
1. **ND2 to HDF5 conversion** using `MP_convert_nd2_to_h5_raw`.
2. **Flat-field estimation**:
   - Reads a separate ND2 file (usually a background field).
   - Computes the median over all frames.
   - Applies a smoothing filter (Gaussian).
3. **Flat-field correction**:
   - The raw iSCAT frame is divided by the calculated flatfield.
   - A pseudo-flatfield correction and normalization is applied to center contrast around 1.
4. **Visualization** of both the original and corrected images.
5. **Contrast histogram** is computed for quality check.
6. **Spot detection** is performed using `detect_iSCAT_spots_localize_style`, with subpixel refinement and duplicate removal.
7. Additional detection methods (`detect_iSCAT_spots_single_v2`, `detect_iSCAT_spots_flatfielded`, etc.) are included but not functional.

### Dependencies
This pipeline relies on the following custom MATLAB functions described below:
- `MP_convert_nd2_to_h5_raw.m`
- `jiggle_spots_dam.m`
- `detect_iSCAT_spots_localize_style.m`

All these functions are required for the complete processing of iSCAT images and **were used to generate the figures 9 presented in report**.

### Example Usage
```matlab
% Step 1: Convert ND2 to HDF5
MP_convert_nd2_to_h5_raw('iSCAT_sample.nd2', 'MP_data.h5');

% Step 2: Compute flatfield from reference ND2
% Step 3: Apply flatfield correction

% Step 4: Spot detection with subpixel refinement
detect_iSCAT_spots_localize_style('MP_data_flatfielded.h5', 'spots_output.h5', 0.02);
```

### Notes
- This script processes only one frame at a time but can be easily adapted for multi-frame stacks.

-----------------------------------------------------------------------------------

## MP_convert_nd2_to_h5_raw.m

This MATLAB script performs a **raw conversion** of a Nikon ND2 video file into an HDF5 (.h5) file without any image processing.  
It is primarily used as a preprocessing step to store large microscopy datasets (e.g., iSCAT) in a more accessible and standard format for further analysis.

### Features
- Uses **Bio-Formats** (`bfGetReader`) to read `.nd2` files frame by frame.
- Extracts image dimensions and number of timepoints.
- Writes the image stack directly to a `/data` dataset in an HDF5 file with single-precision float format.
- No normalization or correction is applied (pure raw export).
- Displays progress every 100 frames.

### Required Input
- `nd2_path`: path to the `.nd2` video file.
- `output_h5_path`: path where the output `.h5` file will be saved.

### Output
- A single HDF5 file containing a 5D dataset at `/data` with dimensions `[dimX, dimY, 1, 1, nT]`.

### Notes
- Requires the **Bio-Formats MATLAB toolbox** (`bfGetReader`) to work.

-----------------------------------------------------------------------------------

## detect_iSCAT_spots_localize_style.m

This MATLAB script performs **automatic spot detection** on a single iSCAT image stored in an HDF5 file, inspired by the `localize_iSCAT_v5_3` wich is the automatic spot detection of the pipeline for SP. It includes filtering, local minima detection, subpixel adjustment, and duplicate removal.

### Features
- Reads an iSCAT image from an HDF5 file (`/data` dataset).
- Applies flat background subtraction using a uniform reference image.
- Enhances the contrast using a **Gaussian filter** (σ = 1).
- Detects **local minima** that exceed a negative contrast threshold.
- Applies **subpixel refinement** with `jiggle_spots_dam` (function explained below).
- Filters out detections too close to image borders.
- Removes **duplicate spots** that are too close (less than 10 pixels apart).
- Displays the detected spots on the original image.

### Input
```matlab
detect_iSCAT_spots_localize_style(input_h5, output_h5, contrast_thresh)
```
- `input_h5`: path to an HDF5 file containing the iSCAT image (5D dataset).
- `output_h5`: path for optional output file (currently commented out).
- `contrast_thresh`: minimum contrast (in cube-root units) to validate candidate spots.

### Output
- Detected spots (`pos_x`, `pos_y`) are optionally saved into the HDF5 file under `/spots/tp1/`.
- A plot is shown with the detected spots overlaid in red.

### Example
```matlab
detect_iSCAT_spots_localize_style('flatfielded_sample.h5', 'spots_detected.h5', 0.015);
```

### Notes
- The cube-root contrast threshold (`contrast_thresh^3`) is used to match legacy `localize` behavior.
- A fixed CRUD mask (10-pixel border) is applied to avoid edge artifacts.
- Use this script in conjunction with:
  - `MP_convert_nd2_to_h5_raw.m` (for ND2 → HDF5 conversion)
  - `jiggle_spots_dam.m` (for subpixel centering)



-----------------------------------------------------------------------------------

## jiggle_spots_dam.m

This MATLAB function is used in the iSCAT image processing pipeline to **refine the position of detected spots**. It adjusts each spot's location by snapping it to a nearby local intensity **extremum** (minimum or maximum) within a defined search radius, thereby improving spot centering and precision.

### Features
- Shifts detected spot coordinates to:
  - the nearest local **minimum**, **maximum**, or
  - the **highest-contrast extremum** depending on user choice.
- Uses `imregionalmin` / `imregionalmax` for extremum detection.
- Allows for customization of:
  - `brightness` (controls search for minima/maxima),
  - `max_dist` (search window radius),
  - `snap_to` method (`'nearest'` or `'highest_contrast'`),
  - whether to `remove_duplicates`.
- Ensures output coordinates remain within image bounds.

### Input Arguments
```matlab
[pos_x_out, pos_y_out, success] = jiggle_spots_dam(frame, pos_x, pos_y, ...)
```
- `frame` : 2D image where the spots are detected.
- `pos_x`, `pos_y` : initial spot positions (arrays of equal length).

### Output
- `pos_x_out`, `pos_y_out`: updated spot positions.
- `success`: logical flag indicating if snapping succeeded for at least one spot.

### Notes
- Used to refine detections after candidate selection.
- Spots outside the image or with no valid extremum in their neighborhood are discarded.


