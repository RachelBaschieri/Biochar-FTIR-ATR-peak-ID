# Biochar-FTIR-ATR-peak-ID
The auto_linear_FTIR_spectra_baseline_correction.r applies a rolling window local minima approach to define points along the baseline of spectral data. Once the baseline points are defined, a piecewise linear function is fit to the points and this function is subtracted from the original absorbance data to create the baseline corrected spectral dataset.
file format (raw FTIR spectral data): .xlsx with a column for 'wavenumber' and a column for 'absorbance', use these exact column names 

The local_max_FTIR_peak_picker.r helps identify peaks in FTIR spectral data.
file format (baseline corrected spectra) : .xlsx with a column for 'wavenumber' and a column for 'absorbance', use these exact column names
The code defines a smooth spline for a spectral curve, identifies local maxima, then thresholds local maxima to define true peaks.

See also: UC Davis California Soil Resource Lab for your Feb. 23, 2010 article Numerical Integration/Differentiation in R: FTIR
https://casoilresource.lawr.ucdavis.edu/software/r-advanced-statistical-package/numerical-integrationdifferentiation-r-ftir-spectra
