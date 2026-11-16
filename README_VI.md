# ASTSMC-AMR — Hướng dẫn sử dụng

Bộ mã MATLAB phục vụ nghiên cứu **Adaptive Super-Twisting Sliding Mode Control (ASTSMC)** cho AMR sáu bánh, đối chiếu với SMC và STSMC. Repository chứa mã nguồn, cấu hình và tài liệu tái lập thí nghiệm; không chứa toàn bộ kết quả mô phỏng dung lượng lớn.

## Bắt đầu nhanh

Đặt **toàn bộ file `.m` trong cùng một thư mục** và chọn thư mục này làm MATLAB Current Folder.

```matlab
main_selftest               % Kiểm tra phụ thuộc và 6 mốc hồi quy
main                        % 3 điều kiện deterministic
main_gaussian               % Gaussian/LPF một seed
main_gaussian_statistics    % 30 seed
main_ablation               % N0–N4
main_sensitivity            % 3 x 17 x 17 điểm độ nhạy
main_replot_sensitivity     % Xuất lại Fig. 18 từ MAT
```

Các mục cấu hình chính: `config_experiment.m`, `config_parameters.m`, `config_noise.m` và `config_plot_style.m`.

## Đảm bảo tái lập và phạm vi kiểm tra

- Deterministic dùng phản hồi tính lại tại các RK4 substage.
- Gaussian/LPF dùng điều khiển lấy mẫu và giữ lệnh; **không gộp trị số tuyệt đối của hai bộ giải để quy nguyên nhân cho nhiễu**.
- Fig. 18: ba điều kiện với cùng trục ITAE **1,40–2,70 m·s²**, cùng thang màu, không có title trong hình.
- Đã có bản ghi self-test 6/6 trên MATLAB R2024a; chưa có bằng chứng chạy lại đầy đủ mọi phép mô phỏng từ lần tổ chức repository này.
- Chỉ công bố dữ liệu/ảnh đã được kiểm tra; không đưa file MAT/FIG xuất tự động lên Git theo mặc định.

Tài liệu tham khảo: [README tiếng Anh](README.md), [giao thức tái lập](REPRODUCIBILITY.md), [quy tắc xuất hình](docs/FIGURE_EXPORT.md), [biểu mẫu vấn đề](.github/ISSUE_TEMPLATE), [ẩn danh phản biện](docs/REVIEW_ANONYMIZATION.md).

**Repository hiện chưa kèm giấy phép tái sử dụng mã nguồn.** Việc công bố, trích dẫn và cấp phép cần được thống nhất trước khi phát hành rộng rãi.
