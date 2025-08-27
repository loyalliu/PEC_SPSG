# Phase Error Corrected Split Slice-GRAPPA (PEC-SPSG) for SMS-EPI Reconstruction
## Suggested setup
- The demo scripts were tested on Matlab 2022a (installed on Windows 10). The demo scripts cannot run correctly on Matlab Online/Matlab for Linux/Matlab for Mac.
- Functions from some publicly available toolboxes are required, please download these toolboxes unzip them under .\tools\. Below plese find the URLs for these toolboxes.
  + ESPIRiT: https://people.eecs.berkeley.edu/~mlustig/software/SPIRiT_v0.3.tar.gz
  + Tools for NIfTI and ANALYZE image: https://ww2.mathworks.cn/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
  + Fast Imaging Library: https://www.ncigt.org/fast-imaging-library/
  + export_fig: https://ww2.mathworks.cn/matlabcentral/fileexchange/23629-export_fig/
 
## Demo and sample data
- A matlab demo script is provided for SMS-EPI reconstruction: Demo.m
- The sample data are available on Zenodo: 
  + GreData_128kx.mat: Single-band GRE calibration data
  + SbData.mat: Single-band multi-shot EPI calibration data
  + SbR2Data.mat: Single-band single-shot EPI data (R=2)
  + Mb4Data.mat: Multi-band EPI data (MB=4, R=2)
- The reconstruction results will be saved under .\result\

## Reference
Zhao, Yunlin, et al. "Improved Simultaneous Multislice EPI Reconstruction for Functional MRI with Slice Specific 2D Nyquist Ghost Correction." Biomedical Signal Processing and Control, In Press.
