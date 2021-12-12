/* 
        function addItemToCart(title, price) {
            console.log(title);
            var cartRow = d3.select('.cart-items')
                .append("div")
                .classed("cart-row", true);           
            //var cartItems = d3.select('.cart-items')
            //var cartItems = document.getElementsByClassName('cart-items')[0]
            //var cartItemNames = cartItems.getElementsByClassName('cart-item-title')
            //var cartRows = cartItems.getElementsByClassName("cart-row")
            var cartRows = d3.selectAll('.cart-row').node()
            console.log(cartRows);
            //for (var i = 0; i < cartItemNames.length; i++) {
            for (var i = 0; i < cartRows.length; i++) {
                console.log(cartRows[i]);
                let cartItemName = cartRows[i].select(".cart-item-title")[0]

                console.log(cartItemName);
                //if (cartItemNames[i].innerText == title) {
                if (cartItemName.innerText == title) {
                    console.log('This item is already added to the cart')                   
                    let cartItemCount = cartRows[i]
                        .select(".cart-quantity-input")
                        .attr("value")

                        console.log(cartItemCount);

                    cartRows[i]
                        .select(".cart-quantity-input")
                        .attr("value", cartItemCount+1)
                  
                    return
                }
            }
            var cartRowContents = `
                <div class="cart-item cart-column">
                    <span class="cart-item-title">${title}</span>
                </div>
                <span class="cart-price cart-column">${price}</span>
                <span class="cart-price cart-column">${price}</span>
                <div class="cart-quantity cart-column">
                    <input class="cart-quantity-input" type="number" value="1">
                    <button class="btn btn-danger" type="button">&#x2715</button>
                </div>`
            //cartRow.innerHTML = cartRowContents
            cartRow.html(cartRowContents)
            cartRow.select('.btn-danger').on('click', removeCartItem)
            cartRow.select('.cart-quantity-input').on('change', quantityChanged)
        } */
        