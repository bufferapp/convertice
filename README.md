# Convertice

This repository contains code and resources for a Trial Conversion Forecasting Model. The goal of the model is to accurately predict how likely to convert is an user that finished their trial.

## Defining the Problem

A **trial conversion** means the user has made a payment within 30 days of the trial start event. The payment has to be for a new subscription or a new plan on an existing subscription. We're trying to predict the probability of a trial converting for users that have been on a trial for at least 5 days.b

### Model Evaluation

To evaluate the model we use the area under the receiver operating characteristic curve (also called [AUC - ROC Curve](https://towardsdatascience.com/understanding-auc-roc-curve-68b2303cc9c5)).

### Inputs and Outputs

To train the model we use several features. These are modeled the in `buffer-dbt` project.

At prediction time we use a view...

The results of the model are saved to another table. We can then use that table to send the predictions to Mixpanel.
