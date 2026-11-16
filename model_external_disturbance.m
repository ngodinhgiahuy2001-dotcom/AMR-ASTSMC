function phi = model_external_disturbance(t,p)
% MODEL_EXTERNAL_DISTURBANCE  Baseline external model_external_disturbance, applied in Cases 2 and 3.
w1 = smooth_window(t,15,35,2);
w2 = smooth_window(t,40,58,2);

phi_v = w1*(p.dist.v_amp1*sin(0.9*t)+p.dist.v_bias1) ...
      + w2*(p.dist.v_amp2*sin(1.15*t)+p.dist.v_bias2);
phi_w = w1*(p.dist.w_amp1*sin(0.7*t+0.4)+p.dist.w_bias1) ...
      + w2*(p.dist.w_amp2*sin(0.95*t)+p.dist.w_bias2);
phi = p.dist.scale * [phi_v;phi_w];
end

function y = smooth_window(t,t1,t2,tr)
if t <= t1 || t >= t2
    y = 0;
elseif t < t1+tr
    q=(t-t1)/tr; y=10*q^3-15*q^4+6*q^5;
elseif t > t2-tr
    q=(t2-t)/tr; y=10*q^3-15*q^4+6*q^5;
else
    y = 1;
end
end
