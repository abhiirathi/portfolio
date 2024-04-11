# Problem Statement
# Identifying and Mitigating Factors Contributing to Elevated Customer Churn Rates

# The analysis has revealed a critical challenge facing our bank: a higher churn rate 
# in certain segments, particularly pronounced among customers with positive balances
# (approx 20% churn rate) as opposed to those with zero balance (only 6% churn rate). 
# This disparity indicates potential shortcomings in the bank’s service offerings and suggests 
# that customers with positive balances may perceive a lack of value or inadequate service relative
# to the financial assets they hold with the bank, prompting them to seek alternative banks that
# offer better benefits for their needs.
# Additionally, the geographical variation in churn, with a notable increase in Germany (32%) 
# compared to just approx 6% in France and Spain, suggests the need for a region-specific 
# approach to customer retention. The imperative now is for the bank to conduct 
# a thorough review of its customer service strategy, address the drivers of customer turnover, 
# and implement targeted interventions. The strategic focus must be on enhancing the customer 
# experience and loyalty to safeguard the bank's market position and ensure long-term profitability.

# Installing the required packages
install.packages("dplyr")
install.packages("caTools")
install.packages("caret")
install.packages("tidyr")
install.packages("patchwork")
install.packages("class")
install.packages("cowplot")

# Loading the packages
library(dplyr)
library(caTools)
library(caret)
library(tidyr)
library(patchwork)
library(class)
library(cowplot)

# Setting the working directory
setwd("/Users/abhishekrathi/Desktop/MBAN/R programming/Bank Churn")

# Loading the BankChurnDataset
df.train <- read.csv('BankChurnDataset.csv')
head(df.train)
str(df.train) 

#Checking missing values
any(is.na(df.train))

# Yes, our data contains missing values and needs to be cleaned.

missing_value_rows <- which(rowSums(is.na(df.train)) > 0)
missing_value_rows

# 9 rows have some missing value in one of their column. 

# Displaying the rows with missing values
df.train[missing_value_rows, ]

# Only Age and Estimated Salary column contain missing values. 

# Using select() from dplyr to remove the unwanted columns
df.train <- select(df.train, -id, -CustomerId, -Surname)
head(df.train)
str(df.train)

# Missing values

# Calculate the mean and median age for each gender
age_stats <- df.train %>%
  group_by(Gender) %>%
  summarize(
    mean_age = ceiling(mean(Age, na.rm = TRUE)), # Using ceiling to round up
    median_age = median(Age, na.rm = TRUE)
  )
age_stats

# Rounding up the mean_age in the above case, as the mean_age was coming to be 
# Male (37.6) and Female (38.8) and in our dataset we only have integer values for Age.

# The mean and median ages are fairly close to each other.
# When the mean and median are similar, it suggests that the data is approximately 
# symmetrically distributed, and thus the mean can be a suitable measure for imputation.
# In this case, the mean serves as a reliable measure of central tendency, accurately 
# reflecting the average condition of the dataset. It captures the overall trend and is 
# sensitive to the values of all data points, making it highly relevant for analyzing 
# broad patterns and changes over time.

# Impute missing Age values with mean values for Male
df.train$Age[is.na(df.train$Age) & df.train$Gender == 'Male'] <- 38

# Impute missing Age values with mean values for Female
df.train$Age[is.na(df.train$Age) & df.train$Gender == 'Female'] <- 39

# Calculate the mean EstimatedSalary for each geography
salary_stats <- df.train %>%
  group_by(Geography) %>%
  summarize(mean_salary = round(mean(EstimatedSalary, na.rm = TRUE), 0)) # Round to 0 decimal places
salary_stats

# As, we only have missing values for Geography - France. We will impute it with the mean
# EstimatedSalary for France. 

df.train$EstimatedSalary[is.na(df.train$EstimatedSalary) & df.train$Geography == "France"] <- 112485

# Using geography-specific mean salaries to impute missing values for EstimatedSalary
# maintains the dataset's accuracy and coherence, reflecting realistic economic 
# variations across regions.

