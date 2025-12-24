

function u = Bregman(g,mu)
% Split Bregman Anisotropic Total Variation Denoising
%
%   u = arg min_u 1/2||u-g||_2^2 + mu*ATV(u)
%   
%   g : noisy image
%   mu: regularisation parameter
%   u : denoised image
%
% Refs:
%  *Goldstein and Osher, The split Bregman method for L1 regularized problems
%   SIAM Journal on Imaging Sciences 2(2) 2009
%  *Micchelli et al, Proximity algorithms for image models: denoising
%   Inverse Problems 27(4) 2011
%
% Benjamin Tr��moulh��ac
% University College London
% b.tremoulheac@cs.ucl.ac.uk
% April 2012
fprintf('Bregman去噪算法开始... / Bregman denoising algorithm started...\n');

g = g(:);
n = length(g);
[B,Bt,BtB] = DiffOper(sqrt(n));
b = zeros(2*n,1);
d = b;
u = g;
err = 1;k = 1;
tol = 1e-3;
lambda = 1;

fprintf('收敛容差: %.1e / Convergence tolerance: %.1e\n', tol, tol);

while err > tol

    fprintf('Bregman迭代 %d / Bregman iteration %d: ', k, k);
    up = u;
    [u,~] = cgs(speye(n)+BtB, g-lambda*Bt*(b-d), 1e-5, 100);
    F = B*u;
    Bub = F+b;
    d = max(abs(Bub)-mu/lambda,0).*sign(Bub);
    b = Bub-d;
    err = norm(up-u)/norm(u);
    fprintf('误差=%.6f / Error=%.6f\n', err, err);
    k = k+1;
end

fprintf('Bregman去噪收敛! 最终误差: %.6f / Bregman denoising converged! Final error: %.6f\n', err, err);
fprintf('停止原因: norm(up-u)/norm(u) <= tol=%.1e / Stopped because: norm(up-u)/norm(u) <= tol=%.1e\n', tol, tol);

end

function [B,Bt,BtB] = DiffOper(N)

D = spdiags([-ones(N,1) ones(N,1)], [0 1], N,N+1);
D(:,1) = [];
D(1,1) = 0;

B = [ kron(speye(N),D) ; kron(D,speye(N)) ];
Bt = B';
BtB = Bt*B;

end