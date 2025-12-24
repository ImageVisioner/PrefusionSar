function S=SSF(I,I0)
% global rpos;
% rpos = rotatePosition(80);

[N,M,D]  = size(I);
sizeI2D  = [N,M];  

Dx       = [1, -1]/2;
Dy       = Dx';
otfDx    = psf2otf(Dx, sizeI2D); 
otfDy    = psf2otf(Dy, sizeI2D);

fxx      = [1, -2, 1]/4;
fyy      = fxx';
fuu      = [1 0  0;  0 -2 0;  0 0 1]/4;
fvv      = [0 0  1;  0 -2 0;  1 0 0]/4;
otfFxx   = psf2otf(fxx, sizeI2D);
otfFyy   = psf2otf(fyy, sizeI2D);
otfFuu   = psf2otf(fuu, sizeI2D);
otfFvv   = psf2otf(fvv, sizeI2D);

Denormin1 = abs(otfDx).^2 + abs(otfDy).^2;
Denormin2 = abs(otfFxx).^2 + abs(otfFyy).^2+abs(otfFuu).^2 + abs(otfFvv).^2;
if D>1
    Denormin1 = repmat(Denormin1,[1,1,D]);
    Denormin2 = repmat(Denormin2,[1,1,D]);
end

S           = I;
iter        = 2;
errs        = []; 
alpha       = 0.8;%0.1
beta        = 0.001; %0.02
kappa       = 1;%1.2
tau         = 0.8;%0.95
iter_max    = 500  ; %1000
lambda_max  = 10e3;
lambda      = 10*beta;
Normin0     = fft2(S);
fprintf('结构特征分解(SSF)开始，可能需要几分钟时间... / Structure Feature Decomposition (SSF) started, may take a few minutes...\n');
fprintf('最大迭代次数: %d / Maximum iterations: %d\n', iter_max, iter_max);
fprintf('最大lambda值: %.1e / Maximum lambda: %.1e\n', lambda_max, lambda_max);

while (lambda <= lambda_max) && (iter <= iter_max)

    Denormin  = 1.0 + alpha*Denormin1 + lambda*Denormin2;
    
    % first-order gradients
    gx = imfilter(S, Dx, 'circular');
    gy = imfilter(S, Dy, 'circular');
    
    % second-order gradients
    gxx = imfilter(S, fxx, 'circular');
    gyy = imfilter(S, fyy, 'circular');
    guu = imfilter(S, fuu, 'circular');
    gvv = imfilter(S, fvv, 'circular');
   
    if D==1
        t = (gxx.^2+gyy.^2+guu.^2+gvv.^2)<beta/lambda;
    else
        t = sum((gxx.^2+gyy.^2+guu.^2+gvv.^2),3)<beta/lambda;
        t = repmat(t,[1,1,D]);
    end
    gxx(t)=0; gyy(t)=0; guu(t)=0; gvv(t)=0;
    %figure,imshow(guu,[-1,1]);

    
    Normin_x = circshift(imfilter(gx, Dx(end:-1:1), 'circular'),[0, 1]);
    Normin_y = circshift(imfilter(gy, Dy(end:-1:1), 'circular'),[1, 0]);
    Normin1 = Normin_x+Normin_y;
    %figure,imshow(Normin1);
    
    Normin_xx = imfilter(gxx, fxx(end:-1:1,end:-1:1), 'circular');
    Normin_yy = imfilter(gyy, fyy(end:-1:1,end:-1:1), 'circular');
    Normin_uu = imfilter(guu, fuu(end:-1:1,end:-1:1), 'circular');
    Normin_vv = imfilter(gvv, fvv(end:-1:1,end:-1:1), 'circular');
    
    Normin2 = Normin_xx+Normin_yy+Normin_uu+Normin_vv;
    %figure,imshow(Normin2);

    FS = (Normin0 + alpha*fft2(Normin1) + lambda*fft2(Normin2))./Denormin;
    %figure,imshow(FS);
    S  = real(ifft2(FS));
    
    %err_vec = (S-I0).^2;
    errs(iter)= mse(S,I0);

    alpha  = tau*alpha;
    lambda = kappa*lambda;
    iter = iter+1;

    % 每50次迭代显示一次进度
    if (mod(iter,50) == 0)
        fprintf('SSF迭代进度: %d/%d (%.1f%%), 当前lambda: %.2e, MSE: %.6f\n', iter, iter_max, (iter/iter_max)*100, lambda, errs(iter-1));
        fprintf('SSF iteration progress: %d/%d (%.1f%%), current lambda: %.2e, MSE: %.6f\n', iter, iter_max, (iter/iter_max)*100, lambda, errs(iter-1));
    end
end

fprintf('SSF结构特征分解完成! / SSF Structure Feature Decomposition completed!\n');
fprintf('总迭代次数: %d / Total iterations: %d\n', iter, iter);

