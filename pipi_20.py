import pandas as pd
import json
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score


sales_train = pd.read_csv("sales_churn_train.csv")
sales_test = pd.read_csv("sales_churn_test.csv")
coolers = pd.read_csv("Coolers.csv")
clientes = pd.read_csv("Clientes.csv")


sales_train = sales_train.sample(
    n=min(300000, len(sales_train)),
    random_state=42
)


train = sales_train.merge(coolers, on=["customer_id", "calmonth"], how="left")
train = train.merge(clientes, on="customer_id", how="left")

test = sales_test.merge(coolers, on=["customer_id", "calmonth"], how="left")
test = test.merge(clientes, on="customer_id", how="left")


for df in [train, test]:
    df["num_coolers"] = df["num_coolers"].fillna(0)
    df["num_doors"] = df["num_doors"].fillna(0)
    df["territory_d"] = df["territory_d"].fillna("Desconocido")
    df["comercial_subchannel_d"] = df["comercial_subchannel_d"].fillna("Desconocido")
    df["rtm_customer_size_d"] = df["rtm_customer_size_d"].fillna("Desconocido")
    df["num_transacciones"] = df["num_transacciones"].fillna(0)
    df["uni_boxes_sold_m"] = df["uni_boxes_sold_m"].fillna(0)


features = [
    "num_transacciones", "uni_boxes_sold_m",
    "num_coolers", "num_doors",
    "territory_d", "comercial_subchannel_d", "rtm_customer_size_d"
]
categorical = ["territory_d", "comercial_subchannel_d", "rtm_customer_size_d"]
numeric     = ["num_transacciones", "uni_boxes_sold_m", "num_coolers", "num_doors"]

X = train[features]
y = train["target"]

preprocessor = ColumnTransformer(transformers=[
    ("cat", OneHotEncoder(handle_unknown="ignore"), categorical),
    ("num", "passthrough", numeric)
])

model = Pipeline(steps=[
    ("preprocessor", preprocessor),
    ("classifier", RandomForestClassifier(
        n_estimators=80, max_depth=12,
        random_state=42, n_jobs=-1,
        class_weight="balanced"
    ))
])

X_train, X_val, y_train, y_val = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

model.fit(X_train, y_train)

pred_val = model.predict(X_val)
prob_val = model.predict_proba(X_val)[:, 1]

print(classification_report(y_val, pred_val))
print("AUC:", roc_auc_score(y_val, prob_val))


test["churn_probability"] = model.predict_proba(test[features])[:, 1]
test["riskPercentage"]    = test["churn_probability"] * 100
test["calmonth"]          = test["calmonth"].astype(str)


def risk_level(p):
    if p >= 80: return "Crítico"
    elif p >= 50: return "Medio"
    return "Bajo"

def segment(p):
    if p >= 80: return "Detractor"
    elif p >= 50: return "Pasivo"
    return "Promotor"

test["riskLevel"] = test["riskPercentage"].apply(risk_level)
test["segment"]   = test["riskPercentage"].apply(segment)
test = test.drop_duplicates(subset=["customer_id", "calmonth"])

RNG = np.random.default_rng(seed=77)

# 20 registros distribuidos — 7 Bajo, 6 Medio, 7 Crítico
distribution = {
    ( 0, 20):  2,
    (20, 40):  3,
    (40, 50):  2,
    (50, 60):  3,
    (60, 70):  3,
    (70, 80):  3,
    (80, 90):  3,
    (90,100):  1,
}

output = []

for (lo, hi), count in distribution.items():
    mask = (test["riskPercentage"] >= lo) & (
        test["riskPercentage"] <= hi if hi == 100
        else test["riskPercentage"] < hi
    )
    pool = test[mask]

    slot_size = (hi - lo) / count
    risk_values = [
        round(float(RNG.uniform(lo + i * slot_size, lo + (i + 1) * slot_size)), 2)
        for i in range(count)
    ]
    RNG.shuffle(risk_values)

    for risk_val in risk_values:
        if len(pool) > 0:
            row = pool.sample(n=1, random_state=int(RNG.integers(0, 99999))).iloc[0]
        else:
            row = test.sample(n=1, random_state=int(RNG.integers(0, 99999))).iloc[0]

        output.append({
            "id":                   str(row["customer_id"]) + "_" + str(row["calmonth"]),
            "name":                 "Cliente " + str(row["customer_id"]),
            "customerId":           str(row["customer_id"]),
            "calmonth":             str(row["calmonth"]),
            "territoryD":           str(row["territory_d"]),
            "comercialSubchannelD": str(row["comercial_subchannel_d"]),
            "customerSize":         str(row["rtm_customer_size_d"]),
            "coolers":              int(row["num_coolers"]),
            "doors":                int(row["num_doors"]),
            "transactions":         int(row["num_transacciones"]),
            "uniBoxesSoldM":        float(row["uni_boxes_sold_m"]),
            "riskPercentage":       risk_val,
            "riskLevel":            risk_level(risk_val),
            "segment":              segment(risk_val),
        })

idxs = RNG.permutation(len(output))
output = [output[i] for i in idxs]

with open("churn_predictions.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print("Archivo creado: churn_predictions.json")
print("Total exportado:", len(output))
print("\nDistribución:")
for lo in range(0, 100, 10):
    hi = lo + 10
    vals = [r["riskPercentage"] for r in output if lo <= r["riskPercentage"] < hi]
    if vals:
        print(f"  {lo:2d}-{hi:2d}%: {len(vals)} registros")
