######################################################################
# a233 Royal Botanical Gardens Wildlife Corridor Mapping            
#  Generate generic species resistance map      
#  09/2020                                  
#                                                                   
# Inputs:                                                           
#    - The combined LULC layer produced by 1_StudyAreaLULC.R                                                                              
#    - The LULC/resistance crosswalk                                
#    - Focal area shapefile
#
#  Outputs:                                                          
#    - Resistance raster layers                                            
#                                                                  
# Script created by B Rayfield, C Debeyser, C Tucker    for ApexRMS 
#####################################################################


## Workspace ---------------------------------------------------------
  # Packages
library(tidyverse)
library(raster)
library(sf)

  # Settings
options(stringsAsFactors=FALSE, SHAPE_RESTORE_SHX=T, useFancyQuotes = F, digits=10)

  # Directories
projectDir <- "C:/Users/bronw/Documents/Apex/Projects/Active/A233_RBGConnectivity/a233" #BR
#projectDir <- "~/Dropbox/Documents/ApexRMS/Work/A233 - Cootes to Escarpment/" #CT
dataDir <- paste0(projectDir, "/Data/Raw")
outDir <- paste0(projectDir, "/Data/Processed")

  # Input parameters
source(file.path(dataDir, "a233_InputParameters.R"))
	polygonBufferWidth
	roadbuffer

## Read in data
  # Combined LULC layers
LULC <- raster(
				file.path(outDir, 
            	paste0("LULC_", polygonBufferWidth, "km.tif")))
LULC_buffer <- raster(
				file.path(outDir, 
                paste0("LULC_", polygonBufferWidth, "km_buffered.tif")))
                
  #Focal area polygon
focalArea <- st_read(
				file.path(outDir, "FocalArea.shp")) # Study area polygon

 # Tabular data
   # Resistance crosswalk
crosswalk <- read_csv(
				file.path(
				paste0(dataDir, "/Resistance"), 
                "GenericSpeciesResistanceCrosswalk.csv"))

## Create resistance layer  ---------------------------------------------------------
  # Reclassify
resistance <- LULC %>%
  reclassify(., rcl=crosswalk[, c("Destination_ID", "Resistance")])

resistance_buffer <- LULC_buffer %>%
  reclassify(., rcl=crosswalk[, c("Destination_ID", "Resistance")])

resistanceFocal <- resistance %>%
  crop(., extent(focalArea), snap="out") %>% # Crop to focal area extent
  mask(., mask=focalArea) %>% # Clip to focal area
  trim(.) # Trim extra white spaces  


# Save outputs ---------------------------------------------------------
#geotif
writeRaster(resistanceFocal, 
			file.path(outDir, "Generic_Resistance_FocalArea.tif"), 
			overwrite=TRUE)
writeRaster(resistance, 
			file.path(outDir, 
			paste0("Generic_Resistance_", polygonBufferWidth, "km.tif")), overwrite=TRUE)
writeRaster(resistance_buffer, 
			file.path(outDir, 
			paste0("Generic_Resistance_", polygonBufferWidth, "km_buffer.tif")), 
			overwrite=TRUE)
#asc
writeRaster(resistance_buffer, 
			file.path(outDir, 
			paste0("Generic_Resistance_", polygonBufferWidth, "km_buffer.asc")), 
			overwrite=TRUE)
