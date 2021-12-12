library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

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
# year_20 = read.csv("/home/yevheniia/python/food_prices_arviched_data/ashan/ashan-18-05-2020.csv", sep=";", stringsAsFactors = FALSE)
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



median = data %>% 
  mutate(month = format(as.Date(time), "%Y-%m")) %>%
  select(id, product,price,section,time,weight_value,weight_unit,price_kg,month,subsection) %>% 
  # rbind(dataFiles) %>% 
  group_by(month, subsection) %>%
  mutate(median = median(price_kg)) %>%
  ungroup() %>%
  select(subsection, month, median) %>%
  unique() %>%
  # spread(key = "month", value = "median") %>% 
  # select(-`2020-02`) %>% 
  rename(value = median) %>% 
  mutate(measure = "median",
         month = as.Date(paste0(month, "-01"), format="%Y-%m-%d"))

q1 = data %>% 
  mutate(month = format(as.Date(time), "%Y-%m")) %>%
  select(id, product,price,section,time,weight_value,weight_unit,price_kg,month,subsection) %>% 
  # rbind(dataFiles) %>% 
  group_by(month, subsection) %>%
  mutate(q_1 = quantile(price_kg, prob=.25, na.rm = TRUE)) %>%
  ungroup() %>%
  select(subsection, month, q_1) %>%
  unique() %>%
  # spread(key = "month", value = "q_1") %>% 
  # select(-`2020-02`) %>% 
  rename(value = q_1) %>% 
  mutate(measure = "Q1",
         month = as.Date(paste0(month, "-01"), format="%Y-%m-%d")) 


infliation_q1 = q1 %>% 
  bind_rows(median) %>% 
  filter(month != as.Date("2020-02-01")) %>% 
  group_by(subsection, measure) %>% 
  arrange(month) %>% 
  mutate(inflation = paste0(formatC((value - lag(value))*100/lag(value), digits = 2))) %>% 
  ungroup() %>% 
  mutate(inflation = as.numeric(inflation))
  # spread(key="month", value="value") %>% 

write.csv(infliation_q1, "/home/yevheniia/Стільниця/cpi_q1_median_november_2021.csv")



#==============================================================
# перевірка цін, які показує держстат із цінами з супермаркету
#==============================================================

# Дані держстату
setwd("/home/yevheniia/python/ціни_держстату/")
govstat = read.csv("sctp_2019_u.csv", stringsAsFactors = F) %>% 
  gather(3:14, key="month", value="value") %>% 
  bind_rows(read.csv("sctp_20.csv", stringsAsFactors = F) %>% gather(3:14, key="month", value="value")) %>% 
  bind_rows(read.csv("sctp_21ue.csv", stringsAsFactors = F) %>% gather(3:14, key="month", value="value")) %>% 
  mutate(month = sub("X","", month),
         month = sub("\\.", "-", month),
         month = as.Date(paste0(month, "-01"), format="%Y-%m-%d"),
         value = sub("\\,", "\\.", value),
         value = as.numeric(value),
         subsection=tolower(trimws(subsection)),
         subsection = sub("філе куряче", "курка філе", subsection),
         subsection = sub("молоко пастеризоване жирністю до 2,6% включно", "молоко 2.5%", subsection),
         subsection = sub("сметана жирністю до 15% включно", "сметана 10-15%", subsection),
         subsection = sub("крупи гречані", "гречка", subsection),
         subsection = sub("яйця", "яйця курячі", subsection),
         subsection = sub("яловичина", "яловичина без кістки", subsection),
         subsection = sub("свинина", "свинина без кістки", subsection),
         subsection = sub("крупи манні", "манка", subsection),
         subsection = sub("ковбаси варені першого ґатунку", "ковбаса варена 1/ґ", subsection)
         ) %>% 
  mutate(value = ifelse(subsection %in% c('батон', 'горілка', 'пиво вітчизняних марок'), value *2, value)) %>% 
  group_by(subsection) %>% 
  arrange(month) %>% 
  mutate(inflation = paste0(formatC((value - lag(value))*100/lag(value), digits = 2))) %>% 
  ungroup() %>% 
  mutate(inflation = as.numeric(inflation))

# спільні категорії товарів
common_items = intersect(infliation_q1$subsection, govstat$subsection)
common_items <- common_items[! common_items %in% c('сало', 'риба морожена')]

# порівнюємо інфляцію(вже у %) на Q1 ціни, median ціни та ціни держстату 
chart_data = infliation_q1 %>% 
  bind_rows(govstat %>% 
              select(-unit) %>% 
              mutate(measure = "govstat") 
            ) %>% 
  filter(subsection %in% common_items) %>% 
  filter(month >= as.Date("2021-08-01"))


# Інфляція
ggplot()+
  geom_line(chart_data, mapping=aes(x=month, y=inflation, group=measure, color=measure))+
  scale_y_continuous(limits=c(-50, 50))+
  facet_wrap(~subsection, 
            # scales="free_y",
             ncol=5)+
  labs(title="Інфляція за категоріями товарів: порівняння")+
  scale_colour_manual(name = '', values =c('govstat'='red', 'Q1'='green','median'='blue'), labels = c('держстат','Ашан Q1', "Ашан median"))+
  theme_minimal()

