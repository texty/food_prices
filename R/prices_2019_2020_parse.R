library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(ggplot2)

# dir with this script as default
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

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
   mutate(subsection = detect_product(section,product)) 
   
year_19_20 = dataFiles %>% 
   filter(!is.na(subsection)) %>% 
   group_by(month, subsection) %>%
   mutate(Q1 = quantile(price_kg, prob=.25, na.rm = TRUE),
          median = median(price_kg, na.rm = TRUE),
          Q3 = quantile(price_kg, prob=.75, na.rm = TRUE)) %>%
   ungroup() %>%
   select(subsection, month,  Q1, median, Q3) %>%
   unique() %>%
   spread(key = "month", value = c("Q1","median","Q3")) %>% 
   select(-`2020-02`)
   


# year_19 = read.csv(
#    "/home/yevheniia/python/food_prices_arviched_data/ashan/ashan-09-11-2019.csv",
#    sep = ";",
#    stringsAsFactors = FALSE
# ) %>%
#    mutate(
#       weight_value = str_extract(
#          product,
#          "([\\d]{1,4}|[\\d]{1,2}[\\.\\,][\\d]{1,2})(?=[:graph:]{1,3}$)"
#       ),
#       weight_unit = tolower(
#          str_extract(product, "(?<=[\\d]{1,4})(г|Г|кг|КГ|шт|ШТ|л|Л|мл|МЛ)")
#       )
#    ) %>%
#    mutate(
#       weight_value = ifelse(str_detect(price, "кг"), 1, weight_value),
#       weight_unit = ifelse(str_detect(price, "кг"), "кг", weight_unit)
#    ) %>%
#    mutate(price = sub("\\s.*", "", price)) %>%
#    filter(!is.na(weight_value)) %>%
#    mutate(
#       price =  as.numeric(price),
#       weight_value = as.numeric(weight_value),
#       price_kg = ifelse(
#          weight_unit == "г",
#          (price / weight_value * 1000),
#          ifelse(
#             weight_unit == "кг" & weight_value == 1,
#             price,
#             ifelse(
#                weight_unit == "кг" & weight_value > 1,
#                (price / weight_value),
#                ifelse(
#                   weight_unit == "мл",
#                   (price / weight_value * 1000),
#                   ifelse(
#                      weight_unit == "л" & weight_value == 1,
#                      price,
#                      ifelse(
#                         weight_unit == "л" & weight_value > 1,
#                         (price / weight_value),
#                         ifelse(weight_unit == "шт", price,
#                                NA)
#                      )
#                   )
#                )
#             )
#          )
#       )
#    ) %>%
#    mutate(product = tolower(product))



