function [result,outputFile] = run_single_controller(p,controller,caseNo,outputBase)
% RUN_SINGLE_CONTROLLER Original main.m single-controller baseline experiment.
% MAT filename and interactive figures retain their original behavior.
if nargin<1 || isempty(p), p=config_parameters(); end
if nargin<2 || isempty(controller), controller='SMC'; end
if nargin<3 || isempty(caseNo), caseNo=3; end
if nargin<4 || isempty(outputBase), outputBase=fileparts(mfilename('fullpath')); end
controller=validatestring(controller,{'SMC','STSMC','ASTSMC'});
validateattributes(caseNo,{'numeric'},{'scalar','integer','>=',1,'<=',3});
if ~exist(outputBase,'dir')
    [ok,msg]=mkdir(outputBase); assert(ok,'Cannot create output folder: %s',msg);
end

%% Time vector
dt = p.sim.dt;

t = (p.sim.t0:dt:p.sim.tf)';

N = numel(t);


%% Initial reference
r0 = model_reference_trajectory(t(1),p);

q0 = ...
    r0(1:3) ...
    + p.init.dq;

eta0 = ...
    r0(4:5) ...
    + p.init.deta;


%% Initial state
switch upper(controller)

    case 'SMC'

        x0 = [ ...
            q0; ...
            eta0];


    case 'STSMC'

        x0 = [ ...
            q0; ...
            eta0; ...
            0; ...
            0];


    case 'ASTSMC'

        x0 = [ ...
            q0; ...
            eta0; ...
            0; ...
            0; ...
            p.AST.alpha0];


    otherwise

        error('Unknown controller: %s',controller);

end


%% State history
nx = numel(x0);

x = zeros(N,nx);

x(1,:) = x0.';


%% Fixed-step RK4
tic;

for k = 1:N-1

    tk = t(k);

    xk = x(k,:).';


    k1 = model_robot_dynamics( ...
        tk, ...
        xk, ...
        p, ...
        controller, ...
        caseNo);


    k2 = model_robot_dynamics( ...
        tk + dt/2, ...
        xk + dt*k1/2, ...
        p, ...
        controller, ...
        caseNo);


    k3 = model_robot_dynamics( ...
        tk + dt/2, ...
        xk + dt*k2/2, ...
        p, ...
        controller, ...
        caseNo);


    k4 = model_robot_dynamics( ...
        tk + dt, ...
        xk + dt*k3, ...
        p, ...
        controller, ...
        caseNo);


    xNext = ...
        xk ...
        + dt/6*( ...
            k1 ...
            + 2*k2 ...
            + 2*k3 ...
            + k4);


    %% ASTSMC gain projection
    if strcmpi(controller,'ASTSMC')

        xNext(8:9) = ...
            max( ...
                xNext(8:9), ...
                p.AST.alphaMin);

        xNext(8:9) = ...
            min( ...
                xNext(8:9), ...
                p.AST.alphaMax);

    end


    %% Wrap heading
    xNext(3) = ...
        atan2( ...
            sin(xNext(3)), ...
            cos(xNext(3)));


    x(k+1,:) = xNext.';

end

runtime = toc;


%% Postprocess
result = postprocess( ...
    t, ...
    x, ...
    p, ...
    controller, ...
    caseNo);


%% Save
outputFile = fullfile(outputBase, ...
    sprintf('Result_Case%d_%s.mat',caseNo,controller));
save(outputFile,'result','p');


%% Plot
plot_single_controller(result,p);


%% Results
fprintf('\n');
fprintf('Controller : %s\n',controller);
fprintf('Case       : %d\n',caseNo);
fprintf('dt         : %.3f s\n',p.sim.dt);
fprintf('Runtime    : %.3f s\n\n',runtime);

disp(result.metrics);




end

function result = postprocess(t,x,p,controller,caseNo)

N = numel(t);

ref   = zeros(N,7);
ep    = zeros(N,1);
eth   = zeros(N,1);
u     = zeros(N,2);
s     = zeros(N,2);
mp    = zeros(N,1);
alpha = nan(N,2);


