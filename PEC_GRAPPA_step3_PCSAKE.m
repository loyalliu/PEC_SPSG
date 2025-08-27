% Edited by Yilong LIU, 2017-12-22
function PEC_GRAPPA_step3_PCSAKE(para)

import LmyGhostCorrection.*

load_folder = para.result_dir;
load(fullfile(load_folder,'SbData_lpc'),'epi_kxkyzc_lpcCor', 'phasepara_evenOddMajar_zp');

%%
ncalib = para.PCSAKE.ncalib;
ksize = para.PCSAKE.ksize; % ESPIRiT kernel-window-size
sakeIter = para.PCSAKE.nIter;

threshold_list = para.PCSAKE.threshold_list;

save_name=['SbData_sake_ksize' num2str(ksize(1)) '_Iter' num2str(sakeIter) '.mat'];
save_name=fullfile(load_folder,save_name);

if para.skip.PCSAKE && exist(save_name, 'file')
    load(save_name,'epi_kxkyzc_sakeCor','epi_kxkyzc_sakeCor_fullCoils','threshold_list');
else
    nSeg = 2*para.nshot; % number of virtual coils

    [epi_kxkyzc_sakeCor, epi_kxkyzc_sakeCor_fullCoils] = LmyGhostCorrection.PCSAKE...
        (epi_kxkyzc_lpcCor, nSeg, ncalib, ksize, threshold_list, sakeIter, [], para);
    save(save_name,'epi_kxkyzc_sakeCor','epi_kxkyzc_sakeCor_fullCoils','threshold_list');
end

if para.verbose.PCSAKE
    %% Export reconstructed images
    export_dir = [fullfile(load_folder, 'PCSAKE') filesep]; mkdir(export_dir);
%     cd(export_dir);
    mon_size = para.mon_size;
    [ncalibx,ncaliby,nSlice,nCoil] = size(epi_kxkyzc_sakeCor);
    % Reconstructed images
    figure(1);MY_montage((sos(ifft2c(crop(epi_kxkyzc_lpcCor,[ncalibx,ncaliby,nSlice,nCoil])))),'size',mon_size,'displayrange', '1x', 'PIC', [export_dir 'LPC']);
    title('LPC');
    figure(1);MY_montage((sos(ifft2c(epi_kxkyzc_sakeCor))),'size',mon_size,'displayrange', '1x', 'PIC', [export_dir 'PC-SAKE']);
    title('PC SAKE')
    % Brightened images
    figure(1);MY_montage((sos(ifft2c(crop(epi_kxkyzc_lpcCor,[ncalibx,ncaliby,nSlice,nCoil])))),'size',mon_size,'displayrange', '10x', 'PIC', [export_dir 'LPC 10x']);
    title('LPC')
    figure(1);MY_montage((sos(ifft2c(epi_kxkyzc_sakeCor))),'size',mon_size,'displayrange', '10x', 'PIC', [export_dir 'PC-SAKE 10x']);
    title('PC SAKE')
    %% Reconstructed coil images
    for ind_coil = para.PCSAKE.verbose_ind_coil
        figure(1);MY_montage((abs(ifft2c(crop(epi_kxkyzc_lpcCor(:,:,:,ind_coil),[ncalibx,ncaliby,nSlice])))), ...
            'size',mon_size,'displayrange', '3x', 'PIC', [export_dir 'LPC_coil' num2str(ind_coil)]);
        title('LPC')
        figure(1);MY_montage((abs(ifft2c(epi_kxkyzc_sakeCor(:,:,:,ind_coil)))),...
            'size',mon_size,'displayrange', '3x', 'PIC', [export_dir 'PC-SAKE_coil' num2str(ind_coil)]);
        title('PC SAKE')
    end
%     
%     size(epi_kxkyzc_sakeCor)
%     figure(1);MY_montage(db(sos(ifft2c(crop(epi_kxkyzc_lpcCor,[ncalibx,ncaliby,nSlice, nCoil])))),...
%         'size',mon_size,'displayrange', '1x', 'PIC', 'db LPC');title('db LPC')
%     figure(1);MY_montage(db(sos(ifft2c(epi_kxkyzc_sakeCor))), ...
%         'size',mon_size,'displayrange', '1x', 'PIC', 'db VC-SAKE');title('db VC SAKE')
end % end of verbose output...

end % end of function ...
