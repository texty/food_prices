d3.csv("data/play_cards.csv").then(function(cards){ 
    cards.forEach(function(d){
        return d.price = +d.price;
    })

    var random_card = cards[Math.floor(Math.random() * cards.length)];



    function letPlay(){
        d3.select("#guess").property("value", "");        

        //обираємо випадкову картку
        random_card = cards[Math.floor(Math.random() * cards.length)];
        
        //виводимо назву продукту і картинку в контейнер з карткою
        d3.select("#guess-picture").attr("src", "img/png/"+ random_card.img)
        d3.select("#guess-product").html( random_card.title.toUpperCase() + " ("+ random_card.weight+")");

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
        d3.select("#btn-play-again").style("display", "block");

    }

    /* ВІДПРАВКА ДАНИХ ЧЕРЕЗ ФОРМУ */
    d3.select("#submit").on("click", function(){    
        let guessValue = d3.select("#guess").property("value");
     
        let row = {"product": random_card.title, 
                   "guess_price": guessValue, 
                   "real_price": random_card.price, 
                   "guess_month": random_card.month,
                   "date": new Date()
                };       

        //відправляємо записаний рядок
/*         d3.json('http://127.0.0.1:5500/', {
            method:"POST",
            body: JSON.stringify(row),
            headers: {
                "Content-Type": "application/json; charset=UTF-8"
            }
        }).then(function(row){ 
            console.log(row);
            submitAnswer() 
        }) 
             */
  
        //submitAnswer()   
        
      });
   
       
    letPlay();
    d3.select("#btn-play-again").on("click", letPlay);




})