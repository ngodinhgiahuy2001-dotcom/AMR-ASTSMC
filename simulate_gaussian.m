function result = simulate_gaussian(p,controller,caseNo,noise)
% SIMULATE_GAUSSIAN Sampled SMC/STSMC/ASTSMC on the ORIGINAL AMR model.
%   - Original controller_*.m, model_reference_trajectory.m, model_external_disturbance.m unchanged.
%   - Original payload model reproduced in model_payload_uncertainty.m.
%   - Case 1: sampled nominal with common LPF, no random noise.
%   - Case 2: external sin+bias + process Gaussian + sensor Gaussian.
%   - Case 3: EXACT Case 2 noises and external model_external_disturbance + original payload.
%   - NO torque saturation, gain freeze or anti-windup (deliberately).
%   - LPF initialized with FIRST measured velocity. Feedback held each Ts;
%     plant integrated with substep RK4, with held command and process noise.
% Output fields also follow plot_deterministic_comparison.m legacy contract.

if ~ismember(caseNo,1:3), error('caseNo must be 1,2,3.'); end
if ~ismember(upper(controller),{'SMC','STSMC','ASTSMC'})
    error('controller must be SMC, STSMC or ASTSMC.');
end
Ts=p.stage2.Ts;
t=(p.sim.t0:Ts:p.sim.tf)'; N=numel(t);
assert(abs(t(end)-p.sim.tf)<1e-9,'(tf-t0) must be a multiple of Ts.');
assert(isequal(size(noise.process),[2 N-1]) && isequal(size(noise.sensor),[2 N]));
assert(p.stage2.rkSubsteps>=1 && p.stage2.rkSubsteps==floor(p.stage2.rkSubsteps));
assert(all(p.stage2.tauLPF(:)>0),'All enabled LPF time constants must be positive.');

r0=model_reference_trajectory(t(1),p);
q0=r0(1:3)+p.init.dq;
eta0=r0(4:5)+p.init.deta;
switch upper(controller)
    case 'SMC',   x0=[q0;eta0];
    case 'STSMC', x0=[q0;eta0;zeros(2,1)];
    case 'ASTSMC',x0=[q0;eta0;zeros(2,1);p.AST.alpha0(:)];
end
x=zeros(N,numel(x0)); x(1,:)=x0.';
ref=zeros(N,7); ep=zeros(N,1); eth=zeros(N,1);
u=zeros(N,2); s=zeros(N,2); sFiltered=zeros(N,2);
mp=zeros(N,1); alpha=nan(N,2); zHist=nan(N,2);
etaMeasured=zeros(N,2); etaFiltered=zeros(N,2);
phiDet=zeros(N,2); phiPayload=zeros(N,2);
nuHist=zeros(N,2);

% Case-1 sensors are noiseless; Cases 2 and 3 share EXACT SAME sequences.
usedSensor=zeros(2,N); usedProcess=zeros(2,N-1);
if caseNo>=2
    if p.stage2.useSensorNoise, usedSensor=noise.sensor; end
    if p.stage2.useProcessNoise, usedProcess=noise.process; end
end
rho=exp(-Ts./p.stage2.tauLPF(:));
etaF=zeros(2,1);

