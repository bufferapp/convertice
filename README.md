# Convertice

This repository contains code and resources for a Trial Conversion Forecasting Model. The goal is to accurately predict how likely an user is to convert after 5 days in a trial.

## Defining the Problem

A **trial conversion** means the user has made a payment within 30 days of the trial start event. The payment has to be for a new subscription or a new plan on an existing subscription. We're trying to predict the probability of a trial converting for users that have been on a trial for at least 5 days.

### Modeling

We've experimented with [different models](/models) to explore the different approaches. To evaluate these models we use the area under the receiver operating characteristic curve (also called [AUC - ROC Curve](https://towardsdatascience.com/understanding-auc-roc-curve-68b2303cc9c5)).

Right now, we're using [Google AutoML Tables](https://cloud.google.com/automl-tables/) to do both training and batch predictions.

### Inputs and Outputs

To train the model we use several features. These are modeled the in `buffer-dbt` project. We'll use `dbt` to version the input dataset. The model can read that table and write predictions into another. This way it can be swaped without affecting the rest of the pipeline.

The final goal is to send the probability of converting to Segment as a new event.
