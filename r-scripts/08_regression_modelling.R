# Multiple regression in a glm context: calculation and plotting
# Q: How does the distribution along the gradient of Orchestia change between years?

renv::restore()

# clear everything in memory (of R)
remove(list=ls())

library(tidyverse)


# read the macrodetritivore abundance data, call the dataset orchdat
# filter to use only years 2018,2019,2021,2022,2023,2024 and only 3 or less replicates and species Orchestia_gammarellus
# group by year and TransectPoint_ID
# calculate the sum of the number of Orchestia found per year and TransectPoint
# do all the above in one pipeline
orchdat<-readr::read_csv("https://docs.google.com/spreadsheets/d/e/2PACX-1vT6bdROUwchBBIreCQQdBenu35D5Heo8bl3UgES9wrpBwax_GUM1bKSo_QXfmLq8Ml9-crCI7MmW2XH/pub?gid=615066255&single=true&output=csv") |>
  dplyr::filter(year %in% c(2018,2019,2021:2024), replicate <= 3, 
                Species_ID == "Orchestia_gammarellus") |> #single = means 'assign', double = indicates logical test (T/F)
  dplyr::group_by(year, TransectPoint_ID) |>
  dplyr::summarise(CountSum = sum(Count, na.rm = TRUE))


# read the macrotransect elevation data, filter and select right variables
elevdat<-readr::read_csv("https://docs.google.com/spreadsheets/d/e/2PACX-1vT4C7olgh28MHskOjCIQGYlY8v5z1sxza9XaCccwITnjoafF_1Ntfyl1g7ngQt4slnQlseWT6Fk3naB/pub?gid=1550309563&single=true&output=csv") %>%
  dplyr::filter(year %in% c(2018,2019,2021,2022,2023,2024) & !is.na(TransectPoint_ID)) %>%
  dplyr::select(year,TransectPoint_ID,elevation_m)   # select  only distance_m and elevation 
elevdat

# join  the elevation with  the orchestia data by year and TransectPoint_ID, and filter to retain only transect points between 200 and 1000 (where it lives)
# make year a factor
names(orchdat)
names(elevdat)
orchdat3<-left_join(orchdat, elevdat, by = c("year", "TransectPoint_ID")) |>
  dplyr::filter(TransectPoint_ID >= 200 & TransectPoint_ID <= 1000) |>
  dplyr::filter(!(year == 2022 & TransectPoint_ID == 260)) # ! means everything, except ...
orchdat3

# explore how Orchestia abundance changes along the transect in a bar plot
orchdat3 |>
  ggplot2::ggplot(mapping = aes(x = factor(TransectPoint_ID), y = CountSum, 
                                group = year)) +
  geom_bar(stat = "identity") + #identity -> just uses the values as they are in the data, no statistics involved
  facet_grid(year ~.) #what is in rows ~ what is in columns

# explore how elevation changes along the transect in a barplot
orchdat3 |>
  ggplot2::ggplot(mapping = aes(x = factor(TransectPoint_ID), y = elevation_m, 
                                group = year)) +
  geom_bar(stat = "identity") + #identity -> just uses the values as they are in the data, no statistics involved
  facet_grid(year ~.) #what is in rows ~ what is in columns
  
# plot Orchestia (y) versus elevation_m (x) in ggplot as a scatterplot, with each year as a different color
p1<- orchdat3  |> 
  ggplot2::ggplot(mapping = aes(x = elevation_m, y = CountSum, col = factor(year))) +
  geom_point(size = 3)
p1

# calculate the optimal preferred elevation by Orchestia for each year using weighted.mean function
orchdat3 |>
  group_by(year) |>
  summarise(wa_elevation = weighted.mean(x = elevation_m, w = CountSum, na.rm = TRUE))

## explore response to elevation and year as a linear model, call this m1
# first only elevation (not yet year)
orchdat3
m1<-lm(CountSum ~ elevation_m, data = orchdat3)
m1

#add the linear model to the plot
orchdat3$pred1 <- predict(m1)
p2 <- p1 + geom_line(data = orchdat3, aes(y = pred1), col = "black", linewidth = 1.2)
p2

# fit model m2 by adding a quadratic term for elevation_m to check for an ecological optimum
# y=b0 + b1x + b2*I(x^2) #Expect that b2 will be negative!
m2 <- lm(CountSum ~ elevation_m + I(elevation_m^2), data = orchdat3)
m2

#add the linear model to the plot
# calculate the predicted value of m2 for every observation, add to the dataset as a variable as pred2
# add the new predicted line to the previous plot p2, store as object p3 and show it
orchdat3$pred2 <- predict(m2)
p2 + geom_line(data = orchdat3, aes(y = pred2), col = "red", linewidth = 1.2)
  
# test if the new model m2 significantly explains more variation than the first model m1
anova(m1, m2) #The RSS (residual sum of squares) is lower for the second model, saying that the total unexpected deviations is lower. It says so with a ** significance, being a factor of 0.01 (1%) -> so it is significant.


