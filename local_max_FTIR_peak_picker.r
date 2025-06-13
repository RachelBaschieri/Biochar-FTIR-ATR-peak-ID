##### This script is intended to be used on baseline corrected FTIR data. The script reads spectra to look for local maxima, then applies thresholds to 
### identify peaks.
library(patchwork)
library(ggplot2)
library(scales)
library(readxl)
library(tools)

#set folder and file paths
input_folder <- ""#This should be a folder full of excel files with baseline corrected spectra, each file should contain only the wavenumber and absorbance data in columns.
output_plots_folder <- ""#This should be a folder you want to save the peak plots to
output_excel_file <- ""#This should be an excel file you want to save the peak wavenumber and absorbance data to

file_list <- list.files(input_folder, pattern = "\\.xlsx$", full.names = TRUE)

# Initialize empty dataframe for peak data
all_peak_data <- data.frame()


if (!dir.exists(output_plots_folder)) {
  dir.create(output_plots_folder, recursive = TRUE)
}

# Loop through each file
for (file in file_list) {
  # Extract Sample and Lab from filename (assuming format Sample_Lab.xlsx)
  filename <- basename(file)
  base_name <- tools::file_path_sans_ext(filename)
  parts <- strsplit(base_name, "_")[[1]]
  
  if (length(parts) >= 2) {
    Sample <- parts[1]
    Lab <- parts[2]
  } else {
    warning(paste("Skipping file due to unexpected filename structure:", filename))
    next
  }
  
  # Read Excel file
  FTIR_data <- read_excel(file)
  
  # Ensure column names are lowercase for consistency
  colnames(FTIR_data) <- tolower(colnames(FTIR_data))
  if (!all(c("wavenumber", "absorbance") %in% colnames(FTIR_data))) {
    warning(paste("Skipping file due to missing columns:", filename))
    next
  }
  
  #Apply smoothing
  fx.spline <- smooth.spline(FTIR_data$wavenumber, FTIR_data$absorbance, spar = 0.2)
  FTIR_data$smoothed <- predict(fx.spline, FTIR_data$wavenumber)$y
  
  n <- nrow(FTIR_data)
  window <- 20
  density_window <- 100  # cm⁻¹ region to consider for peak density
  min_prominence <- 0.03 * max(FTIR_data$smoothed, na.rm = TRUE)
  
  # Step 1: Find all local maxima as peak candidates
  peak_candidates <- c()
  for (i in (window + 1):(n - window)) {
    center_val <- FTIR_data$smoothed[i]
    neighborhood <- FTIR_data$smoothed[(i - window):(i + window)]
    if (center_val == max(neighborhood, na.rm = TRUE)) {
      if (center_val > min_prominence) {
        peak_candidates <- c(peak_candidates, i)
      }
    }
  }
  
  # Step 2: Refine peaks based on local peak density and peak height
  true_peaks <- c()
  for (i in peak_candidates) {
    current_wave <- FTIR_data$wavenumber[i]
    
    # Find other peak candidates in the same region (within ±100 cm⁻¹)
    local_indices <- which(abs(FTIR_data$wavenumber[peak_candidates] - current_wave) <= (density_window / 2))
    local_peaks <- peak_candidates[local_indices]
    
    if (length(local_peaks) > 3) {
      # High density → enforce 30% rule
      local_peak_heights <- FTIR_data$smoothed[local_peaks]
      local_mean <- mean(local_peak_heights[local_peaks != i], na.rm = TRUE)
      
      if (FTIR_data$smoothed[i] > (local_mean * 1.30)) {
        true_peaks <- c(true_peaks, i)
      }
    } else {
      # Low density → keep as true peak
      true_peaks <- c(true_peaks, i)
    }
  }
  
  # Step 3: Plot
  peak_waves <- FTIR_data$wavenumber[true_peaks]
  peak_absorb <- FTIR_data$smoothed[true_peaks]
  
  plot_data <- data.frame(
    wavenumber = FTIR_data$wavenumber,
    absorbance = FTIR_data$smoothed
  )
  
  peak_labels <- data.frame(
    wavenumber = peak_waves,
    absorbance = peak_absorb,
    label = round(peak_waves, 0)
  )
  
  
  # Plot 1: Spectrum without peak points
  p1 <- ggplot(plot_data, aes(x = wavenumber, y = absorbance)) +
    geom_line(color = "steelblue") +
    scale_x_reverse() +
    labs(title = "FTIR Spectrum", x = "Wavenumber (cm⁻¹)", y = "Absorbance") +
    theme_minimal()
  
  # Plot 2: Spectrum with peak points
  p2 <- ggplot(plot_data, aes(x = wavenumber, y = absorbance)) +
    geom_line(color = "steelblue") +
    geom_point(data = peak_labels, aes(x = wavenumber, y = absorbance), color = "red", size = 2) +
    geom_text(data = peak_labels, aes(label = label), vjust = -1, size = 3.5, color = "black") +
    scale_x_reverse() +
    labs(title = "Detected Peaks", x = "Wavenumber (cm⁻¹)", y = "Absorbance") +
    theme_minimal()
  
  # Combine and save
  combined_plot <- p1 / p2  # stacked vertically
  
  ggsave(filename = file.path(output_plots_folder, paste0(base_name,  "_CombinedPeaksPlot.png")),
         plot = combined_plot, width = 8, height = 8, dpi = 300)
  
  if (length(true_peaks) == 0) {
    message(paste("No peaks found in", filename, "- plot will show only spectrum."))
  } else {
    peak_data <- data.frame(
      Sample = Sample,
      Lab = Lab,
      wavenumber = peak_waves,
      absorbance = peak_absorb
    )
    all_peak_data <- bind_rows(all_peak_data, peak_data)
  }
}

write_xlsx(all_peak_data, output_excel_file)

