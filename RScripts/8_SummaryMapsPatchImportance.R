#####################################################################
# a233 Royal Botanical Gardens Wildlife Corridor Mapping       
# Calculate overall summed important of patches for 3 focal species
# 10-2020                                       					
#                             
#	1.Inputs (for focal species):                                   
#    -Patch importance outputs
#  
#   Outputs:
#    -Raster with Normalized sum score for each patch. 
#                                                                   
# Script by C Tucker for ApexRMS 									
#####################################################################

## Workspace ---------------------------------------------------------

  # Packages
library(tidyverse)
library(raster)
library(sf)

  # Directories
projectDir <- "~/Dropbox/Documents/ApexRMS/Work/A233 - Cootes to Escarpment" #CT
rawDataDir <- file.path(projectDir, "Data/Raw")
procDataDir <- file.path(projectDir, "Data/Processed")
outDir <- file.path(projectDir, "Results")

  # Functions
rescaleR <- function(x, new.min = 0, new.max = 1) {
   x.min = suppressWarnings(min(x, na.rm=TRUE))
   x.max = suppressWarnings(max(x, na.rm=TRUE))
   new.min + (x - x.min) * ((new.max - new.min) / (x.max - x.min))
}

  # Input parameters
source(file.path(rawDataDir, "a233_InputParameters.R")) # project level parameters
	specieslist

## Load species patch importance files -----------------------------------------

focalArea <- raster(file.path(procDataDir, "LULC_FocalArea.tif"))

  # Habitat suitability
BLBR_HS <- raster(file.path(procDataDir, 
					  paste0("BLBR", "_HabitatSuitability_FocalArea.tif")))
EMBL_HS <- raster(file.path(procDataDir, 
					  paste0("EMBL", "_HabitatSuitability_FocalArea.tif")))
ODVI_HS <- raster(file.path(procDataDir, 
					  paste0("ODVI", "_HabitatSuitability_FocalArea.tif")))

density <- raster(file.path(outDir, "Generic_CulvertBridge_5pairwise_cum_curmap.tif"))

  # Intra fraction
BLBR_PCflux <- raster(file.path(outDir, 
					  paste0("BLBR", "_PC_FocalArea.tif")),
					  band = 4)
EMBL_PCflux <- raster(file.path(outDir, 
					  paste0("EMBL", "_PC_FocalArea.tif")),
					  band = 4)
ODVI_PCflux <- raster(file.path(outDir, 
					  paste0("ODVI", "_PC_FocalArea.tif")),
					  band = 4)

  # Connector fraction					  
BLBR_PCconnect <- raster(file.path(outDir, 
					  paste0("BLBR", "_PC_FocalArea.tif")),
					  band = 5)
EMBL_PCconnect <- raster(file.path(outDir, 
					  paste0("EMBL", "_PC_FocalArea.tif")),
					  band = 5)
ODVI_PCconnect <- raster(file.path(outDir, 
					  paste0("ODVI", "_PC_FocalArea.tif")),
					  band = 5)
					  
## Process raster layers -----------------------------------------

  # Restrict habitat suitability to 60% only 
  # Data is already scaled from 0-100

BLBR_HSred <- BLBR_HS %>%
			 calc(., fun=function(x){
			 	ifelse(x >= suitabilityThreshold, x, NA)})
  # Make binary version
BLBR_HSbin <- calc(BLBR_HSred, fun=function(x){ifelse(x > 0, 1, x)})
		 
EMBL_HSred <- EMBL_HS  %>%
			 calc(., fun=function(x){
			 	ifelse(x>= suitabilityThreshold, x, NA)}) 
  # Make binary version
EMBL_HSbin <- calc(EMBL_HSred, fun=function(x){ifelse(x > 0, 1, x)})

ODVI_HSred <- ODVI_HS %>% 
			 calc(., fun=function(x){
			 	ifelse(x>= suitabilityThreshold, x, NA)}) 
  # Make binary version
ODVI_HSbin <- calc(ODVI_HSred, fun=function(x){ifelse(x > 0, 1, x)})

## Make combined habitat suitability layer 
combinedHS <- sum(stack(BLBR_HSbin, EMBL_HSbin, ODVI_HSbin), na.rm=TRUE)
combinedBinaryHS <- calc(combinedHS, fun=function(x){ifelse(x==0, NA, 1)})

## Log, to improve normality
densityLog <- density %>% 
			   calc(., fun=function(x){log(x)}) #log values for normality
densityCrop <- densityLog %>% 				
				crop(., focalArea) %>%
				mask(., focalArea)
				
## Crop and scale importance values. 
  # Two different data types are combined, so normalize
