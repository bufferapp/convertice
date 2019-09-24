# Convertice

This repository contains code and resources for a Trial Conversion Forecasting Model. The goal of the model is to accurately predict how likely to convert is an user that finished their trial.


## Defining the Problem

We define a trial conversion as...

### Model Evaluation

To evaluate the model we use the area under the receiver operating characteristic curve (also called [AUC - ROC Curve](https://towardsdatascience.com/understanding-auc-roc-curve-68b2303cc9c5)).

### Inputs and Outputs

To train the model we use several features. These are modeled the in `buffer-dbt` project.

At prediction time we use a view...

The results of the model are saved to another table. We can then use that table to send the predictions to Mixpanel.
