## 📜 BẢN ĐẶC TẢ KIẾN TRÚC SẢN PHẨM: "MAGIC DOODLE"

*(Phiên bản: 1.0 | Trạng thái: Sẵn sàng Build)*

### 1. Tầm nhìn sản phẩm (Product Vision)

Một ứng dụng EdTech "biến họa thành thật". Sử dụng AI tại biên (Edge AI) để quét các nét vẽ tay nghuệch ngoạc của trẻ em trên giấy thực tế, ngay lập tức hô biến chúng thành các mô hình 3D sinh động kèm âm thanh song ngữ trên màn hình, giúp bé học từ vựng trực quan và phát triển trí tưởng tượng.

### 2. Chân dung người dùng (User Persona)

* **Người dùng cuối (Trẻ em 3-7 tuổi):** Thao tác chưa chuẩn xác, dễ mất kiên nhẫn. Yêu cầu UI không có chữ, nút bấm siêu to khổng lồ, phản hồi real-time.
* **Khách hàng (Phụ huynh):** Quan tâm đến thời lượng sử dụng thiết bị (Screen-time) và lộ trình học của con. Thích app nhẹ, tải nhanh.

### 3. Ngăn xếp Công nghệ (Tech Stack)

* **Frontend & 3D Render:** Flutter (Cross-platform cho cả iOS & Android).
* **AI Engine (Trái tim của app):** TensorFlow Lite (TFLite) chạy On-device. Model AI tự train dựa trên bộ data "Google Quick, Draw!".
* **Backend & Cơ sở hạ tầng:** Firebase (Cloud Storage để lưu file 3D/Audio, Cloud Firestore để lưu log offline/online).

### 4. Phân Tích Kiến Trúc Đa Tầng (Multi-layer Architecture)

Khi setup project trong Antigravity IDE, em chia kiến trúc thư mục bám sát 3 tầng này cho anh:

* **Tầng Giao diện (Presentation Layer):**
* Chỉ có 2 trạng thái màn hình chính: Màn hình Loading (khi tải 3D assets) và Màn hình Camera AR.
* *State Management:* Cực kỳ quan trọng. Khi AI đang "vắt óc" suy nghĩ, UI vẫn phải mượt mà, không được đứng hình khung hình camera.


* **Tầng Xử lý tại biên (Edge Processing Layer):**
* Model TFLite được nhúng trực tiếp vào app. Nó lấy luồng video (stream) từ camera, cắt ra khoảng 3-5 hình/giây (FPS) để đoán.
* *Kiến trúc:* Luồng chạy AI (Isolate/Background Thread) phải hoàn toàn tách biệt với luồng vẽ giao diện (Main UI Thread).


* **Tầng Dữ liệu & Mạng (Data & Integration Layer):**
* **On-Demand Caching:** Lần đầu mở app có mạng, kéo mớ file 3D (.glb/.gltf) từ Firebase Storage về, nhét sâu vào bộ nhớ cục bộ (Local Storage). Những lần sau mở lên rút dây mạng ra app vẫn chạy phà phà.
* **Data Flywheel (Vòng đà dữ liệu):** Khi AI nhận diện nét vẽ dưới 50% tự tin, app âm thầm chụp lại vùng ảnh đó (chỉ lấy nét đen trắng), nén lại siêu nhỏ, dán nhãn "Cần train lại", lưu tạm vào máy. Khi có Wi-Fi, Firestore tự động đẩy data thất bại này lên Cloud cho team em phân tích.



### 5. Luồng Người Dùng Cốt Lõi (Core User Flow)

1. **Khởi động:** Mở app -> Check Wi-Fi -> Nếu có: Tải ngầm file 3D mới (nếu có update). Nếu không: Vào thẳng camera.
2. **Quét ảnh:** Bé đưa tờ giấy vẽ (VD: hình quả táo) vào camera.
3. **Xử lý:** TFLite nhận diện `confidence > 70%` là "Quả táo".
4. **Hiển thị:** Màn hình popup mô hình 3D Quả táo xoay vòng vòng + Phát audio "Apple".
5. **Hậu trường (Background):** Ghi log "Bé học từ Apple, thời gian mở app: 5 phút" vào Firestore. Đẩy ảnh vẽ lỗi (nếu có) lên Storage.
