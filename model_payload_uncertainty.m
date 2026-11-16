function phi = model_payload_uncertainty(t,v,r,p)
% Exact mathematical payload model from the local payload_uncertainty()
% function in ORIGINAL model_robot_dynamics.m. Kept separate because MATLAB does not
% expose that local function to other .m files. Do not modify load physics.
mp=model_payload_profile(t);
if mp<=0
    phi=[0;0];
    return;
end
ratio=mp/p.mp_max;
dvd=r(6); dwd=r(7);
F_in=-p.payload.k_in_v*mp*dvd;
F_fr=-p.payload.c_rr*mp*p.g*tanh(v/0.12);
F_osc=p.payload.Fosc*ratio*sin(2.2*t+0.3);
Fres=F_in+F_fr+F_osc;
dJ=p.payload.kJ*mp*p.payload.r_eff^2;
M_in=-p.payload.k_in_w*dJ*dwd;
M_off=-p.payload.y_off*F_in;
M_osc=p.payload.Mosc*ratio*sin(1.7*t+0.8);
Mres=M_in+M_off+M_osc;
phi=[Fres/p.m0;Mres/p.J0];
end
