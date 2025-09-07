import cv2
import mediapipe as mp
import pandas as pd
import numpy as np
import os

VIDEOS_DIR = "/Users/devid/Desktop/gym/validation_work/validation_samples"
LABELS_CSV = "labels.csv"
SUMMARY_CSV = "summary.csv"
FRAMES_CSV = "frames.csv"

GOOD_RATIO_THRESHOLD = 0.30  # was 0.50

mp_pose = mp.solutions.pose

VIEW_CONFIGS = {
    "side": {
        "back_min": 120.0,
        "depth_margin": 0.005,
        "knee_rel": 0.35,
        "usable": True
    },
    "three_quarter": {
        "back_min": 110.0,
        "depth_margin": 0.002,
        "knee_rel": 0.40,
        "usable": True
    },
    "front": {  # fallback instead of skipping
        "back_min": 110.0,
        "depth_margin": 0.002,
        "knee_rel": 0.40,
        "usable": True
    }
}

def angle(ax, ay, bx, by, cx, cy):
    bax, bay = ax - bx, ay - by
    bcx, bcy = cx - bx, cy - by
    dot = bax * bcx + bay * bcy
    mag1 = np.sqrt(bax**2 + bay**2)
    mag2 = np.sqrt(bcx**2 + bcy**2)
    denom = max(mag1 * mag2, 1e-6)
    cosv = np.clip(dot / denom, -1.0, 1.0)
    return np.degrees(np.arccos(cosv))

def classify_view(sx, rsx, ax, tx):
    foot_horiz = abs(tx - ax)
    shoulder_sep = abs(sx - rsx)
    if foot_horiz > 0.3 and shoulder_sep > 0.04:
        return "side"
    elif foot_horiz > 0.15:
        return "three_quarter"
    else:
        return "front"

def knee_over_toe_projected(kx, ky, ax, ay, tx, ty, knee_rel):
    KA = np.array([kx - ax, ky - ay])
    TA = np.array([tx - ax, ty - ay])
    ta_len = np.linalg.norm(TA) + 1e-9
    shin_len = np.linalg.norm(KA) + 1e-9
    u = TA / ta_len
    proj = float(np.dot(KA, u))
    return proj > (knee_rel * shin_len)

def process_video(video_path):
    cap = cv2.VideoCapture(video_path)
    pose = mp_pose.Pose(static_image_mode=False, model_complexity=1, enable_segmentation=False)

    frames = []
    fname = os.path.basename(video_path)

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        h, w, _ = frame.shape
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        res = pose.process(rgb)

        if not res.pose_landmarks:
            continue

        lm = res.pose_landmarks.landmark
        L = mp_pose.PoseLandmark

        LS, RS = lm[L.LEFT_SHOULDER.value], lm[L.RIGHT_SHOULDER.value]
        LH, RH = lm[L.LEFT_HIP.value], lm[L.RIGHT_HIP.value]
        LK, RK = lm[L.LEFT_KNEE.value], lm[L.RIGHT_KNEE.value]
        LA, RA = lm[L.LEFT_ANKLE.value], lm[L.RIGHT_ANKLE.value]
        LT, RT = lm[L.LEFT_FOOT_INDEX.value], lm[L.RIGHT_FOOT_INDEX.value]

        # choose side with better visibility
        left_vis = LH.visibility + LK.visibility + LA.visibility + LT.visibility
        right_vis = RH.visibility + RK.visibility + RA.visibility + RT.visibility
        use_left = left_vis >= right_vis

        if use_left:
            hx, hy = LH.x, LH.y
            kx, ky = LK.x, LK.y
            ax, ay = LA.x, LA.y
            tx, ty = LT.x, LT.y
        else:
            hx, hy = RH.x, RH.y
            kx, ky = RK.x, RK.y
            ax, ay = RA.x, RA.y
            tx, ty = RT.x, RT.y

        sx, rsx = LS.x, RS.x

        # view classification
        view = classify_view(sx, rsx, ax, tx)
        cfg = VIEW_CONFIGS.get(view, {"usable": False})

        if not cfg["usable"]:
            continue

        back_ang = angle(sx, LS.y, hx, hy, ax, ay)
        depth = hy - ky
        knee_ot = knee_over_toe_projected(kx, ky, ax, ay, tx, ty, cfg["knee_rel"])

        back_ok = back_ang >= cfg["back_min"]
        depth_ok = depth > cfg["depth_margin"]
        good = back_ok and depth_ok and not knee_ot

        frames.append({
            "video": fname,
            "view": view,
            "back_angle": back_ang,
            "depth": depth,
            "knee_ot": int(knee_ot),
            "good": int(good)
        })

    cap.release()
    return frames

def main():
    labels = pd.read_csv(LABELS_CSV)
    gt = {r.video: r.ground_truth for _, r in labels.iterrows()}
    all_frames = []

    for f in os.listdir(VIDEOS_DIR):
        if not f.endswith(".mp4"):
            continue
        frames = process_video(os.path.join(VIDEOS_DIR, f))
        all_frames.extend(frames)

    df = pd.DataFrame(all_frames)
    df.to_csv(FRAMES_CSV, index=False)

    summary = []
    for vid, group in df.groupby("video"):
        ratio = group.good.mean() if len(group) else 0.0
        verdict = "good" if ratio >= GOOD_RATIO_THRESHOLD else "bad"
        summary.append({
            "video": vid,
            "ground_truth": gt.get(vid, "?"),
            "predicted": verdict,
            "frames_evaluated": len(group),
            "good_ratio": round(ratio, 3),
            "match": int(verdict == gt.get(vid))
        })

    pd.DataFrame(summary).to_csv(SUMMARY_CSV, index=False)
    print("Wrote", SUMMARY_CSV, "and", FRAMES_CSV)


if __name__ == "__main__":
    main()