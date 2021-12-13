d3.csv("data/cpi_q1_median_november_2021.csv").then(function(data){
    

    const mainColor = '#EB5757';
   

    data.forEach(function(d){
         d.month = d3.timeParse("%Y-%m-%d")(d.month);
         d.inflation = +d.inflation;
         d.price = +d.price;
         d.price = d.price.toFixed(1);
         d.count = 1;
    })
 
    var items_array = data.filter(function(d){           
        return d.measure === "Q1" && 
            d.month.getTime() === new Date("2021-11-01T00:00:00").getTime() 
    })

    var itemDetails = d3.select(".shop-items")
        .selectAll("div.shop-item")
        .data(items_array)
        .enter()
        .append("div")
        .attr("class", "shop-item")
        .append("div")
        .attr("class", "shop-item-details");

    itemDetails
        .append("span")
        .attr('class', "shop-item-title")
        .text(function(d){ return d.name})

    itemDetails
        .append("span")
        .attr('class', "shop-item-price")
        .attr('data-infliation', function(d){ return d.inflation})
        .text(function(d){ return d.price})

    itemDetails
        .append("button")
        .attr('class', "btn btn-primary shop-item-button")
        .attr("type", "button")
        .text(function(d){ return d.name});

    var cart = [];

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
    
        document.getElementsByClassName('btn-purchase')[0].addEventListener('click', purchaseClicked)
        
            
        function purchaseClicked() {    
            var cartItems = document.getElementsByClassName('cart-items')[0]
            while (cartItems.hasChildNodes()) {
                cartItems.removeChild(cartItems.firstChild)
            }
            updateCartTotal()
        }
        
        function removeCartItem(event) {
            var buttonClicked = event.target
            buttonClicked.parentElement.parentElement.remove()
            updateCartTotal();
        }
        
        function quantityChanged(event) {
            var input = event.target
            if (isNaN(input.value) || input.value <= 0) {
                input.value = 1
            }
            updateCartTotal()
        }
        
        function addToCartClicked(event) {
            var button = event.target
            //button.style.backgroundColor = "#73B2DF"
            button.style.backgroundColor = '#64BAAA';
            var shopItem = button.parentElement.parentElement
            var title = shopItem.getElementsByClassName('shop-item-title')[0].innerText
            var price = shopItem.getElementsByClassName('shop-item-price')[0].innerText
            var infliation = shopItem.getElementsByClassName('shop-item-price')[0].getAttribute('data-infliation')           
            addItemToCart(title, price, infliation)
            updateCartTotal()
        }
        
        function addItemToCart(title, price, infliation) {
            price = parseFloat(price);
            infliation = parseFloat(infliation);
            var cartRow = document.createElement('div')
            cartRow.classList.add('cart-row')
            var cartItems = document.getElementsByClassName('cart-items')[0]
            
            var cartItemNames = cartItems.getElementsByClassName('cart-item-title')
            var cartItemCounts = cartItems.getElementsByClassName('cart-quantity-input')
            for (var i = 0; i < cartItemNames.length; i++) {
                if (cartItemNames[i].innerText == title) {
                    console.log('This item is already added to the cart')  
                    cartItemCounts[i].value = parseInt(cartItemCounts[i].value, 10) + 1                   
                    return
                }
            }
            var cartRowContents = `
                <div class="cart-item cart-column">
                    <span class="cart-item-title">${title}</span>
                </div>               
                <span data-infliation='${infliation}' class="cart-price_q1 cart-column">${price}</span>
                <span data-infliation='${infliation}' class="cart-price_median cart-column">${ ((price / (infliation + 100)) *100).toFixed(2) }</span>
                <span class="cart-item_infliation cart-column">${infliation + 100}</span>
                <div class="cart-quantity cart-column">
                    <input class="cart-quantity-input" type="number" value="1">
                    <button class="btn btn-danger" type="button">&#x2715</button>
                </div>`
            cartRow.innerHTML = cartRowContents
            cartItems.append(cartRow)
            cartRow.getElementsByClassName('btn-danger')[0].addEventListener('click', removeCartItem)
            cartRow.getElementsByClassName('cart-quantity-input')[0].addEventListener('change', quantityChanged)
        }
        
        function updateCartTotal() {    
            //cart = [];        
            var formula = []                    
            var count = 0;
            var cartItemContainer = document.getElementsByClassName('cart-items')[0]
            var cartRows = cartItemContainer.getElementsByClassName('cart-row')
            var total_q1 = 0
            var total_median = 0
            for (var i = 0; i < cartRows.length; i++) {
                var cartRow = cartRows[i];

                //масив із назв продуктів, за якими фільтруємо дані для графіків
                var itemTitle = cartRow.getElementsByClassName('cart-item-title')[0].innerText;
                cart.push(itemTitle);

                //ціна за останній місяць для кошику
                var InflQ1 = cartRow.getElementsByClassName('cart-price_q1')[0].getAttribute('data-infliation')
                var price_q1 = parseFloat(cartRow.getElementsByClassName('cart-price_q1')[0].innerText)                
                
                // TODO: поки що тут не медіана, а стара ціна, треба подумати, чи потрібна медіана
                var price_median = parseFloat(cartRow.getElementsByClassName('cart-price_median')[0].innerText)                
               
                var quantity = cartRow.getElementsByClassName('cart-quantity-input')[0].value;

                //перераховуємо "усього"
                total_q1 = total_q1 + (price_q1 * quantity)
                total_median = total_median + (price_median * quantity)
                
                //масив із середніми значеннями ІСЦ на основі вагових коеффіцієнтів
                formula.push(parseFloat(InflQ1) * parseInt(quantity))                
                count =  count + parseInt(quantity);
                     
            }
            total_q1 = Math.round(total_q1 * 100) / 100
            total_median = Math.round(total_median * 100) / 100;

            //розмір персональної інфляції на основі вагових коефіцієнтів
            var personal_q1_inliation = formula.reduce( function(a, b){ return  a + b}, 0) / count; 
            
            document.getElementsByClassName('cart-total-q1')[0].innerText =  total_q1
            document.getElementsByClassName('cart-total-median')[0].innerText =  total_median
            document.getElementsByClassName('infliation-total-q1')[0].innerText = 100 + personal_q1_inliation > 0 ? (100 + personal_q1_inliation).toFixed(1) + "%" : '0%';
            document.getElementsByClassName('infliation-total-median')[0].innerText = (total_q1/(total_median/100)).toFixed(1) + "%";
            
        }

        var sum = function(df, prop){
            return df.reduce( function(a, b){
                return  parseInt(a) + parseInt(b[prop]);
            }, 0);
        };

        function drawCharts(){
            d3.select("#my_dataviz").selectAll("svg").remove();

       

            var chartsData = data.filter(function(k){
                return cart.includes(k.name) & k.measure === "Q1" & !isNaN(k.inflation);
            }) 

           /*  chartsData.forEach(function(d){
                d.month = d3.timeParse("%Y-%m-%d")(d.month);
                //d.price = +d.price;
            }) */

            console.log(chartsData);

            var margin = {top: 30, right: 0, bottom: 30, left: 60},
                width = 210 - margin.left - margin.right,
                height = 210 - margin.top - margin.bottom;

           
             // group the data: I want to draw one line per group
            var sumstat = d3.nest() // nest function allows to group the calculation per level of a factor
                .key(function(d) { return d.name;})
                .entries(chartsData);

            // What is the list of groups?
            allKeys = sumstat.map(function(d){return d.key})

            // Add an svg element for each group. The will be one beside each other and will go on the next row when no more room available
            var svg = d3.select("#my_dataviz")
                .selectAll("uniqueChart")
                .data(sumstat)
                .enter()
                .append("svg")
                    .attr("width", width + margin.left + margin.right)
                    .attr("height", height + margin.top + margin.bottom)
                .append("g")
                    .attr("transform",
                        "translate(" + margin.left + "," + margin.top + ")");

            // Add X axis --> it is a date format
            var x = d3.scaleTime()
                .domain(d3.extent(chartsData, function(d) { return d.month; }))
                .range([ 0, width ]);


            svg
                .append("g")
                .attr("transform", "translate(0," + height + ")")
                .call(d3.axisBottom(x).ticks(3));

            //Add Y axis
            var y = d3.scaleLinear()
                .domain([0, d3.max(chartsData, function(d) { return +d.price; })])
                .range([ height, 0 ]);

            svg.append("g")
                .call(d3.axisLeft(y).ticks(5));

            // Draw the line
            svg
            .append("path")
                .attr("fill", "none")
                .attr("stroke", mainColor)
                .attr("stroke-width", 1.9)
                .attr("d", function(d){
                return d3.line()
                    .x(function(d) { return x(d.month); })
                    .y(function(d) { return y(+d.price); })
                    (d.values)
                })

            // Add titles
            svg
                .append("text")
                .attr("text-anchor", "start")
                .attr("y", -5)
                .attr("x", 0)
                .text(function(d){ return(d.key)})
                .style("fill", '#333')



        }

        d3.select('.btn-drawcharts').on('click', drawCharts);
        function bouncer(arr) {
            return arr.filter(Boolean);
          }


               
});