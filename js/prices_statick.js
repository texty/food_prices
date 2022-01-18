d3.csv("data/govstat_market_compare_prices.csv").then(function(data){  

    data.forEach(function(d){
        d.price = +d.price;
        d.price_q1 = +d.price_q1;
        d.price_min = +d.price_min;
        d.month = d3.timeParse("%Y-%m-%d")(d.month);
    })
    
    var margin = {top: 25, right: 50, bottom: 25, left: 50};
    var chartInnerWidth = 200;
    var chartOuterWidth = 250;
    var chartInnerHeight = 150;
    var chartOuterHeight = 200;    


    var colorScale = d3.scaleSequential()
        .interpolator(d3.interpolateRgb("white", "#7CB3C5", "#000080"))
        .domain([0,399]);  

 
    const xScale = d3.scaleTime()
        .domain([new Date('2021-07-30'), new Date('2021-11-05')])
        .range([0, chartInnerWidth]);

 

    var nested = d3.nest()
        .key(function(d) { return d.item; })
        .entries(data.filter(function(d){ return d.month.getTime() > new Date('2021-07-31').getTime()}));


    //create scale and line generator for each facet
    const chart_data =  Object.fromEntries( nested.map(function(s){ 
        
        const yMax = d3.max(s.values, function(d){ return d.price_q1});
        const yMin = d3.min(s.values, function(d){ return d.price_min});       
       
        const yScale = d3.scaleLinear()
            .domain([0, yMax * 2])
            .range([chartInnerHeight, 0]);
        
        const price_govstat_line = d3.line()
            .x(function(d, i) { return xScale(d.month); })
            .y(function(d) {return yScale(d.price); })

        const price_min_line = d3.line()
            .x(function(d, i) { return xScale(d.month); })
            .y(function(d) {return yScale(d.price_min); })            

        const price_q1_line = d3.line()
            .x(function(d, i) { return xScale(d.month); })
            .y(function(d) {return yScale(d.price_q1); })           

            return [s.key, {yMin, yMax, yScale, price_govstat_line, price_min_line, price_q1_line}];

     })
    )

    const svg = d3.select("#static_chart")
        .selectAll("svg")
        .data(nested)
        .enter()
        .append("svg", ".source")
        .attr("width", chartOuterWidth)
        .attr("height", chartOuterHeight)
        .attr("class", "multiple");


    const multiple = svg.append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");


    multiple.append("g")
        .attr("transform", "translate(0," + chartInnerHeight + ")")
        .attr("class", "x axis")
        .call(d3.axisBottom(xScale)
            .tickFormat(function(d) { return d3.timeFormat("/%m/")(d) })
            .tickValues([new Date('2021-08-01'), new Date('2021-09-01'), new Date('2021-10-01'), new Date('2021-11-01')])
    ).selectAll("text");    
    
    multiple.append("text")
        .attr("class", "item")
        .attr("x", 10)
        .attr("y", 0)
        .text(function(d){ return d.key })
        .style("fill", "#324563")

        //gradient scale
    multiple
        .append("linearGradient")
        .attr("id", function(d, i) { return "line-gradient"+i })
        .attr("gradientUnits", "userSpaceOnUse")
        .attr("x1", 0)
        .attr("y1", 0)
        .attr("x2", 30)
        .attr("y2", chartInnerHeight)
        .selectAll("stop")
        .data(function(d){
            //set different gradient depend on min and max value; 
            let stopColor1 = colorScale(chart_data[d.key].yMax*4);
            let stopColor2 = colorScale(chart_data[d.key].yMax*2);
            let stopColor3 = colorScale(chart_data[d.key].yMin/2);
            
            return [
                {offset: "0%", color: stopColor1}, 
                {offset: "50%", color: stopColor2}, 
                {offset: "100%", color: stopColor3}
            ]
        })
        .enter().append("stop")
        .attr("offset", function(d) { return d.offset; })
        .attr("stop-color", function(d) { return d.color; });



    // Add the line
    multiple.append("rect")
        .attr("x", -15)
        .attr("y", 10)
        .attr("height", function(d){ return chart_data[d.key].yScale(0) - 10 })
        .attr("width", 10 )
        .attr("fill", function(d, i) { return `url(#line-gradient${i})` })



    //govstat    
    multiple.append('path')
        .attr('d', function(d){             
            return chart_data[d.key].price_govstat_line(d.values) 
        })
        .attr('fill', 'none')
        .attr('stroke', '#FF0402')
        .attr('stroke-width', "2px");

    //min price    
    multiple.append('path')
        .attr('d', function(d){             
            return chart_data[d.key].price_min_line(d.values) 
        })
        .attr('fill', 'none')
        .attr('stroke', '#7CB3C5')
        .attr('stroke-width', "2px");

    //q1 price 
    multiple.append('path')
        .attr('d', function(d){             
            return chart_data[d.key].price_q1_line(d.values) 
        })
        .attr('fill', 'none')
        .attr('stroke', darkBlue)
        .attr('stroke-width', "2px");


    multiple
        .each(function(d, i) { 
            if(i === 0){
                d3.select(this)
                    .append("text")
                    .attr("font-size", "12px")                    
                    .attr("y", function(d){ return chart_data[d.key].yScale(d.values[0].price)-5})
                    .attr("x", function(d){ return xScale(new Date('2021-08-01'))})
                    .style("fill", "red")
                    .text("держстат")


                d3.select(this)
                    .append("text")
                    .attr("font-size", "12px")                    
                    .attr("y", function(d){ return chart_data[d.key].yScale(d.values[0].price_min)+10})
                    .attr("x", function(d){ return xScale(new Date('2021-08-01'))})
                    .style("fill", "#7CB3C5")
                    .text("супермаркет: мінімальна")

                d3.select(this)
                    .append("text")
                    .attr("font-size", "12px")                    
                    .attr("y", function(d){ return chart_data[d.key].yScale(d.values[0].price_q1)-5})
                    .attr("x", function(d){ return xScale(new Date('2021-08-01'))})
                    .style("fill", darkBlue)
                    .text("супермаркет:1 квартиль")
            }     
            

    })

    //y axis     
    multiple.append("g")
        .attr("class", "y axis")
        .each(function(d) {      
            const group = d3.select(this);
            const maxYValue = chart_data[d.key].yMax;
            group.call(d3.axisLeft(chart_data[d.key].yScale)                   
                   .tickValues([0, Math.ceil(maxYValue/10)* 10])
                    .tickSize(-chartInnerWidth));

    })
    .selectAll('text').attr('dx', '-1.7em');
});