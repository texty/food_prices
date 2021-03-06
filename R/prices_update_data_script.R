library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(stringr)
library(gridExtra)
library(grid)
library(magick)
library(scales)

# dir with this script as default
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

# скріпт з функцією розподілу категорій на основі споживчого набору
source("function_detect_product.R")

# скріпт, що приєднує пропущенні значення категорії
source("function_restore_sections_value.R")

mode_dictionary = read.csv("/home/yevheniia/git/food_prices/data/mode_dictionary.csv", stringsAsFactors = F) %>% 
   select(-X)

input_data = read.csv("food_prices_fixed_jan_22_full_month.csv", header=FALSE, stringsAsFactors = FALSE) %>% 
   filter(V1 == "Ашан")  %>% 
   mutate(V12 = as.Date(V12, format="%d-%m-%Y")) %>% 
   filter(V12 >= format(as.Date(Sys.Date()), "%Y-%m-01")) %>% 
   unique() %>% 
   select(1:12)

df = restore_sections_value(input_data) %>%
   mutate(month = format(as.Date(time), "%Y-%m-01")) %>%
   group_by(month, subsection) %>%
   mutate(Q1 = quantile(price_kg, prob = .25, na.rm = TRUE)) %>%
   ungroup() %>%
   rename(name = subsection) %>% 
   left_join(mode_dictionary, by="name") %>% 
   distinct(name, month, .keep_all = TRUE) %>%
   gather(key = "measure", value = "price", Q1 ) %>% 
   select(name, month, price, measure, mode) %>% 
   mutate(category = car::recode(name,"
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
            ")) 


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
   filter(short_name != "авокадо") %>% 
   left_join(read.csv("/home/yevheniia/git/food_prices/data/category_picture_pair.csv"), by="category") %>% 
   mutate(step = 0.1, 
          step = ifelse(short_name =="яйця, шт.", 10, 
                        ifelse(short_name =="сигарети преміум класу, пачка" | 
                                  short_name =="сигарети медіум класу, пачка", 1,
                               step)),
          price = ifelse(short_name =="яйця, шт.", price/10, price),
   ) 

# setwd("/home/yevheniia/git/food_prices/data/")
# write.csv(df2, "cpi_q1_median_january_2022_and_govstat_history.csv", row.names = F)
