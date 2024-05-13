
data ratings;
    length rating $4;
    rating = 'A+';
    moodys = 'Baa2';
    s_and_p = 'BBB+';
    fitch = 'A+';
    output;
    rating = 'Aa3';
    moodys = 'Aa3';
    s_and_p = 'AAA';
    fitch = 'AA-';
    output;
    rating = 'c';
    moodys = 'Aa3';
    s_and_p = 'AAA';
    fitch = 'AA-';
    output;
    rating = 'D-';
    moodys = 'Aa3';
    s_and_p = 'D-';
    fitch = 'D-';
    output;
run;

data ratings_match;
    set ratings;
    length rating_match $8;

    if rating = moodys then rating_match = 'moodys';
    else if rating = s_and_p then rating_match = 's_and_p';
    else if rating = fitch then rating_match = 'fitch';
    else rating_match = 'no match';
run;

data ratings_match;    
    set ratings;
    /*  WHICHC talar om variabelnumret man får träff på, baserat på ordningen
        man raddar upp variablerna i på samma sätt som COALESCEC. 
        Finns bara träff i en variabel spelar ordningen ingen roll.
        Prioordning (i de fall man får träff på flera):
        1. Moodys
        2. S&P
        3. Fitch */
    variable_match_number = whichc(rating, moodys, s_and_p, fitch);
run;


data ratings_match;    
    set ratings;
    length rating_match $8;
    /* Array för att peka på de tre variablerna med värden,
       måste ha samma ordning som WHICHC */
    array rating_agency [3] moodys s_and_p fitch;
    
    variable_match_number = whichc(rating, moodys, s_and_p, fitch);
    
    /* Får man träff i någon variabel gå vidare och plocka fram namnet på variabeln */
    if variable_match_number then rating_match = vname(rating_agency[variable_match_number]);
    else rating_match = 'no match';
run;

/* Ändrar ordningen på WHICHC och inte arrayen, blir helt tokigt.
   Är det långa listor kan man med fördel speca ordningen i en 
   makrovariabel så man bara gör det 1 gång. */
data ratings_match_error;    
    set ratings;
    length rating_match $8;
    array rating_agency [3] moodys s_and_p fitch;
    
    variable_match_number = whichc(rating, s_and_p, fitch, moodys);
    
    if variable_match_number then rating_match = vname(rating_agency[variable_match_number]);
    else rating_match = 'no match';
run;
