# layer_uncertainty_analysis
Scripts for processing and analysing behaviour and decoding results in a study investigating the layer specific representation of sensory uncertainty.

## File structure
All analysis scripts are located in the 'scripts' directory, all data (both raw and processed) is present in the 'data' directory, and plots are saved to the 'plots' directory.

Several sources of data are provided with this repository, based on the experimental and analysis results:
* The presented orientation for each participant on each experimental trial (e.g., data/behaviour/sub-01/sub-01_oris.csv)
* The reported orientation for each participant on each trial (e.g., data/behaviour/sub-01/sub-01_reported.csv)
* The [TAFKAP](https://github.com/jeheelab/TAFKAP) output for each participant/run/layer (e.g., data/decoding/sub-01/sub-01_sup_run-01.csv). Note: the first column in this file is the presented orientation, the second column is the estimate of the presented orientation, and the third is the estimate of uncertainty.
* The SVR output for each participant/layer (e.g., data/svr/sub-01/sub-01_sup_svr.csv). Note: the first column in this file is the presented orientation and the second column is the estimate of the presented orientation. See [here](https://github.com/joshjcorbett/circular-svr) for more details on the SVR.
* The Euclidean norm of the head motion parameters for each participant/run, for each TR (e.g., data/motion_enorm/sub-01/sub-01_run-01_enorm.1D)
* The number of voxels included in the decoding analysis for each participant/layer (e.g., data/n_active_vox/sub-01/sub-01_active-vox.txt)

After following the steps in the synopsis (below) two other data directories will be created, including:
* data/processed : Contains R data storage files based on each participants' processed TAFKAP/behavioural data (prior to stats). Includes information about behavioural/decoding error, behavioural bias, behavioural variability, and decoded uncertainty.
* data/svr_processed: Contains R data storage files based on each participants' processed SVR data (i.e., no behaviour).

## Synopsis

1. Run scripts/batch_processing.sh to batch process each individual's behavioural data and TAFKAP output (this will iteratively run individual_processing.R)
2. Run scripts/batch_svr_prep.sh to batch process each individual's SVR output (this will iteratively run svr_prep.R)
3. Open/run scripts/group_stats.rmd to run group level analyses for relevant behaviour only / TAFKAP (i.e., decoding error and decoded uncertainty) analyses
4. Open/run scripts/svr_stats.rmd to run group level analyses on the SVR
5. Open/run plots.rmd to see how all visualisations were made
6. Open/run supplementary.rmd to see the statistics used to consider the relationship between decoding error (using TAFKAP) and head movement/no. voxels included in the analysis
