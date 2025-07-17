import cv2
import numpy as np
from cv2 import aruco
from pythonosc import udp_client

# --- OSC クライアント設定 ---
OSC_IP   = "127.0.0.1"
OSC_PORT = 8000
client = udp_client.SimpleUDPClient(OSC_IP, OSC_PORT)

# --- ArUco 辞書と検出パラメータの設定 ---
aruco_dict = aruco.getPredefinedDictionary(aruco.DICT_6X6_250)
parameters = aruco.DetectorParameters_create()
parameters.adaptiveThreshWinSizeMin = 3
parameters.adaptiveThreshWinSizeMax = 23
parameters.adaptiveThreshConstant = 7
parameters.cornerRefinementMethod = aruco.CORNER_REFINE_SUBPIX

# 四隅マーカー用 ID
marker_id_map = {0:'top_left', 4:'top_right', 19:'bottom_right', 15:'bottom_left'}
WARPED_WIDTH, WARPED_HEIGHT = 1920, 1080

# カメラ初期化
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
if not cap.isOpened():
    print("カメラが開けませんでした")
    exit()
print("カメラ起動成功")

last_valid_src_pts = None
last_pos = {}            # IDごとの最後のデータ保存
target_ids = [1, 2]      # 送信対象

while True:
    ret, frame = cap.read()
    if not ret:
        continue

    # グレースケール変換 → 元画像上で四隅検出
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    corners, ids, _ = aruco.detectMarkers(gray, aruco_dict, parameters=parameters)
    if ids is not None:
        id_map = {int(i[0]): c[0] for i, c in zip(ids, corners)}
        if all(mid in id_map for mid in marker_id_map):
            last_valid_src_pts = np.array([
                id_map[0][0], id_map[4][1],
                id_map[19][2], id_map[15][3]
            ], dtype=np.float32)

    # ワープ処理
    if last_valid_src_pts is not None:
        dst = np.array([
            [0, 0],
            [WARPED_WIDTH-1, 0],
            [WARPED_WIDTH-1, WARPED_HEIGHT-1],
            [0, WARPED_HEIGHT-1]
        ], dtype=np.float32)
        M = cv2.getPerspectiveTransform(last_valid_src_pts, dst)
        warped = cv2.warpPerspective(frame, M, (WARPED_WIDTH, WARPED_HEIGHT))

        # 補正後でマーカー検出
        warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
        corners_w, ids_w, _ = aruco.detectMarkers(warped_gray, aruco_dict, parameters=parameters)
        detected = [] if ids_w is None else ids_w.flatten().tolist()

        # 各ターゲット ID を処理
        for mid in target_ids:
            if mid in detected:
                idx = detected.index(mid)
                c = corners_w[idx][0].astype(np.float32)
                center = c.mean(axis=0)
                vec = c[1] - c[0]
                angle = (np.degrees(np.arctan2(vec[1], vec[0])) + 360) % 360

                last_pos[mid] = (float(center[0]), float(center[1]), float(angle))
            # 未検出時は last_pos をそのまま使う（初回検出前は無視）
            if mid in last_pos:
                x, y, a = last_pos[mid]
                # OSC 送信
                client.send_message(f"/marker/{mid}", [x, y, a])
                print(f"Sent /marker/{mid} → x={x:.1f}, y={y:.1f}, angle={a:.1f}")

        # （必要なら可視化コードをここに）

        cv2.imshow("Warped", warped)

    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
