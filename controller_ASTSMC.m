function [nu,zdot,alphadot,beta,gu,gd] = controller_ASTSMC(s,z,alpha,p)
% CONTROLLER_ASTSMC  Bounded bidirectional adaptive Super-Twisting law.
sigma = tanh(s./p.AST.phi);
beta = p.AST.kappa.^2.*alpha + p.AST.beta0;
nu = -alpha.*sqrt(abs(s)).*sigma + z;
zdot = -beta.*sigma;

gu = 0.5*(1+tanh((abs(s)-p.AST.muH)./p.AST.delta));
gd = 0.5*(1+tanh((p.AST.muL-abs(s))./p.AST.delta));
h = p.AST.gammaUp.*gu ...
  - p.AST.gammaDown.*gd.*(alpha-p.AST.alphaMin);

alphadot = h;
for i=1:2
    if alpha(i) >= p.AST.alphaMax(i) && h(i) > 0
        alphadot(i)=0;
    elseif alpha(i) <= p.AST.alphaMin(i) && h(i) < 0
        alphadot(i)=0;
    end
end
end
