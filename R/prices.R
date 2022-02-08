library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(stringr)
library(gridExtra)
library(grid)
library(magick)
library(scales)
library(readr)

# як врахувати інфляцію для групи продуктів
# апельсини  - 5 кг (інфляція 28%)
# йогурт - 10 літрів (інфляція 11%)
# ФОРМУЛА від Толі: ((5 * 28%) + (10 * 11%) ) / (5+10)


# dir with this script as default
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# скріпт з функцією розподілу категорій на основі споживчого набору
source("function_detect_product.R")

# скріпт, що приєднує пропущенні значення категорії
source("function_restore_sections_value.R")


getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}


# ====================================
# ============= ASHAN ================
# ====================================
mode_dictionary = read.csv("/home/yevheniia/git/food_prices/data/mode_dictionary.csv", stringsAsFactors = F) %>% 
  select(-X)

year_22 = read.csv("food_prices_fixed_jan_22_full_month.csv", header=FALSE, stringsAsFactors = FALSE) 

year_21 = read.csv("food_prices_11_01_2022.csv", header=FALSE, stringsAsFactors = FALSE) %>% 
  bind_rows(read.csv("food_prices_august_2021.csv")) %>% 
  bind_rows(year_22) %>% 
  filter(V1 == "Ашан")  %>% 
  mutate(V12 = as.Date(V12, format="%d-%m-%Y")) %>% 
  unique() %>% 
  select(1:12)



# last_day = as.character(new_data$V12[1])
# last_day =  gsub("-", "_", last_day)

data = restore_sections_value(year_21)

### старі дані з Ашану за 2020 рік, зараз не потрібні
# setwd('/home/yevheniia/python/food_prices_arviched_data/ashan/')
# dataFiles <- list.files(pattern = "*.csv") %>%
#   lapply(read.csv, sep = ";", stringsAsFactors = F) %>%
#   bind_rows %>%
#   mutate(product = tolower(product)) %>%
#   mutate(
#     product = sub(",", "\\.", product),
#     weight_value = str_extract(
#       product,
#       "[\\d]{1,4}(?=(г|кг|мл|л|шт)$)|0\\.[\\d]{1,2}(?=(г|кг|мл|л|шт)$)"
#     ),
#     weight_unit = tolower(str_extract(
#       product, "(?<=[\\d]{1,4})(г|кг|мл|л|шт)"
#     ))
#   ) %>%
#   mutate(
#     weight_value = ifelse(str_detect(price, "кг"), 1, weight_value),
#     weight_unit = ifelse(str_detect(price, "кг"), "кг", weight_unit)
#   ) %>%
#   mutate(price = sub("\\s.*", "", price)) %>%
#   filter(!is.na(weight_value)) %>%
#   mutate(
#     price =  as.numeric(price),
#     weight_value = as.numeric(weight_value),
#     price_kg = ifelse(
#       weight_unit == "г",
#       (price / weight_value * 1000),
#       ifelse(
#         weight_unit == "кг" & weight_value == 1,
#         price,
#         ifelse(
#           weight_unit == "кг" & weight_value > 1,
#           (price / weight_value),
#           ifelse(
#             weight_unit == "мл",
#             (price / weight_value * 1000),
#             ifelse(
#               weight_unit == "л" & weight_value == 1,
#               price,
#               ifelse(
#                 weight_unit == "л" & weight_value > 1,
#                 (price / weight_value),
#                 ifelse(
#                   weight_value < 1,
#                   (price / weight_value),
#                   ifelse(weight_unit == "шт", price,
#                          NA)
#                 )
#               )
#             )
#           )
#         )
#       )
#     )
#   ) %>%
#   mutate(month = format(as.Date(time, format = "%d-%m-%Y"), "%Y-%m")) %>%
#   mutate(subsection = detect_product_ru(section, product))


