d3.csv("data/play_cards.csv").then(function(cards){ 
    cards.forEach(function(d){
        return d.price = +d.price;
    })

    var random_card = cards[Math.floor(Math.random() * cards.length)];

    function letPlay(){
        d3.select("#guess").property("value", "");
        
        random_card = cards[Math.floor(Math.random() * cards.length)];
        
        d3.select("#guess-picture").attr("src", "img/png/"+ random_card.img)
        d3.select("#guess-product").html( random_card.title.toUpperCase() + " ("+ random_card.weight+")");

        submitAnswer();

        d3.select("#correct-answer").style("display", "none");
        d3.select("#action-form").style("display", "grid");

       
        
    }



    function submitAnswer(){
        let guessValue = d3.select("#guess").property("value");
        var testResult;
        var resultColor;       

        if(guessValue === ""){
            return false
        } else {
            d3.select("#correct-price").text(random_card.price);            
            if(guessValue === random_card.price){
                testResult="вгадали";
                resultColor = "green"
            } else if(guessValue > random_card.price*2 || guessValue < random_card.price/2){               
                testResult="не вгадали"; 
                resultColor = "red"            
            } else {
                testResult="майже"; 
                resultColor = "green"      
                
            }
            d3.select("#test-result").select("text").text(testResult).style("color", resultColor);
        }

        d3.select("#correct-answer").style("display", "grid");
        d3.select("#action-form").style("display", "none");
        d3.select("#btn-play-again").style("display", "block");

    }



    letPlay();
    
    d3.select("#submit").on("click", submitAnswer);

    d3.select("#btn-play-again").on("click", letPlay);




})