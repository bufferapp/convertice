# load libraries
library(dplyr)
library(tidyr)
library(readr)
library(randomForest)
library(ROCR)

# read data from csvs
training <- read_csv("~/Downloads/training_data.csv")
testing <- read_csv("~/Downloads/validation_data.csv")

# replace NA and convert label to factor
training <- training %>% 
  replace_na(list(trial_type = "Unknown")) %>% 
  mutate(converted = as.factor(converted),
         plan_interval = as.factor(plan_interval),
         trial_type = as.factor(trial_type),
         trial_length = as.factor(trial_length),
         trial_start_weekday = as.factor(trial_start_weekday),
         started_at_signup = as.factor(started_at_signup))

testing <- testing %>% 
  replace_na(list(trial_type = "Unknown")) %>% 
  mutate(converted = as.factor(converted),
         plan_interval = as.factor(plan_interval),
         trial_type = as.factor(trial_type),
         trial_length = as.factor(trial_length),
         trial_start_weekday = as.factor(trial_start_weekday),
         started_at_signup = as.factor(started_at_signup))


# set seed for reproducibility
set.seed(88)

# grow random forest
rf_mod <- randomForest(converted ~ trial_type + trial_length +
                     profiles + posts + days_with_posts + has_payment_method +
                     trial_start_weekday + started_at_signup, 
                   data = training,
                   importance = TRUE)

# view importance
importance(rf_mod)
varImpPlot(rf_mod)

# make predictions on testing set
preds <- predict(rf_mod, newdata = testing, type = "prob")

# add predictions
testing <- testing %>% 
  mutate(pred = preds[, 2])

# evaluate predictions
eval <- prediction(testing$pred, testing$converted)

# calculate AUC
print(attributes(performance(eval,'auc'))$y.values[[1]])
