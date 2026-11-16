function [Results,Metrics,Quality,outDir] = run_gaussian_quality()
% RUN_GAUSSIAN_QUALITY Run full 3-cases x 3 controllers with revised LPF.
% Stage 2.2: ONLY LPF tau default changed to 0.005 s.
% No original controller, model_external_disturbance, nominal model, or payload edits.
% Use check_lpf_response('full') first for a paired baseline contrast.
p=config_noise();
assert(all(abs(p.stage2.tauLPF(:)-.005)<1e-12),...
  'Stage22 requires tauLPF=0.005s in stage2_parameters.m');
[Results,Metrics,outDir]=run_gaussian(p);
rows=cell(9,11);k=0;
for ca=1:3
 for ic=1:3
    r=Results{ca,ic};k=k+1;
    lag=r.etaFiltered-r.etaTrue;
    if ic==3
        a=r.alpha;
        pct=100*mean(bsxfun(@ge,a,p.AST.alphaMax(:).'-1e-6),1);
        aMax=max(a,[],1);
    else
        pct=[NaN NaN];aMax=[NaN NaN];
    end
    rows(k,:)={ca,r.controller,r.metrics.ITAE,r.metrics.IAE,...
        r.metrics.RMSE_pos,sqrt(mean(lag(:,1).^2)),...
        sqrt(mean(lag(:,2).^2)),pct(1),pct(2),aMax(1),aMax(2)};
 end
end
Quality=cell2table(rows,'VariableNames',{'Case','Controller','ITAE_m_s2',...
   'IAE_m_s','RMSE_pos_m','RMS_lag_v_mps','RMS_lag_w_radps',...
   'AlphaV_atMax_pct','AlphaW_atMax_pct','AlphaV_max','AlphaW_max'});
writetable(Quality,fullfile(outDir,'Stage22_Quality_Metrics.csv'));
disp(Quality);
if any(Quality.AlphaV_atMax_pct(3:3:end)>5 | Quality.AlphaW_atMax_pct(3:3:end)>5)
    warning('ASTSMC reaches upper gain bound in >5%% of samples; inspect filter and sliding errors.');
end
fprintf('\nStage 2.2 completed: %s\n',outDir);
end
