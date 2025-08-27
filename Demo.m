%% Setup environment
clear all
close all
clc

import LmyUtility.*

%% Initialize parameters
PEC_GRAPPA_set_path;

%% Set parameters
PEC_GRAPPA_initial_para;

ncalib = 128;
% ----- Directories -------------------------------------------------------
para.data_name = 'sample';
% para.data_name = 'hard_dwi';
% para.data_name = 'phantom_1';
para.data_dir = ['.' filesep 'data' filesep para.data_name]; % Directory for the data
para.result_dir = fullfile('result', para.data_name); % Directory for interim and final results
tmp_dir = fullfile(para.result_dir, 'tmp'); mkdir(tmp_dir);

% ----- PC-SAKE recon -----------------------------------------------------
para.PCSAKE.threshold_list = 0.01;
para.PCSAKE.nIter = 100;
para.PCSAKE.ksize = [1 1]*3;
para.PCSAKE.ncalib = ncalib;

% ----- CSM and PEM estimation --------------------------------------------
para.bart.cmd_for_PEM_calculation = {0.3, 6, ncalib};
para.bart.cmd_for_CSM_calculation = {0.03, 6, ncalib};
para.recon.PEM_option.model= '2dFreeESPIRiT';  %'2dFreePCSAKE';; %'2dFreePCSAKE';  % '2dFreeESPIRiT', '2dFreeBART', '1dLpc'
para.recon.CSM_option.source='segEPI SAKE';
para.recon.slice2show = [1:48];
para.recon.CSM_option.mask_type = 'CSM';
para.recon.CSM_option.mask = 0.9;
para.recon.CSM_option.mask_dilate = 2;

para.CSM_calc.ncalib = ncalib;

% ----- PEC-SENSE and PEC-GRAPPA recon ------------------------------------
para.recon.filter = 2;
para.recon.reg_factor = 0.00001; % regularization factor for both SENSE and GRAPPA

para.recon.calib_size = [2 1]*ncalib;
para.recon.ksize = [6, 4]; 

% ----- Other information -------------------------------------------------
para.MB_factor = 6;

para.mon_size = [4 12];

para.skip.PCSAKE = 1; % skip VC-SAKE if already done
para.skip.recon = 0; % skip PEC-SENSE/PEC-GRAPPA/PEC-SP-SG reconstruction if already done

para.verbose.gmap = 1; % output g-factor map for evaluation
para.disp.gmap_range = [0.9 3];

para.disp.std_max = 60;
para.prefix = '';
para.rep_list = 1;
para_tmp = para;

%% Batch processing
% Data preprocessing
% PEC_GRAPPA_step1_load_Siemens; % Skipped, as .mat sample data provided
copyfile(para.data_dir, para.result_dir);
PEC_GRAPPA_step2_lpcOnRefData(para);
PEC_GRAPPA_step3_PCSAKE(para);

% para.recon.CSM_option.source='gre';
% PEC_GRAPPA_step4_calc_CSM(para);
para.recon.CSM_option.source='segEPI LPC';
 PEC_GRAPPA_step4_calc_CSM(para);
para.recon.CSM_option.source='segEPI SAKE';
PEC_GRAPPA_step4_calc_CSM(para);

run_PEC_SPSG = 1; run_LPC_GRAPPA = 1;

for mbf = [4]
    para_tmp.MB_factor = mbf;

% ----- PEC-SPSG --------------------------------------------------------
if run_PEC_SPSG
    para = para_tmp; para.verbose.gmap = 0;
    para.recon.calib_size = [1, 1]*ncalib;
    para.recon.ksize = [1, 1]*5; para.skip.PEM_calc = 1;
    para.recon.Recon_option = 'PEC-SPSG'; para.recon.CSM_option.filter='GRAPPA';
    para.recon.flag_calc_tSNR = 0; SMS_EPI_Recon(para); % Reconstruction for 1st frame
%     para.recon.flag_calc_tSNR = 1; SMS_EPI_Recon(para);
end

% ----- 1D LPC-SPSG --------------------------------------------------------
if run_LPC_GRAPPA
    para = para_tmp;  para.verbose.gmap = 0;
    % para.recon.slice2show = [1 11]; para.mon_size = [1 2];
    para.recon.PEM_option.model= '1dLpc';
    para.recon.CSM_option.source='segEPI LPC';
    para.recon.calib_size = [1, 1]*ncalib;
    para.recon.ksize = [1, 1]*5;
    para.skip.PEM_calc = 0; % para.MB_factor = 2;
    para.recon.Recon_option = '1D-LPC-SPSG'; para.recon.CSM_option.filter='GRAPPA';
    para.recon.flag_calc_tSNR = 0; SMS_EPI_Recon(para); % Reconstruction for 1st frame
%     para.recon.flag_calc_tSNR = 1; SMS_EPI_Recon(para); 
end
end