# Ціни
ggplot()+
  geom_line(chart_data, mapping=aes(x=month, y=value, group=measure, color=measure))+
  # scale_y_continuous(limits=c(-50, 50))+
  facet_wrap(~subsection, 
             scales="free_y",
             ncol=5)+
  labs(title="Ціни за категоріями товарів: порівняння")+
  scale_colour_manual(name = '', values =c('govstat'='red', 'Q1'='green','median'='blue'), labels = c('держстат','Ашан Q1', "Ашан median"))+
  theme_minimal()



# Довірчий інтервал
quantile(rice$price_kg, c(.25, .50, .75)) 


# ======================================================



eggs = dataFiles %>% 
  filter(section == "яйца" & str_detect(product, "10шт") & str_detect(time, "11-2019"))

quantile(eggs$price, 0.25)






# старе
# ============== 2021 ===============

median_price_2021_by_month = data %>%
  filter(!(str_detect(product, "Авокадо") &
             weight_unit == "г")) %>%
  mutate(month = format(as.Date(time), "%Y-%m")) %>%
  group_by(month, subsection) %>%
  mutate(median = median(price_kg)) %>%
  ungroup() %>%
  select(subsection, month, median) %>%
  unique() %>%
  spread(key = "month", value = "median")





# ============== 2020 ===============

# залишаємо тільки ті id, що є у нових даних за 2021 рік, додаємо до них вагу та одиниці виміру ваги з датасету 21 року за унікальними id, також додаємо виведену категорію відповідно до споживчого набору (колонка subsection)
year_20_filtered = year_20 %>% 
  filter(id %in% intersect(year_20$id, data$id)) %>% 
  distinct(id, .keep_all = T) %>% 
  select(id, product, price)%>% 
  mutate_all(as.character) %>% 
  left_join(data %>% select(id, weight, weight_value, weight_unit, subsection, price, price_kg ) %>% rename(price_21 = price, price_kg_21 = price_kg), by="id") %>% 
  mutate(price = sub(" грн/*", "", price),
         price = sub("кг", "", price),
         price = sub("\\s.*", "", price))%>% 
  mutate(price =  as.numeric(price),
         weight_value = as.numeric(weight_value),
         price_kg = ifelse(weight_unit == "г", (price/weight_value * 1000), 
                           ifelse(weight_unit == "кг" & weight_value == 1, price,
                                  ifelse(weight_unit == "кг" & weight_value > 1, (price / weight_value),
                                         ifelse(weight_unit == "мл", (price/weight_value * 1000),
                                                ifelse(weight_unit == "л" & weight_value == 1, price,
                                                       ifelse(weight_unit == "л" & weight_value > 1, (price / weight_value),
                                                              ifelse(weight_unit == "шт", price,
                                                                     NA)))))))) %>% 
  rename(price_20 = price) %>% 
  select(id, subsection, product, weight, weight_value, weight_unit, price_kg, price_kg_21)

median_price_05_20 = year_20_filtered %>% 
  group_by(subsection) %>% 
  mutate(`2020-05` = median(price_kg)) %>% 
  ungroup() %>% 
  select(-id, -product, -weight, -weight_value, -weight_unit, -price_kg_20, -price_kg_21) %>% 
  unique() 




# ============== 2019 ==============
# тут немає id, тому залишаємо за назвами продуктів, у 2021 назви українською, тому не співпадає, а от у 2020 качала рос. назви нащастя
# приєднуємо адішники
year_19_filtered = year_19 %>% 
  filter(product %in% intersect(year_19$product, year_20_filtered$product)) %>% 
  left_join(year_20_filtered %>% select(id, subsection, product, weight, weight_value, weight_unit), by="product") %>% 
  # select(id, price) %>% 
  mutate_all(as.character) %>% 
  mutate(price = sub("\\s.*", "", price))%>% 
  unique() %>% 
  select(id, subsection, product, price, weight, weight_value, weight_unit) %>% 
  mutate(price =  as.numeric(price),
         weight_value = as.numeric(weight_value),
         price_kg = ifelse(weight_unit == "г", (price/weight_value * 1000), 
                           ifelse(weight_unit == "кг" & weight_value == 1, price,
                                  ifelse(weight_unit == "кг" & weight_value > 1, (price / weight_value),
                                         ifelse(weight_unit == "мл", (price/weight_value * 1000),
                                                ifelse(weight_unit == "л" & weight_value == 1, price,
                                                       ifelse(weight_unit == "л" & weight_value > 1, (price / weight_value),
                                                              ifelse(weight_unit == "шт", price,
                                                                     NA))))))))


median_price_11_19 = year_19_filtered %>% 
  group_by(subsection) %>% 
  mutate(`2019-11` = median(price_kg)) %>% 
  ungroup() %>% 
  select(-id, -product, -weight, -weight_value, -weight_unit, -price_kg, -price) %>% 
  unique() 





infliation = median_price_11_19 %>% 
  left_join(median_price_05_20, by="subsection") %>% 
  left_join(median_price_2021_by_month, by="subsection") 


library(readr)
setwd("/home/yevheniia/git/food_prices/data/")
df = read.csv("cpi_q1_median_november_2021.csv")

setwd("/home/yevheniia/Стільниця/")
cpi = read.csv("ІСЦ 2017-2021.csv") %>% 
  select(item, starts_with("X2021")) %>% 
  mutate(item = tolower(item))


common = intersect(cpi$item, df$name)

