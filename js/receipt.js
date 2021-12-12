d3.csv("data/cpi_q1_median_november_2021.csv").then(function(data){

    data.forEach(function(d){
         d.price = +d.price;
         d.price = d.price.toFixed(1);
         d.count = 1;
    })
 
    var items_array = data.filter(function(d){
        return d.measure === "Q1" && d.month === "2021-11-01";
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
        .text(function(d){ return d.name})

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
            updateCartTotal()
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
            button.style.backgroundColor = "#abefab"
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
                <span class="cart-item_infliation cart-column">${infliation + 100}</span>
                <span data-infliation='${infliation}' class="cart-price_q1 cart-column">${price}</span>
                <span data-infliation='${infliation}' class="cart-price_median cart-column">${ ((price / (infliation + 100)) *100).toFixed(2) }</span>
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
            var formula = []                    
            var count = 0;
            var cartItemContainer = document.getElementsByClassName('cart-items')[0]
            var cartRows = cartItemContainer.getElementsByClassName('cart-row')
            var total_q1 = 0
            var total_median = 0
            for (var i = 0; i < cartRows.length; i++) {
                var cartRow = cartRows[i]

                var priceQ1Element = cartRow.getElementsByClassName('cart-price_q1')[0]
                var InflQ1 = cartRow.getElementsByClassName('cart-price_q1')[0].getAttribute('data-infliation')
                var priceMedianElement = cartRow.getElementsByClassName('cart-price_median')[0]
                
                var quantityElement = cartRow.getElementsByClassName('cart-quantity-input')[0]
                
                var price_q1 = parseFloat(priceQ1Element.innerText.replace('₴', ''))
                var price_median = parseFloat(priceMedianElement.innerText.replace('₴', ''))
                
                var quantity = quantityElement.value
                total_q1 = total_q1 + (price_q1 * quantity)
                total_median = total_median + (price_median * quantity)
                formula.push(parseFloat(InflQ1) * parseInt(quantity))                
                count =  count + parseInt(quantity);
                     
            }
            total_q1 = Math.round(total_q1 * 100) / 100
            total_median = Math.round(total_median * 100) / 100
            var personal_q1_inliation = formula.reduce( function(a, b){ return  a + b}, 0) / count; 
            
            document.getElementsByClassName('cart-total-q1')[0].innerText =  total_q1
            document.getElementsByClassName('cart-total-median')[0].innerText =  total_median
            document.getElementsByClassName('infliation-total-q1')[0].innerText = personal_q1_inliation.toFixed(1) + "%"
        }

        var sum = function(df, prop){
            return df.reduce( function(a, b){
                return  parseInt(a) + parseInt(b[prop]);
            }, 0);
        };
               
});