
function [PreFusion] =prfusionPress (ImgIr, ImgVis,BalanceParameters)
    % Parameter Description
    % ImgIr:  Infrared image to be fused
    % ImgVis: Visible image to be fused
    % FusionPath: Fusion image storage path
    % BalanceParameters: Controls the balance of infrared image contrast fidelity and infrared visible gradient
    %% Prefusion
    [H,W] = size(ImgIr);
    
    % Modify the image shape to fit the function requirements
    Vis = shrink(H,W,ImgVis,2);
    
    % From 'https://www.mathworks.com/matlabcentral/fileexchange/36278-split-bregman-method-for-total-variation-denoising?s_tid=srchtitle'
    % Modify function input port
    PreFusion = Bregman(-Vis,BalanceParameters); 

    % Inverse transformation back to original shape
    PreFusion = reshape(PreFusion,[max(H,W),max(H,W)]);
    PreFusion = shrink(H,W,PreFusion,3); 
    
    % % PreFusion = (PreFusion+ImgIr+ImgVis)/3;
    PreFusion = PreFusion+ImgIr*0.5+ImgVis*0.5;
    PreFusion = mat2gray(PreFusion);
    PreFusion=im2double(PreFusion);
    
   

end