# Checking missing values now after we have done the imputation for age and EstimatedSalary.
any(is.na(df.train))

# No, missing values remain now in the dataset

# Data type conversions
str(df.train)

# Convert Geography to factor to properly handle categorical data in analysis and modeling
df.train$Geography <- as.factor(df.train$Geography)

# Convert Gender to factor for accurate representation of categorical gender data
df.train$Gender <- as.factor(df.train$Gender)

# Convert HasCrCard to logical to simplify binary (yes/no) representation
df.train$HasCrCard <- as.logical(df.train$HasCrCard)

# Convert IsActiveMember to logical for clear binary (active/inactive) interpretation
df.train$IsActiveMember <- as.logical(df.train$IsActiveMember)

# Convert Exited to factor as it's a categorical target variable(Yes/No) for classification
df.train$Exited <- as.factor(df.train$Exited)

# Convert Age to integer as age is represented as whole numbers in the dataset
df.train$Age <- as.integer(df.train$Age)

str(df.train)

# --- Logistic Regression ---
# Set seed for reproducibility across all devices
set.seed(101)

# Splitting the dataset into training and testing sets
split = sample.split(df.train$Exited, SplitRatio = 0.70)
final.train = subset(df.train, split == TRUE)
final.test = subset(df.train, split == FALSE)

# Training the logistic regression model on the training set
final.log.model <- glm(formula = Exited ~ . , family = binomial(link='logit'), data = final.train)
summary(final.log.model)

# Predicting on the test set
fitted.probabilities <- predict(final.log.model, newdata = final.test, type = 'response')
fitted.results <- ifelse(fitted.probabilities > 0.5, 1, 0)

# Calculating prediction accuracy
misClasificError <- mean(fitted.results != final.test$Exited)
Accuracy_Logistic_Regression <- round(1 - misClasificError,2)
Accuracy_Logistic_Regression

# Accuracy (0.83): This value indicates that the model correctly predicts whether a 
# customer will churn or not 83% of the time. A high accuracy is generally desirable, 
# showing that the model is effective in classifying the customers and could be used for
# business strategies aimed at customer retention.

# Creating a confusion matrix
confusionMatrix <- table(final.test$Exited, fitted.results)
confusionMatrix

# Logistic Regression Confusion Matrix Data
logistic_confusionMatrix <- data.frame(
  Predicted = rep(c('False', 'True'), times = 2),
  Actual = rep(c('False', 'True'), each = 2),
  Freq = c(37285, 1749, 6457, 4019)) # TN, FP, FN, TP

# Converting to factors 
logistic_confusionMatrix$Predicted <- factor(logistic_confusionMatrix$Predicted, levels = c('False', 'True'))
logistic_confusionMatrix$Actual <- factor(logistic_confusionMatrix$Actual, levels = c('False', 'True'))

# Plot the confusion matrix 
ggplot(logistic_confusionMatrix, aes(x = Actual, y = Predicted, fill = Freq)) +
  geom_tile(color = "white") +  
  geom_text(aes(label = Freq), vjust = 1) +  
  scale_fill_gradient(low = "skyblue", high = "orange") + 
  labs(title = "Confusion Matrix", x = "Actual", y = "Predicted") + 
  theme_minimal() +  
  theme(axis.text = element_text(size = 12),  
        axis.title = element_text(size = 14), 
        title = element_text(size = 14, face = "bold"),
        plot.title = element_text(hjust = 0.5)) #Center aligning the plot title 

# Calculating Sensitivity and Specificity
final.test$Exited <- factor(final.test$Exited)
fitted.results <- factor(fitted.results)

sensitivityVal <- round(sensitivity(final.test$Exited, fitted.results),2)
sensitivityVal

#Sensitivity (0.85): Also known as the true positive rate, sensitivity measures the 
# proportion of actual positive cases (customers who exited) that were correctly 
# identified by the model. A sensitivity of 0.85 means that the model correctly 
# identified 85% of the customers who will exit. This indicates a strong ability of 
# the model to capture the customers at risk of churn.

specificityVal <- round(specificity(final.test$Exited, fitted.results),2)
specificityVal

