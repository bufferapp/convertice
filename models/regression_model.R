# load libraries
library(readr)
library(dplyr)
library(ROCR)

# read data from csvs
training <- read_csv("~/Downloads/training_data.csv")
testing <- read_csv("~/Downloads/validation_data.csv")


# create profile cuts cuts
profile_buckets = c(-Inf, 0, 1, 3, 7, 10, 20, 50, 100, Inf)

# create post buckets
post_buckets <- c(-Inf, 0, 5, 10, 50, 100, 500, Inf)

# add new columns for bucketed features
training <- training %>% 
  mutate(profile_bucket = cut(profiles, profile_buckets),
         post_bucket = cut(posts, post_buckets))

testing <- testing %>% 
  mutate(profile_bucket = cut(profiles, profile_buckets),
         post_bucket = cut(posts, post_buckets))

# fit logistic regression model
glm_fit <- glm(converted ~ trial_type + plan_interval + trial_length + 
                 days_with_posts + has_payment_method + trial_start_weekday + 
                 started_at_signup + profile_bucket + post_bucket,
               data = training, family = "binomial")

# make predictions on testing set
preds <- predict(glm_fit, newdata = testing, type = "response")

# add predictions
testing <- testing %>% 
  mutate(pred = preds)

# evaluate predictions
eval <- prediction(testing$pred, testing$converted) 

# calculate AUC
print(attributes(performance(eval,'auc'))$y.values[[1]])
