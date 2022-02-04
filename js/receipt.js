const darkBlue = '#324563';

d3.csv("data/cpi_q1_median_january_2022_and_govstat_history.csv").then(function(data){  

    const mainColor = '#EB5757';   

    data.forEach(function(d){           
         d.month = d3.timeParse("%Y-%m-%d")(d.month);
         d.inflation = +d.inflation;
         d.price = +d.price;   
         d.count = 1;
    })

    var items_array = data.filter(function(d){           
        return d.measure === "Q1" && 
            d.month.getTime() === new Date("2022-01-01T00:00:00").getTime() 
    })

    var nested_data = d3.nest()
        .key(function(d) { return d.category; })
        .entries(items_array);
   
    var itemCategory = d3.select(".categories")
        .selectAll("div.shop-item-category")
        .data(nested_data)
        .enter()
        .append("div")
        .attr('class', "shop-item-category");

    itemCategory.append("img")    
        .attr("class", "icon")      
        .attr("src", function(d){ return "img/png/"+d.values[0].picture});

        
    itemCategory.append("input")    
        .attr("class", "toggle-inbox")
        .attr("id", function(d,i){ return "_"+i })
        .attr("type", "checkbox")

    itemCategory.append("label")
        .attr("class", "label")
        .attr("for", function(d,i){ return "_"+i })
        .text(function(d){  return d.key })
        .on("click", function(){             
            d3.select(this.parentNode)
                .selectAll(".shop-item-wrapper")                
                .classed("hidden", !d3.select(this.parentNode).selectAll(".shop-item-wrapper").classed("hidden"));           
            
        })
        
    var itemDetails = itemCategory
        .append("div")
        .attr("class", "shop-item-wrapper")
        .classed("hidden", true)
        .selectAll("div.shop-item")
        .data(function(d){ return d.values}) 
        .enter()       
        .append("div")
        .attr("class", "shop-item")
        .append("div")
        .attr("class", "shop-item-details");


    //приховані параметри    
    itemDetails
        .append("span")
        .attr('class', "shop-item-title")
        .text(function(d){  return d.short_name })
        .attr("item-price", function(d){ return d.price })
        .attr("mode-weight", function(d){ return d.mode })
        .attr("weight-step", function(d){ return d.step })   


    //видима кнопка
    itemDetails
        .append("button")
        .attr('class', "btn btn-primary shop-item-button")
        .attr("type", "button")
        .text(function(d){ return d.short_name});

    //створюємо пустий кошик    
    var cart = [];
    var cartMode = {};


    var removeCartItemButtons = document.getElementsByClassName('btn-danger')
        for (var i = 0; i < removeCartItemButtons.length; i++) {
            var button = removeCartItemButtons[i]
            button.addEventListener('click', removeCartItem)
        }
    
    var quantityInputs = document.getElementsByClassName('cart-quantity-input')
        for (var i = 0; i < quantityInputs.length; i++) {
            var input = quantityInputs[i]
            input.addEventListener('change', quantityChanged)
        }
    
    var addToCartButtons = document.getElementsByClassName('shop-item-button')
        for (var i = 0; i < addToCartButtons.length; i++) {
            var button = addToCartButtons[i]
            button.addEventListener('click', addToCartClicked)
            }
    
   document.getElementsByClassName('btn-clear-all')[0].addEventListener('click', cleanBasket)
        
            
    //очистити кошик
    function cleanBasket() {    
       
        //clean basket
        var cartItems = document.getElementsByClassName('cart-items')[0]
        while (cartItems.hasChildNodes()) {
            cartItems.removeChild(cartItems.firstChild)
        } 
        
        //оновлюємо корзину
        cart=[];
        updateCartTotal();
        
        //remove click style from products buttons
        let clickedItems = document.getElementsByClassName('shop-item-button');
        for(var i = 0; i < clickedItems.length; i++){
            clickedItems[i].classList.remove('shop-item-clicked')
        }

        //ховаємо іконки категорій
        let iconPics = document.getElementsByClassName('icon');
        for(var i = 0; i < iconPics.length; i++){
            iconPics[i].style.opacity = 0
        }

        //повертаємо "не обрано жодного товару", ховаємо графіки
        document.getElementById('no-history-to-show').style.display="block";  
        document.getElementById('my_dataviz').style.display="none";  
        document.getElementsByClassName('infliation-real')[0].innerText = '0%'
    }
        
    //видалити один елемент
    function removeCartItem(event) {
        var buttonClicked = event.target
        buttonClicked.parentElement.parentElement.remove();
        let valueToRemove = buttonClicked.parentElement.parentElement.getElementsByClassName("cart-item-title")[0].innerHTML;
        let allProducts = document.getElementsByClassName('shop-item-button');
        
        for(var i = 0; i < allProducts.length; i++){
            if(allProducts[i].innerHTML === valueToRemove) {
                allProducts[i].classList.remove('shop-item-clicked')
            }
        }

        cart=[];
        updateCartTotal();


        //якщо в цій категорії не залишилось обраних товарів, прибираємо іконку продукту
        let categList = document.getElementsByClassName('shop-item-category');
        for(var i = 0; i < categList.length; i++){
            if(categList[i].getElementsByClassName('shop-item-clicked')[0]){
                console.log('nothing selected')
            } else {
                categList[i].getElementsByClassName('icon')[0].style.opacity=0
            }
        }        
    }       


    function quantityChanged(event) {
        var input = event.target
        if (isNaN(input.value) || input.value <= 0) {
            input.value = 1
        }

        updateCartTotal()
    }


    d3.select('#cart-price_dropdown').on("change", function(d){
        updateCartTotal()
    })

    function changeMonth(){
        var month_for_compare = d3.select('#cart-price_dropdown').node().value; 
    }
        

    function addToCartClicked(event) {
        event.target.classList.add('shop-item-clicked'); 
        
        var shopItem = event.target.parentElement.parentElement;
        
        //іконки категорій
        shopItem.parentElement.parentElement.getElementsByClassName('icon')[0].style.opacity = 1;  
        
        //додаткові параметри
        var shopItemDetails = shopItem.getElementsByClassName('shop-item-title')[0]        
        var title = shopItemDetails.innerText;            
        var mode = shopItemDetails.getAttribute('mode-weight');
        var step = shopItemDetails.getAttribute('weight-step');
        var price_kg = shopItemDetails.getAttribute('item-price');
        var price = price_kg * mode;

        addItemToCart(title, price, price_kg, mode, step);

        updateCartTotal();

        document.getElementById('no-history-to-show').style.display="none";   
        document.getElementById('my_dataviz').style.display="block";   
    }
        
    function addItemToCart(title, price, price_kg, mode, step) {
        cart = []
        price = parseFloat(price);
        price_kg = parseFloat(price_kg);
        
        var cartRow = document.createElement('div')
        cartRow.classList.add('cart-row')


        var cartItems = document.getElementsByClassName('cart-items')[0];        
        var cartItemNames = cartItems.getElementsByClassName('cart-item-title');

        var cartItemCounts = cartItems.getElementsByClassName('cart-quantity-input')
        for (var i = 0; i < cartItemNames.length; i++) {
            if (cartItemNames[i].innerText == title) {
                console.log('This item is already added to the cart')  
                cartItemCounts[i].value = parseInt(cartItemCounts[i].value, 10) + 1                   
                return
            }
        }

        var cartRowContents = `
            <div class="cart-column cart-item">
                <span class="cart-item-title">${title}</span>
            </div>     
            <input class="cart-quantity-input" type="number" min=”${step}″ value="${mode}" step="${step}" lang="en">   
                
            <span data-price-kg='${price_kg}' class="cart-column cart-price-last">${price.toFixed(2)}</span>                
            <span class="cart-column cart-price-previous"></span>
            <div class="cart-column last-column">
                <span class="cart-item-infliation"></span>
                <button class="btn btn-danger" type="button">&#x2715</button>
            </div>   `
            
        cartRow.innerHTML = cartRowContents
        cartItems.append(cartRow);

        cartRow.getElementsByClassName('btn-danger')[0].addEventListener('click', removeCartItem)
        cartRow.getElementsByClassName('cart-quantity-input')[0].addEventListener('change', quantityChanged)
    }
        
    function updateCartTotal() {   
        var month_for_compare = d3.select('#cart-price_dropdown').node().value;                   
        var formula = []                    
        var count = 0;
        var cartItemContainer = document.getElementsByClassName('cart-items')[0]
        var cartRows = cartItemContainer.getElementsByClassName('cart-row')
        var total_current = 0
        var total_previous = 0;
        cartMode = {};
        for (var i = 0; i < cartRows.length; i++) {
            var cartRow = cartRows[i];

            //кількість біля товару
            let quantity = cartRow.getElementsByClassName('cart-quantity-input')[0].value;

            //масив із назв продуктів, за якими фільтруємо дані для графіків
            var itemTitle = cartRow.getElementsByClassName('cart-item-title')[0].innerText;
            cart.push(itemTitle);       

            
            cartMode[itemTitle] = parseFloat(quantity);            
            
            //дані для обраного для порівняння місяці
            var data_for_compare = data
                .filter(function(d){ return d.month.getTime() === d3.timeParse("%Y-%m-%d")(month_for_compare).getTime() })
                .filter(function(d){ return d.short_name === itemTitle & d.measure === "Q1"});        

            
            
            //ціна за кг за останній місяць для кошику
            let last_price_kg = parseFloat(cartRow.getElementsByClassName('cart-price-last')[0].getAttribute('data-price-kg'));  
            
            //ціна за попередній обраний місяць
            let previous_price_kg = parseFloat(data_for_compare[0].price)
            
            //вартість з урахуванням ваги
            let last_price = last_price_kg * quantity; 
            let previous_price = previous_price_kg * quantity;
                 
            //інфляція
            let infliation = (last_price_kg / (previous_price_kg/100)).toFixed(1)           
            
            //оновлюємо вартість за останній місяць з врахуванням зміненої ваги
            cartRow.getElementsByClassName('cart-price-last')[0].innerHTML = last_price.toFixed(1);            
            cartRow.getElementsByClassName('cart-price-previous')[0].innerHTML = previous_price.toFixed(1);
            cartRow.getElementsByClassName('cart-item-infliation')[0].innerHTML = infliation < 100 ? infliation+"%" + '<span style="color:green;">&#129067;</span>':  
                                    infliation > 100 ? infliation+"%" + '<span style="color:red;">&#129065;</span>':
                                    infliation+"%" ;          
                   
            
            //перераховуємо "усього", базова одиниця в нас 0.1 (тобто 100 гр) через те, що є часник, кава та інші продукти, де кг- це забагато.
            total_current = total_current + last_price;
            total_previous = total_previous + previous_price;
            
            //масив із середніми значеннями ІСЦ на основі вагових коеффіцієнтів
            formula.push(parseFloat(infliation) * parseFloat(quantity))                
            count =  count + parseFloat(quantity);                     
        }


        total_current = Math.round(total_current * 100) / 100
        total_previous = Math.round(total_previous * 100) / 100;

        //розмір персональної інфляції на основі вагових коефіцієнтів
        var personal_q1_inliation = formula.reduce( function(a, b){ return  a + b}, 0) / count; 
        
        document.getElementsByClassName('cart-total-last')[0].innerText = total_current;
        document.getElementsByClassName('cart-total-previous')[0].innerText =  total_previous;
        document.getElementsByClassName('infliation-calculated')[0].innerText = personal_q1_inliation > 0 ? (personal_q1_inliation).toFixed(1) + "%" : '0%';
        document.getElementsByClassName('infliation-real')[0].innerText = personal_q1_inliation > 0 ? (total_current/(total_previous/100)).toFixed(1) + "%" : '0%';

        drawCharts();        
    }

    var sum = function(df, prop){
        return df.reduce( function(a, b){
            return  parseInt(a) + parseInt(b[prop]);
        }, 0);
    };

    function drawCharts(){
        d3.select("#my_dataviz").selectAll("svg").remove();       
        d3.select('#charts-legend').style("display", "block")

        var chartsData = data.filter(function(k){
            return cart.includes(k.short_name) & (k.measure === "Q1" | k.measure === "govstat");
        }) 
        
        //сортуємо дані в тому порядку, як вони йдуть в коризині
        chartsData.sort(function(a,b) { return cart.indexOf(a.name) - cart.indexOf(b.name)})
        

        var margin = {top: 30, right: 0, bottom: 50, left: 30},
            width = 280 - margin.left - margin.right,
            height = 210 - margin.top - margin.bottom;

        
            // group the data: I want to draw one line per group
        var sumstat = d3.nest() // nest function allows to group the calculation per level of a factor
            .key(function(d) { return d.short_name;})
            .entries(chartsData);

        // What is the list of groups?
        allKeys = sumstat.map(function(d){return d.key})

        // Add an svg element for each group. The will be one beside each other and will go on the next row when no more room available
        sumstat.forEach(function(item){   
            item.values = item.values.sort(function(a,b){
                return a.month - b.month
            })                  

            var svg = d3.select("#my_dataviz")
                .append("svg")
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)               
                .append("g")               
                .attr("transform",
                "translate(" + margin.left + "," + margin.top + ")");

            var xYears = d3.scaleTime()
                // .domain(d3.extent(item.values, function(d) { return d.month; }))
                .domain([new Date("2017-10-01"), new Date("2021-12-01")])
                .range([ 0, width/3 ]);

            var xMonths = d3.scaleTime()
                // .domain(d3.extent(item.values, function(d) { return d.month; }))
                .domain([new Date("2021-08-01"), new Date("2022-03-31")])
                .range([width/3, width]);

            svg
                .append("g")
                .attr("transform", "translate(0," + height + ")")
                .call(d3.axisBottom(xMonths)
                .tickValues([                                       
                    new Date('2021-08-01'),
                    new Date('2021-09-01'),
                    new Date('2021-10-01'),
                    new Date('2021-11-01'),
                    new Date('2021-12-01'),
                    new Date('2022-01-01'),                       
                ])
                    .tickSize(-height)
                    .tickFormat(d3.timeFormat("%b %y"))                        
                ).selectAll("text")
                .style("transform", "rotate(-90deg) translate(-10px, 0)");;

                svg
                .append("g")
                .attr("transform", "translate(0," + height + ")")
                .call(d3.axisBottom(xYears)                    
                    .tickValues([
                        new Date('2017-10-01'), 
                        new Date('2018-10-01'), 
                        new Date('2019-10-01'), 
                        new Date('2020-10-01')
                        
                    ]) 
                    .tickFormat(d3.timeFormat("%y"))                        
                )


              
            var yMax = d3.max(item.values, function(d) { 
                return parseFloat(d.price * cartMode[d.short_name]); 
            })

            var y = d3.scaleLinear()
                .domain([0, yMax * 2])
                .range([ height, 0 ]); 

            svg
                .append("g")
                .call(d3.axisLeft(y).ticks(5));              

            svg
                .append("path")
                .attr("fill", "none")
                .attr("stroke", "lightgrey")
                .attr("stroke-width", 1)
                .attr("d", function(){
                    
                return d3.line()
                    .x(function(d) { return xYears(d.month); })
                    .y(function(d) { return y(+d.price * cartMode[d.short_name]); })
                    (item.values.filter(function(k){ return k.measure === "govstat"})) 
                });

            svg.selectAll('circle')
                .data(item.values.filter(function(k){ return k.measure === "Q1"}))
                .enter()
                .append('circle')
                .attr("cx", function(d){ return xMonths(d.month); })
                .attr("cy", function(d){ return y(+d.price * cartMode[d.short_name]); })
                .attr("r", 2.5)
                .attr("fill", "red");


                svg
                .append("path")
                .attr("fill", "none")
                .attr("stroke", mainColor)
                .attr("stroke-width", 1.9)
                .attr("d", function(){                        
                return  d3.line()
                    .x(function(d) { return xMonths(d.month); })
                    .y(function(d) { return y(+d.price * cartMode[d.short_name]); })
                    (item.values.filter(function(k){ return k.measure === "Q1"})) 
                }) 

            // Add titles
            svg
                .append("text")
                .attr("text-anchor", "start")
                .attr("y", -5)
                .attr("x", 0)
                .text(function(){ return(item.key)})
                .style("fill", darkBlue)


            svg
                .append("text")
                .attr("text-anchor", "start")
                .attr("y", height+40)
                .attr("x", 10)
                .text("роки")
                .style("fill", darkBlue)
                .style('font-size', '14px')

            svg
                .append("text")
                .attr("text-anchor", "start")
                .attr("y", height+40)
                .attr("x", xMonths(new Date('2021-10-01')))
                .text("місяці")
                .style("fill", darkBlue)
                .style('font-size', '14px')


        })

    }

      

        function bouncer(arr) {
            return arr.filter(Boolean);
          }


               
});