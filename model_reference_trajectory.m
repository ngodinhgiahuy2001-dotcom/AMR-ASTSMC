function r = model_reference_trajectory(t,p)
% MODEL_REFERENCE_TRAJECTORY  Smooth factory reference P0-P1-P2-P3-P4-P0.
% r = [x_d;y_d;theta_d;v_d;omega_d;dv_d;domega_d]

P = p.route.P;
M = p.route.M;
motion = p.route.motion;
hold = p.route.hold;

for k = 1:size(motion,1)
    ta = motion(k,1); tb = motion(k,2);
    if t >= ta && t <= tb
        i = motion(k,3); j = motion(k,4);
        T = tb-ta;
        tau = min(max((t-ta)/T,0),1);
        [s,sd_tau,sdd_tau] = qblend(tau);
        sd = sd_tau/T;
        sdd = sdd_tau/T^2;

        [xy,rs,rss,rsss] = hermite_geom(P(i,:),P(j,:),M(i,:),M(j,:),s);
        nr = norm(rs);
        if nr < 1e-12
            theta = 0; vd = 0; wd = 0; dvd = 0; dwd = 0;
        else
            theta = atan2(rs(2),rs(1));
            vd = nr*sd;
            dvd = (dot(rs,rss)/nr)*sd^2 + nr*sdd;

            N = rs(1)*rss(2)-rs(2)*rss(1);
            D = dot(rs,rs);
            theta_s = N/D;
            Np = rs(1)*rsss(2)-rs(2)*rsss(1);
            Dp = 2*dot(rs,rss);
            theta_ss = (Np*D-N*Dp)/(D^2);
            wd = theta_s*sd;
            dwd = theta_ss*sd^2 + theta_s*sdd;
        end
        r = [xy(1);xy(2);theta;vd;wd;dvd;dwd];
        return;
    end
end

for k = 1:size(hold,1)
    ta = hold(k,1); tb = hold(k,2); i = hold(k,3);
    if t >= ta && t <= tb
        theta = atan2(M(i,2),M(i,1));
        r = [P(i,1);P(i,2);theta;0;0;0;0];
        return;
    end
end

theta = atan2(M(end,2),M(end,1));
r = [P(end,1);P(end,2);theta;0;0;0;0];
end

function [s,ds,d2s] = qblend(tau)
s   = 10*tau^3 - 15*tau^4 + 6*tau^5;
ds  = 30*tau^2 - 60*tau^3 + 30*tau^4;
d2s = 60*tau - 180*tau^2 + 120*tau^3;
end

function [r,rs,rss,rsss] = hermite_geom(P0,P1,M0,M1,s)
h00 = 2*s^3-3*s^2+1; h10 = s^3-2*s^2+s;
h01 = -2*s^3+3*s^2;  h11 = s^3-s^2;
r = h00*P0+h10*M0+h01*P1+h11*M1;

hp00 = 6*s^2-6*s; hp10 = 3*s^2-4*s+1;
hp01 = -6*s^2+6*s; hp11 = 3*s^2-2*s;
rs = hp00*P0+hp10*M0+hp01*P1+hp11*M1;

hpp00 = 12*s-6; hpp10 = 6*s-4;
hpp01 = -12*s+6; hpp11 = 6*s-2;
rss = hpp00*P0+hpp10*M0+hpp01*P1+hpp11*M1;

rsss = 12*P0+6*M0-12*P1+6*M1;
end
