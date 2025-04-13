# iTaoDoc - Ứng dụng đọc nội dung web

Ứng dụng đọc nội dung web tối ưu hóa, loại bỏ quảng cáo và định dạng phức tạp.

## Cài đặt

### Yêu cầu hệ thống
- Android 5.0 trở lên
- iOS 11.0 trở lên (cho bản iOS)
- macOS với Xcode 13.0 trở lên (để build cho iOS)

### Cài đặt trên Android
1. Tải file APK từ [release](link-to-release)
2. Cài đặt APK vào thiết bị
3. Cấp quyền Internet cho ứng dụng nếu được yêu cầu

### Cài đặt và chạy trên iOS với Xcode
1. Cài đặt [Flutter](https://flutter.dev/docs/get-started/install) và [Xcode](https://developer.apple.com/xcode/)
2. Giải nén file itaodoc.zip
3. Chạy `flutter pub get` để cài đặt các thư viện
4. Chạy `open ios/Runner.xcworkspace` để mở project trong Xcode
5. Trong Xcode:
   - Chọn team phát triển (Apple ID) trong mục Signing & Capabilities
   - Chọn thiết bị đích (iPhone hoặc iPad thực/giả lập)
   - Nhấn nút Run (▶️)
6. Hoặc từ dòng lệnh:
   - Chạy `flutter run -d ios` để khởi động trong chế độ debug
   - Chạy `flutter build ios --release` để build phiên bản release

### Cài đặt từ mã nguồn
1. Cài đặt [Flutter](https://flutter.dev/docs/get-started/install)
2. Giải nén file itaodoc.zip
3. Chạy `flutter pub get` để cài đặt các thư viện
4. Chạy `flutter run` để khởi động ứng dụng trong chế độ debug
5. Để build bản release:
   - Android: `flutter build apk --release`
   - iOS: `flutter build ios --release`