categories_list=c(
   ### хліб
   'хліб цільнозерновий', 'хліб пшеничний','хліб житньо-пшеничний','батон','багет',
   ### фрукти
   'апельсини', 'банани', 'яблука', 'авокадо', 'мандарини', 'виноград', 'лимони','ягоди', 'ківі', 'кавуни',
   ### овочі
   'буряк', 'кабачки', 'капуста білокачанна', 'картопля', 'морква', 'огірки', 'помідори', 'цибуля', 'часник', 'гриби', 'перець','баклажани','салат',
   ### М'ясо
   'свинина без кістки', 'свинина гуляш', 'свинина фарш', 'свинина ребра', 'яловичина без кістки', 'яловичина фарш', 'яловичина ребра','курка філе', 'курка крильця', 'курка стегно',   'курка ціла','субпродукти яловичні','субпродукти свинячі',' субпродукти курячі','сало','свиняча вирізка',
   'яловича вирізка',
   ### Ковбаси
   'сосиски в/ґ', 'сосиски 1/ґ', 'ковбаса варена в/ґ','ковбаса варена 1/ґ', 'ковбаси сирокопчені в/ґ','ковбаси варено-копчені в/ґ',
   ### М'ясні делікатеси
   "м'ясні делікатеси",
   ### Бакалія
   'вівсянка', 'рис довгозернистий', 'гречка', 'борошно пшеничне', 'макарони', 'цукор', 'сухі сніданки', 'квасоля','пшоно','манка','ячна крупа','супи',
   ### Молочка
   'молоко 2.5%', 'йогурт', 'кефір 2.5%', 'сметана 10-15%', 'сметана 20+ %',  'крем-сир', 'сир твердий', 'сир кисломолочний жирний', 'масло вершкове 82%', 'масло вершкове 73%', 'маргарин', 'молоко 3.2%', 'сир кисломолочний нежирний', 'плавлений сир', 'сири розсольні','сирки та сиркова маса','дитяча суміш',
   ### Риба
   'риба червона', 'риба річна', 'ікра червона', 'оселедець','скумбрія копчена', 'філе мороженої риби', 'риба морожена', 'консерви рибні в олії','морепродукти',
   ### Яйця
   'яйця курячі', 
   ### Олія
   'олія соняшникова', 'олія оливкова', 
   ### Безалкогольні напої
   'сік яблучний', 'сік апельсиновий', 
   ### Кава і чай
   'кава розчинна', 'кава в зернах', 'чай у пакетиках',
   ### Напівфабрикати
   'пельмені', 'вареники з картоплею',  'крабові палички', 
   ### Консерви
   'кукурудза консервована', 'горошок консервований','гриби консервовані',
   ### Морожені овочі
   'броколі заморожена', 'шпінат заморожений',
   ### Солодощі
   'печиво здобне', 'печиво затяжне','шоколад чорний', 'цукати', 'вафлі','мед','зефір','морозиво','карамель','цукерки шоколадні', 'торти',
   ### Сухофрукти
   'сухофрукти',
   ### Безалкогольні напої
   'солодка вода',
   ### Алкоголь та цигарки
   'пиво', 'вино біле сухе', 'вино червоне сухе', 'горілка', 'ром', 'віскі', 'шампанське', 'коньяк', 'цигарки',
   ### Соуси
   'томатна паста', 'кетчуп', 'майонез', 'сіль'
)


