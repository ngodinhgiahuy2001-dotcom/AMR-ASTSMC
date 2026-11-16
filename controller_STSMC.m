function [nu,zdot] = controller_STSMC(s,z,p)
% CONTROLLER_STSMC  Fixed-gain smoothed Super-Twisting controller.
sigma = tanh(s./p.ST.phi);
nu = -p.ST.alpha.*sqrt(abs(s)).*sigma + z;
zdot = -p.ST.beta.*sigma;
end
