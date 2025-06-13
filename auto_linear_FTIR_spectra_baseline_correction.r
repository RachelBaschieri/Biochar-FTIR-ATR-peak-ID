#This code will apply a sliding window approach to find local minima of a FTIR spectral curve. From the local minima, a piecewise linear function is fit.
## This piecewise linear function is then subtracted from the original spectra to produce a baseline corrected spectra.

# Load required packages
library(readxl)
library(ggplot2)
library(tools)
library(writexl)

# --- Parameters ---
input_folder <- ""  #This should be a folder with your FTIR data as excel files with a "wavenumber" and "absorbance" column only         
output_folder <- "" #This should be a folder you would like to save the plots of your baseline corrected curves to
output_data_dir <- "" #This should be the directory where you would like to output your baseline corrected spectra excel files


step_size <- 10      # Step size (cm⁻¹)


# Function to apply linear baseline correction to a single file
baseline_correction <- function(file_path, window_size, step_size) {
  # Read file
  FTIR_data <- read_excel(file_path)
  colnames(FTIR_data) <- tolower(colnames(FTIR_data))
  if (!all(c("wavenumber", "absorbance") %in% colnames(FTIR_data))) {
    warning(paste("Missing required columns in:", basename(file_path)))
    return(NULL)
  }
  
  
  # Sort by increasing wavenumber
  FTIR_data <- FTIR_data[order(FTIR_data$wavenumber), ]
  wavenumber <- FTIR_data$wavenumber
  absorbance <- FTIR_data$absorbance
  
  # Function to define window size based on wavenumber evaluated
  get_window_size <- function(wavenumber) {
    if (wavenumber >= 3000 && wavenumber <= 3500) {
      return(300)  # Broad peaks → wide window
    } else if (wavenumber >= 400 && wavenumber <= 800) {
      return(75)   # Sharp peaks → narrow window
    } else {
      return(150)  # Default
    }
  }
  
  # Sliding window to find local minima
  baseline_points <- data.frame(wavenumber = numeric(), absorbance = numeric())
  for (i in seq(from = min(wavenumber), to = max(wavenumber), by = step_size)) {
    window_size <- get_window_size(i)
    window_range <- which(wavenumber >= (i - window_size / 2) & wavenumber <= (i + window_size / 2))
    
    if (length(window_range) > 0) {
      min_idx <- which.min(absorbance[window_range])
      baseline_points <- rbind(baseline_points,
                               data.frame(wavenumber = wavenumber[window_range[min_idx]],
                                          absorbance = absorbance[window_range[min_idx]]))
    }
  }
  
  # Linear interpolation (piecewise baseline)
  baseline_values <- approx(x = baseline_points$wavenumber,
                            y = baseline_points$absorbance,
                            xout = wavenumber,
                            method = "linear", rule = 2)$y
  
  # Corrected absorbance values, but replacing any negative values with 0
  corrected_abs <- pmax(0, absorbance - baseline_values)
  
  # Combine into data frame
  FTIR_data$baseline <- baseline_values
  FTIR_data$corrected <- corrected_abs
  
  return(FTIR_data)
  
}

# Process all Excel files
file_list <- list.files(input_folder, pattern = "\\.xlsx$", full.names = TRUE)

for (file in file_list) {
  cat("Processing:", basename(file), "\n")
  
  result <- baseline_correction(file, window_size, step_size)
  if (is.null(result)) next
  
  # Extract filename parts for output
  base_name <- file_path_sans_ext(basename(file))
  
  # Plot
  p <- ggplot(result, aes(x = wavenumber)) +
    geom_line(aes(y = absorbance), color = "black", size = 1) +
    geom_line(aes(y = baseline), color = "blue", linetype = "dashed", size = 1) +
    geom_line(aes(y = corrected), color = "red", size = 1) +
    scale_x_reverse() +
    labs(title = paste("Auto Linear Baseline Correction:", base_name),
         x = "Wavenumber (cm⁻¹)", y = "Absorbance") +
    theme_minimal()
  
  # Save plot
  ggsave(filename = file.path(output_folder, paste0(base_name, "_autolincorrected.png")),
         plot = p, width = 10, height = 5)
  
  corrected_df <- data.frame(wavenumber = result$wavenumber, absorbance = result$corrected)
  output_file <- file.path(output_data_dir, paste0(base_name, "_autolin_baseline_corrected.xlsx"))
  write_xlsx(corrected_df, output_file)
  
}












