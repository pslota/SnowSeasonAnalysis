#-------------------------------------------------------------------------------------------------------------------------------------------------------
# File Title:   Filtering_snow_height.R
# TITLE:        Analyze and filter snow height signal
# Autor:        Christian Brida
#               Institute for Alpine Environment
# Data:         11/04/2017
# Version:      1.0
#
#------------------------------------------------------------------------------------------------------------------------------------------------------

Sys.setenv(TZ='Etc/GMT-1')

if(!require("zoo")){
  install.packages(zoo)
  require("zoo")
}
if(!require("signal")){
  install.packages(signal)
  require("signal")
}


# ~~~~~~ Section 1 ~~~~~~ 

#------------------------------------------------------------------------------------------------------------------------------------------------------
# Define your Git folder:
#------------------------------------------------------------------------------------------------------------------------------------------------------

# ====== INPUT 1 ====== 

git_folder=getwd() 
#git_folder="C:/Users/CBrida/Desktop/Git/EURAC-Ecohydro/SnowSeasonAnalysis/"
# ===================== 

#------------------------------------------------------------------------------------------------------------------------------------------------------
# Show data available
#------------------------------------------------------------------------------------------------------------------------------------------------------

path <- paste(git_folder,"/data/Input_data/",sep = "")
files_available=dir(path)
print(paste("Example data:",files_available))

# ====== INPUT 2-3 ====== 

# 1. file with snow heigth time series

file="B3_2000m_TOTAL.csv"
# label of snow height column
SNOW_HEIGHT = "Snow_Height"

# List here also the support files

# 2. file with max and min range for snow height
#   Set up parameters in table: "H:/Projekte/Criomon/06_Workspace/BrC/Cryomon/03_R_Script/05_snow_filter/function/Support files/Range_min_max.csv"
Range_min_max <- paste(git_folder,"/data/Support_files/Range_min_max.csv",sep = "")

# 3. file with Values that have high increment or high decrement are considered outliers and substitute with 'NA'
#   Set up parameters in table: "H:/Projekte/Criomon/06_Workspace/BrC/Cryomon/03_R_Script/05_snow_filter/function/Support_files/Rate_min_max.csv"
Rate_min_max <- paste(git_folder,"/data/Support_files/Rate_min_max.csv",sep = "")

# 4. file with snow depth observations used for calibration of snow heigth sensor
# it is supposed to end wiht the same name of the input meteo file: Snow_Depth_Calibration_B3_2000m_TOTAL.csv
folder_surveys=paste(git_folder,"/data/Snow_Depth_Calibration/Snow_Depth_Calibration_",sep = "")

# ======================= 

# ====== METHOD ====== 
# Select one of smoothing method

SMOOTH_METHOD = "Savitzky_Golay"

# Options (copy one of this string in SMOOTH_METOD)
#   1. "Moving_Average"
#   2. "Savitzky_Golay"

# ~~~~~~ Section 2 ~~~~~~ 

#- READ DATA -------------------------------- 
#
# 1.Read data from folder. 2.Convert values from chraracter to numeric. 3.Return a zoo time series of numeric data

# Import functions to read data
# source("H:/Projekte/Criomon/06_Workspace/BrC/Cryomon/03_R_Script/05_snow_filter/function/fun_read_data_metadata.R")
source(paste(git_folder,"/R/fhs_read_data_metadata.R",sep = ""))

# Import data and metadata using funcions loaded before
zoo_data=fun_read_data(PATH = path,FILE = file)
snow = zoo_data[,which(colnames(zoo_data)==SNOW_HEIGHT)]
#------------------------------------------- 

# ~~~~~~ Section 3 ~~~~~~ 

#- CALIBRATION ----------------------------- 

# Import functions to calibrate HS
source(paste(git_folder,"/R/fhs_calibration_HS_2.R",sep = ""))

# snow_elab = data_no_outliers[,which(colnames(zoo_data)==SNOW_HEIGHT)]

# Calibration of HS using real and virtual snow surveys (we assume that at the end of season the snow height is 0 cm)
data_calibr=fun_calibration_HS_2(DATA = snow,FILE_NAME = file,PATH_SURVEYS = folder_surveys)

# Gaps are filled with contant value (the last befor gap)
# data_calibr=na.locf(data_calibr,na.rm=F)
data_calibr=na.fill(object = data_calibr,fill = "extend")


zero=zoo(seq(1,length(data_calibr),by=1),order.by = index(data_calibr))
zoo_calibr=merge(data_calibr,zero)
colnames(zoo_calibr)=c(SNOW_HEIGHT, "zero")

#------------------------------------------- 

# ~~~~~~ Section 4 ~~~~~~ 

#- EXCLUDE DATA OUT OF RANGE ---------------
#
# 1.Exctract selected variable from input data. 
# 2.Values out of physical range are considered outliers and substitute with 'NA'

# Import function to delete outliers (Range)
source(paste(git_folder,"/R/fhs_range.R",sep = ""))

# Exclude HS data out of range min/max set. Units: m 
data_in_range=fun_range(DATA = zoo_calibr,VARIABLE = SNOW_HEIGHT, RANGE = Range_min_max)