for k = 1:N

    %% Reference
    ref(k,:) = model_reference_trajectory(t(k),p).';

    mp(k) = model_payload_profile(t(k));


    %% States
    q   = x(k,1:3).';
    eta = x(k,4:5).';

    th = q(3);


    %% Pose error
    Dx = ref(k,1)-q(1);
    Dy = ref(k,2)-q(2);

    ex = ...
        cos(th)*Dx ...
        + sin(th)*Dy;

    ey = ...
        -sin(th)*Dx ...
        + cos(th)*Dy;

    et = ...
        atan2( ...
            sin(ref(k,3)-th), ...
            cos(ref(k,3)-th));


    %% Reference
    vd  = ref(k,4);
    wd  = ref(k,5);
    dvd = ref(k,6);
    dwd = ref(k,7);


    %% Commands
    vc = ...
        vd*cos(et) ...
        + p.outer.kx*ex;

    wc = ...
        wd ...
        + p.outer.ky*vd*ey ...
        + p.outer.kth*sin(et);


    %% Error derivatives
    exd = ...
        eta(2)*ey ...
        - eta(1) ...
        + vd*cos(et);

    eyd = ...
        -eta(2)*ex ...
        + vd*sin(et);

    etd = ...
        wd ...
        - eta(2);


    %% Command derivatives
    vcd = ...
        dvd*cos(et) ...
        - vd*sin(et)*etd ...
        + p.outer.kx*exd;

    wcd = ...
        dwd ...
        + p.outer.ky*( ...
            dvd*ey ...
            + vd*eyd) ...
        + p.outer.kth*cos(et)*etd;


    %% Sliding variable
    ss = [ ...
        eta(1)-vc; ...
        eta(2)-wc];

    s(k,:) = ss.';


    %% Controller
    switch upper(controller)

        case 'SMC'

            nu = controller_SMC(ss,p);


        case 'STSMC'

            z = x(k,6:7).';

            [nu,~] = ...
                controller_STSMC( ...
                    ss, ...
                    z, ...
                    p);


        case 'ASTSMC'

            z = x(k,6:7).';

            alpha_k = x(k,8:9).';

            [nu,~,~,~,~,~] = ...
                controller_ASTSMC( ...
                    ss, ...
                    z, ...
                    alpha_k, ...
                    p);

            alpha(k,:) = alpha_k.';

    end


    %% Control inputs
    uv = ...
        p.Bv0*eta(1) ...
        + p.m0*vcd ...
        + p.m0*nu(1);

    uw = ...
        p.Bw0*eta(2) ...
        + p.J0*wcd ...
        + p.J0*nu(2);

    u(k,:) = [uv,uw];


    %% Tracking error
    ep(k)  = hypot(Dx,Dy);
    eth(k) = et;

end


%% Metrics
T = t(end)-t(1);

metrics.RMSE_pos = ...
    sqrt(trapz(t,ep.^2)/T);

metrics.Max_pos = ...
    max(ep);

metrics.RMSE_theta = ...
    sqrt(trapz(t,eth.^2)/T);

metrics.IAE = ...
    trapz(t,ep);

metrics.ISE = ...
    trapz(t,ep.^2);

metrics.ITAE = ...
    trapz(t,t.*ep);

metrics.RMS_uv = ...
    sqrt(trapz(t,u(:,1).^2)/T);

metrics.RMS_uw = ...
    sqrt(trapz(t,u(:,2).^2)/T);


if strcmpi(controller,'ASTSMC')

    metrics.Max_alpha_v = max(alpha(:,1));
    metrics.Max_alpha_w = max(alpha(:,2));

    metrics.Mean_alpha_v = mean(alpha(:,1));
    metrics.Mean_alpha_w = mean(alpha(:,2));

else

    metrics.Max_alpha_v  = NaN;
    metrics.Max_alpha_w  = NaN;

    metrics.Mean_alpha_v = NaN;
    metrics.Mean_alpha_w = NaN;

end


result = struct( ...
    't',t, ...
    'x',x, ...
    'ref',ref, ...
    'ep',ep, ...
    'eth',eth, ...
    'u',u, ...
    's',s, ...
    'mp',mp, ...
    'alpha',alpha, ...
    'controller',controller, ...
    'caseNo',caseNo, ...
    'metrics',metrics);

end