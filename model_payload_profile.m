function mp = model_payload_profile(t)
% MODEL_PAYLOAD_PROFILE  Smooth 0->300->800->200->0 kg profile.
if t < 8
    mp = 0;
elseif t < 12
    mp = ramp_mass(t,8,12,0,300);
elseif t < 23
    mp = 300;
elseif t < 27
    mp = ramp_mass(t,23,27,300,800);
elseif t < 42
    mp = 800;
elseif t < 46
    mp = ramp_mass(t,42,46,800,200);
elseif t < 57
    mp = 200;
elseif t < 61
    mp = ramp_mass(t,57,61,200,0);
else
    mp = 0;
end
end

function m = ramp_mass(t,ta,tb,ma,mb)
tau = min(max((t-ta)/(tb-ta),0),1);
lambda = 10*tau^3-15*tau^4+6*tau^5;
m = ma+(mb-ma)*lambda;
end
