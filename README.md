# Biochar-FTIR-ATR-peak-ID


The local_max_FTIR_peak_picker.r helps identify peaks in FTIR spectral data.
file format (baseline corrected spectra) : .xlsx with a column for 'wavenumber' and a column for 'absorbance'
The code defines a smooth spline for a spectral curve, identifies local maxima, then thresholds local maxima to define true peaks.

See also: UC Davis California Soil Resource Lab for your Feb. 23, 2010 article Numerical Integration/Differentiation in R: FTIR
https://casoilresource.lawr.ucdavis.edu/software/r-advanced-statistical-package/numerical-integrationdifferentiation-r-ftir-spectra