for k=1:N
    tk=t(k); state=x(k,:).'; q=state(1:3); eta=state(4:5);
    r=model_reference_trajectory(tk,p);
    etaM=eta+usedSensor(:,k);
    if ~p.stage2.useLPF
        etaF=etaM;
    elseif k==1
        etaF=etaM;                  % LPF initialization: eta_f[0]=eta_m[0]
    else
        etaF=rho.*etaF+(1-rho).*etaM;
    end
    [etaC,etaCDotEst,ethk]=controller_kinematic(q,etaF,r,p);
    sf=etaF-etaC;
    st=eta-etaC;                   % TRUE sliding error for evaluation
    switch upper(controller)
        case 'SMC'
            nu=controller_SMC(sf,p); zdot=zeros(2,1); alphaDot=zeros(2,1);
        case 'STSMC'
            z=state(6:7);
            [nu,zdot]=controller_STSMC(sf,z,p);
            alphaDot=zeros(2,1);
        case 'ASTSMC'
            z=state(6:7); a=state(8:9);
            [nu,zdot,alphaDot]=controller_ASTSMC(sf,z,a,p);
            alpha(k,:)=a.';
    end

    % Original nominal compensation, but measured velocity is FILTERED.
    % No saturation: applied generalized input == commanded input.
    uCmd=[p.Bv0*etaF(1)+p.m0*(etaCDotEst(1)+nu(1)); ...
          p.Bw0*etaF(2)+p.J0*(etaCDotEst(2)+nu(2))];
    ref(k,:)=r.'; ep(k)=hypot(r(1)-q(1),r(2)-q(2)); eth(k)=ethk;
    u(k,:)=uCmd.'; nuHist(k,:)=nu.';
    s(k,:)=st.'; sFiltered(k,:)=sf.';
    etaMeasured(k,:)=etaM.'; etaFiltered(k,:)=etaF.';
    if ~strcmpi(controller,'SMC'),zHist(k,:)=state(6:7).';end
    if caseNo==3 && p.stage2.usePayload,mp(k)=model_payload_profile(tk);end
    [~,pd,pp]=model_sampled_plant_rhs(tk,state(1:5),uCmd,p,caseNo,zeros(2,1));
    phiDet(k,:)=pd.'; phiPayload(k,:)=pp.';
    if k==N,break;end

    % Plant-only RK4 with fixed uCmd and process acceleration within Ts.
    h=Ts/p.stage2.rkSubsteps;
    plant=state(1:5);
    for j=1:p.stage2.rkSubsteps
        tj=tk+(j-1)*h;
        nP=usedProcess(:,k);
        k1=model_sampled_plant_rhs(tj,      plant,           uCmd,p,caseNo,nP);
        k2=model_sampled_plant_rhs(tj+h/2,  plant+h*k1/2,    uCmd,p,caseNo,nP);
        k3=model_sampled_plant_rhs(tj+h/2,  plant+h*k2/2,    uCmd,p,caseNo,nP);
        k4=model_sampled_plant_rhs(tj+h,    plant+h*k3,      uCmd,p,caseNo,nP);
        plant=plant+(h/6)*(k1+2*k2+2*k3+k4);
    end
    plant(3)=atan2(sin(plant(3)),cos(plant(3)));
    next=state;
    next(1:5)=plant;
    if ~strcmpi(controller,'SMC')
        next(6:7)=state(6:7)+Ts*zdot;
    end
    if strcmpi(controller,'ASTSMC')
        aNext=state(8:9)+Ts*alphaDot;
        next(8:9)=max(p.AST.alphaMin(:),min(p.AST.alphaMax(:),aNext));
    end
    if ~all(isfinite(next))
        error('Non-finite state: Case %d, %s, t=%.3f s.',caseNo,controller,tk);
    end
    x(k+1,:)=next.';
end

T=t(end)-t(1);
m.RMSE_pos=sqrt(trapz(t,ep.^2)/T);
m.Max_pos=max(ep);
m.RMSE_theta=sqrt(trapz(t,eth.^2)/T);
m.IAE=trapz(t,ep);
m.ISE=trapz(t,ep.^2);
m.ITAE=trapz(t,t.*ep);
m.RMS_uv=sqrt(trapz(t,u(:,1).^2)/T);
m.RMS_uw=sqrt(trapz(t,u(:,2).^2)/T);
if strcmpi(controller,'ASTSMC')
    m.Max_alpha_v=max(alpha(:,1));m.Max_alpha_w=max(alpha(:,2));
    m.Mean_alpha_v=mean(alpha(:,1));m.Mean_alpha_w=mean(alpha(:,2));
else
    m.Max_alpha_v=NaN;m.Max_alpha_w=NaN;
    m.Mean_alpha_v=NaN;m.Mean_alpha_w=NaN;
end
m.RMS_sliding_v=sqrt(trapz(t,s(:,1).^2)/T);
m.RMS_sliding_w=sqrt(trapz(t,s(:,2).^2)/T);

result=struct('t',t,'x',x,'ref',ref,'ep',ep,'eth',eth, ...
 'u',u,'s',s,'mp',mp,'alpha',alpha,'controller',upper(controller), ...
 'caseNo',caseNo,'metrics',m, 'sFiltered',sFiltered, ...
 'etaTrue',x(:,4:5),'etaMeasured',etaMeasured,'etaFiltered',etaFiltered, ...
 'sensorNoise',usedSensor.','processNoise',[usedProcess.';nan(1,2)], ...
 'phiDet',phiDet,'phiPayload',phiPayload,'nu',nuHist,'z',zHist, ...
 'seed',noise.seed,'Ts',Ts,'rkSubsteps',p.stage2.rkSubsteps, ...
 'LPFEnabled',p.stage2.useLPF);
end