BLBR_PCfluxExt <-  BLBR_PCflux %>%
					extend(., extent(focalArea), value=NA) %>%
					scale(., center=TRUE, scale=TRUE) 
					
EMBL_PCfluxExt <-  EMBL_PCflux %>%
					extend(., extent(focalArea), value=NA) %>%
					scale(., center=TRUE, scale=TRUE) 
					
ODVI_PCfluxExt <-  ODVI_PCflux %>%
					extend(., extent(focalArea), value=NA) %>%
					scale(., center=TRUE, scale=TRUE) 
									
BLBR_PCconnectExt <-  BLBR_PCconnect %>%
						extend(., extent(focalArea), value=NA) %>%
						scale(., center=TRUE, scale=TRUE) 
					
EMBL_PCconnectExt  <-  EMBL_PCconnect %>%
						extend(., extent(focalArea), value=NA) %>%
						scale(., center=TRUE, scale=TRUE) 
					
ODVI_PCconnectExt  <-  ODVI_PCconnect %>%
						extend(., extent(focalArea), value=NA) %>%
						scale(., center=TRUE, scale=TRUE) 
	
	
## Calculate the sum of all layers --------------------------------------

  # Habitat suitability layer
HSlayers <- stack(BLBR_HSred, EMBL_HSred, ODVI_HSred)
  # Calculate
HS_PCRawSum <- sum(HSlayers, na.rm=TRUE)  # Raw sum
HS_PCRawMax <- max(HSlayers, na.rm=TRUE)  # Raw sum
  # Crop layer
HS_SumCrop <- HS_PCRawSum %>%
				crop(., focalArea) %>%
				mask(., combinedBinaryHS)
HS_MaxCrop <- HS_PCRawMax %>%
				crop(., focalArea) %>%
				mask(., combinedBinaryHS)				
				
plot(HS_SumCrop)
plot(HS_MaxCrop)

  # Patch importance layer 
PIlayers <- stack(BLBR_PCfluxExt, BLBR_PCconnectExt, EMBL_PCfluxExt, EMBL_PCconnectExt, ODVI_PCfluxExt, ODVI_PCconnectExt)

  # Process layer
PI_PCRawSum <- sum(PIlayers, na.rm=TRUE)
PI_SumCrop <- PI_PCRawSum %>%
				crop(., focalArea) %>%
				mask(., combinedBinaryHS) %>%
				calc(., fun = rescaleR)

PI_PCRawMax <- max(PIlayers, na.rm=TRUE)
PI_MaxCrop <- PI_PCRawMax %>%
				crop(., focalArea) %>%
				mask(., combinedBinaryHS) %>%
				calc(., fun = rescaleR)
plot(PI_MaxCrop)
plot(PI_SumCrop)

  # Density layer
densityRescale <- densityCrop %>% calc(., fun = rescaleR)
plot(densityRescale)

## Calculate sum layers for all layers

allSp <- stack(calc(HS_SumCrop, rescaleR), PI_SumCrop, densityRescale)
allSpRawSum <- sum(allSp, na.rm=TRUE) %>%
				crop(., focalArea) %>%
				mask(., combinedBinaryHS)
plot(allSpRawSum)
  # Range scale from 0-1
allSp_range <- calc(allSpRawSum, fun = rescaleR)
plot(allSp_range)


## Save output raster files -------------------------------------

  # Intermediate outputs

writeRaster(BLBR_HSbin, 
			file.path(outDir, "BLBR_BinHabitatSuitability.tif"), 
			overwrite=TRUE)		
writeRaster(BLBR_HSbin, 
			file.path(outDir, "EMBL_BinHabitatSuitability.tif"), 
			overwrite=TRUE)		
writeRaster(BLBR_HSbin, 
			file.path(outDir, "ODVI_BinHabitatSuitability.tif"), 
			overwrite=TRUE)		

  # Outputs per input type
writeRaster(HS_SumCrop, 
			file.path(outDir, "All_HabitatSuitabilitySum_60-300.tif"), 
			overwrite=TRUE)
writeRaster(HS_MaxCrop, 
			file.path(outDir, "All_HabitatSuitabilityMax_60-300.tif"), 
			overwrite=TRUE)						
writeRaster(PI_SumCrop, 
			file.path(outDir, "All_PatchImportanceSum_0-1.tif"), 
			overwrite=TRUE)		
writeRaster(PI_MaxCrop, 
			file.path(outDir, "All_PatchImportanceMax_0-1.tif"), 
			overwrite=TRUE)					
writeRaster(densityRescale, 
			file.path(outDir, "All_Density_0-1.tif"), 
			overwrite=TRUE)								

  # Overall output layer
writeRaster(allSp_range, 
			file.path(outDir, "All_CombinedLayers_01.tif"), 
			overwrite=TRUE)		

## End script