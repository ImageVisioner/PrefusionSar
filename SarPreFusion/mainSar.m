clear;
close all;
fprintf('===================================================\n');
fprintf('SAR图像融合程序启动 / SAR Image Fusion Program Started\n');
fprintf('===================================================\n');

if isempty(gcp('nocreate'))
    fprintf('正在启动并行计算池... / Starting parallel computing pool...\n');
    parpool;
    fprintf('并行计算池已启动 / Parallel computing pool started\n');
end

fprintf('正在添加函数路径... / Adding function paths...\n');
addpath Function\
addpath Function\preprocessing\
addpath Function\decomposition\
addpath Function\fusion\
addpath Function\weighting\
addpath Function\utilities\
fprintf('函数路径添加完成 / Function paths added successfully\n');

ParaSet=100; %% 原始是100
fprintf('平衡参数设置为: %d / Balance parameter set to: %d\n', ParaSet, ParaSet);

fprintf('正在创建输出文件夹... / Creating output directories...\n');
mkdir Prefusedir
mkdir fusedir
fprintf('输出文件夹创建完成 / Output directories created\n');

tic
fprintf('开始处理图像... / Starting image processing...\n');
for i=1:1
    fprintf('\n-----------------------------------------------\n');
    fprintf('正在处理第 %d 张图像 / Processing image %d\n', i, i);
    fprintf('-----------------------------------------------\n');

    fprintf('正在读取输入图像路径... / Reading input image paths...\n');
    image_ir =['C:\Users\ImageVisioner\Desktop\YYX-OPT-SAR-main\new\sar\',num2str(i),'.png'];
    image_vis = ['C:\Users\ImageVisioner\Desktop\YYX-OPT-SAR-main\new\opt\',num2str(i),'.png'];
    fprintf('SAR图像路径: %s / SAR image path: %s\n', image_ir, image_ir);
    fprintf('光学图像路径: %s / Optical image path: %s\n', image_vis, image_vis);

    fprintf('正在读取和预处理图像... / Reading and preprocessing images...\n');
    a=im2gray(imread(image_ir));
    b=im2gray(imread(image_vis));
    figure(2),imshowpair(a,b,'montage'),title("Source images: SAR and Optical")
    a=im2double(a);
    b=im2double(b);
    fprintf('图像读取和预处理完成 / Image reading and preprocessing completed\n');
    fprintf('SAR图像尺寸: %dx%d / SAR image size: %dx%d\n', size(a,1), size(a,2), size(a,1), size(a,2));
    fprintf('光学图像尺寸: %dx%d / Optical image size: %dx%d\n', size(b,1), size(b,2), size(b,1), size(b,2));

    fprintf('正在进行预融合处理... / Performing pre-fusion processing...\n');
    PreFusion = prfusionPress(a,b,ParaSet);
    fprintf('预融合处理完成 / Pre-fusion processing completed\n');

    prefused_path =  ['.\Prefusedir\',num2str(i),'.bmp'];
    figure(1),imshow(PreFusion),title("PreFusion image")
    imwrite(PreFusion,prefused_path);
    fprintf('预融合图像已保存到: %s / Pre-fusion image saved to: %s\n', prefused_path, prefused_path);

    % figure(2),imshowpair(a,b,'montage'),title("src image")

    fprintf('正在进行图像分解... / Performing image decomposition...\n');

    fprintf('  正在分解预融合图像... / Decomposing pre-fusion image...\n');
    p1=SSF(PreFusion,PreFusion); %% 纹理层
    p_detail=PreFusion-p1 ;%细节层
    fprintf('  预融合图像分解完成 / Pre-fusion image decomposition completed\n');

    fprintf('  正在分解SAR图像... / Decomposing SAR image...\n');
    L1=SSF(a,a);%纹理层
    D1=a-L1;  %细节层
    fprintf('  SAR图像分解完成 / SAR image decomposition completed\n');

    fprintf('  正在分解光学图像... / Decomposing optical image...\n');
    L2=SSF(b,b);
    D2=b-L2;
    fprintf('  光学图像分解完成 / Optical image decomposition completed\n');

    r=15;
    fprintf('局部窗口半径设置为: %d / Local window radius set to: %d\n', r, r);

    fprintf('正在进行纹理层融合... / Performing texture layer fusion...\n');
    imgSeqColor=zeros(size(a,1),size(a,2),2);
    imgSeqColor(:,:,1)=p1;
    imgSeqColor(:,:,2)=L1;
    C_out = single_scale(imgSeqColor,r);
    fprintf('  纹理层融合(SAR)完成 / Texture layer fusion (SAR) completed\n');

    imgSeqColor1(:,:,1)=p1;
    imgSeqColor1(:,:,2)=L2;
    C_out_1 = single_scale(imgSeqColor1,r);
    fprintf('  纹理层融合(光学)完成 / Texture layer fusion (Optical) completed\n');

    c_tex=max(C_out,C_out_1);
    fprintf('  纹理层融合结果合并完成 / Texture layer fusion results merged\n');

    fprintf('正在进行细节层融合... / Performing detail layer fusion...\n');
    imgSeqColor2=zeros(size(a,1),size(a,2),2);
    imgSeqColor2(:,:,1)=p_detail;
    imgSeqColor2(:,:,2)=D1;
    C_out_2 = single_scale(imgSeqColor2,r);
    fprintf('  细节层融合(SAR)完成 / Detail layer fusion (SAR) completed\n');

    imgSeqColor3=zeros(size(a,1),size(a,2),2);
    imgSeqColor3(:,:,1)=p_detail;
    imgSeqColor3(:,:,2)=D2;
    C_out_3 = single_scale(imgSeqColor3,r);
    fprintf('  细节层融合(光学)完成 / Detail layer fusion (Optical) completed\n');

    c_detal=max(C_out_2,C_out_3);
    fprintf('  细节层融合结果合并完成 / Detail layer fusion results merged\n');

    fprintf('正在进行最终图像融合... / Performing final image fusion...\n');
    c_fusion=0.5*c_tex+0.5*c_detal;
    fprintf('最终融合完成 / Final fusion completed\n');

    figure(3),imshow(c_fusion),title("Final Fused Image")
    fused_path =  ['.\fusedir\',num2str(i),'.bmp'];
    imwrite(c_fusion,fused_path);
    fprintf('融合结果已保存到: %s / Fused result saved to: %s\n', fused_path, fused_path);

    elapsed_time = toc;
    fprintf('第 %d 张图像处理完成，耗时 %.2f 秒 / Image %d processing completed, time elapsed: %.2f seconds\n', i, elapsed_time, i, elapsed_time);

end