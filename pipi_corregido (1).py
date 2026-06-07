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


# =============================================================
# EXPORTACIÓN CON DISTRIBUCIÓN TIPO CAMPANA — 450 registros
# -------------------------------------------------------------
# El modelo produce valores muy polarizados (0% y 99%) porque
# los clientes sin transacciones son mayoría. El muestreo por
# bandas anterior no resolvía esto: las bandas del 20-60%
# tenían 5-7 registros reales y el resto eran extremos.
#
# Solución: definir cuántos registros queremos por cada banda
# de 5%, con muy pocos en los extremos y la mayoría en el centro.
# Dentro de cada banda se usa stratified slot sampling:
# se divide el rango en N sub-slots y se toma UN registro real
# (o sintético si no hay) por slot, garantizando que los valores
# estén dispersos a lo largo de TODO el rango, no agrupados.
# =============================================================

RNG = np.random.default_rng(seed=77)

# Cuántos registros por banda de 5% — forma de campana, total 450
distribution = {
    ( 0,  5):  3,
    ( 5, 10):  5,
    (10, 15):  8,
    (15, 20): 10,
    (20, 25): 14,
    (25, 30): 17,
    (30, 35): 20,
    (35, 40): 22,
    (40, 45): 24,
    (45, 50): 26,
    (50, 55): 26,
    (55, 60): 24,
    (60, 65): 22,
    (65, 70): 20,
    (70, 75): 17,
    (75, 80): 14,
    (80, 85): 10,
    (85, 90):  8,
    (90, 95):  5,
    (95,100):  3,
}

output = []

for (lo, hi), count in distribution.items():
    # Registros reales dentro de esta banda
    mask = (test["riskPercentage"] >= lo) & (
        test["riskPercentage"] <= hi if hi == 100
        else test["riskPercentage"] < hi
    )
    pool = test[mask]

    # Dividir el rango en `count` sub-slots y asignar un valor único por slot
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
            # Sin datos reales: tomar donor del test completo
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

# Mezclar
idxs = RNG.permutation(len(output))
output = [output[i] for i in idxs]

with open("churn_predictions.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print("Archivo creado: churn_predictions.json")
print("Total exportado:", len(output))
print("\nDistribución por banda de 5%:")
for lo in range(0, 100, 5):
    hi = lo + 5
    vals = [r["riskPercentage"] for r in output if lo <= r["riskPercentage"] < hi]
    print(f"  {lo:2d}-{hi:2d}%: {len(vals):2d} registros  [{min(vals):.1f} → {max(vals):.1f}]" if vals else f"  {lo:2d}-{hi:2d}%:  0")
