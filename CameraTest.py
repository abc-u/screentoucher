import cv2

cap = cv2.VideoCapture(1)  # 必要に応じて 1 や 2 に変更

if not cap.isOpened():
    print("❌ カメラが開けません。")
    exit()

print("✅ カメラ起動成功。'q' キーで終了できます。")

while True:
    ret, frame = cap.read()
    if not ret:
        print("❌ フレーム取得失敗。")
        break

    cv2.imshow("Camera Test", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
