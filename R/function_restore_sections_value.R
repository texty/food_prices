restore_sections_value = function(df){
   # ====================================================
   # додати категорію до цін за вересень і початок жовтня
   # =====================================================
   # у вересні відскрейпились дані без категорії товарів
   product_group_list = df %>% 
      select(V2:V5) %>% 
      unique() %>% 
      filter(V3 != "") %>% 
      filter(V2 != "Товари зі знижкою")
   
   # ділимо датасет на два - із категорією та без
   with_group = df %>% 
      filter(V3 != "") %>% 
      filter(V2 != "Товари зі знижкою")
   
   # приєднуємо категорію за id товару
   without_group = df %>% 
      filter(V3 == "") %>% 
      select(-V2, -V3) %>% 
      left_join(product_group_list, by=c("V4", "V5")) %>% 
      select(V1,V2,V3,V4,V5,V6,V7,V8,V9,V10,V11,V12)
   
   # переобʼєднуємо в один набір
   joint = with_group %>% 
      rbind(without_group)
   
   
   colnames(joint) <- c("webstore", "big_category","section","product","id","price","discount","discount_price","weight","weight_value","weight_unit","time")
   
   # уніфікуємо всі ціни за кілограм, штуку або літр
   data = joint %>% 
      mutate(price = ifelse(discount == "false", discount_price, price)) %>% 
      filter(discount == "false") %>%  # не враховуємо випадкові знижки, щоб не спотворити рівень інфляції
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
      mutate(subsection = detect_product(section,product)) %>% 
      filter(!is.na(subsection))
   
   
   return(data)
}