# Specificity(0.7): The true negative rate, reflects the model's ability to correctly
# identify negative cases (customers who will not exit). For example, a specificity of
# 0.70 would mean that 70% of the customers who will not exit are correctly identified
# by the model. Higher specificity indicates that the model is effective in identifying 
# customers who are likely to stay.

# Conclusion - Logistic Regression
# The confusion matrix for the logistic regression model reveals an interesting balance
# between recognizing stable customers and predicting potential departures. With a respectable
# accuracy of 83%, the model reliably forecasts the majority of customer behaviors. However, a
# sensitivity of 85% indicates it's better at detecting customers who might leave the bank (true positives)
# but not perfect, as it overlooks some (false negatives). Specificity at 70% suggests the model is less adept
# at affirming customers who will stay (true negatives), occasionally mistaking a loyal customer
# for a departing one (false positives).
# Therefore, while the logistic regression model is good at flagging potential churn,
# there's room for improvement to ensure that loyal customers are correctly identified and retained.

# ----------------------------------------------------------------------------- 

# Now, we will test our model on the NewCustomerDataset
df.new_customers <- read.csv('NewCustomerDataset.csv')
head(df.new_customers)
str(df.new_customers)

# Dropping irrelevant columns
df.new_customers <- select(df.new_customers, -id, -CustomerId, -Surname)

# Changing the data types and making them consistent with the Bank Churn Dataset
df.new_customers$Geography <- as.factor(df.new_customers$Geography)
df.new_customers$Gender <- as.factor(df.new_customers$Gender)
df.new_customers$HasCrCard <- as.logical(df.new_customers$HasCrCard)
df.new_customers$IsActiveMember <- as.logical(df.new_customers$IsActiveMember)
df.new_customers$Age <- as.integer(df.new_customers$Age)

str(df.new_customers)

#Checking missing values
any(is.na(df.new_customers))

# That's amazing! No missing values in the NewCustomerDataset. 
# Now, let's predict the Churn for the customers in the NewCustomerDataset using the model
# we created above.

# Predicting churn probabilities
predicted_churn_probabilities <- predict(final.log.model, newdata = df.new_customers, type = 'response')

# Converting probabilities to binary predictions based on a 0.5 threshold
df.new_customers$Predicted_Churn <- ifelse(predicted_churn_probabilities > 0.5, 1, 0)

head(df.new_customers)

# There is no existing 'Exited' column in the NewCustomerDataset. So, we can't calculate
# the accuracy of our Predicted Churn values. Also, other performance metrics like 
# Specificity and sensitivity can't be calculated for this dataset. 
# However, we can monitor the performance of our dataset over time and get the Churn values
# for the customers and these will be the actual values. After, we have calculated sufficient
# data points, we can run the accuracy and performance metrics of the actual Churn with our
# Predicted Churn.

# Calculate the number of customers predicted to churn and not churn
churn_counts <- table(df.new_customers$Predicted_Churn)
churn_counts

# Calculate the percentages
churn_percentages <- prop.table(churn_counts) * 100
churn_percentages

# Checking our Churn Statistics
cat('Number of Customers Predicted NOT to Churn:', churn_counts[1], 
    '— This represents', round(churn_percentages[1], 2), 
    '% of the total customers in the new dataset.\n')

cat('Number of Customers Predicted to Churn:', churn_counts[2], 
    '— This represents', round(churn_percentages[2], 2), 
    '% of the total customers.\n')

# Key Insights

# [1] Geography Wise Churn - Bar Graph
# Calculate the count and percentage of each Predicted_Churn by Geography
df_churn_percentages <- df.new_customers %>%
  group_by(Geography, Predicted_Churn) %>%
  summarise(Count = n()) %>%
  ungroup() %>%
  group_by(Geography) %>%
  mutate(Total = sum(Count)) %>%
  mutate(Percentage = Count / Total) %>%
  arrange(Geography, desc(Predicted_Churn)) %>%
  mutate(LabelPos = cumsum(Percentage) - 0.5 * Percentage)

