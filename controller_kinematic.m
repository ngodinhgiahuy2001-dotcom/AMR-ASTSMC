function [etaC,etaCDotEst,headingError] = controller_kinematic(q,etaF,r,p)
% Original outer controller and derivatives copied from model_robot_dynamics.m.
% Stage 2 replaces the exact v,w in derivative formulas with FILTERED etaF.
% This is an explicitly documented derivative estimate, not an exact one.
xd=r(1); yd=r(2); thd=r(3);
vd=r(4); wd=r(5); dvd=r(6); dwd=r(7);
th=q(3);
Dx=xd-q(1); Dy=yd-q(2);
ex=cos(th)*Dx+sin(th)*Dy;
ey=-sin(th)*Dx+cos(th)*Dy;
headingError=atan2(sin(thd-th),cos(thd-th));
vc=vd*cos(headingError)+p.outer.kx*ex;
wc=wd+p.outer.ky*vd*ey+p.outer.kth*sin(headingError);

exd=etaF(2)*ey-etaF(1)+vd*cos(headingError);
eyd=-etaF(2)*ex+vd*sin(headingError);
ethd=wd-etaF(2);
vcd=dvd*cos(headingError)-vd*sin(headingError)*ethd+p.outer.kx*exd;
wcd=dwd+p.outer.ky*(dvd*ey+vd*eyd)+p.outer.kth*cos(headingError)*ethd;
etaC=[vc;wc];
etaCDotEst=[vcd;wcd];
end
