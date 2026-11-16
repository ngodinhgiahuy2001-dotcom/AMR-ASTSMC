function p = config_parameters()

%% Nominal AMR model
p.m0     = 160.0;        % kg
p.J0     = 18.97;        % kg.m^2
p.Bv0    = 5.0;          % N.s/m
p.Bw0    = 2.0;          % N.m.s/rad
p.rw     = 0.1225;       % m
p.track  = 0.60;         % m
p.g      = 9.81;         % m/s^2
p.mp_max = 800.0;        % kg


%% Outer-loop controller
p.outer.kx  = 1.0;
p.outer.ky  = 2.0;
p.outer.kth = 1.0;


%% SMC
p.SMC.K = [5.0; 5.0];


%% Fixed-gain STSMC
% Initial stronger trial set for tuning across Cases 1, 2 and 3.
% NOT a mathematically certified or numerically optimized gain set.
% Vector order: [linear velocity channel; angular velocity channel].
% Keep these gains fixed for all cases to ensure a fair comparison.
p.ST.alpha = [3.00; 3.00];   % alpha_v; alpha_w (trial)
p.ST.beta  = [2.00; 2.00];   % beta_v;  beta_w  (trial)
p.ST.phi   = [0.01; 0.01];   % unchanged smoothing widths


%% ASTSMC
p.AST.alpha0   = [1.20; 1.20];
p.AST.alphaMin = [1.00; 1.00];
p.AST.alphaMax = [8.00; 8.00];

p.AST.gammaUp   = [6.00; 6.00];
p.AST.gammaDown = [0.15; 0.15];

p.AST.kappa = [1.50; 1.50];
p.AST.beta0 = [0.50; 0.50];

p.AST.muL = [5e-4; 5e-4];
p.AST.muH = [2.5e-3; 2.5e-3];

p.AST.phi   = [0.01; 0.01];
p.AST.delta = [5e-4; 5e-4];


%% Simulation
p.sim.t0 = 0.0;
p.sim.tf = 75.0;
p.sim.dt = 0.01;


%% Initial condition
p.init.dq = [ ...
    -0.10; ...
     0.10; ...
     deg2rad(5.0)];

p.init.deta = [ ...
    -0.02; ...
     0.00];


%% Station tolerance
p.station.eps_x  = 0.05;
p.station.eps_y  = 0.05;
p.station.eps_th = deg2rad(3.0);


%% Factory route
p.route.P = [ ...
     0   0; ...
     4   0; ...
     8   3; ...
    12   3; ...
    12   8; ...
     0   0];


%% Motion intervals
p.route.motion = [ ...
     0   8   1   2; ...
    12  23   2   3; ...
    27  42   3   4; ...
    46  57   4   5; ...
    61  75   5   6];


%% Station-hold intervals
p.route.hold = [ ...
     8  12   2; ...
    23  27   3; ...
    42  46   4; ...
    57  61   5];


%% Hermite model_reference_trajectory tangents
P = p.route.P;

M = zeros(size(P));

M(1,:) = 0.5*(P(2,:) - P(1,:));

for i = 2:5
    M(i,:) = 0.5*(P(i+1,:) - P(i-1,:));
end

M(6,:) = 0.5*(P(6,:) - P(5,:));

p.route.M = M;


%% External model_external_disturbance shared by Cases 2 and 3
% Case 2 returns to the baseline model_external_disturbance (scale = 1).
% Case 3 uses the same external model_external_disturbance plus payload uncertainty.
p.dist.scale = 1.0;

p.dist.v_amp1  =  0.35;
p.dist.v_bias1 =  0.22;

p.dist.v_amp2  =  0.28;
p.dist.v_bias2 = -0.18;

p.dist.w_amp1  =  0.20;
p.dist.w_bias1 = -0.10;

p.dist.w_amp2  =  0.22;
p.dist.w_bias2 =  0.12;


%% Payload-induced uncertainty (Case 3 only)
p.payload.k_in_v = 0.90;
p.payload.c_rr   = 0.035;
p.payload.Fosc   = 75.0;

p.payload.r_eff  = 0.31;
p.payload.kJ     = 0.65;
p.payload.k_in_w = 0.95;

p.payload.y_off = 0.14;
p.payload.Mosc  = 8.0;

end