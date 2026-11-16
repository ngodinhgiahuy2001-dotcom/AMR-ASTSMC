# Hướng dẫn sử dụng mã MATLAB ASTSMC–AMR

Bộ mã nguồn được chuẩn hóa để đưa lên GitHub, không chứa thông tin nhận diện cá nhân. **Giữ tất cả file `.m` trong cùng một thư mục** và chọn thư mục đó làm Current Folder của MATLAB.

## File chính cần chạy

- `main.m`: chạy ba điều kiện deterministic với SMC, STSMC và ASTSMC.
- `main_single_controller.m`: chạy một bộ điều khiển và điều kiện.
- `main_gaussian.m`: mô phỏng Gaussian/LPF một seed.
- `main_gaussian_statistics.m`: chạy đánh giá Gaussian/LPF 30 seed.
- `main_ablation.m`: ablation N0–N4.
- `main_sensitivity.m`: độ nhạy ASTSMC cho cả ba điều kiện, mỗi điều kiện 17×17 tổ hợp.
- `main_replot_sensitivity.m`: vẽ lại Fig. 18 từ các file `ITAE_Sensitivity.mat`, không cần tính lại 867 lượt.
- `main_selftest.m`: kiểm tra sự đầy đủ phụ thuộc và kết quả hồi quy.

## Tham số

- `config_experiment.m`: điều kiện chạy, quick/full, số seed, đường dẫn xuất.
- `config_parameters.m`: tham số robot và controller deterministic.
- `config_noise.m`: thiết lập Gaussian/LPF và bộ giải lấy mẫu.
- `config_plot_style.m`: định dạng xuất đồ thị.

## Chạy và tải lên GitHub

Chạy `main_selftest` trước khi công bố kết quả. Mã đã được kiểm tra tham chiếu tĩnh nhưng **chưa thực thi bằng MATLAB tại môi trường đóng gói**.

Khởi tạo Git từ chính thư mục chứa `.m`:

```bash
git init -b main
git add .
git commit -m "Initial public research code structure"
```

Tạo một GitHub repository trống, sau đó dùng `git remote add origin <URL>` và `git push -u origin main`. Bộ kết quả MAT/FIG/PDF nên quản lý riêng, không cần đưa vào lịch sử Git của code.
