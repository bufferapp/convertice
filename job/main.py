import os
import analytics
import pandas as pd
from analytics import Client
from google.cloud import automl_v1beta1
import stacklogging

logger = stacklogging.getLogger(__name__)

MODEL_NAME = "trial_prediction_model"
MODEL_VERSION = "v5"

segment_client = Client(os.getenv("SEGMENT_WRITE_KEY"), max_queue_size=100000)
automl_client = automl_v1beta1.TablesClient(project="buffer-data", region="us-central1")

# Run the batch predict
logger.info("Running AutoML Batch predict")

operation = automl_client.batch_predict(
    bigquery_input_uri="bq://buffer-data.dbt_buffer.predict_publish_trial_conversion_holdout",
    gcs_output_uri_prefix="gs://automl-predictions/",
    model_display_name=f"{MODEL_NAME}_{MODEL_VERSION}",
)

operation.result()
logger.info("AutoML Batch prediction finished")

predicted_at = str(pd.Timestamp.now())

gcs_directory = (
    operation.metadata.batch_predict_details.output_info.gcs_output_directory
)

# Load dataframe in memory

logger.info("Reading data from GCS")
df = pd.read_csv(f"{gcs_directory}/tables_1.csv")
logger.info(f"Loaded {df.shape[0]} rows")

# Remove rows with empty account IDs
logger.info(f"Removing {df['account_id'].isna().sum()} rows with no account_id")
clean_df = df[~df["account_id"].isna()]

# Generate the proper schema and send it to Segment
logger.info("Sending data to Segment")
for index, row in clean_df.iterrows():

    properties = {
        "product": row["product"],
        "productUserId": row["user_id"],
        "subscriptionId": row["subscription_id"],
        "trialId": row["trial_id"],
        "planId": row["plan_id"],
        "modelName": MODEL_NAME,
        "modelVersion": MODEL_VERSION,
        "predictedAt": predicted_at,
        "score": row["converted_true_score"],
    }

    segment_client.track(row["account_id"], "Trial Conversion Predicted", properties)

# Flush before finishing the script
logger.info("Flushing queue")
segment_client.flush()
