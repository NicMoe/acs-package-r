# Install and activate acs library
install.packages("acs")
library("acs", lib.loc="~/R/win-library/3.3")

# Install API key
# Input your actual API key
# Get your key at https://api.census.gov/data/key_signup.html
api.key.install(key="32rn9v3notarealkey203jn8mdw9c")

# Set up list of states (plus DC and PR)
state.fips <- c(01:02,04:06,08:13,15:42,44:51,53:56,72)
formatC(state.fips, digits=2)

# Set geography
everywhere <- geo.make(state=c(state.fips), county="*", tract="*")

# Lookup relevant variables to pull
acs.lookup(2015, span = 5, dataset = "acs", keyword="total", table.number="B08124", case.sensitive = F)

# The relevant variable codes are below
# B01001_001 = total population
# B08014_002 = number of workers with no vehicle available
# B08124_001 = total workers
# B08124_022 = workers taking public transportation to work (excluding taxicabs)

# Pull data for a given geography from Census API
# Note that this can take a few minutes
transit.data <- acs.fetch(2016, span = 5, geography = everywhere, variable = c("B01001_001", "B08014_002", "B08124_001", "B08124_022"), dataset = "acs", col.names = "auto")

# Turn geography, estimates, and standard errors into data frames
transit.geography <- as.data.frame(transit.data@geography)
transit.estimates <- as.data.frame(transit.data@estimate)
transit.se <- as.data.frame(transit.data@standard.error)

# Create tract name variables for 'estimates' and 'se' data frames
transit.estimates$NAME <- rownames(transit.estimates)
transit.se$NAME <- rownames(transit.se)

# In standard error data, rename columns for clarity
names(transit.se)[names(transit.se)=="B01001_001"] <- "B01001_001se"
names(transit.se)[names(transit.se)=="B08014_002"] <- "B08014_002se"
names(transit.se)[names(transit.se)=="B08124_001"] <- "B08124_001se"
names(transit.se)[names(transit.se)=="B08124_022"] <- "B08124_022se"

# Merge the three data frames into one
transit.est.se <- merge(transit.estimates, transit.se, "NAME")
transit.all <- merge(transit.est.se, transit.geography, "NAME")

# Format FIPS codes with fixed digit numbers and leading zeros when necessary
# Note: after finishing everything and checking in Excel, this formatting does nothing. As a workaround, once the output exists as a csv, open it in Excel, and iteratively select each of the three columns (state, county, tract), format cells, custom, type = zeros equal to number of digits (for state, type = 00)
transit.all$state <- sprintf("%02d", transit.all$state)
transit.all$county <- sprintf("%03d", transit.all$county)
transit.all$tract <- sprintf("%06d", transit.all$tract)

# Create and add distinct variables for state, county, and tract names
install.packages("reshape")
library("reshape", lib.loc="~/R/win-library/3.3")
transit.all <- transform(transit.all, name = colsplit(NAME, split = "\\,", names = c('tract', 'county', 'state')))

# Create and add additional variable for county (and county equiv.) names without title
transit.all$name.county2 <- gsub("County|Parish|Borough|Census|Area|Municipality|Municipio|city","",transit.all$name.county)

# Trim white space around state and county names
transit.all$name.state <- trimws(transit.all$name.state, which = "both")
transit.all$name.county <- trimws(transit.all$name.county, which = "both")
transit.all$name.county2 <- trimws(transit.all$name.county2, which = "both")

# Set working directory
setwd("C:/My documents/Wherever")

# Write final dataframe to csv file
write.csv(transit.all, file = "transitestimates.csv")
