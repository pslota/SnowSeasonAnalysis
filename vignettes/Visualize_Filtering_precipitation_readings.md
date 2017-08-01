Visualize\_Filtering\_precipitation\_readings.R
================

Introduction
------------

The script Visualize\_Filtering\_precipitation\_readings.R in folder *inst* plot using an app Shiny the time series of precipitation with the classification. For a better analysis the script plot at the same time the Snow Heigh signal, if available, to verify results.

Description of algorithm
------------------------

-   **Section 1:** in this section you can select the station
    -   to examine and
    -   to load .RData created by Filtering\_precipitation\_readings.R algorithm.
-   **Section 2:** in this section the algorith import and adjust data format and plot 2 graph using **Shiny**

Shiny app
---------

The app shiny plot at the same time 2 plots:

-   **Plot1:** Precipitation time series measured by tipping buckett (red line) with classification on background ([more details](https://github.com/EURAC-Ecohydro/ESOLIP_quality_check/tree/master/vignettes/Filtering_precipitation_readings.Rmd)):
    -   *no precipitation:* grey
    -   *dew/fog/dirty:* magenta
    -   *precipitation:* blue
    -   *uncertain:* yellow
    -   *SnowMelting/Irrigation:* green
-   **Plot2:** Snow Height (grey line). If on the station there aren't any sensors of snow height the Plot2 return a warning message!

-   **Example** <!-- ![](https://github.com/EURAC-Ecohydro/SnowSeasonAnalysis/tree/master/figs/img_Visualize_ESOLIP.PNG) --> ![](C:/Users/CBrida/Desktop/Git/Upload/SnowSeasonAnalysis/figs/img_Visualize_ESOLIP.PNG)

How to use
----------

Open script *Visualize\_Filtering\_precipitation\_readings.R* and:

1.  Select **FILE\_NAME**, the name of station to examine (**without .csv**)
2.  Set **git folder**, the path where the package is download or used.
3.  Run **Load .RData** to import .RData available in folder *data/Output/RData*
4.  Run **Section 2** to launch Shiny app