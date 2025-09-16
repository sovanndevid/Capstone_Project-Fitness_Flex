import pandas as pd, numpy as np
from itertools import product

FRAMES = "frames.csv"
LABELS = "labels.csv"
OUT_SWEEP = "sweep_per_view_results.csv"
OUT_BEST  = "best_per_view_summary.csv"

BACK_SIDE   = [135, 140, 145, 150]
DEPTH_SIDE  = [0.008, 0.010, 0.012, 0.015]
KNEE_SIDE   = [0.22, 0.25, 0.28, 0.30]

BACK_TQ     = [130, 135, 140, 145]
DEPTH_TQ    = [0.008, 0.010, 0.012]
KNEE_TQ     = [0.25, 0.28, 0.30, 0.32]

GOOD_RATIO_THRESHOLD = 0.50

def knee_over_toe_proj(row, knee_rel):
    kx, ky, ax, ay, tx, ty = row.kx, row.ky, row.ax, row.ay, row.tx, row.ty
    ka = np.array([kx-ax, ky-ay]); ta = np.array([tx-ax, ty-ay])
    ta_len = np.linalg.norm(ta) + 1e-9
    shin   = np.linalg.norm(ka) + 1e-9
    u = ta / ta_len
    proj = float(np.dot(ka, u))
    return int(proj > (knee_rel * shin))

def score_video(dfv, back_min, depth_margin, knee_rel):
    dfv = dfv.copy()
    knee = dfv.apply(lambda r: knee_over_toe_proj(r, knee_rel), axis=1)
    good = (dfv.back_angle >= back_min) & (dfv.depth > depth_margin) & (knee == 0)
    ratio = good.mean() if len(dfv) else 0.0
    return ("good" if ratio >= GOOD_RATIO_THRESHOLD else "bad", float(ratio), len(dfv))

def main():
    frames = pd.read_csv(FRAMES)
    labels = pd.read_csv(LABELS)
    gt = {r.video: str(r.ground_truth).strip().lower() for _, r in labels.iterrows()}

    # only use frames we marked usable in validator (non-front)
    frames = frames[frames.usable == 1].copy()

    rows = []
    # group frames per (video, view)
    grouped = frames.groupby(["video", "view"])

    # sweep SIDE
    for b, d, k in product(BACK_SIDE, DEPTH_SIDE, KNEE_SIDE):
        correct = 0; total = 0
        for (vid, view), dfv in grouped:
            if view != "side": continue
            pred, _, _ = score_video(dfv, b, d, k)
            if vid in gt and gt[vid] in ("good","bad"):
                total += 1; correct += int(pred == gt[vid])
        acc = (correct/total) if total else 0.0
        rows.append({"view":"side","back_min":b,"depth_margin":d,"knee_rel":k,"videos":total,"accuracy":round(acc,4)})

    # sweep THREE_QUARTER
    for b, d, k in product(BACK_TQ, DEPTH_TQ, KNEE_TQ):
        correct = 0; total = 0
        for (vid, view), dfv in grouped:
            if view != "three_quarter": continue
            pred, _, _ = score_video(dfv, b, d, k)
            if vid in gt and gt[vid] in ("good","bad"):
                total += 1; correct += int(pred == gt[vid])
        acc = (correct/total) if total else 0.0
        rows.append({"view":"three_quarter","back_min":b,"depth_margin":d,"knee_rel":k,"videos":total,"accuracy":round(acc,4)})

    sweep = pd.DataFrame(rows)
    sweep.to_csv(OUT_SWEEP, index=False)
    print("Top configs per view:")
    print(sweep.sort_values(["view","accuracy","back_min"], ascending=[True,False,True]).groupby("view").head(5).to_string(index=False))

    # pick best per view
    best_side = sweep[sweep.view=="side"].sort_values(["accuracy","back_min"], ascending=[False,True]).head(1)
    best_tq   = sweep[sweep.view=="three_quarter"].sort_values(["accuracy","back_min"], ascending=[False,True]).head(1)

    # summarize per video using the chosen per-view configs
    side_cfg = None if best_side.empty else best_side.iloc[0][["back_min","depth_margin","knee_rel"]].to_dict()
    tq_cfg   = None if best_tq.empty else   best_tq.iloc[0][["back_min","depth_margin","knee_rel"]].to_dict()

    per = []
    for vid, dfv in frames.groupby("video"):
        # video-level decision: apply per-view rules to each frame based on its view
        votes = []; nscored = 0
        for _, r in dfv.iterrows():
            if r.view == "side" and side_cfg:
                pred, _, _ = score_video(pd.DataFrame([r]), side_cfg["back_min"], side_cfg["depth_margin"], side_cfg["knee_rel"])
            elif r.view == "three_quarter" and tq_cfg:
                pred, _, _ = score_video(pd.DataFrame([r]), tq_cfg["back_min"], tq_cfg["depth_margin"], tq_cfg["knee_rel"])
            else:
                continue
            nscored += 1
            votes.append(1 if pred=="good" else 0)

        ratio = (sum(votes)/nscored) if nscored else 0.0
        verdict = "good" if ratio >= 0.5 else "bad"
        per.append({"video":vid, "ground_truth": gt.get(vid,"unknown"), "predicted":verdict, "frames_evaluated": nscored, "good_ratio": round(ratio,3), "match": int(gt.get(vid,"?")==verdict)})

    pd.DataFrame(per).to_csv(OUT_BEST, index=False)
    print("\nWrote:", OUT_SWEEP, "and", OUT_BEST)

if __name__ == "__main__":
    main()