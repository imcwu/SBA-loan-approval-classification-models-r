# This is the R-script File for the SBA Loan Approval Project.
library(readxl)
myTPData <- read_excel("~/Documents/Projects/SBA loan project data FULL SET.xlsx")
View(myTPData)

# Step1: Data Understanding
which(is.na(myTPData$LoanNr_ChkDgt))
which(is.na(myTPData$Name))
which(is.na(myTPData$City))
which(is.na(myTPData$State))
which(is.na(myTPData$Zip))
which(is.na(myTPData$Bank))
which(is.na(myTPData$NAICS))
which(is.na(myTPData$ApprovalDate))
which(is.na(myTPData$ApprovalFY))
which(is.na(myTPData$Term))
which(is.na(myTPData$NoEmp))
which(is.na(myTPData$NewExist))
which(is.na(myTPData$CreateJob))
which(is.na(myTPData$RetainedJob))
which(is.na(myTPData$FranchiseCode))
which(is.na(myTPData$UrbanRural))
which(is.na(myTPData$RevLineCr))
which(is.na(myTPData$LowDoc))
which(is.na(myTPData$ChgOffDate))
which(is.na(myTPData$DisbursementDate))
which(is.na(myTPData$DisbursementGross))
which(is.na(myTPData$BalanceGross))
which(is.na(myTPData$MIS_Status))
which(is.na(myTPData$ChgOffPrinGr))
which(is.na(myTPData$GrAppv))
which(is.na(myTPData$SBA_Appv))
"Notes:
Variables with Missing Entries: Name, City, State, Bank, BankState, ApprovalFY,
NewExist, LowDoc, ChgOffDate, DisbursementDate, and MIS_Status have missing 
entries."

# Data Preparation
"Remove columns that are not important"
myNewTPData <- data.frame(MIS_Status = myTPData$MIS_Status, 
                          GrAppv = myTPData$GrAppv, 
                          Term = myTPData$Term, 
                          NewExist = myTPData$NewExist, 
                          RevLineCr = myTPData$RevLineCr, 
                          UrbanRural = myTPData$UrbanRural, 
                          SBA_Appv = myTPData$SBA_Appv, 
                          CreateJob = myTPData$CreateJob, 
                          RetainedJob = myTPData$RetainedJob, 
                          ChgOffPrinGr = myTPData$ChgOffPrinGr)
# Make Dummy Variable for Target Variable, MIS Status
myNewTPData$MIS_Status = ifelse(myNewTPData$MIS_Status == "CHGOFF", 1, 0)
# Make Dummy Variable for RevLineCr
myNewTPData$RevLineCr = ifelse(myNewTPData$RevLineCr == "Y", 1, 0)
# Make Dummy Variables for NewExist
myOmittedTPData <- subset(myNewTPData, NewExist != 0)
myOmittedTPData$NewBusiness <- ifelse(myOmittedTPData$NewExist == "2", 1, 0)
myOmittedTPData$ExistingBusiness <- ifelse(myOmittedTPData$NewExist == "1", 1, 0)
# Make Dummy Variables for Urban Rural
myOmittedTPData$UrbanRural_Undef <- ifelse(myOmittedTPData$UrbanRural == "0", 1, 0)
myOmittedTPData$UrbanRural_Urban <- ifelse(myOmittedTPData$UrbanRural == "1", 1, 0)
myOmittedTPData$UrbanRural_Rural <- ifelse(myOmittedTPData$UrbanRural == "2", 1, 0)

# Omit the Missing Entries
myOmittedTPData <- na.omit(myOmittedTPData)

# Standardize Numerical Variables
myOmittedTPData$GrAppv <- scale(myOmittedTPData$GrAppv)
myOmittedTPData$Term <- scale(myOmittedTPData$Term)
myOmittedTPData$SBA_Appv <- scale(myOmittedTPData$SBA_Appv)
myOmittedTPData$CreateJob <- scale(myOmittedTPData$CreateJob)
myOmittedTPData$RetainedJob <- scale(myOmittedTPData$RetainedJob)
myOmittedTPData$ChgOffPrinGr <- scale(myOmittedTPData$ChgOffPrinGr)

# Data Training and Validation
library(caret)
set.seed(1)
myIndex <- createDataPartition(myOmittedTPData$MIS_Status, p = 0.6, list = FALSE)
trainSet <- myOmittedTPData[myIndex, ]
validationSet <- myOmittedTPData[-myIndex, ]

