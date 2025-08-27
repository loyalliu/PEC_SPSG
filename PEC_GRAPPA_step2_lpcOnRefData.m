% 1D LPC correction for reference EPI data
function PEC_GRAPPA_step2_lpcOnRefData(para)

import LmyGhostCorrection.*
import LmyUtility.*

load_folder = para.result_dir;
if isfield(para, 'refscan') && para.refscan.flag == 1
    load(fullfile(load_folder,'SbData'),'epi_sampling_mask_kys','epi_fovY','epi_rangeKy');
    load(fullfile(load_folder, para.refscan.filename),'MB_refscan');
    epi_kxkyzc = MB_refscan;
else
    load(fullfile(load_folder,'SbData'),'epi_kxkyzc','epi_sampling_mask_kys','epi_fovY','epi_rangeKy')
end

 nShot = para.nshot;
% nShot = 1;
ky_range = para.crop_ky_range;

if max(ky_range) < size(epi_kxkyzc, 2)
    epi_kxkyzc=single(epi_kxkyzc(:,ky_range,:,:));
    epi_rangeKy = length(ky_range);
%     disp('cropped');
else
    if max(ky_range)-10 > size(epi_kxkyzc, 2)
        epi_rangeKy = size(epi_kxkyzc, 2);
%         disp('unchanged');
    else
        [nx, ny, ns, nc] = size(epi_kxkyzc);
        tmp = zeros([nx, max(ky_range), ns, nc]);
        tmp(:, 1:ny, :, :) = epi_kxkyzc;
        epi_kxkyzc = tmp;
        epi_rangeKy = length(ky_range);
%         disp('zeropadded');
    end
end

