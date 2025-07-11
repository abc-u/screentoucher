import cv2

print("🔍 使用可能なカメラIDをスキャン中...")
for i in range(2):
    cap = cv2.VideoCapture(i)
    if cap.isOpened():
        print(f"✅ カメラID {i} は使用可能です。")
        cap.release()
    else:
        print(f"❌ カメラID {i} は使用不可。")
