# load libraries
library(buffer)
library(dplyr)
library(tidyr)
library(lubridate)
library(bigrquery)
library(DBI)
library(forcats)


# Labels ------------------------------------------------------------------


# connect to bigquery
con <- dbConnect(
  bigrquery::bigquery(),
  project = "buffer-data",
  dataset = "dbt_buffer"
)

# define sql query
sql <- "
  select distinct
    *
    , date_diff(date(trial_end_at), date(trial_start_at), day) as trial_length
  from stripe_trials
  where product = 'publish'
  and trial_start_at between '2018-01-01' and '2019-09-01'
"

# collect data
trials <- dbGetQuery(con, sql)

# set dates
trials <- trials %>% 
  mutate(trial_start_at = as.Date(trial_start_at),
         trial_end_at = as.Date(trial_end_at))


# Features ----------------------------------------------------------------

# connect to bigquery
con <- dbConnect(
  bigrquery::bigquery(),
  project = "buffer-data",
  dataset = "dbt_buffer"
)

# define sql query
sql <- "
  with trials as (
    select distinct
      t.metadata_user_id as user_id
      , t.customer_id
      , t.id as trial_id
      , t.trial_start_at
      , t.trial_end_at
      , date_diff(date(t.trial_end_at), date(t.trial_start_at), day) as trial_length
    from dbt_buffer.stripe_trials t
    where t.trial_start_at between '2018-01-01' and '2019-09-01'
    and t.product = 'publish'
  )

  select 
    t.user_id
    , t.customer_id
    , u.created_at
    , date_diff(date(t.trial_start_at), date(u.created_at), day) as account_age
    , t.trial_id
    , t.trial_start_at
    , t.trial_end_at
    , count(distinct e.id) as payment_methods_added
    , count(distinct p.service_id) as profiles
    , count(distinct up.id) as posts
    , count(distinct date(up.created_at)) as days_with_posts
  from trials t
  left join dbt_buffer.publish_users u
    on t.user_id = u.id
  left join dbt_buffer.publish_profiles p
    on p.user_id = t.user_id
    and date(p.created_at) between date(t.trial_start_at) and date_add(date(t.trial_start_at), interval 5 day)
  left join dbt_buffer.publish_updates as up
    on up.profile_id = p.id
    and up.created_at > t.trial_start_at
    and date(up.created_at) between date(t.trial_start_at) and  date_add(date(t.trial_start_at), interval 5 day)
  left join dbt_buffer.stripe_payment_method_attached_events as e
    on t.customer_id = e.customer_id
    and date(e.created_at) <= date_add(date(t.trial_start_at), interval 5 day)
  group by 1,2,3,4,5,6,7
"

# collect data
features <- dbGetQuery(con, sql)


# Tidying -----------------------------------------------------------------


# remove unneeded fields
features <- features %>% 
  select(trial_id, user_id, created_at, account_age, payment_methods_added:days_with_posts)

# join datasets
trial_features <- trials %>% 
  left_join(features, by = c("id" = "trial_id")) %>% 
  filter(!is.na(user_id) & !is.na(created_at)) %>% 
  rename(signup_at = created_at)

# set trial length as factor and lump uncommon levels
trial_features <- trial_features %>% 
  mutate(trial_length = as.factor(trial_length),
         trial_length = fct_lump(trial_length, n = 5, other_level = "Other"))

# determine if payment method was added
trial_features <- trial_features %>% 
  mutate(has_payment_method = payment_methods_added >= 1)

# get day if week
trial_features <- trial_features %>% 
  mutate(trial_start_weekday = wday(trial_start_at, label = TRUE),
         started_at_signup = account_age == 0)


# select features for training
features_select <- trial_features %>% 
  select(id, trial_start_at, trial_type, plan_interval, converted, trial_length,
         profiles:started_at_signup) %>% 
  mutate(trial_type = as.factor(trial_type),
         plan_interval = as.factor(plan_interval))


# Data Partitioning -------------------------------------------------------


# set seed for reproducibility
set.seed(8)

# create partitions
# train_index <- createDataPartition(trial_features$converted, p = .75, list = FALSE, times = 1)
training <- features_select %>% filter(trial_start_at < "2019-08-01")
testing  <- features_select %>% filter(trial_start_at >= "2019-08-01")

# compare conversions for all datasets
features_select %>% 
  count(converted) %>% 
  mutate(percent = n / sum(n))

training %>% 
  count(converted) %>% 
  mutate(percent = n / sum(n))

testing %>% 
  count(converted) %>% 
  mutate(percent = n / sum(n))

# write csvs
write.csv(training, file = "~/Downloads/training_data.csv", row.names = FALSE)
write.csv(testing, file = "~/Downloads/validation_data.csv", row.names = FALSE)

