# Installing the necessary packages required for analysis
# install.packages("mongolite")
# install.packages("dplyr")
# install.packages("tidytext")
# install.packages("tidyverse")
# install.packages("dplyr")
# install.packages("wordcloud")
# install.packages("RColorBrewer")
# install.packages("topicmodels")
# install.packages("tm")
# install.packages("forcats")
# install.packages("ggcorrplot")

# Loading the packages
library(mongolite)
library(dplyr)
library(tidytext)
library(tidyverse)
library(wordcloud)
library(RColorBrewer)
library(topicmodels)
library(tm)
library(forcats)
library(ggcorrplot)

# Establishing connection with the MongoDB server
connection_string <- 'mongodb+srv://arathi1:3k9tmBurSnT2N9QU@airbnb.qowdo2p.mongodb.net/?retryWrites=true&w=majority&appName=Airbnb'
airbnb_collection <- mongo(collection="listingsAndReviews", db="sample_airbnb", url=connection_string)

#Loading the airbnb dataset
airbnb_all <- airbnb_collection$find()

## ANALYSIS ##
# Analyzing the description feature in the dataset

# Rename 'description' column to 'text'
airbnb_all <- airbnb_all %>% 
  rename(text = description)

# Selecting only the listing_url, text column from the dataframe
mydf <- airbnb_all %>% 
  select(listing_url, text)

# Breaking down the 'text' column into tokens
token_list <- mydf %>%
  unnest_tokens(word, text)

# Counting how frequently each word appears in the dataset
frequencies_tokens <- token_list %>%
  count(word, sort = TRUE)

# Removing stop words
data(stop_words)
frequencies_tokens_nostop <- frequencies_tokens %>%
  anti_join(stop_words, by = "word") %>%
  arrange(desc(n)) # Sort by frequency in descending order

# Topic Modeling
# Create a Document-Term Matrix (DTM) for LDA
dtm <- mydf %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(listing_url, word) %>%
  cast_dtm(listing_url, word, n)

# Perform LDA with the specified number of topics
lda_model <- LDA(dtm, k = 5, control = list(seed = 123))

# Extract and inspect the top terms in each topic
topics <- tidy(lda_model, matrix = "beta")

# Extracting the top terms for each topic
top_terms <- topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

# Naming the topics
topic_names <- c("Multilingual Accessibility & Engagement", 
                 "Convenience & Urban Proximity (Chinese)", 
                 "Recreational & Aesthetic Appeal", 
                 "Urban Access & Connectivity", 
                 "Home Comforts & Amenities")

# Assign these names to the factor levels for the 'topic' variable
top_terms$topic <- factor(top_terms$topic, labels = topic_names)

# Visualize the top terms for each renamed topic 
ggplot(top_terms, aes(reorder(term, beta), beta, fill = topic)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~topic, scales = "free_y") +
  labs(x = "Terms", y = "Beta", title = "Top Terms in Description Topics") +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(family = "Arial Unicode MS"))

# N-grams
# Bigrams
# Tokenizing text into bigrams
airbnb_bigrams <- mydf %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2)

# Separating and filtering out stop words
bigrams_separated <- airbnb_bigrams %>%
  separate(bigram, c("word1", "word2"), sep = " ") %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word)

# Counting and sorting bigrams
bigram_counts <- bigrams_separated %>%
  unite(bigram, word1, word2, sep = " ") %>%
  count(bigram, sort = TRUE)

# Trigrams
# Tokenizing text into trigrams
airbnb_trigrams <- mydf %>%
  unnest_tokens(trigram, text, token = "ngrams", n = 3)

# Separating and filtering out stop words
trigrams_separated <- airbnb_trigrams %>%
  separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) %>%
  filter(!word3 %in% stop_words$word)

# Counting and sorting trigrams
trigram_counts <- trigrams_separated %>%
  unite(trigram, word1, word2, word3, sep = " ") %>%
  count(trigram, sort = TRUE)

# Create a dataframe with listing_url, property_type, and room_type for joining
listing_details <- airbnb_all %>%
  select(listing_url, property_type, room_type)

# Join bigrams with listing details
bigrams_with_details <- bigrams_separated %>%
  unite(bigram, word1, word2, sep = " ") %>%
  inner_join(listing_details, by = "listing_url")

