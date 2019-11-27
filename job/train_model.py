from google.cloud import automl_v1beta1
from google.oauth2 import service_account

automl_client = automl_v1beta1.TablesClient(project="buffer-data", region="us-central1")

m = automl_client.create_model(
    "trial_prediction_model_v6",
    dataset_display_name="trial_prediction_v5",
    train_budget_milli_node_hours=1000,
    optimization_objective="MAXIMIZE_AU_PRC",
)

m.result()
