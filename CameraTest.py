import cv2
import numpy as np
from cv2 import aruco

# --- ArUco辞書と検出パラメータの設定 ---
aruco_dict = aruco.getPredefinedDictionary(aruco.DICT_6X6_250)
parameters = aruco.DetectorParameters_create()
# 必要に応じてパラメータを調整
parameters.adaptiveThreshWinSizeMin = 3
parameters.adaptiveThreshWinSizeMax = 23
parameters.adaptiveThreshConstant = 7
parameters.cornerRefinementMethod = aruco.CORNER_REFINE_SUBPIX

# --- カメラ初期化 ---
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
if not cap.isOpened():
    print("カメラが開けませんでした")
    exit()
print("カメラ起動成功。'q'キーで終了します。")

while True:
    ret, frame = cap.read()
    if not ret:
        continue

    # グレースケール変換
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # マーカー検出
    corners, ids, rejected = aruco.detectMarkers(
        gray,
        aruco_dict,
        parameters=parameters
    )

    # 検出結果を描画
    if ids is not None:
        aruco.drawDetectedMarkers(frame, corners, ids)
        for i, marker_id in enumerate(ids.flatten()):
            # コーナーの中心を計算
            c = corners[i][0]
            center = c.mean(axis=0)
            x, y = int(center[0]), int(center[1])
            cv2.putText(frame, f"ID:{marker_id}",
                        (x, y - 10),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6, (0, 255, 0), 2)

    # 画面表示
    cv2.imshow("ArUco Detection", frame)

    # 'q'キーでループ終了
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