# Creating the plot
ggplot(df_churn_percentages, aes(x = Geography, y = Percentage, fill = factor(Predicted_Churn))) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = sprintf("%1.1f%%", Percentage * 100),
                y = LabelPos), vjust = 0.5, color = "white", size = 3.0) +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_fill_discrete(name = "Churn Prediction", 
                      labels = c("Not Churn", "Churn")) +
  labs(title = "Geography Wise Churn", x = "Geography", y = "Proportion", fill = "Churn Prediction") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5)) #center aligning the plot title

# The graph depicts a significant variance in churn predictions across the three countries. 
# Notably, Germany exhibits a churn prediction rate of 32.1%, which is substantially 
# higher than that of France and Spain, sitting at 6.2% and 6.8% respectively. This stark contrast 
# suggests that customers in Germany are more than five times as likely to churn compared 
# to the other two regions. Such a discrepancy points to the possibility of underlying 
# issues unique to Germany, be it economic factors, customer satisfaction levels, or 
# competitive market dynamics. It underscores the need for the bank to closely examine its 
# market strategy and customer engagement approaches in Germany, potentially conducting 
# detailed customer feedback surveys or market analysis to identify and address the root
# causes of the elevated churn rate.

#[2] Age Wise Bank Churn - Density Plot
ggplot(df.new_customers, aes(x = Age, fill = factor(Predicted_Churn))) +
  geom_density(alpha = 0.5) +
  labs(title = "Age Wise Bank Churn", x = "Age", y = "Density", fill = "Churn Prediction") +
  scale_fill_manual(values = c('0' = 'blue', '1' = 'red'), 
                    labels = c('Not Churn','Churn')) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5)) #center aligning the plot title

# The density plot reveals two distinct trends: the red area, signifying the
# churn, peaks notably for customers aged 35-50, suggesting this demographic
# is more predisposed to leaving the bank. This could be attributed to critical financial
# decision-making periods in their lives, where they might be exploring more competitive
# banking options that offer better rates or services for mortgages, savings plans for
# education of children, or retirement planning.
# Conversely, the blue curve, indicating customers predicted not to churn, is more
# dominant in the younger (below 35) and older (above 50) age brackets. Younger customers
# may be in the early stages of their financial journey and thus less likely to churn
# due to fewer financial commitments or a lower propensity to switch banks. Older customers
# might exhibit loyalty or a preference for stability, making them less inclined to change
# their banking relationships.

#[3] Credit Score Wise Bank Churn - Boxplot
ggplot(df.new_customers, aes(x = factor(Predicted_Churn), y = CreditScore, fill = factor(Predicted_Churn))) +
  geom_boxplot() +
  scale_fill_manual(values = c('0' = 'blue', '1' = 'red'), labels = c('Not Churn','Churn')) +
  labs(title = "Credit Score Wise Bank Churn", x = "Churn Prediction", y = "Credit Score", fill = "Churn Prediction") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5)) #center aligning the plot title

# The boxplot reveals that the credit score distributions for customers predicted to
# churn and those predicted to stay are largely overlapping, with both medians and
# interquartile ranges showing minimal differences. This suggests that credit score
# alone may not be a decisive factor in predicting customer churn. The similarity in
# score distributions across both categories indicates that customers with a wide range
# of credit scores are just as likely to remain with the bank as they are to leave.

#[4] Transaction Activity Wise Bank Churn - Stacked Bar Chart (Horizontal)
df_active_churn <- df.new_customers %>%
  group_by(IsActiveMember) %>%
  count(Predicted_Churn) %>%
  mutate(Percentage = n / sum(n))

# Creating the plot
ggplot(df_active_churn, aes(x = as.factor(IsActiveMember), y = Percentage, fill = as.factor(Predicted_Churn))) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = scales::percent(Percentage, accuracy = 0.1)),
            position = position_stack(vjust = 0.5), color = "white", size = 3) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c('blue', 'red'),
                    labels = c("Not Churn", "Churn")) +
  coord_flip() +  # Flipping coordinates for horizontal bars
  labs(title = "Churn Based on Transaction Activity",
       x = "Transaction Activity",
       y = "Proportion of bank accounts",
       fill = "Churn Status") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5)) +
  scale_x_discrete(labels = c("TRUE" = "Active", "FALSE" = "Not Active")) # Adjusting the Y-axis labels for IsActiveMember

