d3.csv("data/play_cards.csv").then(function(cards){ 
    cards.forEach(function(d){
        return d.price = +d.price;
    })

    var random_card = cards[Math.floor(Math.random() * cards.length)];
    var unwatched_cards = cards.filter(function(d){ return d.index != random_card.index; })

    function letPlay(){
        d3.select("#guess").property("value", "");        

        //якщо всі картки програно, то починаємо спочатку
        if(unwatched_cards.length === 0){
            unwatched_cards = cards
        }

        //обираємо випадкову картку
        random_card = unwatched_cards[Math.floor(Math.random() * unwatched_cards.length)];  

        //прибираємо вибране значення з масиву
        unwatched_cards = unwatched_cards.filter(function(d){ return d.index != random_card.index; })
        
        //виводимо назву продукту і картинку в контейнер з карткою
        d3.select("#guess-picture").attr("src", "img/png/"+ random_card.img)
        d3.select("#guess-product").html( random_card.title.toUpperCase() + " ("+ random_card.weight_to_show+")");

        //ховаємо правильну відповідь
        d3.select("#correct-answer").style("display", "none");

        //показуємо форму для вгадування
        d3.select("#action-form").style("display", "grid");         
    }



    function submitAnswer(){
        //get user input
        let guessValue = d3.select("#guess").property("value");
        
        //test result : вгадали або ні
        var testResult;

        //колір цифри в залежності від результату
        var resultColor;       

        //якщо юзер не ввів цифру і натиснув на submit
        if(guessValue === ""){
            return false
        } else {          
            //TODO поміняти на нормальну формулу             
            if(Math.round(guessValue) === Math.round(random_card.price)){
                testResult="вгадали";
                resultColor = "#25a625";          
            } else if(guessValue > random_card.price*1.2 || guessValue < random_card.price/1.2){               
                testResult="не вгадали"; 
                resultColor = "red";            
            } else {
                testResult="майже"; 
                resultColor = "#25a625"; 
            }

            //виводимо у відповідне поле результати вгадування
            d3.select("#test-result").select("text").text(testResult);
            d3.select("#correct-price").text(random_card.price).style("color", resultColor); 
        }

        //ховаємо форму відповіді і показуємо правильну
        d3.select("#correct-answer").style("display", "grid");
        d3.select("#action-form").style("display", "none");
        d3.select("#btn-play-again")
            .style("opacity", "1")
            .style("pointer-events", "all");

    }

    /* ВІДПРАВКА ДАНИХ ЧЕРЕЗ ФОРМУ */
    d3.select("#submit").on("click", function(){    
        let guessValue = d3.select("#guess").property("value");
     
        let row = {"product": random_card.title, 
                   "guess_price": parseFloat(guessValue), 
                   "real_price": parseFloat(random_card.price), 
                   "guess_month": random_card.month,
                   "date": new Date()
                };      
                
        texty_food_api.add(row)

        submitAnswer(); 
        
      });
   
       
    letPlay();
    d3.select("#btn-play-again").on("click", letPlay);




})