# predict the orchestia abundance at 1.5 m elevation

# add year (as a factor) to the model and fit it as model m3
# so y = b0 + b1x1 + b2x1^2 +b3x2 
# test if it is significant, and better than the previous one
m3 <- lm(CountSum ~ elevation_m + I(elevation_m^2) + factor(year), 
         data = orchdat3)
m3
anova(m3)
  
#add the linear model to the plot
# calculate the predicted value of m2 for every observation, add to the dataset as a variable as pred2
# add the new predicted line to the previous plot p2, store as object p3 and show it
orchdat3$pred3 <- predict(m3)
p1 + geom_line(data = orchdat3, aes(y = pred3, col = factor(year)), linewidth = 1.2) 
  
# does this significantly explain more variation than the model without year?
anova(m3, m2)
  
# yes this is a better model


# include the interaction elevation_m*factor(year) between elevation and year (as a factor) in the model 
  
#add the linear model to the plot
# calculate the predicted value of m2 for every observation, add to the dataset as a variable as pred2
# add the new predicted line to the previous plot p2, store as object p3 and show it
m4 <- lm(CountSum ~ elevation_m + I(elevation_m^2) + factor(year) + 
           elevation_m*factor(year), 
         data = orchdat3)

orchdat3$pred4 <- predict(m4)
p1 + geom_line(data = orchdat3, aes(y = pred4, col = factor(year)), linewidth = 1.2)

anova(m4, m3)

#### m3 is the preferred model in this case (outcome of model selection)



# explore the consequences of a log transformation of y values
x<-c(0,1,2,3,4,5)
y<-c(1,10,100,1000,10000,100000)
dat<-data.frame(x,y)
dat
dat %>% ggplot(aes(x=x,y=y)) +
  geom_point(shape=16,size=5) +
  geom_line(size=1.2)
dat %>% ggplot(aes(x=x,y=log10(y))) +
  geom_point(shape=16,size=3) +
  geom_line(size=1.2)
dat %>% ggplot(aes(x=x,y=log(y))) + # use log with base number e
  geom_point(shape=16,size=3) +
  geom_line(size=1.2)
# explore the consequences of the log base number (10 or e)
log(0)
log10(1)
log10(10)
log(0)
log(1)
exp(1)
log(exp(1))



### develop, test for significance and plot different models of increasing complexity 
#  using  multiple regresssion, assuming a poisson distribution (so use a generalized linear model)
# Explore  how the abundance of Orchestia depends on elevation_m and year,  their potential interaction,
# and a potential ecological optimum of Orchestia with respect to elevation_m
# show the effect of elevation but now in a generalized linear model instead of linear model, using a log link function and a poisson distribution
orchdat3
p1


#add the linear model to the plot
# calculate the predicted value of m2 for every observation, add to the dataset as a variable as pred2
# add the new predicted line to the previous plot p2, store as object p3 and show it
m5 <- glm(CountSum ~ elevation_m, 
          family = poisson(log),
          data = orchdat3)


# now test and show  the effect of both elevation , elevation squared and year
anova(m5, test = "Chisq")


#add the linear model to the plot
# calculate the predicted value of m2 for every observation, add to the dataset as a variable as pred2
# add the new predicted line to the previous plot p2, store as object p3 and show it
orchdat3$pred5 <- predict(m5, type = "response")
p1 + geom_line(data = orchdat3, aes(y = pred5), linewidth = 1.2)

# account for the ecological optimum
m6 <- glm(CountSum ~ elevation_m + I(elevation_m^2), 
          family = poisson(log),
          data = orchdat3)

orchdat3$pred6 <- predict(m6, type = "response")
p1 + geom_line(data = orchdat3, aes(y = pred6), linewidth = 1.2)

# better than the previous?
anova(m6, m5)

# add the interaction to the model: elevation + elevation ^2 + year + elevation*year
# now test and show  the effect of both elevation + year
m7 <- glm(CountSum ~ elevation_m + I(elevation_m^2) + factor(year),
          family = poisson(log),
          data = orchdat3)

orchdat3$pred7 <- predict(m7, type = "response")
p1 + geom_line(data = orchdat3, aes(y = pred7, col = factor(year)), linewidth = 1.2)

anova(m7, "Chisq")
anova(m7, m6, "Chisq")


m8 <- glm(CountSum ~ elevation_m + I(elevation_m^2) + factor(year) + 
            elevation_m*factor(year),
          family = poisson(log),
          data = orchdat3)

orchdat3$pred8 <- predict(m8, type = "response")
p1 + geom_line(data = orchdat3, aes(y = pred8, col = factor(year)), linewidth = 1.2)

anova(m8, "Chisq")
anova(m8, m7, "Chisq")


#add the  model to the plot
# calculate the predicted value of m2 for every observation, add to the dataset as a variable as pred2
# add the new predicted line to the previous plot p2, store as object p3 and show it