# The graph demonstrates a significant difference in churn rates between active
# and inactive accounts. Notably, 19% of inactive accounts are predicted to
# churn, which is substantially higher than the mere 4.2% for active accounts.
# This pronounced disparity suggests that transactional engagement is a critical
# factor in customer retention. The data indicates that inactive accounts are
# approximately 5 times more likely to churn compared to their
# active counterparts, emphasizing the importance of regular account activity
# in customer loyalty and retention. Banks could leverage this insight to prioritize
# initiatives that encourage regular account usage, such as rewards for transactional
# activity or alerts to re-engage dormant account holders, to mitigate the higher
# churn risk associated with inactivity.

#[5] Account Balance Wise Bank Churn

#Checking summary statistics
summary(df.new_customers$Balance)

# Now, based on the summary statistics segmentation of Balance has been done --

# For zero balance, we will sum up the observations having EXACTLY 0 balance. 
# For low balance, we will sum up the observations having balance between 0 and the 55334 (mean)
# For medium balance, we will sum up the observations having balance between 55334 (mean) and 120146(3rd quartile)
# For high balance, we will sum up the observations having balance between 120146 (3rd quartile) and 250898 (max) 

# Define the mean and third quartile values
mean_balance <- 55334
third_quartile_balance <- 120146

# Segmented data and calculated the sum of Predicted_Churn values for each segment
balance_segments <- df.new_customers %>%
  mutate(Balance_Segment = case_when(
    Balance == 0 ~ 'Zero Balance',
    Balance > 0 & Balance < mean_balance ~ 'Low Balance',
    Balance >= mean_balance & Balance < third_quartile_balance ~ 'Medium Balance',
    Balance >= third_quartile_balance ~ 'High Balance'
  )) %>%
  group_by(Balance_Segment) %>%
  summarise(
    Churn = sum(Predicted_Churn == 1),
    Non_Churn = sum(Predicted_Churn == 0),
    .groups = 'drop'
  )

balance_segments

# Calculating the percentage
balance_segments_long <- balance_segments %>%
  pivot_longer(cols = c(Churn, Non_Churn), names_to = "Status", values_to = "Count") %>%
  mutate(Status = ifelse(Status == "Churn", "Churned", "Not Churned")) %>%
  group_by(Balance_Segment) %>%
  mutate(Percentage = Count / sum(Count),
         Label = scales::percent(Percentage)) %>%
  ungroup()

