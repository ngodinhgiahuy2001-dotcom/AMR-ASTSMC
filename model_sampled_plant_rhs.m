function [dx,phiDet,phiPayload] = model_sampled_plant_rhs(t,x,u,p,caseNo,processSample)
% True five-state AMR model_robot_dynamics. ZERO-ORDER-HOLD input and processSample.
% Original deterministic model_external_disturbance and payload are evaluated at the
% requested RK4 substage time, so their smooth time variation is retained.
q=x(1:3); eta=x(4:5);
phiDet=zeros(2,1);
phiPayload=zeros(2,1);
if caseNo>=2 && p.stage2.useExternalDisturbance
    phiDet=model_external_disturbance(t,p); % UNCHANGED original file
end
if caseNo==3 && p.stage2.usePayload
    phiPayload=model_payload_uncertainty(t,eta(1),model_reference_trajectory(t,p),p);
end
phi=phiDet+phiPayload+processSample;
etaDot=[-p.Bv0/p.m0*eta(1)+u(1)/p.m0+phi(1); ...
        -p.Bw0/p.J0*eta(2)+u(2)/p.J0+phi(2)];
dx=[model_robot_kinematics(q,eta);etaDot];
end
