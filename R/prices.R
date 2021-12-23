library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(stringr)
library(gridExtra)
library(grid)
library(magick)
library(scales)

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

# ====================================
# ============= ASHAN ================
# ====================================

# year_19 = read.csv("/home/yevheniia/python/food_prices_arviched_data/ashan/ashan-09-11-2019.csv", sep=";", stringsAsFactors = FALSE)
#year_20 = read.csv("/home/yevheniia/python/food_prices_arviched_data/ashan/ashan-18-05-2020.csv", sep=";", stringsAsFactors = FALSE)
year_21 = read.csv("food_prices_19_11_21.csv", header=FALSE, stringsAsFactors = FALSE) %>% 
  bind_rows(read.csv("food_prices_august_2021.csv")) %>% 
  filter(V1 == "Ашан")  %>% 
  mutate(V12 = as.Date(V12, format="%d-%m-%Y")) %>% 
  unique()

# last_day = as.character(new_data$V12[1])
# last_day =  gsub("-", "_", last_day)

data = restore_sections_value(year_21)


setwd('/home/yevheniia/python/food_prices_arviched_data/ashan/')
dataFiles <- list.files(pattern = "*.csv") %>% 
  lapply(read.csv, sep=";", stringsAsFactors=F) %>% 
  bind_rows %>% 
  mutate(product = tolower(product)) %>% 
  mutate(product = sub(",", "\\.", product),
         weight_value = str_extract(product, "[\\d]{1,4}(?=(г|кг|мл|л|шт)$)|0\\.[\\d]{1,2}(?=(г|кг|мл|л|шт)$)"),
         weight_unit = tolower(str_extract(product, "(?<=[\\d]{1,4})(г|кг|мл|л|шт)"))) %>% 
  mutate(weight_value = ifelse(str_detect(price, "кг"), 1, weight_value),
         weight_unit = ifelse(str_detect(price, "кг"), "кг", weight_unit)) %>% 
  mutate(price = sub("\\s.*", "", price))%>% 
  filter(!is.na(weight_value)) %>% 
  mutate(price =  as.numeric(price),
         weight_value = as.numeric(weight_value),
         price_kg = ifelse(weight_unit == "г", (price/weight_value * 1000), 
                           ifelse(weight_unit == "кг" & weight_value == 1, price,
                                  ifelse(weight_unit == "кг" & weight_value > 1, (price / weight_value),
                                         ifelse(weight_unit == "мл", (price/weight_value * 1000),
                                                ifelse(weight_unit == "л" & weight_value == 1, price,
                                                       ifelse(weight_unit == "л" & weight_value > 1, (price / weight_value),
                                                              ifelse(weight_value < 1, (price / weight_value),
                                                                     ifelse(weight_unit == "шт", price,
                                                                            NA))))))))) %>% 
  mutate(month = format(as.Date(time, format="%d-%m-%Y"), "%Y-%m")) %>% 
  mutate(subsection = detect_product_ru(section,product)) 



# median = data %>%
#   mutate(month = format(as.Date(time), "%Y-%m")) %>%
#   select(
#     id,
#     product,
#     price,
#     section,
#     time,
#     weight_value,
#     weight_unit,
#     price_kg,
#     month,
#     subsection
#   ) %>%
#   group_by(month, subsection) %>%
#   mutate(median = median(price_kg)) %>%
#   ungroup() %>%
#   select(section, subsection, month, median) %>%
#   unique() %>%
#   rename(value = median) %>%
#   mutate(measure = "median",
#          month = as.Date(paste0(month, "-01"), format = "%Y-%m-%d"))

min = data %>%
  mutate(month = format(as.Date(time), "%Y-%m")) %>%
  select(
    id,
    product,
    price,
    section,
    time,
    weight_value,
    weight_unit,
    price_kg,
    month,
    subsection
  ) %>%
  group_by(month, subsection) %>%
  mutate(median = min(price_kg)) %>%
  ungroup() %>%
  select(subsection, month, median) %>%
  unique() %>%
  rename(value = median) %>%
  mutate(measure = "min",
         month = as.Date(paste0(month, "-01"), format = "%Y-%m-%d"))


q1 = data %>%
  mutate(month = format(as.Date(time), "%Y-%m")) %>%
  select(
    id,
    product,
    price,
    section,
    time,
    weight_value,
    weight_unit,
    price_kg,
    month,
    subsection
  ) %>%
  # rbind(dataFiles) %>%
  group_by(month, subsection) %>%
  mutate(q_1 = quantile(price_kg, prob = .25, na.rm = TRUE)) %>%
  ungroup() %>%
  select(subsection, month, q_1) %>%
  unique() %>%
  rename(value = q_1) %>%
  mutate(measure = "Q1",
         month = as.Date(paste0(month, "-01"), format = "%Y-%m-%d"))




