import numpy as np
import cv2
from cv2 import aruco
import time

# マーカー情報
marker_id_map = {
    0: 'top_left',
    4: 'top_right',
    19: 'bottom_right',
    15: 'bottom_left'
}
corner_name_to_index = {
    'top_left': 0,
    'top_right': 1,
    'bottom_right': 2,
    'bottom_left': 3
}
TRACKED_IDS = [1, 2, 3]

# 状態保持
prev_id_to_corner = {}
prev_data = {i: {'tx_warped': 0, 'ty_warped': 0, 'rot': 0} for i in TRACKED_IDS}
last_detect_time = 0
detect_interval = 0.01

# キャプチャ初期化
cap = cv2.VideoCapture(0)  # カメラID 0

width, height = 1280, 720
aruco_dict = aruco.getPredefinedDictionary(aruco.DICT_6X6_250)
parameters = aruco.DetectorParameters_create()

while True:
    ret, frame = cap.read()
    if not ret:
        continue

    frame = cv2.flip(frame, 0)  # TouchDesignerと同じように上下反転

    current_time = time.time()
    run_detection = (current_time - last_detect_time) > detect_interval

    marker_corners, marker_ids = [], None
    if run_detection:
        marker_corners, marker_ids, _ = aruco.detectMarkers(frame, aruco_dict, parameters=parameters)
        last_detect_time = current_time

        current_id_to_corner = {}
        if marker_ids is not None:
            for i, marker_id in enumerate(marker_ids.flatten()):
                if marker_id in marker_id_map:
                    corner_name = marker_id_map[marker_id]
                    corner_index = corner_name_to_index[corner_name]
                    current_id_to_corner[corner_name] = marker_corners[i][0][corner_index]

            prev_id_to_corner.update(current_id_to_corner)

    if all(corner in prev_id_to_corner for corner in corner_name_to_index.keys()):
        src_pts = np.array([
            prev_id_to_corner['top_left'],
            prev_id_to_corner['top_right'],
            prev_id_to_corner['bottom_right'],
            prev_id_to_corner['bottom_left']
        ], dtype="float32")
        dst_pts = np.array([
            [0, 0],
            [width - 1, 0],
            [width - 1, height - 1],
            [0, height - 1]
        ], dtype="float32")

        M = cv2.getPerspectiveTransform(src_pts, dst_pts)
        warped = cv2.warpPerspective(frame, M, (width, height))
        warped = cv2.flip(warped, 0)

        gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
        _, binary = cv2.threshold(gray, 110, 255, cv2.THRESH_BINARY)

        # 表示
        cv2.imshow("Warped Binary", binary)

        if marker_ids is not None:
            for i, marker_id in enumerate(marker_ids.flatten()):
                if marker_id in TRACKED_IDS:
                    pts = marker_corners[i][0]
                    center = np.mean(pts, axis=0)
                    vec = pts[1] - pts[0]
                    angle = np.arctan2(-vec[1], vec[0])
                    rot = np.degrees(angle)

                    center_pt = np.array([[center]], dtype=np.float32)
                    warped_pt = cv2.perspectiveTransform(center_pt, M)[0][0]
                    tx_warped = warped_pt[0] / width
                    ty_warped = 1.0 - (warped_pt[1] / height)

                    prev_data[marker_id] = {
                        'tx_warped': tx_warped,
                        'ty_warped': ty_warped,
                        'rot': rot
                    }

    else:
        if run_detection and marker_ids is not None:
            display = aruco.drawDetectedMarkers(frame.copy(), marker_corners, marker_ids)
            display = cv2.flip(display, 0)
            cv2.imshow("Detection", display)

    # 結果表示（コンソール）
    for id_val in TRACKED_IDS:
        data = prev_data[id_val]
        print(f"ID {id_val}: tx={data['tx_warped']:.2f}, ty={data['ty_warped']:.2f}, rot={data['rot']:.2f}")

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