# Filter and count bigrams by property_type
bigram_property_type <- bigrams_with_details %>%
  group_by(property_type, bigram) %>%
  summarise(n = n()) %>%
  top_n(10, n) %>%
  ungroup()

# Count bigrams by room_type
bigram_room_type <- bigrams_with_details %>%
  group_by(room_type, bigram) %>%
  summarise(n = n()) %>%
  top_n(10, n) %>%
  ungroup()

# Join trigrams with listing details
trigrams_with_details <- trigrams_separated %>%
  unite(trigram, word1, word2, word3, sep = " ") %>%
  inner_join(listing_details, by = "listing_url")

# Filter and count trigrams by property_type
trigram_property_type <- trigrams_with_details %>%
  group_by(property_type, trigram) %>%
  summarise(n = n(), .groups = 'drop') %>%
  top_n(20, n)

# Count trigrams by room_type
trigram_room_type <- trigrams_with_details %>%
  group_by(room_type, trigram) %>%
  summarise(n = n(), .groups = 'drop') %>%
  top_n(10, n)

# Compare the most frequent Bigrams by Property Type
bigram_property_summary <- bigram_property_type %>%
  group_by(property_type) %>%
  top_n(5, n) %>%
  ungroup() %>%
  arrange(property_type, desc(n))

# Compare the most frequent Bigrams by Room Type
bigram_room_summary <- bigram_room_type %>%
  group_by(room_type) %>%
  top_n(5, n) %>%
  ungroup() %>%
  arrange(room_type, desc(n))

# Compare the most frequent Trigrams by Property Type
trigram_property_summary <- trigram_property_type %>%
  group_by(property_type) %>%
  top_n(5, n) %>%
  ungroup() %>%
  arrange(property_type, desc(n))

# Compare the most frequent Trigrams by Room Type
trigram_room_summary <- trigram_room_type %>%
  group_by(room_type) %>%
  top_n(5, n) %>%
  ungroup() %>%
  arrange(room_type, desc(n))

# Sentiment Analysis
afinn <- get_sentiments("afinn")
bing <- get_sentiments("bing")
nrc <- get_sentiments("nrc")

# Tokenization and stop words removal
tokens_with_listing <- mydf %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words, by = "word")

# AFINN Sentiment Analysis
afinn_sentiments <- tokens_with_listing %>%
  inner_join(afinn, by = "word") %>%
  group_by(listing_url) %>%
  summarize(total_afinn_score = sum(value, na.rm = TRUE))

# Bing Sentiment Analysis
bing_sentiments <- tokens_with_listing %>%
  inner_join(bing, by = "word") %>%
  count(listing_url, sentiment) %>%
  spread(key = sentiment, value = n, fill = 0) %>%
  mutate(net_sentiment_bing = positive - negative)

# Combine sentiment scores with property type and room type
sentiment_summary <- airbnb_all %>%
  select(listing_url, property_type, room_type) %>%
  left_join(afinn_sentiments, by = "listing_url") %>%
  left_join(bing_sentiments, by = "listing_url")

# Analyze sentiments by property type
property_type_sentiment <- sentiment_summary %>%
  group_by(property_type) %>%
  summarize(mean_afinn_score = mean(total_afinn_score, na.rm = TRUE),
            mean_bing_score = mean(net_sentiment_bing, na.rm = TRUE))

# Analyze sentiments by room type
room_type_sentiment <- sentiment_summary %>%
  group_by(room_type) %>%
  summarize(mean_afinn_score = mean(total_afinn_score, na.rm = TRUE),
            mean_bing_sentiment = mean(net_sentiment_bing, na.rm = TRUE))

# Amenities
# Unnest the review scores and remove listings with NA review scores
cleaned_data <- airbnb_all %>%
  unnest(cols = c(review_scores)) %>%
  select(listing_url, amenities, review_scores_rating) %>%
  drop_na(review_scores_rating)

# Correct the splitting of amenities
cleaned_data <- cleaned_data %>%
  mutate(amenities = gsub("^c\\(\"|\"\\)$", "", amenities), # Remove c(" at the start and ") at the end
         amenities = gsub('", "', "\",\"", amenities)) %>% # Ensure quotes are correctly placed for splitting
  separate_rows(amenities, sep = "\",\"") %>% # Separate into rows, splitting by ","
  mutate(amenities = str_trim(amenities, side = "both")) # Trim whitespace from each amenity

