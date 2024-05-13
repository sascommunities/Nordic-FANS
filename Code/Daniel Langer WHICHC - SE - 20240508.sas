
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
    /*  WHICHC talar om variabelnumret man f�r tr�ff p�, baserat p� ordningen
        man raddar upp variablerna i p� samma s�tt som COALESCEC. 
        Finns bara tr�ff i en variabel spelar ordningen ingen roll.
        Prioordning (i de fall man f�r tr�ff p� flera):
        1. Moodys
        2. S&P
        3. Fitch */
    variable_match_number = whichc(rating, moodys, s_and_p, fitch);
run;


data ratings_match;    
    set ratings;
    length rating_match $8;
    /* Array f�r att peka p� de tre variablerna med v�rden,
       m�ste ha samma ordning som WHICHC */
    array rating_agency [3] moodys s_and_p fitch;
    
    variable_match_number = whichc(rating, moodys, s_and_p, fitch);
    
    /* F�r man tr�ff i n�gon variabel g� vidare och plocka fram namnet p� variabeln */
    if variable_match_number then rating_match = vname(rating_agency[variable_match_number]);
    else rating_match = 'no match';
run;

/* �ndrar ordningen p� WHICHC och inte arrayen, blir helt tokigt.
   �r det l�nga listor kan man med f�rdel speca ordningen i en 
   makrovariabel s� man bara g�r det 1 g�ng. */
data ratings_match_error;    
    set ratings;
    length rating_match $8;
    array rating_agency [3] moodys s_and_p fitch;
    
    variable_match_number = whichc(rating, s_and_p, fitch, moodys);
    
    if variable_match_number then rating_match = vname(rating_agency[variable_match_number]);
    else rating_match = 'no match';
run;
