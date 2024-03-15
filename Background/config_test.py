# Config file: options for signal fitting

backgroundScriptCfg = {
  
  # Setup
  'inputWSDir':'/eos/user/a/amkrishn/hggWidth/mcNtuples/condor_output/2018/dataSummer19UL18_final_5cats/ws/', # location of 'allData.root' file
  'cats':'auto', # auto: automatically inferred from input ws
  'catOffset':0, # add offset to category numbers (useful for categories from different allData.root files)  
  'ext':'bkg_modelling_2018_test', # extension to add to output directory
  #'year':'combined', # Use combined when merging all years in category (for plots)
  'year':'2018', # Use combined when merging all years in category (for plots)     

  # Job submission options
  'batch':'condor', # [condor,SGE,IC,local]
  'queue':'microcentury' # for condor e.g. microcentury
  
}
