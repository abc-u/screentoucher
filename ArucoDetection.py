import cv2
import numpy as np
from cv2 import aruco

# --- ArUco 辞書と検出パラメータの設定 ---
aruco_dict = aruco.getPredefinedDictionary(aruco.DICT_6X6_250)
parameters = aruco.DetectorParameters_create()
parameters.adaptiveThreshWinSizeMin = 3
parameters.adaptiveThreshWinSizeMax = 23
parameters.adaptiveThreshConstant = 7
parameters.cornerRefinementMethod = aruco.CORNER_REFINE_SUBPIX

# 四隅マーカー用 ID マップ
marker_id_map = {0:'top_left', 4:'top_right', 19:'bottom_right', 15:'bottom_left'}

# ワープ後画像サイズ
WARPED_WIDTH, WARPED_HEIGHT = 1600, 900

# カメラ初期化
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
if not cap.isOpened():
    print("カメラが開けませんでした")
    exit()
print("カメラ起動成功")

last_valid_src_pts = None

# ID=1,2 の最後の中心座標と角度を保存する辞書
# 例: last_pos[1] = {'center': np.array([x,y]), 'angle': 123.4}
last_pos = {}

# 可視化用色設定
colors = {1: (0,255,0), 2: (255,0,0)}  # 1: 緑, 2: 青

while True:
    ret, frame = cap.read()
    if not ret:
        print("フレーム取得失敗")
        continue

    # 元フレームをグレースケール検出用に変換
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    display = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

    # 元画像上でマーカー検出（四隅用）
    corners, ids, _ = aruco.detectMarkers(gray, aruco_dict, parameters=parameters)
    if ids is not None:
        aruco.drawDetectedMarkers(display, corners, ids)
        id_corner_map = {int(i[0]): c[0] for i, c in zip(ids, corners)}
        if all(mid in id_corner_map for mid in marker_id_map):
            last_valid_src_pts = np.array([
                id_corner_map[0][0],
                id_corner_map[4][1],
                id_corner_map[19][2],
                id_corner_map[15][3]
            ], dtype=np.float32)

    # ワープ処理
    if last_valid_src_pts is not None:
        dst = np.array([
            [0, 0],
            [WARPED_WIDTH - 1, 0],
            [WARPED_WIDTH - 1, WARPED_HEIGHT - 1],
            [0, WARPED_HEIGHT - 1]
        ], dtype=np.float32)
        M = cv2.getPerspectiveTransform(last_valid_src_pts, dst)
        warped = cv2.warpPerspective(frame, M, (WARPED_WIDTH, WARPED_HEIGHT))

        # 補正後画像でマーカー検出（1,2用）
        warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
        corners_w, ids_w, _ = aruco.detectMarkers(warped_gray, aruco_dict, parameters=parameters)
        detected_ids = [] if ids_w is None else ids_w.flatten().tolist()

        # 検出マーカーを可視化
        if ids_w is not None:
            aruco.drawDetectedMarkers(warped, corners_w, ids_w)

        # 1,2 を順に処理
        for mid in (1, 2):
            if mid in detected_ids:
                # マーカー検出できたら中心と角度を再計算・保存
                idx = detected_ids.index(mid)
                c = corners_w[idx][0].astype(np.float32)
                center = c.mean(axis=0)
                vec = c[1] - c[0]
                angle = (np.degrees(np.arctan2(vec[1], vec[0])) + 360) % 360

                # 保存
                last_pos[mid] = {'center': center, 'angle': angle}
                print(f"→ ID={mid} current center: ({center[0]:.1f}, {center[1]:.1f}), angle: {angle:.1f}°")
            else:
                # 未検出なら最後の値を出力
                if mid in last_pos:
                    center = last_pos[mid]['center']
                    angle = last_pos[mid]['angle']
                    print(f"→ ID={mid} not detected, using last center: ({center[0]:.1f}, {center[1]:.1f}), angle: {angle:.1f}°")
                else:
                    print(f"→ ID={mid} has no previous data yet")
                    continue

            # 可視化：中心、矢印、テキスト
            color = colors[mid]
            cv2.circle(warped, tuple(center.astype(int)), 6, color, -1)
            # 矢印方向は角度から再計算
            rad = np.radians(angle)
            tip = (center + 50 * np.array([np.cos(rad), np.sin(rad)])).astype(int)
            cv2.arrowedLine(warped,
                            tuple(center.astype(int)),
                            tuple(tip),
                            color, 2, tipLength=0.2)
            cv2.putText(warped,
                        f"ID{mid}: {angle:.1f}°",
                        (int(center[0]) + 10, int(center[1]) - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)

        cv2.imshow("Warped", warped)
    else:
        cv2.putText(display,
                    "四隅マーカーをすべて検出してください",
                    (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    # 元画像と検出マーカーの表示
    cv2.imshow("Original + Markers", display)

    if cv2.waitKey(10) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
