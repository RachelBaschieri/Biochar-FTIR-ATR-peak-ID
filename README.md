# Biochar-FTIR-ATR-peak-ID
Helps identify peaks in spectral data and assign functional groups.

file format : .xlsx with a column for 'wavenumber' and a column for 'absorbance'

The code defines a smooth spline for a spectral curve and uses the first derivative of the curve to identify peaks and valleys (where the first derivative crosses zero) and the second derivative to identify peaks (where the second derivative is negative).  Functional group assignments based on Table 18.1 in Biochar: A Guide to Analytical Methods. 	Johnston, C.T.. (2017). Biochar analysis by Fourier-transform infra-red spectroscopy. In Singh, B., Camps-Arbestain, M., Lehmann, J. (Eds.), Biochar: A Guide to Analytical Methods (pp.199-213). CSIRO.

See also: UC Davis California Soil Resource Lab for your Feb. 23, 2010 article Numerical Integration/Differentiation in R: FTIR
https://casoilresource.lawr.ucdavis.edu/software/r-advanced-statistical-package/numerical-integrationdifferentiation-r-ftir-spectra
