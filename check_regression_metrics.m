function Check = check_regression_metrics()
% CHECK_REGRESSION_METRICS Compare unchanged Stage-2.2 implementation
% against archived reference ITAE values (same seed and 75-s mission).
% Reference data: archived Gaussian/LPF regression metrics,
%             Metrics_3Cases_Stage2.csv.
% This is a software regression check, NOT validation of physical truth.
p=config_noise();
p.stage2.exportPlots=false;
p.stage2.saveMAT=false;
p.stage2.printProgress=false;
assert(abs(p.stage2.tauLPF(1)-.005)<1e-12,...
    'Expected Stage-2.2 LPF tau = 5 ms.');
assert(p.stage2.seed==20261113,...
    'Regression reference was generated with seed 20261113.');
t=(p.sim.t0:p.stage2.Ts:p.sim.tf)';
noise=generate_gaussian_noise(p,numel(t));
controllers={'STSMC','ASTSMC'};
reference=[2.37738128346723,2.38272915011243;...
           3.25372378366835,2.53002808893632;...
           5.31315232171661,2.82780799576636];
rows=cell(6,6);ii=0;
for ca=1:3
    for j=1:2
        name=controllers{j};
        r=simulate_gaussian(p,name,ca,noise);
        itae=r.metrics.ITAE;
        expected=reference(ca,j);
        absDiff=abs(itae-expected);
        tolerance=max(0.005,0.005*expected); % 0.5% relative, >=0.005
        passed=absDiff<=tolerance;
        ii=ii+1;
        rows(ii,:)={ca,name,itae,expected,absDiff,passed};
        fprintf('Stage3 regression C%d %-6s: %.6f, reference %.6f, %s\n',...
            ca,name,itae,expected,check_pass_label(passed));
    end
end
Check=cell2table(rows,'VariableNames',{'Case','Controller',...
    'Observed_ITAE','Reference_ITAE','AbsoluteDifference','Pass'});
assert(all(Check.Pass),...
    ['Regression mismatch with the archived reference metrics. ',...
     'Do not run Stage 3 until Stage-2.2 configuration is reconciled.']);
fprintf('PASS: Stage-2.2 software regression (6 ITAE checks).\n');
end
function s=check_pass_label(p)
if p,s='PASS';else,s='FAIL';end
end
