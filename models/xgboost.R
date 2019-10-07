# load libraries
library(xgboost)
library(dplyr)
library(readr)
library(caret)
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
         post_bucket = cut(posts, post_buckets)) %>% 
  select(-id, -trial_start_at)

testing <- testing %>% 
  mutate(profile_bucket = cut(profiles, profile_buckets),
         post_bucket = cut(posts, post_buckets)) %>% 
  select(-id, -trial_start_at)

# create dummy variables
train_dummy <- dummyVars("~ .-converted", data = training)
train_matrix <- as.matrix(predict(train_dummy, newdata = training))

# create testing set
test_dummy <- dummyVars("~ .-converted", data = testing)
test_matrix <- as.matrix(predict(test_dummy, newdata = testing))

# create output vector
output_vector = training[, "converted"] == TRUE

# gradient boosting with cross validation
xgb_fit <- xgb.cv(
  data = train_matrix,
  label = output_vector,
  nrounds = 1000,
  nfold = 5,
  objective = "binary:logistic",
  early_stopping_rounds = 10
)

# gradient boosting with cross validation
xgb_fit <- xgboost(
  data = train_matrix,
  label = output_vector,
  nrounds = 34,
  objective = "binary:logistic"
)

# create importance matrix
importance_matrix <- xgb.importance(model = xgb_fit)

# variable importance plot
xgb.plot.importance(importance_matrix, top_n = 10, measure = "Gain")

# plot error vs number of trees
ggplot(xgb_fit$evaluation_log) +
  geom_line(aes(iter, train_error_mean), color = "red") +
  geom_line(aes(iter, test_error_mean), color = "blue")

# predict values in test set
y_pred <- predict(xgb_fit, test_matrix)

# add predictions
testing <- testing %>% 
  mutate(pred = y_pred)

# evaluate predictions
eval <- prediction(testing$pred, testing$converted)

# calculate AUC
print(attributes(performance(eval,'auc'))$y.values[[1]])

# hyperparameter grid
hyper_grid <- expand.grid(
  eta = c(.01, .05, .1, .3),
  max_depth = c(1, 3, 5, 7),
  min_child_weight = c(1, 3, 5, 7),
  subsample = c(.65, .8, 1), 
  colsample_bytree = c(.8, .9, 1),
  optimal_trees = 0,               
  min_error = 0                     
)

# grid search 
for(i in 1:nrow(hyper_grid)) {
  
  # create parameter list
  params <- list(
    eta = hyper_grid$eta[i],
    max_depth = hyper_grid$max_depth[i],
    min_child_weight = hyper_grid$min_child_weight[i],
    subsample = hyper_grid$subsample[i],
    colsample_bytree = hyper_grid$colsample_bytree[i]
  )
  
  # reproducibility
  set.seed(123)
  
  # train model
  xgb.tune <- xgb.cv(
    params = params,
    data = train_matrix,
    label = output_vector,
    nrounds = 5000,
    nfold = 5,
    objective = "binary:logistic", 
    early_stopping_rounds = 10
  )
  
  # add min training error and trees to grid
  hyper_grid$optimal_trees[i] <- which.min(xgb.tune$evaluation_log$test_error_mean)
  hyper_grid$min_error[i] <- min(xgb.tune$evaluation_log$test_error_mean)
}

hyper_grid %>%
  dplyr::arrange(min_error) %>%
  head(10)