detect_product <- function(SECTION, PRODUCT) {
   ### Хліб
   `хліб цільнозерновий` = SECTION == "хлеб" & str_detect(PRODUCT, "цельнозерновой")
   `хліб пшеничний` = SECTION == "хлеб" & str_detect(PRODUCT, "пшеничн") & !str_detect(PRODUCT, "цельнозерн")  & !str_detect(PRODUCT, "ржан")
   `хліб житньо-пшеничний` = SECTION == "хлеб" & str_detect(PRODUCT, "\\bржан")
   `батон` = SECTION == "хлеб" & str_detect(PRODUCT, "батон")
   `багет` = SECTION == "хлеб" & str_detect(PRODUCT, "багет")
   
   ### фрукти
   `апельсини` =  SECTION == "фрукты" & str_detect(PRODUCT, "апельси(ни|н)\\b")
   `банани` = SECTION == "фрукты" & str_detect(PRODUCT, "^бана(ны|н)")
   `яблука` =  SECTION == "фрукты" & str_detect(PRODUCT, "ябл(о|у)к(а|о)")
   `авокадо` = SECTION == "фрукты" & str_detect(PRODUCT, "авокадо")
   `мандарини`= SECTION == "фрукты" & str_detect(PRODUCT, "мандарин")
   `виноград`= SECTION == "фрукты" & str_detect(PRODUCT, "виноград")
   `лимони`= SECTION == "фрукты" & str_detect(PRODUCT, "^лимон")
   `ягоди`= SECTION == "фрукты" & (str_detect(PRODUCT, "^голубика") | 
                                      str_detect(PRODUCT, "^малина") | 
                                      str_detect(PRODUCT, "^клубника")  | 
                                      str_detect(PRODUCT, "^смородина")) & !str_detect(PRODUCT, "морожен")
   `ківі` = SECTION == "фрукты" & str_detect(PRODUCT, "киви") & !str_detect(PRODUCT, "сушен")
   `кавуни`= SECTION == "фрукты" & str_detect(PRODUCT, "арбуз")
   
   
   
   ### овочі
   `буряк` = SECTION == "овощи" & str_detect(PRODUCT, "свекла\\b")
   `кабачки`  = SECTION == "овощи" & str_detect(PRODUCT, "кабач(ки|ок)\\b")
   `капуста білокачанна` = SECTION == "овощи" & str_detect(PRODUCT, "(К|к)апуста") & str_detect(PRODUCT, "белокач")
   `картопля` = SECTION == "овощи" & str_detect(PRODUCT, "картофель")
   `морква` = SECTION == "овощи" & str_detect(PRODUCT, "морковь")
   `огірки` = SECTION == "овощи" & str_detect(PRODUCT, "огурцы")
   `помідори` = SECTION == "овощи" & str_detect(PRODUCT, "помидоры")
   `цибуля` = SECTION == "овощи" & str_detect(PRODUCT, "лук")
   `часник` = SECTION == "овощи" & str_detect(PRODUCT, "чеснок")
   `гриби` = SECTION == "помидоры" & str_detect(PRODUCT, "шампиньон")
   `перець`= SECTION == "овощи" & str_detect(PRODUCT, "перец") & (str_detect(PRODUCT, "красный") | str_detect(PRODUCT, "капи") | str_detect(PRODUCT, "білозірка") )
   `баклажани` = SECTION == "овощи" & str_detect(PRODUCT, "баклажан")
   `салат` = SECTION == "Зелень" & str_detect(PRODUCT, "салат")
   
   
   ### мʼясо
   `свинина без кістки` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)вин") & str_detect(PRODUCT, "без кістки")
   `свинина гуляш` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)вин") & str_detect(PRODUCT, "(Г|г)уляш")
   `свинина фарш` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)вин") & str_detect(PRODUCT, "(Ф|a)арш")
   `свинина ребра` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)вин") & str_detect(PRODUCT, "(Р|р)ебра")
   `яловичина без кістки` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(Я|я)лович") & (str_detect(PRODUCT, "без кістки") | str_detect(PRODUCT, "(Ф|ф)іле") | str_detect(PRODUCT, "(С|с)тейк"))
   `яловичина фарш` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(Я|я)лович") & str_detect(PRODUCT, "(Ф|a)арш")
   `яловичина ребра` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(Я|я)лович") & str_detect(PRODUCT, "(Р|р)ебра")
   `курка філе` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(К|к)ур") & str_detect(PRODUCT, "(Ф|ф)іле")
   `курка крильця` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\b(К|к)ур") & str_detect(PRODUCT, "\\b(К|к)рил")
   `курка стегно` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\b(К|к)ур") & str_detect(PRODUCT, "(С|с)тегн")
   `курка ціла` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\b(К|к)ур") & str_detect(PRODUCT, "(Т|т)ушка")
   `субпродукти яловичі` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(Я|я)лович") & (str_detect(PRODUCT, "(Н|н)ирки") | str_detect(PRODUCT, "(П|п)ечінк")| str_detect(PRODUCT, "(Л|л)егені")|str_detect(PRODUCT, "(C|c)ерце"))
   `субпродукти свинячі` = SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)вин") & (str_detect(PRODUCT, "(Н|н)ирки") | str_detect(PRODUCT, "(П|п)ечінк")| str_detect(PRODUCT, "(Л|л)егені")|str_detect(PRODUCT, "(C|c)ерце"))
   `субпродукти курячі`= SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(К|к)ур(яч|ин)") & (str_detect(PRODUCT, "(Н|н)ирки") | str_detect(PRODUCT, "(П|п)ечінк")| str_detect(PRODUCT, "(Л|л)егені")|str_detect(PRODUCT, "(C|c)ерце"))
   `сало`= SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)ало")
   `свиняча вирізка`= SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(С|с)вин") & str_detect(PRODUCT, "\\b(В|в)ирізка")
   `яловича вирізка`= SECTION == "свежее мясо" & str_detect(PRODUCT, "\\b(Я|я)лович") & str_detect(PRODUCT, "\\b(В|в)ирізка")
   
   ### Ковбаса та сосиски
   `сосиски в/ґ` = SECTION == "колбаса и сосиски" & (str_detect(PRODUCT, "(С|с)осиск") | str_detect(PRODUCT, "(С|с)ардель")) & (str_detect(PRODUCT, "в/(ґ|г)")| str_detect(PRODUCT, "вищ.*(ґ|г)ат"))
   `сосиски 1/ґ` = SECTION == "колбаса и сосиски" & (str_detect(PRODUCT, "(С|с)осиск") | str_detect(PRODUCT, "(С|с)ардель")) & str_detect(PRODUCT, "(перш|1/ґ)")
   `ковбаса варена в/ґ` = SECTION == "колбаса и сосиски" & str_detect(PRODUCT, "(К|к)овбаса.*варена") & str_detect(PRODUCT, "вищ.*(гат|сорт|ґатун)")
   `ковбаса варена 1/ґ` = SECTION == "колбаса и сосиски" & str_detect(PRODUCT, "(К|к)овбаса.*варена") & str_detect(PRODUCT, "(перш|1/ґ)")
   `ковбаси сирокопчені в/ґ`= SECTION == "колбаса и сосиски" & str_detect(PRODUCT, "(С|с)ирокопчен") & str_detect(PRODUCT, "(вищ|в/ґ)")
   `ковбаси варено-копчені в/ґ` = SECTION == "колбаса и сосиски" & str_detect(PRODUCT, "(варен)") & str_detect(PRODUCT, "копчен")
   
   ### М'ясні делікатеси
   `м'ясні делікатеси` = SECTION == "мясные деликатесы" #& (str_detect(PRODUCT, "(Б|б)екон")|str_detect(PRODUCT, "(Х|х)амон")|str_detect(PRODUCT, "(Б|б)астурма"))
   
   ### Бакалія
   `вівсянка` = SECTION == "бакалея" & str_detect(PRODUCT, "вівсян")
   `рис` = SECTION == "бакалея" & str_detect(PRODUCT, "рис\\b") & str_detect(PRODUCT, "длиннозер") & str_detect(PRODUCT, "шлифов")
   `гречка` = SECTION == "бакалея" & str_detect(PRODUCT, "греч")
   `борошно` = SECTION == "бакалея" & str_detect(PRODUCT, "мука.*пшени") 
   `макарони` = SECTION == "бакалея" & str_detect(PRODUCT, "макарони")
   `цукор` = SECTION == "бакалея" & str_detect(PRODUCT, "сахар.*белый") 
   `сухі сніданки` = str_detect(PRODUCT, "(сух|готов) завтрак")
   `квасоля` = SECTION == "бакалея" & str_detect(PRODUCT, "\\bфасоль\\b")
   `пшоно`= SECTION == "бакалея" & str_detect(PRODUCT, "пшено")
   `манка`= SECTION == "бакалея" & str_detect(PRODUCT, "манная")
   `ячна`= SECTION == "бакалея" & str_detect(PRODUCT, "ячневая")
   `суп`= SECTION == "бакалея" & str_detect(PRODUCT, "\\b(С|с)уп\\b")
   
   
   ### Молочка
   `молоко 2.5%` = SECTION == "молоко" & str_detect(PRODUCT, "ультрапастеризованное.*2(.|,)5%") 
   `йогурт` = SECTION == "йогурт" & str_detect(PRODUCT, "Йогурт") & !str_detect(PRODUCT, "(К|к)окосовый") & !str_detect(PRODUCT, "(С|с)оевый")
   `кефір` = SECTION == "кисломолочные напитки" & str_detect(PRODUCT, "кефир") & str_detect(PRODUCT, "2(.|,)5%")
   `сметана 10-15%` = SECTION == "сметана" & str_detect(PRODUCT, "сметана.*(10|15)%")
   `сметана 20+ %` = SECTION == "сметана" & str_detect(PRODUCT, "сметана.*(2[\\d]|3[\\d])%")
   `крем-сир` = SECTION == "сыр" & str_detect(PRODUCT, "(К|к)рем-сыр")
   `сир твердий` = SECTION == "сыр" & str_detect(PRODUCT, "сыр") & str_detect(PRODUCT, "\\bтвердый")
   `сир кисломолочний жирний` = SECTION == "творог" & str_detect(PRODUCT, "творог") & str_detect(PRODUCT, "[6-9][0-9]{0,1},{0,1}[\\d]{0,1}%")
   `масло вершкове 82%` = SECTION == "масло и маргарин" & str_detect(PRODUCT, "масло.*сливочн.*82.*%")
   `масло вершкове спред` = SECTION == "масло и маргарин" & str_detect(PRODUCT, "масло.*7[\\d][,.]{0,1}[\\d]{0,1}%")
   `маргарин` = SECTION == "масло и маргарин" & str_detect(PRODUCT, "маргарин\\b.*7.*%")
   `молоко 3.2%` = SECTION == "молоко" & str_detect(PRODUCT, "ультрапастеризованное.*3(.|,)[\\d]%") 
   `сир кисломолочний нежирний` = SECTION == "творог" & str_detect(PRODUCT, "творог") & str_detect(PRODUCT, "[0-5],{0,1}[\\d]{0,1}%")
   `плавлений сир` = SECTION == "сыр" & str_detect(PRODUCT, "сыр.*плавленый")
   `сири розсольні` = SECTION == "сыр" & (str_detect(PRODUCT, "(М|м)оцаре")| str_detect(PRODUCT, "(С|с)улугун")| str_detect(PRODUCT, "фета\\b")| str_detect(PRODUCT, "бр(ы|и)нза"))
   `сирки та сиркова маса`= SECTION == "творог" & (str_detect(PRODUCT, "маса") | str_detect(PRODUCT, "сырок"))
   `дитяча суміш` = SECTION == "био товары" & str_detect(PRODUCT, "молочная") & str_detect(PRODUCT, "смесь")
   
   ### риба
   `риба червона філе` = SECTION == "свежая рыба" & (str_detect(PRODUCT, "лосось") | str_detect(PRODUCT, "сьомга") | str_detect(PRODUCT, "форель")) & str_detect(PRODUCT, "((Ф|ф)іле|(С|с)тейк|\\bціл)")
   `риба річна` = SECTION == "свежая рыба" & (str_detect(PRODUCT, "(Т|т)овстолоб") | str_detect(PRODUCT, "(К|к)ороп"))
   `ікра червона` = SECTION == "морепродукты" & str_detect(PRODUCT, "(и|і)кра.*лосос") & !str_detect(PRODUCT, "белковая") & !str_detect(PRODUCT, "імітован")
   `оселедець` = SECTION == "приготовленная рыба" & str_detect(PRODUCT, "(О|о)селедець")
   `скумбрія копчена` = SECTION == "приготовленная рыба" & str_detect(PRODUCT, "скумбр(и|і)я") & str_detect(PRODUCT, "копчен")
   `філе мороженої риби` = SECTION == "риба" & str_detect(PRODUCT, "филе") & str_detect(PRODUCT, "морож")
   `риба морожена` = SECTION == "рыба" & str_detect(PRODUCT, "мороже") & !str_detect(PRODUCT, "филе") & !str_detect(PRODUCT, "фарш")
   `консерви рибні в олії`= SECTION == "консервированное мясо и рыба" & str_detect(PRODUCT, "в масле")
   `морепродукти`= SECTION == "морепродукты" & !str_detect(PRODUCT, "(и|і)кра") & !str_detect(PRODUCT, "краб.*палоч")
   
   ### Яйця
   `яйця курячі` = SECTION == "яйца" & str_detect(PRODUCT, "курин")
   
   ### Олія
   `олія соняшникова` = SECTION == "масло и уксус" & str_detect(PRODUCT, "подсолнечное")
   `олія оливкова` = SECTION == "масло и уксус" & str_detect(PRODUCT, "оливковое")
   
   ### Безалкогольні напої
   `сік яблучний` = SECTION == "сок" & str_detect(PRODUCT, " яблочний")
   `сік апельсиновий` = SECTION == "сок" & str_detect(PRODUCT, " апельсиновый")
   
   ### Кава і чай
   `кава розчинна` = SECTION == "кофе" & str_detect(PRODUCT, "растворимый") & !str_detect(PRODUCT, "3в1")
   `кава в зернах` = SECTION == "кофе" & str_detect(PRODUCT, "(в зернах|зерновой)")
   `чай у пакетиках` = SECTION == "чай" & str_detect(PRODUCT, "пакетиках") & str_detect(PRODUCT, "25")
   
   ### Напівфабрикати
   `пельмені` = SECTION == "полуфабрикаты" & str_detect(PRODUCT, "пельмени")
   `вареники` =  SECTION == "полуфабрикаты" & str_detect(PRODUCT, "вареники") & str_detect(PRODUCT, "(картошк|картопл)")
   `крабові палички` = SECTION == "полуфабрикаты" & str_detect(PRODUCT, "крабов")& str_detect(PRODUCT, "палочки") 
   
   ### Консерви
   `кукурудза консервована` = SECTION == "консервированные фрукты и овощи" & str_detect(PRODUCT, "кукуруза")
   `горошок консервований` = SECTION == "консервированные фрукты и овощи" & str_detect(PRODUCT, "горошок")
   `гриби консервовані` = SECTION == "консервированные фрукты и овощи" & (str_detect(PRODUCT, "грибы")| str_detect(PRODUCT, "шамп") | str_detect(PRODUCT, "маслюки"))
   
   ### Заморожені овочі
   `броколі заморожена` = SECTION == "овощи и грибы" & str_detect(PRODUCT, "брокколи") & str_detect(PRODUCT, "заморож")
   `шпінат заморожений` = SECTION == "овощи и грибы" & str_detect(PRODUCT, "шпинат") & str_detect(PRODUCT, "заморож")
   
   ### Солодощі
   `печиво здобне` = SECTION == "печенье, кексы, пирожные" & str_detect(PRODUCT, "(П|п)ечиво") & str_detect(PRODUCT, "(З|з)добне")
   `печиво затяжне` = SECTION == "печенье, кексы, пирожные" & str_detect(PRODUCT, "(П|п)ечиво") & str_detect(PRODUCT, "(З|з)атяжне")
   `шоколад чорний` = SECTION == "шоколад, конфеты, жвачки" & str_detect(PRODUCT, "(Ш|ш)околад") & str_detect(PRODUCT, "черний")
   `цукати`= SECTION == "сухофрукты" & str_detect(PRODUCT, "(Ц|ц)укати")
   `вафлі` = SECTION == "печенье, кексы, пирожные" & str_detect(PRODUCT, "вафли")
   `мед`= SECTION == "джем и мед" & str_detect(PRODUCT, "^Мед\\b")
   `зефір` = SECTION == "шоколад, конфеты, жвачки" & str_detect(PRODUCT, "зефир")
   `морозиво` = str_detect(SECTION, "мороженое")
   `карамель` = SECTION == "шоколад, конфеты, жвачки" & str_detect(PRODUCT, "карамель")
   `цукерки шоколадні` = SECTION == "Кондитерські вироби" & str_detect(PRODUCT, "конфеты") & str_detect(PRODUCT, "шоколадные")
   `торти` = SECTION == "торты и пирожные" & str_detect(PRODUCT, "торт\\b")
   
   # 
   
   ### Сухофрукти
   `сухофрукти` = SECTION == "сухофрукты" & (str_detect(PRODUCT, "курага")| 
                                                str_detect(PRODUCT, "абрикос")| 
                                                str_detect(PRODUCT, "чернослив")| 
                                                str_detect(PRODUCT, "изюм")| 
                                                str_detect(PRODUCT, "клюква")
   )
   ### Безалкогольні напої
   `солодка вода` = SECTION == "сладкая вода"
   
   ### Алкоголь та цигарки
   `пиво` = str_detect(PRODUCT, "\\bпиво\\b")
   `вино біле сухе` = str_detect(PRODUCT, "вино") & str_detect(PRODUCT, "\\bсухое") & str_detect(PRODUCT, "белое")
   `вино червоне сухе` = str_detect(PRODUCT, "вино") & str_detect(PRODUCT, "\\bсухое") & str_detect(PRODUCT, "красное")
   `горілка` = str_detect(PRODUCT, "водка")
   `ром` = str_detect(PRODUCT, "\\bром\\b")
   `віскі` = str_detect(PRODUCT, "\\bвиски\\b")
   `шампанське` = str_detect(PRODUCT, "шампанское")
   `коньяк` = str_detect(PRODUCT, "коньяк")
   `цигарки` = SECTION == "сигареті"
   
   ### Соуси
   `томатна паста` = SECTION == "соусы и специи" & str_detect(PRODUCT, "томатна") & str_detect(PRODUCT, "паста")
   `кетчуп`= SECTION == "соусы и специи" & str_detect(PRODUCT, "кетчуп")
   `майонез`= SECTION == "соусы и специи"  & str_detect(PRODUCT, "майонез")
   `сіль`= SECTION == "соусы и специи" & str_detect(PRODUCT, "\\bсоль\\b")
   
   # тут усе повинно бути в тому самому порядку що і у religions_list
   vector = str_c(sep=",", 
                  ### Хліб
                  `хліб цільнозерновий`,`хліб пшеничний`,`хліб житньо-пшеничний`,`батон`,`багет`,
                  
                  ### Фрукти
                  `апельсини`, `банани`, `яблука`, `авокадо`, `мандарини`, `виноград`,`лимони`,`ягоди`,`ківі`,`кавуни`,
                  
                  ### Овочі
                  `буряк`, `кабачки`, `капуста білокачанна`, `картопля`, `морква`, `огірки`, `помідори`, `цибуля`, `часник`, `гриби`,`перець`,`баклажани`,`салат`,
                  
                  ### Мʼясо
                  `свинина без кістки`, `свинина гуляш`, `свинина фарш`, `свинина ребра`, `яловичина без кістки`, `яловичина фарш`, `яловичина ребра`, 
                  `курка філе`, `курка крильця`, `курка стегно`,`курка ціла`,`субпродукти яловичі`,`субпродукти свинячі`,`субпродукти курячі`,`сало`,`свиняча вирізка`,
                  `яловича вирізка`,
                  
                  ### Ковбаси
                  `сосиски в/ґ`,`сосиски 1/ґ`, `ковбаса варена в/ґ`,`ковбаса варена 1/ґ`,`ковбаси сирокопчені в/ґ`,`ковбаси варено-копчені в/ґ`,
                  
                  ### Мʼясні делікатеси
                  `м'ясні делікатеси`,
                  
                  ### Бакалія
                  `вівсянка`, `рис`, `гречка`, `борошно`,`макарони`,`цукор`, `сухі сніданки`, `квасоля`,`пшоно`,`манка`,`ячна`,`суп`,
                  
                  ### Молочка
                  `молоко 2.5%`, `йогурт`, `кефір`, `сметана 10-15%`, `сметана 20+ %`, `крем-сир`,`сир твердий`, `сир кисломолочний жирний`, `масло вершкове 82%`, `масло вершкове спред`, 
                  `маргарин`, `молоко 3.2%`, `сир кисломолочний нежирний`, `плавлений сир`,`сири розсольні`,`сирки та сиркова маса`, `дитяча суміш`,
                  
                  ### Риба
                  `риба червона філе`,`риба річна`,`ікра червона`, `оселедець`,`скумбрія копчена`, `філе мороженої риби`,`риба морожена`, `консерви рибні в олії`,`морепродукти`,
                  
                  ### Яйця
                  `яйця курячі`,
                  
                  ### Олія, жири
                  `олія соняшникова`,`олія оливкова`,
                  
                  ### Напої безалкогольні
                  `сік яблучний`,`сік апельсиновий`,
                  
                  ### Кава і чай
                  `кава розчинна`, `кава в зернах`, `чай у пакетиках`, 
                  
                  ### Напівфабрикати
                  `пельмені`, `вареники`,`крабові палички`,
                  
                  ### Консерви
                  `кукурудза консервована`, `горошок консервований`, `гриби консервовані`,
                  
                  ### Заморожені овочі
                  `броколі заморожена`, `шпінат заморожений`,
                  
                  ### Солодощі
                  `печиво здобне`, `печиво затяжне`, `шоколад чорний`,`цукати`,`вафлі`,`мед`,`зефір`,`морозиво`,`карамель`,`цукерки шоколадні`,`торти`,
                  
                  ### Сухофрукти
                  `сухофрукти`,
                  
                  ### Безалкогольні напої
                  `солодка вода`,
                  
                  ### Алкоголь та цигарки
                  `пиво`, `вино біле сухе`, `вино червоне сухе`, `горілка`, `ром`, `віскі`, `шампанське`, `коньяк`, `цигарки`,
                  
                  ### Соуси
                  `томатна паста`, `кетчуп`,`майонез`,`сіль`
   )
   
   
   
   type = vector %>% purrr::map(function(str){
      type1 = str_which(str, "TRUE")
      indices = (str %>% str_split(",") %>% unlist == "TRUE") %>% which
      categories_list[indices[1]]
   }) %>% unlist
}

