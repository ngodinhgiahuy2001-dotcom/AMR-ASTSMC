function ITAE = simulate_sensitivity_itae(p,caseNo,t,refXY)
    r0 = model_reference_trajectory(t(1),p);
    q0 = r0(1:3) + p.init.dq;
    eta0 = r0(4:5) + p.init.deta;

    % ASTSMC state: q(3), eta(2), z(2), alpha(2) = 9 states.
    xk = [q0;eta0;0;0;p.AST.alpha0];
    N = numel(t);
    ep = zeros(N,1);
    ep(1) = hypot(refXY(1,1)-xk(1),refXY(1,2)-xk(2));
    dt = p.sim.dt;

    for k = 1:N-1
        tk = t(k);
        k1 = model_robot_dynamics(tk,      xk,         p,'ASTSMC',caseNo);
        k2 = model_robot_dynamics(tk+dt/2, xk+dt*k1/2, p,'ASTSMC',caseNo);
        k3 = model_robot_dynamics(tk+dt/2, xk+dt*k2/2, p,'ASTSMC',caseNo);
        k4 = model_robot_dynamics(tk+dt,   xk+dt*k3,   p,'ASTSMC',caseNo);

        xNext = xk + dt/6*(k1+2*k2+2*k3+k4);
        xNext(8:9) = max(xNext(8:9),p.AST.alphaMin);
        xNext(8:9) = min(xNext(8:9),p.AST.alphaMax);
        xNext(3) = atan2(sin(xNext(3)),cos(xNext(3)));

        if any(~isfinite(xNext)) || any(abs(xNext)>1e8)
            error('Non-finite or divergent state.');
        end

        xk = xNext;
        ep(k+1) = hypot(refXY(k+1,1)-xk(1), ...
                        refXY(k+1,2)-xk(2));
    end

    % ITAE = integral_0^75 t * position_error(t) dt
    ITAE = trapz(t,t.*ep);
end