infliation_q1 = q1 %>% 
  bind_rows(min) %>% 
  filter(month != as.Date("2020-02-01")) %>% 
  group_by(subsection, measure) %>% 
  arrange(month) %>% 
  mutate(inflation = paste0(formatC((value - lag(value))*100/lag(value), digits = 2))) %>% 
  ungroup() %>% 
  mutate(inflation = as.numeric(inflation)) %>% 
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



write.csv(infliation_q1, "/home/yevheniia/git/food_prices/data/cpi_q1_median_november_2021.csv")



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
  rename(price_min = min, price_q1 = Q1, item = subsection) 

ashan_data_cpi = infliation_q1 %>% 
  select(-value) %>% 
  spread(key="measure", value="inflation") %>%  
  rename(cpi_min = min, cpi_q1 = Q1, item = subsection) %>% 
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
                         "ковбаси варені вґ", 
                         "ковбаси варені 1ґ",
                         "сосиски, сардельки вґ",
                         "сосиски, сардельки 1ґ",
                         "м’ясні делікатеси"
                         
                         )

static_chart_data = govstat_data %>% 
  left_join(ashan_data_price, by=c("item", "month")) %>%
  left_join(ashan_data_cpi, by=c("item", "month")) %>% 
  left_join(item_amount, by="item") %>% 
  filter(sample > 10) %>% 
  mutate(item = str_replace_all(item, setNames(replacement_products, products))) %>% 
  mutate(price_min = ifelse(!is.na(weight), price_min/1000 * weight, price_min)) %>% 
  mutate(price_q1 = ifelse(!is.na(weight), price_q1/1000 * weight, price_q1))

plot = ggplot(static_chart_data)+
  geom_line(mapping=aes(x=month, y=price_q1), color = '#000080')+
  geom_line(mapping=aes(x=month, y=price_min), color = '#7CB3C5')+
  geom_line(mapping=aes(x=month, y=price), color = '#D7005C')+
  facet_wrap(~item, 
             scales="free_y",
             ncol=7)+
  labs(title="Ціни на продукти харчування: у супермаркеті та підрахунках держстату", y="", x="")+
  scale_colour_manual(name = '', values =c('govstat'='red', 'Q1'='green','median'='blue'), labels = c('держстат','Ашан Q1', "Ашан median"))+
  theme_minimal()+
  theme(
    axis.text.y = element_blank(),
    panel.grid = element_blank(),
    strip.text = element_text(color="#333333")
    
  )

cowplot::ggdraw(plot) + 
  theme(plot.background = element_rect(fill="white", color = NA))
  
# Порівняння інфляцій
ggplot(static_chart_data)+
  geom_line(mapping=aes(x=month, y=cpi_q1), color = '#4484B4')+
  geom_line(mapping=aes(x=month, y=cpi), color = '#D05763')+
  facet_wrap(~item, 
             # scales="free_y",
             ncol=5)+
  scale_y_continuous(limits=c(80, 120))+
  labs(title="Інфляція за категоріями товарів: порівняння")+
  scale_colour_manual(name = '', values =c('govstat'='red', 'Q1'='green','median'='blue'), labels = c('держстат','Ашан Q1', "Ашан median"))+
  theme_minimal()












# Довірчий інтервал
quantile(rice$price_kg, c(.25, .50, .75)) 


# ======================================================



library(readr)
setwd("/home/yevheniia/git/food_prices/data/")
df = read.csv("cpi_q1_median_november_2021.csv", stringsAsFactors = F) %>% 
  rename(item = name) %>% 
  rename(price = value)

setwd("/home/yevheniia/git/food_prices/data/govstat_xlsx/")
cpi = read.csv("ІСЦ 2017-2021.csv", stringsAsFactors = F) %>% 
  select(item, contains("10.01")) %>% 
  mutate(item = tolower(item)) %>% 
  left_join(df %>% 
              filter(month == "2021-11-01" & measure == "Q1") %>% 
              select(item, price) %>% 
              rename(`2021-10-01` = price), by='item'
  ) %>% 
  mutate_at(c(2:6), parse_number, locale = locale(decimal_mark = ",")) %>% 
  # mutate_at(c(2:6), as.numeric) %>% 
  mutate(`2020-10-01` = (`2021-10-01`/X2021.10.01) * 100,
         `2019-10-01` = (`2020-10-01`/X2020.10.01) * 100,
         `2018-10-01` = (`2019-10-01`/X2019.10.01) * 100,
         `2017-10-01` = (`2018-10-01`/X2018.10.01) * 100,
         ) %>% 
  select(1,7:11) %>% 
  gather(2:6, key="month", value="price") %>% 
  mutate(measure = "Q1") 

df = df %>% bind_rows(cpi) %>% 
  rename(name = item) %>% 
  select(-X)

setwd("/home/yevheniia/git/food_prices/data/")
write.csv(df, "cpi_q1_median_november_2021_and_govstat_history.csv", row.names = F)

# common = intersect(cpi$item, df$name)

