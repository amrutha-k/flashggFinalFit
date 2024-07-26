import ROOT
import sys
import numpy as np
from optparse import OptionParser

def get_options():
  parser = OptionParser()
  parser.add_option('--inputWS', dest='inputWS', default='', help='root file containing no-interference signal WS')
  parser.add_option('--cat', dest='cat', default='', help='category (eg: UntaggedTag_0)')
  parser.add_option('--year', dest='year', default='2018', help='Year')
  return parser.parse_args()

(opt,args) = get_options()

f=ROOT.TFile(opt.inputWS, "read")
w = f.Get("wsig_13TeV")
#w.Print()

#dm_original = w.function("dm_dcb_HHggTauTaukl1_2016_SR1_13TeV")
dm_original_name = "dm_dcb_GG2H_%s_%s_13TeV"%(opt.year, opt.cat)
dm_original = w.function(dm_original_name)

GammaH = ROOT.RooRealVar("GammaH", "GammaH", 0.0)

# alpha dictionary
alpha_dict = {
  'UntaggedTag_0': 0.0,
  'UntaggedTag_1': -1.1,
  'UntaggedTag_2': -34.2,
  'UntaggedTag_3': -69.0,
  'UntaggedTag_4': -68.9,
  'UntaggedTag_5': -98.5,
  'UntaggedTag_6': -122.4,
  'UntaggedTag_7': -137.2,
  'UntaggedTag_8': -181.4,
  'UntaggedTag_9': -126.2,
  'VBFTag_0': 0.0,
  'VBFTag_1': 0.0,
  'VBFTag_2': 0.0,
  'VBFTag_3': 0.0
}

# create spline for GammaH dependence
width_ratio = np.linspace(0, 30, 300)
alpha = alpha_dict['%s'%(opt.cat)]
mass_shift = 0.001 * alpha * np.sqrt(width_ratio)  # factor of 10e-3 to convert alpha from MeV to GeV
width_spline = ROOT.RooSpline1D("width_spline", "width_spline", GammaH, len(width_ratio), width_ratio, mass_shift)

# just test the spline works
for xi in width_ratio:
 GammaH.setVal(xi)
 #width_spline.Print()

# create new dm shift which is MH + GammaH dependence
#dm_shift = ROOT.RooFormulaVar("dm_shift_dcb_HHggTauTaukl1_2016_SR1_13TeV", "dm_shift_HHggTauTaukl1_2016_SR1_13TeV", "@0 + @1", ROOT.RooArgList(dm_original, width_spline))
dm_shift_name = "dm_shift_dcb_GG2H_%s_%s_13TeV"%(opt.year, opt.cat)
dm_shift = ROOT.RooFormulaVar(dm_shift_name, dm_shift_name, "@0 + @1", ROOT.RooArgList(dm_original, width_spline))
imp = getattr(w, "import")
imp(dm_shift, ROOT.RooFit.RecycleConflictNodes())

# change also the norm function name 
original_norm_func = w.function("dcb_GG2H_%s_%s_13TeV_norm"%(opt.year, opt.cat))
new_norm_func = original_norm_func.Clone("dcb_shift_GG2H_%s_%s_13TeV_norm"%(opt.year, opt.cat))
imp = getattr(w,"import")
imp(new_norm_func, ROOT.RooFit.RecycleConflictNodes())

# use w.factory to create a new signal model with GammaH dependence included
#original_model_name = "hggpdfsmrel_HHggTauTaukl1_2016_SR1_13TeV"
#new_model_name = "hggpdfsmrel_shift_HHggTauTaukl1_2016_SR1_13TeV"

#original_dm_name = "dm_dcb_HHggTauTaukl1_2016_SR1_13TeV"
#new_dm_name = "dm_shift_dcb_HHggTauTaukl1_2016_SR1_13TeV"

original_model_name = "dcb_GG2H_%s_%s_13TeV"%(opt.year, opt.cat)
new_model_name = "dcb_shift_GG2H_%s_%s_13TeV"%(opt.year, opt.cat)

original_dm_name = "dm_dcb_GG2H_%s_%s_13TeV"%(opt.year, opt.cat)
new_dm_name = "dm_shift_dcb_GG2H_%s_%s_13TeV"%(opt.year, opt.cat)

factory_string = "EDIT::%s(%s, %s=%s )"%(new_model_name, original_model_name, original_dm_name, new_dm_name)
print(factory_string)
w.factory(factory_string)

# print out workspace again
w.Print()

# the new dcb mean is called "mean_dcb_HHggTauTaukl1_2016_SR1_13TeV_hggpdfsmrel_shift_HHggTauTaukl1_2016_SR1_13TeV"
# how does that change as a function of GammaH?
for xi in width_ratio:
  w.var("GammaH").setVal(xi)
  #print(xi, w.function("mean_dcb_HHggTauTaukl1_2016_SR1_13TeV_hggpdfsmrel_shift_HHggTauTaukl1_2016_SR1_13TeV").getVal())
  print(xi, w.function("mean_dcb_GG2H_%s_%s_13TeV_dcb_shift_GG2H_%s_%s_13TeV"%(opt.year, opt.cat, opt.year, opt.cat)).getVal())
  

w.writeToFile("CMS-HGG_sigfit_GG2H_%s_%s_width_model_novtxsplit_syst.root"%(opt.year, opt.cat))