LPC_method = 1;
if ~exist(fullfile(load_folder,'SbData_lpc.mat'), 'file')
% if 1 % ~exist(fullfile(load_folder,'SbData_lpc.mat'), 'file')
    switch LPC_method
        case {'Entropy_min', 1}
            profile = sos(epi_kxkyzc(:, :, :));
            profile = sos(profile');
            ind_kys = find(profile>0);
            if mod(length(ind_kys), 2) == 1
                ind_kys = [ind_kys; ind_kys(end)+nShot];
            end
            % Detect if the single band data is undersampled
            if sum(profile==0) > 5
                tmp = epi_kxkyzc(:, ind_kys, :, :);
                % No significant displacement found in Siemens data
%                 [tmp,even_from_odd] = oneDimlinearCorr_bulk(tmp,1); 
                [tmp, phasepara_evenOddMajar_zp] = oneDimLinearCorr_entropy(tmp, 1);
                epi_kxkyzc_LPC = epi_kxkyzc;
                epi_kxkyzc_LPC(:, ind_kys, :, :) = tmp;
            else
                [epi_kxkyzc_LPC, phasepara_evenOddMajar_zp] = oneDimLinearCorr_entropy(epi_kxkyzc, nShot);          % LPC for even/odd echo phase error
            end
            if isfield(para, 'refscan') && para.refscan.flag == 1 && isfield(para.refscan, 'phasepara_mapping')
                phasepara_mapping = para.refscan.phasepara_mapping;
                phasepara_evenOddMajar_zp(:, 1) = phasepara_evenOddMajar_zp(:, 1)*phasepara_mapping(1, 1)+phasepara_mapping(1, 2);
                phasepara_evenOddMajar_zp(:, 2) = phasepara_evenOddMajar_zp(:, 2)*phasepara_mapping(2, 1)+phasepara_mapping(2, 2);
            end
            if isfield(para, 'refscan') && para.refscan.flag == 1 && isfield(para.refscan, 'phasepara')
                phasepara_evenOddMajar_zp = para.refscan.phasepara;
            end
            
            %
            if sum(profile==0) < 5
                if nShot > 1 % For multishot cases, inter-shot phase error needs to be corrected
                    [epi_kxkyzc_CPC, phasepara_interShot_zp] = oneDimConstCorr_entropy(epi_kxkyzc_LPC, nShot); % LPC for inter-shot phase error
                    [epi_kxkyzc_LPC1, evenOddResidual_zp] = oneDimLinearCorr_entropy(epi_kxkyzc_CPC, nShot);    % LPC for even/odd echo phase error
                    epi_kxkyzc_lpcCor=single(epi_kxkyzc_LPC1);
                    %
                    save(fullfile(load_folder,'SbData_lpc'),'epi_kxkyzc_lpcCor', 'epi_kxkyzc_LPC', 'epi_kxkyzc_LPC1', ...
                        'epi_kxkyzc_CPC', 'phasepara_*','epi_fovY','epi_rangeKy','-v7.3');
                else
                    epi_kxkyzc_lpcCor=single(epi_kxkyzc_LPC);
                    save(fullfile(load_folder,'SbData_lpc'),'epi_kxkyzc_lpcCor','phasepara_*','epi_fovY','epi_rangeKy','-v7.3'); % Save raw data
                end
            else
                epi_kxkyzc_CPC = epi_kxkyzc_LPC;
                epi_kxkyzc_LPC1 = epi_kxkyzc_LPC;
                epi_kxkyzc_lpcCor = epi_kxkyzc_LPC;
                save(fullfile(load_folder,'SbData_lpc'),'epi_kxkyzc_lpcCor','phasepara_*','epi_fovY','epi_rangeKy','-v7.3'); % Save raw data
            end
    end
    
else
    % Load existing data
    load(fullfile(load_folder,'SbData_lpc'));

end
%% Exporting LPC corrected images
if para.verbose.LPC
    export_dir = [fullfile(load_folder, 'LPC') filesep]; mkdir(export_dir);
    para.mon_size = [4 12];
    
    ns = size(epi_kxkyzc, 3);
    slice_inds = 1:ns;
    
    epi_kxkyzc = rot90(epi_kxkyzc(:, :, slice_inds, :), 1);
    epi_kxkyzc_LPC = rot90(epi_kxkyzc_LPC(:, :, slice_inds, :), 1);
    para.mon_size = [4 12];
    
    % ----- Display with original brightness ------------------------------
    mon_size = para.mon_size;
    temp=sos(ifft2c(epi_kxkyzc));
    disp_max999=prctile(abs(temp(:)),99.9);
    
    im2show = sos(ifft2c(epi_kxkyzc));
    figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('before correction');
    export_fig([export_dir 'LPC_step0_No_Correction'],'-m2','-tif');
    im2show = sos(ifft2c(epi_kxkyzc_LPC));
    figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('Step 1: correct as 2 shots');
    export_fig([export_dir 'LPC_step1'],'-m2','-tif');
    if nShot > 1
        im2show = sos(ifft2c(epi_kxkyzc_CPC));
        figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('Step 2: correct as 1 shot');
        export_fig([export_dir 'LPC_step2'],'-m2','-tif');
        im2show = sos(ifft2c(epi_kxkyzc_LPC1));
        figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('Step 3: correct as 2 shots again');
        export_fig([export_dir 'LPC_step3'],'-m2','-tif');
    end
    
    % ----- Display with enhanced brightness ------------------------------
    disp_max999=prctile(abs(temp(:)),99.9)/5;
    
    im2show = sos(ifft2c(epi_kxkyzc));
    figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('before correction');
    export_fig([export_dir 'LPC_x10_step0_No_Correction'],'-m2','-tif');
    im2show = sos(ifft2c(epi_kxkyzc_LPC));
    figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('Step 1: correct as 2 shots');
    export_fig([export_dir 'LPC_x10_step1'],'-m2','-tif');
    if nShot > 1
        im2show = sos(ifft2c(epi_kxkyzc_CPC));
        figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('Step 2: correct as 1 shot');
        export_fig([export_dir 'LPC_x10_step2'],'-m2','-tif');
        im2show = sos(ifft2c(epi_kxkyzc_LPC1));
        figure(1); MY_montage(im2show,'size',mon_size,'displayrange',[0 disp_max999]); % title('Step 3: correct as 2 shots again');
        export_fig([export_dir 'LPC_x10_step3'],'-m2','-tif');
    end
    
end % Ending for exporting LPC corrected images

end