# Function to create pie chart for each segment
create_pie_chart <- function(data, segment_name) {
  ggplot(data, aes(x = "", y = Percentage, fill = Status)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar(theta = "y") +
    geom_text(aes(label = Label), position = position_stack(vjust = 0.5)) +
    labs(title = segment_name) +
    theme_void() +
    theme(legend.position = "none", plot.title = element_text(size = 10, face = "bold"))
}

# Creating pie charts for each balance segment
pie_charts <- lapply(unique(balance_segments_long$Balance_Segment), function(segment) {
  data <- filter(balance_segments_long, Balance_Segment == segment)
  create_pie_chart(data, segment)
})

# Combine all pie charts into one plot
combined_pie_charts <- wrap_plots(pie_charts, ncol = 2)

# Extracting the legend
legend_plot <- create_pie_chart(balance_segments_long, "") + 
  theme(legend.position = "right") + 
  guides(fill = guide_legend(title = "Churn Status"))

legend <- cowplot::get_legend(legend_plot)

# Arrange the pie charts and the legend
final_layout <- combined_pie_charts + plot_layout(guides = 'collect') + 
  plot_annotation(title = "Churn Based on Account Balance") & 
  theme(
    plot.margin = margin(6, 6, 6, 6),
    panel.spacing = unit(2, "lines"),
    plot.background = element_rect(color = "black", linewidth = 1) 
  )

# Final layout
final_layout_with_legend <- final_layout + plot_spacer() + legend
final_layout_with_legend # ZOOM for a better viewing experience!

# The pie charts deliver a clear message: customers with zero balance are remarkably loyal, 
# with only a 6% churn rate. In stark contrast, customers with any balance—low, medium, or 
# high show a churn rate hovering around 18-19%. This 3-fold increase suggests that customers 
# with balances are significantly more prone to churn, possibly due to unmet financial service 
# expectations. This trend presents a compelling case for the bank to closely examine and enhance 
# the value proposition for customers who actively maintain balances.

# --- K-nearest neighbor method ---
set.seed(101) # Ensure reproducibility

# Splitting the dataset again for KNN analysis 
knn_split <- sample.split(df.train$Exited, SplitRatio = 0.70)
knn_train <- subset(df.train, knn_split == TRUE)
knn_test <- subset(df.train, knn_split == FALSE)

# Scale the numeric data excluding the target variable 'Exited' and any non-numeric columns
knn_train_scaled <- scale(knn_train[,-which(names(knn_train) %in% c("Exited", "Geography", "Gender"))])
knn_test_scaled <- scale(knn_test[,-which(names(knn_test) %in% c("Exited", "Geography", "Gender"))], 
                         center = attr(knn_train_scaled, "scaled:center"), 
                         scale = attr(knn_train_scaled, "scaled:scale"))

# PLEASE IGNORE THIS!! The dataset is huge and R-Studio was crashing when I 
# tried to find the optimal k using this method.

# for(k in 1:20) {
#    set.seed(101)
#    pred_knn <- knn(train = knn_train_scaled, test = knn_train_scaled, cl = knn_train$Exited, k = k)
#    # Calculate accuracy
#    accuracy_knn <- sum(pred_knn == knn_train$Exited) / length(knn_train$Exited)
#   
#   if(accuracy_knn > highest_accuracy) {
#     highest_accuracy <- accuracy_knn
#     optimal_k <- k
#   }
# }

# Instead I went with the hit-and-trial approach and inputted values from 1-20 for k and recorded the
# accuracy values. Also, the decision to not increase k beyond 20 is driven by the observation
# of diminishing returns on accuracy improvements beyond this point, indicating a potential accuracy plateau.
# Additionally, larger k values could unnecessarily increase computation time and more hit-and-trial has to be done!

# Perform KNN prediction with a specified number of neighbors
knn_predictions <- knn(train = knn_train_scaled, test = knn_test_scaled, cl = knn_train$Exited, k = 20)

# Converting the KNN predictions and the actual Exited values into factors with explicit ordering, 
# where "1" represents positive cases (exited) and "0" represents negative cases (not exited)
knn_predictions_factor <- factor(knn_predictions, levels = c("1", "0"))
knn_test$Exited_factor <- factor(knn_test$Exited, levels = c("1", "0"))

#Checking for accuracy
knn_accuracy <- sum(knn_predictions_factor == knn_test$Exited_factor) / length(knn_test$Exited_factor)
knn_accuracy <- round(knn_accuracy, 2)
knn_accuracy

# Hard-coding the values obtained by Hit-and-Trial
k_values <- 1:20
accuracies <- c(0.7921834, 0.7928701, 0.8269642, 0.825005, 0.8383155, 0.837548, 0.842961, 0.8428196, 0.8462533, 0.8456675, 0.8478085, 0.8481317, 0.8490002, 0.8484549, 0.8494446, 0.8498081, 0.8506766, 0.8504948, 0.8506362, 0.8512624)

# Loading the data
reverse_elbow_curve <- data.frame(k_values, accuracies)

# Plotting
ggplot(reverse_elbow_curve, aes(x = k_values, y = accuracies)) +
  geom_line(color = "blue", size = 1) + 
  geom_point(color = "red", size = 2) +
  labs(title = "Reverse Elbow Curve", x = "K Value", y = "Accuracy") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

# Creating the confusion matrix by comparing the predicted values from the KNN model (knn_predictions_factor)
# against the actual outcomes in the test dataset (knn_test$Exited_factor).
knn_confusionMatrix <- table(Predicted = knn_predictions_factor, Actual = knn_test$Exited_factor)

# Creating a comprehensive confusion matrix using the caret package's confusionMatrix function,
# which also computes various performance metrics including accuracy, sensitivity and specificity.
conf_matrix <- confusionMatrix(knn_confusionMatrix)
conf_matrix

knn_sensitivity <- conf_matrix$byClass['Sensitivity']
knn_specificity <- conf_matrix$byClass['Specificity']

# Round the results to 2 decimal places
knn_sensitivity <- round(knn_sensitivity, 2)
knn_specificity <- round(knn_specificity, 2)

cat("KNN Sensitivity:", knn_sensitivity)
cat("KNN Specificity:", knn_specificity)

# The KNN model's performance, as shown by the confusion matrix, presents a nuanced picture. 
# With an overall accuracy of 85%, the model is generally adept at predicting customer churn. 
# Yet, this model has a crucial shortcoming: the model's sensitivity is relatively low at 48%. 
# This means it correctly identifies less than half of the actual churn cases (true positives) 
# while missing the rest (false negatives), suggesting that customers at risk of churn might not 
# be consistently flagged for intervention. On the other hand, the model excels in specificity at 95%, 
# demonstrating a high success rate in confirming customers who are likely to stay (true negatives). 
# This indicates that while the KNN model is quite reliable in affirming customer loyalty, 
# its predictive power to accurately detect churn is limited, potentially leaving a significant portion 
# of at-risk customers unaddressed. In a real-world application, this could result in a missed opportunity 
# to proactively engage and retain a sizable segment of the customer base. 

# Logistic Regression VS K-nearest neighbors

# Creating a data frame for the comparison
comparison_data <- data.frame(
  Model = rep(c("Logistic Regression", "KNN"), each=3),
  Metric = rep(c("Accuracy", "Sensitivity", "Specificity"), 2),
  Value = c(Accuracy_Logistic_Regression, sensitivityVal, specificityVal , knn_accuracy, knn_sensitivity, knn_specificity)
)

# Plotting the comparison 
ggplot(comparison_data, aes(x = Metric, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width=0.8)) +
  geom_text(aes(label = Value, 
                y = Value), 
            position = position_dodge(width=0.7),
            vjust = 10,
            color = "black", 
            size = 5.0) +
  scale_fill_manual(values = c("Logistic Regression" = "skyblue", "KNN" = "salmon")) +
  labs(title = "Performance Comparison: Logistic Regression vs KNN",
       x = "Performance Metrics", y = "Value") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5), 
        legend.title = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1))