# Create the Document-Term Matrix (DTM) for TF-IDF analysis
dtm <- cleaned_data %>%
  count(listing_url, amenities) %>%
  cast_dtm(listing_url, amenities, n)

# 94% Sparsity, showcasing a good dtm.

# Convert DTM to a tidy format
tidy_dtm <- dtm %>%
  tidy()

# Calculate TF-IDF scores
tf_idf <- tidy_dtm %>%
  bind_tf_idf(term, document, count)

# Find the top amenities based on TF-IDF scores, considering only listings with review scores = 100
high_review_listings <- cleaned_data %>%
  filter(review_scores_rating == 100) %>% 
  pull(listing_url)

# Filter out the 'translation missing' amenities
filtered_amenities <- tf_idf %>%
  filter(!grepl("translation missing", term)) %>%
  filter(document %in% high_review_listings)

# Summarize TF-IDF scores by term to get the maximum score for each term 
top_terms_summary <- filtered_amenities %>%
  group_by(term) %>%
  summarise(max_tf_idf = max(tf_idf)) %>%
  ungroup() %>%
  arrange(desc(max_tf_idf))

# Get the top 20 unique terms based on their maximum TF-IDF scores
top_20_amenities <- top_terms_summary %>%
  slice(1:20)

# Set the levels of the factor
top_20_amenities$term <- factor(top_20_amenities$term, levels = rev(top_20_amenities$term))

# Plotting
ggplot(top_20_amenities, aes(x = term, y = max_tf_idf)) +
  geom_bar(stat = "identity", fill = 'steelblue') +
  coord_flip() +
  labs(title = "Top 20 Amenities by TF-IDF Score", x = "Amenities", y = "Max TF-IDF Score") +
  theme_minimal()

# Neighborhood Overview Analysis
cleaned_neighborhood_data <- airbnb_all %>%
  unnest(cols = c(review_scores)) %>%
  select(listing_url, neighborhood_overview, review_scores_rating) %>%
  filter(!is.na(neighborhood_overview), !is.na(review_scores_rating)) %>%
  mutate(neighborhood_overview = tolower(neighborhood_overview)) %>%
  unnest_tokens(word, neighborhood_overview)

# Remove stop words
cleaned_neighborhood_data <- cleaned_neighborhood_data %>%
  anti_join(stop_words, by = "word")

# Create a Document-Term Matrix (DTM) for LDA
neighborhood_dtm <- cleaned_neighborhood_data %>%
  count(listing_url, word) %>%
  cast_dtm(listing_url, word, n)

# 100% sparsity. Shows a good dtm.

# Fit the LDA model on the DTM
neighborhood_lda <- LDA(neighborhood_dtm, k = 8, control = list(seed = 123))

# Extract the terms from the topics
neighborhood_lda_terms <- tidy(neighborhood_lda, matrix = "beta")

# Determine the top terms for each topic
top_terms <- neighborhood_lda_terms %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

# Renaming the topics
top_terms <- top_terms %>%
  mutate(
    topic_name = case_when(
      topic == 1 ~ "Central Urban Convenience",
      topic == 2 ~ "Porto's Local Vibes",
      topic == 3 ~ "Cultural and Historic Richness",
      topic == 4 ~ "Latin American Local Life",
      topic == 5 ~ "Asian Urban Living",
      topic == 6 ~ "Australian Beach City Life",
      topic == 7 ~ "Mediterranean Urban Appeal",
      topic == 8 ~ "Resort Towns and Ocean Proximity",
      TRUE ~ as.character(topic) 
    )
  )

# Visualize the top terms for each topic 
ggplot(top_terms, aes(x = term, y = beta, fill = factor(topic_name))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic_name, scales = "free") +
  labs(title = "Top Terms in Neighborhood Topics", x = "Terms", y = "Beta") +
  coord_flip() + # Flipping the coordinates for better readability
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), axis.title.x = element_blank())

# Assign each document to the most probable topic
neighborhood_topics <- tidy(neighborhood_lda, matrix = "gamma") %>%
  arrange(desc(gamma)) %>%
  group_by(document) %>%
  slice(1) %>%
  ungroup()

