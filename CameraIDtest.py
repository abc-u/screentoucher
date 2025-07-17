import cv2

cap = cv2.VideoCapture(0)  # カメラID 0（使用可能と確認済み）

if not cap.isOpened():
    print("❌ カメラが開けません。")
    exit()

print("✅ カメラ起動成功。'q' キーで終了できます。")

while True:
    ret, frame = cap.read()
    if not ret:
        print("❌ フレーム取得失敗。")
        break

    # フレームサイズやチャンネル数を表示（デバッグ用）
    print(f"Frame shape: {frame.shape}")  # 例: (480, 640, 3)

    cv2.imshow("Camera Test", frame)

    # 'q'キーで終了
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