infliation = data %>%
  mutate(month = format(as.Date(time), "%Y-%m-01")) %>%
  group_by(month, subsection) %>%
  mutate(median = median(price_kg)) %>%
  mutate(min = min(price_kg)) %>%
  mutate(Q1 = quantile(price_kg, prob = .25, na.rm = TRUE)) %>%
  ungroup() %>%
  # group_by(subsection) %>% 
  # mutate(mode = getmode(weight_value)) %>%
  # ungroup() %>%
  # mutate(mode = ifelse(mode > 1, mode/1000, mode)) %>%
  distinct(subsection, month, .keep_all = TRUE) %>%
  gather(key = "measure", value = "price", min, median, Q1 ) %>% 
  mutate(category = car::recode(subsection,"
            c('хліб цільнозерновий', 'хліб пшеничний','хліб житньо-пшеничний','батон','багет')='хліб';
            c('апельсини', 'банани', 'яблука', 'авокадо', 'мандарини', 'виноград', 'лимони','ягоди', 'ківі', 'кавуни')='фрукти';
            c('буряк', 'кабачки', 'капуста білокачанна', 'картопля', 'морква', 'огірки', 'помідори', 'цибуля ріпчаста', 'часник', 'гриби', 'перець солодкий','баклажани','салати')='овочі';
            c('свинина', 'свинина гуляш', 'свинина фарш', 'свинина ребра', 'яловичина', 'яловичина фарш', 'яловичина ребра','філе куряче', 'курка крильця', 'курка стегно','птиця (тушки курячі)','субпродукти яловичні','субпродукти свинячі',' субпродукти курячі','сало','вирізка свиняча', 'вирізка яловича') = 'м’ясо';
            c('сосиски, сардельки вищого ґатунку', 'сосиски, сардельки першого ґатунку', 'ковбаси варені вищого ґатунку','ковбаси варені першого ґатунку', 'ковбаси сирокопчені в/ґ','ковбаси варено-копчені в/ґ', 'вироби з м’яса делікатесні') = 'ковбасні вироби';
            c('пластівці вівсяні', 'рис', 'крупи гречані', 'борошно пшеничне', 'макарони', 'цукор', 'сухі сніданки', 'квасоля','пшоно','крупи манні','крупи ячні','супи')= 'бакалея';
            c('молоко пастеризоване жирністю до 2,6% включно', 'йогурт', 'кефір 2.5%', 'сметана жирністю до 15% включно', 'сметана з підвищеним вмістом жиру',  'крем-сир', 'сири тверді типу Едам', 'сири м’які жирні', 'масло вершкове 82%', 'масло вершкове 73%', 'маргарин', 'молоко з підвищеним вмістом жиру', 'сири м’які нежирні', 'сири плавлені', 'сири розсольні','сирки та сиркова маса','молочні суміші для дитячого харчування','яйця')='молочна продукція та яйця';
            c( 'риба червона', 'риба річна', 'ікра червона', 'оселедці','скумбрія копчена', 'філе мороженої риби', 'риба морожена', 'консерви рибні в олії','морепродукти')='риба та морепродукти';
            c('олія соняшникова', 'олія оливкова')='олія';
            c('сік яблучний', 'сік апельсиновий', 'солодка вода' )='безалкогольні напої';
            c('кава розчинна', 'кава мелена', 'чай у пакетиках')='кава і чай';
            c('пельмені', 'вареники з картоплею',  'крабові палички' )='напівфабрикати';
            c('кукурудза консервована', 'горошок консервований','гриби консервовані')='консервовані овочі і гриби';
            c('броколі заморожена', 'шпінат заморожений')='овочі заморожені';
            c('печиво здобне', 'печиво затяжне','шоколад', 'цукати', 'вафлі','мед','зефір','морозиво','карамель','цукерки шоколадні', 'торти')='солодощі';
            c('сухофрукти')='сухофрукти';
            c('пиво', 'вино біле сухе', 'вино червоне сухе', 'горілка', 'ром', 'віскі', 'шампанське', 'коньяк')='алкоголь';
            c('паста томатна', 'кетчуп томатний', 'майонез', 'сіль')='соуси та спеції';
            c('сигарети з фільтром медіум класу', 'сигарети з фільтром преміум класу')='сигарети'
            ")) %>% 
  rename(name = subsection) 

# mode_dictionary = infliation %>%
#   filter(month == as.Date("2021-12-01")) %>%
#   select(name, mode) %>%
#   unique() %>%
#   write.csv("/home/yevheniia/git/food_prices/data/mode_dictionary.csv")

# write.csv(infliation, "/home/yevheniia/git/food_prices/data/cpi_q1_median_january_2022.csv")



# ======================================================
months = c("Липень", "Серпень", "Вересень", "Жовтень", "Листопад")
replacement = c("2021-07-01", "2021-08-01", "2021-09-01", "2021-10-01", "2021-11-01")


df = infliation%>% 
  filter(measure == "Q1") %>% 
  left_join(mode_dictionary, by="name") %>% 
  select(name, month, price, measure, mode,category) %>% 
  rename(item = name)  
  
  # group_by(item) %>% 
  # arrange(desc(month)) %>% 
  # # mutate(inflation_dynamic = paste0(formatC((price - lag(price))*100/lag(price), digits = 2))) %>% 
  # ungroup() %>% 
  # mutate(inflation_dynamic = as.numeric(inflation_dynamic)+100) %>% 
  # mutate(inflation_dynamic = ifelse(is.na(inflation_dynamic), 100, inflation_dynamic)) %>% 
  # group_by(item) %>% 
  # arrange(month) %>% 
  # mutate(inflation = paste0(formatC((price - lag(price))*100/lag(price), digits = 2))) %>% 
  # ungroup() %>% 
  # mutate(inflation = as.numeric(inflation)+100) %>% 
  # mutate(inflation = ifelse(is.na(inflation), 100, inflation)) 
  

setwd("/home/yevheniia/git/food_prices/data/govstat_xlsx/")
govstat_prices = read.csv("govstat_ціни.csv", skip=2) %>% select(-1) %>% 
  gather(2:6, key="month", value="price") %>% 
  separate(X.1, c("product", "weight"), sep="\\(", remove=F) %>% 
  select(-product) %>% 
  mutate(price = gsub(',', ".", price),
         price = as.numeric(price)) %>% 
  rename(`item` = `X.1`) %>% 
  filter(item != "") %>% 
  mutate(item = tolower(item),
         item = gsub(" \\(\\d.*", "", item),
         item = trimws(item),
         month = str_replace_all(month, setNames(replacement, months))
         ) %>% 
  
  # деякі продуктти держстат рахує у вазі від 100гр до 0.75 л., 
  # через це перераховуємо вагу на кг, щоб можна було їх порівнювати
  mutate(weight = gsub("\\)", "", weight ),
         weight = gsub('[А-Яа-я]', "", weight),
         weight = gsub(',', ".", weight),
         weight = as.numeric(weight), 
         weight = ifelse(weight < 1, weight*1000, weight),
         weight = ifelse(is.na(weight), 1000, weight),
         price = price * (1000/weight)
         )  %>% 
  select(-weight)
  
# на основі даних по інфляції доповнюємо ціни за 2017-2020 рр.
govstat_prices_supplement = read.csv("ІСЦ 2017-2021.csv", stringsAsFactors = F) %>% 
  select(item, contains("10.01")) %>% 
  mutate(item = tolower(item),
         item = trimws(item)) %>% 
  left_join(govstat_prices %>% 
              filter(month == "2021-10-01") %>% 
              select(-month) %>% 
              rename(`2021-10-01` = price), by='item') %>% 
  mutate_at(c(2:6), parse_number, locale = locale(decimal_mark = ",")) %>% 
  mutate(`2020-10-01` = (`2021-10-01`/X2021.10.01) * 100,
         `2019-10-01` = (`2020-10-01`/X2020.10.01) * 100,
         `2018-10-01` = (`2019-10-01`/X2019.10.01) * 100,
         `2017-10-01` = (`2018-10-01`/X2018.10.01) * 100,
         ) %>% 
  select(1,7:11) %>% 
  gather(2:6, key="month", value="price") %>% 
  rbind(govstat_prices) %>% 
  unique() %>% 
  mutate(measure = "govstat") %>% 
  # group_by(item) %>% 
  # arrange(desc(month)) %>% 
  # mutate(inflation_dynamic = paste0(formatC((price - lag(price))*100/lag(price), digits = 2))) %>% 
  # ungroup() %>% 
  # mutate(inflation_dynamic = as.numeric(inflation_dynamic)+100) %>% 
  filter(!is.na(price))
  # mutate(inflation_dynamic = ifelse(is.na(inflation_dynamic), 100, inflation_dynamic))

df = df %>% bind_rows(govstat_prices_supplement) %>% 
  rename(name = item)

products = c("молоко пастеризоване жирністю до 2,6% включно", 
             "молоко з підвищеним вмістом жиру",
             "сметана жирністю до 15% включно", 
             "сметана з підвищеним вмістом жиру", 
             "ковбаси варені вищого ґатунку", 
             "ковбаси варені першого ґатунку",
             "сосиски, сардельки вищого ґатунку",
             "сосиски, сардельки першого ґатунку",
             "вироби з м’яса делікатесні",
             "яйця",
             "сигарети з фільтром преміум класу",
             "сигарети з фільтром медіум класу"
)

replacement_products = c("молоко 2.5%", 
             "молоко 3.2%",
             "сметана 10-15%",
             "сметана 20%+", 
             "ковбаси варені в/ґ", 
             "ковбаси варені 1/ґ",
             "сосиски, сардельки в/ґ",
             "сосиски, сардельки 1/ґ",
             "м’ясні делікатеси",
             "яйця, шт.",
             "сигарети преміум класу, пачка",
             "сигарети медіум класу, пачка"
                         
)

#TODO: переробити яця та сигарети так, щоб не перераховувати вагу на штуки
df2 = df %>% 
  mutate(short_name = str_replace_all(name, setNames(replacement_products, products))) %>% 
  # виключаємо ці продукти тимчасово, у скрипт, що буде додавати продукти повернути ці товари
  filter(short_name != "авокадо" & short_name != "ягоди" & short_name != "кавуни" & short_name != "виноград") %>% 
  left_join(read.csv("/home/yevheniia/git/food_prices/data/category_picture_pair.csv"), by="category") %>% 
  mutate(step = 0.1,
         step = ifelse(short_name =="яйця, шт.", 10, 
                       ifelse(short_name =="сигарети преміум класу, пачка" | short_name =="сигарети медіум класу, пачка", 1, step)),
         mode = ifelse(short_name =="яйця, шт.", 10, mode),
         price = ifelse(short_name =="яйця, шт.", price/10, price),
         ) %>% 
  filter(as.Date(month) < as.Date("2022-02-01"))

setwd("/home/yevheniia/git/food_prices/data/")
write.csv(df2, "cpi_q1_median_january_2022_and_govstat_history.csv", row.names = F)





# common = intersect(cpi$item, df$name)









#==============================================================
# перевірка цін, які показує держстат із цінами з супермаркету
#==============================================================

item_amount = data %>% filter(time == "2021-11-17") %>% 
  group_by(subsection) %>% 
  mutate(sample = n()) %>% 
  ungroup() %>% 
  select(subsection, sample) %>% 
  rename(item = subsection) %>% 
  unique()

# Дані держстату
setwd("/home/yevheniia/git/food_prices/data/govstat_xlsx/")
govstat_prices = read.csv("govstat_ціни.csv", skip=2) %>% select(-1) %>% 
  gather(2:6, key="month", value="price") %>% 
  mutate(price = gsub(',', ".", price),
         price = as.numeric(price)) %>% 
  rename(`item` = `X.1`) %>% 
  filter(item != "")

govstat_cpi = read.csv("govstat_ІСЦ.csv", skip=2) %>% select(-1) %>% 
  gather(2:6, key="month", value="cpi") %>% 
  mutate(cpi = gsub(',', ".", cpi),
         cpi = as.numeric(cpi)) %>% 
  rename(`item` = `X.1`) %>% 
  filter(item != "")

# dictionary replacement
months = c("Липень", "Серпень", "Вересень", "Жовтень", "Листопад")
replacement = c("2021-07-01", "2021-08-01", "2021-09-01", "2021-10-01", "2021-11-01")

govstat_data = govstat_prices %>% 
  left_join(govstat_cpi, cpi=c("item", "month")) %>% 
  mutate(month = str_replace_all(month, setNames(replacement, months))) %>% 
  separate(item, c("product", "weight"), sep="\\(", remove=F) %>% 
  select(-product) %>% 
  mutate(weight = gsub("\\)", "", weight ),
         weight = gsub('[А-Яа-я]', "", weight),
         weight = gsub(',', ".", weight),
         weight = as.numeric(weight), 
         weight = ifelse(weight < 1, weight * 1000, weight),
         item = gsub(" \\(\\d.*", "", item),
         month = as.Date(month),
         item = tolower(item))

ashan_data_price = infliation_q1 %>% 
  select(-inflation) %>% 
  spread(key="measure", value="value") %>%  
  rename(price_min = min, price_q1 = Q1, item = name) 

ashan_data_cpi = infliation_q1 %>% 
  select(-value) %>% 
  spread(key="measure", value="inflation") %>%  
  rename(cpi_min = min, cpi_q1 = Q1, item = name) %>% 
  mutate(cpi_min = cpi_min + 100, cpi_q1 = cpi_q1 + 100)


###########################
# Порівняння цін
###########################
products = c("молоко пастеризоване жирністю до 2,6% включно", 
             "молоко з підвищеним вмістом жиру",
             "сметана жирністю до 15% включно", 
             "сметана з підвищеним вмістом жиру", 
             "ковбаси варені вищого ґатунку", 
             "ковбаси варені першого ґатунку",
             "сосиски, сардельки вищого ґатунку",
             "сосиски, сардельки першого ґатунку",
             "вироби з м’яса делікатесні"
)

replacement_products = c("молоко 2.5%", 
                         "молоко 3.2%",
                         "сметана 10-15%",
                         "сметана 20%+", 
                         "ковбаси варені в/ґ", 
                         "ковбаси варені 1/ґ",
                         "сосиски, сардельки в/ґ",
                         "сосиски, сардельки 1/ґ",
                         "м’ясні делікатеси"
                         
)

static_chart_data = govstat_data %>% 
  left_join(ashan_data_price, by=c("item", "month")) %>%
  left_join(ashan_data_cpi, by=c("item", "month")) %>% 
  left_join(item_amount, by="item") %>% 
  filter(sample > 10) %>% 
  mutate(item = str_replace_all(item, setNames(replacement_products, products))) %>% 
  mutate(price_min = ifelse(!is.na(weight), price_min/1000 * weight, price_min)) %>% 
  mutate(price_q1 = ifelse(!is.na(weight), price_q1/1000 * weight, price_q1)) %>% 
  filter(item %in% c('апельсини', 'борошно пшеничне', 'горілка', 'морозиво', 'кава мелена', 'картопля', 'ковбаси варені 1ґ', 'ковбаси варені вґ', 'мед', 'молоко 3.2%', 'молоко 2.5%', 'сухофрукти', 'яловичина', 'свинина', 'сметана 10-15%', 'філе куряче', 'цукерки шоколадні',
'олія соняшникова', 'олія оливкова', 'цукор', 'морепродукти', 'яблука', 'сосиски, сардельки вґ', 'рис')) %>% 
  select(-category.x, -category.y)



write.csv(static_chart_data, "/home/yevheniia/git/food_prices/data/govstat_market_compare_prices.csv", row.names = F)




# Довірчий інтервал
quantile(rice$price_kg, c(.25, .50, .75)) 