# Merge the most probable topic with the original data frame
cleaned_neighborhood_data <- cleaned_neighborhood_data %>%
  left_join(neighborhood_topics, by = c("listing_url" = "document"))

# Calculate the mean review score for each topic
mean_score_review <- cleaned_neighborhood_data %>%
  group_by(topic) %>%
  summarise(mean_review_score = mean(review_scores_rating, na.rm = TRUE)) %>%
  arrange(desc(mean_review_score))

# Adding topic names
mean_score_review <- mean_score_review %>%
  mutate(
    topic_name = case_when(
      topic == 1 ~ "Central Urban Convenience",
      topic == 2 ~ "Porto's Local Vibes",
      topic == 3 ~ "Cultural and Historic Richness",
      topic == 4 ~ "Latin American Local Life",
      topic == 5 ~ "Asian Urban Living",
      topic == 6 ~ "Australian Beach City Life",
      topic == 7 ~ "Mediterranean Urban Appeal",
      topic == 8 ~ "Resort Towns and Ocean Proximity",
      TRUE ~ as.character(topic)
    )
  )

# Print out the results
print(mean_score_review)

# Reviews
# Sentiment Analysis
# Process each listing's reviews to associate them with the listing's URL, filtering out listings without reviews
airbnb_reviews <- lapply(seq_along(airbnb_all$reviews), function(i) {
  df <- airbnb_all$reviews[[i]]
  if(nrow(df) > 0) {  # Check if the listing has reviews
    df$listing_url <- airbnb_all$listing_url[i]  # Associate reviews with listing's URL
    return(df)
  } else {
    return(NULL)  # Exclude listings without reviews by returning NULL
  }
})

# Filter out the NULL entries from the list
airbnb_reviews <- Filter(Negate(is.null), airbnb_reviews)

# Flatten the list into a dataframe
reviews_df <- do.call(rbind, airbnb_reviews)

# Ensure the reviews dataframe has unique row names to avoid issues with row binding
rownames(reviews_df) <- NULL

# Tokenize the words in the comments
tokenized_reviews <- reviews_df %>%
  unnest_tokens(word, comments)

# AFINN
afinn_sentiment_reviews <- tokenized_reviews %>%
  inner_join(get_sentiments("afinn"), by = "word") %>%
  group_by(listing_url) %>%
  summarize(afinn_score = sum(value, na.rm = TRUE))

# Bing
bing_sentiment_reviews <- tokenized_reviews %>%
  inner_join(get_sentiments("bing"), by = "word") %>%
  count(listing_url, sentiment) %>%
  spread(key = sentiment, value = n, fill = 0) %>%
  mutate(bing_score = positive - negative) %>%
  select(-positive, -negative)

# Combine sentiment scores
combined_sentiment_scores <- reduce(list(afinn_sentiment_reviews, bing_sentiment_reviews), full_join, by = "listing_url")

# Add property_type and room_type from the original airbnb_all data
combined_sentiment_details <- left_join(combined_sentiment_scores, airbnb_all %>% select(listing_url, property_type, room_type), by = "listing_url")

# Average sentiment scores by property type
average_sentiment_property <- combined_sentiment_details %>%
  group_by(property_type) %>%
  summarize(average_afinn_score = mean(afinn_score, na.rm = TRUE),
            average_bing_score = mean(bing_score, na.rm = TRUE))

# Average sentiment scores by room type
average_sentiment_room <- combined_sentiment_details %>%
  group_by(room_type) %>%
  summarize(average_afinn_score = mean(afinn_score, na.rm = TRUE),
            average_bing_score = mean(bing_score, na.rm = TRUE))

# LDA (Reviews)
# Tokenize reviews and remove stop words
dtm_reviews <- reviews_df %>%
  unnest_tokens(word, comments) %>%
  anti_join(stop_words, by = "word") %>%
  count(listing_url, word) %>%
  cast_dtm(listing_url, word, n)

# LDA model
k <- 5  # Number of topics
lda_model <- LDA(dtm_reviews, k = k, control = list(seed = 123))

# Extract and inspect top terms in each topic
topics <- tidy(lda_model, matrix = "beta")

# Extracting the top terms for each topic
top_terms <- topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

