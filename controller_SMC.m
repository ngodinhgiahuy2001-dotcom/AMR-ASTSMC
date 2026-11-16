function nu = controller_SMC(s, p)

%% Check input size
s = s(:);

if numel(s) ~= 2
    error('controller_SMC: s must contain 2 elements.');
end


%% SMC gains
K = p.SMC.K(:);

if numel(K) ~= 2
    error('controller_SMC: p.SMC.K must contain 2 elements.');
end


%% First-order SMC switching law
sigma = sign(s);


%% Robust control term
nu = -K .* sigma;

end