function cfg = config_experiment()
% CONFIG_EXPERIMENT Tham so tac vu; khong chua gain hay phuong trinh.
% main_*.m chon san tac vu. cfg.task chi dung neu goi run_experiment truc tiep.
%
% 'baseline'    : 3 case goc x SMC/STSMC/ASTSMC (RK4 goc, 75 s)
% 'noise'       : 3 case co Gaussian/LPF, 1 seed (75 s)
% 'gaussian30'  : thong ke nhieu seed; mac dinh 30 seed (75 s/seed)
% 'sensitivity': do nhay ASTSMC gammaUp/gammaDown, luoi 17x17
% 'ablation'    : tach anh huong N0 -> N4, 1 seed
% 'selftest'    : kiem tra path, solver, noise va 6 moc ITAE goc
cfg.task = 'baseline';

% 'full': ablation / gaussian30 = 75 s; sensitivity = 17x17.
% 'quick': ablation / gaussian30 = 15 s; sensitivity = 5x5, VAN 75 s.
% baseline / noise / selftest luon dung cau hinh day du.
cfg.mode = 'full';

% Chi dung cho gaussian30. Quick van dung so seed duoc khai bao o day.
% De kiem tra nhanh: cfg.mode='quick'; cfg.nSeeds=3;
cfg.nSeeds = 30;

% main_single_controller.m: chon mot controller va mot case.
cfg.singleController = 'SMC';
cfg.singleCase = 3;

% Sensitivity chi dung mo hinh baseline, KHONG co Gaussian/LPF.
cfg.sensitivityCase = 3;
cfg.showSensitivityFigure = true;

% De rong: luu cac folder Results_... / Stage3_... / Sensitivity_...
% ngay canh main.m, giu ten va cau truc con nhu source goc.
% Co the nhap duong dan tuy chon, vi du 'results_archive'.
cfg.outputBase = '';
end