# Zoom the graph for better label positioning

# The comparison between Logistic Regression and KNN models for customer churn prediction shows that
# while both models have similar accuracy (0.85 for KNN and 0.83 for Logistic Regression),
# there are notable differences in sensitivity and specificity. KNN has a significantly
# higher specificity (0.95 vs. 0.7 for Logistic Regression), indicating that it is better
# at correctly identifying customers who will not churn. However, Logistic Regression outperforms
# KNN in terms of sensitivity (0.85 vs. 0.48 for KNN), meaning it is more adept at correctly
# identifying customers who will churn.

# In the context of our case study, sensitivity is crucial because failing to identify
# at-risk customers may result in a greater loss to the business than false alarms.
# High specificity is also valuable, but it is less critical than sensitivity because
# retaining satisfied customers generally requires less intervention. Given the importance of
# identifying potential churners, Logistic Regression seems to be the more appropriate model
# for our case study, as it provides a better balance between sensitivity and specificity,
# and being a more reliable predictor of actual churners.

# Future Work
# In future work, expanding the suite of machine learning models to include methods such 
# as Decision Trees, Random Forests and Gradient Boosting Machines, as well as neural networks 
# and support vector machines, could offer deeper insights and potentially improved performance. 
# These models can capture complex non-linear relationships and interactions between variables 
# that simpler models might miss. Furthermore, investigating the use of feature engineering to 
# create more predictive variables could enhance model accuracy.