# Model 1
LogModel1 <- glm(MIS_Status ~ Term + GrAppv + SBA_Appv, data = trainSet, family = binomial(link = "logit"))
summary(LogModel1)
validationSet$Pred1 <- predict(LogModel1, validationSet, type = "response")
validationSet$PredictedOutcome1 <- ifelse(validationSet$Pred1 >= 0.5, 1, 0)
validationSet$Accuracy1 <- ifelse(validationSet$MIS_Status == validationSet$PredictedOutcome1, 1, 0)
sum(validationSet$Accuracy1) / length(validationSet$Accuracy1)
"0.8176811"
validationSet$TP1 <- ifelse(validationSet$MIS_Status == 1 & validationSet$PredictedOutcome1 == 1, 1, 0)
validationSet$TN1 <- ifelse(validationSet$MIS_Status == 0 & validationSet$PredictedOutcome1 == 0, 1, 0)
validationSet$FP1 <- ifelse(validationSet$MIS_Status == 0 & validationSet$PredictedOutcome1 == 1, 1, 0)
validationSet$FN1 <- ifelse(validationSet$MIS_Status == 1 & validationSet$PredictedOutcome1 == 0, 1, 0)
# Sensitivity
sum(validationSet$TP1) / (sum(validationSet$TP1) + sum(validationSet$FN1)) 
"0.1215265"
# Specificity
sum(validationSet$TN1) / (sum(validationSet$TN1) + sum(validationSet$FP1))
"0.966893"

# Model 2
LogModel2 <- glm(MIS_Status ~ GrAppv + Term + RevLineCr + SBA_Appv + ChgOffPrinGr, data = trainSet, family = binomial(link = "logit"))
summary(LogModel2)
validationSet$Pred2 <- predict(LogModel2, validationSet, type = "response")
validationSet$PredictedOutcome2 <- ifelse(validationSet$Pred2 >= 0.5, 1, 0)
validationSet$Accuracy2 <- ifelse(validationSet$MIS_Status == validationSet$PredictedOutcome2, 1, 0)
sum(validationSet$Accuracy2) / length(validationSet$Accuracy2)
"0.9812224"
validationSet$TP2 <- ifelse(validationSet$MIS_Status == 1 & validationSet$PredictedOutcome2 == 1, 1, 0)
validationSet$TN2 <- ifelse(validationSet$MIS_Status == 0 & validationSet$PredictedOutcome2 == 0, 1, 0)
validationSet$FP2 <- ifelse(validationSet$MIS_Status == 0 & validationSet$PredictedOutcome2 == 1, 1, 0)
validationSet$FN2 <- ifelse(validationSet$MIS_Status == 1 & validationSet$PredictedOutcome2 == 0, 1, 0)
length(which(validationSet$TP2 == 1))
length(which(validationSet$TN2 == 1))
length(which(validationSet$FP2 == 1))
length(which(validationSet$FN2 == 1))
# Sensitivity
sum(validationSet$TP2) / (sum(validationSet$TP2) + sum(validationSet$FN2)) 
"0.9132839"
# Specificity
sum(validationSet$TN2) / (sum(validationSet$TN2) + sum(validationSet$FP2))
"0.9957842"

# Model 3
LogModel3 <- glm(MIS_Status ~ RevLineCr + CreateJob + Term, data = trainSet, family = binomial(link = "logit"))
summary(LogModel3)
validationSet$Pred3 <- predict(LogModel3, validationSet, type = "response")
validationSet$PredictedOutcome3 <- ifelse(validationSet$Pred3 >= 0.5, 1, 0)
validationSet$Accuracy3 <- ifelse(validationSet$MIS_Status == validationSet$PredictedOutcome3, 1, 0)
sum(validationSet$Accuracy3) / length(validationSet$Accuracy3)
"0.8190356"
validationSet$TP3 <- ifelse(validationSet$MIS_Status == 1 & validationSet$PredictedOutcome3 == 1, 1, 0)
validationSet$TN3 <- ifelse(validationSet$MIS_Status == 0 & validationSet$PredictedOutcome3 == 0, 1, 0)
validationSet$FP3 <- ifelse(validationSet$MIS_Status == 0 & validationSet$PredictedOutcome3 == 1, 1, 0)
validationSet$FN3 <- ifelse(validationSet$MIS_Status == 1 & validationSet$PredictedOutcome3 == 0, 1, 0)
# Sensitivity
sum(validationSet$TP3) / (sum(validationSet$TP3) + sum(validationSet$FN3)) 
"0.1224798"
# Specificity
sum(validationSet$TN3) / (sum(validationSet$TN3) + sum(validationSet$FP3))
"0.9683335"