# Visualize the top terms for each topic
ggplot(top_terms, aes(reorder(term, beta), beta, fill = topic)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  facet_wrap(~topic, scales = "free_y") +
  labs(x = "Terms", y = "Beta", title = "Top Terms in Each Topic") +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(family = "Arial Unicode MS"))

# Correlation Analysis

# Superhost vs. Non-Superhost Analysis
# Extract Superhost status
airbnb_all$superhost_status <- ifelse(airbnb_all$host$host_is_superhost == "TRUE", "Superhost", "Non-Superhost")

# Merge the combined sentiment scores with the Superhost status
sentiment_superhost_analysis <- left_join(combined_sentiment_scores, airbnb_all %>% select(listing_url, superhost_status), by = "listing_url")

# Calculate the average sentiment scores for Superhosts and Non-Superhosts
average_sentiment_by_superhost <- sentiment_superhost_analysis %>%
  group_by(superhost_status) %>%
  summarize(average_afinn_score = mean(afinn_score, na.rm = TRUE),
            average_bing_score = mean(bing_score, na.rm = TRUE))

# Output the results
print(average_sentiment_by_superhost)

# Visualizations
# 1. Bigram/Trigram counts for listings
# Adding a 'type' column to each dataframe
bigram_counts <- bigram_counts %>%
  mutate(type = 'Bigram')

trigram_counts <- trigram_counts %>%
  mutate(type = 'Trigram')

# Selecting the top 10 bigrams and trigrams
top_bigrams <- head(bigram_counts, 10)
top_trigrams <- head(trigram_counts, 10)

# Combining the top 10 bigrams and trigrams
combined_counts <- bind_rows(top_bigrams, top_trigrams)

combined_long <- combined_counts %>%
  mutate(phrase = coalesce(bigram, trigram)) %>%
  select(phrase, n, type)

# Plotting
ggplot(combined_long, aes(x = reorder(phrase, n), y = n)) +
  geom_bar(stat = "identity", aes(fill = type)) +
  facet_wrap(~type, scales = "free", ncol = 2) +
  coord_flip() +
  theme_minimal() +
  theme(legend.position = "bottom",
        strip.background = element_blank(),
        strip.text.x = element_text(size = 12, face = "bold"),
        axis.text.y = element_text(size = 10),
        axis.title.y = element_blank())

# 2. Bigram by Room Type
ggplot(bigram_room_summary, aes(x = reorder(bigram, n), y = n)) + 
  geom_bar(stat = "identity", fill = "steelblue") + 
  facet_wrap(~ room_type, scales = "free_y", ncol = 1) +  
  coord_flip() +
  labs(title = "Top Bigrams by Room Type",
       x = "Frequency",
       y = "") + 
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.y = element_text(size = 10),
        axis.text.x = element_blank(),
        strip.text.x = element_text(size = 12, face = "bold"),
        strip.background = element_rect(fill = "lightblue"),
        panel.spacing = unit(1, "lines"), # Adjust spacing between facets
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()) 

# 3. Sentiment scores by Room Type
# Calculate the averages for mean_afinn_score and mean_bing_sentiment
avg_afinn <- mean(room_type_sentiment$mean_afinn_score)
avg_bing <- mean(room_type_sentiment$mean_bing_sentiment)

# Reshape the data for plotting
room_type_sentiment_long <- room_type_sentiment %>%
  pivot_longer(cols = c(mean_afinn_score, mean_bing_sentiment), names_to = "sentiment_type", values_to = "score")

# Plot with separate facets for AFINN and Bing, including average lines
ggplot(room_type_sentiment_long, aes(x = room_type, y = score, fill = sentiment_type)) +
  geom_bar(stat = "identity", position = position_dodge(), color = "black") +
  geom_hline(aes(yintercept = ifelse(sentiment_type == "mean_afinn_score", avg_afinn, avg_bing)), linetype = "dashed", color = "black") +
  coord_flip() +
  facet_wrap(~sentiment_type, scales = "free") +
  theme_minimal() +
  labs(title = "Sentiment Scores by Room Type",
       x = "Room Type",
       y = "Score") +
  scale_fill_manual(values = c("mean_afinn_score" = "red", "mean_bing_sentiment" = "blue")) +
  theme(legend.title = element_blank(),
        legend.position = "bottom")