# Gap are filled with contant value (the last befor gap)
# data_in_range=na.locf(data_in_range,na.rm=F)
data_in_range=na.fill(object = data_in_range,fill = "extend")


#------------------------------------------- 

#- EXCLUDE DATA WITH RAPID INCREASE/DECREASE ------

# 1.Exctract selected variable from input data. 
# 2.Values that have high increment or high decrement are considered outliers and substitute with 'NA'

# Import function to delete outliers (Rate)
source(paste(git_folder,"/R/fhs_rate.R",sep = ""))

# Exclude HS data with high increse and high decrease (Comai thesis). Units: m/h 
data_no_outliers=fun_rate(DATA = data_in_range,VARIABLE = SNOW_HEIGHT, RATE = Rate_min_max)

# Gap are filled with contant value (the last befor gap)

# data_no_outliers=na.locf(data_no_outliers,na.rm=F)
data_no_outliers=na.fill(object = data_no_outliers,fill = "extend")
#------------------------------------------- 


# ~~~~~~ Section 5 ~~~~~~ 

# ==== OPTION 1: MOVING AVERAGE FILTER ====

if(SMOOTH_METHOD == "Moving_Average"){
  
  #- MOVING AVERAGE ---------------------------
  # 1.Run a moving average on data selected with a window lenght set up as function argument
  # Important: time series should not contains NA values
  
  # Import function for a moving average
  source(paste(git_folder,"/R/fhs_moving_average.R",sep = ""))
  
  
  # Apply a moving average with a window length of 5 (Mair et.al.). Units: h
  data_ma=fun_moving_average(DATA = data_calibr, PERIOD_LENGTH = 5)
  
  # Gaps are filled with contant value (the last befor gap)
  # data_ma=na.locf(data_ma,na.rm=F)
  data_ma=na.fill(object = data_ma,fill = "extend")
  
  data_smooth=data_ma    # <- OPTION 1
}
#-------------------------------------------

# ==== OPTION 2: SAVITKY-GOLAY FILTER ==== 
if(SMOOTH_METHOD == "Savitzky_Golay" ){
  
  #- SAVITKY-GOLAY FILTER --------------------------- 
  # Apply a savitzky golay filter (better compared with Moving average) to reduce signal noise. 
  # Suggest to set FILTER_ORDER = 1 and FILTER_LENGTH = 9 
  # Help: sgolay (signal) on https://cran.r-project.org/web/packages/signal/signal.pdf 
  # Important: time series should not contains NA values
  
  
  # Import function for  savitzky golay filter
  source(paste(git_folder,"/R/fhs_savitzky_golay_filter.R",sep = ""))
  
  # Apply a savitzky golay filter with FILTER_ORDER = 1 and FILTER_LENGTH = 9. Units: h 
  data_filt=fun_savitzky_golay(DATA = data_calibr, FILTER_ORDER = 1,FILTER_LENGTH = 9)
  
  # Gap are filled with contant value (the last befor gap)
  # data_filt=na.locf(data_filt,na.rm=F)
  data_filt=na.fill(object = data_filt,fill = "extend")
  data_smooth=data_filt    # <- OPTION 2
}
#------------------------------------------- 

if(SMOOTH_METHOD != "Moving_Average" & SMOOTH_METHOD != "Savitzky_Golay"){
  stop(paste("SMOOTH_METHOD:",SMOOTH_METHOD,"incorrect! Please select one of the options! The selction must be under quotation marks" ))
}else{
  
  #- OUTLIERS ON FILTERED DATA ------------------------- 
  
  # Exclude HS smoothed with moving average data with high increse and high decrease (Comai thesis). Units: m/h 
  data_smooth_no_outliers=fun_rate(DATA = data_smooth,VARIABLE = SNOW_HEIGHT, RATE = Rate_min_max)                         # <--DATA could be data_ma
  
  # Gap are filled with contant value (the last befor gap)
  # data_smooth_no_outliers=na.locf(data_smooth_no_outliers,na.rm=F)
  data_smooth_no_outliers=na.fill(object = data_smooth_no_outliers,fill = "extend")
  
  #------------------------------------------- 
  
  # ~~~~~~ Section 6 ~~~~~~ 
  
  #- SAVE DATA ----------------------------- 
  zoo_output=cbind(snow,data_in_range,data_calibr,data_no_outliers,data_smooth,data_smooth_no_outliers)
  rdata_output=list(snow,data_in_range,data_calibr,data_no_outliers,data_smooth,data_smooth_no_outliers)
  names(rdata_output)=c("HS_original","HS_calibrated","HS_range_QC", "HS_rate_QC", "HS_calibr_smoothed", "HS_calibr_smooothed_rate_QC" )
  output=as.data.frame(zoo_output)
  output=cbind(index(snow),output)
  colnames(output)=c("TIMESTAMP","HS_original","HS_calibrated","HS_range_QC", "HS_rate_QC", "HS_calibr_smoothed", "HS_calibr_smooothed_rate_QC" )
  
  save(rdata_output,file=paste(git_folder,"/data/Output/Snow_Filtering_RData/Snow_",substring(file,1,nchar(file)-4), ".RData",sep=""))
  write.csv(output,paste(git_folder,"/data/Output/Snow_Filtering/Snow_",file,sep = ""),quote = F,row.names = F)
}